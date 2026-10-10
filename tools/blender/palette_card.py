"""Seven painted swatches; test-only calibration geometry."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import bpy
import common as c
c.clean_scene()
material = c.vertex_material()
swatches = []
for index, colour in enumerate(("F7F1E6", "D99B87", "9FB4A0", "F28A52", "F5B53A", "3A3D48", "D8CFE6")):
    bpy.ops.mesh.primitive_cube_add(size=1, location=((index - 3) * 1.03, 0, .5))
    obj = bpy.context.object
    obj.name = "Swatch_" + colour
    obj.scale = (.85, .55, 1)
    c.bevel(obj, .075, 3)
    c.smooth(obj)
    obj.data.materials.append(material)
    c.bake_vertex_ao([obj], [obj], lambda _o, _p, col=colour: c.linear_rgb(col), strength=0, gradient=0)
    swatches.append(obj)
c.export_glb(swatches, "game/assets/models/p1a_palette_card.glb")
print("[PALETTE] seven swatches,", c.triangle_count(swatches), "test-only tris")
