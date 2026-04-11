#include "watchdog.h"

static inline void write_reg(unsigned int addr, unsigned int value) {
    volatile unsigned int *reg = (volatile unsigned int *)addr;
    *reg = value;
}

static inline unsigned int read_reg(unsigned int addr) {
    volatile unsigned int *reg = (volatile unsigned int *)addr;
    return *reg;
}

void watchdog_init(unsigned int timeout_ms) {
    write_reg(WDT_TIMEOUT_REG, timeout_ms);
    write_reg(WDT_CONTROL_REG, 0);
}

void watchdog_enable(int enable) {
    unsigned int control = read_reg(WDT_CONTROL_REG);
    
    if (enable) {
        control |= WDT_ENABLE_BIT;
    } else {
        control &= ~WDT_ENABLE_BIT;
    }
    
    write_reg(WDT_CONTROL_REG, control);
}

void watchdog_feed() {
    write_reg(WDT_RESET_REG, 0x1);
}

unsigned int watchdog_get_status() {
    return read_reg(WDT_STATUS_REG);
}

void watchdog_set_interrupt_enable(int enable) {
    unsigned int control = read_reg(WDT_CONTROL_REG);
    
    if (enable) {
        control |= WDT_INTERRUPT_EN_BIT;
    } else {
        control &= ~WDT_INTERRUPT_EN_BIT;
    }
    
    write_reg(WDT_CONTROL_REG, control);
}

void watchdog_set_reset_enable(int enable) {
    unsigned int control = read_reg(WDT_CONTROL_REG);
    
    if (enable) {
        control |= WDT_RESET_EN_BIT;
    } else {
        control &= ~WDT_RESET_EN_BIT;
    }
    
    write_reg(WDT_CONTROL_REG, control);
}

void watchdog_set_auto_reload(int enable) {
    unsigned int control = read_reg(WDT_CONTROL_REG);
    
    if (enable) {
        control |= WDT_AUTO_RELOAD_BIT;
    } else {
        control &= ~WDT_AUTO_RELOAD_BIT;
    }
    
    write_reg(WDT_CONTROL_REG, control);
}
