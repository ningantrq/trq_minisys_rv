module peri_led (
    input clk_i,
    input rst_i,

// ========== Bridge接口 ==========
    input      [4:0] idx_i,// LED索引（0-23）
    input            wr_i,// 写使能
    input            status_wr_i,// 要写入的状态（0=熄灭，1=点亮）
    output reg       status_rd_o,// 读取的状态

    // ========== 物理LED输出 ==========
     // 绿色LED (0-7)
    output reg gld0_o,
    output reg gld1_o,
    output reg gld2_o,
    output reg gld3_o,
    output reg gld4_o,
    output reg gld5_o,
    output reg gld6_o,
    output reg gld7_o,

    // 黄色LED (8-15)
    output reg yld0_o,
    output reg yld1_o,
    output reg yld2_o,
    output reg yld3_o,
    output reg yld4_o,
    output reg yld5_o,
    output reg yld6_o,
    output reg yld7_o,

    // 红色LED (16-23)
    output reg rld0_o,
    output reg rld1_o,
    output reg rld2_o,
    output reg rld3_o,
    output reg rld4_o,
    output reg rld5_o,
    output reg rld6_o,
    output reg rld7_o
);
  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      // 复位时熄灭所有LED
      gld0_o <= 1'b0;
      gld1_o <= 1'b0;
      gld2_o <= 1'b0;
      gld3_o <= 1'b0;
      gld4_o <= 1'b0;
      gld5_o <= 1'b0;
      gld6_o <= 1'b0;
      gld7_o <= 1'b0;

      yld0_o <= 1'b0;
      yld1_o <= 1'b0;
      yld2_o <= 1'b0;
      yld3_o <= 1'b0;
      yld4_o <= 1'b0;
      yld5_o <= 1'b0;
      yld6_o <= 1'b0;
      yld7_o <= 1'b0;

      rld0_o <= 1'b0;
      rld1_o <= 1'b0;
      rld2_o <= 1'b0;
      rld3_o <= 1'b0;
      rld4_o <= 1'b0;
      rld5_o <= 1'b0;
      rld6_o <= 1'b0;
      rld7_o <= 1'b0;
    end else begin
      // ========== 写操作：根据索引控制对应LED ==========
      if (wr_i) begin
        case (idx_i)
          5'd0: gld0_o <= status_wr_i;
          5'd1: gld1_o <= status_wr_i;
          5'd2: gld2_o <= status_wr_i;
          5'd3: gld3_o <= status_wr_i;
          5'd4: gld4_o <= status_wr_i;
          5'd5: gld5_o <= status_wr_i;
          5'd6: gld6_o <= status_wr_i;
          5'd7: gld7_o <= status_wr_i;

          5'd8:  yld0_o <= status_wr_i;
          5'd9:  yld1_o <= status_wr_i;
          5'd10: yld2_o <= status_wr_i;
          5'd11: yld3_o <= status_wr_i;
          5'd12: yld4_o <= status_wr_i;
          5'd13: yld5_o <= status_wr_i;
          5'd14: yld6_o <= status_wr_i;
          5'd15: yld7_o <= status_wr_i;

          5'd16: rld0_o <= status_wr_i;
          5'd17: rld1_o <= status_wr_i;
          5'd18: rld2_o <= status_wr_i;
          5'd19: rld3_o <= status_wr_i;
          5'd20: rld4_o <= status_wr_i;
          5'd21: rld5_o <= status_wr_i;
          5'd22: rld6_o <= status_wr_i;
          5'd23: rld7_o <= status_wr_i;

          default: ;
        endcase
      end

// ========== 读操作：根据索引返回LED状态 ==========
      case (idx_i)
        5'd0: status_rd_o <= gld0_o;
        5'd1: status_rd_o <= gld1_o;
        5'd2: status_rd_o <= gld2_o;
        5'd3: status_rd_o <= gld3_o;
        5'd4: status_rd_o <= gld4_o;
        5'd5: status_rd_o <= gld5_o;
        5'd6: status_rd_o <= gld6_o;
        5'd7: status_rd_o <= gld7_o;

        5'd8:  status_rd_o <= yld0_o;
        5'd9:  status_rd_o <= yld1_o;
        5'd10: status_rd_o <= yld2_o;
        5'd11: status_rd_o <= yld3_o;
        5'd12: status_rd_o <= yld4_o;
        5'd13: status_rd_o <= yld5_o;
        5'd14: status_rd_o <= yld6_o;
        5'd15: status_rd_o <= yld7_o;

        5'd16: status_rd_o <= rld0_o;
        5'd17: status_rd_o <= rld1_o;
        5'd18: status_rd_o <= rld2_o;
        5'd19: status_rd_o <= rld3_o;
        5'd20: status_rd_o <= rld4_o;
        5'd21: status_rd_o <= rld5_o;
        5'd22: status_rd_o <= rld6_o;
        5'd23: status_rd_o <= rld7_o;

        default: ;
      endcase
    end
  end
endmodule
