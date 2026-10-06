extends Control
# Lower-left comic panel: a funny little picture that pops up when something happens to the gull
# ("why did that hurt?" / "got the fry, feeling smug").
#
# Pictures: put square PNGs named <id>.png in  game/assets/ui/comics/  (also checked: a "comics" folder next to the exe,
# and user://comics/). Without a file the panel draws a placeholder in code. Ids and prompts: docs/20_COMIC_PROMPTS.md.
#   success: smug, perfect, mischief, fish, cool   hurt: hit_swat_punch, hit_swat_poke, hit_swat_sweep, hit_swat_squirt,
#   hurt: hit_swat_lunge (dog), hit_crash (wall), hit_swat_ball (volleyball), hit_swat_rival (a gull), hit_swat_grump (newspaper)
#   other: soaked, rival (a gull beat you to it), scare (a kid shouted BOO)
# smug / perfect take the colour of the fry's rarity (blue rare / purple epic / gold legendary): see `extra` below.

const PW = 250.0
const PH = 304.0
const FR = 113.0          # half size of the picture frame
const INK = Color(0.14, 0.13, 0.18)
const BEAK = Color(1.0, 0.72, 0.18)
const SKIN = Color(0.96, 0.78, 0.62)

var id = ""
var caption = ""
var slide = 0.0
var t = 0.0
var tw = null
var tex_cache = {}
var hurt = false
var extra = {}
var tier = 0
var tint = Color.WHITE

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_comic(p_id, p_caption, hold = 2.8, p_extra = {}):
	id = p_id
	caption = p_caption
	extra = p_extra
	tier = int(extra.get("tier", 0))
	tint = extra.get("col", Color.WHITE)
	hurt = id.begins_with("hit_") or id in ["soaked", "rival", "scare"]
	t = 0.0
	if tw != null:
		tw.kill()
	tw = create_tween().set_ignore_time_scale(true)
	tw.tween_property(self, "slide", 1.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(hold)
	tw.tween_property(self, "slide", 0.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	Sfx.play("pop", -9.0, 1.0 if not hurt else 0.8)

func _process(delta):
	t += delta / max(Engine.time_scale, 0.1)
	if slide > 0.001:
		queue_redraw()

# ------------------------------------------------------------------ pictures
func _tex(pid):
	if tex_cache.has(pid):
		return tex_cache[pid]
	var found = null
	var res_path = "res://assets/ui/comics/%s.png" % pid
	if ResourceLoader.exists(res_path):
		found = load(res_path)
	if found == null:
		for path in [res_path, "user://comics/%s.png" % pid, OS.get_executable_path().get_base_dir() + "/comics/%s.png" % pid]:
			if FileAccess.file_exists(path):
				var img = Image.load_from_file(path)
				if img != null and not img.is_empty():
					found = ImageTexture.create_from_image(img)
					break
	tex_cache[pid] = found
	return found

# ------------------------------------------------------------------ drawing
func _draw():
	if slide <= 0.001:
		return
	var font = ThemeDB.fallback_font
	var k = 0.72                 # round 5: smaller, so it never covers the game
	var x = lerp(-PW * k - 60.0, 22.0, slide)
	var y = size.y - PH * k - 22.0
	var wob = sin(t * 2.2) * 0.012
	draw_set_transform(Vector2(x + PW * k * 0.5, y + PH * k * 0.5), -0.05 + wob, Vector2(k, k))
	var o = Vector2(-PW * 0.5, -PH * 0.5)
	draw_rect(Rect2(o + Vector2(7, 9), Vector2(PW, PH)), Color(0, 0, 0, 0.33))
	draw_rect(Rect2(o, Vector2(PW, PH)), Color(0.99, 0.97, 0.9, 0.98))
	if tier >= 1 and not hurt:
		draw_rect(Rect2(o + Vector2(3, 3), Vector2(PW - 6, PH - 6)), Color(tint.r, tint.g, tint.b, 0.95), false, 6.0)
	draw_rect(Rect2(o, Vector2(PW, PH)), INK, false, 4.0)
	var fc = o + Vector2(PW * 0.5, 12.0 + FR)
	var frame = Rect2(fc - Vector2(FR, FR), Vector2(FR, FR) * 2.0)
	var tx = null
	if tier >= 1 and (id == "smug" or id == "perfect"):
		tx = _tex("%s_%d" % [id, tier])      # smug_1 / smug_2 / smug_3 (rare / epic / legendary) if you made them
	if tx == null:
		tx = _tex(id)
	if tx != null:
		draw_rect(frame, Color(1, 1, 1, 1))
		draw_texture_rect(tx, frame, false)
	else:
		_art(fc)
	draw_rect(frame, INK, false, 3.0)
	if tier >= 1 and not hurt:
		var rn = ["", "SILVER", "GOLD", "DIAMOND", "RAINBOW"][clamp(tier, 0, 4)]
		if id == "fish":
			rn = "PERFECT" if tier >= 3 else "FISH"
		var ribbon = Rect2(frame.position + Vector2(-2, 10), Vector2(24 + rn.length() * 9.0, 22))
		draw_rect(ribbon, tint)
		draw_rect(ribbon, INK, false, 2.0)
		draw_string(font, ribbon.position + Vector2(8, 16), rn, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, INK)
	var cap_y = o.y + 12.0 + FR * 2.0 + 20.0
	draw_multiline_string(font, Vector2(o.x + 12.0, cap_y + 1.5), caption, HORIZONTAL_ALIGNMENT_CENTER, PW - 24.0, 17, 2, Color(0, 0, 0, 0.15))
	draw_multiline_string(font, Vector2(o.x + 12.0, cap_y), caption, HORIZONTAL_ALIGNMENT_CENTER, PW - 24.0, 17, 2, INK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ---- little drawing kit (all coordinates relative to the frame centre) ----
func _burst(c, base, rays, n = 18):
	draw_rect(Rect2(c - Vector2(FR, FR), Vector2(FR, FR) * 2.0), base)
	for i in n:
		var a0 = TAU * i / n + t * 0.15
		var a1 = a0 + TAU / n * 0.5
		var pts = PackedVector2Array([c, _clamp_pt(c + Vector2(cos(a0), sin(a0)) * 400.0, c), _clamp_pt(c + Vector2(cos(a1), sin(a1)) * 400.0, c)])
		draw_colored_polygon(pts, rays)

func _clamp_pt(p, c):
	return c + Vector2(clamp(p.x - c.x, -FR, FR), clamp(p.y - c.y, -FR, FR))

func _ink_circle(c, r, col, w = 4.0):
	draw_circle(c, r, col)
	draw_arc(c, r, 0, TAU, 40, INK, w, true)

func _star(c, r, col, rot = 0.0):
	var pts = PackedVector2Array()
	for i in 10:
		var rr = r if i % 2 == 0 else r * 0.45
		var a = rot + TAU * i / 10.0 - PI / 2.0
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, col)
	pts.append(pts[0])
	draw_polyline(pts, INK, 2.0, true)

func _text(c, s, sz, col):
	var font = ThemeDB.fallback_font
	draw_string(font, c + Vector2(-90, 3), s, HORIZONTAL_ALIGNMENT_CENTER, 180, sz, Color(0, 0, 0, 0.9))
	draw_string(font, c + Vector2(-90, -2), s, HORIZONTAL_ALIGNMENT_CENTER, 180, sz, col)

# the hero: a round, slightly dim, very white gull head
func _gull(c, r, mood):
	# neck + grey shoulder
	draw_circle(c + Vector2(-r * 0.15, r * 0.95), r * 0.8, Color(0.72, 0.76, 0.82))
	draw_arc(c + Vector2(-r * 0.15, r * 0.95), r * 0.8, PI * 1.05, PI * 1.95, 24, INK, 4.0, true)
	_ink_circle(c, r, Color(0.99, 0.99, 0.98))
	var open = mood in ["ow", "dizzy"]
	var by = c + Vector2(r * 0.85, r * 0.12)
	# beak
	if open:
		draw_colored_polygon(PackedVector2Array([by + Vector2(-r * 0.1, -r * 0.3), by + Vector2(r * 0.85, -r * 0.35), by + Vector2(r * 0.05, -r * 0.02)]), BEAK)
		draw_colored_polygon(PackedVector2Array([by + Vector2(-r * 0.1, r * 0.05), by + Vector2(r * 0.7, r * 0.3), by + Vector2(r * 0.0, r * 0.38)]), BEAK)
		draw_colored_polygon(PackedVector2Array([by + Vector2(r * 0.0, -r * 0.02), by + Vector2(r * 0.55, r * 0.0), by + Vector2(r * 0.0, r * 0.1)]), Color(0.8, 0.2, 0.25))
	else:
		draw_colored_polygon(PackedVector2Array([by + Vector2(-r * 0.1, -r * 0.32), by + Vector2(r * 0.95, r * 0.05), by + Vector2(-r * 0.1, r * 0.34)]), BEAK)
		draw_circle(by + Vector2(r * 0.55, r * 0.07), r * 0.07, Color(0.9, 0.2, 0.2))
	draw_polyline(PackedVector2Array([by + Vector2(-r * 0.1, -r * 0.32), by + Vector2(r * 0.95, r * 0.05), by + Vector2(-r * 0.1, r * 0.34)]), INK, 3.0, true)
	# eyes
	var ec = c + Vector2(r * 0.3, -r * 0.22)
	match mood:
		"ow":
			draw_line(ec + Vector2(-r * 0.22, -r * 0.2), ec + Vector2(r * 0.22, r * 0.2), INK, 5.0)
			draw_line(ec + Vector2(-r * 0.22, r * 0.2), ec + Vector2(r * 0.22, -r * 0.2), INK, 5.0)
		"dizzy":
			for k in 3:
				draw_arc(ec, r * (0.08 + 0.07 * k), t * 8.0 + k, t * 8.0 + k + TAU * 0.8, 14, INK, 3.0, true)
		"cool":
			draw_rect(Rect2(ec + Vector2(-r * 0.55, -r * 0.2), Vector2(r * 1.1, r * 0.42)), Color(0.08, 0.08, 0.12))
			draw_rect(Rect2(ec + Vector2(-r * 0.7, -r * 0.14), Vector2(r * 0.2, r * 0.1)), Color(0.08, 0.08, 0.12))
			draw_line(ec + Vector2(-r * 0.4, -r * 0.1), ec + Vector2(-r * 0.2, r * 0.1), Color(1, 1, 1, 0.6), 3.0)
		"smug":
			_ink_circle(ec, r * 0.2, Color.WHITE, 3.0)
			draw_circle(ec + Vector2(r * 0.06, r * 0.03), r * 0.09, INK)
			draw_rect(Rect2(ec + Vector2(-r * 0.24, -r * 0.24), Vector2(r * 0.48, r * 0.24)), Color(0.99, 0.99, 0.98))
			draw_line(ec + Vector2(-r * 0.26, -r * 0.0), ec + Vector2(r * 0.26, -r * 0.0), INK, 4.0)
			draw_line(ec + Vector2(-r * 0.2, -r * 0.34), ec + Vector2(r * 0.28, -r * 0.46), INK, 4.0)
		"wet":
			_ink_circle(ec, r * 0.2, Color.WHITE, 3.0)
			draw_circle(ec + Vector2(r * 0.05, r * 0.06), r * 0.09, INK)
			draw_line(ec + Vector2(-r * 0.3, -r * 0.4), ec + Vector2(r * 0.22, -r * 0.24), INK, 4.0)
		_:
			_ink_circle(ec, r * 0.2, Color.WHITE, 3.0)
			draw_circle(ec + Vector2(r * 0.07, r * 0.0), r * 0.1, INK)
			draw_circle(ec + Vector2(r * 0.1, -r * 0.04), r * 0.035, Color.WHITE)

# ONE fry in the beak: a single golden crinkle-cut stick (with a ribbon in the fry type's colour for the special ones)
func _fry_in_beak(c, r):
	var base = c + Vector2(r * 1.0, r * 0.1)
	var tip = base + Vector2(r * 0.62, -r * 0.98)
	var d = (tip - base).normalized()
	var n = Vector2(-d.y, d.x)
	var wd = r * 0.24
	var pts = PackedVector2Array([base + n * wd * 0.5, tip + n * wd * 0.5, tip - n * wd * 0.5, base - n * wd * 0.5])
	draw_colored_polygon(pts, Color(1.0, 0.82, 0.28))
	for k in 4:
		var u = 0.25 + k * 0.2
		var mid = base.lerp(tip, u)
		draw_line(mid + n * wd * 0.5, mid - n * wd * 0.5, Color(0.86, 0.6, 0.12), 2.0)
	var band_col = GS.TYPE_COLORS.get(str(extra.get("type", "")), Color(0, 0, 0, 0))
	if band_col.a > 0.0:
		var m1 = base.lerp(tip, 0.18)
		var m2 = base.lerp(tip, 0.34)
		draw_colored_polygon(PackedVector2Array([m1 + n * wd * 0.62, m2 + n * wd * 0.62, m2 - n * wd * 0.62, m1 - n * wd * 0.62]), band_col)
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), INK, 2.5, true)

func _tcol(default_col):
	return tint if tier >= 1 else default_col

# a stolen thing, drawn big (hat / balloon / pipe / shades / necklace / bow tie / scarf / beach ball / ice cream)
func _item(kind, hc):
	match kind:
		"balloon":
			draw_line(hc + Vector2(0, 20), hc + Vector2(-6, 80), INK, 2.0)
			_ink_circle(hc + Vector2(0, -12), 34.0, Color(0.9, 0.34, 0.28))
		"pipe":
			draw_rect(Rect2(hc + Vector2(-46, -2), Vector2(70, 12)), Color(0.45, 0.28, 0.14))
			draw_rect(Rect2(hc + Vector2(14, -26), Vector2(34, 36)), Color(0.35, 0.2, 0.1))
			draw_rect(Rect2(hc + Vector2(14, -26), Vector2(34, 36)), INK, false, 3.0)
			for k in 3:
				draw_arc(hc + Vector2(30 + k * 6, -40 - k * 14), 8.0 + k * 3.0, 0, TAU, 12, Color(0.8, 0.8, 0.85, 0.7 - 0.2 * k), 3.0, true)
		"shades":
			draw_rect(Rect2(hc + Vector2(-50, -8), Vector2(40, 26)), Color(0.08, 0.08, 0.12))
			draw_rect(Rect2(hc + Vector2(10, -8), Vector2(40, 26)), Color(0.08, 0.08, 0.12))
			draw_line(hc + Vector2(-10, 2), hc + Vector2(10, 2), Color(0.08, 0.08, 0.12), 5.0)
			draw_line(hc + Vector2(-44, -2), hc + Vector2(-34, 6), Color(1, 1, 1, 0.6), 3.0)
		"necklace":
			draw_arc(hc + Vector2(0, -16), 46.0, 0.2, PI - 0.2, 24, Color(1.0, 0.82, 0.25), 6.0, true)
			_ink_circle(hc + Vector2(0, 32), 11.0, Color(0.9, 0.2, 0.3), 3.0)
		"bowtie":
			draw_colored_polygon(PackedVector2Array([hc + Vector2(0, 8), hc + Vector2(-44, -14), hc + Vector2(-44, 30)]), Color(0.8, 0.15, 0.2))
			draw_colored_polygon(PackedVector2Array([hc + Vector2(0, 8), hc + Vector2(44, -14), hc + Vector2(44, 30)]), Color(0.8, 0.15, 0.2))
			_ink_circle(hc + Vector2(0, 8), 9.0, Color(0.6, 0.1, 0.15), 3.0)
		"scarf":
			draw_rect(Rect2(hc + Vector2(-50, -4), Vector2(100, 24)), Color(0.85, 0.25, 0.2))
			draw_rect(Rect2(hc + Vector2(20, 14), Vector2(24, 54)), Color(0.85, 0.25, 0.2))
			draw_rect(Rect2(hc + Vector2(-50, -4), Vector2(100, 24)), INK, false, 3.0)
		"ball":
			_ink_circle(hc + Vector2(0, 8), 36.0, Color(0.97, 0.95, 0.9))
			draw_rect(Rect2(hc + Vector2(-34, 2), Vector2(68, 12)), Color(0.9, 0.34, 0.28))
		"icecream":
			draw_colored_polygon(PackedVector2Array([hc + Vector2(-16, 10), hc + Vector2(16, 10), hc + Vector2(0, 70)]), Color(0.85, 0.65, 0.25))
			_ink_circle(hc + Vector2(0, -2), 22.0, Color(0.97, 0.78, 0.84), 3.0)
			_ink_circle(hc + Vector2(0, -26), 17.0, Color(1.0, 0.95, 0.78), 3.0)
		_:
			draw_circle(hc + Vector2(0, 12), 46.0, Color(0.94, 0.85, 0.63))
			draw_rect(Rect2(hc + Vector2(-44, 8), Vector2(88, 10)), Color(0.94, 0.85, 0.63))
			draw_rect(Rect2(hc + Vector2(-26, -22), Vector2(52, 32)), Color(0.94, 0.85, 0.63))
			draw_rect(Rect2(hc + Vector2(-26, -2), Vector2(52, 9)), Color(0.85, 0.43, 0.37))
			draw_rect(Rect2(hc + Vector2(-44, 8), Vector2(88, 10)), INK, false, 3.0)

func _fish(c, k):
	var body = Color(0.55, 0.78, 0.9)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-46, 0) * k, c + Vector2(-72, -22) * k, c + Vector2(-72, 22) * k]), body)
	var pts = PackedVector2Array()
	for i in 20:
		var a = TAU * i / 20.0
		pts.append(c + Vector2(cos(a) * 46.0, sin(a) * 24.0) * k)
	draw_colored_polygon(pts, body)
	draw_polyline(pts, INK, 3.0, true)
	draw_circle(c + Vector2(26, -5) * k, 5.0, INK)
	draw_arc(c + Vector2(-4, 4) * k, 18.0, 0.3, 2.6, 10, Color(1, 1, 1, 0.7), 3.0, true)

# the gull's whole outfit: shades + pipe + necklace
func _gear(c, r):
	draw_arc(c + Vector2(-r * 0.1, r * 1.1), r * 0.78, 0.35, PI - 0.35, 20, Color(1.0, 0.82, 0.25), 5.0, true)
	_ink_circle(c + Vector2(-r * 0.1, r * 1.8), r * 0.12, Color(0.9, 0.2, 0.3), 3.0)
	draw_rect(Rect2(c + Vector2(r * 0.75, r * 0.3), Vector2(r * 0.62, r * 0.1)), Color(0.45, 0.28, 0.14))
	draw_rect(Rect2(c + Vector2(r * 1.3, r * 0.05), Vector2(r * 0.22, r * 0.3)), Color(0.35, 0.2, 0.1))
	for k in 2:
		draw_arc(c + Vector2(r * 1.45 + k * 6, -r * 0.1 - k * 14), 8.0 + k * 3.0, 0, TAU, 12, Color(0.8, 0.8, 0.85, 0.6 - 0.2 * k), 3.0, true)

func _drop(c, s, col):
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 1.3), c + Vector2(s * 0.7, s * 0.2), c + Vector2(0, s * 0.8), c + Vector2(-s * 0.7, s * 0.2)]), col)

func _art(fc):
	match id:
		"smug":
			var b1 = _tcol(Color(0.55, 0.8, 1.0))
			_burst(fc, b1, b1.lightened(0.3))
			_gull(fc + Vector2(-34, 12 + sin(t * 3.0) * 2.0), 52.0, "smug")
			_fry_in_beak(fc + Vector2(-34, 12), 52.0)
			_star(fc + Vector2(72, -62), 12.0 + 3.0 * tier, Color(1, 0.95, 0.5), t)
			if tier >= 2:
				_star(fc + Vector2(-82, -66), 10.0, Color(1, 1, 0.85), -t * 1.2)
		"perfect":
			var b2 = _tcol(Color(1.0, 0.85, 0.35))
			_burst(fc, b2, b2.lightened(0.35), 22 if tier >= 3 else 18)
			_gull(fc + Vector2(-34, 12), 52.0, "cool")
			_fry_in_beak(fc + Vector2(-34, 12), 52.0)
			_star(fc + Vector2(72, -66), 15.0, Color(1, 1, 0.8), t * 1.3)
			_star(fc + Vector2(-84, -70), 10.0, Color(1, 1, 0.8), -t)
			_star(fc + Vector2(78, 66), 9.0, Color(1, 1, 0.8), t * 0.7)
		"mischief":
			_burst(fc, Color(0.85, 0.7, 1.0), Color(0.93, 0.82, 1.0))
			_gull(fc + Vector2(-14, 18), 48.0, "smug")
			_item(str(extra.get("kind", "hat")), fc + Vector2(-26, -34))
		"cool":
			_burst(fc, Color(1.0, 0.82, 0.3), Color(1.0, 0.93, 0.6), 22)
			_gull(fc + Vector2(-20, 14), 54.0, "cool")
			_gear(fc + Vector2(-20, 14), 54.0)
			_star(fc + Vector2(76, -68), 14.0, Color(1, 1, 0.8), t * 1.1)
			_star(fc + Vector2(-86, -64), 10.0, Color(1, 1, 0.8), -t)
		"fish":
			var b3 = Color(0.45, 0.82, 0.95) if tier < 3 else Color(1.0, 0.85, 0.4)
			_burst(fc, b3, b3.lightened(0.3))
			for k in 3:
				draw_arc(fc + Vector2(0, 104), 40.0 + k * 30.0, PI * 1.15, PI * 1.85, 16, Color(0.2, 0.5, 0.9, 0.8), 4.0, true)
			_gull(fc + Vector2(-34, 6), 50.0, "smug")
			_fish(fc + Vector2(34, -34 + sin(t * 5.0) * 3.0), 1.0)
			for k in 5:
				_drop(fc + Vector2(-56 + k * 30, -64 + ((k * 7) % 4) * 10 + sin(t * 5 + k) * 3), 6.0, Color(0.3, 0.6, 1.0))
		"hit_swat_ball":
			_burst(fc, Color(1.0, 0.9, 0.5), Color(1.0, 0.8, 0.3))
			_gull(fc + Vector2(-26, 30), 40.0, "dizzy")
			var bc = fc + Vector2(34, -26)
			_ink_circle(bc, 56.0, Color(0.98, 0.97, 0.92))
			draw_arc(bc, 56.0, 0.3, 1.9, 16, Color(0.25, 0.45, 0.85), 8.0, true)
			draw_arc(bc, 56.0, 2.7, 4.2, 16, Color(0.95, 0.75, 0.2), 8.0, true)
			draw_arc(bc, 36.0, 4.4, 5.8, 16, Color(0.25, 0.45, 0.85), 6.0, true)
			_star(fc + Vector2(-60, -50), 11.0, Color(1, 1, 0.5), t * 3.0)
			_text(fc + Vector2(-30, 102), "BOP!", 34, Color(0.85, 0.15, 0.1))
		"hit_swat_rival":
			_burst(fc, Color(1.0, 0.86, 0.3), Color(1.0, 0.64, 0.2))
			_gull(fc + Vector2(-40, 30), 38.0, "ow")
			var rc = fc + Vector2(44, -26)
			draw_circle(rc + Vector2(-8, 60), 44.0, Color(0.55, 0.58, 0.62))
			_ink_circle(rc, 46.0, Color(0.9, 0.9, 0.88))
			draw_colored_polygon(PackedVector2Array([rc + Vector2(-40, -4), rc + Vector2(-96, 6), rc + Vector2(-40, 22)]), BEAK)
			draw_circle(rc + Vector2(-16, -12), 6.0, INK)
			draw_line(rc + Vector2(-30, -26), rc + Vector2(-4, -18), INK, 4.0)
			_text(fc + Vector2(0, -96), "SQUAWK!", 30, Color(0.85, 0.15, 0.1))
		"hit_swat_grump":
			_burst(fc, Color(0.85, 0.85, 0.8), Color(0.95, 0.95, 0.9))
			_gull(fc + Vector2(34, 14), 44.0, "ow")
			var nc = fc + Vector2(-40, -10)
			draw_rect(Rect2(nc + Vector2(-70, -26), Vector2(110, 52)), Color(0.93, 0.9, 0.82))
			for k in 4:
				draw_line(nc + Vector2(-60, -16 + k * 11), nc + Vector2(30, -16 + k * 11), Color(0.35, 0.35, 0.38), 3.0)
			draw_rect(Rect2(nc + Vector2(-70, -26), Vector2(110, 52)), INK, false, 3.0)
			_text(fc + Vector2(0, -92), "SHOO!", 32, Color(0.85, 0.15, 0.1))
		"rival":
			_burst(fc, Color(0.85, 0.85, 0.9), Color(0.95, 0.95, 1.0))
			_gull(fc + Vector2(-52, 36), 40.0, "ow")
			var fl = fc + Vector2(48 + sin(t * 4.0) * 4.0, -34)
			draw_colored_polygon(PackedVector2Array([fl + Vector2(-50, 8), fl + Vector2(-10, -22), fl + Vector2(46, 4), fl + Vector2(-8, 4)]), Color(0.7, 0.74, 0.8))
			_ink_circle(fl + Vector2(-8, 4), 22.0, Color(0.96, 0.96, 0.94))
			draw_line(fl + Vector2(-10, -10), fl + Vector2(20, -52), Color(1.0, 0.82, 0.28), 8.0, true)
			_text(fc + Vector2(0, 98), "MINE! (NOT YOURS)", 22, Color(0.85, 0.15, 0.1))
		"scare":
			_burst(fc, Color(1.0, 0.92, 0.5), Color(1.0, 0.8, 0.3))
			_gull(fc + Vector2(48, 38), 32.0, "ow")
			var kc = fc + Vector2(-26, -10)
			_ink_circle(kc, 54.0, Color(0.97, 0.8, 0.64))
			draw_circle(kc + Vector2(-18, -10), 7.0, INK)
			draw_circle(kc + Vector2(18, -10), 7.0, INK)
			draw_rect(Rect2(kc + Vector2(-20, 14), Vector2(40, 28)), Color(0.55, 0.12, 0.15))
			draw_arc(kc + Vector2(0, -36), 58.0, PI * 1.1, PI * 1.9, 14, Color(0.35, 0.22, 0.12), 14.0, true)
			_text(fc + Vector2(0, -98), "BOO!", 38, Color(0.85, 0.15, 0.1))
		"hit_swat_punch":
			_burst(fc, Color(1.0, 0.86, 0.3), Color(1.0, 0.64, 0.2))
			_gull(fc + Vector2(26 + sin(t * 40.0) * 3.0, 14), 48.0, "ow")
			var f = fc + Vector2(-24, -2)
			draw_rect(Rect2(f + Vector2(-50, -30), Vector2(78, 60)), SKIN)
			for k in 4:
				draw_line(f + Vector2(28, -22 + k * 14), f + Vector2(28, -12 + k * 14), INK, 2.5)
			draw_rect(Rect2(f + Vector2(-50, -30), Vector2(78, 60)), INK, false, 4.0)
			draw_rect(Rect2(f + Vector2(-80, -22), Vector2(30, 44)), Color(0.55, 0.57, 0.62))
			draw_rect(Rect2(f + Vector2(-80, -22), Vector2(30, 44)), INK, false, 3.0)
			_text(fc + Vector2(-20, -84), "POW!", 34, Color(0.85, 0.15, 0.1))
			_star(fc + Vector2(66, -62), 11.0, Color(1, 1, 0.5), t * 3.0)
		"hit_swat_poke":
			_burst(fc, Color(1.0, 0.86, 0.3), Color(1.0, 0.64, 0.2))
			_gull(fc + Vector2(-12, 30), 42.0, "ow")
			draw_line(fc + Vector2(60, -70), fc + Vector2(-2, -4), Color(0.4, 0.25, 0.12), 6.0, true)
			draw_colored_polygon(PackedVector2Array([fc + Vector2(-4, -2), fc + Vector2(8, -14), fc + Vector2(-14, -22)]), Color(0.75, 0.75, 0.8))
			draw_colored_polygon(PackedVector2Array([fc + Vector2(20, -64), fc + Vector2(30, -92), fc + Vector2(58, -106), fc + Vector2(88, -96), fc + Vector2(106, -68), fc + Vector2(60, -62)]), Color(0.65, 0.4, 0.8))
			_text(fc + Vector2(-40, 104), "POKE!", 28, Color(0.85, 0.15, 0.1))
		"hit_swat_sweep":
			_burst(fc, Color(1.0, 0.86, 0.3), Color(1.0, 0.64, 0.2))
			_gull(fc + Vector2(30, 6), 46.0, "dizzy")
			draw_line(fc + Vector2(-100, 70), fc + Vector2(-8, -30), Color(0.55, 0.38, 0.2), 7.0, true)
			draw_colored_polygon(PackedVector2Array([fc + Vector2(-8, -30), fc + Vector2(30, -46), fc + Vector2(46, -2), fc + Vector2(20, 26), fc + Vector2(-20, -8)]), Color(0.86, 0.7, 0.3))
			draw_polyline(PackedVector2Array([fc + Vector2(-8, -30), fc + Vector2(30, -46), fc + Vector2(46, -2), fc + Vector2(20, 26), fc + Vector2(-20, -8), fc + Vector2(-8, -30)]), INK, 3.0, true)
			_text(fc + Vector2(-10, 94), "SWOOSH!", 30, Color(0.85, 0.15, 0.1))
		"hit_swat_squirt":
			_burst(fc, Color(0.7, 0.9, 1.0), Color(0.55, 0.8, 1.0))
			_gull(fc + Vector2(34, 6), 46.0, "wet")
			var g = fc + Vector2(-84, 6)
			draw_rect(Rect2(g + Vector2(-20, -16), Vector2(56, 26)), Color(1.0, 0.5, 0.2))
			draw_rect(Rect2(g + Vector2(-20, -16), Vector2(56, 26)), INK, false, 3.0)
			draw_rect(Rect2(g + Vector2(34, -10), Vector2(24, 12)), Color(0.3, 0.55, 0.9))
			draw_colored_polygon(PackedVector2Array([g + Vector2(-8, 10), g + Vector2(14, 10), g + Vector2(6, 38), g + Vector2(-12, 38)]), Color(0.3, 0.55, 0.9))
			draw_line(g + Vector2(58, -4), fc + Vector2(8, 0), Color(0.35, 0.65, 1.0, 0.9), 8.0, true)
			for k in 5:
				_drop(fc + Vector2(-20 + k * 14, -40 - (k % 3) * 12 + sin(t * 6 + k) * 3), 6.0, Color(0.35, 0.65, 1.0))
			_text(fc + Vector2(-10, 98), "SQUIRT!", 30, Color(0.1, 0.35, 0.8))
		"hit_swat_lunge":
			_burst(fc, Color(1.0, 0.86, 0.3), Color(1.0, 0.64, 0.2))
			_gull(fc + Vector2(60, 56), 30.0, "ow")
			var d = fc + Vector2(-18, -6)
			draw_circle(d + Vector2(-42, -30), 22.0, Color(0.42, 0.28, 0.15))
			draw_circle(d + Vector2(42, -30), 22.0, Color(0.42, 0.28, 0.15))
			_ink_circle(d, 56.0, Color(0.72, 0.5, 0.28))
			_ink_circle(d + Vector2(0, 22), 30.0, Color(0.95, 0.9, 0.82))
			draw_circle(d + Vector2(0, 8), 8.0, INK)
			draw_rect(Rect2(d + Vector2(-20, 24), Vector2(40, 20)), Color(0.75, 0.15, 0.2))
			for k in 4:
				draw_colored_polygon(PackedVector2Array([d + Vector2(-18 + k * 11, 24), d + Vector2(-9 + k * 11, 24), d + Vector2(-13.5 + k * 11, 36)]), Color.WHITE)
			draw_circle(d + Vector2(-20, -14), 6.0, INK)
			draw_circle(d + Vector2(20, -14), 6.0, INK)
			draw_line(d + Vector2(-32, -30), d + Vector2(-8, -22), INK, 4.0)
			draw_line(d + Vector2(32, -30), d + Vector2(8, -22), INK, 4.0)
			_text(fc + Vector2(0, -94), "WOOF!", 32, Color(0.85, 0.15, 0.1))
		"hit_crash":
			_burst(fc, Color(1.0, 0.86, 0.3), Color(1.0, 0.64, 0.2))
			for row in 7:
				for col in 3:
					var bx = fc.x + 36.0 + col * 25.0 + (12.0 if row % 2 == 1 else 0.0) - 12.0
					var by = fc.y - FR + row * 33.0
					draw_rect(Rect2(bx, by, 24.0, 31.0), Color(0.78, 0.4, 0.3))
					draw_rect(Rect2(bx, by, 24.0, 31.0), INK, false, 2.0)
			draw_line(fc + Vector2(50, -30), fc + Vector2(74, 10), INK, 3.0)
			draw_line(fc + Vector2(74, 10), fc + Vector2(58, 40), INK, 3.0)
			_gull(fc + Vector2(-34 + sin(t * 30.0) * 2.0, 0), 42.0, "ow")
			_star(fc + Vector2(8, -66), 12.0, Color(1, 1, 0.5), t * 4.0)
			_star(fc + Vector2(-60, -50), 9.0, Color(1, 1, 0.5), -t * 3.0)
			_text(fc + Vector2(-30, 102), "CRASH!", 28, Color(0.85, 0.15, 0.1))
		"soaked":
			_burst(fc, Color(0.62, 0.86, 1.0), Color(0.5, 0.78, 0.98))
			_gull(fc + Vector2(-10, 4), 48.0, "wet")
			for k in 6:
				_drop(fc + Vector2(-70 + k * 26, -50 + ((k * 7) % 5) * 12 + sin(t * 5 + k) * 3), 6.0, Color(0.3, 0.6, 1.0))
			for k in 3:
				draw_arc(fc + Vector2(0, 100), 40.0 + k * 34.0, PI * 1.15, PI * 1.85, 16, Color(0.2, 0.5, 0.9), 4.0, true)
		_:
			_burst(fc, Color(0.95, 0.95, 0.85), Color(1, 1, 0.95))
			_gull(fc, 52.0, "smug")
