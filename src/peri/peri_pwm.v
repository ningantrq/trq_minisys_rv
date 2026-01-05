module peri_pwm #(
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

    // ========== PWM输出 ==========    
    output reg pwm0_o,   // PWM通道0输出
    output reg pwm1_o,   // PWM通道1输出
    output reg pwm2_o,   // PWM通道2输出
    output reg pwm3_o    // PWM通道3输出
);

    // ========== 寄存器定义 ==========    
    reg [31:0] period_reg;   // 周期寄存器（0x00）
    reg [31:0] duty0_reg;    // 通道0占空比寄存器（0x04）
    reg [31:0] duty1_reg;    // 通道1占空比寄存器（0x08）
    reg [31:0] duty2_reg;    // 通道2占空比寄存器（0x0C）
    reg [31:0] duty3_reg;    // 通道3占空比寄存器（0x10）
    reg [31:0] control_reg;  // 控制寄存器（0x14）
    reg [31:0] status_reg;   // 状态寄存器（0x18）

    // ========== 内部计数器 ==========    
    reg [31:0] count_reg;      // 计数寄存器

    // ========== 寄存器地址解码 ==========    
    localparam PERIOD_ADDR   = 5'd0;   // 0x00 (字节地址) -> 0x00 (字地址)
    localparam DUTY0_ADDR    = 5'd1;   // 0x04 (字节地址) -> 0x01 (字地址)
    localparam DUTY1_ADDR    = 5'd2;   // 0x08 (字节地址) -> 0x02 (字地址)
    localparam DUTY2_ADDR    = 5'd3;   // 0x0C (字节地址) -> 0x03 (字地址)
    localparam DUTY3_ADDR    = 5'd4;   // 0x10 (字节地址) -> 0x04 (字地址)
    localparam CONTROL_ADDR  = 5'd5;   // 0x14 (字节地址) -> 0x05 (字地址)
    localparam STATUS_ADDR   = 5'd6;   // 0x18 (字节地址) -> 0x06 (字地址)

    // ========== 控制寄存器位定义 ==========    
    localparam ENABLE_BIT    = 0;
    localparam CH0_ENABLE_BIT = 1;
    localparam CH1_ENABLE_BIT = 2;
    localparam CH2_ENABLE_BIT = 3;
    localparam CH3_ENABLE_BIT = 4;

    // ========== 状态寄存器位定义 ==========    
    localparam READY_BIT     = 0;
    localparam CH0_READY_BIT = 1;
    localparam CH1_READY_BIT = 2;
    localparam CH2_READY_BIT = 3;
    localparam CH3_READY_BIT = 4;

    // ========== 寄存器读写逻辑 ==========    
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            period_reg  <= 32'h000003E8;  // 默认周期1000（1ms）
            duty0_reg   <= 32'h000001F4;  // 默认占空比500（50%）
            duty1_reg   <= 32'h000001F4;  // 默认占空比500（50%）
            duty2_reg   <= 32'h000001F4;  // 默认占空比500（50%）
            duty3_reg   <= 32'h000001F4;  // 默认占空比500（50%）
            control_reg <= 32'h00000000;  // 默认禁用所有通道
            status_reg  <= 32'h00000001;  // 初始状态为就绪
            reg_data_rd_o <= 32'h0;
        end else begin
            // 读操作
            if (reg_rd_i) begin
                case (reg_addr_i[6:2]) // 4字节对齐，取地址偏移的高5位
                    PERIOD_ADDR:  reg_data_rd_o <= period_reg;
                    DUTY0_ADDR:   reg_data_rd_o <= duty0_reg;
                    DUTY1_ADDR:   reg_data_rd_o <= duty1_reg;
                    DUTY2_ADDR:   reg_data_rd_o <= duty2_reg;
                    DUTY3_ADDR:   reg_data_rd_o <= duty3_reg;
                    CONTROL_ADDR: reg_data_rd_o <= control_reg;
                    STATUS_ADDR:  reg_data_rd_o <= status_reg;
                    default:      reg_data_rd_o <= 32'h0;
                endcase
            end else begin
                reg_data_rd_o <= 32'h0;
            end

            // 写操作
            if (reg_wr_i) begin
                case (reg_addr_i[6:2]) // 4字节对齐，取地址偏移的高5位
                    PERIOD_ADDR: begin
                        period_reg <= reg_data_wr_i;
                        status_reg[READY_BIT] <= 1'b1;
                    end
                    DUTY0_ADDR: begin
                        duty0_reg <= reg_data_wr_i;
                        status_reg[CH0_READY_BIT] <= 1'b1;
                    end
                    DUTY1_ADDR: begin
                        duty1_reg <= reg_data_wr_i;
                        status_reg[CH1_READY_BIT] <= 1'b1;
                    end
                    DUTY2_ADDR: begin
                        duty2_reg <= reg_data_wr_i;
                        status_reg[CH2_READY_BIT] <= 1'b1;
                    end
                    DUTY3_ADDR: begin
                        duty3_reg <= reg_data_wr_i;
                        status_reg[CH3_READY_BIT] <= 1'b1;
                    end
                    CONTROL_ADDR: begin
                        control_reg <= reg_data_wr_i;
                        status_reg[READY_BIT] <= 1'b1;
                    end
                    default: ;
                endcase
            end
        end
    end

    // ========== PWM生成逻辑 ==========    
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            count_reg <= 32'h0;
            pwm0_o <= 1'b0;
            pwm1_o <= 1'b0;
            pwm2_o <= 1'b0;
            pwm3_o <= 1'b0;
        end else begin
            if (control_reg[ENABLE_BIT]) begin  // PWM使能
                // 计数逻辑
                if (count_reg >= period_reg) begin
                    count_reg <= 32'h0;
                end else begin
                    count_reg <= count_reg + 32'h1;
                end

                // 通道0 PWM输出
                if (control_reg[CH0_ENABLE_BIT]) begin
                    pwm0_o <= (count_reg < duty0_reg) ? 1'b1 : 1'b0;
                end else begin
                    pwm0_o <= 1'b0;
                end

                // 通道1 PWM输出
                if (control_reg[CH1_ENABLE_BIT]) begin
                    pwm1_o <= (count_reg < duty1_reg) ? 1'b1 : 1'b0;
                end else begin
                    pwm1_o <= 1'b0;
                end

                // 通道2 PWM输出
                if (control_reg[CH2_ENABLE_BIT]) begin
                    pwm2_o <= (count_reg < duty2_reg) ? 1'b1 : 1'b0;
                end else begin
                    pwm2_o <= 1'b0;
                end

                // 通道3 PWM输出
                if (control_reg[CH3_ENABLE_BIT]) begin
                    pwm3_o <= (count_reg < duty3_reg) ? 1'b1 : 1'b0;
                end else begin
                    pwm3_o <= 1'b0;
                end
            end else begin
                // PWM禁用时，所有输出为低电平
                count_reg <= 32'h0;
                pwm0_o <= 1'b0;
                pwm1_o <= 1'b0;
                pwm2_o <= 1'b0;
                pwm3_o <= 1'b0;
            end
        end
    end

endmodule
