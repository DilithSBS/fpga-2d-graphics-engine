"""
GTKWave Automated Waveform Screenshot & GTKW Session Generator
Captures high-resolution waveform screenshots from simulation VCD files and
generates pre-configured .gtkw session files for one-click inspection in GTKWave.
"""

import os
import subprocess
import time
from PIL import Image

JOBS = [
    {
        "name": "Raster Timing Generator",
        "vcd": "sim/waveforms/tb_raster_timing.vcd",
        "gtkw": "sim/waveforms/tb_raster_timing.gtkw",
        "png": "docs/images/waveform_raster_timing.png",
        "signals": [
            "tb_raster_timing.clk",
            "tb_raster_timing.rst",
            "tb_raster_timing.dut.h_cnt[8:0]",
            "tb_raster_timing.dut.v_cnt[8:0]",
            "tb_raster_timing.active_video",
            "tb_raster_timing.hsync",
            "tb_raster_timing.vsync",
            "tb_raster_timing.pixel_x[8:0]",
            "tb_raster_timing.pixel_y[7:0]",
            "tb_raster_timing.line_start",
            "tb_raster_timing.frame_end"
        ],
        "zoom": "gtkwave::setZoomRangeTimes 0 70000000"
    },
    {
        "name": "Layer Compositor Priority & Transparency",
        "vcd": "sim/waveforms/tb_compositor.vcd",
        "gtkw": "sim/waveforms/tb_compositor.gtkw",
        "png": "docs/images/waveform_compositor.png",
        "signals": [
            "tb_compositor.clk",
            "tb_compositor.active_video",
            "tb_compositor.pixel_x[8:0]",
            "tb_compositor.pixel_y[7:0]",
            "tb_compositor.dut_comp_standalone.l3_valid",
            "tb_compositor.dut_comp_standalone.l3_rgb[23:0]",
            "tb_compositor.dut_comp_standalone.l2_valid",
            "tb_compositor.dut_comp_standalone.l2_rgb[23:0]",
            "tb_compositor.dut_comp_standalone.l1_valid",
            "tb_compositor.dut_comp_standalone.l1_rgb[23:0]",
            "tb_compositor.dut_comp_standalone.l0_rgb[23:0]",
            "tb_compositor.dut_comp_standalone.final_rgb[23:0]"
        ],
        "zoom": "gtkwave::setZoomRangeTimes 0 50000"
    },
    {
        "name": "Full-Chip Top-Level Graphics System",
        "vcd": "sim/waveforms/tb_graphics_system.vcd",
        "gtkw": "sim/waveforms/tb_graphics_system.gtkw",
        "png": "docs/images/waveform_graphics_system.png",
        "signals": [
            "tb_graphics_system.clk",
            "tb_graphics_system.rst",
            "tb_graphics_system.hsync",
            "tb_graphics_system.vsync",
            "tb_graphics_system.active_video",
            "tb_graphics_system.pixel_x[8:0]",
            "tb_graphics_system.pixel_y[7:0]",
            "tb_graphics_system.rgb_out[23:0]"
        ],
        "zoom": "gtkwave::setZoomRangeTimes 0 70000000"
    }
]

def generate_gtkw(job):
    """Write standard GTKWave save file (.gtkw)"""
    lines = [
        "[*] GTKWave Analyzer Save File",
        f"[*]{time.ctime()}",
        "[dumpfile] \"" + os.path.abspath(job["vcd"]).replace("\\", "/") + "\"",
        "[savefile] \"" + os.path.abspath(job["gtkw"]).replace("\\", "/") + "\"",
        "[timestart] 0",
        "[size] 1280 720",
        "[pos] -1 -1",
        "*-16.000000 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1",
        "[treeopen] tb_raster_timing.",
        "[treeopen] tb_compositor.",
        "[treeopen] tb_graphics_system.",
    ]
    for s in job["signals"]:
        lines.append(f"@28\n{s}")
    with open(job["gtkw"], "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"  [SAVED] {job['gtkw']}")

def capture_job(job):
    vcd = job["vcd"]
    png = job["png"]
    if not os.path.exists(vcd):
        print(f"Skipping {job['name']}: {vcd} not found.")
        return False

    print(f"\nProcessing Waveform: {job['name']}...")
    generate_gtkw(job)

    # Remove any existing output png before starting
    if os.path.exists(png):
        try:
            os.remove(png)
        except Exception:
            pass

    # Format Tcl script with escaped brackets
    tcl_sigs_list = []
    for s in job["signals"]:
        escaped_s = s.replace("[", "\\[").replace("]", "\\]")
        tcl_sigs_list.append(f'"{escaped_s}"')
    tcl_sigs = " ".join(tcl_sigs_list)

    tcl_content = f"""
set sigs [list {tcl_sigs}]
gtkwave::addSignalsFromList $sigs
{job["zoom"]}
catch {{gtkwave::/File/Grab_To_File "{png}"}}
"""
    tcl_path = f"sim/temp_grab_{int(time.time()*1000)%10000}.tcl"
    with open(tcl_path, "w") as f:
        f.write(tcl_content)

    t0 = time.time()
    p = subprocess.Popen(["gtkwave", "-d", vcd, "-S", tcl_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    # Poll for file creation up to 25 seconds
    captured = False
    for _ in range(50):
        time.sleep(0.5)
        if os.path.exists(png) and os.path.getsize(png) > 1000:
            time.sleep(0.5)  # ensure file is fully flushed
            captured = True
            break
        if p.poll() is not None:
            break

    try:
        p.terminate()
        p.wait(timeout=2)
    except Exception:
        pass

    if os.path.exists(tcl_path):
        try:
            os.remove(tcl_path)
        except Exception:
            pass

    if captured and os.path.exists(png) and os.path.getsize(png) > 1000:
        with Image.open(png) as img:
            print(f"  [SCREENSHOT OK] {png} ({img.size[0]}x{img.size[1]}, {os.path.getsize(png):,} bytes, in {time.time()-t0:.2f}s)")
        return True
    else:
        print(f"  [SCREENSHOT FAILED] {png}")
        return False

def main():
    print("=" * 68)
    print(" GTKWAVE AUTOMATED WAVEFORM SCREENSHOT & SESSION GENERATOR")
    print("=" * 68)
    success = 0
    for j in JOBS:
        if capture_job(j):
            success += 1
    print("\n" + "=" * 68)
    print(f" Successfully generated {success}/{len(JOBS)} waveform screenshots & GTKW sessions.")
    print("=" * 68)

if __name__ == "__main__":
    main()
