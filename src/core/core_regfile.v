module core_regfile (
    input         clk_i,        // 时钟信号
    input         rst_i,        // 复位信号（高电平有效）
    
    // 写端口（WB阶段写入）
    input  [4:0]  rd_i,         // 目标寄存器地址（5位，0-31）
    input  [31:0] rd_data_i,    // 要写入的数据
    
    // 读端口A（ID阶段读取rs1）
    input  [4:0]  ra_i,         // 源寄存器A地址
    output [31:0] ra_data_o,    // 源寄存器A数据
    
    // 读端口B（ID阶段读取rs2）
    input  [4:0]  rb_i,         // 源寄存器B地址
    output [31:0] rb_data_o     // 源寄存器B数据
);
  reg [31:0] ra_output_r;
  reg [31:0] rb_output_r;
  assign ra_data_o = ra_output_r;
  assign rb_data_o = rb_output_r;

  reg [31:0] x1_ra_r;//返回地址
  reg [31:0] x2_sp_r;//栈指针
  reg [31:0] x3_gp_r;//全局指针
  reg [31:0] x4_tp_r;//线程指针
  //临时寄存器
  reg [31:0] x5_t0_r;
  reg [31:0] x6_t1_r;
  reg [31:0] x7_t2_r;

  reg [31:0] x8_s0_r;//保存寄存器 s0 / 帧指针 fp
  reg [31:0] x9_s1_r;//保存寄存器 s1
  reg [31:0] x10_a0_r;//函数参数/返回值 a0
  reg [31:0] x11_a1_r;//函数参数/返回值 a1
  //函数参数
  reg [31:0] x12_a2_r;
  reg [31:0] x13_a3_r;
  reg [31:0] x14_a4_r;
  reg [31:0] x15_a5_r;
  reg [31:0] x16_a6_r;
  reg [31:0] x17_a7_r;
  //保存寄存器
  reg [31:0] x18_s2_r;
  reg [31:0] x19_s3_r;
  reg [31:0] x20_s4_r;
  reg [31:0] x21_s5_r;
  reg [31:0] x22_s6_r;
  reg [31:0] x23_s7_r;
  reg [31:0] x24_s8_r;
  reg [31:0] x25_s9_r;
  reg [31:0] x26_s10_r;
  reg [31:0] x27_s11_r;
  //临时寄存器
  reg [31:0] x28_t3_r;
  reg [31:0] x29_t4_r;
  reg [31:0] x30_t5_r;
  reg [31:0] x31_t6_r;

  // --------------------------------------------------------------------------
  // 写端口实现（时序逻辑）
  // --------------------------------------------------------------------------
  // 在时钟下降沿写入数据
  // 关键：x0不能被写入，必须始终为0

  always @(negedge clk_i or posedge rst_i) begin
    // 复位时将所有寄存器清零
    if (rst_i) begin
      x1_ra_r   <= 32'h0;
      x2_sp_r   <= 32'h8001ffff;
      x3_gp_r   <= 32'h0;
      x4_tp_r   <= 32'h0;
      x5_t0_r   <= 32'h0;
      x6_t1_r   <= 32'h0;
      x7_t2_r   <= 32'h0;
      x8_s0_r   <= 32'h0;
      x9_s1_r   <= 32'h0;
      x10_a0_r  <= 32'h0;
      x11_a1_r  <= 32'h0;
      x12_a2_r  <= 32'h0;
      x13_a3_r  <= 32'h0;
      x14_a4_r  <= 32'h0;
      x15_a5_r  <= 32'h0;
      x16_a6_r  <= 32'h0;
      x17_a7_r  <= 32'h0;
      x18_s2_r  <= 32'h0;
      x19_s3_r  <= 32'h0;
      x20_s4_r  <= 32'h0;
      x21_s5_r  <= 32'h0;
      x22_s6_r  <= 32'h0;
      x23_s7_r  <= 32'h0;
      x24_s8_r  <= 32'h0;
      x25_s9_r  <= 32'h0;
      x26_s10_r <= 32'h0;
      x27_s11_r <= 32'h0;
      x28_t3_r  <= 32'h0;
      x29_t4_r  <= 32'h0;
      x30_t5_r  <= 32'h0;
      x31_t6_r  <= 32'h0;
    end else begin
      // 正常运行：根据rd_i写入对应寄存器
      // 注意：rd_i == 0时不写入（保护x0）
      case (rd_i)
        5'd0:  ;  // x0不可写，忽略
        5'd1:  x1_ra_r   <= rd_data_i;
        5'd2:  x2_sp_r   <= rd_data_i;
        5'd3:  x3_gp_r   <= rd_data_i;
        5'd4:  x4_tp_r   <= rd_data_i;
        5'd5:  x5_t0_r   <= rd_data_i;
        5'd6:  x6_t1_r   <= rd_data_i;
        5'd7:  x7_t2_r   <= rd_data_i;
        5'd8:  x8_s0_r   <= rd_data_i;
        5'd9:  x9_s1_r   <= rd_data_i;
        5'd10: x10_a0_r  <= rd_data_i;
        5'd11: x11_a1_r  <= rd_data_i;
        5'd12: x12_a2_r  <= rd_data_i;
        5'd13: x13_a3_r  <= rd_data_i;
        5'd14: x14_a4_r  <= rd_data_i;
        5'd15: x15_a5_r  <= rd_data_i;
        5'd16: x16_a6_r  <= rd_data_i;
        5'd17: x17_a7_r  <= rd_data_i;
        5'd18: x18_s2_r  <= rd_data_i;
        5'd19: x19_s3_r  <= rd_data_i;
        5'd20: x20_s4_r  <= rd_data_i;
        5'd21: x21_s5_r  <= rd_data_i;
        5'd22: x22_s6_r  <= rd_data_i;
        5'd23: x23_s7_r  <= rd_data_i;
        5'd24: x24_s8_r  <= rd_data_i;
        5'd25: x25_s9_r  <= rd_data_i;
        5'd26: x26_s10_r <= rd_data_i;
        5'd27: x27_s11_r <= rd_data_i;
        5'd28: x28_t3_r  <= rd_data_i;
        5'd29: x29_t4_r  <= rd_data_i;
        5'd30: x30_t5_r  <= rd_data_i;
        5'd31: x31_t6_r  <= rd_data_i;
      endcase
    end
  end

  // --------------------------------------------------------------------------
  // 读端口实现（组合逻辑）
  // --------------------------------------------------------------------------
  // 根据读地址，立即输出对应寄存器的值
  // 使用组合逻辑确保读操作无延迟
  always @* begin
    case (ra_i)
      5'd1: ra_output_r = x1_ra_r;
      5'd2: ra_output_r = x2_sp_r;
      5'd3: ra_output_r = x3_gp_r;
      5'd4: ra_output_r = x4_tp_r;
      5'd5: ra_output_r = x5_t0_r;
      5'd6: ra_output_r = x6_t1_r;
      5'd7: ra_output_r = x7_t2_r;
      5'd8: ra_output_r = x8_s0_r;
      5'd9: ra_output_r = x9_s1_r;
      5'd10: ra_output_r = x10_a0_r;
      5'd11: ra_output_r = x11_a1_r;
      5'd12: ra_output_r = x12_a2_r;
      5'd13: ra_output_r = x13_a3_r;
      5'd14: ra_output_r = x14_a4_r;
      5'd15: ra_output_r = x15_a5_r;
      5'd16: ra_output_r = x16_a6_r;
      5'd17: ra_output_r = x17_a7_r;
      5'd18: ra_output_r = x18_s2_r;
      5'd19: ra_output_r = x19_s3_r;
      5'd20: ra_output_r = x20_s4_r;
      5'd21: ra_output_r = x21_s5_r;
      5'd22: ra_output_r = x22_s6_r;
      5'd23: ra_output_r = x23_s7_r;
      5'd24: ra_output_r = x24_s8_r;
      5'd25: ra_output_r = x25_s9_r;
      5'd26: ra_output_r = x26_s10_r;
      5'd27: ra_output_r = x27_s11_r;
      5'd28: ra_output_r = x28_t3_r;
      5'd29: ra_output_r = x29_t4_r;
      5'd30: ra_output_r = x30_t5_r;
      5'd31: ra_output_r = x31_t6_r;
      default: ra_output_r = 31'h0;
    endcase

    case (rb_i)
      5'd1: rb_output_r = x1_ra_r;
      5'd2: rb_output_r = x2_sp_r;
      5'd3: rb_output_r = x3_gp_r;
      5'd4: rb_output_r = x4_tp_r;
      5'd5: rb_output_r = x5_t0_r;
      5'd6: rb_output_r = x6_t1_r;
      5'd7: rb_output_r = x7_t2_r;
      5'd8: rb_output_r = x8_s0_r;
      5'd9: rb_output_r = x9_s1_r;
      5'd10: rb_output_r = x10_a0_r;
      5'd11: rb_output_r = x11_a1_r;
      5'd12: rb_output_r = x12_a2_r;
      5'd13: rb_output_r = x13_a3_r;
      5'd14: rb_output_r = x14_a4_r;
      5'd15: rb_output_r = x15_a5_r;
      5'd16: rb_output_r = x16_a6_r;
      5'd17: rb_output_r = x17_a7_r;
      5'd18: rb_output_r = x18_s2_r;
      5'd19: rb_output_r = x19_s3_r;
      5'd20: rb_output_r = x20_s4_r;
      5'd21: rb_output_r = x21_s5_r;
      5'd22: rb_output_r = x22_s6_r;
      5'd23: rb_output_r = x23_s7_r;
      5'd24: rb_output_r = x24_s8_r;
      5'd25: rb_output_r = x25_s9_r;
      5'd26: rb_output_r = x26_s10_r;
      5'd27: rb_output_r = x27_s11_r;
      5'd28: rb_output_r = x28_t3_r;
      5'd29: rb_output_r = x29_t4_r;
      5'd30: rb_output_r = x30_t5_r;
      5'd31: rb_output_r = x31_t6_r;
      default: rb_output_r = 31'h0;
    endcase
  end
endmodule
