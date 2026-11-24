module sprite_renderer #(
    parameter   SPRITE_W = 16,
    parameter   SPRITE_H = 16
) (
    
    // Raster beam coordinate inputs
    input   wire    [8:0]   pixel_x,        // Current beam X (0 to 319)
    input   wire    [8:0]   pixel_y,        // Current beam Y (0 to 239)
    input   wire            active_video,   // 1 = Active display, 0 = Blanking

    // Sprite descriptor
    input   wire            enable,         // 1 = Render sprite, 0 = Disabled
    input   wire    [8:0]   sprite_x,       // Upper-left corner X
    input   wire    [8:0]   sprite_y,       // Upper-left corner Y
    
    // Layer output interface
    output  reg     [23:0]  pixel_rgb,
    output  reg             pixel_valid

);

    // Sprite Boundary
    wire [9:0] x_end = {1'b0, sprite_x} + 10'd16;
    wire [9:0] y_end = {1'b0, sprite_y} + 10'd16;

    // In-sprite check
    wire in_sprite  =  ({1'b0, pixel_x} >= {1'b0, sprite_x}) && ({1'b0, pixel_x} < x_end) 
                    && ({1'b0, pixel_y} >= {1'b0, sprite_y}) && ({1'b0, pixel_y} < y_end);
    

    // Sprite pixel coordinates
    wire [3:0] dx = pixel_x[3:0] - sprite_x[3:0];
    wire [3:0] dy = pixel_y[3:0] - sprite_y[3:0];

    reg [31:0] rom_row;

    always @* begin
        case (dy)
            4'd0:  rom_row = 32'h0001_4000; // . . . . . . . 1 1 . . . . . . .
            4'd1:  rom_row = 32'h0007_D000; // . . . . . . 1 3 3 1 . . . . . .
            4'd2:  rom_row = 32'h0007_D000; // . . . . . . 1 3 3 1 . . . . . .
            4'd3:  rom_row = 32'h001B_E400; // . . . . . 1 2 3 3 2 1 . . . . .
            4'd4:  rom_row = 32'h001A_A400; // . . . . . 1 2 2 2 2 1 . . . . .
            4'd5:  rom_row = 32'h006A_A900; // . . . . 1 2 2 2 2 2 2 1 . . . .
            4'd6:  rom_row = 32'h006A_A900; // . . . . 1 2 2 2 2 2 2 1 . . . .
            4'd7:  rom_row = 32'h01A5_5A40; // . . . 1 2 2 1 1 1 1 2 2 1 . . .
            4'd8:  rom_row = 32'h0690_0690; // . . 1 2 2 1 . . . . 1 2 2 1 . .
            4'd9:  rom_row = 32'h1690_01A4; // . 1 2 2 1 . . . . . . 1 2 2 1 .
            4'd10: rom_row = 32'h6A90_01A9; // 1 2 2 2 1 . . . . . . 1 2 2 2 1
            4'd11: rom_row = 32'h6A95_56A9; // 1 2 2 2 2 1 1 1 1 1 1 2 2 2 2 1
            4'd12: rom_row = 32'h556A_A955; // 1 1 1 1 1 2 2 2 2 2 2 1 1 1 1 1
            4'd13: rom_row = 32'h005F_F500; // . . . . 1 1 3 3 3 3 1 1 . . . .
            4'd14: rom_row = 32'h001F_F400; // . . . . . 1 3 3 3 3 1 . . . . .
            4'd15: rom_row = 32'h0007_D000; // . . . . . . 1 3 3 1 . . . . . .
            default: rom_row = 32'h0000_0000;
        endcase
    end

    // Extract 2-bit pixel from ROM row 
    wire [1:0] sprite_pixel = (rom_row >> ((4'd15 - dx) * 2)) & 2'b11;    

    // Output multiplexer
    always @* begin
        if (!active_video || !enable || !in_sprite || (sprite_pixel == 2'b00)) begin
            pixel_valid = 1'b0;
            pixel_rgb   = 24'h000000;
        end else begin
            pixel_valid = 1'b1;
            case (sprite_pixel)
                2'b01:   pixel_rgb = 24'h1A202C; // Dark Outline
                2'b10:   pixel_rgb = 24'h00D8D6; // Cyan Hull
                2'b11:   pixel_rgb = 24'hFF6B6B; // Orange Flame / Cockpit
                default: pixel_rgb = 24'h000000;
            endcase
        end
    end

    


endmodule