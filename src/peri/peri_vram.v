module peri_vram (
    input clk_i,
    input rst_i,

    // ========== CPU侧接口（端口A）==========
    output [31:0] vram_data_rd_o,  // CPU读取数据
    output        vram_done_o,     // CPU操作完成

    input        vram_enable_i,    // CPU使能
    input        vram_wr_i,        // CPU写使能
    input        vram_rd_i,        // CPU读使能
    input [31:0] vram_addr_i,      // CPU地址
    input [31:0] vram_data_wr_i,   // CPU写数据
    input [31:0] vram_mask_wr_i,   // CPU写掩码

    // ========== VGA侧接口（端口B）==========
    input         vga_clk_i,       // VGA像素时钟
    input  [ 9:0] vga_h_addr_i,    // VGA水平地址
    input  [ 9:0] vga_v_addr_i,    // VGA垂直地址
    output [11:0] vga_data_o       // VGA像素数据（12位RGB）
);
  // vram
  localparam VRAM_STATUS_IDLE = 3'b000;
  localparam VRAM_STATUS_B_00 = 3'b001;
  localparam VRAM_STATUS_B_01 = 3'b010;
  localparam VRAM_STATUS_B_10 = 3'b011;
  localparam VRAM_STATUS_B_11 = 3'b100;
  localparam VRAM_STATUS_DONE = 3'b101;

  reg  [ 2:0] vram_status_r;

  reg  [31:0] vram_data_rd_r;
  reg         vram_done_r;
  reg         vram_enable_r;
  reg         vram_wr_r;
  reg         vram_rd_r;
  reg  [31:0] vram_addr_r;
  reg  [31:0] vram_data_wr_r;
  reg  [31:0] vram_mask_wr_r;

  reg  [ 7:0] vram_dinb_r;// BRAM端口A写入数据（8位）
  reg         vram_web_r;// BRAM端口A写使能

  wire [ 7:0] vram_doutb_w;// BRAM端口A读取数据（8位）

  assign vram_data_rd_o = vram_data_rd_r;
  assign vram_done_o    = vram_done_r;

  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      vram_status_r  <= VRAM_STATUS_IDLE;

      vram_data_rd_r <= 32'b0;
      vram_done_r    <= 1'b0;
      vram_enable_r  <= 1'b0;
      vram_wr_r      <= 1'b0;
      vram_rd_r      <= 1'b0;
      vram_addr_r    <= 32'b0;
      vram_data_wr_r <= 32'b0;
      vram_mask_wr_r <= 32'b0;
      vram_dinb_r    <= 8'b0;
      vram_web_r     <= 1'b0;
    end else begin
      case (vram_status_r)
        VRAM_STATUS_IDLE: begin
          vram_done_r   <= 1'b0;
          vram_status_r <= VRAM_STATUS_IDLE;
          vram_web_r    <= 1'b0;
          if (vram_enable_i) begin
            vram_wr_r      <= vram_wr_i;
            vram_rd_r      <= vram_rd_i;
            vram_addr_r    <= vram_addr_i;
            vram_data_wr_r <= vram_data_wr_i;
            vram_mask_wr_r <= vram_mask_wr_i;
            vram_status_r  <= VRAM_STATUS_B_00;

            vram_dinb_r    <= vram_data_wr_i[7:0];
            vram_web_r     <= vram_wr_i ? vram_mask_wr_i[0] : 1'b0;
          end
        end

        VRAM_STATUS_B_00: begin
          vram_status_r <= VRAM_STATUS_B_01;
          vram_addr_r   <= vram_addr_r + 1;
          vram_dinb_r   <= vram_data_wr_r[15:8];
          vram_web_r    <= vram_wr_r ? vram_mask_wr_r[8] : 1'b0;
        end

        VRAM_STATUS_B_01: begin
          vram_status_r       <= VRAM_STATUS_B_10;
          vram_addr_r         <= vram_addr_r + 1;
          vram_data_rd_r[7:0] <= vram_doutb_w;
          vram_dinb_r         <= vram_data_wr_r[23:16];
          vram_web_r          <= vram_wr_r ? vram_mask_wr_r[16] : 1'b0;
        end

        VRAM_STATUS_B_10: begin
          vram_status_r        <= VRAM_STATUS_B_11;
          vram_addr_r          <= vram_addr_r + 1;
          vram_data_rd_r[15:8] <= vram_doutb_w;
          vram_dinb_r          <= vram_data_wr_r[31:24];
          vram_web_r           <= vram_wr_r ? vram_mask_wr_r[24] : 1'b0;
        end

        VRAM_STATUS_B_11: begin
          vram_status_r         <= VRAM_STATUS_DONE;
          vram_data_rd_r[23:16] <= vram_doutb_w;
        end

        VRAM_STATUS_DONE: begin
          vram_done_r <= 1'b1;
          vram_data_rd_r[31:24] <= vram_doutb_w;
          vram_status_r <= VRAM_STATUS_IDLE;
        end

        default: vram_status_r <= VRAM_STATUS_IDLE;
      endcase
    end
  end

// VGA侧：像素数据重组：BRAM输出16位，提取12位RGB
  reg  [16:0] vga_addr_r;
  wire [15:0] vga_data_w;
  assign vga_data_o = {vga_data_w[7:0], vga_data_w[15:12]};
  always @(*) begin
    // 降采样：每隔一个像素采样一次（640->320, 480->240）
    vga_addr_r <= (vga_v_addr_i[9:1] * 320 + vga_h_addr_i[9:1]);
    if (rst_i) begin
      vga_addr_r <= 17'b0;
    end
  end

ip_vram vram (
  // ========== 端口A：CPU访问 ==========
  .clka(clk_i),                  // CPU时钟
  .ena(1'b1),                    // 始终使能
  .wea(vram_web_r),              // CPU写使能
  .addra(vram_addr_r[17:0]),     // CPU地址（18位）
  .dina(vram_dinb_r),            // CPU写数据（8位）
  .douta(vram_doutb_w),          // CPU读数据（8位）
  
  // ========== 端口B：VGA读取 ==========
  .clkb(vga_clk_i),              // VGA时钟
  .enb(1'b1),                    // 始终使能
  .web(1'b0),                    // 只读
  .addrb(vga_addr_r),            // VGA地址（17位）
  .dinb(16'b0),                  // 不写入
  .doutb(vga_data_w)             // VGA读数据（16位）
);
endmodule
