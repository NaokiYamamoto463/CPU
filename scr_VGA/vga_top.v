
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
    // 100MHz -> VGA 25MHz / CPU 50MHz
    // =====================================
    wire pix_clk25;
    wire cpu_clk50;
    wire locked;

    clk_wiz_0 u_clk (
        .clk_in1(CLK100MHZ),
        .clk_out1(pix_clk25),
        .clk_out2(cpu_clk50),
        .reset(~CPU_RESETN),
        .locked(locked)
    );

    // =====================================
    // CPUリセット（50MHzドメイン）
    // =====================================
    wire reset_req = ~CPU_RESETN | ~locked;

    (* ASYNC_REG = "TRUE" *)
    reg [1:0] cpu_reset_sync = 2'b11;

    always @(posedge cpu_clk50 or posedge reset_req) begin
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
    // RISC-V CPU（50MHz）
    // =====================================
    m_proc9_F u_cpu (
        .w_clk(cpu_clk50),
        .reset(reset),
        .r_dout(cpu_result),

        .mmio_addr(mmio_addr),
        .mmio_wdata(mmio_wdata),
        .mmio_we(mmio_we),
        .mmio_re(mmio_re),
        .mmio_rdata(mmio_rdata)
    );

    // =====================================
    // VGA MMIO（50MHz）
    // =====================================
    vga_mmio u_mmio (
        .clk(cpu_clk50),
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
    // 画面用メモリ
    // =====================================

    // CPUのアクセス先が画面用メモリか判定
    wire fb_sel = (mmio_addr >= 32'h8100_0000) &&
                  (mmio_addr <  32'h8112_C000) &&
                  (mmio_addr[1:0] == 2'b00);

    // 表示する画素番号 = Y × 640 + X
    wire [18:0] fb_pix_addr = y * 19'd640 + {9'd0, x};

    // 読み出した画素の色
    wire [11:0] fb_pix_data;

    vga_framebuffer u_fb (
        // CPU側
        .cpu_clk(cpu_clk50),
        .cpu_we(mmio_we && fb_sel),
        .cpu_re(1'b0),
        .cpu_addr(mmio_addr[20:2]),
        .cpu_wdata(mmio_wdata),
        .cpu_rdata(),

        // VGA側
        .pix_clk(pix_clk25),
        .pix_addr(visible ? fb_pix_addr : 19'd0),
        .pix_data(fb_pix_data)
    );

    // =====================================
    // VGA出力
    // =====================================

    // メモリの読み出しに同期信号を合わせる
    reg visible_delay = 1'b0;
    reg hsync_delay = 1'b1;
    reg vsync_delay = 1'b1;

    always @(posedge pix_clk25) begin
        visible_delay <= visible;
        hsync_delay <= hsync;
        vsync_delay <= vsync;

        VGA_HS <= hsync_delay;
        VGA_VS <= vsync_delay;

        if (visible_delay && locked && CPU_RESETN) begin
            // 保存された画素の色を出力
            VGA_R <= fb_pix_data[11:8];
            VGA_G <= fb_pix_data[7:4];
            VGA_B <= fb_pix_data[3:0];
        end else begin
            VGA_R <= 4'h0;
            VGA_G <= 4'h0;
            VGA_B <= 4'h0;
        end
    end

endmodule
