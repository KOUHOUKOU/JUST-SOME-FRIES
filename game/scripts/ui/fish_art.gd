extends RefCounted
# Little drawn fish for the HUD (catch card) and the Codex (fish book). `ci` is any CanvasItem inside its _draw().

static func ell(c, rx, ry, n = 28):
	var pts = PackedVector2Array()
	for i in n:
		var a = TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts

# s = half the body length in pixels. The fish swims to the left (head at the left).
static func draw(ci, c, s, sp, alpha = 1.0, lit = true):
	var d = GS.FISH_SPECIES[sp]
	var body = Color(d[6])
	var belly = Color(d[7])
	if not lit:
		body = Color(0.22, 0.25, 0.32)
		belly = Color(0.3, 0.33, 0.4)
	body.a = alpha
	belly.a = alpha
	var hy = {"sardine": 0.36, "mackerel": 0.38, "herring": 0.44, "mullet": 0.46, "flyer": 0.36, "bass": 0.52, "tuna": 0.56, "opah": 0.92, "marlin": 0.4}[sp]
	var fin = body.lerp(Color("E88A4C"), 0.5 if lit else 0.0)
	# tail
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.8, 0), c + Vector2(s * 1.5, -s * hy * 1.0), c + Vector2(s * 1.38, 0), c + Vector2(s * 1.5, s * hy * 1.0)]), fin)
	# dorsal fin
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.2, -s * hy * 0.9), c + Vector2(s * 0.3, -s * hy * 1.45), c + Vector2(s * 0.5, -s * hy * 0.8)]), fin)
	if sp == "marlin":
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.1, -s * hy * 0.8), c + Vector2(s * 0.45, -s * hy * 2.2), c + Vector2(s * 0.6, -s * hy * 0.7)]), body.lerp(Color("2F6FD0"), 0.6))
		ci.draw_line(c + Vector2(-s * 0.98, 0), c + Vector2(-s * 1.55, 0), Color(0.1, 0.1, 0.14, alpha), maxf(s * 0.05, 2.0))
	if sp == "flyer":
		ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.3, 0), c + Vector2(s * 0.3, -s * 1.0), c + Vector2(s * 0.55, -s * 0.15)]), Color(0.86, 0.92, 0.98, alpha * 0.9))
	# body
	ci.draw_colored_polygon(ell(c, s, s * hy), body)
	ci.draw_colored_polygon(ell(c + Vector2(0, s * hy * 0.34), s * 0.9, s * hy * 0.55), belly)
	match sp:
		"mackerel":
			for k in 5:
				var x = -s * 0.5 + k * s * 0.3
				ci.draw_line(c + Vector2(x, -s * hy * 0.85), c + Vector2(x + s * 0.12, -s * hy * 0.2), Color(0.1, 0.16, 0.22, alpha * 0.8), maxf(s * 0.05, 1.5))
		"mullet":
			ci.draw_line(c + Vector2(-s * 0.7, -s * hy * 0.05), c + Vector2(s * 0.7, -s * hy * 0.05), Color(0.97, 0.82, 0.3, alpha), maxf(s * 0.08, 2.0))
		"opah":
			for k in 7:
				var a = k * 0.9
				ci.draw_circle(c + Vector2(cos(a) * s * 0.55, sin(a) * s * 0.55 * hy), maxf(s * 0.05, 1.5), Color(1, 1, 1, alpha * 0.9))
		"tuna":
			for k in 4:
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * (0.5 + k * 0.1), -s * hy * 0.8), c + Vector2(s * (0.56 + k * 0.1), -s * hy * 1.15), c + Vector2(s * (0.62 + k * 0.1), -s * hy * 0.75)]), Color(1.0, 0.9, 0.3, alpha))
	# eye + gill
	ci.draw_circle(c + Vector2(-s * 0.66, -s * hy * 0.16), maxf(s * 0.07, 2.0), Color(0.06, 0.06, 0.09, alpha))
	ci.draw_arc(c + Vector2(-s * 0.4, 0), s * hy * 0.8, -1.0, 1.0, 8, Color(0, 0, 0, alpha * 0.2), maxf(s * 0.04, 1.2), true)
