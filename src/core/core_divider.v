`include "core_defs.v"

module core_divider (
    input clk_i,
    input rst_i,

    input [31:0] inst_i,
    input [31:0] rs1_data_i,
    input [31:0] rs2_data_i,
    input        enable_i,

    output        stall_o,
    output [31:0] rd_data_o
);

  localparam STATUS_IDLE = 3'b000;
  localparam STATUS_CHEK = 3'b001;// 检查特殊情况（除零、溢出）
  localparam STATUS_INIT = 3'b010;// 初始化除法器IP
  localparam STATUS_WAIT = 3'b011;

  reg [ 2:0] status_r;
  reg        stall_r;
  reg        input_valid_r;// IP输入有效信号

  reg [31:0] inst_r, rs1_data_r, rs2_data_r;
  reg        flip_r;// 结果符号标志
  reg [31:0] dividend_r, divisor_r;//送给IP的操作数（绝对值）
  reg [31:0] output_r;

  assign stall_o   = stall_r;
  assign rd_data_o = output_r;

  wire [63:0] result_w;// IP输出：{商[63:32], 余数[31:0]}
  wire        out_valid_w;// IP输出有效标志

  ip_divider divider (
      .aclk(clk_i),
      .s_axis_divisor_tvalid(input_valid_r),// 除数有效
      .s_axis_divisor_tdata(divisor_r),// 除数
      .s_axis_dividend_tvalid(input_valid_r),// 被除数有效
      .s_axis_dividend_tdata(dividend_r),// 被除数
      .m_axis_dout_tvalid(out_valid_w),// 输出有效
      .m_axis_dout_tdata(result_w)// 输出数据{商, 余数}
  );

  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      status_r   <= STATUS_IDLE;
      stall_r    <= 1'b0;
      inst_r     <= 32'b0;
      rs1_data_r <= 32'b0;
      rs2_data_r <= 32'b0;
      output_r   <= 32'b0;
    end else begin
      case (status_r)
        STATUS_IDLE: begin
          stall_r  <= 1'b0;
          status_r <= STATUS_IDLE;
          if (enable_i) begin
            stall_r    <= 1'b1;
            inst_r     <= inst_i;
            rs1_data_r <= rs1_data_i;
            rs2_data_r <= rs2_data_i;
            status_r   <= STATUS_CHEK;
          end
        end

        STATUS_CHEK: begin
            // DIV: 有符号除法特殊情况
          if ((inst_r & `MASK_DIV) == `INST_DIV) begin
            if (rs2_data_r == 32'h0) begin
                // 除零：返回-1
              output_r <= 32'hffffffff;
              stall_r  <= 1'b0;
              status_r <= STATUS_IDLE;
            end else if ((rs1_data_r == 32'h80000000) && (rs2_data_r == 32'hffffffff)) begin
                // 溢出：-2^31 / -1 = 2^31（溢出）
              output_r <= 32'h80000000;
              stall_r  <= 1'b0;
              status_r <= STATUS_IDLE;
            end else begin
              status_r <= STATUS_INIT;
            end
            // DIVU: 无符号除法
          end else if ((inst_r & `MASK_DIVU) == `INST_DIVU) begin
            if (rs2_data_r == 32'h0) begin
              output_r <= 32'hffffffff;// 除零返回最大值
              stall_r  <= 1'b0;
              status_r <= STATUS_IDLE;
            end else begin
              status_r <= STATUS_INIT;
            end
            // REM: 有符号取余
          end else if ((inst_r & `MASK_REM) == `INST_REM) begin
            if (rs2_data_r == 32'h0) begin
              output_r <= rs1_data_r;// 除零：余数=被除数
              stall_r  <= 1'b0;
              status_r <= STATUS_IDLE;
            end else if ((rs1_data_r == 32'h80000000) && (rs2_data_r == 32'hffffffff)) begin
              output_r <= 32'h00000000;// 溢出：余数=0
              stall_r  <= 1'b0;
              status_r <= STATUS_IDLE;
            end else begin
              status_r <= STATUS_INIT;
            end
            // REMU: 无符号取余
          end else if ((inst_r & `MASK_REMU) == `INST_REMU) begin
            if (rs2_data_r == 32'h0) begin
              output_r <= rs1_data_r;// 除零：余数=被除数
              stall_r  <= 1'b0;
              status_r <= STATUS_IDLE;
            end else begin
              status_r <= STATUS_INIT;
            end
          end
        end

        STATUS_INIT: begin
          flip_r        <= 1'b0;
          input_valid_r <= 1'b1;//启动IP
          status_r      <= STATUS_WAIT;
          dividend_r    <= rs1_data_r;
          divisor_r     <= rs2_data_r;

          // DIV: 有符号除法，转绝对值
          if ((inst_r & `MASK_DIV) == `INST_DIV) begin
            dividend_r <= (rs1_data_r[31] == 1'b1) ? -rs1_data_r : rs1_data_r;
            divisor_r  <= (rs2_data_r[31] == 1'b1) ? -rs2_data_r : rs2_data_r;
            flip_r     <= (rs1_data_r[31] ^ rs2_data_r[31]);

            // REM: 余数符号取决于被除数
          end else if ((inst_r & `MASK_REM) == `INST_REM) begin
            dividend_r <= (rs1_data_r[31] == 1'b1) ? -rs1_data_r : rs1_data_r;
            divisor_r  <= (rs2_data_r[31] == 1'b1) ? -rs2_data_r : rs2_data_r;
            flip_r     <= rs1_data_i[31];
          end
        end

        STATUS_WAIT: begin
          input_valid_r <= 1'b0;
          if (out_valid_w) begin
            stall_r  <= 1'b0;
            status_r <= STATUS_IDLE;

            // DIV/DIVU: 返回商
            if (((inst_r & `MASK_DIV) == `INST_DIV) || ((inst_r & `MASK_DIVU) == `INST_DIVU)) begin
              output_r <= flip_r ? -result_w[63:32] : result_w[63:32];
            // REM/REMU: 返回余数
            end else if (((inst_r & `MASK_REM) == `INST_REM) ||
                         ((inst_r & `MASK_REMU) == `INST_REMU)) begin
              output_r <= flip_r ? -result_w[31:0] : result_w[31:0];
            end
          end
        end

        default: status_r <= STATUS_IDLE;
      endcase
    end
  end
endmodule
