#include "keyboard.h"
#include "seg.h"

void delay();
void delay_short();
void test_all_digits();
void test_counter();
void test_scroll();
void keyboard_accumulator();

// 测试模式
// 按键	    功能	                  说明
// 1	     测试所有数码管	       依次在8个位置显示0-7
// 2	     计数器测试	          从0计数到255，展示动态刷新
// 3	     滚动测试	12345678    循环左移显示
// 4	     键盘累加器	          连续输入8个按键，构成完整显示
// F	     清空显示	            所有数码管归零
// 其他键	顺序填充	           从位置0-7依次填充按键值


int main() {
  int last_key = 0;
  int current_key = 0;
  int mode = 0;
  
  seg_clear();
  seg_display_all(0x12345678);
  delay();
  
  while (1) {
    current_key = keyboard_read();
    
    if (current_key != last_key && current_key != 0) {
      
      switch (current_key) {
        case 0x1:
          test_all_digits();
          break;
        case 0x2:
          test_counter();
          break;
        case 0x3:
          test_scroll();
          break;
        case 0x4:
          keyboard_accumulator();
          break;
        case 0xF:
          seg_clear();
          break;
        default:
          seg_display_digit(mode, current_key);
          mode = (mode + 1) % 8;
          break;
      }
      
      last_key = current_key;
      delay();
    } else if (current_key == 0) {
      last_key = 0;
    }
  }
  
  return 0;
}

void test_all_digits() {
  for (int i = 0; i < 8; i++) {
    seg_display_digit(i, i);
    delay_short();
  }
  delay();
}

void test_counter() {
  for (unsigned int i = 0; i <= 0xFFFFFFFF && i < 256; i++) {
    seg_display_hex(i);
    delay_short();
  }
}

void test_scroll() {
  unsigned int pattern = 0x12345678;
  for (int i = 0; i < 16; i++) {
    seg_display_hex(pattern);
    pattern = ((pattern << 4) | (pattern >> 28)) & 0xFFFFFFFF;
    delay_short();
  }
}

void keyboard_accumulator() {
  unsigned int display_val = 0;
  int count = 0;
  int last_key = 0;
  
  seg_clear();
  
  while (count < 8) {
    int key = keyboard_read();
    
    if (key != last_key && key != 0) {
      display_val = (display_val << 4) | (key & 0xF);
      seg_display_hex(display_val);
      count++;
      last_key = key;
      delay();
    } else if (key == 0) {
      last_key = 0;
    }
  }
  
  delay();
  delay();
}

void delay() {
  for (int i = 0; i < 500000; ++i) {
    asm volatile("nop");
  }
}

void delay_short() {
  for (int i = 0; i < 100000; ++i) {
    asm volatile("nop");
  }
}
