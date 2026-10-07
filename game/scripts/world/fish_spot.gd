extends Node3D
# A little fishing easter egg: now and then the water bubbles (the sign), a few seconds later a fish leaps out for about two seconds.
# A gull that comes in fast enough (gauge 58), aims at it and presses E on a very narrow ring catches it. This is the hardest check in
# the game (narrowest ring, fastest ring), and it is optional: the reward is a laugh, a full breath and a place in the credits.
#   idle -> bubbles (3.2 s) -> leap (2.3 s) -> cooldown

const GullVisual = preload("res://scripts/player/gull_visual.gd")

# ---- the fish itself (the snatch code treats it like a decorative steal with ftype "fish") ----
class Fish extends Node3D:
	var ftype = "fish"
	var id = "FISH"
	var kind = "fish"
	var tier = 4
	var min_speed = 14.0
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
	var u = 0.0
	func setup(p_spot):
		spot = p_spot
		add_to_group("mischief")
		physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		visual = Node3D.new()
		add_child(visual)
		var body_m = StandardMaterial3D.new()
		body_m.albedo_color = Color("7FA9BD")
		body_m.roughness = 0.35
		body_m.emission_enabled = true
		body_m.emission = Color("9CC7E0")
		body_m.emission_energy_multiplier = 0.25
		var belly_m = StandardMaterial3D.new()
		belly_m.albedo_color = Color("F2F5F7")
		belly_m.roughness = 0.4
		var fin_m = StandardMaterial3D.new()
		fin_m.albedo_color = Color("E88A4C")
		fin_m.roughness = 0.7
		var body = MeshInstance3D.new()
		var sm = SphereMesh.new()
		sm.radius = 0.5
		sm.height = 1.0
		sm.radial_segments = 14
		sm.rings = 8
		body.mesh = sm
		body.scale = Vector3(0.2, 0.22, 0.85)
		body.material_override = body_m
		visual.add_child(body)
		var belly = MeshInstance3D.new()
		belly.mesh = sm
		belly.scale = Vector3(0.17, 0.12, 0.74)
		belly.position = Vector3(0, -0.07, 0)
		belly.material_override = belly_m
		visual.add_child(belly)
		for sx in [-1.0, 1.0]:
			var eye = MeshInstance3D.new()
			var es = SphereMesh.new()
			es.radius = 0.028
			es.height = 0.056
			eye.mesh = es
			var em = StandardMaterial3D.new()
			em.albedo_color = Color("101015")
			eye.material_override = em
			eye.position = Vector3(0.085 * sx, 0.04, -0.3)
			visual.add_child(eye)
		var tail = MeshInstance3D.new()
		var pm = PrismMesh.new()
		pm.size = Vector3(0.05, 0.3, 0.26)
		tail.mesh = pm
		tail.material_override = fin_m
		tail.position = Vector3(0, 0, 0.5)
		tail.rotation = Vector3(PI / 2.0, 0, 0)
		tail.name = "Tail"
		visual.add_child(tail)
		var dorsal = MeshInstance3D.new()
		var dm = PrismMesh.new()
		dm.size = Vector3(0.04, 0.16, 0.3)
		dorsal.mesh = dm
		dorsal.material_override = fin_m
		dorsal.position = Vector3(0, 0.2, 0.05)
		visual.add_child(dorsal)
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
		tw.tween_property(self, "scale", Vector3(0.55, 0.55, 0.55), 0.12)
	func stolen(player):
		taken = true
		consumed = true
		remove_from_group("mischief")
		GS.stats["fish"] += 1
		GS.award("GONE FISHING")
		GS.quest_finish("fish")
		if GS.stats["fish"] >= 3:
			GS.award("SEA DOG")
		player.refill()
		Sfx.play("splash", -8.0, 1.3)
		Sfx.play("happy", -4.0, 1.15)
		if spot != null:
			spot.fish_gone(true)
		get_tree().create_timer(0.7).timeout.connect(queue_free)

var player = null
var water_y = -0.75
var state = "idle"
var st = 0.0
var wait = 12.0
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
var last_bubble = 0.0

func setup(p_player, pos, p_water_y = -0.75):
	player = p_player
	water_y = p_water_y
	position = Vector3(pos.x, p_water_y, pos.z)
	wait = randf_range(5.0, 18.0)
	heading = randf() * TAU
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

func _process(delta):
	if player == null or not player.active:
		return
	# an idle spot far from the gull does nothing (and costs nothing)
	var d = global_position.distance_to(player.global_position)
	if state == "idle":
		if GS.gull_sense_count < 3 or GS.ordinary_eaten or d > 170.0:
			return
		wait -= delta
		if wait <= 0.0 and d < 150.0:
			_begin_bubbles()
		return
	st += delta
	match state:
		"bubbles":
			var k = st / 3.2
			ripple.visible = true
			var phase = fmod(st, 1.05) / 1.05
			ripple.scale = Vector3(0.4 + phase * 5.0, 1.0, 0.4 + phase * 5.0)
			ripple_mat.albedo_color = Color(1, 1, 1, (1.0 - phase) * 0.8)
			foam.visible = true
			foam.scale = Vector3.ONE * (1.0 + 0.12 * sin(st * 9.0))
			foam_mat.albedo_color = Color(1, 1, 1, clamp(st / 0.8, 0.0, 1.0) * 0.55)
			bubbles.amount = int(lerp(14.0, 40.0, clamp(k, 0.0, 1.0)))
			if st - last_bubble > 0.55:
				last_bubble = st
				_bubble_sound(d, 0.7 + 0.5 * k)
			if st >= 3.2:
				_begin_leap()
		"leap":
			_leap_step()
		"cooldown":
			if st >= wait:
				state = "idle"
				wait = randf_range(14.0, 34.0)

func _bubble_sound(d, pitch):
	var v = clamp(-9.0 - d * 0.16, -34.0, -9.0)
	Sfx.play("bubble", v, pitch)

func _begin_bubbles():
	state = "bubbles"
	st = 0.0
	last_bubble = -1.0
	bubbles.emitting = true
	ripple.visible = true

func _begin_leap():
	state = "leap"
	st = 0.0
	bubbles.emitting = false
	ripple.visible = false
	foam.visible = false
	heading = randf() * TAU
	var dir = Vector3(cos(heading), 0, sin(heading))
	leap_from = global_position + Vector3(0, 0.0, 0) - dir * 0.8
	leap_to = global_position + dir * 2.0
	leap_h = 3.6
	fish = Fish.new()
	fish.setup(self)
	get_parent().add_child(fish)
	fish.global_position = leap_from
	_splash(leap_from)
	Sfx.play("splash", clamp(-8.0 - global_position.distance_to(player.global_position) * 0.12, -30.0, -8.0), 1.2)

func _leap_step():
	if fish == null or not is_instance_valid(fish):
		state = "cooldown"
		wait = 20.0
		st = 0.0
		return
	var dur = 2.3
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

# the fish is gone (caught, spooked, or it simply fell back in)
func fish_gone(caught):
	if fish != null and is_instance_valid(fish) and not caught:
		fish.queue_free()
	fish = null
	state = "cooldown"
	st = 0.0
	wait = 70.0 if caught else randf_range(18.0, 36.0)

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
