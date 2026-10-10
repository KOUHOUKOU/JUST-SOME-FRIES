extends RefCounted
const Prof=preload("res://scripts/art/s7_profile.gd")
# Merges thousands of primitives into one mesh per material (few draw calls) with one StaticBody holding all
# collision shapes. Special named materials (window, lamp) stay individually addressable for the day cycle.

var tools = {}
var drawn_tools = {}
var visual_suppressed = false
var capture = false
var captured = []
var old_tools = {}
var art_tools = {}
var cover_batch = false
var cover_meshes = {}
var compare_art = "--art-p1b" in OS.get_cmdline_user_args() and "--cams" in OS.get_cmdline_user_args()
const Art = preload("res://scripts/art/art_loader.gd")
var mats = {}
var body
var parent
var unit_box
var unit_cyl
var unit_cone
var unit_sph
var lamp_sph
var unit_prism
var special = {}
var shape_count = 0

func _init(p_parent):
	parent = p_parent
	body = StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.name = "SolidBody"
	parent.add_child(body)
	unit_box = BoxMesh.new()
	unit_box.size = Vector3.ONE
	unit_cyl = CylinderMesh.new()
	unit_cyl.top_radius = 0.5
	unit_cyl.bottom_radius = 0.5
	unit_cyl.height = 1.0
	unit_cyl.radial_segments = 10
	unit_cone = CylinderMesh.new()
	unit_cone.top_radius = 0.0
	unit_cone.bottom_radius = 0.5
	unit_cone.height = 1.0
	unit_cone.radial_segments = 10
	unit_sph = SphereMesh.new()
	unit_sph.radius = 0.5
	unit_sph.height = 1.0
	# S6: tiny static berries/pebbles/fenders use the cover's faceted silhouette.
	# Collision generation below deliberately retains the original hull points.
	unit_sph.radial_segments = 8
	unit_sph.rings = 4
	# Small glowing bulbs need no dense sphere: same envelope, shared lamp batch.
	lamp_sph = SphereMesh.new()
	lamp_sph.radius=.5;lamp_sph.height=1.0;lamp_sph.radial_segments=6;lamp_sph.rings=3
	unit_prism = PrismMesh.new()
	unit_prism.size = Vector3.ONE

func set_special(key, material):
	special[key] = material

func _col(color):
	if typeof(color) == TYPE_STRING and color == "":
		return Color.BLACK
	return Color(color)

func _tool(key, color, emit, rough):
	if tools.has(key):
		return tools[key]
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var m
	if special.has(key):
		m = special[key]
	else:
		m = StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = rough
		if emit > 0.0:
			m.emission_enabled = true
			m.emission = color
			m.emission_energy_multiplier = emit
	st.set_material(m)
	tools[key] = st
	mats[key] = m
	return st

func _xf(pos, size, rot_deg):
	var b = Basis.from_euler(Vector3(deg_to_rad(rot_deg.x), deg_to_rad(rot_deg.y), deg_to_rad(rot_deg.z)))
	return Transform3D(b * Basis.from_scale(size), pos)

func _key(color, emit, rough, mat_key):
	if mat_key != "":
		return mat_key
	return "%s|%s|%s" % [color.to_html(), emit, rough]

func box(pos, size, color, collide = true, rot_deg = Vector3.ZERO, emit = 0.0, mat_key = "", rough = 0.9):
	var c = _col(color)
	var key = _key(c, emit, rough, mat_key)
	_append(unit_box, key, c, emit, rough, _xf(pos, size, rot_deg))
	_record("box", pos, size, c, rot_deg, mat_key)
	if collide:
		_shape_box(pos, size, rot_deg)

func cyl(pos, radius, height, color, collide = false, top_radius = -1.0, emit = 0.0, rot_deg = Vector3.ZERO, mat_key = ""):
	var c = _col(color)
	var key = _key(c, emit, 0.9, mat_key)
	var mesh = unit_cone if (top_radius >= 0.0 and top_radius < 0.001) else unit_cyl
	var sz = Vector3(radius * 2.0, height, radius * 2.0)
	_append(mesh, key, c, emit, 0.9, _xf(pos, sz, rot_deg))
	_record("cyl", pos, sz, c, rot_deg, mat_key)
	if collide:
		var cs = CollisionShape3D.new()
		var sh = CylinderShape3D.new()
		sh.radius = radius
		sh.height = height
		cs.shape = sh
		cs.transform = _xf(pos, Vector3.ONE, rot_deg)
		body.add_child(cs)
		shape_count += 1

func cone(pos, radius, height, color, collide = false):
	var c = _col(color)
	var key = _key(c, 0.0, 0.9, "")
	_append(unit_cone, key, c, 0.0, 0.9, _xf(pos, Vector3(radius * 2.0, height, radius * 2.0), Vector3.ZERO))
	_record("cone", pos, Vector3(radius * 2.0,height,radius * 2.0), c, Vector3.ZERO, "")
	if collide:
		# the real cone (round 7): a gull can stand on the slope of a pine or a spire
		var pts = PackedVector3Array()
		for k in 10:
			var a = TAU * k / 10.0
			pts.append(Vector3(cos(a) * radius * 0.95, -height * 0.5, sin(a) * radius * 0.95))
		pts.append(Vector3(0, height * 0.5, 0))
		var cs = CollisionShape3D.new()
		var sh = ConvexPolygonShape3D.new()
		sh.points = pts
		cs.shape = sh
		cs.position = pos
		body.add_child(cs)
		shape_count += 1

func ball(pos, radius, color, scale_v = Vector3.ONE, emit = 0.0, collide = false, mat_key = ""):
	var c = _col(color)
	var key = _key(c, emit, 0.9, mat_key)
	_append(lamp_sph if mat_key=="lamp" else unit_sph, key, c, emit, 0.9, _xf(pos, Vector3(radius * 2.0, radius * 2.0, radius * 2.0) * scale_v, Vector3.ZERO))
	_record("ball", pos, Vector3.ONE * radius * 2.0 * scale_v, c, Vector3.ZERO, mat_key)
	if collide:
		# round 7: the exact solid of the (squashed) ball, as a convex hull a few percent inside the mesh, so a gull can stand on a tree top / a bush without sinking in
		_shape_ellipsoid(pos, Vector3(radius, radius, radius) * scale_v * 0.96)

# triangular prism, ridge along local X (pitched roof): size = (length, height, depth)
func prism(pos, size, color, collide = true, rot_deg = Vector3.ZERO):
	var c = _col(color)
	var key = _key(c, 0.0, 0.9, "")
	# PrismMesh has its ridge along Z; rotate 90 deg so the ridge runs along X
	var b = Basis.from_euler(Vector3(deg_to_rad(rot_deg.x), deg_to_rad(rot_deg.y + 90.0), deg_to_rad(rot_deg.z)))
	var s = Vector3(size.z, size.y, size.x)
	_append(unit_prism, key, c, 0.0, 0.9, Transform3D(b * Basis.from_scale(s), pos))
	_record("prism", pos, size, c, rot_deg, "")
	if collide:
		_shape_prism(pos, size, rot_deg)

# the exact solid of a pitched roof (a triangular prism, ridge along local X): the gull can stand on the slope, feet on the tiles
func _shape_prism(pos, size, rot_deg):
	var hx = size.x * 0.5
	var hy = size.y * 0.5
	var hz = size.z * 0.5
	var pts = PackedVector3Array([Vector3(-hx, -hy, -hz), Vector3(hx, -hy, -hz), Vector3(-hx, -hy, hz), Vector3(hx, -hy, hz), Vector3(-hx, hy, 0), Vector3(hx, hy, 0)])
	var cs = CollisionShape3D.new()
	var sh = ConvexPolygonShape3D.new()
	sh.points = pts
	cs.shape = sh
	cs.transform = _xf(pos, Vector3.ONE, rot_deg)
	body.add_child(cs)
	shape_count += 1

func _shape_ellipsoid(pos, radii):
	var pts = PackedVector3Array()
	for i in range(1, 6):
		var phi = PI * i / 6.0
		for j in 10:
			var th = TAU * j / 10.0
			pts.append(Vector3(sin(phi) * cos(th) * radii.x, cos(phi) * radii.y, sin(phi) * sin(th) * radii.z))
	pts.append(Vector3(0, radii.y, 0))
	pts.append(Vector3(0, -radii.y, 0))
	var cs = CollisionShape3D.new()
	var sh = ConvexPolygonShape3D.new()
	sh.points = pts
	cs.shape = sh
	cs.position = pos
	body.add_child(cs)
	shape_count += 1

func perch_pad(pos, radius):
	var cs = CollisionShape3D.new()
	var sh = CylinderShape3D.new()
	sh.radius = radius
	sh.height = 0.2
	cs.shape = sh
	cs.position = pos - Vector3(0, 0.1, 0)
	body.add_child(cs)
	shape_count += 1

func _shape_box(pos, size, rot_deg):
	var cs = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.transform = _xf(pos, Vector3.ONE, rot_deg)
	body.add_child(cs)
	shape_count += 1

func _append(mesh, key, c, emit, rough, xf):
	if compare_art:
		if not old_tools.has(key):
			var old = SurfaceTool.new()
			old.begin(Mesh.PRIMITIVE_TRIANGLES)
			_tool(key, c, emit, rough)
			old.set_material(mats[key])
			old_tools[key] = old
		old_tools[key].append_from(mesh, 0, xf)
	if not visual_suppressed:
		if cover_batch and not special.has(key) and emit == 0.0:
			cover_piece(mesh,c,xf)
		else:
			drawn_tools[key] = true
			_tool(key, c, emit, rough).append_from(mesh, 0, xf)

func _record(kind, pos, size, c, rot, key):
	if capture:
		captured.append({"kind":kind,"pos":[pos.x,pos.y,pos.z],"size":[size.x,size.y,size.z],"colour":c.to_html(false),"rot":[rot.x,rot.y,rot.z],"key":key})

func begin_visual_capture(suppress):
	assert(not capture)
	capture = true
	captured = []
	visual_suppressed = suppress

func end_visual_capture():
	capture = false
	visual_suppressed = false
	return captured

func cover_piece(mesh,c,xf):
	var profile_t=Prof.start()
	var key=str(mesh.get_instance_id())+c.to_html()
	if not cover_meshes.has(key):
		var a=mesh.get_mesh_arrays() if mesh is PrimitiveMesh else mesh.surface_get_arrays(0)
		var cols=PackedColorArray()
		for v in a[Mesh.ARRAY_VERTEX]:cols.append(c.srgb_to_linear())
		a[Mesh.ARRAY_COLOR]=cols
		var painted=ArrayMesh.new();painted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a);cover_meshes[key]=painted
	Prof.end("primitive paint cache",profile_t)
	authored(cover_meshes[key],xf)

func authored(mesh, xf):
	var profile_t=Prof.start()
	var key = Vector2i(floori(xf.origin.x / 50.0), floori(xf.origin.z / 50.0))
	if not art_tools.has(key):
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_material(Art.material())
		art_tools[key] = st
	art_tools[key].append_from(mesh, 0, xf)
	Prof.end("district append",profile_t)

func flush():
	var profile_t=Prof.start()
	for key in art_tools:
		var mi = MeshInstance3D.new()
		mi.mesh = art_tools[key].commit()
		mi.material_override = Art.material()
		mi.name = "AuthoredHouses_" + str(key)
		mi.add_to_group("p1b_new_world")
		parent.add_child(mi)
	art_tools.clear()
	for key in old_tools:
		var mi = MeshInstance3D.new()
		mi.mesh = old_tools[key].commit()
		mi.name = "LegacyBatch_" + str(key)
		mi.visible = false
		mi.add_to_group("p1b_old_world")
		parent.add_child(mi)
	old_tools.clear()
	for key in tools:
		if not drawn_tools.has(key):continue
		var st = tools[key]
		var mesh = st.commit()
		var mi = MeshInstance3D.new()
		mi.mesh = mesh
		mi.name = "B_" + str(key).substr(0, 12)
		if key in ["lamp","window"]:mi.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.add_to_group("p1b_new_world")
		parent.add_child(mi)
	tools.clear()
	drawn_tools.clear()

	Prof.end("batch commit upload",profile_t)
