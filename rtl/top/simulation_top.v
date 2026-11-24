module simulation_top (
    input   wire        clk,
    input   wire        rst,

    // Player controls
    input   wire        btn_up,
    input   wire        btn_down,
    input   wire        btn_left,
    input   wire        btn_right,
    input   wire        btn_restart,

    // Video outputs
    output  wire        hsync,
    output  wire        vsync,
    output  wire        active_video,
    output  wire [23:0] rgb_out,

    // Game status
    output  wire        collision_detected,
    output  wire        game_over,
    output  wire [15:0] score
);

    // -------------------------------------------------------------
    // Internal Wires
    // -------------------------------------------------------------
    wire    [8:0]       pixel_x;
    wire    [8:0]       pixel_y;
    wire                line_start;
    wire                frame_start;
    wire                frame_end;

    wire    [8:0]       player_x;
    wire    [8:0]       player_y;
    wire                player_enable;

    wire    [8:0]       asteroid_x;
    wire    [8:0]       asteroid_y;
    wire                asteroid_enable;

    // Layer Buses
    wire    [23:0]      l0_rgb;

    wire    [23:0]      l1_rgb;
    wire                l1_valid;

    wire    [23:0]      l2_rgb;
    wire                l2_valid;

    wire    [23:0]      l3_rgb;
    wire                l3_valid;

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
    // Subsystem 2: Game Controller
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
    // Layer 0: Background (Deep Space Navy Blue)
    background_gen u_bg (
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .active_video(active_video),
        .bg_mode     (2'b00),
        .solid_color (24'h080C16),
        .rgb_out     (l0_rgb)
    );

    // Layer 1: Asteroid Sprite (ID = 1)
    sprite_renderer u_asteroid (
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .active_video(active_video),
        .sprite_id   (3'b001),
        .enable      (asteroid_enable),
        .sprite_x    (asteroid_x),
        .sprite_y    (asteroid_y),
        .pixel_rgb   (l1_rgb),
        .pixel_valid (l1_valid)
    );

    // Layer 2: Spacecraft Sprite (ID = 0)
    sprite_renderer u_spacecraft (
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .active_video(active_video),
        .sprite_id   (3'b000),
        .enable      (player_enable),
        .sprite_x    (player_x),
        .sprite_y    (player_y),
        .pixel_rgb   (l2_rgb),
        .pixel_valid (l2_valid)
    );

    // Layer 3: Shield / Circular Beacon around Player (Disabled initially)
    circle_renderer u_shield (
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .active_video(active_video),
        .enable      (1'b0), // Can be driven by a shield power-up
        .center_x    (player_x + 9'd8),
        .center_y    (player_y + 9'd8),
        .radius      (8'd12),
        .circle_color(24'h48BB78),
        .pixel_rgb   (l3_rgb),
        .pixel_valid (l3_valid)
    );

    // -------------------------------------------------------------
    // Subsystem 4: Multi-Layer Priority Compositor
    // -------------------------------------------------------------
    layer_compositor u_compositor (
        .active_video(active_video),
        .l0_rgb      (l0_rgb),
        .l1_rgb      (l1_rgb),
        .l1_valid    (l1_valid),
        .l2_rgb      (l2_rgb),
        .l2_valid    (l2_valid),
        .l3_rgb      (l3_rgb),
        .l3_valid    (l3_valid),
        .final_rgb   (rgb_out)
    );

endmodule