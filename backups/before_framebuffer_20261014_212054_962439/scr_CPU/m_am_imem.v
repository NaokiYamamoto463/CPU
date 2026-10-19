module m_am_imem (
    input wire [31:0] w_pc,
    output wire [31:0] w_insn
);
    // PCから64ワード内の命令を選ぶ
    reg [31:0] mem [0:63];
    assign w_insn = mem[w_pc[7:2]];
    integer i; initial begin
        for (i=0; i<64; i=i+1) mem[i] = 32'd0;
    end
    // asm.vhの命令列を命令メモリに設定する
    initial begin
        `define MM mem
        `include "asm.vh"
    end
endmodule
