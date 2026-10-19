module m_proc9_F (
    input wire w_clk,
    input wire reset,
    output reg [31:0] r_dout = 32'd0,
    // MMIOへの出力
    output wire [31:0] mmio_addr,
    output wire [31:0] mmio_wdata,
    output wire        mmio_we,
    output wire        mmio_re,
    // MMIOからの読み出し
    input wire [31:0] mmio_rdata
);
    // 各パイプライン段で命令・データ・制御信号を保持する
    reg [31:0] P1_ir=32'h13, P1_pc=0, P2_pc=0, P3_pc=0, P4_pc=0;
    reg [31:0] P2_r1=0, P2_s2=0, P2_r2=0, P2_tpc=0, P3_r2=0;
    reg [31:0] P3_alu, P3_in3, P4_alu=0, P4_ldd=0;
    reg P2_r=0, P2_s=0, P2_b=0, P2_ld=0, P2_u=0, P4_s=0, P4_b=0, P4_ld=0;
    reg P3_s=0, P3_b=0, P3_ld=0;
    reg [4:0] P2_rd=0, P2_rs1=0, P2_rs2=0, P3_rd=0, P4_rd=0;
    reg P1_v=0, P2_v=0, P3_v=0, P4_v=0;
    wire [31:0] w_npc, w_ir, w_imm, w_r1, w_r2, w_s2, w_rt;
    wire [31:0] w_alu, w_ldd, w_tpc, w_pcin, w_in1, w_in2, w_in3;
    wire w_r, w_i, w_s, w_b, w_u, w_j, w_ld, w_tkn;
    reg [31:0] r_pc = 0;
    wire [31:0] w_ppc;
    wire w_pred;
    m_gshare m15 (.w_clk (w_clk), .w_radr (r_pc[6:2]), .w_pred (w_pred), .w_wadr (P2_pc[6:2]), 
                .w_we (P2_v & P2_b & !reset), .w_tkn (w_tkn));
    wire [57:0] w_btb_wd = {1'b1, P2_pc[31:7], P2_tpc};
    wire w_hit;
    m_btb m14 (.w_clk (w_clk), .w_pc (r_pc), .w_hit (w_hit), .w_dout (w_ppc), .w_wadr (P2_pc[6:2]), 
            .w_we (P2_v & P2_b & !reset), .w_wd (w_btb_wd));
    wire w_bp_tkn = w_pred & w_hit;
    wire [31:0] w_truepc = (P2_v & P2_b & w_tkn) ? P2_tpc : P2_pc + 4;
    // 分岐成立時は後続命令を無効化し、ロード直後の依存時は停止する
    wire w_miss = P2_v & P2_b & P1_v & (P1_pc != w_truepc);
    wire w_lduse = P3_v & P3_ld & ((P3_rd==P2_rs1) | ((P3_rd==P2_rs2) & (P2_r | P2_b |P2_s)));
    reg [3:0] P2_func;
    wire [3:0] w_func;
    // 命令の各フィールドを抽出
    wire [6:0] w_opcode = P1_ir[6:0];
    wire [2:0] w_funct3 = P1_ir[14:12];
    wire [6:0] w_funct7 = P1_ir[31:25];
    // 命令形式の判定
    wire w_rtype = (w_opcode == 7'b0110011);
    wire w_itype = (w_opcode == 7'b0010011);
    // SUB
    wire w_sub = w_rtype && (w_funct3 == 3'b000) && (w_funct7 == 7'b0100000);
    // SRA 
    wire w_sra = w_rtype && (w_funct3 == 3'b101) && (w_funct7 == 7'b0100000);
    // SRAI 
    wire w_srai = w_itype && (w_funct3 == 3'b101) && (w_funct7 == 7'b0100000);
    // ALU制御信号生成
    assign w_func = (w_ld | w_s | w_u) ? 4'b0000 : // Load / Store はアドレス加算
                    w_b ?  ((w_funct3 == 3'b000) ? 4'b1001 : // BEQ
                            (w_funct3 == 3'b001) ? 4'b1010 : // BNE
                            (w_funct3 == 3'b100) ? 4'b1011 : // BLT
                            (w_funct3 == 3'b101) ? 4'b1100 : // BGE
                            (w_funct3 == 3'b110) ? 4'b1110 : // BLTU
                            (w_funct3 == 3'b111) ? 4'b1111 : // BGEU
                                                    4'b0000) :
                    w_sub ? 4'b1000 : //sub
                    (w_sra | w_srai) ? 4'b1101 : // SRA / SRAI
                    {1'b0, w_funct3}; //その他の演算
    // VGA MMIOのアドレス判定
    wire vga_reg_sel = (P3_alu == 32'h8000_0000) || // 赤
                    (P3_alu == 32'h8000_0004) || // 緑
                    (P3_alu == 32'h8000_0008) || // 青
                    (P3_alu == 32'h8000_000C) || // X座標
                    (P3_alu == 32'h8000_0010);   // Y座標
    // 画面用メモリ:1画素につき4バイトのアドレス
    wire fb_sel = (P3_alu >= 32'h8100_0000) && 
                    (P3_alu < 32'h8112_C000) &&
                    (P3_alu[1:0] == 2'b00);
    // どちらのデータも通称のRAMとは異なるアクセス先
    wire mmio_sel = vga_reg_sel || fb_sel;
    // MMIOへの信号
    assign mmio_addr = P3_alu;
    assign mmio_wdata = P3_in3;
    assign mmio_we = P3_s & P3_v & mmio_sel & !reset;
    assign mmio_re = P3_ld & P3_v & vga_reg_sel & !reset;
    // 通常RAMの書き込み許可
    wire ram_we = P3_s & P3_v & !mmio_sel & !reset;
    // 通常RAMの読み出しデータ
    wire [31:0] ram_rdata;

    always @(posedge w_clk) begin
        if (reset) begin
            r_dout <= 32'd0;
        // 書き戻しデータw_rtと同じP4段でx30への書き込みを判定する。
        end else if (!P4_s && !P4_b && P4_v && P4_rd == 5'd30) begin
            r_dout <= w_rt;
        end
    end
    // IF: 次のPCを選び、命令を読み出す
    assign w_pcin = (w_miss) ? w_truepc : (w_bp_tkn) ? w_ppc : w_npc;
    m_adder m2 (.w_in1 (32'h4), .w_in2 (r_pc), .w_out (w_npc));
    m_am_imem m3 (.w_pc (r_pc), .w_insn (w_ir));
    //----------------------------------------------------
    // ID: 命令を解読し、レジスタ値と即値を取り出す
    m_gen_imm m4 (.w_ir (P1_ir), .w_imm (w_imm), .w_r (w_r), .w_i (w_i), .w_s (w_s), .w_b (w_b), .w_u (w_u), 
                .w_j (w_j), .w_ld (w_ld));
    m_RF2 m5 (.w_clk (w_clk), .w_ra1 (P1_ir[19:15]), .w_ra2 (P1_ir[24:20]), .w_rd1 (w_r1), .w_rd2 (w_r2), 
            .w_wa (P4_rd), .w_we (!P4_s & !P4_b & P4_v & !reset), .w_wd (w_rt));
    m_adder m6 (.w_in1 (w_imm), .w_in2 (P1_pc), .w_out (w_tpc));
    m_mux m7 (.w_in1 (w_r2), .w_in2 (w_imm), .w_s (!w_r & !w_b), .w_out (w_s2));
    always @(posedge w_clk) begin
        if (reset) begin
            r_pc <= 0;
            P1_ir <= 32'h00000013;
            P1_pc <= 0;
            P2_pc <= 0;

            P1_v <= 0;
            P2_v <= 0;

            P2_r1 <= 0;
            P2_r2 <= 0;
            P2_s2 <= 0;
            P2_tpc <= 0;

            P2_r <= 0;
            P2_s <= 0;
            P2_b <= 0;
            P2_ld <= 0;
            P2_u <= 0;

            P2_rs1 <= 0;
            P2_rs2 <= 0;
            P2_rd <= 0;
            P2_func <= 0;
        end else if (!w_lduse) begin
            {P1_v, P2_v} <= {!w_miss, !w_miss & P1_v};
            {r_pc, P1_ir, P1_pc, P2_pc} <= {w_pcin, w_ir, r_pc, P1_pc};
            {P2_r1, P2_r2, P2_s2, P2_tpc} <= {w_r1, w_r2, w_s2, w_tpc};
            {P2_r, P2_s, P2_b, P2_ld} <= {w_r, w_s, w_b, w_ld};
            {P2_rs2, P2_rs1, P2_rd} <= {P1_ir[24:20], P1_ir[19:15], P1_ir[11:7]};
            P2_func <= w_func; 
            P2_u <= w_u;
        end else begin
            {P2_r1, P2_r2, P2_s2} <= {w_in1, w_in3, w_in2};
        end
    end
    always @(posedge w_clk) begin
        if (reset) begin
            P3_v <= 0;
            P4_v <= 0;

            P3_pc <= 0;
            P3_ld <= 0;
            P3_r2 <= 0;
            P3_in3 <= 0;
            P3_alu <= 0;
            P3_rd <= 0;
            P3_s <= 0;
            P3_b <= 0;

            P4_pc <= 0;
            P4_s <= 0;
            P4_b <= 0;
            P4_ld <= 0;
            P4_alu <= 0;
            P4_ldd <= 0;
            P4_rd <= 0;
        end else begin
            {P3_v, P4_v} <= {P2_v & !w_lduse, P3_v};
            {P3_pc, P3_ld, P3_r2, P3_in3} <= {P2_pc, P2_ld, P2_r2, w_in3};
            {P3_alu, P3_rd} <= {w_alu, P2_rd};
            {P3_s, P3_b, P3_ld} <= {P2_s, P2_b, P2_ld};
            {P4_pc, P4_s, P4_b, P4_ld} <= {P3_pc, P3_s, P3_b, P3_ld};
            {P4_alu, P4_ldd, P4_rd} <= {P3_alu, w_ldd, P3_rd};
        end
    end
    //----------------------------------------------------
    // EX: 演算と分岐条件の判定を行う
    m_alu m8 (.w_in1 (w_in1), .w_in2 (w_in2), .w_func (P2_func), .w_out (w_alu), .w_tkn (w_tkn));
    // MA: データメモリを読み書きする
    m_am_dmem m9 (.w_clk (w_clk), .w_we (ram_we), .w_adr (P3_alu), .w_wd (P3_in3), .w_rd (ram_rdata));
    // RAMまたはMMIOからの読み出しデータを選択
    assign w_ldd = mmio_sel ? mmio_rdata : ram_rdata;
    //-----------------------------------------------------
    // WB: レジスタへ書き戻す演算結果またはロード値を選ぶ
    m_mux m10 (.w_in1 (P4_alu), .w_in2 (P4_ldd), .w_s (P4_ld), .w_out (w_rt));
    //-----------------------------------------------------
    // フォワーディング: 書き戻しを待たずに後続命令へ結果を渡す
    wire w_f3 = !P3_s & !P3_b & |P3_rd & P3_v;
    wire w_f4 = !P4_s & !P4_b & |P4_rd & P4_v;
    wire w_fwd1_P3 = (w_f3 & P3_rd==P2_rs1);
    wire w_fwd1_P4 = (w_f4 & P4_rd==P2_rs1);
    wire w_fwd2_P3 = (w_f3 & P3_rd==P2_rs2 & (P2_r | P2_b));
    wire w_fwd2_P4 = (w_f4 & P4_rd==P2_rs2 & (P2_r | P2_b));
    wire w_fwd3_P3 = {w_f3 & P3_rd==P2_rs2};
    wire w_fwd3_P4 = {w_f4 & P4_rd==P2_rs2};
    assign w_in1 = P2_u ? 32'd0 : (w_fwd1_P3) ? P3_alu : (w_fwd1_P4) ? w_rt : P2_r1;
    assign w_in2 = (w_fwd2_P3) ? P3_alu : (w_fwd2_P4) ? w_rt : P2_s2;
    assign w_in3 = (w_fwd3_P3) ? P3_alu : (w_fwd3_P4) ? w_rt : P2_r2;
endmodule
