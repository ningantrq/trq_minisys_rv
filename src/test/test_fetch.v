module test_fetch;
  reg         clk;
  reg         rst;

  reg  [31:0] pc_branch;
  reg         pc_take_branch;
  reg         enable;
  reg  [31:0] mem_data;
  reg         mem_done;
  reg  [31:0] mem_addr_r;

  wire [31:0] pc_o;
  wire [31:0] inst;
  wire [31:0] mem_addr;
  wire        mem_enable;
  wire        stall;

  core_fetch uut (
      .clk_i(clk),
      .rst_i(rst),
      .pc_branch_i(pc_branch),
      .pc_take_branch_i(pc_take_branch),
      .enable_i(enable),
      .mem_data_i(mem_data),
      .mem_done_i(mem_done),
      .pc_o(pc_o),
      .inst_o(inst),
      .mem_addr_o(mem_addr),
      .mem_enable_o(mem_enable),
      .stall_o(stall)
  );

  always #5 clk = ~clk;

  initial begin
    $dumpfile("test_fetch.vcd");
    $dumpvars(0, test_fetch);
    $display("----- FETCH testbench start -----");
    clk = 1'b0;
    rst = 1'b1;

    #10 rst = 1'b0;


    pc_branch = 32'h12345678;
    pc_take_branch = 1'b1;
    enable    = 1'b1;
    mem_done  = 1'b0;
    mem_data  = 32'h00000000;

    #10;
    pc_take_branch = 1'b0;
    enable = 1'b0;
    wait (mem_enable);
    mem_addr_r = mem_addr;
    #30;
    mem_done = 1'b1;
    mem_data = mem_addr_r;
    #10;
    mem_done = 1'b0;

    wait (!stall);
    enable = 1'b1;
    #10;
    enable = 1'b0;
    wait (mem_enable);
    mem_addr_r = mem_addr;
    #30;
    mem_done = 1'b1;
    mem_data = mem_addr_r;
    #10;
    mem_done = 1'b0;

    pc_branch = 32'h87654321;
    pc_take_branch = 1'b1;
    wait (!stall);
    enable = 1'b1;
    #10;
    enable = 1'b0;
    wait (mem_enable);
    mem_addr_r = mem_addr;
    #30;
    mem_done = 1'b1;
    mem_data = mem_addr_r;
    #10;
    mem_done = 1'b0;

    $display("----- FETCH testbench end -----");
    #100 $finish;
  end

endmodule
