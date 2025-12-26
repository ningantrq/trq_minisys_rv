`include "core_defs.v"

module core_alu (
  input  [3:0]  alu_op_i,      // 4位操作码，支持16种操作（当前用11种）
  input  [31:0] alu_a_i,       // 32位操作数A（可能是寄存器值、PC、立即数等）
  input  [31:0] alu_b_i,       // 32位操作数B（可能是寄存器值、立即数等）

  output [31:0] alu_r_o        // 32位运算结果
);


  // 减法结果（预先计算，供减法操作使用）
  wire [31:0] alu_sub_r = alu_a_i - alu_b_i;

  // 最终结果寄存器
  reg  [31:0] result_r;
  assign alu_r_o = result_r;

  // 移位量（只使用低5位，因为32位数最多移31位）
  wire [4:0] shift_amount = alu_b_i[4:0];

  always @(alu_op_i or alu_a_i or alu_b_i or alu_sub_r or shift_amount) begin
    result_r = 32'h0;

    case (alu_op_i)

      // 逻辑左移 - 使用Verilog移位运算符
      `ALU_SHIFTL: begin
        result_r = alu_a_i << shift_amount;
      end

      // 逻辑右移 - 使用Verilog移位运算符
      `ALU_SHIFTR: begin
        result_r = alu_a_i >> shift_amount;
      end

      // 算术右移 - 使用Verilog有符号移位运算符
      `ALU_SHIFTR_ARITH: begin
        result_r = $signed(alu_a_i) >>> shift_amount;
      end

      `ALU_ADD: result_r = alu_a_i + alu_b_i;

      `ALU_SUB: result_r = alu_sub_r;

      `ALU_AND: result_r = alu_a_i & alu_b_i;

      `ALU_OR: result_r = alu_a_i | alu_b_i;

      `ALU_XOR: result_r = alu_a_i ^ alu_b_i;

      `ALU_LESS_THAN: begin
        result_r = (alu_a_i < alu_b_i) ? 32'h1 : 32'h0;
      end

      `ALU_LESS_THAN_SIGNED: begin
        result_r = ($signed(alu_a_i) < $signed(alu_b_i)) ? 32'h1 : 32'h0;
      end

      default: result_r = alu_a_i;
    endcase
  end
endmodule
