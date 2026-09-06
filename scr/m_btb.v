module m_btb (
    input wire w_clk,
    input wire [31:0] w_pc,
    output wire w_hit,
    output wire [31:0] w_dout,
    input wire [4:0] w_wadr,
    input wire w_we,
    input wire [57:0] w_wd
);
    wire w_v;
    wire [24:0] w_tag;
    wire [31:0] w_data;
    reg [57:0] mem [0:31];
    always @(posedge w_clk) begin
        if (w_we) mem[w_wadr] <= w_wd;
    end
    assign {w_v, w_tag, w_data} = mem[w_pc[6:2]];
    assign w_hit = w_v & (w_tag == w_pc[31:7]);
    assign w_dout = w_data;
    integer i; initial for (i=0; i<32; i=i+1) mem[i] = 0;
endmodule