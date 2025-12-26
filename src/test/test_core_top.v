`timescale 1ns / 1ps
`include "../core/core_defs.v"

module test_core_top ();
  reg clk;
  reg rst;

  // CPU接口信号
  wire [31:0] iram_data_w;
  wire        iram_done_w;
  wire        iram_enable_w;
  wire [31:0] iram_addr_w;

  wire [31:0] dram_data_rd_w;
  wire        dram_done_w;
  wire        dram_enable_w;
  wire        dram_wr_w;
  wire        dram_rd_w;
  wire [31:0] dram_addr_w;
  wire [31:0] dram_data_wr_w;
  wire [31:0] dram_mask_wr_w;

  // ========== 实例化被测试的CPU ==========
  core_top uut_core (
      .clk_i(clk),
      .rst_i(rst),
      .timer_interrupt_i(1'b0),  // 不测试中断

      // 指令内存接口
      .iram_data_i  (iram_data_w),
      .iram_done_i  (iram_done_w),
      .iram_enable_o(iram_enable_w),
      .iram_addr_o  (iram_addr_w),

      // 数据内存接口
      .dram_data_rd_i (dram_data_rd_w),
      .dram_done_i    (dram_done_w),
      .dram_enable_o  (dram_enable_w),
      .dram_wr_o      (dram_wr_w),
      .dram_rd_o      (dram_rd_w),
      .dram_addr_o    (dram_addr_w),
      .dram_data_wr_o (dram_data_wr_w),
      .dram_mask_wr_o (dram_mask_wr_w)
  );

  // ========== 指令内存模拟 ==========
  reg [31:0] instruction_memory[0:255];  // 256条指令
  reg [31:0] iram_data_r;
  reg        iram_done_r;

  assign iram_data_w = iram_data_r;
  assign iram_done_w = iram_done_r;

  // 指令内存读取逻辑
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      iram_data_r <= 32'h00000013;  // NOP (ADDI x0, x0, 0)
      iram_done_r <= 1'b0;
    end else begin
      if (iram_enable_w) begin
        iram_data_r <= instruction_memory[iram_addr_w[9:2]];  // 字对齐
        iram_done_r <= 1'b1;
      end else begin
        iram_done_r <= 1'b0;
      end
    end
  end

  // ========== 数据内存模拟 ==========
  reg [31:0] data_memory[0:255];  // 256字数据
  reg [31:0] dram_data_rd_r;
  reg        dram_done_r;

  assign dram_data_rd_w = dram_data_rd_r;
  assign dram_done_w    = dram_done_r;

  integer i;

  // 数据内存读写逻辑
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      dram_data_rd_r <= 32'h0;
      dram_done_r    <= 1'b0;
    end else begin
      if (dram_enable_w) begin
        if (dram_wr_w) begin
          // 写操作：根据mask写入
          for (i = 0; i < 4; i = i + 1) begin
            if (dram_mask_wr_w[i*8+:8] != 8'h00) begin
              data_memory[dram_addr_w[9:2]][i*8+:8] <= dram_data_wr_w[i*8+:8];
            end
          end
          $display("[DRAM WRITE] addr=%h, data=%h, mask=%h", dram_addr_w, dram_data_wr_w,
                   dram_mask_wr_w);
        end else if (dram_rd_w) begin
          // 读操作
          dram_data_rd_r <= data_memory[dram_addr_w[9:2]];
          $display("[DRAM READ] addr=%h, data=%h", dram_addr_w,
                   data_memory[dram_addr_w[9:2]]);
        end
        dram_done_r <= 1'b1;
      end else begin
        dram_done_r <= 1'b0;
      end
    end
  end

  // ========== 时钟生成 ==========
  always #5 clk = ~clk;

  // ========== 测试程序加载 ==========
  initial begin
    // 初始化内存
    for (i = 0; i < 256; i = i + 1) begin
      instruction_memory[i] = 32'h00000013;  // NOP
      data_memory[i]        = 32'h00000000;
    end

    // ========== 测试程序1：基本算术指令 ==========
    // 地址0: ADDI x1, x0, 5      (x1 = 5)
    instruction_memory[0] = 32'h00500093;  // addi x1, x0, 5

    // 地址4: ADDI x2, x0, 10     (x2 = 10)
    instruction_memory[1] = 32'h00A00113;  // addi x2, x0, 10

    // 地址8: ADD x3, x1, x2      (x3 = x1 + x2 = 15)
    instruction_memory[2] = 32'h002081B3;  // add x3, x1, x2

    // 地址12: SUB x4, x2, x1     (x4 = x2 - x1 = 5)
    instruction_memory[3] = 32'h40110233;  // sub x4, x2, x1

    // 地址16: AND x5, x1, x2     (x5 = x1 & x2)
    instruction_memory[4] = 32'h0020F2B3;  // and x5, x1, x2

    // 地址20: OR x6, x1, x2      (x6 = x1 | x2)
    instruction_memory[5] = 32'h0020E333;  // or x6, x1, x2

    // 地址24: XOR x7, x1, x2     (x7 = x1 ^ x2)
    instruction_memory[6] = 32'h0020C3B3;  // xor x7, x1, x2

    // 地址28: SLL x8, x1, x0     (x8 = x1 << 0)
    instruction_memory[7] = 32'h00109433;  // sll x8, x1, x0

    // 地址32: SRL x9, x2, x0     (x9 = x2 >> 0)
    instruction_memory[8] = 32'h00015493;  // srl x9, x2, x0

    // ========== 测试程序2：Load/Store指令 ==========
    // 地址36: ADDI x10, x0, 0x80 (x10 = 0x80, 数据内存基址)
    instruction_memory[9] = 32'h08000513;  // addi x10, x0, 0x80

    // 地址40: ADDI x11, x0, 0x42 (x11 = 0x42, 测试数据)
    instruction_memory[10] = 32'h04200593;  // addi x11, x0, 0x42

    // 地址44: SW x11, 0(x10)     (存储x11到地址0x80)
    instruction_memory[11] = 32'h00B52023;  // sw x11, 0(x10)

    // 地址48: LW x12, 0(x10)     (从地址0x80加载到x12)
    instruction_memory[12] = 32'h00052603;  // lw x12, 0(x10)

    // ========== 测试程序3：分支指令 ==========
    // 地址52: ADDI x13, x0, 5    (x13 = 5)
    instruction_memory[13] = 32'h00500693;  // addi x13, x0, 5

    // 地址56: ADDI x14, x0, 5    (x14 = 5)
    instruction_memory[14] = 32'h00500713;  // addi x14, x0, 5

    // 地址60: BEQ x13, x14, 8    (如果x13==x14，跳转到PC+8)
    instruction_memory[15] = 32'h00E68463;  // beq x13, x14, 8

    // 地址64: ADDI x15, x0, 99   (不应该执行)
    instruction_memory[16] = 32'h06300793;  // addi x15, x0, 99

    // 地址68: ADDI x16, x0, 88   (跳转到这里)
    instruction_memory[17] = 32'h05800813;  // addi x16, x0, 88

    // 地址72: JAL x17, 8         (跳转并保存返回地址)
    instruction_memory[18] = 32'h008008EF;  // jal x17, 8

    // 地址76: ADDI x18, x0, 77   (不应该执行)
    instruction_memory[19] = 32'h04D00913;  // addi x18, x0, 77

    // 地址80: ADDI x19, x0, 66   (跳转到这里)
    instruction_memory[20] = 32'h04200993;  // addi x19, x0, 66

    // 结束程序
    instruction_memory[21] = 32'h00000013;  // NOP
    instruction_memory[22] = 32'h00000013;  // NOP
    instruction_memory[23] = 32'h00000013;  // NOP
  end

  // ========== 测试流程 ==========
  integer test_count;
  integer cycle_count;

  initial begin
    $dumpfile("test_core_top.vcd");
    $dumpvars(0, test_core_top);

    clk        = 1'b0;
    rst        = 1'b1;
    test_count = 0;
    cycle_count = 0;

    $display("========================================");
    $display("Core Top Testbench Start");
    $display("========================================");

    // 复位
    #20 rst = 1'b0;
    $display("[%0t] Reset released", $time);

    // 运行足够的周期让程序执行完
    #2000;

    $display("\n========================================");
    $display("Test Complete - Checking Results");
    $display("========================================");

    // ========== 验证结果 ==========
    
    // 测试1：基本算术指令
    $display("\n--- Test 1: Arithmetic Instructions ---");
    if (uut_core.regfile.x1_t0_r == 32'h00000005) begin
      $display("[PASS] x1 = 5 (expected: 5)");
      test_count = test_count + 1;
    end else begin
      $display("[FAIL] x1 = %h (expected: 5)", uut_core.regfile.x1_t0_r);
    end

    if (uut_core.regfile.x2_t1_r == 32'h0000000A) begin
      $display("[PASS] x2 = 10 (expected: 10)");
      test_count = test_count + 1;
    end else begin
      $display("[FAIL] x2 = %h (expected: 10)", uut_core.regfile.x2_t1_r);
    end

    if (uut_core.regfile.x3_t2_r == 32'h0000000F) begin
      $display("[PASS] x3 = 15 (x1+x2)");
      test_count = test_count + 1;
    end else begin
      $display("[FAIL] x3 = %h (expected: 15)", uut_core.regfile.x3_t2_r);
    end

    if (uut_core.regfile.x4_t3_r == 32'h00000005) begin
      $display("[PASS] x4 = 5 (x2-x1)");
      test_count = test_count + 1;
    end else begin
      $display("[FAIL] x4 = %h (expected: 5)", uut_core.regfile.x4_t3_r);
    end

    // 测试2：Load/Store指令
    $display("\n--- Test 2: Load/Store Instructions ---");
    if (uut_core.regfile.x11_a1_r == 32'h00000042) begin
      $display("[PASS] x11 = 0x42 (test data)");
      test_count = test_count + 1;
    end else begin
      $display("[FAIL] x11 = %h (expected: 0x42)", uut_core.regfile.x11_a1_r);
    end

    if (uut_core.regfile.x12_a2_r == 32'h00000042) begin
      $display("[PASS] x12 = 0x42 (loaded from memory)");
      test_count = test_count + 1;
    end else begin
      $display("[FAIL] x12 = %h (expected: 0x42)", uut_core.regfile.x12_a2_r);
    end

    if (data_memory[32] == 32'h00000042) begin  // 地址0x80 = index 32
      $display("[PASS] Memory[0x80] = 0x42");
      test_count = test_count + 1;
    end else begin
      $display("[FAIL] Memory[0x80] = %h (expected: 0x42)", data_memory[32]);
    end

    // 测试3：分支指令
    $display("\n--- Test 3: Branch Instructions ---");
    if (uut_core.regfile.x15_a5_r == 32'h00000000) begin
      $display("[PASS] x15 = 0 (branch taken, instruction skipped)");
      test_count = test_count + 1;
    end else begin
      $display("[FAIL] x15 = %h (expected: 0, branch should have been taken)",
               uut_core.regfile.x15_a5_r);
    end

    if (uut_core.regfile.x16_a6_r == 32'h00000058) begin
      $display("[PASS] x16 = 88 (branch target executed)");
      test_count = test_count + 1;
    end else begin
      $display("[FAIL] x16 = %h (expected: 88)", uut_core.regfile.x16_a6_r);
    end

    if (uut_core.regfile.x17_a7_r != 32'h00000000) begin
      $display("[PASS] x17 = %h (return address saved by JAL)", uut_core.regfile.x17_a7_r);
      test_count = test_count + 1;
    end else begin
      $display("[FAIL] x17 = 0 (JAL should have saved return address)");
    end

    if (uut_core.regfile.x19_s3_r == 32'h00000042) begin
      $display("[PASS] x19 = 66 (JAL target executed)");
      test_count = test_count + 1;
    end else begin
      $display("[FAIL] x19 = %h (expected: 66)", uut_core.regfile.x19_s3_r);
    end

    // ========== 总结 ==========
    $display("\n========================================");
    $display("Test Summary: %0d/11 tests passed", test_count);
    $display("========================================");

    if (test_count == 11) begin
      $display("*** ALL TESTS PASSED ***");
    end else begin
      $display("*** SOME TESTS FAILED ***");
    end

    // 显示所有寄存器的最终状态
    $display("\n--- Final Register Values ---");
    $display("x1  (t0) = %h", uut_core.regfile.x1_t0_r);
    $display("x2  (t1) = %h", uut_core.regfile.x2_t1_r);
    $display("x3  (t2) = %h", uut_core.regfile.x3_t2_r);
    $display("x4  (t3) = %h", uut_core.regfile.x4_t3_r);
    $display("x5  (t4) = %h", uut_core.regfile.x5_t4_r);
    $display("x6  (t5) = %h", uut_core.regfile.x6_t5_r);
    $display("x7  (t6) = %h", uut_core.regfile.x7_s1_r);
    $display("x10 (a0) = %h", uut_core.regfile.x10_a0_r);
    $display("x11 (a1) = %h", uut_core.regfile.x11_a1_r);
    $display("x12 (a2) = %h", uut_core.regfile.x12_a2_r);
    $display("x13 (a3) = %h", uut_core.regfile.x13_a3_r);
    $display("x14 (a4) = %h", uut_core.regfile.x14_a4_r);
    $display("x15 (a5) = %h", uut_core.regfile.x15_a5_r);
    $display("x16 (a6) = %h", uut_core.regfile.x16_a6_r);
    $display("x17 (a7) = %h", uut_core.regfile.x17_a7_r);
    $display("x19 (s3) = %h", uut_core.regfile.x19_s3_r);

    $display("\n========================================");
    $finish;
  end

  // ========== 监控PC变化 ==========
  always @(posedge clk) begin
    if (!rst) begin
      cycle_count = cycle_count + 1;
      // 每当有指令提交时输出（简化版，监控fetch阶段的PC）
      if (iram_enable_w && iram_done_w) begin
        $display("[Cycle %0d] PC=%h, Inst=%h", cycle_count, iram_addr_w, iram_data_w);
      end
    end
  end

  // ========== 超时保护 ==========
  initial begin
    #10000;
    $display("\n[ERROR] Timeout! Test did not complete in time.");
    $finish;
  end

endmodule
