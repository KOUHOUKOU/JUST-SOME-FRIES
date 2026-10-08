extends Node
# Other gulls want the fries too. Now and then a scruffy rival spots a fry near you and dives for it (you hear it and see it coming for about
# two seconds). If it gets there first the fry is gone (its owner "reorders" it a little later). You can beat it three ways:
# be faster (a lock on the fry makes it back off), yell (F) to shoo it, or fly into it (it bounces off - and costs you a little breath).
# One rival at a time, never in the first minutes, never while you are in the middle of a steal.

const GullVisual = preload("res://scripts/player/gull_visual.gd")

class Rival extends Node3D:
	var director
	var player
	var target = null
	var gull
	var state = "approach"      # approach | leave | bump
	var t = 0.0
	var speed = 21.0
	var mark
	var stick
	var has_fry = false
	var away = Vector3.ZERO
	var spin = 0.0
	func setup(p_dir, p_player, p_target, from_pos):
		director = p_dir
		player = p_player
		target = p_target
		position = from_pos
		physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		gull = Node3D.new()
		gull.set_script(GullVisual)
		gull.plain = true
		add_child(gull)
		gull.build()
		gull.scale = Vector3.ONE * 1.15
		# round 12: a rival is a stranger in a faint colour (butter, blush, sky, mint, lilac, peach) with one piece of decoration of its own, never the player's white
		gull.tint_pale(GullVisual.pale_color(randi()))
		var accs = ["bowtie", "scarf", "sailor", "beret", "glasses", "hat"]
		gull.wear(accs[randi() % accs.size()], true)
		mark = Label3D.new()
		mark.text = "!"
		mark.font_size = 140
		mark.pixel_size = 0.006
		mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		mark.no_depth_test = true
		mark.modulate = Color(1.0, 0.5, 0.3)
		mark.outline_size = 14
		mark.position = Vector3(0, 1.1, 0)
		add_child(mark)
		Sfx.play("rival_call", clamp(-6.0 - from_pos.distance_to(player.global_position) * 0.08, -24.0, -6.0), randf_range(0.9, 1.1))
	func _process(delta):
		t += delta
		if player == null:
			queue_free()
			return
		match state:
			"approach":
				_approach(delta)
			"leave":
				_leave(delta)
			"bump":
				_bump(delta)
		gull.pose("throttle" if state != "bump" else "tumble", 0.0, true, delta)
	func _target_ok():
		if target == null or not is_instance_valid(target):
			return false
		if target.has_method("is_snatchable") and not target.is_snatchable():
			return false
		return true
	func _approach(delta):
		var sn = player.snatch
		# the gull got there first (it is locked on the fry): the rival backs off
		if not _target_ok() or sn.lock_fry == target or (sn.state != "idle" and sn.state != "cine") or GS.sense_active:
			if _target_ok() and sn.lock_fry == target:
				player.show_toast("RIVAL SCARED OFF", 0.9)
			_start_leave(false)
			return
		var tp = target.aim_point() + Vector3(0, 0.25, 0)
		var to = tp - global_position
		var d = to.length()
		var sp = speed * (0.35 + 0.65 * clamp(t / 0.9, 0.0, 1.0))   # a moment to read the "!" before it gets going
		position += to.normalized() * min(sp * delta, d)
		_face(to)
		mark.visible = true
		# gull meets gull
		if global_position.distance_to(player.global_position) < 1.5 and t > 0.6:
			_start_bump()
			return
		if d < 1.0:
			_steal()
	func _steal():
		if _target_ok():
			if target.has_method("rival_take"):
				target.rival_take(14.0)
			elif target.has_method("escape"):
				target.escape()
			has_fry = true
			stick = MeshInstance3D.new()
			var bm = BoxMesh.new()
			bm.size = Vector3(0.05, 0.05, 0.3)
			stick.mesh = bm
			var sm = StandardMaterial3D.new()
			sm.albedo_color = Color("F4C95B")
			stick.material_override = sm
			stick.position = Vector3(0, -0.02, -0.5)
			gull.add_child(stick)
			GS.add_heat(0.2)
			GS.comic.emit("rival", "A GULL BEAT YOU TO IT.", {"tier": 0})
			Sfx.play("rival_call", -6.0, 0.8)
		_start_leave(true)
	func _start_bump():
		state = "bump"
		t = 0.0
		mark.visible = false
		away = (global_position - player.global_position)
		away.y = 0.0
		if away.length() < 0.1:
			away = Vector3(1, 0, 0)
		away = away.normalized() + Vector3(0, 0.6, 0)
		GS.stats["rivals"] += 1
		GS.award("TERRITORIAL")
		if player.shield_hit("rival", global_position):
			Sfx.play("rival_call", -8.0, 0.7)
			return
		GS.player_hurt.emit("swat_rival", false)
		player.spend(4.0)
		player.shake = max(player.shake, 0.3)
		Sfx.play("thud", -10.0, 1.4)
		Sfx.play("rival_call", -8.0, 0.7)
	func _bump(delta):
		position += away * 9.0 * delta
		gull.rotation.z += 12.0 * delta
		if t > 0.6:
			gull.rotation.z = 0.0
			_start_leave(false)
	func _start_leave(with_fry):
		state = "leave"
		t = 0.0
		mark.visible = false
		var a = randf() * TAU
		away = Vector3(cos(a), 0.35, sin(a)).normalized()
		director.rival_done()
	func _leave(delta):
		position += away * 17.0 * delta
		_face(away)
		if t > 5.0 or global_position.distance_to(player.global_position) > 130.0:
			queue_free()
	func _face(dir):
		if dir.length() > 0.01:
			look_at(global_position + dir, Vector3.UP)
	func scare():
		if state == "approach":
			_start_leave(false)
			Sfx.play("rival_call", -9.0, 1.3)

var player
var cd = 45.0
var rival = null
var spots = []          # fish spots (world builder)
var force_next = false
var last_pick = null

func _process(delta):
	if player == null or not player.active:
		return
	if rival != null and not is_instance_valid(rival):
		rival = null
	if cd > 0.0:
		cd -= delta
	if rival != null or cd > 0.0 and not force_next:
		return
	# never while the player is busy with something delicate
	var sn = player.snatch
	if GS.gull_sense_count < 3 or GS.ordinary_eaten or GS.showcase_active or GS.sense_active or GS.codex_open or get_tree().paused:
		return
	if sn.state != "idle" or sn.lock_fry != null or player.mode == 2 or player.input_locked:
		return
	if GS.stats["stolen"] < 2 and not force_next:
		return
	var tgt = _pick_target()
	if tgt == null:
		return
	_spawn(tgt)

const DRINKS = ["coffee", "alcohol", "icecream"]

# round 12: a rival goes for what the gull is flying towards (a fry or a drink, 12-40 m ahead); if nothing is in front of the gull, for something near it
func _pick_target():
	var pp = player.global_position
	var fwd = Vector3(-sin(player.yaw), 0, -cos(player.yaw))
	var best = null
	var best_score = 1e9
	var cands = []
	for f in get_tree().get_nodes_in_group("fries"):
		if not is_instance_valid(f) or f.ftype == "ordinary" or f.ftype == "tutorial" or f.ftype == "star":
			continue
		if not f.is_snatchable() or not f.visible:
			continue
		if f.npc == null or f.npc.gone or f.npc.leaving:
			continue
		cands.append(f)
	for m in get_tree().get_nodes_in_group("mischief"):
		if is_instance_valid(m) and m.get("kind") in DRINKS and m.is_snatchable() and m.respawn_sec > 0.0:
			cands.append(m)
	for f in cands:
		var d = f.global_position.distance_to(pp)
		if d < 12.0 or d > 40.0:
			continue
		var dir = (f.global_position - pp)
		dir.y = 0.0
		var align = fwd.dot(dir.normalized()) if dir.length() > 0.1 else 0.0
		var score = abs(d - 22.0) + (1.0 - align) * 18.0 + randf() * 6.0
		if score < best_score:
			best_score = score
			best = f
	for sp in spots:
		if is_instance_valid(sp) and sp.state == "leap" and sp.fish != null and is_instance_valid(sp.fish) and sp.fish.available:
			var d2 = sp.fish.global_position.distance_to(pp)
			if d2 > 18.0 and d2 < 60.0 and (randf() < 0.45 or force_next):
				return sp.fish
	return best

func _spawn(tgt):
	cd = randf_range(35.0, 65.0)
	force_next = false
	var pp = player.global_position
	var tp = tgt.aim_point()
	var a = randf() * TAU
	var from = tp + Vector3(cos(a) * 30.0, 11.0, sin(a) * 30.0)
	if tgt.ftype == "fish":
		from = tp + Vector3(cos(a) * 26.0, 7.0, sin(a) * 26.0)
	var r = Rival.new()
	r.setup(self, player, tgt, from)
	get_parent().add_child(r)
	rival = r

func rival_done():
	pass

# F (yell) shoos a rival that is still on its way
func scare(from_pos):
	if rival != null and is_instance_valid(rival) and rival.global_position.distance_to(from_pos) < 60.0:
		rival.scare()
		GS.stats["rivals"] += 1
