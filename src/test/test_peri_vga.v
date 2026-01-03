`timescale 1ns / 1ps

module test_peri_vga;
  reg        clk;
  reg        rst;
  wire       h_sync;
  wire       v_sync;
  wire       valid;
  wire [9:0] h_addr;
  wire [9:0] v_addr;
  wire [3:0] red;
  wire [3:0] green;
  wire [3:0] blue;

  peri_vga uut (
      .clk_i(clk),
      .rst_i(rst),
      .vga_data_i(12'hf00),
      .h_addr_o(h_addr),
      .v_addr_o(v_addr),
      .valid_o(valid),
      .red_o(red),
      .green_o(green),
      .blue_o(blue),
      .h_sync_o(h_sync),
      .v_sync_o(v_sync)
  );

  always #10 clk = ~clk;

  initial begin
    clk = 0;
    rst = 1;

    #10;
    rst = 0;

    #100000000000;
    $stop;
  end
endmodule
