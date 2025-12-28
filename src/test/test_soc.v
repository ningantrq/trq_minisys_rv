`timescale 1ns / 1ps

module test_soc;
  reg        clk;
  reg        rst;

  reg        uart_tx_enable;
  reg  [7:0] uart_tx_data;
  wire       uart_tx_wire;

  reg        rx;
  wire       tx;

  wire [3:0] red;
  wire [3:0] green;
  wire [3:0] blue;
  wire       h_sync;
  wire       v_sync;

  minisys_soc uut_soc (
      .clk_i(clk),
      .rst_i(rst),

      // uart
      .rx_i(uart_tx_wire),
      .tx_o(tx),

      // vga
      .red_o(red),
      .green_o(green),
      .blue_o(blue),
      .h_sync_o(h_sync),
      .v_sync_o(v_sync)
  );

  peri_uart_tx uart_tx (
      .clk_i(clk),
      .rst_i(rst),
      .tx_enable_i(uart_tx_enable),
      .tx_data_i(uart_tx_data),
      .tx_o(uart_tx_wire)
  );

  integer fd;

  always #5 clk = ~clk;
  initial begin
    fd = $fopen("reg.log", "w");
    $dumpfile("tb_minisys_soc.vcd");
    $dumpvars(0, tb_minisys_soc);

    clk = 1'b0;
    rst = 1'b1;
    rx = 1'b1;
    uart_tx_enable = 0;
    uart_tx_data = "a";

    #15 rst = 1'b0;

    // #100000;
    // uart_tx_enable = 1;
    // #10 uart_tx_enable = 0;

    #100000000;
    $fclose(fd);
    $finish();
  end

  always @(uut_soc.core.pipeline_ctrl.mem_wb_pc_r) begin
    // verilog_format: off
    $fdisplay(fd, "ra\t%h", uut_soc.core.regfile.x1_ra_r);
    $fdisplay(fd, "sp\t%h", uut_soc.core.regfile.x2_sp_r);
    $fdisplay(fd, "gp\t%h", uut_soc.core.regfile.x3_gp_r);
    $fdisplay(fd, "tp\t%h", uut_soc.core.regfile.x4_tp_r);
    $fdisplay(fd, "t0\t%h", uut_soc.core.regfile.x5_t0_r);
    $fdisplay(fd, "t1\t%h", uut_soc.core.regfile.x6_t1_r);
    $fdisplay(fd, "t2\t%h", uut_soc.core.regfile.x7_t2_r);
    $fdisplay(fd, "fp\t%h", uut_soc.core.regfile.x8_s0_r);
    $fdisplay(fd, "s1\t%h", uut_soc.core.regfile.x9_s1_r);
    $fdisplay(fd, "a0\t%h", uut_soc.core.regfile.x10_a0_r);
    $fdisplay(fd, "a1\t%h", uut_soc.core.regfile.x11_a1_r);
    $fdisplay(fd, "a2\t%h", uut_soc.core.regfile.x12_a2_r);
    $fdisplay(fd, "a3\t%h", uut_soc.core.regfile.x13_a3_r);
    $fdisplay(fd, "a4\t%h", uut_soc.core.regfile.x14_a4_r);
    $fdisplay(fd, "a5\t%h", uut_soc.core.regfile.x15_a5_r);
    $fdisplay(fd, "a6\t%h", uut_soc.core.regfile.x16_a6_r);
    $fdisplay(fd, "a7\t%h", uut_soc.core.regfile.x17_a7_r);
    $fdisplay(fd, "s2\t%h", uut_soc.core.regfile.x18_s2_r);
    $fdisplay(fd, "s3\t%h", uut_soc.core.regfile.x19_s3_r);
    $fdisplay(fd, "s4\t%h", uut_soc.core.regfile.x20_s4_r);
    $fdisplay(fd, "s5\t%h", uut_soc.core.regfile.x21_s5_r);
    $fdisplay(fd, "s6\t%h", uut_soc.core.regfile.x22_s6_r);
    $fdisplay(fd, "s7\t%h", uut_soc.core.regfile.x23_s7_r);
    $fdisplay(fd, "s8\t%h", uut_soc.core.regfile.x24_s8_r);
    $fdisplay(fd, "s9\t%h", uut_soc.core.regfile.x25_s9_r);
    $fdisplay(fd, "s10\t%h", uut_soc.core.regfile.x26_s10_r);
    $fdisplay(fd, "s11\t%h", uut_soc.core.regfile.x27_s11_r);
    $fdisplay(fd, "t3\t%h", uut_soc.core.regfile.x28_t3_r);
    $fdisplay(fd, "t4\t%h", uut_soc.core.regfile.x29_t4_r);
    $fdisplay(fd, "t5\t%h", uut_soc.core.regfile.x30_t5_r);
    $fdisplay(fd, "t6\t%h", uut_soc.core.regfile.x31_t6_r);
    $fdisplay(fd, "pc\t%h", uut_soc.core.pipeline_ctrl.mem_wb_pc_r);
    $fdisplay(fd, "---------------------------------------------------");
  end

  //   initial begin
  //     $monitor("committed pc: %h, inst: %h", uut_core.pipeline_ctrl.mem_wb_pc_r,
  //              uut_core.pipeline_ctrl.mem_wb_inst_r);
  //   end
endmodule
