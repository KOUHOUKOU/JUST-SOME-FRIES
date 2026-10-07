extends RefCounted
# Round 6: the hill town, rebuilt. Three flat shelves (see terrain.gd) carry fewer, bigger and more different buildings:
#   * HOUSES      plain family houses, every one a different size, colour, roof and shutters
#   * VILLAS      big houses with a fenced garden: a BBQ with a cook, kids and a dog at play... or a swimming pool with sun loungers
#   * BLOCKS      flat-roofed houses with a roof terrace: somebody reading up there, somebody hanging washing, a lounger, plants
# Every kind of person up here is a real fry-world citizen: the BBQ cook and the poolside have gold fries over them (anchors villa_bbq, villa_pool).

const Terrain = preload("res://scripts/world/terrain.gd")

const CHALK = "E8E2D2"
const CORAL = "D96D5F"
const FADED_BLUE = "7396A8"
const WOOD = "8B6A4D"
const DARKWOOD = "6F5238"
const TERRA = "B96F50"
const SLATE = "586169"
const OCHRE = "D9B25F"
const CREAM = "EFE3C6"
const WHITE = "F4F1E8"
const SAGE = "879B82"

var w
var B
var life = []               # people and animals of the yards and the roofs, spawned after the encounters exist
var roof_terraces = []      # flat roofs with a terrace (the laundry roofs use hill_flat instead)

# the three shelves: height, south edge (z of the front), north edge (z of the back)
const SHELF = [{"y": 5.5, "zs": -31.0, "zn": -47.0}, {"y": 11.0, "zs": -52.0, "zn": -68.0}, {"y": 16.5, "zs": -73.0, "zn": -84.5}]

func setup(p_w):
	w = p_w
	B = w.B

# [kind, x_from, x_to] per row and side (x_to - x_from = the lot width)
const LOTS = [
	[["house", -65.0, -55.5], ["villa_pool", -53.0, -33.0], ["house", -31.0, -21.5], ["block", -19.0, -8.0],
		["block", 8.5, 19.5], ["villa_bbq", 22.0, 42.0], ["house", 44.0, 50.0]],
	[["house", -65.0, -55.5], ["block", -52.5, -43.0], ["house", -41.0, -33.0], ["house", -14.0, -6.5],
		["block", 8.0, 17.5], ["villa_pool", 20.0, 39.5], ["house", 42.0, 50.0]],
	[["house", -66.0, -57.0], ["house", -54.5, -45.5], ["block", -43.0, -34.5], ["house", -31.0, -27.5],
		["block", 28.5, 37.5], ["house", 40.0, 49.5]],
]

func _pick(a):
	return w._pick(a)

func build_hill():
	var rng = w.rng
	var wall_cols = ["E8E2D2", "7396A8", "D96D5F", "879B82", "D9B25F", "EFE3C6", "C9A68A", "A9BCC4", "F0D9A0", "B9D0B4"]
	var roof_cols = ["B96F50", "586169", "A25A44", "6F7C84", "8B4A3A", "9C5A3C"]
	var block_n = 0
	for r in LOTS.size():
		var sh = SHELF[r]
		for lot in LOTS[r]:
			var kind = lot[0]
			var x0 = lot[1]
			var x1 = lot[2]
			var cx = (x0 + x1) * 0.5
			var wallc = _pick(wall_cols)
			var roofc = _pick(roof_cols)
			match kind:
				"house":
					var hw = x1 - x0 - rng.randf_range(0.5, 1.5)
					var hd = rng.randf_range(6.4, 8.0)
					var hh = rng.randf_range(4.2, 8.2)
					var cz = sh["zn"] + 1.4 + hd * 0.5
					var flat = rng.randf() < 0.18
					var top = w.house(cx, cz, hw, hd, hh, wallc, roofc, "flat" if flat else "pitched")
					_register(cx, cz, hw + 1.0, hd + 1.0)
					var door = Vector3(cx - hw * 0.25, w.gh(cx, cz + hd * 0.5 + 0.9), cz + hd * 0.5 + 0.9)
					B.box(door + Vector3(0, -0.12, 0), Vector3(1.8, 0.3, 1.5), "CFC6B0", true)
					w.hill_doors.append(door)
					_garden(cx, cz + hd * 0.5 + 1.6, x0, x1, sh["zs"], hw)
					if r == 1 and cx > 5 and not w.anchors.has("chimney"):
						w.anchors["chimney"] = Vector3(cx + hw * 0.3, top + 3.2, cz + hd * 0.5 + 1.0)
				"block":
					var bw = x1 - x0 - 0.8
					var bd = 8.0
					var bh = rng.randf_range(6.2, 8.6)
					var cz2 = sh["zn"] + 1.4 + bd * 0.5
					var top2 = w.house(cx, cz2, bw, bd, bh, wallc, "7F8A92", "flat", {"chimney": false})
					_register(cx, cz2, bw + 1.0, bd + 1.0)
					var door2 = Vector3(cx - bw * 0.25, w.gh(cx, cz2 + bd * 0.5 + 0.9), cz2 + bd * 0.5 + 0.9)
					B.box(door2 + Vector3(0, -0.12, 0), Vector3(1.8, 0.3, 1.5), "CFC6B0", true)
					w.hill_doors.append(door2)
					block_n += 1
					if block_n <= 4:
						w.hill_flat.append({"x": cx, "z": cz2, "top": top2, "w": bw, "d": bd})
					else:
						_roof_terrace(cx, cz2, top2, bw, bd, r)
					_garden(cx, cz2 + bd * 0.5 + 1.6, x0, x1, sh["zs"], bw)
				"villa_pool", "villa_bbq":
					_villa(kind, x0, x1, sh, wallc, roofc, r)
	_stairs()
	# the little tower of the old hill: a water tower on the first shelf, between the houses
	var wx = 38.0
	var wz = -40.0
	var wy = w.gh(wx, wz)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			B.box(Vector3(wx + sx * 1.6, wy + 5.0, wz + sz * 1.6), Vector3(0.3, 10.0, 0.3), SLATE, true)
	B.cyl(Vector3(wx, wy + 11.5, wz), 2.6, 3.2, "B8BEC4", true)
	B.cone(Vector3(wx, wy + 14.0, wz), 2.8, 1.6, CORAL, true)
	B.perch_pad(Vector3(wx, wy + 14.8, wz), 0.5)
	_register(wx, wz, 7.0, 7.0)

# remember where buildings and yards are, so trees, flowers and people stay out of them
func _register(x, z, ww, dd):
	w.add_foot(x, z, ww * 0.5, dd * 0.5)

# a tidy front garden: a low hedge or fence on the street side, flower beds, a mailbox, a small tree now and then
func _garden(cx, fz, x0, x1, zs, hw):
	var rng = w.rng
	var y = w.gh(cx, fz)
	var gz = zs - 0.9                        # the street edge of the shelf
	var kind = rng.randi() % 3
	var gx0 = x0 + 0.3
	var gx1 = x1 - 0.3
	if kind == 0:
		_hedge(gx0, gx1, gz, y)
	elif kind == 1:
		_fence(gx0, gx1, gz, y, _pick(["F4F1E8", "D9C9A0", "A9BCC4"]))
	else:
		for k in int((gx1 - gx0) / 1.5):
			w.planter(gx0 + 0.9 + k * 1.5, gz, y)
	for k in 5:
		var fx = cx + rng.randf_range(-hw * 0.5, hw * 0.5)
		B.box(Vector3(fx, y + 0.12, fz + rng.randf_range(-0.2, 0.6)), Vector3(1.0, 0.24, 0.5), "6FA04A", false)
		for q in 4:
			B.ball(Vector3(fx - 0.35 + q * 0.23, y + 0.34, fz + rng.randf_range(-0.2, 0.6)), 0.1, _pick(["E85745", "F1C94B", "F7C7D4", "FFFFFF", "A98FB8", "FF8A3C"]))
	if rng.randf() < 0.5:
		var tx = x0 + 1.4 if rng.randf() < 0.5 else x1 - 1.4
		w.tree(tx, fz + 0.5, 0, rng.randf_range(0.7, 1.0))
	B.box(Vector3(x1 - 0.8, y + 0.55, gz + 0.2), Vector3(0.3, 0.5, 0.2), "C8372D", false)      # the mailbox
	B.box(Vector3(x1 - 0.8, y + 0.25, gz + 0.2), Vector3(0.06, 0.5, 0.06), DARKWOOD, false)

func _hedge(x0, x1, z, y):
	B.box(Vector3((x0 + x1) * 0.5, y + 0.4, z), Vector3(x1 - x0, 0.8, 0.7), "4F8A45", true)
	for k in int((x1 - x0) / 1.3):
		B.ball(Vector3(x0 + 0.6 + k * 1.3, y + 0.85, z), 0.45, "5F9A4F", Vector3(1, 0.7, 0.8))

func _fence(x0, x1, z, y, col, gap = -999.0):
	var n = int((x1 - x0) / 1.1)
	for k in n:
		var fx = x0 + 0.5 + k * (x1 - x0 - 1.0) / max(n - 1, 1)
		if abs(fx - gap) < 1.0:
			continue
		B.box(Vector3(fx, y + 0.5, z), Vector3(0.14, 1.0, 0.1), col, false)
	B.box(Vector3((x0 + x1) * 0.5, y + 0.8, z), Vector3(x1 - x0, 0.07, 0.06), col, false)
	B.box(Vector3((x0 + x1) * 0.5, y + 0.4, z), Vector3(x1 - x0, 0.07, 0.06), col, false)

# ---------------------------------------------------------------- roof terraces (flat roofs with something going on)
func _roof_terrace(cx, cz, top, bw, bd, row):
	var rng = w.rng
	var y = top
	# a table with an umbrella, a couple of pots, a lounger
	w.table(cx - bw * 0.2, cz + 0.8, 0.0, y)
	w.chair(cx - bw * 0.2 - 0.9, cz + 0.8, 90, y)
	w.chair(cx - bw * 0.2 + 0.9, cz + 0.8, 270, y)
	w.patio_umbrella(cx - bw * 0.2, cz + 0.8, _pick([CORAL, FADED_BLUE, OCHRE, SAGE]), y)
	w.planter(cx + bw * 0.38, cz - 2.2, y)
	w.planter(cx - bw * 0.38, cz - 2.2, y)
	var lounger_at = Vector3(cx + bw * 0.2, y, cz - 0.3)
	var hip = w.lounger(lounger_at.x, lounger_at.y, lounger_at.z, 0.0, "FFD27A")
	# who is up there?
	var pick = rng.randi() % 3
	if pick == 0:
		life.append({"mode": "sit", "pos": Vector3(cx - bw * 0.2 - 0.9, y, cz + 0.8), "face": Vector3(1, 0, 0), "style": {"seated": true, "item_r": "paper", "hair_style": "bun"}})
		life.append({"mode": "recline", "pos": hip, "face": Vector3(0, 0, 1), "style": {"hair_style": "short", "shirt": "F277B5", "item_r": "cocktail"}})
	elif pick == 1:
		life.append({"mode": "recline", "pos": hip, "face": Vector3(0, 0, 1), "style": {"hair_style": "long", "shirt": "F1C94B"}})
		life.append({"mode": "stand", "pos": Vector3(cx - bw * 0.1, y, cz - 1.8), "face": Vector3(0, 0, 1), "style": {"item_r": "basket", "hair_style": "cap"}})
	else:
		life.append({"mode": "chat", "pos": Vector3(cx - bw * 0.2 - 0.9, y, cz + 0.8), "face": Vector3(1, 0, 0), "style": {"seated": true, "item_r": "mug", "hair_style": "beanie"}})
		life.append({"mode": "chat", "pos": Vector3(cx - bw * 0.2 + 0.9, y, cz + 0.8), "face": Vector3(-1, 0, 0), "style": {"seated": true, "item_r": "cup", "hair_style": "long"}})
	roof_terraces.append({"x": cx, "z": cz, "top": top})

# ---------------------------------------------------------------- the villas
func _villa(kind, x0, x1, sh, wallc, roofc, row):
	var rng = w.rng
	var cx = (x0 + x1) * 0.5
	var zs = sh["zs"]
	var zn = sh["zn"]
	var y = sh["y"]
	var hw = 10.0
	var hd = 6.8
	var hh = rng.randf_range(4.6, 5.4)
	var hx = x0 + hw * 0.5 + 0.8                # the house sits at the left, the garden takes the right and the front
	var hz = zn + 1.4 + hd * 0.5
	w.house(hx, hz, hw, hd, hh, wallc, roofc, "pitched", {"chimney": true})
	_register(hx, hz, hw + 1.0, hd + 1.0)
	var door = Vector3(hx - hw * 0.25, y, hz + hd * 0.5 + 0.9)
	B.box(door + Vector3(0, -0.12, 0), Vector3(1.8, 0.3, 1.5), "CFC6B0", true)
	w.hill_doors.append(door)
	# the garden: a fence all round the front, hedges at the sides, a paved terrace behind the house
	var gx0 = x0 + 0.3
	var gx1 = x1 - 0.3
	var gz = zs - 0.9
	_fence(gx0, gx1, gz, y, "F4F1E8", (gx0 + gx1) * 0.5)
	B.box(Vector3(gx0, y + 0.45, (gz + zn) * 0.5), Vector3(0.6, 0.9, abs(gz - zn)), "4F8A45", true)
	B.box(Vector3(gx1, y + 0.45, (gz + zn) * 0.5), Vector3(0.6, 0.9, abs(gz - zn)), "4F8A45", true)
	B.box(Vector3(cx, y + 0.02, gz + 0.1), Vector3(1.8, 0.04, 1.6), "CFC6B0", false)      # the gate path
	var gy = y
	var area = Rect2(Vector2(hx + hw * 0.5 + 1.0, hz + hd * 0.5 + 0.5), Vector2(x1 - (hx + hw * 0.5 + 1.0) - 0.8, zs - (hz + hd * 0.5 + 0.5) - 1.0))
	_register(area.position.x + area.size.x * 0.5, area.position.y + area.size.y * 0.5, area.size.x + 1.0, area.size.y + 1.0)
	if kind == "villa_pool":
		var px = x1 - 5.2
		var pz = hz + hd * 0.5 + 3.4
		_pool(px, pz, 6.4, 3.4, gy)
		w.anchors["villa_pool"] = Vector3(px, gy + 2.6, pz)
		# two loungers on the deck, one with someone on it, a beach umbrella, a kid and a dog
		var h1 = w.lounger(px - 3.6, gy, pz + 0.2, 0.0, "7ADBE8")
		var h2 = w.lounger(px - 3.6, gy, pz - 1.6 + 3.2, 0.0, "FF8AD8")
		w.patio_umbrella(px - 4.5, pz + 1.0, "7ADBE8", gy)
		life.append({"mode": "recline", "pos": h1, "face": Vector3(0, 0, 1), "style": {"hair_style": "bun", "shirt": "F277B5", "pants": "F277B5", "item_r": "cocktail"}})
		life.append({"mode": "play", "pos": Vector3(px + 0.2, gy, pz + 2.6), "face": Vector3(0, 0, 1), "style": {"scale": 0.7, "hair_style": "cap"}})
		life.append({"dog": Vector3(px + 2.0, gy, pz + 2.8), "yaw": 3.0, "coat": "F1E6D2"})
		_register(h2.x, h2.z, 1.0, 1.0)
	else:
		var gx = x1 - 4.6
		var gzb = hz + hd * 0.5 + 2.6
		_bbq(gx, gzb, gy)
		w.anchors["villa_bbq"] = Vector3(gx, gy + 3.0, gzb)
		w.table(gx - 3.0, gzb + 0.6, 0.3, gy, 1.6, 0.9)
		w.chair(gx - 3.0 - 1.0, gzb + 0.6, 90, gy)
		w.chair(gx - 3.0 + 1.0, gzb + 0.6, 270, gy)
		w.patio_umbrella(gx - 3.0, gzb + 0.6, CORAL, gy)
		# the cook (with an apron and a tray), two people eating at the table, two kids chasing each other, a dog
		life.append({"mode": "stand", "pos": Vector3(gx + 0.1, gy, gzb + 1.1), "face": Vector3(0, 0, -1), "style": {"apron": true, "hair_style": "cap", "hat": "F4F1E8", "item_r": "tray", "fat": 1.2}})
		life.append({"mode": "eat", "pos": Vector3(gx - 4.0, gy, gzb + 0.6), "face": Vector3(1, 0, 0), "style": {"seated": true, "item_r": "fries", "hair_style": "long"}})
		life.append({"mode": "chat", "pos": Vector3(gx - 2.0, gy, gzb + 0.6), "face": Vector3(-1, 0, 0), "style": {"seated": true, "item_r": "cocktail", "hair_style": "short"}})
		life.append({"mode": "play", "pos": Vector3(gx - 1.2, gy, gzb + 3.4), "face": Vector3(0, 0, 1), "style": {"scale": 0.7, "hair_style": "beanie"}})
		life.append({"mode": "play", "pos": Vector3(gx + 1.8, gy, gzb + 3.2), "face": Vector3(-1, 0, 0), "style": {"scale": 0.68, "hair_style": "cap"}})
		life.append({"dog": Vector3(gx + 2.6, gy, gzb + 2.0), "yaw": 2.2, "coat": "B58A4B"})
	# a tree or two in the back corners
	w.tree(x1 - 1.6, zn + 2.0, 0, rng.randf_range(0.8, 1.1))
	if kind == "villa_bbq":
		w.tree(x0 + 1.6, zs - 2.4, 0, 0.8)

func _bbq(x, z, y):
	B.box(Vector3(x, y + 0.5, z), Vector3(1.3, 0.16, 0.8), "30343A", true)
	B.box(Vector3(x, y + 0.72, z), Vector3(1.3, 0.34, 0.8), "3A3F4A", false)
	B.cyl(Vector3(x, y + 0.9, z), 0.46, 0.2, "30343A", false, -1.0, 0.0, Vector3(0, 0, 90))
	for sx in [-0.55, 0.55]:
		for sz in [-0.3, 0.3]:
			B.box(Vector3(x + sx, y + 0.24, z + sz), Vector3(0.06, 0.48, 0.06), "30343A", false)
	B.box(Vector3(x, y + 0.84, z), Vector3(1.1, 0.04, 0.6), "E85745", false, Vector3.ZERO, 1.2)       # the glowing coals
	for k in 5:
		B.box(Vector3(x - 0.4 + k * 0.2, y + 0.92, z), Vector3(0.12, 0.05, 0.3), "7A3A22", false)
	B.box(Vector3(x + 1.0, y + 0.45, z + 0.2), Vector3(0.7, 0.9, 0.5), WOOD, true)        # a side table
	var smoke = CPUParticles3D.new()
	smoke.amount = 14
	smoke.lifetime = 2.6
	smoke.direction = Vector3.UP
	smoke.spread = 14.0
	smoke.initial_velocity_min = 0.5
	smoke.initial_velocity_max = 0.9
	smoke.gravity = Vector3(0.1, 0.25, 0)
	smoke.local_coords = false
	smoke.scale_amount_min = 0.8
	smoke.scale_amount_max = 2.2
	var q = QuadMesh.new()
	q.size = Vector2(0.5, 0.5)
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = preload("res://scripts/player/gull_visual.gd").soft_tex()
	m.albedo_color = Color(0.82, 0.82, 0.86, 0.3)
	q.material = m
	smoke.mesh = q
	smoke.position = Vector3(x, y + 1.0, z)
	w.root.add_child(smoke)

# a raised pool: white coping, blue water, a ladder
func _pool(x, z, pw, pd, y):
	B.box(Vector3(x, y + 0.14, z), Vector3(pw + 0.9, 0.28, pd + 0.9), "F4F1E8", true)
	B.box(Vector3(x, y + 0.32, z), Vector3(pw, 0.12, pd), "3FB8E0", false, Vector3.ZERO, 0.35)
	B.box(Vector3(x, y + 0.02, z), Vector3(pw + 3.2, 0.04, pd + 3.0), "E8E2D2", false)       # the deck
	for sz in [-0.3, 0.3]:
		B.cyl(Vector3(x + pw * 0.5 - 0.1, y + 0.7, z + sz), 0.03, 0.8, "B8BEC4", false)
	B.ball(Vector3(x - 1.0, y + 0.42, z + 0.4), 0.3, "E85745", Vector3(1, 0.6, 1), 0.0)      # a floating ring

# ---------------------------------------------------------------- the stairs up the middle: real steps on the banks, paving on the shelves
func _stairs():
	var banks = Terrain.BANKS
	var prev_h = 0.0
	for b in banks:
		var zb0 = b[0]
		var zb1 = b[1]
		var rise = b[2] - prev_h
		var n = int(ceil(rise / 0.42))
		var dz = abs(zb1 - zb0) / n
		for i in n:
			var zn = zb0 - (i + 1) * dz
			var top = Terrain.H(0.0, zn) + 0.04
			B.box(Vector3(0, top - 0.9, zb0 - (i + 0.5) * dz), Vector3(4.0, 1.8, dz + 0.02), "CFC6B0", true)
		for sx in [-2.15, 2.15]:
			var a = Vector3(sx, prev_h + 0.9, zb0)
			var c = Vector3(sx, b[2] + 0.9, zb1)
			w.line(a, c, "E8E2D2", false)
			B.box(Vector3(sx, prev_h + 0.45, zb0 + 0.1), Vector3(0.08, 0.9, 0.08), CHALK, false)
			B.box(Vector3(sx, b[2] + 0.45, zb1 - 0.1), Vector3(0.08, 0.9, 0.08), CHALK, false)
		prev_h = b[2]
	# the paved strip over each shelf
	var ends = [[-26.0, -26.0]]
	var z_prev = -26.0
	for i in banks.size():
		var b2 = banks[i]
		if i > 0:
			B.box(Vector3(0, banks[i - 1][2] + 0.04, (banks[i - 1][1] + b2[0]) * 0.5), Vector3(4.0, 0.12, abs(banks[i - 1][1] - b2[0])), "CFC6B0", true)
	B.box(Vector3(0, banks[banks.size() - 1][2] + 0.04, (banks[banks.size() - 1][1] - 5.5)), Vector3(4.0, 0.12, 9.0), "CFC6B0", true)
	for i in 3:
		w.lamp(-2.9, -34.0 - i * 16.0, Terrain.H(0, -34.0 - i * 16.0))
		w.lamp(2.9, -34.0 - i * 16.0, Terrain.H(0, -34.0 - i * 16.0))
	_unused(ends, z_prev)

func _unused(_a, _b):
	pass

# ---------------------------------------------------------------- the people of the yards and roofs (spawned once the world exists)
func build_life():
	for e in life:
		if e.has("dog"):
			var d = Node3D.new()
			d.set_script(w.DOG_SCRIPT)
			w.root.add_child(d)
			d.setup(w.player, e["dog"], e["yaw"], e["coat"], null)
			continue
		w._amb(e["mode"], e["pos"], e["face"], e["style"])
