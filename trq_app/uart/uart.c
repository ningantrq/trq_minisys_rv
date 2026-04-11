#include "uart.h"

// ========================================================================
// UART驱动实现
// ========================================================================
// 波特率: 9600 (硬件固定)
// 数据位: 8位
// 停止位: 1位
// 无校验
// ========================================================================

// 发送单个字符（阻塞等待发送完成）
void uart_putc(char c) {
    // 等待上一次发送完成（TX_FLAG == 0 表示空闲）
    while (UART_TX_FLAG != 0) {
        // 忙等待
    }
    // 写入数据，触发发送
    UART_TX_DATA = (unsigned int)c;
}

// 发送字符串
void uart_puts(const char *str) {
    while (*str) {
        uart_putc(*str++);
    }
}

// 发送十六进制数（带0x前缀）
void uart_put_hex(unsigned int val) {
    const char hex_chars[] = "0123456789ABCDEF";
    uart_puts("0x");
    for (int i = 28; i >= 0; i -= 4) {
        uart_putc(hex_chars[(val >> i) & 0xF]);
    }
}

// 发送十进制数
void uart_put_dec(unsigned int val) {
    char buf[12];
    int i = 0;
    
    if (val == 0) {
        uart_putc('0');
        return;
    }
    
    while (val > 0) {
        buf[i++] = '0' + (val % 10);
        val /= 10;
    }
    
    // 反向输出
    while (i > 0) {
        uart_putc(buf[--i]);
    }
}

// 接收单个字符（阻塞等待接收完成）
char uart_getc(void) {
    // 等待接收完成（RX_FLAG != 0 表示有数据）
    while (UART_RX_FLAG == 0) {
        // 忙等待
    }
    // 读取数据
    char c = (char)(UART_RX_DATA & 0xFF);
    // 清除接收标志
    UART_RX_FLAG = 0;
    return c;
}

// 检查是否有数据可读（非阻塞）
int uart_rx_ready(void) {
    return (UART_RX_FLAG != 0);
}

// 检查发送是否空闲（非阻塞）
int uart_tx_idle(void) {
    return (UART_TX_FLAG == 0);
}
