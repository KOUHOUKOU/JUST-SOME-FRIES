extends Node3D
# Background townsfolk: they make the town feel inhabited, walk/jog/fish/paint/chat, and act as WITNESSES:
# a gull carrying someone's fries makes them point and cry out, which alerts nearby fry owners.
# Round 4: they can also be a nuisance. GRUMPY people swat at a gull that hangs around within arm's reach (a short wind-up you can read,
# then a swing: leave in time or get smacked); CHASER kids run at a gull that has landed near them and shout BOO (a fright, not a hit);
# and friendly people wave at a gull that sits still near them.

const HumanRig = preload("res://scripts/npc/human_rig.gd")
const Terrain = preload("res://scripts/world/terrain.gd")

var rig
var mode = "stand"
var waypoints = []
var wp_i = 0
var wp_wait = 0.0
var speed = 1.1
var player = null
var alarm_t = 0.0
var witness_cd = 0.0
var vis_t = 0.0
var scan_t = 0.0
var base_yaw = 0.0
var active = true
var phase = 0.0
var grumpy = false
var chaser = false
var home_pos = Vector3.ZERO
var swing_state = ""        # "" | wind | swing | rest
var swing_t = 0.0
var swing_cd = 3.0
var chase_state = ""        # "" | run | home
var chase_t = 0.0
var chase_cd = 6.0
var landed_t = 0.0
var wave_cd = 12.0
var bang = null
# round 7: KIND CHILDREN. A heart (not an exclamation mark) floats over their heads. Land near one and it runs over to feed you a rainbow fry.
var kind_kid = false
var kk_state = ""            # "" | run | give | home
var kk_t = 0.0
var kk_cd = 0.0
var kk_heart = null
var kk_fry = null
var kk_from = Vector3.ZERO
var carried_fry = null       # a rainbow fry in this person's hand (a passer-by who can be robbed)

func setup(p_mode, style, pos, face, path, p_speed, p_player):
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	mode = p_mode
	player = p_player
	position = pos
	rotation.y = atan2(face.x, face.z)
	base_yaw = rotation.y
	waypoints = path
	speed = p_speed
	phase = randf() * 6.0
	grumpy = style.get("grumpy", false)
	chaser = style.get("chaser", false)
	kind_kid = style.get("kind_kid", false)
	home_pos = pos
	rig = Node3D.new()
	rig.set_script(HumanRig)
	add_child(rig)
	rig.build(style)
	GS.cull_tree(rig, 110.0)
	if style.get("seated", false):
		rig.seated = true
	match mode:
		"stroll":
			rig.set_mode("walk")
			rig.walk_rate = speed / 1.3
		"jog":
			rig.set_mode("jog")
			rig.walk_rate = speed / 2.6
		"fish", "paint", "play", "chat", "lie", "sit", "wave", "eat", "recline":
			rig.set_mode(mode)
		_:
			rig.set_mode("idle")
	add_to_group("ambient")
	if style.has("mischief"):
		_add_mischief(style["mischief"])
	if kind_kid:
		_make_heart()

func _process(delta):
	if player == null:
		return
	vis_t -= delta
	if vis_t <= 0.0:
		vis_t = 0.4 + randf() * 0.2
		var d = global_position.distance_to(player.global_position)
		active = d < (75.0 if GS.web else 130.0)
		visible = active
	if not active:
		return
	witness_cd = max(witness_cd - delta, 0.0)
	if alarm_t > 0.0:
		alarm_t -= delta
		if alarm_t <= 0.0:
			_restore_mode()
	if mode in ["stroll", "jog"] and alarm_t <= 0.0:
		_walk(delta)
	elif mode == "stand" or mode == "chat":
		scan_t -= delta
		if scan_t <= 0.0:
			scan_t = randf_range(3.0, 6.0)
			rig.head.rotation.y = randf_range(-0.7, 0.7)
	_witness()
	_cower()
	_grump(delta)
	_chase(delta)
	_kind(delta)
	_friendly(delta)

func _restore_mode():
	match mode:
		"stroll":
			rig.set_mode("walk")
		"jog":
			rig.set_mode("jog")
		"stand":
			rig.set_mode("idle")
		_:
			rig.set_mode(mode)

func _walk(delta):
	if waypoints.size() < 2:
		return
	if wp_wait > 0.0:
		wp_wait -= delta
		return
	var tgt = waypoints[wp_i]
	var to = tgt - position
	to.y = 0.0
	if to.length() < 0.3:
		wp_i = (wp_i + 1) % waypoints.size()
		if mode == "stroll" and randf() < 0.3:
			wp_wait = randf_range(1.0, 3.0)
		return
	var dir = to.normalized()
	position += dir * speed * delta
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 5.0 * delta)

func _witness():
	if witness_cd > 0.0 or alarm_t > 0.0:
		return
	var carrying = player.carry_fry != null
	if not carrying:
		return
	var to = player.global_position - global_position
	if to.length() > 12.0:
		return
	var f = Vector3(sin(rotation.y), 0, cos(rotation.y))
	if f.dot(Vector3(to.x, 0, to.z).normalized()) < -0.2:
		return
	witness_cd = 5.0
	alarm_t = 2.0
	rig.set_mode("alarm")
	rig.emote("surprise", 1.5)
	Sfx.play("oh", -10.0, randf_range(0.85, 1.2))
	GS.add_heat(0.15)
	# tell the nearest fry owner
	for n in get_tree().get_nodes_in_group("npcs"):
		if is_instance_valid(n) and n.global_position.distance_to(global_position) < 9.0:
			n.look_at_pos(player.global_position, 1.8)
			n.notice_boost(0.15)

var cower_cd = 0.0

func _cower():
	cower_cd = max(cower_cd - get_process_delta_time(), 0.0)
	if cower_cd > 0.0 or alarm_t > 0.0 or GS.gull_sense_count < 3 or swing_state != "" or chase_state != "":
		return
	if global_position.distance_to(player.global_position) < 7.0 and player.speed > 9.0:
		cower_cd = 6.0
		alarm_t = 1.4
		rig.set_mode("alarm")
		Sfx.play("oh", -14.0, randf_range(0.9, 1.1))

const MischiefScript = preload("res://scripts/fries/mischief.gd")
var mischief_item = null

func _add_mischief(kind):
	var m = Node3D.new()
	m.set_script(MischiefScript)
	match kind:
		"hat":
			m.setup("hat", rig.head, Vector3(0, 0.3, 0), self)
		"icecream":
			m.setup("icecream", rig.hand_r, Vector3(0, 0.05, 0.05), self)
		"balloon":
			m.setup("balloon", rig.hand_l, Vector3(0, 0.0, 0.0), self)
		"pipe":
			m.setup("pipe", rig.head, Vector3(0.05, 0.08, 0.17), self)
		"shades":
			m.setup("shades", rig.head, Vector3(0, 0.2, 0.172), self)
		"necklace":
			m.setup("necklace", rig.torso, Vector3(0, 0.62, 0.26), self)
		"bowtie":
			m.setup("bowtie", rig.torso, Vector3(0, 0.72, 0.25), self)
		"scarf":
			m.setup("scarf", rig.torso, Vector3(0, 0.74, 0.02), self)
		"sailor", "topper", "beret":
			m.setup(kind, rig.head, Vector3(0, 0.3, 0), self)
		"glasses":
			m.setup("glasses", rig.head, Vector3(0, 0.2, 0.17), self)
		"hawaii", "stripes", "coat":
			m.setup(kind, rig.hand_l, Vector3(0, 0.0, 0.1), self)
		"coffee", "alcohol":
			m.setup(kind, rig.hand_r, Vector3(0, 0.05, 0.06), self)
			m.scale = Vector3(0.7, 0.7, 0.7)
	mischief_item = m

func theft_reaction():
	alarm_t = 2.5
	rig.set_mode("alarm")
	rig.emote("surprise", 1.5)
	Sfx.play("oh", -8.0, randf_range(0.8, 1.1))

# ------------------------------------------------------------------ nuisances
func _face_player(delta, rate = 9.0):
	var to = player.global_position - global_position
	to.y = 0.0
	if to.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 1.0 - exp(-rate * delta))

func _bang(on):
	if bang == null:
		bang = Label3D.new()
		bang.text = "!"
		bang.font_size = 150
		bang.pixel_size = 0.006
		bang.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		bang.no_depth_test = true
		bang.modulate = Color(1.0, 0.45, 0.25)
		bang.outline_size = 14
		bang.position = Vector3(0, 2.4, 0)
		add_child(bang)
	bang.visible = on

# a short readable wind-up, then the swing. Only if the gull is still within reach when it lands.
func _grump(delta):
	if not grumpy:
		return
	swing_cd = max(swing_cd - delta, 0.0)
	var reach_c = global_position + Vector3(0, 1.3, 0)
	var d = reach_c.distance_to(player.global_position)
	match swing_state:
		"":
			if swing_cd <= 0.0 and GS.gull_sense_count >= 3 and d < 2.9 and player.mode != 2 and player.invuln_t <= 0.0 and player.speed < 9.5 \
					and player.snatch.state == "idle" and alarm_t <= 0.0:
				swing_state = "wind"
				swing_t = 0.0
				_bang(true)
				Sfx.play("warn", -8.0)
		"wind":
			swing_t += delta
			_face_player(delta)
			rig.override_arm_r = lerp(0.0, -2.9, clamp(swing_t / 0.6, 0.0, 1.0))
			rig.override_arm_r_z = 0.0
			if swing_t >= 0.6:
				swing_state = "swing"
				swing_t = 0.0
				rig.override_arm_r = -1.1
				Sfx.play("broom", -10.0, 1.2)
		"swing":
			swing_t += delta
			if swing_t >= 0.1:
				if d < 3.1 and player.invuln_t <= 0.0 and player.mode != 2:
					player.get_swatted(self, "grump")
				else:
					Sfx.play("whoosh", -10.0, 1.2)
				swing_state = "rest"
				swing_t = 0.0
		"rest":
			swing_t += delta
			if swing_t > 0.7:
				rig.override_arm_r = null
				swing_state = ""
				swing_cd = 8.0
				_bang(false)

# ---- the kind children: a heart, a run, a rainbow fry ----
const RestEvents = preload("res://scripts/world/rest_events.gd")
const FryScript = preload("res://scripts/fries/fry.gd")

func _make_heart():
	kk_heart = Sprite3D.new()
	kk_heart.texture = RestEvents.heart_tex()
	kk_heart.pixel_size = 0.014
	kk_heart.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	kk_heart.no_depth_test = true
	kk_heart.shaded = false
	kk_heart.position = Vector3(0, 1.75, 0)
	add_child(kk_heart)

# the colour of the gift: one that is complete, otherwise any colour the gull already has
static func gift_type():
	var done = []
	var some = []
	for k in GS.FRY_TYPES:
		if GS.lv[k] >= 3:
			done.append(k)
		elif GS.lv[k] >= 1:
			some.append(k)
	if not done.is_empty():
		return done[randi() % done.size()]
	if not some.is_empty():
		return some[randi() % some.size()]
	return GS.FRY_TYPES[randi() % GS.FRY_TYPES.size()]

func _kind(delta):
	if not kind_kid:
		return
	kk_cd = max(kk_cd - delta, 0.0)
	var pl = player
	var t = GS.msec() * 0.001
	if kk_heart != null:
		kk_heart.visible = kk_state == "" and kk_cd <= 0.0 and GS.gull_sense_count >= 3
		kk_heart.position.y = 1.75 + sin(t * 3.0 + phase) * 0.06
		kk_heart.scale = Vector3.ONE * (1.0 + 0.12 * sin(t * 5.0 + phase))
	var flat = Vector2(pl.global_position.x - global_position.x, pl.global_position.z - global_position.z)
	match kk_state:
		"":
			if kk_cd <= 0.0 and GS.gull_sense_count >= 3 and pl.mode == 1 and pl.still_t > 0.5 and flat.length() < 22.0 and alarm_t <= 0.0 					and abs(pl.global_position.y - global_position.y) < 4.5 and Terrain.H(pl.global_position.x, pl.global_position.z) > -0.25 and not GS.codex_open:
				kk_state = "run"
				kk_t = 0.0
				rig.set_mode("jog")
				rig.walk_rate = 1.6
				Sfx.play("oh", -12.0, 1.5)
		"run":
			kk_t += delta
			if pl.mode != 1 and flat.length() > 10.0 or kk_t > 14.0:
				kk_state = "home"
				kk_t = 0.0
				rig.set_mode("walk")
				return
			var dir = Vector3(flat.x, 0, flat.y).normalized()
			position += dir * 3.6 * delta
			position.y = home_pos.y + (Terrain.H(position.x, position.z) - Terrain.H(home_pos.x, home_pos.z))
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 8.0 * delta)
			if flat.length() < 2.2:
				kk_state = "give"
				kk_t = 0.0
				rig.set_mode("idle")
				rig.override_arm_r = -1.7
				var f = Node3D.new()
				f.set_script(FryScript)
				get_tree().current_scene.add_child(f)
				f.setup("GIFT_FRY", gift_type(), "box", 0, 4)
				for gname in ["fries", "special_fries", "star_fries"]:
					if f.is_in_group(gname):
						f.remove_from_group(gname)
				f.revealed = true
				f.visible = true
				f.scale = Vector3.ONE * 0.7
				f.global_position = global_position + Vector3(0, 1.0, 0) + Vector3(sin(rotation.y), 0, cos(rotation.y)) * 0.5
				kk_fry = f
				kk_from = f.global_position
				Sfx.play("feed", -8.0)
		"give":
			kk_t += delta
			_face_player(delta)
			if kk_fry == null or not is_instance_valid(kk_fry):
				kk_state = "home"
				return
			var u = clamp((kk_t - 0.35) / 0.6, 0.0, 1.0)
			var p = kk_from.lerp(pl.beak_socket.global_position, u)
			p.y += sin(u * PI) * 0.6
			kk_fry.global_position = p
			kk_fry.rotation.y += 6.0 * delta
			if u >= 1.0:
				var type = kk_fry.utype
				var old_max = GS.stamina_max()
				GS.add_rainbow(type)
				if type == "blue":
					pl.stamina += GS.stamina_max() - old_max
				GS.stats["fed"] += 1
				GS.fry_got.emit(type, 4)
				GS.award("A KIND CHILD")
				GS.quests_check()
				Sfx.play("reward_1", -8.0, 1.4)
				Sfx.play("heart", -8.0, 1.2)
				pl.fov_kick = 3.0
				kk_fry.queue_free()
				kk_fry = null
				rig.override_arm_r = null
				rig.set_mode("wave")
				kk_state = "home"
				kk_t = 0.0
				kk_cd = 150.0
		"home":
			kk_t += delta
			if kk_t > 1.6:
				rig.set_mode("walk")
			var back = home_pos - position
			back.y = 0.0
			if back.length() < 0.4 or kk_t > 16.0:
				kk_state = ""
				rig.set_mode(mode if mode != "stand" else "idle")
				rotation.y = base_yaw
				return
			if kk_t > 1.6:
				var dir2 = back.normalized()
				position += dir2 * 2.6 * delta
				position.y = home_pos.y + (Terrain.H(position.x, position.z) - Terrain.H(home_pos.x, home_pos.z))
				rotation.y = lerp_angle(rotation.y, atan2(dir2.x, dir2.z), 6.0 * delta)

# kids: a gull that sits down nearby is an invitation
func _chase(delta):
	if not chaser:
		return
	chase_cd = max(chase_cd - delta, 0.0)
	var pl = player
	var landed = pl.mode == 1
	landed_t = landed_t + delta if landed else 0.0
	var flat = Vector2(pl.global_position.x - global_position.x, pl.global_position.z - global_position.z)
	match chase_state:
		"":
			if chase_cd <= 0.0 and landed_t > 1.0 and GS.gull_sense_count >= 3 and flat.length() < 20.0 and alarm_t <= 0.0 \
					and pl.global_position.y - global_position.y < 3.2 and Terrain.H(pl.global_position.x, pl.global_position.z) > -0.25:
				chase_state = "run"
				chase_t = 0.0
				rig.set_mode("jog")
				rig.walk_rate = 1.5
				Sfx.play("oh", -12.0, 1.5)
		"run":
			chase_t += delta
			if not landed or chase_t > 10.0 or Terrain.H(global_position.x, global_position.z) < -0.2:
				_chase_end(false)
				return
			var dir = Vector3(flat.x, 0, flat.y).normalized()
			position += dir * 3.7 * delta
			position.y = home_pos.y + (Terrain.H(position.x, position.z) - Terrain.H(home_pos.x, home_pos.z))
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 8.0 * delta)
			if flat.length() < 1.8:
				# BOO!
				Sfx.play("boo", -9.0, randf_range(1.15, 1.35))
				rig.emote("surprise", 0.9)
				pl.startle(global_position, 6.0)
				GS.comic.emit("scare", "A KID. A VERY LOUD KID.", {"tier": 0})
				GS.add_heat(0.2)
				_chase_end(true)
		"home":
			chase_t += delta
			var back = home_pos - position
			back.y = 0.0
			if back.length() < 0.4 or chase_t > 14.0:
				chase_state = ""
				rig.set_mode(mode if mode != "stand" else "idle")
				rotation.y = base_yaw
				return
			var dir2 = back.normalized()
			position += dir2 * 2.6 * delta
			position.y = home_pos.y + (Terrain.H(position.x, position.z) - Terrain.H(home_pos.x, home_pos.z))
			rotation.y = lerp_angle(rotation.y, atan2(dir2.x, dir2.z), 6.0 * delta)

func _chase_end(booed):
	chase_state = "home"
	chase_t = 0.0
	chase_cd = 16.0 if booed else 9.0
	rig.set_mode("walk")
	rig.walk_rate = 1.2

# people wave at a gull that sits quietly near them
func _friendly(delta):
	wave_cd = max(wave_cd - delta, 0.0)
	if wave_cd > 0.0 or grumpy or chaser or alarm_t > 0.0 or swing_state != "" or chase_state != "":
		return
	if player.mode == 1 and player.calm > 0.6 and mode in ["stand", "stroll", "chat", "lie"]:
		if global_position.distance_to(player.global_position) < 9.0 and randf() < 0.03:
			wave_cd = 30.0
			alarm_t = 2.6
			rig.set_mode("wave")
			if randf() < 0.5:
				Sfx.play("oh", -16.0, 1.1)
