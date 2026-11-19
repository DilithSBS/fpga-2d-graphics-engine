// tb_raster_timing.v: Self-checking unit testbench for raster_timing module
`timescale 1ns / 1ps

module tb_raster_timing;

    // -------------------------------------------------------------
    // Timing & Clock Configuration (6.288 MHz ~ 159.033 ns period)
    // -------------------------------------------------------------
    // Using 10 ns clock for fast simulation (timing ratios are cycle-based)
    localparam CLK_PERIOD = 20;

    localparam H_VISIBLE = 320;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 48;
    localparam H_BACK    = 16;
    localparam H_TOTAL   = 400;

    localparam V_VISIBLE = 240;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 10;
    localparam V_TOTAL   = 262;

    localparam FRAME_CLOCKS = H_TOTAL * V_TOTAL; // 104,800 clocks

    // -------------------------------------------------------------
    // DUT Signals
    // -------------------------------------------------------------
    reg        clk;
    reg        rst;

    wire       hsync;
    wire       vsync;
    wire       active_video;
    wire [8:0] pixel_x;
    wire [8:0] pixel_y;
    wire       line_start;
    wire       frame_start;
    wire       frame_end;

    // -------------------------------------------------------------
    // Verification Variables
    // -------------------------------------------------------------
    integer errors = 0;
    integer clock_count = 0;
    integer frame_clock_count = 0;
    integer frame_count = 0;

    integer hsync_low_clocks = 0;
    integer active_video_clocks_in_line = 0;
    integer active_video_lines_in_frame = 0;
    integer vsync_low_clocks = 0;

    reg prev_hsync;
    reg prev_vsync;
    reg prev_active_video;

    // -------------------------------------------------------------
    // Instantiate Device Under Test (DUT)
    // -------------------------------------------------------------
    raster_timing #(
        .H_VISIBLE(H_VISIBLE),
        .H_FRONT  (H_FRONT),
        .H_SYNC   (H_SYNC),
        .H_BACK   (H_BACK),
        .H_TOTAL  (H_TOTAL),

        .V_VISIBLE(V_VISIBLE),
        .V_FRONT  (V_FRONT),
        .V_SYNC   (V_SYNC),
        .V_BACK   (V_BACK),
        .V_TOTAL  (V_TOTAL)
    ) dut (
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
    // Clock Generation
    // -------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // -------------------------------------------------------------
    // Main Verification Process
    // -------------------------------------------------------------
    initial begin
        $dumpfile("sim/waveforms/tb_raster_timing.vcd");
        $dumpvars(0, tb_raster_timing);

        $display("==================================================");
        $display("  STARTING VERIFICATION: tb_raster_timing");
        $display("==================================================");

        // Test 1: Reset behavior
        rst = 1;
        repeat (5) @(posedge clk);
        #1; // Sample shortly after clock edge

        if (hsync !== 1'b1 || vsync !== 1'b1 || active_video !== 1'b0) begin
            $display("[FAIL] Time %0t: Reset outputs incorrect! hsync=%b, vsync=%b, active=%b",
                     $time, hsync, vsync, active_video);
            errors = errors + 1;
        end else begin
            $display("[PASS] Reset condition verified.");
        end

        // Release reset synchronously
        @(posedge clk);
        #1;
        rst = 0;

        // Run simulation for 2 full frames to observe steady state
        // 2 frames = 2 * 104,800 = 209,600 clock cycles
        while (frame_count < 2) begin
            @(posedge clk);
            #1; // Sample outputs

            clock_count = clock_count + 1;
            frame_clock_count = frame_clock_count + 1;

            // Track HSYNC pulse width
            if (hsync == 1'b0) begin
                hsync_low_clocks = hsync_low_clocks + 1;
            end else if (prev_hsync == 1'b0) begin
                // Rising edge of HSYNC: check pulse width
                if (hsync_low_clocks !== H_SYNC) begin
                    $display("[FAIL] Cycle %0d: HSYNC pulse width mismatch! Found: %0d, Expected: %0d",
                             clock_count, hsync_low_clocks, H_SYNC);
                    errors = errors + 1;
                end
                hsync_low_clocks = 0;
            end

            // Track VSYNC pulse width
            if (vsync == 1'b0) begin
                vsync_low_clocks = vsync_low_clocks + 1;
            end else if (prev_vsync == 1'b0) begin
                // Rising edge of VSYNC: check pulse width (V_SYNC * H_TOTAL clocks)
                if (vsync_low_clocks !== (V_SYNC * H_TOTAL)) begin
                    $display("[FAIL] Cycle %0d: VSYNC pulse width mismatch! Found: %0d, Expected: %0d",
                             clock_count, vsync_low_clocks, V_SYNC * H_TOTAL);
                    errors = errors + 1;
                end
                vsync_low_clocks = 0;
            end

            // Coordinate clamping check during blanking
            if (active_video == 1'b0) begin
                if (pixel_x !== 9'd0 || pixel_y !== 9'd0) begin
                    $display("[FAIL] Cycle %0d: Blanking coordinate leak! pixel_x=%0d, pixel_y=%0d during blanking (active_video=0)",
                             clock_count, pixel_x, pixel_y);
                    errors = errors + 1;
                end
            end else begin
                // Active video bounds check
                if (pixel_x >= H_VISIBLE || pixel_y >= V_VISIBLE) begin
                    $display("[FAIL] Cycle %0d: Active pixel out of range! pixel_x=%0d, pixel_y=%0d",
                             clock_count, pixel_x, pixel_y);
                    errors = errors + 1;
                end
            end

            // Detect start of new frame (via frame_start strobe or frame rollover)
            if (frame_start == 1'b1 && clock_count > 10) begin
                if (frame_count > 0) begin
                    if (frame_clock_count !== FRAME_CLOCKS) begin
                        $display("[FAIL] Frame %0d duration mismatch! Clocks: %0d, Expected: %0d",
                                 frame_count, frame_clock_count, FRAME_CLOCKS);
                        errors = errors + 1;
                    end else begin
                        $display("[PASS] Frame %0d timing verified: exactly %0d pixel clocks.",
                                 frame_count, frame_clock_count);
                    end
                end
                frame_clock_count = 0;
                frame_count = frame_count + 1;
            end

            prev_hsync = hsync;
            prev_vsync = vsync;
            prev_active_video = active_video;
        end

        // Final Report
        $display("==================================================");
        $display("  VERIFICATION COMPLETE");
        $display("  Total Clock Cycles Simulated: %0d", clock_count);
        $display("  Total Frames Simulated: %0d", frame_count);
        $display("  Total Verification Errors: %0d", errors);
        $display("==================================================");

        if (errors == 0) begin
            $display(">>> ALL M1 RASTER TIMING CHECKS PASSED <<<");
        end else begin
            $display(">>> M1 RASTER TIMING FAILED WITH %0d ERRORS <<<", errors);
        end

        $finish;
    end

endmodule

