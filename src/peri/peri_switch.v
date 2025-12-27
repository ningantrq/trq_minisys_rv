module peri_switch (

      // ========== Bridge接口 ==========
    input [4:0] idx_i,// Switch索引（0-23）
    output reg status_o,// Switch状态（0=OFF, 1=ON）

   // ========== 物理Switch输入 ==========
    input sw0_i,
    input sw1_i,
    input sw2_i,
    input sw3_i,
    input sw4_i,
    input sw5_i,
    input sw6_i,
    input sw7_i,
    input sw8_i,
    input sw9_i,
    input sw10_i,
    input sw11_i,
    input sw12_i,
    input sw13_i,
    input sw14_i,
    input sw15_i,
    input sw16_i,
    input sw17_i,
    input sw18_i,
    input sw19_i,
    input sw20_i,
    input sw21_i,
    input sw22_i,
    input sw23_i
);
  always @(*) begin
    case (idx_i)
      5'd0: status_o <= sw0_i;
      5'd1: status_o <= sw1_i;
      5'd2: status_o <= sw2_i;
      5'd3: status_o <= sw3_i;
      5'd4: status_o <= sw4_i;
      5'd5: status_o <= sw5_i;
      5'd6: status_o <= sw6_i;
      5'd7: status_o <= sw7_i;
      5'd8: status_o <= sw8_i;
      5'd9: status_o <= sw9_i;
      5'd10: status_o <= sw10_i;
      5'd11: status_o <= sw11_i;
      5'd12: status_o <= sw12_i;
      5'd13: status_o <= sw13_i;
      5'd14: status_o <= sw14_i;
      5'd15: status_o <= sw15_i;
      5'd16: status_o <= sw16_i;
      5'd17: status_o <= sw17_i;
      5'd18: status_o <= sw18_i;
      5'd19: status_o <= sw19_i;
      5'd20: status_o <= sw20_i;
      5'd21: status_o <= sw21_i;
      5'd22: status_o <= sw22_i;
      5'd23: status_o <= sw23_i;
      default: status_o <= 1'b0;
    endcase
  end
endmodule
