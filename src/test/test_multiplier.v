`timescale 1ns / 1ps
`include "../core/core_defs.v"

module test_multiplier ();
  reg         clk;
  reg         rst;

  reg  [31:0] inst;
  reg  [31:0] rs1_data;
  reg  [31:0] rs2_data;
  reg         enable;

  wire        stall;
  wire [31:0] rd_data;

  reg  [63:0] result;

  core_multiplier uut (
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

  localparam MUL_TB_NUM = 8;
  reg [31:0] mul_rs1_data_arr[MUL_TB_NUM - 1:0];
  reg [31:0] mul_rs2_data_arr[MUL_TB_NUM - 1:0];

  integer i;

  initial begin
    $dumpfile("test_multiplier.vcd");
    $dumpvars(0, test_multiplier);

    clk = 1'b0;
    rst = 1'b1;

    #10 rst = 1'b0;

    mul_rs1_data_arr[0] = 32'h00000001;
    mul_rs2_data_arr[0] = 32'h00000001;

    mul_rs1_data_arr[1] = 32'h20241107;
    mul_rs2_data_arr[1] = 32'h19491001;

    mul_rs1_data_arr[2] = 32'h00000001;
    mul_rs2_data_arr[2] = -32'h00000001;

    mul_rs1_data_arr[3] = 32'h20241107;
    mul_rs2_data_arr[3] = -32'h19491001;

    mul_rs1_data_arr[4] = -32'h00000001;
    mul_rs2_data_arr[4] = 32'h00000001;

    mul_rs1_data_arr[5] = -32'h20241107;
    mul_rs2_data_arr[5] = 32'h19491001;

    mul_rs1_data_arr[6] = -32'h00000001;
    mul_rs2_data_arr[6] = -32'h00000001;

    mul_rs1_data_arr[7] = -32'h20241107;
    mul_rs2_data_arr[7] = -32'h19491001;

    $display("----- MULTIPLIER testbench start -----");
    $display("----- MUL testbench start -----");

    for (i = 0; i < MUL_TB_NUM; i = i + 1) begin
      inst     = `INST_MUL;
      rs1_data = mul_rs1_data_arr[i];
      rs2_data = mul_rs2_data_arr[i];
      enable   = 1'b1;
      #10 enable = 1'b0;

      wait (!stall);
      result[31:0] = rd_data;
      #10;

      inst   = `INST_MULH;
      enable = 1'b1;
      #10 enable = 1'b0;

      wait (!stall);
      result[63:32] = rd_data;
      $display("rs1_data = %d, rs2_data = %d, result = %d", $signed(rs1_data), $signed(rs2_data),
               $signed(result));
      #10;
    end

    $display("----- MUL testbench end -----");

    $display("----- MULSU testbench start -----");

    for (i = 0; i < MUL_TB_NUM; i = i + 1) begin
      inst     = `INST_MUL;
      rs1_data = mul_rs1_data_arr[i];
      rs2_data = mul_rs2_data_arr[i];
      enable   = 1'b1;
      #10 enable = 1'b0;

      wait (!stall);
      result[31:0] = rd_data;
      #10;

      inst   = `INST_MULHSU;
      enable = 1'b1;
      #10 enable = 1'b0;

      wait (!stall);
      result[63:32] = rd_data;
      $display("rs1_data = %d, rs2_data = %d, result = %d", $signed(rs1_data), rs2_data,
               $signed(result));
      #10;
    end

    $display("----- MULSU testbench end -----");

    $display("----- MULU testbench start -----");

    for (i = 0; i < MUL_TB_NUM; i = i + 1) begin
      inst     = `INST_MUL;
      rs1_data = mul_rs1_data_arr[i];
      rs2_data = mul_rs2_data_arr[i];
      enable   = 1'b1;
      #10 enable = 1'b0;

      wait (!stall);
      result[31:0] = rd_data;
      #10;

      inst   = `INST_MULHU;
      enable = 1'b1;
      #10 enable = 1'b0;

      wait (!stall);
      result[63:32] = rd_data;
      $display("rs1_data = %d, rs2_data = %d, result = %d", rs1_data, rs2_data, result);
      #10;
    end

    $display("----- MULU testbench end -----");
    $display("----- MULTIPLIER testbench end -----");
  end
endmodule
