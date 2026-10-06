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
			# a prop / drink / fish: a small grey mark with its number, only when it is on screen and there is room
			if onscreen and n_labels < 18 and d < 90.0:
				var gc = Color(0.75, 0.8, 0.88, 0.7 * a) if reachable else Color(0.6, 0.55, 0.55, 0.55 * a)
				if f.ftype == "fish":
					gc = Color(0.4, 0.8, 1.0, 0.8 * a)
				ci.draw_circle(sp, 5.0 * u, gc)
				ci.draw_arc(sp, 9.0 * u, 0, TAU, 20, Color(gc.r, gc.g, gc.b, gc.a * 0.7), 1.5, true)
				ci.draw_string(font, sp + Vector2(-30, 24 * u), "%d" % int(round(need)), HORIZONTAL_ALIGNMENT_CENTER, 60, int(11 * u), Color(gc.r, gc.g, gc.b, gc.a + 0.1))
				n_labels += 1
	if items_.is_empty():
		ci.draw_string(font, Vector2(0, size.y * 0.5), "nothing to snatch in range", HORIZONTAL_ALIGNMENT_CENTER, size.x, int(16 * u), Color(1, 1, 1, 0.3 * a))
	_unused(seen_labels, my_max)

func _unused(_a, _b):
	pass
