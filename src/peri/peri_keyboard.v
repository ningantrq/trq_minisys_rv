// ========================================================================
// 4x4矩阵键盘外设模块
// ========================================================================
// 功能说明：
//   - 通过扫描方式检测4x4矩阵键盘的按键
//   - 使用状态机逐列扫描，检测按键按下
//   - 将按键位置转换为对应的键值（0-F）
// 
// 接口说明：
//   - clk_i: 系统时钟输入
//   - rst_i: 复位信号（高电平有效）
//   - row_i[3:0]: 键盘行输入信号（高电平表示未按下）
//   - col_o[3:0]: 键盘列输出信号（低电平表示扫描该列）
//   - rd_i: 读使能信号（保留接口）
//   - key_val_o[3:0]: 当前按键值输出（0-F）
// ========================================================================
module peri_keyboard (
    input clk_i,
    input rst_i,
    
    input [3:0] row_i,
    output reg [3:0] col_o,
    
    input rd_i,
    output [3:0] key_val_o,
    output reg data_ready_o
);

// ========================================================================
// 时钟分频 - 生成键盘扫描时钟
// ========================================================================
// 20位计数器，取最高位作为扫描时钟
// 分频比 = 2^20 / 系统时钟频率，约为21ms的扫描周期
reg [19:0] cnt;
wire key_clk;

always @(posedge clk_i or posedge rst_i) begin
    if (rst_i)
        cnt <= 0;
    else
        cnt <= cnt + 1'b1;
end

assign key_clk = cnt[19];  // 扫描时钟，约21ms周期

// ========================================================================
// 状态机定义 - 使用独热码编码
// ========================================================================
parameter NO_KEY_PRESSED = 6'b000_001;  // 无按键按下状态
parameter SCAN_COL0      = 6'b000_010;  // 扫描第0列
parameter SCAN_COL1      = 6'b000_100;  // 扫描第1列
parameter SCAN_COL2      = 6'b001_000;  // 扫描第2列
parameter SCAN_COL3      = 6'b010_000;  // 扫描第3列
parameter KEY_PRESSED    = 6'b100_000;  // 按键按下状态

reg [5:0] current_state, next_state;

always @(posedge key_clk or posedge rst_i) begin
    if (rst_i)
        current_state <= NO_KEY_PRESSED;
    else
        current_state <= next_state;
end

// ========================================================================
// 状态机组合逻辑 - 次态转移
// ========================================================================
// 状态转移规则：
//   1. NO_KEY_PRESSED: 如果检测到按键（row_i != 4'hF），开始扫描第0列
//   2. SCAN_COLx: 如果检测到按键，进入按键按下状态；否则扫描下一列
//   3. KEY_PRESSED: 按键保持按下则维持状态，释放后返回空闲状态
always @(*) begin
    case (current_state)
        NO_KEY_PRESSED:  // 空闲状态，检测是否有按键按下
            if (row_i != 4'hF)  // 有按键按下（至少一个行信号为低）
                next_state = SCAN_COL0;
            else
                next_state = NO_KEY_PRESSED;
        SCAN_COL0:  // 扫描第0列
            if (row_i != 4'hF)  // 该列有按键按下
                next_state = KEY_PRESSED;
            else
                next_state = SCAN_COL1;  // 扫描下一列
        SCAN_COL1:  // 扫描第1列
            if (row_i != 4'hF)
                next_state = KEY_PRESSED;
            else
                next_state = SCAN_COL2;
        SCAN_COL2:  // 扫描第2列
            if (row_i != 4'hF)
                next_state = KEY_PRESSED;
            else
                next_state = SCAN_COL3;
        SCAN_COL3:  // 扫描第3列
            if (row_i != 4'hF)
                next_state = KEY_PRESSED;
            else
                next_state = NO_KEY_PRESSED;  // 所有列扫描完毕
        KEY_PRESSED:  // 按键按下状态
            if (row_i != 4'hF)  // 按键仍然按下
                next_state = KEY_PRESSED;
            else  // 按键释放
                next_state = NO_KEY_PRESSED;
        default: next_state = NO_KEY_PRESSED;
    endcase
end

// ========================================================================
// 状态机时序逻辑 - 输出控制
// ========================================================================
// 根据次态生成列扫描信号和锁存按键位置
reg key_pressed_flag;  // 按键按下标志
reg [3:0] col_val, row_val;  // 锁存的列值和行值

always @(posedge key_clk or posedge rst_i) begin
    if (rst_i) begin
        col_o <= 4'h0;
        key_pressed_flag <= 0;
    end else begin
        case (next_state)
            NO_KEY_PRESSED: begin
                col_o <= 4'h0;  // 所有列为高电平（不扫描）
                key_pressed_flag <= 0;  // 清除按键标志
            end
            SCAN_COL0:  // 扫描第0列，将col[0]拉低
                col_o <= 4'b1110;
            SCAN_COL1:  // 扫描第1列，将col[1]拉低
                col_o <= 4'b1101;
            SCAN_COL2:  // 扫描第2列，将col[2]拉低
                col_o <= 4'b1011;
            SCAN_COL3:  // 扫描第3列，将col[3]拉低
                col_o <= 4'b0111;
            KEY_PRESSED: begin  // 检测到按键，锁存当前行列值
                col_val <= col_o;  // 锁存列值
                row_val <= row_i;  // 锁存行值
                key_pressed_flag <= 1;  // 设置按键标志
            end
            default: begin
                col_o <= 4'h0;
                key_pressed_flag <= 0;
            end
        endcase
    end
end

// ========================================================================
// 按键译码 - 将行列位置转换为键值
// ========================================================================
// 键盘布局（标准4x4矩阵键盘）：
//        COL0   COL1   COL2   COL3
// ROW0:   1      2      3      A
// ROW1:   4      5      6      B
// ROW2:   7      8      9      C
// ROW3:   E      0      F      D
reg [3:0] keyboard_val;  // 当前按键值
reg       key_valid;     // 按键有效标志（内部使用）

always @(posedge key_clk or posedge rst_i) begin
    if (rst_i) begin
        keyboard_val <= 4'h0;
        key_valid <= 1'b0;
    end else if (key_pressed_flag) begin  // 有按键按下时进行译码
        key_valid <= 1'b1;  // 设置按键有效标志
        case ({col_val, row_val})  // 根据列值和行值的组合译码
            // 第0列 (col=1110)
            8'b1110_1110: keyboard_val <= 4'h1;  // ROW0,COL0 -> 1
            8'b1110_1101: keyboard_val <= 4'h4;  // ROW1,COL0 -> 4
            8'b1110_1011: keyboard_val <= 4'h7;  // ROW2,COL0 -> 7
            8'b1110_0111: keyboard_val <= 4'hE;  // ROW3,COL0 -> E
            
            // 第1列 (col=1101)
            8'b1101_1110: keyboard_val <= 4'h2;  // ROW0,COL1 -> 2
            8'b1101_1101: keyboard_val <= 4'h5;  // ROW1,COL1 -> 5
            8'b1101_1011: keyboard_val <= 4'h8;  // ROW2,COL1 -> 8
            8'b1101_0111: keyboard_val <= 4'h0;  // ROW3,COL1 -> 0
            
            // 第2列 (col=1011)
            8'b1011_1110: keyboard_val <= 4'h3;  // ROW0,COL2 -> 3
            8'b1011_1101: keyboard_val <= 4'h6;  // ROW1,COL2 -> 6
            8'b1011_1011: keyboard_val <= 4'h9;  // ROW2,COL2 -> 9
            8'b1011_0111: keyboard_val <= 4'hF;  // ROW3,COL2 -> F
            
            // 第3列 (col=0111)
            8'b0111_1110: keyboard_val <= 4'hA;  // ROW0,COL3 -> A
            8'b0111_1101: keyboard_val <= 4'hB;  // ROW1,COL3 -> B
            8'b0111_1011: keyboard_val <= 4'hC;  // ROW2,COL3 -> C
            8'b0111_0111: keyboard_val <= 4'hD;  // ROW3,COL3 -> D
            default: keyboard_val <= keyboard_val;  // 保持原值
        endcase
    end else if (!key_pressed_flag && key_valid) begin
        // 按键释放后清除有效标志
        key_valid <= 1'b0;
    end
end

// ========================================================================
// 数据就绪标志管理 - 实现程序查询方式
// ========================================================================
// data_ready_o: 数据就绪标志，CPU通过检查此位判断是否可以读取
//   1: 有新按键按下，数据就绪，CPU可以读取
//   0: 无新数据，CPU需要等待
// 当CPU读取（rd_i=1）时，自动清除就绪标志，等待下一次按键
always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        data_ready_o <= 1'b0;
    end else begin
        if (key_valid && !data_ready_o) begin
            // 检测到新按键，设置就绪标志
            data_ready_o <= 1'b1;
        end else if (rd_i && data_ready_o) begin
            // CPU读取后，清除就绪标志
            data_ready_o <= 1'b0;
        end
    end
end

assign key_val_o = keyboard_val;  // 输出当前按键值

endmodule
