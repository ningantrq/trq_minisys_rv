#include "pwm.h"

static inline void write_reg(unsigned int addr, unsigned int value) {
    volatile unsigned int *reg = (volatile unsigned int *)addr;
    *reg = value;
}

static inline unsigned int read_reg(unsigned int addr) {
    volatile unsigned int *reg = (volatile unsigned int *)addr;
    return *reg;
}

void pwm_init(unsigned int period) {
    write_reg(PWM_PERIOD_REG, period);
    write_reg(PWM_CONTROL_REG, 0);
}

void pwm_set_duty(int channel, unsigned int duty) {
    unsigned int reg_addr = PWM_DUTY0_REG + (channel * 4);
    write_reg(reg_addr, duty);
}

void pwm_enable_channel(int channel, int enable) {
    unsigned int control = read_reg(PWM_CONTROL_REG);
    unsigned int ch_bit = PWM_CH0_ENABLE_BIT << channel;
    
    if (enable) {
        control |= ch_bit;
    } else {
        control &= ~ch_bit;
    }
    
    write_reg(PWM_CONTROL_REG, control);
}

void pwm_enable(int enable) {
    unsigned int control = read_reg(PWM_CONTROL_REG);
    
    if (enable) {
        control |= PWM_ENABLE_BIT;
    } else {
        control &= ~PWM_ENABLE_BIT;
    }
    
    write_reg(PWM_CONTROL_REG, control);
}

unsigned int pwm_get_status() {
    return read_reg(PWM_STATUS_REG);
}
