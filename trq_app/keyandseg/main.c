#include "keyboard.h"
#include "seg.h"

void delay();

int main() {
  int last_key = 0;
  int current_key = 0;
  
  seg_display(0);
  
  while (1) {
    current_key = keyboard_read();
    
    if (current_key != last_key && current_key != 0) {
      seg_display(current_key);
      last_key = current_key;
      delay();
    } else if (current_key == 0) {
      last_key = 0;
    }
  }
  
  return 0;
}

void delay() {
  for (int i = 0; i < 100000; ++i) {
    asm volatile("nop");
  }
}
