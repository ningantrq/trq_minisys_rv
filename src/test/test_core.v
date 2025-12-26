`timescale 1ns / 1ps

module test_core;
  reg         clk;
  reg         rst;

  wire [31:0] icache_data_w;
  wire        icache_done_w;
  wire        icache_enable_w;
  wire [31:0] icache_addr_w;
  wire [31:0] dcache_data_rd_w;
  wire        dcache_done_w;
  wire        dcache_enable_w;
  wire        dcache_wr_w;
  wire        dcache_rd_w;
  wire [31:0] dcache_addr_w;
  wire [31:0] dcache_data_wr_w;
  wire [31:0] dcache_mask_wr_w;

  tool_bram_cache cache (
      .clk_i(clk),
      .rst_i(rst),

      .icache_data_o(icache_data_w),
      .icache_done_o(icache_done_w),
      .icache_enable_i(icache_enable_w),
      .icache_addr_i({1'b0, icache_addr_w[30:0]}),
      .dcache_data_rd_o(dcache_data_rd_w),
      .dcache_done_o(dcache_done_w),
      .dcache_enable_i(dcache_enable_w),
      .dcache_wr_i(dcache_wr_w),
      .dcache_rd_i(dcache_rd_w),
      .dcache_addr_i({1'b0, dcache_addr_w[30:0]}),
      .dcache_data_wr_i(dcache_data_wr_w),
      .dcache_mask_wr_i(dcache_mask_wr_w)
  );

  core_top uut_core (
      .clk_i(clk),
      .rst_i(rst),

      .iram_data_i  (icache_data_w),
      .iram_done_i  (icache_done_w),
      .iram_enable_o(icache_enable_w),
      .iram_addr_o  (icache_addr_w),

      .dram_data_rd_i(dcache_data_rd_w),
      .dram_done_i(dcache_done_w),
      .dram_enable_o(dcache_enable_w),
      .dram_wr_o(dcache_wr_w),
      .dram_rd_o(dcache_rd_w),
      .dram_addr_o(dcache_addr_w),
      .dram_data_wr_o(dcache_data_wr_w),
      .dram_mask_wr_o(dcache_mask_wr_w)
  );
  integer fd;

  always #5 clk = ~clk;
  initial begin
    fd = $fopen("reg.log", "w");
    $dumpfile("tb_core.vcd");
    $dumpvars(0, tb_core);

    clk = 1'b0;
    rst = 1'b1;

    #15 rst = 1'b0;

    #1000000;
    $fclose(fd);
    $finish();
  end

  always @(uut_core.pipeline_ctrl.mem_wb_pc_r) begin
    // verilog_format: off
    $fdisplay(fd, "ra\t%h", uut_core.regfile.x1_ra_r);
    $fdisplay(fd, "sp\t%h", uut_core.regfile.x2_sp_r);
    $fdisplay(fd, "gp\t%h", uut_core.regfile.x3_gp_r);
    $fdisplay(fd, "tp\t%h", uut_core.regfile.x4_tp_r);
    $fdisplay(fd, "t0\t%h", uut_core.regfile.x5_t0_r);
    $fdisplay(fd, "t1\t%h", uut_core.regfile.x6_t1_r);
    $fdisplay(fd, "t2\t%h", uut_core.regfile.x7_t2_r);
    $fdisplay(fd, "fp\t%h", uut_core.regfile.x8_s0_r);
    $fdisplay(fd, "s1\t%h", uut_core.regfile.x9_s1_r);
    $fdisplay(fd, "a0\t%h", uut_core.regfile.x10_a0_r);
    $fdisplay(fd, "a1\t%h", uut_core.regfile.x11_a1_r);
    $fdisplay(fd, "a2\t%h", uut_core.regfile.x12_a2_r);
    $fdisplay(fd, "a3\t%h", uut_core.regfile.x13_a3_r);
    $fdisplay(fd, "a4\t%h", uut_core.regfile.x14_a4_r);
    $fdisplay(fd, "a5\t%h", uut_core.regfile.x15_a5_r);
    $fdisplay(fd, "a6\t%h", uut_core.regfile.x16_a6_r);
    $fdisplay(fd, "a7\t%h", uut_core.regfile.x17_a7_r);
    $fdisplay(fd, "s2\t%h", uut_core.regfile.x18_s2_r);
    $fdisplay(fd, "s3\t%h", uut_core.regfile.x19_s3_r);
    $fdisplay(fd, "s4\t%h", uut_core.regfile.x20_s4_r);
    $fdisplay(fd, "s5\t%h", uut_core.regfile.x21_s5_r);
    $fdisplay(fd, "s6\t%h", uut_core.regfile.x22_s6_r);
    $fdisplay(fd, "s7\t%h", uut_core.regfile.x23_s7_r);
    $fdisplay(fd, "s8\t%h", uut_core.regfile.x24_s8_r);
    $fdisplay(fd, "s9\t%h", uut_core.regfile.x25_s9_r);
    $fdisplay(fd, "s10\t%h", uut_core.regfile.x26_s10_r);
    $fdisplay(fd, "s11\t%h", uut_core.regfile.x27_s11_r);
    $fdisplay(fd, "t3\t%h", uut_core.regfile.x28_t3_r);
    $fdisplay(fd, "t4\t%h", uut_core.regfile.x29_t4_r);
    $fdisplay(fd, "t5\t%h", uut_core.regfile.x30_t5_r);
    $fdisplay(fd, "t6\t%h", uut_core.regfile.x31_t6_r);
    $fdisplay(fd, "pc\t%h", uut_core.pipeline_ctrl.mem_wb_pc_r);
    $fdisplay(fd, "---------------------------------------------------");
  end

  //   initial begin
  //     $monitor("committed pc: %h, inst: %h", uut_core.pipeline_ctrl.mem_wb_pc_r,
  //              uut_core.pipeline_ctrl.mem_wb_inst_r);
  //   end
endmodule
