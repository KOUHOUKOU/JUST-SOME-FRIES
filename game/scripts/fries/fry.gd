extends Node3D
# One data-driven fry for every type: tutorial / red / blue / yellow / green / rose (tier 1), star (tier 2-3 of a type), ordinary.
# Carriers (docs/18 §4): box (carton), plate, hand. Oversized, saturated and haloed so they read at a glance.
# RARITY: the halo + rim around a fry is its rarity colour (white common, blue rare, purple epic, gold legendary).
# The plain fry has none of it: no halo, no ring, no glow in Gull Sight.

const COLORS = {
	"tutorial": Color("F6C453"), "red": Color("E8453C"), "orange": Color("F28A2E"), "green": Color("4FBF5A"), "cyan": Color("33CFD6"),
	"blue": Color("3D6FE0"), "purple": Color("9B5DE0"), "pink": Color("F277B5"),
}
const GOLD = Color("F2B53A")
const ORDINARY_GOLD = Color("E3A93A")
const SPECIAL_TYPES = ["red", "orange", "green", "cyan", "blue", "purple", "pink"]

static var _halo_tex = null
static var _ring_tex = null
static var _rim_tex = null
static var _mats = {}

var id = ""
var ftype = "tutorial"
var carrier = "box"
var kind = 0
var tier = 0                 # 0 common (tutorial), 1 rare, 2 epic, 3 legendary
var utype = ""               # which stat a star fry raises
var npc = null
var available = true
var consumed = false
var carried = false
var revealed = true
var vanished = false
var home_parent = null
var home_local = Vector3.ZERO
var home_pos = Vector3.ZERO
var visual
var halo
var rim
var sense_ring
var glints
var halo_color = Color.WHITE
var halo_alpha = 0.0
var halo_base = 0.0
var chime_cd = 0.0
var t = 0.0
var rng = RandomNumberGenerator.new()

func setup(p_id, p_type, p_carrier = "box", p_kind = 0, p_tier = -1):
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	id = p_id
	ftype = p_type
	carrier = p_carrier
	kind = p_kind
	if p_tier >= 0:
		tier = p_tier
	elif ftype == "tutorial" or ftype == "ordinary":
		tier = 0
	else:
		tier = 1
	if ftype == "star":
		utype = SPECIAL_TYPES[clamp(kind, 0, SPECIAL_TYPES.size() - 1)]
	elif is_special():
		utype = ftype
		kind = SPECIAL_TYPES.find(ftype)
	rng.seed = hash(p_id) + p_kind
	add_to_group("fries")
	if is_special():
		add_to_group("special_fries")
		revealed = tier >= 4          # rainbow fries are always visible (they are the repeatable ones)
		visible = tier >= 4
	if ftype == "star":
		add_to_group("star_fries")
	_rebuild()

func is_special():
	return ftype in SPECIAL_TYPES

func rarity_color():
	if ftype == "ordinary":
		return ORDINARY_GOLD
	if tier >= 4:
		return Color.from_hsv(fmod(t * 0.25 + float(hash(id) % 10) * 0.1, 1.0), 0.5, 1.0)
	return GS.RARITY_COLORS[clamp(tier, 0, 3)]

func is_fry_like():
	return true

func type_color():
	if ftype == "star" or is_special():
		return GS.TYPE_COLORS[utype]
	return COLORS.get(ftype, Color.WHITE)

var plain = false

func is_snatchable():
	if GS.ordinary_eaten and ftype != "ordinary":
		return false
	return available and revealed and not carried and not consumed and not vanished

func go_plain():
	plain = true
	halo_alpha = 0.0
	halo_base = 0.0
	_apply_halo()
	if glints != null:
		glints.emitting = false
	if rim != null:
		rim.visible = false

# Gull Sight: where this fry shines (null = it does not glow at all: the plain fry, taken fries, hidden fries)
func vision_info():
	if consumed or carried or vanished or plain or ftype == "ordinary" or not revealed:
		return null
	return {"pos": global_position + Vector3(0, 0.3, 0), "col": rarity_color(), "core": type_color(), "tier": tier}

func aim_point():
	if ftype == "ordinary":
		return global_position + Vector3(0, 0.15, 0)
	if ftype == "star":
		return global_position + Vector3(0, 0.1, 0)
	match carrier:
		"plate":
			return global_position + Vector3(0, 0.3, 0)
		"hand":
			return global_position + Vector3(0, 0.4, 0)
	return global_position + Vector3(0, 0.5, 0)

static func mat(c, emit = 0.0, rough = 0.85):
	var key = str(c) + str(emit) + str(rough)
	if _mats.has(key):
		return _mats[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	_mats[key] = m
	return m

func _box(parent, pos, size, m, rot = Vector3.ZERO):
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

func _cyl(parent, pos, r, h, m):
	var mi = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = 16
	mi.mesh = cm
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	return mi

func _stick(parent, pos, len_, thick, m, rot):
	var s = _box(parent, pos, Vector3(thick, len_, thick), m, rot)
	# crinkle band
	_box(s, Vector3(0, len_ * 0.15, 0), Vector3(thick * 1.12, 0.012, thick * 1.12), mat(GOLD.darkened(0.15), 0.2))
	return s

func _rebuild():
	if visual != null:
		visual.queue_free()
	if halo != null:
		halo.queue_free()
	if rim != null:
		rim.queue_free()
	if sense_ring != null:
		sense_ring.queue_free()
	if glints != null:
		glints.queue_free()
	visual = Node3D.new()
	add_child(visual)
	rng.seed = hash(id) + kind
	match ftype:
		"ordinary":
			_build_ordinary()
		"star":
			_build_star()
		_:
			match carrier:
				"plate":
					_build_plate()
				"hand":
					_build_carton(0.8)
				_:
					_build_carton(1.0)
	_build_halo()
	_build_sense_ring()

func set_carrier(c):
	carrier = c
	_rebuild()

func _body_color():
	if ftype == "tutorial":
		return Color("E8453A")
	return COLORS.get(ftype, Color.WHITE)

func _stick_mat():
	var glow = 0.25 if ftype == "tutorial" else 0.7
	return mat(GOLD, glow)

func _build_carton(s):
	var body = _body_color()
	var glow = 0.15 if ftype == "tutorial" else 1.0
	var bm = mat(body, glow)
	_box(visual, Vector3(0, 0.13 * s, 0), Vector3(0.36, 0.26, 0.15) * s, bm)
	_box(visual, Vector3(0, 0.13 * s, 0.077 * s), Vector3(0.3, 0.12, 0.01) * s, mat(Color("FFF3D6")))
	_box(visual, Vector3(0, 0.255 * s, 0.07 * s), Vector3(0.37, 0.035, 0.04) * s, bm, Vector3(0.5, 0, 0))
	var sm = _stick_mat()
	for k in 13:
		var row = k % 2
		var x = (-0.15 + (k / 2) * 0.05 + row * 0.02) * s
		var h = rng.randf_range(0.36, 0.5) * s
		_stick(visual, Vector3(x, 0.26 * s + h * 0.38, (row - 0.5) * 0.06 * s), h, 0.07 * s, sm,
			Vector3(rng.randf_range(-0.12, 0.12), 0, rng.randf_range(-0.14, 0.14)))

func _build_plate():
	_cyl(visual, Vector3(0, 0.02, 0), 0.38, 0.035, mat(Color("F7F3EA"), 0.0, 0.5))
	_cyl(visual, Vector3(0, 0.045, 0), 0.31, 0.02, mat(Color("E9E3D3"), 0.0, 0.5))
	var sm = _stick_mat()
	for k in 24:
		var a = rng.randf() * TAU
		var r = rng.randf_range(0.0, 0.22)
		var tilt = rng.randf_range(0.5, 1.3)
		var len_ = rng.randf_range(0.28, 0.4)
		_stick(visual, Vector3(cos(a) * r, 0.12 + (0.22 - r) * 0.6 + rng.randf() * 0.04, sin(a) * r), len_, 0.065, sm,
			Vector3(cos(a + 1.57) * tilt, rng.randf() * TAU, sin(a + 1.57) * tilt))
	var ketchup = MeshInstance3D.new()
	var sp = SphereMesh.new()
	sp.radius = 0.07
	sp.height = 0.09
	ketchup.mesh = sp
	ketchup.material_override = mat(Color("C8372D"), 0.2)
	ketchup.position = Vector3(0.27, 0.07, 0.12)
	visual.add_child(ketchup)

func _build_ordinary():
	var m = mat(ORDINARY_GOLD, 0.0, 0.7)
	var main = _box(visual, Vector3(0, 0.06, 0), Vector3(0.1, 0.1, 0.72), m, Vector3(0, 0.35, 0))
	_box(main, Vector3(0, 0, 0.1), Vector3(0.108, 0.108, 0.012), mat(ORDINARY_GOLD.darkened(0.2), 0.0, 0.7))
	_box(main, Vector3(0, 0, -0.12), Vector3(0.108, 0.108, 0.012), mat(ORDINARY_GOLD.darkened(0.2), 0.0, 0.7))
	_box(main, Vector3(0, 0, -0.3), Vector3(0.108, 0.108, 0.012), mat(ORDINARY_GOLD.darkened(0.2), 0.0, 0.7))
	_box(main, Vector3(0.004, 0.056, 0.0), Vector3(0.09, 0.012, 0.6), mat(ORDINARY_GOLD.lightened(0.25), 0.0, 0.6))

# STAR fries: a floating fry in the shape that belongs to its type, with a ribbon in the type's colour.
func _build_star():
	var m = mat(GOLD, 0.9)
	var accent = mat(type_color(), 1.3)
	match kind:
		0: # shoestring (tailwind)
			for k in 16:
				_box(visual, Vector3(rng.randf_range(-0.08, 0.08), 0.0, rng.randf_range(-0.08, 0.08)), Vector3(0.035, 0.5, 0.035), m,
					Vector3(rng.randf_range(-0.4, 0.4), rng.randf() * TAU, rng.randf_range(-0.4, 0.4)))
		1: # curly (deep breath)
			for k in 18:
				var a = k * 0.55
				_box(visual, Vector3(cos(a) * 0.14, -0.2 + k * 0.025, sin(a) * 0.14), Vector3(0.13, 0.07, 0.07), m, Vector3(0, -a, 0.3))
		2: # waffle (second wind)
			for k in 5:
				_box(visual, Vector3(0, 0.02, -0.16 + k * 0.08), Vector3(0.34, 0.04, 0.04), m)
				_box(visual, Vector3(-0.16 + k * 0.08, 0.06, 0), Vector3(0.04, 0.04, 0.34), m)
		3: # wedges (steady beak)
			for k in 6:
				var a2 = k * 1.05
				var pm = MeshInstance3D.new()
				var pr = PrismMesh.new()
				pr.size = Vector3(0.12, 0.12, 0.34)
				pm.mesh = pr
				pm.material_override = mat(Color("D99A2B"), 0.6)
				pm.position = Vector3(cos(a2) * 0.12, 0.0 + (k % 2) * 0.1, sin(a2) * 0.12)
				pm.rotation = Vector3(0, a2, 0)
				visual.add_child(pm)
		4: # tater tots (deep breath)
			for k in 9:
				var a3 = k * 2.4
				var tm = MeshInstance3D.new()
				var cm2 = CylinderMesh.new()
				cm2.top_radius = 0.07
				cm2.bottom_radius = 0.07
				cm2.height = 0.17
				cm2.radial_segments = 10
				tm.mesh = cm2
				tm.material_override = mat(Color("D99A2B"), 0.7)
				tm.position = Vector3(cos(a3) * 0.13, -0.05 + (k % 3) * 0.1, sin(a3) * 0.13)
				tm.rotation = Vector3(rng.randf_range(-0.5, 0.5), rng.randf() * TAU, rng.randf_range(-0.5, 0.5))
				visual.add_child(tm)
		5: # crinkle cut slabs (second wind)
			for k in 7:
				_box(visual, Vector3(rng.randf_range(-0.07, 0.07), -0.12 + k * 0.045, rng.randf_range(-0.07, 0.07)), Vector3(0.36, 0.035, 0.1), m,
					Vector3(0, rng.randf() * TAU, rng.randf_range(-0.1, 0.1)))
		_: # sweet potato (fluff)
			var sw = mat(Color("F08A3C"), 0.9)
			for k in 12:
				_box(visual, Vector3(rng.randf_range(-0.1, 0.1), 0.0, rng.randf_range(-0.1, 0.1)), Vector3(0.07, 0.46, 0.07), sw,
					Vector3(rng.randf_range(-0.35, 0.35), rng.randf() * TAU, rng.randf_range(-0.35, 0.35)))
	_box(visual, Vector3(0, -0.28, 0), Vector3(0.2, 0.05, 0.2), accent)
	_box(visual, Vector3(0, -0.12, 0), Vector3(0.17, 0.035, 0.17), accent)
	visual.scale = Vector3.ONE * (1.0 if tier <= 2 else 1.25)

static func _glow_tex():
	if _halo_tex == null:
		var g = Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var gt = GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 128
		gt.height = 128
		_halo_tex = gt
	return _halo_tex

# crisp ring + soft inner disc: the "rarity badge" that hangs behind a fry
static func _rim_texture():
	if _rim_tex == null:
		var img = Image.create(128, 128, false, Image.FORMAT_RGBA8)
		for y in 128:
			for x in 128:
				var d = Vector2(x - 63.5, y - 63.5).length() / 64.0
				var ring = clamp(1.0 - abs(d - 0.8) / 0.06, 0.0, 1.0)
				var disc = clamp(1.0 - d, 0.0, 1.0) * 0.25
				var edge = clamp((1.0 - d) * 8.0, 0.0, 1.0)
				img.set_pixel(x, y, Color(1, 1, 1, clamp(max(ring, disc) * edge, 0.0, 1.0)))
		_rim_tex = ImageTexture.create_from_image(img)
	return _rim_tex

func _build_halo():
	var tex = _glow_tex()
	halo = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = Vector2(1, 1)
	halo.mesh = q
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = tex
	m.disable_receive_shadows = true
	halo.material_override = m
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.position = Vector3(0, 0.3, 0)
	add_child(halo)
	match ftype:
		"ordinary":
			halo_color = Color(1.0, 0.78, 0.4)
			halo.scale = Vector3(2.2, 2.2, 2.2)
			halo.position = Vector3(0, 0.12, 0)
			halo_base = 0.0
		"tutorial":
			halo_color = Color(1.0, 0.92, 0.7)
			halo.scale = Vector3(2.0, 2.0, 2.0)
			halo_base = 0.5
		_:
			halo_color = rarity_color()
			var sz = [0.0, 3.4, 4.0, 4.8, 5.0][clamp(tier, 1, 4)]
			halo.scale = Vector3(sz, sz, sz)
			halo_base = 0.95
	halo_alpha = halo_base
	_apply_halo()
	# the rarity rim: a crisp ring behind the fry (not for the plain fry or the common tutorial fries)
	if tier >= 1 and ftype != "ordinary":
		rim = MeshInstance3D.new()
		var rq = QuadMesh.new()
		rq.size = Vector2(1, 1)
		rim.mesh = rq
		var rm = StandardMaterial3D.new()
		rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		rm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		rm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		rm.albedo_texture = _rim_texture()
		rm.albedo_color = Color(halo_color.r, halo_color.g, halo_color.b, 0.9)
		rm.disable_receive_shadows = true
		rim.material_override = rm
		rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var rs = [0.0, 1.7, 2.1, 2.6, 2.8][clamp(tier, 1, 4)]
		rim.scale = Vector3(rs, rs, rs)
		rim.position = Vector3(0, 0.3, 0)
		add_child(rim)
	# gentle glints so a fry catches the eye from far away
	if ftype != "ordinary":
		glints = CPUParticles3D.new()
		glints.amount = 8 + 3 * max(tier - 1, 0)
		glints.lifetime = 1.4
		glints.direction = Vector3.UP
		glints.spread = 30.0
		glints.initial_velocity_min = 0.2
		glints.initial_velocity_max = 0.6
		glints.gravity = Vector3.ZERO
		glints.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		glints.emission_sphere_radius = 0.3
		var gq = QuadMesh.new()
		gq.size = Vector2(0.07, 0.07)
		var gm = StandardMaterial3D.new()
		gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		gm.albedo_color = Color(1, 0.95, 0.7, 0.9) if tier <= 1 else Color(halo_color.r, halo_color.g, halo_color.b, 0.95).lightened(0.3)
		gm.albedo_texture = tex
		gq.material = gm
		glints.mesh = gq
		glints.position = Vector3(0, 0.3, 0)
		add_child(glints)

# a very faint wisp of steam: the one thing about the plain fry that is not a glow. Strength 0..1 (see main.gd hunger ladder).
func set_steam(level):
	if steam == null:
		steam = CPUParticles3D.new()
		steam.amount = 14
		steam.lifetime = 2.6
		steam.direction = Vector3.UP
		steam.spread = 14.0
		steam.initial_velocity_min = 0.35
		steam.initial_velocity_max = 0.7
		steam.gravity = Vector3(0, 0.12, 0)
		steam.scale_amount_min = 0.7
		steam.scale_amount_max = 1.6
		steam.local_coords = false
		var q = QuadMesh.new()
		q.size = Vector2(0.28, 0.28)
		var m = StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.albedo_texture = _glow_tex()
		m.albedo_color = Color(1.0, 0.97, 0.9, 0.0)
		q.material = m
		steam.mesh = q
		steam.position = Vector3(0, 0.25, 0)
		steam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(steam)
	steam.mesh.material.albedo_color = Color(1.0, 0.97, 0.9, 0.05 + 0.2 * clamp(level, 0.0, 1.0))
	steam.emitting = level > 0.01 and not consumed

var steam = null

func _build_sense_ring():
	# kept as an empty (hidden) node: Gull Sight is drawn by the HUD now, and the plain fry must never get a ring
	sense_ring = Node3D.new()
	add_child(sense_ring)

func _apply_halo():
	var m = halo.material_override
	m.albedo_color = Color(halo_color.r, halo_color.g, halo_color.b, halo_alpha)
	halo.visible = halo_alpha > 0.01 and not vanished
	if rim != null and not plain:
		rim.visible = halo_alpha > 0.01 and not vanished

func _process(delta):
	t += delta
	if vanished:
		return
	if plain:
		halo.visible = false
		return
	if tier >= 4 and not carried and halo != null:
		halo_color = rarity_color()
		_apply_halo()
		if rim != null:
			rim.material_override.albedo_color = Color(halo_color.r, halo_color.g, halo_color.b, 0.9)
	if rim != null:
		var pulse = 1.0 + 0.05 * sin(t * 2.4 + float(hash(id) % 7))
		var rs = [0.0, 1.7, 2.1, 2.6, 2.8][clamp(tier, 1, 4)] * pulse
		rim.scale = Vector3(rs, rs, rs)
	if (is_special() or ftype == "star") and not carried:
		visual.rotation.y += delta * 1.2
		visual.position.y = 0.05 + 0.05 * sin(t * 2.5)
	elif ftype == "tutorial" and not carried:
		visual.position.y = 0.02 * sin(t * 2.0)
	if not available and not carried and not consumed and ftype != "ordinary":
		halo.visible = int(t * 10.0) % 2 == 0
	elif not carried:
		halo.visible = halo_alpha > 0.01
	if glints != null:
		glints.emitting = (not carried) and revealed and (not consumed)

func reveal():
	revealed = true
	visible = true
	halo_alpha = 0.0
	var tw = create_tween()
	tw.tween_method(func(a):
		halo_alpha = a
		_apply_halo(), 0.0, halo_base, 1.0)
	var beam = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 0.06
	cm.bottom_radius = 0.09
	cm.height = 26.0
	beam.mesh = cm
	var bm = StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bm.albedo_color = Color(halo_color.r, halo_color.g, halo_color.b, 0.0)
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material_override = bm
	beam.position = Vector3(0, 13.0, 0)
	add_child(beam)
	var tb = create_tween()
	tb.tween_property(bm, "albedo_color:a", 0.5, 0.9)
	tb.tween_property(bm, "albedo_color:a", 0.0, 3.0)
	tb.tween_callback(beam.queue_free)

func attach(socket):
	carried = true
	reparent(socket, true)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "position", Vector3(0, -0.06, -0.04), 0.12)
	tw.tween_property(self, "rotation", Vector3.ZERO, 0.12)
	tw.tween_property(self, "scale", Vector3(0.42, 0.42, 0.42), 0.12)
	visual.rotation = Vector3.ZERO
	visual.position = Vector3.ZERO
	halo.visible = false
	if rim != null:
		rim.visible = false

# ---- shot down: the fry leaves the beak, hits the floor and is gone (the owner "reorders" a fresh one later) ----
func _ground_y(p):
	var q = PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.5, 0), p + Vector3(0, -40.0, 0), 1)
	var hit = get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return home_pos.y if home_pos != Vector3.ZERO else 0.0
	return hit["position"].y

func fall_and_vanish(restock_sec = 16.0):
	carried = false
	available = false
	var scene = get_tree().current_scene
	reparent(scene, true)
	scale = Vector3.ONE
	rotation = Vector3.ZERO
	visual.rotation = Vector3.ZERO
	visual.position = Vector3.ZERO
	var gp = global_position
	var gy = _ground_y(gp)
	var fall_t = clamp((gp.y - gy) * 0.1 + 0.3, 0.3, 0.9)
	var tw = create_tween()
	tw.tween_property(self, "global_position:y", gy + 0.05, fall_t).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(_splat)
	tw.tween_interval(0.55)
	tw.tween_property(visual, "scale", Vector3(0.01, 0.01, 0.01), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(_hide_vanished.bind(restock_sec))

# a rival gull got there first: the fry is simply gone (its owner reorders a fresh one later)
func rival_take(restock_sec = 14.0):
	if consumed or carried or vanished:
		return
	available = false
	if npc != null:
		npc.react("surprise")
		npc.look_at_pos(get_tree().get_first_node_in_group("player").global_position, 1.5)
	_hide_vanished(restock_sec)

func _splat():
	Sfx.play("land", -12.0, 1.4)
	var pr = CPUParticles3D.new()
	pr.amount = 14
	pr.one_shot = true
	pr.explosiveness = 1.0
	pr.lifetime = 0.7
	pr.direction = Vector3.UP
	pr.spread = 70.0
	pr.initial_velocity_min = 0.8
	pr.initial_velocity_max = 2.4
	pr.gravity = Vector3(0, -7, 0)
	var q = BoxMesh.new()
	q.size = Vector3(0.04, 0.14, 0.04)
	q.material = mat(GOLD, 0.3)
	pr.mesh = q
	get_parent().add_child(pr)
	pr.global_position = global_position + Vector3(0, 0.1, 0)
	pr.emitting = true
	get_tree().create_timer(1.2).timeout.connect(pr.queue_free)

func _hide_vanished(restock_sec):
	if consumed:
		return
	vanished = true
	visible = false
	halo.visible = false
	if rim != null:
		rim.visible = false
	if glints != null:
		glints.emitting = false
	if ftype == "star":
		consume()      # a star fry never reorders itself: the spawner hangs a new one somewhere else
		return
	get_tree().create_timer(restock_sec).timeout.connect(_try_restock)

func _try_restock():
	if consumed or not is_inside_tree():
		return
	var pl = get_tree().get_first_node_in_group("player")
	var anchor = npc.global_position if npc != null else home_pos
	var near = pl != null and pl.global_position.distance_to(anchor) < 14.0 and not id.begins_with("TUTORIAL")
	if near or (npc != null and (npc.gone or npc.leaving)):
		get_tree().create_timer(2.0).timeout.connect(_try_restock)
		return
	vanished = false
	visible = true
	scale = Vector3.ONE
	rotation = Vector3.ZERO
	visual.scale = Vector3.ONE
	if carrier == "hand" and npc != null and npc.hand_anchor != null:
		reparent(npc.hand_anchor, false)
		position = Vector3.ZERO
		home_parent = npc.hand_anchor
	else:
		reparent(home_parent, true)
		global_position = home_pos
	available = true
	halo_alpha = 0.0
	var tw = create_tween()
	tw.tween_method(func(a):
		halo_alpha = a
		_apply_halo(), 0.0, halo_base, 0.8)
	if glints != null:
		glints.emitting = true
	Sfx.play("chime", -20.0, 1.6)

func return_home():
	if consumed:
		return
	if carrier == "hand" and npc != null and npc.hand_anchor != null:
		reparent(npc.hand_anchor, false)
		position = Vector3(0, 0, 0)
		rotation = Vector3.ZERO
		home_parent = npc.hand_anchor
	available = true

func guard(sec):
	available = false
	get_tree().create_timer(sec).timeout.connect(func():
		if not carried and not consumed and not vanished:
			available = true)

func consume():
	consumed = true
	available = false
	visible = false
	remove_from_group("fries")
	get_tree().create_timer(0.6).timeout.connect(queue_free)

# Ordinary Fry convergence (docs/07): never a marker, only a halo that earns visibility.
# `longing` grows with star fries found and with time spent STILL HUNGRY.
func update_convergence(player_pos, player_fwd, delta):
	if consumed:
		return
	var n = GS.longing()
	var rng_ = 0.0
	var a = 0.0
	if n >= 12.0:
		rng_ = 25.0
		a = 0.8
	elif n >= 9.0:
		rng_ = 25.0
		a = 0.7
	elif n >= 6.0:
		rng_ = 18.0
		a = 0.5
	elif n >= 3.0:
		rng_ = 10.0
		a = 0.3
	var d = player_pos.distance_to(global_position)
	if rng_ > 0.0 and d < rng_:
		var k = clamp(1.0 - d / rng_, 0.0, 1.0)
		var pulse = 1.0
		if n >= 6.0:
			pulse = 0.8 + 0.2 * sin(t * 2.2)
		if n >= 9.0:
			pulse *= 0.85 + 0.15 * sin(t * 6.0)
		halo_alpha = a * clamp(k * 2.0, 0.0, 1.0) * pulse
	else:
		halo_alpha = 0.0
	_apply_halo()
	chime_cd -= delta
	if n >= 12.0 and chime_cd <= 0.0 and d < 35.0:
		var to = (global_position - player_pos).normalized()
		if player_fwd.dot(to) > cos(deg_to_rad(25.0)):
			chime_cd = 15.0
			Sfx.play("chime", -8.0)
