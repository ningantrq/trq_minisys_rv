module minisys_soc (
    input clk_i,
    input rst_i,

    // uart
    input  rx_i,
    output tx_o,

    // led
    output gld0_o,
    output gld1_o,
    output gld2_o,
    output gld3_o,
    output gld4_o,
    output gld5_o,
    output gld6_o,
    output gld7_o,

    output yld0_o,
    output yld1_o,
    output yld2_o,
    output yld3_o,
    output yld4_o,
    output yld5_o,
    output yld6_o,
    output yld7_o,

    output rld0_o,
    output rld1_o,
    output rld2_o,
    output rld3_o,
    output rld4_o,
    output rld5_o,
    output rld6_o,
    output rld7_o,

    // switch
    input sw0_i,
    input sw1_i,
    input sw2_i,
    input sw3_i,
    input sw4_i,
    input sw5_i,
    input sw6_i,
    input sw7_i,
    input sw8_i,
    input sw9_i,
    input sw10_i,
    input sw11_i,
    input sw12_i,
    input sw13_i,
    input sw14_i,
    input sw15_i,
    input sw16_i,
    input sw17_i,
    input sw18_i,
    input sw19_i,
    input sw20_i,
    input sw21_i,
    input sw22_i,
    input sw23_i,

    // vga
    output [3:0] red_o,
    output [3:0] green_o,
    output [3:0] blue_o,
    output       h_sync_o,
    output       v_sync_o
);
  wire clk_w;

  ip_clock_div clk_div (
      // Clock out ports
      .clk_out1(clk_w),  // output clk_out1
      // Status and control signals
      .reset   (1'b0),     // input reset
      // Clock in ports
      .clk_in1 (clk_i)    // input clk_in1
  );

  wire [31:0] iram_data_w;
  wire        iram_done_w;
  wire        iram_enable_w;
  wire [31:0] iram_addr_w;
  wire [31:0] dram_data_rd_w;
  wire        dram_done_w;
  wire        dram_enable_w;
  wire        dram_wr_w;
  wire        dram_rd_w;
  wire [31:0] dram_addr_w;
  wire [31:0] dram_data_wr_w;
  wire [31:0] dram_mask_wr_w;

  core_top core (
      .clk_i(clk_w),
      .rst_i(rst_i),

      .timer_interrupt_i(timer_interrupt_w),

      .iram_data_i  (iram_data_w),
      .iram_done_i  (iram_done_w),
      .iram_enable_o(iram_enable_w),
      .iram_addr_o  (iram_addr_w),

      .dram_data_rd_i(dram_data_rd_w),
      .dram_done_i   (dram_done_w),
      .dram_enable_o (dram_enable_w),
      .dram_wr_o     (dram_wr_w),
      .dram_rd_o     (dram_rd_w),
      .dram_addr_o   (dram_addr_w),
      .dram_data_wr_o(dram_data_wr_w),
      .dram_mask_wr_o(dram_mask_wr_w)
  );
  // uart
  wire        tx_enable_w;
  wire [ 7:0] tx_data_w;

  wire        rx_done_w;
  wire [ 7:0] rx_data_w;
  wire        tx_done_w;

  // timer
  wire [31:0] timer_cycle_w;
  wire [31:0] timer_cycleh_w;
  wire [31:0] timer_time_w;
  wire [31:0] timer_timeh_w;
  wire [31:0] timer_timecmp_w;
  wire [31:0] timer_timecmph_w;

  wire [31:0] timer_timecmp_wr_w;
  wire [31:0] timer_timecmph_wr_w;

  wire        timer_interrupt_w;

  // vram
  wire [31:0] vram_data_rd_w;
  wire        vram_done_w;

  wire        vram_enable_w;
  wire        vram_wr_w;
  wire        vram_rd_w;
  wire [31:0] vram_addr_w;
  wire [31:0] vram_data_wr_w;
  wire [31:0] vram_mask_wr_w;

  // ram
  wire [31:0] ram_data_rd_w;
  wire        ram_done_w;
  wire        ram_enable_w;
  wire        ram_wr_w;
  wire        ram_rd_w;
  wire [31:0] ram_addr_w;
  wire [31:0] ram_data_wr_w;
  wire [31:0] ram_mask_wr_w;

  peri_bridge bridge (
      .clk_i(clk_w),
      .rst_i(rst_i),

      .dram_rd_i     (dram_rd_w),
      .dram_wr_i     (dram_wr_w),
      .dram_addr_i   (dram_addr_w),
      .dram_enable_i (dram_enable_w),
      .dram_data_wr_i(dram_data_wr_w),
      .dram_mask_wr_i(dram_mask_wr_w),

      .dram_data_rd_o(dram_data_rd_w),
      .dram_done_o   (dram_done_w),

      // timer
      .timer_cycle_i(timer_cycle_w),
      .timer_cycleh_i(timer_cycleh_w),
      .timer_time_i(timer_time_w),
      .timer_timeh_i(timer_timeh_w),
      .timer_timecmp_i(timer_timecmp_w),
      .timer_timecmph_i(timer_timecmph_w),

      .timer_timecmp_o (timer_timecmp_wr_w),
      .timer_timecmph_o(timer_timecmph_wr_w),

      // uart
      .tx_enable_o(tx_enable_w),
      .tx_data_o  (tx_data_w),

      .rx_done_i(rx_done_w),
      .rx_data_i(rx_data_w),
      .tx_done_i(tx_done_w),

      // vram
      .vram_data_rd_i(vram_data_rd_w),
      .vram_done_i   (vram_done_w),

      .vram_enable_o (vram_enable_w),
      .vram_wr_o     (vram_wr_w),
      .vram_rd_o     (vram_rd_w),
      .vram_addr_o   (vram_addr_w),
      .vram_data_wr_o(vram_data_wr_w),
      .vram_mask_wr_o(vram_mask_wr_w),

      // led
      .led_idx_o      (led_idx_w),
      .led_wr_o       (led_wr_w),
      .led_status_wr_o(led_status_wr_w),
      .led_status_rd_i(led_status_rd_w),

      // switch
      .switch_idx_o   (switch_idx_w),
      .switch_status_i(switch_status_w),

      // ram
      .ram_data_rd_i(ram_data_rd_w),
      .ram_done_i   (ram_done_w),
      .ram_enable_o (ram_enable_w),
      .ram_wr_o     (ram_wr_w),
      .ram_rd_o     (ram_rd_w),
      .ram_addr_o   (ram_addr_w),
      .ram_data_wr_o(ram_data_wr_w),
      .ram_mask_wr_o(ram_mask_wr_w)
  );

  peri_uart uart (
      .clk_i      (clk_w),
      .rst_i      (rst_i),
      .tx_enable_i(tx_enable_w),
      .tx_data_i  (tx_data_w),
      .rx_i       (rx_i),

      .rx_done_o(rx_done_w),
      .rx_data_o(rx_data_w),
      .tx_done_o(tx_done_w),
      .tx_o     (tx_o)
  );

  peri_timer timer (
      .clk_i(clk_w),
      .rst_i(rst_i),

      .timecmp_i (timer_timecmp_wr_w),
      .timecmph_i(timer_timecmph_wr_w),

      .cycle_o(timer_cycle_w),
      .cycleh_o(timer_cycleh_w),
      .time_o(timer_time_w),
      .timeh_o(timer_timeh_w),
      .timecmp_o(timer_timecmp_w),
      .timecmph_o(timer_timecmph_w),

      .timer_interrupt_o(timer_interrupt_w)
  );

  wire        vga_clk_w;
  wire [ 9:0] vga_h_addr_w;
  wire [ 9:0] vga_v_addr_w;
  wire [11:0] vga_data_w;

  peri_vram vram (
      .clk_i(clk_w),
      .rst_i(rst_i),

      .vram_data_rd_o(vram_data_rd_w),
      .vram_done_o   (vram_done_w),

      .vram_enable_i (vram_enable_w),
      .vram_wr_i     (vram_wr_w),
      .vram_rd_i     (vram_rd_w),
      .vram_addr_i   (vram_addr_w),
      .vram_data_wr_i(vram_data_wr_w),
      .vram_mask_wr_i(vram_mask_wr_w),

      .vga_clk_i   (vga_clk_w),
      .vga_h_addr_i(vga_h_addr_w),
      .vga_v_addr_i(vga_v_addr_w),
      .vga_data_o  (vga_data_w)
  );

  wire [4:0] led_idx_w;
  wire       led_wr_w;
  wire       led_status_wr_w;
  wire       led_status_rd_w;

  peri_led led (
      .clk_i(clk_w),
      .rst_i(rst_i),
      .idx_i(led_idx_w),
      .wr_i(led_wr_w),
      .status_wr_i(led_status_wr_w),
      .status_rd_o(led_status_rd_w),

      .gld0_o(gld0_o),
      .gld1_o(gld1_o),
      .gld2_o(gld2_o),
      .gld3_o(gld3_o),
      .gld4_o(gld4_o),
      .gld5_o(gld5_o),
      .gld6_o(gld6_o),
      .gld7_o(gld7_o),

      .yld0_o(yld0_o),
      .yld1_o(yld1_o),
      .yld2_o(yld2_o),
      .yld3_o(yld3_o),
      .yld4_o(yld4_o),
      .yld5_o(yld5_o),
      .yld6_o(yld6_o),
      .yld7_o(yld7_o),

      .rld0_o(rld0_o),
      .rld1_o(rld1_o),
      .rld2_o(rld2_o),
      .rld3_o(rld3_o),
      .rld4_o(rld4_o),
      .rld5_o(rld5_o),
      .rld6_o(rld6_o),
      .rld7_o(rld7_o)
  );

  wire [4:0] switch_idx_w;
  wire       switch_status_w;

  peri_switch switch (
      .idx_i(switch_idx_w),
      .status_o(switch_status_w),

      .sw0_i (sw0_i),
      .sw1_i (sw1_i),
      .sw2_i (sw2_i),
      .sw3_i (sw3_i),
      .sw4_i (sw4_i),
      .sw5_i (sw5_i),
      .sw6_i (sw6_i),
      .sw7_i (sw7_i),
      .sw8_i (sw8_i),
      .sw9_i (sw9_i),
      .sw10_i(sw10_i),
      .sw11_i(sw11_i),
      .sw12_i(sw12_i),
      .sw13_i(sw13_i),
      .sw14_i(sw14_i),
      .sw15_i(sw15_i),
      .sw16_i(sw16_i),
      .sw17_i(sw17_i),
      .sw18_i(sw18_i),
      .sw19_i(sw19_i),
      .sw20_i(sw20_i),
      .sw21_i(sw21_i),
      .sw22_i(sw22_i),
      .sw23_i(sw23_i)
  );

  peri_vga vga (
      .clk_i     (clk_i),
      .rst_i     (rst_i),
      .vga_data_i(vga_data_w),

      .vga_clk_o(vga_clk_w),
      .h_addr_o (vga_h_addr_w),
      .v_addr_o (vga_v_addr_w),
      .red_o    (red_o),
      .green_o  (green_o),
      .blue_o   (blue_o),
      .h_sync_o (h_sync_o),
      .v_sync_o (v_sync_o)
  );

  peri_ram ram (
      .clk_i(clk_w),
      .rst_i(rst_i),

      .iram_data_o   (iram_data_w),
      .iram_done_o   (iram_done_w),
      .iram_enable_i (iram_enable_w),
      .iram_addr_i   ({4'h0, iram_addr_w[27:0]}),
      .dram_data_rd_o(ram_data_rd_w),
      .dram_done_o   (ram_done_w),
      .dram_enable_i (ram_enable_w),
      .dram_wr_i     (ram_wr_w),
      .dram_rd_i     (ram_rd_w),
      .dram_addr_i   (ram_addr_w),
      .dram_data_wr_i(ram_data_wr_w),
      .dram_mask_wr_i(ram_mask_wr_w)
  );
endmodule
