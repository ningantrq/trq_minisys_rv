# M mode / U mode 特权级测试程序

## 功能概述

本测试程序用于验证 TRQ MiniSys RISC-V CPU 的 M mode (Machine mode) 和 U mode (User mode) 特权级支持功能。

## 测试内容

### 1. M mode 初始状态验证
- 验证系统复位后处于 M mode
- 读取 mstatus 寄存器确认 MPP 位

### 2. CSR 寄存器读写测试
- 读取 mhartid, misa, mstatus, mcycle 等寄存器
- 测试 mscratch 寄存器的读写功能

### 3. Trap Handler 配置
- 设置 mtvec 指向 trap_entry 处理函数
- 配置异常/中断处理机制

### 4. M mode → U mode 切换
- 通过 MRET 指令从 M mode 切换到 U mode
- 设置 mstatus.MPP = 0 (U mode)
- 设置 mepc 为 U mode 代码入口

### 5. U mode → M mode 切换
- 在 U mode 下执行 ECALL 指令
- 触发 Environment Call from U-mode 异常 (mcause = 8)
- Trap handler 处理后返回 M mode

## 可见效果

### UART 输出 (9600 baud, 8N1)
- 详细的测试步骤和结果信息
- CSR 寄存器值
- Trap 信息 (mcause, mepc, mstatus)

### LED 显示
- **M mode**: LED[3:0] 亮 (pattern = 0x0F)
- **U mode**: LED[7:4] 亮 (pattern = 0xF0)
- **测试完成**: LED 交替闪烁 (0xAA ↔ 0x55)

## 文件说明

| 文件 | 说明 |
|------|------|
| `main.c` | 主程序，包含测试逻辑和 trap handler |
| `trap.S` | 汇编 trap 入口和 U mode 切换函数 |
| `csr.h` | CSR 寄存器定义和操作宏 |
| `uart.c/h` | UART 驱动 |
| `led.h` | LED 驱动 |
| `link.ld` | 链接脚本 |
| `Makefile` | 编译脚本 |

## 编译方法

```bash
# 确保已安装 riscv32-unknown-elf 工具链
make clean
make
```

生成文件：
- `main.elf` - ELF 可执行文件
- `main.dump` - 反汇编文件
- `main.bin` - 二进制文件
- `main.coe` - Vivado COE 文件 (用于 BRAM 初始化)

## 硬件要求

- TRQ MiniSys RISC-V 开发板
- UART 连接 (用于查看详细输出)
- LED 指示灯 (用于观察模式切换)

## 预期输出示例

```
########################################
#  TRQ MiniSys RISC-V Mode Test       #
#  Testing M mode & U mode Support    #
########################################

[1] Initial state check (should be M mode)
    mstatus = 0x00001800
      MIE  (bit 3):  0
      MPIE (bit 7):  0
      MPP  (bit 12:11): 3 (M mode)
    LED pattern: 0x0F (M mode)

[2] Setting up trap handler...
    mtvec = 0x80000XXX

[3] M mode CSR read/write test
    mhartid:  0x00000000
    misa:     0x40000100
    mstatus:  0x00001800
    Testing mscratch R/W...
      Write: 0xDEADBEEF, Read: 0xDEADBEEF [PASS]

[4] Starting mode switch tests...
----------------------------------------
  Round 1: M mode -> U mode -> M mode
----------------------------------------
  Currently in M mode
  Switching to U mode via MRET...
  [U mode] Now running in User mode!
  [U mode] LED pattern: 0xF0
  [U mode] Executing ECALL to return to M mode...

========================================
  TRAP #1
========================================
  mcause: 0x00000008 -> Exception: ECALL from U-mode
  mepc:   0x80000XXX
  mstatus:0x00000080
  MPP:    0 (U mode)
========================================
  [U mode ECALL detected]
  Back in M mode after ECALL
  [SUCCESS] U mode ECALL correctly returned to M mode
```

## 技术原理

### MRET 指令
1. 将 PC 设置为 mepc 的值
2. 将特权级设置为 mstatus.MPP
3. 将 mstatus.MIE 设置为 mstatus.MPIE
4. 将 mstatus.MPP 设置为 U mode (最低特权级)

### ECALL 指令
1. 触发异常，跳转到 mtvec
2. 设置 mcause 为 8 (U mode ECALL) 或 11 (M mode ECALL)
3. 保存当前 PC 到 mepc
4. 保存当前特权级到 mstatus.MPP
5. 切换到 M mode

## 参考资料

- RISC-V Privileged Architecture Specification
- TRQ MiniSys 硬件文档
