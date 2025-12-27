`timescale 1ns / 1ps

module tool_bram_cache (
    input clk_i,
    input rst_i,

    output reg [31:0] icache_data_o,
    output reg        icache_done_o,
    input             icache_enable_i,
    input      [31:0] icache_addr_i,

    output reg [31:0] dcache_data_rd_o,
    output reg        dcache_done_o,
    input             dcache_enable_i,
    input             dcache_wr_i,
    input             dcache_rd_i,
    input      [31:0] dcache_addr_i,
    input      [31:0] dcache_data_wr_i,
    input      [31:0] dcache_mask_wr_i
);

  localparam integer IMEM_WORDS = 256;
  localparam integer DMEM_WORDS = 256;

  reg [31:0] imem[0:IMEM_WORDS - 1];
  reg [31:0] dmem[0:DMEM_WORDS - 1];

  integer i;

  initial begin
    for (i = 0; i < IMEM_WORDS; i = i + 1) begin
      imem[i] = 32'h00000013;
    end
    for (i = 0; i < DMEM_WORDS; i = i + 1) begin
      dmem[i] = 32'h00000000;
    end

    imem[0] = 32'h00500093;
    imem[1] = 32'h00a00113;
    imem[2] = 32'h002081b3;
    imem[3] = 32'h40110233;

    imem[4] = 32'h04200593;
    imem[5] = 32'h08b02023;
    imem[6] = 32'h08002603;

    imem[7] = 32'h0000006f;
  end

  reg        icache_pending_r;
  reg [31:0] icache_addr_r;

  reg        dcache_pending_r;
  reg        dcache_wr_r;
  reg        dcache_rd_r;
  reg [31:0] dcache_addr_r;
  reg [31:0] dcache_data_wr_r;
  reg [31:0] dcache_mask_wr_r;

  wire [31:0] icache_word_idx_w = icache_addr_r[31:2];
  wire [31:0] dcache_word_idx_w = dcache_addr_r[31:2];

  wire icache_in_range_w = (icache_word_idx_w < IMEM_WORDS);
  wire dcache_in_range_w = (dcache_word_idx_w < DMEM_WORDS);

  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      icache_data_o    <= 32'h00000013;
      icache_done_o    <= 1'b0;
      icache_pending_r <= 1'b0;
      icache_addr_r    <= 32'b0;

      dcache_data_rd_o    <= 32'b0;
      dcache_done_o       <= 1'b0;
      dcache_pending_r    <= 1'b0;
      dcache_wr_r         <= 1'b0;
      dcache_rd_r         <= 1'b0;
      dcache_addr_r       <= 32'b0;
      dcache_data_wr_r    <= 32'b0;
      dcache_mask_wr_r    <= 32'b0;
    end else begin
      icache_done_o <= 1'b0;
      dcache_done_o <= 1'b0;

      if (icache_enable_i) begin
        icache_pending_r <= 1'b1;
        icache_addr_r    <= icache_addr_i;
      end
      if (icache_pending_r) begin
        icache_done_o    <= 1'b1;
        icache_pending_r <= 1'b0;
        icache_data_o    <= icache_in_range_w ? imem[icache_word_idx_w] : 32'h00000013;
      end

      if (dcache_enable_i) begin
        dcache_pending_r <= 1'b1;
        dcache_wr_r      <= dcache_wr_i;
        dcache_rd_r      <= dcache_rd_i;
        dcache_addr_r    <= dcache_addr_i;
        dcache_data_wr_r <= dcache_data_wr_i;
        dcache_mask_wr_r <= dcache_mask_wr_i;
      end

      if (dcache_pending_r) begin
        dcache_done_o    <= 1'b1;
        dcache_pending_r <= 1'b0;
        if (dcache_wr_r && dcache_in_range_w) begin
          dmem[dcache_word_idx_w] <= (dmem[dcache_word_idx_w] & ~dcache_mask_wr_r) |
                                    (dcache_data_wr_r & dcache_mask_wr_r);
          dcache_data_rd_o <= 32'b0;
        end else if (dcache_rd_r) begin
          dcache_data_rd_o <= dcache_in_range_w ? dmem[dcache_word_idx_w] : 32'b0;
        end else begin
          dcache_data_rd_o <= 32'b0;
        end
      end
    end
  end

endmodule
