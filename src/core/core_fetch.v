module core_fetch (
    input clk_i,
    input rst_i,

    // 来自EX/MEM阶段的分支信号
    input [31:0] pc_branch_i,// 分支目标地址
    input        pc_take_branch_i,// 是否发生分支

    // 来自流水线控制器的使能信号
    input        enable_i,// 允许取下一条指令

    // 与指令内存的接口（输入）
    input [31:0] mem_data_i,// 从内存读到的指令
    input        mem_done_i,// 内存操作完成

    // 输出到ID阶段
    output [31:0] pc_o,// 当前指令的PC
    output [31:0] inst_o,// 取到的指令

    // 与指令内存的接口（输出）
    output [31:0] mem_addr_o,// 要读取的地址
    output        mem_enable_o,// 内存使能信号

    // 流水线控制
    output        stall_o// 暂停信号（等待内存时）
);

  // 状态机定义
  localparam STATUS_IDLE = 2'b00;
  localparam STATUS_WAIT = 2'b01;

  reg [ 1:0] status_r;// 当前状态
  reg [31:0] pc_r;// 程序计数器
  reg [31:0] mem_data_r;// 保存从内存读到的指令
  reg        mem_enable_r;// 内存使能寄存器
  reg        stall_r;// 暂停信号寄存器

  assign pc_o         = pc_r;
  assign inst_o       = mem_data_r;
  assign mem_addr_o   = pc_r;
  assign mem_enable_o = mem_enable_r;
  assign stall_o      = stall_r;

  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      // 复位：回到IDLE状态，PC设为起始地址-8
      // 为什么是-8？因为第一次enable时会+4，实际从0x80000000开始
      status_r     <= STATUS_IDLE;
      pc_r         <= 32'h80000000 - 32'd8;
      mem_data_r   <= 32'b0;
      mem_enable_r <= 1'b0;
      stall_r      <= 1'b0;
    end else begin
      case (status_r)
      // IDLE状态：等待enable信号
        STATUS_IDLE: begin
          mem_enable_r <= 1'b0;
          stall_r      <= 1'b0;
          status_r     <= STATUS_IDLE;
          if (enable_i) begin
            // 收到enable：更新PC并发起内存请求
            pc_r         <= pc_take_branch_i ? pc_branch_i : pc_r + 4;
            mem_enable_r <= 1'b1;//发起内存读请求
            stall_r      <= 1'b1;//暂停流水线
            status_r     <= STATUS_WAIT;
          end
        end

        // WAIT状态：等待内存响应
        STATUS_WAIT: begin
          status_r     <= STATUS_WAIT;
          mem_enable_r <= 1'b0;//请求已发出，拉低使能
          if (mem_done_i) begin
            // 内存响应到达
            stall_r <= 1'b0;// 取消暂停
            mem_data_r <= mem_data_i;// 保存读到的指令
            status_r <= STATUS_IDLE;
          end
        end

        default: status_r <= STATUS_IDLE;
      endcase
    end
  end

endmodule
