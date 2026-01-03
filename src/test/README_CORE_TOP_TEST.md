# test_core_top.v - CPU核心功能测试

## 📋 测试概述

`test_core_top.v` 是一个**独立的功能测试**，用于验证 `core_top` CPU核心的基本功能，无需差分测试或外部工具。

### 测试特点

- ✅ **独立运行**：不依赖QEMU或其他参考实现
- ✅ **内置测试程序**：手写RISC-V机器码，直接验证结果
- ✅ **简单内存模拟**：256字指令RAM + 256字数据RAM
- ✅ **清晰输出**：直接在终端查看测试结果
- ✅ **与其他测试一致**：风格类似 `test_alu.v`、`test_fetch.v` 等

---

## 🎯 测试内容

### 测试1：基本算术指令
- `ADDI` - 立即数加法
- `ADD` - 寄存器加法
- `SUB` - 减法
- `AND` - 按位与
- `OR` - 按位或
- `XOR` - 按位异或
- `SLL` - 逻辑左移
- `SRL` - 逻辑右移

**验证点**：
- x1 = 5
- x2 = 10
- x3 = 15 (x1+x2)
- x4 = 5 (x2-x1)

### 测试2：Load/Store指令
- `SW` - 存储字
- `LW` - 加载字

**验证点**：
- x11 = 0x42 (测试数据)
- x12 = 0x42 (从内存加载)
- Memory[0x80] = 0x42 (存储到内存)

### 测试3：分支跳转指令
- `BEQ` - 相等分支
- `JAL` - 跳转并链接

**验证点**：
- x15 = 0 (BEQ跳过的指令)
- x16 = 88 (BEQ跳转目标)
- x17 != 0 (JAL保存的返回地址)
- x19 = 66 (JAL跳转目标)

---

## 🚀 运行方法

### 方法1：使用iverilog（推荐）

```bash
cd /Users/ning/awesome_minisys_rv/src/test

# 编译并运行
iverilog -g2012 -o test_core_top \
  -I../core \
  ../core/core_defs.v \
  ../core/core_alu.v \
  ../core/core_regfile.v \
  ../core/core_fetch.v \
  ../core/core_decode.v \
  ../core/core_exec.v \
  ../core/core_lsu.v \
  ../core/core_pipeline_ctrl.v \
  ../core/core_top.v \
  test_core_top.v

# 运行仿真
./test_core_top

# 查看波形（可选）
gtkwave test_core_top.vcd
```

### 方法2：使用Vivado XSim

```bash
cd /Users/ning/awesome_minisys_rv/src/test

# 编译
xvlog --incr --relax -i ../core \
  ../core/core_defs.v \
  ../core/core_alu.v \
  ../core/core_regfile.v \
  ../core/core_fetch.v \
  ../core/core_decode.v \
  ../core/core_exec.v \
  ../core/core_lsu.v \
  ../core/core_pipeline_ctrl.v \
  ../core/core_top.v \
  test_core_top.v

# 链接
xelab -debug typical test_core_top -s test_core_top_snapshot

# 运行
xsim test_core_top_snapshot -runall
```

### 方法3：使用Vivado GUI

1. **启动Vivado**
   ```bash
   vivado &
   ```

2. **创建项目**
   - File → Project → New
   - 项目类型：RTL Project

3. **添加源文件**
   - Design Sources：添加 `src/core/*.v` (所有核心模块)
   - Simulation Sources：添加 `src/test/test_core_top.v`

4. **设置Include路径**
   - Settings → Simulation → Verilog Options
   - Include Directories: `src/core`

5. **运行仿真**
   - Flow Navigator → Simulation → Run Behavioral Simulation

---

## 📊 预期输出

### 成功输出示例

```
========================================
Core Top Testbench Start
========================================
[20] Reset released
[Cycle 1] PC=00000000, Inst=00500093
[Cycle 2] PC=00000004, Inst=00a00113
...
[DRAM WRITE] addr=00000080, data=00000042, mask=ffffffff
[DRAM READ] addr=00000080, data=00000042
...

========================================
Test Complete - Checking Results
========================================

--- Test 1: Arithmetic Instructions ---
[PASS] x1 = 5 (expected: 5)
[PASS] x2 = 10 (expected: 10)
[PASS] x3 = 15 (x1+x2)
[PASS] x4 = 5 (x2-x1)

--- Test 2: Load/Store Instructions ---
[PASS] x11 = 0x42 (test data)
[PASS] x12 = 0x42 (loaded from memory)
[PASS] Memory[0x80] = 0x42

--- Test 3: Branch Instructions ---
[PASS] x15 = 0 (branch taken, instruction skipped)
[PASS] x16 = 88 (branch target executed)
[PASS] x17 = 0000004c (return address saved by JAL)
[PASS] x19 = 66 (JAL target executed)

========================================
Test Summary: 11/11 tests passed
========================================
*** ALL TESTS PASSED ***

--- Final Register Values ---
x1  (t0) = 00000005
x2  (t1) = 0000000a
x3  (t2) = 0000000f
...
```

---

## 🔧 测试实现细节

### 内存模拟

```verilog
// 指令内存：256条指令（1KB）
reg [31:0] instruction_memory[0:255];

// 数据内存：256字（1KB）
reg [31:0] data_memory[0:255];
```

### 测试程序结构

测试程序直接用RISC-V机器码编写：

```verilog
// ADDI x1, x0, 5 (x1 = 5)
instruction_memory[0] = 32'h00500093;
//                         ^^^^^^^^^
//                         |||||||||
//                         opcode + funct3 + rd + rs1 + imm
```

**为什么不用汇编？**
- 避免依赖外部工具链
- 测试代码完全自包含
- 方便精确控制每条指令

### 寄存器访问

测试直接访问CPU内部的寄存器文件：

```verilog
uut_core.regfile.x1_t0_r  // 访问x1寄存器
uut_core.regfile.x2_t1_r  // 访问x2寄存器
```

这是**白盒测试**的方式，适合功能验证。

---

## 🐛 常见问题

### Q1: 编译错误："module 'core_top' not found"

**原因**：未添加所有依赖的核心模块

**解决**：确保添加了以下文件：
```
core_defs.v
core_alu.v
core_regfile.v
core_fetch.v
core_decode.v
core_exec.v
core_lsu.v
core_pipeline_ctrl.v
core_top.v
```

### Q2: 测试失败："x1 = 00000000 (expected: 5)"

**可能原因**：
1. 流水线未正确推进
2. 寄存器写回逻辑有问题
3. 时序问题（运行时间不够）

**调试方法**：
```verilog
// 增加仿真时间
#2000 → #10000

// 添加更多调试输出
$display("PC=%h, x1=%h", PC, x1);
```

### Q3: 内存读写不正常

**检查点**：
- 确认 `dram_enable_w` 信号有效
- 确认地址字对齐（地址[1:0] = 2'b00）
- 检查 `dram_mask_wr_w` 是否正确

### Q4: 波形文件太大

**优化方法**：
```verilog
// 只记录关键信号
$dumpvars(1, test_core_top);  // 只记录顶层
$dumpvars(2, uut_core.regfile);  // 只记录寄存器文件
```

---

## 📈 扩展测试

### 添加更多指令测试

```verilog
// 测试逻辑指令
instruction_memory[24] = 32'h0020F2B3;  // and x5, x1, x2
instruction_memory[25] = 32'h0020E333;  // or x6, x1, x2

// 测试移位指令
instruction_memory[26] = 32'h00109433;  // sll x8, x1, x0
instruction_memory[27] = 32'h00015493;  // srl x9, x2, x0
```

### 添加数据冒险测试

```verilog
// Load-Use冒险
instruction_memory[30] = 32'h00052603;  // lw x12, 0(x10)
instruction_memory[31] = 32'h00C60633;  // add x12, x12, x12  // 立即使用x12
```

### 添加控制冒险测试

```verilog
// 分支延迟槽测试
instruction_memory[40] = 32'h00E68463;  // beq x13, x14, 8
instruction_memory[41] = 32'h00500793;  // addi x15, x0, 5  // 应该被跳过
```

---

## 🎯 与其他测试的对比

| 测试文件 | 测试对象 | 测试方式 | 复杂度 |
|---------|---------|---------|--------|
| `test_alu.v` | ALU模块 | 遍历所有操作码 | ⭐ |
| `test_fetch.v` | 取指模块 | 模拟分支跳转 | ⭐⭐ |
| `test_lsu.v` | 访存模块 | 测试Load/Store | ⭐⭐ |
| `test_core_top.v` | **完整CPU** | **运行RISC-V程序** | ⭐⭐⭐ |
| `tb_core.v` (difftest) | 完整CPU | 与QEMU对比 | ⭐⭐⭐⭐ |

**test_core_top.v的定位**：
- 比单模块测试更全面
- 比差分测试更简单
- 适合快速功能验证

---

## ✅ 验证清单

运行测试前检查：
- [ ] 所有核心模块文件存在
- [ ] `core_defs.v` 包含所有指令定义
- [ ] `core_top.v` 无编译错误
- [ ] 测试环境（iverilog或Vivado）已安装

测试通过标准：
- [ ] 11/11测试全部通过
- [ ] 无编译错误或警告
- [ ] 终端输出 `*** ALL TESTS PASSED ***`
- [ ] 寄存器值符合预期

---

## 📚 相关文档

- **CPU设计文档**：`../doc/CPU_DESIGN.md`
- **指令集参考**：`../doc/RISC-V_ISA.md`
- **其他测试**：`test_alu.v`, `test_fetch.v`, `test_lsu.v`
- **差分测试**：`../../minisys-rv-main/difftest/README.md`

---

**创建日期**: 2025-11-24  
**测试覆盖**: RV32I基本指令集（算术、逻辑、访存、分支）  
**维护状态**: 活跃
