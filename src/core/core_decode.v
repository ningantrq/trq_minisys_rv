`include "core_defs.v"

module core_decode (
    input [31:0] inst_i,

    output [4:0] rs1_o, rs2_o, rd_o,
    output [31:0] imm_i_o, imm_s_o, imm_b_o, imm_u_o, imm_j_o, shamt_o,
    output invalid_o, lsu_o, mem_read_o, mem_write_o,
    output mul_o, div_o, csr_o, rd_valid_o
);

  // 寄存器地址提取
  assign rs1_o = inst_i[19:15];
  assign rs2_o = inst_i[24:20];
  assign rd_o = inst_i[11:7];

  // 立即数提取
  assign imm_i_o = {{21{inst_i[31]}}, inst_i[30:20]};
  assign imm_s_o = {{21{inst_i[31]}}, inst_i[30:25], inst_i[11:8], inst_i[7]};
  assign imm_b_o = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
  assign imm_u_o = {inst_i[31], inst_i[30:20], inst_i[19:12], 12'b0};
  assign imm_j_o = {
    {12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:25], inst_i[24:21], 1'b0
  };
  assign shamt_o = {27'b0, inst_i[24:20]};


  // 指令有效性检查（列举所有支持的指令）
  wire invalid_w = ~(
    (( inst_i & `MASK_LUI       ) == `INST_LUI       ) ||
    (( inst_i & `MASK_AUIPC     ) == `INST_AUIPC     ) ||
    (( inst_i & `MASK_JAL       ) == `INST_JAL       ) ||
    (( inst_i & `MASK_JALR      ) == `INST_JALR      ) ||
    (( inst_i & `MASK_BEQ       ) == `INST_BEQ       ) ||
    (( inst_i & `MASK_BNE       ) == `INST_BNE       ) ||
    (( inst_i & `MASK_BLT       ) == `INST_BLT       ) ||
    (( inst_i & `MASK_BGE       ) == `INST_BGE       ) ||
    (( inst_i & `MASK_BLTU      ) == `INST_BLTU      ) ||
    (( inst_i & `MASK_BGEU      ) == `INST_BGEU      ) ||
    (( inst_i & `MASK_LB        ) == `INST_LB        ) ||
    (( inst_i & `MASK_LH        ) == `INST_LH        ) ||
    (( inst_i & `MASK_LW        ) == `INST_LW        ) ||
    (( inst_i & `MASK_LBU       ) == `INST_LBU       ) ||
    (( inst_i & `MASK_LHU       ) == `INST_LHU       ) ||
    (( inst_i & `MASK_SB        ) == `INST_SB        ) ||
    (( inst_i & `MASK_SH        ) == `INST_SH        ) ||
    (( inst_i & `MASK_SW        ) == `INST_SW        ) ||
    (( inst_i & `MASK_ADDI      ) == `INST_ADDI      ) ||
    (( inst_i & `MASK_SLTI      ) == `INST_SLTI      ) ||
    (( inst_i & `MASK_SLTIU     ) == `INST_SLTIU     ) ||
    (( inst_i & `MASK_XORI      ) == `INST_XORI      ) ||
    (( inst_i & `MASK_ORI       ) == `INST_ORI       ) ||
    (( inst_i & `MASK_ANDI      ) == `INST_ANDI      ) ||
    (( inst_i & `MASK_SLLI      ) == `INST_SLLI      ) ||
    (( inst_i & `MASK_SRLI      ) == `INST_SRLI      ) ||
    (( inst_i & `MASK_SRAI      ) == `INST_SRAI      ) ||
    (( inst_i & `MASK_ADD       ) == `INST_ADD       ) ||
    (( inst_i & `MASK_SUB       ) == `INST_SUB       ) ||
    (( inst_i & `MASK_SLL       ) == `INST_SLL       ) ||
    (( inst_i & `MASK_SLT       ) == `INST_SLT       ) ||
    (( inst_i & `MASK_SLTU      ) == `INST_SLTU      ) ||
    (( inst_i & `MASK_XOR       ) == `INST_XOR       ) ||
    (( inst_i & `MASK_SRL       ) == `INST_SRL       ) ||
    (( inst_i & `MASK_SRA       ) == `INST_SRA       ) ||
    (( inst_i & `MASK_OR        ) == `INST_OR        ) ||
    (( inst_i & `MASK_AND       ) == `INST_AND       ) ||
    (( inst_i & `MASK_FENCE     ) == `INST_FENCE     ) ||
    (( inst_i & `MASK_PAUSE     ) == `INST_PAUSE     ) ||
    (( inst_i & `MASK_ECALL     ) == `INST_ECALL     ) ||
    (( inst_i & `MASK_EBREAK    ) == `INST_EBREAK    ) ||
    (( inst_i & `MASK_MUL       ) == `INST_MUL       ) ||
    (( inst_i & `MASK_MULH      ) == `INST_MULH      ) ||
    (( inst_i & `MASK_MULHSU    ) == `INST_MULHSU    ) ||
    (( inst_i & `MASK_MULHU     ) == `INST_MULHU     ) ||
    (( inst_i & `MASK_DIV       ) == `INST_DIV       ) ||
    (( inst_i & `MASK_DIVU      ) == `INST_DIVU      ) ||
    (( inst_i & `MASK_REM       ) == `INST_REM       ) ||
    (( inst_i & `MASK_REMU      ) == `INST_REMU      )
  );
  assign invalid_o = invalid_w;

  // 控制信号生成
  assign lsu_o =
    (( inst_i & `MASK_LB        ) == `INST_LB        ) ||
    (( inst_i & `MASK_LH        ) == `INST_LH        ) ||
    (( inst_i & `MASK_LW        ) == `INST_LW        ) ||
    (( inst_i & `MASK_LBU       ) == `INST_LBU       ) ||
    (( inst_i & `MASK_LHU       ) == `INST_LHU       ) ||
    (( inst_i & `MASK_SB        ) == `INST_SB        ) ||
    (( inst_i & `MASK_SH        ) == `INST_SH        ) ||
    (( inst_i & `MASK_SW        ) == `INST_SW        );

  assign mem_read_o =
    (( inst_i & `MASK_LB        ) == `INST_LB        ) ||
    (( inst_i & `MASK_LH        ) == `INST_LH        ) ||
    (( inst_i & `MASK_LW        ) == `INST_LW        ) ||
    (( inst_i & `MASK_LBU       ) == `INST_LBU       ) ||
    (( inst_i & `MASK_LHU       ) == `INST_LHU       );

  assign mem_write_o =
    (( inst_i & `MASK_SB        ) == `INST_SB        ) ||
    (( inst_i & `MASK_SH        ) == `INST_SH        ) ||
    (( inst_i & `MASK_SW        ) == `INST_SW        );

  assign mul_o =
    (( inst_i & `MASK_MUL       ) == `INST_MUL       ) ||
    (( inst_i & `MASK_MULH      ) == `INST_MULH      ) ||
    (( inst_i & `MASK_MULHSU    ) == `INST_MULHSU    ) ||
    (( inst_i & `MASK_MULHU     ) == `INST_MULHU     );

  assign div_o =
    (( inst_i & `MASK_DIV       ) == `INST_DIV       ) ||
    (( inst_i & `MASK_DIVU      ) == `INST_DIVU      ) ||
    (( inst_i & `MASK_REM       ) == `INST_REM       ) ||
    (( inst_i & `MASK_REMU      ) == `INST_REMU      );

  // rd_valid: 所有需要写回寄存器的指令（不包括Branch和Store）
  assign rd_valid_o =
    (( inst_i & `MASK_LUI       ) == `INST_LUI       ) ||
    (( inst_i & `MASK_AUIPC     ) == `INST_AUIPC     ) ||
    (( inst_i & `MASK_JAL       ) == `INST_JAL       ) ||
    (( inst_i & `MASK_JALR      ) == `INST_JALR      ) ||
    (( inst_i & `MASK_LB        ) == `INST_LB        ) ||
    (( inst_i & `MASK_LH        ) == `INST_LH        ) ||
    (( inst_i & `MASK_LW        ) == `INST_LW        ) ||
    (( inst_i & `MASK_LBU       ) == `INST_LBU       ) ||
    (( inst_i & `MASK_LHU       ) == `INST_LHU       ) ||
    (( inst_i & `MASK_ADDI      ) == `INST_ADDI      ) ||
    (( inst_i & `MASK_SLTI      ) == `INST_SLTI      ) ||
    (( inst_i & `MASK_SLTIU     ) == `INST_SLTIU     ) ||
    (( inst_i & `MASK_XORI      ) == `INST_XORI      ) ||
    (( inst_i & `MASK_ORI       ) == `INST_ORI       ) ||
    (( inst_i & `MASK_ANDI      ) == `INST_ANDI      ) ||
    (( inst_i & `MASK_SLLI      ) == `INST_SLLI      ) ||
    (( inst_i & `MASK_SRLI      ) == `INST_SRLI      ) ||
    (( inst_i & `MASK_SRAI      ) == `INST_SRAI      ) ||
    (( inst_i & `MASK_ADD       ) == `INST_ADD       ) ||
    (( inst_i & `MASK_SUB       ) == `INST_SUB       ) ||
    (( inst_i & `MASK_SLL       ) == `INST_SLL       ) ||
    (( inst_i & `MASK_SLT       ) == `INST_SLT       ) ||
    (( inst_i & `MASK_SLTU      ) == `INST_SLTU      ) ||
    (( inst_i & `MASK_XOR       ) == `INST_XOR       ) ||
    (( inst_i & `MASK_SRL       ) == `INST_SRL       ) ||
    (( inst_i & `MASK_SRA       ) == `INST_SRA       ) ||
    (( inst_i & `MASK_OR        ) == `INST_OR        ) ||
    (( inst_i & `MASK_AND       ) == `INST_AND       ) ||
    (( inst_i & `MASK_MUL       ) == `INST_MUL       ) ||
    (( inst_i & `MASK_MULH      ) == `INST_MULH      ) ||
    (( inst_i & `MASK_MULHSU    ) == `INST_MULHSU    ) ||
    (( inst_i & `MASK_MULHU     ) == `INST_MULHU     ) ||
    (( inst_i & `MASK_DIV       ) == `INST_DIV       ) ||
    (( inst_i & `MASK_DIVU      ) == `INST_DIVU      ) ||
    (( inst_i & `MASK_REM       ) == `INST_REM       ) ||
    (( inst_i & `MASK_REMU      ) == `INST_REMU      ) ||
    (( inst_i & `MASK_CSRRW     ) == `INST_CSRRW     ) ||
    (( inst_i & `MASK_CSRRS     ) == `INST_CSRRS     ) ||
    (( inst_i & `MASK_CSRRC     ) == `INST_CSRRC     ) ||
    (( inst_i & `MASK_CSRRWI    ) == `INST_CSRRWI    ) ||
    (( inst_i & `MASK_CSRRSI    ) == `INST_CSRRSI    ) ||
    (( inst_i & `MASK_CSRRCI    ) == `INST_CSRRCI    );

  assign csr_o =
    (( inst_i & `MASK_EBREAK    ) == `INST_EBREAK    ) ||
    (( inst_i & `MASK_ECALL     ) == `INST_ECALL     ) ||
    (( inst_i & `MASK_FENCE     ) == `INST_FENCE     ) ||
    (( inst_i & `MASK_PAUSE     ) == `INST_PAUSE     ) ||
    (( inst_i & `MASK_CSRRW     ) == `INST_CSRRW     ) ||
    (( inst_i & `MASK_CSRRS     ) == `INST_CSRRS     ) ||
    (( inst_i & `MASK_CSRRC     ) == `INST_CSRRC     ) ||
    (( inst_i & `MASK_CSRRWI    ) == `INST_CSRRWI    ) ||
    (( inst_i & `MASK_CSRRSI    ) == `INST_CSRRSI    ) ||
    (( inst_i & `MASK_CSRRCI    ) == `INST_CSRRCI    );
endmodule
