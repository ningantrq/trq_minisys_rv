`include "core_defs.v"

module core_csr (
    input        clk_i,
    input        rst_i,
    input [31:0] pc_i,
    input [31:0] inst_i,
    input [31:0] ex_mem_pc_branch_i,
    input        ex_mem_pc_take_branch_i,

    input [31:0] rs1_data_i,        // CSR指令的写入数据
    input        timer_interrupt_i, // 定时器中断请求

    output [31:0] rd_data_o,        // CSR读取结果（送到rd）
    output        branch_o,         // 触发跳转（异常/中断）
    output        interrupt_o       // 中断发生
);

  // MISA: 指示支持的扩展
  wire [31:0] misa_w = 32'b01_0000_00000000000001000100000000;
  // RV32I/M/Zicsr         ZYXWVUSTRQPONMLKJIHGFEDCBA

  // ====== 关键修复 1: 定义特权级常量 ======
  localparam PRIV_M = 2'b11;
  localparam PRIV_U = 2'b00;
  
  // 当前特权级寄存器 (记录CPU当前处于什么模式)
  reg [1:0] cur_priv_r;
  // ===================================

  // CSR寄存器
  reg [31:0] mhartid_r;    // 硬件线程ID
  reg [31:0] mstatus_r;    // 状态寄存器
  reg [31:0] mie_r;        // 中断使能
  reg [31:0] mtvec_r;      // 异常向量
  reg [31:0] mscratch_r;   // 临时寄存器
  reg [31:0] mepc_r;       // 异常PC
  reg [31:0] mcause_r;     // 异常原因
  reg [31:0] mtval_r;      // 异常值
  reg [31:0] mip_r;        // 中断待处理
  reg [63:0] mcycle_r;     // 周期计数
  reg [63:0] minstret_r;   // 指令计数

  reg  [31:0] pc_r;

  reg  [31:0] rd_data_r;
  reg         branch_r;
  reg         interrupt_r;

  assign rd_data_o   = rd_data_r;
  assign branch_o    = branch_r;
  assign interrupt_o = interrupt_r;

  // Zicsr扩展指令检测
  wire zicsr_w = (( inst_i & `MASK_CSRRW  ) == `INST_CSRRW  ) ||
                 (( inst_i & `MASK_CSRRS  ) == `INST_CSRRS  ) ||
                 (( inst_i & `MASK_CSRRC  ) == `INST_CSRRC  ) ||
                 (( inst_i & `MASK_CSRRWI ) == `INST_CSRRWI ) ||
                 (( inst_i & `MASK_CSRRSI ) == `INST_CSRRSI ) ||
                 (( inst_i & `MASK_CSRRCI ) == `INST_CSRRCI );

  // 特权指令检测
  wire priv_inst_w = ((inst_i & `MASK_ECALL  ) == `INST_ECALL  ) ||
                     ((inst_i & `MASK_EBREAK ) == `INST_EBREAK ) ||
                     ((inst_i & `MASK_MRET   ) == `INST_MRET   );

  // 立即数版本检测（使用uimm代替rs1）
  wire imm_u_enable_w = (( inst_i & `MASK_CSRRWI ) == `INST_CSRRWI ) ||
                        (( inst_i & `MASK_CSRRSI ) == `INST_CSRRSI ) ||
                        (( inst_i & `MASK_CSRRCI ) == `INST_CSRRCI );

  // CSR操作类型检测
  wire csr_write_w = (( inst_i & `MASK_CSRRW  ) == `INST_CSRRW  ) ||
                     (( inst_i & `MASK_CSRRWI ) == `INST_CSRRWI );

  wire csr_set_w = (( inst_i & `MASK_CSRRS  ) == `INST_CSRRS  ) ||
                   (( inst_i & `MASK_CSRRSI ) == `INST_CSRRSI );

  wire csr_clear_w = (( inst_i & `MASK_CSRRC  ) == `INST_CSRRC  ) ||
                     (( inst_i & `MASK_CSRRCI ) == `INST_CSRRCI );

  // 单独识别特权指令
  wire ecall_w = ((inst_i & `MASK_ECALL) == `INST_ECALL);
  wire ebreak_w = ((inst_i & `MASK_EBREAK) == `INST_EBREAK);
  wire mret_w = ((inst_i & `MASK_MRET) == `INST_MRET);

  // 提取CSR地址和立即数
  wire [11:0] csr_addr_w = inst_i[31:20];
  wire [31:0] imm_w = {27'b0, inst_i[19:15]};
  // 数据源选择：立即数或寄存器
  wire [31:0] rs_data_w = imm_u_enable_w ? imm_w : rs1_data_i;

  always @(negedge clk_i or posedge rst_i) begin
    if (pc_r == pc_i) begin
      // PC未变化，说明是同一条指令，不处理（避免重复）
      ;
    end else begin
      // PC变化了，处理新指令
      branch_r    <= 1'b0;
      interrupt_r <= 1'b0;
      pc_r        <= pc_i; // 更新PC

      mip_r[7]    <= timer_interrupt_i; // 更新定时器中断待处理标志

      if (rst_i) begin
        // ====== 关键修复 2: 复位逻辑 ======
        cur_priv_r <= PRIV_M;
        // ==============================
        mhartid_r  <= 32'h0;
        mstatus_r  <= {19'b0, 2'b11, 11'b0};
        mie_r      <= 32'h0;
        mtvec_r    <= 32'h1;
        mscratch_r <= 32'h0;
        mepc_r     <= 32'h0;
        mcause_r   <= 32'h0;
        mtval_r    <= 32'h0;
        mip_r      <= 32'h0;
        mcycle_r   <= 64'h0;
        minstret_r <= 64'h0;
        rd_data_r  <= 32'h0;
      end else if (zicsr_w) begin
        // CSR读取
        case (csr_addr_w)
          `CSR_MHARTID:  rd_data_r <= mhartid_r;
          `CSR_MSTATUS:  rd_data_r <= mstatus_r;
          `CSR_MISA:     rd_data_r <= misa_w;
          `CSR_MIE:      rd_data_r <= mie_r;
          `CSR_MTVEC:    rd_data_r <= mtvec_r;
          `CSR_MSCRATCH: rd_data_r <= mscratch_r;
          `CSR_MEPC:     rd_data_r <= mepc_r;
          `CSR_MCAUSE:   rd_data_r <= mcause_r;
          `CSR_MTVAL:    rd_data_r <= mtval_r;
          `CSR_MIP:      rd_data_r <= mip_r;
          `CSR_MCYCLE:   rd_data_r <= mcycle_r[31:0];
          `CSR_MINSTRET: rd_data_r <= minstret_r[31:0];
          default:       rd_data_r <= 32'h0;
        endcase

        // CSR写操作
        if (csr_write_w) begin
          case (csr_addr_w)
            `CSR_MSTATUS: begin
              // ====== 关键修复 3: 允许写入MPP ======
              mstatus_r <= {19'b0, rs_data_w[12:11], 3'b0, rs_data_w[7], 3'b0, rs_data_w[3], 3'b0};
              // ==================================
            end
            `CSR_MIE:      mie_r <= rs_data_w;
            `CSR_MTVEC:    mtvec_r <= rs_data_w;
            `CSR_MSCRATCH: mscratch_r <= rs_data_w;
            `CSR_MEPC:     mepc_r <= rs_data_w;
            `CSR_MCAUSE:   mcause_r <= rs_data_w;
            `CSR_MTVAL:    mtval_r <= rs_data_w;
            `CSR_MCYCLE:   mcycle_r <= rs_data_w;
            `CSR_MINSTRET: minstret_r <= rs_data_w;
            default:       ;
          endcase
        end

        // CSR置位操作
        if (csr_set_w) begin
          case (csr_addr_w)
            `CSR_MSTATUS: begin
              mstatus_r <= {
                19'b0,
                2'b11, 
                3'b0,
                mstatus_r[7] | rs_data_w[7],
                3'b0,
                mstatus_r[3] | rs_data_w[3],
                3'b0
              };
            end
            `CSR_MIE:      mie_r <= mie_r | rs_data_w;
            `CSR_MTVEC:    mtvec_r <= mtvec_r | rs_data_w;
            `CSR_MSCRATCH: mscratch_r <= mscratch_r | rs_data_w;
            `CSR_MEPC:     mepc_r <= mepc_r | rs_data_w;
            `CSR_MCAUSE:   mcause_r <= mcause_r | rs_data_w;
            `CSR_MTVAL:    mtval_r <= mtval_r | rs_data_w;
            `CSR_MCYCLE:   mcycle_r <= mcycle_r | rs_data_w;
            `CSR_MINSTRET: minstret_r <= minstret_r | rs_data_w;
            default:       ;
          endcase
        end

        // CSR清零操作
        if (csr_clear_w) begin
          case (csr_addr_w)
            `CSR_MSTATUS: begin
              mstatus_r <= {
                19'b0,
                2'b11,
                3'b0,
                mstatus_r[7] & ~rs_data_w[7],
                3'b0,
                mstatus_r[3] & ~rs_data_w[3],
                3'b0
              };
            end
            `CSR_MIE:      mie_r <= mie_r & ~rs_data_w;
            `CSR_MTVEC:    mtvec_r <= mtvec_r & ~rs_data_w;
            `CSR_MSCRATCH: mscratch_r <= mscratch_r & ~rs_data_w;
            `CSR_MEPC:     mepc_r <= mepc_r & ~rs_data_w;
            `CSR_MCAUSE:   mcause_r <= mcause_r & ~rs_data_w;
            `CSR_MTVAL:    mtval_r <= mtval_r & ~rs_data_w;
            `CSR_MCYCLE:   mcycle_r <= mcycle_r & ~rs_data_w;
            `CSR_MINSTRET: minstret_r <= minstret_r & ~rs_data_w;
            default:       ;
          endcase
        end

      end else if (priv_inst_w) begin
        // 特权指令处理
        
        // ECALL指令
        if (ecall_w && mstatus_r[3]) begin
            // ====== 关键修复 4: ECALL 进入 M-mode ======
            mstatus_r <= {19'b0, cur_priv_r, 3'b0, mstatus_r[3], 3'b0, 1'b0, 3'b0};
            cur_priv_r <= PRIV_M;
            
            // 记录异常原因
            if (cur_priv_r == PRIV_U)
                mcause_r <= {1'd0, 31'd8};  // User ECALL
            else
                mcause_r <= {1'd0, 31'd11}; // Machine ECALL
            // ==========================================

            mepc_r    <= pc_i;
            mtval_r   <= 32'b0;
            rd_data_r <= mtvec_r;
            branch_r  <= 1'b1;

        end else if (ebreak_w && mstatus_r[3]) begin
          // EBREAK
          mstatus_r <= {19'b0, 2'b11, 3'b0, mstatus_r[3], 3'b0, 1'b0, 3'b0};
          mcause_r  <= {1'd0, 31'd3};
          mepc_r    <= pc_i;
          mtval_r   <= 32'b0;
          rd_data_r <= mtvec_r;
          branch_r  <= 1'b1;

        end else if (mret_w) begin
          // MRET
          // ====== 关键修复 5: MRET 恢复模式 ======
          cur_priv_r <= mstatus_r[12:11];
          // 恢复 mstatus
          mstatus_r <= {19'b0, PRIV_U, 3'b0, 1'b1, 3'b0, mstatus_r[7], 3'b0};
          // ===================================

          rd_data_r <= mepc_r;
          branch_r  <= 1'b1;
        end

      end else if (pc_i != 32'h0) begin
        // 定时器中断处理
        if (timer_interrupt_i && mstatus_r[3] && mie_r[7]) begin
          interrupt_r <= 1'b1;

          // ====== 关键修复 6: 中断强制进 M-mode ======
          mstatus_r   <= {19'b0, cur_priv_r, 3'b0, mstatus_r[3], 3'b0, 1'b0, 3'b0};
          cur_priv_r <= PRIV_M;
          // ========================================

          mcause_r    <= {1'd1, 31'd7};

          if (ex_mem_pc_take_branch_i) begin
            mepc_r <= ex_mem_pc_branch_i;
          end else begin
            mepc_r <= pc_i;
          end
          mtval_r   <= 32'b0;

          rd_data_r <= mtvec_r;
          branch_r  <= 1'b1;
        end
      end
    end
  end
endmodule