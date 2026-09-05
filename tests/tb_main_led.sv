`timescale 1ns / 1ps

// Observation-only replacement for the Vivado VIO IP.
module vio_0 (
    input wire clk,
    input wire [31:0] probe_in0
);
endmodule

module tb_main_led;
    reg w_clk = 0;
    wire [15:0] sample_led;
    wire [15:0] values_led;
    integer sample_writes = 0;
    integer i;
    integer cycles;
    reg values_done = 0;

    m_main sample (.CLK100MHZ(w_clk), .LED(sample_led));
    m_main values (.CLK100MHZ(w_clk), .LED(values_led));

    always #5 w_clk = ~w_clk;

    // Count actual x30 writes to verify that the sample runs again after
    // the instruction-memory address wraps, while its LEDs stay stable.
    always @(posedge w_clk) begin
        if (sample.m1.m5.w_we && sample.m1.m5.w_wa == 5'd30)
            sample_writes = sample_writes + 1;
    end

    task automatic expect_value(input [31:0] expected);
        integer elapsed;
        begin
            elapsed = 0;
            while (values_led !== expected[15:0] && elapsed < 40) begin
                @(posedge w_clk);
                #1;
                elapsed = elapsed + 1;
            end
            if (values_led !== expected[15:0])
                $fatal(1, "LED timeout: expected %h, got %h",
                       expected[15:0], values_led);
            if (values.r_rslt !== expected ||
                values.m2.probe_in0 !== expected)
                $fatal(1, "Full result/VIO mismatch for %h", expected);
            repeat (4) begin
                @(posedge w_clk);
                #1;
                if (values_led !== expected[15:0])
                    $fatal(1, "LED value changed before the next result");
            end
        end
    endtask

    initial begin
        // Keep the first CPU's asm.vh unchanged. Give a second real CPU
        // three results to check load output, truncation, zero, and all ones.
        #1;
        if (sample_led !== 16'd0 || values_led !== 16'd0 ||
            sample.w_rslt !== 32'd0 || values.w_rslt !== 32'd0)
            $fatal(1, "CPU result and LEDs must start at zero");
        for (i = 0; i < 64; i = i + 1)
            values.m1.m3.mem[i] = 32'h00000013; // nop
        values.m1.m9.mem[0] = 32'h1234a55a;
        values.m1.m3.mem[0] = 32'h00002f03;     // lw x30,0(x0)
        values.m1.m3.mem[8] = 32'h00000f13;     // addi x30,x0,0
        values.m1.m3.mem[16] = 32'hfff00f13;    // addi x30,x0,-1

        expect_value(32'h1234a55a);
        expect_value(32'h00000000);
        expect_value(32'hffffffff);
        values_done = 1;
        $display("PASS: initial LEDs off; load, low 16 bits, zero and all ones");
    end

    initial begin
        cycles = 0;
        while (sample_led !== 16'h13ba && cycles < 800) begin
            @(posedge w_clk);
            #1;
            cycles = cycles + 1;
            if (sample_led !== 16'd0 && sample_led !== 16'h13ba)
                $fatal(1, "Unexpected sample LED value: %h", sample_led);
        end
        if (sample_led !== 16'h13ba || sample.r_rslt !== 32'd5050)
            $fatal(1, "Sample did not produce 5050 within 800 clocks");

        while (sample_writes < 2 && cycles < 2000) begin
            @(posedge w_clk);
            #1;
            cycles = cycles + 1;
            if (sample_led !== 16'h13ba)
                $fatal(1, "Sample LEDs changed during program rerun");
        end
        if (sample_writes < 2)
            $fatal(1, "Sample did not complete a second run");
        repeat (20) begin
            @(posedge w_clk);
            #1;
            if (sample_led !== 16'h13ba)
                $fatal(1, "Sample LEDs changed after program rerun");
        end
        if (!values_done)
            $fatal(1, "Additional result checks did not finish");
        $display("PASS: sample 5050 = 16'h13BA, stable across %0d runs",
                 sample_writes);
        $finish;
    end

    initial begin
        #25000;
        $fatal(1, "Overall simulation timeout");
    end
endmodule
