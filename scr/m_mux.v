module m_mux (
    input wire [31:0] w_in1,
    input wire [31:0] w_in2,
    input wire w_s,
    output wire [31:0] w_out
);
    // 選択信号が1なら入力2、0なら入力1を出力する
    assign w_out = (w_s) ? w_in2 : w_in1;
endmodule
