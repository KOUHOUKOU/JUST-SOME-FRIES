extends RefCounted
# ROUND 15: what the sky leaves on the gull. Everything here is a quiet, see-through effect (it must never hide the view): the sun puts a pale-gold holy light
# over the gull's body and a slow halo above its head; the moon wraps the lower half of the body in a pale-blue light that sheds moon dust; the rainbow hangs as a
# bright, translucent arch round the gull; a cloud (white, or a grey rain cloud with a drizzle) lies under it, so the gull rides on it.
# Every material fades out when the camera comes close, so nothing floats across the lens.

const GV = preload("res://scripts/player/gull_visual.gd")
const RP = preload("res://scripts/world/rainbow_pair.gd")
const KINDS = ["sun", "moon", "skybow", "cloud", "raincloud"]

const VEIL = """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;
uniform vec4 col : source_color = vec4(1.0, 0.9, 0.55, 1.0);
uniform float dir = 1.0;
uniform float strength = 0.3;
varying float ly;
void vertex() {
	ly = VERTEX.y;
}
void fragment() {
	float vdn = abs(dot(normalize(NORMAL), normalize(VIEW)));
	float rim = pow(1.0 - vdn, 1.4);
	float g = smoothstep(-0.95, 0.8, ly * dir);
	float near = smoothstep(1.1, 3.4, length(VERTEX));
	ALBEDO = col.rgb;
	ALPHA = strength * (0.35 + 0.65 * rim) * g * g * near;
}
"""
static var _veil_shader = null

static func _veil(col, dir_, strength):
	if _veil_shader == null:
		_veil_shader = Shader.new()
		_veil_shader.code = VEIL
	var m = ShaderMaterial.new()
	m.shader = _veil_shader
	m.set_shader_parameter("col", col)
	m.set_shader_parameter("dir", dir_)
	m.set_shader_parameter("strength", strength)
	return m

static func _unshaded(col, add = false, near_fade = true):
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if add:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = col
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if near_fade:
		m.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
		m.distance_fade_min_distance = 0.9
		m.distance_fade_max_distance = 3.0
	return m

static func _mi(parent, mesh, pos, mat, scl = Vector3.ONE):
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scl
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

static func _sphere(r = 1.0):
	var s = SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 16
	s.rings = 10
	return s

static func _glow(parent, pos, size, col, tex = null):
	var q = QuadMesh.new()
	q.size = Vector2(size, size)
	var m = _unshaded(col, true)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = tex if tex != null else GV.soft_tex()
	return _mi(parent, q, pos, m)

# sparkles that stay where they were dropped and fade away
static func _sparks(parent, pos, col, amount, life, radius, grav, up_speed = 0.1, tex = null, size = 0.3):
	var sp = CPUParticles3D.new()
	sp.amount = amount
	sp.lifetime = life
	sp.local_coords = false
	sp.direction = Vector3.UP
	sp.spread = 180.0
	sp.initial_velocity_min = up_speed * 0.4
	sp.initial_velocity_max = up_speed * 1.6
	sp.gravity = Vector3(0, grav, 0)
	sp.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sp.emission_sphere_radius = radius
	sp.angle_min = -40.0
	sp.angle_max = 40.0
	sp.scale_amount_min = 0.5
	sp.scale_amount_max = 1.2
	var cv = Curve.new()
	cv.add_point(Vector2(0.0, 0.1))
	cv.add_point(Vector2(0.2, 1.0))
	cv.add_point(Vector2(1.0, 0.1))
	sp.scale_amount_curve = cv
	var ramp = Gradient.new()
	ramp.set_color(0, Color(col.r, col.g, col.b, 0.0))
	ramp.add_point(0.2, Color(col.r, col.g, col.b, col.a))
	ramp.set_color(2, Color(col.r, col.g, col.b, 0.0))
	sp.color_ramp = ramp
	var q = QuadMesh.new()
	q.size = Vector2(size, size)
	var m = _unshaded(Color(1, 1, 1, 1), true)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = tex if tex != null else GV.star_tex()
	m.distance_fade_min_distance = 1.0
	m.distance_fade_max_distance = 3.2
	q.material = m
	sp.mesh = q
	sp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sp.position = pos
	parent.add_child(sp)
	sp.emitting = true
	return sp

# ---- one little script per effect (animation only)
class FxNode extends Node3D:
	var kind = ""
	var g = null
	var t = 0.0
	var ring = null
	var pad = null
	var rays = null
	var veil = null
	var arch = null
	var rain = null
	var puffs = []
	var ring_wait = 1.2
	var last_pos = Vector3.ZERO
	var rings = []                        # {node, mat, age, life, size, drift}

	# round 16: the rainbow is not worn on the body any more (it hid the view). Now, while the gull flies, a small rainbow-coloured ring appears behind it every few seconds,
	# grows a little, drifts after the gull and fades: a flight effect, never in the way.
	func _skybow_rings(delta, grounded):
		var gp = global_position
		var spd = gp.distance_to(last_pos) / max(delta, 0.0001)
		last_pos = gp
		var i = 0
		while i < rings.size():
			var r = rings[i]
			r["age"] += delta
			var u = r["age"] / r["life"]
			if u >= 1.0 or not is_instance_valid(r["node"]):
				if is_instance_valid(r["node"]):
					r["node"].queue_free()
				rings.remove_at(i)
				continue
			r["node"].global_position += r["drift"] * delta
			r["node"].scale = Vector3.ONE * lerp(0.35, r["size"], 1.0 - pow(1.0 - u, 2.0))
			r["mat"].albedo_color = Color(1, 1, 1, 0.8 * sin(u * PI) * (1.0 if u > 0.0 else 0.0))
			i += 1
		if g == null or g.get("tracked") != true or grounded or spd < 3.0 or spd > 150.0:
			return
		ring_wait -= delta
		if ring_wait > 0.0:
			return
		ring_wait = randf_range(2.0, 3.6)
		var back = global_transform.basis.z.normalized()
		var node = MeshInstance3D.new()
		node.mesh = load("res://scripts/world/aura_fx.gd").rainbow_ring_mesh()
		var mt = load("res://scripts/world/aura_fx.gd")._unshaded(Color(1, 1, 1, 0.0), true, true)
		mt.vertex_color_use_as_albedo = true
		mt.cull_mode = BaseMaterial3D.CULL_DISABLED
		node.material_override = mt
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		get_tree().current_scene.add_child(node)
		node.global_position = gp + back * 1.5 + Vector3(0, 0.1, 0)
		# the ring stands across the gull's path (its axis along the flight direction)
		var zb = back
		var xb = Vector3.UP.cross(zb).normalized() if abs(zb.y) < 0.95 else Vector3.RIGHT
		var yb = zb.cross(xb).normalized()
		node.global_transform = Transform3D(Basis(xb, yb, zb), node.global_position)
		rings.append({"node": node, "mat": mt, "age": 0.0, "life": 1.5, "size": 1.25, "drift": -back * min(spd * 0.55, 14.0)})

	func _exit_tree():
		for r in rings:
			if is_instance_valid(r["node"]):
				r["node"].queue_free()

	func _process(delta):
		t += delta
		var grounded = g != null and g.get("on_ground") == true
		match kind:
			"sun":
				if ring != null:
					ring.rotation.y += delta * 0.9
					ring.position.y = 0.66 + sin(t * 1.7) * 0.02
					ring.scale = Vector3.ONE * (1.0 + 0.03 * sin(t * 2.4))
				if veil != null:
					veil.set_shader_parameter("strength", 0.30 + 0.07 * sin(t * 1.9))
			"moon":
				if veil != null:
					veil.set_shader_parameter("strength", 0.34 + 0.07 * sin(t * 1.5 + 1.0))
			"skybow":
				_skybow_rings(delta, grounded)
			"cloud", "raincloud":
				if pad != null:
					pad.visible = not grounded
					pad.position.y = -0.4 + sin(t * 1.3) * 0.025
					for i in puffs.size():
						puffs[i].position.y = puffs[i].get_meta("y0") + sin(t * 1.1 + i * 1.7) * 0.02
					pad.rotation.y = sin(t * 0.4) * 0.08
				if rain != null:
					rain.emitting = not grounded

# the finished effect for a worn sky item (a Node3D child of the gull)
static func build(g, kind):
	var n = FxNode.new()
	n.kind = kind
	n.g = g
	g.add_child(n)
	match kind:
		"sun":
			var gold = Color(1.0, 0.86, 0.45)
			var vm = _veil(gold, 1.0, 0.3)
			n.veil = vm
			_mi(n, _sphere(1.0), Vector3(0, 0.12, 0.02), vm, Vector3(0.66, 0.56, 0.9))
			n.ring = _mi(n, _ring_mesh(0.27, 0.017), Vector3(0, 0.66, -0.2), _unshaded(Color(1.0, 0.87, 0.5, 0.75), true))
			_glow(n, Vector3(0, 0.5, 0.0), 1.5, Color(1.0, 0.85, 0.45, 0.17))
			_sparks(n, Vector3(0, 0.15, 0.1), Color(1.0, 0.86, 0.42, 0.85), 22, 2.2, 0.5, 0.0, 0.18)
		"moon":
			var blue = Color(0.62, 0.84, 1.0)
			var vm2 = _veil(blue, -1.0, 0.34)
			n.veil = vm2
			_mi(n, _sphere(1.0), Vector3(0, -0.04, 0.02), vm2, Vector3(0.66, 0.56, 0.9))
			_glow(n, Vector3(0, -0.34, 0.05), 1.7, Color(0.6, 0.82, 1.0, 0.2))
			_sparks(n, Vector3(0, -0.2, 0.1), Color(0.7, 0.88, 1.0, 0.85), 22, 2.6, 0.45, -0.25, 0.1)
		"skybow":
			pass            # (round 16: no arch on the body; the rings are made by FxNode while the gull flies)
		"cloud", "raincloud":
			var rainy = kind == "raincloud"
			var top = Color(0.6, 0.64, 0.74, 0.82) if rainy else Color(1.0, 1.0, 1.0, 0.8)
			var pad = Node3D.new()
			pad.position = Vector3(0, -0.4, 0.02)
			n.add_child(pad)
			n.pad = pad
			for c in [[0.0, 0.0, 0.0, 0.5, 1.0], [0.42, -0.02, 0.1, 0.34, 0.9], [-0.42, -0.02, 0.1, 0.34, 0.9], [0.18, 0.04, -0.28, 0.3, 0.9], [-0.2, 0.03, -0.3, 0.3, 0.9], [0.0, 0.0, 0.36, 0.34, 0.9], [0.62, -0.03, -0.1, 0.2, 0.8], [-0.62, -0.03, -0.1, 0.2, 0.8]]:
				var cm = _unshaded(top.darkened(0.08 * float(c[1] < 0.0)), false)
				var pf = _mi(pad, _sphere(1.0), Vector3(c[0], c[1], c[2]), cm, Vector3(c[3], c[3] * 0.42, c[3] * 1.05))
				pf.set_meta("y0", c[1])
				n.puffs.append(pf)
			var wisp = _sparks(pad, Vector3(0, 0.0, 0.3), Color(top.r, top.g, top.b, 0.5), 12, 1.6, 0.6, 0.0, 0.2, GV.soft_tex(), 0.5)
			wisp.direction = Vector3(0, 0, 1)
			wisp.spread = 25.0
			if rainy:
				var rn = CPUParticles3D.new()
				rn.amount = 36
				rn.lifetime = 0.75
				rn.local_coords = false
				rn.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
				rn.emission_box_extents = Vector3(0.5, 0.02, 0.55)
				rn.direction = Vector3(0, -1, 0)
				rn.spread = 3.0
				rn.initial_velocity_min = 3.0
				rn.initial_velocity_max = 4.2
				rn.gravity = Vector3(0, -3.0, 0)
				var rq = QuadMesh.new()
				rq.size = Vector2(0.025, 0.4)
				var rm = _unshaded(Color(0.75, 0.86, 1.0, 0.5), false)
				rm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
				rq.material = rm
				rn.mesh = rq
				rn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				rn.position = Vector3(0, -0.06, 0)
				pad.add_child(rn)
				rn.emitting = true
				n.rain = rn
	return n

# a flat ring whose colour runs through the rainbow all the way round (unit radius, in the XY plane)
static var _rb_ring = null
static func rainbow_ring_mesh():
	if _rb_ring != null:
		return _rb_ring
	var n = 40
	var verts = PackedVector3Array()
	var cols = PackedColorArray()
	var idx = PackedInt32Array()
	for i in n + 1:
		var an = TAU * i / n
		var c = Color.from_hsv(fmod(float(i) / n * 1.0, 1.0), 0.55, 1.0, 1.0)
		verts.append(Vector3(cos(an) * 0.88, sin(an) * 0.88, 0.0))
		cols.append(c)
		verts.append(Vector3(cos(an) * 1.0, sin(an) * 1.0, 0.0))
		cols.append(c)
	for i in n:
		var b = i * 2
		idx.append_array(PackedInt32Array([b, b + 1, b + 2, b + 1, b + 3, b + 2]))
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_COLOR] = cols
	arr[Mesh.ARRAY_INDEX] = idx
	var am = ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_rb_ring = am
	return am

static func _ring_mesh(r, t):
	var tm = TorusMesh.new()
	tm.inner_radius = r - t
	tm.outer_radius = r + t
	tm.rings = 28
	tm.ring_segments = 8
	return tm
