`include "core_defs.v"

module core_csr (
    input        clk_i,
    input        rst_i,
    input [31:0] pc_i,
    input [31:0] inst_i,
    input [31:0] ex_mem_pc_branch_i,
    input        ex_mem_pc_take_branch_i,

    input [31:0] rs1_data_i,//CSR指令的写入数据
    input        timer_interrupt_i,//定时器中断请求

    output [31:0] rd_data_o,//CSR读取结果（送到rd）
    output        branch_o,//触发跳转（异常/中断）
    output        interrupt_o// 中断发生
);

   // MISA: 指示支持的扩展
  wire [31:0] misa_w = 32'b01_0000_00000000000001000100000000;
  // RV32I/M/Zicsr                 ZYXWVUSTRQPONMLKJIHGFEDCBA

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
      pc_r        <= pc_i;//更新PC

      mip_r[7]    <= timer_interrupt_i;// 更新定时器中断待处理标志

      if (rst_i) begin
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
        // CSR指令处理
        //注意：在所有CSR指令中，读操作总是先执行
        //rd_data_r保存读到的值，用于写回目标寄存器 rd
        //即使是 CSRRW（写入指令），也先读再写
        case (csr_addr_w)// 根据CSR地址（inst[31:20]）选择寄存器
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
            // mstatus特殊处理：只允许修改MIE(bit3)和MPIE(bit7)，其他位固定
              mstatus_r <= {19'b0, 2'b11, 3'b0, rs_data_w[7], 3'b0, rs_data_w[3], 3'b0};
              //            ^^^^^  ^^^^^  ^^^^  ^^^^^^^^^^^^  ^^^^  ^^^^^^^^^^^^  ^^^^
              //            保留   MPP=11 保留  MPIE(bit7)    保留  MIE(bit3)     保留
              //                   (M-mode)     从rs_data_w取       从rs_data_w取
              // 为何固定MPP=11？
              // 当前实现仅支持M-mode，MPP（进入异常前的特权级）永远是M-mode
            end
            // 中断/异常配置寄存器（可完全写入）
            `CSR_MIE:      mie_r <= rs_data_w;
            `CSR_MTVEC:    mtvec_r <= rs_data_w;
            `CSR_MSCRATCH: mscratch_r <= rs_data_w;
            //异常处理寄存器（软件可写入用于调试）
            `CSR_MEPC:     mepc_r <= rs_data_w;
            `CSR_MCAUSE:   mcause_r <= rs_data_w;
            `CSR_MTVAL:    mtval_r <= rs_data_w;
            //性能计数器（可写入用于重置）
            `CSR_MCYCLE:   mcycle_r <= rs_data_w;
            `CSR_MINSTRET: minstret_r <= rs_data_w;
            // 注意：MHARTID和MISA是只读寄存器，无写入case（硬件忽略）
            default:       ;
          endcase
        end

        // CSR置位操作
        if (csr_set_w) begin
          case (csr_addr_w)
            `CSR_MSTATUS: begin
              mstatus_r <= {
                19'b0,// 保留位：固定为0
                2'b11,// MPP：固定为M-mode
                3'b0,// 保留位
                mstatus_r[7] | rs_data_w[7],// MPIE |= rs_data_w[7] (bit7置位)
                3'b0,// 保留位
                mstatus_r[3] | rs_data_w[3],// MIE |= rs_data_w[3]  (bit3置位)
                3'b0// 保留位
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
            `CSR_MIE:      mie_r <= mie_r & ~rs_data_w;// 禁用某些中断
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

        // 特权指令处理（ECALL/EBREAK/MRET）
      end else if (priv_inst_w) begin
        // ECALL指令 且 中断使能（防止在异常处理中再次触发）
        if (ecall_w && mstatus_r[3]) begin
            // ========== 步骤1：保存当前状态 ==========
            mstatus_r <= {19'b0, 2'b11, 3'b0, mstatus_r[3], 3'b0, 1'b0, 3'b0};
            //            保留   MPP=11 保留   ^^^^^^^^^^^^  保留   ^^^^  保留
            //                   (M-mode)      保存MIE到MPIE        清除MIE
            // 关键操作：
            // 1. MPIE ← MIE (保存进入异常前的中断使能状态)
            // 2. MIE ← 0    (禁用中断，防止异常处理被中断)
            
            // ========== 步骤2：记录异常信息 ==========
            mcause_r  <= {1'd0, 31'd11};  // 异常码11：Environment call from M-mode
            //            ^^^^  ^^^^^^^
            //            bit31=0  异常码=11（ECALL from M-mode）
            //            (0=异常, 1=中断)
            
            mepc_r    <= pc_i;            // 保存触发ECALL的指令地址（返回时会跳到这里）
            mtval_r   <= 32'b0;           // 异常值：ECALL不涉及错误地址/数据，设为0
            
            // ========== 步骤3：跳转到异常处理程序 ==========
            rd_data_r <= mtvec_r;         // 将mtvec（异常向量基址）作为跳转目标
            branch_r  <= 1'b1;            // 触发分支跳转信号（通知流水线跳转）
        end else if (ebreak_w && mstatus_r[3]) begin// EBREAK指令 且 中断使能
        // ========== 与ECALL处理完全相同，只是异常码不同 ==========
          mstatus_r <= {19'b0, 2'b11, 3'b0, mstatus_r[3], 3'b0, 1'b0, 3'b0};
          mcause_r  <= {1'd0, 31'd3};  // Breakpoint
          mepc_r    <= pc_i;
          mtval_r   <= 32'b0;
          rd_data_r <= mtvec_r;
          branch_r  <= 1'b1;
        end else if (mret_w) begin
        // ========== 步骤1：恢复中断使能 ==========
        mstatus_r <= {19'b0, 2'b11, 3'b0, 1'b1, 3'b0, mstatus_r[7], 3'b0};
        //            保留   MPP=11 保留   ^^^^  保留   ^^^^^^^^^^^^  保留
        //                           MIE=1         保持MPIE不变（或丢弃）
        
        // 简化设计：直接设置MIE=1（而非标准的MIE←MPIE）
        // 原因：当前不支持嵌套异常，进入异常时MIE总是0，返回时总是恢复为1
        
        // ========== 步骤2：返回到异常发生点 ==========
        rd_data_r <= mepc_r;    // 将mepc（保存的PC）作为跳转目标
        branch_r  <= 1'b1;      // 触发跳转信号
        
        // 注意：PC实际更新由流水线控制器根据rd_data_r和branch_r完成
        end

        // 定时器中断处理
      end else if (pc_i != 32'h0) begin
        //中断触发条件检查（三个条件同时满足）
        if (timer_interrupt_i && mstatus_r[3] && mie_r[7]) begin
          interrupt_r <= 1'b1;//标记中断发生
          mstatus_r   <= {19'b0, 2'b11, 3'b0, mstatus_r[3], 3'b0, 1'b0, 3'b0};//保存当前状态
          //记录中断信息
          mcause_r    <= {1'd1, 31'd7};  // Machine timer interrupt
          //保存PC（考虑流水线分支延迟）
            // 问题：中断可能发生在分支指令执行过程中
            // - 如果IF阶段在取分支指令，但EX/MEM阶段已经计算出要跳转
            // - 此时中断到来，应该保存分支目标地址，而不是分支指令地址
        if (ex_mem_pc_take_branch_i) begin
        mepc_r <= ex_mem_pc_branch_i;  // 情况1：流水线中有分支发生
        //        ^^^^^^^^^^^^^^^^^^^^    保存分支目标地址（即将跳转的地址）
        // 示例：BEQ指令判断为真，准备跳到0x2000，此时中断到来
        //      应该保存0x2000，返回后继续从0x2000执行
        end else begin
        mepc_r <= pc_i;                 // 情况2：无分支
        //        ^^^^                    保存当前PC
        end
          mtval_r   <= 32'b0;

          //跳转到中断处理程序
          rd_data_r <= mtvec_r;// 将中断向量地址作为跳转目标
          branch_r  <= 1'b1;// 触发分支跳转
        end
      end
    end
  end
endmodule
