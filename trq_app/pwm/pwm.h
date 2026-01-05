#ifndef _PWM_H_
#define _PWM_H_

#define PWM_BASE_ADDR 0x70000000

#define PWM_PERIOD_REG    (PWM_BASE_ADDR + 0x00)
#define PWM_DUTY0_REG     (PWM_BASE_ADDR + 0x04)
#define PWM_DUTY1_REG     (PWM_BASE_ADDR + 0x08)
#define PWM_DUTY2_REG     (PWM_BASE_ADDR + 0x0C)
#define PWM_DUTY3_REG     (PWM_BASE_ADDR + 0x10)
#define PWM_CONTROL_REG   (PWM_BASE_ADDR + 0x14)
#define PWM_STATUS_REG    (PWM_BASE_ADDR + 0x18)

#define PWM_ENABLE_BIT        (1 << 0)
#define PWM_CH0_ENABLE_BIT    (1 << 1)
#define PWM_CH1_ENABLE_BIT    (1 << 2)
#define PWM_CH2_ENABLE_BIT    (1 << 3)
#define PWM_CH3_ENABLE_BIT    (1 << 4)

void pwm_init(unsigned int period);
void pwm_set_duty(int channel, unsigned int duty);
void pwm_enable_channel(int channel, int enable);
void pwm_enable(int enable);
unsigned int pwm_get_status();

#endif
