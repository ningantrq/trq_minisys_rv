#include "pwm.h"

void delay(int cycles);

int main() {
    unsigned int period = 1000;
    unsigned int duty = 0;
    int direction = 1;
    unsigned int step = 10;
    
    pwm_init(period);
    pwm_set_duty(0, duty);
    pwm_enable_channel(0, 1);
    pwm_enable(1);
    
    while (1) {
        if (direction == 1) {
            duty += step;
            if (duty >= period) {
                duty = period;
                direction = -1;
            }
        } else {
            if (duty <= step) {
                duty = 0;
                direction = 1;
            } else {
                duty -= step;
            }
        }
        
        pwm_set_duty(0, duty);
        
        delay(50000);
    }
    
    return 0;
}

void delay(int cycles) {
    for (int i = 0; i < cycles; ++i) {
        asm volatile("nop");
    }
}
