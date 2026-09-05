module m_am_dmem (
    input wire w_clk,
    input wire w_we,
    input wire [31:0] w_adr,
    input wire [31:0] w_wd,
    output wire [31:0] w_rd
);
    // 64ワードのデータメモリ。アドレスの下位2ビットは使わない
    reg [31:0] mem [0:63];
    assign w_rd = mem[w_adr[7:2]];
    // 読み出しは常時、書き込みはクロックの立ち上がりで行う
    always @(posedge w_clk) begin
        if (w_we) mem[w_adr[7:2]] <= w_wd;
    end
    integer i; initial begin
        for (i=0; i<64; i=i+1) mem[i] = 32'd0;
    end
endmodule
