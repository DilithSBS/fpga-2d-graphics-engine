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
* [ ] **M2: Background & Pixel Output**
  * [ ] RGB888 pixel interface definition.
  * [ ] Solid colors, color bars, checkerboard generator (`rtl/graphics/background_gen.v`).
  * [ ] Frame rendering to PPM/PNG via Python script.
* [ ] **M3: Graphics Primitives**
  * [ ] Rectangle renderer (`rtl/graphics/rectangle_renderer.v`).
  * [ ] Circle renderer (`rtl/graphics/circle_renderer.v`).
  * [ ] Unit testbenches and boundary coverage.
* [ ] **M4: Layer Compositor**
  * [ ] 4-layer priority compositor (`rtl/graphics/layer_compositor.v`).
  * [ ] 1-bit transparency handling and blanking suppression.
  * [ ] Multi-layer integration testbench.
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
