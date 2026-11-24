module rectangle_renderer (

    // Raster beam coordinate inputs
    input   wire    [8:0]   pixel_x,    // Current beam x (0 to 319)
    input   wire    [8:0]   pixel_y,    // Current beam y (0 to 239)
    input   wire            active_video,

    // Rectangle Descriptor
    input   wire            enable,     // 1 - Render object, 0 - Disabled
    input   wire    [8:0]   rect_x,     // Upper-left corner X 
    input   wire    [8:0]   rect_y,     // Upper-left corner Y
    input   wire    [8:0]   rect_w,     // width in pixels
    input   wire    [8:0]   rect_h,     // height in pixels
    input   wire    [23:0]  rect_color,


    // Layer output interface
    output  reg     [23:0]  pixel_rgb,     // Pixel color
    output  reg             pixel_valid    // 1-bit transparency mask (1 = opaque, 0 = transparent)

);

    // -------------------------------------------------------------
    // Boundary Calculations (10-bit to prevent overflow wrap-around)
    // -------------------------------------------------------------

    wire [9:0] x_end = {1'b0, rect_x} + {1'b0, rect_w};
    wire [9:0] y_end = {1'b0, rect_y} + {1'b0, rect_h};

    wire in_x = ({1'b0, pixel_x} >= {1'b0, rect_x}) && ({1'b0, pixel_x} < x_end);
    wire in_y = ({1'b0, pixel_y} >= {1'b0, rect_y}) && ({1'b0, pixel_y} < y_end);


    // -------------------------------------------------------------
    // Output Multiplexing
    // -------------------------------------------------------------
   
    always @* begin
        if (!active_video || !enable) begin
        
            pixel_valid = 1'b0;
            pixel_rgb = 24'h000000;

        end
        else if (in_x && in_y) begin
            pixel_valid = 1'b1;
            pixel_rgb = rect_color;
        
        end
        else begin
            pixel_valid = 1'b0;
            pixel_rgb   = 24'h000000;
        end
    end


endmodule