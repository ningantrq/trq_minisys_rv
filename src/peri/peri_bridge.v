// verilog_format: off
// Memory addr
`define MEM_RAM_MASK        32'hf0000000
`define MEM_UART_ADDR       32'h00000000
`define MEM_UART_TX_DATA    32'h00000000
`define MEM_UART_TX_FLAG    32'h00000001
`define MEM_UART_RX_DATA    32'h00000002
`define MEM_UART_RX_FLAG    32'h00000003
`define MEM_TIMER_ADDR      32'h10000000
`define MEM_TIMER_CYCLE     32'h10000000
`define MEM_TIMER_CYCLEH    32'h10000004
`define MEM_TIMER_TIME      32'h10000008
`define MEM_TIMER_TIMEH     32'h1000000C
`define MEM_TIMER_TIMECMP   32'h10000010
`define MEM_TIMER_TIMECMPH  32'h10000014
`define MEM_VRAM_ADDR       32'h20000000
`define MEM_LED_ADDR        32'h30000000
`define MEM_SWITCH_ADDR     32'h40000000
`define MEM_RAM_ADDR        32'h80000000
// verilog_format: on


module peri_bridge (
    input clk_i,
    input rst_i,

    input        dram_rd_i,
    input        dram_wr_i,
    input [31:0] dram_addr_i,
    input        dram_enable_i,
    input [31:0] dram_data_wr_i,
    input [31:0] dram_mask_wr_i,

    output [31:0] dram_data_rd_o,
    output        dram_done_o,

    // uart
    output       tx_enable_o,
    output [7:0] tx_data_o,

    input       rx_done_i,
    input [7:0] rx_data_i,
    input       tx_done_i,

    // timer
    input [31:0] timer_cycle_i,
    input [31:0] timer_cycleh_i,
    input [31:0] timer_time_i,
    input [31:0] timer_timeh_i,
    input [31:0] timer_timecmp_i,
    input [31:0] timer_timecmph_i,

    output reg [31:0] timer_timecmp_o,
    output reg [31:0] timer_timecmph_o,

    // vram
    input [31:0] vram_data_rd_i,
    input        vram_done_i,

    output reg        vram_enable_o,
    output reg        vram_wr_o,
    output reg        vram_rd_o,
    output reg [31:0] vram_addr_o,
    output reg [31:0] vram_data_wr_o,
    output reg [31:0] vram_mask_wr_o,

    // led
    output reg [4:0] led_idx_o,
    output reg       led_wr_o,
    output reg       led_status_wr_o,
    input            led_status_rd_i,

    // switch
    output reg [4:0] switch_idx_o,
    input            switch_status_i,

    // ram
    input      [31:0] ram_data_rd_i,
    input             ram_done_i,
    output reg        ram_enable_o,
    output reg        ram_wr_o,
    output reg        ram_rd_o,
    output reg [31:0] ram_addr_o,
    output reg [31:0] ram_data_wr_o,
    output reg [31:0] ram_mask_wr_o
);
  // uart
  reg [31:0] uart_tx_data_r;
  reg [31:0] uart_tx_flag_r;  // 0: idle, 1: busy
  reg        uart_tx_enable_r;
  reg [31:0] uart_rx_data_r;
  reg [31:0] uart_rx_flag_r;  // 0: receiving, 1: done

  // bridge
  localparam STATUS_IDLE = 2'b00;
  localparam STATUS_INIT = 2'b01;
  localparam STATUS_WAIT = 2'b10;
  localparam STATUS_DONE = 2'b11;

  reg [ 1:0] status_r;

  reg        dram_rd_r;
  reg        dram_wr_r;
  reg [31:0] dram_addr_r;
  reg [31:0] dram_data_wr_r;
  reg [31:0] dram_mask_wr_r;

  reg [31:0] dram_data_rd_r;
  reg        dram_done_r;

  assign dram_data_rd_o = dram_data_rd_r;
  assign dram_done_o    = dram_done_r;
  assign tx_enable_o    = uart_tx_enable_r;
  assign tx_data_o      = uart_tx_data_r;

  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      status_r         <= STATUS_IDLE;
      dram_rd_r        <= 1'b0;
      dram_wr_r        <= 1'b0;
      dram_addr_r      <= 32'b0;
      dram_data_wr_r   <= 32'b0;
      dram_mask_wr_r   <= 32'b0;
      dram_data_rd_r   <= 32'b0;
      dram_done_r      <= 1'b0;
      uart_tx_data_r   <= 32'b0;
      uart_tx_flag_r   <= 32'b0;
      uart_tx_enable_r <= 1'b0;
      uart_rx_data_r   <= 32'b0;
      uart_rx_flag_r   <= 32'h0;

      timer_timecmp_o  <= 32'hffffffff;
      timer_timecmph_o <= 32'hffffffff;
    end else begin
      if (tx_done_i) uart_tx_flag_r <= 32'h0;
      if (rx_done_i) begin
        uart_rx_data_r <= rx_data_i;
        uart_rx_flag_r <= 32'hffffffff;
      end
      case (status_r)
        STATUS_IDLE: begin
          status_r <= STATUS_IDLE;
          dram_done_r <= 1'b0;
          if (dram_enable_i) begin
            dram_rd_r      <= dram_rd_i;
            dram_wr_r      <= dram_wr_i;
            dram_addr_r    <= dram_addr_i;
            dram_data_wr_r <= dram_data_wr_i;
            dram_mask_wr_r <= dram_mask_wr_i;
            status_r       <= STATUS_INIT;
          end
        end

        STATUS_INIT: begin
          status_r <= STATUS_WAIT;
          case (dram_addr_r & `MEM_RAM_MASK)
            `MEM_UART_ADDR: begin  // uart
              dram_done_r <= 1'b1;
              status_r <= STATUS_DONE;
              if (dram_addr_r == `MEM_UART_TX_DATA) begin
                if (dram_wr_r) begin
                  uart_tx_enable_r <= 1'b1;
                  uart_tx_flag_r   <= 32'hffffffff;
                  uart_tx_data_r   <= dram_data_wr_r;
                end else begin
                  dram_data_rd_r <= uart_tx_data_r;
                end
              end else if (dram_addr_r == `MEM_UART_TX_FLAG) begin
                if (dram_wr_r) begin
                  uart_tx_flag_r <= dram_data_wr_r;
                end else begin
                  dram_data_rd_r <= uart_tx_flag_r;
                end
              end else if (dram_addr_r == `MEM_UART_RX_DATA) begin
                if (dram_wr_r) begin
                  uart_rx_data_r <= dram_data_wr_r;
                end else begin
                  dram_data_rd_r <= uart_rx_data_r;
                end
              end else if (dram_addr_r == `MEM_UART_RX_FLAG) begin
                if (dram_wr_r) begin
                  uart_rx_flag_r <= dram_data_wr_r;
                end else begin
                  dram_data_rd_r <= uart_rx_flag_r;
                end
              end
            end

            `MEM_TIMER_ADDR: begin  // timer
              dram_done_r <= 1'b1;
              status_r <= STATUS_DONE;

              case (dram_addr_r)
                `MEM_TIMER_CYCLE: dram_data_rd_r <= timer_cycle_i;
                `MEM_TIMER_CYCLEH: dram_data_rd_r <= timer_cycleh_i;
                `MEM_TIMER_TIME: dram_data_rd_r <= timer_time_i;
                `MEM_TIMER_TIMEH: dram_data_rd_r <= timer_timeh_i;
                `MEM_TIMER_TIMECMP: dram_data_rd_r <= timer_timecmp_i;
                `MEM_TIMER_TIMECMPH: dram_data_rd_r <= timer_timecmph_i;
                default: ;
              endcase

              if (dram_wr_r) begin
                case (dram_addr_r)
                  `MEM_TIMER_TIMECMP: timer_timecmp_o <= dram_data_wr_r;
                  `MEM_TIMER_TIMECMPH: timer_timecmph_o <= dram_data_wr_r;
                  default: ;
                endcase
              end
            end

            `MEM_VRAM_ADDR: begin  // vram
              status_r       <= STATUS_WAIT;
              vram_enable_o  <= 1'b1;
              vram_wr_o      <= dram_wr_r;
              vram_rd_o      <= dram_rd_r;
              vram_addr_o    <= {4'h0, dram_addr_r[27:0]};
              vram_data_wr_o <= dram_data_wr_r;
              vram_mask_wr_o <= dram_mask_wr_r;
            end

            `MEM_LED_ADDR: begin  // led
              status_r        <= STATUS_WAIT;
              led_idx_o       <= dram_addr_r[4:0];
              led_wr_o        <= dram_wr_r;
              led_status_wr_o <= dram_data_wr_r[0];
            end

            `MEM_SWITCH_ADDR: begin  // switch
              status_r     <= STATUS_WAIT;
              switch_idx_o <= dram_addr_r[4:0];
            end

            `MEM_RAM_ADDR: begin  // ram
              status_r      <= STATUS_WAIT;
              ram_enable_o  <= 1'b1;
              ram_wr_o      <= dram_wr_r;
              ram_rd_o      <= dram_rd_r;
              ram_addr_o    <= {4'h0, dram_addr_r[27:0]};
              ram_data_wr_o <= dram_data_wr_r;
              ram_mask_wr_o <= dram_mask_wr_r;
            end

            default: status_r <= STATUS_DONE;
          endcase
        end

        STATUS_WAIT: begin
          case (dram_addr_r & `MEM_RAM_MASK)
            `MEM_VRAM_ADDR: begin  // vram
              status_r <= STATUS_WAIT;
              vram_enable_o <= 1'b0;
              if (vram_done_i) begin
                status_r       <= STATUS_DONE;
                dram_data_rd_r <= vram_data_rd_i;
                dram_done_r    <= 1'b1;
              end
            end

            `MEM_LED_ADDR: begin  // led
              status_r    <= STATUS_DONE;
              dram_data_rd_r <= {32{led_status_rd_i}};
              dram_done_r <= 1'b1;
            end

            `MEM_SWITCH_ADDR: begin  // switch
              status_r       <= STATUS_DONE;
              dram_data_rd_r <= {32{switch_status_i}};
              dram_done_r    <= 1'b1;
            end

            `MEM_RAM_ADDR: begin  // ram
              status_r <= STATUS_WAIT;
              ram_enable_o <= 1'b0;
              if (ram_done_i) begin
                status_r       <= STATUS_DONE;
                dram_data_rd_r <= ram_data_rd_i;
                dram_done_r    <= 1'b1;
              end
            end
            default: status_r <= STATUS_DONE;
          endcase
        end

        STATUS_DONE: begin
          status_r <= STATUS_IDLE;
          uart_tx_enable_r <= 1'b0;
          dram_done_r <= 1'b0;
        end

        default: ;
      endcase
    end
  end
endmodule
