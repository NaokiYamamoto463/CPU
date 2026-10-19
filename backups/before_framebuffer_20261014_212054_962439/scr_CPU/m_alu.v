
module m_alu (
    input wire [31:0] w_in1,
    input wire [31:0] w_in2,
    input wire [3:0] w_func,
    output wire [31:0] w_out,
    output wire w_tkn
);

    wire signed [31:0] sra_result;

    // SRA / SRAI：符号付き右シフト
    assign sra_result = $signed(w_in1) >>> w_in2[4:0];

    // ========================================
    // ALU演算処理
    // ========================================
    assign w_out =　(w_func == 4'b0000) ? w_in1 + w_in2 :                               // ADD / ADDI：加算
                    (w_func == 4'b0001) ? w_in1 << w_in2[4:0] :                         // SLL / SLLI：論理左シフト
                    (w_func == 4'b0010) ? {31'b0, ($signed(w_in1) < $signed(w_in2))} :  // SLT / SLTI：符号付き比較
                    (w_func == 4'b0011) ? {31'b0, (w_in1 < w_in2)} :                    // SLTU / SLTIU：符号なし比較
                    (w_func == 4'b0100) ? w_in1 ^ w_in2 :                              // XOR / XORI：排他的論理和
                    (w_func == 4'b0101) ? w_in1 >> w_in2[4:0] :                        // SRL / SRLI：論理右シフト
                    (w_func == 4'b0110) ? w_in1 | w_in2 :                              // OR / ORI：論理和
                    (w_func == 4'b0111) ? w_in1 & w_in2 :                              // AND / ANDI：論理積
                    (w_func == 4'b1000) ? w_in1 - w_in2 :                              // SUB：減算
                    (w_func == 4'b1101) ? sra_result :                                 // SRA / SRAI：算術右シフト
                                        32'd0;

    // ========================================
    // B-Type 分岐判定
    // ========================================
    assign w_tkn =　(w_func == 4'b1001) ? (w_in1 == w_in2) :                  // BEQ：等しければ分岐
                    (w_func == 4'b1010) ? (w_in1 != w_in2) :                  // BNE：等しくなければ分岐
                    (w_func == 4'b1011) ? ($signed(w_in1) < $signed(w_in2)) : // BLT：符号付きで小さければ分岐
                    (w_func == 4'b1100) ? ($signed(w_in1) >= $signed(w_in2)): // BGE：符号付きで以上なら分岐
                    (w_func == 4'b1110) ? (w_in1 < w_in2) :                  // BLTU：符号なしで小さければ分岐
                    (w_func == 4'b1111) ? (w_in1 >= w_in2) :                 // BGEU：符号なしで以上なら分岐
                                        1'b0;

endmodule
