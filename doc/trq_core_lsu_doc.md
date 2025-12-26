## 模块概述

LSU（Load-Store Unit）是流水线的MEM级

**核心职责**：
1. Load指令处理：从内存读取字节/半字/字，进行符号/零扩展
2. Store指令处理：向内存写入字节/半字/字，使用写掩码
3. 状态机控制：与内存接口握手，生成流水线暂停信号
4. 多周期操作：处理内存访问延迟

## 设计要点

### **Load/Store指令总览**

| 指令 | 操作 | 数据位宽 | 扩展方式 |
|------|------|---------|---------|
| LB | Load Byte | 8位 | 符号扩展 |
| LH | Load Halfword | 16位 | 符号扩展 |
| LW | Load Word | 32位 | 无需扩展 |
| LBU | Load Byte Unsigned | 8位 | 零扩展 |
| LHU | Load Halfword Unsigned | 16位 | 零扩展 |
| SB | Store Byte | 8位 | - |
| SH | Store Halfword | 16位 | - |
| SW | Store Word | 32位 | - |

### **内存掩码机制**

Store指令需要告诉内存写入哪些字节：
```verilog
SB: mem_mask = 32'h000000FF  // 只写最低字节
SH: mem_mask = 32'h0000FFFF  // 只写低两字节
SW: mem_mask = 32'hFFFFFFFF  // 写全部4字节
```

### **状态机设计**
见PPT MEM部分