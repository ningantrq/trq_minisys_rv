`timescale 1ns / 1ps

module test_peri_uart;
  reg        clk;
  reg        rst;

//发送接口
  reg        tx_enable;
  reg  [7:0] tx_data;

  //接收接口
  reg        rx;
  wire       rx_done;
  wire [7:0] rx_data;

  //发送输出
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

//环回测试
  always #10 clk = ~clk;

   // 将TX连接到RX，实现环回
  always @(posedge clk) begin
    rx <= tx;
  end
  initial begin
    clk = 1'b0;
    rst = 1'b1;

    tx_enable = 1'b1;
    tx_data = "!";// 发送字符'!'
    rx = 1'b1;

    #10;
    rst = 0;
  end

endmodule
