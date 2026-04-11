#include "uart.h"

void uart_putc(char c) {
    while (UART_TX_FLAG != 0) { }
    UART_TX_DATA = (unsigned int)c;
}

void uart_puts(const char *str) {
    while (*str) {
        uart_putc(*str++);
    }
}

void uart_put_hex(unsigned int val) {
    const char hex_chars[] = "0123456789ABCDEF";
    uart_puts("0x");
    for (int i = 28; i >= 0; i -= 4) {
        uart_putc(hex_chars[(val >> i) & 0xF]);
    }
}

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
    
    while (i > 0) {
        uart_putc(buf[--i]);
    }
}

char uart_getc(void) {
    while (UART_RX_FLAG == 0) { }
    char c = (char)(UART_RX_DATA & 0xFF);
    UART_RX_FLAG = 0;
    return c;
}

int uart_rx_ready(void) {
    return (UART_RX_FLAG != 0);
}

int uart_tx_idle(void) {
    return (UART_TX_FLAG == 0);
}
