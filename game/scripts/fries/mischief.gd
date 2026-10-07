extends Node3D
# Everything a gull can steal that is not a fry: hats, glasses, shirts, a sock, a balloon (each KIND exists exactly ONCE in the world and can be taken
# ONCE), the drinks and the ice cream (they come back after a while: coffee, cocktail, ice cream give the gull a 20 s buff), and the two things in
# the sky (a cloud and the sun, quests of the mission board). The gull wears whatever it steals (see gull_visual.gd `wear`).
# Harder than a fry? No: one circle, one wave. But it needs speed, and it rewards nothing but style, a laugh or a buff. It still only wants the plain fry.

const Pattern = preload("res://scripts/world/pattern.gd")

# kinds that exist once per world (the first one the world builder places wins, the rest are quietly dropped)
const UNIQUE = ["hat", "sailor", "topper", "beret", "glasses", "shades", "necklace", "bowtie", "scarf", "pipe", "hawaii", "stripes", "coat", "socks", "balloon", "ball", "cloud", "sun"]
const ICE_COLORS = ["F7C7D4", "BFEBD2", "FFF1C7", "8A5636", "FFB36B", "9DB5F5", "FF6F91", "D6B6FF"]
static var claimed = {}
static var ice_count = 0

static func reset_claims():
	claimed = {}
	ice_count = 0

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
var quest_item = false

func setup(p_kind, parent, local_pos, p_owner = null):
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	kind = p_kind
	# one of each kind: a second hat, a second pipe... never appears (and a kind the gull already owns is not placed again after "continue")
	if UNIQUE.has(kind):
		if claimed.has(kind) or GS.worn.has(kind) or GS.mischief_counts.get(kind, 0) > 0:
			queue_free()
			return
		claimed[kind] = true
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

func _box(pos, size, c, rot = Vector3.ZERO, mat = null):
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat if mat != null else _m(c)
	mi.position = pos
	mi.rotation = rot
	visual.add_child(mi)
	return mi

func _cyl(pos, r, h, c, top = -1.0, mat = null):
	var mi = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.bottom_radius = r
	cm.top_radius = r if top < 0.0 else top
	cm.height = h
	cm.radial_segments = 12
	mi.mesh = cm
	mi.material_override = mat if mat != null else _m(c)
	mi.position = pos
	visual.add_child(mi)
	return mi

func _ball(pos, r, c, sc = Vector3.ONE, mat = null, emit = 0.2):
	var mi = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	mi.material_override = mat if mat != null else _m(c, emit)
	mi.position = pos
	mi.scale = sc
	visual.add_child(mi)
	return mi

func _build():
	match kind:
		"hat":                 # the straw hat: a gingham band
			_cyl(Vector3(0, 0, 0), 0.4, 0.03, "F0D9A0")
			_cyl(Vector3(0, 0.07, 0), 0.2, 0.14, "F0D9A0")
			_cyl(Vector3(0, 0.03, 0), 0.205, 0.04, "", -1.0, Pattern.mat("check", "D96D5F", "FFF3E0", 6))
		"icecream":
			var fl = ICE_COLORS[ice_count % ICE_COLORS.size()]
			var fl2 = ICE_COLORS[(ice_count * 3 + 2) % ICE_COLORS.size()]
			ice_count += 1
			_cyl(Vector3(0, 0.12, 0), 0.0, 0.24, "", 0.07, Pattern.mat("check", "D9A441", "B98428", 4))
			_ball(Vector3(0, 0.3, 0), 0.1, fl)
			_ball(Vector3(0, 0.42, 0), 0.085, fl2)
			_ball(Vector3(0, 0.5, 0), 0.03, "E03A55")
		"balloon":
			_cyl(Vector3(0, 0.6, 0), 0.006, 1.2, "FFFFFF")
			_ball(Vector3(0, 1.4, 0), 0.3, "", Vector3(1, 1.15, 1), Pattern.mat("stripes", "E85745", "FFF3E0", 3, 0.5))
		"ball":
			_ball(Vector3(0, 0.25, 0), 0.25, "", Vector3.ONE, Pattern.mat("vstripes", "F4F1E8", "E85745", 3, 0.6))
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
				_ball(Vector3(sin(a) * 0.2, 0.12 - cos(a) * 0.14, 0), 0.024, "F2B53A" if k % 2 == 0 else "FFE08A")
			_ball(Vector3(0, -0.04, 0.0), 0.04, "E03A55")
		"bowtie":
			var dots = Pattern.mat("dots", "C9202E", "FFFFFF", 3, 0.7)
			_box(Vector3(-0.07, 0, 0), Vector3(0.1, 0.07, 0.02), "", Vector3(0, 0, 0.4), dots)
			_box(Vector3(0.07, 0, 0), Vector3(0.1, 0.07, 0.02), "", Vector3(0, 0, -0.4), dots)
			_box(Vector3(0, 0, 0.005), Vector3(0.04, 0.04, 0.03), "8E1520")
		"sailor":
			_cyl(Vector3(0, 0.05, 0), 0.22, 0.1, "F4F4F0", 0.2)
			_cyl(Vector3(0, 0.0, 0), 0.25, 0.04, "", -1.0, Pattern.mat("stripes", "2D4F8E", "F4F4F0", 3))
			_ball(Vector3(0, 0.13, 0), 0.04, "D93A3A")
		"topper":
			_cyl(Vector3(0, 0.0, 0), 0.3, 0.03, "15151A")
			_cyl(Vector3(0, 0.17, 0), 0.19, 0.34, "", -1.0, Pattern.mat("vstripes", "15151A", "2A2A33", 5, 0.5))
			_cyl(Vector3(0, 0.06, 0), 0.2, 0.06, "C9A227")
		"beret":
			_ball(Vector3(0, 0.02, 0), 0.27, "", Vector3(1.0, 0.34, 1.0), Pattern.mat("dots", "C23B3B", "F6D9A8", 4))
			_box(Vector3(0, 0.12, 0), Vector3(0.03, 0.06, 0.03), "C23B3B")
		"glasses":
			for sx in [-1.0, 1.0]:
				var tm2 = MeshInstance3D.new()
				var tr = TorusMesh.new()
				tr.inner_radius = 0.04
				tr.outer_radius = 0.058
				tm2.mesh = tr
				tm2.material_override = Pattern.mat("dots", "A0642A", "3A200E", 3, 0.5)
				tm2.position = Vector3(0.085 * sx, 0, 0)
				tm2.rotation = Vector3(PI / 2.0, 0, 0)
				visual.add_child(tm2)
			_box(Vector3(0, 0.01, 0), Vector3(0.05, 0.012, 0.012), "3A200E")
		"hawaii":              # a flower shirt
			var fm = Pattern.mat("floral", "2BA7A0", "FF6FA8", 4)
			_box(Vector3(0, 0.0, 0), Vector3(0.62, 0.7, 0.12), "", Vector3.ZERO, fm)
			_box(Vector3(-0.42, 0.22, 0), Vector3(0.26, 0.2, 0.12), "", Vector3(0, 0, 0.6), fm)
			_box(Vector3(0.42, 0.22, 0), Vector3(0.26, 0.2, 0.12), "", Vector3(0, 0, -0.6), fm)
		"stripes":             # a sailor's shirt
			var sm = Pattern.mat("stripes", "F4F4F0", "2D4F8E", 5)
			_box(Vector3(0, 0.0, 0), Vector3(0.62, 0.7, 0.12), "", Vector3.ZERO, sm)
			_box(Vector3(-0.42, 0.22, 0), Vector3(0.26, 0.2, 0.12), "", Vector3(0, 0, 0.6), sm)
			_box(Vector3(0.42, 0.22, 0), Vector3(0.26, 0.2, 0.12), "", Vector3(0, 0, -0.6), sm)
		"coat":                # a long plaid coat
			var pm = Pattern.mat("plaid", "3A4155", "C9A64A", 4)
			_box(Vector3(0, -0.05, 0), Vector3(0.66, 0.95, 0.12), "", Vector3.ZERO, pm)
			_box(Vector3(-0.42, 0.25, 0), Vector3(0.26, 0.5, 0.12), "", Vector3(0, 0, 0.35), pm)
			_box(Vector3(0.42, 0.25, 0), Vector3(0.26, 0.5, 0.12), "", Vector3(0, 0, -0.35), pm)
			for k in 3:
				_ball(Vector3(0, 0.2 - k * 0.2, 0.07), 0.03, "E7C04A")
		"socks":               # a stripy sock on a peg
			var km = Pattern.mat("stripes", "E85745", "FFF3E0", 5)
			_box(Vector3(0, 0.0, 0), Vector3(0.2, 0.5, 0.12), "", Vector3.ZERO, km)
			_box(Vector3(0.1, -0.2, 0), Vector3(0.36, 0.16, 0.12), "", Vector3.ZERO, km)
			_box(Vector3(0, 0.24, 0), Vector3(0.24, 0.07, 0.14), "F4F1E8")
			_box(Vector3(0.26, -0.2, 0), Vector3(0.1, 0.16, 0.12), "3D8CD9")
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
			var sm2 = StandardMaterial3D.new()
			sm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			sm2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			sm2.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			sm2.albedo_color = Color(1, 1, 1, 0.3)
			sm2.albedo_texture = preload("res://scripts/player/gull_visual.gd").soft_tex()
			sq.material = sm2
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
			tm.material_override = Pattern.mat("vstripes", "D9442E", "FFF3E0", 6)
			visual.add_child(tm)
			_box(Vector3(0.1, -0.2, 0.26), Vector3(0.12, 0.34, 0.03), "", Vector3.ZERO, Pattern.mat("stripes", "D9442E", "FFF3E0", 4))
		"cloud":               # a whole cloud (the sky quest): a fat white heap that glitters
			quest_item = true
			var cm = _m("FFFFFF", 0.5)
			for k in [[0, 0, 0, 1.0], [1.1, -0.1, 0.2, 0.8], [-1.1, -0.15, -0.1, 0.78], [0.5, 0.45, 0, 0.7], [-0.5, 0.4, 0.2, 0.66], [1.8, -0.3, 0, 0.5], [-1.8, -0.3, 0, 0.5]]:
				_ball(Vector3(k[0], k[1], k[2]), k[3], "", Vector3(1.1, 0.8, 1.0), cm)
			visual.scale = Vector3.ONE * 2.6
			var gl = CPUParticles3D.new()
			gl.amount = 14
			gl.lifetime = 1.6
			gl.direction = Vector3.UP
			gl.spread = 180.0
			gl.initial_velocity_min = 0.2
			gl.initial_velocity_max = 0.7
			gl.gravity = Vector3.ZERO
			gl.local_coords = false
			gl.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			gl.emission_sphere_radius = 3.4
			var gq = QuadMesh.new()
			gq.size = Vector2(0.4, 0.4)
			var gm = StandardMaterial3D.new()
			gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			gm.albedo_color = Color(1.0, 0.92, 0.6, 0.9)
			gm.albedo_texture = preload("res://scripts/player/gull_visual.gd").soft_tex()
			gq.material = gm
			gl.mesh = gq
			visual.add_child(gl)
		"sun":                 # the sun (the last sky quest): a hot gold ball with a corona
			quest_item = true
			_ball(Vector3.ZERO, 1.0, "FFC83A", Vector3.ONE, null, 2.2)
			for k in 12:
				var a2 = k * TAU / 12.0
				var ray = _box(Vector3(cos(a2) * 1.5, sin(a2) * 1.5, 0), Vector3(0.28, 0.9, 0.12), "FFB02E", Vector3(0, 0, a2 + PI / 2.0))
				ray.material_override = _m("FFB02E", 1.6)
			var cg = MeshInstance3D.new()
			var cq = QuadMesh.new()
			cq.size = Vector2(7.0, 7.0)
			cg.mesh = cq
			var cgm = StandardMaterial3D.new()
			cgm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			cgm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			cgm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			cgm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			cgm.albedo_texture = preload("res://scripts/player/gull_visual.gd").soft_tex()
			cgm.albedo_color = Color(1.0, 0.8, 0.35, 0.85)
			cg.material_override = cgm
			cg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			visual.add_child(cg)
			visual.scale = Vector3.ONE * 2.2
	if kind == "ball":
		min_speed = 13.0
	elif kind == "cloud":
		min_speed = 96.0 / 6.0
	elif kind == "sun":
		min_speed = 114.0 / 6.0
	elif kind in ["pipe", "shades", "necklace", "bowtie", "scarf", "glasses"]:
		min_speed = 13.0      # worn by a person: a little less than the hats and balloons, but you still have to be quick
	elif kind in ["hawaii", "stripes", "coat", "socks"]:
		min_speed = 12.5      # laundry and beach clothes: a bit easier
	elif kind in ["coffee", "alcohol", "icecream"]:
		min_speed = 12.0      # a cup on a table, a cone in a hand
		respawn_sec = 55.0 if kind != "icecream" else 60.0
	elif kind in ["sailor", "topper", "beret"]:
		min_speed = 13.5
	else:
		min_speed = 14.0

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
		"hawaii", "stripes", "coat", "socks", "coffee", "alcohol":
			return global_position + Vector3(0, 0.25, 0)
		"cloud", "sun":
			return global_position
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
	tw.tween_property(self, "scale", Vector3(0.5, 0.5, 0.5) if not quest_item else Vector3(0.2, 0.2, 0.2), 0.12)

const AWARDS = {"hat": "HAT TRICK", "pipe": "PIPE DREAMS", "shades": "TOO COOL", "necklace": "BLING", "bowtie": "BLACK TIE (BLACK-BEAKED)", "scarf": "COZY",
	"sailor": "SEA LEGS", "topper": "A GENTLEBIRD", "beret": "VERY ARTISTIC", "glasses": "WELL READ", "hawaii": "WEEKEND MODE", "stripes": "MARINE LIFE",
	"coat": "DETECTIVE GULL", "socks": "SOCKED AWAY", "balloon": "UP, UP AND AWAY", "cloud": "HEAD IN THE CLOUDS", "sun": "TOO HOT TO HANDLE"}

func stolen(player):
	taken = true
	consumed = true
	remove_from_group("mischief")
	if owner_amb != null and is_instance_valid(owner_amb):
		owner_amb.theft_reaction()
	GS.add_heat(0.3)
	GS.mischief_counts[kind] = GS.mischief_counts.get(kind, 0) + 1
	if is_wearable():
		player.gull.wear(kind)
		GS.award(AWARDS[kind])
		if kind == "cloud":
			GS.quest_finish("cloud")
		elif kind == "sun":
			GS.quest_finish("sun")
	else:
		match kind:
			"coffee":
				GS.stats["drinks"] += 1
				GS.add_buff("coffee")
				GS.award("ESPRESSO")
				Sfx.play("sip", -4.0)
			"alcohol":
				GS.stats["drinks"] += 1
				GS.add_buff("alcohol")
				GS.award("LAST ORDERS")
				Sfx.play("sip", -4.0, 0.8)
			"icecream":
				GS.stats["drinks"] += 1
				GS.add_buff("ice")
				GS.award("SWEET TOOTH")
				Sfx.play("crunch", -8.0, 1.3)
			"ball":
				GS.award("BEACH BALL BANDIT")
	if is_wearable():
		if GS.worn.size() == 3:
			GS.comic.emit("cool", "GETTING DANGEROUSLY STYLISH.", {"tier": 0})
		elif GS.worn.size() >= 10 and not GS.achievements_done.has("FULLY ARMED"):
			GS.award("FULLY ARMED")
			GS.comic.emit("cool", "FULLY ARMED. STILL HUNGRY.", {"tier": 3, "col": GS.RARITY_COLORS[3]})
	if GS.mischief_counts.size() >= 3:
		GS.award("TROUBLEMAKER")
	if not (kind in ["coffee", "alcohol", "icecream"]):
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
	elif kind == "cloud":
		visual.position.y = sin(t * 0.6) * 0.5
	elif kind == "sun":
		visual.rotation.z += delta * 0.25
		visual.scale = Vector3.ONE * (2.2 + 0.08 * sin(t * 2.2))
