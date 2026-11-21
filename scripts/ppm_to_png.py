"""
PPM to PNG Converter and Image Inspector
Converts all PPM files dumped by the simulation into PNG for easy viewing.
"""
import os
import glob
from PIL import Image

def convert_all_ppm(directory="sim/output"):
    ppm_files = glob.glob(os.path.join(directory, "*.ppm"))
    if not ppm_files:
        print(f"No PPM files found in {directory}")
        return

    print(f"Converting {len(ppm_files)} PPM files to PNG...")
    for ppm_path in ppm_files:
        png_path = os.path.splitext(ppm_path)[0] + ".png"
        try:
            with Image.open(ppm_path) as img:
                img.save(png_path, "PNG")
                print(f"  [OK] {ppm_path} -> {png_path} ({img.size[0]}x{img.size[1]})")
        except Exception as e:
            print(f"  [FAIL] Failed to convert {ppm_path}: {e}")

if __name__ == "__main__":
    convert_all_ppm()
