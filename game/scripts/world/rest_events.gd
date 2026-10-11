extends Node
# Resting is not empty time (round 5). A gull that sits still on the ground for a few seconds can meet:
#   * a friendly GULL that lands next to it, a few little hearts float up, then it flies off again  (a little breath back)
#   * a KID who runs up and feeds it a RAINBOW fry of a random colour
#   * a stray DOG that trots over to harass it (a "!" and a red patch warn you: fly off or get bitten)
# Only one thing at a time, never right after another, never before Gull Sight is open, never at the very start of a run.

const HumanRig = preload("res://scripts/npc/human_rig.gd")
const GullVisual = preload("res://scripts/player/gull_visual.gd")
const DOG = preload("res://scripts/npc/dog.gd")
const FRY = preload("res://scripts/fries/fry.gd")
const Warn = preload("res://scripts/world/warn.gd")
const Terrain = preload("res://scripts/world/terrain.gd")

var player = null
var rest_t = 0.0
var cd = 6.0
var kid_cd = 30.0
var ev = null
var force_kind = ""          # dev tests
static var _heart_tex = null

static func heart_tex():
	if _heart_tex == null:
		var img = Image.create(48, 48, false, Image.FORMAT_RGBA8)
		for y in 48:
			for x in 48:
				var u = (x - 23.5) / 17.0
				var v = -(y - 25.0) / 17.0
				var q = pow(u * u + v * v - 1.0, 3.0) - u * u * v * v * v
				var a = clamp(-q * 6.0, 0.0, 1.0)
				img.set_pixel(x, y, Color(1.0, 0.35, 0.5, a))
		_heart_tex = ImageTexture.create_from_image(img)
	return _heart_tex

func _ground_pos(angle, dist):
	var pp = player.global_position
	var x = pp.x + cos(angle) * dist
	var z = pp.z + sin(angle) * dist
	var h = Terrain.H(x, z)
	if h < -0.2:
		return null
	var space = player.get_world_3d().direct_space_state
	var q = PhysicsRayQueryParameters3D.create(Vector3(x, pp.y + 4.0, z), Vector3(x, pp.y - 6.0, z), 1)
	var hit = space.intersect_ray(q)
	if hit.is_empty() or abs(hit["position"].y - pp.y) > 1.2:
		return null
	# a clear line to the gull
	var q2 = PhysicsRayQueryParameters3D.create(hit["position"] + Vector3(0, 0.8, 0), pp + Vector3(0, 0.4, 0), 1)
	if not space.intersect_ray(q2).is_empty():
		return null
	return hit["position"]

func _pick_spot(dist):
	for i in 14:
		var p = _ground_pos(randf() * TAU, dist + randf_range(-1.0, 1.0))
		if p != null:
			return p
	return null

func _process(delta):
	if player == null or not player.active or get_tree().paused:
		return
	var dt = delta / max(Engine.time_scale, 0.1)
	_step_flock(dt)
	cd = max(cd - dt, 0.0)
	gift_cd = max(gift_cd - dt, 0.0)
	kid_cd = max(kid_cd - dt, 0.0)
	var resting = player.mode == 1 and player.still_t > 0.8 and not player.input_locked and GS.gull_sense_count >= 3 and not GS.ordinary_eaten \
		and not GS.codex_open and player.snatch.state == "idle"
	if ev == null:
		rest_t = rest_t + dt if resting else 0.0
		if resting and cd <= 0.0 and rest_t > (1.0 if force_kind != "" else 3.0):
			_start()
	else:
		_step(dt)

func _start():
	# a calm town is a warm town: other gulls, children with a heart, a stranger with a cup, a puppy that wants to play. A hostile dog only comes when the crowd is wary.
	var kinds = ["buddy", "buddy", "stranger", "puppy"]
	if GS.fry_total() >= 4:
		kinds.append("kid")
		if kid_cd <= 0.0:
			kinds.append("kid")
		if GS.watch < 1.0:
			kinds.append_array(["stranger", "puppy", "kid"])
	if GS.watch >= 1.6:
		kinds = ["buddy", "dog", "dog"]
	elif GS.watch >= 1.0:
		kinds = ["buddy", "puppy", "kid"]
	if stranger_cd > 0.0:
		kinds = kinds.filter(func(k): return k != "stranger")
	if player.perch_high:
		kinds = ["buddy"]          # on a roof or a tree top only another gull can come to visit
	var kind = kinds[randi() % kinds.size()]
	if force_kind != "":
		kind = force_kind
	match kind:
		"buddy":
			_start_buddy()
		"kid":
			_start_kid()
		"dog":
			_start_dog()
		"stranger":
			_start_stranger()
		"puppy":
			_start_puppy()
	if ev == null:
		cd = 3.0      # nothing fit here: try again soon

var stranger_cd = 25.0

func _end(cool):
	ev = null
	cd = cool
	rest_t = 0.0

# ------------------------------------------------------------------ round 16: the squawk on a roof (F) calls a flock of gulls: they come from every side, land (or hover) round the
# gull, a few hearts rise, and after a short visit they fly off again
var flock = []
var flock_t = 0.0
var flock_done = false

func call_flock():
	if not flock.is_empty():
		return
	var pp = player.global_position
	var n = 4 + randi() % 2
	flock_t = 0.0
	flock_done = false
	var right = Vector3(cos(player.yaw), 0, -sin(player.yaw))
	var fwd = Vector3(-sin(player.yaw), 0, -cos(player.yaw))
	for i in n:
		var ang = TAU * (float(i) + randf() * 0.3) / n
		var ring = Vector3(cos(ang), 0, sin(ang))
		var spot = _ground_pos(ang, 1.7 + 0.55 * (i % 3))
		var hover = false
		if spot == null:
			spot = pp + ring * (2.0 + 0.45 * (i % 3)) + Vector3(0, 0.5 + 0.18 * (i % 2), 0)
			hover = true
			if not _free_air(spot):
				spot = pp + Vector3(0, 1.4 + 0.5 * i, 0) + fwd * (-1.5)
		var g = Node3D.new()
		g.set_script(GullVisual)
		g.plain = true
		get_tree().current_scene.add_child(g)
		g.build()
		g.tint_pale(GullVisual.pale_color(randi() + i))
		g.scale = Vector3.ONE * 1.2
		var a2 = randf() * TAU
		var from = spot + Vector3(cos(a2) * 40.0, 10.0 + randf() * 8.0, sin(a2) * 40.0)
		g.global_position = from
		flock.append({"g": g, "from": from, "to": spot + (Vector3.ZERO if hover else Vector3(0, 0.4, 0)), "hover": hover, "delay": 0.25 * i + randf() * 0.2, "t": 0.0,
			"phase": "wait", "hearts": 0})
	Sfx.play("rival_call", -9.0, 1.3)
	for i in 3:
		get_tree().create_timer(0.4 * i + 0.3, true, false, true).timeout.connect(func(): Sfx.play("gull_far", -12.0 + 2.0 * i, randf_range(0.95, 1.3)))

func _step_flock(dt):
	if flock.is_empty():
		return
	flock_t += dt
	var pp = player.global_position
	var seated = 0
	var alive = 0
	for e in flock:
		var g = e["g"]
		if not is_instance_valid(g):
			continue
		alive += 1
		e["t"] += dt
		match e["phase"]:
			"wait":
				g.visible = false
				if e["t"] >= e["delay"]:
					e["phase"] = "fly"
					e["t"] = 0.0
					g.visible = true
			"fly":
				var u = clamp(e["t"] / 2.6, 0.0, 1.0)
				var ee = u * u * (3.0 - 2.0 * u)
				var p = e["from"].lerp(e["to"], ee)
				p.y += sin(u * PI) * 1.2
				var look = e["to"] - e["from"]
				g.look_at(g.global_position + Vector3(look.x, look.y * 0.4, look.z), Vector3.UP)
				g.global_position = p
				g.pose("glide" if u < 0.82 else "brake", 0.0, false, dt)
				if u >= 1.0:
					e["phase"] = "sit"
					e["t"] = 0.0
					Sfx.play("land", -16.0, randf_range(1.2, 1.6))
			"sit":
				seated += 1
				if e["hover"]:
					g.pose("throttle", 0.0, true, dt)
					g.global_position = e["to"] + Vector3(0, sin(e["t"] * 4.0 + e["delay"] * 9.0) * 0.08, 0)
				else:
					g.pose("ground", 0.0, false, dt)
					g.global_position = e["to"] + Vector3(0, sin(e["t"] * 6.0) * 0.015, 0)
				g.look_at(Vector3(pp.x, g.global_position.y, pp.z), Vector3.UP)
				g.head.rotation.x = sin(e["t"] * 5.0 + e["delay"] * 7.0) * 0.25
				if e["hearts"] < 3 and e["t"] > 0.5 + e["hearts"] * 0.7:
					e["hearts"] += 1
					_heart(g.global_position + Vector3(0, 0.9, 0))
				if player.mode != 1 or flock_t > 9.5:
					e["phase"] = "leave"
					e["t"] = 0.0
			"leave":
				var dir = (g.global_position - pp)
				dir.y = 0.0
				dir = dir.normalized() if dir.length() > 0.1 else Vector3(1, 0, 0)
				g.pose("throttle", 0.0, true, dt)
				g.global_position += (dir * 7.0 + Vector3(0, 4.5, 0)) * dt * (0.4 + clamp(e["t"] / 3.0, 0.0, 1.0))
				g.look_at(g.global_position + dir * 3.0 + Vector3(0, 1.5, 0), Vector3.UP)
				if e["t"] > 4.0:
					g.queue_free()
	if seated >= 3 and not flock_done:
		flock_done = true
		GS.ach_unlock("callgulls")
		GS.comic.emit("call_roof", "YOU CALLED. A FLOCK CAME. NOBODY ASKED WHY.", {"tier": 0})
		player.show_toast("A FLOCK. BREATH BACK.", 1.4)
		player.refill()
		GS.stats["friends"] = GS.stats.get("friends", 0) + 1
	var left = 0
	for e in flock:
		if is_instance_valid(e["g"]):
			left += 1
	if left == 0:
		flock.clear()

# ------------------------------------------------------------------ the friendly gull
func _start_buddy():
	var spot = _pick_spot(1.6)
	var hover = false
	var pp0 = player.global_position
	if spot == null:
		# nowhere flat to land next to the gull (a tree top, a narrow roof ridge): the friend hovers beside it instead
		var right = Vector3(cos(player.yaw), 0, -sin(player.yaw))
		spot = pp0 + right * 1.9 + Vector3(0, 0.55, 0)
		if not _free_air(spot):
			spot = pp0 - right * 1.9 + Vector3(0, 0.55, 0)
			if not _free_air(spot):
				return
		hover = true
	var gift = null
	if GS.fry_total() >= 3 and ((gift_cd <= 0.0 and randf() < (0.55 if (player.perch_high or hover) else 0.3)) or force_kind != ""):
		gift = true
	var g = Node3D.new()
	g.set_script(GullVisual)
	g.plain = true
	get_tree().current_scene.add_child(g)
	g.build()
	g.tint_pale(GullVisual.pale_color(randi()))
	g.scale = Vector3.ONE * 1.25
	var ang = randf() * TAU
	var from = spot + Vector3(cos(ang) * 38.0, 14.0, sin(ang) * 38.0)
	g.global_position = from
	ev = {"kind": "buddy", "t": 0.0, "g": g, "from": from, "to": spot + (Vector3.ZERO if hover else Vector3(0, 0.4, 0)), "hearts": 0, "phase": "fly",
		"hover": hover, "gift": null, "given": false, "give_t": 0.0}
	if gift != null:
		# the friend arrives with a rainbow fry in its beak
		var f = Node3D.new()
		f.set_script(FRY)
		get_tree().current_scene.add_child(f)
		f.setup("GIFT_FRY", load("res://scripts/npc/ambient_npc.gd").gift_type(), "box", 0, 4)
		for gname in ["fries", "special_fries", "star_fries"]:
			if f.is_in_group(gname):
				f.remove_from_group(gname)
		f.revealed = true
		f.visible = true
		f.carried = true
		f.reparent(g.beak_socket, false)
		f.position = Vector3(0, -0.06, -0.04)
		f.scale = Vector3(0.42, 0.42, 0.42)
		f.halo.visible = false
		if f.rim != null:
			f.rim.visible = false
		ev["gift"] = f
	Sfx.play("gull_far", -10.0, 1.2)

var gift_cd = 20.0

func _free_air(p):
	var sh = SphereShape3D.new()
	sh.radius = 0.55
	var q = PhysicsShapeQueryParameters3D.new()
	q.shape = sh
	q.transform = Transform3D(Basis.IDENTITY, p)
	q.collision_mask = 1
	return player.get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()

func _heart(pos):
	heart_fx(get_tree().current_scene, pos)

static func heart_fx(root, pos):
	var s = Sprite3D.new()
	s.texture = heart_tex()
	s.pixel_size = 0.012
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.no_depth_test = true
	s.modulate = Color(1, 1, 1, 1)
	s.shaded = false
	root.add_child(s)
	s.global_position = pos
	s.scale = Vector3(0.3, 0.3, 0.3)
	var tw = s.create_tween().set_parallel(true)
	tw.tween_property(s, "scale", Vector3(1.0, 1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_property(s, "global_position", pos + Vector3(randf_range(-0.3, 0.3), 1.6, randf_range(-0.3, 0.3)), 1.4)
	tw.tween_property(s, "modulate:a", 0.0, 1.4).set_delay(0.5)
	tw.chain().tween_callback(s.queue_free)
	Sfx.play("heart", -10.0, randf_range(0.95, 1.15))

# a few words over somebody's head (fades by itself)
static func say(root, who, text, sec = 3.0, height = 2.2):
	var l = Label3D.new()
	l.text = text
	l.font_size = 56
	l.pixel_size = 0.0075
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.modulate = Color(1, 0.96, 0.82, 0.0)
	l.outline_size = 12
	l.outline_modulate = Color(0.05, 0.04, 0.07, 0.9)
	l.render_priority = 120
	l.outline_render_priority = 119
	l.position = Vector3(0, height, 0)
	who.add_child(l)
	var tw = l.create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.25)
	tw.tween_interval(sec)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)
	return l

func _step_buddy(dt):
	var g = ev["g"]
	if not is_instance_valid(g):
		_end(10.0)
		return
	ev["t"] += dt
	var pp = player.global_position
	match ev["phase"]:
		"fly":
			var u = clamp(ev["t"] / 3.2, 0.0, 1.0)
			var e = u * u * (3.0 - 2.0 * u)
			var p = ev["from"].lerp(ev["to"], e)
			p.y += sin(u * PI) * 1.5
			var look = ev["to"] - ev["from"]
			g.look_at(g.global_position + Vector3(look.x, look.y * 0.4, look.z), Vector3.UP)
			g.global_position = p
			g.pose("glide" if u < 0.8 else "brake", 0.0, false, dt)
			if u >= 1.0:
				ev["phase"] = "sit"
				ev["t"] = 0.0
				g.look_at(Vector3(pp.x, g.global_position.y, pp.z) + Vector3.ZERO, Vector3.UP)
				Sfx.play("land", -14.0, 1.4)
			if player.mode != 1:
				ev["phase"] = "leave"
				ev["t"] = 0.0
		"sit":
			if ev["hover"]:
				g.pose("throttle", 0.0, true, dt)
				g.global_position = ev["to"] + Vector3(0, sin(ev["t"] * 4.0) * 0.08, 0)
			else:
				g.pose("ground", 0.0, false, dt)
				g.global_position = ev["to"] + Vector3(0, sin(ev["t"] * 6.0) * 0.015, 0)
			g.look_at(Vector3(pp.x, g.global_position.y, pp.z), Vector3.UP)
			# the gift: the fry leaves the friend's beak and flies into the gull's
			var gf = ev["gift"]
			if gf != null and is_instance_valid(gf) and ev["t"] > 1.1:
				if not ev["given"]:
					ev["given"] = true
					gf.reparent(get_tree().current_scene, true)
					gf.scale = Vector3.ONE * 0.7
					ev["gfrom"] = gf.global_position
					Sfx.play("feed", -8.0)
				ev["give_t"] += dt
				var gu = clamp(ev["give_t"] / 0.6, 0.0, 1.0)
				var gp = ev["gfrom"].lerp(player.beak_socket.global_position, gu)
				gp.y += sin(gu * PI) * 0.5
				gf.global_position = gp
				gf.rotation.y += 6.0 * dt
				if gu >= 1.0:
					var gtype = gf.utype
					var gold_max = GS.stamina_max()
					GS.add_rainbow(gtype)
					if gtype == "blue":
						player.stamina += GS.stamina_max() - gold_max
					GS.stats["fed"] += 1
					GS.stats["gifts"] = GS.stats.get("gifts", 0) + 1
					GS.fry_got.emit(gtype, 4)
					GS.award("A FRIEND WHO SHARES")
					GS.quests_check()
					Sfx.play("reward_1", -8.0, 1.4)
					player.fov_kick = 3.0
					gf.queue_free()
					ev["gift"] = null
					gift_cd = 60.0
			# a little courtship bob, and the hearts
			g.head.rotation.x = sin(ev["t"] * 5.0) * 0.25
			if ev["hearts"] < 6 and ev["t"] > 0.5 + ev["hearts"] * 0.5:
				ev["hearts"] += 1
				_heart((pp + g.global_position) * 0.5 + Vector3(0, 0.7, 0))
			if player.mode != 1 or ev["t"] > (4.4 if ev["gift"] == null else 5.4):
				ev["phase"] = "leave"
				ev["t"] = 0.0
				if player.mode == 1:
					player.stamina = min(player.stamina + 14.0, GS.stamina_max())
					GS.stats["friends"] += 1
					GS.award("NEW FRIEND")
					GS.comic.emit("friend", "A FRIEND. HEARTS WERE EXCHANGED.", {"tier": 0})
					player.show_toast("A FRIEND. BREATH BACK.", 1.4)
		"leave":
			var u2 = clamp(ev["t"] / 3.0, 0.0, 1.0)
			g.pose("throttle", 0.0, true, dt)
			var dir = (g.global_position - pp)
			dir.y = 0.0
			dir = dir.normalized() if dir.length() > 0.1 else Vector3(1, 0, 0)
			g.global_position += (dir * 7.0 + Vector3(0, 4.5, 0)) * dt * (0.4 + u2)
			g.look_at(g.global_position + dir * 3.0 + Vector3(0, 1.5, 0), Vector3.UP)
			if ev["t"] > 4.0:
				g.queue_free()
				_end(randf_range(9.0, 14.0))

# ------------------------------------------------------------------ the kid who feeds you
func _start_kid():
	var spot = _pick_spot(11.0)
	if spot == null:
		return
	var kid = Node3D.new()
	var rig = Node3D.new()
	rig.set_script(HumanRig)
	kid.add_child(rig)
	get_tree().current_scene.add_child(kid)
	rig.build({"scale": 0.7, "shirt": ["E8573A", "3D8CD9", "F1C94B", "4FB56D"][randi() % 4], "hair_style": ["cap", "short", "bun"][randi() % 3], "hat": "3D8CD9", "skin": "F0C6A0"})
	rig.set_mode("jog")
	rig.walk_rate = 1.6
	kid.global_position = spot
	var hs = Sprite3D.new()          # a heart over the head: this one comes to feed the gull
	hs.texture = heart_tex()
	hs.pixel_size = 0.014
	hs.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hs.no_depth_test = true
	hs.shaded = false
	hs.position = Vector3(0, 1.75, 0)
	kid.add_child(hs)
	var type = load("res://scripts/npc/ambient_npc.gd").gift_type()
	ev = {"kind": "kid", "t": 0.0, "kid": kid, "rig": rig, "phase": "run", "type": type, "fry": null, "from": Vector3.ZERO}
	Sfx.play("oh", -12.0, 1.5)

func _face(node, to):
	var d = to - node.global_position
	d.y = 0.0
	if d.length() > 0.05:
		node.rotation.y = lerp_angle(node.rotation.y, atan2(d.x, d.z), 0.25)

func _step_kid(dt):
	var kid = ev["kid"]
	if not is_instance_valid(kid):
		_end(10.0)
		return
	ev["t"] += dt
	var pp = player.global_position
	match ev["phase"]:
		"run":
			var to = pp - kid.global_position
			to.y = 0.0
			var d = to.length()
			_face(kid, pp)
			if d > 2.1:
				kid.global_position += to.normalized() * 3.4 * dt
				kid.global_position.y = lerp(kid.global_position.y, pp.y, 0.2)
			else:
				ev["phase"] = "give"
				ev["t"] = 0.0
				ev["rig"].set_mode("idle")
				ev["rig"].override_arm_r = -1.7
				# the fry: a little carton in the kid's hand, then it flies to the gull's beak
				var f = Node3D.new()
				f.set_script(FRY)
				get_tree().current_scene.add_child(f)
				f.setup("GIFT_FRY", ev["type"], "box", 0, 4)
				for gname in ["fries", "special_fries", "star_fries"]:
					if f.is_in_group(gname):
						f.remove_from_group(gname)
				f.revealed = true
				f.visible = true
				f.global_position = kid.global_position + Vector3(0, 1.0, 0) + Vector3(sin(kid.rotation.y), 0, cos(kid.rotation.y)) * 0.5
				f.scale = Vector3.ONE * 0.7
				ev["fry"] = f
				ev["from"] = f.global_position
				Sfx.play("feed", -8.0)
			if player.mode != 1 and d > 8.0:
				ev["phase"] = "leave"
		"give":
			var f2 = ev["fry"]
			_face(kid, pp)
			if not is_instance_valid(f2):
				ev["phase"] = "leave"
				ev["t"] = 0.0
				return
			var u = clamp((ev["t"] - 0.35) / 0.6, 0.0, 1.0)
			var tgt = player.beak_socket.global_position
			var p = ev["from"].lerp(tgt, u)
			p.y += sin(u * PI) * 0.6
			f2.global_position = p
			f2.rotation.y += 6.0 * dt
			if u >= 1.0:
				var type = ev["type"]
				var old_max = GS.stamina_max()
				GS.add_rainbow(type)
				if type == "blue":
					player.stamina += GS.stamina_max() - old_max
				GS.stats["fed"] += 1
				GS.fry_got.emit(type, 4)
				GS.award("A KIND CHILD")
				Sfx.play("reward_1", -8.0, 1.4)
				player.fov_kick = 3.0
				f2.queue_free()
				ev["fry"] = null
				ev["phase"] = "leave"
				ev["t"] = 0.0
				ev["rig"].override_arm_r = null
				ev["rig"].set_mode("wave")
				kid_cd = 70.0 if GS.watch >= 0.7 else 30.0
		"leave":
			if ev["t"] > 1.4:
				ev["rig"].set_mode("jog")
				var away = kid.global_position - pp
				away.y = 0.0
				if away.length() > 0.1:
					kid.global_position += away.normalized() * 3.2 * dt
					_face(kid, kid.global_position + away)
			if ev["t"] > 5.0:
				kid.queue_free()
				_end(randf_range(9.0, 14.0))

# ------------------------------------------------------------------ the stray dog
func _start_dog():
	var spot = _pick_spot(11.0)
	if spot == null:
		return
	var d = Node3D.new()
	d.set_script(DOG)
	get_tree().current_scene.add_child(d)
	d.setup(player, spot, 0.0, ["B58A4B", "3A2A20", "F1E6D2", "8A6A4A"][randi() % 4], null)
	d.cd = 0.0
	ev = {"kind": "dog", "t": 0.0, "dog": d, "spot": spot}
	Sfx.play("bark", -10.0, 1.3)

func _step_dog(dt):
	var d = ev["dog"]
	if not is_instance_valid(d):
		_end(10.0)
		return
	ev["t"] += dt
	var pp = player.global_position
	# it trots towards the gull until it is close (the dog's own script takes over: bark, "!", crouch, lunge)
	if d.state in ["sleep", "bark"] and ev["t"] < 5.0:
		var to = pp - d.global_position
		to.y = 0.0
		if to.length() > 5.6:
			d.global_position += to.normalized() * 3.2 * dt
			d.global_position.y = ev["spot"].y
			d.rotation.y = lerp_angle(d.rotation.y, atan2(to.x, to.z), 0.2)
			d.body.position.y = abs(sin(ev["t"] * 14.0)) * 0.05
	if ev["t"] > 16.0 or (d.state == "sleep" and ev["t"] > 7.0):
		d.queue_free()
		_end(randf_range(16.0, 22.0))

# ------------------------------------------------------------------ the stranger with a cup (round 15)
# A passer-by with a heart over the head walks up to a gull that sits quietly, sets a cup down in front of it and says "this might suit a gull." The cup is a drink
# (coffee, a cocktail or ice cream: one the gull is not drinking yet, if possible); the gull sips it, the buff starts like any other drink.
const DRINK_OF = {"coffee": "coffee", "alcohol": "alcohol", "icecream": "ice"}

func _start_stranger():
	var spot = _pick_spot(12.0)
	if spot == null:
		return
	var who = Node3D.new()
	var rig = Node3D.new()
	rig.set_script(HumanRig)
	who.add_child(rig)
	get_tree().current_scene.add_child(who)
	rig.build({"scale": 1.0, "shirt": ["E8573A", "3D8CD9", "F1C94B", "4FB56D", "B58CF0"][randi() % 5], "hair_style": ["cap", "short", "bun"][randi() % 3], "hat": "E8D9A8", "skin": ["F0C6A0", "D9A77A", "B98462"][randi() % 3]})
	rig.set_mode("walk")
	rig.walk_rate = 1.3
	who.global_position = spot
	var hs = Sprite3D.new()
	hs.texture = heart_tex()
	hs.pixel_size = 0.014
	hs.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hs.no_depth_test = true
	hs.shaded = false
	hs.position = Vector3(0, 2.1, 0)
	who.add_child(hs)
	# a drink the gull is not running yet
	var want = []
	for k in ["coffee", "alcohol", "icecream"]:
		if GS.buff[DRINK_OF[k]] <= 0.0:
			want.append(k)
	if want.is_empty():
		want = ["coffee", "alcohol", "icecream"]
	ev = {"kind": "stranger", "t": 0.0, "who": who, "rig": rig, "phase": "walk", "drink": want[randi() % want.size()], "cup": null, "from": Vector3.ZERO, "heart": hs}
	Sfx.play("oh", -14.0, 1.2)

func _step_stranger(dt):
	var who = ev["who"]
	if not is_instance_valid(who):
		_end(10.0)
		return
	ev["t"] += dt
	var pp = player.global_position
	var rig = ev["rig"]
	match ev["phase"]:
		"walk":
			var to = pp - who.global_position
			to.y = 0.0
			var d = to.length()
			_face(who, pp)
			if d > 2.4:
				who.global_position += to.normalized() * 2.5 * dt
				who.global_position.y = lerp(who.global_position.y, pp.y - 0.35, 0.2)
			else:
				ev["phase"] = "give"
				ev["t"] = 0.0
				rig.set_mode("idle")
				rig.override_arm_r = -1.5
				var m = Node3D.new()
				m.set_script(load("res://scripts/fries/mischief.gd"))
				m.setup(ev["drink"], get_tree().current_scene, who.global_position + Vector3(0, 1.0, 0))
				m.remove_from_group("mischief")
				m.available = false
				m.respawn_sec = 0.0
				m.scale = Vector3.ONE * 0.9
				ev["cup"] = m
				var dirv = (pp - who.global_position)
				dirv.y = 0.0
				ev["spot"] = pp + (-dirv.normalized() * 1.0 if dirv.length() > 0.1 else Vector3(0, 0, 1)) + Vector3(0, -0.25, 0)
				ev["from"] = m.global_position
				say(get_tree().current_scene, who, "this might suit a gull.", 3.2, 2.35)
				Sfx.play("feed", -9.0)
			if player.mode != 1 and d > 9.0:
				ev["phase"] = "leave"
				ev["t"] = 0.0
		"give":
			var cup = ev["cup"]
			_face(who, pp)
			if cup == null or not is_instance_valid(cup):
				ev["phase"] = "leave"
				ev["t"] = 0.0
				return
			if ev["t"] < 0.9:
				# the cup is set down on the ground in front of the gull
				var u0 = clamp(ev["t"] / 0.9, 0.0, 1.0)
				var gp = ev["from"].lerp(ev["spot"], u0)
				gp.y += sin(u0 * PI) * 0.25
				cup.global_position = gp
			elif ev["t"] < 1.9:
				cup.global_position = ev["spot"]
				if ev["t"] > 0.95 and ev["t"] < 1.0:
					rig.override_arm_r = null
			else:
				var u = clamp((ev["t"] - 1.9) / 0.5, 0.0, 1.0)
				var tgt = player.beak_socket.global_position
				var p = ev["spot"].lerp(tgt, u)
				p.y += sin(u * PI) * 0.4
				cup.global_position = p
				if u >= 1.0:
					_drink_given(cup, ev["drink"])
					ev["cup"] = null
					ev["phase"] = "leave"
					ev["t"] = 0.0
					rig.override_arm_r = null
					rig.set_mode("wave")
					stranger_cd = 70.0
		"leave":
			var hs = ev["heart"]
			if is_instance_valid(hs) and ev["t"] < 0.2:
				heart_fx(get_tree().current_scene, who.global_position + Vector3(0, 2.2, 0))
			if ev["t"] > 1.6:
				rig.set_mode("walk")
				var away = who.global_position - pp
				away.y = 0.0
				if away.length() > 0.1:
					who.global_position += away.normalized() * 2.2 * dt
					_face(who, who.global_position + away)
			if ev["t"] > 6.0:
				who.queue_free()
				_end(randf_range(9.0, 14.0))

# a drink that was GIVEN (it does not make the town more wary, and it is not a theft)
func _drink_given(cup, kind):
	var bk = DRINK_OF[kind]
	GS.stats["drinks"] += 1
	GS.mischief_counts[kind] = GS.mischief_counts.get(kind, 0) + 1
	GS.add_buff(bk)
	GS.award({"coffee": "ESPRESSO", "alcohol": "LAST ORDERS", "icecream": "SWEET TOOTH"}[kind])
	GS.ach_unlock("kind")
	Sfx.play("sip" if kind != "icecream" else "crunch", -5.0, 1.0 if kind != "icecream" else 1.3)
	player.fov_kick = 3.0
	heart_fx(get_tree().current_scene, player.global_position + Vector3(0, 0.9, 0))
	GS.comic.emit("gift", "A STRANGER LEFT A DRINK. HOW KIND.", {"tier": 0})
	GS.quests_check()
	if is_instance_valid(cup):
		cup.queue_free()

# ------------------------------------------------------------------ the puppy (round 15)
func _start_puppy():
	var spot = _pick_spot(10.0)
	if spot == null:
		return
	var d = Node3D.new()
	d.set_script(DOG)
	get_tree().current_scene.add_child(d)
	d.setup(player, spot, 0.0, ["B58A4B", "C98A4B", "F1E6D2", "8A6A4A"][randi() % 4], null)
	d.state = "friend"
	d.cd = 0.0
	d.scale = Vector3.ONE * 0.8
	ev = {"kind": "puppy", "t": 0.0, "dog": d, "spot": spot}
	Sfx.play("bark", -12.0, 1.7)

func _step_puppy(dt):
	var d = ev["dog"]
	if not is_instance_valid(d):
		_end(10.0)
		return
	ev["t"] += dt
	if d.state != "friend" and ev["t"] < 3.0:
		d.state = "friend"
	if ev["t"] > 9.5 or (player.mode != 1 and ev["t"] > 2.0):
		d.queue_free()
		_end(randf_range(11.0, 16.0))
		return
	if d.circled and not ev.get("done", false):
		ev["done"] = true
		GS.ach_unlock("puppy")
		GS.comic.emit("puppy", "A PUPPY CIRCLED YOU. FOR NO REASON. HEARTS.", {"tier": 0})
		player.stamina = min(player.stamina + 10.0, GS.stamina_max())


func _step(dt):
	match ev["kind"]:
		"stranger":
			_step_stranger(dt)
		"puppy":
			_step_puppy(dt)
		"buddy":
			_step_buddy(dt)
		"kid":
			_step_kid(dt)
		"dog":
			_step_dog(dt)
