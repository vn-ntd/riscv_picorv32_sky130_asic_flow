# Python script to export high-resolution layout images using KLayout
# Run inside Ubuntu: klayout -z -r scripts/export_layout_image.py

import os
import pya

layout_path = os.path.abspath("results/picorv32.gds")
lyp_path = os.path.expanduser("~/.ciel/sky130A/libs.tech/klayout/tech/sky130A.lyp")
output_path = os.path.abspath("docs/images/layout.png")

os.makedirs("docs/images", exist_ok=True)

app = pya.Application.instance()
mw = app.main_window()
view = mw.load_layout(layout_path, 0)

if os.path.exists(lyp_path):
    view.load_layer_props(lyp_path)

view.zoom_fit()
view.save_image(output_path, 2048, 2048)
print(f"[SUCCESS] Exported high-resolution GDSII render to: {output_path}")
app.exit(0)
