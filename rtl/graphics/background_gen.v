module background_gen (
    input   wire    [8:0]   pixel_x,        // 0 to 319
    input   wire    [8:0]   pixel_y,        // 0 to 239
    input   wire            active_video,   // 1 when active video, 0 when blanking

    input   wire    [1:0]   bg_mode,     
    // 00: solid color
    // 01: vertical gradient
    // 10: horizontal gradient 
    // 11: checkerboard


    input   wire    [23:0]  solid_color,
    output  reg     [23:0]  rgb_out
);

    reg     [23:0]  color_solid;
    reg     [23:0]  color_bars;
    reg     [23:0]  color_checker;
    reg     [23:0]  color_gradient;

    
    always @* begin

        color_solid     = 24'h000000;
        color_bars      = 24'h000000;
        color_checker   = 24'h000000;
        color_gradient  = 24'h000000;
        rgb_out         = 24'h000000;
        
        if (!active_video) begin
            rgb_out = 24'h000000;
        end

        else if (bg_mode == 2'b00) begin
            color_solid = solid_color;
            rgb_out = color_solid;
        end

        else if (bg_mode == 2'b01) begin
            
            if      (pixel_x < 9'd40)  color_bars = 24'hFFFFFF; // White
            else if (pixel_x < 9'd80)  color_bars = 24'hFFFF00; // Yellow
            else if (pixel_x < 9'd120) color_bars = 24'h00FFFF; // Cyan
            else if (pixel_x < 9'd160) color_bars = 24'h00FF00; // Green
            else if (pixel_x < 9'd200) color_bars = 24'hFF00FF; // Magenta
            else if (pixel_x < 9'd240) color_bars = 24'hFF0000; // Red
            else if (pixel_x < 9'd280) color_bars = 24'h0000FF; // Blue
            else                       color_bars = 24'h000000; // Black 
            rgb_out = color_bars;
        end


        else if (bg_mode == 2'b10) begin
            color_checker = (pixel_x[5] ^ pixel_y[5]) ? 24'hCCCCCC : 24'h333333; // Light gray & dark gray
            rgb_out = color_checker;
        end

        else if (bg_mode == 2'b11) begin
            color_gradient = {pixel_x[7:0], pixel_y[7:0], 8'h80};
            rgb_out = color_gradient;
        end


    end
   


endmodule