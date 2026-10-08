extends Node
# SHOOTING STARS (round 8). Now and then a star falls across the sky. Most of them are just a streak far away (decoration). Every few minutes - and ALWAYS
# a little after STARLIGHT starts - a real one comes by close enough to chase: it can be caught like a fish, with FIVE judgements, but only by a gull that is
# faster than anything else in the game (it needs 262 on the gauge: a gold-SONIC gull in STARLIGHT).
#   forecast (5 s)  -> only Gull Sight shows it (hold TAB high in the sky): the whole orbit as a dotted line, the seconds left, the speed it needs
#   twinkle         -> a point of light grows where the star will enter
#   flight (~17 s)  -> a bright head with a long tail and sparkles; the gull can intercept it or chase it down
# Catching one: breath back, +10 s of STARLIGHT if it is running, a task ticked off, and (the first time) a cinematic moment.

const GullVisual = preload("res://scripts/player/gull_visual.gd")
const Terrain = preload("res://scripts/world/terrain.gd")

const SPEED = 21.0                 # m/s of the catchable star
const PRE = 6.0                    # seconds from entering to the closest approach to the gull
const LIFE = 17.0
const FORECAST = 5.0

const FX = preload("res://scripts/world/meteor_fx.gd")

var player = null
var main = null
var day = null
var star = null
var plan = null
var next_star = 150.0
var next_deco = 18.0
var star_pending = -1.0
var decos = []

# ---- the visual of a star: a head, a tail, and (for the real one) sparkles and a little light
class Comet extends Node3D:
	var vel = Vector3.ZERO
	var age = 0.0
	var life = 5.0
	var head_a
	var head_b
	var tail
	var tail_mat
	var spark = null
	var light = null
	var scl = 1.0
	var fade = 1.0
	var dying = false

	func build(length, radius, size, fancy):
		scl = size
		head_a = FX.billboard(size * 3.2, GullVisual.soft_tex(), Color(1.0, 0.9, 0.62, 0.85))
		add_child(head_a)
		head_b = FX.billboard(size * 1.5, GullVisual.star_tex(), Color(1, 1, 1, 1))
		add_child(head_b)
		tail = MeshInstance3D.new()
		tail.mesh = FX.tail_mesh(length, radius)
		tail_mat = FX.tail_material().duplicate()
		tail.material_override = tail_mat
		tail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(tail)
		if fancy:
			spark = CPUParticles3D.new()
			spark.amount = 36
			spark.lifetime = 1.8
			spark.local_coords = false
			spark.direction = Vector3.UP
			spark.spread = 180.0
			spark.initial_velocity_min = 0.2
			spark.initial_velocity_max = 1.4
			spark.gravity = Vector3(0, -0.4, 0)
			spark.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			spark.emission_sphere_radius = 0.9
			var q = QuadMesh.new()
			q.size = Vector2(0.55, 0.55)
			q.material = FX.glow_mat(GullVisual.star_tex(), Color(1.0, 0.93, 0.7, 0.9))
			spark.mesh = q
			spark.scale_amount_min = 0.5
			spark.scale_amount_max = 1.4
			spark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(spark)
			spark.emitting = true
			if not GS.web:
				light = OmniLight3D.new()
				light.omni_range = 34.0
				light.light_energy = 2.2
				light.light_color = Color(1.0, 0.9, 0.65)
				light.shadow_enabled = false
				add_child(light)

	func orient():
		if vel.length() > 0.01:
			look_at(global_position + vel, Vector3.UP)

	func set_fade(f):
		fade = f
		tail_mat.set_shader_parameter("strength", f)
		head_a.material_override.albedo_color.a = 0.85 * f
		head_b.material_override.albedo_color.a = f
		if light != null:
			light.light_energy = 2.2 * f

	func _process(delta):
		age += delta
		global_position += vel * delta
		head_b.rotation.z += delta * 1.4
		head_a.scale = Vector3.ONE * (1.0 + 0.06 * sin(age * 9.0))
		var f = clamp(min(age / 0.6, (life - age) / 1.0), 0.0, 1.0)
		set_fade(f)
		if age >= life:
			queue_free()

# ---- the catchable star: the snatch code treats it like a "thing" (ftype mischief, kind meteor) that asks for 5 judgements
class Star extends Comet:
	var ftype = "mischief"
	var kind = "meteor"
	var id = "METEOR"
	var tier = 0
	var utype = ""
	var npc = null
	var owner_amb = null
	var carrier = "none"
	var min_speed = 31.0
	var available = true
	var consumed = false
	var taken = false
	var revealed = true
	var carried = false
	var vanished = false
	var gone = false

	func is_snatchable():
		return available and not taken and not vanished and age > 0.5 and age < life - 1.0
	func is_fry_like():
		return false
	func vision_info():
		return null
	func aim_point():
		return global_position
	func consume():
		consumed = true
	func guard(_sec):
		burn_out()
	func escape():
		burn_out()
	func burn_out():
		# a missed star does not wait: it flares and is gone
		available = false
		vanished = true
		life = min(life, age + 0.9)
		vel *= 2.2
		Sfx.play("meteor_pass", -14.0, 1.3)
	func attach(socket):
		carried = true
		vel = Vector3.ZERO
		reparent(socket, true)
		var tw = create_tween().set_parallel(true)
		tw.tween_property(self, "position", Vector3(0, -0.02, -0.06), 0.15)
		tw.tween_property(self, "scale", Vector3(0.09, 0.09, 0.09), 0.15)
		tail.visible = false
		if light != null:
			light.omni_range = 6.0
	func _process(delta):
		if carried:
			age += delta
			head_b.rotation.z += delta * 2.0
			return
		super._process(delta)
	func stolen(pl):
		taken = true
		consumed = true
		remove_from_group("mischief")
		GS.stats["meteors"] += 1
		GS.mischief_counts["meteor"] = GS.mischief_counts.get("meteor", 0) + 1
		GS.award("WISHFUL THINKING")
		GS.quest_finish("meteor")
		GS.quests_check()
		pl.refill()
		if GS.star_t > 0.0:
			GS.star_t = min(GS.star_t + 10.0, 60.0)
		Sfx.play("meteor_get", -3.0)
		Sfx.play("happy", -5.0, 1.25)
		GS.meteor_caught.emit()
		if GS.cine_seen.has("meteor"):
			if not GS.worn.has("meteor"):
				pl.gull.wear("meteor")           # it stays: from now on the gull trails a tail of light
			var tw = create_tween()
			tw.tween_interval(0.5)
			tw.tween_property(self, "scale", Vector3.ZERO, 0.6)
			tw.tween_callback(queue_free)
		else:
			GS.cine_hold = self
			get_tree().create_timer(40.0).timeout.connect(func():
				if is_instance_valid(self):
					queue_free())

func _ready():
	add_to_group("meteor_mgr")
	if GS.has_signal("star_started"):
		GS.star_started.connect(func():
			if star == null and plan == null:
				star_pending = 2.5)

# what Gull Sight shows: null, or {"pos", "dir", "speed", "t" (seconds until it enters, 0 = flying), "left" (seconds of flight left), "need"}
func sight_info():
	if plan != null:
		return {"pos": plan["start"], "dir": plan["dir"], "speed": SPEED, "t": max(plan["t"], 0.0), "left": LIFE, "need": GS.METEOR_NEED, "start": plan["start"]}
	if star != null and is_instance_valid(star) and not star.vanished and not star.carried:
		return {"pos": star.global_position, "dir": star.vel.normalized(), "speed": SPEED, "t": 0.0, "left": star.life - star.age, "need": GS.METEOR_NEED, "start": star.global_position}
	return null

func _can_catch():
	return GS.boost_speed() * GS.SPEED_UNIT >= GS.METEOR_NEED - 1.0

func _free_sky(p):
	return Terrain.H(p.x, p.z) + 14.0 <= p.y

func _plan_star():
	var pp = player.global_position
	var pred = pp + player.velocity * FORECAST * 0.6
	pred.y = pp.y
	var ang = randf() * TAU
	var off = Vector3(cos(ang), 0, sin(ang)) * randf_range(30.0, 60.0)
	var c = pred + off
	var cy = clamp(pred.y + randf_range(6.0, 28.0), 62.0, 120.0)
	var hd = randf() * TAU
	var d = Vector3(cos(hd), -0.10, sin(hd)).normalized()
	for tries in 8:
		var ok = true
		for k in 12:
			var u = float(k) / 11.0
			var p = (Vector3(c.x, cy, c.z) - d * SPEED * PRE) + d * SPEED * LIFE * u
			if not _free_sky(p):
				ok = false
		if ok:
			break
		cy += 22.0
	var start = Vector3(c.x, cy, c.z) - d * SPEED * PRE
	plan = {"start": start, "dir": d, "t": FORECAST}
	if main != null and main.hud != null:
		main.hud.whisper("something is falling, somewhere up there.", 4.0)

func _launch():
	var s = Star.new()
	s.min_speed = GS.METEOR_NEED / GS.SPEED_UNIT
	s.vel = plan["dir"] * SPEED
	s.life = LIFE
	s.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	get_tree().current_scene.add_child(s)
	s.build(46.0, 1.1, 1.2, true)
	s.global_position = plan["start"]
	s.orient()
	s.add_to_group("mischief")
	star = s
	plan = null
	var d = player.global_position.distance_to(s.global_position)
	Sfx.play("meteor_pass", clamp(-6.0 - d * 0.03, -24.0, -6.0), 1.0)

func _deco():
	var pp = player.global_position
	var ang = randf() * TAU
	var dist = randf_range(260.0, 420.0)
	var c = Vector3(pp.x + cos(ang) * dist, randf_range(150.0, 280.0), pp.z + sin(ang) * dist)
	var hd = ang + PI * 0.5 + randf_range(-0.7, 0.7)
	var d = Vector3(cos(hd), -randf_range(0.15, 0.35), sin(hd)).normalized()
	var s = Comet.new()
	s.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	get_tree().current_scene.add_child(s)
	s.build(70.0, 0.9, 1.6, false)
	s.global_position = c
	s.vel = d * 150.0
	s.life = 1.5
	s.orient()
	Sfx.play("meteor_pass", clamp(-18.0 - dist * 0.01, -30.0, -18.0), randf_range(1.0, 1.5))

func _process(delta):
	if player == null or not player.active:
		return
	var rdt = delta / max(Engine.time_scale, 0.05)
	var on = GS.gull_sense_count >= 3 and not GS.ordinary_eaten and not GS.showcase_active and not get_tree().paused
	if main != null and main.intro_active:
		on = false
	if not on:
		return
	# the real one
	if plan != null:
		plan["t"] -= rdt
		if plan["t"] <= 0.0:
			_launch()
	elif star != null and not is_instance_valid(star):
		star = null
	elif star == null:
		if star_pending > 0.0:
			star_pending -= rdt
			if star_pending <= 0.0 and _can_catch():
				_plan_star()
		else:
			next_star -= rdt
			if next_star <= 0.0 and _can_catch():       # round 9: a star is only sent to a gull that can actually reach it
				next_star = randf_range(110.0, 200.0)
				_plan_star()
	# a streak far away now and then
	next_deco -= rdt
	if next_deco <= 0.0:
		var night = 0.0
		if day != null:
			night = smoothstep(0.55, 0.95, day.t)
		next_deco = lerp(randf_range(30.0, 60.0), randf_range(12.0, 26.0), night)
		_deco()
