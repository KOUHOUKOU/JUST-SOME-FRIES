extends CharacterBody3D
# PlayerGull v2 — fighter-style flight (docs/18 §2), stamina fuel + perch recovery (§3),
# collisions with consequences (§2.3), camera rig. Snatching lives in snatch_controller.gd.
# Gameplay never depends on the visual; hero_gull.glb is an optional replacement.

signal escaped(fry)
signal ate_ordinary(fry)
signal tumbled
signal landed(high)

const SnatchScript = preload("res://scripts/player/snatch_controller.gd")
const VisualScript = preload("res://scripts/player/gull_visual.gd")

const WATER_Y = -0.75
const GROUND_SPEED = 2.2
const CAM_TABLE = [[2.5, 62.0, 3.6], [5.0, 66.0, 4.0], [11.0, 74.0, 5.2], [19.0, 92.0, 7.5], [25.0, 104.0, 9.4], [30.0, 110.0, 10.5]]
const TURN_TABLE = [[2.5, 8.0], [5.0, 7.0], [11.0, 4.5], [19.0, 2.0], [25.0, 1.6], [30.0, 1.4]]

enum M { FLY, GROUND, TUMBLE }

var mode = M.FLY
var active = false
var input_locked = false
var yaw = PI
var pitch = 0.0
var aim_yaw = PI
var aim_pitch = 0.0
var speed = 5.0
var vert_boost = 0.0
var lift_now = 0.0
var stamina = 100.0
var since_spend = 0.0
var boost_locked = false
var boosting = false
var landing = false             # Ctrl held: come down now
var drunk_t = 0.0
var ground_drink_t = 0.0
var scripted_move = false      # an ending cutscene moves the gull: no flight code, no collisions
var drunk_dir = 0.0
var throttling = false
var braking = false
var regen_active = false
var flap_cd = 0.0
var flap_anim = 0.0
var roll_t = 0.0
var roll_dir = 0.0
var roll_cd = 0.0
var invuln_t = 0.0
var tumble_t = 0.0
var soaked_t = 0.0
var splash_cd = 0.0
var knock = Vector3.ZERO
var mouse_accum = Vector2.ZERO
var last_tap = {"bank_left": -9.0, "bank_right": -9.0}
var yaw_rate = 0.0
var roll = 0.0
var walk_t = 0.0
var still_t = 0.0
var calm = 0.0
var shake = 0.0
var fov_kick = 0.0
var low_stamina = false
var perch_high = false
var off_floor_t = 0.0
var skim_t = 0.0
var focus = 0.0                # 0..1 blend of the bullet-time look (zoom + faster steering)
var vision = 0.0               # 0..1 blend of Gull Sight (wider eye, faster steering to compensate the slow motion)
var speed_target = 5.0         # what the speed is heading to (shown on the speed gauge)
var accel_now = 0.0            # smoothed m/s^2 (gauge arrows)
var thermal_t = 0.0
var ground_h = null
var air_zones = []
var carry_fry = null          # mirrored from the snatch controller for NPC scripts
var swat_window = 0.0
var respawn_point = Vector3(-9.5, 12.0, -2.0)

var visual_root
var gull
var beak_socket
var snatch
var rig
var arm
var cam
var cine_cam
var spray
var drip
var cam_yaw = PI
var cam_pitch = 0.0
var cam_dist = 4.0
var cam_fov = 66.0
var ov_xf = Transform3D.IDENTITY
var ov_fov = 40.0
var ov_goal = 0.0
var ov_w = 0.0
var ov_rate = 8.0

func _ready():
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	floor_max_angle = deg_to_rad(50.0)
	floor_snap_length = 0.0
	var cs = CollisionShape3D.new()
	var sh = SphereShape3D.new()
	sh.radius = 0.38
	cs.shape = sh
	add_child(cs)
	visual_root = Node3D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)
	gull = Node3D.new()
	gull.set_script(VisualScript)
	gull.tracked = true
	visual_root.add_child(gull)
	gull.build()
	visual_root.scale = Vector3.ONE * 1.3
	beak_socket = gull.beak_socket
	_try_load_hero()
	snatch = Node.new()
	snatch.name = "Snatch"
	snatch.set_script(SnatchScript)
	snatch.player = self
	add_child(snatch)
	rig = Node3D.new()
	rig.name = "CameraRig"
	rig.top_level = true
	rig.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(rig)
	arm = SpringArm3D.new()
	arm.spring_length = cam_dist
	arm.collision_mask = 1
	arm.margin = 0.3
	rig.add_child(arm)
	cam = Camera3D.new()
	cam.fov = cam_fov
	cam.near = 0.1
	cam.far = 2000.0
	arm.add_child(cam)
	cam.current = true
	cine_cam = Camera3D.new()
	cine_cam.top_level = true
	cine_cam.near = 0.05
	cine_cam.far = 2000.0
	cine_cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(cine_cam)
	spray = _make_particles(Color(0.85, 0.95, 1.0, 0.7), 0.18, 60, 0.7)
	spray.top_level = true
	spray.direction = Vector3.UP
	spray.spread = 40.0
	spray.initial_velocity_min = 1.5
	spray.initial_velocity_max = 4.0
	spray.gravity = Vector3(0, -7, 0)
	add_child(spray)
	drip = _make_particles(Color(0.7, 0.85, 1.0, 0.8), 0.07, 30, 0.6)
	drip.direction = Vector3.DOWN
	drip.spread = 20.0
	drip.initial_velocity_min = 0.5
	drip.initial_velocity_max = 1.0
	drip.gravity = Vector3(0, -6, 0)
	drip.local_coords = false
	add_child(drip)
	stamina = GS.stamina_max()
	GS.special_collected.connect(func(_k): gull.apply_growth())
	update_camera(0.0, true)

func _make_particles(col, size, amount, life):
	var p = CPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.emitting = false
	var q = QuadMesh.new()
	q.size = Vector2(size, size)
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = col
	m.albedo_texture = VisualScript.soft_tex()
	q.material = m
	p.mesh = q
	return p

func _try_load_hero():
	if ResourceLoader.exists("res://assets/models/hero_gull.glb"):
		var scn = load("res://assets/models/hero_gull.glb")
		if scn is PackedScene:
			var inst = scn.instantiate()
			visual_root.add_child(inst)
			gull.visible = false
			var bs = Marker3D.new()
			bs.position = Vector3(0, 0.0, -0.6)
			visual_root.add_child(bs)
			beak_socket = bs

func _input(event):
	if event is InputEventMouseMotion and active and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_accum += event.relative

# ------------------------------------------------------------------ public helpers
func refill():
	stamina = GS.stamina_max()

func spend(a):
	stamina = max(stamina - a, 0.0)
	since_spend = 0.0

func show_toast(txt, sec = 0.8):
	snatch.toast = txt
	snatch.toast_t = sec

func is_vulnerable():
	return snatch.carry_fry != null or swat_window > 0.0

# a short roll that lets the gull slip a swing (the reward for a good escape check)
func dodge_flourish():
	roll_t = 0.45
	roll_dir = 1.0 if randf() < 0.5 else -1.0
	invuln_t = 0.7
	knock += Vector3(cos(yaw), 0, -sin(yaw)) * roll_dir * 6.0
	fov_kick = 5.0
	Sfx.play("roll", -6.0)

func get_swatted(from_npc, kind = "punch"):
	if invuln_t > 0.0:
		GS.award("DODGE")
		GS.stats["slipped"] += 1
		Sfx.play("whoosh", -6.0, 1.3)
		fov_kick = 6.0
		show_toast("DODGE", 0.7)
		return
	GS.stats["swats"] += 1
	GS.player_hurt.emit("swat_" + kind, snatch.carry_fry != null)
	snatch.on_hit()
	var away = global_position - from_npc.global_position
	away.y = 0.0
	if away.length() < 0.05:
		away = Vector3(sin(yaw), 0.0, cos(yaw))
	GS.add_heat(1.0)
	# FLUFF fries (orange) soften every hit: less damage, less time on the floor
	start_tumble(away.normalized() * 6.0 + Vector3(0, 3.0, 0), 30.0 * GS.hurt_mult(), 1.2 * GS.stun_mult())
	Sfx.play("thud")
	Sfx.play("cry", -4.0, 1.1)

# a fright that is not a hit: a kid yelling "BOO", a gull-sized dog bark... the gull hops into the air and loses a little breath
func startle(from_pos, amount = 6.0):
	if invuln_t > 0.0 or mode == M.TUMBLE:
		return
	GS.stats["scares"] += 1
	spend(amount * GS.hurt_mult())
	var away = global_position - from_pos
	away.y = 0.0
	if away.length() < 0.05:
		away = Vector3(sin(yaw), 0.0, cos(yaw))
	knock += away.normalized() * 5.0
	mode = M.FLY
	speed = max(speed, 4.5)
	vert_boost = 6.5
	pitch = 0.3
	aim_pitch = 0.3
	flap_anim = 0.4
	fov_kick = 4.0
	shake = max(shake, 0.25)
	Sfx.play("cry", -8.0, 1.25)

func start_tumble(kick, dmg, dur):
	if mode == M.TUMBLE:
		return
	mode = M.TUMBLE
	tumble_t = dur
	velocity = kick
	speed = 2.0
	spend(dmg)
	shake = 0.8
	roll_t = 0.0
	boosting = false
	throttling = false
	tumbled.emit()
	if snatch.carry_fry != null:
		snatch.drop_carry()
	Sfx.play("tumble", -4.0)

func set_override(xf, fov, goal, rate = 8.0):
	ov_xf = xf
	ov_fov = fov
	ov_goal = goal
	ov_rate = rate

# ------------------------------------------------------------------ physics
func _physics_process(delta):
	if not active:
		return
	if scripted_move:
		return
	var mouse = mouse_accum
	mouse_accum = Vector2.ZERO
	if input_locked:
		mouse = Vector2.ZERO
	flap_cd = max(flap_cd - delta, 0.0)
	flap_anim = max(flap_anim - delta, 0.0)
	roll_cd = max(roll_cd - delta, 0.0)
	invuln_t = max(invuln_t - delta, 0.0)
	soaked_t = max(soaked_t - delta, 0.0)
	splash_cd = max(splash_cd - delta, 0.0)
	swat_window = max(swat_window - delta, 0.0)
	since_spend += delta
	GS.dash_cooldown_changed.emit(1.0 - roll_cd / 1.0)
	if GS.sense_active:
		# Gull Sight costs stamina per REAL second (the world is slowed down while it is held)
		var real_dt = delta / max(Engine.time_scale, 0.05)
		var cost = GS.vision_cost() if mode == M.FLY else 0.0
		GS.stats["vision_s"] += real_dt
		if cost > 0.0:
			stamina = max(stamina - cost * real_dt, 0.0)
			since_spend = 0.0
			if stamina <= 0.0:
				GS.vision_tired = true
	match mode:
		M.FLY:
			_fly(delta, mouse)
		M.GROUND:
			_ground(delta, mouse)
		M.TUMBLE:
			_tumble(delta)
	var smax = GS.stamina_max()
	stamina = clamp(stamina, 0.0, smax)
	low_stamina = stamina < smax * 0.2
	GS.stamina_changed.emit(stamina, smax)
	carry_fry = snatch.carry_fry
	snatch.step(delta)
	knock = knock.move_toward(Vector3.ZERO, 14.0 * delta)
	_safety()

func _interp(table, x, col):
	if x <= table[0][0]:
		return table[0][col]
	for i in range(1, table.size()):
		if x <= table[i][0]:
			var u = (x - table[i - 1][0]) / (table[i][0] - table[i - 1][0])
			return lerp(table[i - 1][col], table[i][col], u)
	return table[table.size() - 1][col]

func _zone_lift(p):
	var best = 0.0
	for z in air_zones:
		var dx = p.x - z["pos"].x
		var dz = p.z - z["pos"].z
		var d = sqrt(dx * dx + dz * dz)
		if d < z["r"] and p.y > z["pos"].y and p.y < z["pos"].y + z["h"]:
			var f = clamp((1.0 - d / z["r"]) * 2.0, 0.0, 1.0)
			best = max(best, z["lift"] * f)
	return best

func _fly(delta, mouse):
	var sens = 0.0022 * GS.mouse_sens_mult
	var bank = 0.0 if input_locked else Input.get_axis("bank_left", "bank_right")
	landing = (not input_locked) and Input.is_action_pressed("land")
	var want_boost = (not input_locked) and Input.is_action_pressed("dash") and not landing
	var want_throttle = (not input_locked) and Input.is_action_pressed("move_forward") and not landing
	braking = (not input_locked) and Input.is_action_pressed("move_back")
	if boost_locked and stamina >= 15.0:
		boost_locked = false
	var was_boost = boosting
	boosting = want_boost and stamina > 0.0 and not boost_locked
	if want_boost and stamina <= 0.0:
		boost_locked = true
	throttling = want_throttle and stamina > 0.0 and not boosting
	if boosting and not was_boost:
		Sfx.play("boost", -5.0)
		fov_kick = 3.0
	var drain = 0.0
	if boosting:
		drain = 18.0
	elif throttling:
		drain = 3.0
	if drain > 0.0:
		stamina = max(stamina - drain * delta, 0.0)
		since_spend = 0.0
		if stamina <= 0.0 and boosting:
			boost_locked = true
	# aiming: the target heading follows the mouse; the bird follows it at a speed-limited rate
	aim_yaw += -mouse.x * sens - bank * 2.0 * delta
	if GS.drink == "alcohol" and not input_locked:
		# a slow, wide sway (not a random jerk): the gull cannot quite hold a line
		drunk_t += delta
		aim_yaw += (sin(drunk_t * 1.1) * 0.5 + sin(drunk_t * 2.3 + 1.3) * 0.28) * delta
		aim_pitch += sin(drunk_t * 0.9 + 0.6) * 0.12 * delta
	elif GS.drink == "coffee" and not input_locked:
		drunk_t += delta
		aim_yaw += sin(drunk_t * 17.0) * 0.012
	aim_pitch = clamp(aim_pitch - mouse.y * sens * (-1.0 if GS.invert_y else 1.0), deg_to_rad(-60.0), deg_to_rad(45.0))
	var rate = _interp(TURN_TABLE, speed, 1) * max(lerp(1.0, 2.8, focus), lerp(1.0, 3.2, vision))
	var dyaw_goal = clamp(angle_difference(yaw, aim_yaw), -1.3, 1.3)
	aim_yaw = yaw + dyaw_goal
	var step_y = clamp(dyaw_goal, -rate * delta, rate * delta)
	yaw += step_y
	var step_p = clamp(aim_pitch - pitch, -rate * 0.8 * delta, rate * 0.8 * delta)
	pitch += step_p
	yaw_rate = lerp(yaw_rate, step_y / max(delta, 0.001), 1.0 - exp(-10.0 * delta))
	# double tap A/D = barrel roll dodge
	if not input_locked:
		for k in ["bank_left", "bank_right"]:
			if Input.is_action_just_pressed(k):
				var now = GS.msec() / 1000.0
				if now - last_tap[k] < 0.28 and roll_cd <= 0.0 and stamina >= 10.0 and roll_t <= 0.0:
					_start_roll(1.0 if k == "bank_right" else -1.0)
				last_tap[k] = now
	if roll_t > 0.0:
		roll_t = max(roll_t - delta, 0.0)
	# speed
	var target = GS.glide_speed()
	if boosting:
		target = GS.boost_speed()
	elif throttling:
		target = GS.cruise_speed()
	elif braking:
		target = 2.5
	elif landing:
		target = 3.0
	var sp = sin(pitch)
	var dive = 0.0
	if sp < 0.0 and not braking and not boosting:
		dive = -sp
		target = min(target + dive * 9.0, max(target, 16.0))
	elif sp > 0.0:
		target = max(target - sp * 3.5, 2.5)
	if soaked_t > 0.0:
		target *= 0.85
	if input_locked:
		target = speed
	speed_target = target
	var speed_before = speed
	if speed < target:
		var acc = 3.0
		if boosting:
			acc = 8.0
		elif throttling:
			acc = 4.0
		# TAILWIND fries change only THIS: a long runway at first, a snappy start once maxed. Top speeds never change.
		acc *= GS.accel_mult() * (1.0 + dive * 1.5)
		speed = move_toward(speed, target, acc * delta)
	else:
		speed = move_toward(speed, target, (18.0 if landing else (8.0 if was_boost and not boosting else 4.0)) * delta)
	accel_now = lerp(accel_now, (speed - speed_before) / max(delta, 0.0001), 1.0 - exp(-10.0 * delta))
	# flap
	if not input_locked and Input.is_action_just_pressed("flap"):
		if flap_cd <= 0.0 and stamina >= 6.0:
			spend(6.0)
			flap_cd = 0.3
			flap_anim = 0.4
			vert_boost = max(vert_boost, 0.0) + 6.5
			Sfx.play("flap", -9.0, randf_range(0.9, 1.1))
		elif stamina < 6.0:
			Sfx.play("tooslow", -16.0)
	vert_boost = move_toward(vert_boost, 0.0, 9.0 * delta)
	# thermals
	var lift_t = _zone_lift(global_position)
	lift_now = move_toward(lift_now, lift_t, 8.0 * delta)
	if lift_now > 1.5:
		thermal_t += delta
		if thermal_t > 4.0:
			GS.award("THERMAL RIDER")
	else:
		thermal_t = max(thermal_t - delta, 0.0)
	var sink = 0.8 if (not boosting and not throttling and speed < 8.0 and vert_boost < 0.5) else 0.0
	if landing:
		sink = 9.0
	var fwd = Vector3(-sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
	velocity = fwd * speed + Vector3.UP * (vert_boost + lift_now - sink) + knock
	rotation = Vector3(pitch, yaw, 0.0)
	floor_snap_length = 0.0
	if snatch.state == "cine" or (snatch.lock_fry != null and snatch.seq != null):
		return      # the snatch controller carries the gull (guided last metres / close-up): no collisions, no crash
	var pre = velocity
	move_and_slide()
	# collisions: only hard wall hits hurt
	var worst = 0.0
	var wn = Vector3.ZERO
	for i in get_slide_collision_count():
		var n = get_slide_collision(i).get_normal()
		if n.y < 0.7:
			var imp = -pre.dot(n)
			if imp > worst:
				worst = imp
				wn = n
	if worst > 9.0:
		GS.award("WALL KISS")
		GS.stats["walls"] += 1
		Sfx.play("thud")
		Sfx.play("cry", -6.0, 1.15)
		GS.player_hurt.emit("crash", snatch.carry_fry != null)
		start_tumble(wn * 4.0 + Vector3(0, 2.0, 0), 12.0 * GS.hurt_mult(), 1.2 * GS.stun_mult())
		return
	elif worst > 2.5:
		shake = max(shake, clamp(worst / 20.0, 0.1, 0.4))
		speed = min(speed, max(get_real_velocity().length(), 3.0))
		if worst > 5.0:
			Sfx.play("land", -8.0)
	if is_on_floor() and speed < 9.0:
		speed = move_toward(speed, 0.0, 3.0 * delta)
	_water(delta)
	# land on anything flat
	if is_on_floor() and (speed < 8.5 or landing) and not boosting and vert_boost < 1.5 and velocity.y <= 1.0 and knock.length() < 1.0:
		_land()
		return
	regen_active = false
	if since_spend >= 1.0 and not boosting and not throttling:
		stamina += GS.regen_glide() * (0.5 if soaked_t > 0.0 else 1.0) * delta
		regen_active = true
	still_t = 0.0
	calm = move_toward(calm, 0.0, delta / 0.6)
	_skim_fx(delta)

func _start_roll(dir):
	roll_t = 0.45
	roll_dir = dir
	invuln_t = 0.45
	roll_cd = GS.roll_cooldown()
	spend(10.0)
	var right = Vector3(cos(yaw), 0, -sin(yaw))
	knock += right * dir * 7.0
	Sfx.play("roll", -6.0)

func _land():
	mode = M.GROUND
	var high = global_position.y >= 4.0
	perch_high = high
	velocity = Vector3.ZERO
	speed = 0.0
	pitch = 0.0
	aim_pitch = 0.0
	boosting = false
	throttling = false
	Sfx.play("land", -6.0)
	landed.emit(high)
	if global_position.y >= 15.0:
		GS.award("SKYLINE")

func _ground(delta, mouse):
	var sens = 0.0022 * GS.mouse_sens_mult
	yaw -= mouse.x * sens
	aim_yaw = yaw
	pitch = clamp(pitch - mouse.y * sens * (-1.0 if GS.invert_y else 1.0), deg_to_rad(-40.0), deg_to_rad(25.0))
	aim_pitch = pitch
	yaw_rate = 0.0
	boosting = false
	throttling = false
	braking = false
	var f = Vector3(-sin(yaw), 0, -cos(yaw))
	var r = Vector3(cos(yaw), 0, -sin(yaw))
	var d = Vector3.ZERO
	if not input_locked:
		if Input.is_action_pressed("move_forward"):
			d += f
		if Input.is_action_pressed("move_back"):
			d -= f
		if Input.is_action_pressed("bank_right"):
			d += r
		if Input.is_action_pressed("bank_left"):
			d -= r
	var moving = d.length() > 0.1
	d = d.normalized() * GROUND_SPEED
	velocity.x = move_toward(velocity.x, d.x, 18.0 * delta) + knock.x
	velocity.z = move_toward(velocity.z, d.z, 18.0 * delta) + knock.z
	velocity.y = max(velocity.y - 22.0 * delta, -25.0)
	rotation = Vector3(0, yaw, 0)
	floor_snap_length = 0.4
	move_and_slide()
	speed = 0.0
	if moving:
		walk_t += delta * 8.0
	if is_on_floor():
		off_floor_t = 0.0
	else:
		off_floor_t += delta
		if off_floor_t > 0.18:
			mode = M.FLY
			speed = 2.5
			pitch = 0.0
			aim_pitch = 0.0
			aim_yaw = yaw
			return
	# a drink wears off once the gull has been standing on the ground for a few seconds (it shakes its feathers)
	if GS.drink != "":
		ground_drink_t += delta
		if ground_drink_t > 3.0:
			ground_drink_t = 0.0
			GS.set_drink("")
			flap_anim = 0.4
			Sfx.play("shake", -6.0)
			show_toast("SHOOK IT OFF", 0.9)
	else:
		ground_drink_t = 0.0
	# perch recovery: standing anywhere refills stamina; higher is faster
	stamina += GS.regen_perch(perch_high) * (0.5 if soaked_t > 0.0 else 1.0) * delta
	regen_active = true
	var still = (not moving) and velocity.length() < 0.3
	if still:
		still_t += delta
	else:
		still_t = 0.0
	calm = move_toward(calm, 1.0 if still_t > 1.5 else 0.0, delta / 0.8)
	if calm > 0.5:
		Sfx.stop_growl()
	if soaked_t > 0.0 and still_t > 0.6:
		soaked_t = 0.0
		Sfx.play("shake", -6.0)
		flap_anim = 0.4
	if not input_locked and Input.is_action_just_pressed("flap"):
		mode = M.FLY
		speed = GS.glide_speed()
		pitch = 0.3
		aim_pitch = 0.3
		aim_yaw = yaw
		vert_boost = 6.5
		flap_anim = 0.4
		Sfx.play("flap", -6.0)

func _tumble(delta):
	tumble_t -= delta
	velocity.y -= 16.0 * delta
	velocity.x *= (1.0 - 1.2 * delta)
	velocity.z *= (1.0 - 1.2 * delta)
	floor_snap_length = 0.0
	move_and_slide()
	_water(delta)
	if is_on_floor():
		velocity.x *= 0.85
		velocity.z *= 0.85
	if tumble_t <= 0.0:
		if is_on_floor():
			mode = M.GROUND
			perch_high = global_position.y >= 4.0
			velocity = Vector3.ZERO
		else:
			mode = M.FLY
			speed = 3.0
			pitch = 0.0
			aim_pitch = 0.0
			aim_yaw = yaw
			vert_boost = 0.0

func _water(_delta):
	if splash_cd > 0.0:
		return
	if global_position.y < WATER_Y + 0.3 and _over_water():
		splash_cd = 0.5
		var first = soaked_t <= 0.0
		soaked_t = 15.0
		Sfx.play("splash", -4.0)
		_splash_fx()
		if first:
			if not GS.achievements_done.has("SOAKED"):
				GS.comic.emit("soaked", "WET. DEEPLY DISGRUNTLED.", {})
			GS.award("SOAKED")
		if mode == M.FLY:
			vert_boost = 5.0
			speed *= 0.75

func _over_water():
	if ground_h == null:
		return global_position.y < WATER_Y + 0.3
	return ground_h.call(global_position.x, global_position.z) < WATER_Y + 0.05

func _splash_fx():
	var p = _make_particles(Color(0.9, 0.97, 1.0, 0.85), 0.2, 40, 0.8)
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 60.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 5.0
	p.gravity = Vector3(0, -9, 0)
	p.top_level = true
	add_child(p)
	p.global_position = Vector3(global_position.x, WATER_Y, global_position.z)
	p.emitting = true
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)

func _skim_fx(delta):
	var low = global_position.y < WATER_Y + 1.6 and global_position.y > WATER_Y - 0.1 and speed > 6.0
	var over = low and _over_water()
	spray.emitting = over
	if over:
		spray.global_position = Vector3(global_position.x, WATER_Y + 0.05, global_position.z)
		spray.initial_velocity_max = 2.0 + speed * 0.25
		skim_t += delta
		if skim_t > 4.0:
			GS.award("SKIMMER")
	else:
		skim_t = max(skim_t - delta, 0.0)
	drip.emitting = soaked_t > 0.0

func _safety():
	var p = global_position
	if p.y < -4.0:
		global_position = Vector3(p.x, 2.0, p.z)
		velocity = Vector3.ZERO
		soaked_t = 15.0
	if abs(p.x) > 230.0 or p.z > 230.0 or p.z < -170.0 or p.y > 140.0:
		GS.award("SOMEWHERE ELSE")
		global_position = respawn_point
		yaw = PI
		aim_yaw = PI
		pitch = 0.0
		speed = 5.0
		mode = M.FLY
		refill()
		update_camera(0.0, true)

# ------------------------------------------------------------------ visuals + camera
func _process(delta):
	if not is_inside_tree():
		return
	var mname = "glide"
	if mode == M.GROUND:
		mname = "ground"
	elif mode == M.TUMBLE:
		mname = "tumble"
	elif boosting:
		mname = "boost"
	elif braking:
		mname = "brake"
	elif throttling:
		mname = "throttle"
	gull.pose(mname, flap_anim / 0.4 if flap_anim > 0.0 else 0.0, throttling, delta)
	gull.set_trails(boosting and speed > 14.0)
	var roll_target = clamp(yaw_rate * 0.3 - (0.0 if input_locked else Input.get_axis("bank_left", "bank_right")) * 0.4, -0.8, 0.8)
	if mode == M.GROUND:
		roll_target = sin(walk_t) * 0.12
	roll = lerp(roll, roll_target, 1.0 - exp(-8.0 * delta))
	var extra = 0.0
	if roll_t > 0.0:
		extra = -roll_dir * TAU * (1.0 - roll_t / 0.45)
	if mode == M.TUMBLE:
		extra = GS.msec() * 0.012
	visual_root.rotation = Vector3(0, 0, roll + extra)
	visual_root.position.y = abs(sin(walk_t)) * 0.05 if mode == M.GROUND else 0.0
	Sfx.set_wind(speed / 24.0 if mode != M.GROUND else 0.0, boosting)
	Sfx.set_calm(calm)
	update_camera(delta, false)

func update_camera(delta, snap):
	var boost_n = clamp((speed - 11.0) / 12.0, 0.0, 1.0)
	var ky = 1.0 if snap else 1.0 - exp(-lerp(14.0, 9.0, boost_n) * delta)
	var kp = 1.0 if snap else 1.0 - exp(-12.0 * delta)
	cam_yaw = lerp_angle(cam_yaw, yaw, ky)
	cam_pitch = lerp(cam_pitch, pitch * 0.9, kp)
	var roll_cam = roll * 0.25
	rig.global_transform = Transform3D(Basis.from_euler(Vector3(cam_pitch, cam_yaw, roll_cam)), rig.global_position)
	var target_pos = get_global_transform_interpolated().origin + Vector3(0, 0.7, 0)
	if snap:
		rig.global_position = target_pos
	else:
		rig.global_position = rig.global_position.lerp(target_pos, 1.0 - exp(-lerp(26.0, 12.0, boost_n) * delta))
	var fov_t = _interp(CAM_TABLE, speed, 1)
	var dist_t = _interp(CAM_TABLE, speed, 2)
	if mode == M.GROUND:
		fov_t = 62.0
		dist_t = 3.4
	fov_t -= 4.0 * calm
	dist_t -= 0.4 * calm
	var dt_f = delta / max(Engine.time_scale, 0.05)
	focus = move_toward(focus, 1.0 if (snatch != null and snatch.lock_fry != null and snatch.state == "idle") else 0.0, 5.0 * dt_f) if not snap else 0.0
	fov_t -= 14.0 * focus
	dist_t -= 0.7 * focus
	vision = move_toward(vision, 1.0 if GS.sense_active else 0.0, 4.0 * dt_f) if not snap else 0.0
	fov_t += 7.0 * vision
	fov_kick = move_toward(fov_kick, 0.0, 22.0 * delta)
	cam_fov = lerp(cam_fov, fov_t, 1.0 if snap else 1.0 - exp(-4.0 * dt_f))
	cam.fov = cam_fov + fov_kick
	cam_dist = lerp(cam_dist, dist_t, 1.0 if snap else 1.0 - exp(-3.0 * dt_f))
	arm.spring_length = cam_dist
	shake = move_toward(shake, 0.0, 2.5 * delta)
	cam.h_offset = randf_range(-1.0, 1.0) * shake * 0.12
	cam.v_offset = randf_range(-1.0, 1.0) * shake * 0.12
	# cinematic / intro / sense override camera
	var dt_real = delta / max(Engine.time_scale, 0.02)
	ov_w = move_toward(ov_w, ov_goal, ov_rate * dt_real)
	if ov_w > 0.001:
		var w = smoothstep(0.0, 1.0, ov_w)
		var base = cam.global_transform
		cine_cam.global_transform = base.interpolate_with(ov_xf, w)
		cine_cam.fov = lerp(cam.fov, ov_fov, w)
		cine_cam.current = true
	elif cine_cam.current:
		cam.current = true
