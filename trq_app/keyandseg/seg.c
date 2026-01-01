#include "seg.h"

void seg_display_all(unsigned int value) {
  *((volatile unsigned int *)(SEG_BASE_ADDR)) = value;
}

void seg_display_digit(int position, int value) {
  if (position < 0 || position > 7) return;
  
  unsigned int current = *((volatile unsigned int *)(SEG_BASE_ADDR));
  unsigned int mask = ~(0xF << (position * 4));
  current = (current & mask) | ((value & 0xF) << (position * 4));
  *((volatile unsigned int *)(SEG_BASE_ADDR)) = current;
}

void seg_clear() {
  *((volatile unsigned int *)(SEG_BASE_ADDR)) = 0x00000000;
}

void seg_display_hex(unsigned int value) {
  *((volatile unsigned int *)(SEG_BASE_ADDR)) = value;
}
