// ALU 操作码定义 (4位编码)
// 这些操作码用于控制ALU执行何种运算

`define ALU_NONE                  4'b0000  // 无操作
`define ALU_SHIFTL                4'b0001  // 逻辑左移 (<<)
`define ALU_SHIFTR                4'b0010  // 逻辑右移 (>>u)
`define ALU_SHIFTR_ARITH          4'b0011  // 算术右移 (>>s, 符号扩展)
`define ALU_ADD                   4'b0100  // 加法
`define ALU_SUB                   4'b0101  // 减法
`define ALU_AND                   4'b0110  // 按位与
`define ALU_OR                    4'b0111  // 按位或
`define ALU_XOR                   4'b1000  // 按位异或
`define ALU_LESS_THAN             4'b1001  // 无符号小于比较
`define ALU_LESS_THAN_SIGNED      4'b1010  // 有符号小于比较

// RV32I
// ----------------------------------------------------------------------------
// U-type 指令 (高位立即数)
// ----------------------------------------------------------------------------
// 格式: imm[31:12] | rd[11:7] | opcode[6:0]

// LUI - Load Upper Immediate
// 功能: x[rd] = imm << 12
// 用途: 加载高20位立即数到寄存器
`define INST_LUI                  32'b00000000000000000000000000110111
`define MASK_LUI                  32'b00000000000000000000000001111111


// AUIPC - Add Upper Immediate to PC
// 功能: x[rd] = pc + (imm << 12)
// 用途: PC相对寻址，常用于位置无关代码
`define INST_AUIPC                32'b00000000000000000000000000010111
`define MASK_AUIPC                32'b00000000000000000000000001111111

// ----------------------------------------------------------------------------
// J-type 指令 (无条件跳转)
// ----------------------------------------------------------------------------
// 格式: imm[20|10:1|11|19:12] | rd[11:7] | opcode[6:0]

// JAL - Jump and Link
// 功能: x[rd] = pc + 4; pc += imm
// 用途: 函数调用（rd=ra）或长跳转（rd=x0）
`define INST_JAL                  32'b00000000000000000000000001101111
`define MASK_JAL                  32'b00000000000000000000000001111111

// ----------------------------------------------------------------------------
// I-type 指令 (跳转)
// ----------------------------------------------------------------------------

// JALR - Jump and Link Register
// 功能: x[rd] = pc + 4; pc = (x[rs1] + imm) & ~1
// 用途: 间接跳转、函数返回（rs1=ra, rd=x0）
`define INST_JALR                 32'b00000000000000000000000001100111
`define MASK_JALR                 32'b00000000000000000111000001111111


// ----------------------------------------------------------------------------
// B-type 指令 (条件分支)
// ----------------------------------------------------------------------------
// 格式: imm[12|10:5] | rs2 | rs1 | funct3 | imm[4:1|11] | opcode
// 所有分支的跳转偏移是有符号数，以2字节为单位

// BEQ - Branch if Equal
// 功能: if (x[rs1] == x[rs2]) pc += imm
`define INST_BEQ                  32'b00000000000000000000000001100011
`define MASK_BEQ                  32'b00000000000000000111000001111111

// BNE - Branch if Not Equal
// 功能: if (x[rs1] != x[rs2]) pc += imm
`define INST_BNE                  32'b00000000000000000001000001100011
`define MASK_BNE                  32'b00000000000000000111000001111111

// BLT - Branch if Less Than (signed)
// 功能: if (x[rs1] <s x[rs2]) pc += imm
`define INST_BLT                  32'b00000000000000000100000001100011
`define MASK_BLT                  32'b00000000000000000111000001111111

// BGE - Branch if Greater or Equal (signed)
// 功能: if (x[rs1] ≥s x[rs2]) pc += imm
`define INST_BGE                  32'b00000000000000000101000001100011
`define MASK_BGE                  32'b00000000000000000111000001111111

// BLTU - Branch if Less Than (unsigned)
// 功能: if (x[rs1] <u x[rs2]) pc += imm
`define INST_BLTU                 32'b00000000000000000110000001100011
`define MASK_BLTU                 32'b00000000000000000111000001111111

// BGEU - Branch if Greater or Equal (unsigned)
// 功能: if (x[rs1] ≥u x[rs2]) pc += imm
`define INST_BGEU                 32'b00000000000000000111000001100011
`define MASK_BGEU                 32'b00000000000000000111000001111111


// ----------------------------------------------------------------------------
// I-type 指令 (加载 Load)
// ----------------------------------------------------------------------------
// 格式: imm[11:0] | rs1 | funct3 | rd | opcode
// 地址计算: addr = x[rs1] + sign_extend(imm)

// LB - Load Byte (sign-extended)
// 功能: x[rd] = sign_extend(M[addr][7:0])
`define INST_LB                   32'b00000000000000000000000000000011
`define MASK_LB                   32'b00000000000000000111000001111111

// LH - Load Halfword (sign-extended)
// 功能: x[rd] = sign_extend(M[addr][15:0])
`define INST_LH                   32'b00000000000000000001000000000011
`define MASK_LH                   32'b00000000000000000111000001111111

// LW - Load Word
// 功能: x[rd] = M[addr][31:0]
`define INST_LW                   32'b00000000000000000010000000000011
`define MASK_LW                   32'b00000000000000000111000001111111

// LBU - Load Byte Unsigned (zero-extended)
// 功能: x[rd] = zero_extend(M[addr][7:0])
`define INST_LBU                  32'b00000000000000000100000000000011
`define MASK_LBU                  32'b00000000000000000111000001111111

// LHU - Load Halfword Unsigned (zero-extended)
// 功能: x[rd] = zero_extend(M[addr][15:0])
`define INST_LHU                  32'b00000000000000000101000000000011
`define MASK_LHU                  32'b00000000000000000111000001111111

// ----------------------------------------------------------------------------
// S-type 指令 (存储 Store)
// ----------------------------------------------------------------------------
// 格式: imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode
// 地址计算: addr = x[rs1] + sign_extend(imm)

// SB - Store Byte
// 功能: M[addr][7:0] = x[rs2][7:0]
`define INST_SB                   32'b00000000000000000000000000100011
`define MASK_SB                   32'b00000000000000000111000001111111

// SH - Store Halfword
// 功能: M[addr][15:0] = x[rs2][15:0]
`define INST_SH                   32'b00000000000000000001000000100011
`define MASK_SH                   32'b00000000000000000111000001111111

// SW - Store Word
// 功能: M[addr][31:0] = x[rs2][31:0]
`define INST_SW                   32'b00000000000000000010000000100011
`define MASK_SW                   32'b00000000000000000111000001111111


// ----------------------------------------------------------------------------
// I-type 指令 (立即数算术运算)
// ----------------------------------------------------------------------------

// ADDI - Add Immediate
// 功能: x[rd] = x[rs1] + sign_extend(imm)
// 注意: ADDI x0, x0, 0 是NOP指令
`define INST_ADDI                 32'b00000000000000000000000000010011
`define MASK_ADDI                 32'b00000000000000000111000001111111

// SLTI - Set Less Than Immediate (signed)
// 功能: x[rd] = (x[rs1] <s imm) ? 1 : 0
`define INST_SLTI                 32'b00000000000000000010000000010011
`define MASK_SLTI                 32'b00000000000000000111000001111111

// SLTIU - Set Less Than Immediate Unsigned
// 功能: x[rd] = (x[rs1] <u imm) ? 1 : 0
// 注意: 用于判断x[rs1]是否为0 (SLTIU rd, rs1, 1)
`define INST_SLTIU                32'b00000000000000000011000000010011
`define MASK_SLTIU                32'b00000000000000000111000001111111

// XORI - XOR Immediate
// 功能: x[rd] = x[rs1] ^ sign_extend(imm)
// 注意: XORI rd, rs1, -1 是NOT指令
`define INST_XORI                 32'b00000000000000000100000000010011
`define MASK_XORI                 32'b00000000000000000111000001111111

// ORI - OR Immediate
// 功能: x[rd] = x[rs1] | sign_extend(imm)
`define INST_ORI                  32'b00000000000000000110000000010011
`define MASK_ORI                  32'b00000000000000000111000001111111

// ANDI - AND Immediate
// 功能: x[rd] = x[rs1] & sign_extend(imm)
`define INST_ANDI                 32'b00000000000000000111000000010011
`define MASK_ANDI                 32'b00000000000000000111000001111111


// ----------------------------------------------------------------------------
// I-type 指令 (移位操作，特殊编码)
// ----------------------------------------------------------------------------
// 格式: funct7 | shamt[4:0] | rs1 | funct3 | rd | opcode
// shamt: 移位量，0-31

// SLLI - Shift Left Logical Immediate
// 功能: x[rd] = x[rs1] << shamt
`define INST_SLLI                 32'b00000000000000000001000000010011
`define MASK_SLLI                 32'b11111110000000000111000001111111

// SRLI - Shift Right Logical Immediate
// 功能: x[rd] = x[rs1] >>u shamt (逻辑右移，高位补0)
`define INST_SRLI                 32'b00000000000000000101000000010011
`define MASK_SRLI                 32'b11111110000000000111000001111111

// SRAI - Shift Right Arithmetic Immediate
// 功能: x[rd] = x[rs1] >>s shamt (算术右移，符号扩展)
`define INST_SRAI                 32'b01000000000000000101000000010011
`define MASK_SRAI                 32'b11111110000000000111000001111111


// ----------------------------------------------------------------------------
// R-type 指令 (寄存器间运算)
// ----------------------------------------------------------------------------
// 格式: funct7 | rs2 | rs1 | funct3 | rd | opcode

// ADD - Add
// 功能: x[rd] = x[rs1] + x[rs2]
`define INST_ADD                  32'b00000000000000000000000000110011
`define MASK_ADD                  32'b11111110000000000111000001111111

// SUB - Subtract
// 功能: x[rd] = x[rs1] - x[rs2]
`define INST_SUB                  32'b01000000000000000000000000110011
`define MASK_SUB                  32'b11111110000000000111000001111111

// SLL - Shift Left Logical
// 功能: x[rd] = x[rs1] << x[rs2][4:0]
`define INST_SLL                  32'b00000000000000000001000000110011
`define MASK_SLL                  32'b11111110000000000111000001111111

// SLT - Set Less Than (signed)
// 功能: x[rd] = (x[rs1] <s x[rs2]) ? 1 : 0
`define INST_SLT                  32'b00000000000000000010000000110011
`define MASK_SLT                  32'b11111110000000000111000001111111

// SLTU - Set Less Than Unsigned
// 功能: x[rd] = (x[rs1] <u x[rs2]) ? 1 : 0
`define INST_SLTU                 32'b00000000000000000011000000110011
`define MASK_SLTU                 32'b11111110000000000111000001111111

// XOR - XOR
// 功能: x[rd] = x[rs1] ^ x[rs2]
`define INST_XOR                  32'b00000000000000000100000000110011
`define MASK_XOR                  32'b11111110000000000111000001111111

// SRL - Shift Right Logical
// 功能: x[rd] = x[rs1] >>u x[rs2][4:0]
`define INST_SRL                  32'b00000000000000000101000000110011
`define MASK_SRL                  32'b11111110000000000111000001111111

// SRA - Shift Right Arithmetic
// 功能: x[rd] = x[rs1] >>s x[rs2][4:0]
`define INST_SRA                  32'b01000000000000000101000000110011
`define MASK_SRA                  32'b11111110000000000111000001111111

// OR - OR
// 功能: x[rd] = x[rs1] | x[rs2]
`define INST_OR                   32'b00000000000000000110000000110011
`define MASK_OR                   32'b11111110000000000111000001111111

// AND - AND
// 功能: x[rd] = x[rs1] & x[rs2]
`define INST_AND                  32'b00000000000000000111000000110011
`define MASK_AND                  32'b11111110000000000111000001111111


// ----------------------------------------------------------------------------
// 内存屏障和同步指令
// ----------------------------------------------------------------------------

// FENCE - Fence Memory and I/O
// 功能: 保证内存访问顺序
`define INST_FENCE                32'b00000000000000000000000000001111
`define MASK_FENCE                32'b00000000000000000111000001111111

// PAUSE - Pause Hint
// 功能: 提示处理器可以降低功耗（在自旋锁中使用）
`define INST_PAUSE                32'b00000001000000000000000000001111
`define MASK_PAUSE                32'b11111111111111111111111111111111

// ============================================================================
// RV32M 乘除法扩展
// ============================================================================
// 所有乘除法指令都是R-type格式
// funct7=0000001 标识M扩展指令

// MUL - Multiply (取低32位)
// 功能: x[rd] = (x[rs1] * x[rs2])[31:0]
`define INST_MUL                  32'b00000010000000000000000000110011
`define MASK_MUL                  32'b11111110000000000111000001111111

// MULH - Multiply High (signed × signed，取高32位)
// 功能: x[rd] = (x[rs1] *s x[rs2])[63:32]
`define INST_MULH                 32'b00000010000000000001000000110011
`define MASK_MULH                 32'b11111110000000000111000001111111

// MULHSU - Multiply High (signed × unsigned，取高32位)
// 功能: x[rd] = (x[rs1]_signed * x[rs2]_unsigned)[63:32]
`define INST_MULHSU               32'b00000010000000000010000000110011
`define MASK_MULHSU               32'b11111110000000000111000001111111

// MULHU - Multiply High (unsigned × unsigned，取高32位)
// 功能: x[rd] = (x[rs1] *u x[rs2])[63:32]
`define INST_MULHU                32'b00000010000000000011000000110011
`define MASK_MULHU                32'b11111110000000000111000001111111

// DIV - Divide (signed)
// 功能: x[rd] = x[rs1] ÷s x[rs2]
// 注意: 除0结果为-1，溢出(最小值÷-1)结果为最小值
`define INST_DIV                  32'b00000010000000000100000000110011
`define MASK_DIV                  32'b11111110000000000111000001111111

// DIVU - Divide (unsigned)
// 功能: x[rd] = x[rs1] ÷u x[rs2]
// 注意: 除0结果为2^32-1
`define INST_DIVU                 32'b00000010000000000101000000110011
`define MASK_DIVU                 32'b11111110000000000111000001111111

// REM - Remainder (signed)
// 功能: x[rd] = x[rs1] %s x[rs2]
// 注意: 除0结果为被除数，溢出结果为0
`define INST_REM                  32'b00000010000000000110000000110011
`define MASK_REM                  32'b11111110000000000111000001111111

// REMU - Remainder (unsigned)
// 功能: x[rd] = x[rs1] %u x[rs2]
// 注意: 除0结果为被除数
`define INST_REMU                 32'b00000010000000000111000000110011
`define MASK_REMU                 32'b11111110000000000111000001111111

// ============================================================================
// RV32Zicsr 控制状态寄存器扩展
// ============================================================================
// CSR指令格式: csr[31:20] | rs1/uimm[19:15] | funct3[14:12] | rd[11:7] | opcode

// CSRRW - CSR Read and Write
// 功能: t=CSR[csr]; CSR[csr]=x[rs1]; x[rd]=t
`define INST_CSRRW                32'b00000000000000000001000001110011
`define MASK_CSRRW                32'b00000000000000000111000001111111

// CSRRS - CSR Read and Set
// 功能: t=CSR[csr]; CSR[csr]=t|x[rs1]; x[rd]=t
`define INST_CSRRS                32'b00000000000000000010000001110011
`define MASK_CSRRS                32'b00000000000000000111000001111111

// CSRRC - CSR Read and Clear
// 功能: t=CSR[csr]; CSR[csr]=t&~x[rs1]; x[rd]=t
`define INST_CSRRC                32'b00000000000000000011000001110011
`define MASK_CSRRC                32'b00000000000000000111000001111111

// CSRRWI - CSR Read and Write Immediate
// 功能: x[rd]=CSR[csr]; CSR[csr]=zero_extend(uimm)
`define INST_CSRRWI               32'b00000000000000000101000001110011
`define MASK_CSRRWI               32'b00000000000000000111000001111111

// CSRRSI - CSR Read and Set Immediate
// 功能: t=CSR[csr]; CSR[csr]=t|zero_extend(uimm); x[rd]=t
`define INST_CSRRSI               32'b00000000000000000110000001110011
`define MASK_CSRRSI               32'b00000000000000000111000001111111

// CSRRCI - CSR Read and Clear Immediate
// 功能: t=CSR[csr]; CSR[csr]=t&~zero_extend(uimm); x[rd]=t
`define INST_CSRRCI               32'b00000000000000000111000001110011
`define MASK_CSRRCI               32'b00000000000000000111000001111111

// ============================================================================
// RV32 特权指令
// ============================================================================

// ECALL - Environment Call
// 功能: 触发环境调用异常
// 用途: 系统调用（从U模式到S模式，或从S模式到M模式）
`define INST_ECALL                32'b00000000000000000000000001110011
`define MASK_ECALL                32'b11111111111111111111111111111111

// EBREAK - Environment Break
// 功能: 触发断点异常
// 用途: 调试器设置断点
`define INST_EBREAK               32'b00000000000100000000000001110011
`define MASK_EBREAK               32'b11111111111111111111111111111111

// MRET - Machine-mode Return
// 功能: 从机器模式陷阱返回
// 操作: pc=mepc; 恢复mstatus中的中断使能位
`define INST_MRET                 32'b00110000001000000000000001110011
`define MASK_MRET                 32'b11111111111111111111111111111111

// ============================================================================
// CSR 寄存器地址定义
// ============================================================================
// CSR地址为12位，[11:10]表示特权级别
`define CSR_MHARTID               32'hf14  // Hardware thread ID (只读)

// Machine Trap Setup
`define CSR_MSTATUS               32'h300  // Machine status register
`define CSR_MISA                  32'h301  // ISA and extensions (只读)
`define CSR_MIE                   32'h304  // Machine interrupt-enable register
`define CSR_MTVEC                 32'h305  // Machine trap-handler base address

// Machine Trap Handling
`define CSR_MSCRATCH              32'h340  // Scratch register for trap handlers
`define CSR_MEPC                  32'h341  // Machine exception program counter
`define CSR_MCAUSE                32'h342  // Machine trap cause
`define CSR_MTVAL                 32'h343  // Machine bad address or instruction
`define CSR_MIP                   32'h344  // Machine interrupt pending

// Machine Counter/Timers
`define CSR_MCYCLE                32'hb00  // Machine cycle counter
`define CSR_MINSTRET              32'hb02  // Machine instructions-retired counter
