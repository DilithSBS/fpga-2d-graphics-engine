// tb_interactive.v: Interactive Co-Simulation Testbench for Hardware-in-the-Loop Play
`timescale 1ns / 1ps

module tb_interactive;

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

    integer cmd;
    integer pixels_in_frame;

    // -------------------------------------------------------------
    // Top-Level FPGA Design Under Test
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
    // Main Interactive Simulation Loop
    // -------------------------------------------------------------
    initial begin
        btn_up      = 1'b0;
        btn_down    = 1'b0;
        btn_left    = 1'b0;
        btn_right   = 1'b0;
        btn_restart = 1'b0;

        // Synchronous Reset
        rst = 1'b1;
        repeat (5) @(posedge clk);
        @(posedge clk);
        #1;
        rst = 1'b0;

        // Continuous Interactive Frame Stream
        while (1) begin
            // 1. Read single-byte input command from STDIN (32'h8000_0000)
            cmd = $fgetc(32'h8000_0000);
            if (cmd == -1 || cmd[7]) begin
                // EOF or Exit command received
                $finish;
            end

            // Unpack keymask:
            // bit 0: UP
            // bit 1: DOWN
            // bit 2: LEFT
            // bit 3: RIGHT
            // bit 4: RESTART
            btn_up      = cmd[0];
            btn_down    = cmd[1];
            btn_left    = cmd[2];
            btn_right   = cmd[3];
            btn_restart = cmd[4];

            // 2. Wait for active video display window to start
            while (active_video == 1'b1) @(posedge clk);
            while (active_video == 1'b0) @(posedge clk);

            // 3. Stream 76,800 RGB pixels (230,400 raw bytes) over STDOUT (32'h8000_0001)
            pixels_in_frame = 0;
            while (pixels_in_frame < (320 * 240)) begin
                @(posedge clk);
                #1;
                if (active_video) begin
                    $fwrite(32'h8000_0001, "%c%c%c", rgb_out[23:16], rgb_out[15:8], rgb_out[7:0]);
                    pixels_in_frame = pixels_in_frame + 1;
                end
            end

            // 4. Send 4-byte frame status footer: [collision, game_over, score_hi, score_lo]
            $fwrite(32'h8000_0001, "%c%c%c%c", 
                    collision_detected ? 8'd1 : 8'd0,
                    game_over          ? 8'd1 : 8'd0,
                    score[15:8],
                    score[7:0]);
            $fflush(32'h8000_0001);
        end
    end

endmodule
