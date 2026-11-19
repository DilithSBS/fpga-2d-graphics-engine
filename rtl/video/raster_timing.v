module raster_timing #(
    // Parameterized for flexibility and reusable testbench setups
    parameter       H_VISIBLE = 320,
    parameter       H_FRONT = 16,
    parameter       H_SYNC = 48,
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

    output reg  [8:0]   pixel_x,        // 0 - 319 pixels during active video == 1, and clamped to 0 in blanking
    output reg  [8:0]   pixel_y,        // 0 - 239 pixels during active video == 1, and clamped to 0 in blanking


    output  reg         line_start,     // 1-cycle pulse at the start of each line
    output  reg         frame_start,    // 1-cycle pulse at start of active frame
    output  reg         frame_end       // 1-cycle pulse at the end of the frame (v_count == 240)

);

    // -------------------------------------------------------------
    // Internal Counter Registers
    // -------------------------------------------------------------
    reg         [8:0]   h_cnt;
    reg         [8:0]   v_cnt;
    
    // -------------------------------------------------------------
    // Horizontal and Vertical Scan Counters
    // -------------------------------------------------------------
    always @(posedge clk) begin

        // Hosizontal Count Logic
        if (rst) begin
            h_cnt <= 9'd0;
            v_cnt <= 9'd0;
        end else begin
            if (h_cnt == H_TOTAL - 1) begin
                
                h_cnt <= 9'd0;
                
                if (v_cnt == V_TOTAL - 1) 
                    v_cnt <= 9'd0;
                else 
                    v_cnt <= v_cnt + 1'b1;
            end
            else 
                h_cnt <= h_cnt + 1'b1;
            
        end
    end


    // -------------------------------------------------------------
    // Registered Output Generation (ADR-003, Glitch-Free)
    // -------------------------------------------------------------
    always @(posedge clk) begin
        
        if (rst) begin
            hsync           <= 1'b1;
            vsync           <= 1'b1;
            active_video    <= 1'b0;
            pixel_x         <= 9'd0;
            pixel_y         <= 9'd0;
            line_start      <= 1'b0;
            frame_start     <= 1'b0;
            frame_end       <= 1'b0;
        end else begin
        // active-low pulse when counter is in [336,383]
        // Start: (H_VISIBLE + H_FRONT) = 320+16=336
        // End: (H_VISIBLE + H_FRONT + H_SYNC - 1) = 320+16+48−1=383
        hsync <= !((h_cnt >= (H_VISIBLE + H_FRONT)) && (h_cnt <= (H_VISIBLE + H_FRONT + H_SYNC - 1)));

        // active-low pulse when counter is in [250,251]
        // Start: (V_VISIBLE + V_FRONT) = 240+10=250
        // End: (V_VISIBLE + V_FRONT + V_SYNC - 1) = 240+10+2−1=251
        vsync <= !((v_cnt >= (V_VISIBLE + V_FRONT)) && (v_cnt <= (V_VISIBLE + V_FRONT + V_SYNC - 1)));

        // active video flag
        active_video <= (h_cnt < H_VISIBLE) && (v_cnt < V_VISIBLE);
        
        // Coordinates with Blanking Clamping (ADR-004)
        if ((h_cnt < H_VISIBLE) && (v_cnt < V_VISIBLE)) begin
            pixel_x <= h_cnt;
            pixel_y <= v_cnt;
        end

        else begin
            pixel_x <= 9'b0;
            pixel_y <= 9'b0;
        end

        // Single-cycle Event Strobes
        line_start  <= (h_cnt == 9'd0);
        frame_start <= (h_cnt == 9'd0 && v_cnt == 9'd0);
        frame_end   <= (h_cnt == 9'd0 && v_cnt == V_VISIBLE);


    end
end

endmodule