# Technical Specification: FPGA 2D Graphics Engine

**Document Status**: Approved Baseline  
**Revision**: 1.0  
**Target HDL**: Verilog-2001 (Synthesizable RTL)

---

## 1. Video and Raster Timing Specification

The graphics engine implements a custom raster profile inspired by progressive VGA scanning. It targets a nominal 60 frames per second (FPS) at a 320 × 240 active resolution.

### 1.1 Resolution and Pixel Clock
* **Visible Resolution**: 320 (H) × 240 (V) pixels
* **Pixel Clock Frequency**: 6.288 MHz
* **Total Frame Clocks**: $400 \times 262 = 104,800$ clocks/frame
* **Calculated Frame Rate**: $6,288,000 / 104,800 \approx 60.00$ FPS
* **Pixel Format**: RGB888 (24 bits total: 8 bits Red, 8 bits Green, 8 bits Blue)

### 1.2 Horizontal Timing Breakdown
One horizontal line consists of exactly 400 pixel clock periods:

| Region | Duration (Clocks) | Counter Range (`h_count`) | Signal Behavior |
| :--- | :--- | :--- | :--- |
| **Visible Area** | 320 | `0` through `319` | `active_video = 1`, `pixel_x = h_count` |
| **Front Porch** | 16 | `320` through `335` | `active_video = 0`, `hsync = 1` |
| **Sync Pulse** | 48 | `336` through `383` | `hsync = 0` (Active-low pulse) |
| **Back Porch** | 16 | `384` through `399` | `hsync = 1` |
| **Total** | **400** | `0` through `399` | Rollover to `0` on clock 400 |

### 1.3 Vertical Timing Breakdown
One full frame consists of exactly 262 scan lines:

| Region | Duration (Lines) | Counter Range (`v_count`) | Signal Behavior |
| :--- | :--- | :--- | :--- |
| **Visible Area** | 240 | `0` through `239` | `active_video = 1` (when $H < 320$), `pixel_y = v_count` |
| **Front Porch** | 10 | `240` through `249` | `active_video = 0`, `vsync = 1` |
| **Sync Pulse** | 2 | `250` through `251` | `vsync = 0` (Active-low pulse) |
| **Back Porch** | 10 | `252` through `261` | `vsync = 1` |
| **Total** | **262** | `0` through `261` | Rollover to `0` on line 262 |

### 1.4 Active Video Conditions
The signal `active_video` indicates that the raster beam is within the visible display window:
$$\text{active\_video} = (h\_count < 320) \land (v\_count < 240)$$

During blanking (`active_video == 0`), coordinate outputs `pixel_x` and `pixel_y` are clamped to zero to prevent downstream memory address corruption and out-of-range evaluation.

---

## 2. Rendering Subsystem Specification

### 2.1 On-the-Fly Raster Rendering
* No framebuffer in Version 1.
* Output RGB color is determined combinatorially / pipelined synchronously on each clock tick based on current `(pixel_x, pixel_y)` coordinates.

### 2.2 Compositing Layers and Priority
The engine supports 4 compositing layers:
1. **Layer 0**: Background generator (solid colors, test bars, checkerboard, or procedural patterns).
2. **Layer 1**: Foreground Object Slot 0.
3. **Layer 2**: Foreground Object Slot 1.
4. **Layer 3**: Foreground Object Slot 2.

**Priority Rule**: Fixed priority where Layer 3 (topmost) > Layer 2 > Layer 1 > Layer 0 (background).

### 2.3 Transparency
Each foreground layer outputs:
* `[23:0] rgb_data`: 24-bit color.
* `pixel_valid`: 1-bit transparency indicator (`1` = opaque pixel, `0` = transparent/pass-through).

---

## 3. Subsystem Separation Rules

1. **Raster Timing Subsystem**: Sole owner of horizontal/vertical counters, active video generation, and sync pulses. Must contain zero game or shape logic.
2. **Graphics Rendering Subsystem**: Consumes coordinates and object configuration to produce composite RGB pixel data.
3. **Application / Game Controller**: Manages game state, physics, motion, and collision. Updates object descriptors during vertical blanking intervals (`frame_end`).
