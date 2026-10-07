extends RefCounted
# Merges thousands of primitives into one mesh per material (few draw calls) with one StaticBody holding all
# collision shapes. Special named materials (window, lamp) stay individually addressable for the day cycle.

var tools = {}
var mats = {}
var body
var parent
var unit_box
var unit_cyl
var unit_cone
var unit_sph
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
	unit_sph.radial_segments = 10
	unit_sph.rings = 6
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
	_tool(key, c, emit, rough).append_from(unit_box, 0, _xf(pos, size, rot_deg))
	if collide:
		_shape_box(pos, size, rot_deg)

func cyl(pos, radius, height, color, collide = false, top_radius = -1.0, emit = 0.0, rot_deg = Vector3.ZERO, mat_key = ""):
	var c = _col(color)
	var key = _key(c, emit, 0.9, mat_key)
	var mesh = unit_cone if (top_radius >= 0.0 and top_radius < 0.001) else unit_cyl
	var sz = Vector3(radius * 2.0, height, radius * 2.0)
	_tool(key, c, emit, 0.9).append_from(mesh, 0, _xf(pos, sz, rot_deg))
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
	_tool(key, c, 0.0, 0.9).append_from(unit_cone, 0, _xf(pos, Vector3(radius * 2.0, height, radius * 2.0), Vector3.ZERO))
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
	_tool(key, c, emit, 0.9).append_from(unit_sph, 0, _xf(pos, Vector3(radius * 2.0, radius * 2.0, radius * 2.0) * scale_v, Vector3.ZERO))
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
	_tool(key, c, 0.0, 0.9).append_from(unit_prism, 0, Transform3D(b * Basis.from_scale(s), pos))
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

func flush():
	for key in tools:
		var st = tools[key]
		var mesh = st.commit()
		var mi = MeshInstance3D.new()
		mi.mesh = mesh
		mi.name = "B_" + str(key).substr(0, 12)
		parent.add_child(mi)
	tools.clear()
