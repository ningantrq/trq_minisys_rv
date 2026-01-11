#ifndef __LED_H__
#define __LED_H__

// ========================================================================
// LED驱动头文件
// ========================================================================
// LED基地址: 0x30000000
// 写入地址 0x30000000 + n 控制第n个LED (n = 0-15)
// 写入值: 0=灭, 1=亮
// ========================================================================

#define LED_BASE        0x30000000

// 设置LED状态 (idx: 0-15, status: 0=off, 1=on)
static inline void led_set(int idx, int status) {
    volatile unsigned int *led = (volatile unsigned int *)(LED_BASE + idx);
    *led = status ? 1 : 0;
}

// 设置所有LED (pattern: 16位, bit0=LED0, bit15=LED15)
static inline void led_set_all(unsigned int pattern) {
    for (int i = 0; i < 16; i++) {
        led_set(i, (pattern >> i) & 1);
    }
}

// 清除所有LED
static inline void led_clear_all(void) {
    led_set_all(0);
}

#endif // __LED_H__
