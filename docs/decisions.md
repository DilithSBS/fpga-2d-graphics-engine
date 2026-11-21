# Architecture Decision Records (ADR)

This document tracks all formal architectural and technical design decisions, trade-offs evaluated, and rationale.

---

## ADR-001: Synchronous Active-High Reset Strategy
* **Date**: 2026-11-18
* **Status**: Approved
* **Context**: Need a unified reset methodology across all synthesizable RTL modules.
* **Decision**: Standardize on synchronous active-high reset (`rst`).
* **Rationale**:
  1. Modern FPGA architectures (AMD/Xilinx 7-Series, Lattice iCE40/ECP5, Gowin) have dedicated synchronous set/reset control inputs in logic slice flip-flops.
  2. Eliminates asynchronous reset glitching, recovery, and removal timing violation hazards.
  3. Simplifies simulation scheduling and prevents race conditions in testbenches.

---

## ADR-002: Direct On-The-Fly Rendering (No Framebuffer in V1)
* **Date**: 2026-11-18
* **Status**: Approved
* **Context**: 320 × 240 pixels at RGB888 requires $320 \times 240 \times 3 = 230,400$ bytes ($\approx 225\text{ KB}$) of RAM. Many mid-tier FPGAs do not have sufficient on-chip Block RAM for a full 24-bit uncompressed frame buffer without external SDRAM/DDR controllers.
* **Decision**: Compute pixel colors on-the-fly based on real-time raster coordinates $(X, Y)$ and object bounding boxes.
* **Rationale**:
  1. Extremely resource-efficient: fits into small, cost-effective FPGAs with minimal BRAM usage.
  2. Zero latency: no frame buffer read/write arbitration or memory bandwidth bottlenecks.
  3. Framebuffer support can be added as a future extension (Milestone M7+) if complex scene graph or multi-pass effects are needed.

---

## ADR-003: Registered Outputs for Raster Timing Generator
* **Date**: 2026-11-18
* **Status**: Approved
* **Context**: Video synchronization and coordinate outputs can be decoded combinationally or registered synchronously.
* **Decision**: Register all timing outputs (`hsync`, `vsync`, `active_video`, `pixel_x`, `pixel_y`) at the module boundary.
* **Rationale**:
  1. Combinational decodes can generate glitches during multi-bit counter switching.
  2. Registered outputs guarantee clean signal transitions, meeting setup/hold timing at output pins.
  3. All downstream rendering logic receives aligned, glitch-free coordinates.

---

## ADR-004: Coordinate Clamping During Blanking
* **Date**: 2026-11-18
* **Status**: Approved
* **Context**: During blanking intervals (front porch, sync, back porch), raw counters exceed visible ranges ($X \ge 320$, $Y \ge 240$).
* **Decision**: Explicitly clamp `pixel_x = 0` and `pixel_y = 0` whenever `active_video == 0`.
* **Rationale**:
  Prevents downstream graphics rendering modules from addressing invalid memory or triggering spurious hit-tests during blanking.

---

## ADR-005: Combinational Rendering for Primitives and Compositor
* **Date**: 2026-11-20
* **Status**: Approved
* **Context**: Pixel renderers (`background_gen`, `rectangle_renderer`, `circle_renderer`) and `layer_compositor` can either be pipelined registers (adding 1 cycle latency per stage) or pure combinational logic.
* **Decision**: Implement rendering primitives and the layer compositor as combinational modules (`always @*`), with optional registration at the top-level display output interface.
* **Rationale**:
  1. **Zero Pipeline Skew**: Rendering decisions execute in 0 clock cycles relative to `pixel_x`, `pixel_y`, and `active_video`. No matched delay pipelines are required for `hsync` and `vsync`.
  2. **Timing Margin**: At our target pixel clock of 6.288 MHz, the clock period is $\approx 159.03\text{ ns}$. Combinational logic paths for boundary comparisons and priority multiplexing take $< 6\text{ ns}$, leaving $> 150\text{ ns}$ of timing slack.
  3. **Simplicity and Modularity**: Individual renderers remain purely stateless functions of current coordinates and configuration registers.

