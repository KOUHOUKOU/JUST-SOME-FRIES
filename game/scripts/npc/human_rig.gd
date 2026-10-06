extends Node3D
# Procedural low-poly person with a tiny animation set. Visual only (game logic lives in the controllers).
# Face front = local +Z (see npc_controller). Modes: idle walk jog eat chat fish paint sit lie wave alarm play

static var _mats = {}

var style = {}
var root
var torso
var head
var eye_l
var eye_r
var mouth
var arm_l
var arm_r
var hand_l
var hand_r
var leg_l
var leg_r
var hand_anchor
var mode = "idle"
var holding = false
var seated = false
var phase = 0.0
var t = 0.0
var walk_rate = 1.0
var override_arm_r = null
var override_arm_r_z = 0.0
var emote_t = 0.0
var scale_f = 1.0
var seed_off = 0.0
var item_node_r = null
var item_node_l = null

static func mat(c, rough = 0.9):
	var key = str(c) + str(rough)
	if _mats.has(key):
		return _mats[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	_mats[key] = m
	return m

func _box(parent, pos, size, c, rot = Vector3.ZERO):
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(Color(c))
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

func _sph(parent, pos, r, c, sc = Vector3.ONE):
	var mi = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	mi.material_override = mat(Color(c))
	mi.position = pos
	mi.scale = sc
	parent.add_child(mi)
	return mi

func _cyl(parent, pos, r, h, c, top_r = -1.0, rot = Vector3.ZERO):
	var mi = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.bottom_radius = r
	cm.top_radius = r if top_r < 0.0 else top_r
	cm.height = h
	cm.radial_segments = 10
	mi.mesh = cm
	mi.material_override = mat(Color(c))
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

func build(st):
	style = st
	scale_f = st.get("scale", 1.0)
	seed_off = randf() * 10.0
	root = Node3D.new()
	root.scale = Vector3.ONE * scale_f
	add_child(root)
	var skin = Color(st.get("skin", "E3B590"))
	var shirt = Color(st.get("shirt", "8C8F96"))
	var pants = Color(st.get("pants", "4B5566"))
	var fat = st.get("fat", 1.0)
	torso = Node3D.new()
	torso.position = Vector3(0, 0.85, 0)
	root.add_child(torso)
	var body = MeshInstance3D.new()
	var cm = CapsuleMesh.new()
	cm.radius = 0.27
	cm.height = 0.82
	body.mesh = cm
	body.material_override = mat(shirt)
	body.position = Vector3(0, 0.32, 0)
	body.scale = Vector3(fat, 1.0, fat * 0.9)
	torso.add_child(body)
	if st.get("apron", false):
		_box(torso, Vector3(0, 0.15, 0.22), Vector3(0.34, 0.5, 0.04), "F4F1E8")
	if st.get("backpack", false):
		_box(torso, Vector3(0, 0.35, -0.27), Vector3(0.3, 0.4, 0.14), st.get("pack_color", "C65A3A"))
	if st.get("vest", false):
		_box(torso, Vector3(0, 0.32, 0.0), Vector3(0.56 * fat, 0.5, 0.42 * fat), st.get("vest_color", "E8573A"))
	# legs
	leg_l = Node3D.new()
	leg_l.position = Vector3(-0.11, 0.85, 0)
	root.add_child(leg_l)
	leg_r = Node3D.new()
	leg_r.position = Vector3(0.11, 0.85, 0)
	root.add_child(leg_r)
	for leg in [leg_l, leg_r]:
		_box(leg, Vector3(0, -0.38, 0), Vector3(0.16, 0.76, 0.19), pants)
		_box(leg, Vector3(0, -0.8, 0.04), Vector3(0.17, 0.08, 0.28), st.get("shoes", "3A3330"))
	# arms
	arm_l = _make_arm(-1.0, shirt, skin)
	arm_r = _make_arm(1.0, shirt, skin)
	hand_l = arm_l.get_node("Hand")
	hand_r = arm_r.get_node("Hand")
	# head
	head = Node3D.new()
	head.position = Vector3(0, 1.62, 0)
	root.add_child(head)
	_sph(head, Vector3(0, 0.16, 0), 0.165, skin, Vector3(1.0, 1.06, 1.0))
	eye_l = _sph(head, Vector3(-0.06, 0.2, 0.15), 0.022, "20202A")
	eye_r = _sph(head, Vector3(0.06, 0.2, 0.15), 0.022, "20202A")
	_sph(head, Vector3(0, 0.15, 0.165), 0.028, skin)
	mouth = _box(head, Vector3(0, 0.08, 0.16), Vector3(0.07, 0.016, 0.02), "6B3A30")
	if st.get("glasses", false):
		_box(head, Vector3(-0.06, 0.2, 0.165), Vector3(0.07, 0.05, 0.01), "2A2A30")
		_box(head, Vector3(0.06, 0.2, 0.165), Vector3(0.07, 0.05, 0.01), "2A2A30")
	_build_hair(st, skin)
	hand_anchor = Node3D.new()
	add_child(hand_anchor)
	if st.has("item_r"):
		item_node_r = _make_item(st["item_r"], hand_r)
	if st.has("item_l"):
		item_node_l = _make_item(st["item_l"], hand_l)

func _make_arm(side, shirt, skin):
	var a = Node3D.new()
	a.position = Vector3(0.35 * side, 1.4 * 1.0 - 0.0, 0)
	a.position.y = 0.85 + 0.55
	root.add_child(a)
	_box(a, Vector3(0, -0.28, 0), Vector3(0.1, 0.56, 0.1), shirt)
	_sph(a, Vector3(0, -0.58, 0), 0.065, skin)
	var h = Node3D.new()
	h.name = "Hand"
	h.position = Vector3(0, -0.6, 0.04)
	a.add_child(h)
	return a

func _build_hair(st, skin):
	var hc = st.get("hair", "3A2A20")
	match st.get("hair_style", "short"):
		"bald":
			pass
		"long":
			var hm = SphereMesh.new()
			hm.is_hemisphere = true
			hm.radius = 0.18
			hm.height = 0.36
			_hemi(head, Vector3(0, 0.2, -0.01), hm, hc)
			_box(head, Vector3(0, 0.0, -0.12), Vector3(0.3, 0.36, 0.08), hc)
		"bun":
			var hm = SphereMesh.new()
			hm.is_hemisphere = true
			hm.radius = 0.18
			hm.height = 0.36
			_hemi(head, Vector3(0, 0.2, -0.01), hm, hc)
			_sph(head, Vector3(0, 0.4, -0.08), 0.08, hc)
		"cap":
			var hm = SphereMesh.new()
			hm.is_hemisphere = true
			hm.radius = 0.18
			hm.height = 0.36
			_hemi(head, Vector3(0, 0.2, -0.01), hm, st.get("hat", "3D8CD9"))
			_box(head, Vector3(0, 0.22, 0.2), Vector3(0.22, 0.02, 0.16), st.get("hat", "3D8CD9"))
		"sunhat":
			_cyl(head, Vector3(0, 0.3, 0), 0.34, 0.02, st.get("hat", "F0D9A0"))
			_cyl(head, Vector3(0, 0.34, 0), 0.17, 0.1, st.get("hat", "F0D9A0"))
		"beanie":
			var hm = SphereMesh.new()
			hm.is_hemisphere = true
			hm.radius = 0.185
			hm.height = 0.4
			_hemi(head, Vector3(0, 0.2, -0.01), hm, st.get("hat", "C65A3A"))
		_:
			var hm = SphereMesh.new()
			hm.is_hemisphere = true
			hm.radius = 0.175
			hm.height = 0.35
			_hemi(head, Vector3(0, 0.2, -0.01), hm, hc)

func _hemi(parent, pos, mesh, c):
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(Color(c))
	mi.position = pos
	parent.add_child(mi)

func _make_item(kind, hand):
	var n = Node3D.new()
	hand.add_child(n)
	match kind:
		"broom":
			_cyl(n, Vector3(0, 0.0, 0.0), 0.025, 1.4, "8B6A4D", -1.0, Vector3(0.0, 0, 0))
			_box(n, Vector3(0, -0.72, 0.0), Vector3(0.3, 0.2, 0.12), "D9A441")
		"umbrella":
			_cyl(n, Vector3(0, 0.0, 0.0), 0.025, 1.0, "30343A")
			_cyl(n, Vector3(0, 0.55, 0.0), 0.1, 0.35, "D96D5F", 0.01)
		"watergun":
			_box(n, Vector3(0, 0.0, 0.14), Vector3(0.1, 0.14, 0.34), "2F9BE0")
			_cyl(n, Vector3(0, 0.04, 0.34), 0.03, 0.2, "F2C230", -1.0, Vector3(PI / 2, 0, 0))
		"rod":
			_cyl(n, Vector3(0, 0.0, 0.9), 0.015, 2.4, "5A4332", 0.006, Vector3(PI / 2 - 0.5, 0, 0))
		"brush":
			_cyl(n, Vector3(0, 0.0, 0.1), 0.012, 0.35, "6B4E33", -1.0, Vector3(PI / 2, 0, 0))
		"cup":
			_cyl(n, Vector3(0, 0.05, 0.05), 0.05, 0.13, "F4F1E8", 0.04)
		"icecream":
			_cyl(n, Vector3(0, 0.1, 0.05), 0.05, 0.2, "D9A441", 0.0)
			_sph(n, Vector3(0, 0.24, 0.05), 0.07, "F7C7D4")
			_sph(n, Vector3(0, 0.32, 0.05), 0.06, "FFF1C7")
		"paper":
			_box(n, Vector3(0, 0.05, 0.1), Vector3(0.34, 0.4, 0.02), "EFEBE0", Vector3(0.3, 0, 0))
		"tray":
			_cyl(n, Vector3(0, 0.05, 0.1), 0.3, 0.025, "B8BEC4")
			_cyl(n, Vector3(0.1, 0.12, 0.12), 0.045, 0.11, "F4F1E8", 0.04)
			_cyl(n, Vector3(-0.1, 0.12, 0.05), 0.045, 0.11, "D96D5F", 0.04)
		"guitar":
			_box(n, Vector3(0, 0.0, 0.1), Vector3(0.36, 0.48, 0.1), "B8743A")
			_box(n, Vector3(0, 0.55, 0.1), Vector3(0.06, 0.6, 0.04), "5A4332")
		"balloon":
			_cyl(n, Vector3(0, 0.6, 0.0), 0.004, 1.2, "FFFFFF")
			_sph(n, Vector3(0, 1.3, 0.0), 0.28, style.get("balloon", "E85745"), Vector3(1, 1.15, 1))
		"kite":
			_cyl(n, Vector3(0, 0.6, 0.0), 0.004, 1.2, "FFFFFF")
		"ball":
			_sph(n, Vector3(0, 0.1, 0.1), 0.14, "F4F1E8")
		"fries":            # a carton of fries held in the hand (just for looking at: people eat them)
			_box(n, Vector3(0, 0.07, 0.08), Vector3(0.12, 0.13, 0.07), "D93A3A")
			for k in 5:
				_box(n, Vector3(-0.04 + k * 0.02, 0.18, 0.08), Vector3(0.018, 0.1, 0.018), "F2C14E")
		"mug":
			_cyl(n, Vector3(0, 0.05, 0.06), 0.045, 0.1, "F4F1E8")
			_box(n, Vector3(0.06, 0.05, 0.06), Vector3(0.03, 0.05, 0.015), "F4F1E8")
		"cocktail":
			_cyl(n, Vector3(0, 0.1, 0.06), 0.0, 0.1, "FF7A4F", 0.06)
			_cyl(n, Vector3(0, 0.03, 0.06), 0.01, 0.06, "DDE8EE")
			_cyl(n, Vector3(0.03, 0.18, 0.06), 0.006, 0.12, "E03A55")
		"basket":
			_box(n, Vector3(0, 0.0, 0.2), Vector3(0.46, 0.22, 0.34), "C9A66A")
			_box(n, Vector3(0, 0.14, 0.2), Vector3(0.4, 0.08, 0.28), "F4F1E8")
		"clothes":          # a shirt held up by the shoulders
			_box(n, Vector3(0, 0.0, 0.1), Vector3(0.38, 0.42, 0.04), "2BA7A0")
			_box(n, Vector3(-0.22, 0.12, 0.1), Vector3(0.16, 0.12, 0.04), "2BA7A0", Vector3(0, 0, 0.6))
			_box(n, Vector3(0.22, 0.12, 0.1), Vector3(0.16, 0.12, 0.04), "2BA7A0", Vector3(0, 0, -0.6))
	return n

func emote(kind, sec = 0.8):
	emote_t = sec
	if kind == "surprise":
		eye_l.scale = Vector3.ONE * 1.7
		eye_r.scale = Vector3.ONE * 1.7
		mouth.scale = Vector3(0.8, 6.0, 1.0)

func set_mode(m):
	mode = m

func _process(delta):
	t += delta
	if emote_t > 0.0:
		emote_t -= delta
		if emote_t <= 0.0:
			eye_l.scale = Vector3.ONE
			eye_r.scale = Vector3.ONE
			mouth.scale = Vector3.ONE
	var walk_k = 0.0
	var arm_l_x = 0.0
	var arm_r_x = 0.0
	var arm_r_z = 0.0
	var arm_l_z = 0.0
	var leg_x = 0.0
	var root_y = 0.0
	var tilt = 0.0
	var seat = false
	match mode:
		"walk":
			phase += delta * 5.5 * walk_rate
			walk_k = 0.55
			leg_x = sin(phase) * walk_k
			arm_l_x = -sin(phase) * 0.45
			arm_r_x = sin(phase) * 0.45
			root_y = abs(sin(phase)) * 0.025
		"jog":
			phase += delta * 9.5 * walk_rate
			walk_k = 0.9
			leg_x = sin(phase) * walk_k
			arm_l_x = -sin(phase) * 0.9 - 0.6
			arm_r_x = sin(phase) * 0.9 - 0.6
			root_y = abs(sin(phase)) * 0.05
			tilt = 0.12
		"eat":
			var cyc = fmod(t * 0.33 + seed_off, 1.0)
			var up = smoothstep(0.0, 0.18, cyc) * (1.0 - smoothstep(0.55, 0.75, cyc))
			arm_r_x = lerp(-0.25, -2.2, up)
			arm_r_z = -0.2 * up
		"chat":
			arm_r_x = -0.7 + sin(t * 2.0 + seed_off) * 0.35
			arm_r_z = sin(t * 1.3) * 0.2
			arm_l_x = -0.3 + sin(t * 1.6 + 1.0) * 0.2
		"fish":
			arm_r_x = -1.1 + sin(t * 0.5) * 0.04
			arm_l_x = -1.0
		"paint":
			arm_r_x = -1.2 + sin(t * 1.7) * 0.12
			arm_r_z = sin(t * 1.1) * 0.25
		"wave":
			arm_r_x = -2.8
			arm_r_z = sin(t * 8.0) * 0.4
		"alarm":
			arm_r_x = -2.9
			arm_l_x = -0.4
			arm_r_z = sin(t * 14.0) * 0.15
		"play":
			arm_l_x = -1.1
			arm_r_x = -0.9 + sin(t * 5.0) * 0.25
			tilt = sin(t * 1.5) * 0.04
		"sit":
			seat = true
			leg_x = -1.45
			arm_r_x = -0.5
			arm_l_x = -0.5
		"lie":
			pass
		"idle":
			arm_l_x = sin(t * 1.2 + seed_off) * 0.04
			arm_r_x = -sin(t * 1.2 + seed_off) * 0.04
			root_y = sin(t * 1.4 + seed_off) * 0.006
	if seated and mode != "sit":
		seat = true
		leg_x = -1.45
	if holding:
		arm_l_x = -1.3 + sin(t * 3.0) * (0.06 if mode != "walk" else 0.12)
	if override_arm_r != null:
		arm_r_x = override_arm_r
		arm_r_z = override_arm_r_z
	var k = 1.0 - exp(-14.0 * delta)
	arm_l.rotation.x = lerp(arm_l.rotation.x, arm_l_x, k)
	arm_l.rotation.z = lerp(arm_l.rotation.z, arm_l_z, k)
	arm_r.rotation.x = lerp(arm_r.rotation.x, arm_r_x, k if override_arm_r == null else 1.0)
	arm_r.rotation.z = lerp(arm_r.rotation.z, arm_r_z, k)
	leg_l.rotation.x = lerp(leg_l.rotation.x, leg_x, k)
	leg_r.rotation.x = lerp(leg_r.rotation.x, -leg_x if not seat else leg_x, k)
	root.position.y = lerp(root.position.y, root_y - (0.42 * scale_f if seat else 0.0), k)
	torso.rotation.x = lerp(torso.rotation.x, tilt, k)
	if mode == "lie":
		root.rotation.x = lerp(root.rotation.x, -PI / 2.0, k)
		root.position.y = lerp(root.position.y, 0.22, k)
	else:
		root.rotation.x = lerp(root.rotation.x, 0.0, k)
	# held fry follows the left hand but stays upright
	hand_anchor.global_position = hand_l.global_position + Vector3(0, 0.02, 0)
	hand_anchor.global_rotation = Vector3(0, global_rotation.y, 0)
