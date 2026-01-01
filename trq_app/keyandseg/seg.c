#include "seg.h"

void seg_display(int value) {
  *((volatile int *)(SEG_BASE_ADDR)) = value & 0xF;
}
