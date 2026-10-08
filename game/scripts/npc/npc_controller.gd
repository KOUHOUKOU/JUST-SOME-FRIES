extends Node3D
# Fry-owner NPC (docs/18 §5, §7): readable attention rhythm, awareness (distance + facing + line of sight),
# telegraphed swats of several kinds, per-encounter wariness, leaving with the fries when pushed too far.

const HumanRig = preload("res://scripts/npc/human_rig.gd")
const Warn = preload("res://scripts/world/warn.gd")
const Nav = preload("res://scripts/npc/nav.gd")
var stuck_t = 0.0

const PROFILES = {
	"elder": {"view": 8.0, "angle": 80.0, "gain": 0.3, "decay": 0.8, "ring": 1.05, "timing": 0.46, "tele": 0.7, "active": 0.25, "radius": 2.4, "kind": "punch", "scale": 0.95, "grace": true},
	"elder_poke": {"view": 8.0, "angle": 80.0, "gain": 0.3, "decay": 0.8, "ring": 1.05, "timing": 0.44, "tele": 0.65, "active": 0.25, "radius": 2.1, "kind": "poke", "scale": 0.92, "grace": true},
	"adult": {"view": 11.0, "angle": 105.0, "gain": 0.75, "decay": 0.65, "ring": 0.8, "timing": 0.32, "tele": 0.45, "active": 0.22, "radius": 2.6, "kind": "punch", "scale": 1.0},
	"parent": {"view": 11.0, "angle": 105.0, "gain": 0.75, "decay": 0.65, "ring": 0.8, "timing": 0.32, "tele": 0.45, "active": 0.22, "radius": 2.1, "kind": "poke", "scale": 1.0},
	"vendor": {"view": 11.0, "angle": 100.0, "gain": 0.7, "decay": 0.65, "ring": 0.8, "timing": 0.3, "tele": 0.55, "active": 0.3, "radius": 3.4, "kind": "sweep", "scale": 1.02},
	"child": {"view": 12.0, "angle": 125.0, "gain": 1.0, "decay": 0.55, "ring": 0.68, "timing": 0.25, "tele": 0.4, "active": 0.2, "radius": 1.2, "kind": "squirt", "scale": 0.68},
}
const SUSPICIOUS = 0.35
const ALERT = 0.7

var enc = {}
var arch = "adult"
var prof
var rig
var head
var hand_anchor
var player = null
var fry = null
var awareness = 0.0
var wary = 0.0
var wary_cd = 0.0
var swat_phase = 0
var swat_t = 0.0
var hit_done = false
var swatted_this_carry = false
var swat_cd = 0.0
var aim_pos = Vector3.ZERO
var bang
var danger
var line
var was_alert = false
var behavior = "stand"
var base_yaw = 0.0
var yaw_b = 0.0
var waypoints = []
var wp_i = 0
var wp_wait = 0.0
var walk_speed = 1.2
var center = Vector3.ZERO
var attn_t = 0.0
var attn_up = true
var scan_t = 0.0
var scan_dir = 0.0
var lure_pos = Vector3.ZERO
var lure_t = 0.0
var lure_count = 0
var lure_decay = 0.0
var look_t = 0.0
var look_pos = Vector3.ZERO
var leaving = false
var gone = false
var respawn_t = 0.0
var alt_i = 0
var scripted = ""           # "" | "pending" | "hit" | "whiff" - set while the escape check is running
var scripted_tele = 0.55
var body_scale = 1.0
var eye_h = 1.6
var phase_seed = 0.0
var happened_escape = false

func setup(p_enc, p_player):
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	enc = p_enc
	player = p_player
	arch = enc["arch"]
	prof = PROFILES[arch]
	body_scale = prof["scale"]
	eye_h = 1.62 * body_scale
	behavior = enc.get("behavior", "stand")
	phase_seed = randf() * 6.0
	add_to_group("npcs")
	rig = Node3D.new()
	rig.set_script(HumanRig)
	add_child(rig)
	var st = enc["style"].duplicate()
	st["scale"] = body_scale
	rig.build(st)
	head = rig.head
	hand_anchor = rig.hand_anchor
	rig.holding = enc["carrier"] == "hand"
	position = enc["pos"]
	set_facing(enc["face"])
	base_yaw = rotation.y
	yaw_b = base_yaw + enc.get("turn", 1.6)
	center = enc["pos"]
	waypoints = enc.get("path", [])
	walk_speed = enc.get("speed", 1.2)
	match behavior:
		"sit_eat":
			rig.set_mode("eat")
		"patrol":
			rig.set_mode("walk")
		"kid":
			rig.set_mode("jog")
		"chat":
			rig.set_mode("chat")
		_:
			rig.set_mode("idle")
	bang = Label3D.new()
	bang.text = "!"
	bang.font_size = 150
	bang.pixel_size = 0.006
	bang.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bang.no_depth_test = true
	bang.modulate = Color(1.0, 0.45, 0.25)
	bang.outline_size = 14
	bang.position = Vector3(0, 2.3 * body_scale, 0)
	bang.visible = false
	add_child(bang)
	_make_cone()

func set_facing(face):
	rotation.y = atan2(face.x, face.z)

# ------------------------------------------------------------------ queries used by other scripts
func ring_time():
	return prof["ring"]

func timing_fraction():
	return prof["timing"] * (1.0 - 0.15 * int(wary))

func is_alert():
	return awareness >= ALERT

func swat_busy():
	return swat_phase == 1 or swat_phase == 2

func view_dir():
	var y = rotation.y + head.rotation.y
	return Vector3(sin(y), 0, cos(y))

func _view_dist():
	return prof["view"] * GS.heat_view_mult() * (1.0 + 0.15 * int(wary))

func can_see(pos):
	var eye = global_position + Vector3(0, eye_h, 0)
	var to = pos - eye
	var dist = to.length()
	if dist > _view_dist():
		return false
	var flat = Vector3(to.x, 0, to.z).normalized()
	if view_dir().dot(flat) < cos(deg_to_rad(prof["angle"] * 0.5)):
		return false
	return _los(eye, pos)

func notice_boost(a):
	awareness = clamp(awareness + a, 0.0, 1.0)

# ------------------------------------------------------------------ reactions
func react(kind):
	if rig != null:
		if kind == "surprise":
			rig.emote("surprise", 1.0)
			Sfx.play("oh", -9.0, randf_range(0.9, 1.1) * (1.35 if arch == "child" else 1.0))
		elif kind == "guard":
			rig.emote("surprise", 0.6)

func on_snatched():
	pass

func on_escaped():
	happened_escape = true
	awareness = 0.0
	rig.holding = false
	rig.set_mode("alarm")
	react("surprise")
	get_tree().create_timer(3.0).timeout.connect(func():
		if is_instance_valid(self) and not leaving:
			rig.set_mode("idle"))

func on_failed(amount):
	var before = int(wary)
	wary = clamp(wary + amount, 0.0, 3.0)
	wary_cd = 15.0 if enc["type"] == "tutorial" else 25.0
	if int(wary) > before:
		_wary_up(int(wary))

func _wary_up(level):
	if fry == null or fry.consumed:
		return
	if level == 1:
		var nxt = "plate" if fry.carrier == "box" else "hand"
		if fry.carrier != "hand" and enc["type"] != "tutorial":
			_set_carrier(nxt)
	elif level == 2:
		if fry.carrier == "box":
			_set_carrier("plate")
	elif level >= 3 and enc["type"] != "tutorial":
		_start_leaving()

func _set_carrier(c):
	if fry.carrier == c:
		return
	fry.set_carrier(c)
	if c == "hand":
		fry.reparent(hand_anchor, false)
		fry.position = Vector3.ZERO
		fry.rotation = Vector3.ZERO
		fry.home_parent = hand_anchor
		rig.holding = true
		enc["carrier"] = "hand"

func _start_leaving():
	leaving = true
	rig.set_mode("walk")
	rig.holding = fry.carrier == "hand"
	if fry.carrier != "hand":
		fry.visible = false
	set_meta("exit_dir", (global_position - player.global_position).normalized())
	respawn_t = 0.0

func _finish_leaving():
	gone = true
	visible = false
	if fry != null and not fry.consumed and not fry.carried:
		fry.available = false
		fry.visible = false
	respawn_t = 40.0
	bang.visible = false

func _respawn():
	var alts = enc.get("alts", [])
	if alts.size() > 0:
		var a = alts[alt_i % alts.size()]
		alt_i += 1
		position = a["pos"]
		set_facing(a["face"])
		base_yaw = rotation.y
		yaw_b = base_yaw + 1.6
		center = a["pos"]
		if fry != null and not fry.consumed:
			if fry.carrier != "hand" and a.has("table"):
				fry.reparent(fry.get_parent(), false)
				fry.home_pos = a["table"] + Vector3(0, 0.81, 0)
				fry.global_position = fry.home_pos
	wary = 0.0
	awareness = 0.0
	leaving = false
	gone = false
	visible = true
	rig.set_mode("eat" if behavior == "sit_eat" else ("walk" if behavior == "patrol" else "idle"))
	if fry != null and not fry.consumed:
		fry.visible = true
		fry.set_carrier(enc["base_carrier"])
		if enc["base_carrier"] == "hand":
			fry.reparent(hand_anchor, false)
			fry.position = Vector3.ZERO
			fry.rotation = Vector3.ZERO
			fry.home_parent = hand_anchor
			rig.holding = true
		else:
			rig.holding = false
			fry.home_parent = fry.get_parent()
		enc["carrier"] = enc["base_carrier"]
		fry.available = true

# ------------------------------------------------------------------ hearing / looking
func hear(pos, loudness = 1.0):
	if gone or leaving or swat_busy():
		return
	var d = global_position.distance_to(pos)
	if d > 12.0 * loudness:
		return
	if awareness >= ALERT:
		return
	lure_pos = pos
	lure_t = 2.0
	lure_count += 1
	lure_decay = 20.0
	if lure_count >= 2:
		awareness = min(awareness + 0.2, 1.0)

func look_at_pos(pos, sec):
	look_pos = pos
	look_t = sec

func _make_cone():
	var mi = MeshInstance3D.new()
	var am = ArrayMesh.new()
	var verts = PackedVector3Array()
	var n = 14
	var half = deg_to_rad(prof["angle"] * 0.5)
	for i in n:
		var a0 = -half + (2.0 * half) * float(i) / n
		var a1 = -half + (2.0 * half) * float(i + 1) / n
		verts.append(Vector3(0, 0.0, 0))
		verts.append(Vector3(sin(a0), 0, cos(a0)))
		verts.append(Vector3(sin(a1), 0, cos(a1)))
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	mi.mesh = am
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.5, 0.15, 0.38)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = true
	m.render_priority = 5
	mi.material_override = m
	mi.position = Vector3(0, 0.15, 0)
	mi.scale = Vector3(prof["view"], 1, prof["view"])
	mi.visible = false
	mi.name = "Cone"
	head.add_child(mi)
	mi.position = Vector3(0, -head.position.y + 0.15, 0)

func _update_cone():
	var c = head.get_node_or_null("Cone")
	if c == null:
		return
	c.visible = GS.sense_active and not gone
	if c.visible:
		var v = _view_dist()
		c.scale = Vector3(v / body_scale, 1, v / body_scale)

func _los(from, to):
	var q = PhysicsRayQueryParameters3D.create(from, to, 1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

# ------------------------------------------------------------------ swat
func trigger_swat():
	if swat_phase != 0 or swat_cd > 0.0 or gone or leaving:
		return
	swat_phase = 1
	swat_t = 0.0
	hit_done = false
	swatted_this_carry = true
	aim_pos = player.global_position
	Sfx.play("warn", -6.0)
	Warn.bang(self, 2.4 * body_scale, 0.9)
	_show_danger(true)

# The ESCAPE CHECK (stage 2 of a snatch): the owner winds up a swing and the HUD ring runs on that wind-up.
# The snatch controller decides the verdict ("whiff" = the gull slips away, "hit" = shot down); the swing just plays it out.
func begin_scripted_swat():
	swat_phase = 1
	swat_t = 0.0
	hit_done = false
	swatted_this_carry = true
	swat_cd = 0.0
	scripted = "pending"
	scripted_tele = max(prof["tele"], 0.5)
	aim_pos = player.global_position
	look_at_pos(player.global_position, 2.0)
	Sfx.play("alert", -4.0)
	_show_danger(true)
	return scripted_tele

func swat_progress():
	if swat_phase == 1:
		return clamp(swat_t / _tele(), 0.0, 1.0)
	if swat_phase >= 2:
		return 1.0
	return 0.0

func swat_kind():
	return prof["kind"]

func _tele():
	if scripted != "":
		return scripted_tele
	return prof["tele"] * (1.0 - 0.2 * max(int(wary) - 1, 0))

func _swat_center():
	var f = Vector3(sin(rotation.y), 0, cos(rotation.y))
	match prof["kind"]:
		"poke":
			return global_position + f * 0.7 + Vector3(0, 1.9 * body_scale, 0)
		"sweep":
			return global_position + f * 1.3 + Vector3(0, 1.0, 0)
		_:
			return global_position + f * 0.9 + Vector3(0, 1.2 * body_scale, 0)

func _show_danger(on):
	if danger == null:
		danger = MeshInstance3D.new()
		var sm = SphereMesh.new()
		sm.radius = 1.0
		sm.height = 2.0
		sm.radial_segments = 16
		sm.rings = 8
		danger.mesh = sm
		var m = StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(1.0, 0.25, 0.2, 0.18)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		danger.material_override = m
		danger.top_level = true
		add_child(danger)
		line = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(0.12, 0.12, 1.0)
		line.mesh = bm
		var lm = StandardMaterial3D.new()
		lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		lm.albedo_color = Color(1.0, 0.25, 0.2, 0.55)
		line.material_override = lm
		line.top_level = true
		add_child(line)
	var sq = prof["kind"] == "squirt"
	danger.visible = on and not sq
	line.visible = on and sq

func _update_swat(delta):
	swat_cd = max(swat_cd - delta, 0.0)
	var kind = prof["kind"]
	var tele = _tele()
	match swat_phase:
		0:
			rig.override_arm_r = null
		1:
			swat_t += delta
			var u = clamp(swat_t / tele, 0.0, 1.0)
			match kind:
				"sweep":
					rig.override_arm_r = -1.4
					rig.override_arm_r_z = lerp(0.0, 1.3, u)
				"squirt":
					rig.override_arm_r = -1.55
					rig.override_arm_r_z = 0.0
					if u < 0.6:
						aim_pos = player.global_position + player.velocity * 0.25
				"poke":
					rig.override_arm_r = lerp(0.0, -2.2, u)
					rig.override_arm_r_z = 0.0
				_:
					rig.override_arm_r = lerp(0.0, -2.9, u)
					rig.override_arm_r_z = 0.0
			_telegraph_visual(u)
			if swat_t >= tele:
				swat_phase = 2
				swat_t = 0.0
				if kind == "squirt":
					Sfx.play("squirt", -6.0)
				elif kind == "sweep":
					Sfx.play("broom", -6.0)
		2:
			swat_t += delta
			var u2 = clamp(swat_t / prof["active"], 0.0, 1.0)
			match kind:
				"sweep":
					rig.override_arm_r_z = lerp(1.3, -1.4, u2)
				"squirt":
					pass
				"poke":
					rig.override_arm_r = lerp(-2.2, -1.2, u2)
				_:
					rig.override_arm_r = lerp(-2.9, -1.1, u2)
			if not hit_done:
				if scripted == "whiff":
					hit_done = true          # slipped: the swing cuts through empty air
					Sfx.play("whoosh", -8.0, 1.2)
				elif scripted == "hit" or scripted == "pending":
					hit_done = true          # no verdict in time counts as a miss
					player.get_swatted(self, kind)
				elif _hits_player():
					hit_done = true
					player.get_swatted(self, kind)
			if swat_t >= prof["active"]:
				swat_phase = 3
				swat_t = 0.0
				swat_cd = 3.0
				_show_danger(false)
		3:
			swat_t += delta
			if swat_t >= 0.6:
				swat_phase = 0
				scripted = ""
				awareness = min(awareness, 0.5)
				rig.override_arm_r = null

func _telegraph_visual(u):
	if prof["kind"] == "squirt":
		var from = rig.hand_r.global_position
		var dir = (aim_pos - from)
		var len_ = dir.length()
		if len_ > 0.1:
			var mid = from + dir * 0.5
			line.global_position = mid
			line.scale = Vector3(1, 1, len_)
			line.look_at(aim_pos, Vector3.UP)
			line.material_override.albedo_color.a = 0.2 + 0.5 * u
	else:
		danger.global_position = _swat_center()
		var r = prof["radius"]
		danger.scale = Vector3.ONE * r * (0.6 + 0.4 * u)
		danger.material_override.albedo_color.a = 0.1 + 0.25 * u

func _hits_player():
	var pp = player.global_position
	match prof["kind"]:
		"squirt":
			var from = rig.hand_r.global_position
			var dir = (aim_pos - from).normalized()
			var to_p = pp - from
			var proj = clamp(to_p.dot(dir), 0.0, 14.0)
			return (from + dir * proj).distance_to(pp) < 1.1
		"poke":
			return pp.distance_to(_swat_center()) < prof["radius"] and pp.y - global_position.y > 1.0
		"sweep":
			return pp.distance_to(_swat_center()) < prof["radius"] and pp.y - global_position.y < 2.5
		_:
			return pp.distance_to(_swat_center()) < prof["radius"]

# ------------------------------------------------------------------ main update
func _physics_process(delta):
	if player == null:
		return
	if gone:
		respawn_t -= delta
		if respawn_t <= 0.0:
			_respawn()
		return
	var dist_p = global_position.distance_to(player.global_position)
	if dist_p > 150.0:
		return
	_update_wary(delta)
	_update_behavior(delta)
	_update_awareness(delta, dist_p)
	_update_swat(delta)
	_update_cone()

func _update_wary(delta):
	if wary > 0.0 and not leaving:
		wary_cd -= delta
		if wary_cd <= 0.0:
			wary = max(wary - 1.0, 0.0)
			wary_cd = 15.0 if enc["type"] == "tutorial" else 25.0
	if lure_decay > 0.0:
		lure_decay -= delta
		if lure_decay <= 0.0:
			lure_count = 0

func _update_behavior(delta):
	attn_t += delta
	scan_t -= delta
	if leaving:
		var dir = get_meta("exit_dir", Vector3(0, 0, 1))
		dir.y = 0
		Nav.step(self, dir.normalized() * 2.4 * delta)
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 4.0 * delta)
		respawn_t += delta
		if respawn_t > 7.0:
			_finish_leaving()
		return
	match behavior:
		"sit_eat":
			# 4 s cycle: head down eating (safe), head up looking around (dangerous)
			var cyc = fmod(attn_t + phase_seed, 4.0)
			attn_up = cyc > 2.6
		"patrol", "kid":
			_walk_path(delta)
			var cyc2 = fmod(attn_t + phase_seed, 3.4 if behavior == "patrol" else 1.6)
			attn_up = cyc2 > (1.6 if behavior == "patrol" else 0.6)
		"chat":
			var cyc3 = fmod(attn_t + phase_seed, 9.0)
			var tgt = base_yaw if cyc3 < 4.5 else yaw_b
			rotation.y = lerp_angle(rotation.y, tgt, 1.5 * delta)
			attn_up = fmod(attn_t, 5.0) > 2.0
		_:
			attn_up = true
			if scan_t <= 0.0:
				scan_t = randf_range(3.0, 5.0)
				scan_dir = randf_range(-0.9, 0.9)

func _walk_path(delta):
	if waypoints.size() < 2:
		return
	if wp_wait > 0.0:
		wp_wait -= delta
		rig.set_mode("idle")
		return
	var tgt = waypoints[wp_i]
	var to = tgt - position
	to.y = 0
	if to.length() < 0.25:
		wp_i = (wp_i + 1) % waypoints.size()
		wp_wait = 2.0 if behavior == "patrol" else 0.0
		return
	rig.set_mode("walk" if behavior == "patrol" else "jog")
	rig.walk_rate = walk_speed / 1.3
	var dir = to.normalized()
	if not Nav.step(self, dir * walk_speed * delta):
		# round 10: a wall in the way - wait a beat, then go on to the next waypoint instead of pushing into it
		stuck_t += delta
		if stuck_t > 0.8:
			stuck_t = 0.0
			wp_i = (wp_i + 1) % waypoints.size()
			wp_wait = 0.5
	else:
		stuck_t = 0.0
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 6.0 * delta)

func _update_awareness(delta, _dist_p):
	if GS.ordinary_eaten:
		awareness = 0.0
		bang.visible = false
		rig.override_arm_r = null
		swat_phase = 0
		_show_danger(false)
		head.rotation.y = lerp_angle(head.rotation.y, 0.0, 1.0 - exp(-4.0 * delta))
		return
	var eye = global_position + Vector3(0, eye_h, 0)
	var target = player.global_position
	var to = target - eye
	var dist = to.length()
	var vd = _view_dist()
	var sees = false
	var peripheral = false
	if dist <= vd and player.mode != 99:
		var flat = Vector3(to.x, 0, to.z).normalized()
		var d = view_dir().dot(flat)
		if d >= cos(deg_to_rad(prof["angle"] * 0.5)):
			sees = _los(eye, target)
		elif dist <= vd * 0.7:
			peripheral = _los(eye, target)
	var attn = 1.0
	if behavior == "sit_eat":
		attn = 1.0 if attn_up else 0.18
	elif behavior in ["patrol", "kid"]:
		attn = 1.0 if attn_up else 0.4
	elif behavior == "chat":
		attn = 1.0 if attn_up else 0.45
	var gain = prof["gain"] * GS.heat_gain_mult() * attn
	if player.calm > 0.5:
		gain *= 0.4
	if sees:
		awareness += gain * delta
	elif peripheral:
		awareness += gain * 0.3 * delta
	else:
		awareness -= prof["decay"] * delta
	awareness = clamp(awareness, 0.0, 1.0)
	# head: eating = look down; otherwise suspicion / lure / scan
	var head_yaw = 0.0
	var head_pitch = 0.0
	if behavior == "sit_eat" and not attn_up:
		head_pitch = 0.5
	if awareness >= SUSPICIOUS and dist < vd + 3.0:
		var lp = to_local(target)
		head_yaw = clamp(atan2(lp.x, lp.z), -1.5, 1.5)
		head_pitch = 0.0
	elif lure_t > 0.0:
		lure_t -= delta
		var lp2 = to_local(lure_pos)
		head_yaw = clamp(atan2(lp2.x, lp2.z), -1.6, 1.6)
	elif look_t > 0.0:
		look_t -= delta
		var lp3 = to_local(look_pos)
		head_yaw = clamp(atan2(lp3.x, lp3.z), -1.6, 1.6)
	elif behavior == "kid":
		head_yaw = sin(attn_t * 2.6 + phase_seed) * 1.1
	elif behavior in ["stand", "chat", "patrol"]:
		head_yaw = scan_dir * clamp(scan_t, 0.0, 1.0) if scan_t > 0.0 else 0.0
		head_yaw = scan_dir * (0.6 if scan_t > 0.5 else 0.0)
	head.rotation.y = lerp_angle(head.rotation.y, head_yaw, 1.0 - exp(-7.0 * delta))
	head.rotation.x = lerp(head.rotation.x, head_pitch, 1.0 - exp(-6.0 * delta))
	var alert_now = awareness >= ALERT or swat_busy()
	bang.visible = alert_now
	if alert_now and not was_alert:
		Sfx.play("alert", -10.0)
		for n in get_tree().get_nodes_in_group("npcs"):
			if n != self and is_instance_valid(n) and n.global_position.distance_to(global_position) < 6.0:
				n.look_at_pos(player.global_position, 1.5)
	was_alert = alert_now
	# swat: carrying my fry (or just failed) and alert; squirt guns also shoot at close hovering gulls
	var carrying_mine = player.carry_fry != null and player.carry_fry.npc == self
	if not carrying_mine:
		swatted_this_carry = false
	if swat_phase == 0 and not leaving:
		if prof["kind"] == "squirt":
			if awareness >= ALERT and dist < 9.0 and (player.is_vulnerable() or dist < 6.0):
				trigger_swat()
		elif awareness >= ALERT and player.is_vulnerable() and dist < 6.0 and not swatted_this_carry and not prof.get("grace", false):
			trigger_swat()
