extends Node3D
# THE SEA IS FULL OF FISH (round 7). A fishing spot is a patch of open water. Every few seconds it plans a leap:
#   forecast (5 s)  -> only Gull Sight shows it: a ring on the water, the rarity of the fish and how fast the gull has to be
#   bubbles (2.4 s) -> foam and bubbles on the surface, for everybody
#   leap            -> the fish flies a long lazy arc (2.6 / 3.0 / 3.6 s). A gull that is fast enough, aims and presses E in the rhythm catches it
#   cooldown
# Nine kinds in three rarities (GS.FISH_SPECIES): common = 2 judgements, rare = 3, legendary = 5; every fish rolls its own length and weight and the
# fish book (Codex) keeps the biggest of each kind. The water column of a leap is checked: a fish never jumps through the pier, a boat or a dock.

const GullVisual = preload("res://scripts/player/gull_visual.gd")
const Terrain = preload("res://scripts/world/terrain.gd")

static var avoid_rects = []      # [x0, x1, z0, z1] areas of water that must stay free of leaps (the pier, the marina, the harbour...)
static var avoid_discs = []      # [Vector3 centre, radius] (sailing boats, buoys)
static var live = 0              # leaps being prepared / flying right now (at most MAX_LIVE at a time)
const MAX_LIVE = 4
const LEAP_SEC = [2.6, 3.0, 3.6]
const LEAP_H = [3.2, 3.8, 4.4]

# ---- the fish itself (the snatch code treats it like a decorative steal with ftype "fish") ----
class Fish extends Node3D:
	var ftype = "fish"
	var id = "FISH"
	var kind = "fish"
	var tier = 4
	var min_speed = 16.0
	var utype = ""
	var revealed = true
	var carried = false
	var vanished = false
	var npc = null
	var owner_amb = null
	var carrier = "none"
	var available = true
	var consumed = false
	var taken = false
	var spot = null
	var visual
	var species = "sardine"
	var rarity = 0
	var len_cm = 20.0
	var kg = 0.1
	var scl = 1.0
	var u = 0.0

	func _m(c, rough = 0.4, emit = 0.0):
		var m = StandardMaterial3D.new()
		m.albedo_color = Color(c)
		m.roughness = rough
		if emit > 0.0:
			m.emission_enabled = true
			m.emission = Color(c)
			m.emission_energy_multiplier = emit
		return m

	func _blob(parent, pos, scale_v, mat, r = 0.5):
		var mi = MeshInstance3D.new()
		var sm = SphereMesh.new()
		sm.radius = r
		sm.height = r * 2.0
		sm.radial_segments = 12
		sm.rings = 7
		mi.mesh = sm
		mi.scale = scale_v
		mi.material_override = mat
		mi.position = pos
		parent.add_child(mi)
		return mi

	func _fin(parent, pos, size, mat, rot = Vector3.ZERO):
		var mi = MeshInstance3D.new()
		var pm = PrismMesh.new()
		pm.size = size
		mi.mesh = pm
		mi.material_override = mat
		mi.position = pos
		mi.rotation = rot
		parent.add_child(mi)
		return mi

	func setup(p_spot, info):
		spot = p_spot
		species = info["sp"]
		len_cm = info["len"]
		kg = info["kg"]
		var d = GS.FISH_SPECIES[species]
		rarity = d[1]
		min_speed = GS.FISH_NEED[rarity] / GS.SPEED_UNIT
		scl = clamp(0.38 + len_cm / 95.0, 0.5, 2.7)
		add_to_group("mischief")
		physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		visual = Node3D.new()
		add_child(visual)
		var body_m = _m(d[6], 0.3, 0.22)
		var belly_m = _m(d[7], 0.4)
		var fin_m = _m(Color(d[6]).lerp(Color("E88A4C"), 0.55), 0.7)
		var dark_m = _m("101015", 0.6)
		# body proportions per kind (width, height, length of the ellipsoid)
		var bs = {"sardine": Vector3(0.16, 0.2, 0.85), "mackerel": Vector3(0.18, 0.22, 0.9), "herring": Vector3(0.14, 0.25, 0.85), "mullet": Vector3(0.2, 0.26, 0.8),
			"flyer": Vector3(0.16, 0.18, 0.85), "bass": Vector3(0.22, 0.3, 0.9), "tuna": Vector3(0.3, 0.36, 0.95), "opah": Vector3(0.11, 0.62, 0.72), "marlin": Vector3(0.2, 0.26, 1.0)}[species]
		_blob(visual, Vector3.ZERO, bs, body_m)
		_blob(visual, Vector3(0, -bs.y * 0.34, 0), Vector3(bs.x * 0.85, bs.y * 0.5, bs.z * 0.86), belly_m)
		for sx in [-1.0, 1.0]:
			_blob(visual, Vector3(bs.x * 0.55 * sx, bs.y * 0.2, -bs.z * 0.34), Vector3.ONE, dark_m, 0.028)
		var tail = _fin(visual, Vector3(0, 0, bs.z * 0.55 + 0.08), Vector3(0.05, bs.y * 1.4 + 0.1, 0.3), fin_m, Vector3(PI / 2.0, 0, 0))
		tail.name = "Tail"
		_fin(visual, Vector3(0, bs.y * 0.9, 0.05), Vector3(0.04, 0.16 + bs.y * 0.3, 0.3), fin_m)
		match species:
			"mackerel":
				for k in 4:
					var st = _blob(visual, Vector3(0, bs.y * 0.62, -0.28 + k * 0.17), Vector3(bs.x * 1.5, 0.05, 0.05), dark_m, 0.5)
					st.rotation.x = 0.0
			"mullet":
				_blob(visual, Vector3(0, bs.y * 0.1, 0.0), Vector3(bs.x * 2.05, 0.05, bs.z * 1.7), _m("F2D04A", 0.5), 0.5)
			"flyer":
				for sx in [-1.0, 1.0]:
					_fin(visual, Vector3(0.28 * sx, 0.04, -0.12), Vector3(0.5, 0.03, 0.34), _m("DCEBFA", 0.5), Vector3(0, 0, -0.5 * sx))
			"opah":
				for k in 8:
					var a = k * 0.8
					_blob(visual, Vector3(bs.x * 0.9 * (1.0 if k % 2 == 0 else -1.0), cos(a) * 0.3, sin(a) * 0.3), Vector3.ONE, _m("FFFFFF", 0.5), 0.035)
				_fin(visual, Vector3(0, -bs.y * 0.2, -0.05), Vector3(0.04, 0.22, 0.45), _m("E8452F", 0.5), Vector3(0, 0, 1.2))
			"marlin":
				var bill = MeshInstance3D.new()
				var cm = CylinderMesh.new()
				cm.top_radius = 0.0
				cm.bottom_radius = 0.045
				cm.height = 0.55
				bill.mesh = cm
				bill.material_override = dark_m
				bill.position = Vector3(0, 0, -bs.z * 0.5 - 0.3)
				bill.rotation = Vector3(PI / 2.0, 0, 0)
				visual.add_child(bill)
				_fin(visual, Vector3(0, bs.y * 1.1, -0.08), Vector3(0.03, 0.5, 0.75), _m("2F6FD0", 0.5))
			"tuna":
				for k in 5:
					_fin(visual, Vector3(0, bs.y * 0.5, 0.42 + k * 0.05), Vector3(0.02, 0.07, 0.07), _m("FFE24A", 0.5))
		visual.scale = Vector3.ONE * scl
		# a rarer fish glints so it can be seen from far away
		if rarity >= 1:
			var gl = CPUParticles3D.new()
			gl.amount = 14 + 10 * rarity
			gl.lifetime = 0.9
			gl.local_coords = false
			gl.direction = Vector3.UP
			gl.spread = 180.0
			gl.initial_velocity_min = 0.1
			gl.initial_velocity_max = 0.5
			gl.gravity = Vector3.ZERO
			gl.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			gl.emission_sphere_radius = 0.5 * scl
			var q = QuadMesh.new()
			q.size = Vector2(0.28, 0.28)
			var m = StandardMaterial3D.new()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			var rc = GS.FISH_RARITY_COLORS[rarity]
			m.albedo_color = Color(rc.r, rc.g, rc.b, 0.9)
			m.albedo_texture = GullVisual.star_tex()
			q.material = m
			gl.mesh = q
			add_child(gl)
			gl.emitting = true

	func is_snatchable():
		return available and not taken and visible
	func is_fry_like():
		return false
	func vision_info():
		return null
	func aim_point():
		return global_position
	func guard(_sec):
		escape()
	func escape():
		available = false
		if spot != null:
			spot.fish_gone(false)
	func attach(socket):
		reparent(socket, true)
		var tw = create_tween().set_parallel(true)
		tw.tween_property(self, "position", Vector3(0, -0.02, -0.08), 0.12)
		tw.tween_property(self, "rotation", Vector3(0, PI / 2.0, 0), 0.12)
		tw.tween_property(self, "scale", Vector3(0.55, 0.55, 0.55) / max(scl * 0.7, 0.7), 0.12)
	func stolen(player):
		taken = true
		consumed = true
		remove_from_group("mischief")
		GS.stats["fish"] += 1
		GS.flight_loot()
		GS.award("GONE FISHING")
		if GS.stats["fish"] >= 3:
			GS.award("SEA DOG")
		if rarity == 2:
			GS.award("BIG FISH ENERGY")
		var info = GS.fish_record({"sp": species, "len": len_cm, "kg": kg})
		GS.quest_finish("fish")
		GS.quests_check()
		player.refill()
		Sfx.play("splash", -8.0, 1.3)
		Sfx.play("happy", -4.0, 1.15)
		if rarity >= 1:
			Sfx.play("reward_%d" % (rarity + 0), -9.0, 1.2)
		if spot != null:
			spot.fish_gone(true)
		get_tree().create_timer(0.7).timeout.connect(queue_free)

var player = null
var water_y = -0.75
var state = "idle"
var st = 0.0
var wait = 6.0
var fish = null
var bubbles
var ripple
var ripple_mat
var foam
var foam_mat
var heading = 0.0
var leap_from = Vector3.ZERO
var leap_to = Vector3.ZERO
var leap_h = 3.4
var leap_dur = 2.6
var last_bubble = 0.0
var center = Vector3.ZERO
var region_r = 9.0
var plan = {}                  # the fish that is going to jump: {"sp", "len", "kg"} (rolled when the leap is planned)
var plan_rarity = 0
var forecast_t = 0.0           # real seconds left until the leap (forecast + bubbles): Gull Sight shows it
var holds_live = false

func setup(p_player, pos, p_water_y = -0.75, p_radius = 9.0):
	player = p_player
	water_y = p_water_y
	center = Vector3(pos.x, p_water_y, pos.z)
	region_r = p_radius
	position = center
	wait = randf_range(1.5, 9.0)
	heading = randf() * TAU
	add_to_group("fish_spots")
	# bubbles: soft blobs rising from the water
	bubbles = CPUParticles3D.new()
	bubbles.amount = 30
	bubbles.lifetime = 1.5
	bubbles.emitting = false
	bubbles.direction = Vector3.UP
	bubbles.spread = 25.0
	bubbles.initial_velocity_min = 0.3
	bubbles.initial_velocity_max = 0.9
	bubbles.gravity = Vector3(0, 0.15, 0)
	bubbles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	bubbles.emission_sphere_radius = 1.6
	bubbles.local_coords = true
	var q = QuadMesh.new()
	q.size = Vector2(0.6, 0.6)
	var bm = StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	bm.albedo_color = Color(1, 1, 1, 1.0)
	bm.albedo_texture = GullVisual.soft_tex()
	q.material = bm
	bubbles.mesh = q
	bubbles.scale_amount_min = 0.5
	bubbles.scale_amount_max = 1.5
	bubbles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(bubbles)
	# ripple ring on the surface
	ripple = MeshInstance3D.new()
	var tm = TorusMesh.new()
	tm.inner_radius = 0.82
	tm.outer_radius = 1.0
	tm.rings = 24
	tm.ring_segments = 6
	ripple.mesh = tm
	ripple_mat = StandardMaterial3D.new()
	ripple_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ripple_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ripple_mat.albedo_color = Color(1, 1, 1, 0.0)
	ripple.material_override = ripple_mat
	ripple.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ripple.position = Vector3(0, 0.06, 0)
	ripple.scale = Vector3(0.1, 1.0, 0.1)
	ripple.visible = false
	add_child(ripple)
	# a patch of foam: the first thing you see of a bubbling spot, even from far away
	foam = MeshInstance3D.new()
	var fc = CylinderMesh.new()
	fc.top_radius = 1.9
	fc.bottom_radius = 1.9
	fc.height = 0.02
	foam.mesh = fc
	foam_mat = StandardMaterial3D.new()
	foam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	foam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	foam_mat.albedo_color = Color(1, 1, 1, 0.0)
	foam.material_override = foam_mat
	foam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	foam.position = Vector3(0, 0.05, 0)
	foam.visible = false
	add_child(foam)

# ---------------------------------------------------------------- is this patch of water free of everything that a leaping fish could hit?
func _in_avoid(x, z, margin):
	for r in avoid_rects:
		if x > r[0] - margin and x < r[1] + margin and z > r[2] - margin and z < r[3] + margin:
			return true
	for dsc in avoid_discs:
		if Vector2(x, z).distance_to(Vector2(dsc[0].x, dsc[0].z)) < dsc[1] + margin:
			return true
	return false

func _blocked(p, r = 1.2):
	var sh = SphereShape3D.new()
	sh.radius = r
	var qy = PhysicsShapeQueryParameters3D.new()
	qy.shape = sh
	qy.collision_mask = 1
	var space = get_world_3d().direct_space_state
	for h in [0.5, 1.6, 2.8, 4.0, 5.2]:
		qy.transform = Transform3D(Basis.IDENTITY, Vector3(p.x, water_y + h, p.z))
		if not space.intersect_shape(qy, 1).is_empty():
			return true
	return false

# the whole arc (from, to, peak) has clear water under and above it
func _path_free(a, b, margin):
	for i in 6:
		var p = a.lerp(b, i / 5.0)
		if _in_avoid(p.x, p.z, margin):
			return false
		if Terrain.H(p.x, p.z) > water_y - 0.15:
			return false           # land
		if _blocked(p):
			return false
	return true

func _plan_leap():
	var sp = GS.fish_pick_species()
	plan = GS.fish_roll(sp)
	plan_rarity = GS.FISH_SPECIES[sp][1]
	leap_dur = LEAP_SEC[plan_rarity]
	leap_h = LEAP_H[plan_rarity]
	var reach = 2.2 + plan_rarity * 0.5
	for i in 16:
		var ang = randf() * TAU
		var rad = sqrt(randf()) * region_r
		var c = Vector3(center.x + cos(ang) * rad, water_y, center.z + sin(ang) * rad)
		var hd = randf() * TAU
		var dir = Vector3(cos(hd), 0, sin(hd))
		var a = c - dir * (reach * 0.5 + 0.6)
		var b = c + dir * (reach * 0.5 + 1.2)
		if _path_free(a, b, 2.0):
			position = c
			heading = hd
			leap_from = a
			leap_to = b
			return true
	return false

func _process(delta):
	if player == null or not player.active:
		return
	var d = global_position.distance_to(player.global_position)
	var rdt = delta / max(Engine.time_scale, 0.05)
	match state:
		"idle":
			if GS.gull_sense_count < 3 or GS.ordinary_eaten or d > 110.0:
				return
			wait -= delta
			if wait <= 0.0:
				if live >= MAX_LIVE:
					wait = 1.5
					return
				if _plan_leap():
					state = "forecast"
					st = 0.0
					live += 1
					holds_live = true
					forecast_t = 5.0 + 2.4
				else:
					wait = 3.0
			return
		"forecast":
			st += rdt
			forecast_t = 5.0 + 2.4 - st
			if st >= 5.0:
				_begin_bubbles()
			return
	st += delta
	match state:
		"bubbles":
			var k = st / 2.4
			forecast_t = max(2.4 - st, 0.0)
			ripple.visible = true
			var phase = fmod(st, 0.9) / 0.9
			ripple.scale = Vector3(0.4 + phase * 5.0, 1.0, 0.4 + phase * 5.0)
			ripple_mat.albedo_color = Color(1, 1, 1, (1.0 - phase) * 0.8)
			foam.visible = true
			foam.scale = Vector3.ONE * (1.0 + 0.12 * sin(st * 9.0))
			foam_mat.albedo_color = Color(1, 1, 1, clamp(st / 0.8, 0.0, 1.0) * 0.55)
			bubbles.amount = int(lerp(14.0, 40.0, clamp(k, 0.0, 1.0)))
			if st - last_bubble > 0.5:
				last_bubble = st
				_bubble_sound(d, 0.7 + 0.5 * k)
			if st >= 2.4:
				_begin_leap()
		"leap":
			_leap_step()
		"cooldown":
			if st >= wait:
				state = "idle"
				wait = randf_range(3.0, 10.0)

func _bubble_sound(d, pitch):
	var v = clamp(-9.0 - d * 0.16, -34.0, -9.0)
	Sfx.play("bubble", v, pitch)

func _begin_bubbles():
	state = "bubbles"
	st = 0.0
	last_bubble = -1.0
	bubbles.emitting = true
	ripple.visible = true

# what Gull Sight shows (null when nothing is planned here): the spot of the water, the seconds left, the rarity of the fish
func sight_info():
	if state != "forecast" and state != "bubbles":
		return null
	return {"pos": global_position + Vector3(0, 0.1, 0), "t": forecast_t, "rarity": plan_rarity, "need": GS.FISH_NEED[plan_rarity]}

func _begin_leap():
	state = "leap"
	st = 0.0
	bubbles.emitting = false
	ripple.visible = false
	foam.visible = false
	forecast_t = 0.0
	fish = Fish.new()
	fish.setup(self, plan)
	get_parent().add_child(fish)
	fish.global_position = leap_from
	_splash(leap_from)
	Sfx.play("splash", clamp(-8.0 - global_position.distance_to(player.global_position) * 0.12, -30.0, -8.0), 1.2)

func _leap_step():
	if fish == null or not is_instance_valid(fish):
		_release()
		state = "cooldown"
		wait = 8.0
		st = 0.0
		return
	var dur = leap_dur
	var u = clamp(st / dur, 0.0, 1.0)
	# a long, lazy arc: a lot of time near the top so that a fast gull has a chance
	var yy = water_y - 0.2 + leap_h * (1.0 - pow(2.0 * u - 1.0, 2.0))
	var p = leap_from.lerp(leap_to, u)
	fish.global_position = Vector3(p.x, yy, p.z)
	var vy = -leap_h * 2.0 * (2.0 * u - 1.0) * 2.0 / dur
	var dir = (leap_to - leap_from).normalized()
	var look = fish.global_position + Vector3(dir.x * 3.0, vy * 0.5, dir.z * 3.0)
	if look.distance_to(fish.global_position) > 0.01:
		fish.look_at(look, Vector3.UP)
	var tail = fish.visual.get_node_or_null("Tail")
	if tail != null:
		tail.rotation.y = sin(st * 18.0) * 0.5
	if u >= 1.0:
		_splash(fish.global_position)
		Sfx.play("splash", clamp(-8.0 - global_position.distance_to(player.global_position) * 0.12, -30.0, -8.0), 0.9)
		fish_gone(false)

func _release():
	if holds_live:
		holds_live = false
		live = max(live - 1, 0)

# the fish is gone (caught, spooked, or it simply fell back in)
func fish_gone(caught):
	if fish != null and is_instance_valid(fish) and not caught:
		fish.queue_free()
	fish = null
	_release()
	state = "cooldown"
	st = 0.0
	wait = 20.0 if caught else randf_range(6.0, 14.0)

func _splash(pos):
	var p = CPUParticles3D.new()
	p.amount = 34
	p.lifetime = 0.8
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 55.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 5.0
	p.gravity = Vector3(0, -9.0, 0)
	var q = QuadMesh.new()
	q.size = Vector2(0.2, 0.2)
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = Color(0.9, 0.97, 1.0, 0.85)
	m.albedo_texture = GullVisual.soft_tex()
	q.material = m
	p.mesh = q
	get_parent().add_child(p)
	p.global_position = Vector3(pos.x, water_y + 0.05, pos.z)
	p.emitting = true
	get_tree().create_timer(1.4).timeout.connect(p.queue_free)
