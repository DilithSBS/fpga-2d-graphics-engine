// tb_primitives.v: Unit testbench for rectangle_renderer and circle_renderer
`timescale 1ns / 1ps

module tb_primitives;

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

    // Rectangle 1 (Center-Left Blue Rect)
    reg         r1_enable;
    reg  [8:0]  r1_x, r1_y, r1_w, r1_h;
    reg  [23:0] r1_color;
    wire [23:0] r1_rgb;
    wire        r1_valid;

    // Rectangle 2 (Edge-Clipping Red Rect)
    reg         r2_enable;
    reg  [8:0]  r2_x, r2_y, r2_w, r2_h;
    reg  [23:0] r2_color;
    wire [23:0] r2_rgb;
    wire        r2_valid;

    // Circle 1 (Center Amber Circle)
    reg         c1_enable;
    reg  [8:0]  c1_cx, c1_cy;
    reg  [7:0]  c1_r;
    reg  [23:0] c1_color;
    wire [23:0] c1_rgb;
    wire        c1_valid;

    // Composite display color for PPM dump
    reg  [23:0] composite_rgb;

    integer errors = 0;

    // -------------------------------------------------------------
    // Device Under Test Instantiations
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

    background_gen dut_bg (
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .active_video(active_video),
        .bg_mode     (2'b10), // Checkerboard
        .solid_color (24'h000000),
        .rgb_out     (bg_rgb)
    );

    rectangle_renderer dut_rect1 (
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .active_video(active_video),
        .enable      (r1_enable),
        .rect_x      (r1_x),
        .rect_y      (r1_y),
        .rect_w      (r1_w),
        .rect_h      (r1_h),
        .rect_color  (r1_color),
        .pixel_rgb   (r1_rgb),
        .pixel_valid (r1_valid)
    );

    rectangle_renderer dut_rect2 (
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .active_video(active_video),
        .enable      (r2_enable),
        .rect_x      (r2_x),
        .rect_y      (r2_y),
        .rect_w      (r2_w),
        .rect_h      (r2_h),
        .rect_color  (r2_color),
        .pixel_rgb   (r2_rgb),
        .pixel_valid (r2_valid)
    );

    circle_renderer dut_circle1 (
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .active_video(active_video),
        .enable      (c1_enable),
        .center_x    (c1_cx),
        .center_y    (c1_cy),
        .radius      (c1_r),
        .circle_color(c1_color),
        .pixel_rgb   (c1_rgb),
        .pixel_valid (c1_valid)
    );

    // Clock Generation
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Simple priority compositing for test visualization
    always @* begin
        if (!active_video)
            composite_rgb = 24'h000000;
        else if (c1_valid)
            composite_rgb = c1_rgb;
        else if (r1_valid)
            composite_rgb = r1_rgb;
        else if (r2_valid)
            composite_rgb = r2_rgb;
        else
            composite_rgb = bg_rgb;
    end

    // Helper task to wait for specific coordinate with post-clock settle
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
    // Task: Boundary Test for Rectangle
    // -------------------------------------------------------------
    task verify_rectangle_logic;
        begin
            $display("[TEST] Verifying Rectangle Boundary Assertions...");

            // Test 1: Active coordinates inside R1 (x=30..89, y=40..89)
            wait_pixel(9'd30, 9'd40);
            if (r1_valid !== 1'b1 || r1_rgb !== r1_color) begin
                $display("[FAIL] Upper-left corner of R1 not valid! X=%0d Y=%0d valid=%b, rgb=%h",
                         pixel_x, pixel_y, r1_valid, r1_rgb);
                errors = errors + 1;
            end else begin
                $display("[PASS] Rectangle upper-left corner inclusion verified.");
            end

            // Test 2: Bottom-right inside pixel (x=89, y=89)
            wait_pixel(9'd89, 9'd89);
            if (r1_valid !== 1'b1) begin
                $display("[FAIL] Bottom-right inside pixel of R1 not valid! X=%0d Y=%0d valid=%b",
                         pixel_x, pixel_y, r1_valid);
                errors = errors + 1;
            end else begin
                $display("[PASS] Rectangle bottom-right corner inclusion verified.");
            end

            // Test 3: Half-open boundary exclusion (x=90, y=89)
            wait_pixel(9'd90, 9'd89);
            if (r1_valid !== 1'b0) begin
                $display("[FAIL] Half-open boundary pixel (X0+W) should be excluded! X=%0d Y=%0d valid=%b",
                         pixel_x, pixel_y, r1_valid);
                errors = errors + 1;
            end else begin
                $display("[PASS] Rectangle half-open exclusion boundary verified.");
            end
        end
    endtask

    // -------------------------------------------------------------
    // Task: Boundary Test for Circle
    // -------------------------------------------------------------
    task verify_circle_logic;
        begin
            $display("[TEST] Verifying Circle Boundary Assertions...");

            // Test 1: Circle Center (cx=160, cy=120)
            wait_pixel(9'd160, 9'd120);
            if (c1_valid !== 1'b1 || c1_rgb !== c1_color) begin
                $display("[FAIL] Circle center not valid! X=%0d Y=%0d valid=%b, rgb=%h",
                         pixel_x, pixel_y, c1_valid, c1_rgb);
                errors = errors + 1;
            end else begin
                $display("[PASS] Circle center inclusion verified.");
            end

            // Test 2: Point at radius boundary (cx+R = 160 + 35 = 195, cy=120)
            wait_pixel(9'd195, 9'd120);
            if (c1_valid !== 1'b1) begin
                $display("[FAIL] Circle boundary pixel (cx+R) not valid! X=%0d Y=%0d valid=%b",
                         pixel_x, pixel_y, c1_valid);
                errors = errors + 1;
            end else begin
                $display("[PASS] Circle perimeter boundary inclusion verified.");
            end

            // Test 3: Point just outside radius boundary (cx+R+1 = 196, cy=120)
            wait_pixel(9'd196, 9'd120);
            if (c1_valid !== 1'b0) begin
                $display("[FAIL] Point outside circle (cx+R+1) should be excluded! X=%0d Y=%0d valid=%b",
                         pixel_x, pixel_y, c1_valid);
                errors = errors + 1;
            end else begin
                $display("[PASS] Circle exterior exclusion verified.");
            end
        end
    endtask

    // -------------------------------------------------------------
    // Main Simulation Process
    // -------------------------------------------------------------
    integer ppm_file;
    integer pixels_captured;

    initial begin
        $dumpfile("sim/waveforms/tb_primitives.vcd");
        $dumpvars(0, tb_primitives);

        $display("==================================================");
        $display("  STARTING M3 PRIMITIVES VERIFICATION");
        $display("==================================================");

        // Object 1: Blue Rectangle
        r1_enable = 1;
        r1_x = 9'd30;
        r1_y = 9'd40;
        r1_w = 9'd60;
        r1_h = 9'd50;
        r1_color = 24'h2B6CB0; // Blue

        // Object 2: Green Rectangle clipping right and bottom edges
        r2_enable = 1;
        r2_x = 9'd270;
        r2_y = 9'd190;
        r2_w = 9'd70;  // 270 + 70 = 340 (clips at 320)
        r2_h = 9'd60;  // 190 + 60 = 250 (clips at 240)
        r2_color = 24'h38A169; // Green

        // Object 3: Amber Circle
        c1_enable = 1;
        c1_cx = 9'd160;
        c1_cy = 9'd120;
        c1_r  = 8'd35;
        c1_color = 24'hDD6B20; // Amber

        // Apply reset
        rst = 1;
        repeat (5) @(posedge clk);
        @(posedge clk);
        #1;
        rst = 0;

        // Run self-checking assertion tasks
        verify_rectangle_logic();
        verify_circle_logic();

        // Render full composite frame to PPM
        $display("[INFO] Rendering composite primitives frame to sim/output/frame_primitives.ppm...");
        ppm_file = $fopen("sim/output/frame_primitives.ppm", "w");
        $fwrite(ppm_file, "P3\n320 240\n255\n");

        while (!(frame_start == 1'b1)) @(posedge clk);

        pixels_captured = 0;
        while (pixels_captured < (320 * 240)) begin
            @(posedge clk);
            #1;
            if (active_video) begin
                $fwrite(ppm_file, "%0d %0d %0d\n", composite_rgb[23:16], composite_rgb[15:8], composite_rgb[7:0]);
                pixels_captured = pixels_captured + 1;
            end
        end
        $fclose(ppm_file);
        $display("[PASS] Captured %0d pixels to sim/output/frame_primitives.ppm.", pixels_captured);

        $display("==================================================");
        $display("  M3 PRIMITIVES VERIFICATION COMPLETE");
        $display("  Total Errors: %0d", errors);
        $display("==================================================");

        if (errors == 0) begin
            $display(">>> ALL M3 PRIMITIVES CHECKS PASSED <<<");
        end else begin
            $display(">>> M3 PRIMITIVES FAILED WITH %0d ERRORS <<<", errors);
        end

        $finish;
    end

endmodule
