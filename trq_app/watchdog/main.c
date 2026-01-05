#include "watchdog.h"
#include "led.h"

void delay(int cycles);

int main() {
    unsigned int timeout_ms = 100;
    int feed_counter = 0;
    int status;
    
    for (int i = 0; i < 8; i++) {
        led_write(i, 0);
    }
    
    watchdog_init(timeout_ms);
    watchdog_set_auto_reload(1);
    watchdog_set_interrupt_enable(1);
    watchdog_enable(1);
    
    led_write(0, 1);
    delay(500000);
    
    while (1) {
        status = watchdog_get_status();
        
        if (status & WDT_ACTIVE_STATUS_BIT) {
            led_write(1, 1);
        } else {
            led_write(1, 0);
        }
        
        if (status & WDT_TIMEOUT_STATUS_BIT) {
            led_write(2, 1);
            delay(1000000);
            led_write(2, 0);
        }
        
        watchdog_feed();
        
        feed_counter++;
        if (feed_counter >= 10) {
            led_write(3, 1);
            delay(200000);
            led_write(3, 0);
            feed_counter = 0;
        }
        
        delay(50000);
    }
    
    return 0;
}

void delay(int cycles) {
    for (int i = 0; i < cycles; ++i) {
        asm volatile("nop");
    }
}
