## 模块概述

**核心职责**：
1. **CSR读写指令**：CSRRW, CSRRS, CSRRC及立即数版本（CSRRWI, CSRRSI, CSRRCI）
2. **特权指令**：ECALL, EBREAK, MRET
3. **异常处理**：保存异常现场（mepc, mcause），跳转到mtvec
4. **中断处理**：定时器中断（支持嵌入式系统）
5. **特权级管理**：仅支持Machine mode（M-mode）

## 支持的指令集

### **Zicsr扩展（CSR读写指令）**

| 指令 | 格式 | 操作 | 详细说明 |
|------|------|------|---------|
| **CSRRW** | `csrrw rd, csr, rs1` | `t=CSR[csr]; CSR[csr]=rs1; rd=t` | 原子交换：将CSR的值读到rd，同时将rs1写入CSR |
| **CSRRS** | `csrrs rd, csr, rs1` | `t=CSR[csr]; CSR[csr]=t\|rs1; rd=t` | 原子置位：读CSR到rd，将CSR中rs1为1的位置位 |
| **CSRRC** | `csrrc rd, csr, rs1` | `t=CSR[csr]; CSR[csr]=t&~rs1; rd=t` | 原子清零：读CSR到rd，将CSR中rs1为1的位清零 |
| **CSRRWI** | `csrrwi rd, csr, uimm` | `t=CSR[csr]; CSR[csr]=uimm; rd=t` | 立即数交换：rs1替换为5位无符号立即数（零扩展） |
| **CSRRSI** | `csrrsi rd, csr, uimm` | `t=CSR[csr]; CSR[csr]=t\|uimm; rd=t` | 立即数置位：rs1替换为5位无符号立即数 |
| **CSRRCI** | `csrrci rd, csr, uimm` | `t=CSR[csr]; CSR[csr]=t&~uimm; rd=t` | 立即数清零：rs1替换为5位无符号立即数 |

**指令编码**：
```
CSR指令格式 (I-type):
  31        20 19    15 14   12 11    7 6      0
  +----------+--------+-------+--------+--------+
  |   csr    |   rs1  | funct3|   rd   | opcode |
  | (12位)   | (5位)  | (3位) | (5位)  | 1110011|
  +----------+--------+-------+--------+--------+

funct3编码：
  001: CSRRW    101: CSRRWI
  010: CSRRS    110: CSRRSI
  011: CSRRC    111: CSRRCI
```

### **特权指令**

| 指令 | 格式 | 功能 | 详细说明 |
|------|------|------|---------|
| **ECALL** | `ecall` | 环境调用 | 触发环境调用异常，用于系统调用（syscall）<br>• 保存PC到mepc<br>• 设置mcause=11<br>• 跳转到mtvec<br>• 禁用中断（MIE=0） |
| **EBREAK** | `ebreak` | 断点 | 触发断点异常，用于调试器<br>• 保存PC到mepc<br>• 设置mcause=3<br>• 跳转到mtvec<br>• 禁用中断（MIE=0） |
| **MRET** | `mret` | 异常返回 | 从M-mode异常/中断返回<br>• 从mepc恢复PC<br>• 恢复中断使能（MIE=1）<br>• 继续执行 |

**指令编码**：
```
特权指令格式：
  31                    20 19    15 14   12 11    7 6      0
  +----------------------+--------+-------+--------+--------+
  |      funct12         | rs1(0) | func3 | rd(0)  | opcode |
  +----------------------+--------+-------+--------+--------+
                                    000              1110011

funct12编码：
  000000000000: ECALL
  000000000001: EBREAK
  001100000010: MRET
```

### **中断处理**

| 中断类型 | 触发条件 | 处理流程 |
|---------|---------|---------|
| **定时器中断** | `timer_interrupt_i=1` <br> `mie[7]=1` (定时器中断使能) <br> `mstatus[3]=1` (全局中断使能) | • 保存PC到mepc（考虑分支延迟）<br>• 设置mcause=0x80000007<br>• 跳转到mtvec<br>• 禁用中断（MIE=0） |

**中断优先级**：当前实现仅支持定时器中断，无优先级仲裁。

## 关键设计特点

### **特殊时钟边沿**

最特别的设计：**使用negedge clk_i**！

```verilog
always @(negedge clk_i or posedge rst_i) begin
```

**设计理由**：
- 避免同一周期CSR读写冲突
- 给CSR操作更多时间稳定
- 与其他模块的posedge错开

## 关键CSR寄存器

| 寄存器 | 地址 | 功能 |
|--------|------|------|
| mhartid | 0xF14 | 硬件线程ID（只读）|
| mstatus | 0x300 | 机器状态寄存器 |
| misa | 0x301 | ISA支持（只读）|
| mie | 0x304 | 中断使能 |
| mtvec | 0x305 | 异常向量基址 |
| mscratch | 0x340 | 临时寄存器 |
| mepc | 0x341 | 异常PC |
| mcause | 0x342 | 异常原因 |
| mtval | 0x343 | 异常值 |
| mip | 0x344 | 中断待处理 |
| mcycle | 0xB00 | 周期计数器 |
| minstret | 0xB02 | 指令计数器 |

## 核心代码框架（基于实际代码）

### **模块接口（第3-16行）**

```verilog
module minisys_csr (
    input        clk_i,
    input        rst_i,
    input [31:0] pc_i,                      // 当前PC
    input [31:0] ex_mem_pc_branch_i,        // EX/MEM阶段的分支目标
    input        ex_mem_pc_take_branch_i,   // EX/MEM阶段是否发生分支
    input [31:0] inst_i,                    // CSR指令
    input [31:0] rs1_data_i,                // 源寄存器数据
    input        timer_interrupt_i,         // 定时器中断信号
    
    output [31:0] rd_data_o,                // CSR读取数据
    output        branch_o,                 // 触发跳转（异常/中断/MRET）
    output        interrupt_o               // 中断发生标志
);
```

**关键输入**：
- `ex_mem_pc_branch_i/ex_mem_pc_take_branch_i`：用于中断时正确保存PC（考虑分支延迟槽）

### **CSR寄存器定义（第17-36行）**

```verilog
  reg  [31:0] mhartid_r;     // 硬件线程ID
  reg  [31:0] mstatus_r;     // 机器状态寄存器
  wire [31:0] misa_w = 32'b01_0000_00000000000001000100000000;
  //                      ||                      | |  |
  //                      ||                      | |  +-- I (RV32I基础指令集)
  //                      ||                      | +----- C (压缩指令，预留)
  //                      ||                      +------- M (乘除法扩展)
  //                      |+----------------------------- MXL=01 (XLEN=32)
  
  reg  [31:0] mie_r;         // 中断使能寄存器
  reg  [31:0] mtvec_r;       // 异常向量基址
  reg  [31:0] mscratch_r;    // 临时寄存器（软件使用）
  reg  [31:0] mepc_r;        // 异常程序计数器
  reg  [31:0] mcause_r;      // 异常原因
  reg  [31:0] mtval_r;       // 异常值（地址或数据）
  reg  [31:0] mip_r;         // 中断待处理
  reg  [31:0] mcycle_r;      // 周期计数器（简化为32位）
  reg  [31:0] minstret_r;    // 指令退休计数器（简化为32位）
  
  reg  [31:0] pc_r;          // 保存的PC（用于检测PC变化）
  reg  [31:0] rd_data_r;     // CSR读取结果
  reg         branch_r;      // 分支触发标志
  reg         interrupt_r;   // 中断触发标志
```

**注意**：
- `misa_w` 是常量，只读
- `pc_r` 用于检测PC是否更新，避免重复处理同一指令

### **指令识别（第41-75行）**

```verilog
  // Zicsr扩展指令检测
  wire zicsr_w = (( inst_i & `MASK_CSRRW  ) == `INST_CSRRW  ) ||
                 (( inst_i & `MASK_CSRRS  ) == `INST_CSRRS  ) ||
                 (( inst_i & `MASK_CSRRC  ) == `INST_CSRRC  ) ||
                 (( inst_i & `MASK_CSRRWI ) == `INST_CSRRWI ) ||
                 (( inst_i & `MASK_CSRRSI ) == `INST_CSRRSI ) ||
                 (( inst_i & `MASK_CSRRCI ) == `INST_CSRRCI );

  // 特权指令检测
  wire priv_inst_w = ((inst_i & `MASK_ECALL  ) == `INST_ECALL  ) ||
                     ((inst_i & `MASK_EBREAK ) == `INST_EBREAK ) ||
                     ((inst_i & `MASK_MRET   ) == `INST_MRET   );

  // 立即数版本检测（使用uimm代替rs1）
  wire imm_u_enable_w = (( inst_i & `MASK_CSRRWI ) == `INST_CSRRWI ) ||
                        (( inst_i & `MASK_CSRRSI ) == `INST_CSRRSI ) ||
                        (( inst_i & `MASK_CSRRCI ) == `INST_CSRRCI );

  // CSR操作类型
  wire csr_write_w = (( inst_i & `MASK_CSRRW  ) == `INST_CSRRW  ) ||
                     (( inst_i & `MASK_CSRRWI ) == `INST_CSRRWI );

  wire csr_set_w = (( inst_i & `MASK_CSRRS  ) == `INST_CSRRS  ) ||
                   (( inst_i & `MASK_CSRRSI ) == `INST_CSRRSI );

  wire csr_clear_w = (( inst_i & `MASK_CSRRC  ) == `INST_CSRRC  ) ||
                     (( inst_i & `MASK_CSRRCI ) == `INST_CSRRCI );

  // 单独识别特权指令
  wire ecall_w  = ((inst_i & `MASK_ECALL ) == `INST_ECALL );
  wire ebreak_w = ((inst_i & `MASK_EBREAK) == `INST_EBREAK);
  wire mret_w   = ((inst_i & `MASK_MRET  ) == `INST_MRET  );

  // 提取CSR地址和立即数
  wire [11:0] csr_addr_w = inst_i[31:20];
  wire [31:0] imm_w = {27'b0, inst_i[19:15]};  // uimm零扩展

  // 数据源选择：立即数或寄存器
  wire [31:0] rs_data_w = imm_u_enable_w ? imm_w : rs1_data_i;
```

**设计亮点**：
- 使用组合逻辑识别指令类型，避免多个 if-else
- `rs_data_w` 统一处理立即数和寄存器数据源

### **核心状态机（第77-219行）**

这是整个CSR模块最关键的部分，使用**negedge时钟**：

```verilog
  always @(negedge clk_i or posedge rst_i) begin
    if (pc_r == pc_i) begin
      // PC未变化，说明是同一条指令，不处理（避免重复）
      ;
    end else begin
      // PC变化了，处理新指令
      branch_r    <= 1'b0;        // 清除分支标志
      interrupt_r <= 1'b0;        // 清除中断标志
      pc_r        <= pc_i;        // 更新保存的PC
      
      mip_r[7]    <= timer_interrupt_i;  // 更新定时器中断待处理标志
      
      if (rst_i) begin
        // 复位初始化（第87-99行）
        mhartid_r  <= 32'h0;
        mstatus_r  <= {19'b0, 2'b11, 11'b0};  // MPP=11(M-mode)
        mie_r      <= 32'h0;
        mtvec_r    <= 32'h1;                   // 异常向量地址
        mscratch_r <= 32'h0;
        mepc_r     <= 32'h0;
        mcause_r   <= 32'h0;
        mtval_r    <= 32'h0;
        mip_r      <= 32'h0;
        mcycle_r   <= 64'h0;
        minstret_r <= 64'h0;
        rd_data_r  <= 32'h0;
      end else if (zicsr_w) begin
        // CSR指令处理
        ...
      end else if (priv_inst_w) begin
        // 特权指令处理（ECALL/EBREAK/MRET）
        ...
      end else if (pc_i != 32'h0) begin
        // 定时器中断处理
        ...
      end
    end
  end
```

**关键设计点**：
1. **PC检测**：`if (pc_r == pc_i)` 避免同一指令被重复处理
2. **negedge触发**：与其他模块的posedge错开，避免冲突
3. **四种处理路径**：复位 → CSR指令 → 特权指令 → 中断

## 🔍 关键设计解析

### **1. CSR读写操作（第100-182行）**

#### **CSR读取（第101-115行）**

**原子性保证**：所有CSR指令都是原子操作，读和写在同一个negedge周期完成。

```verilog
if (zicsr_w) begin  // 检测到任意CSR指令（CSRRW/CSRRS/CSRRC及立即数版本）
  case (csr_addr_w)  // 根据CSR地址（inst[31:20]）选择寄存器
    // ========== 机器信息寄存器（只读）==========
    `CSR_MHARTID:  rd_data_r <= mhartid_r;   // 0xF14: 硬件线程ID
    `CSR_MISA:     rd_data_r <= misa_w;      // 0x301: ISA扩展信息（wire常量）
    
    // ========== 机器陷阱设置寄存器 ==========
    `CSR_MSTATUS:  rd_data_r <= mstatus_r;   // 0x300: 机器状态（MIE, MPIE等）
    `CSR_MIE:      rd_data_r <= mie_r;       // 0x304: 中断使能（bit7=定时器）
    `CSR_MTVEC:    rd_data_r <= mtvec_r;     // 0x305: 异常向量基址
    
    // ========== 机器陷阱处理寄存器 ==========
    `CSR_MSCRATCH: rd_data_r <= mscratch_r;  // 0x340: 临时寄存器（软件自由使用）
    `CSR_MEPC:     rd_data_r <= mepc_r;      // 0x341: 异常程序计数器（保存的PC）
    `CSR_MCAUSE:   rd_data_r <= mcause_r;    // 0x342: 异常原因码
    `CSR_MTVAL:    rd_data_r <= mtval_r;     // 0x343: 异常相关值（地址/数据）
    `CSR_MIP:      rd_data_r <= mip_r;       // 0x344: 中断待处理（bit7=定时器）
    
    // ========== 机器计数器寄存器 ==========
    `CSR_MCYCLE:   rd_data_r <= mcycle_r[31:0];    // 0xB00: 周期计数器低32位
    `CSR_MINSTRET: rd_data_r <= minstret_r[31:0];  // 0xB02: 指令退休计数器低32位
    
    default:       rd_data_r <= 32'h0;  // 未实现的CSR返回0
  endcase
```

**读取时机**：
- 在所有CSR指令中，读操作**总是先执行**
- `rd_data_r` 保存读到的值，用于写回目标寄存器 `rd`
- 即使是 CSRRW（写入指令），也先读再写

#### **CSRRW/CSRRWI - 写入操作（第117-132行）**

**指令语义**：
- **CSRRW**：`rd = CSR[csr]; CSR[csr] = rs1;` （原子交换）
- **CSRRWI**：`rd = CSR[csr]; CSR[csr] = uimm;` （立即数交换）

```verilog
if (csr_write_w) begin  // csr_write_w = CSRRW || CSRRWI
  case (csr_addr_w)
    `CSR_MSTATUS: begin
      // mstatus特殊处理：只允许修改MIE(bit3)和MPIE(bit7)，其他位固定
      mstatus_r <= {19'b0, 2'b11, 3'b0, rs_data_w[7], 3'b0, rs_data_w[3], 3'b0};
      //            ^^^^^  ^^^^^  ^^^^  ^^^^^^^^^^^^  ^^^^  ^^^^^^^^^^^^  ^^^^
      //            保留   MPP=11 保留  MPIE(bit7)    保留  MIE(bit3)     保留
      //                   (M-mode)     从rs_data_w取       从rs_data_w取
      
      // 为何固定MPP=11？
      // 当前实现仅支持M-mode，MPP（进入异常前的特权级）永远是M-mode
    end
    
    // ========== 中断/异常配置寄存器（可完全写入）==========
    `CSR_MIE:      mie_r <= rs_data_w;       // 0x304: 中断使能，直接写入rs/uimm
    `CSR_MTVEC:    mtvec_r <= rs_data_w;     // 0x305: 异常向量基址
    `CSR_MSCRATCH: mscratch_r <= rs_data_w;  // 0x340: 临时寄存器
    
    // ========== 异常处理寄存器（软件可写入用于调试）==========
    `CSR_MEPC:     mepc_r <= rs_data_w;      // 0x341: 异常PC（可手动修改返回地址）
    `CSR_MCAUSE:   mcause_r <= rs_data_w;    // 0x342: 异常原因
    `CSR_MTVAL:    mtval_r <= rs_data_w;     // 0x343: 异常值
    
    // ========== 性能计数器（可写入用于重置）==========
    `CSR_MCYCLE:   mcycle_r <= rs_data_w;    // 0xB00: 周期计数器（可清零）
    `CSR_MINSTRET: minstret_r <= rs_data_w;  // 0xB02: 指令计数器（可清零）
    
    // 注意：MHARTID和MISA是只读寄存器，无写入case（硬件忽略）
  endcase
end
```

**关键点**：
1. **rs_data_w**：统一的数据源
   - CSRRW：`rs_data_w = rs1_data_i`（寄存器值）
   - CSRRWI：`rs_data_w = {27'b0, inst[19:15]}`（立即数零扩展）
2. **完全替换**：CSR的值被完全替换为 `rs_data_w`
3. **只读寄存器保护**：MHARTID、MISA没有写入case，硬件自动忽略写入

#### **CSRRS/CSRRSI - 按位置位（第134-157行）**

**指令语义**：
- **CSRRS**：`rd = CSR[csr]; CSR[csr] |= rs1;` （按位或，置位）
- **CSRRSI**：`rd = CSR[csr]; CSR[csr] |= uimm;` （立即数置位）

**使用场景**：选择性地将某些位设置为1，而不影响其他位。

```verilog
if (csr_set_w) begin  // csr_set_w = CSRRS || CSRRSI
  case (csr_addr_w)
    `CSR_MSTATUS: begin
      // mstatus按位置位：rs_data_w中为1的位被置位，为0的位保持不变
      mstatus_r <= {
        19'b0,                        // 保留位：固定为0
        2'b11,                        // MPP：固定为M-mode
        3'b0,                         // 保留位
        mstatus_r[7] | rs_data_w[7],  // MPIE |= rs_data_w[7] (bit7置位)
        3'b0,                         // 保留位
        mstatus_r[3] | rs_data_w[3],  // MIE |= rs_data_w[3]  (bit3置位)
        3'b0                          // 保留位
      };
      
      // 示例：如果rs1=0x00000008 (bit3=1)，则只将MIE置位，MPIE不变
    end
    
    // ========== 其他CSR：直接按位或 ==========
    `CSR_MIE:      mie_r <= mie_r | rs_data_w;       // 使能某些中断
    `CSR_MTVEC:    mtvec_r <= mtvec_r | rs_data_w;   
    `CSR_MSCRATCH: mscratch_r <= mscratch_r | rs_data_w;
    `CSR_MEPC:     mepc_r <= mepc_r | rs_data_w;
    `CSR_MCAUSE:   mcause_r <= mcause_r | rs_data_w;
    `CSR_MTVAL:    mtval_r <= mtval_r | rs_data_w;
    `CSR_MCYCLE:   mcycle_r <= mcycle_r | rs_data_w;
    `CSR_MINSTRET: minstret_r <= minstret_r | rs_data_w;
  endcase
end
```

**典型用法**：
```assembly
# 使能全局中断（MIE=1）
csrrsi zero, mstatus, 0x08  # 将mstatus的bit3置1，其他位不变

# 使能定时器中断
li t0, 0x80                 # bit7=1（定时器中断）
csrrs zero, mie, t0         # 将mie的bit7置1
```

#### **CSRRC/CSRRCI - 按位清零（第159-182行）**

**指令语义**：
- **CSRRC**：`rd = CSR[csr]; CSR[csr] &= ~rs1;` （按位与非，清零）
- **CSRRCI**：`rd = CSR[csr]; CSR[csr] &= ~uimm;` （立即数清零）

**使用场景**：选择性地将某些位清零，而不影响其他位。

```verilog
if (csr_clear_w) begin  // csr_clear_w = CSRRC || CSRRCI
  case (csr_addr_w)
    `CSR_MSTATUS: begin
      // mstatus按位清零：rs_data_w中为1的位被清零，为0的位保持不变
      mstatus_r <= {
        19'b0,                         // 保留位：固定为0
        2'b11,                         // MPP：固定为M-mode
        3'b0,                          // 保留位
        mstatus_r[7] & ~rs_data_w[7],  // MPIE &= ~rs_data_w[7] (bit7清零)
        3'b0,                          // 保留位
        mstatus_r[3] & ~rs_data_w[3],  // MIE &= ~rs_data_w[3]  (bit3清零)
        3'b0                           // 保留位
      };
      
      // 示例：如果rs1=0x00000008 (bit3=1)，则只将MIE清零，MPIE不变
      // 逻辑：mstatus[3] = mstatus[3] & ~0x08 = mstatus[3] & 0 = 0
    end
    
    // ========== 其他CSR：直接按位与非 ==========
    `CSR_MIE:      mie_r <= mie_r & ~rs_data_w;       // 禁用某些中断
    `CSR_MTVEC:    mtvec_r <= mtvec_r & ~rs_data_w;   
    `CSR_MSCRATCH: mscratch_r <= mscratch_r & ~rs_data_w;
    `CSR_MEPC:     mepc_r <= mepc_r & ~rs_data_w;
    `CSR_MCAUSE:   mcause_r <= mcause_r & ~rs_data_w;
    `CSR_MTVAL:    mtval_r <= mtval_r & ~rs_data_w;
    `CSR_MCYCLE:   mcycle_r <= mcycle_r & ~rs_data_w;
    `CSR_MINSTRET: minstret_r <= minstret_r & ~rs_data_w;
  endcase
end
```

**典型用法**：
```assembly
# 禁用全局中断（MIE=0）
csrrci zero, mstatus, 0x08  # 将mstatus的bit3清零，其他位不变

# 禁用定时器中断
li t0, 0x80                 # bit7=1（定时器中断）
csrrc zero, mie, t0         # 将mie的bit7清零
```

**三种操作对比**：

| 操作 | 指令 | 行为 | 用途 |
|------|------|------|------|
| **写入** | CSRRW/CSRRWI | `CSR = rs1` | 完全替换CSR值 |
| **置位** | CSRRS/CSRRSI | `CSR \|= rs1` | 将某些位置1 |
| **清零** | CSRRC/CSRRCI | `CSR &= ~rs1` | 将某些位清0 |

**示例对比**（假设 mstatus初始值=0x00000000）：
```assembly
csrrw t0, mstatus, 0x88  # mstatus = 0x00000088 (完全替换)
csrrs t0, mstatus, 0x08  # mstatus = 0x00000088 | 0x08 = 0x88 (bit3置位)
csrrc t0, mstatus, 0x80  # mstatus = 0x00000088 & ~0x80 = 0x08 (bit7清零)
```

### **2. 特权指令处理（第183-202行）**

#### **ECALL - 环境调用（第184-190行）**

**用途**：触发软件系统调用（syscall），从用户态请求操作系统服务。

```verilog
else if (priv_inst_w) begin  // 检测到特权指令（ECALL/EBREAK/MRET）
  if (ecall_w && mstatus_r[3]) begin  // ECALL指令 且 中断使能（防止在异常处理中再次触发）
    
    // ========== 步骤1：保存当前状态 ==========
    mstatus_r <= {19'b0, 2'b11, 3'b0, mstatus_r[3], 3'b0, 1'b0, 3'b0};
    //            保留   MPP=11 保留   ^^^^^^^^^^^^  保留   ^^^^  保留
    //                   (M-mode)      保存MIE到MPIE        清除MIE
    // 关键操作：
    // 1. MPIE ← MIE (保存进入异常前的中断使能状态)
    // 2. MIE ← 0    (禁用中断，防止异常处理被中断)
    
    // ========== 步骤2：记录异常信息 ==========
    mcause_r  <= {1'd0, 31'd11};  // 异常码11：Environment call from M-mode
    //            ^^^^  ^^^^^^^
    //            bit31=0  异常码=11（ECALL from M-mode）
    //            (0=异常, 1=中断)
    
    mepc_r    <= pc_i;            // 保存触发ECALL的指令地址（返回时会跳到这里）
    mtval_r   <= 32'b0;           // 异常值：ECALL不涉及错误地址/数据，设为0
    
    // ========== 步骤3：跳转到异常处理程序 ==========
    rd_data_r <= mtvec_r;         // 将mtvec（异常向量基址）作为跳转目标
    branch_r  <= 1'b1;            // 触发分支跳转信号（通知流水线跳转）
  end
```

**ECALL处理流程图**：
```
1. 用户程序执行 ECALL
   ↓
2. 硬件自动：
   • 保存 PC → mepc         (保存返回地址)
   • 保存 MIE → MPIE        (保存中断状态)
   • 清除 MIE = 0           (禁用中断)
   • 设置 mcause = 11       (记录异常类型)
   • 跳转到 mtvec           (进入异常处理程序)
   ↓
3. 异常处理程序执行 (软件)
   • 根据 mcause 判断异常类型
   • 执行相应的系统调用处理
   ↓
4. 执行 MRET 返回
   • 从 mepc 恢复 PC
   • 恢复 MIE = 1
   • 继续执行用户程序
```

#### **EBREAK - 断点（第191-197行）**

**用途**：触发调试断点，用于调试器设置断点和单步调试。

```verilog
else if (ebreak_w && mstatus_r[3]) begin  // EBREAK指令 且 中断使能
  
  // ========== 与ECALL处理完全相同，只是异常码不同 ==========
  mstatus_r <= {19'b0, 2'b11, 3'b0, mstatus_r[3], 3'b0, 1'b0, 3'b0};
  //            保存MIE到MPIE，清除MIE（禁用中断）
  
  mcause_r  <= {1'd0, 31'd3};    // 异常码3：Breakpoint (断点异常)
  //            ^^^^  ^^^^^
  //            异常   码=3
  
  mepc_r    <= pc_i;             // 保存断点指令地址
  mtval_r   <= 32'b0;            // 断点异常不需要额外信息
  rd_data_r <= mtvec_r;          // 跳转到异常处理程序
  branch_r  <= 1'b1;             // 触发跳转
end
```

**EBREAK vs ECALL**：

| 特性 | ECALL | EBREAK |
|------|-------|--------|
| **用途** | 系统调用（syscall） | 调试断点 |
| **mcause** | 11 | 3 |
| **典型场景** | 用户程序请求OS服务 | 调试器设置断点 |
| **处理流程** | 完全相同（硬件层面） | 完全相同（硬件层面） |
| **软件处理** | 执行系统调用 | 通知调试器 |

**使用示例**：
```assembly
# 调试器在某行设置断点
0x1000: add  x1, x2, x3    # 原指令
        ↓ (调试器替换)
0x1000: ebreak             # 插入断点指令

# 执行到此处时：
# 1. 触发EBREAK异常
# 2. 跳转到异常处理程序
# 3. 异常处理程序通知调试器：断点触发
# 4. 调试器暂停程序，显示状态
```

#### **MRET - 异常返回（第198-202行）**

**用途**：从M-mode异常/中断返回，恢复到异常发生前的执行状态。

```verilog
else if (mret_w) begin  // MRET指令
  
  // ========== 步骤1：恢复中断使能 ==========
  mstatus_r <= {19'b0, 2'b11, 3'b0, 1'b1, 3'b0, mstatus_r[7], 3'b0};
  //            保留   MPP=11 保留   ^^^^  保留   ^^^^^^^^^^^^  保留
  //                           MIE=1         保持MPIE不变（或丢弃）
  
  // 简化设计：直接设置MIE=1（而非标准的MIE←MPIE）
  // 原因：当前不支持嵌套异常，进入异常时MIE总是0，返回时总是恢复为1
  
  // ========== 步骤2：返回到异常发生点 ==========
  rd_data_r <= mepc_r;    // 将mepc（保存的PC）作为跳转目标
  branch_r  <= 1'b1;      // 触发跳转信号
  
  // 注意：PC实际更新由流水线控制器根据rd_data_r和branch_r完成
end
```

**标准RISC-V规范 vs 当前实现**：

| 操作 | 标准规范 | 当前实现 | 影响 |
|------|---------|---------|------|
| **MIE恢复** | `MIE ← MPIE` | `MIE ← 1` (固定) | 不支持嵌套异常 |
| **MPIE更新** | `MPIE ← 1` | 丢弃（保持不变） | 无影响（单层异常） |
| **MPP更新** | `MPP ← U/S` | 保持M-mode | 仅支持M-mode |

**为何简化**：
- 当前CPU只有M-mode，无用户态
- 异常/中断不可嵌套（进入异常后MIE=0）
- MRET返回时必定恢复到正常执行（MIE=1）
- 简化逻辑，降低硬件复杂度

**MRET执行流程**：
```
1. 异常处理程序执行完毕
   ↓
2. 执行 MRET 指令
   • MIE ← 1             (恢复中断使能)
   • PC ← mepc           (返回到异常发生点)
   ↓
3. 继续执行用户程序（从异常点之后的指令开始）
```

### **3. 定时器中断处理（第203-217行）**

**触发时机**：在执行任意指令时，如果定时器中断条件满足，立即保存现场并跳转到中断处理程序。

```verilog
else if (pc_i != 32'h0) begin  // 排除PC=0（复位/无效状态）
  
  // ========== 中断触发条件检查（三个条件同时满足）==========
  if (timer_interrupt_i && mstatus_r[3] && mie_r[7]) begin
    //  ^^^^^^^^^^^^^^^^    ^^^^^^^^^^^^^    ^^^^^^^^
    //  条件1:外部定时器     条件2:全局使能    条件3:定时器使能
    //  中断信号拉高         MIE=1            mie[7]=1
    
    // ========== 步骤1：标记中断发生 ==========
    interrupt_r <= 1'b1;   // 输出中断发生信号（供流水线控制器使用）
    
    // ========== 步骤2：保存当前状态 ==========
    mstatus_r   <= {19'b0, 2'b11, 3'b0, mstatus_r[3], 3'b0, 1'b0, 3'b0};
    //              保留   MPP=11 保留   ^^^^^^^^^^^^  保留   ^^^^  保留
    //                             保存MIE到MPIE       清除MIE
    // 与异常处理相同：保存中断使能状态，禁用新中断
    
    // ========== 步骤3：记录中断信息 ==========
    mcause_r    <= {1'd1, 31'd7};  // 中断原因码
    //              ^^^^  ^^^^^^^
    //              bit31=1       中断码=7（Machine Timer Interrupt）
    //              (表示中断)    
    
    // ========== 步骤4：保存PC（关键！考虑流水线分支延迟）==========
    // 问题：中断可能发生在分支指令执行过程中
    // - 如果IF阶段在取分支指令，但EX/MEM阶段已经计算出要跳转
    // - 此时中断到来，应该保存分支目标地址，而不是分支指令地址
    
    if (ex_mem_pc_take_branch_i) begin
      mepc_r <= ex_mem_pc_branch_i;  // 情况1：流水线中有分支发生
      //        ^^^^^^^^^^^^^^^^^^^^    保存分支目标地址（即将跳转的地址）
      // 示例：BEQ指令判断为真，准备跳到0x2000，此时中断到来
      //      应该保存0x2000，返回后继续从0x2000执行
    end else begin
      mepc_r <= pc_i;                 // 情况2：无分支
      //        ^^^^                    保存当前PC
    end
    
    mtval_r   <= 32'b0;              // 中断不涉及错误地址/数据
    
    // ========== 步骤5：跳转到中断处理程序 ==========
    rd_data_r <= mtvec_r;            // 将中断向量地址作为跳转目标
    branch_r  <= 1'b1;               // 触发分支跳转
  end
end
```

**中断触发条件详解**：

| 条件 | 信号 | 含义 | 控制方式 |
|------|------|------|---------|
| **条件1** | `timer_interrupt_i` | 外部定时器中断请求 | 硬件定时器产生 |
| **条件2** | `mstatus_r[3]` (MIE) | 全局中断使能 | `csrrsi/csrrci mstatus` |
| **条件3** | `mie_r[7]` | 定时器中断使能 | `csrrs/csrrc mie` |

**三者关系**：
- **条件1**：外部事件（硬件）
- **条件2**：全局开关（软件可关闭所有中断）
- **条件3**：单个中断开关（软件可选择性禁用定时器中断）

**PC保存策略图解**：

```
场景1：无分支，正常指令序列
  IF:  0x1000 (ADD)  ← pc_i = 0x1000
  ID:  ...
  EX:  ...           ← 中断到来，ex_mem_pc_take_branch_i = 0
  结果：mepc = 0x1000 (正确)

场景2：有分支指令，且将要跳转
  IF:  0x1000 (BEQ)  ← pc_i = 0x1000
  ID:  ...
  EX:  比较结果=真    ← 中断到来
       准备跳转到0x2000  ex_mem_pc_take_branch_i = 1
       ex_mem_pc_branch_i = 0x2000
  结果：mepc = 0x2000 (正确！保存了分支目标)
  
  如果保存pc_i=0x1000：
    - MRET返回后会重新执行BEQ
    - 分支判断可能已经不成立（数据变化）
    - 程序行为错误！
```

**mcause编码**：
```
0x80000007 = {1'b1, 31'd7}
             ^^^^  ^^^^^^^
             中断   定时器中断码

bit[31] = 1: 表示中断（与异常区分）
bit[30:0] = 7: Machine Timer Interrupt
```

**中断处理完整流程**：
```
1. 定时器产生中断信号 (timer_interrupt_i=1)
   ↓
2. 硬件检查中断使能条件 (MIE=1 && mie[7]=1)
   ↓
3. 保存现场：
   • mepc ← PC (考虑分支延迟)
   • MPIE ← MIE
   • MIE ← 0
   • mcause ← 0x80000007
   ↓
4. 跳转到 mtvec (中断处理程序入口)
   ↓
5. 中断处理程序执行 (软件)
   • 保存寄存器到栈
   • 处理定时器中断（如时间片轮转、定时任务等）
   • 恢复寄存器
   ↓
6. 执行 MRET 返回
   • PC ← mepc
   • MIE ← 1
   ↓
7. 继续执行被中断的程序
```

### **4. mstatus寄存器结构**

```
31            13 12 11  8 7  4 3  0
+-------------+--+-----+----+----+
|    保留     |MP|WPRI |MPIE|MIE |
|   (19位)    |P | (3) |(1) |(1) |
+-------------+--+-----+----+----+
             ^^         ^    ^
             ||         |    +--- MIE (bit 3): 全局中断使能
             ||         +-------- MPIE (bit 7): 进入异常前的MIE（用于MRET恢复）
             |+------------------ MPP (bit 12-11): 进入异常前的特权级
             +------------------- 固定为11 (M-mode)
```

**实际代码中的mstatus格式**：
```verilog
mstatus_r = {19'b0, 2'b11, 3'b0, MPIE, 3'b0, MIE, 3'b0};
```

## 📊 mcause异常/中断码

### **异常码（bit[31]=0）**

| 值 | 异常类型 | 实际使用 |
|----|---------|---------|
| 0 | 指令地址不对齐 | 未实现 |
| 1 | 指令访问错误 | 未实现 |
| 2 | 非法指令 | 未实现 |
| 3 | 断点 (EBREAK) | ✅ 已实现 |
| 11 | 环境调用 (ECALL) | ✅ 已实现 |

### **中断码（bit[31]=1）**

| 值 | 中断类型 | 实际使用 |
|----|---------|---------|
| 0x80000007 | 机器定时器中断 | ✅ 已实现 |

**编码规则**：
- `mcause[31] = 0`：异常
- `mcause[31] = 1`：中断
- `mcause[30:0]`：异常/中断具体码

## 🎓 深入理解

### **Q1: 为什么使用 negedge 而不是 posedge？**

**实际代码使用**：`always @(negedge clk_i or posedge rst_i)`

**设计原因**：
1. **时序分离**：避免与其他模块（寄存器文件、ALU等）在同一 posedge 竞争
2. **读写原子性**：CSR读和写在同一指令周期完成，negedge 提供更好的时序裕量
3. **简化设计**：不需要额外的前递逻辑

**现代设计趋势**：
- 通常使用 posedge + 前递网络
- negedge 方案在教学和原型中较常见
- 实际ASIC设计中较少使用（因为时钟树负担）

### **Q2: PC检测机制 `if (pc_r == pc_i)` 的作用？**

```verilog
always @(negedge clk_i or posedge rst_i) begin
  if (pc_r == pc_i) begin
    ; // PC未变化，不处理（同一条指令）
  end else begin
    // PC变化了，处理新指令
    pc_r <= pc_i;
    // ... CSR操作
  end
end
```

**作用**：
- 避免同一条CSR指令被重复处理
- negedge 触发可能在同一PC上触发多次
- 通过比较 `pc_r`（保存的PC）和 `pc_i`（当前PC）来检测是否是新指令

### **Q3: 为什么中断要保存分支目标地址？**

```verilog
if (ex_mem_pc_take_branch_i) begin
  mepc_r <= ex_mem_pc_branch_i;  // 保存分支目标
end else begin
  mepc_r <= pc_i;                 // 保存当前PC
end
```

**原因**：
- 中断可能发生在**分支指令执行过程中**
- 如果 EX/MEM 阶段已经确定要跳转，但中断先触发
- 需要保存**分支目标地址**而不是当前PC
- 否则 MRET 返回后会丢失分支结果

**示例**：
```
IF: BEQ x1, x2, target  ← pc_i 指向这里
ID: ...
EX: 比较结果为真，准备跳转  ← ex_mem_pc_take_branch_i = 1
                           ← 此时定时器中断到来
```
应该保存 `target` 而不是 `BEQ` 的地址。

### **Q4: MRET 为何直接设置 MIE=1？**

**标准RISC-V规范**：`MIE <= MPIE`（从MPIE恢复）

**实际代码**：
```verilog
mstatus_r <= {19'b0, 2'b11, 3'b0, 1'b1, 3'b0, mstatus_r[7], 3'b0};
//                              ^^^^
//                              直接设置为1，未使用MPIE
```

**简化原因**：
- 当前实现不支持嵌套中断/异常
- 进入异常时总是禁用中断（`MIE=0`）
- 返回时总是恢复为使能（`MIE=1`）
- 简化了设计，适合教学和简单应用

**标准实现应该**：
```verilog
mstatus_r <= {19'b0, 2'b11, 3'b0, mstatus_r[7], 3'b0, mstatus_r[7], 3'b0};
//                              ^^^^^^^^^^^^         ^^^^^^^^^^^^
//                              MIE = MPIE           保持MPIE不变
```

## 💡 实现总结

### **实际代码特点**

1. **negedge时钟**：与主流水线的posedge错开
2. **PC检测机制**：避免重复处理同一指令
3. **分支感知中断**：正确保存分支目标地址
4. **简化的MRET**：直接恢复MIE=1，适合非嵌套场景
5. **32位计数器**：`mcycle` 和 `minstret` 简化为32位

### **支持的功能**

✅ **已实现**：
- 6条CSR读写指令（CSRRW/CSRRS/CSRRC及立即数版本）
- 3条特权指令（ECALL/EBREAK/MRET）
- 定时器中断处理
- M-mode特权级
- 12个M-mode CSR寄存器

❌ **未实现**：
- U-mode/S-mode特权级
- 其他异常（非法指令、地址不对齐等）
- 嵌套中断
- 64位计数器

### **关键设计亮点**

| 特性 | 实现方式 | 优势 |
|------|---------|------|
| **原子CSR操作** | negedge统一处理读写 | 简化时序，无需前递 |
| **PC变化检测** | `if (pc_r == pc_i)` | 避免重复处理 |
| **分支感知中断** | 检查`ex_mem_pc_take_branch_i` | 正确保存PC |
| **指令识别** | 组合逻辑wire | 清晰，易于扩展 |

## ➡️ 下一步

CSR模块完成！现在CPU支持异常和中断处理，具备完整的M-mode特权级功能。

接下来：**[BUILD_GUIDE_10_PIPELINE.md](BUILD_GUIDE_10_PIPELINE.md)** - 流水线控制器

流水线控制器是CPU的核心，将把所有模块串联起来，处理数据冒险和控制冒险。
