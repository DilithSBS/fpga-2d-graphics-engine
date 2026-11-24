module game_controller (
    input   wire        clk,
    input   wire        rst,
    input   wire        frame_end,  // 60 Hz vertical blanking pulse
    
    // player control buttons (active-high)
    input   wire        btn_up,
    input   wire        btn_down,
    input   wire        btn_left,
    input   wire        btn_right,
    input   wire        btn_restart,

    // Spacecraft Descriptor outputs (to sprite_renderer #1)
    // Spacecraft Descriptor Outputs (to sprite_renderer #1)
    output  reg     [8:0]   player_x,
    output  reg     [8:0]   player_y,
    output  reg             player_enable,

    // Asteroid Descriptor Outputs (to sprite_renderer #2)
    output  reg     [8:0]   asteroid_x,
    output  reg     [8:0]   asteroid_y,
    output  reg             asteroid_enable,
    
    // Game Status Outputs
    output  wire            collision_detected,
    output  reg             game_over,
    output  reg     [15:0]  score    

);

    // Asteroid direction state (0 = positive, 1 = negative)
    reg ast_dir_x;
    reg ast_dir_y;

    // -------------------------------------------------------------
    // Combinational AABB Collision Detection
    // -------------------------------------------------------------
    assign collision_detected = (player_enable && asteroid_enable) &&
                                (player_x < asteroid_x + 9'd16) && 
                                (player_x + 9'd16 > asteroid_x) &&
                                (player_y < asteroid_y + 9'd16) && 
                                (player_y + 9'd16 > asteroid_y);

    always @(posedge clk) begin
        if (rst || btn_restart) begin
            
            // Reset player to center-left
            player_x        <= 9'd40;
            player_y        <= 9'd112;
            player_enable   <= 1'b1;

            // Reset asteroid to top-right
            asteroid_x      <= 9'd240;
            asteroid_y      <= 9'd40;
            asteroid_enable <= 1'b1;
            ast_dir_x       <= 1'b1;    // Start moving left
            ast_dir_y       <= 1'b0;    // Start moving down
            game_over       <= 1'b0;
            score           <= 16'd0;
            
        end 
        else if (frame_end) begin
        
        // Check collision
        if (collision_detected) begin
                game_over <= 1'b1;
            end
            // Only update physics and score while alive
            if (!game_over && !collision_detected) begin
                
                // 1. Increment survival score
                score <= score + 16'd1;
                
                // 2. Player Motion & Screen Boundary Clamping
                if (btn_left && (player_x >= 9'd2))
                    player_x <= player_x - 9'd2;
                else if (btn_right && (player_x <= 9'd302))
                    player_x <= player_x + 9'd2;
                
                if (btn_up && (player_y >= 9'd2))
                    player_y <= player_y - 9'd2;
                else if (btn_down && (player_y <= 9'd222))
                    player_y <= player_y + 9'd2;
                
                // 3. Asteroid Horizontal Bouncing Physics (speed = 2 px/frame)
                if (!ast_dir_x) begin
                    if (asteroid_x >= 9'd302) begin
                        ast_dir_x  <= 1'b1; // Bounce left
                        asteroid_x <= asteroid_x - 9'd2;
                    end 
                    else begin
                        asteroid_x <= asteroid_x + 9'd2;
                    end
                
                end 
                else begin
                    if (asteroid_x <= 9'd2) begin
                        ast_dir_x  <= 1'b0; // Bounce right
                        asteroid_x <= asteroid_x + 9'd2;
                    end 
                    else begin
                        asteroid_x <= asteroid_x - 9'd2;
                    end
                end
                
                // 4. Asteroid Vertical Bouncing Physics (speed = 1 px/frame)
                if (!ast_dir_y) begin
                    if (asteroid_y >= 9'd222) begin
                        ast_dir_y  <= 1'b1; // Bounce up
                        asteroid_y <= asteroid_y - 9'd1;
                    end 
                    else begin
                        asteroid_y <= asteroid_y + 9'd1;
                    end
                end
                
                else begin
                    if (asteroid_y <= 9'd2) begin
                        ast_dir_y  <= 1'b0; // Bounce down
                        asteroid_y <= asteroid_y + 9'd1;
                    end 
                    else begin
                        asteroid_y <= asteroid_y - 9'd1;
                    end
                end
            end
        end
    end

endmodule