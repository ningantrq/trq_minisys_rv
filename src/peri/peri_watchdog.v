module peri_watchdog #(
    parameter CLK_FREQ = 25000000
) (
    input clk_i,
    input rst_i,

    // ========== Bridge接口 ==========    
    input  [31:0] reg_addr_i,  // 寄存器地址偏移（0-15）
    input         reg_wr_i,     // 写使能
    input         reg_rd_i,     // 读使能
    input  [31:0] reg_data_wr_i,// 写数据
    output reg [31:0] reg_data_rd_o,// 读数据

    // ========== 外部接口 ==========    
    output reg wdt_interrupt_o,// 看门狗中断输出
    output reg wdt_reset_o      // 看门狗复位输出（可选）
);

    // ========== 寄存器定义 ==========    
    reg [31:0] timeout_reg;    // 超时时间寄存器（0x00）
    reg [31:0] control_reg;    // 控制寄存器（0x04）
    reg [31:0] status_reg;     // 状态寄存器（0x08）
    reg [31:0] reset_reg;      // 复位寄存器（0x0C）

    // ========== 内部计数器 ==========    
    reg [31:0] count_reg;      // 计数寄存器
    reg [31:0] timeout_count_reg; // 超时计数寄存器

    // ========== 寄存器地址解码 ==========    
    localparam TIMEOUT_ADDR   = 5'd0;  // 0x00
    localparam CONTROL_ADDR   = 5'd1;  // 0x04
    localparam STATUS_ADDR    = 5'd2;  // 0x08
    localparam RESET_ADDR     = 5'd3;  // 0x0C

    // ========== 控制寄存器位定义 ==========    
    localparam ENABLE_BIT     = 0;
    localparam INTERRUPT_EN_BIT = 1;
    localparam RESET_EN_BIT   = 2;
    localparam AUTO_RELOAD_BIT = 3;

    // ========== 状态寄存器位定义 ==========    
    localparam TIMEOUT_BIT    = 0;
    localparam ACTIVE_BIT     = 1;

    // ========== 寄存器读写逻辑 ==========    
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            timeout_reg    <= 32'h0000C350;  // 默认超时时间50000（2ms）
            control_reg    <= 32'h00000000;  // 默认禁用
            status_reg     <= 32'h00000000;  // 初始状态
            reset_reg      <= 32'h00000000;
            reg_data_rd_o  <= 32'h0;
        end else begin
            // 读操作
            if (reg_rd_i) begin
                case (reg_addr_i[6:2]) // 4字节对齐，取地址偏移的高5位
                    TIMEOUT_ADDR:  reg_data_rd_o <= timeout_reg;
                    CONTROL_ADDR:  reg_data_rd_o <= control_reg;
                    STATUS_ADDR:   reg_data_rd_o <= status_reg;
                    RESET_ADDR:    reg_data_rd_o <= reset_reg;
                    default:       reg_data_rd_o <= 32'h0;
                endcase
            end else begin
                reg_data_rd_o <= 32'h0;
            end

            // 写操作
            if (reg_wr_i) begin
                case (reg_addr_i[6:2]) // 4字节对齐，取地址偏移的高5位
                    TIMEOUT_ADDR: begin
                        timeout_reg <= reg_data_wr_i;
                        status_reg[TIMEOUT_BIT] <= 1'b0;
                    end
                    CONTROL_ADDR: begin
                        control_reg <= reg_data_wr_i;
                        status_reg[TIMEOUT_BIT] <= 1'b0;
                    end
                    RESET_ADDR: begin
                        // 写入任意值都会重置计数器
                        reset_reg <= reg_data_wr_i;
                        count_reg <= 32'h0;
                        timeout_count_reg <= 32'h0;
                        status_reg[TIMEOUT_BIT] <= 1'b0;
                        wdt_interrupt_o <= 1'b0;
                        wdt_reset_o <= 1'b0;
                    end
                    default: ;
                endcase
            end
        end
    end

    // ========== 看门狗计数逻辑 ==========    
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            count_reg <= 32'h0;
            timeout_count_reg <= 32'h0;
            status_reg <= 32'h0;
            wdt_interrupt_o <= 1'b0;
            wdt_reset_o <= 1'b0;
        end else begin
            wdt_interrupt_o <= 1'b0;
            wdt_reset_o <= 1'b0;

            if (control_reg[ENABLE_BIT]) begin  // 看门狗使能
                status_reg[ACTIVE_BIT] <= 1'b1;

                // 计数逻辑
                if (count_reg >= CLK_FREQ / 1000) begin  // 1ms计数
                    count_reg <= 32'h0;
                    timeout_count_reg <= timeout_count_reg + 32'h1;
                end else begin
                    count_reg <= count_reg + 32'h1;
                end

                // 超时检查
                if (timeout_count_reg >= timeout_reg) begin
                    status_reg[TIMEOUT_BIT] <= 1'b1;

                    // 中断生成
                    if (control_reg[INTERRUPT_EN_BIT]) begin
                        wdt_interrupt_o <= 1'b1;
                    end

                    // 复位生成
                    if (control_reg[RESET_EN_BIT]) begin
                        wdt_reset_o <= 1'b1;
                    end

                    // 自动重载
                    if (control_reg[AUTO_RELOAD_BIT]) begin
                        timeout_count_reg <= 32'h0;
                    end else begin
                        control_reg[ENABLE_BIT] <= 1'b0;  // 禁用看门狗
                        status_reg[ACTIVE_BIT] <= 1'b0;
                    end
                end
            end else begin
                status_reg[ACTIVE_BIT] <= 1'b0;
                count_reg <= 32'h0;
                timeout_count_reg <= 32'h0;
            end
        end
    end

endmodule



