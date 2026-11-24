// tb_sprite.v: Dedicated unit testbench for multi-sprite sprite_renderer
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

    // Sprite 1: Spacecraft (sprite_id = 0)
    reg         sp1_enable;
    reg  [2:0]  sp1_id;
    reg  [8:0]  sp1_x, sp1_y;
    wire [23:0] sp1_rgb;
    wire        sp1_valid;

    // Sprite 2: Asteroid (sprite_id = 1)
    reg         sp2_enable;
    reg  [2:0]  sp2_id;
    reg  [8:0]  sp2_x, sp2_y;
    wire [23:0] sp2_rgb;
    wire        sp2_valid;

    // Simple compositor for visual test: Sprite 1 > Sprite 2 > Background
    wire [23:0] composite_rgb = sp1_valid ? sp1_rgb
                              : sp2_valid ? sp2_rgb
                              : bg_rgb;

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

    // Instance 1: Spacecraft
    sprite_renderer #(
        .SPRITE_W(16),
        .SPRITE_H(16)
    ) dut_spacecraft (
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .active_video(active_video),
        .sprite_id   (sp1_id),
        .enable      (sp1_enable),
        .sprite_x    (sp1_x),
        .sprite_y    (sp1_y),
        .pixel_rgb   (sp1_rgb),
        .pixel_valid (sp1_valid)
    );

    // Instance 2: Asteroid
    sprite_renderer #(
        .SPRITE_W(16),
        .SPRITE_H(16)
    ) dut_asteroid (
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .active_video(active_video),
        .sprite_id   (sp2_id),
        .enable      (sp2_enable),
        .sprite_x    (sp2_x),
        .sprite_y    (sp2_y),
        .pixel_rgb   (sp2_rgb),
        .pixel_valid (sp2_valid)
    );

    // Clock Generation
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

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
    // Behavioral Assertions
    // -------------------------------------------------------------
    task verify_sprites;
        begin
            $display("[TEST] Verifying Spacecraft & Asteroid Assertions...");

            // Check Spacecraft tip outline at (sp1_x+7, sp1_y+0) = (107, 112)
            wait_pixel(9'd107, 9'd112);
            if (sp1_valid !== 1'b1 || sp1_rgb !== 24'h1A202C) begin
                $display("[FAIL] Spacecraft tip outline mismatch! Got=%h, Expected=24'h1A202C", sp1_rgb);
                errors = errors + 1;
            end else begin
                $display("[PASS] Spacecraft tip outline verified.");
            end

            // Check Asteroid rocky body pixel at (sp2_x+7, sp2_y+4) = (207, 116)
            wait_pixel(9'd207, 9'd116);
            if (sp2_valid !== 1'b1 || sp2_rgb !== 24'h718096) begin
                $display("[FAIL] Asteroid rock body mismatch! Got=%h, Expected=24'h718096", sp2_rgb);
                errors = errors + 1;
            end else begin
                $display("[PASS] Asteroid rocky body pixel verified.");
            end

            // Check Asteroid ridge highlight at (sp2_x+4, sp2_y+1) = (204, 113)
            wait_pixel(9'd204, 9'd113);
            if (sp2_valid !== 1'b1 || sp2_rgb !== 24'hCBD5E0) begin
                $display("[FAIL] Asteroid ridge highlight mismatch! Got=%h, Expected=24'hCBD5E0", sp2_rgb);
                errors = errors + 1;
            end else begin
                $display("[PASS] Asteroid ridge highlight pixel verified.");
            end
        end
    endtask

    initial begin
        $dumpfile("sim/waveforms/tb_sprite.vcd");
        $dumpvars(0, tb_sprite);

        $display("==================================================");
        $display("  STARTING MULTI-SPRITE VERIFICATION");
        $display("==================================================");

        // Position Spacecraft on the left (X=100, Y=112)
        sp1_enable = 1'b1;
        sp1_id     = 3'b000;
        sp1_x      = 9'd100;
        sp1_y      = 9'd112;

        // Position Asteroid on the right (X=200, Y=112)
        sp2_enable = 1'b1;
        sp2_id     = 3'b001;
        sp2_x      = 9'd200;
        sp2_y      = 9'd112;

        rst = 1;
        repeat (5) @(posedge clk);
        @(posedge clk);
        #1;
        rst = 0;

        verify_sprites();

        // Render full frame with both sprites
        $display("[INFO] Rendering multi-sprite frame to sim/output/frame_sprite.ppm...");
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
        $display("  MULTI-SPRITE VERIFICATION COMPLETE");
        $display("  Total Errors: %0d", errors);
        $display("==================================================");

        if (errors == 0) begin
            $display(">>> ALL MULTI-SPRITE CHECKS PASSED <<<");
        end else begin
            $display(">>> MULTI-SPRITE FAILED WITH %0d ERRORS <<<", errors);
        end

        $finish;
    end

endmodule
