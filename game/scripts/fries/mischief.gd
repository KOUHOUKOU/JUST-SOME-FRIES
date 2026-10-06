extends Node3D
# Optional decorative steals (docs/18 §12): hats, ice-cream cones, balloons, beach balls - and (round 4) the things strangers wear:
# a pipe, sunglasses, a necklace, a bow tie, a scarf. The gull wears whatever it steals (see gull_visual.gd `wear`).
# Harder than a fry (needs boost speed and a precise press) and rewards nothing but style and a laugh. It still only wants the plain fry.

var kind = "hat"
var taken = false
var available = true
var min_speed = 14.5
var ftype = "mischief"
var id = "MISCHIEF"
var consumed = false
var npc = null
var carrier = "none"
var tier = 0
var utype = ""
var revealed = true
var carried = false
var vanished = false
var owner_amb = null
var respawn_sec = 0.0        # drinks come back after a while (bars and cafes keep serving)
var home_parent = null
var home_pos = Vector3.ZERO
var visual
var t = 0.0
var base_y = 0.0

func setup(p_kind, parent, local_pos, p_owner = null):
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	kind = p_kind
	owner_amb = p_owner
	add_to_group("mischief")
	parent.add_child(self)
	position = local_pos
	home_parent = parent
	home_pos = local_pos
	base_y = local_pos.y
	visual = Node3D.new()
	add_child(visual)
	_build()

func _m(c, emit = 0.0):
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(c)
	m.roughness = 0.8
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c)
		m.emission_energy_multiplier = emit
	return m

func _box(pos, size, c, rot = Vector3.ZERO):
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _m(c)
	mi.position = pos
	mi.rotation = rot
	visual.add_child(mi)

func _cyl(pos, r, h, c, top = -1.0):
	var mi = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.bottom_radius = r
	cm.top_radius = r if top < 0.0 else top
	cm.height = h
	cm.radial_segments = 12
	mi.mesh = cm
	mi.material_override = _m(c)
	mi.position = pos
	visual.add_child(mi)

func _ball(pos, r, c, sc = Vector3.ONE):
	var mi = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	mi.material_override = _m(c, 0.2)
	mi.position = pos
	mi.scale = sc
	visual.add_child(mi)

func _build():
	match kind:
		"hat":
			_cyl(Vector3(0, 0, 0), 0.4, 0.03, "F0D9A0")
			_cyl(Vector3(0, 0.07, 0), 0.2, 0.14, "F0D9A0")
			_cyl(Vector3(0, 0.03, 0), 0.205, 0.04, "D96D5F")
		"icecream":
			_cyl(Vector3(0, 0.12, 0), 0.07, 0.24, "D9A441", 0.0)
			_ball(Vector3(0, 0.3, 0), 0.1, "F7C7D4")
			_ball(Vector3(0, 0.42, 0), 0.085, "FFF1C7")
		"balloon":
			_cyl(Vector3(0, 0.6, 0), 0.006, 1.2, "FFFFFF")
			_ball(Vector3(0, 1.4, 0), 0.3, _pick_col(), Vector3(1, 1.15, 1))
		"ball":
			_ball(Vector3(0, 0.25, 0), 0.25, "F4F1E8")
			_box(Vector3(0, 0.25, 0), Vector3(0.52, 0.12, 0.52), "E85745")
		"pipe":
			_box(Vector3(0, 0, 0.09), Vector3(0.022, 0.022, 0.18), "5A3A1E")
			_cyl(Vector3(0, 0.035, 0.19), 0.034, 0.075, "3E2412")
		"shades":
			_box(Vector3(-0.062, 0, 0), Vector3(0.07, 0.048, 0.014), "0A0A10")
			_box(Vector3(0.062, 0, 0), Vector3(0.07, 0.048, 0.014), "0A0A10")
			_box(Vector3(0, 0.012, 0), Vector3(0.05, 0.012, 0.012), "0A0A10")
		"necklace":
			for k in 9:
				var a = -1.25 + k * 0.3125
				_ball(Vector3(sin(a) * 0.2, 0.12 - cos(a) * 0.14, 0), 0.024, "F2B53A")
			_ball(Vector3(0, -0.04, 0.0), 0.04, "E03A55")
		"bowtie":
			_box(Vector3(-0.07, 0, 0), Vector3(0.1, 0.07, 0.02), "C9202E", Vector3(0, 0, 0.4))
			_box(Vector3(0.07, 0, 0), Vector3(0.1, 0.07, 0.02), "C9202E", Vector3(0, 0, -0.4))
			_box(Vector3(0, 0, 0.005), Vector3(0.04, 0.04, 0.03), "8E1520")
		"sailor":
			_cyl(Vector3(0, 0.05, 0), 0.22, 0.1, "F4F4F0", 0.2)
			_cyl(Vector3(0, 0.0, 0), 0.25, 0.04, "2D4F8E")
			_ball(Vector3(0, 0.13, 0), 0.04, "D93A3A")
		"topper":
			_cyl(Vector3(0, 0.0, 0), 0.3, 0.03, "15151A")
			_cyl(Vector3(0, 0.17, 0), 0.19, 0.34, "15151A")
			_cyl(Vector3(0, 0.06, 0), 0.2, 0.06, "C9A227")
		"beret":
			_ball(Vector3(0, 0.02, 0), 0.27, "C23B3B", Vector3(1.0, 0.34, 1.0))
			_box(Vector3(0, 0.12, 0), Vector3(0.03, 0.06, 0.03), "C23B3B")
		"glasses":
			for sx in [-1.0, 1.0]:
				var tm2 = MeshInstance3D.new()
				var tr = TorusMesh.new()
				tr.inner_radius = 0.04
				tr.outer_radius = 0.058
				tm2.mesh = tr
				tm2.material_override = _m("20202A")
				tm2.position = Vector3(0.085 * sx, 0, 0)
				tm2.rotation = Vector3(PI / 2.0, 0, 0)
				visual.add_child(tm2)
			_box(Vector3(0, 0.01, 0), Vector3(0.05, 0.012, 0.012), "20202A")
		"hawaii":
			_box(Vector3(0, 0.0, 0), Vector3(0.62, 0.7, 0.12), "2BA7A0")
			_box(Vector3(-0.42, 0.22, 0), Vector3(0.26, 0.2, 0.12), "2BA7A0", Vector3(0, 0, 0.6))
			_box(Vector3(0.42, 0.22, 0), Vector3(0.26, 0.2, 0.12), "2BA7A0", Vector3(0, 0, -0.6))
			for k in 6:
				_ball(Vector3(-0.2 + (k % 3) * 0.2, 0.2 - (k / 3) * 0.3, 0.07), 0.05, ["FF6FA8", "FFD23A", "FF8A3C"][k % 3], Vector3(1, 1, 0.4))
		"stripes":
			_box(Vector3(0, 0.0, 0), Vector3(0.62, 0.7, 0.12), "F4F4F0")
			_box(Vector3(-0.42, 0.22, 0), Vector3(0.26, 0.2, 0.12), "F4F4F0", Vector3(0, 0, 0.6))
			_box(Vector3(0.42, 0.22, 0), Vector3(0.26, 0.2, 0.12), "F4F4F0", Vector3(0, 0, -0.6))
			for k in 4:
				_box(Vector3(0, 0.26 - k * 0.17, 0.065), Vector3(0.62, 0.07, 0.01), "2D4F8E")
		"coat":
			_box(Vector3(0, -0.05, 0), Vector3(0.66, 0.95, 0.12), "262B3A")
			_box(Vector3(-0.42, 0.25, 0), Vector3(0.26, 0.5, 0.12), "262B3A", Vector3(0, 0, 0.35))
			_box(Vector3(0.42, 0.25, 0), Vector3(0.26, 0.5, 0.12), "262B3A", Vector3(0, 0, -0.35))
			for k in 3:
				_ball(Vector3(0, 0.2 - k * 0.2, 0.07), 0.03, "E7C04A")
		"coffee":
			_cyl(Vector3(0, 0.0, 0), 0.2, 0.02, "F4F1E8")
			_cyl(Vector3(0, 0.1, 0), 0.12, 0.18, "F4F1E8", 0.14)
			_cyl(Vector3(0, 0.185, 0), 0.115, 0.012, "5A3418")
			_box(Vector3(0.17, 0.11, 0), Vector3(0.07, 0.09, 0.025), "F4F1E8")
			var st = CPUParticles3D.new()
			st.amount = 6
			st.lifetime = 1.4
			st.direction = Vector3.UP
			st.spread = 14.0
			st.initial_velocity_min = 0.1
			st.initial_velocity_max = 0.2
			st.gravity = Vector3(0, 0.05, 0)
			st.local_coords = false
			var sq = QuadMesh.new()
			sq.size = Vector2(0.1, 0.1)
			var sm = StandardMaterial3D.new()
			sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			sm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			sm.albedo_color = Color(1, 1, 1, 0.3)
			sm.albedo_texture = preload("res://scripts/player/gull_visual.gd").soft_tex()
			sq.material = sm
			st.mesh = sq
			st.position = Vector3(0, 0.22, 0)
			visual.add_child(st)
		"alcohol":
			_cyl(Vector3(0, 0.0, 0), 0.1, 0.02, "DDE8EE")
			_cyl(Vector3(0, 0.07, 0), 0.015, 0.14, "DDE8EE")
			_cyl(Vector3(0, 0.2, 0), 0.0, 0.2, "FF7A4F", 0.17)
			_cyl(Vector3(0, 0.28, 0), 0.17, 0.014, "FFB38A")
			_cyl(Vector3(0.05, 0.4, 0), 0.01, 0.2, "E03A55")
			_ball(Vector3(-0.06, 0.3, 0.02), 0.03, "C9202E")
			_cyl(Vector3(0.08, 0.34, 0), 0.0, 0.12, "9B5DE0", 0.1)
		"scarf":
			var tm = MeshInstance3D.new()
			var tor = TorusMesh.new()
			tor.inner_radius = 0.2
			tor.outer_radius = 0.3
			tm.mesh = tor
			tm.material_override = _m("D9442E")
			visual.add_child(tm)
			_box(Vector3(0.1, -0.2, 0.26), Vector3(0.12, 0.34, 0.03), "D9442E")
	if kind == "ball":
		min_speed = 13.0
	elif kind in ["pipe", "shades", "necklace", "bowtie", "scarf", "glasses"]:
		min_speed = 13.5      # worn by a person: a little less than the hats and balloons, but you still have to be quick
	elif kind in ["hawaii", "stripes", "coat"]:
		min_speed = 12.5      # laundry and beach clothes: a bit easier
	elif kind in ["coffee", "alcohol"]:
		min_speed = 12.0      # a cup on a table
		respawn_sec = 55.0
	elif kind in ["sailor", "topper", "beret"]:
		min_speed = 13.5
	else:
		min_speed = 14.5

func _pick_col():
	return ["E85745", "3D8CD9", "F1C94B", "4FB56D", "F7C7D4"][randi() % 5]

func is_snatchable():
	return available and not taken and is_visible_in_tree()

func is_fry_like():
	return false

func vision_info():
	return null

func aim_point():
	match kind:
		"balloon":
			return global_position + Vector3(0, 1.4, 0)
		"icecream":
			return global_position + Vector3(0, 0.3, 0)
		"hawaii", "stripes", "coat", "coffee", "alcohol":
			return global_position + Vector3(0, 0.25, 0)
	return global_position + Vector3(0, 0.1, 0)

# a fresh copy of a drink that was taken (bars and cafes keep serving), once the player is not standing right there
static func respawn_static(parent, pos, kind):
	if not is_instance_valid(parent) or not parent.is_inside_tree():
		return
	var pl = parent.get_tree().get_first_node_in_group("player")
	if pl != null and pl.global_position.distance_to(parent.to_global(pos)) < 14.0:
		parent.get_tree().create_timer(5.0).timeout.connect(Callable(load("res://scripts/fries/mischief.gd"), "respawn_static").bind(parent, pos, kind))
		return
	var m = Node3D.new()
	m.set_script(load("res://scripts/fries/mischief.gd"))
	m.setup(kind, parent, pos)

func is_wearable():
	return kind in GS.WEARABLES

func guard(sec):
	available = false
	get_tree().create_timer(sec).timeout.connect(func():
		if not taken:
			available = true)

func attach(socket):
	reparent(socket, true)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "position", Vector3(0, 0, -0.05), 0.12)
	tw.tween_property(self, "rotation", Vector3.ZERO, 0.12)
	tw.tween_property(self, "scale", Vector3(0.5, 0.5, 0.5), 0.12)

func stolen(player):
	taken = true
	consumed = true
	remove_from_group("mischief")
	if owner_amb != null and is_instance_valid(owner_amb):
		owner_amb.theft_reaction()
	GS.add_heat(0.3)
	match kind:
		"hat":
			GS.mischief_counts["hat"] = GS.mischief_counts.get("hat", 0) + 1
			player.gull.wear("hat")
			if GS.mischief_counts["hat"] >= 3:
				GS.award("HAT TRICK")
		"balloon":
			GS.mischief_counts["balloon"] = GS.mischief_counts.get("balloon", 0) + 1
			player.gull.wear("balloon")
			GS.award("UP, UP AND AWAY")
		"pipe", "shades", "necklace", "bowtie", "scarf", "sailor", "topper", "beret", "glasses", "hawaii", "stripes", "coat":
			GS.mischief_counts[kind] = GS.mischief_counts.get(kind, 0) + 1
			player.gull.wear(kind)
			GS.award({"pipe": "PIPE DREAMS", "shades": "TOO COOL", "necklace": "BLING", "bowtie": "BLACK TIE (BLACK-BEAKED)", "scarf": "COZY", "sailor": "SEA LEGS",
				"topper": "A GENTLEBIRD", "beret": "VERY ARTISTIC", "glasses": "WELL READ", "hawaii": "WEEKEND MODE", "stripes": "MARINE LIFE", "coat": "DETECTIVE GULL"}[kind])
		"coffee":
			GS.mischief_counts["coffee"] = GS.mischief_counts.get("coffee", 0) + 1
			GS.stats["drinks"] += 1
			GS.set_drink("coffee")
			GS.award("ESPRESSO")
			Sfx.play("sip", -4.0)
		"alcohol":
			GS.mischief_counts["alcohol"] = GS.mischief_counts.get("alcohol", 0) + 1
			GS.stats["drinks"] += 1
			GS.set_drink("alcohol")
			GS.award("LAST ORDERS")
			Sfx.play("sip", -4.0, 0.8)
		"icecream":
			GS.mischief_counts["icecream"] = GS.mischief_counts.get("icecream", 0) + 1
			GS.award("SWEET TOOTH")
			Sfx.play("crunch", -8.0, 1.3)
		"ball":
			GS.mischief_counts["ball"] = GS.mischief_counts.get("ball", 0) + 1
			GS.award("BEACH BALL BANDIT")
	if is_wearable():
		if GS.worn.size() == 3:
			GS.comic.emit("cool", "GETTING DANGEROUSLY STYLISH.", {"tier": 0})
		elif GS.worn.size() >= 10 and not GS.achievements_done.has("FULLY ARMED"):
			GS.award("FULLY ARMED")
			GS.comic.emit("cool", "FULLY ARMED. STILL HUNGRY.", {"tier": 3, "col": GS.RARITY_COLORS[3]})
	if GS.mischief_counts.size() >= 3:
		GS.award("TROUBLEMAKER")
	if kind == "coffee" or kind == "alcohol":
		pass
	else:
		Sfx.play("equip" if is_wearable() else "happy", -6.0, 1.0)
	if respawn_sec > 0.0 and home_parent != null and is_instance_valid(home_parent):
		player.get_tree().create_timer(respawn_sec).timeout.connect(Callable(load("res://scripts/fries/mischief.gd"), "respawn_static").bind(home_parent, home_pos, kind))
	get_tree().create_timer(2.5 if kind == "icecream" else 0.2).timeout.connect(queue_free)

func _process(delta):
	t += delta
	if taken:
		return
	if kind == "balloon":
		visual.rotation.z = sin(t * 1.5) * 0.08
	elif kind == "ball":
		visual.position.y = abs(sin(t * 1.2)) * 0.03
