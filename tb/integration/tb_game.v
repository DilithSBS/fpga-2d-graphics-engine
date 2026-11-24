// tb_game.v: Comprehensive integration testbench for game_controller and graphics pipeline
`timescale 1ns / 1ps

module tb_game;

    localparam CLK_PERIOD = 20;

    reg clk;
    reg rst;

    // Player inputs
    reg btn_up;
    reg btn_down;
    reg btn_left;
    reg btn_right;
    reg btn_restart;

    // Raster timing wires
    wire       hsync;
    wire       vsync;
    wire       active_video;
    wire [8:0] pixel_x;
    wire [8:0] pixel_y;
    wire       line_start;
    wire       frame_start;
    wire       frame_end;

    // Game controller outputs
    wire [8:0]  player_x;
    wire [8:0]  player_y;
    wire        player_enable;

    wire [8:0]  asteroid_x;
    wire [8:0]  asteroid_y;
    wire        asteroid_enable;

    wire        collision_detected;
    wire        game_over;
    wire [15:0] score;

    // Graphics pipeline wires
    wire [23:0] bg_rgb;
    wire [23:0] player_rgb;
    wire        player_valid;
    wire [23:0] asteroid_rgb;
    wire        asteroid_valid;
    wire [23:0] final_rgb;

    integer errors = 0;
    integer ppm_file;
    integer pixels_captured;

    // -------------------------------------------------------------
    // Subsystem 1: Raster Timing Generator
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

    // -------------------------------------------------------------
    // Subsystem 2: Game Controller Under Test
    // -------------------------------------------------------------
    game_controller u_game (
        .clk               (clk),
        .rst               (rst),
        .frame_end         (frame_end),
        .btn_up            (btn_up),
        .btn_down          (btn_down),
        .btn_left          (btn_left),
        .btn_right         (btn_right),
        .btn_restart       (btn_restart),
        .player_x          (player_x),
        .player_y          (player_y),
        .player_enable     (player_enable),
        .asteroid_x        (asteroid_x),
        .asteroid_y        (asteroid_y),
        .asteroid_enable   (asteroid_enable),
        .collision_detected(collision_detected),
        .game_over         (game_over),
        .score             (score)
    );

    // -------------------------------------------------------------
    // Subsystem 3: Graphics Rendering Engine
    // -------------------------------------------------------------
    // Layer 0: Space Background
    background_gen u_bg (
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .active_video(active_video),
        .bg_mode     (2'b00), // Solid Deep Space Navy Blue
        .solid_color (24'h080C16),
        .rgb_out     (bg_rgb)
    );

    // Layer 1: Asteroid Sprite (ID = 1)
    sprite_renderer u_sprite_asteroid (
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .active_video(active_video),
        .sprite_id   (3'b001), // Asteroid
        .enable      (asteroid_enable),
        .sprite_x    (asteroid_x),
        .sprite_y    (asteroid_y),
        .pixel_rgb   (asteroid_rgb),
        .pixel_valid (asteroid_valid)
    );

    // Layer 2: Player Spacecraft Sprite (ID = 0, Topmost)
    sprite_renderer u_sprite_player (
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .active_video(active_video),
        .sprite_id   (3'b000), // Spacecraft
        .enable      (player_enable),
        .sprite_x    (player_x),
        .sprite_y    (player_y),
        .pixel_rgb   (player_rgb),
        .pixel_valid (player_valid)
    );

    // 4-Layer Priority Compositor
    layer_compositor u_compositor (
        .active_video(active_video),
        .l0_rgb      (bg_rgb),
        .l1_rgb      (asteroid_rgb),
        .l1_valid    (asteroid_valid),
        .l2_rgb      (player_rgb),
        .l2_valid    (player_valid),
        .l3_rgb      (24'h000000), // Unused L3 slot
        .l3_valid    (1'b0),
        .final_rgb   (final_rgb)
    );

    // Clock Generation
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // -------------------------------------------------------------
    // Task: Capture a full visual frame to PPM
    // -------------------------------------------------------------
    task capture_game_frame;
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
                while (!(frame_start == 1'b1)) @(posedge clk);
                captured = 0;
                while (captured < (320 * 240)) begin
                    @(posedge clk);
                    #1;
                    if (active_video) begin
                        $fwrite(file, "%0d %0d %0d\n", final_rgb[23:16], final_rgb[15:8], final_rgb[7:0]);
                        captured = captured + 1;
                    end
                end
                $fclose(file);
                $display("[PASS] Rendered %0s (%0d pixels).", filename, captured);
            end
        end
    endtask

    // -------------------------------------------------------------
    // Verification Procedures
    // -------------------------------------------------------------
    initial begin
        $dumpfile("sim/waveforms/tb_game.vcd");
        $dumpvars(0, tb_game);

        $display("==================================================");
        $display("  STARTING M6 GAME INTEGRATION VERIFICATION");
        $display("==================================================");

        btn_up = 0;
        btn_down = 0;
        btn_left = 0;
        btn_right = 0;
        btn_restart = 0;

        // Apply reset
        rst = 1;
        repeat (5) @(posedge clk);
        @(posedge clk);
        #1;
        rst = 0;

        // Assertion 1: Check Reset Positions
        if (player_x !== 9'd40 || player_y !== 9'd112 || score !== 16'd0 || game_over !== 1'b0) begin
            $display("[FAIL] Game reset state mismatch! player=(%0d,%0d), score=%0d, game_over=%b",
                     player_x, player_y, score, game_over);
            errors = errors + 1;
        end else begin
            $display("[PASS] Initial game state verified: player=(40,112), score=0, game_over=0.");
        end

        // Capture Frame 1: Initial starting positions
        capture_game_frame("sim/output/game_frame_start.ppm");

        // Assertion 2: Player Movement (Move Right for 5 frames)
        $display("[TEST] Applying btn_right = 1 for 5 frames...");
        btn_right = 1;
        repeat (5) begin
            while (!(frame_end == 1'b1)) @(posedge clk);
            @(posedge clk);
            #1;
        end
        btn_right = 0;

        // In 5 frames at 2 px/frame, player_x should be 40 + 10 = 50
        if (player_x !== 9'd50) begin
            $display("[FAIL] Player right motion mismatch! Expected X=50, Found X=%0d", player_x);
            errors = errors + 1;
        end else begin
            $display("[PASS] Player right motion verified: X=%0d after 5 frames.", player_x);
        end

        // Assertion 3: Score Accumulation
        if (score !== 16'd6) begin
            $display("[FAIL] Score mismatch! Found=%0d, Expected=6", score);
            errors = errors + 1;
        end else begin
            $display("[PASS] Survival score increment verified: score=%0d.", score);
        end

        // Capture Frame 2: Mid-game with player displaced and asteroid moving
        capture_game_frame("sim/output/game_frame_moving.ppm");

        // Assertion 4: Collision Detection
        // Force player directly onto asteroid position to test collision detection
        $display("[TEST] Testing Collision Detection (aligning player with asteroid)...");
        btn_restart = 1;
        repeat (2) @(posedge clk);
        #1;
        btn_restart = 0;

        // Wait for next frame
        while (!(frame_end == 1'b1)) @(posedge clk);
        @(posedge clk);
        #1;

        // Manually steer player into collision
        // In initial reset: player=(40,112), asteroid=(240,40)
        // Steer player rapidly across 100 frames until collision occurs
        while (!collision_detected && score < 200) begin
            if (player_x < asteroid_x) btn_right = 1; else btn_right = 0;
            if (player_x > asteroid_x) btn_left = 1;  else btn_left = 0;
            if (player_y < asteroid_y) btn_down = 1;  else btn_down = 0;
            if (player_y > asteroid_y) btn_up = 1;    else btn_up = 0;

            while (!(frame_end == 1'b1)) @(posedge clk);
            @(posedge clk);
            #1;
        end

        btn_right = 0; btn_left = 0; btn_down = 0; btn_up = 0;

        if (!collision_detected) begin
            $display("[FAIL] Collision was not triggered during pursuit!");
            errors = errors + 1;
        end else begin
            $display("[PASS] Hardware collision detected at player=(%0d,%0d), asteroid=(%0d,%0d)!",
                     player_x, player_y, asteroid_x, asteroid_y);
        end

        // Wait 1 more frame for game_over register to update
        while (!(frame_end == 1'b1)) @(posedge clk);
        @(posedge clk);
        #1;

        if (game_over !== 1'b1) begin
            $display("[FAIL] game_over register was not asserted after collision!");
            errors = errors + 1;
        end else begin
            $display("[PASS] game_over state asserted successfully.");
        end

        // Capture Frame 3: Collision scene
        capture_game_frame("sim/output/game_frame_collision.ppm");

        $display("==================================================");
        $display("  M6 GAME INTEGRATION VERIFICATION COMPLETE");
        $display("  Total Errors: %0d", errors);
        $display("==================================================");

        if (errors == 0) begin
            $display(">>> ALL M6 GAME INTEGRATION CHECKS PASSED <<<");
        end else begin
            $display(">>> M6 GAME INTEGRATION FAILED WITH %0d ERRORS <<<", errors);
        end

        $finish;
    end

endmodule

