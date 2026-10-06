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
var cd = 12.0
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
	cd = max(cd - dt, 0.0)
	kid_cd = max(kid_cd - dt, 0.0)
	var resting = player.mode == 1 and player.still_t > 0.8 and not player.input_locked and GS.gull_sense_count >= 3 and not GS.ordinary_eaten \
		and not GS.codex_open and player.snatch.state == "idle"
	if ev == null:
		rest_t = rest_t + dt if resting else 0.0
		if resting and cd <= 0.0 and rest_t > (1.0 if force_kind != "" else 4.5):
			_start()
	else:
		_step(dt)

func _start():
	var kinds = ["buddy", "buddy", "kid", "kid", "dog"]
	if kid_cd > 0.0 or GS.fry_total() < 4:
		kinds = ["buddy", "buddy", "dog"]
	if GS.watch_high():
		kinds = ["buddy"]
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
	if ev == null:
		cd = 3.0      # nothing fit here: try again soon

func _end(cool):
	ev = null
	cd = cool
	rest_t = 0.0

# ------------------------------------------------------------------ the friendly gull
func _start_buddy():
	var spot = _pick_spot(1.6)
	if spot == null:
		return
	var g = Node3D.new()
	g.set_script(GullVisual)
	g.plain = true
	get_tree().current_scene.add_child(g)
	g.build()
	g.scale = Vector3.ONE * 1.25
	var ang = randf() * TAU
	var from = spot + Vector3(cos(ang) * 38.0, 14.0, sin(ang) * 38.0)
	g.global_position = from
	ev = {"kind": "buddy", "t": 0.0, "g": g, "from": from, "to": spot + Vector3(0, 0.4, 0), "hearts": 0, "phase": "fly"}
	Sfx.play("gull_far", -10.0, 1.2)

func _heart(pos):
	var s = Sprite3D.new()
	s.texture = heart_tex()
	s.pixel_size = 0.012
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.no_depth_test = true
	s.modulate = Color(1, 1, 1, 1)
	s.shaded = false
	get_tree().current_scene.add_child(s)
	s.global_position = pos
	s.scale = Vector3(0.3, 0.3, 0.3)
	var tw = s.create_tween().set_parallel(true)
	tw.tween_property(s, "scale", Vector3(1.0, 1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK)
	tw.tween_property(s, "global_position", pos + Vector3(randf_range(-0.3, 0.3), 1.6, randf_range(-0.3, 0.3)), 1.4)
	tw.tween_property(s, "modulate:a", 0.0, 1.4).set_delay(0.5)
	tw.chain().tween_callback(s.queue_free)
	Sfx.play("heart", -10.0, randf_range(0.95, 1.15))

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
			g.pose("ground", 0.0, false, dt)
			g.look_at(Vector3(pp.x, g.global_position.y, pp.z), Vector3.UP)
			g.global_position = ev["to"] + Vector3(0, sin(ev["t"] * 6.0) * 0.015, 0)
			# a little courtship bob, and the hearts
			g.head.rotation.x = sin(ev["t"] * 5.0) * 0.25
			if ev["hearts"] < 6 and ev["t"] > 0.5 + ev["hearts"] * 0.5:
				ev["hearts"] += 1
				_heart((pp + g.global_position) * 0.5 + Vector3(0, 0.7, 0))
			if player.mode != 1 or ev["t"] > 4.4:
				ev["phase"] = "leave"
				ev["t"] = 0.0
				if player.mode == 1:
					player.stamina = min(player.stamina + 14.0, GS.stamina_max())
					GS.stats["friends"] += 1
					GS.award("NEW FRIEND")
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
				_end(randf_range(14.0, 20.0))

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
	var type = GS.FRY_TYPES[randi() % GS.FRY_TYPES.size()]
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
				kid_cd = 90.0
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
				_end(randf_range(14.0, 20.0))

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

func _step(dt):
	match ev["kind"]:
		"buddy":
			_step_buddy(dt)
		"kid":
			_step_kid(dt)
		"dog":
			_step_dog(dt)
