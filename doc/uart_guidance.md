# UART 使用指南

## 寄存器地址

| 地址 | 名称 | 读/写 | 说明 |
|------|------|-------|------|
| `0x00000000` | TX_DATA | W | 写入要发送的字节（低8位有效） |
| `0x00000001` | TX_FLAG | R/W | 发送状态：0=空闲，非0=忙 |
| `0x00000002` | RX_DATA | R | 接收到的字节（低8位有效） |
| `0x00000003` | RX_FLAG | R/W | 接收状态：0=无数据，非0=有数据（写0清除） |

## 通信参数

- 波特率：9600
- 数据位：8
- 停止位：1
- 校验：无

---

## C语言使用

### 寄存器定义

```c
#define UART_TX_DATA  (*(volatile unsigned int *)0x00000000)
#define UART_TX_FLAG  (*(volatile unsigned int *)0x00000001)
#define UART_RX_DATA  (*(volatile unsigned int *)0x00000002)
#define UART_RX_FLAG  (*(volatile unsigned int *)0x00000003)
```

### 发送字符

```c
void uart_putc(char c) {
    while (UART_TX_FLAG != 0);  // 等待发送空闲
    UART_TX_DATA = c;           // 写入数据，触发发送
}
```

### 接收字符

```c
char uart_getc(void) {
    while (UART_RX_FLAG == 0);  // 等待数据到达
    char c = UART_RX_DATA;      // 读取数据
    UART_RX_FLAG = 0;           // 清除标志
    return c;
}
```

---

## 汇编语言使用

### 寄存器地址常量

```asm
.equ UART_TX_DATA, 0x00000000
.equ UART_TX_FLAG, 0x00000001
.equ UART_RX_DATA, 0x00000002
.equ UART_RX_FLAG, 0x00000003
```

### 发送字符（a0 = 要发送的字符）

```asm
uart_putc:
    li   t0, UART_TX_FLAG       # t0 = TX_FLAG地址
wait_tx:
    lw   t1, 0(t0)              # 读取TX_FLAG
    bnez t1, wait_tx            # 非0则继续等待
    
    li   t0, UART_TX_DATA       # t0 = TX_DATA地址
    sw   a0, 0(t0)              # 写入数据，触发发送
    ret
```

### 接收字符（返回值在 a0）

```asm
uart_getc:
    li   t0, UART_RX_FLAG       # t0 = RX_FLAG地址
wait_rx:
    lw   t1, 0(t0)              # 读取RX_FLAG
    beqz t1, wait_rx            # 为0则继续等待
    
    li   t0, UART_RX_DATA       # t0 = RX_DATA地址
    lw   a0, 0(t0)              # 读取接收数据
    andi a0, a0, 0xFF           # 只保留低8位
    
    li   t0, UART_RX_FLAG       # 清除RX_FLAG
    sw   zero, 0(t0)
    ret
```

### 发送字符串（a0 = 字符串地址）

```asm
uart_puts:
    mv   t2, ra                 # 保存返回地址
    mv   t3, a0                 # 保存字符串指针
puts_loop:
    lb   a0, 0(t3)              # 加载字符
    beqz a0, puts_done          # 遇到\0结束
    jal  uart_putc              # 发送字符
    addi t3, t3, 1              # 指针+1
    j    puts_loop
puts_done:
    mv   ra, t2                 # 恢复返回地址
    ret
```

---

## 完整汇编示例

```asm
.section .text
.globl main

.equ UART_TX_DATA, 0x00000000
.equ UART_TX_FLAG, 0x00000001

main:
    la   a0, hello_str          # 加载字符串地址
    jal  uart_puts              # 发送字符串
loop:
    j    loop                   # 死循环

uart_putc:
    li   t0, UART_TX_FLAG
1:  lw   t1, 0(t0)
    bnez t1, 1b
    li   t0, UART_TX_DATA
    sw   a0, 0(t0)
    ret

uart_puts:
    mv   t2, ra
    mv   t3, a0
1:  lb   a0, 0(t3)
    beqz a0, 2f
    jal  uart_putc
    addi t3, t3, 1
    j    1b
2:  mv   ra, t2
    ret

.section .data
hello_str:
    .asciz "Hello from RISC-V!\r\n"
```

---

## 注意事项

1. **发送前必须检查TX_FLAG**，否则可能覆盖正在发送的数据
2. **接收后必须清除RX_FLAG**（写0），否则下次读到的还是旧数据
3. 使用 `\r\n` 换行（CR+LF），确保串口终端正确显示
4. 9600波特率下，发送1字节约需1ms，大量数据时需耐心等待
