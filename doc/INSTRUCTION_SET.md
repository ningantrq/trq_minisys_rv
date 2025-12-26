# minisys-rv 指令集完整列表

## RV32I 基础整数指令集

### R-type 指令格式
```
31      25 24   20 19   15 14   12 11    7 6      0
funct7    rs2     rs1     funct3  rd      opcode
```

| 指令  | funct7  | rs2 | rs1 | funct3 | rd  | opcode  | 功能描述                        |
|-------|---------|-----|-----|--------|-----|---------|--------------------------------|
| ADD   | 0000000 | rs2 | rs1 | 000    | rd  | 0110011 | x[rd] = x[rs1] + x[rs2]        |
| SUB   | 0100000 | rs2 | rs1 | 000    | rd  | 0110011 | x[rd] = x[rs1] - x[rs2]        |
| SLL   | 0000000 | rs2 | rs1 | 001    | rd  | 0110011 | x[rd] = x[rs1] << x[rs2]       |
| SLT   | 0000000 | rs2 | rs1 | 010    | rd  | 0110011 | x[rd] = (x[rs1] <s x[rs2]) ? 1 : 0 |
| SLTU  | 0000000 | rs2 | rs1 | 011    | rd  | 0110011 | x[rd] = (x[rs1] <u x[rs2]) ? 1 : 0 |
| XOR   | 0000000 | rs2 | rs1 | 100    | rd  | 0110011 | x[rd] = x[rs1] ^ x[rs2]        |
| SRL   | 0000000 | rs2 | rs1 | 101    | rd  | 0110011 | x[rd] = x[rs1] >>u x[rs2]      |
| SRA   | 0100000 | rs2 | rs1 | 101    | rd  | 0110011 | x[rd] = x[rs1] >>s x[rs2]      |
| OR    | 0000000 | rs2 | rs1 | 110    | rd  | 0110011 | x[rd] = x[rs1] \| x[rs2]       |
| AND   | 0000000 | rs2 | rs1 | 111    | rd  | 0110011 | x[rd] = x[rs1] & x[rs2]        |

### I-type 指令格式（算术/逻辑）
```
31          20 19   15 14   12 11    7 6      0
imm[11:0]      rs1     funct3  rd      opcode
```

| 指令  | imm[11:0] | rs1 | funct3 | rd  | opcode  | 功能描述                        |
|-------|-----------|-----|--------|-----|---------|--------------------------------|
| ADDI  | imm       | rs1 | 000    | rd  | 0010011 | x[rd] = x[rs1] + sext(imm)     |
| SLTI  | imm       | rs1 | 010    | rd  | 0010011 | x[rd] = (x[rs1] <s sext(imm)) ? 1 : 0 |
| SLTIU | imm       | rs1 | 011    | rd  | 0010011 | x[rd] = (x[rs1] <u sext(imm)) ? 1 : 0 |
| XORI  | imm       | rs1 | 100    | rd  | 0010011 | x[rd] = x[rs1] ^ sext(imm)     |
| ORI   | imm       | rs1 | 110    | rd  | 0010011 | x[rd] = x[rs1] \| sext(imm)    |
| ANDI  | imm       | rs1 | 111    | rd  | 0010011 | x[rd] = x[rs1] & sext(imm)     |

### I-type 指令格式（移位）
```
31      25 24   20 19   15 14   12 11    7 6      0
funct7    shamt   rs1     funct3  rd      opcode
```

| 指令  | funct7  | shamt   | rs1 | funct3 | rd  | opcode  | 功能描述                        |
|-------|---------|---------|-----|--------|-----|---------|--------------------------------|
| SLLI  | 0000000 | shamt   | rs1 | 001    | rd  | 0010011 | x[rd] = x[rs1] << shamt        |
| SRLI  | 0000000 | shamt   | rs1 | 101    | rd  | 0010011 | x[rd] = x[rs1] >>u shamt       |
| SRAI  | 0100000 | shamt   | rs1 | 101    | rd  | 0010011 | x[rd] = x[rs1] >>s shamt       |

### I-type 指令格式（加载）
```
31          20 19   15 14   12 11    7 6      0
imm[11:0]      rs1     funct3  rd      opcode
```

| 指令  | imm[11:0] | rs1 | funct3 | rd  | opcode  | 功能描述                        |
|-------|-----------|-----|--------|-----|---------|--------------------------------|
| LB    | offset    | rs1 | 000    | rd  | 0000011 | x[rd] = sext(M[x[rs1] + sext(offset)][7:0]) |
| LH    | offset    | rs1 | 001    | rd  | 0000011 | x[rd] = sext(M[x[rs1] + sext(offset)][15:0]) |
| LW    | offset    | rs1 | 010    | rd  | 0000011 | x[rd] = M[x[rs1] + sext(offset)][31:0] |
| LBU   | offset    | rs1 | 100    | rd  | 0000011 | x[rd] = zext(M[x[rs1] + sext(offset)][7:0]) |
| LHU   | offset    | rs1 | 101    | rd  | 0000011 | x[rd] = zext(M[x[rs1] + sext(offset)][15:0]) |

### I-type 指令格式（跳转）
```
31          20 19   15 14   12 11    7 6      0
imm[11:0]      rs1     funct3  rd      opcode
```

| 指令  | imm[11:0] | rs1 | funct3 | rd  | opcode  | 功能描述                        |
|-------|-----------|-----|--------|-----|---------|--------------------------------|
| JALR  | offset    | rs1 | 000    | rd  | 1100111 | x[rd] = pc+4; pc = (x[rs1] + sext(offset)) & ~1 |

### S-type 指令格式
```
31      25 24   20 19   15 14   12 11       7 6      0
imm[11:5]  rs2     rs1     funct3  imm[4:0]  opcode
```

| 指令  | imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode  | 功能描述                        |
|-------|-----------|-----|-----|--------|----------|---------|--------------------------------|
| SB    | offset[11:5] | rs2 | rs1 | 000 | offset[4:0] | 0100011 | M[x[rs1] + sext(offset)][7:0] = x[rs2][7:0] |
| SH    | offset[11:5] | rs2 | rs1 | 001 | offset[4:0] | 0100011 | M[x[rs1] + sext(offset)][15:0] = x[rs2][15:0] |
| SW    | offset[11:5] | rs2 | rs1 | 010 | offset[4:0] | 0100011 | M[x[rs1] + sext(offset)][31:0] = x[rs2][31:0] |

### B-type 指令格式
```
31   30      25 24   20 19   15 14   12 11   8 7   6      0
imm[12|10:5]   rs2     rs1     funct3  imm[4:1|11] opcode
```

| 指令  | imm[12] | imm[10:5] | rs2 | rs1 | funct3 | imm[4:1] | imm[11] | opcode  | 功能描述 |
|-------|---------|-----------|-----|-----|--------|----------|---------|---------|----------|
| BEQ   | offset[12] | offset[10:5] | rs2 | rs1 | 000 | offset[4:1] | offset[11] | 1100011 | if (x[rs1] == x[rs2]) pc += sext(offset) |
| BNE   | offset[12] | offset[10:5] | rs2 | rs1 | 001 | offset[4:1] | offset[11] | 1100011 | if (x[rs1] != x[rs2]) pc += sext(offset) |
| BLT   | offset[12] | offset[10:5] | rs2 | rs1 | 100 | offset[4:1] | offset[11] | 1100011 | if (x[rs1] <s x[rs2]) pc += sext(offset) |
| BGE   | offset[12] | offset[10:5] | rs2 | rs1 | 101 | offset[4:1] | offset[11] | 1100011 | if (x[rs1] ≥s x[rs2]) pc += sext(offset) |
| BLTU  | offset[12] | offset[10:5] | rs2 | rs1 | 110 | offset[4:1] | offset[11] | 1100011 | if (x[rs1] <u x[rs2]) pc += sext(offset) |
| BGEU  | offset[12] | offset[10:5] | rs2 | rs1 | 111 | offset[4:1] | offset[11] | 1100011 | if (x[rs1] ≥u x[rs2]) pc += sext(offset) |

### U-type 指令格式
```
31                    12 11    7 6      0
imm[31:12]               rd      opcode
```

| 指令   | imm[31:12] | rd  | opcode  | 功能描述                        |
|--------|------------|-----|---------|--------------------------------|
| LUI    | imm        | rd  | 0110111 | x[rd] = sext(imm[31:12] << 12) |
| AUIPC  | imm        | rd  | 0010111 | x[rd] = pc + sext(imm[31:12] << 12) |

### J-type 指令格式
```
31   30       21 20   19        12 11    7 6      0
imm[20|10:1|11|19:12]              rd      opcode
```

| 指令  | imm[20] | imm[10:1] | imm[11] | imm[19:12] | rd  | opcode  | 功能描述 |
|-------|---------|-----------|---------|------------|-----|---------|----------|
| JAL   | offset[20] | offset[10:1] | offset[11] | offset[19:12] | rd | 1101111 | x[rd] = pc+4; pc += sext(offset) |

### I-type 其他指令
```
31          20 19   15 14   12 11    7 6      0
特殊编码       rs1     funct3  rd      opcode
```

| 指令   | 编码 | 功能描述 |
|--------|------|----------|
| FENCE  | 0000xxxx xxxx 00000 000 00000 0001111 | 内存屏障指令 |
| PAUSE  | 0000 0001 0000 00000 000 00000 0001111 | 暂停提示指令 |

---

## RV32M 乘除法扩展

### R-type 指令格式
```
31      25 24   20 19   15 14   12 11    7 6      0
funct7    rs2     rs1     funct3  rd      opcode
```

| 指令    | funct7  | rs2 | rs1 | funct3 | rd  | opcode  | 功能描述                        |
|---------|---------|-----|-----|--------|-----|---------|--------------------------------|
| MUL     | 0000001 | rs2 | rs1 | 000    | rd  | 0110011 | x[rd] = (x[rs1] × x[rs2])[31:0] |
| MULH    | 0000001 | rs2 | rs1 | 001    | rd  | 0110011 | x[rd] = (x[rs1] ×s x[rs2])[63:32] |
| MULHSU  | 0000001 | rs2 | rs1 | 010    | rd  | 0110011 | x[rd] = (x[rs1]s × x[rs2]u)[63:32] |
| MULHU   | 0000001 | rs2 | rs1 | 011    | rd  | 0110011 | x[rd] = (x[rs1] ×u x[rs2])[63:32] |
| DIV     | 0000001 | rs2 | rs1 | 100    | rd  | 0110011 | x[rd] = x[rs1] ÷s x[rs2]       |
| DIVU    | 0000001 | rs2 | rs1 | 101    | rd  | 0110011 | x[rd] = x[rs1] ÷u x[rs2]       |
| REM     | 0000001 | rs2 | rs1 | 110    | rd  | 0110011 | x[rd] = x[rs1] %s x[rs2]       |
| REMU    | 0000001 | rs2 | rs1 | 111    | rd  | 0110011 | x[rd] = x[rs1] %u x[rs2]       |

---

## RV32Zicsr 控制状态寄存器扩展

### I-type CSR 指令格式
```
31          20 19   15 14   12 11    7 6      0
csr            rs1     funct3  rd      opcode
```

| 指令    | csr    | rs1 | funct3 | rd  | opcode  | 功能描述                        |
|---------|--------|-----|--------|-----|---------|--------------------------------|
| CSRRW   | csr    | rs1 | 001    | rd  | 1110011 | t = CSRs[csr]; CSRs[csr] = x[rs1]; x[rd] = t |
| CSRRS   | csr    | rs1 | 010    | rd  | 1110011 | t = CSRs[csr]; CSRs[csr] = t \| x[rs1]; x[rd] = t |
| CSRRC   | csr    | rs1 | 011    | rd  | 1110011 | t = CSRs[csr]; CSRs[csr] = t & ~x[rs1]; x[rd] = t |
| CSRRWI  | csr    | uimm| 101    | rd  | 1110011 | x[rd] = CSRs[csr]; CSRs[csr] = zext(uimm) |
| CSRRSI  | csr    | uimm| 110    | rd  | 1110011 | t = CSRs[csr]; CSRs[csr] = t \| zext(uimm); x[rd] = t |
| CSRRCI  | csr    | uimm| 111    | rd  | 1110011 | t = CSRs[csr]; CSRs[csr] = t & ~zext(uimm); x[rd] = t |

### 支持的CSR寄存器

| CSR地址 | CSR名称   | 功能描述           |
|---------|-----------|-------------------|
| 0xF14   | mhartid   | 硬件线程ID        |
| 0x300   | mstatus   | 机器状态寄存器     |
| 0x301   | misa      | ISA和扩展          |
| 0x304   | mie       | 机器中断使能       |
| 0x305   | mtvec     | 机器陷阱向量基址   |
| 0x340   | mscratch  | 机器临时寄存器     |
| 0x341   | mepc      | 机器异常PC        |
| 0x342   | mcause    | 机器异常原因       |
| 0x343   | mtval     | 机器陷阱值        |
| 0x344   | mip       | 机器中断挂起       |
| 0xB00   | mcycle    | 机器周期计数器     |
| 0xB02   | minstret  | 机器指令计数器     |

---

## RV32 特权指令

### 特殊格式指令
```
31                                    0
固定编码
```

| 指令    | 完整编码（32位） | 功能描述 |
|---------|-----------------|----------|
| ECALL   | 0000 0000 0000 0 0000 000 0000 0 1110011 | 环境调用，触发陷阱到操作系统 |
| EBREAK  | 0000 0000 0001 0 0000 000 0000 0 1110011 | 断点，触发调试器 |
| MRET    | 0011 0000 0010 0 0000 000 0000 0 1110011 | 从机器模式陷阱返回 |

---

## 符号说明

- **x[rs1], x[rs2], x[rd]**: 通用寄存器
- **sext(x)**: 符号扩展
- **zext(x)**: 零扩展
- **M[addr]**: 内存地址
- **pc**: 程序计数器
- **CSRs[csr]**: 控制状态寄存器
- **<<u**: 逻辑左移
- **>>u**: 逻辑右移
- **>>s**: 算术右移
- **<s**: 有符号小于比较
- **<u**: 无符号小于比较
- **≥s**: 有符号大于等于比较
- **≥u**: 无符号大于等于比较
- **×s**: 有符号乘法
- **×u**: 无符号乘法
- **÷s**: 有符号除法
- **÷u**: 无符号除法
- **%s**: 有符号取余
- **%u**: 无符号取余

---

## 总结

- **RV32I**: 37条基础指令
- **RV32M**: 8条乘除法指令
- **RV32Zicsr**: 6条CSR操作指令
- **特权指令**: 3条系统指令
- **总计**: 54条指令

**注意**: 本工程已实现RV32I/M/Zicsr除异常与中断外的所有指令。
