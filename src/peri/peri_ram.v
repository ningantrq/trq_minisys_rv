module peri_ram (
    input clk_i,
    input rst_i,

    // ========== 端口A：指令读取 ==========
    output [31:0] iram_data_o,// 指令数据输出
    output        iram_done_o,// 指令读取完成
    input         iram_enable_i,// 指令读取使能
    input  [31:0] iram_addr_i, // 指令地址

    // ========== 端口B：数据读写 ==========
    output [31:0] dram_data_rd_o, // 数据读取输出
    output        dram_done_o,    // 数据操作完成
    input         dram_enable_i,  // 数据使能
    input         dram_wr_i,      // 数据写使能
    input         dram_rd_i,      // 数据读使能
    input  [31:0] dram_addr_i,    // 数据地址
    input  [31:0] dram_data_wr_i, // 数据写入
    input  [31:0] dram_mask_wr_i  // 写掩码
);

  // iram
  localparam IRAM_STATUS_IDLE = 3'b000;
  localparam IRAM_STATUS_B_00 = 3'b001;// 读字节0
  localparam IRAM_STATUS_B_01 = 3'b010;// 读字节1
  localparam IRAM_STATUS_B_10 = 3'b011;// 读字节2
  localparam IRAM_STATUS_B_11 = 3'b100;// 读字节3
  localparam IRAM_STATUS_DONE = 3'b101;// 完成

  reg  [ 2:0] iram_status_r;
  reg  [31:0] iram_data_r;
  reg  [31:0] iram_addr_r;
  reg         iram_done_r;

  wire [ 7:0] bram_douta_w;// 来自BRAM端口A的8位数据

  assign iram_done_o = iram_done_r;
  assign iram_data_o = iram_data_r;

  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      iram_status_r <= IRAM_STATUS_IDLE;
      iram_data_r   <= 32'b0;
      iram_addr_r   <= 32'b0;
      iram_done_r   <= 1'b0;
    end else begin
      case (iram_status_r)
        IRAM_STATUS_IDLE: begin
          iram_done_r   <= 1'b0;
          iram_status_r <= IRAM_STATUS_IDLE;
          if (iram_enable_i) begin
            iram_addr_r   <= iram_addr_i;
            iram_status_r <= IRAM_STATUS_B_00;
          end
        end

        IRAM_STATUS_B_00: begin
          iram_status_r <= IRAM_STATUS_B_01;
          iram_addr_r   <= iram_addr_r + 1;// 地址+1(BRAM读取延迟)
        end

        IRAM_STATUS_B_01: begin
          iram_status_r    <= IRAM_STATUS_B_10;
          iram_data_r[7:0] <= bram_douta_w;// 保存字节0
          iram_addr_r      <= iram_addr_r + 1;
        end

        IRAM_STATUS_B_10: begin
          iram_status_r     <= IRAM_STATUS_B_11;
          iram_data_r[15:8] <= bram_douta_w;// 保存字节1
          iram_addr_r       <= iram_addr_r + 1;
        end

        IRAM_STATUS_B_11: begin
          iram_status_r      <= IRAM_STATUS_DONE;
          iram_data_r[23:16] <= bram_douta_w;// 保存字节2
        end

        IRAM_STATUS_DONE: begin
          iram_done_r        <= 1'b1;
          iram_data_r[31:24] <= bram_douta_w;// 保存字节3
          iram_status_r      <= IRAM_STATUS_IDLE;
        end

        default: iram_status_r <= IRAM_STATUS_IDLE;
      endcase
    end
  end

  // dram
  localparam DRAM_STATUS_IDLE = 3'b000;
  localparam DRAM_STATUS_B_00 = 3'b001;
  localparam DRAM_STATUS_B_01 = 3'b010;
  localparam DRAM_STATUS_B_10 = 3'b011;
  localparam DRAM_STATUS_B_11 = 3'b100;
  localparam DRAM_STATUS_DONE = 3'b101;

  reg  [ 2:0] dram_status_r;

  reg  [31:0] dram_data_rd_r;
  reg         dram_done_r;
  reg         dram_enable_r;
  reg         dram_wr_r;
  reg         dram_rd_r;
  reg  [31:0] dram_addr_r;
  reg  [31:0] dram_data_wr_r;
  reg  [31:0] dram_mask_wr_r;

  reg  [ 7:0] bram_dinb_r;// BRAM端口B写入数据
  reg         bram_web_r;// BRAM端口B写使能

  wire [ 7:0] bram_doutb_w;// 来自BRAM端口B的8位数据

  assign dram_data_rd_o = dram_data_rd_r;
  assign dram_done_o    = dram_done_r;

  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      dram_status_r  <= IRAM_STATUS_IDLE;

      dram_data_rd_r <= 32'b0;
      dram_done_r    <= 1'b0;
      dram_enable_r  <= 1'b0;
      dram_wr_r      <= 1'b0;
      dram_rd_r      <= 1'b0;
      dram_addr_r    <= 32'b0;
      dram_data_wr_r <= 32'b0;
      dram_mask_wr_r <= 32'b0;
      bram_dinb_r    <= 8'b0;
      bram_web_r     <= 1'b0;
    end else begin
      case (dram_status_r)
        DRAM_STATUS_IDLE: begin
          dram_done_r   <= 1'b0;
          dram_status_r <= DRAM_STATUS_IDLE;
          bram_web_r    <= 1'b0;
          if (dram_enable_i) begin
            dram_wr_r      <= dram_wr_i;
            dram_rd_r      <= dram_rd_i;
            dram_addr_r    <= dram_addr_i;
            dram_data_wr_r <= dram_data_wr_i;
            dram_mask_wr_r <= dram_mask_wr_i;
            dram_status_r  <= DRAM_STATUS_B_00;
            // 字节0写入
            bram_dinb_r    <= dram_data_wr_i[7:0];
            bram_web_r     <= dram_wr_i ? dram_mask_wr_i[0] : 1'b0;
          end
        end

        DRAM_STATUS_B_00: begin
          dram_status_r <= DRAM_STATUS_B_01;
          dram_addr_r   <= dram_addr_r + 1;
          // 字节1写入
          bram_dinb_r   <= dram_data_wr_r[15:8];
          bram_web_r    <= dram_wr_r ? dram_mask_wr_r[8] : 1'b0;
        end

        DRAM_STATUS_B_01: begin
          dram_status_r       <= DRAM_STATUS_B_10;
          dram_addr_r         <= dram_addr_r + 1;
          dram_data_rd_r[7:0] <= bram_doutb_w;// 读取字节0
          bram_dinb_r         <= dram_data_wr_r[23:16];// 字节2写入
          bram_web_r          <= dram_wr_r ? dram_mask_wr_r[16] : 1'b0;
        end

        DRAM_STATUS_B_10: begin
          dram_status_r        <= DRAM_STATUS_B_11;
          dram_addr_r          <= dram_addr_r + 1;
          dram_data_rd_r[15:8] <= bram_doutb_w;// 读取字节1
          bram_dinb_r          <= dram_data_wr_r[31:24];// 字节3写入
          bram_web_r           <= dram_wr_r ? dram_mask_wr_r[24] : 1'b0;
        end

        DRAM_STATUS_B_11: begin
          dram_status_r         <= DRAM_STATUS_DONE;
          dram_data_rd_r[23:16] <= bram_doutb_w;// 读取字节2
        end

        DRAM_STATUS_DONE: begin
          dram_done_r <= 1'b1;
          dram_data_rd_r[31:24] <= bram_doutb_w;// 读取字节3
          dram_status_r <= DRAM_STATUS_IDLE;
        end

        default: dram_status_r <= DRAM_STATUS_IDLE;
      endcase
    end
  end

ip_bram bram (
  .clka(clk_i),                // 端口A：系统时钟
  .wea(1'b0),                  // 端口A：只读（指令存储）
  .addra(iram_addr_r[16:0]),   // 端口A：地址（17位 = 128KB）
  .dina(8'b0),                 // 端口A：不写入
  .douta(bram_douta_w),        // 端口A：8位数据输出
  
  .clkb(clk_i),                // 端口B：系统时钟
  .web(bram_web_r),            // 端口B：写使能
  .addrb(dram_addr_r[16:0]),   // 端口B：地址
  .dinb(bram_dinb_r),          // 端口B：8位数据输入
  .doutb(bram_doutb_w)         // 端口B：8位数据输出
);

endmodule
