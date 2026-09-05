module m_get_type (
    input wire [4:0] opcode5,
    output wire r,
    output wire i,
    output wire s,
    output wire b,
    output wire u,
    output wire j
);
    assign j = (opcode5==5'b11011);
    assign b = (opcode5==5'b11000);
    assign s = (opcode5==5'b01000);
    assign r = (opcode5==5'b01100);
    assign u = (opcode5==5'b00101 || opcode5==5'b01101);
    assign i = ~(j | b | s | r | u);
endmodule