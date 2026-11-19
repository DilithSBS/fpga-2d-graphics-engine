# FPGA-Based 2D Graphics Engine

A reusable, modular 2D graphics engine designed from scratch in synthesizable Verilog HDL (Verilog-2001) targeting FPGA platforms and simulated via native Windows tools.

## Overview

The engine renders 2D raster graphics on-the-fly (direct coordinate-based rendering without an initial framebuffer) at a resolution of 320 × 240 pixels with 24-bit RGB888 color output. The system architecture strictly decouples video raster timing, graphics rendering primitives and compositing, and application/game state logic.

## Key Specifications

* **Target Resolution**: 320 × 240 visible pixels.
* **Target Refresh Rate**: 60 FPS nominal.
* **Pixel Clock**: 6.288 MHz ($400 \times 262$ clocks per frame).
* **Color Depth**: RGB888 (24-bit true color: 8 bits Red, 8 bits Green, 8 bits Blue).
* **Sync Polarity**: Active-low HSYNC and VSYNC.
* **Rendering Architecture**: Real-time raster scanning, multi-layer compositing with 1-bit transparency, and fixed priority.

## Repository Structure

```text
fpga-2d-graphics-engine/
├── assets/             # Asset source files (e.g., sprite graphics, palettes)
│   └── sprites/
├── docs/               # Technical specifications and architectural records
│   ├── architecture.md
│   ├── decisions.md
│   ├── progress.md
│   ├── specification.md
│   └── verification.md
├── rtl/                # Synthesizable Verilog HDL source files
│   ├── game/           # Application and game state logic
│   ├── graphics/       # Shape renderers, background generator, layer compositor
│   ├── top/            # Top-level integration and simulation wrapper
│   └── video/          # Raster timing generator and sync logic
├── scripts/            # Helper automation scripts (Python, PowerShell)
├── sim/                # Simulation output artifacts and waveform dumps
│   ├── output/         # Rendered image outputs (PPM/PNG)
│   └── waveforms/      # VCD waveform dumps for GTKWave
└── tb/                 # Verification testbenches
    ├── integration/    # Subsystem and full-chip integration testbenches
    └── unit/           # Dedicated unit testbenches for each RTL module
```

## Prerequisites and Toolchain

* **OS**: Windows 11 (native PowerShell execution).
* **Simulator**: Icarus Verilog (`iverilog`, `vvp` v12.0+).
* **Waveform Viewer**: GTKWave.
* **Scripting / Image Inspection**: Python 3.x with `Pillow`.
* **Version Control**: Git.

## Simulation Quickstart

To run unit or integration simulations:
```powershell
# Compile with Icarus Verilog
iverilog -g2001 -o sim/tb_module.vvp rtl/... tb/...

# Execute simulation runtime
vvp sim/tb_module.vvp

# Open waveforms in GTKWave
gtkwave sim/waveforms/tb_module.vcd
```

