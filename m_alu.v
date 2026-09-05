module m_alu (
    input wire [31:0] w_in1,
    input wire [31:0] w_in2,
    input wire [2:0] w_func,
    output wire [31:0] w_out,
    output wire w_tkn
);

    // w_funcに応じて加算・減算・XOR・OR・ANDを選ぶ
    assign w_out =  (w_func == 3'b000) ? w_in1 + w_in2 :
                    (w_func == 3'b001) ? w_in1 - w_in2 :
                    (w_func == 3'b100) ? w_in1 ^ w_in2 :
                    (w_func == 3'b110) ? w_in1 | w_in2 :
                    (w_func == 3'b111) ? w_in1 & w_in2 :
                                        32'd0;

    // 2つの値が異なる場合に分岐を成立させる
    assign w_tkn = w_in1 != w_in2;

endmodule
