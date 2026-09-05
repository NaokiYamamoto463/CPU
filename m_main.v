module m_main (
    input  wire w_clk,
    output reg  r_out = 0
);

    wire [31:0] w_rslt;
    reg  [31:0] r_rslt = 0;
    reg  [25:0] r_cnt  = 0;

    // CPU
    m_proc9_F m1 (
        .w_clk  (w_clk),
        .r_dout (w_rslt)
    );

    // CPU結果を保存
    always @(posedge w_clk) begin
        r_rslt <= w_rslt;
    end

    // VIOでCPU結果を確認
    vio_0 m2 (
        .clk       (w_clk),
        .probe_in0 (r_rslt)
    );

    // カウンタ
    always @(posedge w_clk) begin
        r_cnt <= r_cnt + 1;
    end

    // LED等への出力
    always @(posedge w_clk) begin
        r_out <= (^r_rslt) ^ r_cnt[25];
    end

endmodule