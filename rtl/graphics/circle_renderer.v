module circle_renderer (
    // Raster beam coordinate inputs
    input   wire    [8:0]   pixel_x,       // Current beam X (0 to 319)
    input   wire    [8:0]   pixel_y,       // Current beam Y (0 to 239)
    input   wire            active_video,  // 1 = Active display, 0 = Blanking
    // Circle descriptor
    input   wire            enable,        // 1 = Render object, 0 = Disabled
    input   wire    [8:0]   center_x,      // Center X coordinate
    input   wire    [8:0]   center_y,      // Center Y coordinate
    input   wire    [7:0]   radius,        // Radius R in pixels (0 to 127)
    input   wire    [23:0]  circle_color,  // 24-bit RGB888 color
    // Layer output interface
    output  reg     [23:0]  pixel_rgb,
    output  reg             pixel_valid    // 1-bit transparency mask
);

    wire [8:0] diff_x = (pixel_x > center_x) ? (pixel_x - center_x) : (center_x - pixel_x);
    wire [8:0] diff_y = (pixel_y > center_y) ? (pixel_y - center_y) : (center_y - pixel_y);
    
    // Squared value wires
    wire [17:0] dx_sq = diff_x * diff_x;
    wire [17:0] dy_sq = diff_y * diff_y;
    wire [17:0] r_sq  = radius * radius;

    // 19 bits to hold the sum without overflow
    wire [18:0] dist_sq = {1'b0, dx_sq} + {1'b0, dy_sq};

    // Inclusion test
    wire in_circle = (dist_sq <= {1'b0, r_sq});

    always @* begin
        if (!active_video || !enable) begin
            pixel_valid = 1'b0;
            pixel_rgb   = 24'h000000;
        end 
        else if (in_circle) begin
            pixel_valid = 1'b1;
            pixel_rgb   = circle_color;
        end 
        else begin
            pixel_valid = 1'b0;
            pixel_rgb   = 24'h000000;
        end
    end
endmodule