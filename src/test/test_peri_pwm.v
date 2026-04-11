`timescale 1ns / 1ps

// 包含被测试的PWM模块
`include "../peri/peri_pwm.v"

module test_peri_pwm;
  // 时钟和复位信号
  reg        clk;
  reg        rst;
  
  // PWM控制器接口
  reg        reg_wr;
  reg        reg_rd;
  reg  [31:0] reg_addr;
  reg  [31:0] reg_data_wr;
  wire [31:0] reg_data_rd;
  
  // PWM输出
  wire       pwm0;
  wire       pwm1;
  wire       pwm2;
  wire       pwm3;
  
  // 实例化PWM控制器
  peri_pwm uut (
      .clk_i(clk),
      .rst_i(rst),
      
      // 寄存器接口
      .reg_addr_i(reg_addr),
      .reg_wr_i(reg_wr),
      .reg_rd_i(reg_rd),
      .reg_data_wr_i(reg_data_wr),
      .reg_data_rd_o(reg_data_rd),
      
      // PWM输出
      .pwm0_o(pwm0),
      .pwm1_o(pwm1),
      .pwm2_o(pwm2),
      .pwm3_o(pwm3)
  );
  
  // 时钟生成 (50MHz)
  always #10 clk = ~clk;  // 20ns周期，50MHz
  
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
    #20;
    rst = 1'b0;
    
    // 等待一段时间
    #50;
    
    // =============================
    // 测试1: 寄存器写操作
    // =============================
    $display("\n测试1: 寄存器写操作");
    
    // 设置周期为100 (2us)
    reg_wr = 1'b1;
    reg_addr = 32'h00;  // 周期寄存器地址
    reg_data_wr = 32'd100;
    #20;  // 一个时钟周期
    reg_wr = 1'b0;
    
    // 设置通道0占空比为50 (50%)
    reg_wr = 1'b1;
    reg_addr = 32'h04;  // 通道0占空比寄存器地址
    reg_data_wr = 32'd50;
    #20;
    reg_wr = 1'b0;
    
    // 设置通道1占空比为25 (25%)
    reg_wr = 1'b1;
    reg_addr = 32'h08;  // 通道1占空比寄存器地址
    reg_data_wr = 32'd25;
    #20;
    reg_wr = 1'b0;
    
    // 设置通道2占空比为75 (75%)
    reg_wr = 1'b1;
    reg_addr = 32'h0C;  // 通道2占空比寄存器地址
    reg_data_wr = 32'd75;
    #20;
    reg_wr = 1'b0;
    
    // 设置通道3占空比为10 (10%)
    reg_wr = 1'b1;
    reg_addr = 32'h10;  // 通道3占空比寄存器地址
    reg_data_wr = 32'd10;
    #20;
    reg_wr = 1'b0;
    
    // 使能PWM总开关和所有通道
    reg_wr = 1'b1;
    reg_addr = 32'h14;  // 控制寄存器地址
    reg_data_wr = 32'b00011111;  // 第0位总使能，1-4位通道使能
    #20;
    reg_wr = 1'b0;
    
    // =============================
    // 测试2: 寄存器读操作
    // =============================
    $display("\n测试2: 寄存器读操作");
    
    // 读取周期寄存器
    reg_rd = 1'b1;
    reg_addr = 32'h00;
    #20;
    $display("周期寄存器值: %d", reg_data_rd);
    reg_rd = 1'b0;
    
    // 读取通道0占空比寄存器
    reg_rd = 1'b1;
    reg_addr = 32'h04;
    #20;
    $display("通道0占空比寄存器值: %d", reg_data_rd);
    reg_rd = 1'b0;
    
    // 读取控制寄存器
    reg_rd = 1'b1;
    reg_addr = 32'h14;
    #20;
    $display("控制寄存器值: 0x%h", reg_data_rd);
    reg_rd = 1'b0;
    
    // =============================
    // 测试3: 观察PWM波形
    // =============================
    $display("\n测试3: 观察PWM波形");
    $display("PWM0: 50%%占空比, PWM1: 25%%占空比");
    $display("PWM2: 75%%占空比, PWM3: 10%%占空比");
    $display("观察波形5000ns...");
    
    // 等待5000ns观察波形
    #5000;
    
    // =============================
    // 测试4: 动态修改占空比
    // =============================
    $display("\n测试4: 动态修改占空比");
    
    // 修改通道0占空比为80%
    reg_wr = 1'b1;
    reg_addr = 32'h04;
    reg_data_wr = 32'd80;
    #20;
    reg_wr = 1'b0;
    
    $display("已将通道0占空比修改为80%");
    
    // 等待4000ns观察波形变化
    #4000;
    
    // =============================
    // 测试5: 关闭PWM
    // =============================
    $display("\n测试5: 关闭PWM");
    
    // 关闭PWM总开关
    reg_wr = 1'b1;
    reg_addr = 32'h14;
    reg_data_wr = 32'b00000000;
    #20;
    reg_wr = 1'b0;
    
    $display("PWM已关闭，所有输出应为低电平");
    
    // 等待100ns观察
    #100;
    
    // 结束测试
    $display("\nPWM控制器测试完成！");
    $finish;
  end
  
  // 监测PWM输出变化
  always @(posedge pwm0 or negedge pwm0) begin
    $display("%t: PWM0 = %b", $time, pwm0);
  end
  
  always @(posedge pwm1 or negedge pwm1) begin
    $display("%t: PWM1 = %b", $time, pwm1);
  end
  
  always @(posedge pwm2 or negedge pwm2) begin
    $display("%t: PWM2 = %b", $time, pwm2);
  end
  
  always @(posedge pwm3 or negedge pwm3) begin
    $display("%t: PWM3 = %b", $time, pwm3);
  end
  
endmodule