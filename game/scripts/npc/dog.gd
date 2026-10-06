extends Node3D
# A guard dog: dozes, wakes when a fast gull gets close, barks (which alerts its owner and anyone near),
# and lunges at a gull that is carrying fries (telegraphed crouch, then a short jump).
# Round 4: dogs also go for a gull that has LANDED nearby (a gull on the ground is a gull in reach).

var player = null
var owner_npc = null
var home = Vector3.ZERO
var state = "sleep"
var st = 0.0
var cd = 0.0
var lunge_from = Vector3.ZERO
var lunge_to = Vector3.ZERO
var hit_done = false
var body
var head
var tail
var legs = []
var bark_t = 0.0
var base_yaw = 0.0
const Warn = preload("res://scripts/world/warn.gd")

static var _mats = {}

static func mat(c):
	if not _mats.has(c):
		var m = StandardMaterial3D.new()
		m.albedo_color = Color(c)
		m.roughness = 0.95
		_mats[c] = m
	return _mats[c]

func _box(parent, pos, size, c):
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(c)
	mi.position = pos
	parent.add_child(mi)
	return mi

func setup(p_player, pos, yaw, coat, p_owner = null):
	player = p_player
	owner_npc = p_owner
	position = pos
	home = pos
	rotation.y = yaw
	base_yaw = yaw
	body = Node3D.new()
	add_child(body)
	_box(body, Vector3(0, 0.45, 0), Vector3(0.38, 0.38, 0.9), coat)
	head = Node3D.new()
	head.position = Vector3(0, 0.62, 0.52)
	body.add_child(head)
	_box(head, Vector3(0, 0, 0), Vector3(0.3, 0.28, 0.3), coat)
	_box(head, Vector3(0, -0.06, 0.2), Vector3(0.18, 0.14, 0.2), "F1E6D2")
	_box(head, Vector3(0, 0.0, 0.31), Vector3(0.07, 0.06, 0.04), "1E1A18")
	_box(head, Vector3(-0.17, 0.12, -0.02), Vector3(0.07, 0.2, 0.12), "6B4A2B")
	_box(head, Vector3(0.17, 0.12, -0.02), Vector3(0.07, 0.2, 0.12), "6B4A2B")
	_box(head, Vector3(-0.07, 0.07, 0.15), Vector3(0.04, 0.04, 0.03), "1E1A18")
	_box(head, Vector3(0.07, 0.07, 0.15), Vector3(0.04, 0.04, 0.03), "1E1A18")
	tail = Node3D.new()
	tail.position = Vector3(0, 0.6, -0.45)
	body.add_child(tail)
	_box(tail, Vector3(0, 0.12, -0.05), Vector3(0.07, 0.3, 0.07), coat)
	for sx in [-0.14, 0.14]:
		for sz in [-0.3, 0.3]:
			var l = _box(body, Vector3(sx, 0.13, sz), Vector3(0.1, 0.26, 0.1), coat)
			legs.append(l)
	add_to_group("dogs")

func _physics_process(delta):
	if player == null:
		return
	cd = max(cd - delta, 0.0)
	bark_t = max(bark_t - delta, 0.0)
	var to = player.global_position - global_position
	var d = to.length()
	var carrying = player.carry_fry != null
	match state:
		"sleep":
			body.position.y = lerp(body.position.y, -0.18, 6.0 * delta)
			body.scale.y = lerp(body.scale.y, 0.8, 6.0 * delta)
			head.rotation.x = lerp(head.rotation.x, 0.6, 4.0 * delta)
			body.scale.x = 1.0 + sin(GS.msec() * 0.002) * 0.02
			tail.rotation.y = 0.0
			var landed = player.mode == 1 and d < 8.5 and GS.gull_sense_count >= 3
			if ((d < 9.0 and (player.speed > 9.0 or carrying)) or landed) and cd <= 0.0:
				state = "bark"
				st = 0.0
				Sfx.play("bark", -4.0)
				if owner_npc != null:
					owner_npc.notice_boost(0.4)
					owner_npc.look_at_pos(player.global_position, 1.5)
				for n in get_tree().get_nodes_in_group("npcs"):
					if n.global_position.distance_to(global_position) < 10.0:
						n.look_at_pos(player.global_position, 1.2)
		"bark":
			st += delta
			body.position.y = lerp(body.position.y, 0.0, 10.0 * delta)
			body.scale.y = lerp(body.scale.y, 1.0, 10.0 * delta)
			head.rotation.x = lerp(head.rotation.x, -0.15, 10.0 * delta)
			rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 8.0 * delta)
			tail.rotation.y = sin(GS.msec() * 0.03) * 0.6
			if int(st * 3.0) != int((st - delta) * 3.0) and st < 1.4:
				Sfx.play("bark", -8.0, randf_range(0.9, 1.1))
			if (carrying or (player.mode == 1 and GS.gull_sense_count >= 3)) and d < 6.5 and cd <= 0.0:
				state = "crouch"
				st = 0.0
				# the warning: a "!" over the dog and a red patch where it will land
				Warn.bang(self, 1.3, 0.8)
				var wtgt = player.global_position + player.velocity * 0.15
				wtgt.y = global_position.y + 0.05
				Warn.disc(get_tree().current_scene, wtgt, 1.5, 0.72)
			elif st > 2.5 or d > 14.0:
				state = "sleep"
				cd = 6.0
		"crouch":
			st += delta
			body.position.y = lerp(body.position.y, -0.12, 14.0 * delta)
			rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), 12.0 * delta)
			if st > 0.72:
				state = "lunge"
				st = 0.0
				hit_done = false
				lunge_from = global_position
				lunge_to = player.global_position + player.velocity * 0.15
				lunge_to.y = global_position.y
				Sfx.play("bark", -2.0, 0.8)
		"lunge":
			st += delta
			var u = clamp(st / 0.5, 0.0, 1.0)
			var p = lunge_from.lerp(lunge_to, u)
			p.y = home.y + sin(u * PI) * 1.3
			global_position = p
			body.position.y = 0.0
			if not hit_done and d < 1.7 and player.global_position.y - home.y < 2.6:
				hit_done = true
				player.get_swatted(self, "lunge")
			if st > 0.5:
				state = "return"
				st = 0.0
				cd = 4.0
		"return":
			global_position = global_position.move_toward(home, 3.0 * delta)
			global_position.y = home.y
			rotation.y = lerp_angle(rotation.y, atan2(home.x - global_position.x, home.z - global_position.z), 6.0 * delta)
			if global_position.distance_to(home) < 0.2:
				state = "sleep"
				rotation.y = base_yaw
				cd = 5.0
