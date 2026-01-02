# MiniSys RISC-V SOC 优化方向实现指南

本文档提供三个主要优化方向的实现指导，重点在于**如何实现**，包括架构设计、关键模块和集成方法。

---

## 1. AXI总线的实现

### 1.1 当前架构分析

当前系统使用简单的点对点总线接口（`peri_bridge.v`）：
- 基于状态机的简单握手协议（enable/done）
- 每个外设独立的控制信号
- 地址译码在桥接模块中硬编码

**局限性**：
- 不支持总线仲裁
- 无法实现burst传输
- 扩展性差，添加外设需修改桥接逻辑

### 1.2 AXI4-Lite实现方案（推荐用于外设）

#### 架构设计

```
    CPU Core
       |
       v
  +----------+
  | AXI Master|  (新增)
  | Interface |
  +----------+
       |
       v  AXI4-Lite Bus
       |
  +----------+
  |Interconnect| (AXI Crossbar或Simple Arbiter)
  +----------+
       |
       +----+----+----+----+
       v    v    v    v    v
     RAM UART LED Timer ...
   (AXI Slaves)
```

#### 关键模块设计

**1. AXI Master接口模块（axi_master.v）**

连接CPU核心的访存接口到AXI总线：

```verilog
module axi_master (
    input clk_i, rst_i,
    
    // CPU接口（保持现有core_top接口）
    input  [31:0] cpu_addr_i,
    input  [31:0] cpu_wdata_i,
    input         cpu_rd_i,
    input         cpu_wr_i,
    input         cpu_enable_i,
    output [31:0] cpu_rdata_o,
    output        cpu_done_o,
    
    // AXI4-Lite Master接口
    // 写地址通道
    output [31:0] m_axi_awaddr,
    output        m_axi_awvalid,
    input         m_axi_awready,
    // 写数据通道
    output [31:0] m_axi_wdata,
    output [3:0]  m_axi_wstrb,  // 字节使能
    output        m_axi_wvalid,
    input         m_axi_wready,
    // 写响应通道
    input  [1:0]  m_axi_bresp,
    input         m_axi_bvalid,
    output        m_axi_bready,
    // 读地址通道
    output [31:0] m_axi_araddr,
    output        m_axi_arvalid,
    input         m_axi_arready,
    // 读数据通道
    input  [31:0] m_axi_rdata,
    input  [1:0]  m_axi_rresp,
    input         m_axi_rvalid,
    output        m_axi_rready
);

// 实现要点：
// 1. 状态机控制AXI事务（IDLE/WRITE_ADDR/WRITE_DATA/WRITE_RESP/READ_ADDR/READ_DATA）
// 2. 根据cpu_mask_wr_i生成wstrb信号
// 3. 处理AXI的ready/valid握手
// 4. 将AXI响应转换为cpu_done信号
```

**2. AXI Slave接口包装器（axi_slave_wrapper.v）**

将现有外设包装为AXI Slave：

```verilog
module axi_slave_wrapper #(
    parameter ADDR_BASE = 32'h30000000,
    parameter ADDR_MASK = 32'hF0000000
)(
    // AXI Slave接口
    input [31:0] s_axi_awaddr,
    input        s_axi_awvalid,
    output       s_axi_awready,
    // ... 其他AXI信号
    
    // 外设原始接口
    output [31:0] peri_addr_o,
    output [31:0] peri_wdata_o,
    output        peri_wr_o,
    output        peri_rd_o,
    input  [31:0] peri_rdata_i,
    input         peri_done_i
);

// 实现要点：
// 1. 地址范围检查
// 2. AXI握手协议转简单读写控制
// 3. 响应生成（OKAY/SLVERR）
```

**3. AXI Interconnect（可选Xilinx IP或自实现）**

选项A：使用Xilinx AXI Interconnect IP
- 优点：成熟可靠，支持多主多从
- 在Vivado中配置Master/Slave数量和地址范围

选项B：简单自实现（适用于单主多从场景）

```verilog
module axi_interconnect (
    // 1个Master接口
    input [31:0] s_axi_awaddr,
    // ... Master信号
    
    // 多个Slave接口
    output [31:0] m_axi_awaddr[N-1:0],
    // ... Slave信号数组
);

// 实现要点：
// 1. 根据地址译码选择目标Slave
// 2. 路由Master请求到对应Slave
// 3. 多路复用Slave响应回Master
// 4. 处理地址不匹配情况（返回DECERR）
```

#### 集成步骤

1. **保留CPU核心接口不变**
   - 在`core_top`和`minisys_soc`之间插入AXI Master

2. **逐个迁移外设**
   - 先迁移简单外设（LED、Switch）
   - 为每个外设创建AXI Slave包装器
   - 保留原外设模块逻辑

3. **地址映射配置**
   ```verilog
   // 在interconnect或包装器中配置
   localparam [31:0] LED_BASE    = 32'h30000000;
   localparam [31:0] LED_SIZE    = 32'h00001000;
   localparam [31:0] UART_BASE   = 32'h00000000;
   localparam [31:0] UART_SIZE   = 32'h00001000;
   ```

4. **验证策略**
   - 使用现有测试程序验证功能不变
   - 添加AXI协议检查器（Vivado ILA）
   - 测试边界情况（无效地址、超时）

### 1.3 性能优化（进阶）

- **Outstanding Transaction**：允许多个未完成的读写请求
- **Write Buffer**：缓存写请求减少等待
- **Read Ahead**：预取指令提高取指效率

---

## 2. M模式和U模式的实现

### 2.1 当前状态分析

当前CSR实现（`core_csr.v`）：
- 支持M模式的基本CSR寄存器（mstatus, mepc, mcause等）
- 实现ECALL/EBREAK/MRET指令
- 支持定时器中断

**缺失部分**：
- 无U模式支持
- 无特权级别切换机制
- 无内存访问权限控制

### 2.2 特权模式实现方案

#### 架构扩展

```
              +----------+
              | M Mode   |  (Machine, 最高特权)
              +----------+
                   |
           mret/exception
                   v
              +----------+
              | U Mode   |  (User, 用户态)
              +----------+
```

#### 关键实现要点

**1. 在CSR模块中添加特权级别寄存器**

```verilog
// 在core_csr.v中添加
reg [1:0] privilege_mode_r;  // 00=U, 11=M

localparam MODE_U = 2'b00;
localparam MODE_M = 2'b11;

// 复位时进入M模式
always @(posedge clk_i or posedge rst_i) begin
    if (rst_i)
        privilege_mode_r <= MODE_M;
    // ... 模式切换逻辑
end
```

**2. 扩展mstatus寄存器**

```verilog
// mstatus寄存器位域（RV32）
// [12:11] MPP (Machine Previous Privilege): 异常前的特权级
// [7] MPIE (Machine Previous Interrupt Enable): 异常前的MIE
// [3] MIE (Machine Interrupt Enable): 中断使能

reg [1:0] mstatus_mpp_r;   // 异常前特权级
reg       mstatus_mpie_r;  // 异常前中断使能
reg       mstatus_mie_r;   // 当前中断使能

always @(*) begin
    mstatus_r = 32'h0;
    mstatus_r[12:11] = mstatus_mpp_r;
    mstatus_r[7]     = mstatus_mpie_r;
    mstatus_r[3]     = mstatus_mie_r;
end
```

**3. 实现ECALL的特权级区分**

```verilog
// 在core_csr.v中修改ECALL处理
wire ecall_from_u = ecall_w && (privilege_mode_r == MODE_U);
wire ecall_from_m = ecall_w && (privilege_mode_r == MODE_M);

always @(posedge clk_i) begin
    if (ecall_from_u) begin
        // U模式ECALL: 环境调用异常
        mcause_r <= 32'd8;  // Environment call from U-mode
        mepc_r <= pc_i;
        mstatus_mpp_r <= privilege_mode_r;  // 保存当前特权级
        mstatus_mpie_r <= mstatus_mie_r;    // 保存中断使能
        privilege_mode_r <= MODE_M;         // 进入M模式
        branch_r <= 1'b1;
        // PC跳转到mtvec
    end
    else if (ecall_from_m) begin
        // M模式ECALL: 不同处理（可用于调试）
        mcause_r <= 32'd11;  // Environment call from M-mode
        // ...
    end
end
```

**4. 实现MRET的特权级恢复**

```verilog
always @(posedge clk_i) begin
    if (mret_w) begin
        // 从异常/中断返回
        privilege_mode_r <= mstatus_mpp_r;   // 恢复特权级
        mstatus_mie_r <= mstatus_mpie_r;     // 恢复中断使能
        mstatus_mpie_r <= 1'b1;              // MPIE设为1
        mstatus_mpp_r <= MODE_U;             // MPP设为U
        branch_r <= 1'b1;
        // PC跳转到mepc
    end
end
```

**5. 添加特权级检查（在LSU或pipeline_ctrl中）**

```verilog
// 在core_lsu.v或新增的privilege_check模块中
wire priv_violation = 
    (privilege_mode_i == MODE_U) && 
    (addr_i[31:28] == 4'h0);  // U模式禁止访问M模式专用地址

always @(*) begin
    if (priv_violation) begin
        // 触发Load/Store Access Fault异常
        exception_o = 1'b1;
        exception_cause_o = (mem_wr_o) ? 32'd7 : 32'd5;
    end
end
```

#### 系统调用机制

**1. 在M模式下实现系统调用处理程序**

```c
// 示例：M模式trap handler
void m_trap_handler() {
    uint32_t cause = read_csr(mcause);
    uint32_t epc = read_csr(mepc);
    
    if (cause == 8) {  // ECALL from U-mode
        // 读取系统调用号（约定放在a7寄存器）
        uint32_t syscall_num = /* 从保存的寄存器获取 */;
        
        switch (syscall_num) {
            case SYS_WRITE:  // 写入
                handle_write();
                break;
            case SYS_READ:   // 读取
                handle_read();
                break;
            // ... 其他系统调用
        }
        
        // 返回U模式
        write_csr(mepc, epc + 4);  // 跳过ECALL指令
        asm volatile("mret");
    }
}
```

**2. U模式应用程序示例**

```c
// U模式程序
int main() {
    // 通过ECALL进行系统调用
    asm volatile(
        "li a7, %0\n"      // 系统调用号
        "ecall\n"
        : : "i"(SYS_WRITE)
    );
    return 0;
}
```

#### 内存保护扩展（PMP - Physical Memory Protection）

可选的内存保护机制：

```verilog
// 添加PMP CSR寄存器（8个区域）
reg [31:0] pmpaddr0_r, pmpaddr1_r, ..., pmpaddr7_r;
reg [7:0]  pmpcfg0_r;   // 每2位配置一个区域（R/W/X权限）

// 在访存时检查PMP
wire pmp_allow = check_pmp_permission(
    addr_i, 
    mem_wr_o, 
    privilege_mode_i
);

wire access_fault = (privilege_mode_i == MODE_U) && !pmp_allow;
```

### 2.3 集成和测试

1. **逐步添加特权寄存器**
   - 先实现mstatus的MPP/MPIE位
   - 添加特权模式状态寄存器

2. **修改异常处理流程**
   - 在ECALL时根据当前特权级设置mcause
   - MRET时恢复特权级

3. **编写测试程序**
   ```c
   // 测试M->U切换
   void test_mode_switch() {
       // 设置用户栈
       // 设置mepc指向用户代码
       // 设置mstatus.MPP = U
       asm volatile("mret");  // 切换到U模式
   }
   
   // U模式代码
   void user_code() {
       // 尝试访问M模式地址（应该触发异常）
       // 执行ECALL（应该陷入M模式）
   }
   ```

4. **验证点**
   - 特权级正确切换
   - ECALL从U模式正确陷入M模式
   - MRET正确返回U模式
   - U模式无法访问M模式资源

---

## 3. PWM控制器与看门狗控制器的实现

### 3.0 PWM与看门狗概述

#### 什么是PWM（脉冲宽度调制）

PWM（Pulse Width Modulation）是一种通过改变脉冲宽度来控制输出功率的技术。

**基本原理**：
- 在固定周期内，通过改变高电平时间占比（占空比）来控制平均输出电压
- 占空比 = 高电平时间 / 周期时间
- 例如：周期1ms，高电平0.5ms，则占空比为50%

**应用场景**：
- **电机速度控制**：通过PWM占空比控制电机转速
- **LED亮度调节**：改变占空比实现LED调光（人眼看到的是平均亮度）
- **舵机控制**：特定PWM脉宽对应舵机角度
- **电源管理**：DC-DC转换器中的开关控制
- **音频输出**：通过PWM生成音频信号

**为什么需要PWM控制器**：
- 软件产生PWM信号不稳定（受中断、调度影响）
- 硬件PWM可以产生精确、稳定的周期信号
- 多通道PWM可以同时控制多个设备

#### 什么是看门狗（Watchdog）

看门狗是一种硬件定时器，用于检测和恢复系统故障。

**基本原理**：
- 看门狗定时器持续倒计时
- 软件必须定期"喂狗"（重置计数器）
- 如果超时未喂狗，认为系统死机，触发复位

**应用场景**：
- **嵌入式系统可靠性**：防止程序跑飞或死循环
- **工业控制**：确保控制系统在故障时自动重启
- **物联网设备**：长期运行设备的自我恢复机制
- **安全关键系统**：航空、汽车等领域的强制要求

**为什么需要看门狗**：
- 软件可能因为各种原因失去响应（死循环、堆栈溢出、指针错误等）
- 硬件看门狗独立于CPU运行，提供最后一道防线
- 自动复位功能可以实现无人值守系统的自愈

#### 与物理外设的本质区别

**物理外设**（如LED、Switch、UART、Keyboard）：
- 有**明确的物理实体**：LED灯、拨码开关、RS232接口、矩阵键盘
- 需要**FPGA引脚连接**：在XDC文件中定义引脚约束
- 功能是**数据输入/输出**：读取外部状态或控制外部器件
- 示例：
  ```verilog
  output gld0_o,  // 连接到开发板上的绿色LED
  input  sw0_i    // 连接到开发板上的拨码开关
  ```

**功能外设**（如PWM、Watchdog）：
- **没有固定的物理实体**：纯粹的数字逻辑功能模块
- **可选的外部连接**：
  - PWM输出可以连接到引脚驱动外部设备，也可以纯内部使用
  - Watchdog输出的复位信号是SOC内部信号
- 功能是**信号生成或系统管理**：
  - PWM生成时序信号
  - Watchdog监控系统健康状态
- 灵活性更高：可以根据需求决定是否引出到外部

#### 如何编写功能外设代码

功能外设的实现分为**三个层次**：

**1. 核心功能模块（Verilog）**

完全在FPGA内部实现，不依赖外部硬件：

```verilog
// PWM核心：生成PWM信号的数字逻辑
module peri_pwm (
    input clk_i,
    input rst_i,
    input [31:0] period_i,    // 从寄存器读取配置
    input [31:0] duty_i,
    output pwm_o              // PWM信号（可内部使用或外部输出）
);
    reg [31:0] counter;
    // 计数器逻辑：比较counter和duty产生PWM波形
endmodule

// Watchdog核心：倒计时和超时检测
module peri_watchdog (
    input clk_i,
    input rst_i,
    input feed_i,             // 喂狗信号
    output timeout_o          // 超时信号（内部复位）
);
    reg [31:0] counter;
    // 倒计时逻辑：counter为0时触发timeout
endmodule
```

**2. 寄存器接口层**

提供CPU访问接口，遵循统一的外设接口规范：

```verilog
// 包装PWM核心，添加寄存器控制
module peri_pwm_wrapper (
    // 标准外设接口（与LED、UART等一致）
    input        wr_i,
    input  [2:0] addr_i,
    input  [31:0] data_wr_i,
    output [31:0] data_rd_o,
    
    // PWM输出（可选：引出或不引出）
    output [7:0] pwm_o
);
    // 寄存器：CTRL, PERIOD, DUTY0-7
    // 连接到PWM核心模块
endmodule
```

**3. SOC集成层**

在`peri_bridge.v`和`minisys_soc.v`中集成，与其他外设同等对待：

```verilog
// 在peri_bridge中添加地址译码
`define MEM_PWM_ADDR 32'h70000000

// 在minisys_soc中实例化
peri_pwm_wrapper pwm (
    .wr_i(pwm_wr_w),
    .addr_i(pwm_addr_w[2:0]),
    .data_wr_i(pwm_data_w),
    .pwm_o(pwm_out_w)  // 内部信号
);

// 决策：是否引出到外部
// 选项A：引出到引脚（需要在XDC中定义）
output [7:0] pwm_o,
assign pwm_o = pwm_out_w;

// 选项B：纯内部使用（例如PWM控制内部LED亮度）
assign led_pwm = pwm_out_w[0];  // 用PWM调制LED

// 选项C：连接到其他内部模块
assign motor_ctrl = pwm_out_w[1];
```

#### 实现策略建议

**PWM控制器**：
- **最小实现**：单通道PWM，连接到LED测试亮度控制
- **标准实现**：8通道PWM，可选引出到GPIO引脚
- **高级实现**：支持死区时间、同步等特性（电机控制）

**看门狗控制器**：
- **最小实现**：单个定时器，超时触发内部复位信号
- **标准实现**：可配置超时时间，带窗口看门狗功能
- **高级实现**：多级看门狗、看门狗中断（超时前警告）

**调试和验证**：
1. **仿真验证**：编写testbench验证PWM波形和看门狗时序
2. **LED测试**：PWM控制LED亮度，看门狗复位后LED闪烁
3. **串口输出**：打印PWM计数器值，看门狗状态
4. **逻辑分析**：使用ILA观察内部信号

**与物理外设的统一性**：
虽然PWM和看门狗是功能外设，但从CPU角度看，访问方式完全一致：
```c
// 物理外设
*(uint32_t*)0x30000000 = 1;  // LED

// 功能外设（访问方式相同）
*(uint32_t*)0x70000000 = 100; // PWM占空比
*(uint32_t*)0x80000000 = 0xCAFE; // 喂狗
```

这种统一的抽象使得软件开发者无需关心底层是物理还是功能外设。

---

### 3.1 PWM控制器实现

#### 硬件模块设计（peri_pwm.v）

```verilog
module peri_pwm (
    input clk_i,
    input rst_i,
    
    // 寄存器接口
    input        wr_i,
    input  [2:0] addr_i,        // 寄存器地址
    input  [31:0] data_wr_i,
    output [31:0] data_rd_o,
    
    // PWM输出
    output [7:0] pwm_o          // 8通道PWM输出
);

// 寄存器定义
// 0x00: CTRL   - 控制寄存器（使能、预分频器）
// 0x04: PERIOD - 周期寄存器（计数器最大值）
// 0x08: DUTY0  - 通道0占空比
// 0x0C: DUTY1  - 通道1占空比
// ...

reg [31:0] ctrl_r;
reg [31:0] period_r;
reg [31:0] duty_r[7:0];

// PWM生成逻辑
reg [31:0] counter_r;
reg [31:0] prescaler_cnt_r;

wire [15:0] prescaler = ctrl_r[15:0];
wire pwm_enable = ctrl_r[31];

// 预分频计数器
always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        prescaler_cnt_r <= 0;
        counter_r <= 0;
    end
    else if (pwm_enable) begin
        if (prescaler_cnt_r >= prescaler) begin
            prescaler_cnt_r <= 0;
            if (counter_r >= period_r)
                counter_r <= 0;
            else
                counter_r <= counter_r + 1;
        end
        else
            prescaler_cnt_r <= prescaler_cnt_r + 1;
    end
end

// PWM输出生成
genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin : gen_pwm
        assign pwm_o[i] = pwm_enable && 
                          (counter_r < duty_r[i]);
    end
endgenerate

// 寄存器读写
always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        ctrl_r <= 0;
        period_r <= 1000;  // 默认周期
        for (int i = 0; i < 8; i++)
            duty_r[i] <= 0;
    end
    else if (wr_i) begin
        case (addr_i)
            3'h0: ctrl_r <= data_wr_i;
            3'h1: period_r <= data_wr_i;
            3'h2: duty_r[0] <= data_wr_i;
            3'h3: duty_r[1] <= data_wr_i;
            // ...
        endcase
    end
end

endmodule
```

#### 地址映射

```
0x70000000: PWM_CTRL    - [31]:使能, [15:0]:预分频值
0x70000004: PWM_PERIOD  - PWM周期（计数器最大值）
0x70000008: PWM_DUTY0   - 通道0占空比
0x7000000C: PWM_DUTY1   - 通道1占空比
...
0x70000024: PWM_DUTY7   - 通道7占空比
```

#### C语言API

```c
#define PWM_BASE 0x70000000
#define PWM_CTRL   (PWM_BASE + 0x00)
#define PWM_PERIOD (PWM_BASE + 0x04)
#define PWM_DUTY(n) (PWM_BASE + 0x08 + (n)*4)

void pwm_init(uint32_t period, uint32_t prescaler) {
    *(volatile uint32_t*)PWM_PERIOD = period;
    *(volatile uint32_t*)PWM_CTRL = prescaler & 0xFFFF;
}

void pwm_enable() {
    *(volatile uint32_t*)PWM_CTRL |= (1u << 31);
}

void pwm_set_duty(int channel, uint32_t duty) {
    *(volatile uint32_t*)PWM_DUTY(channel) = duty;
}

// 示例：LED亮度控制
void led_breathe() {
    pwm_init(1000, 100);  // 周期1000, 预分频100
    pwm_enable();
    
    for (int i = 0; i < 1000; i++) {
        pwm_set_duty(0, i);  // 占空比从0到1000
        delay_ms(2);
    }
}
```

### 3.2 看门狗控制器实现

#### 硬件模块设计（peri_watchdog.v）

```verilog
module peri_watchdog (
    input clk_i,
    input rst_i,
    
    // 寄存器接口
    input        wr_i,
    input  [1:0] addr_i,
    input  [31:0] data_wr_i,
    output [31:0] data_rd_o,
    
    // 系统复位输出
    output reg wdt_reset_o
);

// 寄存器定义
// 0x00: CTRL   - [31]:使能, [30]:复位使能
// 0x04: RELOAD - 重装载值
// 0x08: VALUE  - 当前计数值（只读）
// 0x0C: FEED   - 喂狗寄存器（写入0xCAFE复位计数器）

reg [31:0] ctrl_r;
reg [31:0] reload_r;
reg [31:0] counter_r;

wire wdt_enable = ctrl_r[31];
wire reset_enable = ctrl_r[30];

localparam FEED_KEY = 32'hCAFE;

// 看门狗计数器
always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        counter_r <= 0;
        wdt_reset_o <= 0;
    end
    else if (wdt_enable) begin
        if (counter_r == 0) begin
            // 超时
            if (reset_enable)
                wdt_reset_o <= 1'b1;  // 触发系统复位
        end
        else
            counter_r <= counter_r - 1;
    end
end

// 寄存器写入
always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        ctrl_r <= 0;
        reload_r <= 32'hFFFFFFFF;
    end
    else if (wr_i) begin
        case (addr_i)
            2'h0: ctrl_r <= data_wr_i;
            2'h1: reload_r <= data_wr_i;
            2'h3: begin
                // 喂狗操作
                if (data_wr_i == FEED_KEY)
                    counter_r <= reload_r;
            end
        endcase
    end
end

// 寄存器读取
assign data_rd_o = (addr_i == 2'h2) ? counter_r : 32'h0;

endmodule
```

#### 地址映射

```
0x80000000: WDT_CTRL   - [31]:使能, [30]:复位使能
0x80000004: WDT_RELOAD - 重装载值（超时时间）
0x80000008: WDT_VALUE  - 当前计数值（只读）
0x8000000C: WDT_FEED   - 喂狗（写入0xCAFE）
```

#### C语言API

```c
#define WDT_BASE    0x80000000
#define WDT_CTRL    (WDT_BASE + 0x00)
#define WDT_RELOAD  (WDT_BASE + 0x04)
#define WDT_VALUE   (WDT_BASE + 0x08)
#define WDT_FEED    (WDT_BASE + 0x0C)

#define WDT_FEED_KEY 0xCAFE

void watchdog_init(uint32_t timeout_cycles) {
    *(volatile uint32_t*)WDT_RELOAD = timeout_cycles;
}

void watchdog_enable() {
    *(volatile uint32_t*)WDT_CTRL = (1u << 31) | (1u << 30);
}

void watchdog_feed() {
    *(volatile uint32_t*)WDT_FEED = WDT_FEED_KEY;
}

uint32_t watchdog_get_value() {
    return *(volatile uint32_t*)WDT_VALUE;
}

// 示例：使用看门狗保护系统
int main() {
    watchdog_init(1000000);  // 1秒超时（假设1MHz时钟）
    watchdog_enable();
    
    while (1) {
        // 正常任务
        do_work();
        
        // 定期喂狗
        watchdog_feed();
        
        delay_ms(500);  // 确保在超时前喂狗
    }
}
```

### 3.3 集成到SOC

**1. 在peri_bridge.v中添加新外设**

```verilog
// 添加地址定义
`define MEM_PWM_ADDR     32'h70000000
`define MEM_WDT_ADDR     32'h80000000  // 注意：与RAM冲突，需调整

// 添加接口信号
output reg [2:0]  pwm_addr_o,
output reg        pwm_wr_o,
output reg [31:0] pwm_data_o,
input      [31:0] pwm_data_i,

output reg [1:0]  wdt_addr_o,
output reg        wdt_wr_o,
output reg [31:0] wdt_data_o,
input      [31:0] wdt_data_i
```

**2. 在minisys_soc.v中实例化**

```verilog
// PWM实例
peri_pwm pwm_inst (
    .clk_i(clk_w),
    .rst_i(rst_i),
    .wr_i(pwm_wr_w),
    .addr_i(pwm_addr_w),
    .data_wr_i(pwm_data_w),
    .data_rd_o(pwm_rdata_w),
    .pwm_o(pwm_out)
);

// 看门狗实例
wire wdt_reset_w;
peri_watchdog wdt_inst (
    .clk_i(clk_w),
    .rst_i(rst_i),
    .wr_i(wdt_wr_w),
    .addr_i(wdt_addr_w),
    .data_wr_i(wdt_data_w),
    .data_rd_o(wdt_rdata_w),
    .wdt_reset_o(wdt_reset_w)
);

// 将看门狗复位连接到系统复位
assign system_reset = rst_i | wdt_reset_w;
```

**3. 添加IO端口**

```verilog
// 在minisys_soc顶层添加
output [7:0] pwm_o
```

**4. 更新XDC约束文件**

```tcl
# PWM输出引脚
set_property PACKAGE_PIN XX [get_ports {pwm_o[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pwm_o[0]}]
# ... 其他通道
```

---
