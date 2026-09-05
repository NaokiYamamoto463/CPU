module m_RF2 (
    input wire w_clk,
    input wire [4:0] w_ra1,
    input wire [4:0] w_ra2,
    output wire [31:0] w_rd1,
    output wire [31:0] w_rd2,
    input wire [4:0] w_wa,
    input wire w_we,
    input wire [31:0] w_wd 
);
    reg [31:0] mem [31:0];
    wire w_bp1 = (w_we & w_ra1 == w_wa);
    wire w_bp2 = (w_we & w_ra2 == w_wa);
    assign w_rd1 = (w_ra1==5'd0) ? 32'd0 : (w_bp1) ? w_wd : mem[w_ra1];
    assign w_rd2 = (w_ra2==5'd0) ? 32'd0 : (w_bp2) ? w_wd : mem[w_ra2];
    always @(posedge w_clk) begin
        if (w_we) mem[w_wa] <= w_wd;
    end
    // 合成時は終了処理を除外する。LED表示のシミュレーションでも
    // SYNTHESISを定義すると、結果を観測するまで実行を継続できる。
`ifndef SYNTHESIS
    always @(posedge w_clk) begin
        if (w_we & w_wa==5'd30) $finish;
    end
`endif
    integer i; initial for (i=0; i<32; i=i+1) mem[i] = 0;
endmodule
