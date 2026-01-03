/*
 * MiniSys RISC-V外设测试程序
 * 测试PWM控制器和看门狗的功能
 */

#include <stdint.h>
#include <stdio.h>

// 外设基地址定义
#define UART_BASE        0x00000000
#define TIMER_BASE       0x10000000
#define LED_BASE         0x20000000
#define SWITCH_BASE      0x30000000
#define RAM_BASE         0x40000000
#define KEYBOARD_BASE    0x50000000
#define SEGMENT_BASE     0x60000000
#define PWM_BASE         0x70000000
#define WATCHDOG_BASE    0x90000000

// UART寄存器定义
#define UART_DATA_REG    (UART_BASE + 0x00)
#define UART_STATUS_REG  (UART_BASE + 0x04)
#define UART_CTRL_REG    (UART_BASE + 0x08)

// PWM寄存器定义
#define PWM_CH0_REG      (PWM_BASE + 0x00)  // 通道0周期和占空比
#define PWM_CH1_REG      (PWM_BASE + 0x04)  // 通道1周期和占空比
#define PWM_CH2_REG      (PWM_BASE + 0x08)  // 通道2周期和占空比
#define PWM_CH3_REG      (PWM_BASE + 0x0C)  // 通道3周期和占空比
#define PWM_CTRL_REG     (PWM_BASE + 0x10)  // 控制寄存器
#define PWM_STATUS_REG   (PWM_BASE + 0x14)  // 状态寄存器

// PWM控制寄存器位定义
#define PWM_CH0_EN       (1 << 0)            // 通道0使能
#define PWM_CH1_EN       (1 << 1)            // 通道1使能
#define PWM_CH2_EN       (1 << 2)            // 通道2使能
#define PWM_CH3_EN       (1 << 3)            // 通道3使能

// 看门狗寄存器定义
#define WDT_TIME_REG     (WATCHDOG_BASE + 0x00)  // 超时时间寄存器
#define WDT_CTRL_REG     (WATCHDOG_BASE + 0x04)  // 控制寄存器
#define WDT_STATUS_REG   (WATCHDOG_BASE + 0x08)  // 状态寄存器
#define WDT_RESET_REG    (WATCHDOG_BASE + 0x0C)  // 复位寄存器

// 看门狗控制寄存器位定义
#define WDT_EN           (1 << 0)            // 看门狗使能
#define WDT_INT_EN       (1 << 1)            // 中断使能
#define WDT_RST_EN       (1 << 2)            // 复位使能
#define WDT_AUTO_RELOAD  (1 << 3)            // 自动重载使能

// 看门狗状态寄存器位定义
#define WDT_INT_FLAG     (1 << 0)            // 中断标志
#define WDT_RST_FLAG     (1 << 1)            // 复位标志

// 函数声明
void uart_putc(char c);
void uart_puts(const char* s);
char uart_getc(void);
void write32(uint32_t addr, uint32_t data);
uint32_t read32(uint32_t addr);
void delay(uint32_t ms);

// 主测试程序
int main() {
    uart_puts("\nMiniSys RISC-V 外设测试程序\n");
    uart_puts("==============================\n");
    
    // 测试PWM控制器
    uart_puts("\n1. PWM控制器测试\n");
    uart_puts("------------------------------\n");
    
    // 初始化PWM通道0：周期1000（1ms），占空比50%（500）
    write32(PWM_CH0_REG, (1000 << 16) | 500);
    uart_puts("   PWM通道0配置：周期1ms，占空比50%\n");
    
    // 初始化PWM通道1：周期2000（2ms），占空比25%（500）
    write32(PWM_CH1_REG, (2000 << 16) | 500);
    uart_puts("   PWM通道1配置：周期2ms，占空比25%\n");
    
    // 初始化PWM通道2：周期500（0.5ms），占空比75%（375）
    write32(PWM_CH2_REG, (500 << 16) | 375);
    uart_puts("   PWM通道2配置：周期0.5ms，占空比75%\n");
    
    // 初始化PWM通道3：周期4000（4ms），占空比10%（400）
    write32(PWM_CH3_REG, (4000 << 16) | 400);
    uart_puts("   PWM通道3配置：周期4ms，占空比10%\n");
    
    // 使能所有PWM通道
    write32(PWM_CTRL_REG, PWM_CH0_EN | PWM_CH1_EN | PWM_CH2_EN | PWM_CH3_EN);
    uart_puts("   所有PWM通道已使能\n");
    
    // 验证PWM配置是否正确
    uint32_t ch0_val = read32(PWM_CH0_REG);
    uint32_t ch1_val = read32(PWM_CH1_REG);
    uint32_t ctrl_val = read32(PWM_CTRL_REG);
    
    uart_puts("   读取验证：\n");
    uart_puts("   PWM通道0寄存器值：0x");
    // 这里需要实现十六进制打印函数
    uart_puts("\n   PWM控制寄存器值：0x");
    // 这里需要实现十六进制打印函数
    uart_puts("\n");
    
    uart_puts("   PWM测试完成！请使用示波器观察PWM输出波形。\n");
    
    // 延时5秒，观察PWM输出
    uart_puts("   延时5秒...\n");
    delay(5000);
    
    // 关闭所有PWM通道
    write32(PWM_CTRL_REG, 0x0);
    uart_puts("   所有PWM通道已关闭\n");
    
    // 测试看门狗
    uart_puts("\n2. 看门狗测试\n");
    uart_puts("------------------------------\n");
    
    // 测试1：基本喂狗功能
    uart_puts("   测试1：基本喂狗功能\n");
    uart_puts("   配置看门狗：超时时间2秒，使能中断\n");
    
    // 配置看门狗超时时间为2秒（2000ms）
    write32(WDT_TIME_REG, 2000);
    
    // 使能看门狗，仅启用中断功能
    write32(WDT_CTRL_REG, WDT_EN | WDT_INT_EN);
    
    uart_puts("   看门狗已启动，将在2秒内喂狗...\n");
    
    // 延时1秒
    delay(1000);
    
    // 喂狗操作
    write32(WDT_RESET_REG, 0x1);
    uart_puts("   已执行喂狗操作\n");
    
    // 再延时1秒
    delay(1000);
    
    // 读取状态寄存器
    uint32_t wdt_status = read32(WDT_STATUS_REG);
    if (wdt_status & WDT_INT_FLAG) {
        uart_puts("   错误：看门狗产生了中断！\n");
    } else {
        uart_puts("   成功：看门狗未产生中断，喂狗功能正常\n");
    }
    
    // 清除状态寄存器
    write32(WDT_STATUS_REG, WDT_INT_FLAG);
    
    // 测试2：自动重载功能
    uart_puts("   \n测试2：自动重载功能\n");
    uart_puts("   启用看门狗自动重载功能\n");
    
    // 配置看门狗：超时时间1秒，启用自动重载
    write32(WDT_TIME_REG, 1000);
    write32(WDT_CTRL_REG, WDT_EN | WDT_INT_EN | WDT_AUTO_RELOAD);
    
    uart_puts("   看门狗已启动，自动重载模式\n");
    
    // 延时3秒，由于自动重载，看门狗不应产生中断
    uart_puts("   延时3秒...\n");
    delay(3000);
    
    // 读取状态寄存器
    wdt_status = read32(WDT_STATUS_REG);
    if (wdt_status & WDT_INT_FLAG) {
        uart_puts("   错误：看门狗产生了中断！\n");
    } else {
        uart_puts("   成功：看门狗未产生中断，自动重载功能正常\n");
    }
    
    // 清除状态寄存器
    write32(WDT_STATUS_REG, WDT_INT_FLAG);
    
    // 关闭看门狗
    write32(WDT_CTRL_REG, 0x0);
    
    uart_puts("\n所有测试完成！\n");
    uart_puts("==============================\n");
    
    return 0;
}

// 内存写入函数
void write32(uint32_t addr, uint32_t data) {
    *(volatile uint32_t*)addr = data;
}

// 内存读取函数
uint32_t read32(uint32_t addr) {
    return *(volatile uint32_t*)addr;
}

// UART发送字符
void uart_putc(char c) {
    // 等待发送缓冲区为空
    while (!(read32(UART_STATUS_REG) & 0x2));
    // 发送字符
    write32(UART_DATA_REG, c);
}

// UART发送字符串
void uart_puts(const char* s) {
    while (*s) {
        uart_putc(*s++);
    }
}

// UART接收字符
char uart_getc(void) {
    // 等待接收缓冲区有数据
    while (!(read32(UART_STATUS_REG) & 0x1));
    // 读取字符
    return (char)read32(UART_DATA_REG);
}

// 延时函数（毫秒）
void delay(uint32_t ms) {
    // 这里需要根据实际系统时钟实现延时
    // 假设系统时钟为50MHz，每个循环大约需要2个时钟周期
    uint32_t cycles = ms * 50000;  // 50MHz * ms
    
    for (uint32_t i = 0; i < cycles; i++) {
        // 空操作
        asm volatile ("nop");
    }
}