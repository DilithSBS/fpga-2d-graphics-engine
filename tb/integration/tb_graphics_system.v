// tb_graphics_system.v: Full-chip top-level integration testbench for simulation_top
`timescale 1ns / 1ps

module tb_graphics_system;

    localparam CLK_PERIOD = 20;

    reg clk;
    reg rst;

    reg btn_up;
    reg btn_down;
    reg btn_left;
    reg btn_right;
    reg btn_restart;

    wire        hsync;
    wire        vsync;
    wire        active_video;
    wire [23:0] rgb_out;

    wire        collision_detected;
    wire        game_over;
    wire [15:0] score;

    integer errors = 0;
    integer ppm_file;
    integer pixels_captured;

    // -------------------------------------------------------------
    // Device Under Test: Full System Top
    // -------------------------------------------------------------
    simulation_top dut_top (
        .clk               (clk),
        .rst               (rst),
        .btn_up            (btn_up),
        .btn_down          (btn_down),
        .btn_left          (btn_left),
        .btn_right         (btn_right),
        .btn_restart       (btn_restart),
        .hsync             (hsync),
        .vsync             (vsync),
        .active_video      (active_video),
        .rgb_out           (rgb_out),
        .collision_detected(collision_detected),
        .game_over         (game_over),
        .score             (score)
    );

    // Clock Generation
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // -------------------------------------------------------------
    // Task: Capture complete frame from top-level video outputs
    // -------------------------------------------------------------
    task capture_top_frame;
        input [8*64-1:0] filename;
        integer file;
        integer captured;
        begin
            file = $fopen(filename, "w");
            if (file == 0) begin
                $display("[ERROR] Failed to open %0s", filename);
                errors = errors + 1;
            end else begin
                $fwrite(file, "P3\n320 240\n255\n");
                
                // Wait for active video to begin
                while (active_video == 1'b1) @(posedge clk);
                while (active_video == 1'b0) @(posedge clk);

                captured = 0;
                while (captured < (320 * 240)) begin
                    @(posedge clk);
                    #1;
                    if (active_video) begin
                        $fwrite(file, "%0d %0d %0d\n", rgb_out[23:16], rgb_out[15:8], rgb_out[7:0]);
                        captured = captured + 1;
                    end else begin
                        // Self-checking: Top-level blanking clamping assertion
                        if (rgb_out !== 24'h000000) begin
                            $display("[FAIL] Top-level blanking color leak! rgb_out=%h", rgb_out);
                            errors = errors + 1;
                        end
                    end
                end
                $fclose(file);
                $display("[PASS] Rendered %0s (%0d pixels captured).", filename, captured);
            end
        end
    endtask

    // -------------------------------------------------------------
    // Main Verification Process
    // -------------------------------------------------------------
    initial begin
        $dumpfile("sim/waveforms/tb_graphics_system.vcd");
        $dumpvars(0, tb_graphics_system);

        $display("==================================================");
        $display("  STARTING M7 FULL CHIP TOP-LEVEL VERIFICATION");
        $display("==================================================");

        btn_up = 0;
        btn_down = 0;
        btn_left = 0;
        btn_right = 0;
        btn_restart = 0;

        // Apply global synchronous reset
        rst = 1;
        repeat (5) @(posedge clk);
        @(posedge clk);
        #1;
        rst = 0;

        // Assertion 1: Reset behavior
        if (hsync !== 1'b1 || vsync !== 1'b1 || active_video !== 1'b0 || score !== 16'd0) begin
            $display("[FAIL] Top-level reset outputs incorrect! hsync=%b, vsync=%b, score=%0d",
                     hsync, vsync, score);
            errors = errors + 1;
        end else begin
            $display("[PASS] Top-level global reset outputs verified.");
        end

        // Capture Frame 1: Initial System State
        capture_top_frame("sim/output/top_system_frame.ppm");

        $display("==================================================");
        $display("  M7 FULL SYSTEM VERIFICATION COMPLETE");
        $display("  Total Errors: %0d", errors);
        $display("==================================================");

        if (errors == 0) begin
            $display(">>> ALL M7 FULL SYSTEM CHECKS PASSED <<<");
        end else begin
            $display(">>> M7 FULL SYSTEM FAILED WITH %0d ERRORS <<<", errors);
        end

        $finish;
    end

endmodule
