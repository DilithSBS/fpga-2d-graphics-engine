# Project Progress Tracker

## Milestone Overview

* [x] **M0: Development Environment & Toolchain Verification**
  * [x] Environment inspection (iverilog, vvp, gtkwave, python, git).
  * [x] Git repository initialization & `.gitignore`.
  * [x] Repository directory layout verification.
  * [x] Project baseline documentation scaffolded.
  * [x] Minimal smoke test verification (iverilog compilation + vvp execution + VCD generation).
* [x] **M1: Raster Timing Generator**
  * [x] Architecture and interface definition.
  * [x] Implementation of `rtl/video/raster_timing.v`.
  * [x] Self-checking unit testbench `tb/unit/tb_raster_timing.v`.
  * [x] Waveform verification in GTKWave (`sim/waveforms/tb_raster_timing.vcd`).
* [x] **M2: Background & Pixel Output**
  * [x] RGB888 pixel interface definition.
  * [x] Solid colors, color bars, checkerboard generator (`rtl/graphics/background_gen.v`).
  * [x] Frame rendering to PPM/PNG via Python script (`sim/output/*.png`).
* [x] **M3: Graphics Primitives**
  * [x] Rectangle renderer (`rtl/graphics/rectangle_renderer.v`).
  * [x] Circle renderer (`rtl/graphics/circle_renderer.v`).
  * [x] Unit testbenches and boundary coverage (`tb/unit/tb_primitives.v`).
  * [x] Visual rendering verification (`sim/output/frame_primitives.png`).
* [x] **M4: Layer Compositor**
  * [x] 4-layer priority compositor (`rtl/graphics/layer_compositor.v`).
  * [x] 1-bit transparency handling and blanking suppression.
  * [x] Multi-layer integration testbench (`tb/unit/tb_compositor.v`).
  * [x] Overlapping layers visual verification (`sim/output/frame_compositor.png`).
* [x] **M5: Sprite Rendering**
  * [x] ROM-based sprite storage (16x16 2-bit indexed spacecraft).
  * [x] Sprite coordinate mapping, transparency, and bounding tests.
  * [x] Dedicated unit testbench (`tb/unit/tb_sprite.v`).
  * [x] Visual sprite render (`sim/output/frame_sprite.png`).
* [x] **M6: Game Integration**
  * [x] Generic game controller (`rtl/game/game_controller.v`).
  * [x] Frame-synchronized state/position updates on VBlank.
  * [x] Player directional control and boundary clamping.
  * [x] Asteroid bouncing physics.
  * [x] Real-time hardware AABB collision detection.
  * [x] Integration testbench (`tb/integration/tb_game.v`).
  * [x] Visual gameplay sequence rendering (`sim/output/game_frame_*.png`).
* [x] **M7: Final Verification and Refinement**
  * [x] Top-level synthesizable system wrapper (`rtl/top/simulation_top.v`).
  * [x] End-to-end system integration testbench (`tb/integration/tb_graphics_system.v`).
  * [x] Complete chip frame rendering (`sim/output/top_system_frame.png`).
  * [x] Full architectural and verification documentation finalized.
  * [ ] Full-chip simulation and video sequence validation.
  * [ ] Timing analysis, code cleanup, and complete technical report.
