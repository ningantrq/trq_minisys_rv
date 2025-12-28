`timescale 1ns / 1ps

module test_peri_uart;
  reg        clk;
  reg        rst;

  reg        tx_enable;
  reg  [7:0] tx_data;
  reg        rx;

  wire       rx_done;
  wire [7:0] rx_data;
  wire       tx;

  peri_uart uut (
      .clk_i(clk),
      .rst_i(rst),
      .tx_enable_i(tx_enable),
      .tx_data_i(tx_data),
      .rx_i(rx),

      .rx_done_o(rx_done),
      .rx_data_o(rx_data),
      .tx_done_o(rx_done),
      .tx_o(tx)
  );

  always #10 clk = ~clk;
  always @(posedge clk) begin
    rx <= tx;
  end
  initial begin
    clk = 1'b0;
    rst = 1'b1;

    tx_enable = 1'b1;
    tx_data = "!";
    rx = 1'b1;

    #10;
    rst = 0;
  end

endmodule
