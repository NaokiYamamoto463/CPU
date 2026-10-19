module m_am_dmem (
    input wire w_clk,
    input wire w_we,
    input wire [31:0] w_adr,
    input wire [31:0] w_wd,
    output wire [31:0] w_rd
);
    // 16,384 x 32-bit data RAM. 8500 words needed for baseball image.
    // 0x00000000..0x0000FFFF only; CPU must route 0x81000000 to MMIO.
    reg [31:0] mem [0:16383];
    wire in_range = (w_adr[31:16] == 16'b0);
    assign w_rd = in_range ? mem[w_adr[15:2]] : 32'b0;
    always @(posedge w_clk) begin
        if (w_we && in_range) mem[w_adr[15:2]] <= w_wd;
    end
    integer i;
    initial begin
        for (i=0; i<16384; i=i+1) mem[i] = 32'b0;
        `define DM mem
        `include "data.vh"
        `undef DM
    end
endmodule
