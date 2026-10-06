extends RefCounted
# Round 5: a livelier, more varied town. Open-air terraces (no closed interiors):
#   * FRESH MART      a supermarket with an open front: a fry shelf, a cashier and, outside, people smoking pipes, eating fries while they talk, drinking
#   * ESPRESSO CORNER a coffee terrace on the boardwalk (coffee on the tables)
#   * SUNSET TIKI BAR a beach bar (cocktails on the counter, a bottle shelf with a gold fry in front of it)
#   * THE "GULL'S LUCK" a fishing boat in the harbour with a deck, a clothesline and two fishermen
#   * LAUNDRY ROOFS  flat roofs on the hill with clotheslines and people hanging washing (shirts and a coat can be borrowed)
#   * BEACH CLOTHES  loungers and umbrellas with shirts and a coat left on them
# Placement helpers come from the world builder `w` (table, chair, patio_umbrella, lamp...).

const MISCHIEF = preload("res://scripts/fries/mischief.gd")

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

func setup(p_w):
	w = p_w
	B = w.B

func _mis(kind, pos, parent = null):
	var m = Node3D.new()
	m.set_script(MISCHIEF)
	m.setup(kind, parent if parent != null else w.root, pos)
	return m

func _sign(pos, text, col, size = 90, yaw_deg = 0.0):
	var l = Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.012
	l.modulate = Color(col)
	l.outline_size = 14
	l.outline_modulate = Color(0.1, 0.07, 0.05, 0.9)
	l.rotation_degrees = Vector3(0, yaw_deg, 0)
	l.position = pos
	l.shaded = false
	w.root.add_child(l)

# ====================================================================== places
func build_places():
	_supermarket()
	_espresso()
	_tiki_bar()
	_fishing_boat()
	_beach_clothes()
	_laundry_roofs()

# a stripe-awning on a row of boxes (the open-air look)
func _awning(cx, y, z, width, depth, c1, c2, tilt = -12.0):
	var n = int(width / 0.9)
	for k in n:
		B.box(Vector3(cx - width * 0.5 + (k + 0.5) * width / n, y, z), Vector3(width / n, 0.1, depth), c1 if k % 2 == 0 else c2, false, Vector3(tilt, 0, 0))

func _shelf(x, z, width, y0, rows, seed_off):
	B.box(Vector3(x, y0 + rows * 0.45, z), Vector3(width, rows * 0.9, 0.5), "9A8468", true)
	var cols = ["E85745", "F1C94B", "4FB56D", "3D8CD9", "F277B5", "F0883C", "F4F1E8"]
	for r in rows:
		B.box(Vector3(x, y0 + 0.9 * r + 0.06, z + 0.02), Vector3(width, 0.06, 0.56), DARKWOOD, false)
		var n = int(width / 0.55)
		for k in n:
			var c = cols[(k * 3 + r * 5 + seed_off) % cols.size()]
			B.box(Vector3(x - width * 0.5 + 0.3 + k * 0.55, y0 + 0.9 * r + 0.42, z + 0.3), Vector3(0.4, 0.62, 0.16), c, false)

func _supermarket():
	var cx = 28.0
	var cz = -14.0
	# an open-fronted shop: back wall, side walls, roof, a long awning out front
	B.box(Vector3(cx, 2.2, cz - 5.8), Vector3(18.0, 4.4, 0.5), CREAM, true)
	B.box(Vector3(cx - 8.8, 2.2, cz - 2.5), Vector3(0.5, 4.4, 7.0), CREAM, true)
	B.box(Vector3(cx + 8.8, 2.2, cz - 2.5), Vector3(0.5, 4.4, 7.0), CREAM, true)
	B.box(Vector3(cx, 4.55, cz - 2.2), Vector3(18.6, 0.3, 7.4), TERRA, true)
	B.box(Vector3(cx, 0.06, cz - 2.2), Vector3(17.6, 0.1, 7.0), "D8D2C0", false)
	B.box(Vector3(cx, 5.15, cz + 1.4), Vector3(11.0, 1.1, 0.25), CORAL, true)
	_sign(Vector3(cx, 5.18, cz + 1.6), "FRESH MART", "FFF3D6", 120)
	_awning(cx, 4.0, cz + 3.0, 18.0, 3.4, CORAL, WHITE)
	for sx in [-8.4, -3.0, 3.0, 8.4]:
		B.box(Vector3(cx + sx, 1.9, cz + 4.6), Vector3(0.12, 3.8, 0.12), DARKWOOD, false)
	# shelves with colourful boxes, a freezer, the checkout
	_shelf(cx - 5.0, cz - 5.2, 5.2, 0.0, 3, 0)
	_shelf(cx + 5.0, cz - 5.2, 5.2, 0.0, 3, 2)
	B.box(Vector3(cx, 0.55, cz - 5.2), Vector3(3.6, 1.1, 0.9), "DCE6EA", true)       # the freezer
	B.box(Vector3(cx, 1.12, cz - 5.2), Vector3(3.7, 0.08, 1.0), SLATE, false)
	# the FRY SHELF in the middle of the back wall: a little tower of golden cartons (a gold fry can hang over it)
	B.box(Vector3(cx, 1.6, cz - 5.55), Vector3(2.4, 0.1, 0.5), DARKWOOD, false)
	for k in 5:
		B.box(Vector3(cx - 0.9 + k * 0.45, 1.85, cz - 5.55), Vector3(0.34, 0.5, 0.2), "D93A3A", false)
		B.box(Vector3(cx - 0.9 + k * 0.45, 2.2, cz - 5.55), Vector3(0.3, 0.2, 0.06), "F2C14E", false)
	w.anchors["market_stall"] = Vector3(cx, 2.9, cz - 4.6)
	B.box(Vector3(cx - 6.0, 0.55, cz - 1.4), Vector3(3.2, 1.1, 1.0), WOOD, true)       # the checkout
	B.box(Vector3(cx - 6.0, 1.15, cz - 1.4), Vector3(3.3, 0.06, 1.1), DARKWOOD, false)
	B.box(Vector3(cx - 6.2, 1.4, cz - 1.5), Vector3(0.5, 0.4, 0.35), "30343A", false)
	# crates of fruit outside, a little tree, lamps
	for k in 3:
		w.crate(cx - 7.4 + k * 1.2, cz + 2.4, 0.7)
		B.ball(Vector3(cx - 7.4 + k * 1.2, 0.78, cz + 2.4), 0.22, ["E85745", "F1A93A", "7FB04B"][k], Vector3(1, 0.7, 1))
	w.lamp(cx - 9.6, cz + 4.4)
	w.lamp(cx + 9.6, cz + 4.4)
	# outside seating: three tables
	for t in [[cx - 4.0, cz + 7.8], [cx + 1.5, cz + 8.4], [cx + 7.0, cz + 7.6]]:
		w.table(t[0], t[1], 0.0)
		w.chair(t[0] - 0.9, t[1], 90)
		w.chair(t[0] + 0.9, t[1], 270)
		w.chair(t[0], t[1] + 0.9, 180)
	w.patio_umbrella(cx - 4.0, cz + 7.8, WHITE)
	w.patio_umbrella(cx + 7.0, cz + 7.6, FADED_BLUE)
	# a cup of coffee and a cocktail on the tables (they come back after a while)
	_mis("coffee", Vector3(cx + 1.5, 0.84, cz + 8.4))
	_mis("alcohol", Vector3(cx + 7.0, 0.84, cz + 7.6))

func _espresso():
	var cx = 14.0
	var cz = 3.0
	B.box(Vector3(cx, 0.55, cz + 2.4), Vector3(6.4, 1.1, 1.2), WOOD, true)
	B.box(Vector3(cx, 1.12, cz + 2.4), Vector3(6.6, 0.07, 1.3), DARKWOOD, false)
	B.box(Vector3(cx - 1.6, 1.55, cz + 2.7), Vector3(1.0, 0.8, 0.6), "30343A", true)       # the espresso machine
	B.box(Vector3(cx - 1.6, 2.02, cz + 2.7), Vector3(1.1, 0.12, 0.7), "B8BEC4", false)
	for k in 4:
		B.cyl(Vector3(cx + 0.2 + k * 0.45, 1.3, cz + 2.3), 0.09, 0.26, "F4F1E8", false)
	B.box(Vector3(cx, 2.4, cz + 3.1), Vector3(6.8, 2.7, 0.2), CREAM, true)
	B.box(Vector3(cx, 3.95, cz + 0.4), Vector3(7.0, 0.16, 5.8), TERRA, true)
	_awning(cx, 3.6, cz - 0.6, 7.2, 3.6, "2D6F5E", WHITE, 0.0)
	for sx in [-3.3, 3.3]:
		B.box(Vector3(cx + sx, 1.9, cz - 2.4), Vector3(0.12, 3.8, 0.12), DARKWOOD, false)
	_sign(Vector3(cx, 3.2, cz + 3.25), "ESPRESSO", "FFF3D6", 80)
	# tables on the terrace
	for t in [[cx - 3.2, cz - 3.4], [cx, cz - 4.6], [cx + 3.4, cz - 3.4]]:
		w.table(t[0], t[1], 0.0)
		w.chair(t[0] - 0.9, t[1], 90)
		w.chair(t[0] + 0.9, t[1], 270)
	w.patio_umbrella(cx, cz - 4.6, "2D6F5E")
	_mis("coffee", Vector3(cx - 3.2, 0.84, cz - 3.4))
	_mis("coffee", Vector3(cx + 3.4, 0.84, cz - 3.4))
	w.planter(cx - 4.6, cz - 1.0)
	w.planter(cx + 4.8, cz - 1.0)
	# a fourth little table out front, nothing over it: a gold fry hangs above it
	w.table(cx, cz - 8.4, 0.0)
	w.chair(cx - 0.9, cz - 8.4, 90)
	w.chair(cx + 0.9, cz - 8.4, 270)
	w.anchors["cafe_table"] = Vector3(cx, 1.5, cz - 8.4)

func _tiki_bar():
	var cx = 66.0
	var cz = 28.0
	var gy = w.gh(cx, cz)
	# the bar faces the sea (south): the counter, the stools and the guests on the sea side, the bartender and the bottle shelf behind
	B.box(Vector3(cx, gy + 0.55, cz), Vector3(7.0, 1.1, 1.4), WOOD, true)
	B.box(Vector3(cx, gy + 1.12, cz), Vector3(7.2, 0.07, 1.6), DARKWOOD, false)
	B.box(Vector3(cx, gy + 1.7, cz - 2.4), Vector3(7.6, 3.4, 0.3), "7A5A3A", true)
	for r in 3:
		B.box(Vector3(cx, gy + 1.3 + r * 0.75, cz - 2.15), Vector3(7.2, 0.06, 0.4), DARKWOOD, false)
		for k in 13:
			var col = ["3FA7C9", "E8A23A", "7FB04B", "D95D75", "F4F1E8", "9B5DE0"][(k + r) % 6]
			B.cyl(Vector3(cx - 3.3 + k * 0.55, gy + 1.5 + r * 0.75, cz - 2.15), 0.09, 0.4, col, false)
	for sx in [-3.4, 3.4]:
		for sz in [-2.6, 0.9]:
			B.cyl(Vector3(cx + sx, gy + 2.15, cz + sz), 0.12, 4.3, DARKWOOD, true)
	B.cone(Vector3(cx, gy + 5.5, cz - 0.8), 4.4, 2.4, "A8884E", true)
	B.box(Vector3(cx, gy + 4.3, cz - 0.8), Vector3(7.6, 0.14, 4.2), "8A6A3E", false)
	_sign(Vector3(cx, gy + 3.6, cz + 1.05), "SUNSET TIKI", "FFD27A", 100)
	for k in 4:
		B.cyl(Vector3(cx - 2.4 + k * 1.6, gy + 0.27, cz + 1.5), 0.26, 0.54, "C65A3A", true)
	w.line(Vector3(cx - 5.0, gy + 3.2, cz + 2.0), Vector3(cx + 5.0, gy + 3.2, cz + 2.0), "D8D2C0", false, true)
	for x in [-2.4, 0.0, 2.4]:
		_mis("alcohol", Vector3(cx + x, gy + 1.2, cz + 0.1))
	w.anchors["bar_shelf"] = Vector3(cx, gy + 2.5, cz - 1.5)

func _fishing_boat():
	var bx = 101.0
	var bz = 19.5
	var hy = -0.35
	B.box(Vector3(bx, hy, bz), Vector3(11.0, 1.3, 3.8), "2D4F8E", true)
	B.box(Vector3(bx, hy + 0.5, bz), Vector3(11.2, 0.12, 4.0), "F4F4F0", false)       # the deck rim
	B.prism(Vector3(bx + 6.1, hy, bz), Vector3(3.0, 1.3, 3.6), "2D4F8E", true, Vector3(0, 90, 0))
	B.box(Vector3(bx, hy + 0.7, bz), Vector3(10.4, 0.1, 3.4), "B8A07A", false)         # the deck boards
	B.box(Vector3(bx - 3.2, hy + 1.9, bz), Vector3(3.2, 2.3, 2.8), WHITE, true)        # the wheelhouse
	B.box(Vector3(bx - 3.2, hy + 3.1, bz), Vector3(3.6, 0.2, 3.2), CORAL, true)
	B.box(Vector3(bx - 1.55, hy + 2.1, bz), Vector3(0.1, 0.9, 2.0), "", false, Vector3.ZERO, 0.0, "window")
	B.cyl(Vector3(bx + 2.0, hy + 3.2, bz), 0.1, 5.8, "E8E2D2", true)                    # the mast
	B.box(Vector3(bx + 2.0, hy + 5.4, bz), Vector3(0.12, 0.12, 3.2), "E8E2D2", false)
	B.perch_pad(Vector3(bx + 2.0, hy + 6.2, bz), 0.4)
	# a net, barrels, crates, a fish box
	B.box(Vector3(bx + 2.6, hy + 1.3, bz + 1.1), Vector3(1.6, 1.2, 0.1), "6B8F6A", false, Vector3(0, 0, 20))
	B.cyl(Vector3(bx + 4.3, hy + 1.2, bz - 1.0), 0.45, 1.0, "8B6A4D", true)
	B.cyl(Vector3(bx + 4.3, hy + 1.2, bz + 0.2), 0.45, 1.0, "C65A3A", true)
	w.crate(bx + 0.4, bz - 1.2, 0.8, hy + 0.7)
	w.crate(bx + 1.4, bz - 1.1, 0.7, hy + 0.7)
	# a clothesline from the mast to the wheelhouse: a striped shirt dries there
	w.line(Vector3(bx + 2.0, hy + 3.4, bz + 0.6), Vector3(bx - 1.5, hy + 3.2, bz + 0.6), "D8D2C0", false)
	_mis("stripes", Vector3(bx + 0.4, hy + 2.7, bz + 0.6))
	for k in 2:
		B.box(Vector3(bx + 1.4 + k * 0.5, hy + 2.8, bz + 0.6), Vector3(0.35, 0.5, 0.03), ["E85745", "F4F1E8"][k], false)
	# a lantern
	B.ball(Vector3(bx - 1.2, hy + 2.3, bz - 1.5), 0.15, "FFE2A8", Vector3.ONE, 0.6)
	# a ladder up the quay
	B.box(Vector3(bx - 5.8, hy + 1.0, bz - 2.5), Vector3(0.1, 2.0, 0.1), DARKWOOD, false)
	w.anchors["boat_deck"] = Vector3(bx - 0.3, hy + 2.6, bz + 0.4)

func _beach_clothes():
	# loungers with a shirt left on the backrest
	for spec in [[48.0, 31.5, "hawaii", 0.0], [56.0, 35.0, "stripes", 20.0], [30.0, 28.0, "", 340.0]]:
		var x = spec[0]
		var z = spec[1]
		var gy = w.gh(x, z)
		B.box(Vector3(x, gy + 0.22, z), Vector3(0.75, 0.1, 1.5), "F4F1E8", true, Vector3(0, spec[3], 0))
		B.box(Vector3(x, gy + 0.6, z - 0.75), Vector3(0.75, 0.9, 0.1), "F4F1E8", false, Vector3(-30, spec[3], 0))
		B.box(Vector3(x + 0.9, gy + 0.03, z), Vector3(1.0, 0.04, 1.8), ["F277B5", "3D8CD9", "F1C94B"][int(x) % 3], false)       # a towel
		if spec[2] != "":
			_mis(spec[2], Vector3(x, gy + 1.15, z - 0.85))
	# an umbrella with a long coat hung on it
	var ux = 73.0
	var uz = 22.0
	var uy = w.gh(ux, uz)
	B.cyl(Vector3(ux, uy + 1.1, uz), 0.04, 2.2, WHITE, false)
	B.cyl(Vector3(ux, uy + 2.3, uz), 1.5, 0.45, "2D6F5E", true, 0.0)
	_mis("coat", Vector3(ux + 0.5, uy + 1.55, uz + 0.05))
	B.box(Vector3(ux + 1.1, uy + 0.22, uz + 0.4), Vector3(0.7, 0.1, 1.5), "F4F1E8", true)
	# a thermos of coffee on a towel, a cocktail on a little beach table
	var tx = 36.0
	var tz = 24.0
	var ty = w.gh(tx, tz)
	B.box(Vector3(tx, ty + 0.03, tz), Vector3(1.6, 0.04, 1.0), "E85745", false)
	_mis("coffee", Vector3(tx, ty + 0.06, tz))
	var cx = 58.0
	var cz = 31.0
	var cy = w.gh(cx, cz)
	B.cyl(Vector3(cx, cy + 0.3, cz), 0.35, 0.6, WOOD, true)
	_mis("alcohol", Vector3(cx, cy + 0.62, cz))

func _laundry_roofs():
	var used = []
	var made = 0
	var steal_kinds = ["hawaii", "stripes", "coat"]
	for r in w.hill_flat:
		if made >= 8:
			break
		var p = Vector3(r["x"], r["top"] + 0.3, r["z"])
		var too_close = false
		for q in used:
			if Vector2(p.x, p.z).distance_to(Vector2(q.x, q.z)) < 22.0:
				too_close = true
		if too_close:
			continue
		used.append(p)
		var hw = r["w"] * 0.5 - 0.7
		var y = p.y
		# two posts and a line along the front half of the roof
		for sx in [-hw, hw]:
			B.cyl(Vector3(p.x + sx, y + 0.85, p.z + 1.0), 0.05, 1.7, "30343A", false)
		B.box(Vector3(p.x, y + 1.62, p.z + 1.0), Vector3(hw * 2.0, 0.04, 0.04), "D8D2C0", false)
		var n = 5
		for k in n:
			var cxk = p.x - hw + (k + 0.5) * (hw * 2.0) / n
			var col = ["E85745", "F4F1E8", "7396A8", "F1C94B", "F277B5", "879B82"][(k + made) % 6]
			if k == 2 and made < steal_kinds.size() + 1:
				continue          # that peg holds a shirt you can take
			B.box(Vector3(cxk, y + 1.28, p.z + 1.0), Vector3(0.55, 0.6, 0.03), col, false)
		if made < 3:
			_mis(steal_kinds[made], Vector3(p.x, y + 1.15, p.z + 1.0))
		elif made == 3:
			w.anchors["roof_laundry"] = Vector3(p.x, y + 3.2, p.z + 0.4)
		# somebody is hanging the washing
		var ex = {"item_r": "basket", "hair_style": ["bun", "cap", "short", "long"][made % 4], "shirt": ["7A5A8B", "C65A3A", "5E8F6B", "3E6F8E"][made % 4]}
		if made % 3 == 1:
			ex["grumpy"] = true
		w._amb("stand", Vector3(p.x - hw * 0.5, y, p.z + 2.0), Vector3(0, 0, 1), ex)
		made += 1
	w.out["laundry_roofs"] = made
	w.out["laundry_list"] = used

# ====================================================================== people
func build_life():
	var cx = 28.0
	var cz = -14.0
	# --- FRESH MART: a cashier, pipe smokers, fry eaters, drinkers, a gentleman in a top hat
	w._amb("stand", Vector3(cx - 6.0, 0.0, cz - 2.6), Vector3(0, 0, 1), {"apron": true, "shirt": "5E8F6B", "hair_style": "bun"})
	w._amb("chat", Vector3(cx - 4.9, 0.0, cz + 7.8), Vector3(1, 0, 0), {"seated": true, "mischief": "pipe", "hair_style": "bald", "shirt": "6B5A48"})
	w._amb("chat", Vector3(cx - 3.1, 0.0, cz + 7.8), Vector3(-1, 0, 0), {"seated": true, "hair_style": "short", "item_r": "paper"})
	w._amb("chat", Vector3(cx + 0.6, 0.0, cz + 8.4), Vector3(1, 0, 0), {"seated": true, "item_r": "fries", "hair_style": "long"})
	w._amb("chat", Vector3(cx + 2.4, 0.0, cz + 8.4), Vector3(-1, 0, 0), {"seated": true, "item_r": "fries", "hair_style": "cap", "shirt": "3E6F8E"})
	w._amb("chat", Vector3(cx + 6.1, 0.0, cz + 7.6), Vector3(1, 0, 0), {"seated": true, "item_r": "cocktail", "hair_style": "beanie"})
	w._amb("chat", Vector3(cx + 7.9, 0.0, cz + 7.6), Vector3(-1, 0, 0), {"seated": true, "item_r": "cocktail", "hair_style": "short", "shirt": "D96D5F"})
	w._amb("stand", Vector3(cx + 5.0, 0.0, cz + 5.2), Vector3(0, 0, 1), {"mischief": "topper", "shirt": "262B3A", "pants": "262B3A", "hair_style": "bald", "item_r": "paper"})
	w._amb("stand", Vector3(cx - 8.6, 0.0, cz + 4.6), Vector3(0, 0, 1), {"mischief": "pipe", "hair_style": "short", "shirt": "8C8F96"})
	w._amb("stroll", Vector3(cx - 12.0, 0.0, cz + 10.0), Vector3(1, 0, 0), {"item_r": "fries", "hair_style": "cap"}, [Vector3(cx - 12.0, 0.0, cz + 10.0), Vector3(cx + 12.0, 0.0, cz + 11.0)], 0.9)
	# --- ESPRESSO CORNER
	w._amb("stand", Vector3(14.0, 0.0, 6.0), Vector3(0, 0, -1), {"apron": true, "shirt": "2D6F5E", "hair_style": "bun", "item_r": "mug"})
	w._amb("chat", Vector3(9.9, 0.0, -0.4), Vector3(1, 0, 0), {"seated": true, "item_r": "mug", "hair_style": "long"})
	w._amb("chat", Vector3(11.7, 0.0, -0.4), Vector3(-1, 0, 0), {"seated": true, "item_r": "mug", "mischief": "glasses", "hair_style": "short"})
	w._amb("eat", Vector3(16.5, 0.0, -0.4), Vector3(1, 0, 0), {"seated": true, "item_r": "fries", "hair_style": "beanie"})
	# --- TIKI BAR
	var bx = 66.0
	var bz = 28.0
	var by = w.gh(bx, bz)
	w._amb("stand", Vector3(bx, by, bz - 1.4), Vector3(0, 0, 1), {"apron": true, "shirt": "2BA7A0", "hair_style": "cap", "hat": "F1C94B", "item_r": "cocktail"})
	w._amb("chat", Vector3(bx - 0.8, by + 0.0, bz + 1.5), Vector3(0, 0, -1), {"seated": true, "item_r": "cocktail", "hair_style": "bun", "shirt": "F277B5"})
	w._amb("chat", Vector3(bx + 2.4, by + 0.0, bz + 1.5), Vector3(0, 0, -1), {"seated": true, "item_r": "cocktail", "hair_style": "short", "shirt": "E8A23A"})
	w._amb("lie", Vector3(48.0, w.gh(48.0, 31.5) + 0.2, 31.5), Vector3(0, 0, 1), {"hair_style": "short", "mischief": ""})
	w._amb("lie", Vector3(56.0, w.gh(56.0, 35.0) + 0.2, 35.0), Vector3(0, 0, 1), {"hair_style": "long"})
	w._amb("lie", Vector3(30.0, w.gh(30.0, 28.0) + 0.2, 28.0), Vector3(0, 0, 1), {"hair_style": "beanie"})
	# --- the boat: two fishermen
	w._amb("stand", Vector3(99.0, 0.35, 20.1), Vector3(0, 0, 1), {"mischief": "sailor", "shirt": "2D4F8E", "hair_style": "bald", "item_r": "cup"})
	w._amb("fish", Vector3(104.0, 0.35, 20.9), Vector3(0, 0, 1), {"item_r": "rod", "hair_style": "beanie", "mischief": "pipe"})
	# --- the park: a reader on a bench (reading glasses), the plaza painter wears a beret
	w._amb("sit", Vector3(-45.0, w.gh(-45.0, -12.0), -12.0), Vector3(0, 0, 1), {"seated": true, "mischief": "glasses", "hair_style": "bun", "item_r": "paper", "shirt": "7A5A8B"})
