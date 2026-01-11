#ifndef __UART_H__
#define __UART_H__

// ========================================================================
// UART驱动头文件
// ========================================================================

#define UART_TX_DATA    (*(volatile unsigned int *)0x00000000)
#define UART_TX_FLAG    (*(volatile unsigned int *)0x00000001)
#define UART_RX_DATA    (*(volatile unsigned int *)0x00000002)
#define UART_RX_FLAG    (*(volatile unsigned int *)0x00000003)

void uart_putc(char c);
void uart_puts(const char *str);
void uart_put_hex(unsigned int val);
void uart_put_dec(unsigned int val);
char uart_getc(void);
int uart_rx_ready(void);
int uart_tx_idle(void);

#endif // __UART_H__
