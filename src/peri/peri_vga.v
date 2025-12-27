
module peri_vga #(
    // 640 * 480 @ 60Hz 时序参数
    parameter H_SYNPULSE     = 96,
    parameter H_BACK_PORCH   = 48,
    parameter H_ACTIVE_TIME  = 640,
    parameter H_FRONT_PORCH  = 16,
    parameter H_LINE_PERIOD  = 800,
    parameter V_SYNPULSE     = 2,
    parameter V_BACK_PORCH   = 33,
    parameter V_ACTIVE_TIME  = 480,
    parameter V_FRONT_PORCH  = 10,
    parameter V_FRAME_PERIOD = 525,
    parameter CLK_FREQ       = 100000000
) (
    input        clk_i,
    input        rst_i,
    input [11:0] vga_data_i,// 来自VRAM的像素数据

    output       vga_clk_o,// VGA像素时钟（50MHz）
    output [9:0] h_addr_o,// 水平地址
    output [9:0] v_addr_o,// 垂直地址
    output       valid_o,// 有效区域标志
    output [3:0] red_o,
    output [3:0] green_o,
    output [3:0] blue_o,
    output       h_sync_o,
    output       v_sync_o
);

//时钟分频：生成50MHz像素时钟
  localparam CLK_CNT_LIMIT = CLK_FREQ / 2 / 50_000_000;
  reg [31:0] clk_cnt_r;
  reg        clk_50_mhz_r;
  assign vga_clk_o = clk_50_mhz_r;

  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      clk_cnt_r    <= 32'b0;
      clk_50_mhz_r <= 1'b0;
    end else begin
      clk_cnt_r <= clk_cnt_r + 1'b1;
      if (clk_cnt_r >= CLK_CNT_LIMIT) begin
        clk_cnt_r    <= 32'b0;
        clk_50_mhz_r <= ~clk_50_mhz_r;
      end
    end
  end

//扫描计数器
  reg  [9:0] h_cnt_r;
  reg  [9:0] v_cnt_r;

  wire       h_valid_w;
  wire       v_valid_w;

//水平扫描
  always @(posedge clk_50_mhz_r or posedge rst_i) begin
    if (rst_i) begin
      h_cnt_r <= 10'd0;
    end else if (h_cnt_r == H_LINE_PERIOD - 1'b1) begin
      h_cnt_r <= 10'd0;// 到达行周期，回到0
    end else begin
      h_cnt_r <= h_cnt_r + 1'b1;
    end
  end
  // 水平同步信号：在同步脉冲期间为低电平
  assign h_sync_o = (h_cnt_r < H_SYNPULSE) ? 1'b0 : 1'b1;

//垂直扫描
  always @(posedge clk_50_mhz_r or posedge rst_i) begin
    if (rst_i) begin
      v_cnt_r <= 10'd0;
    end else if (v_cnt_r == V_FRAME_PERIOD - 1'b1) begin
      v_cnt_r <= 10'd0;// 到达帧周期，回到0
    end else if (h_cnt_r == H_LINE_PERIOD - 1'b1) begin
      v_cnt_r <= v_cnt_r + 1'b1;// 每行结束时递增
    end else begin
      v_cnt_r <= v_cnt_r;
    end
  end
  // 垂直同步信号：在同步脉冲期间为低电平
  assign v_sync_o = (v_cnt_r < V_SYNPULSE) ? 1'b0 : 1'b1;

// 水平有效区域判断
  assign h_valid_w = (h_cnt_r >= (H_SYNPULSE + H_BACK_PORCH)) &&
                     (h_cnt_r <  (H_SYNPULSE + H_BACK_PORCH + H_ACTIVE_TIME));
  // 垂直有效区域判断
  assign v_valid_w = (v_cnt_r >= (V_SYNPULSE + V_BACK_PORCH)) &&
                     (v_cnt_r <  (V_SYNPULSE + V_BACK_PORCH + V_ACTIVE_TIME));

// 地址输出（减1是为了提前一个周期，补偿BRAM延迟）
  assign h_addr_o = h_valid_w ? (h_cnt_r - (H_SYNPULSE + H_BACK_PORCH - 1)) : 10'b0;
  assign v_addr_o = v_valid_w ? (v_cnt_r - (V_SYNPULSE + V_BACK_PORCH - 1)) : 10'b0;
  // 有效区域标志
  assign valid_o = h_valid_w && v_valid_w;

//RGB输出
  assign red_o = valid_o ? vga_data_i[11:8] : 4'b0;
  assign green_o = valid_o ? vga_data_i[7:4] : 4'b0;
  assign blue_o = valid_o ? vga_data_i[3:0] : 4'b0;

endmodule
