module peri_timer #(
    parameter CLK_FREQ = 25000000
) (
    input clk_i,
    input rst_i,

    // ========== Bridge接口 ==========
        // 写入比较值
    input [31:0] timecmp_i,
    input [31:0] timecmph_i,

    // 读取计数值
    output [31:0] cycle_o,
    output [31:0] cycleh_o,
    output [31:0] time_o,
    output [31:0] timeh_o,
    output [31:0] timecmp_o,
    output [31:0] timecmph_o,

    // ========== 中断输出 ==========
    output reg timer_interrupt_o
);
  reg [63:0] cycle_r;// 周期计数器（每时钟周期+1）
  reg [63:0] timecnt_r;// 时间分频计数器
  reg [63:0] time_r;  // 时间计数器（1ms精度）
  reg [63:0] timecmp_r;// 比较值寄存器

  assign cycle_o    = cycle_r[31:0];
  assign cycleh_o   = cycle_r[63:32];
  assign time_o     = time_r[31:0];
  assign timeh_o    = time_r[63:32];
  assign timecmp_o  = timecmp_r[31:0];
  assign timecmph_o = timecmp_r[63:32];

  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      timer_interrupt_o <= 1'b0;
      cycle_r           <= 64'b0;
      timecnt_r         <= 64'b0;
      time_r            <= 64'b0;
      timecmp_r         <= 64'hffffffffffffffff;// 复位时设为最大值
    end else begin
      timer_interrupt_o <= 1'b0;
      timecmp_r         <= {timecmph_i, timecmp_i};// 更新比较值
      cycle_r           <= cycle_r + 32'h1;// 周期计数器：每时钟周期+1

        // 时间分频逻辑：实现1ms精度
      timecnt_r         <= timecnt_r + 64'h1;
      if (timecnt_r == CLK_FREQ / 1000) begin// 达到1ms
        time_r <= time_r + 64'h1;// 时间+1ms
        timecnt_r <= 64'b0;// 重置分频计数
      end

      // 中断生成：time >= timecmp时触发
      if (time_r >= timecmp_r) begin
        timer_interrupt_o <= 1'b1;
      end
    end
  end
endmodule
