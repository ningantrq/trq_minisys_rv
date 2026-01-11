#ifndef __CSR_H__
#define __CSR_H__

// ========================================================================
// CSR寄存器定义和操作宏
// ========================================================================
// 用于M mode和U mode测试
// ========================================================================

// CSR寄存器地址定义
#define CSR_MSTATUS     0x300
#define CSR_MISA        0x301
#define CSR_MIE         0x304
#define CSR_MTVEC       0x305
#define CSR_MSCRATCH    0x340
#define CSR_MEPC        0x341
#define CSR_MCAUSE      0x342
#define CSR_MTVAL       0x343
#define CSR_MIP         0x344
#define CSR_MCYCLE      0xB00
#define CSR_MHARTID     0xF14

// mstatus寄存器位域定义
#define MSTATUS_MIE     (1 << 3)   // Machine Interrupt Enable
#define MSTATUS_MPIE    (1 << 7)   // Machine Previous Interrupt Enable
#define MSTATUS_MPP_M   (3 << 11)  // Machine Previous Privilege = M mode
#define MSTATUS_MPP_U   (0 << 11)  // Machine Previous Privilege = U mode

// 特权级定义
#define PRIV_M          3
#define PRIV_U          0

// mcause定义
#define MCAUSE_ECALL_U  8   // Environment call from U-mode
#define MCAUSE_ECALL_M  11  // Environment call from M-mode
#define MCAUSE_EBREAK   3   // Breakpoint

// ========================================================================
// CSR读写宏
// ========================================================================

#define read_csr(reg) ({ \
    unsigned long __tmp; \
    asm volatile ("csrr %0, " #reg : "=r"(__tmp)); \
    __tmp; \
})

#define write_csr(reg, val) ({ \
    asm volatile ("csrw " #reg ", %0" :: "rK"(val)); \
})

#define set_csr(reg, bit) ({ \
    asm volatile ("csrs " #reg ", %0" :: "rK"(bit)); \
})

#define clear_csr(reg, bit) ({ \
    asm volatile ("csrc " #reg ", %0" :: "rK"(bit)); \
})

// 使用数字地址版本的CSR操作
#define read_csr_num(num) ({ \
    unsigned long __tmp; \
    asm volatile ("csrr %0, %1" : "=r"(__tmp) : "i"(num)); \
    __tmp; \
})

#define write_csr_num(num, val) ({ \
    asm volatile ("csrw %0, %1" :: "i"(num), "rK"(val)); \
})

// ========================================================================
// 特权指令宏
// ========================================================================

// ECALL: 触发环境调用异常
#define ecall() asm volatile ("ecall")

// EBREAK: 触发断点异常
#define ebreak() asm volatile ("ebreak")

// MRET: 从M mode返回
#define mret() asm volatile ("mret")

// NOP: 空操作
#define nop() asm volatile ("nop")

#endif // __CSR_H__
