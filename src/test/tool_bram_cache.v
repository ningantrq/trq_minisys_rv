`timescale 1ns / 1ps

module tool_bram_cache (
    input clk_i,
    input rst_i,

    output reg [31:0] icache_data_o,
    output reg        icache_done_o,
    input             icache_enable_i,
    input      [31:0] icache_addr_i,

    output reg [31:0] dcache_data_rd_o,
    output reg        dcache_done_o,
    input             dcache_enable_i,
    input             dcache_wr_i,
    input             dcache_rd_i,
    input      [31:0] dcache_addr_i,
    input      [31:0] dcache_data_wr_i,
    input      [31:0] dcache_mask_wr_i
);

  localparam integer IMEM_WORDS = 256;
  localparam integer DMEM_WORDS = 256;

  reg [31:0] imem[0:IMEM_WORDS - 1];
  reg [31:0] dmem[0:DMEM_WORDS - 1];

  integer i;

  initial begin
    for (i = 0; i < IMEM_WORDS; i = i + 1) begin
      imem[i] = 32'h00000013;
    end
    for (i = 0; i < DMEM_WORDS; i = i + 1) begin
      dmem[i] = 32'h00000000;
    end

  //R型算术逻辑指令（0-14）
  imem[0]  = 32'h00500093;  // ADDI x1, x0, 5       x1=5
  imem[1]  = 32'h00a00113;  // ADDI x2, x0, 10      x2=10
  imem[2]  = 32'h002081b3;  // ADD  x3, x1, x2      x3=15
  imem[3]  = 32'h40110233;  // SUB  x4, x2, x1      x4=5
  imem[4]  = 32'h002092b3;  // SLL  x5, x1, x2      x5=5<<10
  imem[5]  = 32'h40208333;  // SRA  x6, x1, x2      x6=5>>10(算术)
  imem[6]  = 32'h0020e3b3;  // OR   x7, x1, x2      x7=5|10=15
  imem[7]  = 32'h0020c433;  // XOR  x8, x1, x2      x8=5^10=15
  imem[8]  = 32'h0020f4b3;  // AND  x9, x1, x2      x9=5&10=0
  imem[9]  = 32'h00109533;  // SLL  x10,x1, x1      x10=5<<5=160
  imem[10] = 32'h0010d5b3;  // SRL  x11,x1, x1      x11=5>>5=0
  imem[11] = 32'h4010d633;  // SRA  x12,x1, x1      x12=5>>5=0
  imem[12] = 32'h0010a6b3;  // SLT  x13,x1, x1      x13=(5<5)?0
  imem[13] = 32'h0010b733;  // SLTU x14,x1, x1      x14=(5<5u)?0
  imem[14] = 32'h00c007b3;  // SLTU x15,x0, x12     x15=(0<0u)?0

  //I型立即数指令（15-23）
  imem[15] = 32'h01400813;  // ADDI  x16,x0, 20     x16=20
  imem[16] = 32'h00a12893;  // SLTI  x17,x2, 10     x17=(10<10)?0
  imem[17] = 32'h00a13913;  // SLTIU x18,x2, 10     x18=(10<10u)?0
  imem[18] = 32'h00a14993;  // XORI  x19,x2, 10     x19=10^10=0
  imem[19] = 32'h00a16a13;  // ORI   x20,x2, 10     x20=10|10=10
  imem[20] = 32'h00a17a93;  // ANDI  x21,x2, 10     x21=10&10=10
  imem[21] = 32'h00109b13;  // SLLI  x22,x1, 1      x22=5<<1=10
  imem[22] = 32'h0010db93;  // SRLI  x23,x1, 1      x23=5>>1=2
  imem[23] = 32'h4010dc13;  // SRAI  x24,x1, 1      x24=5>>1=2

  //U型和J型指令（24-27）
  imem[24] = 32'h00008cb7;  // LUI   x25,0x8        x25=0x8000
  imem[25] = 32'h00001d17;  // AUIPC x26,0x1        x26=PC+0x1000
  imem[26] = 32'h008000ef;  // JAL   x1, 8          x1=PC+4,跳到PC+8
  imem[27] = 32'h0080006f;  // JAL   x0, 8          跳到PC+8(28)

  //I型跳转和B型分支指令（28-57）
  imem[28] = 32'h00100d93;  // ADDI  x27,x0, 1      x27=1
  imem[29] = 32'h002d8e67;  // JALR  x28,x27, 2     x28=PC+4,跳到x27+2
  imem[30] = 32'h00200e13;  // ADDI  x28,x0, 2      x28=2
  imem[31] = 32'h01c00e93;  // ADDI  x29,x0, 28     x29=28

  // BEQ测试
  imem[32] = 32'h01ce0063;  // BEQ   x28,x29, 8     28==28?跳过NOP
  imem[33] = 32'h00000013;  // NOP                   (应被跳过)
  imem[34] = 32'h0080006f;  // JAL   x0, 8          跳到39

  // BNE测试
  imem[35] = 32'h00300e93;  // ADDI  x29,x0, 3      x29=3
  imem[36] = 32'h01ce1063;  // BNE   x28,x29, 8     2!=3?跳过NOP
  imem[37] = 32'h00000013;  // NOP                   (应被跳过)
  imem[38] = 32'h0080006f;  // JAL   x0, 8          跳到43

  // BLT测试
  imem[39] = 32'h00400e93;  // ADDI  x29,x0, 4      x29=4
  imem[40] = 32'hffff0f37;  // LUI   x30,0xffff0    x30=负数
  imem[41] = 32'hffff0fb7;  // LUI   x31,0xffff0    x31=负数
  imem[42] = 32'h01ef4063;  // BLT   x30,x29, 8     负<4?跳过NOP
  imem[43] = 32'h00000013;  // NOP                   (应被跳过)
  imem[44] = 32'h0080006f;  // JAL   x0, 8          跳到49

  // BGE测试
  imem[45] = 32'h00500e93;  // ADDI  x29,x0, 5      x29=5
  imem[46] = 32'h01ef5063;  // BGE   x30,x29, 8     负>=5?不跳
  imem[47] = 32'h00000013;  // NOP                   (会执行)
  imem[48] = 32'h0080006f;  // JAL   x0, 8          跳到53

  // BLTU测试
  imem[49] = 32'h00600e93;  // ADDI  x29,x0, 6      x29=6
  imem[50] = 32'h01ef6063;  // BLTU  x30,x29, 8     负<6u?不跳
  imem[51] = 32'h00000013;  // NOP                   (会执行)
  imem[52] = 32'h0080006f;  // JAL   x0, 8          跳到57

  // BGEU测试
  imem[53] = 32'h00700e93;  // ADDI  x29,x0, 7      x29=7
  imem[54] = 32'h01ef7063;  // BGEU  x30,x29, 8     负>=7u?跳过NOP
  imem[55] = 32'h00000013;  // NOP                   (应被跳过)
  imem[56] = 32'h0080006f;  // JAL   x0, 8          跳到61
  imem[57] = 32'h00800e93;  // ADDI  x29,x0, 8      x29=8

  //Load/Store指令（58-69）
  imem[58] = 32'h04200f13;  // ADDI  x30,x0, 66     x30=0x42
  // SW/LW测试
  imem[59] = 32'h09e02023;  // SW    x30,158(x0)    [158]=0x42
  imem[60] = 32'h09e00f83;  // LW    x31,158(x0)    x31=[158]=0x42
  // SH/LH测试
  imem[61] = 32'h0a002223;  // SH    x0, 160(x0)    [160]=0(半字)
  imem[62] = 32'h0a001003;  // LH    x0, 160(x0)    读半字
  // SH/LHU测试
  imem[63] = 32'h0a201423;  // SH    x2, 162(x0)    [162]=x2低16位
  imem[64] = 32'h0a202083;  // LH    x1, 162(x0)    x1=[162](符号扩展)
  // SW/LW测试
  imem[65] = 32'h0a401623;  // SW    x4, 164(x0)    [164]=x4
  imem[66] = 32'h0a404103;  // LW    x2, 164(x0)    x2=[164]
  // SB/LBU测试
  imem[67] = 32'h0a600823;  // SB    x6, 166(x0)    [166]=x6低8位
  imem[68] = 32'h0a605183;  // LBU   x3, 166(x0)    x3=[166](零扩展)
  imem[69] = 32'h00900e93;  // ADDI  x29,x0, 9      x29=9

  //M扩展乘除法指令（70-79）
  imem[70] = 32'h00700293;  // ADDI  x5, x0, 7      x5=7
  imem[71] = 32'h00600313;  // ADDI  x6, x0, 6      x6=6
  imem[72] = 32'h026303b3;  // MUL   x7, x6, x5     x7=6*7=42(低32位)
  imem[73] = 32'h02631433;  // MULH  x8, x6, x5     x8=6*7的高32位
  imem[74] = 32'h026324b3;  // MULHSU x9, x6, x5    x9=6*7(有符号×无符号)
  imem[75] = 32'h02633533;  // MULHU x10,x6, x5     x10=6*7(无符号高位)
  imem[76] = 32'h02634633;  // DIV   x12,x6, x5     x12=6/7=0
  imem[77] = 32'h026356b3;  // DIVU  x13,x6, x5     x13=6/7=0(无符号)
  imem[78] = 32'h02636733;  // REM   x14,x6, x5     x14=6%7=6
  imem[79] = 32'h026377b3;  // REMU  x15,x6, x5     x15=6%7=6(无符号)
  imem[80] = 32'h00a00e93;  // ADDI  x29,x0, 10     x29=10

  //Zicsr CSR指令（81-90）
  imem[81] = 32'h30029073;  // CSRRW x0, mstatus,x5  写mstatus=x5
  imem[82] = 32'h300022f3;  // CSRRS x5, mstatus,x0  读mstatus到x5
  imem[83] = 32'h30531073;  // CSRRW x0, mtvec, x6   写mtvec=x6
  imem[84] = 32'h30502373;  // CSRRS x6, mtvec, x0   读mtvec到x6
  imem[85] = 32'h305333f3;  // CSRRC x7, mtvec, x6   清除mtvec位
  imem[86] = 32'h30503473;  // CSRRC x8, mtvec, x0   读mtvec到x8
  imem[87] = 32'h305fd4f3;  // CSRRWI x9, mtvec,31   写mtvec=31
  imem[88] = 32'h305fe573;  // CSRRSI x10,mtvec,28   置位mtvec
  imem[89] = 32'h305ff5f3;  // CSRRCI x11,mtvec,30   清位mtvec
  imem[90] = 32'h00b00e93;  // ADDI  x29,x0, 11     x29=11(标记CSR完成)

  //结束循环（91）
  imem[91] = 32'h0ec0006f;  // JAL   x0, 236        跳转到结束(死循环)
  end

  reg        icache_pending_r;
  reg [31:0] icache_addr_r;

  reg        dcache_pending_r;
  reg        dcache_wr_r;
  reg        dcache_rd_r;
  reg [31:0] dcache_addr_r;
  reg [31:0] dcache_data_wr_r;
  reg [31:0] dcache_mask_wr_r;

  wire [31:0] icache_word_idx_w = icache_addr_r[31:2];
  wire [31:0] dcache_word_idx_w = dcache_addr_r[31:2];

  wire icache_in_range_w = (icache_word_idx_w < IMEM_WORDS);
  wire dcache_in_range_w = (dcache_word_idx_w < DMEM_WORDS);


  always @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
      icache_data_o    <= 32'h00000013;
      icache_done_o    <= 1'b0;
      icache_pending_r <= 1'b0;
      icache_addr_r    <= 32'b0;

      dcache_data_rd_o    <= 32'b0;
      dcache_done_o       <= 1'b0;
      dcache_pending_r    <= 1'b0;
      dcache_wr_r         <= 1'b0;
      dcache_rd_r         <= 1'b0;
      dcache_addr_r       <= 32'b0;
      dcache_data_wr_r    <= 32'b0;
      dcache_mask_wr_r    <= 32'b0;
    end else begin
      icache_done_o <= 1'b0;
      dcache_done_o <= 1'b0;

      if (icache_enable_i) begin
        icache_pending_r <= 1'b1;
        icache_addr_r    <= icache_addr_i;
      end
      if (icache_pending_r) begin
        icache_done_o    <= 1'b1;
        icache_pending_r <= 1'b0;
        icache_data_o    <= icache_in_range_w ? imem[icache_word_idx_w] : 32'h00000013;
      end

      if (dcache_enable_i) begin
        dcache_pending_r <= 1'b1;
        dcache_wr_r      <= dcache_wr_i;
        dcache_rd_r      <= dcache_rd_i;
        dcache_addr_r    <= dcache_addr_i;
        dcache_data_wr_r <= dcache_data_wr_i;
        dcache_mask_wr_r <= dcache_mask_wr_i;
      end

      if (dcache_pending_r) begin
        dcache_done_o    <= 1'b1;
        dcache_pending_r <= 1'b0;
        if (dcache_wr_r && dcache_in_range_w) begin
          dmem[dcache_word_idx_w] <= (dmem[dcache_word_idx_w] & ~dcache_mask_wr_r) |
                                    (dcache_data_wr_r & dcache_mask_wr_r);
          dcache_data_rd_o <= 32'b0;
        end else if (dcache_rd_r) begin
          dcache_data_rd_o <= dcache_in_range_w ? dmem[dcache_word_idx_w] : 32'b0;
        end else begin
          dcache_data_rd_o <= 32'b0;
        end
      end
    end
  end

endmodule
