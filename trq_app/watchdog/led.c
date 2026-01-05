#include "led.h"

static inline void write_reg(unsigned int addr, unsigned int value) {
    volatile unsigned int *reg = (volatile unsigned int *)addr;
    *reg = value;
}

static inline unsigned int read_reg(unsigned int addr) {
    volatile unsigned int *reg = (volatile unsigned int *)addr;
    return *reg;
}

void led_write(int idx, int status) {
    unsigned int addr = LED_BASE_ADDR + (idx * 4);
    write_reg(addr, status);
}

int led_read(int idx) {
    unsigned int addr = LED_BASE_ADDR + (idx * 4);
    return read_reg(addr);
}
