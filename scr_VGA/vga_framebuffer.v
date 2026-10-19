module vga_framebuffer (
    input wire cpu_clk,
    input wire cpu_we,
    input wire cpu_re,
    input wire [18:0] cpu_addr,
    input wire [31:0] cpu_wdata,
    output wire [31:0] cpu_rdata,

    input wire pix_clk,
    input wire [18:0] pix_addr,
    output wire [11:0] pix_data
);
    localparam TOTAL = 307200;
    localparam BANKS = 38;

    wire [11:0] cpu_bank_data [0:BANKS-1];
    wire [11:0] pix_bank_data [0:BANKS-1];

    reg [5:0] cpu_bank_delay = 6'd0;
    reg cpu_valid_delay = 1'b0;
    reg [5:0] pix_bank_delay = 6'd0;
    reg pix_valid_delay = 1'b0;

    always @(posedge cpu_clk) begin
        if (cpu_re) begin
            cpu_bank_delay <= cpu_addr[18:13];
            cpu_valid_delay <= (cpu_addr < TOTAL);
        end
    end

    always @(posedge pix_clk) begin
        pix_bank_delay <= pix_addr[18:13];
        pix_valid_delay <= (pix_addr < TOTAL);
    end

    genvar b;
    generate
        for (b = 0; b < BANKS; b = b + 1) begin : banks
            localparam [5:0] BANK_ID = b;
            wire cpu_selected = (cpu_addr < TOTAL) &&
                                (cpu_addr[18:13] == BANK_ID);
            wire pix_selected = (pix_addr < TOTAL) &&
                                (pix_addr[18:13] == BANK_ID);

            (* keep_hierarchy = "yes" *)
            vga_framebuffer_bank u_bank (
                .cpu_clk(cpu_clk),
                .cpu_we(cpu_we && cpu_selected),
                .cpu_re(cpu_re && cpu_selected),
                .cpu_addr(cpu_addr[12:0]),
                .cpu_wdata(cpu_wdata[11:0]),
                .cpu_rdata(cpu_bank_data[b]),
                .pix_clk(pix_clk),
                .pix_re(pix_selected),
                .pix_addr(pix_addr[12:0]),
                .pix_data(pix_bank_data[b])
            );
        end
    endgenerate

    assign cpu_rdata = cpu_valid_delay
                    ? {20'd0, cpu_bank_data[cpu_bank_delay]} : 32'd0;
    assign pix_data = pix_valid_delay
                    ? pix_bank_data[pix_bank_delay] : 12'd0;
endmodule

// One bank: 8192 pixels, RGB444. All reads have one clock of latency.
module vga_framebuffer_bank (
    input wire cpu_clk,
    input wire cpu_we,
    input wire cpu_re,
    input wire [12:0] cpu_addr,
    input wire [11:0] cpu_wdata,
    output reg [11:0] cpu_rdata = 12'd0,

    input wire pix_clk,
    input wire pix_re,
    input wire [12:0] pix_addr,
    output reg [11:0] pix_data = 12'd0
);
    (* ram_style = "block" *) reg [3:0] mem_r [0:8191];
    (* ram_style = "block" *) reg [3:0] mem_g [0:8191];
    (* ram_style = "block" *) reg [3:0] mem_b [0:8191];

    integer i;
    initial begin
        for (i = 0; i < 8192; i = i + 1) begin
            mem_r[i] = 4'd0;
            mem_g[i] = 4'd0;
            mem_b[i] = 4'd0;
        end
    end

    always @(posedge cpu_clk) begin
        if (cpu_we) begin
            mem_r[cpu_addr] <= cpu_wdata[11:8];
            mem_g[cpu_addr] <= cpu_wdata[7:4];
            mem_b[cpu_addr] <= cpu_wdata[3:0];
        end
        if (cpu_re)
            cpu_rdata <= {mem_r[cpu_addr], mem_g[cpu_addr], mem_b[cpu_addr]};
    end

    always @(posedge pix_clk) begin
        if (pix_re)
            pix_data <= {mem_r[pix_addr], mem_g[pix_addr], mem_b[pix_addr]};
    end
endmodule
