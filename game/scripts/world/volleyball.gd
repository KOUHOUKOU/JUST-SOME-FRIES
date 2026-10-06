extends Node3D
# A beach volleyball match. The ball really flies back and forth over the net; a gull that cuts through the court at the wrong moment
# gets a BOP (a hit like any swat: tumble, lost breath, a comic panel). Players are the ambient "play" people placed by the world builder.

var gull = null
var people = []          # 4 ambient npcs: west 0,1 / east 2,3
var ball
var st = 0.0
var dur = 1.5
var idx = 0
var from_p = Vector3.ZERO
var to_p = Vector3.ZERO
var arc = 4.6
var cool = 0.0
var hit_pause = 0.0
var net_x = 52.0
var lastpos = Vector3.ZERO
const Warn = preload("res://scripts/world/warn.gd")
var smash = ""            # "" | "wind" | "fly": the players deliberately spike the ball at a gull that hangs around the court
var smash_cd = 8.0
var near_t = 0.0
var smash_t = 0.0
var smash_hitter = null
var smash_target = Vector3.ZERO
var smash_from = Vector3.ZERO
var smash_lines = null

func setup(p_gull, p_people, p_net_x):
	gull = p_gull
	people = p_people
	net_x = p_net_x
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	ball = Node3D.new()
	add_child(ball)
	var white = StandardMaterial3D.new()
	white.albedo_color = Color("F8F6EE")
	white.roughness = 0.5
	var sm = SphereMesh.new()
	sm.radius = 0.25
	sm.height = 0.5
	sm.radial_segments = 14
	sm.rings = 8
	var bi = MeshInstance3D.new()
	bi.mesh = sm
	bi.material_override = white
	ball.add_child(bi)
	for k in 2:
		var band = MeshInstance3D.new()
		var tm = TorusMesh.new()
		tm.inner_radius = 0.236
		tm.outer_radius = 0.262
		tm.rings = 16
		tm.ring_segments = 6
		band.mesh = tm
		var bm = StandardMaterial3D.new()
		bm.albedo_color = Color("3D8CD9") if k == 0 else Color("F1C94B")
		band.material_override = bm
		band.rotation = Vector3(0, 0, 0) if k == 0 else Vector3(PI / 2.0, 0, 0)
		ball.add_child(band)

func _ready():
	if not people.is_empty():
		_next()

func _hand(i):
	var n = people[i % people.size()]
	return n.global_position + Vector3(0, 1.5, 0)

func _next():
	var order = [0, 2, 1, 3]
	var a = order[idx % 4]
	var b = order[(idx + 1) % 4]
	from_p = _hand(a)
	to_p = _hand(b)
	idx += 1
	st = 0.0
	dur = randf_range(1.35, 1.8)
	arc = randf_range(4.0, 5.4)
	# the hitter swings
	var hitter = people[a % people.size()]
	if hitter != null and is_instance_valid(hitter) and hitter.rig != null:
		hitter.rig.override_arm_r = -2.75
		get_tree().create_timer(0.3).timeout.connect(func():
			if is_instance_valid(hitter) and hitter.rig != null:
				hitter.rig.override_arm_r = null)
	if gull != null:
		var d = ball.global_position.distance_to(gull.global_position) if is_inside_tree() else 99.0
		Sfx.play("bop", clamp(-10.0 - d * 0.12, -32.0, -10.0), randf_range(0.9, 1.1))

func _smash_ok():
	if gull.mode == 2 or GS.gull_sense_count < 3 or GS.ordinary_eaten or gull.input_locked:
		return false
	var d2 = Vector2(gull.global_position.x - net_x, gull.global_position.z - global_position.z).length()
	return d2 < 22.0 and gull.global_position.y < 9.0 and gull.snatch.state == "idle" and gull.snatch.lock_fry == null

func _smash_step(delta):
	if smash == "":
		near_t = near_t + delta if _smash_ok() else 0.0
		smash_cd = max(smash_cd - delta, 0.0)
		if smash_cd <= 0.0 and near_t > 2.5:
			# the nearest player turns on the gull: a "!" pops over their head, the ball hangs in their hand, a red line shows the way
			var best = null
			var bd = 1e9
			for n in people:
				if is_instance_valid(n):
					var d = n.global_position.distance_to(gull.global_position)
					if d < bd:
						bd = d
						best = n
			if best == null or bd > 34.0:
				return false
			smash = "wind"
			smash_t = 0.0
			smash_hitter = best
			smash_target = gull.global_position
			Warn.bang(best, 2.5, 1.1)
			if best.rig != null:
				best.rig.override_arm_r = -2.8
			return true
		return false
	smash_t += delta
	var hand = smash_hitter.global_position + Vector3(0, 2.3, 0)
	if smash == "wind":
		ball.global_position = hand
		if smash_t < 0.75:
			smash_target = gull.global_position + gull.velocity * 0.25      # the aim follows you... until the last moment
		if int(smash_t * 8.0) != int((smash_t - delta) * 8.0) and smash_t < 0.75:
			if smash_lines != null and is_instance_valid(smash_lines):
				smash_lines.queue_free()
			smash_lines = Warn.line(get_tree().current_scene, hand, smash_target, 0.15)
		if smash_t >= 1.1:
			smash = "fly"
			smash_t = 0.0
			smash_from = hand
			Sfx.play("bop", -3.0, 0.8)
			if smash_hitter.rig != null:
				smash_hitter.rig.override_arm_r = -1.0
				var h = smash_hitter
				get_tree().create_timer(0.35).timeout.connect(func():
					if is_instance_valid(h) and h.rig != null:
						h.rig.override_arm_r = null)
		return true
	# the ball flies at 18 m/s along the line it was aimed on
	var dist = smash_from.distance_to(smash_target)
	var u = clamp(smash_t * 18.0 / max(dist, 1.0), 0.0, 1.0)
	ball.global_position = smash_from.lerp(smash_target, u)
	ball.rotation.x += delta * 14.0
	if cool <= 0.0 and gull.mode != 2 and gull.invuln_t <= 0.0 and ball.global_position.distance_to(gull.global_position) < 1.25:
		cool = 4.0
		GS.stats["bops"] += 1
		Sfx.play("bop", -4.0, 0.7)
		gull.get_swatted(self, "ball")
		u = 1.0
	if u >= 1.0 or smash_t > 2.5:
		smash = ""
		smash_cd = randf_range(11.0, 16.0)
		near_t = 0.0
		_next()
	return true

func _process(delta):
	if gull == null or not gull.active:
		return
	if people.is_empty():
		return
	var dist_g = global_position.distance_to(gull.global_position)
	if dist_g > 140.0:
		return
	cool = max(cool - delta, 0.0)
	if dist_g < 60.0 and _smash_step(delta):
		return
	st += delta
	var u = clamp(st / dur, 0.0, 1.0)
	var p = from_p.lerp(to_p, u)
	p.y += arc * 4.0 * u * (1.0 - u)
	ball.global_position = p
	ball.rotation.x += delta * 6.0
	# the hit
	if cool <= 0.0 and u > 0.06 and u < 0.94 and gull.mode != 2 and gull.invuln_t <= 0.0:
		if ball.global_position.distance_to(gull.global_position) < 1.2:
			cool = 4.0
			GS.stats["bops"] += 1
			Sfx.play("bop", -4.0, 0.7)
			gull.get_swatted(self, "ball")
	if u >= 1.0:
		_next()
