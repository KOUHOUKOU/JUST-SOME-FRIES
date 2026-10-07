extends RefCounted
# A sky you can read: crisp low-poly clouds (flat-shaded heaps with a blue-grey belly) that drift across the town at 70-135 m, and a real sun disc
# with a corona and rays (it is also the thing the "CATCH THE SUN" quest asks for). Both used to be blurry gradient quads.

const CLOUD_SHADER = """
shader_type spatial;
render_mode cull_back, diffuse_lambert;
uniform vec4 top_col : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 bottom_col : source_color = vec4(0.74, 0.82, 0.93, 1.0);
uniform float glow = 0.42;
varying float up;
void vertex() {
	up = (MODEL_MATRIX * vec4(NORMAL, 0.0)).y;
}
void fragment() {
	float k = smoothstep(-0.55, 0.65, up);
	ALBEDO = mix(bottom_col.rgb, top_col.rgb, k);
	EMISSION = ALBEDO * glow;
	ROUGHNESS = 1.0;
}
"""

static var _unit = null

# a flat-shaded unit sphere: every facet has its own normal, so the clouds read as crisp, stylised heaps
static func unit_blob():
	if _unit == null:
		var sm = SphereMesh.new()
		sm.radius = 1.0
		sm.height = 2.0
		sm.radial_segments = 9
		sm.rings = 5
		var st = SurfaceTool.new()
		st.create_from(sm, 0)
		st.deindex()
		st.generate_normals()
		_unit = st.commit()
	return _unit

# one cloud: a heap of blobs along a spine, flat underneath. size ~ the width in metres
static func cloud_mesh(rng, size):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n = rng.randi_range(6, 10)
	for i in n:
		var u = (float(i) / float(n - 1)) * 2.0 - 1.0          # -1 .. 1 along the cloud
		var r = size * rng.randf_range(0.16, 0.26) * (1.0 - 0.45 * abs(u))
		var pos = Vector3(u * size * 0.46 + rng.randf_range(-0.04, 0.04) * size, rng.randf_range(0.0, 0.14) * size * (1.0 - abs(u)), rng.randf_range(-0.14, 0.14) * size)
		var xf = Transform3D(Basis.from_scale(Vector3(r * 1.15, r * 0.72, r)), pos + Vector3(0, r * 0.3, 0))
		st.append_from(unit_blob(), 0, xf)
	return st.commit()

static func cloud_material():
	var sh = Shader.new()
	sh.code = CLOUD_SHADER
	var m = ShaderMaterial.new()
	m.shader = sh
	return m

# the drifting field of clouds. Returns {"mat": material, "node": the node that drifts them}
static func build_clouds(parent, rng, avoid = []):
	var mat = cloud_material()
	var holder = Node3D.new()
	holder.name = "Clouds"
	holder.set_script(load("res://scripts/world/cloud_drift.gd"))
	parent.add_child(holder)
	var made = 0
	var tries = 0
	while made < 26 and tries < 200:
		tries += 1
		var pos = Vector3(rng.randf_range(-300, 300), rng.randf_range(72, 138), rng.randf_range(-220, 300))
		var bad = false
		for a in avoid:
			if Vector2(pos.x, pos.z).distance_to(Vector2(a.x, a.z)) < 60.0 and abs(pos.y - a.y) < 40.0:
				bad = true
		if bad:
			continue
		var size = rng.randf_range(26.0, 62.0)
		var mi = MeshInstance3D.new()
		mi.mesh = cloud_mesh(rng, size)
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = pos
		mi.rotation.y = rng.randf_range(0.0, TAU)
		mi.set_meta("drift", rng.randf_range(0.8, 2.2))
		holder.add_child(mi)
		made += 1
	# a low bank of big clouds near the horizon: the town sits under a big sky
	for i in 14:
		var a = rng.randf_range(0.0, TAU)
		var dist = rng.randf_range(520.0, 760.0)
		var size2 = rng.randf_range(120.0, 220.0)
		var mi2 = MeshInstance3D.new()
		mi2.mesh = cloud_mesh(rng, size2)
		mi2.material_override = mat
		mi2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi2.position = Vector3(cos(a) * dist, rng.randf_range(35, 90), sin(a) * dist - 40.0)
		mi2.rotation.y = rng.randf_range(0.0, TAU)
		holder.add_child(mi2)
	return {"mat": mat, "node": holder}

# the sun: a disc with a corona and rays that always faces the camera
static func build_sun(parent):
	var root = Node3D.new()
	root.name = "SunDisc"
	parent.add_child(root)
	var core = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 9.0
	sm.height = 18.0
	sm.radial_segments = 20
	sm.rings = 10
	core.mesh = sm
	var cm = StandardMaterial3D.new()
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cm.albedo_color = Color(1.0, 0.95, 0.72)
	core.material_override = cm
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(core)
	var soft = preload("res://scripts/player/gull_visual.gd").soft_tex()
	for spec in [[70.0, Color(1.0, 0.85, 0.5, 0.55)], [150.0, Color(1.0, 0.8, 0.45, 0.22)]]:
		var g = MeshInstance3D.new()
		var q = QuadMesh.new()
		q.size = Vector2(spec[0], spec[0])
		g.mesh = q
		var gm = StandardMaterial3D.new()
		gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		gm.billboard_keep_scale = true
		gm.albedo_texture = soft
		gm.albedo_color = spec[1]
		gm.no_depth_test = false
		g.material_override = gm
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(g)
	# rays: sixteen thin spikes in a ring (flat quads, billboarded together)
	var rays = MeshInstance3D.new()
	var rq = QuadMesh.new()
	rq.size = Vector2(120.0, 120.0)
	rays.mesh = rq
	var rm = StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	rm.billboard_keep_scale = true
	rm.albedo_texture = ray_texture()
	rm.albedo_color = Color(1.0, 0.9, 0.6, 0.55)
	rays.material_override = rm
	rays.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rays.name = "Rays"
	root.add_child(rays)
	root.set_script(load("res://scripts/world/sun_spin.gd"))
	return root

static var _ray = null

static func ray_texture():
	if _ray == null:
		var S = 128
		var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
		for y in S:
			for x in S:
				var d = Vector2(x - S * 0.5 + 0.5, y - S * 0.5 + 0.5)
				var r = d.length() / (S * 0.5)
				var a = atan2(d.y, d.x)
				var spike = pow(max(cos(a * 8.0), 0.0), 18.0)
				var v = spike * clamp(1.0 - r, 0.0, 1.0) * clamp((r - 0.12) * 6.0, 0.0, 1.0)
				img.set_pixel(x, y, Color(1, 1, 1, clamp(v, 0.0, 1.0)))
		_ray = ImageTexture.create_from_image(img)
	return _ray
