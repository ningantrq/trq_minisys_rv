module peri_display (
    input clk_i,
    input rst_i,

    // ========== VGA物理接口 ==========
    output [3:0] red_o,      // 红色信号
    output [3:0] green_o,    // 绿色信号
    output [3:0] blue_o,     // 蓝色信号
    output       h_sync_o,   // 行同步
    output       v_sync_o    // 场同步
);

wire [ 9:0] vga_h_addr_w;  // VGA水平地址
wire [ 9:0] vga_v_addr_w;  // VGA垂直地址
wire        vga_clk_w;     // VGA像素时钟
wire [11:0] vga_data_w;    // 从VRAM读取的像素数据

//地址计算
  reg  [19:0] vga_addr_r;
  always @(*) begin
    vga_addr_r <= (vga_v_addr_w * 640 + vga_h_addr_w);
    if (rst_i) begin
      vga_addr_r <= 20'b0;
    end
  end

  ip_vram vram (
      .clka(clk_i),  // input wire clka
      .ena(1'b0),  // input wire ena
      .wea(1'b0),  // input wire [0 : 0] wea
      .addra(19'b0),  // input wire [18 : 0] addra
      .dina(12'b0),  // input wire [11 : 0] dina
      //   .douta(douta),  // output wire [11 : 0] douta
      .clkb(vga_clk_w),  // input wire clkb
      .web(1'b0),  // input wire [0 : 0] web
      .addrb(vga_addr_r),  // input wire [18 : 0] addrb
      .dinb(12'b0),  // input wire [11 : 0] dinb
      .doutb(vga_data_w)  // output wire [11 : 0] doutb
  );

  periph_vga vga (
      .clk_i(clk_i),
      .rst_i(rst_i),
      .vga_data_i(vga_data_w),
      .vga_clk_o(vga_clk_w),
      .h_addr_o(vga_h_addr_w),
      .v_addr_o(vga_v_addr_w),
      .red_o(red_o),
      .green_o(green_o),
      .blue_o(blue_o),
      .h_sync_o(h_sync_o),
      .v_sync_o(v_sync_o)
  );

endmodule
