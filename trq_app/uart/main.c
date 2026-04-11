#include "uart.h"

// ========================================================================
// UART测试程序
// ========================================================================
// 功能说明：
//   1. 启动时发送欢迎信息
//   2. 进入回显模式：接收字符并回显，同时显示ASCII码
//   3. 特殊命令：
//      - 输入 'h' 显示帮助信息
//      - 输入 't' 发送测试字符串
//      - 输入 'c' 发送计数器测试
//      - 输入 'q' 退出回显模式，进入连续发送测试
//
// 测试要点：
//   - 验证TX发送功能（字符、字符串、十六进制、十进制）
//   - 验证RX接收功能（单字符接收）
//   - 验证收发时序和波特率正确性
// ========================================================================

void delay(void);
void print_help(void);
void counter_test(void);
void continuous_tx_test(void);

int main() {
    // 启动延迟，等待硬件稳定
    delay();
    
    // 发送欢迎信息
    uart_puts("\r\n");
    uart_puts("========================================\r\n");
    uart_puts("  TRQ MiniSys RISC-V UART Test\r\n");
    uart_puts("  Baud: 9600, 8N1\r\n");
    uart_puts("========================================\r\n");
    uart_puts("\r\n");
    
    print_help();
    
    // 回显模式主循环
    uart_puts("\r\n> ");
    
    while (1) {
        char c = uart_getc();
        
        switch (c) {
            case 'h':
            case 'H':
                uart_puts("\r\n");
                print_help();
                break;
                
            case 't':
            case 'T':
                uart_puts("\r\n[TX Test] The quick brown fox jumps over the lazy dog.\r\n");
                uart_puts("[TX Test] 0123456789 ABCDEFGHIJKLMNOPQRSTUVWXYZ\r\n");
                break;
                
            case 'c':
            case 'C':
                uart_puts("\r\n[Counter Test]\r\n");
                counter_test();
                break;
                
            case 'q':
            case 'Q':
                uart_puts("\r\n[Entering continuous TX test...]\r\n");
                continuous_tx_test();
                break;
                
            case '\r':
            case '\n':
                uart_puts("\r\n> ");
                break;
                
            default:
                // 回显字符及其ASCII码
                uart_puts(" -> '");
                uart_putc(c);
                uart_puts("' (ASCII: ");
                uart_put_dec((unsigned int)c);
                uart_puts(", Hex: ");
                uart_put_hex((unsigned int)c);
                uart_puts(")\r\n> ");
                break;
        }
    }
    
    return 0;
}

void print_help(void) {
    uart_puts("Commands:\r\n");
    uart_puts("  h - Show this help\r\n");
    uart_puts("  t - TX string test\r\n");
    uart_puts("  c - Counter test (0-9)\r\n");
    uart_puts("  q - Continuous TX test\r\n");
    uart_puts("  Other - Echo with ASCII code\r\n");
}

void counter_test(void) {
    for (int i = 0; i < 10; i++) {
        uart_puts("Count: ");
        uart_put_dec(i);
        uart_puts(" (Hex: ");
        uart_put_hex(i);
        uart_puts(")\r\n");
        delay();
    }
    uart_puts("[Counter Test Done]\r\n");
}

void continuous_tx_test(void) {
    int count = 0;
    uart_puts("Sending continuous data... (Reset board to stop)\r\n");
    
    while (1) {
        uart_puts("Packet #");
        uart_put_dec(count++);
        uart_puts(": UART_TX_TEST_DATA_");
        uart_put_hex(count);
        uart_puts("\r\n");
        
        // 较长延迟便于观察
        delay();
        delay();
    }
}

void delay(void) {
    for (volatile int i = 0; i < 200000; ++i) {
        asm volatile("nop");
    }
}
