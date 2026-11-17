// tb_smoke.v: Minimal toolchain verification testbench
`timescale 1ns / 1ps

module tb_smoke;

    reg clk;
    reg rst;
    reg [7:0] counter;
    integer errors;

    // Clock generator: 50 MHz (20 ns period)
    always #10 clk = ~clk;

    // Synchronous counter behavior under test
    always @(posedge clk) begin
        if (rst) begin
            counter <= 8'd0;
        end else begin
            counter <= counter + 8'd1;
        end
    end

    initial begin
        // Initialize VCD dump
        $dumpfile("sim/waveforms/tb_smoke.vcd");
        $dumpvars(0, tb_smoke);

        errors = 0;
        clk = 0;
        rst = 1;

        // Apply reset for 3 cycles
        repeat (3) @(posedge clk);
        #1;
        if (counter !== 8'd0) begin
            $display("ERROR: Counter failed to reset! Found: %d, Expected: 0", counter);
            errors = errors + 1;
        end else begin
            $display("PASS: Reset verified successfully.");
        end

        // Release reset and count for 10 cycles
        rst = 0;
        repeat (10) @(posedge clk);
        #1;
        if (counter !== 8'd10) begin
            $display("ERROR: Counter mismatch after 10 cycles! Found: %d, Expected: 10", counter);
            errors = errors + 1;
        end else begin
            $display("PASS: Counter increment verified successfully (count = %d).", counter);
        end

        // Report summary
        if (errors == 0) begin
            $display("=== M0 TOOLCHAIN SMOKE TEST PASSED ===");
        end else begin
            $display("=== M0 TOOLCHAIN SMOKE TEST FAILED with %0d errors ===", errors);
        end

        $finish;
    end

endmodule
