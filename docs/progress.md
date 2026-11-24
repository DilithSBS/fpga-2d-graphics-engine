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
* [ ] **M5: Sprite Rendering**
  * [ ] ROM-based sprite storage.
  * [ ] Sprite coordinate mapping, transparency, and bounding tests.
* [ ] **M6: Game Integration**
  * [ ] Generic game controller (`rtl/game/game_controller.v`).
  * [ ] Frame-synchronized state/position updates on VBlank.
  * [ ] Collision detection logic.
* [ ] **M7: Final Verification and Refinement**
  * [ ] Full-chip simulation and video sequence validation.
  * [ ] Timing analysis, code cleanup, and complete technical report.
