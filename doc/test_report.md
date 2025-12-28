## 生成 IP

1.  创建 Vivado 工程
File -> Project -> New
Project Type：RTL Project
选你的 FPGA Part/Board（IP 会与器件绑定）
勾选/不勾选 “Do not specify sources at this time” 都行
2.  添加源文件
    - Design Sources（设计源）
        把 src/core/ 下所有 .v 加入（建议全加，避免缺依赖）
    - Simulation Sources（仿真源）加入：
        ```
        src/test/test_divider.v
        src/test/test_multiplier.v
        src/test/test_core.v
        src/test/tool_bram_cache.v
        ```
3) 添加 IP（从 .xci 导入）
Add Sources -> Add or Create IP
把下列 .xci 加进来（至少前两个是必须的）：

        ```
        ip/ip_divider/ip_divider.xci
        ip/ip_multiplier/ip_multiplier.xci
        ip/ip_bram/ip_bram.xci
        ip/ip_vram/ip_vram.xci
        ip/ip_clock_div/ip_clock_div.xci
        ```

4) 生成 IP 输出产物（Generate Output Products）：
对每个 IP，在 Sources 面板里找到 IP, 右键 .xci 文件：Upgrade IP（如果提示需要升级），之后Generate Output Products。注意multiplier与divider的IP一般在core_top下面的multiplier与divider的下一个层级。

## 运行仿真：test_divider / test_multiplier / test_core

### 除法测试
1. 操作：在 Sources -> Simulation Sources 里右键 test_divider.v，选择Set as Top

    如果需要修改运行时间（视测试而定，vivado默认为1000ns），点击左侧 Flow Navigator → Simulation → Simulation Settings
    或者点击菜单栏 Tools → Settings → Simulation，在 Simulation 选项卡中找到 xsim.simulate.runtime，将默认值从 1000ns 改为你需要的时间，点击 Apply 和 OK。

    之后选择Flow Navigator -> Run Simulation -> Run Behavioral Simulation

2. 测试功能:
准备11组测试数据：
包括：
- **普通除法**：`1 ÷ 1`、`0x20241107 ÷ 0x19491001`
- **正负数组合**：正÷负、负÷正、负÷负
- **除零测试**：`0x20241107 ÷ 0`、`-0x20241107 ÷ 0`
- **溢出测试**：`0x80000000 ÷ -1`（最小负数除以-1）

```verilog
localparam DIV_TB_NUM = 11;
reg [31:0] div_rs1_data_arr[DIV_TB_NUM - 1:0];
reg [31:0] div_rs2_data_arr[DIV_TB_NUM - 1:0];
```

之后分别进行DIV和REM测试（有符号除法和取余）以及DIVU和REMU测试（无符号除法和取余）在这11个测试用例上的测试。

**有符号关键验证点**：
- **除法恒等式**：`被除数 = 除数 × 商 + 余数`
- **余数符号**：余数符号与被除数相同
- **除零行为**：商为-1，余数为被除数本身（RISC-V规范）
- **溢出行为**：`-2^31 ÷ -1`商为`-2^31`，余数为0

3. 结果：

### 乘法测试
1. 操作：同上

2. 测试功能:
验证`core_multiplier`模块的正确性，包括：
- **MUL**：32位乘法（返回低32位）
- **MULH**：32位有符号乘法（返回高32位）
- **MULHSU**：32位有符号×无符号乘法（返回高32位）
- **MULHU**：32位无符号乘法（返回高32位）
准备8组测试数据：
包括：
- **正数×正数**：`1 × 1`、`0x20241107 × 0x19491001`
- **正数×负数**：`1 × -1`、`0x20241107 × -0x19491001`
- **负数×正数**：`-1 × 1`、`-0x20241107 × 0x19491001`
- **负数×负数**：`-1 × -1`、`-0x20241107 × -0x19491001`

3. 结果：

### CPU集成测试
1. 操作：同上

2. 测试功能:
验证`core_multiplier`模块的正确性，包括：
- **MUL**：32位乘法（返回低32位）
- **MULH**：32位有符号乘法（返回高32位）
- **MULHSU**：32位有符号×无符号乘法（返回高32位）
- **MULHU**：32位无符号乘法（返回高32位）
准备8组测试数据：
包括：
- **正数×正数**：`1 × 1`、`0x20241107 × 0x19491001`
- **正数×负数**：`1 × -1`、`0x20241107 × -0x19491001`
- **负数×正数**：`-1 × 1`、`-0x20241107 × 0x19491001`
- **负数×负数**：`-1 × -1`、`-0x20241107 × -0x19491001`

3. 结果：