`include "core_defs.v"

module core_lsu (
    input clk_i,
    input rst_i,

    input [31:0] inst_i,
    input [31:0] addr_i,  // 来自Execute的地址（rs1+imm）
    input [31:0] data_wr_i, // 要写的数据（rs2）
    input        enable_i,  // LSU使能

    // 内存接口（输入）
    input [31:0] mem_data_rd_i, // 从内存读到的数据
    input        mem_done_i, // 内存操作完成

    // 数据输出
    output [31:0] data_rd_o,     // Load结果

    // 内存接口（输出）
    output        mem_rd_o,      // 内存读请求
    output        mem_wr_o,      // 内存写请求
    output [31:0] mem_addr_o,    // 内存访问地址
    output        mem_enable_o,  // 内存使能
    output [31:0] mem_data_wr_o, // 写入内存的数据
    output [31:0] mem_mask_wr_o, // 写掩码

    // 控制输出
    output        stall_o        // 暂停信号
);
  localparam STATUS_IDLE = 4'b0000;
  localparam STATUS_INIT = 4'b0001; // 初始化状态
  localparam STATUS_WAIT = 4'b0010; // 等待内存响应
  localparam STATUS_EXTD = 4'b0011; // 符号/零扩展
  localparam STATUS_DONE = 4'b0100;

  reg [ 3:0] status_r;
  reg [31:0] inst_r;

  reg        mem_rd_r;
  reg        mem_wr_r;
  reg [31:0] mem_addr_r;
  reg        mem_enable_r;
  reg [31:0] data_rd_r;
  reg [31:0] mem_data_wr_r;
  reg [31:0] mem_mask_wr_r;
  reg        stall_r;

  assign mem_rd_o      = mem_rd_r;
  assign mem_wr_o      = mem_wr_r;
  assign mem_addr_o    = mem_addr_r;
  assign mem_enable_o  = mem_enable_r;
  assign data_rd_o     = data_rd_r;
  assign mem_data_wr_o = mem_data_wr_r;
  assign mem_mask_wr_o = mem_mask_wr_r;
  assign stall_o       = stall_r;

  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      inst_r        <= 32'b0;
      mem_rd_r      <= 1'b0;
      mem_wr_r      <= 1'b0;
      mem_addr_r    <= 32'b0;
      mem_enable_r  <= 1'b0;
      data_rd_r     <= 32'b0;
      mem_data_wr_r <= 32'b0;
      stall_r       <= 1'b0;
      status_r      <= STATUS_IDLE;
    end else begin
      case (status_r)
      // IDLE状态：等待访存请求,检测到LSU指令，暂停流水线并锁存所有输入信号
      STATUS_IDLE: begin
          mem_rd_r     <= 1'b0;      // 清除读信号
          mem_wr_r     <= 1'b0;      // 清除写信号
          mem_enable_r <= 1'b0;      // 清除使能
          stall_r      <= 1'b0;      // 不暂停流水线
          status_r     <= STATUS_IDLE;
          
          if (enable_i) begin        // 如果有访存请求
              inst_r        <= inst_i;      // 锁存指令
              stall_r       <= 1'b1;        // 暂停流水线
              mem_addr_r    <= addr_i;      // 锁存地址
              mem_data_wr_r <= data_wr_i;   // 锁存写数据
              status_r      <= STATUS_INIT;  // 进入初始化状态
          end
      end

        //INIT状态：根据指令类型发起内存读写请求
        STATUS_INIT: begin
          status_r     <= STATUS_WAIT;
          mem_rd_r     <= 1'b0;
          mem_wr_r     <= 1'b0;
          mem_enable_r <= 1'b1;
          //识别Load指令
          if (((inst_r & `MASK_LB) == `INST_LB) ||
              ((inst_r & `MASK_LH) == `INST_LH) ||
              ((inst_r & `MASK_LW) == `INST_LW) ||
              ((inst_r & `MASK_LBU) == `INST_LBU) ||
              ((inst_r & `MASK_LHU) == `INST_LHU)) begin
            mem_rd_r <= 1'b1;
          // 识别Store指令并设置写掩码
          //存储字节
          end else if ((inst_r & `MASK_SB) == `INST_SB) begin
            mem_wr_r <= 1'b1;
            mem_mask_wr_r <= 32'h000000ff;
          //存储半字
          end else if ((inst_r & `MASK_SH) == `INST_SH) begin
            mem_wr_r <= 1'b1;
            mem_mask_wr_r <= 32'h0000ffff;
          //存储字
          end else if ((inst_r & `MASK_SW) == `INST_SW) begin
            mem_wr_r <= 1'b1;
            mem_mask_wr_r <= 32'hffffffff;
          end else begin
            mem_enable_r <= 1'b0;
            status_r <= STATUS_DONE;
          end
        end

        // WAIT状态：等待内存响应
        STATUS_WAIT: begin
          status_r     <= STATUS_WAIT;
          mem_enable_r <= 1'b0; //清除enable信号
          if (mem_done_i) begin // 内存操作完成
            if (((inst_r & `MASK_LB) == `INST_LB) ||
                ((inst_r & `MASK_LH) == `INST_LH) ||
                ((inst_r & `MASK_LW) == `INST_LW) ||
                ((inst_r & `MASK_LBU) == `INST_LBU) ||
                ((inst_r & `MASK_LHU) == `INST_LHU)) begin
              data_rd_r <= mem_data_rd_i;
              status_r  <= STATUS_EXTD;
            end else begin
               // 存储指令不需要扩展
              status_r <= STATUS_DONE;
            end
          end
        end

        // EXTEND状态：对Load数据进行符号或零扩展
        STATUS_EXTD: begin
          status_r <= STATUS_DONE;
          if ((inst_r & `MASK_LB) == `INST_LB) begin
            data_rd_r[31:8] <= {24{data_rd_r[7]}};
          end else if ((inst_r & `MASK_LBU) == `INST_LBU) begin
            data_rd_r[31:8] <= 24'b0;
          end else if ((inst_r & `MASK_LH) == `INST_LH) begin
            data_rd_r[31:16] <= {16{data_rd_r[15]}};
          end else if ((inst_r & `MASK_LHU) == `INST_LHU) begin
            data_rd_r[31:16] <= 16'b0;
          end
        end
        // DONE状态：完成访存，解除暂停
        STATUS_DONE: begin
          stall_r  <= 1'b0;
          status_r <= STATUS_IDLE;
        end

        default: status_r <= STATUS_IDLE;
      endcase
    end
  end

endmodule
