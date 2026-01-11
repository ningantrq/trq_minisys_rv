// ========================================================================
// M mode / U mode 特权级测试程序
// ========================================================================
// 功能说明：
//   1. 系统启动后默认处于M mode
//   2. 配置trap handler (mtvec)
//   3. 测试M mode下的CSR读写
//   4. 通过MRET切换到U mode
//   5. 在U mode下触发ECALL返回M mode
//   6. 循环测试并通过LED和UART显示当前状态
//
// 可见效果：
//   - UART输出详细测试信息
//   - LED显示当前模式: M mode=0x0F, U mode=0xF0
// ========================================================================

#include "uart.h"
#include "led.h"
#include "csr.h"

// 外部符号声明
extern void trap_entry(void);
extern void switch_to_umode(void (*func)(void));

// 全局变量
volatile unsigned int g_trap_count = 0;      // trap计数
volatile unsigned int g_current_mode = PRIV_M;  // 当前模式 (用于显示)
volatile unsigned int g_ecall_from_umode = 0;   // U mode ECALL标志

// 函数声明
void delay(void);
void print_mstatus(void);
void print_mcause(unsigned int mcause);
void test_m_mode(void);
void umode_func(void);
void run_mode_test(void);

// ========================================================================
// Trap Handler (C语言部分)
// ========================================================================
// 由trap.S调用，处理异常和中断
// 参数: mcause - 异常原因, mepc - 异常PC
// 返回: 新的mepc值
// ========================================================================
unsigned int trap_handler(unsigned int mcause, unsigned int mepc) {
    g_trap_count++;
    
    uart_puts("\r\n");
    uart_puts("========================================\r\n");
    uart_puts("  TRAP #");
    uart_put_dec(g_trap_count);
    uart_puts("\r\n");
    uart_puts("========================================\r\n");
    
    uart_puts("  mcause: ");
    uart_put_hex(mcause);
    uart_puts(" -> ");
    print_mcause(mcause);
    uart_puts("\r\n");
    
    uart_puts("  mepc:   ");
    uart_put_hex(mepc);
    uart_puts("\r\n");
    
    // 读取mstatus查看MPP
    unsigned int mstatus = read_csr(mstatus);
    uart_puts("  mstatus:");
    uart_put_hex(mstatus);
    uart_puts("\r\n");
    
    unsigned int mpp = (mstatus >> 11) & 0x3;
    uart_puts("  MPP:    ");
    uart_put_dec(mpp);
    uart_puts(" (");
    if (mpp == PRIV_M) uart_puts("M mode");
    else if (mpp == PRIV_U) uart_puts("U mode");
    else uart_puts("Unknown");
    uart_puts(")\r\n");
    uart_puts("========================================\r\n");
    
    // 处理ECALL
    unsigned int cause_code = mcause & 0x7FFFFFFF;
    if (cause_code == MCAUSE_ECALL_U) {
        // U mode ECALL - 系统调用
        uart_puts("  [U mode ECALL detected]\r\n");
        g_ecall_from_umode = 1;
        g_current_mode = PRIV_M;  // 进入M mode
        
        // LED显示M mode
        led_set_all(0x0F);
        
        // ECALL指令长度为4字节，返回到下一条指令
        return mepc + 4;
        
    } else if (cause_code == MCAUSE_ECALL_M) {
        // M mode ECALL
        uart_puts("  [M mode ECALL detected]\r\n");
        return mepc + 4;
        
    } else if (cause_code == MCAUSE_EBREAK) {
        // EBREAK
        uart_puts("  [EBREAK detected]\r\n");
        return mepc + 4;
    }
    
    // 其他异常
    uart_puts("  [Unhandled exception]\r\n");
    return mepc + 4;
}

// ========================================================================
// 主函数
// ========================================================================
int main(void) {
    // 初始化延迟
    delay();
    
    // 欢迎信息
    uart_puts("\r\n");
    uart_puts("########################################\r\n");
    uart_puts("#  TRQ MiniSys RISC-V Mode Test       #\r\n");
    uart_puts("#  Testing M mode & U mode Support    #\r\n");
    uart_puts("########################################\r\n");
    uart_puts("\r\n");
    
    // 1. 确认初始状态 (M mode)
    uart_puts("[1] Initial state check (should be M mode)\r\n");
    print_mstatus();
    
    // LED显示M mode
    led_set_all(0x0F);
    uart_puts("    LED pattern: 0x0F (M mode)\r\n");
    delay();
    
    // 2. 配置trap handler
    uart_puts("\r\n[2] Setting up trap handler...\r\n");
    write_csr(mtvec, (unsigned int)trap_entry);
    uart_puts("    mtvec = ");
    uart_put_hex(read_csr(mtvec));
    uart_puts("\r\n");
    
    // 3. M mode CSR测试
    uart_puts("\r\n[3] M mode CSR read/write test\r\n");
    test_m_mode();
    
    // 4. 运行模式切换测试
    uart_puts("\r\n[4] Starting mode switch tests...\r\n");
    run_mode_test();
    
    // 5. 测试完成，循环闪烁LED
    uart_puts("\r\n########################################\r\n");
    uart_puts("#  All tests completed!               #\r\n");
    uart_puts("########################################\r\n");
    
    int count = 0;
    while (1) {
        led_set_all(0xAA);
        delay();
        led_set_all(0x55);
        delay();
        
        if (++count % 5 == 0) {
            uart_puts("  [Running... cycle ");
            uart_put_dec(count);
            uart_puts("]\r\n");
        }
    }
    
    return 0;
}

// ========================================================================
// 模式切换测试
// ========================================================================
void run_mode_test(void) {
    for (int round = 1; round <= 3; round++) {
        uart_puts("\r\n----------------------------------------\r\n");
        uart_puts("  Round ");
        uart_put_dec(round);
        uart_puts(": M mode -> U mode -> M mode\r\n");
        uart_puts("----------------------------------------\r\n");
        
        // 当前在M mode
        uart_puts("  Currently in M mode\r\n");
        led_set_all(0x0F);
        g_current_mode = PRIV_M;
        g_ecall_from_umode = 0;
        delay();
        
        // 切换到U mode
        uart_puts("  Switching to U mode via MRET...\r\n");
        g_current_mode = PRIV_U;
        
        // 调用汇编函数切换到U mode执行umode_func
        switch_to_umode(umode_func);
        
        // 从trap handler返回后继续这里 (已经回到M mode)
        uart_puts("  Back in M mode after ECALL\r\n");
        
        if (g_ecall_from_umode) {
            uart_puts("  [SUCCESS] U mode ECALL correctly returned to M mode\r\n");
        }
        
        delay();
    }
}

// ========================================================================
// U mode下执行的函数
// ========================================================================
void umode_func(void) {
    // 在U mode下执行
    uart_puts("  [U mode] Now running in User mode!\r\n");
    
    // LED显示U mode
    led_set_all(0xF0);
    uart_puts("  [U mode] LED pattern: 0xF0\r\n");
    
    // 短延迟让用户看到LED变化
    for (volatile int i = 0; i < 100000; i++) {
        asm volatile("nop");
    }
    
    // 执行ECALL返回M mode
    uart_puts("  [U mode] Executing ECALL to return to M mode...\r\n");
    ecall();
    
    // 不会执行到这里，因为ECALL会触发trap
    uart_puts("  [U mode] ERROR: Should not reach here!\r\n");
}

// ========================================================================
// M mode CSR测试
// ========================================================================
void test_m_mode(void) {
    // 读取各种CSR
    uart_puts("    mhartid:  ");
    uart_put_hex(read_csr(mhartid));
    uart_puts("\r\n");
    
    uart_puts("    misa:     ");
    uart_put_hex(read_csr(misa));
    uart_puts("\r\n");
    
    uart_puts("    mstatus:  ");
    uart_put_hex(read_csr(mstatus));
    uart_puts("\r\n");
    
    // 测试mscratch读写
    uart_puts("    Testing mscratch R/W...\r\n");
    unsigned int test_val = 0xDEADBEEF;
    write_csr(mscratch, test_val);
    unsigned int read_val = read_csr(mscratch);
    uart_puts("      Write: ");
    uart_put_hex(test_val);
    uart_puts(", Read: ");
    uart_put_hex(read_val);
    if (read_val == test_val) {
        uart_puts(" [PASS]\r\n");
    } else {
        uart_puts(" [FAIL]\r\n");
    }
    
    // 测试mcycle
    uart_puts("    mcycle:   ");
    uart_put_hex(read_csr(mcycle));
    uart_puts("\r\n");
}

// ========================================================================
// 打印mstatus寄存器内容
// ========================================================================
void print_mstatus(void) {
    unsigned int mstatus = read_csr(mstatus);
    uart_puts("    mstatus = ");
    uart_put_hex(mstatus);
    uart_puts("\r\n");
    
    uart_puts("      MIE  (bit 3):  ");
    uart_put_dec((mstatus >> 3) & 1);
    uart_puts("\r\n");
    
    uart_puts("      MPIE (bit 7):  ");
    uart_put_dec((mstatus >> 7) & 1);
    uart_puts("\r\n");
    
    uart_puts("      MPP  (bit 12:11): ");
    unsigned int mpp = (mstatus >> 11) & 0x3;
    uart_put_dec(mpp);
    uart_puts(" (");
    if (mpp == 3) uart_puts("M mode");
    else if (mpp == 0) uart_puts("U mode");
    else uart_puts("Reserved");
    uart_puts(")\r\n");
}

// ========================================================================
// 打印mcause含义
// ========================================================================
void print_mcause(unsigned int mcause) {
    unsigned int interrupt = (mcause >> 31) & 1;
    unsigned int code = mcause & 0x7FFFFFFF;
    
    if (interrupt) {
        uart_puts("Interrupt: ");
        switch (code) {
            case 7:  uart_puts("Machine timer interrupt"); break;
            case 11: uart_puts("Machine external interrupt"); break;
            default: uart_puts("Unknown interrupt"); break;
        }
    } else {
        uart_puts("Exception: ");
        switch (code) {
            case 0:  uart_puts("Instruction address misaligned"); break;
            case 1:  uart_puts("Instruction access fault"); break;
            case 2:  uart_puts("Illegal instruction"); break;
            case 3:  uart_puts("Breakpoint"); break;
            case 4:  uart_puts("Load address misaligned"); break;
            case 5:  uart_puts("Load access fault"); break;
            case 6:  uart_puts("Store address misaligned"); break;
            case 7:  uart_puts("Store access fault"); break;
            case 8:  uart_puts("ECALL from U-mode"); break;
            case 9:  uart_puts("ECALL from S-mode"); break;
            case 11: uart_puts("ECALL from M-mode"); break;
            default: uart_puts("Unknown exception"); break;
        }
    }
}

// ========================================================================
// 延迟函数
// ========================================================================
void delay(void) {
    for (volatile int i = 0; i < 200000; ++i) {
        asm volatile("nop");
    }
}
