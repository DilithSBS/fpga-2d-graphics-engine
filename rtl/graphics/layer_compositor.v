module layer_compositor (
    input   wire            active_video,   // 1 - Active display, 0 - Blanking
    
    // Layer 0: Background
    input   wire    [23:0]  l0_rgb,

    // Layer 1: Foreground Object Slot 0
    input   wire    [23:0]  l1_rgb,
    input   wire            l1_valid,

    // Layer 2: Foreground Object Slot 1
    input   wire    [23:0]  l2_rgb,
    input   wire            l2_valid,

    // Layer 3: Foreground Object Slot 2
    input   wire    [23:0]  l3_rgb,
    input   wire            l3_valid,

    // Composite output
    output  reg     [23:0]  final_rgb

);

    // Priority Rules for each layer
    wire [23:0] selected_rgb = l3_valid ? l3_rgb
                             : l2_valid ? l2_rgb 
                             : l1_valid ? l1_rgb 
                             : l0_rgb; 

    // Output the final
    always @* begin
        if (active_video)   final_rgb = selected_rgb;
        else                final_rgb = 24'h000000;
    end




endmodule