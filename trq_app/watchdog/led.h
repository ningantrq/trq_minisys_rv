#ifndef _LED_H_
#define _LED_H_

#define LED_BASE_ADDR 0x30000000

void led_write(int idx, int status);
int led_read(int idx);

#endif
