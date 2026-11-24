// tb_compositor.v: Unit testbench for layer_compositor and multi-layer integration
`timescale 1ns / 1ps

module tb_compositor;

    localparam CLK_PERIOD = 20;

    reg clk;
    reg rst;

    // Direct standalone test signals
    reg         comp_active;
    reg  [23:0] test_l0_rgb;
    reg  [23:0] test_l1_rgb;
    reg         test_l1_valid;
    reg  [23:0] test_l2_rgb;
    reg         test_l2_valid;
    reg  [23:0] test_l3_rgb;
    reg         test_l3_valid;
    wire [23:0] test_final_rgb;

    integer errors = 0;
    integer i;

    // -------------------------------------------------------------
    // DUT 1: Standalone Compositor (for exhaustive priority matrix)
    // -------------------------------------------------------------
    layer_compositor dut_comp_standalone (
        .active_video(comp_active),
        .l0_rgb      (test_l0_rgb),
        .l1_rgb      (test_l1_rgb),
        .l1_valid    (test_l1_valid),
        .l2_rgb      (test_l2_rgb),
        .l2_valid    (test_l2_valid),
        .l3_rgb      (test_l3_rgb),
        .l3_valid    (test_l3_valid),
        .final_rgb   (test_final_rgb)
    );

    // -------------------------------------------------------------
    // DUT 2: Integrated Pipeline (Raster + BG + 2 Rects + Circle + Compositor)
    // -------------------------------------------------------------
    wire       hsync;
    wire       vsync;
    wire       active_video;
    wire [8:0] pixel_x;
    wire [8:0] pixel_y;
    wire       line_start;
    wire       frame_start;
    wire       frame_end;

    wire [23:0] bg_rgb;
    wire [23:0] r1_rgb;
    wire        r1_valid;
    wire [23:0] r2_rgb;
    wire        r2_valid;
    wire [23:0] c1_rgb;
    wire        c1_valid;
    wire [23:0] integrated_final_rgb;

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

    // Layer 0: Background
    background_gen u_bg (
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .active_video(active_video),
        .bg_mode     (2'b10), // Checkerboard
        .solid_color (24'h000000),
        .rgb_out     (bg_rgb)
    );

    // Layer 1: Blue Back Rectangle (X=80, Y=60, W=120, H=80)
    rectangle_renderer u_rect_l1 (
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .active_video(active_video),
        .enable      (1'b1),
        .rect_x      (9'd80),
        .rect_y      (9'd60),
        .rect_w      (9'd120),
        .rect_h      (9'd80),
        .rect_color  (24'h2B6CB0), // Blue
        .pixel_rgb   (r1_rgb),
        .pixel_valid (r1_valid)
    );

    // Layer 2: Green Middle Rectangle overlapping L1 (X=130, Y=90, W=110, H=80)
    rectangle_renderer u_rect_l2 (
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .active_video(active_video),
        .enable      (1'b1),
        .rect_x      (9'd130),
        .rect_y      (9'd90),
        .rect_w      (9'd110),
        .rect_h      (9'd80),
        .rect_color  (24'h38A169), // Green
        .pixel_rgb   (r2_rgb),
        .pixel_valid (r2_valid)
    );

    // Layer 3: Amber Topmost Circle overlapping both L1 and L2 (Center: 140, 100, R=35)
    circle_renderer u_circle_l3 (
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .active_video(active_video),
        .enable      (1'b1),
        .center_x    (9'd140),
        .center_y    (9'd100),
        .radius      (8'd35),
        .circle_color(24'hDD6B20), // Amber
        .pixel_rgb   (c1_rgb),
        .pixel_valid (c1_valid)
    );

    // Integrated Compositor
    layer_compositor u_compositor (
        .active_video(active_video),
        .l0_rgb      (bg_rgb),
        .l1_rgb      (r1_rgb),
        .l1_valid    (r1_valid),
        .l2_rgb      (r2_rgb),
        .l2_valid    (r2_valid),
        .l3_rgb      (c1_rgb),
        .l3_valid    (c1_valid),
        .final_rgb   (integrated_final_rgb)
    );

    // Clock Generation
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // -------------------------------------------------------------
    // Task: Exhaustive 8-State Priority Matrix Verification
    // -------------------------------------------------------------
    task test_priority_matrix;
        reg [23:0] expected_color;
        begin
            $display("[TEST] Testing all 8 layer transparency combinations (Active Video = 1)...");
            test_l0_rgb = 24'h111111; // L0
            test_l1_rgb = 24'h222222; // L1
            test_l2_rgb = 24'h333333; // L2
            test_l3_rgb = 24'h444444; // L3
            comp_active = 1'b1;

            for (i = 0; i < 8; i = i + 1) begin
                test_l1_valid = i[0];
                test_l2_valid = i[1];
                test_l3_valid = i[2];
                #5; // Settle combinational logic

                // Determine expected priority: L3 > L2 > L1 > L0
                if (test_l3_valid)      expected_color = test_l3_rgb;
                else if (test_l2_valid) expected_color = test_l2_rgb;
                else if (test_l1_valid) expected_color = test_l1_rgb;
                else                    expected_color = test_l0_rgb;

                if (test_final_rgb !== expected_color) begin
                    $display("[FAIL] Priority State {L3=%b, L2=%b, L1=%b} Mismatch! Got=%h, Expected=%h",
                             test_l3_valid, test_l2_valid, test_l1_valid, test_final_rgb, expected_color);
                    errors = errors + 1;
                end else begin
                    $display("[PASS] Priority State {L3=%b, L2=%b, L1=%b} -> Output=%h Verified.",
                             test_l3_valid, test_l2_valid, test_l1_valid, test_final_rgb);
                end
            end

            // Blanking Suppression Test across all 8 states
            $display("[TEST] Testing Blanking Clamping across all 8 combinations (Active Video = 0)...");
            comp_active = 1'b0;
            for (i = 0; i < 8; i = i + 1) begin
                test_l1_valid = i[0];
                test_l2_valid = i[1];
                test_l3_valid = i[2];
                #5;
                if (test_final_rgb !== 24'h000000) begin
                    $display("[FAIL] Blanking color leak when active_video=0! State={%b,%b,%b}, Got=%h",
                             test_l3_valid, test_l2_valid, test_l1_valid, test_final_rgb);
                    errors = errors + 1;
                end
            end
            $display("[PASS] Blanking suppression verified across all states.");
        end
    endtask

    // -------------------------------------------------------------
    // Main Verification Process
    // -------------------------------------------------------------
    integer ppm_file;
    integer pixels_captured;

    initial begin
        $dumpfile("sim/waveforms/tb_compositor.vcd");
        $dumpvars(0, tb_compositor);

        $display("==================================================");
        $display("  STARTING M4 LAYER COMPOSITOR VERIFICATION");
        $display("==================================================");

        // Step 1: Run standalone priority checks
        test_priority_matrix();

        // Step 2: Run full frame simulation and render multi-layer overlapping scene
        $display("[INFO] Rendering multi-layer overlapping scene to sim/output/frame_compositor.ppm...");
        rst = 1;
        repeat (5) @(posedge clk);
        @(posedge clk);
        #1;
        rst = 0;

        ppm_file = $fopen("sim/output/frame_compositor.ppm", "w");
        $fwrite(ppm_file, "P3\n320 240\n255\n");

        while (!(frame_start == 1'b1)) @(posedge clk);

        pixels_captured = 0;
        while (pixels_captured < (320 * 240)) begin
            @(posedge clk);
            #1;
            if (active_video) begin
                $fwrite(ppm_file, "%0d %0d %0d\n",
                        integrated_final_rgb[23:16],
                        integrated_final_rgb[15:8],
                        integrated_final_rgb[7:0]);
                pixels_captured = pixels_captured + 1;
            end
        end
        $fclose(ppm_file);
        $display("[PASS] Captured %0d composite pixels to sim/output/frame_compositor.ppm.", pixels_captured);

        $display("==================================================");
        $display("  M4 COMPOSITOR VERIFICATION COMPLETE");
        $display("  Total Errors: %0d", errors);
        $display("==================================================");

        if (errors == 0) begin
            $display(">>> ALL M4 COMPOSITOR CHECKS PASSED <<<");
        end else begin
            $display(">>> M4 COMPOSITOR FAILED WITH %0d ERRORS <<<", errors);
        end

        $finish;
    end

endmodule

