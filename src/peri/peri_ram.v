// peri_ram.v
module peri_ram (
    input clk_i,
    input rst_i,

    // Port A (指令)
    output [31:0] iram_data_o,
    output        iram_done_o,
    input         iram_enable_i,
    input  [31:0] iram_addr_i,

    // ========== AXI4-Lite Slave 接口 (Port B 数据) ==========
    input  [31:0] s_axi_awaddr_i,
    input         s_axi_awvalid_i,
    output        s_axi_awready_o,
    input  [31:0] s_axi_wdata_i,
    input  [3:0]  s_axi_wstrb_i,
    input         s_axi_wvalid_i,
    output        s_axi_wready_o,
    output [1:0]  s_axi_bresp_o,
    output        s_axi_bvalid_o,
    input         s_axi_bready_i,
    input  [31:0] s_axi_araddr_i,
    input         s_axi_arvalid_i,
    output        s_axi_arready_o,
    output [31:0] s_axi_rdata_o,
    output [1:0]  s_axi_rresp_o,
    output        s_axi_rvalid_o,
    input         s_axi_rready_i
);

  localparam IRAM_STATUS_IDLE = 3'b000;
  localparam IRAM_STATUS_B_00 = 3'b001;
  localparam IRAM_STATUS_B_01 = 3'b010;
  localparam IRAM_STATUS_B_10 = 3'b011;
  localparam IRAM_STATUS_B_11 = 3'b100;
  localparam IRAM_STATUS_DONE = 3'b101;

  reg  [ 2:0] iram_status_r;
  reg  [31:0] iram_data_r;
  reg  [31:0] iram_addr_r;
  reg         iram_done_r;
  wire [ 7:0] bram_douta_w;

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
          if (iram_enable_i) begin
            iram_addr_r   <= iram_addr_i;
            iram_status_r <= IRAM_STATUS_B_00;
          end
        end
        IRAM_STATUS_B_00: begin
          iram_status_r <= IRAM_STATUS_B_01;
          iram_addr_r   <= iram_addr_r + 1;
        end
        IRAM_STATUS_B_01: begin
          iram_status_r    <= IRAM_STATUS_B_10;
          iram_data_r[7:0] <= bram_douta_w;
          iram_addr_r      <= iram_addr_r + 1;
        end
        IRAM_STATUS_B_10: begin
          iram_status_r     <= IRAM_STATUS_B_11;
          iram_data_r[15:8] <= bram_douta_w;
          iram_addr_r       <= iram_addr_r + 1;
        end
        IRAM_STATUS_B_11: begin
          iram_status_r      <= IRAM_STATUS_DONE;
          iram_data_r[23:16] <= bram_douta_w;
        end
        IRAM_STATUS_DONE: begin
          iram_done_r        <= 1'b1;
          iram_data_r[31:24] <= bram_douta_w;
          iram_status_r      <= IRAM_STATUS_IDLE;
        end
        default: iram_status_r <= IRAM_STATUS_IDLE;
      endcase
    end
  end

  localparam DRAM_STATUS_IDLE = 3'b000;
  localparam DRAM_STATUS_B_00 = 3'b001;
  localparam DRAM_STATUS_B_01 = 3'b010;
  localparam DRAM_STATUS_B_10 = 3'b011;
  localparam DRAM_STATUS_B_11 = 3'b100;
  localparam DRAM_STATUS_DONE = 3'b101;

  reg [2:0] dram_status_r;
  reg [31:0] axi_addr_r;
  reg [31:0] axi_wdata_r;
  reg [3:0]  axi_wstrb_r;
  reg [31:0] axi_rdata_r;
  reg        axi_is_write_r;
  reg [7:0] bram_dinb_r;
  reg       bram_web_r;
  wire [7:0] bram_doutb_w;

  assign s_axi_awready_o = (dram_status_r == DRAM_STATUS_IDLE);
  assign s_axi_wready_o  = (dram_status_r == DRAM_STATUS_IDLE);
  assign s_axi_arready_o = (dram_status_r == DRAM_STATUS_IDLE) && !s_axi_awvalid_i;
  assign s_axi_bvalid_o  = (dram_status_r == DRAM_STATUS_DONE) && axi_is_write_r;
  assign s_axi_bresp_o   = 2'b00;
  assign s_axi_rvalid_o  = (dram_status_r == DRAM_STATUS_DONE) && !axi_is_write_r;
  assign s_axi_rdata_o   = { (dram_status_r == DRAM_STATUS_DONE && !axi_is_write_r) ? bram_doutb_w : axi_rdata_r[31:24], axi_rdata_r[23:0] };
  assign s_axi_rresp_o   = 2'b00;

  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      dram_status_r  <= DRAM_STATUS_IDLE;
      axi_is_write_r <= 1'b0;
      axi_addr_r     <= 32'b0;
      axi_wdata_r    <= 32'b0;
      axi_wstrb_r    <= 4'b0;
      axi_rdata_r    <= 32'b0;
      bram_web_r     <= 1'b0;
      bram_dinb_r    <= 8'b0;
    end else begin
      case (dram_status_r)
        DRAM_STATUS_IDLE: begin
          bram_web_r <= 1'b0;
          if (s_axi_awvalid_i && s_axi_wvalid_i) begin
            dram_status_r  <= DRAM_STATUS_B_00;
            axi_is_write_r <= 1'b1;
            axi_addr_r     <= s_axi_awaddr_i;
            axi_wdata_r    <= s_axi_wdata_i;
            axi_wstrb_r    <= s_axi_wstrb_i;
            bram_dinb_r    <= s_axi_wdata_i[7:0];
            bram_web_r     <= s_axi_wstrb_i[0]; 
          end
          else if (s_axi_arvalid_i) begin
            dram_status_r  <= DRAM_STATUS_B_00;
            axi_is_write_r <= 1'b0;
            axi_addr_r     <= s_axi_araddr_i;
          end
        end
        DRAM_STATUS_B_00: begin
          dram_status_r <= DRAM_STATUS_B_01;
          axi_addr_r    <= axi_addr_r + 1;
          bram_dinb_r   <= axi_wdata_r[15:8];
          bram_web_r    <= axi_is_write_r ? axi_wstrb_r[1] : 1'b0;
        end
        DRAM_STATUS_B_01: begin
          dram_status_r <= DRAM_STATUS_B_10;
          axi_addr_r    <= axi_addr_r + 1;
          if (!axi_is_write_r) axi_rdata_r[7:0] <= bram_doutb_w;
          bram_dinb_r   <= axi_wdata_r[23:16];
          bram_web_r    <= axi_is_write_r ? axi_wstrb_r[2] : 1'b0;
        end
        DRAM_STATUS_B_10: begin
          dram_status_r <= DRAM_STATUS_B_11;
          axi_addr_r    <= axi_addr_r + 1;
          if (!axi_is_write_r) axi_rdata_r[15:8] <= bram_doutb_w;
          bram_dinb_r   <= axi_wdata_r[31:24];
          bram_web_r    <= axi_is_write_r ? axi_wstrb_r[3] : 1'b0;
        end
        DRAM_STATUS_B_11: begin
          dram_status_r <= DRAM_STATUS_DONE;
          bram_web_r    <= 1'b0;
          if (!axi_is_write_r) axi_rdata_r[23:16] <= bram_doutb_w;
        end
        DRAM_STATUS_DONE: begin
          if (!axi_is_write_r) axi_rdata_r[31:24] <= bram_doutb_w;
          if (axi_is_write_r) begin
            if (s_axi_bready_i) dram_status_r <= DRAM_STATUS_IDLE;
          end else begin
            if (s_axi_rready_i) dram_status_r <= DRAM_STATUS_IDLE;
          end
        end
        default: dram_status_r <= DRAM_STATUS_IDLE;
      endcase
    end
  end
  ip_bram bram (
    .clka (clk_i),
    .wea  (1'b0),
    .addra(iram_addr_r[16:0]),
    .dina (8'b0),
    .douta(bram_douta_w),
    .clkb (clk_i),
    .web  (bram_web_r),
    .addrb(axi_addr_r[16:0]),
    .dinb (bram_dinb_r),
    .doutb(bram_doutb_w)
  );
endmodule