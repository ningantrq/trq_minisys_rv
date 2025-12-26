module core_top (
    input clk_i,
    input rst_i,

    input timer_interrupt_i,

    input  [31:0] iram_data_i,
    input         iram_done_i,
    output        iram_enable_o,
    output [31:0] iram_addr_o,

    input  [31:0] dram_data_rd_i,
    input         dram_done_i,
    output        dram_enable_o,
    output        dram_wr_o,
    output        dram_rd_o,
    output [31:0] dram_addr_o,
    output [31:0] dram_data_wr_o,
    output [31:0] dram_mask_wr_o
);

  // IF
  wire        if_enable_i_w;
  wire [31:0] if_mem_data_i_w;
  wire        if_mem_done_i_w;

  assign if_mem_data_i_w = iram_data_i;
  assign if_mem_done_i_w = iram_done_i;

  wire [31:0] if_pc_o_w;
  wire [31:0] if_inst_o_w;
  wire [31:0] if_mem_addr_o_w;
  wire        if_mem_enable_o_w;
  wire        if_stall_o_w;

  assign iram_enable_o = if_mem_enable_o_w;
  assign iram_addr_o   = if_mem_addr_o_w;

  core_fetch fetch (
      .clk_i(clk_i),
      .rst_i(rst_i),
      .pc_branch_i(mem_pc_branch_i_w),
      .pc_take_branch_i(mem_pc_take_branch_i_w),
      .enable_i(if_enable_i_w),
      .mem_data_i(if_mem_data_i_w),
      .mem_done_i(if_mem_done_i_w),
      .pc_o(if_pc_o_w),
      .inst_o(if_inst_o_w),
      .mem_addr_o(if_mem_addr_o_w),
      .mem_enable_o(if_mem_enable_o_w),
      .stall_o(if_stall_o_w)
  );

  // ID
  wire [31:0] id_inst_i_w;
  wire [31:0] id_rs1_o_w;
  wire [31:0] id_rs2_o_w;
  wire [31:0] id_rd_o_w;
  wire [31:0] id_imm_i_o_w;
  wire [31:0] id_imm_s_o_w;
  wire [31:0] id_imm_b_o_w;
  wire [31:0] id_imm_u_o_w;
  wire [31:0] id_imm_j_o_w;
  wire [31:0] id_shamt_o_w;
  wire        id_invalid_o_w;
  wire        id_lsu_o_w;
  wire        id_mem_read_o_w;
  wire        id_mem_write_o_w;
  wire        id_lsu_o_w;
  wire        id_mul_o_w;
  wire        id_div_o_w;
  wire        id_csr_o_w;
  wire        id_rd_valid_o_w;

  core_decode decode (
      .inst_i(id_inst_i_w),
      .rs1_o(id_rs1_o_w),
      .rs2_o(id_rs2_o_w),
      .rd_o(id_rd_o_w),
      .imm_i_o(id_imm_i_o_w),
      .imm_s_o(id_imm_s_o_w),
      .imm_b_o(id_imm_b_o_w),
      .imm_u_o(id_imm_u_o_w),
      .imm_j_o(id_imm_j_o_w),
      .shamt_o(id_shamt_o_w),
      .invalid_o(id_invalid_o_w),
      .lsu_o(id_lsu_o_w),
      .mem_read_o(id_mem_read_o_w),
      .mem_write_o(id_mem_write_o_w),
      .mul_o(id_mul_o_w),
      .div_o(id_div_o_w),
      .csr_o(id_csr_o_w),
      .rd_valid_o(id_rd_valid_o_w)
  );

  wire [31:0] id_rs1_data_o_w;
  wire [31:0] id_rs2_data_o_w;

  wire [ 4:0] regfile_wb_rd_w;
  wire [31:0] regfile_wb_rd_data_w;

  core_regfile regfile (
      .clk_i(clk_i),
      .rst_i(rst_i),
      .rd_i(regfile_wb_rd_w),
      .ra_i(id_rs1_o_w),
      .rb_i(id_rs2_o_w),
      .rd_data_i(regfile_wb_rd_data_w),
      .ra_data_o(id_rs1_data_o_w),
      .rb_data_o(id_rs2_data_o_w)
  );

  // EX
  wire [31:0] ex_pc_i_w;
  wire [31:0] ex_inst_i_w;
  wire [31:0] ex_rs1_data_i_w;
  wire [31:0] ex_rs2_data_i_w;
  wire [31:0] ex_imm_i_i_w;
  wire [31:0] ex_imm_s_i_w;
  wire [31:0] ex_imm_b_i_w;
  wire [31:0] ex_imm_u_i_w;
  wire [31:0] ex_imm_j_i_w;
  wire [31:0] ex_shamt_i_w;

  wire [31:0] ex_exec_pc_branch_o_w;
  wire        ex_exec_pc_take_branch_o_w;
  wire [31:0] ex_exec_alu_result_o_w;
  wire        ex_multiplier_enable_i_w;
  wire [31:0] ex_multiplier_rd_data_o_w;
  wire        ex_multiplier_stall_o_w;
  wire        ex_divider_enable_i_w;
  wire [31:0] ex_divider_rd_data_o_w;
  wire        ex_divider_stall_o_w;
  wire [31:0] ex_csr_rd_data_o_w;
  wire        ex_csr_branch_o_w;
  wire        ex_csr_interrupt_o_w;

  core_exec exec (
      .clk_i(clk_i),
      .rst_i(rst_i),
      .pc_i(ex_pc_i_w),
      .inst_i(ex_inst_i_w),
      .rs1_data_i(ex_rs1_data_i_w),
      .rs2_data_i(ex_rs2_data_i_w),
      .imm_i_i(ex_imm_i_i_w),
      .imm_s_i(ex_imm_s_i_w),
      .imm_b_i(ex_imm_b_i_w),
      .imm_u_i(ex_imm_u_i_w),
      .imm_j_i(ex_imm_j_i_w),
      .shamt_i(ex_shamt_i_w),
      .pc_branch_o(ex_exec_pc_branch_o_w),
      .pc_take_branch_o(ex_exec_pc_take_branch_o_w),
      .alu_result_o(ex_exec_alu_result_o_w)
  );

  core_multiplier multiplier (
      .clk_i(clk_i),
      .rst_i(rst_i),
      .inst_i(ex_inst_i_w),
      .rs1_data_i(ex_rs1_data_i_w),
      .rs2_data_i(ex_rs2_data_i_w),
      .enable_i(ex_multiplier_enable_i_w),
      .rd_data_o(ex_multiplier_rd_data_o_w),
      .stall_o(ex_multiplier_stall_o_w)
  );

  core_divider divider (
      .clk_i(clk_i),
      .rst_i(rst_i),
      .inst_i(ex_inst_i_w),
      .rs1_data_i(ex_rs1_data_i_w),
      .rs2_data_i(ex_rs2_data_i_w),
      .enable_i(ex_divider_enable_i_w),
      .stall_o(ex_divider_stall_o_w),
      .rd_data_o(ex_divider_rd_data_o_w)
  );

  core_csr csr (
      .clk_i(clk_i),
      .rst_i(rst_i),
      .pc_i(ex_pc_i_w),
      .ex_mem_pc_branch_i(mem_pc_branch_i_w),
      .ex_mem_pc_take_branch_i(mem_pc_take_branch_i_w),
      .inst_i(ex_inst_i_w),
      .rs1_data_i(ex_rs1_data_i_w),
      .timer_interrupt_i(timer_interrupt_i),

      .rd_data_o(ex_csr_rd_data_o_w),
      .branch_o(ex_csr_branch_o_w),
      .interrupt_o(ex_csr_interrupt_o_w)
  );

  // MEM
  wire [31:0] mem_inst_i_w;
  wire [31:0] mem_addr_i_w;
  wire [31:0] mem_data_wr_i_w;
  wire        mem_enable_i_w;
  wire [31:0] mem_pc_branch_i_w;
  wire        mem_pc_take_branch_i_w;
  wire [31:0] mem_mem_data_rd_i_w = dram_data_rd_i;
  wire        mem_mem_done_i_w = dram_done_i;
  wire [31:0] mem_data_rd_o_w;
  wire        mem_mem_rd_o_w;
  wire        mem_mem_wr_o_w;
  wire [31:0] mem_mem_addr_o_w;
  wire        mem_mem_enable_o_w;
  wire [31:0] mem_mem_data_wr_o_w;
  wire [31:0] mem_mem_mask_wr_o_w;
  wire        mem_stall_o_w;

  assign dram_enable_o  = mem_mem_enable_o_w;
  assign dram_wr_o      = mem_mem_wr_o_w;
  assign dram_rd_o      = mem_mem_rd_o_w;
  assign dram_addr_o    = mem_mem_addr_o_w;
  assign dram_data_wr_o = mem_mem_data_wr_o_w;
  assign dram_mask_wr_o = mem_mem_mask_wr_o_w;

  core_lsu lsu (
      .clk_i(clk_i),
      .rst_i(rst_i),
      .inst_i(mem_inst_i_w),
      .addr_i(mem_addr_i_w),
      .data_wr_i(mem_data_wr_i_w),
      .enable_i(mem_enable_i_w),
      .mem_data_rd_i(mem_mem_data_rd_i_w),
      .mem_done_i(mem_mem_done_i_w),
      .data_rd_o(mem_data_rd_o_w),
      .mem_rd_o(mem_mem_rd_o_w),
      .mem_wr_o(mem_mem_wr_o_w),
      .mem_addr_o(mem_mem_addr_o_w),
      .mem_enable_o(mem_mem_enable_o_w),
      .mem_data_wr_o(mem_mem_data_wr_o_w),
      .mem_mask_wr_o(mem_mem_mask_wr_o_w),
      .stall_o(mem_stall_o_w)
  );

  core_pipeline_ctrl pipeline_ctrl (
      .clk_i(clk_i),
      .rst_i(rst_i),
      .if_enable_o(if_enable_i_w),
      .if_pc_i(if_pc_o_w),
      .if_inst_i(if_inst_o_w),
      .if_stall_i(if_stall_o_w),
      .id_inst_o(id_inst_i_w),
      .id_rs1_i(id_rs1_o_w),
      .id_rs2_i(id_rs2_o_w),
      .id_rs1_data_i(id_rs1_data_o_w),
      .id_rs2_data_i(id_rs2_data_o_w),
      .id_rd_i(id_rd_o_w),
      .id_imm_i_i(id_imm_i_o_w),
      .id_imm_s_i(id_imm_s_o_w),
      .id_imm_b_i(id_imm_b_o_w),
      .id_imm_u_i(id_imm_u_o_w),
      .id_imm_j_i(id_imm_j_o_w),
      .id_shamt_i(id_shamt_o_w),
      .id_invalid_i(id_invalid_o_w),
      .id_lsu_i(id_lsu_o_w),
      .id_mem_read_i(id_mem_read_o_w),
      .id_mem_write_i(id_mem_write_o_w),
      .id_mul_i(id_mul_o_w),
      .id_div_i(id_div_o_w),
      .id_csr_i(id_csr_o_w),
      .id_rd_valid_i(id_rd_valid_o_w),
      .ex_pc_o(ex_pc_i_w),
      .ex_inst_o(ex_inst_i_w),
      .ex_rs1_data_o(ex_rs1_data_i_w),
      .ex_rs2_data_o(ex_rs2_data_i_w),
      .ex_imm_i_o(ex_imm_i_i_w),
      .ex_imm_s_o(ex_imm_s_i_w),
      .ex_imm_b_o(ex_imm_b_i_w),
      .ex_imm_u_o(ex_imm_u_i_w),
      .ex_imm_j_o(ex_imm_j_i_w),
      .ex_shamt_o(ex_shamt_i_w),
      .ex_multiplier_enable_o(ex_multiplier_enable_i_w),
      .ex_divider_enable_o(ex_divider_enable_i_w),
      .ex_exec_pc_branch_i(ex_exec_pc_branch_o_w),
      .ex_exec_pc_take_branch_i(ex_exec_pc_take_branch_o_w),
      .ex_exec_alu_result_i(ex_exec_alu_result_o_w),
      .ex_multiplier_rd_data_i(ex_multiplier_rd_data_o_w),
      .ex_multiplier_stall_i(ex_multiplier_stall_o_w),
      .ex_divider_rd_data_i(ex_divider_rd_data_o_w),
      .ex_divider_stall_i(ex_divider_stall_o_w),
      .ex_csr_rd_data_i(ex_csr_rd_data_o_w),
      .ex_csr_branch_i(ex_csr_branch_o_w),
      .ex_csr_interrupt_i(ex_csr_interrupt_o_w),
      .mem_inst_o(mem_inst_i_w),
      .mem_addr_o(mem_addr_i_w),
      .mem_data_wr_o(mem_data_wr_i_w),
      .mem_enable_o(mem_enable_i_w),
      .mem_pc_branch_o(mem_pc_branch_i_w),
      .mem_pc_take_branch_o(mem_pc_take_branch_i_w),
      .mem_data_rd_i(mem_data_rd_o_w),
      .mem_stall_i(mem_stall_o_w),
      .wb_rd_o(regfile_wb_rd_w),
      .wb_rd_value_o(regfile_wb_rd_data_w)
  );
endmodule
