# MiniSys RISC-V SOC 外设控制指南

## 目录

1. [概述](#概述)
2. [外设地址映射表](#外设地址映射表)
3. [UART串口控制](#uart串口控制)
4. [LED控制](#led控制)
5. [Switch开关控制](#switch开关控制)
6. [Timer定时器控制](#timer定时器控制)
7. [Keyboard键盘控制](#keyboard键盘控制)
8. [Segment数码管控制](#segment数码管控制)
9. [VRAM显存控制](#vram显存控制)
10. [RAM内存访问](#ram内存访问)
11. [完整示例程序](#完整示例程序)

---

## 写在前面

该文档中有些程序并未进行实际运行测试，不保证正确性，只用作引导，该文档主要作用是提供外设的C语言调用与访问方法，具体应用程序提供了一些未经验证的示例，仅供参考

可能还会有的外设： PWM， watchdog

VRAM与VGA显示相关部分可以先放一放，如果时间不够可以不开发与其相关的程序

## 概述

本文档详细介绍如何使用RISC-V汇编语言和C语言控制MiniSys SOC中的各种外设。该SOC通过内存映射I/O（MMIO）方式访问外设，所有外设都映射到特定的内存地址空间。

### 目前支持的外设

- **UART**: 串口通信，支持发送和接收字符
- **LED**: 24个LED灯（8个绿色、8个黄色、8个红色）
- **Switch**: 24个拨码开关
- **Timer**: 高精度定时器，支持周期计数和时间中断
- **Keyboard**: 4x4矩阵键盘，支持16个按键（0-9, A-F）
- **Segment**: 8位七段数码管，支持同时显示十六进制数字
- **VRAM**: 显存（用于VGA显示）
- **RAM**: 主存储器

---

## 外设地址映射表

| 外设 | 基地址 | 地址范围 | 说明 |
|------|--------|----------|------|
| UART | 0x00000000 | 0x00000000 - 0x00000003 | 串口通信 |
| Timer | 0x10000000 | 0x10000000 - 0x10000014 | 定时器 |
| VRAM | 0x20000000 | 0x20000000 - 0x2FFFFFFF | 显存 |
| LED | 0x30000000 | 0x30000000 - 0x30000017 | LED灯（0-23） |
| Switch | 0x40000000 | 0x40000000 - 0x40000017 | 开关（0-23） |
| Keyboard | 0x50000000 | 0x50000000 | 4x4矩阵键盘 |
| Segment | 0x60000000 | 0x60000000 | 七段数码管 |
| RAM | 0x80000000 | 0x80000000 - 0xFFFFFFFF | 主存储器 |

---

## UART串口控制

### 寄存器定义

| 寄存器地址 | 名称 | 读/写 | 说明 |
|------------|------|-------|------|
| 0x00000000 | TX_DATA | W | 发送数据寄存器（写入要发送的字节） |
| 0x00000001 | TX_FLAG | R/W | 发送状态标志（0=空闲，非0=忙） |
| 0x00000002 | RX_DATA | R | 接收数据寄存器（读取接收到的字节） |
| 0x00000003 | RX_FLAG | R/W | 接收状态标志（0=无数据，非0=有数据） |

### 工作原理

1. **发送流程**：
   - 检查TX_FLAG，等待为0（空闲）
   - 将数据写入TX_DATA
   - 硬件自动设置TX_FLAG为1（忙）
   - 发送完成后硬件自动清除TX_FLAG

2. **接收流程**：
   - 检查RX_FLAG，等待非0（有数据）
   - 从RX_DATA读取数据
   - 写0到RX_FLAG清除标志

### C语言示例

```c
// 定义寄存器地址
#define UART_TX_DATA_REG 0x00000000
#define UART_TX_FLAG_REG 0x00000001
#define UART_RX_DATA_REG 0x00000002
#define UART_RX_FLAG_REG 0x00000003

// 发送单个字符
void uart_put_char(char c) {
    // 等待发送缓冲区空闲
    while (*((volatile int *)(UART_TX_FLAG_REG)) != 0)
        ;
    // 写入数据
    *((volatile int *)(UART_TX_DATA_REG)) = c;
}

// 接收单个字符
char uart_get_char() {
    // 等待接收到数据
    while (*((volatile int *)(UART_RX_FLAG_REG)) == 0)
        ;
    // 清除接收标志
    *((volatile int *)(UART_RX_FLAG_REG)) = 0;
    // 读取数据
    return *((volatile int *)(UART_RX_DATA_REG));
}

// 发送字符串
void uart_put_string(const char *str) {
    while (*str) {
        uart_put_char(*str++);
    }
}

// 示例：回显程序
int main() {
    char c;
    uart_put_string("UART Echo Test\r\n");
    
    while (1) {
        c = uart_get_char();      // 接收字符
        uart_put_char(c);         // 回显字符
    }
    return 0;
}
```



## LED控制

### 地址映射

LED通过索引访问，共24个LED：
- **绿色LED（0-7）**: 地址 0x30000000 + 索引
- **黄色LED（8-15）**: 地址 0x30000008 + (索引-8)
- **红色LED（16-23）**: 地址 0x30000010 + (索引-16)

| LED索引 | 颜色 | 地址 |
|---------|------|------|
| 0-7 | 绿色 | 0x30000000 - 0x30000007 |
| 8-15 | 黄色 | 0x30000008 - 0x3000000F |
| 16-23 | 红色 | 0x30000010 - 0x30000017 |

### 控制方式

- **写入0**: 熄灭LED
- **写入非0**: 点亮LED（通常写入0xFFFFFFFF）
- **读取**: 返回当前LED状态（0=熄灭，非0=点亮）

### C语言示例

```c
#define LED_BASE_ADDR 0x30000000

// 点亮LED
void led_turn_on(int index) {
    if (index < 24)
        *((volatile int *)(LED_BASE_ADDR + index)) = 0xFFFFFFFF;
}

// 熄灭LED
void led_turn_off(int index) {
    if (index < 24)
        *((volatile int *)(LED_BASE_ADDR + index)) = 0x0;
}

// 检查LED是否点亮
int led_is_on(int index) {
    if (index < 24)
        return *((volatile int *)(LED_BASE_ADDR + index));
    else
        return 0;
}

// 切换LED状态
void led_toggle(int index) {
    if (led_is_on(index))
        led_turn_off(index);
    else
        led_turn_on(index);
}

// 示例1：流水灯效果
void led_running_light() {
    while (1) {
        for (int i = 0; i < 24; i++) {
            led_turn_on(i);
            delay_ms(100);  // 延时100ms
            led_turn_off(i);
        }
    }
}

// 示例2：对称流水灯
void led_symmetric_light() {
    while (1) {
        // 从两端向中间
        for (int i = 0; i < 12; i++) {
            led_turn_on(i);
            led_turn_on(23 - i);
            delay_ms(100);
        }
        // 从中间向两端熄灭
        for (int i = 0; i < 12; i++) {
            led_turn_off(i);
            led_turn_off(23 - i);
            delay_ms(100);
        }
    }
}

// 示例3：二进制计数显示
void led_binary_counter() {
    int count = 0;
    while (1) {
        // 在低8位LED上显示计数值
        for (int i = 0; i < 8; i++) {
            if (count & (1 << i))
                led_turn_on(i);
            else
                led_turn_off(i);
        }
        count++;
        delay_ms(500);
    }
}
```

## Switch开关控制

### 地址映射

Switch通过索引访问，共24个开关，地址范围：0x40000000 - 0x40000017

| Switch索引 | 地址 |
|------------|------|
| 0-23 | 0x40000000 + 索引 |

### 控制方式

- **只读**: Switch是输入设备，只能读取状态
- **读取值**: 0=关闭（OFF），非0=打开（ON）

### C语言示例

```c
#define SWITCH_BASE_ADDR 0x40000000

// 读取Switch状态
int switch_is_on(int index) {
    if (index < 24)
        return *((volatile int *)(SWITCH_BASE_ADDR + index));
    else
        return 0;
}

// 示例1：Switch控制LED（一对一映射）
void switch_control_led() {
    while (1) {
        for (int i = 0; i < 24; i++) {
            if (switch_is_on(i)) {
                led_turn_on(i);
            } else {
                led_turn_off(i);
            }
        }
    }
}

// 示例2：读取Switch作为4位二进制数
int read_switch_value(int start_index) {
    int value = 0;
    for (int i = 0; i < 4; i++) {
        if (switch_is_on(start_index + i)) {
            value |= (1 << i);
        }
    }
    return value;
}

// 示例3：两个4位数相乘，结果显示在LED上
void switch_multiplier() {
    while (1) {
        // Switch 0-3作为第一个数
        int a = read_switch_value(0);
        // Switch 12-15作为第二个数
        int b = read_switch_value(12);
        // 计算乘积
        int c = a * b;
        
        // 在LED 0-7上显示结果
        for (int i = 0; i < 8; i++) {
            if (c & (1 << i))
                led_turn_on(i);
            else
                led_turn_off(i);
        }
    }
}

// 示例4：使用Switch作为操作选择器
void switch_operation_selector() {
    int value = 0;
    
    while (1) {
        // Switch 21-23作为操作码（3位，支持8种操作）
        int op = 0;
        op |= (switch_is_on(21) != 0) << 0;
        op |= (switch_is_on(22) != 0) << 1;
        op |= (switch_is_on(23) != 0) << 2;
        
        switch (op) {
            case 0: // 无操作
                break;
            case 1: // 从Switch 0-15加载值
                value = read_switch_value(0) | (read_switch_value(4) << 4) |
                        (read_switch_value(8) << 8) | (read_switch_value(12) << 12);
                break;
            case 2: // 加1
                value++;
                break;
            case 3: // 减1
                value--;
                break;
            case 4: // 清零
                value = 0;
                break;
            case 5: // 左移
                value <<= 1;
                break;
            case 6: // 逻辑右移
                value = (unsigned short)value >> 1;
                break;
            case 7: // 算术右移
                value = (short)value >> 1;
                break;
        }
        
        // 在LED上显示当前值
        for (int i = 0; i < 16; i++) {
            if (value & (1 << i))
                led_turn_on(i);
            else
                led_turn_off(i);
        }
    }
}
```

## Timer定时器控制

### 寄存器定义

| 寄存器地址 | 名称 | 读/写 | 说明 |
|------------|------|-------|------|
| 0x10000000 | CYCLE | R | 周期计数低32位（每时钟周期+1） |
| 0x10000004 | CYCLEH | R | 周期计数高32位 |
| 0x10000008 | TIME | R | 时间计数低32位（1ms精度） |
| 0x1000000C | TIMEH | R | 时间计数高32位 |
| 0x10000010 | TIMECMP | R/W | 比较值低32位（用于定时中断） |
| 0x10000014 | TIMECMPH | R/W | 比较值高32位 |

### 工作原理

1. **CYCLE计数器**: 每个时钟周期递增1，用于精确计时
2. **TIME计数器**: 按1ms精度递增，用于毫秒级定时
3. **定时中断**: 当 TIME >= TIMECMP 时触发中断

### C语言示例

```c
#define TIMER_CYCLE     0x10000000
#define TIMER_CYCLEH    0x10000004
#define TIMER_TIME      0x10000008
#define TIMER_TIMEH     0x1000000C
#define TIMER_TIMECMP   0x10000010
#define TIMER_TIMECMPH  0x10000014

// 读取64位周期计数
unsigned long long read_cycle() {
    unsigned int low = *((volatile unsigned int *)(TIMER_CYCLE));
    unsigned int high = *((volatile unsigned int *)(TIMER_CYCLEH));
    return ((unsigned long long)high << 32) | low;
}

// 读取64位时间计数（单位：ms）
unsigned long long read_time() {
    unsigned int low = *((volatile unsigned int *)(TIMER_TIME));
    unsigned int high = *((volatile unsigned int *)(TIMER_TIMEH));
    return ((unsigned long long)high << 32) | low;
}

// 设置定时中断
void set_timer_interrupt(unsigned long long time_ms) {
    *((volatile unsigned int *)(TIMER_TIMECMP)) = (unsigned int)(time_ms & 0xFFFFFFFF);
    *((volatile unsigned int *)(TIMER_TIMECMPH)) = (unsigned int)(time_ms >> 32);
}

// 延时函数（基于TIME计数器）
void delay_ms(unsigned int ms) {
    unsigned long long start = read_time();
    while ((read_time() - start) < ms)
        ;
}

// 示例1：测量代码执行时间
void measure_execution_time() {
    unsigned long long start_cycle = read_cycle();
    unsigned long long start_time = read_time();
    
    // 执行要测量的代码
    for (int i = 0; i < 1000; i++) {
        led_turn_on(i % 24);
        led_turn_off(i % 24);
    }
    
    unsigned long long end_cycle = read_cycle();
    unsigned long long end_time = read_time();
    
    unsigned long long cycles = end_cycle - start_cycle;
    unsigned long long time_ms = end_time - start_time;
    
    // 通过UART输出结果（需要printf支持）
    printf("Execution time: %llu cycles, %llu ms\n", cycles, time_ms);
}

// 示例2：定时闪烁LED（1秒间隔）
void timer_blink_led() {
    unsigned long long last_time = read_time();
    int led_state = 0;
    
    while (1) {
        unsigned long long current_time = read_time();
        if (current_time - last_time >= 1000) {  // 1000ms = 1秒
            led_state = !led_state;
            if (led_state)
                led_turn_on(0);
            else
                led_turn_off(0);
            last_time = current_time;
        }
    }
}

// 示例3：使用定时中断（需要中断处理支持）
volatile int timer_flag = 0;

void timer_interrupt_handler() {
    timer_flag = 1;
    // 设置下次中断（1秒后）
    unsigned long long next_time = read_time() + 1000;
    set_timer_interrupt(next_time);
}

void use_timer_interrupt() {
    // 设置1秒后触发中断
    unsigned long long trigger_time = read_time() + 1000;
    set_timer_interrupt(trigger_time);
    
    // 主循环
    while (1) {
        if (timer_flag) {
            timer_flag = 0;
            // 处理定时事件
            led_toggle(0);
        }
        // 其他任务...
    }
}
```

## Keyboard键盘控制

### 概述

4x4矩阵键盘是一种常见的输入设备，通过4根行线和4根列线的扫描组合，可以检测16个按键的状态。硬件采用扫描方式工作，自动完成按键检测和译码。

### 硬件工作原理

- **扫描方式**: 硬件自动逐列扫描（约21ms周期）
- **按键检测**: 列线输出低电平，检测行线反馈判断按键位置
- **自动译码**: 硬件将行列位置转换为对应的键值（0-F）

### 键盘布局

标准4x4矩阵键盘布局：

```
     COL0   COL1   COL2   COL3
ROW0:  1      2      3      A
ROW1:  4      5      6      B
ROW2:  7      8      9      C
ROW3:  E      0      F      D
```

### 地址映射

| 寄存器地址 | 名称 | 读/写 | 说明 |
|------------|------|-------|------|
| 0x50000000 | KEY_VAL | R | 按键值寄存器（0-F，低4位有效） |

### 读取方式

- **只读寄存器**: 直接读取即可获得当前按键值
- **返回值**: 0-F表示对应按键，0表示无按键或按键0

### C语言示例

```c
#define KEYBOARD_BASE_ADDR 0x50000000

// 读取按键值
int keyboard_read() {
    return *((volatile int *)(KEYBOARD_BASE_ADDR)) & 0xF;
}

// 示例1：等待按键并返回
int wait_for_key() {
    int key;
    // 等待有效按键（非0）
    do {
        key = keyboard_read();
    } while (key == 0);
    
    // 简单防抖延时
    for (int i = 0; i < 100000; i++)
        asm volatile("nop");
    
    return key;
}

// 示例2：检测按键按下并释放
int get_key_press() {
    int current_key, last_key = 0;
    
    while (1) {
        current_key = keyboard_read();
        
        // 检测按键从按下到释放的边沿
        if (last_key != 0 && current_key == 0) {
            return last_key;  // 返回释放的按键值
        }
        
        last_key = current_key;
    }
}

// 示例3：密码输入
int password_input(int *buffer, int max_len) {
    int count = 0;
    int key;
    
    while (count < max_len) {
        key = get_key_press();  // 获取按键
        buffer[count++] = key;   // 存入缓冲区
        
        // 如果按下'D'键，表示输入结束
        if (key == 0xD)
            break;
    }
    
    return count;
}

// 示例4：计算器输入（配合LED显示）
void calculator_input() {
    int num1 = 0, num2 = 0, op = 0, result = 0;
    int state = 0;  // 0=输入数字1, 1=输入运算符, 2=输入数字2
    
    while (1) {
        int key = get_key_press();
        
        switch (state) {
            case 0:  // 输入第一个数字
                if (key >= 0 && key <= 9) {
                    num1 = num1 * 10 + key;
                    // 在LED上显示
                    for (int i = 0; i < 8; i++) {
                        led_set(i, (num1 >> i) & 1);
                    }
                } else if (key == 0xA) {  // 按'A'表示加法
                    op = 1;
                    state = 1;
                }
                break;
                
            case 1:  // 输入第二个数字
                if (key >= 0 && key <= 9) {
                    num2 = num2 * 10 + key;
                    for (int i = 0; i < 8; i++) {
                        led_set(i + 8, (num2 >> i) & 1);
                    }
                } else if (key == 0xD) {  // 按'D'计算结果
                    if (op == 1)
                        result = num1 + num2;
                    // 显示结果
                    for (int i = 0; i < 16; i++) {
                        led_set(i, (result >> i) & 1);
                    }
                    state = 0;
                    num1 = num2 = 0;
                }
                break;
        }
    }
}
```

## Segment数码管控制

### 概述

8位七段数码管用于显示数字和字母，支持十六进制（0-9, A-F）。当前实现为所有8个数码管同时显示相同的内容（统一显示模式）。

### 硬件特性

- **数码管类型**: 共阴极七段数码管
- **数量**: 8个数码管
- **显示方式**: 所有数码管同时显示相同内容
- **支持字符**: 0-9, A-F（十六进制）

### 七段数码管结构

```
      A
     ---
  F |   | B
     -G-
  E |   | C
     ---
      D   DP
```

段位定义：{DP, G, F, E, D, C, B, A}

### 地址映射

| 寄存器地址 | 名称 | 读/写 | 说明 |
|------------|------|-------|------|
| 0x60000000 | SEG_DATA | W | 显示数据寄存器（低4位有效，0-F） |

### 控制方式

- **只写寄存器**: 写入4位BCD码（0-F）
- **自动译码**: 硬件自动将BCD码转换为七段显示码
- **统一显示**: 所有8个数码管显示相同数字

### C语言示例

```c
#define SEG_BASE_ADDR 0x60000000

// 显示一个十六进制数字
void seg_display(int value) {
    *((volatile int *)(SEG_BASE_ADDR)) = value & 0xF;
}

// 示例1：显示0-F循环
void seg_cycle_display() {
    while (1) {
        for (int i = 0; i <= 0xF; i++) {
            seg_display(i);
            delay_ms(500);  // 延时500ms
        }
    }
}

// 示例2：根据Switch状态显示
void seg_display_switch() {
    while (1) {
        // 读取Switch 0-3的状态作为4位数字
        int value = 0;
        for (int i = 0; i < 4; i++) {
            if (switch_is_on(i))
                value |= (1 << i);
        }
        seg_display(value);
    }
}

// 示例3：倒计时显示
void seg_countdown(int seconds) {
    for (int i = seconds; i >= 0; i--) {
        seg_display(i % 16);  // 只显示低4位
        delay_ms(1000);       // 1秒延时
    }
    seg_display(0);  // 倒计时结束显示0
}

// 示例4：显示LED状态（十六进制）
void seg_display_led_status() {
    while (1) {
        // 读取LED 0-3的状态
        int value = 0;
        for (int i = 0; i < 4; i++) {
            if (led_is_on(i))
                value |= (1 << i);
        }
        seg_display(value);
        delay_ms(100);
    }
}
```

## VRAM显存控制

### 概述

VRAM（Video RAM）用于VGA显示，映射到地址空间 0x20000000 - 0x2FFFFFFF。VRAM是双端口存储器，CPU可以写入像素数据，VGA控制器可以读取并显示。

### 显示规格

- **分辨率**: 320x240（实际VGA输出640x480，通过2倍上采样）
- **像素格式**: 16位RGB（实际使用12位：4位R + 4位G + 4位B）
- **存储方式**: 字节寻址，每个像素占2字节

### 地址计算

对于坐标(x, y)的像素，地址计算公式：
```
地址 = 0x20000000 + (y * 320 + x) * 2
```

### C语言示例

```c
#define VRAM_BASE 0x20000000
#define SCREEN_WIDTH 320
#define SCREEN_HEIGHT 240

// RGB颜色宏（12位颜色）
#define RGB(r, g, b) ((((r) & 0xF) << 8) | (((g) & 0xF) << 4) | ((b) & 0xF))

// 常用颜色定义
#define COLOR_BLACK   0x000
#define COLOR_WHITE   0xFFF
#define COLOR_RED     0xF00
#define COLOR_GREEN   0x0F0
#define COLOR_BLUE    0x00F
#define COLOR_YELLOW  0xFF0
#define COLOR_CYAN    0x0FF
#define COLOR_MAGENTA 0xF0F

// 设置像素颜色
void vram_set_pixel(int x, int y, unsigned short color) {
    if (x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT) {
        unsigned int addr = VRAM_BASE + (y * SCREEN_WIDTH + x) * 2;
        *((volatile unsigned short *)addr) = color;
    }
}

// 读取像素颜色
unsigned short vram_get_pixel(int x, int y) {
    if (x >= 0 && x < SCREEN_WIDTH && y >= 0 && y < SCREEN_HEIGHT) {
        unsigned int addr = VRAM_BASE + (y * SCREEN_WIDTH + x) * 2;
        return *((volatile unsigned short *)addr);
    }
    return 0;
}

// 清屏
void vram_clear(unsigned short color) {
    for (int y = 0; y < SCREEN_HEIGHT; y++) {
        for (int x = 0; x < SCREEN_WIDTH; x++) {
            vram_set_pixel(x, y, color);
        }
    }
}

// 画水平线
void vram_draw_hline(int x1, int x2, int y, unsigned short color) {
    if (x1 > x2) {
        int temp = x1;
        x1 = x2;
        x2 = temp;
    }
    for (int x = x1; x <= x2; x++) {
        vram_set_pixel(x, y, color);
    }
}

// 画垂直线
void vram_draw_vline(int x, int y1, int y2, unsigned short color) {
    if (y1 > y2) {
        int temp = y1;
        y1 = y2;
        y2 = temp;
    }
    for (int y = y1; y <= y2; y++) {
        vram_set_pixel(x, y, color);
    }
}

// 画矩形
void vram_draw_rect(int x, int y, int width, int height, unsigned short color) {
    for (int dy = 0; dy < height; dy++) {
        for (int dx = 0; dx < width; dx++) {
            vram_set_pixel(x + dx, y + dy, color);
        }
    }
}

// 画矩形边框
void vram_draw_rect_outline(int x, int y, int width, int height, unsigned short color) {
    vram_draw_hline(x, x + width - 1, y, color);
    vram_draw_hline(x, x + width - 1, y + height - 1, color);
    vram_draw_vline(x, y, y + height - 1, color);
    vram_draw_vline(x + width - 1, y, y + height - 1, color);
}

// 示例1：彩虹渐变
void vram_rainbow_gradient() {
    vram_clear(COLOR_BLACK);
    for (int y = 0; y < SCREEN_HEIGHT; y++) {
        for (int x = 0; x < SCREEN_WIDTH; x++) {
            // 创建彩虹渐变
            int r = (x * 15) / SCREEN_WIDTH;
            int g = (y * 15) / SCREEN_HEIGHT;
            int b = ((x + y) * 15) / (SCREEN_WIDTH + SCREEN_HEIGHT);
            vram_set_pixel(x, y, RGB(r, g, b));
        }
    }
}

// 示例2：棋盘格
void vram_checkerboard() {
    int square_size = 20;
    for (int y = 0; y < SCREEN_HEIGHT; y++) {
        for (int x = 0; x < SCREEN_WIDTH; x++) {
            int is_white = ((x / square_size) + (y / square_size)) % 2;
            vram_set_pixel(x, y, is_white ? COLOR_WHITE : COLOR_BLACK);
        }
    }
}

// 示例3：简单动画
void vram_bouncing_ball() {
    int ball_x = 160, ball_y = 120;
    int ball_vx = 2, ball_vy = 2;
    int ball_size = 10;
    
    while (1) {
        // 清除上一帧的球
        vram_draw_rect(ball_x - ball_size/2, ball_y - ball_size/2, 
                      ball_size, ball_size, COLOR_BLACK);
        
        // 更新位置
        ball_x += ball_vx;
        ball_y += ball_vy;
        
        // 边界检测
        if (ball_x <= ball_size/2 || ball_x >= SCREEN_WIDTH - ball_size/2)
            ball_vx = -ball_vx;
        if (ball_y <= ball_size/2 || ball_y >= SCREEN_HEIGHT - ball_size/2)
            ball_vy = -ball_vy;
        
        // 绘制新位置的球
        vram_draw_rect(ball_x - ball_size/2, ball_y - ball_size/2, 
                      ball_size, ball_size, COLOR_RED);
        
        delay_ms(20);  // 50 FPS
    }
}
```

## RAM内存访问

### 概述

RAM映射到地址空间 0x80000000 - 0xFFFFFFFF，是程序的主存储器，用于存储代码、数据和堆栈。

### 访问方式

RAM支持标准的load/store指令，可以进行字节、半字和字访问：

### C语言示例

```c
#define RAM_BASE 0x80000000

// 直接内存访问（通常由编译器自动处理）
void ram_example() {
    // 定义变量（自动分配在RAM中）
    int array[100];
    
    // 写入数据
    for (int i = 0; i < 100; i++) {
        array[i] = i * i;
    }
    
    // 读取数据
    int sum = 0;
    for (int i = 0; i < 100; i++) {
        sum += array[i];
    }
}

// 直接地址访问
void ram_direct_access() {
    volatile int *ptr = (volatile int *)(RAM_BASE + 0x1000);
    *ptr = 0x12345678;  // 写入
    int value = *ptr;    // 读取
}
```


## 完整示例程序

### 示例1：综合控制（C语言）

```c
#include <stdio.h>

// 所有外设定义
#define UART_TX_DATA 0x00000000
#define UART_TX_FLAG 0x00000001
#define UART_RX_DATA 0x00000002
#define UART_RX_FLAG 0x00000003

#define TIMER_TIME   0x10000008
#define TIMER_TIMEH  0x1000000C

#define LED_BASE     0x30000000
#define SWITCH_BASE  0x40000000

// 辅助函数
void uart_put_char(char c) {
    while (*((volatile int *)(UART_TX_FLAG)) != 0);
    *((volatile int *)(UART_TX_DATA)) = c;
}

void uart_put_string(const char *str) {
    while (*str) uart_put_char(*str++);
}

void led_set(int index, int on) {
    if (index < 24)
        *((volatile int *)(LED_BASE + index)) = on ? 0xFFFFFFFF : 0;
}

int switch_get(int index) {
    return (index < 24) ? *((volatile int *)(SWITCH_BASE + index)) : 0;
}

unsigned long long read_time() {
    unsigned int low = *((volatile unsigned int *)(TIMER_TIME));
    unsigned int high = *((volatile unsigned int *)(TIMER_TIMEH));
    return ((unsigned long long)high << 32) | low;
}

void delay_ms(unsigned int ms) {
    unsigned long long start = read_time();
    while ((read_time() - start) < ms);
}

// 主程序：多功能演示
int main() {
    uart_put_string("TRQ MiniSys Demo\r\n");
    uart_put_string("================\r\n");
    
    int mode = 0;
    unsigned long long last_time = read_time();
    
    while (1) {
        // 读取Switch 0-1作为模式选择
        mode = (switch_get(0) ? 1 : 0) | (switch_get(1) ? 2 : 0);
        
        switch (mode) {
            case 0: // 模式0：LED全灭
                for (int i = 0; i < 24; i++)
                    led_set(i, 0);
                break;
                
            case 1: // 模式1：Switch控制LED
                for (int i = 0; i < 24; i++)
                    led_set(i, switch_get(i));
                break;
                
            case 2: // 模式2：流水灯
                if (read_time() - last_time >= 100) {
                    static int pos = 0;
                    for (int i = 0; i < 24; i++)
                        led_set(i, i == pos);
                    pos = (pos + 1) % 24;
                    last_time = read_time();
                }
                break;
                
            case 3: // 模式3：呼吸灯效果
                if (read_time() - last_time >= 50) {
                    static int brightness = 0;
                    static int direction = 1;
                    
                    for (int i = 0; i < 24; i++)
                        led_set(i, (i % 4) < brightness);
                    
                    brightness += direction;
                    if (brightness == 4 || brightness == 0)
                        direction = -direction;
                    
                    last_time = read_time();
                }
                break;
        }
    }
    
    return 0;
}
```

### 示例2：键盘输入数码管显示（C语言）

这是 `trq_app/keyandseg/main.c` 的实际应用示例：

```c
#include "keyboard.h"
#include "seg.h"

void delay();

int main() {
    int last_key = 0;
    int current_key = 0;
    
    seg_display(0);  // 初始显示0
    
    while (1) {
        current_key = keyboard_read();
        
        // 检测按键变化（边沿触发）
        if (current_key != last_key && current_key != 0) {
            seg_display(current_key);  // 更新数码管显示
            last_key = current_key;
            delay();  // 防抖延时
        } else if (current_key == 0) {
            last_key = 0;  // 按键释放
        }
    }
    
    return 0;
}

void delay() {
    for (int i = 0; i < 100000; ++i) {
        asm volatile("nop");
    }
}
```

**功能说明**：
- 初始化时数码管显示0
- 检测键盘输入（0-F）
- 按键按下时，数码管显示对应数字
- 防抖处理避免误触发

### 示例3：键盘密码锁（C语言）

```c
#include "keyboard.h"
#include "seg.h"
#include "led.h"

#define PASSWORD_LENGTH 4

int password[PASSWORD_LENGTH] = {1, 2, 3, 4};  // 预设密码1234
int input_buffer[PASSWORD_LENGTH];
int input_count = 0;

void delay_ms(int ms);

int main() {
    seg_display(0);
    
    while (1) {
        int key = keyboard_read();
        
        if (key != 0) {
            // 显示当前按键
            seg_display(key);
            
            // 存入输入缓冲区
            if (input_count < PASSWORD_LENGTH) {
                input_buffer[input_count++] = key;
                
                // 点亮对应LED指示输入进度
                led_turn_on(input_count - 1);
            }
            
            // 检查是否输入完成
            if (input_count == PASSWORD_LENGTH) {
                int correct = 1;
                for (int i = 0; i < PASSWORD_LENGTH; i++) {
                    if (input_buffer[i] != password[i]) {
                        correct = 0;
                        break;
                    }
                }
                
                if (correct) {
                    // 密码正确：绿色LED全亮
                    for (int i = 0; i < 8; i++)
                        led_turn_on(i);
                    seg_display(0xA);  // 显示A表示Accept
                } else {
                    // 密码错误：红色LED全亮
                    for (int i = 16; i < 24; i++)
                        led_turn_on(i);
                    seg_display(0xE);  // 显示E表示Error
                }
                
                delay_ms(2000);  // 显示结果2秒
                
                // 重置
                input_count = 0;
                for (int i = 0; i < 24; i++)
                    led_turn_off(i);
                seg_display(0);
            }
            
            // 等待按键释放
            while (keyboard_read() != 0)
                ;
            delay_ms(50);  // 防抖
        }
    }
    
    return 0;
}

void delay_ms(int ms) {
    for (int i = 0; i < ms; i++) {
        for (int j = 0; j < 10000; j++) {
            asm volatile("nop");
        }
    }
}
```

### 示例4：简单计算器（C语言）

```c
#include "keyboard.h"
#include "seg.h"

int get_key_press();
void delay_ms(int ms);

int main() {
    int num1 = 0, num2 = 0, result = 0;
    int state = 0;  // 0=输入num1, 1=输入num2, 2=显示结果
    
    seg_display(0);
    
    while (1) {
        int key = get_key_press();
        
        if (state == 0) {
            // 输入第一个数字
            if (key >= 0 && key <= 9) {
                num1 = key;
                seg_display(num1);
            } else if (key == 0xA) {  // 按A键表示"+"
                state = 1;
                seg_display(0xA);  // 显示运算符
                delay_ms(500);
            }
        } else if (state == 1) {
            // 输入第二个数字
            if (key >= 0 && key <= 9) {
                num2 = key;
                seg_display(num2);
            } else if (key == 0xD) {  // 按D键表示"="
                result = num1 + num2;
                seg_display(result & 0xF);  // 只显示低4位
                state = 2;
            }
        } else if (state == 2) {
            // 显示结果后，任意键重置
            if (key != 0) {
                state = 0;
                num1 = num2 = result = 0;
                seg_display(0);
            }
        }
    }
    
    return 0;
}

int get_key_press() {
    int key;
    // 等待有效按键
    do {
        key = keyboard_read();
    } while (key == 0);
    
    // 等待按键释放
    while (keyboard_read() != 0)
        ;
    
    delay_ms(50);  // 防抖
    return key;
}

void delay_ms(int ms) {
    for (int i = 0; i < ms; i++) {
        for (int j = 0; j < 10000; j++) {
            asm volatile("nop");
        }
    }
}
```

### 示例5：简单操作系统任务调度（C语言）

```c
#include <stdio.h>

typedef void (*task_func_t)(void);

typedef struct {
    task_func_t func;
    unsigned long long last_run;
    unsigned int period_ms;
} task_t;

// 任务1：LED闪烁
void task_led_blink() {
    static int state = 0;
    led_set(0, state);
    state = !state;
}

// 任务2：读取Switch并更新LED
void task_switch_monitor() {
    for (int i = 8; i < 16; i++) {
        led_set(i, switch_get(i));
    }
}

// 任务3：发送心跳消息
void task_heartbeat() {
    static int count = 0;
    char msg[32];
    sprintf(msg, "Heartbeat: %d\r\n", count++);
    uart_put_string(msg);
}

// 任务调度器
task_t tasks[] = {
    {task_led_blink, 0, 500},      // 500ms周期
    {task_switch_monitor, 0, 50},  // 50ms周期
    {task_heartbeat, 0, 2000},     // 2s周期
};

#define NUM_TASKS (sizeof(tasks) / sizeof(task_t))

void scheduler() {
    uart_put_string("Task Scheduler Started\r\n");
    
    while (1) {
        unsigned long long current_time = read_time();
        
        for (int i = 0; i < NUM_TASKS; i++) {
            if (current_time - tasks[i].last_run >= tasks[i].period_ms) {
                tasks[i].func();
                tasks[i].last_run = current_time;
            }
        }
    }
}

int main() {
    scheduler();
    return 0;
}
```

## 附录

### A. 常用寄存器地址速查表

```c
// UART
#define UART_TX_DATA 0x00000000
#define UART_TX_FLAG 0x00000001
#define UART_RX_DATA 0x00000002
#define UART_RX_FLAG 0x00000003

// Timer
#define TIMER_CYCLE     0x10000000
#define TIMER_CYCLEH    0x10000004
#define TIMER_TIME      0x10000008
#define TIMER_TIMEH     0x1000000C
#define TIMER_TIMECMP   0x10000010
#define TIMER_TIMECMPH  0x10000014

// VRAM
#define VRAM_BASE 0x20000000

// LED
#define LED_BASE 0x30000000

// Switch
#define SWITCH_BASE 0x40000000

// Keyboard
#define KEYBOARD_BASE_ADDR 0x50000000

// Segment Display (7-Segment)
#define SEG_BASE_ADDR 0x60000000

// RAM
#define RAM_BASE 0x80000000
```