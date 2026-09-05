module m_main (
    input  wire CLK100MHZ,     // ボードの100 MHzクロック
    output wire [15:0] LED     // 16個のLED（1で点灯）
);

    wire [31:0] w_rslt;
    reg  [31:0] r_rslt = 0;

    // CPUから32ビットの計算結果を受け取る
    m_proc9_F m1 (
        .w_clk  (CLK100MHZ),
        .r_dout (w_rslt)
    );

    // クロックの立ち上がりで結果を保存
    always @(posedge CLK100MHZ) begin
        r_rslt <= w_rslt;
    end

    // VIOでCPU結果を確認
    vio_0 m2 (
        .clk       (CLK100MHZ),
        .probe_in0 (r_rslt)
    );

    // 結果の下位16ビットを表示（LED[0]が最下位ビット）
    // 5050 = 16'b0001_0011_1011_1010
    assign LED = r_rslt[15:0];

endmodule
