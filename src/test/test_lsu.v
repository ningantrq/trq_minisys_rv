`include "../core/core_defs.v"

module test_lsu;
  reg         clk;
  reg         rst;

  reg  [31:0] inst;
  reg  [31:0] addr;
  reg  [31:0] data_wr;
  reg         enable;
  reg  [31:0] mem_data_rd;
  reg   mem_done;

  wire [31:0] data_rd;
  wire        mem_rd;
  wire        mem_wr;
  wire [31:0] mem_addr;
  wire        mem_enable;
  wire [31:0] mem_data_wr;
  wire [31:0] mem_mask_wr;
  wire        stall;

  core_lsu uut (
      .clk_i(clk),
      .rst_i(rst),
      .inst_i(inst),
      .addr_i(addr),
      .data_wr_i(data_wr),
      .enable_i(enable),
      .mem_data_rd_i(mem_data_rd),
      .mem_done_i(mem_done),
      .data_rd_o(data_rd),
      .mem_rd_o(mem_rd),
      .mem_wr_o(mem_wr),
      .mem_addr_o(mem_addr),
      .mem_enable_o(mem_enable),
      .mem_data_wr_o(mem_data_wr),
      .mem_mask_wr_o(mem_mask_wr),
      .stall_o(stall)
  );

  localparam TB_LOAD_NUM = 5;
  localparam TB_STORE_NUM = 3;
  reg [31:0] load_inst_arr[TB_LOAD_NUM - 1:0];
  reg [31:0] store_inst_arr[TB_STORE_NUM - 1:0];

  integer i;

  always #5 clk = ~clk;

  initial begin
    $dumpfile("test_lsu.vcd");
    $dumpvars(0, test_lsu);

    clk               = 1'b0;
    rst               = 1'b1;
    addr              = 32'h00000000;
    data_wr           = 32'h00000000;

    load_inst_arr[0]  = `INST_LB;
    load_inst_arr[1]  = `INST_LH;
    load_inst_arr[2]  = `INST_LW;
    load_inst_arr[3]  = `INST_LBU;
    load_inst_arr[4]  = `INST_LHU;

    store_inst_arr[0] = `INST_SB;
    store_inst_arr[1] = `INST_SH;
    store_inst_arr[2] = `INST_SW;

    #10 rst = 1'b0;

    $display("----- LSU testbench start -----");
    $display("----- LOAD testbench start -----");

    $display("----- LOAD 0x12345678 -----");

    for (i = 0; i < TB_LOAD_NUM; i = i + 1) begin
      inst        = load_inst_arr[i];
      enable      = 1'b1;
      mem_data_rd = 32'h00000000;
      mem_done    = 1'b0;

      #10 enable = 1'b0;

      wait (mem_enable);
      #20;
      mem_done    = 1'b1;
      mem_data_rd = 32'h12345678;

      wait (!stall);
      case (inst)
        `INST_LB:  $display("INST_LB read: %h", data_rd);
        `INST_LH:  $display("INST_LH read: %h", data_rd);
        `INST_LW:  $display("INST_LW read: %h", data_rd);
        `INST_LBU: $display("INST_LBU read: %h", data_rd);
        `INST_LHU: $display("INST_LHU read: %h", data_rd);
        default:   $display("ILLEGAL INST!");
      endcase
      #30;
    end

    $display("----- LOAD 0x8234d6f8 -----");

    for (i = 0; i < TB_LOAD_NUM; i = i + 1) begin
      inst        = load_inst_arr[i];
      enable      = 1'b1;
      mem_data_rd = 32'h00000000;
      mem_done    = 1'b0;

      #10 enable = 1'b0;

      wait (mem_enable);
      #20;
      mem_done    = 1'b1;
      mem_data_rd = 32'h8234d6f8;

      wait (!stall);
      case (inst)
        `INST_LB:  $display("INST_LB read: %h", data_rd);
        `INST_LH:  $display("INST_LH read: %h", data_rd);
        `INST_LW:  $display("INST_LW read: %h", data_rd);
        `INST_LBU: $display("INST_LBU read: %h", data_rd);
        `INST_LHU: $display("INST_LHU read: %h", data_rd);
        default:   $display("ILLEGAL INST!");
      endcase
      #30;
    end

    $display("----- LOAD testbench end -----");
    $display("----- STORE testbench start -----");

    for (i = 0; i < TB_STORE_NUM; i = i + 1) begin
      inst        = store_inst_arr[i];
      enable      = 1'b1;
      data_wr     = 32'h12345678;
      mem_data_rd = 32'h00000000;
      mem_done    = 1'b0;

      #10 enable = 1'b0;

      wait (mem_enable);
      case (inst)
        `INST_SB: $display("INST_SB store: %h, mask: %h", mem_data_wr, mem_mask_wr);
        `INST_SH: $display("INST_SH store: %h, mask: %h", mem_data_wr, mem_mask_wr);
        `INST_SW: $display("INST_SW store: %h, mask: %h", mem_data_wr, mem_mask_wr);
        default:  $display("ILLEGAL INST!");
      endcase
      #20;
      mem_done    = 1'b1;
      mem_data_rd = 32'h8234d6f8;
      wait (!stall);
      #30;
    end

    $display("----- STORE testbench end -----");
    $display("----- LSU testbench end -----");
    
    $finish;  // 终止仿真
  end

endmodule
