module vga_640x480(
    input wire pix_clk,
    output wire hsync,
    output wire vsync,
    output wire visible,
    output wire [9:0] x,
    output wire [9:0] y
);
    localparam H_VISIBLE = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = 800;

    localparam V_VISIBLE = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = 525;

    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;

    always @(posedge pix_clk) begin
        if (h_count == H_TOTAL - 1) begin
            h_count <= 0;
            if (v_count == V_TOTAL - 1) begin
                v_count <= 0;
            end else begin
                v_count <= v_count + 1'b1;
            end
        end else begin
            h_count <= h_count + 1'b1;
        end
    end

    assign visible = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);
    assign x = h_count;
    assign y = v_count;

    assign hsync = ~((h_count >= H_VISIBLE + H_FRONT) && (h_count <  H_VISIBLE + H_FRONT + H_SYNC));
    assign vsync = ~((v_count >= V_VISIBLE + V_FRONT) && (v_count <  V_VISIBLE + V_FRONT + V_SYNC));
endmodule