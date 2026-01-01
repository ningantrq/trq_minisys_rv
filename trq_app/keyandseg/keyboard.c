#include "keyboard.h"

int keyboard_read() {
  return *((volatile int *)(KEYBOARD_BASE_ADDR)) & 0xF;
}
