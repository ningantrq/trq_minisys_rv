module peri_uart #(
    parameter BAUD_RATE = 9600,
    parameter CLK_FREQ  = 25000000
) (
    input       clk_i,
    input       rst_i,

    // ========== CPU接口（通过Bridge）==========
    input       tx_enable_i,// 发送使能
    input [7:0] tx_data_i,// 要发送的数据

    output       rx_done_o,// 接收完成标志
    output [7:0] rx_data_o,// 接收到的数据
    output       tx_done_o,// 发送完成标志

    // ========== 物理接口 ==========
    input  rx_i,              // RX线（输入）
    output tx_o               // TX线（输出）
);


  peri_uart_rx #(
      .BAUD_RATE(BAUD_RATE),
      .CLK_FREQ (CLK_FREQ)
  ) rx (
      .clk_i(clk_i),
      .rst_i(rst_i),
      .rx_i (rx_i),

      .rx_done_o(rx_done_o),
      .rx_data_o(rx_data_o)
  );

  peri_uart_tx #(
      .BAUD_RATE(BAUD_RATE),
      .CLK_FREQ (CLK_FREQ)
  ) tx (
      .clk_i(clk_i),
      .rst_i(rst_i),
      .tx_enable_i(tx_enable_i),
      .tx_data_i(tx_data_i),

      .tx_done_o(tx_done_o),
      .tx_busy_o(tx_busy_o),
      .tx_o(tx_o)
  );
endmodule


module peri_uart_rx #(
    parameter BAUD_RATE = 9600,
    parameter CLK_FREQ  = 100000000
) (
    input clk_i,
    input rst_i,
    input rx_i,

    output       rx_done_o,
    output [7:0] rx_data_o
);
  localparam BAUD_CNT_MAX = CLK_FREQ / BAUD_RATE;
  localparam STATUS_IDLE = 3'b000;// 空闲
  localparam STATUS_INIT = 3'b001;// 检测起始位
  localparam STATUS_DATA = 3'b010;// 接收数据位
  localparam STATUS_STOP = 3'b011;// 检测停止位
  localparam STATUS_DONE = 3'b100;// 完成

  reg rx_i_tmp_r;
  reg rx_i_r;
  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      rx_i_tmp_r <= 1'b0;
      rx_i_r     <= 1'b0;
    end else begin
      rx_i_tmp_r <= rx_i;
      rx_i_r     <= rx_i_tmp_r;
    end
  end

  reg [ 2:0] status_r;
  reg        rx_done_r;
  reg [ 7:0] rx_data_r;
  reg [31:0] baud_cnt_r;
  reg [ 3:0] bit_idx_r;

  assign rx_done_o = rx_done_r;
  assign rx_data_o = rx_data_r;

  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      status_r   <= STATUS_IDLE;
      rx_done_r  <= 1'b0;
      rx_data_r  <= 8'b0;
      baud_cnt_r <= 32'b0;
      bit_idx_r  <= 4'b0;
    end else begin
      case (status_r)
        STATUS_IDLE: begin
          rx_done_r  <= 1'b0;
          baud_cnt_r <= 32'b0;
          bit_idx_r  <= 4'b0;

          // 检测起始位（下降沿） 
          if (rx_i_r == 1'b0) begin
            status_r <= STATUS_INIT;
          end else begin
            status_r <= STATUS_IDLE;
          end
        end

        STATUS_INIT: begin
          if (baud_cnt_r == (BAUD_CNT_MAX - 1) / 2) begin
            if (rx_i_r == 1'b0) begin
              baud_cnt_r <= 32'b0;
              status_r   <= STATUS_DATA;
              bit_idx_r  <= 4'b0;
            end else begin
              status_r <= STATUS_IDLE;
            end
          end else begin
            baud_cnt_r <= baud_cnt_r + 1'b1;
            status_r   <= STATUS_INIT;
          end
        end

        STATUS_DATA: begin
          if (baud_cnt_r == BAUD_CNT_MAX - 1) begin
            baud_cnt_r <= 32'b0;
            rx_data_r[bit_idx_r] <= rx_i_r;
            if (bit_idx_r == 4'd7) begin
              bit_idx_r <= 0;
              status_r  <= STATUS_STOP;
            end else begin
              bit_idx_r <= bit_idx_r + 1'b1;
              status_r  <= STATUS_DATA;
            end
          end else begin
            baud_cnt_r <= baud_cnt_r + 1'b1;
            status_r   <= STATUS_DATA;
          end
        end

        STATUS_STOP: begin
          if (baud_cnt_r == BAUD_CNT_MAX - 1) begin
            baud_cnt_r <= 32'b0;
            rx_done_r  <= 1'b1;
            status_r   <= STATUS_DONE;
          end else begin
            baud_cnt_r <= baud_cnt_r + 1'b1;
            status_r   <= STATUS_STOP;
          end
        end

        STATUS_DONE: begin
          rx_done_r <= 1'b0;
          status_r  <= STATUS_IDLE;
        end
        default: status_r <= STATUS_IDLE;
      endcase
    end
  end
endmodule


module peri_uart_tx #(
    parameter BAUD_RATE = 9600,
    parameter CLK_FREQ  = 100000000
) (
    input       clk_i,
    input       rst_i,
    input       tx_enable_i,
    input [7:0] tx_data_i,

    output tx_done_o,
    output tx_busy_o,
    output tx_o
);
  localparam BAUD_CNT_MAX = CLK_FREQ / BAUD_RATE;
  localparam STATUS_IDLE = 3'b000;
  localparam STATUS_INIT = 3'b001;
  localparam STATUS_DATA = 3'b010;
  localparam STATUS_STOP = 3'b011;
  localparam STATUS_DONE = 3'b100;

  reg [ 2:0] status_r;
  reg        tx_done_r;
  reg        tx_busy_r;
  reg        tx_o_r;
  reg [ 7:0] tx_data_r;
  reg [31:0] baud_cnt_r;
  reg [ 3:0] bit_idx_r;

  assign tx_done_o = tx_done_r;
  assign tx_busy_o = tx_busy_r;
  assign tx_o      = tx_o_r;

  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      status_r   <= STATUS_IDLE;
      tx_done_r  <= 1'b0;
      tx_busy_r  <= 1'b0;
      tx_o_r     <= 1'b1;
      tx_data_r  <= 8'b0;
      baud_cnt_r <= 32'b0;
      bit_idx_r  <= 4'b0;
    end else begin
      case (status_r)
        STATUS_IDLE: begin
          tx_done_r <= 1'b0;
          tx_busy_r <= 1'b0;
          tx_o_r    <= 1'b1;
          tx_data_r <= 8'b0;
          if (tx_enable_i) begin
            tx_busy_r <= 1'b1;
            tx_data_r <= tx_data_i;
            status_r  <= STATUS_INIT;
          end else begin
            status_r <= STATUS_IDLE;
          end
        end

        STATUS_INIT: begin
          tx_o_r <= 1'b0;
          if (baud_cnt_r == BAUD_CNT_MAX - 1) begin
            baud_cnt_r <= 32'b0;
            bit_idx_r  <= 4'b0;
            status_r   <= STATUS_DATA;
          end else begin
            baud_cnt_r <= baud_cnt_r + 1;
            status_r   <= STATUS_INIT;
          end
        end

        STATUS_DATA: begin
          tx_o_r <= tx_data_r[bit_idx_r];
          if (baud_cnt_r == BAUD_CNT_MAX - 1) begin
            baud_cnt_r <= 32'b0;
            if (bit_idx_r == 4'd7) begin
              bit_idx_r <= 4'b0;
              status_r  <= STATUS_STOP;
            end else begin
              bit_idx_r <= bit_idx_r + 1;
              status_r  <= STATUS_DATA;
            end
          end else begin
            baud_cnt_r <= baud_cnt_r + 1;
            status_r   <= STATUS_DATA;
          end
        end

        STATUS_STOP: begin
          tx_o_r <= 1'b1;
          if (baud_cnt_r == BAUD_CNT_MAX - 1) begin
            baud_cnt_r <= 32'b0;
            tx_done_r  <= 1'b1;
            tx_busy_r  <= 1'b0;
            status_r   <= STATUS_DONE;
          end else begin
            baud_cnt_r <= baud_cnt_r + 1;
            status_r   <= STATUS_STOP;
          end
        end

        STATUS_DONE: begin
          tx_done_r <= 1'b0;
          status_r  <= STATUS_IDLE;
        end

        default: status_r <= STATUS_IDLE;
      endcase
    end
  end
endmodule
