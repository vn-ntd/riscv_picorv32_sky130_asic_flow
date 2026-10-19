#!/usr/bin/env python3
"""
Automated Layout Export Script for PicoRV32 on SkyWater 130nm
Supports both:
  1. KLayout execution: klayout -z -r scripts/export_layout_image.py
  2. Standalone Python: python scripts/export_layout_image.py (uses matplotlib to parse DEF)
"""

import os
import sys

output_path = os.path.abspath("docs/images/layout.png")
os.makedirs(os.path.dirname(output_path), exist_ok=True)

try:
    import pya
    # KLayout engine mode
    layout_path = os.path.abspath("results/picorv32.gds")
    if not os.path.exists(layout_path) and os.path.exists("results/picorv32.gds.gz"):
        import gzip, shutil
        with gzip.open("results/picorv32.gds.gz", "rb") as f_in, open(layout_path, "wb") as f_out:
            shutil.copyfileobj(f_in, f_out)

    lyp_path = os.path.expanduser("~/.ciel/sky130A/libs.tech/klayout/tech/sky130A.lyp")
    app = pya.Application.instance()
    mw = app.main_window()
    view = mw.load_layout(layout_path, 0)
    if os.path.exists(lyp_path):
        view.load_layer_props(lyp_path)
    view.zoom_fit()
    view.save_image(output_path, 2048, 2048)
    print(f"[SUCCESS] Exported high-resolution GDSII render via KLayout to: {output_path}")
    app.exit(0)

except ImportError:
    # Standalone Python mode via Matplotlib & DEF parsing
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    import matplotlib.patches as patches

    def_path = os.path.abspath("results/picorv32.def")
    if not os.path.exists(def_path):
        print(f"[ERROR] DEF file not found at {def_path}")
        sys.exit(1)

    die_x, die_y = 395410, 406130
    core_llx, core_lly = 5520, 10880
    core_urx, core_ury = 389620, 395080

    fig, ax = plt.subplots(figsize=(10, 10), dpi=300)
    fig.patch.set_facecolor('#0b0e14')
    ax.set_facecolor('#0b0e14')

    ax.add_patch(patches.Rectangle((0, 0), die_x/1000, die_y/1000, edgecolor='#3b4252', facecolor='#151821', lw=1.5, label='Die Boundary (0.1606 mm²)'))
    ax.add_patch(patches.Rectangle((core_llx/1000, core_lly/1000), (core_urx-core_llx)/1000, (core_ury-core_lly)/1000, edgecolor='#88c0d0', facecolor='#1e222d', lw=1.2, linestyle='--', label='Active Core (147,310 µm²)'))

    x_logic, y_logic = [], []
    x_clk, y_clk = [], []
    x_decap, y_decap = [], []
    x_tap, y_tap = [], []
    x_diode, y_diode = [], []

    with open(def_path, 'r') as f:
        in_comp = False
        for line in f:
            if line.startswith('COMPONENTS'):
                in_comp = True
                continue
            if line.startswith('END COMPONENTS'):
                break
            if in_comp and line.strip().startswith('-'):
                parts = line.strip().split()
                if len(parts) >= 8:
                    model = parts[2]
                    try:
                        pt_idx = parts.index('(')
                        x = float(parts[pt_idx+1]) / 1000.0
                        y = float(parts[pt_idx+2]) / 1000.0
                        if 'clkbuf' in model:
                            x_clk.append(x); y_clk.append(y)
                        elif 'decap' in model:
                            x_decap.append(x); y_decap.append(y)
                        elif 'tap' in model:
                            x_tap.append(x); y_tap.append(y)
                        elif 'diode' in model:
                            x_diode.append(x); y_diode.append(y)
                        elif 'fill' not in model:
                            x_logic.append(x); y_logic.append(y)
                    except Exception:
                        pass

    ax.scatter(x_logic, y_logic, s=0.8, color='#5e81ac', alpha=0.5, label=f'Standard Logic ({len(x_logic):,} cells)')
    ax.scatter(x_decap, y_decap, s=0.8, color='#b48ead', alpha=0.5, label=f'Decap Cells ({len(x_decap):,})')
    ax.scatter(x_tap, y_tap, s=0.8, color='#ebcb8b', alpha=0.4, label=f'Welltap Cells ({len(x_tap):,})')
    ax.scatter(x_diode, y_diode, s=4.0, color='#bf616a', alpha=0.9, label=f'Antenna Diodes ({len(x_diode):,})')
    ax.scatter(x_clk, y_clk, s=8.0, color='#a3be8c', marker='^', alpha=1.0, label=f'CTS Clock Buffers ({len(x_clk):,})')

    ax.set_xlim(-10, die_x/1000 + 10)
    ax.set_ylim(-10, die_y/1000 + 10)
    ax.set_aspect('equal')
    ax.set_title('PicoRV32 RISC-V Core — Physical Placement & Floorplan (SkyWater 130nm)', color='#eceff4', fontsize=12, pad=12)
    ax.set_xlabel('Width (µm)', color='#d8dee9', fontsize=10)
    ax.set_ylabel('Height (µm)', color='#d8dee9', fontsize=10)
    ax.tick_params(colors='#d8dee9', labelsize=8)

    for spine in ax.spines.values():
        spine.set_color('#4c566a')

    legend = ax.legend(loc='upper right', facecolor='#1e222d', edgecolor='#4c566a', fontsize=7)
    for text in legend.get_texts():
        text.set_color('#eceff4')

    plt.tight_layout()
    plt.savefig(output_path, dpi=300)
    print(f"[SUCCESS] Exported high-resolution floorplan layout render to: {output_path}")
