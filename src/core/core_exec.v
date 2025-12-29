`include "core_defs.v"

module core_exec (
    input        clk_i,
    input        rst_i,
    input [31:0] pc_i,
    input [31:0] inst_i,
    input [31:0] rs1_data_i,
    input [31:0] rs2_data_i,

    input [31:0] imm_i_i, imm_s_i, imm_b_i, imm_u_i, imm_j_i, shamt_i,

    output [31:0] pc_branch_o,// 分支目标地址
    output        pc_take_branch_o,// 是否跳转

    output [31:0] alu_result_o// ALU计算结果
);
  reg [ 3:0] alu_op_r;
  reg [31:0] alu_a_r;
  reg [31:0] alu_b_r;

  // ALU控制
  always @(*) begin
    alu_op_r = `ALU_NONE;
    alu_a_r  = 32'b0;
    alu_b_r  = 32'b0;
    if ((inst_i & `MASK_LUI) == `INST_LUI) begin
      alu_a_r = imm_u_i;
    end else if ((inst_i & `MASK_AUIPC) == `INST_AUIPC) begin
      alu_op_r = `ALU_ADD;
      alu_a_r  = pc_i;
      alu_b_r  = imm_u_i;
    end else if ((inst_i & `MASK_ADDI) == `INST_ADDI) begin
      alu_op_r = `ALU_ADD;
      alu_a_r  = rs1_data_i;
      alu_b_r  = imm_i_i;
    end else if ((inst_i & `MASK_SLTI) == `INST_SLTI) begin
      alu_op_r = `ALU_LESS_THAN_SIGNED;
      alu_a_r  = rs1_data_i;
      alu_b_r  = imm_i_i;
    end else if ((inst_i & `MASK_SLTIU) == `INST_SLTIU) begin
      alu_op_r = `ALU_LESS_THAN;
      alu_a_r  = rs1_data_i;
      alu_b_r  = imm_i_i;
    end else if ((inst_i & `MASK_XORI) == `INST_XORI) begin
      alu_op_r = `ALU_XOR;
      alu_a_r  = rs1_data_i;
      alu_b_r  = imm_i_i;
    end else if ((inst_i & `MASK_ORI) == `INST_ORI) begin
      alu_op_r = `ALU_OR;
      alu_a_r  = rs1_data_i;
      alu_b_r  = imm_i_i;
    end else if ((inst_i & `MASK_ANDI) == `INST_ANDI) begin
      alu_op_r = `ALU_AND;
      alu_a_r  = rs1_data_i;
      alu_b_r  = imm_i_i;
    end else if ((inst_i & `MASK_SLLI) == `INST_SLLI) begin
      alu_op_r = `ALU_SHIFTL;
      alu_a_r  = rs1_data_i;
      alu_b_r  = shamt_i;
    end else if ((inst_i & `MASK_SRLI) == `INST_SRLI) begin
      alu_op_r = `ALU_SHIFTR;
      alu_a_r  = rs1_data_i;
      alu_b_r  = shamt_i;
    end else if ((inst_i & `MASK_SRAI) == `INST_SRAI) begin
      alu_op_r = `ALU_SHIFTR_ARITH;
      alu_a_r  = rs1_data_i;
      alu_b_r  = shamt_i;
    end else if ((inst_i & `MASK_ADD) == `INST_ADD) begin
      alu_op_r = `ALU_ADD;
      alu_a_r  = rs1_data_i;
      alu_b_r  = rs2_data_i;
    end else if ((inst_i & `MASK_SUB) == `INST_SUB) begin
      alu_op_r = `ALU_SUB;
      alu_a_r  = rs1_data_i;
      alu_b_r  = rs2_data_i;
    end else if ((inst_i & `MASK_SLL) == `INST_SLL) begin
      alu_op_r = `ALU_SHIFTL;
      alu_a_r  = rs1_data_i;
      alu_b_r  = rs2_data_i;
    end else if ((inst_i & `MASK_SLT) == `INST_SLT) begin
      alu_op_r = `ALU_LESS_THAN_SIGNED;
      alu_a_r  = rs1_data_i;
      alu_b_r  = rs2_data_i;
    end else if ((inst_i & `MASK_SLTU) == `INST_SLTU) begin
      alu_op_r = `ALU_LESS_THAN;
      alu_a_r  = rs1_data_i;
      alu_b_r  = rs2_data_i;
    end else if ((inst_i & `MASK_XOR) == `INST_XOR) begin
      alu_op_r = `ALU_XOR;
      alu_a_r  = rs1_data_i;
      alu_b_r  = rs2_data_i;
    end else if ((inst_i & `MASK_SRL) == `INST_SRL) begin
      alu_op_r = `ALU_SHIFTR;
      alu_a_r  = rs1_data_i;
      alu_b_r  = rs2_data_i;
    end else if ((inst_i & `MASK_SRA) == `INST_SRA) begin
      alu_op_r = `ALU_SHIFTR_ARITH;
      alu_a_r  = rs1_data_i;
      alu_b_r  = rs2_data_i;
    end else if ((inst_i & `MASK_OR) == `INST_OR) begin
      alu_op_r = `ALU_OR;
      alu_a_r  = rs1_data_i;
      alu_b_r  = rs2_data_i;
    end else if ((inst_i & `MASK_AND) == `INST_AND) begin
      alu_op_r = `ALU_AND;
      alu_a_r  = rs1_data_i;
      alu_b_r  = rs2_data_i;
    end else if (((inst_i & `MASK_JAL) == `INST_JAL) ||  // verilog_format: off
                 ((inst_i & `MASK_JALR) == `INST_JALR)) begin // verilog_format: on
      alu_op_r = `ALU_ADD;
      alu_a_r  = pc_i;
      alu_b_r  = 32'd4;
    end else if (((inst_i & `MASK_LB) == `INST_LB) ||
                 ((inst_i & `MASK_LH) == `INST_LH) ||
                 ((inst_i & `MASK_LW) == `INST_LW) ||
                 ((inst_i & `MASK_LBU) == `INST_LBU) ||
                 ((inst_i & `MASK_LHU) == `INST_LHU)) begin
      alu_op_r = `ALU_ADD;
      alu_a_r  = rs1_data_i;
      alu_b_r  = imm_i_i;
    end else if (((inst_i & `MASK_SB) == `INST_SB) ||
                 ((inst_i & `MASK_SH) == `INST_SH) ||
                 ((inst_i & `MASK_SW) == `INST_SW)) begin
      alu_op_r = `ALU_ADD;
      alu_a_r  = rs1_data_i;
      alu_b_r  = imm_s_i;
    end
  end

  wire [31:0] alu_result_w;
  reg  [31:0] alu_result_r;
  core_alu alu (
      .alu_op_i(alu_op_r),
      .alu_a_i (alu_a_r),
      .alu_b_i (alu_b_r),
      .alu_r_o (alu_result_w)
  );

  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      alu_result_r <= 32'b0;
    end else begin
      alu_result_r <= alu_result_w;
    end
  end
  assign alu_result_o = alu_result_r;

  // 分支判断
  reg        pc_take_branch_r;
  reg [31:0] pc_branch_r;

  reg [31:0] rs1_rs2_diff_r;
  reg [31:0] rs2_rs1_diff_r;

  always @(*) begin
    pc_branch_r      = pc_i + imm_b_i;
    pc_take_branch_r = 1'b0;
    rs1_rs2_diff_r   = rs1_data_i - rs2_data_i;
    rs2_rs1_diff_r   = rs2_data_i - rs1_data_i;

    if ((inst_i & `MASK_JAL) == `INST_JAL) begin
      pc_branch_r      = pc_i + {imm_j_i[31:1], 1'b0};
      pc_take_branch_r = 1'b1;
    end else if ((inst_i & `MASK_JALR) == `INST_JALR) begin
      pc_branch_r      = rs1_data_i + imm_i_i;
      pc_take_branch_r = 1'b1;
    end else if ((inst_i & `MASK_BEQ) == `INST_BEQ) begin
      pc_take_branch_r = (rs1_data_i == rs2_data_i);
    end else if ((inst_i & `MASK_BNE) == `INST_BNE) begin
      pc_take_branch_r = (rs1_data_i != rs2_data_i);
    end else if ((inst_i & `MASK_BLT) == `INST_BLT) begin
      pc_take_branch_r = (rs1_data_i[31] != rs2_data_i[31]) ? rs1_data_i[31] : rs1_rs2_diff_r[31];
    end else if ((inst_i & `MASK_BGE) == `INST_BGE) begin
      pc_take_branch_r = (rs1_data_i == rs2_data_i) ||
                         ((rs1_data_i[31] != rs2_data_i[31]) ?
                         rs2_data_i[31] : rs2_rs1_diff_r[31]);
    end else if ((inst_i & `MASK_BLTU) == `INST_BLTU) begin
      pc_take_branch_r = (rs1_data_i < rs2_data_i);
    end else if ((inst_i & `MASK_BGEU) == `INST_BGEU) begin
      pc_take_branch_r = (rs1_data_i == rs2_data_i) || (rs1_data_i > rs2_data_i);
    end
  end

  assign pc_branch_o      = pc_branch_r;
  assign pc_take_branch_o = pc_take_branch_r;
endmodule
