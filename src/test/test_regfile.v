`timescale 1ns / 1ps

module test_regfile;
    reg         clk;
    reg         rst;
    reg  [4:0]  rd;
    reg  [31:0] rd_data;
    reg  [4:0]  ra;
    wire [31:0] ra_data;
    reg  [4:0]  rb;
    wire [31:0] rb_data;
    
    // 实例化寄存器文件
    core_regfile uut (
        .clk_i(clk),
        .rst_i(rst),
        .rd_i(rd),
        .rd_data_i(rd_data),
        .ra_i(ra),
        .ra_data_o(ra_data),
        .rb_i(rb),
        .rb_data_o(rb_data)
    );
    
    // 生成时钟
    always #5 clk = ~clk;
    
    initial begin
        $dumpfile("test_regfile.vcd");      // 生成波形文件
        $dumpvars(0, test_regfile);
        $display("=== Regfile Test Begin ===");
        clk = 0;
        rst = 1;
        rd = 0;
        rd_data = 0;
        ra = 0;
        rb = 0;
        
        // 复位
        #10 rst = 0;
        
        // 测试1：写入x1寄存器
        #10;
        rd = 5'd1;
        rd_data = 32'hABCD_EF01;
        #10;  // 等待写入完成
        ra = 5'd1;
        #1;  // 等待组合逻辑稳定
        $display("Test 1: Write x1=0xABCD_EF01, Read x1=0x%h", ra_data);
        
        // 测试2：写入x2寄存器
        #10;
        rd = 5'd2;
        rd_data = 32'hCAFEBABE;
        #10;
        ra = 5'd2;
        #1;
        $display("Test 2: Write x2=0xCAFEBABE, Read x2=0x%h", ra_data);
        
        // 测试3：同时读x1和x2
        ra = 5'd1;
        rb = 5'd2;
        #1;
        $display("Test 3: Read x1=0x%h, x2=0x%h simultaneously", ra_data, rb_data);
        
        // 测试4：尝试写入x0（应该被忽略）
        #10;
        rd = 5'd0;
        rd_data = 32'hFFFFFFFF;
        #10;
        ra = 5'd0;
        #1;
        $display("Test 4: Try write x0=0xFFFFFFFF, Read x0=0x%h (should be 0)", ra_data);
        
        // 测试5：验证x1和x2未被破坏
        ra = 5'd1;
        rb = 5'd2;
        #1;
        $display("Test 5: Verify x1=0x%h, x2=0x%h (should be unchanged)", ra_data, rb_data);
        
        $display("=== Regfile Test End ===");
        $finish;
    end
endmodule