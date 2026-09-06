module m_gshare (
    input wire w_clk,
    input wire [4:0] w_radr,
    output wire w_pred,
    input wire [4:0] w_wadr,
    input wire w_we,
    input wire w_tkn
);
    reg [1:0] mem [0:31];
    reg [4:0] r_bhr = 0;
    always @(posedge w_clk) begin
        if (w_we) r_bhr <= {w_tkn, r_bhr[4:1]};
    end
    assign w_pred = w_data[1];
    wire [1:0] w_data = mem[w_radr ^ r_bhr];
    wire [1:0] w_cnt = mem[w_wadr ^ r_bhr];
    always @(posedge w_clk) begin
        mem[w_wadr ^ r_bhr] <= (w_cnt < 3 & w_tkn) ? w_cnt + 1 :
                                (w_cnt > 0 & !w_tkn) ? w_cnt - 1 : w_cnt;
    end
    integer i; initial for (i=0; i<32: i=i+1) mem[i] = 1;
endmodule