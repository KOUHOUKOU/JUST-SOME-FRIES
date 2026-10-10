"""P0 only: 1 m rounded colour swatch with base-centre pivot."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bpy
import common as c

c.clean_scene()
bpy.ops.mesh.primitive_cube_add(size=1, location=(0, 0, 0.5))
cube = bpy.context.object
cube.name = "P0RoundedCube"
c.bevel(cube, 0.12, 3)
c.smooth(cube)
# Put the origin at the feet without moving the visible shape.
bpy.context.scene.cursor.location = (0, 0, 0)
bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
cube.data.materials.append(c.vertex_material())
bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, -0.002))
floor = bpy.context.object
floor.name = "BakeAndReviewGround_NOT_EXPORTED"
mat = bpy.data.materials.new("ReviewCream")
mat.diffuse_color = (*c.linear_rgb("DED6C7"), 1)
floor.data.materials.append(mat)
peach, sage = c.linear_rgb("D99B87"), c.linear_rgb("9FB4A0")
def palette(_obj, position):
    return peach.lerp(sage, max(0, min(1, position.x + 0.5)))
ao = c.bake_vertex_ao([cube], [cube, floor], palette)
tris = c.triangle_count([cube])
assert tris <= 200, tris
glb = c.export_glb([cube], "game/assets/models/p0_rounded_cube.glb")
review = c.render_turntable([cube], "art_src/p0/review", resolution=384, samples=8)
c.contact_sheet(review, "art_src/p0/review/contact_sheet.png")
c.output_path("art_src/p0/asset_stats.json").write_text(json.dumps({
    "blender": bpy.app.version_string, "triangles": tris, "materials": 1,
    "glb_bytes": glb.stat().st_size, "dimensions_m": list(cube.dimensions),
    "pivot": "base centre; Blender +Z -> glTF/Godot +Y", "ao": ao,
    "review": {"engine": "EEVEE", "samples": 8, "pixels": 384, "views": 5}
}, indent=2))
print(f"[P0] {tris} tris, 1 material, {glb.stat().st_size} bytes; AO={ao}")
