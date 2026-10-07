extends Control
# GULL SIGHT (hold TAB): the world goes dark and slow. A ring on the ground shows how far you can see (40 m at first, then x2, x4, x8 with
# FARSIGHT fries). Everything you could interact with inside that radius is listed, each with the speed it needs ("NEED 72", the same
# number as the speed tach). Only FRIES glow: coloured by colour, ringed by rarity. Props, drinks and fish are small grey marks.
# The plain fry never shines - it is too ordinary to be found this way.
# On the ground (or a roof) Gull Sight is free; in the air it costs stamina unless a FARSIGHT diamond fry makes it free.

var hud
var a = 0.0
var vtex
var glow
var t = 0.0
var items = []          # [{node, kind}] gathered when the view opens

class Glow extends Control:
	var ov
	func _ready():
		var m = CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = m
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
	func _draw():
		ov.draw_glows(self)

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var g = Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.0))
	g.add_point(0.5, Color(0, 0, 0, 0.15))
	g.set_color(2, Color(0.0, 0.02, 0.08, 0.95))
	vtex = GradientTexture2D.new()
	vtex.gradient = g
	vtex.fill = GradientTexture2D.FILL_RADIAL
	vtex.fill_from = Vector2(0.5, 0.5)
	vtex.fill_to = Vector2(1.1, 0.5)
	vtex.width = 256
	vtex.height = 256
	glow = Glow.new()
	glow.ov = self
	add_child(glow)

func _process(delta):
	t += delta
	var real_dt = delta / max(Engine.time_scale, 0.05)
	a = move_toward(a, 1.0 if GS.sense_active else 0.0, 4.5 * real_dt)
	visible = a > 0.005
	if visible:
		queue_redraw()
		glow.queue_redraw()

func _draw():
	if a <= 0.005:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.02, 0.06, 0.62 * a))
	draw_texture_rect(vtex, Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, a))
	var font = ThemeDB.fallback_font
	var p = hud.player
	var tired = GS.vision_tired
	var u = size.y / 720.0
	var title = "GULL SIGHT"
	var col = Color(0.8, 0.92, 1.0, 0.9 * a)
	var sub = "%d m" % int(GS.sight_radius())
	if tired:
		title = "OUT OF BREATH"
		sub = "REST  -  LAND SOMEWHERE"
		col = Color(1.0, 0.6, 0.4, 0.95 * a)
	draw_string(font, Vector2(0, 112 * u), title, HORIZONTAL_ALIGNMENT_CENTER, size.x, int(22 * u), col)
	var cost = GS.vision_cost()
	var free = p.mode != 0 or cost <= 0.0
	var cost_txt = "FREE" if free else "-%.1f STAMINA / SEC" % cost
	draw_string(font, Vector2(0, 132 * u), sub + "    " + cost_txt, HORIZONTAL_ALIGNMENT_CENTER, size.x, int(13 * u), Color(1.0, 0.92, 0.7, 0.6 * a))
	if (GS.hunger_t > 100.0 or GS.fry_total() >= 8) and not GS.ordinary_eaten:
		draw_string(font, Vector2(0, size.y - 60 * u), "nothing ordinary glows.", HORIZONTAL_ALIGNMENT_CENTER, size.x, int(15 * u), Color(1, 1, 1, 0.34 * a))

# everything inside the radius that the gull could snatch, nearest first (fries before props), at most ~16 labels
func _gather():
	var out = []
	var pl = hud.player
	if pl == null:
		return out
	var pp = pl.global_position
	var rad = GS.sight_radius()
	var cands = get_tree().get_nodes_in_group("fries")
	cands.append_array(get_tree().get_nodes_in_group("mischief"))
	for f in cands:
		if not is_instance_valid(f):
			continue
		if f.ftype == "ordinary" or f.consumed or f.carried or not f.revealed or f.vanished:
			continue
		if not f.is_fry_like() and not f.is_snatchable():
			continue
		var wp = f.global_position + Vector3(0, 0.3, 0)
		var d = pp.distance_to(wp)
		if d > rad:
			continue
		out.append({"f": f, "d": d, "pos": wp})
	out.sort_custom(func(x, y):
		var fx = 0 if x["f"].is_fry_like() else 1
		var fy = 0 if y["f"].is_fry_like() else 1
		if fx != fy:
			return fx < fy
		return x["d"] < y["d"])
	return out

func draw_glows(ci):
	if a <= 0.005:
		return
	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return
	var font = ThemeDB.fallback_font
	var u = size.y / 720.0
	var rect = Rect2(Vector2(46, 170 * u), size - Vector2(180, 270 * u))
	var pl = hud.player
	var my_max = GS.boost_speed()
	# the sight radius, drawn on the ground around the gull
	if pl != null:
		var rad = GS.sight_radius()
		var gp = pl.global_position
		var steps = 72
		var prev = Vector2.ZERO
		var have = false
		var pts = PackedVector2Array()
		for k in steps + 1:
			var ang = TAU * k / steps
			var wp = Vector3(gp.x + cos(ang) * rad, gp.y - 1.0, gp.z + sin(ang) * rad)
			if cam.is_position_behind(wp):
				if pts.size() > 1:
					ci.draw_polyline(pts, Color(0.55, 0.8, 1.0, 0.35 * a), 2.0, true)
				pts = PackedVector2Array()
				continue
			pts.append(cam.unproject_position(wp))
		if pts.size() > 1:
			ci.draw_polyline(pts, Color(0.55, 0.8, 1.0, 0.35 * a), 2.0, true)
		_unused(prev, have)
	var items_ = _gather()
	var n_labels = 0
	var seen_labels = {}
	for it in items_:
		var f = it["f"]
		var d = it["d"]
		var wp2 = it["pos"]
		var fry = f.is_fry_like()
		var need = GS.need_speed(f) * GS.SPEED_UNIT
		var reachable = GS.boost_speed() * GS.SPEED_UNIT >= need - 0.5
		var behind = cam.is_position_behind(wp2)
		var sp = cam.unproject_position(wp2)
		var ph = float(hash(f.id) % 13)
		var pulse = 1.0 + 0.08 * sin(t * 4.0 + ph)
		var onscreen = (not behind) and rect.has_point(sp)
		if fry:
			var info = f.vision_info()
			if info == null:
				continue
			var col = info["col"]
			var core = info["core"]
			var tier = info["tier"]
			var label = "%s  %dm" % [GS.RARITY_NAMES[clamp(tier, 0, 4)], int(d)] if tier >= 1 else "%dm" % int(d)
			label += "\nNEED %d" % int(round(need))
			var lc = Color(1, 1, 1, 0.9 * a) if reachable else Color(1.0, 0.55, 0.45, 0.8 * a)
			if onscreen:
				var r = (22.0 + 70.0 / (1.0 + d / 18.0)) * pulse * u
				ci.draw_circle(sp, r * 1.6, Color(col.r, col.g, col.b, 0.10 * a))
				ci.draw_circle(sp, r, Color(col.r, col.g, col.b, 0.24 * a))
				ci.draw_circle(sp, r * 0.46, Color(core.r, core.g, core.b, 0.75 * a))
				ci.draw_circle(sp, r * 0.17, Color(1, 1, 1, 0.9 * a))
				ci.draw_arc(sp, r * 0.92, 0, TAU, 44, Color(col.r, col.g, col.b, 0.95 * a), 2.5, true)
				if tier == 3:
					for k in 10:
						var ang2 = t * 0.9 + TAU * k / 10.0
						ci.draw_line(sp + Vector2(cos(ang2), sin(ang2)) * r * 1.05, sp + Vector2(cos(ang2), sin(ang2)) * r * 1.35, Color(col.r, col.g, col.b, 0.9 * a), 2.5, true)
				elif tier == 2:
					ci.draw_arc(sp, r * 1.12, t, t + TAU * 0.7, 30, Color(col.r, col.g, col.b, 0.7 * a), 2.0, true)
				elif tier >= 4:
					for k in 6:
						var ang3 = t * 1.4 + TAU * k / 6.0
						var rc = Color.from_hsv(fmod(float(k) / 6.0 + t * 0.3, 1.0), 0.55, 1.0, 0.9 * a)
						ci.draw_circle(sp + Vector2(cos(ang3), sin(ang3)) * r * 1.15, 4.0 * u, rc)
				var lines = label.split("\n")
				ci.draw_string(font, sp + Vector2(-80, r * 0.92 + 18 * u), lines[0], HORIZONTAL_ALIGNMENT_CENTER, 160, int(13 * u), Color(1, 1, 1, 0.85 * a))
				ci.draw_string(font, sp + Vector2(-80, r * 0.92 + 33 * u), lines[1], HORIZONTAL_ALIGNMENT_CENTER, 160, int(13 * u), lc)
				n_labels += 1
			else:
				var dir = sp - size * 0.5
				if behind:
					dir = -dir
				if dir.length() < 1.0:
					dir = Vector2(0, 1)
				dir = dir.normalized()
				var half = rect.size * 0.5
				var kx = half.x / max(abs(dir.x), 0.001)
				var ky = half.y / max(abs(dir.y), 0.001)
				var pos = rect.position + half + dir * min(kx, ky)
				var nrm = Vector2(-dir.y, dir.x)
				var sc = (1.0 + 0.1 * sin(t * 5.0 + ph))
				ci.draw_circle(pos, 24.0 * sc * u, Color(col.r, col.g, col.b, 0.2 * a))
				ci.draw_colored_polygon(PackedVector2Array([pos + dir * 17.0 * sc * u, pos - dir * 9.0 * u + nrm * 12.0 * u, pos - dir * 9.0 * u - nrm * 12.0 * u]), Color(col.r, col.g, col.b, 0.95 * a))
				ci.draw_circle(pos - dir * 4.0, 4.0 * u, Color(core.r, core.g, core.b, 0.9 * a))
				var lines2 = label.split("\n")
				ci.draw_string(font, pos - dir * 34.0 * u + Vector2(-60, 0), lines2[0], HORIZONTAL_ALIGNMENT_CENTER, 120, int(12 * u), Color(1, 1, 1, 0.8 * a))
				ci.draw_string(font, pos - dir * 34.0 * u + Vector2(-60, 14 * u), lines2[1], HORIZONTAL_ALIGNMENT_CENTER, 120, int(12 * u), lc)
				n_labels += 1
		else:
			# a thing (a drink, an ice cream, something to wear, a fish, a cloud...): a small picture of what it is, so the gull can decide whether it wants it
			if (onscreen and n_labels < 22 and d < 110.0) or f.ftype == "mischief" and f.kind in ["cloud", "sun"] and onscreen:
				var kind = f.kind if "kind" in f else f.ftype
				var tint = _tint_of(kind)
				var tag = _tag_of(kind)
				var s = (9.0 + 8.0 / (1.0 + d / 30.0)) * u
				if not reachable:
					tint = tint.lerp(Color(0.6, 0.55, 0.55), 0.55)
				ci.draw_circle(sp, s * 1.35, Color(0.02, 0.03, 0.07, 0.55 * a))
				ci.draw_arc(sp, s * 1.35, 0, TAU, 24, Color(tint.r, tint.g, tint.b, 0.85 * a), 1.6, true)
				_icon(ci, kind, sp, s, Color(tint.r, tint.g, tint.b, a))
				ci.draw_string(font, sp + Vector2(-50, s * 1.35 + 13 * u), tag, HORIZONTAL_ALIGNMENT_CENTER, 100, int(11 * u), Color(1, 1, 1, 0.8 * a))
				ci.draw_string(font, sp + Vector2(-50, s * 1.35 + 25 * u), "%d" % int(round(need)), HORIZONTAL_ALIGNMENT_CENTER, 100, int(10 * u), Color(1.0, 0.9, 0.6, 0.75 * a) if reachable else Color(1.0, 0.5, 0.45, 0.8 * a))
				n_labels += 1
	# when no fry is inside the circle of sight, the nearest fry in the whole town is still pointed out: there is always something to fly to
	var have_fry = false
	for it2 in items_:
		if it2["f"].is_fry_like() and it2["f"].vision_info() != null:
			have_fry = true
	if not have_fry and pl != null:
		_nearest_pointer(ci, cam, font, u, rect, pl)
	if items_.is_empty():
		ci.draw_string(font, Vector2(0, size.y * 0.5 + 40 * u), "nothing in range - but there is one out there:", HORIZONTAL_ALIGNMENT_CENTER, size.x, int(14 * u), Color(1, 1, 1, 0.34 * a))
	_unused(seen_labels, my_max)

func _unused(_a, _b):
	pass

# the nearest fry anywhere (not the plain one: it never glows), as an arrow on the edge of the view with its distance
func _nearest_pointer(ci, cam, font, u, rect, pl):
	var best = null
	var bd = 1e9
	for f in get_tree().get_nodes_in_group("fries"):
		if not is_instance_valid(f) or f.ftype == "ordinary":
			continue
		if f.vision_info() == null:
			continue
		var d = pl.global_position.distance_to(f.global_position)
		if d < bd:
			bd = d
			best = f
	if best == null:
		return
	var info = best.vision_info()
	var col = info["col"]
	var wp = info["pos"]
	var behind = cam.is_position_behind(wp)
	var sp = cam.unproject_position(wp)
	var onscreen = (not behind) and rect.has_point(sp)
	var label = "NEAREST FRY   %d m" % int(bd)
	var pulse = 1.0 + 0.12 * sin(t * 5.0)
	if onscreen:
		var r = 30.0 * pulse * u
		ci.draw_arc(sp, r, 0, TAU, 36, Color(col.r, col.g, col.b, 0.95 * a), 3.0, true)
		ci.draw_circle(sp, r * 0.4, Color(info["core"].r, info["core"].g, info["core"].b, 0.85 * a))
		ci.draw_string(font, sp + Vector2(-90, r + 18 * u), label, HORIZONTAL_ALIGNMENT_CENTER, 180, int(13 * u), Color(1, 1, 1, 0.9 * a))
		return
	var dir = sp - size * 0.5
	if behind:
		dir = -dir
	if dir.length() < 1.0:
		dir = Vector2(0, 1)
	dir = dir.normalized()
	var half = rect.size * 0.5
	var kx = half.x / max(abs(dir.x), 0.001)
	var ky = half.y / max(abs(dir.y), 0.001)
	var pos = rect.position + half + dir * min(kx, ky)
	var nrm = Vector2(-dir.y, dir.x)
	ci.draw_circle(pos, 30.0 * pulse * u, Color(col.r, col.g, col.b, 0.22 * a))
	ci.draw_colored_polygon(PackedVector2Array([pos + dir * 22.0 * pulse * u, pos - dir * 11.0 * u + nrm * 15.0 * u, pos - dir * 11.0 * u - nrm * 15.0 * u]), Color(col.r, col.g, col.b, 0.97 * a))
	ci.draw_string(font, pos - dir * 40.0 * u + Vector2(-90, 0), label, HORIZONTAL_ALIGNMENT_CENTER, 180, int(13 * u), Color(1, 1, 1, 0.92 * a))

# ---------------------------------------------------------------- the pictures of the things
const KIND_TAG = {"coffee": "COFFEE", "alcohol": "COCKTAIL", "icecream": "ICE CREAM", "hawaii": "SHIRT", "stripes": "SHIRT", "coat": "COAT", "socks": "SOCK", "hat": "HAT", "sailor": "HAT",
	"topper": "HAT", "beret": "HAT", "glasses": "GLASSES", "shades": "SHADES", "necklace": "CHAIN", "bowtie": "BOW TIE", "scarf": "SCARF", "pipe": "PIPE", "balloon": "BALLOON",
	"ball": "BALL", "fish": "FISH", "cloud": "CLOUD", "sun": "THE SUN"}

func _tag_of(kind):
	return KIND_TAG.get(kind, "THING")

func _tint_of(kind):
	match kind:
		"coffee":
			return Color("D9A066")
		"alcohol":
			return Color("FF9A5A")
		"icecream":
			return Color.from_hsv(fmod(t * 0.4, 1.0), 0.45, 1.0)
		"fish":
			return Color("5FC8F5")
		"cloud":
			return Color("FFFFFF")
		"sun":
			return Color("FFC83A")
	return Color("D8E2EE")

func _icon(ci, kind, c, s, col):
	var lw = max(s * 0.18, 1.5)
	match kind:
		"coffee":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.55, -s * 0.3), Vector2(s * 1.0, s * 0.85)), col)
			ci.draw_arc(c + Vector2(s * 0.5, s * 0.1), s * 0.3, -PI / 2, PI / 2, 8, col, lw, true)
			ci.draw_line(c + Vector2(-s * 0.2, -s * 0.55), c + Vector2(-s * 0.1, -s * 0.85), Color(1, 1, 1, col.a * 0.7), lw)
			ci.draw_line(c + Vector2(s * 0.15, -s * 0.55), c + Vector2(s * 0.25, -s * 0.85), Color(1, 1, 1, col.a * 0.7), lw)
		"alcohol":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.7, -s * 0.7), c + Vector2(s * 0.7, -s * 0.7), c + Vector2(0, s * 0.1)]), col)
			ci.draw_line(c + Vector2(0, s * 0.1), c + Vector2(0, s * 0.75), col, lw)
			ci.draw_line(c + Vector2(-s * 0.4, s * 0.78), c + Vector2(s * 0.4, s * 0.78), col, lw)
		"icecream":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.4, -s * 0.1), c + Vector2(s * 0.4, -s * 0.1), c + Vector2(0, s * 0.9)]), Color(0.85, 0.65, 0.25, col.a))
			ci.draw_circle(c + Vector2(0, -s * 0.3), s * 0.5, col)
			ci.draw_circle(c + Vector2(0, -s * 0.75), s * 0.35, col.lightened(0.3))
		"hawaii", "stripes", "coat":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.4, -s * 0.7), c + Vector2(s * 0.4, -s * 0.7), c + Vector2(s * 0.9, -s * 0.3), c + Vector2(s * 0.6, 0.0),
				c + Vector2(s * 0.4, -s * 0.15), c + Vector2(s * 0.4, s * 0.75), c + Vector2(-s * 0.4, s * 0.75), c + Vector2(-s * 0.4, -s * 0.15), c + Vector2(-s * 0.6, 0.0), c + Vector2(-s * 0.9, -s * 0.3)]), col)
		"socks":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.3, -s * 0.8), c + Vector2(s * 0.3, -s * 0.8), c + Vector2(s * 0.3, s * 0.2), c + Vector2(s * 0.85, s * 0.3), c + Vector2(s * 0.85, s * 0.8), c + Vector2(-s * 0.3, s * 0.8)]), col)
		"hat", "sailor", "topper", "beret":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.45, -s * 0.7), Vector2(s * 0.9, s * 0.8)), col)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.9, s * 0.05), Vector2(s * 1.8, s * 0.3)), col)
		"glasses", "shades":
			ci.draw_arc(c + Vector2(-s * 0.45, 0), s * 0.4, 0, TAU, 14, col, lw, true)
			ci.draw_arc(c + Vector2(s * 0.45, 0), s * 0.4, 0, TAU, 14, col, lw, true)
			ci.draw_line(c + Vector2(-s * 0.05, 0), c + Vector2(s * 0.05, 0), col, lw)
		"necklace":
			ci.draw_arc(c + Vector2(0, -s * 0.4), s * 0.85, deg_to_rad(20), deg_to_rad(160), 12, col, lw, true)
		"bowtie":
			ci.draw_colored_polygon(PackedVector2Array([c, c + Vector2(-s * 0.9, -s * 0.45), c + Vector2(-s * 0.9, s * 0.45)]), col)
			ci.draw_colored_polygon(PackedVector2Array([c, c + Vector2(s * 0.9, -s * 0.45), c + Vector2(s * 0.9, s * 0.45)]), col)
		"scarf":
			ci.draw_arc(c + Vector2(0, -s * 0.2), s * 0.7, deg_to_rad(10), deg_to_rad(170), 10, col, lw * 2.0, true)
			ci.draw_rect(Rect2(c + Vector2(s * 0.2, 0), Vector2(s * 0.3, s * 0.8)), col)
		"pipe":
			ci.draw_line(c + Vector2(-s * 0.8, s * 0.2), c + Vector2(s * 0.2, s * 0.2), col, lw * 1.4)
			ci.draw_rect(Rect2(c + Vector2(s * 0.1, -s * 0.4), Vector2(s * 0.5, s * 0.7)), col)
		"balloon":
			ci.draw_circle(c + Vector2(0, -s * 0.25), s * 0.6, col)
			ci.draw_line(c + Vector2(0, s * 0.35), c + Vector2(s * 0.1, s * 0.9), col, lw * 0.7)
		"ball":
			ci.draw_circle(c, s * 0.7, col)
			ci.draw_line(c + Vector2(-s * 0.7, 0), c + Vector2(s * 0.7, 0), Color(0, 0, 0, col.a * 0.5), lw * 0.7)
		"fish":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.9, 0), c + Vector2(-s * 0.1, -s * 0.5), c + Vector2(s * 0.5, 0), c + Vector2(-s * 0.1, s * 0.5)]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.4, 0), c + Vector2(s * 0.95, -s * 0.45), c + Vector2(s * 0.95, s * 0.45)]), col)
		"cloud":
			ci.draw_circle(c + Vector2(-s * 0.4, s * 0.1), s * 0.45, col)
			ci.draw_circle(c + Vector2(s * 0.1, -s * 0.15), s * 0.55, col)
			ci.draw_circle(c + Vector2(s * 0.5, s * 0.15), s * 0.4, col)
		"sun":
			ci.draw_circle(c, s * 0.5, col)
			for k in 8:
				var a2 = k * TAU / 8.0
				ci.draw_line(c + Vector2(cos(a2), sin(a2)) * s * 0.7, c + Vector2(cos(a2), sin(a2)) * s * 1.05, col, lw)
		_:
			ci.draw_circle(c, s * 0.4, col)
