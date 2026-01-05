#ifndef _WATCHDOG_H_
#define _WATCHDOG_H_

#define WATCHDOG_BASE_ADDR 0x90000000

#define WDT_TIMEOUT_REG   (WATCHDOG_BASE_ADDR + 0x00)
#define WDT_CONTROL_REG   (WATCHDOG_BASE_ADDR + 0x04)
#define WDT_STATUS_REG    (WATCHDOG_BASE_ADDR + 0x08)
#define WDT_RESET_REG     (WATCHDOG_BASE_ADDR + 0x0C)

#define WDT_ENABLE_BIT        (1 << 0)
#define WDT_INTERRUPT_EN_BIT  (1 << 1)
#define WDT_RESET_EN_BIT      (1 << 2)
#define WDT_AUTO_RELOAD_BIT   (1 << 3)

#define WDT_TIMEOUT_STATUS_BIT (1 << 0)
#define WDT_ACTIVE_STATUS_BIT  (1 << 1)

void watchdog_init(unsigned int timeout_ms);
void watchdog_enable(int enable);
void watchdog_feed();
unsigned int watchdog_get_status();
void watchdog_set_interrupt_enable(int enable);
void watchdog_set_reset_enable(int enable);
void watchdog_set_auto_reload(int enable);

#endif
