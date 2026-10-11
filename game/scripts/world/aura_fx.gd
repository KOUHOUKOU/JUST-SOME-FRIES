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
				if arch != null:
					arch.rotation.z = sin(t * 0.8) * 0.05
					arch.scale = Vector3.ONE * (1.0 + 0.025 * sin(t * 1.6))
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
			var am = RP.arc_mesh(Vector3(1, 0, 0), 1.0, 0.86, 0.052, 0.026, 28, 0.52)
			var ma = StandardMaterial3D.new()
			ma.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			ma.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ma.vertex_color_use_as_albedo = true
			ma.cull_mode = BaseMaterial3D.CULL_DISABLED
			ma.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
			ma.distance_fade_min_distance = 1.0
			ma.distance_fade_max_distance = 3.2
			n.arch = _mi(n, am, Vector3(0, -0.12, 0.12), ma)
			var sp = _sparks(n, Vector3(0, 0.3, 0.1), Color(1, 1, 1, 0.9), 26, 1.8, 0.8, 0.0, 0.25)
			sp.hue_variation_min = -1.0
			sp.hue_variation_max = 1.0
			var gr2 = Gradient.new()
			gr2.colors = PackedColorArray([Color("FF9AB8"), Color("FFE08A"), Color("9BF0FF"), Color("C6A8FF"), Color(1, 1, 1, 0)])
			gr2.offsets = PackedFloat32Array([0.0, 0.3, 0.55, 0.8, 1.0])
			sp.color_ramp = gr2
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

static func _ring_mesh(r, t):
	var tm = TorusMesh.new()
	tm.inner_radius = r - t
	tm.outer_radius = r + t
	tm.rings = 28
	tm.ring_segments = 8
	return tm
