
module vga_top (
    input wire CLK100MHZ,
    input wire CPU_RESETN,

    output reg VGA_HS,
    output reg VGA_VS,
    output reg [3:0] VGA_R,
    output reg [3:0] VGA_G,
    output reg [3:0] VGA_B
);

    // =====================================
    // Clocking Wizard
    // 100MHz -> VGA 25MHz / CPU 60MHz
    // =====================================
    wire pix_clk25;
    wire cpu_clk60;
    wire locked;

    clk_wiz_0 u_clk (
        .clk_in1(CLK100MHZ),
        .clk_out1(pix_clk25),
        .clk_out2(cpu_clk60),
        .reset(~CPU_RESETN),
        .locked(locked)
    );

    // =====================================
    // CPUリセット（60MHzドメイン）
    // =====================================
    wire reset_req = ~CPU_RESETN | ~locked;

    (* ASYNC_REG = "TRUE" *)
    reg [1:0] cpu_reset_sync = 2'b11;

    always @(posedge cpu_clk60 or posedge reset_req) begin
        if (reset_req)
            cpu_reset_sync <= 2'b11;
        else
            cpu_reset_sync <= {cpu_reset_sync[0], 1'b0};
    end

    wire reset = cpu_reset_sync[1];

    // =====================================
    // CPUとMMIO間の信号
    // =====================================
    wire [31:0] mmio_addr;
    wire [31:0] mmio_wdata;
    wire [31:0] mmio_rdata;

    wire mmio_we;
    wire mmio_re;

    wire [31:0] cpu_result;

    // =====================================
    // MMIOのRGB出力
    // =====================================
    wire [3:0] mmio_r;
    wire [3:0] mmio_g;
    wire [3:0] mmio_b;
    wire [9:0] mmio_x;
    wire [9:0] mmio_y;

    // =====================================
    // RISC-V CPU（60MHz）
    // =====================================
    m_proc9_F u_cpu (
        .w_clk(cpu_clk60),
        .reset(reset),
        .r_dout(cpu_result),

        .mmio_addr(mmio_addr),
        .mmio_wdata(mmio_wdata),
        .mmio_we(mmio_we),
        .mmio_re(mmio_re),
        .mmio_rdata(mmio_rdata)
    );

    // =====================================
    // VGA MMIO（60MHz）
    // =====================================
    vga_mmio u_mmio (
        .clk(cpu_clk60),
        .reset(reset),

        .addr(mmio_addr),
        .wdata(mmio_wdata),
        .we(mmio_we),
        .re(mmio_re),

        .rdata(mmio_rdata),

        .vga_r(mmio_r),
        .vga_g(mmio_g),
        .vga_b(mmio_b),
        .vga_x(mmio_x),
        .vga_y(mmio_y)
    );

    // =====================================
    // VGA同期信号＋座標（25MHz）
    // =====================================
    wire hsync;
    wire vsync;
    wire visible;

    wire [9:0] x;
    wire [9:0] y;

    vga_640x480 u_vga (
        .pix_clk(pix_clk25),
        .hsync(hsync),
        .vsync(vsync),
        .visible(visible),
        .x(x),
        .y(y)
    );

    // =====================================
    // RGB信号のクロック同期
    // CPU 60MHz -> VGA 25MHz
    // =====================================
    (* ASYNC_REG = "TRUE" *)
    reg [11:0] rgb_sync1 = 12'd0;

    (* ASYNC_REG = "TRUE" *)
    reg [11:0] rgb_sync2 = 12'd0;

    always @(posedge pix_clk25) begin
        if (!locked || !CPU_RESETN) begin
            rgb_sync1 <= 12'd0;
            rgb_sync2 <= 12'd0;
        end
        else begin
            rgb_sync1 <= {mmio_r, mmio_g, mmio_b};
            rgb_sync2 <= rgb_sync1;
        end
    end

    // =====================================
    // VGA出力（25MHz）
    // =====================================
    wire text_on;
    vga_name u_name (.x(x), .y(y), .text_on(text_on));

    always @(posedge pix_clk25) begin
        VGA_HS <= hsync;
        VGA_VS <= vsync;

        if (visible && locked && CPU_RESETN) begin
            VGA_R <= text_on ? rgb_sync2[11:8] : 4'h0;
            VGA_G <= text_on ? rgb_sync2[7:4] : 4'h0;
            VGA_B <= text_on ? rgb_sync2[3:0] : 4'h0;
        end
        else begin
            VGA_R <= 4'h0;
            VGA_G <= 4'h0;
            VGA_B <= 4'h0;
        end
    end

endmodule


// Three 32x32 glyphs, scaled to 64x64 pixels: U+7551 U+82BD U+80B2.
// Display area: x=216..423, y=208..271. Two 8-pixel gaps.
module vga_name (
    input wire [9:0] x,
    input wire [9:0] y,
    output reg text_on
);
    reg [6:0] row_addr;
    reg [4:0] col;
    reg in_glyph;
    reg [31:0] glyph_row;
    wire [9:0] dx0 = x - 10'd216;
    wire [9:0] dx1 = x - 10'd288;
    wire [9:0] dx2 = x - 10'd360;
    wire [9:0] dy = y - 10'd208;

    always @(*) begin
        row_addr = 7'd0;
        col = 5'd0;
        in_glyph = 1'b0;
        if (y >= 10'd208 && y < 10'd272) begin
            if (x >= 10'd216 && x < 10'd280) begin
                in_glyph = 1'b1;
                row_addr = {2'd0, dy[5:1]};
                col = dx0[5:1];
            end else if (x >= 10'd288 && x < 10'd352) begin
                in_glyph = 1'b1;
                row_addr = {2'd1, dy[5:1]};
                col = dx1[5:1];
            end else if (x >= 10'd360 && x < 10'd424) begin
                in_glyph = 1'b1;
                row_addr = {2'd2, dy[5:1]};
                col = dx2[5:1];
            end
        end
        case (row_addr)
            7'd0: glyph_row = 32'h00000000;
            7'd1: glyph_row = 32'h00000000;
            7'd2: glyph_row = 32'h00600000;
            7'd3: glyph_row = 32'h0061FFE0;
            7'd4: glyph_row = 32'h0061FFE0;
            7'd5: glyph_row = 32'h00618C60;
            7'd6: glyph_row = 32'h00658C60;
            7'd7: glyph_row = 32'h066F8C60;
            7'd8: glyph_row = 32'h067D8C60;
            7'd9: glyph_row = 32'h06798C60;
            7'd10: glyph_row = 32'h06718C60;
            7'd11: glyph_row = 32'h06618C60;
            7'd12: glyph_row = 32'h06618C60;
            7'd13: glyph_row = 32'h0E61FFE0;
            7'd14: glyph_row = 32'h0C61FFE0;
            7'd15: glyph_row = 32'h04618C60;
            7'd16: glyph_row = 32'h00618C60;
            7'd17: glyph_row = 32'h00618C60;
            7'd18: glyph_row = 32'h00F18C60;
            7'd19: glyph_row = 32'h00F98C60;
            7'd20: glyph_row = 32'h00DD8C60;
            7'd21: glyph_row = 32'h018F8C60;
            7'd22: glyph_row = 32'h0385FFE0;
            7'd23: glyph_row = 32'h0701FFE0;
            7'd24: glyph_row = 32'h0F018060;
            7'd25: glyph_row = 32'h06018000;
            7'd26: glyph_row = 32'h00000000;
            7'd27: glyph_row = 32'h00000000;
            7'd28: glyph_row = 32'h00000000;
            7'd29: glyph_row = 32'h00000000;
            7'd30: glyph_row = 32'h00000000;
            7'd31: glyph_row = 32'h00000000;
            7'd32: glyph_row = 32'h00000000;
            7'd33: glyph_row = 32'h00181800;
            7'd34: glyph_row = 32'h00181800;
            7'd35: glyph_row = 32'h00181800;
            7'd36: glyph_row = 32'h07FFFFE0;
            7'd37: glyph_row = 32'h07FFFFE0;
            7'd38: glyph_row = 32'h00181800;
            7'd39: glyph_row = 32'h00181800;
            7'd40: glyph_row = 32'h00000000;
            7'd41: glyph_row = 32'h01FFFFC0;
            7'd42: glyph_row = 32'h01FFFFC0;
            7'd43: glyph_row = 32'h00181800;
            7'd44: glyph_row = 32'h00181800;
            7'd45: glyph_row = 32'h00181800;
            7'd46: glyph_row = 32'h00181800;
            7'd47: glyph_row = 32'h07FFFFF0;
            7'd48: glyph_row = 32'h07FFFFF0;
            7'd49: glyph_row = 32'h0001D800;
            7'd50: glyph_row = 32'h0003D800;
            7'd51: glyph_row = 32'h00079800;
            7'd52: glyph_row = 32'h001E1800;
            7'd53: glyph_row = 32'h007C1800;
            7'd54: glyph_row = 32'h03F01800;
            7'd55: glyph_row = 32'h0FC01800;
            7'd56: glyph_row = 32'h0700F800;
            7'd57: glyph_row = 32'h00007800;
            7'd58: glyph_row = 32'h00000000;
            7'd59: glyph_row = 32'h00000000;
            7'd60: glyph_row = 32'h00000000;
            7'd61: glyph_row = 32'h00000000;
            7'd62: glyph_row = 32'h00000000;
            7'd63: glyph_row = 32'h00000000;
            7'd64: glyph_row = 32'h00000000;
            7'd65: glyph_row = 32'h00038000;
            7'd66: glyph_row = 32'h00038000;
            7'd67: glyph_row = 32'h00038000;
            7'd68: glyph_row = 32'h0FFFFFF0;
            7'd69: glyph_row = 32'h0FFFFFF0;
            7'd70: glyph_row = 32'h000C1000;
            7'd71: glyph_row = 32'h001C3C00;
            7'd72: glyph_row = 32'h00380F00;
            7'd73: glyph_row = 32'h07FFFF80;
            7'd74: glyph_row = 32'h03FFC1E0;
            7'd75: glyph_row = 32'h000000C0;
            7'd76: glyph_row = 32'h00FFFF00;
            7'd77: glyph_row = 32'h00FFFF00;
            7'd78: glyph_row = 32'h00C00300;
            7'd79: glyph_row = 32'h00C00300;
            7'd80: glyph_row = 32'h00FFFF00;
            7'd81: glyph_row = 32'h00FFFF00;
            7'd82: glyph_row = 32'h00C00300;
            7'd83: glyph_row = 32'h00C00300;
            7'd84: glyph_row = 32'h00FFFF00;
            7'd85: glyph_row = 32'h00FFFF00;
            7'd86: glyph_row = 32'h00C00300;
            7'd87: glyph_row = 32'h00C00300;
            7'd88: glyph_row = 32'h00C00F00;
            7'd89: glyph_row = 32'h00C00F00;
            7'd90: glyph_row = 32'h00000000;
            7'd91: glyph_row = 32'h00000000;
            7'd92: glyph_row = 32'h00000000;
            7'd93: glyph_row = 32'h00000000;
            7'd94: glyph_row = 32'h00000000;
            7'd95: glyph_row = 32'h00000000;
            default: glyph_row = 32'h00000000;
        endcase
        text_on = in_glyph && glyph_row[31-col];
    end
endmodule


