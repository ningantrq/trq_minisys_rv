# MiniSys RISC-V 外设扩展设计方案

## 概述

本文档描述了MiniSys RISC-V SOC的外设扩展设计，包括PWM控制器和看门狗(Watchdog)的实现方案。这些扩展外设将遵循现有的内存映射I/O(MMIO)架构，并与现有外设保持一致的接口规范。

## 1. 现有外设架构分析

### 1.1 内存映射模式

现有外设采用统一的内存映射I/O架构，所有外设通过特定的内存地址空间访问。主要特点包括：

- **基地址划分**：每个外设分配一个唯一的32位基地址，通过高4位(bit31-28)进行区分
- **寄存器布局**：外设内部寄存器通过基地址偏移进行访问
- **统一接口**：所有外设通过标准的Load/Store指令访问

### 1.2 外设设计模式

现有外设的设计遵循以下模式：

1. **模块结构**：每个外设作为独立的Verilog模块实现
2. **桥接接口**：通过peri_bridge.v实现CPU与外设的连接
3. **寄存器映射**：外设功能通过寄存器进行控制和状态查询
4. **中断支持**：部分外设支持中断功能(如Timer)

## 2. PWM控制器设计方案

### 2.1 功能需求

- 支持4路独立的PWM输出通道
- 可配置的PWM周期和占空比
- 支持PWM输出的使能/禁用
- 支持极性反转
- 支持自动重载模式

### 2.2 地址映射

| 外设 | 基地址 | 地址范围 | 说明 |
|------|--------|----------|------|
|PWM   |0x70000000|0x70000000-0x7000003F|脉冲宽度调制器| 

### 2.3 寄存器定义

| 寄存器地址 | 名称 | 读/写 | 说明 |
|------------|------|-------|------|
|0x70000000|PWM_CTRL|W|PWM控制寄存器| 
|0x70000004|PWM_STATUS|R|PWM状态寄存器| 
|0x70000008|PWM_PERIOD_CH0|W|通道0周期寄存器| 
|0x7000000C|PWM_DUTY_CH0|W|通道0占空比寄存器| 
|0x70000010|PWM_PERIOD_CH1|W|通道1周期寄存器| 
|0x70000014|PWM_DUTY_CH1|W|通道1占空比寄存器| 
|0x70000018|PWM_PERIOD_CH2|W|通道2周期寄存器| 
|0x7000001C|PWM_DUTY_CH2|W|通道2占空比寄存器| 
|0x70000020|PWM_PERIOD_CH3|W|通道3周期寄存器| 
|0x70000024|PWM_DUTY_CH3|W|通道3占空比寄存器| 

#### 2.3.1 PWM_CTRL寄存器(0x70000000)

| 位 | 功能 | 说明 |
|----|------|------|
|31-4|保留|未使用| 
|3|POLARITY_CH3|通道3极性(0:正常, 1:反转)| 
|2|POLARITY_CH2|通道2极性(0:正常, 1:反转)| 
|1|POLARITY_CH1|通道1极性(0:正常, 1:反转)| 
|0|POLARITY_CH0|通道0极性(0:正常, 1:反转)| 

#### 2.3.2 PWM_STATUS寄存器(0x70000004)

| 位 | 功能 | 说明 |
|----|------|------|
|31-4|保留|未使用| 
|3|ENABLE_CH3|通道3使能状态(0:禁用, 1:使能)| 
|2|ENABLE_CH2|通道2使能状态(0:禁用, 1:使能)| 
|1|ENABLE_CH1|通道1使能状态(0:禁用, 1:使能)| 
|0|ENABLE_CH0|通道0使能状态(0:禁用, 1:使能)| 

### 2.4 硬件实现

```verilog
module peri_pwm #(
    parameter CLK_FREQ = 25000000
) (
    input clk_i,
    input rst_i,
    
    // Bridge接口
    input [31:0] pwm_period_ch0_i,
    input [31:0] pwm_duty_ch0_i,
    input [31:0] pwm_period_ch1_i,
    input [31:0] pwm_duty_ch1_i,
    input [31:0] pwm_period_ch2_i,
    input [31:0] pwm_duty_ch2_i,
    input [31:0] pwm_period_ch3_i,
    input [31:0] pwm_duty_ch3_i,
    input [31:0] pwm_ctrl_i,
    
    // 物理输出
    output reg pwm_ch0_o,
    output reg pwm_ch1_o,
    output reg pwm_ch2_o,
    output reg pwm_ch3_o,
    
    // 状态输出
    output reg [31:0] pwm_status_o
);
    
    // 通道计数器
    reg [31:0] cnt_ch0_r;
    reg [31:0] cnt_ch1_r;
    reg [31:0] cnt_ch2_r;
    reg [31:0] cnt_ch3_r;
    
    // 占空比和周期寄存器
    reg [31:0] period_ch0_r;
    reg [31:0] duty_ch0_r;
    reg [31:0] period_ch1_r;
    reg [31:0] duty_ch1_r;
    reg [31:0] period_ch2_r;
    reg [31:0] duty_ch2_r;
    reg [31:0] period_ch3_r;
    reg [31:0] duty_ch3_r;
    
    // 极性控制
    wire polarity_ch0 = pwm_ctrl_i[0];
    wire polarity_ch1 = pwm_ctrl_i[1];
    wire polarity_ch2 = pwm_ctrl_i[2];
    wire polarity_ch3 = pwm_ctrl_i[3];
    
    // 初始化和寄存器更新
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            // 复位所有寄存器
            cnt_ch0_r <= 32'b0;
            cnt_ch1_r <= 32'b0;
            cnt_ch2_r <= 32'b0;
            cnt_ch3_r <= 32'b0;
            
            period_ch0_r <= 32'hffff;
            duty_ch0_r <= 32'h7fff;
            period_ch1_r <= 32'hffff;
            duty_ch1_r <= 32'h7fff;
            period_ch2_r <= 32'hffff;
            duty_ch2_r <= 32'h7fff;
            period_ch3_r <= 32'hffff;
            duty_ch3_r <= 32'h7fff;
            
            pwm_ch0_o <= 1'b0;
            pwm_ch1_o <= 1'b0;
            pwm_ch2_o <= 1'b0;
            pwm_ch3_o <= 1'b0;
            
            pwm_status_o <= 32'b0;
        end else begin
            // 更新周期和占空比寄存器
            period_ch0_r <= (pwm_period_ch0_i != 0) ? pwm_period_ch0_i : period_ch0_r;
            duty_ch0_r <= (pwm_duty_ch0_i != 0) ? pwm_duty_ch0_i : duty_ch0_r;
            period_ch1_r <= (pwm_period_ch1_i != 0) ? pwm_period_ch1_i : period_ch1_r;
            duty_ch1_r <= (pwm_duty_ch1_i != 0) ? pwm_duty_ch1_i : duty_ch1_r;
            period_ch2_r <= (pwm_period_ch2_i != 0) ? pwm_period_ch2_i : period_ch2_r;
            duty_ch2_r <= (pwm_duty_ch2_i != 0) ? pwm_duty_ch2_i : duty_ch2_r;
            period_ch3_r <= (pwm_period_ch3_i != 0) ? pwm_period_ch3_i : period_ch3_r;
            duty_ch3_r <= (pwm_duty_ch3_i != 0) ? pwm_duty_ch3_i : duty_ch3_r;
            
            // 通道0 PWM生成
            if (cnt_ch0_r >= period_ch0_r - 1) begin
                cnt_ch0_r <= 32'b0;
            end else begin
                cnt_ch0_r <= cnt_ch0_r + 1'b1;
            end
            
            if (cnt_ch0_r < duty_ch0_r) begin
                pwm_ch0_o <= polarity_ch0 ? 1'b0 : 1'b1;
            end else begin
                pwm_ch0_o <= polarity_ch0 ? 1'b1 : 1'b0;
            end
            
            // 通道1 PWM生成
            if (cnt_ch1_r >= period_ch1_r - 1) begin
                cnt_ch1_r <= 32'b0;
            end else begin
                cnt_ch1_r <= cnt_ch1_r + 1'b1;
            end
            
            if (cnt_ch1_r < duty_ch1_r) begin
                pwm_ch1_o <= polarity_ch1 ? 1'b0 : 1'b1;
            end else begin
                pwm_ch1_o <= polarity_ch1 ? 1'b1 : 1'b0;
            end
            
            // 通道2 PWM生成
            if (cnt_ch2_r >= period_ch2_r - 1) begin
                cnt_ch2_r <= 32'b0;
            end else begin
                cnt_ch2_r <= cnt_ch2_r + 1'b1;
            end
            
            if (cnt_ch2_r < duty_ch2_r) begin
                pwm_ch2_o <= polarity_ch2 ? 1'b0 : 1'b1;
            end else begin
                pwm_ch2_o <= polarity_ch2 ? 1'b1 : 1'b0;
            end
            
            // 通道3 PWM生成
            if (cnt_ch3_r >= period_ch3_r - 1) begin
                cnt_ch3_r <= 32'b0;
            end else begin
                cnt_ch3_r <= cnt_ch3_r + 1'b1;
            end
            
            if (cnt_ch3_r < duty_ch3_r) begin
                pwm_ch3_o <= polarity_ch3 ? 1'b0 : 1'b1;
            end else begin
                pwm_ch3_o <= polarity_ch3 ? 1'b1 : 1'b0;
            end
            
            // 更新状态寄存器
            pwm_status_o[0] <= (period_ch0_r != 0);
            pwm_status_o[1] <= (period_ch1_r != 0);
            pwm_status_o[2] <= (period_ch2_r != 0);
            pwm_status_o[3] <= (period_ch3_r != 0);
            pwm_status_o[31:4] <= 28'b0;
        end
    end
    
endmodule
```

### 2.5 软件接口

```c
// PWM基地址定义
#define PWM_BASE_ADDR 0x70000000

// 寄存器定义
#define PWM_CTRL      (PWM_BASE_ADDR + 0x00)
#define PWM_STATUS    (PWM_BASE_ADDR + 0x04)
#define PWM_PERIOD_CH0 (PWM_BASE_ADDR + 0x08)
#define PWM_DUTY_CH0   (PWM_BASE_ADDR + 0x0C)
#define PWM_PERIOD_CH1 (PWM_BASE_ADDR + 0x10)
#define PWM_DUTY_CH1   (PWM_BASE_ADDR + 0x14)
#define PWM_PERIOD_CH2 (PWM_BASE_ADDR + 0x18)
#define PWM_DUTY_CH2   (PWM_BASE_ADDR + 0x1C)
#define PWM_PERIOD_CH3 (PWM_BASE_ADDR + 0x20)
#define PWM_DUTY_CH3   (PWM_BASE_ADDR + 0x24)

// 初始化PWM通道
void pwm_init(int channel, uint32_t period, uint32_t duty) {
    volatile uint32_t *period_reg = (volatile uint32_t *)(PWM_PERIOD_CH0 + channel * 0x08);
    volatile uint32_t *duty_reg = (volatile uint32_t *)(PWM_DUTY_CH0 + channel * 0x08);
    
    *period_reg = period;
    *duty_reg = duty;
}

// 设置PWM通道占空比
void pwm_set_duty(int channel, uint32_t duty) {
    volatile uint32_t *duty_reg = (volatile uint32_t *)(PWM_DUTY_CH0 + channel * 0x08);
    *duty_reg = duty;
}

// 设置PWM通道极性
void pwm_set_polarity(int channel, int polarity) {
    volatile uint32_t *ctrl_reg = (volatile uint32_t *)PWM_CTRL;
    uint32_t ctrl = *ctrl_reg;
    
    if (polarity) {
        ctrl |= (1 << channel);
    } else {
        ctrl &= ~(1 << channel);
    }
    
    *ctrl_reg = ctrl;
}

// 获取PWM通道状态
int pwm_get_status(int channel) {
    volatile uint32_t *status_reg = (volatile uint32_t *)PWM_STATUS;
    return ((*status_reg) >> channel) & 0x1;
}
```

## 3. 看门狗设计方案

### 3.1 功能需求

- 可配置的超时时间
- 支持中断和系统复位功能
- 支持手动喂狗(重置计数器)
- 支持使能/禁用控制
- 支持超时中断状态查询

### 3.2 地址映射

| 外设 | 基地址 | 地址范围 | 说明 |
|------|--------|----------|------|
|Watchdog|0x90000000|0x90000000-0x9000000F|看门狗定时器| 

### 3.3 寄存器定义

| 寄存器地址 | 名称 | 读/写 | 说明 |
|------------|------|-------|------|
|0x90000000|WD_LOAD|W|加载超时值寄存器| 
|0x90000004|WD_VALUE|R|当前计数值寄存器| 
|0x90000008|WD_CTRL|W|控制寄存器| 
|0x9000000C|WD_INT_CLEAR|W|中断清除寄存器| 

#### 3.3.1 WD_CTRL寄存器(0x90000008)

| 位 | 功能 | 说明 |
|----|------|------|
|31-3|保留|未使用| 
|2|RESET_EN|复位使能(0:禁用, 1:使能)| 
|1|INT_EN|中断使能(0:禁用, 1:使能)| 
|0|ENABLE|看门狗使能(0:禁用, 1:使能)| 

### 3.4 硬件实现

```verilog
module peri_watchdog #(
    parameter CLK_FREQ = 25000000,
    parameter RESET_DELAY = 1000  // 复位脉冲宽度(时钟周期数)
) (
    input clk_i,
    input rst_i,
    
    // Bridge接口
    input [31:0] wd_load_i,       // 加载超时值
    input [31:0] wd_ctrl_i,        // 控制寄存器
    input        wd_int_clear_i,   // 中断清除
    
    // 输出
    output reg wd_int_o,           // 中断输出
    output reg wd_reset_o,         // 复位输出
    output reg [31:0] wd_value_o   // 当前计数值
);
    
    // 控制信号
    wire enable = wd_ctrl_i[0];
    wire int_en = wd_ctrl_i[1];
    wire reset_en = wd_ctrl_i[2];
    
    // 计数器
    reg [31:0] counter_r;
    reg [31:0] load_value_r;
    reg reset_pulse_cnt_r;
    
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            // 系统复位
            counter_r <= 32'b0;
            load_value_r <= 32'hffff_ffff;
            wd_int_o <= 1'b0;
            wd_reset_o <= 1'b0;
            reset_pulse_cnt_r <= 0;
        end else begin
            // 加载新的超时值
            if (wd_load_i != 0) begin
                load_value_r <= wd_load_i;
                counter_r <= wd_load_i;
                wd_int_o <= 1'b0;
            end
            
            // 清除中断
            if (wd_int_clear_i) begin
                wd_int_o <= 1'b0;
            end
            
            // 看门狗计数
            if (enable) begin
                if (counter_r > 0) begin
                    counter_r <= counter_r - 1'b1;
                end else begin
                    // 超时处理
                    if (int_en && !wd_int_o) begin
                        wd_int_o <= 1'b1;
                    end
                    
                    if (reset_en) begin
                        if (reset_pulse_cnt_r < RESET_DELAY) begin
                            wd_reset_o <= 1'b1;
                            reset_pulse_cnt_r <= reset_pulse_cnt_r + 1'b1;
                        end else begin
                            wd_reset_o <= 1'b0;
                            reset_pulse_cnt_r <= 0;
                            // 重置计数器
                            counter_r <= load_value_r;
                        end
                    end else begin
                        // 没有使能复位，重新加载计数器
                        counter_r <= load_value_r;
                    end
                end
            end else begin
                // 看门狗禁用，保持计数器值
                counter_r <= load_value_r;
            end
        end
    end
    
    // 输出当前计数值
    always @(*) begin
        wd_value_o = counter_r;
    end
    
endmodule
```

### 3.5 软件接口

```c
// 看门狗基地址定义
#define WD_BASE_ADDR 0x90000000

// 寄存器定义
#define WD_LOAD       (WD_BASE_ADDR + 0x00)
#define WD_VALUE      (WD_BASE_ADDR + 0x04)
#define WD_CTRL       (WD_BASE_ADDR + 0x08)
#define WD_INT_CLEAR  (WD_BASE_ADDR + 0x0C)

// 控制位定义
#define WD_ENABLE     (1 << 0)
#define WD_INT_EN     (1 << 1)
#define WD_RESET_EN   (1 << 2)

// 初始化看门狗
void wd_init(uint32_t timeout, int enable_int, int enable_reset) {
    volatile uint32_t *load_reg = (volatile uint32_t *)WD_LOAD;
    volatile uint32_t *ctrl_reg = (volatile uint32_t *)WD_CTRL;
    uint32_t ctrl = 0;
    
    // 设置超时时间
    *load_reg = timeout;
    
    // 配置控制寄存器
    ctrl |= WD_ENABLE;
    if (enable_int) ctrl |= WD_INT_EN;
    if (enable_reset) ctrl |= WD_RESET_EN;
    
    *ctrl_reg = ctrl;
}

// 喂狗(重置计数器)
void wd_feed(void) {
    volatile uint32_t *load_reg = (volatile uint32_t *)WD_LOAD;
    volatile uint32_t *value_reg = (volatile uint32_t *)WD_VALUE;
    uint32_t current_load = *value_reg; // 读取当前加载值
    
    *load_reg = current_load;
}

// 禁用看门狗
void wd_disable(void) {
    volatile uint32_t *ctrl_reg = (volatile uint32_t *)WD_CTRL;
    *ctrl_reg = 0;
}

// 清除看门狗中断
void wd_clear_int(void) {
    volatile uint32_t *clear_reg = (volatile uint32_t *)WD_INT_CLEAR;
    *clear_reg = 1; // 写入任意值清除中断
}

// 获取看门狗当前计数值
uint32_t wd_get_value(void) {
    volatile uint32_t *value_reg = (volatile uint32_t *)WD_VALUE;
    return *value_reg;
}
```

## 4. 集成说明

### 4.1 与peri_bridge.v的集成

需要在peri_bridge.v中添加以下修改：

1. 定义新的内存地址：
```verilog
`define MEM_PWM_ADDR        32'h70000000  // PWM基地址
`define MEM_WATCHDOG_ADDR   32'h90000000  // 看门狗基地址
```

2. 添加PWM和看门狗的接口信号

3. 在地址译码逻辑中添加对新外设的支持

### 4.2 与SOC顶层模块的集成

需要在minisys_soc.v中添加以下修改：

1. 实例化PWM和看门狗模块

2. 连接peri_bridge与新外设的接口

3. 处理看门狗的复位输出

## 5. 测试方案

### 5.1 PWM测试

1. 初始化PWM通道0，设置周期为1000，占空比为500
2. 观察PWM输出波形，验证占空比是否为50%
3. 动态修改占空比为250，观察波形变化
4. 测试极性反转功能
5. 测试多通道同时工作

### 5.2 看门狗测试

1. 初始化看门狗，设置较短的超时时间(如1000个时钟周期)
2. 使能中断和复位功能
3. 不喂狗，观察是否产生中断
4. 清除中断，继续运行
5. 再次不喂狗，观察是否产生系统复位
6. 重新初始化，使能中断但禁用复位
7. 不喂狗，观察中断是否产生，但系统不复位
8. 测试喂狗功能，验证计数器重置

## 6. 总结

本设计方案提供了MiniSys RISC-V SOC的外设扩展实现，包括PWM控制器和看门狗。这些扩展外设遵循现有的内存映射I/O架构，并与现有外设保持一致的接口规范，确保了系统的可扩展性和兼容性。

通过这些扩展，MiniSys RISC-V SOC将具备更丰富的外设功能，能够满足更多嵌入式应用的需求。