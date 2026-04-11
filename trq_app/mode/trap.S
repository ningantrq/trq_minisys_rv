# ========================================================================
# Trap Handler for M mode / U mode testing
# ========================================================================
# 当发生异常(如ECALL)或中断时，CPU跳转到mtvec指向的地址
# 此handler保存上下文，调用C语言trap处理函数，然后恢复上下文返回
# ========================================================================

.section .text.trap
.global trap_entry
.align 4

trap_entry:
    # 保存所有通用寄存器到栈
    addi sp, sp, -128
    sw ra,   0(sp)
    sw t0,   4(sp)
    sw t1,   8(sp)
    sw t2,  12(sp)
    sw t3,  16(sp)
    sw t4,  20(sp)
    sw t5,  24(sp)
    sw t6,  28(sp)
    sw a0,  32(sp)
    sw a1,  36(sp)
    sw a2,  40(sp)
    sw a3,  44(sp)
    sw a4,  48(sp)
    sw a5,  52(sp)
    sw a6,  56(sp)
    sw a7,  60(sp)
    sw s0,  64(sp)
    sw s1,  68(sp)
    sw s2,  72(sp)
    sw s3,  76(sp)
    sw s4,  80(sp)
    sw s5,  84(sp)
    sw s6,  88(sp)
    sw s7,  92(sp)
    sw s8,  96(sp)
    sw s9, 100(sp)
    sw s10,104(sp)
    sw s11,108(sp)

    # 调用C语言trap处理函数
    # trap_handler(mcause, mepc) -> 返回新的mepc
    csrr a0, mcause
    csrr a1, mepc
    call trap_handler

    # 更新mepc (trap_handler返回值在a0中)
    csrw mepc, a0

    # 恢复所有通用寄存器
    lw ra,   0(sp)
    lw t0,   4(sp)
    lw t1,   8(sp)
    lw t2,  12(sp)
    lw t3,  16(sp)
    lw t4,  20(sp)
    lw t5,  24(sp)
    lw t6,  28(sp)
    lw a0,  32(sp)
    lw a1,  36(sp)
    lw a2,  40(sp)
    lw a3,  44(sp)
    lw a4,  48(sp)
    lw a5,  52(sp)
    lw a6,  56(sp)
    lw a7,  60(sp)
    lw s0,  64(sp)
    lw s1,  68(sp)
    lw s2,  72(sp)
    lw s3,  76(sp)
    lw s4,  80(sp)
    lw s5,  84(sp)
    lw s6,  88(sp)
    lw s7,  92(sp)
    lw s8,  96(sp)
    lw s9, 100(sp)
    lw s10,104(sp)
    lw s11,108(sp)
    addi sp, sp, 128

    # 返回
    mret

# ========================================================================
# 切换到U mode的辅助函数
# void switch_to_umode(void (*func)(void))
# 参数 a0: U mode下要执行的函数地址
# ========================================================================
.global switch_to_umode
.align 4

switch_to_umode:
    # 1. 设置mepc为目标函数地址
    csrw mepc, a0
    
    # 2. 设置mstatus:
    #    - 清除MPP位 (设为U mode, 即00)
    #    - 设置MPIE位 (返回后使能中断)
    li t0, 0x1880       # MPP位掩码 (bits 12:11)
    csrc mstatus, t0    # 清除MPP (设为U mode)
    li t0, 0x80         # MPIE位掩码 (bit 7)
    csrs mstatus, t0    # 设置MPIE
    
    # 3. 执行mret切换到U mode
    mret
