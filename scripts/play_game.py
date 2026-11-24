"""
FPGA 2D Graphics Engine - Interactive Desktop Arcade
Hardware-in-the-Loop Co-Simulation with Icarus Verilog

Run this script to interactively play your synthesizable Verilog game
using your keyboard in real time!

Controls:
  Arrow Keys / WASD : Move Spacecraft
  R                 : Restart Game after Collision
  ESC               : Quit
"""

import sys
import os
import subprocess
import threading
import time
import tkinter as tk
from PIL import Image, ImageTk

WIDTH = 320
HEIGHT = 240
SCALE = 2  # Scaled to 640x480 for crisp retro viewing
FRAME_BYTES = WIDTH * HEIGHT * 3

class FPGAInteractiveGame:
    def __init__(self, root):
        self.root = root
        self.root.title("FPGA 2D Graphics Engine - Spacecraft Evasion (Hardware Co-Sim)")
        self.root.resizable(False, False)
        self.root.configure(bg="#050811")

        # Key state flags (bitmask)
        # bit 0: UP, bit 1: DOWN, bit 2: LEFT, bit 3: RIGHT, bit 4: RESTART
        self.keys = {
            "up": False,
            "down": False,
            "left": False,
            "right": False,
            "restart": False
        }

        # Status labels
        self.info_frame = tk.Frame(root, bg="#0A0E1A", padx=10, pady=5)
        self.info_frame.pack(fill=tk.X)

        self.lbl_title = tk.Label(
            self.info_frame, 
            text="FPGA 2D GRAPHICS ENGINE [VERILOG HARDWARE CO-SIM]", 
            font=("Consolas", 10, "bold"), 
            fg="#00D8D6", 
            bg="#0A0E1A"
        )
        self.lbl_title.pack(side=tk.LEFT)

        self.lbl_score = tk.Label(
            self.info_frame, 
            text="SCORE: 0  |  STATUS: ACTIVE", 
            font=("Consolas", 11, "bold"), 
            fg="#FFD700", 
            bg="#0A0E1A"
        )
        self.lbl_score.pack(side=tk.RIGHT)

        # Canvas for video rendering
        self.canvas = tk.Canvas(
            root, 
            width=WIDTH * SCALE, 
            height=HEIGHT * SCALE, 
            bg="black", 
            highlightthickness=0
        )
        self.canvas.pack()

        # Footer controls help
        self.lbl_help = tk.Label(
            root, 
            text="Controls: Arrow Keys / WASD to Steer  |  R to Restart  |  ESC to Quit", 
            font=("Consolas", 9), 
            fg="#718096", 
            bg="#050811", 
            pady=4
        )
        self.lbl_help.pack()

        # Keyboard event bindings
        root.bind("<KeyPress>", self.on_key_press)
        root.bind("<KeyRelease>", self.on_key_release)
        root.protocol("WM_DELETE_WINDOW", self.on_close)

        # Image display handle
        self.photo = None
        self.image_id = None
        self.running = True

        # Compile and spawn Verilog simulation
        self.ensure_compiled()
        self.start_simulator()

        # Start simulation receiver thread
        self.sim_thread = threading.Thread(target=self.sim_loop, daemon=True)
        self.sim_thread.start()

    def ensure_compiled(self):
        vvp_path = "sim/tb_interactive.vvp"
        sources = [
            "rtl/video/raster_timing.v",
            "rtl/graphics/background_gen.v",
            "rtl/graphics/sprite_renderer.v",
            "rtl/graphics/circle_renderer.v",
            "rtl/graphics/rectangle_renderer.v",
            "rtl/graphics/layer_compositor.v",
            "rtl/game/game_controller.v",
            "rtl/top/simulation_top.v",
            "tb/integration/tb_interactive.v"
        ]

        # Check if vvp needs compilation
        needs_compile = not os.path.exists(vvp_path)
        if not needs_compile:
            vvp_mtime = os.path.getmtime(vvp_path)
            for src in sources:
                if os.path.getmtime(src) > vvp_mtime:
                    needs_compile = True
                    break

        if needs_compile:
            print("[INFO] Compiling interactive Verilog hardware model with Icarus Verilog...")
            cmd = ["iverilog", "-g2001", "-o", vvp_path] + sources
            res = subprocess.run(cmd)
            if res.returncode != 0:
                print("[ERROR] Compilation failed!")
                sys.exit(1)
            print("[OK] Interactive hardware model compiled successfully.")

    def start_simulator(self):
        cmd = ["vvp", "sim/tb_interactive.vvp"]
        self.proc = subprocess.Popen(
            cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            bufsize=0
        )
        print("[OK] Verilog hardware simulator process spawned.")

    def on_key_press(self, event):
        k = event.keysym.lower()
        if k in ("up", "w"):
            self.keys["up"] = True
        elif k in ("down", "s"):
            self.keys["down"] = True
        elif k in ("left", "a"):
            self.keys["left"] = True
        elif k in ("right", "d"):
            self.keys["right"] = True
        elif k == "r":
            self.keys["restart"] = True
        elif k == "escape":
            self.on_close()

    def on_key_release(self, event):
        k = event.keysym.lower()
        if k in ("up", "w"):
            self.keys["up"] = False
        elif k in ("down", "s"):
            self.keys["down"] = False
        elif k in ("left", "a"):
            self.keys["left"] = False
        elif k in ("right", "d"):
            self.keys["right"] = False
        elif k == "r":
            self.keys["restart"] = False

    def get_key_mask(self):
        mask = 0
        if self.keys["up"]:      mask |= (1 << 0)
        if self.keys["down"]:    mask |= (1 << 1)
        if self.keys["left"]:    mask |= (1 << 2)
        if self.keys["right"]:   mask |= (1 << 3)
        if self.keys["restart"]: mask |= (1 << 4)
        return mask

    def sim_loop(self):
        frame_time_accum = 0
        frames_rendered = 0
        start_time = time.time()

        while self.running and self.proc.poll() is None:
            mask = self.get_key_mask()
            try:
                # 1. Send 1-byte key state to Verilog simulation over STDIN
                self.proc.stdin.write(bytes([mask]))
                self.proc.stdin.flush()

                # 2. Read 230,400 image bytes (320 * 240 * 3) from STDOUT
                raw_pixels = bytearray()
                while len(raw_pixels) < FRAME_BYTES and self.running:
                    chunk = self.proc.stdout.read(FRAME_BYTES - len(raw_pixels))
                    if not chunk:
                        return
                    raw_pixels.extend(chunk)

                # 3. Read 4-byte status footer: [collision, game_over, score_hi, score_lo]
                status_bytes = bytearray()
                while len(status_bytes) < 4 and self.running:
                    chunk = self.proc.stdout.read(4 - len(status_bytes))
                    if not chunk:
                        return
                    status_bytes.extend(chunk)

                if not self.running:
                    break

                collision = status_bytes[0]
                game_over = status_bytes[1]
                score = (status_bytes[2] << 8) | status_bytes[3]

                # Convert raw pixels into a PIL Image and scale 2x
                img = Image.frombytes("RGB", (WIDTH, HEIGHT), bytes(raw_pixels))
                img_scaled = img.resize((WIDTH * SCALE, HEIGHT * SCALE), Image.NEAREST)

                # Queue update onto Tkinter main GUI thread
                self.root.after(0, self.update_display, img_scaled, score, game_over, collision)

                frames_rendered += 1
            except Exception as e:
                break

    def update_display(self, img, score, game_over, collision):
        if not self.running:
            return

        self.photo = ImageTk.PhotoImage(img)
        if self.image_id is None:
            self.image_id = self.canvas.create_image(0, 0, anchor=tk.NW, image=self.photo)
        else:
            self.canvas.itemconfig(self.image_id, image=self.photo)

        # Update HUD telemetry
        if game_over:
            self.lbl_score.config(
                text=f"SCORE: {score}  |  STATUS: GAME OVER! (Press 'R' to Restart)",
                fg="#FF4D4D"
            )
        elif collision:
            self.lbl_score.config(
                text=f"SCORE: {score}  |  STATUS: COLLISION DETECTED!",
                fg="#FF9F43"
            )
        else:
            self.lbl_score.config(
                text=f"SCORE: {score}  |  STATUS: ACTIVE",
                fg="#2ECC71"
            )

    def on_close(self):
        self.running = False
        try:
            if self.proc and self.proc.poll() is None:
                # Send exit command (0x80)
                self.proc.stdin.write(bytes([0x80]))
                self.proc.stdin.flush()
                self.proc.terminate()
        except:
            pass
        self.root.destroy()

def main():
    root = tk.Tk()
    app = FPGAInteractiveGame(root)
    root.mainloop()

if __name__ == "__main__":
    main()
