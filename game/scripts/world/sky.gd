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

const Terrain = preload("res://scripts/world/terrain.gd")
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

# a darker material for the grey clouds and the rain clouds (day_cycle.gd tints it like the white one, only greyer)
static func storm_material():
	var m = cloud_material()
	m.set_shader_parameter("top_col", Color(0.52, 0.56, 0.65))
	m.set_shader_parameter("bottom_col", Color(0.24, 0.27, 0.35))
	m.set_shader_parameter("glow", 0.16)
	return m

# is the sea (well off the coast) under this point and the footprint of a cloud of this size?
static func over_sea(x, z, r = 0.0):
	for o in [Vector2.ZERO, Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r)]:
		if Terrain.H(x + o.x, z + o.y) > -1.2:
			return false
	return true

# the rain under a rain cloud: long thin streaks that fall to the sea. It only rains where there is sea under the cloud (cloud_drift.gd switches it).
static func rain_node(size):
	var pr = CPUParticles3D.new()
	pr.name = "Rain"
	pr.amount = 130 if GS.web else 380
	pr.lifetime = 3.4
	pr.preprocess = 3.4
	pr.local_coords = true
	pr.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	pr.emission_box_extents = Vector3(size * 0.26, 0.4, size * 0.15)
	pr.direction = Vector3(0, -1, 0)
	pr.spread = 1.5
	pr.initial_velocity_min = 38.0
	pr.initial_velocity_max = 44.0
	pr.gravity = Vector3(0, -4.0, 0)
	pr.position = Vector3(0, -size * 0.03, 0)
	var q = QuadMesh.new()
	q.size = Vector2(0.14, 3.6)
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.albedo_color = Color(0.72, 0.82, 0.95, 0.42)
	q.material = m
	pr.mesh = q
	pr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return pr

# one cloud as a mesh instance; kind = "white" | "dark" | "rain"
static func make_cloud(rng, size, kind, mats):
	var mi = MeshInstance3D.new()
	mi.mesh = cloud_mesh(rng, size * (1.15 if kind != "white" else 1.0))
	mi.material_override = mats["white"] if kind == "white" else mats["storm"]
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if kind != "white":
		mi.scale = Vector3(1.0, 0.8, 1.0)         # heavier and flatter
	mi.rotation.y = rng.randf_range(0.0, TAU)
	mi.set_meta("kind", kind)
	if kind == "rain":
		var rn = rain_node(size)
		rn.emitting = false
		mi.add_child(rn)
		mi.set_meta("rain", rn)
		mi.add_to_group("rain_cloud")
	return mi

# the drifting field of clouds: white (the most), dark grey ones, and rain clouds that only rain over the sea; one pair of rain cloud + white cloud has a rainbow between them
# (world/rainbow_pair.gd). Returns {"mat": the white material, "storm": the grey one, "node": the node that drifts them}
static func build_clouds(parent, rng, avoid = []):
	var mats = {"white": cloud_material(), "storm": storm_material()}
	var holder = Node3D.new()
	holder.name = "Clouds"
	holder.set_script(load("res://scripts/world/cloud_drift.gd"))
	parent.add_child(holder)
	var plan = []
	for i in 15:
		plan.append("white")
	for i in 6:
		plan.append("dark")
	for i in 5:
		plan.append("rain")
	for kind in plan:
		var tries = 0
		while tries < 200:
			tries += 1
			var pos = Vector3(rng.randf_range(-300, 300), rng.randf_range(72, 138), rng.randf_range(-220, 300))
			var size = rng.randf_range(26.0, 62.0)
			if kind == "rain":
				pos.y = rng.randf_range(70, 105)
				if not over_sea(pos.x, pos.z, size * 0.3):
					continue
			var bad = false
			for a in avoid:
				if Vector2(pos.x, pos.z).distance_to(Vector2(a.x, a.z)) < 60.0 and abs(pos.y - a.y) < 40.0:
					bad = true
			if kind != "white" and Vector2(pos.x, pos.z).length() < 110.0:
				bad = true                    # no storm right over the town
			if bad:
				continue
			var mi = make_cloud(rng, size, kind, mats)
			mi.position = pos
			mi.set_meta("drift", rng.randf_range(0.8, 2.2))
			holder.add_child(mi)
			break
	# a low bank of big clouds near the horizon: the town sits under a big sky
	for i in 14:
		var a = rng.randf_range(0.0, TAU)
		var dist = rng.randf_range(520.0, 760.0)
		var size2 = rng.randf_range(120.0, 220.0)
		var mi2 = MeshInstance3D.new()
		mi2.mesh = cloud_mesh(rng, size2)
		mi2.material_override = mats["white"]
		mi2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi2.position = Vector3(cos(a) * dist, rng.randf_range(35, 90), sin(a) * dist - 40.0)
		mi2.rotation.y = rng.randf_range(0.0, TAU)
		holder.add_child(mi2)
	# the rainbow between a rain cloud and a white cloud, out over the southern sea
	var pair = Node3D.new()
	pair.set_script(load("res://scripts/world/rainbow_pair.gd"))
	pair.name = "RainbowPair"
	pair.set_meta("drift", 1.1)
	holder.add_child(pair)
	pair.position = Vector3(-160.0, 82.0, 215.0)
	pair.build(rng, mats)
	return {"mat": mats["white"], "storm": mats["storm"], "node": holder, "pair": pair}

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
