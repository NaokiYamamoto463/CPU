module m_adder (
    input wire [31:0] w_in1,
    input wire [31:0] w_in2,
    output wire [31:0] w_out
);
    // 2つの32ビット入力を加算する
    assign w_out = w_in1 + w_in2;
endmodule
