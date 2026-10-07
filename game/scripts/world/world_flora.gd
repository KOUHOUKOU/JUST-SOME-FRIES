extends RefCounted
# Round 6: the ground is no longer bare. Thousands of grass tufts, wild flowers, pebbles and shells (a few MultiMeshes: very cheap) are scattered
# over every kind of ground that suits them, and kept out of buildings, yards, stairs and shops (the builder keeps a list of footprints).

const Terrain = preload("res://scripts/world/terrain.gd")

var w

func setup(p_w):
	w = p_w

func _tuft_mesh():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# five blades leaning outwards, darker at the root, lighter at the tip
	for k in 5:
		var a = k * TAU / 5.0 + 0.3
		var lean = 0.12 + 0.05 * float(k % 2)
		var hgt = 0.34 + 0.12 * float((k * 7) % 3)
		var dir = Vector3(cos(a), 0, sin(a))
		var side = Vector3(-dir.z, 0, dir.x) * 0.045
		var root = dir * 0.03
		var tip = root + dir * lean + Vector3(0, hgt, 0)
		st.set_color(Color(0.62, 0.62, 0.62))
		st.add_vertex(root - side)
		st.set_color(Color(0.62, 0.62, 0.62))
		st.add_vertex(root + side)
		st.set_color(Color(1.12, 1.12, 1.0))
		st.add_vertex(tip)
	st.generate_normals()
	var m = st.commit()
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 1.0
	m.surface_set_material(0, mat)
	return m

func _flower_mesh():
	var sm = SphereMesh.new()
	sm.radius = 0.075
	sm.height = 0.13
	sm.radial_segments = 6
	sm.rings = 3
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.8
	sm.material = mat
	return sm

func _pebble_mesh():
	var sm = SphereMesh.new()
	sm.radius = 0.12
	sm.height = 0.16
	sm.radial_segments = 6
	sm.rings = 3
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	sm.material = mat
	return sm

func _spawn(mesh, count, vis_end, fn):
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	var xs = []
	var n = 0
	var tries = 0
	while n < count and tries < count * 12:
		tries += 1
		var r = fn.call()
		if r == null:
			continue
		xs.append(r)
		n += 1
	mm.instance_count = xs.size()
	for i in xs.size():
		mm.set_instance_transform(i, xs[i][0])
		mm.set_instance_color(i, xs[i][1])
	var mi = MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = vis_end
	w.map.add_child(mi)

func _ok(x, z):
	if not Terrain.is_land(x, z):
		return false
	if abs(x) < 3.2 and z < -24.0:
		return false                          # the stairs
	return w.is_clear(x, z, 0.4)

func _slope(x, z):
	var h = Terrain.H(x, z)
	return max(abs(Terrain.H(x + 0.6, z) - h), abs(Terrain.H(x, z + 0.6) - h)) / 0.6

func build():
	var rng = RandomNumberGenerator.new()
	rng.seed = 777
	# grass tufts on grassy ground
	_spawn(_tuft_mesh(), 9000, 85.0, func():
		var x = rng.randf_range(-138.0, 125.0)
		var z = rng.randf_range(-96.0, 132.0)
		if not _ok(x, z):
			return null
		var h = Terrain.H(x, z)
		var c = Terrain.color_at(x, z, h, 0.0)
		if c.a != 0.0 or h < 0.35 or _slope(x, z) > 0.8:
			return null
		var s = rng.randf_range(0.8, 1.7)
		var b = Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3(s, s * rng.randf_range(0.8, 1.3), s))
		var g = rng.randf_range(0.82, 1.18)
		return [Transform3D(b, Vector3(x, h - 0.02, z)), Color(0.45 * g, 0.74 * g, 0.33 * g)])
	# wild flowers in loose drifts (the colour comes from the drift, so a patch of daisies is a patch of daisies)
	var drift_cols = [Color("FFFFFF"), Color("F7C7D4"), Color("F1C94B"), Color("E85745"), Color("A98FB8"), Color("FF8A3C")]
	_spawn(_flower_mesh(), 3200, 80.0, func():
		var x = rng.randf_range(-138.0, 125.0)
		var z = rng.randf_range(-96.0, 132.0)
		if not _ok(x, z):
			return null
		var h = Terrain.H(x, z)
		var c = Terrain.color_at(x, z, h, 0.0)
		if c.a != 0.0 or h < 0.35 or _slope(x, z) > 0.6:
			return null
		var cell = int(floor(x / 7.0)) * 31 + int(floor(z / 7.0)) * 17
		if abs(cell) % 3 != 0:
			return null                          # a flower only where its drift is
		var col = drift_cols[abs(cell / 3) % drift_cols.size()]
		var s = rng.randf_range(0.8, 1.3)
		return [Transform3D(Basis.IDENTITY.scaled(Vector3(s, s, s)), Vector3(x, h + 0.3 * s, z)), col.lerp(Color(1, 1, 1), rng.randf() * 0.25)])
	# pebbles and stones on sand, paving and the shore
	_spawn(_pebble_mesh(), 1600, 70.0, func():
		var x = rng.randf_range(-100.0, 125.0)
		var z = rng.randf_range(-50.0, 100.0)
		if not _ok(x, z):
			return null
		var h = Terrain.H(x, z)
		if h < -0.2:
			return null
		var c = Terrain.color_at(x, z, h, 0.0)
		if c.a != 0.2 and c.a != 0.4:
			return null
		var sh = rng.randf_range(0.5, 1.4)
		var tone = rng.randf_range(0.5, 0.78)
		return [Transform3D(Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3(sh, sh * 0.6, sh * 1.2)), Vector3(x, h + 0.03, z)), Color(tone, tone * 0.97, tone * 0.9)])
	# shells and starfish on the beach
	_spawn(_pebble_mesh(), 500, 60.0, func():
		var x = rng.randf_range(14.0, 80.0)
		var z = rng.randf_range(8.0, 46.0)
		if not _ok(x, z):
			return null
		var h = Terrain.H(x, z)
		if h < -0.3 or h > 1.0:
			return null
		var shell = [Color("F8EDE4"), Color("F2B8A8"), Color("FFE08A")][rng.randi() % 3]
		return [Transform3D(Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3(0.6, 0.3, 0.7)), Vector3(x, h + 0.02, z)), shell])
	# bushes: round green heaps along the edges of the plazas and under the hill's banks
	var bush_pos = []
	for i in 160:
		var x2 = rng.randf_range(-95.0, 95.0)
		var z2 = rng.randf_range(-92.0, 24.0)
		if not _ok(x2, z2):
			continue
		var h2 = Terrain.H(x2, z2)
		var c2 = Terrain.color_at(x2, z2, h2, 0.0)
		if c2.a != 0.0 or h2 < 0.3 or _slope(x2, z2) > 0.5:
			continue
		bush_pos.append(Vector3(x2, h2, z2))
	for p in bush_pos:
		var r2 = rng.randf_range(0.5, 1.0)
		w.B.ball(p + Vector3(0, r2 * 0.45, 0), r2, w._pick(["4F8A45", "5F9A4F", "447F3E", "6AA85A"]), Vector3(1.2, 0.8, 1.0))
		if rng.randf() < 0.35:
			for k in 4:
				w.B.ball(p + Vector3(rng.randf_range(-0.6, 0.6), r2 * 0.8 + 0.1, rng.randf_range(-0.5, 0.5)), 0.1, w._pick(["E85745", "F1C94B", "F7C7D4", "FFFFFF"]))
