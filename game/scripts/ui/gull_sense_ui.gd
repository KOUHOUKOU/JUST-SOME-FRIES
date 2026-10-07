extends CanvasLayer
# THE CODEX (key C), round 5: pictures, not paragraphs.
#   left   the gull itself (the world camera orbits it), the WARDROBE under it: every hat, pair of glasses and shirt as a little picture,
#          dark until you have taken one; a number says how many you have taken; RIGHT-CLICK a taken one to put it on or take it off
#   right  seven fry rows: the fry, a picture of what it does and its number, three gems (silver / gold / diamond) and a rainbow count;
#          two menu items (coffee, cocktail); a row of stats
#   corner a small map with the fries you have not found yet pulsing
# Mouse: drag with the left button to turn the gull around.

const Terrain = preload("res://scripts/world/terrain.gd")

const SPECIAL_MARKERS = {"red": Vector3(1.5, 0, 70), "blue": Vector3(20, 0, 19), "purple": Vector3(-11, 0, 11.5), "green": Vector3(27, 0, 14.5), "pink": Vector3(-45, 0, -1.5),
	"orange": Vector3(7, 0, -82), "cyan": Vector3(-92, 0, 44)}
const MAP_X0 = -135.0
const MAP_X1 = 125.0
const MAP_Z0 = -95.0
const MAP_Z1 = 130.0
const INK = Color(0.04, 0.05, 0.09)

var player = null
var panel
var map_tex
var seen_t = 0.0

signal wear_toggled(kind)

class Pane extends Control:
	var ui
	var hit = {}            # kind -> Rect2 (the wardrobe tiles, in control coordinates)
	var u = 1.0

	func _gui_input(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			for k in hit:
				if hit[k].has_point(event.position) and GS.worn.has(k):
					ui.wear_toggled.emit(k)
					accept_event()
					return

	# ---------------------------------------------------------------- tiny pictograms (all centred on c, about `s` px across)
	func _gem(c, s, col, lit):
		var a = 1.0 if lit else 0.22
		var pts = PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.8, -s * 0.2), c + Vector2(s * 0.5, s * 0.9), c + Vector2(-s * 0.5, s * 0.9), c + Vector2(-s * 0.8, -s * 0.2)])
		draw_colored_polygon(pts, Color(col.r, col.g, col.b, a))
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[4], pts[0]]), Color(1, 1, 1, 0.8 if lit else 0.25), 1.5, true)
		if lit:
			draw_line(c + Vector2(-s * 0.3, -s * 0.3), c + Vector2(0, s * 0.25), Color(1, 1, 1, 0.7), 1.5)

	func _fry_icon(c, s, col, lit):
		var body = col if lit else Color(0.25, 0.27, 0.32, 0.7)
		var stick = Color("F4C95B") if lit else Color(1, 1, 1, 0.18)
		for k in 5:
			var sx = c.x - s * 0.36 + k * s * 0.18
			var sh = s * (0.5 + 0.1 * float((k * 7) % 4))
			draw_rect(Rect2(Vector2(sx, c.y - s * 0.2 - sh), Vector2(s * 0.14, sh + s * 0.1)), stick)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.45, -s * 0.2), c + Vector2(s * 0.45, -s * 0.2), c + Vector2(s * 0.34, s * 0.55), c + Vector2(-s * 0.34, s * 0.55)]), body)
		draw_polyline(PackedVector2Array([c + Vector2(-s * 0.45, -s * 0.2), c + Vector2(s * 0.45, -s * 0.2), c + Vector2(s * 0.34, s * 0.55), c + Vector2(-s * 0.34, s * 0.55), c + Vector2(-s * 0.45, -s * 0.2)]),
			Color(1, 1, 1, 0.85 if lit else 0.3), 2.0, true)
		if lit:
			draw_rect(Rect2(c + Vector2(-s * 0.2, s * 0.05), Vector2(s * 0.4, s * 0.25)), Color(1, 0.96, 0.84, 0.9))

	# the picture of what a colour does
	func _stat_icon(kind, c, s, col):
		match kind:
			"red":          # a speedometer
				draw_arc(c + Vector2(0, s * 0.3), s * 0.8, PI, TAU, 24, col, 3.0, true)
				draw_line(c + Vector2(0, s * 0.3), c + Vector2(s * 0.5, -s * 0.2), col, 3.0, true)
				draw_circle(c + Vector2(0, s * 0.3), 3.5, col)
			"orange":       # three chevrons
				for k in 3:
					var x = c.x - s * 0.5 + k * s * 0.45
					draw_polyline(PackedVector2Array([Vector2(x, c.y - s * 0.5), Vector2(x + s * 0.4, c.y), Vector2(x, c.y + s * 0.5)]), col, 3.0, true)
			"green":        # a target: thick green ring, thin gold ring
				draw_arc(c, s * 0.75, 0, TAU, 28, col, 5.0, true)
				draw_arc(c, s * 0.42, 0, TAU, 24, Color(1.0, 0.82, 0.25), 2.5, true)
				draw_circle(c, 2.5, Color(1, 1, 1))
			"cyan":         # an eye
				draw_arc(c + Vector2(0, s * 0.5), s * 0.9, deg_to_rad(235), deg_to_rad(305), 12, col, 3.0, true)
				draw_arc(c + Vector2(0, -s * 0.5), s * 0.9, deg_to_rad(55), deg_to_rad(125), 12, col, 3.0, true)
				draw_circle(c, s * 0.25, col)
				draw_circle(c, s * 0.1, INK)
			"blue":         # a battery of breath
				draw_rect(Rect2(c + Vector2(-s * 0.7, -s * 0.35), Vector2(s * 1.4, s * 0.7)), col, false, 3.0)
				draw_rect(Rect2(c + Vector2(s * 0.7, -s * 0.12), Vector2(s * 0.14, s * 0.24)), col)
				draw_rect(Rect2(c + Vector2(-s * 0.58, -s * 0.23), Vector2(s * 0.9, s * 0.46)), col)
			"purple":       # a heart
				draw_circle(c + Vector2(-s * 0.28, -s * 0.15), s * 0.32, col)
				draw_circle(c + Vector2(s * 0.28, -s * 0.15), s * 0.32, col)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.58, -s * 0.02), c + Vector2(s * 0.58, -s * 0.02), c + Vector2(0, s * 0.7)]), col)
			"pink":         # a shield
				draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.55, -s * 0.5), c + Vector2(s * 0.55, -s * 0.5), c + Vector2(s * 0.5, s * 0.15), c + Vector2(0, s * 0.7), c + Vector2(-s * 0.5, s * 0.15)]), col)
				draw_line(c + Vector2(0, -s * 0.4), c + Vector2(0, s * 0.5), Color(1, 1, 1, 0.6), 2.0)

	func _cup(c, s, steam):
		draw_rect(Rect2(c + Vector2(-s * 0.45, -s * 0.2), Vector2(s * 0.9, s * 0.7)), Color(0.96, 0.94, 0.88))
		draw_arc(c + Vector2(s * 0.5, s * 0.1), s * 0.22, -PI / 2, PI / 2, 10, Color(0.96, 0.94, 0.88), 3.0, true)
		draw_rect(Rect2(c + Vector2(-s * 0.4, -s * 0.2), Vector2(s * 0.8, s * 0.12)), Color(0.35, 0.2, 0.1))
		if steam:
			draw_arc(c + Vector2(-s * 0.1, -s * 0.5), s * 0.15, 0, PI, 8, Color(1, 1, 1, 0.7), 2.0, true)
			draw_arc(c + Vector2(s * 0.15, -s * 0.5), s * 0.15, PI, TAU, 8, Color(1, 1, 1, 0.7), 2.0, true)

	func _cone(c, s):
		draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.4, -s * 0.15), c + Vector2(s * 0.4, -s * 0.15), c + Vector2(0, s * 0.85)]), Color(0.86, 0.66, 0.26))
		draw_line(c + Vector2(-s * 0.3, -s * 0.0), c + Vector2(s * 0.1, s * 0.7), Color(0.6, 0.4, 0.12), 1.5)
		draw_circle(c + Vector2(0, -s * 0.35), s * 0.5, Color(0.97, 0.78, 0.84))
		draw_circle(c + Vector2(0, -s * 0.8), s * 0.36, Color(0.75, 0.92, 0.82))
		draw_circle(c + Vector2(s * 0.05, -s * 1.12), s * 0.12, Color(0.88, 0.23, 0.33))

	func _shield(c, s, col):
		draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.5, -s * 0.5), c + Vector2(s * 0.5, -s * 0.5), c + Vector2(s * 0.45, s * 0.15), c + Vector2(0, s * 0.7), c + Vector2(-s * 0.45, s * 0.15)]), col)
		draw_line(c + Vector2(0, -s * 0.35), c + Vector2(0, s * 0.45), Color(1, 1, 1, 0.7), 2.0)

	func _cocktail(c, s):
		draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.55, -s * 0.5), c + Vector2(s * 0.55, -s * 0.5), c + Vector2(0, s * 0.15)]), Color(1.0, 0.48, 0.3))
		draw_line(c + Vector2(0, s * 0.15), c + Vector2(0, s * 0.7), Color(0.86, 0.9, 0.93), 3.0)
		draw_line(c + Vector2(-s * 0.3, s * 0.72), c + Vector2(s * 0.3, s * 0.72), Color(0.86, 0.9, 0.93), 3.0)
		draw_line(c + Vector2(s * 0.15, -s * 0.5), c + Vector2(s * 0.45, -s * 0.9), Color(0.9, 0.2, 0.3), 2.0)
		draw_circle(c + Vector2(-s * 0.35, -s * 0.55), s * 0.12, Color(0.8, 0.1, 0.2))

	# one picture per wearable
	func _wear_icon(kind, c, s, col):
		match kind:
			"hat":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-s, s * 0.25), c + Vector2(s, s * 0.25), c + Vector2(s * 0.5, s * 0.1), c + Vector2(-s * 0.5, s * 0.1)]), col)
				draw_rect(Rect2(c + Vector2(-s * 0.45, -s * 0.5), Vector2(s * 0.9, s * 0.62)), col)
				draw_rect(Rect2(c + Vector2(-s * 0.45, -s * 0.05), Vector2(s * 0.9, s * 0.14)), Color(0.85, 0.35, 0.3, col.a))
				for q in 6:
					draw_rect(Rect2(c + Vector2(-s * 0.45 + q * s * 0.15, -s * 0.05 + (q % 2) * s * 0.07), Vector2(s * 0.075, s * 0.07)), Color(1, 0.95, 0.85, col.a))
			"sailor":
				draw_rect(Rect2(c + Vector2(-s * 0.6, -s * 0.15), Vector2(s * 1.2, s * 0.5)), col)
				draw_rect(Rect2(c + Vector2(-s * 0.7, s * 0.2), Vector2(s * 1.4, s * 0.2)), Color(0.18, 0.31, 0.56, col.a))
				for q in 4:
					draw_rect(Rect2(c + Vector2(-s * 0.7 + q * s * 0.36, s * 0.2), Vector2(s * 0.14, s * 0.2)), Color(1, 1, 1, col.a))
				draw_circle(c + Vector2(0, -s * 0.28), s * 0.12, Color(0.85, 0.2, 0.2, col.a))
			"topper":
				draw_rect(Rect2(c + Vector2(-s * 0.4, -s * 0.8), Vector2(s * 0.8, s * 1.05)), col)
				draw_rect(Rect2(c + Vector2(-s * 0.85, s * 0.2), Vector2(s * 1.7, s * 0.22)), col)
				draw_rect(Rect2(c + Vector2(-s * 0.4, -s * 0.1), Vector2(s * 0.8, s * 0.18)), Color(0.9, 0.75, 0.2, col.a))
				for q in 3:
					draw_line(c + Vector2(-s * 0.2 + q * s * 0.2, -s * 0.7), c + Vector2(-s * 0.2 + q * s * 0.2, -s * 0.15), Color(1, 1, 1, col.a * 0.28), 1.5)
			"beret":
				draw_circle(c, s * 0.8, col)
				draw_line(c + Vector2(0, -s * 0.8), c + Vector2(0, -s * 1.05), col, 3.0)
				for q in 5:
					draw_circle(c + Vector2(cos(q * 1.26) * s * 0.4, sin(q * 1.26) * s * 0.4), s * 0.1, Color(1, 0.9, 0.7, col.a))
			"glasses":
				draw_arc(c + Vector2(-s * 0.5, 0), s * 0.38, 0, TAU, 16, col, 3.0, true)
				draw_arc(c + Vector2(s * 0.5, 0), s * 0.38, 0, TAU, 16, col, 3.0, true)
				draw_line(c + Vector2(-s * 0.12, 0), c + Vector2(s * 0.12, 0), col, 3.0)
			"shades":
				draw_rect(Rect2(c + Vector2(-s * 0.85, -s * 0.3), Vector2(s * 0.75, s * 0.55)), col)
				draw_rect(Rect2(c + Vector2(s * 0.1, -s * 0.3), Vector2(s * 0.75, s * 0.55)), col)
				draw_line(c + Vector2(-s * 0.1, -s * 0.15), c + Vector2(s * 0.1, -s * 0.15), col, 3.0)
			"necklace":
				draw_arc(c + Vector2(0, -s * 0.5), s * 0.85, deg_to_rad(20), deg_to_rad(160), 14, Color(0.95, 0.72, 0.22, col.a), 4.0, true)
				draw_circle(c + Vector2(0, s * 0.42), s * 0.22, Color(0.88, 0.23, 0.33, col.a))
			"bowtie":
				draw_colored_polygon(PackedVector2Array([c, c + Vector2(-s * 0.9, -s * 0.45), c + Vector2(-s * 0.9, s * 0.45)]), col)
				draw_colored_polygon(PackedVector2Array([c, c + Vector2(s * 0.9, -s * 0.45), c + Vector2(s * 0.9, s * 0.45)]), col)
				draw_circle(c, s * 0.2, Color(0.55, 0.08, 0.12, col.a))
				for q in 4:
					draw_circle(c + Vector2((q - 1.5) * s * 0.4, (q % 2) * s * 0.2 - s * 0.1), s * 0.07, Color(1, 1, 1, col.a))
			"scarf":
				draw_arc(c + Vector2(0, -s * 0.2), s * 0.8, deg_to_rad(10), deg_to_rad(170), 14, col, 7.0, true)
				draw_rect(Rect2(c + Vector2(s * 0.3, s * 0.1), Vector2(s * 0.3, s * 0.85)), col)
				for q in 5:
					draw_line(c + Vector2(-s * 0.7 + q * s * 0.32, -s * 0.4), c + Vector2(-s * 0.7 + q * s * 0.32, s * 0.05), Color(1, 0.95, 0.85, col.a * 0.8), 2.0)
			"pipe":
				draw_line(c + Vector2(-s * 0.85, s * 0.2), c + Vector2(s * 0.2, s * 0.2), Color(0.35, 0.22, 0.12, col.a), 5.0)
				draw_rect(Rect2(c + Vector2(s * 0.1, -s * 0.35), Vector2(s * 0.5, s * 0.65)), Color(0.24, 0.14, 0.07, col.a))
				draw_arc(c + Vector2(s * 0.35, -s * 0.6), s * 0.18, PI, TAU, 8, Color(1, 1, 1, 0.55 * col.a), 2.0, true)
			"hawaii", "stripes", "coat":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.45, -s * 0.7), c + Vector2(s * 0.45, -s * 0.7), c + Vector2(s * 0.95, -s * 0.3), c + Vector2(s * 0.7, s * 0.0),
					c + Vector2(s * 0.45, -s * 0.15), c + Vector2(s * 0.45, s * 0.75), c + Vector2(-s * 0.45, s * 0.75), c + Vector2(-s * 0.45, -s * 0.15), c + Vector2(-s * 0.7, s * 0.0), c + Vector2(-s * 0.95, -s * 0.3)]), col)
				if kind == "hawaii":
					for k in 4:
						draw_circle(c + Vector2(-s * 0.2 + (k % 2) * s * 0.4, -s * 0.3 + (k / 2) * s * 0.5), s * 0.09, Color(1, 0.8, 0.3, col.a))
				elif kind == "stripes":
					for k in 3:
						draw_line(c + Vector2(-s * 0.45, -s * 0.35 + k * s * 0.3), c + Vector2(s * 0.45, -s * 0.35 + k * s * 0.3), Color(0.18, 0.31, 0.56, col.a), 4.0)
				else:
					draw_line(c + Vector2(0, -s * 0.6), c + Vector2(0, s * 0.7), Color(0.9, 0.75, 0.3, col.a), 2.0)
			"balloon":
				draw_circle(c + Vector2(0, -s * 0.2), s * 0.6, col)
				draw_line(c + Vector2(0, s * 0.4), c + Vector2(s * 0.1, s * 0.95), Color(1, 1, 1, 0.6 * col.a), 1.5)
				for q in 3:
					draw_arc(c + Vector2(0, -s * 0.2), s * (0.15 + q * 0.2), 0, TAU, 14, Color(1, 1, 1, 0.5 * col.a), 1.5, true)
			"socks":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.35, -s * 0.8), c + Vector2(s * 0.3, -s * 0.8), c + Vector2(s * 0.3, s * 0.15), c + Vector2(s * 0.9, s * 0.25), c + Vector2(s * 0.9, s * 0.8), c + Vector2(-s * 0.35, s * 0.8)]), col)
				for q in 4:
					draw_line(c + Vector2(-s * 0.35, -s * 0.6 + q * s * 0.3), c + Vector2(s * 0.3, -s * 0.6 + q * s * 0.3), Color(1, 0.96, 0.88, col.a), 3.0)
			"cloud":
				draw_circle(c + Vector2(-s * 0.5, s * 0.15), s * 0.5, col)
				draw_circle(c + Vector2(s * 0.1, -s * 0.2), s * 0.65, col)
				draw_circle(c + Vector2(s * 0.65, s * 0.2), s * 0.45, col)
				draw_rect(Rect2(c + Vector2(-s * 0.5, s * 0.15), Vector2(s * 1.15, s * 0.5)), col)
			"sun":
				draw_circle(c, s * 0.5, col)
				for q in 10:
					var a3 = q * TAU / 10.0
					draw_line(c + Vector2(cos(a3), sin(a3)) * s * 0.7, c + Vector2(cos(a3), sin(a3)) * s * 1.05, col, 3.0)

	func _w2m(x, z, r):
		return Vector2(r.position.x + (x - ui.MAP_X0) / (ui.MAP_X1 - ui.MAP_X0) * r.size.x,
			r.position.y + (ui.MAP_Z1 - z) / (ui.MAP_Z1 - ui.MAP_Z0) * r.size.y)

	func _value_text(k, lv):
		match k:
			"red":
				return "%d" % int(round((GS.BOOST_TAB[lv] + 0.15 * GS.rainbow["red"]) * GS.SPEED_UNIT))
			"orange":
				return "x%.1f" % (GS.ACCEL_TAB[lv] + 0.04 * GS.rainbow["orange"])
			"green":
				return "x%.2f" % GS.WINDOW_TAB[lv]
			"cyan":
				return "%d m" % int(GS.SIGHT_R_TAB[lv])
			"blue":
				return "%d" % int(GS.STAM_TAB[lv] + 4.0 * GS.rainbow["blue"])
			"purple":
				return "x%.1f" % GS.REGEN_PERCH_TAB[lv]
			"pink":
				return "-%d%%" % int(round((1.0 - GS.HURT_TAB[lv]) * 100.0))
		return ""

	func _draw():
		if size.y < 100.0:
			return
		u = size.y / 720.0
		var font = ThemeDB.fallback_font
		var t = GS.msec() * 0.001
		hit.clear()
		# soft dark panels (the world stays visible around the gull)
		draw_rect(Rect2(Vector2(size.x * 0.5, 0), Vector2(size.x * 0.5, size.y)), Color(0.02, 0.03, 0.06, 0.66))
		draw_rect(Rect2(Vector2(0, size.y * 0.66), Vector2(size.x * 0.5, size.y * 0.34)), Color(0.02, 0.03, 0.06, 0.5))
		# ---- header: the stat strip (pictures + numbers)
		var x0 = size.x * 0.5 + 24.0 * u
		var stats = [
			["red", "%d" % int(round(GS.boost_speed() * GS.SPEED_UNIT))],
			["orange", "x%.1f" % GS.accel_mult()],
			["blue", "%d" % int(GS.stamina_max())],
			["cyan", "%d m" % int(GS.sight_radius())],
		]
		for i in stats.size():
			var cx = x0 + 34.0 * u + i * 150.0 * u
			var k = stats[i][0]
			_stat_icon(k, Vector2(cx, 40.0 * u), 15.0 * u, GS.TYPE_COLORS[k])
			draw_string(font, Vector2(cx + 28.0 * u, 48.0 * u), stats[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, int(24 * u), Color(1, 0.97, 0.88))
		# ---- the seven fry rows
		var y = 84.0 * u
		var rh = 68.0 * u
		for i in GS.FRY_TYPES.size():
			var k2 = GS.FRY_TYPES[i]
			var col = GS.TYPE_COLORS[k2]
			var lv = GS.lv[k2]
			var have = lv >= 1
			draw_rect(Rect2(Vector2(x0 - 8.0 * u, y), Vector2(size.x * 0.5 - 40.0 * u, rh - 6.0 * u)), Color(col.r, col.g, col.b, 0.2 if have else 0.07))
			draw_rect(Rect2(Vector2(x0 - 8.0 * u, y), Vector2(6.0 * u, rh - 6.0 * u)), Color(col.r, col.g, col.b, 0.95 if have else 0.3))
			_fry_icon(Vector2(x0 + 36.0 * u, y + 32.0 * u), 36.0 * u, col, have)
			if not have:
				draw_string(font, Vector2(x0 + 24.0 * u, y + 42.0 * u), "?", HORIZONTAL_ALIGNMENT_CENTER, 24.0 * u, int(26 * u), Color(1, 1, 1, 0.5))
			# what it does + the number
			if have:
				_stat_icon(k2, Vector2(x0 + 128.0 * u, y + 28.0 * u), 17.0 * u, col.lightened(0.25))
				var val = _value_text(k2, lv)
				draw_string(font, Vector2(x0 + 162.0 * u, y + 38.0 * u), val, HORIZONTAL_ALIGNMENT_LEFT, -1, int(26 * u), Color(1, 0.97, 0.88))
			else:
				_stat_icon(k2, Vector2(x0 + 128.0 * u, y + 28.0 * u), 17.0 * u, Color(1, 1, 1, 0.22))
			# the three gems + the rainbow count
			var gx = x0 + 300.0 * u
			var gcols = [GS.RARITY_COLORS[1], GS.RARITY_COLORS[2], GS.RARITY_COLORS[3]]
			for g in 3:
				_gem(Vector2(gx + g * 46.0 * u, y + 30.0 * u), 14.0 * u, gcols[g], lv >= g + 1)
			var rb = GS.rainbow[k2]
			var rx = gx + 3.0 * 46.0 * u + 14.0 * u
			for q in 5:
				var rc = Color.from_hsv(float(q) / 5.0, 0.55, 1.0, 1.0 if rb > 0 else 0.2)
				draw_arc(Vector2(rx, y + 40.0 * u), (16.0 - q * 2.2) * u, PI, TAU, 14, rc, 2.5, true)
			draw_string(font, Vector2(rx + 22.0 * u, y + 42.0 * u), "x%d" % rb, HORIZONTAL_ALIGNMENT_LEFT, -1, int(20 * u), Color(1, 0.8, 0.95, 1.0 if rb > 0 else 0.3))
			y += rh
		# ---- the menu: coffee, the cocktail and ice cream, with the number you have had
		var my = y + 8.0 * u
		for i in 3:
			var key = ["coffee", "alcohol", "icecream"][i]
			var n = GS.mischief_counts.get(key, 0)
			var cx2 = x0 + 52.0 * u + i * 168.0 * u
			draw_rect(Rect2(Vector2(cx2 - 46.0 * u, my), Vector2(158.0 * u, 62.0 * u)), Color(1, 1, 1, 0.07 if n == 0 else 0.15))
			if i == 0:
				_cup(Vector2(cx2, my + 34.0 * u), 22.0 * u, n > 0)
			elif i == 1:
				_cocktail(Vector2(cx2, my + 34.0 * u), 20.0 * u)
			else:
				_cone(Vector2(cx2, my + 32.0 * u), 21.0 * u)
			if n == 0:
				draw_rect(Rect2(Vector2(cx2 - 30.0 * u, my + 4.0 * u), Vector2(60.0 * u, 54.0 * u)), Color(0.02, 0.03, 0.06, 0.62))
			# what it does: coffee = faster (arrows up), cocktail = free flight (a battery), ice cream = a shield
			var ac = [Color(1.0, 0.6, 0.25), Color(1.0, 0.85, 0.2), Color(1.0, 0.55, 0.85)][i]
			var ax = cx2 + 46.0 * u
			if i == 0:
				draw_polyline(PackedVector2Array([Vector2(ax - 8, my + 40.0 * u), Vector2(ax, my + 28.0 * u), Vector2(ax + 8, my + 40.0 * u)]), ac, 3.0, true)
				draw_polyline(PackedVector2Array([Vector2(ax - 8, my + 52.0 * u), Vector2(ax, my + 40.0 * u), Vector2(ax + 8, my + 52.0 * u)]), ac, 3.0, true)
			elif i == 1:
				draw_rect(Rect2(Vector2(ax - 11.0 * u, my + 30.0 * u), Vector2(22.0 * u, 14.0 * u)), ac, false, 2.5)
				draw_rect(Rect2(Vector2(ax - 8.0 * u, my + 33.0 * u), Vector2(16.0 * u, 8.0 * u)), ac)
				draw_polyline(PackedVector2Array([Vector2(ax - 8, my + 50.0 * u), Vector2(ax, my + 46.0 * u), Vector2(ax + 8, my + 50.0 * u)]), ac, 2.5, true)
			else:
				_shield(Vector2(ax, my + 38.0 * u), 15.0 * u, ac)
			draw_string(font, Vector2(cx2 + 62.0 * u, my + 42.0 * u), "x%d" % n, HORIZONTAL_ALIGNMENT_LEFT, -1, int(20 * u), Color(1, 0.97, 0.88, 1.0 if n > 0 else 0.35))
		# ---- the wardrobe (under the gull)
		var wx = 22.0 * u
		var wy = size.y * 0.695
		var tw = 62.0 * u
		var kinds = GS.WEARABLES
		for i in kinds.size():
			var k3 = kinds[i]
			var col2 = i % 6
			var row = i / 6
			var r = Rect2(Vector2(wx + col2 * (tw + 6.0 * u), wy + row * (tw * 0.9 + 6.0 * u)), Vector2(tw, tw * 0.9))
			hit[k3] = r
			var owned = GS.worn.has(k3)
			var on = GS.equipped.has(k3)
			draw_rect(r, Color(1, 1, 1, 0.14 if owned else 0.05))
			if on:
				draw_rect(r, Color(1.0, 0.85, 0.35, 0.95), false, 3.0)
			var base = {"hat": Color("F0D9A0"), "sailor": Color("F4F4F0"), "topper": Color("2A2D36"), "beret": Color("C23B3B"), "glasses": Color("DDE3EA"), "shades": Color("15151A"),
				"necklace": Color("F2B53A"), "bowtie": Color("C9202E"), "scarf": Color("D9442E"), "pipe": Color("5A3A1E"), "hawaii": Color("2BA7A0"), "stripes": Color("F4F4F0"),
				"coat": Color("3A4155"), "balloon": Color("E85745"), "socks": Color("E85745"), "cloud": Color("FFFFFF"), "sun": Color("FFC83A")}[k3]
			var pc = base if owned else Color(0.4, 0.42, 0.5, 0.35)
			if owned and k3 in ["topper", "shades", "pipe", "coat"]:
				draw_rect(Rect2(r.position + Vector2(5, 5), r.size - Vector2(10, 10)), Color(0.8, 0.82, 0.9, 0.22))
			_wear_icon(k3, r.position + r.size * 0.5 + Vector2(0, -2.0 * u), tw * 0.26, pc)
			if not owned:
				draw_string(font, r.position + Vector2(0, r.size.y * 0.72), "?", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, int(18 * u), Color(1, 1, 1, 0.22))
			var cnt = GS.mischief_counts.get(k3, 0)
			if owned:
				draw_string(font, r.position + Vector2(r.size.x - 30.0 * u, r.size.y - 5.0 * u), "x%d" % max(cnt, 1), HORIZONTAL_ALIGNMENT_RIGHT, 26.0 * u, int(12 * u), Color(1, 0.95, 0.8))
				if not GS.menu_seen.has("w_" + k3):
					draw_circle(r.position + Vector2(r.size.x - 8.0 * u, 9.0 * u), 5.0 * u, Color(1.0, 0.3, 0.3))
		# the mouse hint: a little mouse with the right button lit
		var mx = wx + 6.0 * (tw + 6.0 * u) + 8.0 * u
		var my2 = wy + 4.0 * u
		draw_rect(Rect2(Vector2(mx, my2), Vector2(26.0 * u, 38.0 * u)), Color(1, 1, 1, 0.5), false, 2.0)
		draw_rect(Rect2(Vector2(mx + 13.0 * u, my2), Vector2(13.0 * u, 16.0 * u)), Color(1.0, 0.85, 0.35, 0.9))
		# ---- the map (top-left)
		var mw = 210.0 * u
		var mh = mw * (ui.MAP_Z1 - ui.MAP_Z0) / (ui.MAP_X1 - ui.MAP_X0)
		var mr = Rect2(Vector2(22.0 * u, 22.0 * u), Vector2(mw, mh))
		draw_texture_rect(ui.map_tex, mr, false)
		draw_rect(mr, Color(1, 1, 1, 0.3), false, 2.0)
		if GS.gull_sense_count >= 3:
			for key in ui.SPECIAL_MARKERS:
				if GS.lv[key] < 1:
					var m = ui.SPECIAL_MARKERS[key]
					var p2 = _w2m(m.x, m.z, mr)
					var cc = GS.TYPE_COLORS[key]
					draw_circle(p2, 3.0 + 1.6 * sin(t * 5.0), Color(cc.r, cc.g, cc.b, 0.95))
					draw_arc(p2, 6.0 + 4.0 * fmod(t * 1.3, 1.0), 0, TAU, 20, Color(cc.r, cc.g, cc.b, 0.6), 1.5)
		var pl = ui.player
		if pl != null:
			var pp = _w2m(pl.global_position.x, pl.global_position.z, mr)
			var f = -pl.global_transform.basis.z
			var d = Vector2(f.x, -f.z).normalized()
			var n2 = Vector2(-d.y, d.x)
			draw_colored_polygon(PackedVector2Array([pp + d * 7, pp - d * 4 + n2 * 4, pp - d * 4 - n2 * 4]), Color(1, 1, 1))
		if GS.ordinary_eaten:
			draw_string(font, Vector2(size.x * 0.5 + 24.0 * u, size.y - 20.0 * u), "FRY   -   no effect.   tastes good.", HORIZONTAL_ALIGNMENT_LEFT, -1, int(18 * u), Color(1, 0.95, 0.8, 0.8))

func _ready():
	layer = 12
	var img = Image.create(130, 113, false, Image.FORMAT_RGBA8)
	for iy in 113:
		for ix in 130:
			var x = MAP_X0 + (ix + 0.5) / 130.0 * (MAP_X1 - MAP_X0)
			var z = MAP_Z1 - (iy + 0.5) / 113.0 * (MAP_Z1 - MAP_Z0)
			var h = Terrain.H(x, z)
			var c = Color("2C5560")
			if h > -0.7:
				var core = x > -72 and x < 50 and z > -26 and z < 27
				c = Color("8E8672") if core else Color("5E7F55")
				if x > 8 and z > 4 and z < 52 and x < 90:
					c = Color("B9A77F")
				if h > 8.0:
					c = Color("6E7F5A").lerp(Color("A3AE92"), clamp((h - 8.0) / 20.0, 0.0, 1.0))
				if x > 50 and z < 14 and z > -50 and h < 1.0:
					c = Color("8A8E8A")
			if x > -3.0 and x < 5.0 and z > 24.0 and z < 76.0:
				c = Color("7A6248")
			if x > -10.0 and x < 14.0 and z > 48.0 and z < 62.0:
				c = Color("7A6248")
			for fx in [-12.0, -20.0, -28.0]:
				if abs(x - fx) < 1.0 and z > 27.0 and z < 44.0:
					c = Color("7A6248")
			img.set_pixel(ix, iy, c)
	map_tex = ImageTexture.create_from_image(img)
	panel = Pane.new()
	panel.ui = self
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	visible = false
	wear_toggled.connect(_on_wear_toggled)

func _on_wear_toggled(kind):
	if player == null:
		return
	if GS.equipped.has(kind):
		player.gull.unwear(kind)
		Sfx.play("equip", -10.0, 0.7)
	else:
		player.gull.wear(kind)
		Sfx.play("equip", -8.0, 1.1)

func _process(delta):
	if visible:
		panel.queue_redraw()
		seen_t += delta / max(Engine.time_scale, 0.1)
		if seen_t > 1.6:
			for k in GS.worn:
				GS.menu_seen["w_" + k] = true
	else:
		seen_t = 0.0
