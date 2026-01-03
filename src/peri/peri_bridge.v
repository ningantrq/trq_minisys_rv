// verilog_format: off
// Memory addr
`define MEM_RAM_MASK        32'hf0000000

`define MEM_UART_ADDR       32'h00000000
`define MEM_UART_TX_DATA    32'h00000000// 发送数据寄存器
`define MEM_UART_TX_FLAG    32'h00000001// 发送状态标志
`define MEM_UART_RX_DATA    32'h00000002// 接收数据寄存器
`define MEM_UART_RX_FLAG    32'h00000003// 接收状态标志

`define MEM_TIMER_ADDR      32'h10000000
`define MEM_TIMER_CYCLE     32'h10000000// 周期计数低32位
`define MEM_TIMER_CYCLEH    32'h10000004// 周期计数高32位
`define MEM_TIMER_TIME      32'h10000008// 时间计数低32位
`define MEM_TIMER_TIMEH     32'h1000000C// 时间计数高32位
`define MEM_TIMER_TIMECMP   32'h10000010// 比较值低32位
`define MEM_TIMER_TIMECMPH  32'h10000014// 比较值高32位


`define MEM_VRAM_ADDR       32'h20000000
`define MEM_LED_ADDR        32'h30000000
`define MEM_SWITCH_ADDR     32'h40000000
`define MEM_KEYBOARD_ADDR   32'h50000000  // 键盘外设基地址（只读，返回4位键值）
`define MEM_SEG_ADDR        32'h60000000  // 数码管外设基地址（只写，接收32位数据，8个4位BCD码）
`define MEM_PWM_ADDR        32'h70000000  // PWM控制器基地址
`define MEM_WATCHDOG_ADDR   32'h90000000  // 看门狗基地址
`define MEM_RAM_ADDR        32'h80000000
// verilog_format: on


module peri_bridge (
    input clk_i,
    input rst_i,

    // ========== CPU Core接口 ==========    
    // 来自CPU的访存请求
    input        dram_rd_i,         // 读使能
    input        dram_wr_i,         // 写使能
    input [31:0] dram_addr_i,       // 访存地址
    input        dram_enable_i,     // 访存使能
    input [31:0] dram_data_wr_i,    // 写数据
    input [31:0] dram_mask_wr_i,    // 写掩码

    // 返回给CPU的响应
    output [31:0] dram_data_rd_o,   // 读数据
    output        dram_done_o,      // 完成标志

    // ========== UART接口 ==========    
    output       tx_enable_o,       // 发送使能
    output [7:0] tx_data_o,         // 发送数据
    input        rx_done_i,         // 接收完成
    input  [7:0] rx_data_i,         // 接收数据
    input        tx_done_i,         // 发送完成

    // ========== Timer接口 ==========    
    input  [31:0] timer_cycle_i,    // 读取周期计数
    input  [31:0] timer_cycleh_i,
    input  [31:0] timer_time_i,     // 读取时间计数
    input  [31:0] timer_timeh_i,
    input  [31:0] timer_timecmp_i,  // 读取比较值
    input  [31:0] timer_timecmph_i,
    output reg [31:0] timer_timecmp_o,  // 写入比较值
    output reg [31:0] timer_timecmph_o,

    // ========== VRAM接口 ==========    
    input  [31:0] vram_data_rd_i,   // 从VRAM读取的数据
    input         vram_done_i,      // VRAM操作完成
    output reg        vram_enable_o,    // VRAM使能
    output reg        vram_wr_o,        // VRAM写使能
    output reg        vram_rd_o,        // VRAM读使能
    output reg [31:0] vram_addr_o,      // VRAM地址
    output reg [31:0] vram_data_wr_o,   // VRAM写数据
    output reg [31:0] vram_mask_wr_o,   // VRAM写掩码

    // ========== LED接口 ==========    
    output reg [4:0] led_idx_o,         // LED索引
    output reg       led_wr_o,          // LED写使能
    output reg       led_status_wr_o,   // LED状态
    input            led_status_rd_i,   // LED读取状态

    // ========== Switch接口 ==========    
    output reg [4:0] switch_idx_o,      // Switch索引
    input            switch_status_i,   // Switch状态

    // ========== Keyboard接口 ==========    
    // 4x4矩阵键盘，只读接口
    input      [3:0] keyboard_val_i,    // 键盘当前按键值（0-F）

    // ========== Segment Display接口 ==========    
    // 七段数码管显示，只写接口
    output reg        seg_wr_o,          // 数码管写使能
    output reg [31:0] seg_data_o,        // 数码管显示数据（8个4位BCD码）

    // ========== RAM接口 ==========    
    input      [31:0] ram_data_rd_i,    // RAM读数据
    input             ram_done_i,       // RAM完成
    output reg        ram_enable_o,     // RAM使能
    output reg        ram_wr_o,         // RAM写使能
    output reg        ram_rd_o,         // RAM读使能
    output reg [31:0] ram_addr_o,       // RAM地址
    output reg [31:0] ram_data_wr_o,    // RAM写数据
    output reg [31:0] ram_mask_wr_o,    // RAM写掩码
    
    // ========== PWM接口 ==========    
    output            pwm_reg_wr_o,      // PWM寄存器写使能
    output            pwm_reg_rd_o,      // PWM寄存器读使能
    output [31:0]     pwm_reg_addr_o,    // PWM寄存器地址
    output [31:0]     pwm_reg_data_wr_o, // PWM寄存器写数据
    input  [31:0]     pwm_reg_data_rd_i, // PWM寄存器读数据
    
    // ========== 看门狗接口 ==========    
    output            wdt_reg_wr_o,      // 看门狗寄存器写使能
    output            wdt_reg_rd_o,      // 看门狗寄存器读使能
    output [31:0]     wdt_reg_addr_o,    // 看门狗寄存器地址
    output [31:0]     wdt_reg_data_wr_o, // 看门狗寄存器写数据
    input  [31:0]     wdt_reg_data_rd_i  // 看门狗寄存器读数据
);
// UART内部寄存器
reg [31:0] uart_tx_data_r;   // 发送数据缓冲
reg [31:0] uart_tx_flag_r;   // 0: idle, 1: busy
reg        uart_tx_enable_r; // 发送使能信号
reg [31:0] uart_rx_data_r;   // 接收数据缓冲
reg [31:0] uart_rx_flag_r;   // 0: receiving, 1: done

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
      // UART状态更新
      if (tx_done_i) uart_tx_flag_r <= 32'h0;// 发送完成，清除忙标志
      if (rx_done_i) begin
        uart_rx_data_r <= rx_data_i;// 保存接收数据
        uart_rx_flag_r <= 32'hffffffff;// 设置接收完成标志
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
          case (dram_addr_r & `MEM_RAM_MASK)// 根据高4位判断外设

          // ========== UART访问 ==========
            `MEM_UART_ADDR: begin
              dram_done_r <= 1'b1;// 寄存器访问，立即完成
              status_r <= STATUS_DONE;

              if (dram_addr_r == `MEM_UART_TX_DATA) begin
                if (dram_wr_r) begin
                  // 写发送数据
                  uart_tx_enable_r <= 1'b1;
                  uart_tx_flag_r   <= 32'hffffffff;// 设置忙标志
                  uart_tx_data_r   <= dram_data_wr_r;
                end else begin
                  // 读发送数据（通常无意义）
                  dram_data_rd_r <= uart_tx_data_r;
                end
              end else if (dram_addr_r == `MEM_UART_TX_FLAG) begin
                if (dram_wr_r) begin
                  uart_tx_flag_r <= dram_data_wr_r;
                end else begin
                  dram_data_rd_r <= uart_tx_flag_r;// 查询发送状态
                end
              end else if (dram_addr_r == `MEM_UART_RX_DATA) begin
                if (dram_wr_r) begin
                  uart_rx_data_r <= dram_data_wr_r;
                end else begin
                  dram_data_rd_r <= uart_rx_data_r;// 读接收数据
                end
              end else if (dram_addr_r == `MEM_UART_RX_FLAG) begin
                if (dram_wr_r) begin
                  uart_rx_flag_r <= dram_data_wr_r;// 清除接收标志
                end else begin
                  dram_data_rd_r <= uart_rx_flag_r;// 查询接收状态
                end
              end
            end

            // ========== Timer访问 ==========
            `MEM_TIMER_ADDR: begin
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
                  `MEM_TIMER_TIMECMP: timer_timecmp_o <= dram_data_wr_r;// 写比较值
                  `MEM_TIMER_TIMECMPH: timer_timecmph_o <= dram_data_wr_r;//读比较值
                  default: ;
                endcase
              end
            end

        // ========== VRAM访问 ==========
            `MEM_VRAM_ADDR: begin
              // VRAM需要多周期访问
              status_r       <= STATUS_WAIT;
              vram_enable_o  <= 1'b1;
              vram_wr_o      <= dram_wr_r;
              vram_rd_o      <= dram_rd_r;
              vram_addr_o    <= {4'h0, dram_addr_r[27:0]};
              vram_data_wr_o <= dram_data_wr_r;
              vram_mask_wr_o <= dram_mask_wr_r;
            end

            // ========== LED访问 ==========
            `MEM_LED_ADDR: begin
              status_r        <= STATUS_WAIT;
              led_idx_o       <= dram_addr_r[4:0];// LED索引
              led_wr_o        <= dram_wr_r;
              led_status_wr_o <= dram_data_wr_r[0];// 写LED状态
            end

            // ========== Switch访问 ==========
            `MEM_SWITCH_ADDR: begin 
              status_r     <= STATUS_WAIT;
              switch_idx_o <= dram_addr_r[4:0];
            end

            // ========== Keyboard访问 ==========
            // 键盘为只读外设，直接进入等待状态
            // 在STATUS_WAIT阶段读取keyboard_val_i并返回
            `MEM_KEYBOARD_ADDR: begin
              status_r <= STATUS_WAIT;
            end

            // ========== Segment Display访问 ==========
            // 数码管为只写外设，接收32位数据（8个4位BCD码）
            // seg_wr_o控制数码管模块的写使能
            `MEM_SEG_ADDR: begin
              status_r    <= STATUS_WAIT;
              seg_wr_o    <= dram_wr_r;        // 传递写使能信号
              seg_data_o  <= dram_data_wr_r;   // 传递32位数据（8个BCD码）
            end

            // ========== RAM访问 ==========
            `MEM_RAM_ADDR: begin  // ram
              status_r      <= STATUS_WAIT;
              ram_enable_o  <= 1'b1;
              ram_wr_o      <= dram_wr_r;
              ram_rd_o      <= dram_rd_r;
              ram_addr_o    <= {4'h0, dram_addr_r[27:0]};
              ram_data_wr_o <= dram_data_wr_r;
              ram_mask_wr_o <= dram_mask_wr_r;
            end
            
            // ========== PWM访问 ==========
            `MEM_PWM_ADDR: begin
              dram_done_r <= 1'b1;// 寄存器访问，立即完成
              status_r <= STATUS_DONE;
              
              // 直接将PWM寄存器的读写信号传递给PWM模块
              pwm_reg_wr_o <= dram_wr_r;
              pwm_reg_rd_o <= dram_rd_r;
              pwm_reg_addr_o <= dram_addr_r;
              pwm_reg_data_wr_o <= dram_data_wr_r;
              
              // 读取PWM模块的返回数据
              if (dram_rd_r) begin
                dram_data_rd_r <= pwm_reg_data_rd_i;
              end
            end
            
            // ========== 看门狗访问 ==========
            `MEM_WATCHDOG_ADDR: begin
              dram_done_r <= 1'b1;// 寄存器访问，立即完成
              status_r <= STATUS_DONE;
              
              // 直接将看门狗寄存器的读写信号传递给看门狗模块
              wdt_reg_wr_o <= dram_wr_r;
              wdt_reg_rd_o <= dram_rd_r;
              wdt_reg_addr_o <= dram_addr_r;
              wdt_reg_data_wr_o <= dram_data_wr_r;
              
              // 读取看门狗模块的返回数据
              if (dram_rd_r) begin
                dram_data_rd_r <= wdt_reg_data_rd_i;
              end
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

            // ========== Keyboard读取完成 ==========
            // 从keyboard_val_i读取4位按键值，扩展为32位返回
            `MEM_KEYBOARD_ADDR: begin  // keyboard
              status_r       <= STATUS_DONE;
              dram_data_rd_r <= {28'h0, keyboard_val_i};  // 高28位填0，低4位为键值
              dram_done_r    <= 1'b1;
            end

            // ========== Segment Display写入完成 ==========
            // 数码管写操作无需返回数据，直接完成
            `MEM_SEG_ADDR: begin  // segment display
              status_r    <= STATUS_DONE;
              dram_done_r <= 1'b1;  // 写操作完成标志
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
            
            // PWM和看门狗的访问在STATUS_INIT阶段已经完成，不需要在STATUS_WAIT处理
            
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

