# Verification Plan & Results: FPGA 2D Graphics Engine

**Revision**: 1.0  
**Verification Philosophy**: Self-checking testbenches, cycle-accurate timing assertions, and end-to-end visual frame rendering verification (PPM/PNG output).

---

## 1. Test Methodology

Every RTL module requires:
1. A dedicated self-checking unit testbench located in `tb/unit/`.
2. Cycle-accurate behavioral assertions evaluating reset conditions, corner cases, and boundary roll-overs.
3. Automated pass/fail tallies (`errors == 0`).
4. Output VCD waveform dumps stored under `sim/waveforms/` for debugging via GTKWave.
5. Visual rendering verification (for graphics modules) dumping full raster frames to `sim/output/*.ppm`.

---

## 2. Milestone Test Matrix

| Milestone | Module Under Test | Testbench File | Status | Verification Criteria |
| :--- | :--- | :--- | :--- | :--- |
| **M0** | Smoke Test (Toolchain) | `tb/unit/tb_smoke.v` | **PASSED** | Basic compilation, VVP simulation, VCD dump |
| **M1** | `raster_timing` | `tb/unit/tb_raster_timing.v` | **PASSED** | Exact 400 clocks/line, 262 lines/frame, sync pulse widths (HSYNC=48, VSYNC=800 clocks), active video window (320x240), blanking clamping (0 errors across 209,601 cycles) |
| **M2** | `background_gen` | `tb/unit/tb_background.v` | **PASSED** | Solid color, color bars, checkerboard, gradient patterns, 0 errors, visual frame dumps (76,800 px/frame) to PPM & PNG |
| **M3** | Shape Primitives | `tb/unit/tb_primitives.v` | **PASSED** | Rectangle & circle boundary inclusion/exclusion, edge clipping, half-open intervals, 0 errors, visual render to PPM & PNG |
| **M4** | `layer_compositor` | `tb/unit/tb_compositor.v` | Planned | 4-layer priority muxing, 1-bit transparency, blanking blank-out |
| **M5** | `sprite_renderer` | `tb/unit/tb_sprite.v` | Planned | ROM coordinate lookup, transparency masking, position off-screen |
| **M6** | `game_controller` | `tb/integration/tb_game.v` | Planned | VBlank-synchronized state update, motion, collision flags |
| **M7** | Full System Top | `tb/integration/tb_graphics_system.v` | Planned | End-to-end frame generation, multi-frame video sequence |

