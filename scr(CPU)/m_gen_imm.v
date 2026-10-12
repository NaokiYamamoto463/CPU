// 命令形式の判定と即値生成をまとめる
module m_gen_imm (
    input wire [31:0] w_ir,
    output wire [31:0] w_imm,
    output wire w_r,
    output wire w_i,
    output wire w_s,
    output wire w_b,
    output wire w_u,
    output wire w_j,
    output wire w_ld
);
    m_get_type m1 (.opcode5 (w_ir[6:2]), .r (w_r), .i (w_i), .s (w_s), .b (w_b), .u (w_u), .j (w_j)); //オペコードのフィールド判定
    m_get_imm m2 (.ir (w_ir), .i (w_i), .s (w_s), .b (w_b), .u (w_u), .j (w_j), .imm (w_imm)); //即値の算出

    // ロード命令ならw_ldを1にする
    assign w_ld = (w_ir[6:2] == 0);
endmodule
