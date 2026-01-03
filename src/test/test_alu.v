`timescale 1ns / 1ps
`include "../core/core_defs.v"

module test_alu ();
  reg  [ 3:0] opcode;
  reg  [31:0] a;
  reg  [31:0] b;
  wire [31:0] r;

  // 实例化ALU
  core_alu alu (
      .alu_op_i(opcode),
      .alu_a_i (a),
      .alu_b_i (b),
      .alu_r_o (r)
  );
  
  integer i;

  initial begin
    $dumpfile("test_alu.vcd");      // 生成波形文件
    $dumpvars(0, test_alu);
    
    // 测试1：逻辑左移 - 遍历所有移位量（0-31位）
    $display("----- SHIFTL test start -----");
    opcode = `ALU_SHIFTL;
    a = 32'hffffffff;              // 全1，方便观察移位效果
    b = 32'b0;
    
    for (i = 0; i < 32; i = i + 1) begin
      b = b + 1'b1;
      #5;                          // 在显示前等待组合逻辑稳定
      $display("a = %b, b = %b, result = %b", a, b, r);
    end
    
    // 测试2：逻辑右移 - 遍历所有移位量
    $display("----- SHIFTR test start -----");
    opcode = `ALU_SHIFTR;
    a = 32'hffffffff;
    b = 32'b0;
    
    for (i = 0; i < 32; i = i + 1) begin
      b = b + 1'b1;
      #5;                          // 在显示前等待组合逻辑稳定
      $display("a = %b, b = %b, result = %b", a, b, r);
    end
    
    // 测试3：算术右移（负数） - 验证符号扩展
    $display("----- SHIFTR_ARITH negative test start -----");
    opcode = `ALU_SHIFTR_ARITH;
    a = 32'h80000000;              // 最小负数
    b = 32'b0;
    
    for (i = 0; i < 32; i = i + 1) begin
      b = b + 1'b1;
      #5;                          // 在显示前等待组合逻辑稳定
      $display("a = %b, b = %b, result = %b", a, b, r);
    end
    
    // 测试4：算术右移（正数） - 验证零扩展
    $display("----- SHIFTR_ARITH positive test start -----");
    a = 32'h7fffffff;              // 最大正数
    b = 32'b0;
    
    for (i = 0; i < 32; i = i + 1) begin
      b = b + 1'b1;
      #5;                          // 在显示前等待组合逻辑稳定
      $display("a = %b, b = %b, result = %b", a, b, r);
    end
    
    // =================================================================
    // 测试5-10：其他运算
    // =================================================================
    
    // 加法测试
    opcode = `ALU_ADD;
    a = 32'h12345678;
    b = 32'h01234567;
    #5;
    $display("ADD: %h + %h = %h", a, b, r);
    
    // 减法测试
    opcode = `ALU_SUB;
    #5;
    $display("SUB: %h - %h = %h", a, b, r);
    
    // 按位与测试
    opcode = `ALU_AND;
    #5;
    $display("AND: %h & %h = %h", a, b, r);
    
    // 按位或测试
    opcode = `ALU_OR;
    #5;
    $display("OR: %h | %h = %h", a, b, r);
    
    // 按位异或测试
    opcode = `ALU_XOR;
    #5;
    $display("XOR: %h ^ %h = %h", a, b, r);
    
    // 无符号比较测试
    opcode = `ALU_LESS_THAN;
    #5;
    $display("SLTU: %h < %h = %d", a, b, r);
    
    // 有符号比较测试
    opcode = `ALU_LESS_THAN_SIGNED;
    a = 32'h12345678;              // 正数
    b = 32'hf1234567;              // 负数
    #5;
    $display("SLT: %h < %h = %d", a, b, r);
  end
endmodule