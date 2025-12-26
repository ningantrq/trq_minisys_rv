`timescale 1ns / 1ps
`include "../core/core_defs.v"

module test_divider ();
  reg         clk;
  reg         rst;

  reg  [31:0] inst;
  reg  [31:0] rs1_data;
  reg  [31:0] rs2_data;
  reg         enable;

  wire        stall;
  wire [31:0] rd_data;
  reg  [31:0] quotient;
  reg  [31:0] remainder;

  core_divider uut (
      .clk_i(clk),
      .rst_i(rst),
      .inst_i(inst),
      .rs1_data_i(rs1_data),
      .rs2_data_i(rs2_data),
      .enable_i(enable),
      .stall_o(stall),
      .rd_data_o(rd_data)
  );

  always #5 clk = ~clk;

  localparam DIV_TB_NUM = 11;
  reg [31:0] div_rs1_data_arr[DIV_TB_NUM - 1:0];
  reg [31:0] div_rs2_data_arr[DIV_TB_NUM - 1:0];

  integer i;

  initial begin
    $dumpfile("test_divider.vcd");
    $dumpvars(0, test_divider);

    clk = 1'b0;
    rst = 1'b1;
    enable = 1'b0;

    #10 rst = 1'b0;

    div_rs1_data_arr[0]  = 32'h00000001;
    div_rs2_data_arr[0]  = 32'h00000001;

    div_rs1_data_arr[1]  = 32'h20241107;
    div_rs2_data_arr[1]  = 32'h19491001;

    div_rs1_data_arr[2]  = 32'h00000001;
    div_rs2_data_arr[2]  = -32'h00000001;

    div_rs1_data_arr[3]  = 32'h20241107;
    div_rs2_data_arr[3]  = -32'h19491001;

    div_rs1_data_arr[4]  = -32'h00000001;
    div_rs2_data_arr[4]  = 32'h00000001;

    div_rs1_data_arr[5]  = -32'h20241107;
    div_rs2_data_arr[5]  = 32'h19491001;

    div_rs1_data_arr[6]  = -32'h00000001;
    div_rs2_data_arr[6]  = -32'h00000001;

    div_rs1_data_arr[7]  = -32'h20241107;
    div_rs2_data_arr[7]  = -32'h19491001;

    div_rs1_data_arr[8]  = 32'h20241107;
    div_rs2_data_arr[8]  = 32'h00000000;

    div_rs1_data_arr[9]  = -32'h20241107;
    div_rs2_data_arr[9]  = 32'h00000000;

    div_rs1_data_arr[10] = 32'h80000000;
    div_rs2_data_arr[10] = -32'h00000001;

    $display("----- DIVIDER testbench start -----");
    $display("----- DIV & REM testbench start -----");

    for (i = 0; i < DIV_TB_NUM; i = i + 1) begin
      inst     = `INST_DIV;
      rs1_data = div_rs1_data_arr[i];
      rs2_data = div_rs2_data_arr[i];
      enable   = 1'b1;
      #10 enable = 1'b0;

      wait (!stall);
      quotient = rd_data;
      #10;

      inst   = `INST_REM;
      enable = 1'b1;
      #10 enable = 1'b0;

      wait (!stall);
      remainder = rd_data;
      #10;

      $display("rs1_data = %d, rs2_data = %d, quotient = %d, remainder = %d", $signed(rs1_data),
               $signed(rs2_data), $signed(quotient), $signed(remainder));
      #10;
    end

    $display("----- DIV testbench end -----");

    $display("----- DIVU testbench end -----");

    for (i = 0; i < DIV_TB_NUM; i = i + 1) begin
      inst     = `INST_DIVU;
      rs1_data = div_rs1_data_arr[i];
      rs2_data = div_rs2_data_arr[i];
      enable   = 1'b1;
      #10 enable = 1'b0;

      wait (!stall);
      quotient = rd_data;
      #10;

      inst   = `INST_REMU;
      enable = 1'b1;
      #10 enable = 1'b0;

      wait (!stall);
      remainder = rd_data;
      #10;

      $display("rs1_data = %d, rs2_data = %d, quotient = %d, remainder = %d", rs1_data, rs2_data,
               quotient, remainder);
      #10;
    end

    $display("----- DIVU testbench end -----");
    $display("----- DIVIDER testbench end -----");
  end
endmodule
