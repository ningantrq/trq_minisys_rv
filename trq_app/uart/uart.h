#ifndef __UART_H__
#define __UART_H__

// ========================================================================
// UART驱动头文件
// ========================================================================
// 内存映射地址定义（与peri_bridge.v一致）
// ========================================================================

#define UART_TX_DATA    (*(volatile unsigned int *)0x00000000)  // 发送数据寄存器
#define UART_TX_FLAG    (*(volatile unsigned int *)0x00000001)  // 发送状态标志
#define UART_RX_DATA    (*(volatile unsigned int *)0x00000002)  // 接收数据寄存器
#define UART_RX_FLAG    (*(volatile unsigned int *)0x00000003)  // 接收状态标志

// ========================================================================
// 函数声明
// ========================================================================

// 发送单个字符（阻塞等待发送完成）
void uart_putc(char c);

// 发送字符串
void uart_puts(const char *str);

// 发送十六进制数（带0x前缀）
void uart_put_hex(unsigned int val);

// 发送十进制数
void uart_put_dec(unsigned int val);

// 接收单个字符（阻塞等待接收完成）
char uart_getc(void);

// 检查是否有数据可读（非阻塞）
int uart_rx_ready(void);

// 检查发送是否空闲（非阻塞）
int uart_tx_idle(void);

#endif // __UART_H__
