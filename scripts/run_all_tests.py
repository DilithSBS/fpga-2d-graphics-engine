"""
Automated Test Runner for FPGA 2D Graphics Engine
Compiles and executes all unit and integration testbenches using Icarus Verilog.
Reports pass/fail status and verification metrics.
"""

import os
import sys
import subprocess
import time

TESTS = [
    {
        "name": "Smoke Test (Toolchain)",
        "output": "sim/tb_smoke.vvp",
        "sources": ["tb/unit/tb_smoke.v"]
    },
    {
        "name": "M1: Raster Timing Generator",
        "output": "sim/tb_raster_timing.vvp",
        "sources": ["rtl/video/raster_timing.v", "tb/unit/tb_raster_timing.v"]
    },
    {
        "name": "M2: Background Generator",
        "output": "sim/tb_background.vvp",
        "sources": ["rtl/video/raster_timing.v", "rtl/graphics/background_gen.v", "tb/unit/tb_background.v"]
    },
    {
        "name": "M3: Graphics Primitives (Rect & Circle)",
        "output": "sim/tb_primitives.vvp",
        "sources": [
            "rtl/video/raster_timing.v",
            "rtl/graphics/background_gen.v",
            "rtl/graphics/rectangle_renderer.v",
            "rtl/graphics/circle_renderer.v",
            "tb/unit/tb_primitives.v"
        ]
    },
    {
        "name": "M4: Layer Compositor",
        "output": "sim/tb_compositor.vvp",
        "sources": [
            "rtl/video/raster_timing.v",
            "rtl/graphics/background_gen.v",
            "rtl/graphics/rectangle_renderer.v",
            "rtl/graphics/circle_renderer.v",
            "rtl/graphics/layer_compositor.v",
            "tb/unit/tb_compositor.v"
        ]
    },
    {
        "name": "M5: Sprite Renderer",
        "output": "sim/tb_sprite.vvp",
        "sources": [
            "rtl/video/raster_timing.v",
            "rtl/graphics/background_gen.v",
            "rtl/graphics/sprite_renderer.v",
            "tb/unit/tb_sprite.v"
        ]
    },
    {
        "name": "M6: Game Controller & Physics",
        "output": "sim/tb_game.vvp",
        "sources": [
            "rtl/video/raster_timing.v",
            "rtl/game/game_controller.v",
            "rtl/graphics/background_gen.v",
            "rtl/graphics/rectangle_renderer.v",
            "rtl/graphics/sprite_renderer.v",
            "rtl/graphics/layer_compositor.v",
            "tb/integration/tb_game.v"
        ]
    },
    {
        "name": "M7: Full-Chip Top-Level Integration",
        "output": "sim/tb_graphics_system.vvp",
        "sources": [
            "rtl/video/raster_timing.v",
            "rtl/graphics/background_gen.v",
            "rtl/graphics/rectangle_renderer.v",
            "rtl/graphics/circle_renderer.v",
            "rtl/graphics/sprite_renderer.v",
            "rtl/graphics/layer_compositor.v",
            "rtl/game/game_controller.v",
            "rtl/top/simulation_top.v",
            "tb/integration/tb_graphics_system.v"
        ]
    }
]

def run_tests():
    os.makedirs("sim/output", exist_ok=True)
    os.makedirs("sim/waveforms", exist_ok=True)

    print("=" * 72)
    print(" FPGA 2D GRAPHICS ENGINE - AUTOMATED REGRESSION TEST SUITE")
    print("=" * 72)

    passed_count = 0
    total_count = len(TESTS)
    start_total = time.time()

    for idx, test in enumerate(TESTS, 1):
        print(f"\n[{idx}/{total_count}] Compiling & Running: {test['name']}")
        
        # 1. Compile
        compile_cmd = ["iverilog", "-g2001", "-o", test["output"]] + test["sources"]
        c_proc = subprocess.run(compile_cmd, capture_output=True, text=True)
        if c_proc.returncode != 0:
            print(f"  --> COMPILE ERROR:")
            print(c_proc.stderr)
            continue

        # 2. Simulate
        s_proc = subprocess.run(["vvp", test["output"]], capture_output=True, text=True)
        output = s_proc.stdout + s_proc.stderr

        # Check for error indicators
        if "ERROR" in output or "FAIL" in output or "FAILED" in output or s_proc.returncode != 0:
            print(f"  --> SIMULATION FAILED")
            for line in output.strip().splitlines()[-10:]:
                print(f"      {line}")
        else:
            print(f"  --> PASSED (Zero errors)")
            passed_count += 1

    total_time = time.time() - start_total
    print("\n" + "=" * 72)
    print(f" TEST RESULTS SUMMARY: {passed_count}/{total_count} PASSED in {total_time:.2f}s")
    print("=" * 72)

    return passed_count == total_count

if __name__ == "__main__":
    success = run_tests()
    sys.exit(0 if success else 1)

