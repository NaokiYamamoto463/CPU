module vga_mmio (
    input wire clk,
    input wire reset,

    input wire [31:0] addr,
    input wire [31:0] wdata,
    input wire we,
    input wire re,

    output reg [31:0] rdata,

    output reg [3:0] vga_r,
    output reg [3:0] vga_g,
    output reg [3:0] vga_b,
    output reg [9:0] vga_x,
    output reg [9:0] vga_y
);

    always @(posedge clk) begin
        if (reset) begin
            vga_r <= 0;
            vga_g <= 0;
            vga_b <= 0;
            vga_x <= 10'd216;
            vga_y <= 10'd208;
        end else if (we) begin
            case (addr)
                32'h8000_0000: vga_r <= wdata[3:0];
                32'h8000_0004: vga_g <= wdata[3:0];
                32'h8000_0008: vga_b <= wdata[3:0];
                32'h8000_000C: vga_x <= wdata[9:0];
                32'h8000_0010: vga_y <= wdata[9:0];
                default: ;
            endcase
            end
    end

    always @(*) begin
        rdata = 32'b0;
        if (re) begin
            case (addr)
                32'h8000_0000: rdata = {28'b0, vga_r};
                32'h8000_0004: rdata = {28'b0, vga_g};
                32'h8000_0008: rdata = {28'b0, vga_b};
                32'h8000_000C: rdata = {22'b0, vga_x};
                32'h8000_0010: rdata = {22'b0, vga_y};
                default: rdata = 32'b0;
            endcase
        end
    end

endmodule