module raster_timing #(
    // Parameterized for flexibility and reusable testbench setups
    parameter       H_VISIBLE = 320,
    parameter       H_FRONT = 16,
    parameter       H_SYNC = 4,
    parameter       H_BACK = 16,
    parameter       H_TOTAL = 400,

    parameter       V_VISIBLE = 240,
    parameter       V_FRONT = 10,
    parameter       V_SYNC = 2,
    parameter       V_BACK = 10,
    parameter       V_TOTAL = 262

) (

    input wire          clk,
    input wire          rst,

    output reg          hsync,
    output reg          vsync,
    output reg          active_video,

    output reg  [8:0]   pixel_x;        // 0 - 319 pixels during active video == 1, and clamped to 0 in blanking
    output reg  [8:0]   pixel_y;        // 0 - 239 pixels during active video == 1, and clamped to 0 in blanking


    output  reg         line_start,     // 1-cycle pulse at the start of each line
    output  reg         frame_start,    // 1-cycle pulse at start of active frame
    output  reg         frame_end       // 1-cycle pulse at the end of the frame

);