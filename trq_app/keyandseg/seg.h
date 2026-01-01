#ifndef _SEG_H_
#define _SEG_H_

#define SEG_BASE_ADDR 0x60000000

void seg_display_all(unsigned int value);
void seg_display_digit(int position, int value);
void seg_clear();
void seg_display_hex(unsigned int value);

#endif
