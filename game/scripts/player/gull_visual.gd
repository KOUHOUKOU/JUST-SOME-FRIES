extends Node3D
# Procedural gull: bent wings (shoulder + elbow), tail fan, legs. Pure visuals; gameplay never depends on it.
# Optional: assets/models/hero_gull.glb replaces the fallback (see player).

const Pattern = preload("res://scripts/world/pattern.gd")
const WHITE = Color("F6F6F1")
const GREY = Color("AEB8C0")
const DARK = Color("2B2F36")
const ORANGE = Color("F2A22E")

var shoulder = {}
var elbow = {}
var head
var beak_socket
var legs
var tail
var wing_mats = []
var tip_mats = []
var tail_mat
var chest_mat
var eye_mats = []
var beak_mat
var trail_l
var trail_r
var cur = {"a": 0.12, "e": 0.3, "s": 0.0, "legs": 0.0}
var t = 0.0
var flap_phase = 0.0
var head_lunge = 0.0
var worn = {}                  # slot nodes of what this gull has ON right now: kind -> node
var plain = false              # not the player: no growth looks
var tracked = false            # the player gull: wearing changes the game state (GS.worn = owned, GS.equipped = on)
var body_mi

func _mat(c, rough = 0.95):
	var m = StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

func _mesh(parent, mesh, pos, mat):
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

func _box(size):
	var b = BoxMesh.new()
	b.size = size
	return b

func _sph(r, h = -1.0):
	var s = SphereMesh.new()
	s.radius = r
	s.height = r * 2.0 if h < 0.0 else h
	s.radial_segments = 14
	s.rings = 8
	return s

func build():
	var white = _mat(WHITE)
	chest_mat = _mat(WHITE)
	var body = _mesh(self, _sph(0.2), Vector3(0, 0, 0), white)
	body.scale = Vector3(1.0, 0.9, 1.9)
	body_mi = body
	var chest = _mesh(self, _sph(0.12), Vector3(0, -0.04, -0.2), chest_mat)
	chest.scale = Vector3(1.1, 1.0, 1.0)
	head = Node3D.new()
	head.position = Vector3(0, 0.1, -0.36)
	add_child(head)
	_mesh(head, _sph(0.115), Vector3.ZERO, white)
	beak_mat = _mat(ORANGE)
	_mesh(head, _box(Vector3(0.05, 0.045, 0.2)), Vector3(0, -0.03, -0.16), beak_mat)
	_mesh(head, _box(Vector3(0.052, 0.02, 0.05)), Vector3(0, -0.055, -0.22), _mat(Color("D9443A")))
	for sx in [-1.0, 1.0]:
		var em = _mat(Color("101015"))
		eye_mats.append(em)
		_mesh(head, _sph(0.02), Vector3(0.06 * sx, 0.03, -0.065), em)
	beak_socket = Marker3D.new()
	beak_socket.name = "BeakSocket"
	beak_socket.position = Vector3(0, -0.03, -0.3)
	head.add_child(beak_socket)
	tail = Node3D.new()
	tail.position = Vector3(0, 0.0, 0.38)
	add_child(tail)
	tail_mat = _mat(GREY)
	for k in 3:
		var tm = _mesh(tail, _box(Vector3(0.1, 0.02, 0.28)), Vector3((k - 1) * 0.06, 0, 0.1), tail_mat)
		tm.rotation.y = (k - 1) * 0.16
	for side in [-1.0, 1.0]:
		var sh = Node3D.new()
		sh.position = Vector3(0.14 * side, 0.07, -0.06)
		add_child(sh)
		shoulder[side] = sh
		var wm = _mat(GREY)
		wing_mats.append(wm)
		_mesh(sh, _box(Vector3(0.32, 0.035, 0.34)), Vector3(0.16 * side, 0, 0.04), wm)
		var el = Node3D.new()
		el.position = Vector3(0.32 * side, 0, 0.0)
		sh.add_child(el)
		elbow[side] = el
		var wm2 = _mat(GREY)
		wing_mats.append(wm2)
		_mesh(el, _box(Vector3(0.34, 0.03, 0.28)), Vector3(0.17 * side, 0, 0.06), wm2)
		var tm2 = _mat(DARK)
		tip_mats.append(tm2)
		_mesh(el, _box(Vector3(0.17, 0.032, 0.2)), Vector3(0.42 * side, 0, 0.1), tm2)
		_mesh(el, _box(Vector3(0.05, 0.034, 0.05)), Vector3(0.38 * side, 0, 0.03), _mat(WHITE))
	legs = Node3D.new()
	add_child(legs)
	var om = _mat(ORANGE)
	for x in [-0.07, 0.07]:
		_mesh(legs, _box(Vector3(0.025, 0.2, 0.025)), Vector3(x, -0.28, 0.02), om)
		_mesh(legs, _box(Vector3(0.08, 0.015, 0.13)), Vector3(x, -0.39, -0.03), om)
	legs.visible = false
	trail_l = _make_trail()
	trail_r = _make_trail()
	elbow[-1.0].add_child(trail_l)
	elbow[1.0].add_child(trail_r)
	trail_l.position = Vector3(-0.5, 0, 0.1)
	trail_r.position = Vector3(0.5, 0, 0.1)
	apply_growth()

func _make_trail():
	var p = CPUParticles3D.new()
	p.amount = 40
	p.lifetime = 0.55
	p.local_coords = false
	p.emitting = false
	p.direction = Vector3(0, 0, 1)
	p.spread = 4.0
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 0.6
	p.gravity = Vector3.ZERO
	var q = QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = Color(1, 1, 1, 0.5)
	m.albedo_texture = soft_tex()
	q.material = m
	p.mesh = q
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.2
	return p

# growth cosmetics: the gull visibly changes with every special fry (docs/18 §11)
# back to the bare gull (the ending: all the finery falls away)
func reset_plain():
	plain = true
	for k in worn.keys():
		_remove(k)
	scale = Vector3.ONE
	if body_mi != null:
		body_mi.scale = Vector3(1.0, 0.9, 1.9)
	for m in tip_mats:
		m.albedo_color = DARK
	for m in wing_mats:
		m.albedo_color = GREY
	tail_mat.albedo_color = GREY
	chest_mat.albedo_color = WHITE
	beak_mat.albedo_color = ORANGE
	for m in eye_mats:
		m.albedo_color = Color("101015")
	trail_color = Color.WHITE

func apply_growth():
	if plain:
		return          # other gulls (the buddy, the big brother) never take the player's stat looks
	var n = GS.special_count()
	scale = Vector3.ONE * (1.0 + 0.03 * n + 0.1 * (GS.star_count() / 10.0))
	var red = Color("E85745")
	var blue = Color("3D8CD9")
	var yellow = Color("F1C94B")
	var green = Color("4FB56D")
	var rose = Color("F277B5")
	var silver = Color("C9D6E6")
	if body_mi != null:
		var fluff = 1.0 + 0.045 * GS.lv["orange"]       # FLUFF fries: a visibly rounder gull
		body_mi.scale = Vector3(1.0 * fluff, 0.9 * fluff, 1.9)
	for m in tip_mats:
		m.albedo_color = red.darkened(0.1) if GS.has["red"] else DARK
	tail_mat.albedo_color = red.lightened(0.1) if GS.has["red"] else GREY
	chest_mat.albedo_color = blue.lightened(0.5) if GS.has["blue"] else WHITE
	beak_mat.albedo_color = yellow if GS.has["purple"] else ORANGE
	for m in eye_mats:
		m.albedo_color = rose.darkened(0.2) if GS.has["pink"] else (green.darkened(0.5) if GS.has["green"] else Color("101015"))
	if GS.has["cyan"]:
		for m in wing_mats:
			m.albedo_color = GREY.lerp(silver, 0.35 + 0.15 * GS.lv["cyan"])
	else:
		for m in wing_mats:
			m.albedo_color = GREY
	var tc = Color.WHITE
	if GS.has["orange"]:
		tc = tc.lerp(Color("F0883C"), 0.5)
	if GS.has["cyan"]:
		tc = tc.lerp(silver, 0.5)
	if GS.has["red"]:
		tc = tc.lerp(red, 0.5)
	if GS.has["blue"]:
		tc = tc.lerp(blue, 0.5)
	if GS.has["purple"]:
		tc = tc.lerp(yellow, 0.5)
	if GS.has["green"]:
		tc = tc.lerp(green, 0.5)
	if GS.has["pink"]:
		tc = tc.lerp(rose, 0.5)
	trail_color = tc

var trail_color = Color.WHITE
static var _soft = null

static func soft_tex():
	if _soft == null:
		var gr = Gradient.new()
		gr.set_color(0, Color(1, 1, 1, 1))
		gr.set_color(1, Color(1, 1, 1, 0))
		var gt = GradientTexture2D.new()
		gt.gradient = gr
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 64
		gt.height = 64
		_soft = gt
	return _soft

func set_trails(on):
	for tr in [trail_l, trail_r]:
		tr.emitting = on
		tr.mesh.material.albedo_color = Color(trail_color.r, trail_color.g, trail_color.b, 0.55)

# st: {mode, flap, roll_extra, boost_n, throttle}
func pose(mode, flap_t, throttle, delta):
	t += delta
	var a = 0.12
	var e = 0.3
	var s = 0.0
	var leg = 0.0
	match mode:
		"glide":
			a = 0.12 + sin(t * 1.6) * 0.04
			e = 0.3 + sin(t * 1.3) * 0.05
		"throttle":
			flap_phase += delta * TAU * 1.5
			a = 0.1 + sin(flap_phase) * 0.45
			e = 0.3 - cos(flap_phase) * 0.25
			s = 0.15
		"boost":
			a = -0.05
			e = 0.55
			s = 0.85
		"brake":
			a = 0.55
			e = 0.2
			s = -0.35
			leg = 1.0
		"ground":
			a = -1.2
			e = 1.1
			s = 0.1
			leg = 1.0
		"tumble":
			a = sin(t * 24.0) * 0.9
			e = cos(t * 19.0) * 0.6
	if flap_t > 0.0:
		a += sin((1.0 - flap_t) * TAU) * 0.95
		e -= sin((1.0 - flap_t) * TAU + 0.8) * 0.4
	var k = 1.0 - exp(-12.0 * delta)
	cur["a"] = lerp(cur["a"], a, k)
	cur["e"] = lerp(cur["e"], e, k)
	cur["s"] = lerp(cur["s"], s, k)
	cur["legs"] = lerp(cur["legs"], leg, k)
	for side in [-1.0, 1.0]:
		shoulder[side].rotation = Vector3(0, -cur["s"] * side, cur["a"] * side)
		elbow[side].rotation = Vector3(0, 0, -cur["e"] * side)
	legs.visible = cur["legs"] > 0.3
	tail.rotation.x = -0.1 * cur["legs"]
	head.position.z = -0.36 - head_lunge

# ---- wearables: every kind lives in one slot; putting something on replaces whatever sat in that slot ----
const SLOTS = {"hat": "head", "sailor": "head", "topper": "head", "beret": "head", "glasses": "eyes", "shades": "eyes", "necklace": "neck", "bowtie": "neck",
	"scarf": "neck", "pipe": "mouth", "hawaii": "body", "stripes": "body", "coat": "body", "balloon": "float", "socks": "tail", "cloud": "cloud", "sun": "halo"}

static func slot_of(kind):
	return SLOTS.get(kind, "head")

# put it on (and own it); `silent` for gulls that are not the player
func wear(kind, silent = false):
	var slot = slot_of(kind)
	for k in worn.keys():
		if slot_of(k) == slot:
			_remove(k)
	var n = _build_item(kind)
	worn[kind] = n
	if tracked and not silent:
		GS.worn[kind] = true
		GS.equipped[kind] = true

func _remove(kind):
	if worn.has(kind):
		if is_instance_valid(worn[kind]):
			worn[kind].queue_free()
		worn.erase(kind)
	if tracked:
		GS.equipped.erase(kind)

func unwear(kind):
	_remove(kind)

func is_on(kind):
	return worn.has(kind)

# put everything the gull has on back (after loading a save)
func restore_worn():
	for k in worn.keys():
		_remove(k)
	var list = GS.equipped.keys()
	for k in list:
		wear(k, true)
		GS.equipped[k] = true

func strip_all():
	for k in worn.keys():
		var n = worn[k]
		if is_instance_valid(n):
			n.visible = false

func show_all():
	for k in worn.keys():
		var n = worn[k]
		if is_instance_valid(n):
			n.visible = true

func worn_count():
	return worn.size()

func _cyl(parent, r_top, r_bot, h, pos, col, rough = 0.95, pat = null):
	var mi = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bot
	cm.height = h
	cm.radial_segments = 14
	mi.mesh = cm
	mi.material_override = pat if pat != null else _mat(Color(col), rough)
	mi.position = pos
	parent.add_child(mi)
	return mi

func _blk(parent, size, pos, col, rough = 0.95, pat = null):
	var mi = MeshInstance3D.new()
	mi.mesh = _box(size)
	mi.material_override = pat if pat != null else _mat(Color(col), rough)
	mi.position = pos
	parent.add_child(mi)
	return mi

func _ball_(parent, r, pos, col, sc = Vector3.ONE, rough = 0.95, pat = null):
	var mi = MeshInstance3D.new()
	mi.mesh = _sph(r)
	mi.material_override = pat if pat != null else _mat(Color(col), rough)
	mi.position = pos
	mi.scale = sc
	parent.add_child(mi)
	return mi

func _ring_(parent, r_in, r_out, pos, col, rot = Vector3(PI / 2.0, 0, 0), rough = 0.4, pat = null):
	var mi = MeshInstance3D.new()
	var tm = TorusMesh.new()
	tm.inner_radius = r_in
	tm.outer_radius = r_out
	mi.mesh = tm
	mi.material_override = pat if pat != null else _mat(Color(col), rough)
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

func _build_item(kind):
	var n = Node3D.new()
	match kind:
		"hat":                      # the straw sun hat
			head.add_child(n)
			n.position = Vector3(0, 0.1, 0.0)
			_cyl(n, 0.2, 0.2, 0.02, Vector3.ZERO, "F0D9A0")
			_cyl(n, 0.1, 0.11, 0.09, Vector3(0, 0.05, 0), "F0D9A0")
			_cyl(n, 0.112, 0.112, 0.025, Vector3(0, 0.02, 0), "D96D5F", 0.95, Pattern.mat("check", "D96D5F", "FFF3E0", 6))
		"sailor":                   # a white sailor cap with a blue band and a red pom
			head.add_child(n)
			n.position = Vector3(0, 0.1, 0.0)
			_cyl(n, 0.115, 0.125, 0.06, Vector3(0, 0.03, 0), "F4F4F0")
			_cyl(n, 0.13, 0.13, 0.02, Vector3(0, 0.0, 0), "2D4F8E", 0.95, Pattern.mat("stripes", "2D4F8E", "F4F4F0", 2))
			_cyl(n, 0.1, 0.12, 0.012, Vector3(0, 0.065, 0), "F4F4F0")
			_ball_(n, 0.02, Vector3(0, 0.085, 0), "D93A3A")
		"topper":                   # a tall black top hat
			head.add_child(n)
			n.position = Vector3(0, 0.1, 0.0)
			_cyl(n, 0.17, 0.17, 0.015, Vector3.ZERO, "15151A")
			_cyl(n, 0.095, 0.1, 0.17, Vector3(0, 0.09, 0), "15151A", 0.95, Pattern.mat("vstripes", "15151A", "2E2E3A", 5))
			_cyl(n, 0.101, 0.101, 0.03, Vector3(0, 0.03, 0), "C9A227", 0.4)
		"beret":                    # a red beret, slightly sideways
			head.add_child(n)
			n.position = Vector3(0.02, 0.105, 0.0)
			_ball_(n, 0.13, Vector3(0, 0.0, 0), "C23B3B", Vector3(1.0, 0.32, 1.0), 0.95, Pattern.mat("dots", "C23B3B", "F6D9A8", 3))
			_blk(n, Vector3(0.012, 0.03, 0.012), Vector3(0, 0.05, 0), "C23B3B")
		"glasses":                  # round scholar glasses
			head.add_child(n)
			for sx in [-1.0, 1.0]:
				_ring_(n, 0.026, 0.034, Vector3(0.062 * sx, 0.034, -0.1), "20202A", Vector3(PI / 2.0, 0, 0), 0.4, Pattern.mat("dots", "B0702E", "3A200E", 3, 0.4))
				_blk(n, Vector3(0.012, 0.012, 0.09), Vector3(0.108 * sx, 0.04, -0.055), "20202A")
			_blk(n, Vector3(0.03, 0.01, 0.01), Vector3(0, 0.042, -0.108), "20202A")
		"shades":
			head.add_child(n)
			for sx in [-1.0, 1.0]:
				_blk(n, Vector3(0.056, 0.034, 0.014), Vector3(0.062 * sx, 0.036, -0.1), "0A0A10", 0.2)
				_blk(n, Vector3(0.012, 0.012, 0.09), Vector3(0.108 * sx, 0.04, -0.055), "0A0A10", 0.2)
			_blk(n, Vector3(0.03, 0.012, 0.012), Vector3(0, 0.042, -0.108), "0A0A10", 0.2)
		"pipe":
			head.add_child(n)
			_blk(n, Vector3(0.016, 0.016, 0.14), Vector3(0.05, -0.062, -0.14), "5A3A1E")
			_cyl(n, 0.032, 0.026, 0.06, Vector3(0.05, -0.04, -0.215), "3E2412")
			var smoke = CPUParticles3D.new()
			smoke.amount = 10
			smoke.lifetime = 1.8
			smoke.direction = Vector3.UP
			smoke.spread = 18.0
			smoke.initial_velocity_min = 0.12
			smoke.initial_velocity_max = 0.22
			smoke.gravity = Vector3(0, 0.08, 0)
			smoke.local_coords = false
			var sq = QuadMesh.new()
			sq.size = Vector2(0.06, 0.06)
			var sm2 = StandardMaterial3D.new()
			sm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			sm2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			sm2.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			sm2.albedo_color = Color(0.95, 0.95, 1.0, 0.35)
			sm2.albedo_texture = soft_tex()
			sq.material = sm2
			smoke.mesh = sq
			smoke.position = Vector3(0.05, 0.0, -0.215)
			n.add_child(smoke)
		"necklace":                 # a thick gold chain with a red gem
			add_child(n)
			n.position = Vector3(0, -0.015, -0.27)
			_ring_(n, 0.1, 0.12, Vector3.ZERO, "F2B53A", Vector3(PI / 2.0, 0.0, 0.0), 0.25)
			_ball_(n, 0.026, Vector3(0, -0.125, -0.03), "E03A55", Vector3.ONE, 0.2)
		"bowtie":
			head.add_child(n)
			n.position = Vector3(0, -0.075, -0.07)
			for sx in [-1.0, 1.0]:
				var wing = _blk(n, Vector3(0.05, 0.036, 0.012), Vector3(0.034 * sx, 0, 0), "C9202E", 0.95, Pattern.mat("dots", "C9202E", "FFFFFF", 2, 0.7))
				wing.rotation = Vector3(0, 0, 0.45 * sx)
			_blk(n, Vector3(0.02, 0.02, 0.016), Vector3.ZERO, "8E1520")
		"scarf":
			add_child(n)
			n.position = Vector3(0, -0.015, -0.25)
			_ring_(n, 0.09, 0.135, Vector3.ZERO, "D9442E", Vector3(PI / 2.0, 0.0, 0.0), 0.95, Pattern.mat("vstripes", "D9442E", "FFF3E0", 7))
			var st = _blk(n, Vector3(0.05, 0.012, 0.26), Vector3(0.06, -0.06, 0.12), "D9442E", 0.95, Pattern.mat("stripes", "D9442E", "FFF3E0", 5))
			st.name = "ScarfTail"
		"hawaii":                   # a loud flower shirt
			add_child(n)
			_ball_(n, 0.212, Vector3(0, -0.005, 0.05), "2BA7A0", Vector3(1.02, 0.9, 1.15), 0.95, Pattern.mat("floral", "2BA7A0", "FF6FA8", 5))
		"stripes":                  # a sailor's striped shirt
			add_child(n)
			_ball_(n, 0.209, Vector3(0, -0.005, 0.05), "F4F4F0", Vector3(1.02, 0.9, 1.15))
			for k in 4:
				var rg = _ring_(n, 0.17, 0.215, Vector3(0, -0.005, -0.04 + k * 0.085), "2D4F8E", Vector3(0, 0, 0), 0.9)
				rg.scale = Vector3(1.0, 0.9, 1.0)
		"coat":                     # a long dark coat with gold buttons and a collar
			add_child(n)
			_ball_(n, 0.215, Vector3(0, -0.01, 0.06), "262B3A", Vector3(1.03, 0.92, 1.25), 0.95, Pattern.mat("plaid", "3A4155", "C9A64A", 4))
			_blk(n, Vector3(0.05, 0.05, 0.02), Vector3(-0.06, 0.12, -0.14), "262B3A")
			_blk(n, Vector3(0.05, 0.05, 0.02), Vector3(0.06, 0.12, -0.14), "262B3A")
			for k in 3:
				_ball_(n, 0.012, Vector3(0, 0.1 - k * 0.04, -0.16 + k * 0.03), "E7C04A", Vector3.ONE, 0.3)
		"balloon":                  # a balloon tied to the gull, bobbing above
			add_child(n)
			_cyl(n, 0.004, 0.004, 0.7, Vector3(0, 0.38, 0.02), "EEEEEE")
			var bl = _ball_(n, 0.17, Vector3(0, 0.82, 0.02), "E85745", Vector3(1, 1.15, 1), 0.3, Pattern.mat("stripes", "E85745", "FFF3E0", 4, 0.3))
			bl.name = "Balloon"
		"socks":                    # a striped sock pulled over the tail feathers
			tail.add_child(n)
			var sm = Pattern.mat("stripes", "E85745", "FFF3E0", 6)
			var tube = _cyl(n, 0.075, 0.062, 0.34, Vector3(0, 0, 0.1), "E85745", 0.95, sm)
			tube.rotation = Vector3(PI / 2.0, 0, 0)
			var cuff = _cyl(n, 0.082, 0.082, 0.05, Vector3(0, 0, -0.06), "F4F1E8")
			cuff.rotation = Vector3(PI / 2.0, 0, 0)
			var toe = _ball_(n, 0.062, Vector3(0, 0, 0.27), "3D8CD9")
			toe.scale = Vector3(1, 0.9, 0.8)
		"cloud":                    # a small cloud following the gull, just above and behind
			add_child(n)
			n.position = Vector3(0, 0.66, 0.1)
			for c in [[0, 0, 0, 0.16], [0.17, -0.02, 0.02, 0.12], [-0.17, -0.03, 0.0, 0.12], [0.07, 0.07, 0, 0.1], [-0.08, 0.06, 0, 0.1]]:
				_ball_(n, c[3], Vector3(c[0], c[1], c[2]), "FFFFFF", Vector3(1.1, 0.8, 1.0), 0.8)
			n.name = "CloudBuddy"
		"sun":                      # a little sun, a glowing coin behind the head
			add_child(n)
			n.position = Vector3(0, 0.14, 0.3)
			_ball_(n, 0.1, Vector3.ZERO, "FFC83A", Vector3.ONE, 0.2)
			for k in 10:
				var a3 = k * TAU / 10.0
				var ry = _blk(n, Vector3(0.025, 0.07, 0.02), Vector3(cos(a3) * 0.17, sin(a3) * 0.17, 0), "FFB02E")
				ry.rotation = Vector3(0, 0, a3 + PI / 2.0)
			var gl = MeshInstance3D.new()
			var gq = QuadMesh.new()
			gq.size = Vector2(0.9, 0.9)
			gl.mesh = gq
			var gm = StandardMaterial3D.new()
			gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			gm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			gm.albedo_texture = soft_tex()
			gm.albedo_color = Color(1.0, 0.8, 0.35, 0.6)
			gl.material_override = gm
			gl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n.add_child(gl)
		_:
			add_child(n)
	return n
