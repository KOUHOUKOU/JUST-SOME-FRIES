"""Round 14: deterministic, low-cost Blender -> vertex-coloured GLB helpers.

Run generators with Blender --background --threads 4 --python ... .
Colours passed to bake_vertex_ao are linear RGB; use linear_rgb for hex swatches.
AO uses a finite-distance, cosine-weighted BVH hemisphere bake (no Cycles job).
Apply geometry modifiers BEFORE baking. Bake static contact only for moving parts.
"""
import math
from array import array
from pathlib import Path

import bpy
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT = Path(__file__).resolve().parents[2]


def output_path(path):
    path = (ROOT / path).resolve()
    allowed = [ROOT / p for p in ("art_src", "game", "tools/blender", "docs")]
    if not any(path.is_relative_to(p) for p in allowed):
        raise ValueError(f"Output outside authorised folders: {path}")
    path.parent.mkdir(parents=True, exist_ok=True)
    return path


def clean_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    # Only remove unused datablocks, never an external file.
    for blocks in (bpy.data.meshes, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for block in list(blocks):
            if block.users == 0:
                blocks.remove(block)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    scene.render.threads_mode = "FIXED"
    scene.render.threads = 4
    return scene


def activate(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def bevel(obj, width, segments=3):
    if segments not in (2, 3):
        raise ValueError("Review assets use 2 or 3 bevel segments")
    activate(obj)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    mod = obj.modifiers.new("SoftEdges", "BEVEL")
    mod.width, mod.segments = width, segments
    mod.affect = "EDGES"
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def smooth(obj, weighted=True):
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    if weighted:
        activate(obj)
        mod = obj.modifiers.new("WeightedNormals", "WEIGHTED_NORMAL")
        mod.keep_sharp = True
        mod.weight = 50
        bpy.ops.object.modifier_apply(modifier=mod.name)
    obj.data.update()


def linear_rgb(hex_colour):
    values = [int(hex_colour[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return Vector([v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in values])


def vertex_material(name="ClayVertex", attribute="Col"):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    material.node_tree.nodes.clear()
    bsdf = material.node_tree.nodes.new("ShaderNodeBsdfPrincipled")
    output = material.node_tree.nodes.new("ShaderNodeOutputMaterial")
    material.node_tree.links.new(bsdf.outputs["BSDF"], output.inputs["Surface"])
    bsdf.inputs["Roughness"].default_value = 0.92
    bsdf.inputs["Metallic"].default_value = 0.0
    colour = material.node_tree.nodes.new("ShaderNodeVertexColor")
    colour.layer_name = attribute
    material.node_tree.links.new(colour.outputs["Color"], bsdf.inputs["Base Color"])
    return material


def bake_vertex_ao(objects, occluders, colour, samples=32, distance=0.4,
                   strength=0.38, gradient=0.14, attribute="Col"):
    """Bake palette * height gradient * violet AO into CORNER float RGBA.

    colour(obj, world_position) returns linear RGB. Alpha stays 1 (opaque).
    Occluders must have applied modifiers; include receivers for self occlusion.
    Records real visibility statistics independently of the colour gradient.
    """
    if samples < 1 or distance <= 0:
        raise ValueError("AO samples and distance must be positive")
    vertices, triangles = [], []
    for obj in occluders:
        if obj.modifiers:
            raise ValueError(f"Apply modifiers before AO: {obj.name}")
        mesh = obj.data
        mesh.calc_loop_triangles()
        offset = len(vertices)
        vertices.extend(obj.matrix_world @ v.co for v in mesh.vertices)
        triangles.extend(tuple(offset + i for i in t.vertices) for t in mesh.loop_triangles)
    bvh = BVHTree.FromPolygons(vertices, triangles, all_triangles=True)
    world_points = [o.matrix_world @ v.co for o in objects for v in o.data.vertices]
    zlo, zhi = min(p.z for p in world_points), max(p.z for p in world_points)
    violet = Vector((0.70, 0.60, 0.82))
    summary = {}
    for obj in objects:
        mesh = obj.data
        previous = mesh.color_attributes.get(attribute)
        if previous:
            mesh.color_attributes.remove(previous)
        colours = mesh.color_attributes.new(name=attribute, type="FLOAT_COLOR", domain="CORNER")
        mesh.color_attributes.active_color = colours
        mesh.color_attributes.render_color_index = list(mesh.color_attributes).index(colours)
        normal_matrix = obj.matrix_world.to_3x3().inverted().transposed()
        occlusions = []
        cache = {}
        for loop in mesh.loops:
            position = obj.matrix_world @ mesh.vertices[loop.vertex_index].co
            normal = (normal_matrix @ mesh.corner_normals[loop.index].vector).normalized()
            key = (loop.vertex_index, tuple(round(v, 5) for v in normal))
            if key not in cache:
                tangent = normal.cross(Vector((0, 0, 1)) if abs(normal.z) < 0.9 else Vector((0, 1, 0))).normalized()
                bitangent = normal.cross(tangent)
                hits = 0
                for k in range(samples):
                    radius = math.sqrt((k + 0.5) / samples)
                    angle = k * math.pi * (3 - math.sqrt(5))
                    ray = tangent * (radius * math.cos(angle)) + bitangent * (radius * math.sin(angle)) + normal * math.sqrt(1 - radius * radius)
                    if bvh.ray_cast(position + normal * 0.001, ray, distance)[0] is not None:
                        hits += 1
                cache[key] = hits / samples
            ao = cache[key]
            occlusions.append(ao)
            height = (position.z - zlo) / max(zhi - zlo, 1e-6)
            base = Vector(colour(obj, position)) * (1 - gradient * (1 - height))
            tint = Vector((1, 1, 1)).lerp(violet * 0.55, ao * strength)
            colours.data[loop.index].color = (*[max(0, min(1, base[i] * tint[i])) for i in range(3)], 1)
        summary[obj.name] = {"occlusion_min": min(occlusions), "occlusion_max": max(occlusions),
                             "occlusion_mean": sum(occlusions) / len(occlusions), "samples": samples,
                             "ray_distance_m": distance, "colour_corners": len(colours.data)}
    return summary


def export_glb(objects, path, texcoords=False):
    path = output_path(path)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True,
                              export_yup=True, export_apply=True, export_normals=True,
                              export_texcoords=texcoords, export_materials="EXPORT",
                              export_all_vertex_colors=True, export_animations=False,
                              export_cameras=False, export_lights=False, export_extras=False)
    return path


def triangle_count(objects):
    for obj in objects:
        obj.data.calc_loop_triangles()
    return sum(len(obj.data.loop_triangles) for obj in objects)


def render_turntable(objects, folder, resolution=384, samples=8, framing=2.0):
    """One bounded review batch: four azimuths and top; no retry/render loop."""
    if not 1 <= resolution <= 512 or not 1 <= samples <= 16:
        raise ValueError("Review budget: <=512 px and <=16 EEVEE samples")
    folder = output_path(Path(folder) / "placeholder").parent
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.eevee.taa_render_samples = samples
    scene.render.resolution_x = scene.render.resolution_y = resolution
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.world = bpy.data.worlds.new("SoftSky")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes.clear()
    background = scene.world.node_tree.nodes.new("ShaderNodeBackground")
    output = scene.world.node_tree.nodes.new("ShaderNodeOutputWorld")
    scene.world.node_tree.links.new(background.outputs[0], output.inputs[0])
    background.inputs[0].default_value = (0.66, 0.74, 0.9, 1)
    background.inputs[1].default_value = 0.35
    points = [o.matrix_world @ Vector(p) for o in objects for p in o.bound_box]
    lo = Vector([min(p[i] for p in points) for i in range(3)])
    hi = Vector([max(p[i] for p in points) for i in range(3)])
    centre, extent = (hi + lo) * 0.5, max(hi - lo)
    lights = []
    for name, offset, energy, color in [
        ("WarmKey", (3, -4, 5), 400, (1, 0.83, 0.68)),
        ("SkyFill", (-3, -1, 3), 180, (0.72, 0.8, 1))]:
        data = bpy.data.lights.new(name, "AREA")
        data.energy, data.color, data.shape, data.size = energy * extent ** 2, color, "DISK", extent * 4
        obj = bpy.data.objects.new(name, data)
        scene.collection.objects.link(obj)
        obj.location = centre + Vector(offset) * extent
        obj.rotation_euler = (centre - obj.location).to_track_quat("-Z", "Y").to_euler()
        lights.append(obj)
    data = bpy.data.cameras.new("ReviewCamera")
    camera = bpy.data.objects.new("ReviewCamera", data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    data.type, data.ortho_scale = "ORTHO", extent * framing
    paths = []
    for index, angle in enumerate((45, 135, 225, 315, None)):
        if angle is None:
            camera.location = centre + Vector((0, -0.001, extent * 5))
        else:
            a = math.radians(angle)
            camera.location = centre + Vector((math.cos(a) * 4, math.sin(a) * 4, 2.5)) * extent
        camera.rotation_euler = (centre - camera.location).to_track_quat("-Z", "Y").to_euler()
        path = folder / ("top.png" if angle is None else f"angle_{angle:03d}.png")
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        paths.append(path)
    for obj in lights + [camera]:
        bpy.data.objects.remove(obj, do_unlink=True)
    return paths


def contact_sheet(paths, path, tile=170, columns=3):
    """Blender-native PNG composition; no Pillow/package dependency."""
    rows = math.ceil(len(paths) / columns)
    width, height = tile * columns, tile * rows
    if max(width, height) > 512:
        raise ValueError("Contact sheet must fit inside 512 px")
    pixels = array("f", (0.88, 0.85, 0.81, 1)) * (width * height)
    for index, source in enumerate(paths):
        img = bpy.data.images.load(str(source), check_existing=False)
        img.scale(tile, tile)
        data = array("f", [0]) * (tile * tile * 4)
        img.pixels.foreach_get(data)
        x, y = index % columns * tile, (rows - 1 - index // columns) * tile
        for row in range(tile):
            start = ((y + row) * width + x) * 4
            pixels[start:start + tile * 4] = data[row * tile * 4:(row + 1) * tile * 4]
        bpy.data.images.remove(img)
    sheet = bpy.data.images.new("ContactSheet", width, height, alpha=True)
    sheet.pixels.foreach_set(pixels)
    sheet.filepath_raw, sheet.file_format = str(output_path(path)), "PNG"
    sheet.save()
    bpy.data.images.remove(sheet)
