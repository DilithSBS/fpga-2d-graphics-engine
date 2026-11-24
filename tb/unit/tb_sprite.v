// tb_sprite.v: Dedicated unit testbench for sprite_renderer
`timescale 1ns / 1ps

module tb_sprite;

    localparam CLK_PERIOD = 20;

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

    // Background generator wires
    wire [23:0] bg_rgb;

    // Sprite controls and wires
    reg         sp_enable;
    reg  [8:0]  sp_x;
    reg  [8:0]  sp_y;
    wire [23:0] sp_rgb;
    wire        sp_valid;

    // Composited color for PPM dump
    wire [23:0] composite_rgb = sp_valid ? sp_rgb : bg_rgb;

    integer errors = 0;
    integer ppm_file;
    integer pixels_captured;

    // -------------------------------------------------------------
    // Device Under Test Instantiations
    // -------------------------------------------------------------
    raster_timing u_raster (
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

    background_gen u_bg (
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .active_video(active_video),
        .bg_mode     (2'b00), // Solid Deep Space Navy Blue
        .solid_color (24'h0A0E1A),
        .rgb_out     (bg_rgb)
    );

    sprite_renderer #(
        .SPRITE_W(16),
        .SPRITE_H(16)
    ) dut_sprite (
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .active_video(active_video),
        .enable      (sp_enable),
        .sprite_x    (sp_x),
        .sprite_y    (sp_y),
        .pixel_rgb   (sp_rgb),
        .pixel_valid (sp_valid)
    );

    // Clock Generation
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // -------------------------------------------------------------
    // Helper task: Sample pixel at post-clock quiescent edge
    // -------------------------------------------------------------
    task wait_pixel;
        input [8:0] target_x;
        input [8:0] target_y;
        begin
            @(posedge clk);
            #1;
            while (!(pixel_x == target_x && pixel_y == target_y)) begin
                @(posedge clk);
                #1;
            end
        end
    endtask

    // -------------------------------------------------------------
    // Task: Detailed Sprite Pixel & Transparency Assertions
    // -------------------------------------------------------------
    task verify_sprite_assertions;
        begin
            $display("[TEST] Verifying Sprite Pixel & Transparency Assertions...");

            // Test 1: Corner pixel (0,0) is Transparent (sp_x=152, sp_y=112)
            wait_pixel(9'd152, 9'd112);
            if (sp_valid !== 1'b0) begin
                $display("[FAIL] Corner (0,0) should be transparent! valid=%b", sp_valid);
                errors = errors + 1;
            end else begin
                $display("[PASS] Sprite transparency at (0,0) verified.");
            end

            // Test 2: Tip of spacecraft outline at (7, 0) -> (152+7=159, 112)
            wait_pixel(9'd159, 9'd112);
            if (sp_valid !== 1'b1 || sp_rgb !== 24'h1A202C) begin
                $display("[FAIL] Tip outline mismatch at (7,0)! valid=%b, rgb=%h (Expected 24'h1A202C)",
                         sp_valid, sp_rgb);
                errors = errors + 1;
            end else begin
                $display("[PASS] Spacecraft tip outline at (7,0) verified.");
            end

            // Test 3: Cockpit flame at (7, 1) -> (159, 113)
            wait_pixel(9'd159, 9'd113);
            if (sp_valid !== 1'b1 || sp_rgb !== 24'hFF6B6B) begin
                $display("[FAIL] Flame/Cockpit color mismatch at (7,1)! valid=%b, rgb=%h",
                         sp_valid, sp_rgb);
                errors = errors + 1;
            end else begin
                $display("[PASS] Flame/Cockpit pixel at (7,1) verified.");
            end

            // Test 4: Cyan hull at (7, 5) -> (159, 117)
            wait_pixel(9'd159, 9'd117);
            if (sp_valid !== 1'b1 || sp_rgb !== 24'h00D8D6) begin
                $display("[FAIL] Cyan hull mismatch at (7,5)! valid=%b, rgb=%h",
                         sp_valid, sp_rgb);
                errors = errors + 1;
            end else begin
                $display("[PASS] Cyan hull pixel at (7,5) verified.");
            end

            // Test 5: Right boundary exclusion at (152+16=168, 112)
            wait_pixel(9'd168, 9'd112);
            if (sp_valid !== 1'b0) begin
                $display("[FAIL] Pixel past right boundary should be excluded! valid=%b", sp_valid);
                errors = errors + 1;
            end else begin
                $display("[PASS] Sprite right boundary exclusion verified.");
            end
        end
    endtask

    // -------------------------------------------------------------
    // Main Verification Process
    // -------------------------------------------------------------
    initial begin
        $dumpfile("sim/waveforms/tb_sprite.vcd");
        $dumpvars(0, tb_sprite);

        $display("==================================================");
        $display("  STARTING M5 SPRITE RENDERER VERIFICATION");
        $display("==================================================");

        // Center sprite on 320x240 screen: (320-16)/2 = 152, (240-16)/2 = 112
        sp_enable = 1'b1;
        sp_x = 9'd152;
        sp_y = 9'd112;

        rst = 1;
        repeat (5) @(posedge clk);
        @(posedge clk);
        #1;
        rst = 0;

        // Run behavioral assertions
        verify_sprite_assertions();

        // Render full frame with spacecraft sprite to PPM
        $display("[INFO] Rendering sprite frame to sim/output/frame_sprite.ppm...");
        ppm_file = $fopen("sim/output/frame_sprite.ppm", "w");
        $fwrite(ppm_file, "P3\n320 240\n255\n");

        while (!(frame_start == 1'b1)) @(posedge clk);

        pixels_captured = 0;
        while (pixels_captured < (320 * 240)) begin
            @(posedge clk);
            #1;
            if (active_video) begin
                $fwrite(ppm_file, "%0d %0d %0d\n",
                        composite_rgb[23:16],
                        composite_rgb[15:8],
                        composite_rgb[7:0]);
                pixels_captured = pixels_captured + 1;
            end
        end
        $fclose(ppm_file);
        $display("[PASS] Captured %0d pixels to sim/output/frame_sprite.ppm.", pixels_captured);

        $display("==================================================");
        $display("  M5 SPRITE VERIFICATION COMPLETE");
        $display("  Total Errors: %0d", errors);
        $display("==================================================");

        if (errors == 0) begin
            $display(">>> ALL M5 SPRITE CHECKS PASSED <<<");
        end else begin
            $display(">>> M5 SPRITE FAILED WITH %0d ERRORS <<<", errors);
        end

        $finish;
    end

endmodule
