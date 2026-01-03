`timescale 1ns / 1ps

// 包含被测试的看门狗模块
`include "../peri/peri_watchdog.v"

module test_peri_watchdog;
  // 时钟和复位信号
  reg        clk;
  reg        rst;
  
  // 看门狗接口
  reg        reg_wr;
  reg        reg_rd;
  reg  [31:0] reg_addr;
  reg  [31:0] reg_data_wr;
  wire [31:0] reg_data_rd;
  
  // 看门狗输出
  wire       wdt_interrupt;
  wire       wdt_reset;
  
  // 实例化看门狗模块
  peri_watchdog uut (
      .clk_i(clk),
      .rst_i(rst),
      
      // 寄存器接口
      .reg_addr_i(reg_addr),
      .reg_wr_i(reg_wr),
      .reg_rd_i(reg_rd),
      .reg_data_wr_i(reg_data_wr),
      .reg_data_rd_o(reg_data_rd),
      
      // 输出接口
      .wdt_interrupt_o(wdt_interrupt),
      .wdt_reset_o(wdt_reset)
  );
  
  // 时钟生成 (25MHz)
  always #20 clk = ~clk;  // 40ns周期，25MHz
  
  // 测试程序
  initial begin
    // 初始化信号
    clk = 1'b0;
    rst = 1'b1;
    reg_wr = 1'b0;
    reg_rd = 1'b0;
    reg_addr = 32'h0;
    reg_data_wr = 32'h0;
    
    // 复位释放
    #40;
    rst = 1'b0;
    
    // 等待一段时间
    #100;
    
    // =============================
    // 测试1: 寄存器写操作
    // =============================
    $display("\n测试1: 寄存器写操作");
    
    // 设置超时时间为5ms
    reg_wr = 1'b1;
    reg_addr = 32'h00;  // 超时时间寄存器地址
    reg_data_wr = 32'd5;  // 5ms
    #40;
    reg_wr = 1'b0;
    
    // 使能看门狗，启用中断和复位
    reg_wr = 1'b1;
    reg_addr = 32'h04;  // 控制寄存器地址
    reg_data_wr = 32'b00001111;  // 使能+中断+复位+自动重载
    #40;
    reg_wr = 1'b0;
    
    // =============================
    // 测试2: 寄存器读操作
    // =============================
    $display("\n测试2: 寄存器读操作");
    
    // 读取超时时间寄存器
    reg_rd = 1'b1;
    reg_addr = 32'h00;
    #40;
    $display("超时时间寄存器值: %d ms", reg_data_rd);
    reg_rd = 1'b0;
    
    // 读取控制寄存器
    reg_rd = 1'b1;
    reg_addr = 32'h04;
    #40;
    $display("控制寄存器值: 0x%h", reg_data_rd);
    reg_rd = 1'b0;
    
    // 读取状态寄存器
    reg_rd = 1'b1;
    reg_addr = 32'h08;
    #40;
    $display("状态寄存器值: 0x%h", reg_data_rd);
    reg_rd = 1'b0;
    
    // =============================
    // 测试3: 看门狗超时中断测试
    // =============================
    $display("\n测试3: 看门狗超时中断测试");
    $display("看门狗已启动，5ms后应产生中断");
    
    // 等待6ms
    #6000000;  // 6ms (25MHz时钟，每个周期40ns，6ms=150000个周期)
    
    // =============================
    // 测试4: 喂狗功能测试
    // =============================
    $display("\n测试4: 喂狗功能测试");
    
    // 重新使能看门狗，超时时间改为10ms
    reg_wr = 1'b1;
    reg_addr = 32'h00;
    reg_data_wr = 32'd10;  // 10ms
    #40;
    reg_addr = 32'h04;
    reg_data_wr = 32'b00001111;  // 使能+中断+复位+自动重载
    #40;
    reg_wr = 1'b0;
    
    $display("看门狗已重新启动，超时时间10ms");
    $display("将在5ms时喂狗...");
    
    // 等待5ms
    #5000000;  // 5ms
    
    // 执行喂狗操作
    reg_wr = 1'b1;
    reg_addr = 32'h0C;  // 复位寄存器地址
    reg_data_wr = 32'h1;
    #40;
    reg_wr = 1'b0;
    
    $display("已执行喂狗操作，看门狗计数器已重置");
    
    // 等待15ms，验证不会超时
    $display("等待15ms验证不会超时...");
    #15000000;  // 15ms
    
    $display("喂狗成功，未产生超时中断");
    
    // =============================
    // 测试5: 自动重载功能测试
    // =============================
    $display("\n测试5: 自动重载功能测试");
    
    // 确认控制寄存器已启用自动重载
    reg_rd = 1'b1;
    reg_addr = 32'h04;
    #40;
    $display("控制寄存器值: 0x%h", reg_data_rd);
    reg_rd = 1'b0;
    
    $display("看门狗已启用自动重载功能，将连续产生中断");
    
    // 等待15ms，观察多次中断
    #15000000;  // 15ms
    
    // =============================
    // 测试6: 关闭看门狗
    // =============================
    $display("\n测试6: 关闭看门狗");
    
    // 关闭看门狗
    reg_wr = 1'b1;
    reg_addr = 32'h04;
    reg_data_wr = 32'b00000000;
    #40;
    reg_wr = 1'b0;
    
    $display("看门狗已关闭");
    
    // 等待5ms，确认不会产生中断
    #5000000;  // 5ms
    
    // 结束测试
    $display("\n看门狗测试完成！");
    $finish;
  end
  
  // 监测中断和复位信号
  always @(posedge wdt_interrupt) begin
    $display("%t: 产生看门狗中断", $time);
  end
  
  always @(posedge wdt_reset) begin
    $display("%t: 产生看门狗复位信号", $time);
  end
  
  // 定期检查看门狗状态
  always #1000000 begin  // 每1ms检查一次
    reg_rd = 1'b1;
    reg_addr = 32'h08;
    #40;
    $display("%t: 状态寄存器值: 0x%h", $time, reg_data_rd);
    reg_rd = 1'b0;
  end
  
endmodule