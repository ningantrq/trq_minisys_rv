`include "core_defs.v"

module core_pipeline_ctrl (
    input clk_i,
    input rst_i,

    // ========== IF/ID接口 ==========
    output        if_enable_o,     // 指令取指使能信号（控制Fetch模块）
    input  [31:0] if_pc_i,         // 当前取指PC
    input  [31:0] if_inst_i,       // 取到的指令
    input         if_stall_i,      // Fetch模块暂停信号（等待指令内存）
    output [31:0] id_inst_o,       // 传递给ID阶段的指令

    // ========== ID/EX接口 ==========
    // ID阶段解码后的输入信号
    input  [ 4:0] id_rs1_i,        // 源寄存器1编号
    input  [ 4:0] id_rs2_i,        // 源寄存器2编号
    input  [31:0] id_rs1_data_i,   // 源寄存器1数据（从寄存器堆读取）
    input  [31:0] id_rs2_data_i,   // 源寄存器2数据
    input  [ 4:0] id_rd_i,         // 目标寄存器编号
    input  [31:0] id_imm_i_i,      // I型立即数
    input  [31:0] id_imm_s_i,      // S型立即数
    input  [31:0] id_imm_b_i,      // B型立即数
    input  [31:0] id_imm_u_i,      // U型立即数
    input  [31:0] id_imm_j_i,      // J型立即数
    input  [31:0] id_shamt_i,      // 移位量
    input         id_invalid_i,    // 非法指令标志
    input         id_lsu_i,        // LSU指令标志（Load/Store）
    input         id_mem_read_i,   // 内存读标志
    input         id_mem_write_i,  // 内存写标志
    input         id_mul_i,        // 乘法指令标志
    input         id_div_i,        // 除法指令标志
    input         id_csr_i,        // CSR指令标志
    input         id_rd_valid_i,   // 目标寄存器有效标志

    // 输出给EX阶段的信号（流水线寄存器输出）
    output [31:0] ex_pc_o,                // EX阶段PC
    output [31:0] ex_inst_o,              // EX阶段指令
    output [31:0] ex_rs1_data_o,          // EX阶段rs1数据（经过前递）
    output [31:0] ex_rs2_data_o,          // EX阶段rs2数据（经过前递）
    output [31:0] ex_imm_i_o,             // EX阶段立即数
    output [31:0] ex_imm_s_o,
    output [31:0] ex_imm_b_o,
    output [31:0] ex_imm_u_o,
    output [31:0] ex_imm_j_o,
    output [31:0] ex_shamt_o,
    output        ex_multiplier_enable_o, // 乘法器使能
    output        ex_divider_enable_o,    // 除法器使能

    // ========== EX/MEM接口 ==========
    // EX阶段执行结果输入
    input  [31:0] ex_exec_pc_branch_i,      // 分支目标地址（从ALU计算得到）
    input         ex_exec_pc_take_branch_i, // 分支跳转标志（分支判断结果）
    input  [31:0] ex_exec_alu_result_i,     // ALU计算结果
    input  [31:0] ex_multiplier_rd_data_i,  // 乘法器结果
    input         ex_multiplier_stall_i,    // 乘法器暂停请求
    input  [31:0] ex_divider_rd_data_i,     // 除法器结果
    input         ex_divider_stall_i,       // 除法器暂停请求
    input  [31:0] ex_csr_rd_data_i,         // CSR读取结果
    input         ex_csr_branch_i,          // CSR分支信号（ECALL/EBREAK/MRET）
    input         ex_csr_interrupt_i,       // CSR中断信号

    // 输出给MEM阶段的信号
    output [31:0] mem_inst_o,          // MEM阶段指令
    output [31:0] mem_addr_o,          // 内存访问地址（来自ALU结果）
    output [31:0] mem_data_wr_o,       // 内存写入数据（来自rs2）
    output        mem_enable_o,        // LSU使能信号
    output [31:0] mem_pc_branch_o,     // 分支目标地址（传递给Fetch）
    output        mem_pc_take_branch_o,// 分支跳转标志（传递给Fetch）

    // ========== MEM/WB接口 ==========
    input  [31:0] mem_data_rd_i,       // 内存读取的数据
    input         mem_stall_i,         // 内存暂停信号（等待数据内存）

    output [ 4:0] wb_rd_o,             // WB阶段目标寄存器编号
    output [31:0] wb_rd_value_o        // WB阶段写回数据
);

  // ========== IF/ID流水线寄存器 ==========
  reg         if_enable_r;      // Fetch使能寄存器
  reg  [31:0] if_id_pc_r;       // IF阶段PC
  reg  [31:0] if_id_inst_r;     // IF阶段取到的指令
  
  // ========== ID/EX流水线寄存器 ==========
  // 控制和数据信号
  reg  [31:0] id_ex_pc_r;       // ID阶段PC
  reg  [31:0] id_ex_inst_r;     // ID阶段指令
  
  // 寄存器编号
  reg  [ 4:0] id_ex_rs1_r;      // 源寄存器1编号
  reg  [ 4:0] id_ex_rs2_r;      // 源寄存器2编号
  reg  [ 4:0] id_ex_rd_r;       // 目标寄存器编号
  
  // 寄存器数据
  reg  [31:0] id_ex_rs1_data_r; // 源寄存器1数据
  reg  [31:0] id_ex_rs2_data_r; // 源寄存器2数据
  
  // 立即数（5种格式）
  reg  [31:0] id_ex_imm_i_r;    // I型立即数
  reg  [31:0] id_ex_imm_s_r;    // S型立即数
  reg  [31:0] id_ex_imm_b_r;    // B型立即数
  reg  [31:0] id_ex_imm_u_r;    // U型立即数
  reg  [31:0] id_ex_imm_j_r;    // J型立即数
  reg  [31:0] id_ex_shamt_r;    // 移位量
  
  // 控制信号
  reg         id_ex_invalid_r;           // 非法指令标志
  reg         id_ex_lsu_r;               // LSU指令标志
  reg         id_ex_mem_read_r;          // 内存读标志
  reg         id_ex_mem_write_r;         // 内存写标志
  reg         id_ex_mul_r;               // 乘法指令标志
  reg         id_ex_div_r;               // 除法指令标志
  reg         id_ex_csr_r;               // CSR指令标志
  reg         id_ex_rd_valid_r;          // 目标寄存器有效标志
  reg         id_ex_multiplier_enable_r; // 乘法器使能
  reg         id_ex_divider_enable_r;    // 除法器使能

  // ========== EX/MEM流水线寄存器 ==========
  reg  [31:0] ex_mem_pc_r;             // EX阶段PC
  reg  [31:0] ex_mem_inst_r;           // EX阶段指令
  reg  [31:0] ex_mem_rs2_data_r;       // rs2数据（用于Store指令）
  reg  [31:0] ex_mem_pc_branch_r;      // 分支目标地址
  reg         ex_mem_pc_take_branch_r; // 分支跳转标志
  reg  [31:0] ex_mem_ex_result_r;      // EX阶段执行结果
  reg  [ 4:0] ex_mem_rd_r;             // 目标寄存器编号
  reg         ex_mem_rd_valid_r;       // 目标寄存器有效标志
  reg         ex_mem_enable_r;         // LSU使能
  reg         ex_mem_mem_read_r;       // 内存读标志
  
  // CSR分支相关寄存器
  reg         ex_csr_branch_r;         // CSR分支标志（延迟一拍）
  reg  [31:0] ex_csr_rd_data_r;        // CSR数据（延迟一拍）

  // ========== MEM/WB流水线寄存器 ==========
  reg  [31:0] mem_wb_pc_r;       // MEM阶段PC（用于调试）
  reg  [31:0] mem_wb_inst_r;     // MEM阶段指令（用于调试）
  reg  [ 4:0] mem_wb_rd_r;       // 目标寄存器编号
  reg  [31:0] mem_wb_rd_value_r; // 目标寄存器数据（最终写回值）
  
  // ========== 数据前递相关wire信号 ==========
  wire [31:0] ex_rs1_data_w;     // 前递后的rs1数据
  wire [31:0] ex_rs2_data_w;     // 前递后的rs2数据
  
  // ========== 冒险检测相关寄存器 ==========
  reg         control_harzard_r; // 控制冒险标志（延迟一拍处理）

  // 输出连接
  assign if_enable_o            = if_enable_r;
  assign id_inst_o              = if_id_inst_r;
  assign ex_pc_o                = id_ex_pc_r;
  assign ex_inst_o              = id_ex_inst_r;
  assign ex_rs1_data_o          = ex_rs1_data_w;//前递后的数据
  assign ex_rs2_data_o          = ex_rs2_data_w;//前递后的数据
  assign ex_imm_i_o             = id_ex_imm_i_r;
  assign ex_imm_s_o             = id_ex_imm_s_r;
  assign ex_imm_b_o             = id_ex_imm_b_r;
  assign ex_imm_u_o             = id_ex_imm_u_r;
  assign ex_imm_j_o             = id_ex_imm_j_r;
  assign ex_shamt_o             = id_ex_shamt_r;
  assign ex_multiplier_enable_o = id_ex_multiplier_enable_r;
  assign ex_divider_enable_o    = id_ex_divider_enable_r;
  assign mem_inst_o             = ex_mem_inst_r;
  assign mem_addr_o             = ex_mem_ex_result_r;// 内存地址来自EX结果
  assign mem_data_wr_o          = ex_mem_rs2_data_r;// Store数据来自rs2
  assign mem_enable_o           = ex_mem_enable_r;
  assign mem_pc_branch_o        = ex_mem_pc_branch_r;
  assign mem_pc_take_branch_o   = ex_mem_pc_take_branch_r;
  assign wb_rd_o                = mem_wb_rd_r;
  assign wb_rd_value_o          = mem_wb_rd_value_r;

//Stall条件汇总
  // 1. if_stall_i: Fetch模块等待指令内存响应
  // 2. if_enable_r: 取指使能有效，表示正在取指
  // 3. ex_multiplier_stall_i: 乘法器还未完成
  // 4. id_ex_multiplier_enable_r: 乘法指令在EX阶段执行中
  // 5. ex_divider_stall_i: 除法器还未完成
  // 6. id_ex_divider_enable_r: 除法指令在EX阶段执行中
  // 7. mem_stall_i: 内存访问未完成
  // 8. ex_mem_enable_r: LSU指令在MEM阶段执行中
  wire stall_w = (if_stall_i || if_enable_r) ||
                 (ex_multiplier_stall_i || id_ex_multiplier_enable_r) ||
                 (ex_divider_stall_i || id_ex_divider_enable_r) ||
                 (mem_stall_i || ex_mem_enable_r);

  // 数据前递
    // RS1前递
  assign ex_rs1_data_w = rst_i ? 32'b0 :  // 复位时清零
    // ========== 优先级1: 从EX/MEM阶段前递（最新数据）==========
    (ex_mem_rd_valid_r &&           // 条件1: EX/MEM阶段有有效的写回
     ex_mem_rd_r != 5'b0 &&         // 条件2: 不是x0寄存器（x0永远为0）
     ex_mem_rd_r == id_ex_rs1_r) ?  // 条件3: 目标寄存器与当前rs1匹配
       ex_mem_ex_result_r :         // 使用EX/MEM阶段的执行结果
    
    // ========== 优先级2: 从MEM/WB阶段前递 ==========
    (mem_wb_rd_r != 5'b0 &&         // 条件1: 不是x0寄存器
     mem_wb_rd_r == id_ex_rs1_r) ?  // 条件2: 目标寄存器与当前rs1匹配
       mem_wb_rd_value_r :          // 使用MEM/WB阶段的写回数据
    
    // ========== 无前递: 使用ID/EX寄存器中的原始值 ==========
    id_ex_rs1_data_r;

  assign ex_rs2_data_w = rst_i ? 32'b0 :
                         (ex_mem_rd_valid_r && ex_mem_rd_r != 5'b0 &&
                          ex_mem_rd_r == id_ex_rs2_r) ? ex_mem_ex_result_r :
                         (mem_wb_rd_r != 5'b0 && mem_wb_rd_r == id_ex_rs2_r) ? mem_wb_rd_value_r :
                         id_ex_rs2_data_r;

  // 冒险检测
  // Load-Use数据冒险检测
  wire data_harzard_w = (id_ex_mem_read_r &&  // 条件1: ID/EX阶段是Load指令
                         ((id_ex_rd_r == if_id_inst_r[19:15]) ||  // 条件2a: Load的rd = 当前指令的rs1
                          (id_ex_rd_r == if_id_inst_r[24:20])));  // 条件2b: Load的rd = 当前指令的rs2

 // 控制冒险检测
  wire control_harzard_w = ex_mem_pc_take_branch_r;//分支跳转标志


  // 流水线推进
  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      if_enable_r               <= 1'b1;
      if_id_pc_r                <= 32'b0;
      if_id_inst_r              <= 32'b0;
      id_ex_pc_r                <= 32'b0;
      id_ex_inst_r              <= 32'b0;
      id_ex_rs1_r               <= 5'b0;
      id_ex_rs2_r               <= 5'b0;
      id_ex_rd_r                <= 5'b0;
      id_ex_rs1_data_r          <= 32'b0;
      id_ex_rs2_data_r          <= 32'b0;
      id_ex_imm_i_r             <= 32'b0;
      id_ex_imm_s_r             <= 32'b0;
      id_ex_imm_b_r             <= 32'b0;
      id_ex_imm_u_r             <= 32'b0;
      id_ex_imm_j_r             <= 32'b0;
      id_ex_shamt_r             <= 32'b0;
      id_ex_invalid_r           <= 1'b0;
      id_ex_lsu_r               <= 1'b0;
      id_ex_mem_read_r          <= 1'b0;
      id_ex_mem_write_r         <= 1'b0;
      id_ex_mul_r               <= 1'b0;
      id_ex_div_r               <= 1'b0;
      id_ex_csr_r               <= 1'b0;
      id_ex_rd_valid_r          <= 1'b0;
      id_ex_multiplier_enable_r <= 1'b0;
      id_ex_divider_enable_r    <= 1'b0;
      ex_mem_pc_r               <= 32'b0;
      ex_mem_inst_r             <= 32'b0;
      ex_mem_rs2_data_r         <= 32'b0;
      ex_mem_pc_branch_r        <= 32'b0;
      ex_mem_pc_take_branch_r   <= 32'b0;
      ex_mem_ex_result_r        <= 32'b0;
      ex_mem_rd_r               <= 5'b0;
      ex_mem_rd_valid_r         <= 1'b0;
      ex_mem_enable_r           <= 1'b0;
      ex_mem_mem_read_r         <= 1'b0;
      ex_csr_branch_r           <= 1'b0;
      ex_csr_rd_data_r          <= 32'b0;
      mem_wb_rd_r               <= 5'b0;
      mem_wb_rd_value_r         <= 32'b0;
      control_harzard_r         <= 1'b0;
    end else if (stall_w) begin
      //冻结流水线
      control_harzard_r <= control_harzard_w;  // 记录控制冒险（即使暂停也要检测分支）
      
      // 根据不同的暂停原因，清除相应的使能信号
      if (if_stall_i) if_enable_r <= 1'b0;                          // Fetch等待内存，停止取指
      if (ex_multiplier_stall_i) id_ex_multiplier_enable_r <= 1'b0; // 乘法器未就绪，清除使能
      if (ex_divider_stall_i) id_ex_divider_enable_r <= 1'b0;       // 除法器未就绪，清除使能
      if (mem_stall_i) ex_mem_enable_r <= 1'b0;  
                         // LSU等待内存，清除使能
    end else begin
      // 正常流水线推进
      if_enable_r <= 1'b0;

      //IF -> ID
      if (!data_harzard_w) begin
        if_enable_r  <= 1'b1;
        if_id_pc_r   <= if_pc_i;
        if_id_inst_r <= if_inst_i;
      end
      //控制冒险检测与处理
      if (control_harzard_w) control_harzard_r <= 1'b1;
      if (control_harzard_r) begin
        //分支延迟一拍处理
        if_id_pc_r   <= if_pc_i;// 重新从正确地址取指
        if_id_inst_r <= if_inst_i;// 重新取正确的指令
      end

      //ID -> EX
      // 无条件更新所有ID/EX寄存器（后面可能被气泡覆盖）
      id_ex_pc_r                <= if_id_pc_r;
      id_ex_inst_r              <= if_id_inst_r;
      id_ex_rs1_r               <= id_rs1_i;
      id_ex_rs2_r               <= id_rs2_i;
      id_ex_rd_r                <= id_rd_i;
      id_ex_rs1_data_r          <= id_rs1_data_i;
      id_ex_rs2_data_r          <= id_rs2_data_i;
      id_ex_imm_i_r             <= id_imm_i_i;
      id_ex_imm_s_r             <= id_imm_s_i;
      id_ex_imm_b_r             <= id_imm_b_i;
      id_ex_imm_u_r             <= id_imm_u_i;
      id_ex_imm_j_r             <= id_imm_j_i;
      id_ex_shamt_r             <= id_shamt_i;
      id_ex_invalid_r           <= id_invalid_i;
      id_ex_lsu_r               <= id_lsu_i;
      id_ex_mem_read_r          <= id_mem_read_i;
      id_ex_mem_write_r         <= id_mem_write_i;
      id_ex_mul_r               <= id_mul_i;
      id_ex_div_r               <= id_div_i;
      id_ex_csr_r               <= id_csr_i;
      id_ex_rd_valid_r          <= id_rd_valid_i;
      id_ex_multiplier_enable_r <= id_mul_i;
      id_ex_divider_enable_r    <= id_div_i;

      // 如果有冒险，插入NOP气泡
      if (data_harzard_w || control_harzard_r) begin
        // 气泡 = ADDI x0, x0, 0（什么都不做的指令）
        id_ex_pc_r                <= 32'b0;
        id_ex_inst_r              <= `INST_ADDI;
        id_ex_rs1_r               <= 5'b0;
        id_ex_rs2_r               <= 5'b0;
        id_ex_rd_r                <= 5'b0;
        id_ex_rs1_data_r          <= 32'b0;
        id_ex_rs2_data_r          <= 32'b0;
        id_ex_imm_i_r             <= 32'b0;
        id_ex_imm_s_r             <= 32'b0;
        id_ex_imm_b_r             <= 32'b0;
        id_ex_imm_u_r             <= 32'b0;
        id_ex_imm_j_r             <= 32'b0;
        id_ex_shamt_r             <= 32'b0;
        id_ex_invalid_r           <= 1'b0;
        id_ex_lsu_r               <= 1'b0;
        id_ex_mem_read_r          <= 1'b0;
        id_ex_mem_write_r         <= 1'b0;
        id_ex_mul_r               <= 1'b0;
        id_ex_div_r               <= 1'b0;
        id_ex_csr_r               <= 1'b0;
        id_ex_rd_valid_r          <= 1'b0;
        id_ex_multiplier_enable_r <= 1'b0;
        id_ex_divider_enable_r    <= 1'b0;
      end


    //CSR分支处理
      ex_csr_branch_r  <= ex_csr_branch_i;// 寄存CSR分支信号
      ex_csr_rd_data_r <= ex_csr_rd_data_i;// 寄存CSR数据

    // EX -> MEM
    // 情况1: CSR分支（ECALL/EBREAK/MRET/中断）
      if (ex_csr_branch_i || ex_csr_branch_r) begin
        //插入气泡，清空流水线
        ex_mem_pc_r       <= 32'b0;
        ex_mem_inst_r     <= `INST_ADDI;
        ex_mem_rs2_data_r <= 32'b0;
        // 设置分支目标地址（优先使用当前周期的CSR数据）
        if (ex_csr_branch_i) begin
          ex_mem_pc_branch_r <= ex_csr_rd_data_i;// 使用当前CSR输出
        end else begin
          ex_mem_pc_branch_r <= ex_csr_rd_data_r;// 使用寄存的CSR数据
        end
        ex_mem_pc_take_branch_r <= 1'b1;// 标记需要跳转
        ex_mem_ex_result_r      <= 32'b0;
        ex_mem_rd_valid_r       <= 1'b0;// 无写回
        ex_mem_rd_r             <= 5'b0;
        ex_mem_enable_r         <= 1'b0;// 禁止LSU
        ex_mem_mem_read_r       <= 1'b0;

      // 情况2: 普通分支冒险（BEQ/BNE等）
      end else if (control_harzard_r) begin
        // 插入气泡，不跳转（PC已由Fetch模块处理）
        ex_mem_pc_r             <= 32'b0;
        ex_mem_inst_r           <= `INST_ADDI;
        ex_mem_rs2_data_r       <= 32'b0;
        ex_mem_pc_branch_r      <= 32'b0;
        ex_mem_pc_take_branch_r <= 1'b0;
        ex_mem_ex_result_r      <= 32'b0;
        ex_mem_rd_valid_r       <= 1'b0;
        ex_mem_rd_r             <= 5'b0;
        ex_mem_enable_r         <= 1'b0;
        ex_mem_mem_read_r       <= 1'b0;

      // 情况3: 正常推进
      end else begin
        ex_mem_pc_r             <= id_ex_pc_r;
        ex_mem_inst_r           <= id_ex_inst_r;
        ex_mem_rs2_data_r       <= ex_rs2_data_w;
        ex_mem_pc_branch_r      <= ex_exec_pc_branch_i;
        ex_mem_pc_take_branch_r <= ex_exec_pc_take_branch_i;

        // 选择EX阶段的结果
        if (id_ex_mul_r) begin
          ex_mem_ex_result_r <= ex_multiplier_rd_data_i;
        end else if (id_ex_div_r) begin
          ex_mem_ex_result_r <= ex_divider_rd_data_i;
        end else if (id_ex_csr_r) begin
          ex_mem_ex_result_r <= ex_csr_rd_data_i;
        end else begin
          ex_mem_ex_result_r <= ex_exec_alu_result_i;
        end

        ex_mem_rd_valid_r <= id_ex_rd_valid_r;
        ex_mem_rd_r       <= id_ex_rd_r;
        ex_mem_enable_r   <= id_ex_lsu_r;
        ex_mem_mem_read_r <= id_ex_mem_read_r;
      end

// MEM -> WB
      mem_wb_pc_r       <= ex_mem_pc_r;
      mem_wb_inst_r     <= ex_mem_inst_r;
      // 目标寄存器编号：只有在rd_valid时才传递
      mem_wb_rd_r       <= ex_mem_rd_valid_r ? ex_mem_rd_r : 5'b0;
      // 目标寄存器数据：选择Load数据或EX结果
      mem_wb_rd_value_r <= ex_mem_mem_read_r ? mem_data_rd_i : ex_mem_ex_result_r;
    end
  end
endmodule
