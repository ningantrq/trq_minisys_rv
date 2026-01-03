全部使用Verilog自带运算符，包括<<, >>, >>>, $signed
可选实现：
移位使用桶形移位器
```
      `ALU_SHIFTL: begin
        shift_l_1_r = (alu_b_i[0]) ? {alu_a_i[30:0], 1'h0} : alu_a_i;
        shift_l_2_r = (alu_b_i[1]) ? {shift_l_1_r[29:0], 2'h0} : shift_l_1_r;
        shift_l_4_r = (alu_b_i[2]) ? {shift_l_2_r[27:0], 4'h0} : shift_l_2_r;
        shift_l_8_r = (alu_b_i[3]) ? {shift_l_4_r[23:0], 8'h0} : shift_l_4_r;
        result_r    = (alu_b_i[4]) ? {shift_l_8_r[15:0], 16'h0} : shift_l_8_r;
      end

      `ALU_SHIFTR, `ALU_SHIFTR_ARITH: begin
        if (alu_a_i[31] == 1'b1 && alu_op_i == `ALU_SHIFTR_ARITH) begin
          shift_r_fill = 32'hffffffff;
        end else begin
          shift_r_fill = 32'b0;
        end

        shift_r_1_r = (alu_b_i[0]) ? {shift_r_fill[31], alu_a_i[31:1]} : alu_a_i;
        shift_r_2_r = (alu_b_i[1]) ? {shift_r_fill[31:30], shift_r_1_r[31:2]} : shift_r_1_r;
        shift_r_4_r = (alu_b_i[2]) ? {shift_r_fill[31:28], shift_r_2_r[31:4]} : shift_r_2_r;
        shift_r_8_r = (alu_b_i[3]) ? {shift_r_fill[31:24], shift_r_4_r[31:8]} : shift_r_4_r;
        result_r    = (alu_b_i[4]) ? {shift_r_fill[31:16], shift_r_8_r[31:16]} : shift_r_8_r;
      end
```

有符号比较：
```
      `ALU_LESS_THAN_SIGNED: begin
        if (alu_a_i[31] != alu_b_i[31]) begin
          result_r = alu_a_i[31] ? 32'h1 : 32'h0;
        end else begin
          result_r = alu_sub_r[31] ? 32'h1 : 32'h0;
        end
      end
```
