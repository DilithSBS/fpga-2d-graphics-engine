// tb_background.v: Unit testbench for background_gen and visual frame dumper
`timescale 1ns / 1ps

module tb_background;

    localparam CLK_PERIOD = 20;

    // Clock and Reset
    reg clk;
    reg rst;

    // Raster timing wires
    wire       hsync;
    wire       vsync;
    wire       active_video;
    wire [8:0] pixel_x;
    wire [8:0] pixel_y;
    wire       line_start;
    wire       frame_start;
    wire       frame_end;

    // Background generator controls & output
    reg  [1:0]  bg_mode;
    reg  [23:0] solid_color;
    wire [23:0] rgb_out;

    // Verification bookkeeping
    integer errors = 0;
    integer frame_index = 0;
    integer ppm_file;
    integer x, y;

    // -------------------------------------------------------------
    // DUT 1: Raster Timing Generator (M1 verified baseline)
    // -------------------------------------------------------------
    raster_timing dut_raster (
        .clk         (clk),
        .rst         (rst),
        .hsync       (hsync),
        .vsync       (vsync),
        .active_video(active_video),
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .line_start  (line_start),
        .frame_start (frame_start),
        .frame_end   (frame_end)
    );

    // -------------------------------------------------------------
    // DUT 2: Background Generator Under Test
    // -------------------------------------------------------------
    background_gen dut_bg (
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .active_video(active_video),
        .bg_mode     (bg_mode),
        .solid_color (solid_color),
        .rgb_out     (rgb_out)
    );

    // Clock Generation
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // -------------------------------------------------------------
    // Task: Capture One Full Frame to a PPM Image File
    // -------------------------------------------------------------
    task capture_frame;
        input [1:0]       mode;
        input [23:0]      color;
        input [8*64-1:0]  filename; // 64 ASCII characters string buffer
        integer file;
        integer pixels_captured;
        begin
            bg_mode = mode;
            solid_color = color;
            pixels_captured = 0;

            // Open PPM image file in write mode
            file = $fopen(filename, "w");
            if (file == 0) begin
                $display("[ERROR] Failed to open %0s for writing!", filename);
                errors = errors + 1;
            end else begin
                // Write PPM Header: P3 = ASCII RGB, 320 cols, 240 rows, max color = 255
                $fwrite(file, "P3\n320 240\n255\n");

                // Wait for the exact start of an active frame
                @(posedge clk);
                while (!(frame_start == 1'b1)) @(posedge clk);

                // Now stream out visible pixels as raster scans across 240 lines
                while (pixels_captured < (320 * 240)) begin
                    @(posedge clk);
                    #1; // Sample output after combinational settle
                    if (active_video) begin
                        // $fwrite RGB triplet: red, green, blue
                        $fwrite(file, "%0d %0d %0d\n", rgb_out[23:16], rgb_out[15:8], rgb_out[7:0]);
                        pixels_captured = pixels_captured + 1;
                    end else begin
                        // Self-checking: blanking clamping assertion
                        if (rgb_out !== 24'h000000) begin
                            $display("[FAIL] Blanking color leak! rgb_out=%h at X=%0d, Y=%0d",
                                     rgb_out, pixel_x, pixel_y);
                            errors = errors + 1;
                        end
                    end
                end

                $fclose(file);
                $display("[PASS] Rendered %0s (%0d pixels captured).", filename, pixels_captured);
            end
        end
    endtask

    // -------------------------------------------------------------
    // Main Verification Sequence
    // -------------------------------------------------------------
    initial begin
        $dumpfile("sim/waveforms/tb_background.vcd");
        $dumpvars(0, tb_background);

        $display("==================================================");
        $display("  STARTING M2 BACKGROUND VERIFICATION");
        $display("==================================================");

        errors = 0;
        bg_mode = 2'b00;
        solid_color = 24'h1A365D; // Navy blue

        // Apply reset
        rst = 1;
        repeat (5) @(posedge clk);
        @(posedge clk);
        #1;
        rst = 0;

        // Render Frame 0: Solid Navy Blue (Mode 00)
        capture_frame(2'b00, 24'h1A365D, "sim/output/frame_solid.ppm");

        // Render Frame 1: Standard Color Bars (Mode 01)
        capture_frame(2'b01, 24'h000000, "sim/output/frame_bars.ppm");

        // Render Frame 2: Checkerboard Pattern (Mode 10)
        capture_frame(2'b10, 24'h000000, "sim/output/frame_checker.ppm");

        // Render Frame 3: Coordinate Gradient (Mode 11)
        capture_frame(2'b11, 24'h000000, "sim/output/frame_gradient.ppm");

        $display("==================================================");
        $display("  M2 VERIFICATION COMPLETE");
        $display("  Total Errors: %0d", errors);
        $display("==================================================");

        if (errors == 0) begin
            $display(">>> ALL M2 BACKGROUND CHECKS PASSED <<<");
        end else begin
            $display(">>> M2 BACKGROUND FAILED WITH %0d ERRORS <<<", errors);
        end

        $finish;
    end

endmodule
