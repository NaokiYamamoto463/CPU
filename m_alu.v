module m_alu (
    input wire [31:0] w_in1,
    input wire [31:0] w_in2,
    input wire [2:0] w_func,
    output wire [31:0] w_out,
    output wire w_tkn
);
    assign w_out = (w_func == 3'b000) ? w_in1 + w_in2 :
                   (w_func == 3'b001) ? w_in1 - w_in2 :
                                        w_in1 & w_in2;
    // assign w_out = w_in1 + w_in2;
    assign w_tkn = w_in1 != w_in2;
endmodule