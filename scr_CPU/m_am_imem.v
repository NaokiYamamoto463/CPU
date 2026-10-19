module m_am_imem (
    input wire [31:0] w_pc,
    output wire [31:0] w_insn
);
    // PCから64ワード内の命令を選ぶ
    reg [31:0] mem [0:1023];
    assign w_insn = mem[w_pc[11:2]];
    integer i; initial begin
        for (i=0; i<1024; i=i+1) begin
            mem[i] = 32'h00000013;
        end
        `define MM mem
        `include "asm.vh"
        `undef MM
    end
endmodule
