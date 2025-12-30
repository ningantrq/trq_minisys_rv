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

    建议在Wave窗口中添加以下信号组：

    **寄存器文件组**（用于验证算术逻辑指令）：
    ```
    uut_core.regfile.x1_ra_r    # 预期：0x00000005
    uut_core.regfile.x2_sp_r    # 预期：0x0000000a
    uut_core.regfile.x3_gp_r    # 预期：0x0000000f (ADD结果)
    uut_core.regfile.x4_tp_r    # 预期：0x00000005 (SUB结果)
    uut_core.regfile.x7_t2_r    # 预期：0x0000000f (OR结果)
    uut_core.regfile.x8_s0_r    # 预期：0x0000000f (XOR结果)
    uut_core.regfile.x9_s1_r    # 预期：0x00000000 (AND结果)
    uut_core.regfile.x22_s6_r   # 预期：0x0000000a (SLLI结果)
    uut_core.regfile.x29_t4_r   # 阶段标记（1-11）
    ```

    **乘除法单元组**（用于验证M扩展）：
    ```
    uut_core.multiplier.status_r
    uut_core.multiplier.stall_o
    uut_core.divider.status_r
    uut_core.divider.stall_o
    uut_core.regfile.x5_t0_r    # 乘除法操作数：7
    uut_core.regfile.x6_t1_r    # 乘除法操作数：6
    uut_core.regfile.x7_t2_r    # MUL结果：42
    uut_core.regfile.x12_a2_r   # DIV结果：0
    uut_core.regfile.x14_a4_r   # REM结果：6
    ```

    **访存接口组**（用于验证Load/Store）：
    ```
    dcache_enable_w
    dcache_wr_w
    dcache_rd_w
    dcache_addr_w
    dcache_data_wr_w
    dcache_data_rd_w
    dcache_done_w
    ```

    **CSR单元组**（用于验证Zicsr扩展）：
    ```
    uut_core.csr.mstatus_r
    uut_core.csr.mtvec_r
    uut_core.csr.mepc_r
    ```

2. 测试功能:
验证完整的RISC-V处理器核心（`core_top`）功能：
- 指令取指和执行
- 寄存器读写
- 数据存储器访问
- 流水线控制

    测试程序（全面覆盖RV32IMZicsr），`tool_bram_cache`预加载的测试程序包含**92条指令**，全面覆盖RV32IMZicsr指令集。

3. 结果：
寄存器记录见doc/test_result/core_test_reg.log。


测试波形：
![test_core_waveform_1](doc_figure/core_test_1.png "test_core_waveform_1")

![test_core_waveform_2](doc_figure/core_test_2.png "test_core_waveform_2")

![test_core_waveform_3](doc_figure/core_test_3.png "test_core_waveform_3")

![test_core_waveform_4](doc_figure/core_test_4.png "test_core_waveform_4")

![test_core_waveform_5](doc_figure/core_test_5.png "test_core_waveform_5")

![test_core_waveform_6](doc_figure/core_test_6.png "test_core_waveform_6")

![test_core_waveform_7](doc_figure/core_test_7.png "test_core_waveform_7")

![test_core_waveform_8](doc_figure/core_test_8.png "test_core_waveform_8")

4. 结果解释：
