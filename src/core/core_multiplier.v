`include "core_defs.v"

module core_multiplier (
    input clk_i,
    input rst_i,

    input [31:0] inst_i,
    input [31:0] rs1_data_i,
    input [31:0] rs2_data_i,
    input        enable_i,// 使能信号（来自Pipeline Ctrl）

    output [31:0] rd_data_o,
    output        stall_o
);
  localparam STATUS_IDLE = 4'b0000;// 空闲状态
  localparam STATUS_INIT = 4'b0001;// 初始化状态
  //流水线计算
  localparam STATUS_STG0 = 4'b0010;
  localparam STATUS_STG1 = 4'b0011;
  localparam STATUS_STG2 = 4'b0100;
  localparam STATUS_STG3 = 4'b0101;
  localparam STATUS_STG4 = 4'b0110;

  localparam STATUS_FLIP = 4'b0111;// 符号调整：根据flip_r决定是否取反
  localparam STATUS_DONE = 4'b1000;

  reg [ 3:0] status_r;
  reg        stall_r;

  reg [31:0] inst_r;
  reg [31:0] rs1_data_r;
  reg [31:0] rs2_data_r;
  reg        flip_r;
  reg [31:0] ra_r, rb_r;// 送给DSP的操作数（绝对值）
  reg [63:0] rp_r;//乘积结果
  reg [31:0] output_r;

  assign rd_data_o = output_r;
  assign stall_o   = stall_r;

  wire [63:0] rp_w;
  ip_multiplier multiplier (
      .CLK(clk_i),
      .A  (ra_r),
      .B  (rb_r),
      .P  (rp_w)
  );

  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      status_r   <= STATUS_IDLE;
      stall_r    <= 1'b0;
      inst_r     <= 32'b0;
      rs1_data_r <= 32'b0;
      rs2_data_r <= 32'b0;
      ra_r       <= 32'b0;
      rb_r       <= 32'b0;
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
            status_r   <= STATUS_INIT;
          end
        end

        STATUS_INIT: begin
            // MUL: 有符号×有符号
          if ((inst_r & `MASK_MUL) == `INST_MUL) begin
            ra_r     <= (rs1_data_r[31] == 1'b1) ? -rs1_data_r : rs1_data_r;//绝对值
            rb_r     <= (rs2_data_r[31] == 1'b1) ? -rs2_data_r : rs2_data_r;
            flip_r   <= (rs1_data_r[31] ^ rs2_data_r[31]);//符号异或
            status_r <= STATUS_STG0;

            // MULH: 有符号×有符号（同MUL）
          end else if ((inst_r & `MASK_MULH) == `INST_MULH) begin
            ra_r     <= (rs1_data_r[31] == 1'b1) ? -rs1_data_r : rs1_data_r;
            rb_r     <= (rs2_data_r[31] == 1'b1) ? -rs2_data_r : rs2_data_r;
            flip_r   <= (rs1_data_r[31] ^ rs2_data_r[31]);
            status_r <= STATUS_STG0;

            // MULHSU: 有符号×无符号
          end else if ((inst_r & `MASK_MULHSU) == `INST_MULHSU) begin
            ra_r     <= (rs1_data_r[31] == 1'b1) ? -rs1_data_r : rs1_data_r;
            rb_r     <= rs2_data_r;
            flip_r   <= rs1_data_r[31];
            status_r <= STATUS_STG0;

            // MULHU: 无符号×无符号
          end else if ((inst_r & `MASK_MULHU) == `INST_MULHU) begin
            ra_r     <= rs1_data_r;
            rb_r     <= rs2_data_r;
            flip_r   <= 1'b0;
            status_r <= STATUS_STG0;
          end else begin
            status_r <= STATUS_IDLE;
          end
        end

        STATUS_STG0: status_r <= STATUS_STG1;
        STATUS_STG1: status_r <= STATUS_STG2;
        STATUS_STG2: status_r <= STATUS_STG3;
        STATUS_STG3: status_r <= STATUS_STG4;
        STATUS_STG4: status_r <= STATUS_FLIP;

        STATUS_FLIP: begin
          rp_r <= rp_w;
          if (flip_r) begin
            rp_r <= -rp_w;
          end
          status_r <= STATUS_DONE;
        end

        STATUS_DONE: begin
          stall_r  <= 1'b0;
          status_r <= STATUS_IDLE;
          if ((inst_r & `MASK_MUL) == `INST_MUL) begin
            output_r <= rp_r[31:0];
          end else if (((inst_r & `MASK_MULH) == `INST_MULH) ||
                       ((inst_r & `MASK_MULHSU) == `INST_MULHSU) ||
                       ((inst_r & `MASK_MULHU) == `INST_MULHU)) begin
            output_r <= rp_r[63:32];
          end
        end

        default: status_r <= STATUS_IDLE;
      endcase
    end
  end

endmodule
