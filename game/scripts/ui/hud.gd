extends CanvasLayer
# HUD (round 5, "less but clearer"): stamina + crowd WATCH (top right) with the racing-style SPEED TACH under it, the rhythm rings
# around the fry, the half-rainbow of fries (top-left) with a tiny mission board, Gull Sight overlay, lower-left comic panel,
# close-up letterbox, hints, achievement toasts, Still Hungry, ending.
# The "you got a fry" moment is light: the fry flies into its slot of the rainbow and a small name tag fades in. Nothing pauses.

const ComicPop = preload("res://scripts/ui/comic_pop.gd")
const Vision = preload("res://scripts/ui/vision_overlay.gd")

const COMMON_FRY = Color("F6C453")
const GOLD = Color("F5C65A")
const RING_GREEN = Color(0.32, 0.92, 0.42)
const RING_GOLD = Color(1.0, 0.82, 0.25)

const HURT_CAPTIONS = {
	"swat_punch": ["POW. A PUNCH. FROM A GRANDPARENT.", "SMACKED. BY AN ELDERLY HAND."],
	"swat_poke": ["POKED. WITH AN UMBRELLA.", "AN UMBRELLA. OF ALL THINGS."],
	"swat_sweep": ["SWEPT UP WITH THE CRUMBS.", "THE BROOM HAS OPINIONS."],
	"swat_squirt": ["SQUIRTED. BY A CHILD.", "A CHILD. A WATER GUN. A TRAGEDY."],
	"swat_lunge": ["A DOG. OF COURSE.", "WOOF. (THAT MEANS 'MINE')"],
	"crash": ["THE WALL WAS REAL.", "THE WALL WON."],
	"swat_ball": ["VOLLEYBALL. THE NET WAS RIGHT THERE.", "SPIKED. NOBODY SAID SORRY."],
	"swat_rival": ["A GULL. THE AUDACITY.", "BEAKED. BY A STRANGER."],
	"swat_grump": ["SHOO'D. WITH A NEWSPAPER.", "A STRANGER'S HAND. HOW RUDE."],
}

# the mission board's small print: [fries needed, line]
const MISSION_HINTS = [
	[0, "the old man's table is a good start."],
	[3, "hold TAB. look around."],
	[6, "fries glow in colours. the colours mean things."],
	[10, "you are strong now. and still hungry. why?"],
	[17, "silver, gold, diamond. in that order."],
	[24, "everything is full. except you."],
]

var player = null
var ui_root
var objective_title
var objective_count
var status
var arc
var reticle
var gauge
var streaks
var bars
var center_msg
var small_msg
var hint_label
var whisper_label
var toast_box
var toast_label
var ending_fry
var ending_text
var fade_rect
var slots_visible = false
var collected = {}
var msg_tween
var hint_shown = {}
var hint_tween
var whisper_tween
var toast_queue = []
var toast_busy = false
var lb = 0.0
var focus_a = 0.0
var vignette
var guide
var guide_pos = null
var hint_pos = null
var hint_text = ""
var prompt_label
var prompt_text = ""
var comic
var vision
var last_comic = {"id": "", "t": -9.0}
var gains = []                  # fries flying into the rainbow: {type, tier, t}
var plate = null                # the small name tag: {type, tier, t}

# ---------------------------------------------------------------- inner draw classes
class HC extends Control:
	func shadow(font, pos, text, size_, col, align = HORIZONTAL_ALIGNMENT_LEFT, width = -1.0):
		draw_string(font, pos + Vector2(1.5, 1.5), text, align, width, size_, Color(0, 0, 0, col.a * 0.75))
		draw_string(font, pos, text, align, width, size_, col)
	func chevron(c, up, col, w = 12.0):
		var s = -1.0 if up else 1.0
		draw_polyline(PackedVector2Array([c + Vector2(-w, -s * w * 0.45), c + Vector2(0, s * w * 0.45), c + Vector2(w, -s * w * 0.45)]), col, 3.0, true)

class Reticle extends HC:
	var hud
	var pulse_t = 0.0
	var pulse_col = Color.WHITE
	func _draw():
		var p = hud.player
		if p == null:
			return
		var s = p.snatch
		var c = size * 0.5
		var u = size.y / 720.0
		draw_circle(c, 2.5, Color(1, 1, 1, 0.75))
		var font = ThemeDB.fallback_font
		match s.hud_state:
			"slow":
				_brackets(s, Color(0.7, 0.7, 0.72, 0.8), "NEED  %d" % int(round(s.need_speed * GS.SPEED_UNIT)))
			"ok":
				_brackets(s, Color(1.0, 0.82, 0.35, 0.95), "")
			"eat":
				shadow(font, c + Vector2(-20, 46 * u), "EAT", int(18 * u), Color(1, 0.9, 0.6, 0.95), HORIZONTAL_ALIGNMENT_CENTER, 40)
			"locked", "flee":
				_rhythm(s)
		if s.flash != 0 and s.hud_state != "locked" and s.hud_state != "flee":
			var fc = Color(0.5, 1.0, 0.5, 0.9) if s.flash > 0 else Color(1.0, 0.35, 0.3, 0.9)
			draw_arc(c, 32.0 * u, 0, TAU, 40, fc, 3.0, true)
		if s.toast_t > 0.0 and s.toast != "":
			var a = clamp(s.toast_t / 0.4, 0.0, 1.0)
			shadow(font, c + Vector2(-150, 96 * u), s.toast, int(20 * u), Color(1, 1, 1, a), HORIZONTAL_ALIGNMENT_CENTER, 300)
		if s.note_t > 0.0 and s.note != "":
			var na = clamp(s.note_t / 1.0, 0.0, 1.0) * 0.55
			shadow(font, c + Vector2(-220, 124 * u), "(" + s.note + ")", int(14 * u), Color(1, 0.95, 0.85, na), HORIZONTAL_ALIGNMENT_CENTER, 440)
		if pulse_t > 0.0:
			var k = 1.0 - pulse_t / 0.7
			draw_arc(c, 20.0 + 80.0 * k, 0, TAU, 48, Color(pulse_col.r, pulse_col.g, pulse_col.b, 1.0 - k), 4.0, true)
	# the one fry the game is looking at: brackets sit ON it, so you can see which one will be judged
	func _brackets(s, col, label):
		var tgt = s.near_target
		if tgt == null or not is_instance_valid(tgt):
			return
		var cam = get_viewport().get_camera_3d()
		if cam == null:
			return
		var wp = tgt.aim_point()
		if cam.is_position_behind(wp):
			return
		var sp = cam.unproject_position(wp)
		if not Rect2(Vector2(24, 24), size - Vector2(48, 48)).has_point(sp):
			return
		var d = cam.global_position.distance_to(wp)
		var r = clamp(560.0 / max(d, 1.0), 22.0, 48.0)
		var l = r * 0.4
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				var corner = sp + Vector2(r * sx, r * sy)
				draw_line(corner, corner + Vector2(-l * sx, 0), col, 2.5)
				draw_line(corner, corner + Vector2(0, -l * sy), col, 2.5)
		if label != "":
			shadow(ThemeDB.fallback_font, sp + Vector2(-60, r + 20), label, 14, col, HORIZONTAL_ALIGNMENT_CENTER, 120)
	# THE RHYTHM. Each note is a white ring that shrinks through a THICK green ring (good) and then a THIN gold ring (perfect); inside
	# the gold ring there is nothing. Press E when the white ring is in a band. Gold = three places; diamond = five notes hopping between them.
	func _rhythm(s):
		var sq = s.seq
		if sq == null:
			return
		var cam = get_viewport().get_camera_3d()
		if cam == null:
			return
		var wp = sq["world"]
		var u = size.y / 720.0
		var fc = size * 0.5
		if not cam.is_position_behind(wp):
			fc = cam.unproject_position(wp)
		fc = Vector2(clamp(fc.x, 230.0 * u, size.x - 230.0 * u), clamp(fc.y, 150.0 * u, size.y - 190.0 * u))
		var font = ThemeDB.fallback_font
		var flee = sq["kind"] == "flee"
		var now = s.seq_now()
		var t = GS.msec() * 0.001
		var r_ge = 30.0 * u                                  # the ring's radius when the gold band ends
		var r_start = 108.0 * u
		var vpx = (r_start - r_ge) / max(sq["appr"], 0.2)    # pixels per second the white ring shrinks
		var sep = 152.0 * u
		var multi = sq["n"] > 1
		var gold_px = max(sq["gw"] * vpx, 3.0)
		var green_px = max(sq["gg"] * vpx, 5.0)
		for i in sq["notes"].size():
			var nt = sq["notes"][i]
			var spawn = nt["t"] - sq["appr"]
			if now < spawn - 0.01:
				continue
			var done = nt["res"] != ""
			var age = now - nt["res_t"] if done else 0.0
			if done and age > 0.5:
				continue
			var c = fc + Vector2(nt["slot"] * sep, 0.0) if multi else fc
			var fade = clamp((now - spawn) / 0.12, 0.0, 1.0)
			if done:
				fade *= clamp(1.0 - age / 0.5, 0.0, 1.0)
			var r_gold_in = r_ge
			var r_gold_out = r_ge + gold_px
			var r_green_out = r_gold_out + green_px
			var g_mid = (r_gold_out + r_green_out) * 0.5
			var o_mid = (r_gold_in + r_gold_out) * 0.5
			# the fry / gull marker
			draw_arc(c, r_ge * 0.55, 0, TAU, 24, Color(1, 1, 1, 0.35 * fade), 2.0, true)
			# THICK green ring, THIN gold ring just inside it. Nothing inside.
			draw_arc(c, g_mid, 0, TAU, 96, Color(RING_GREEN.r, RING_GREEN.g, RING_GREEN.b, 0.14 * fade), green_px + 8.0, true)
			draw_arc(c, g_mid, 0, TAU, 96, Color(RING_GREEN.r, RING_GREEN.g, RING_GREEN.b, 0.82 * fade), green_px, true)
			draw_arc(c, o_mid, 0, TAU, 96, Color(RING_GOLD.r, RING_GOLD.g, RING_GOLD.b, 0.25 * fade), gold_px + 6.0, true)
			draw_arc(c, o_mid, 0, TAU, 96, Color(RING_GOLD.r, RING_GOLD.g, RING_GOLD.b, fade), gold_px, true)
			# the shrinking white ring
			var tt = nt["res_t"] if done else now
			var r = r_ge + (nt["t"] - tt) * vpx
			if done:
				var rc2 = {"gold": RING_GOLD, "green": RING_GREEN, "miss": Color(1.0, 0.35, 0.3)}[nt["res"]]
				draw_arc(c, max(r, 4.0) + age * 60.0 * u, 0, TAU, 64, Color(rc2.r, rc2.g, rc2.b, fade), 4.0, true)
				if nt["res"] != "miss":
					draw_arc(c, r_green_out + age * 120.0 * u, 0, TAU, 64, Color(rc2.r, rc2.g, rc2.b, 0.6 * fade), 3.0, true)
				continue
			var dt = now - nt["t"]
			var zone = "none"
			if dt >= -sq["gw"] and dt <= 0.02:
				zone = "gold"
			elif dt >= -(sq["gw"] + sq["gg"]) and dt < -sq["gw"]:
				zone = "green"
			var rc = Color(1, 1, 1, 0.95 * fade)
			var rw = 3.0 * u
			if zone == "gold":
				rc = Color(1, 1, 1, 1.0).lerp(RING_GOLD, 0.5 + 0.5 * sin(t * 26.0))
				rw = 5.0 * u
			elif zone == "green":
				rw = 4.0 * u
				draw_arc(c, max(r, 4.0), 0, TAU, 72, Color(RING_GREEN.r, RING_GREEN.g, RING_GREEN.b, 0.28 * fade), 11.0 * u, true)
			elif dt > 0.02:
				rc = Color(1.0, 0.45, 0.4, 0.8 * fade)
			draw_arc(c, max(r, 4.0), 0, TAU, 72, rc, rw, true)
		# the note pips (what is already judged) + the key cap
		var top_y = fc.y - (r_start + 22.0 * u)
		var n = sq["n"]
		if n > 1:
			for i in n:
				var res = sq["notes"][i]["res"]
				var pc = Color(1, 1, 1, 0.25)
				if res == "gold":
					pc = RING_GOLD
				elif res == "green":
					pc = RING_GREEN
				elif res == "miss":
					pc = Color(1.0, 0.35, 0.3)
				var px = fc.x + (i - (n - 1) * 0.5) * 22.0 * u
				draw_circle(Vector2(px, top_y), 6.0 * u, pc)
				draw_arc(Vector2(px, top_y), 6.0 * u, 0, TAU, 16, Color(0, 0, 0, 0.5), 1.5)
		if flee:
			shadow(font, Vector2(fc.x - 140, top_y - 12.0 * u), "SLIP THE SWING!", int(22 * u), Color(1.0, 0.55, 0.45, 0.65 + 0.35 * sin(t * 12.0)), HORIZONTAL_ALIGNMENT_CENTER, 280)
		var kc = Vector2(fc.x, min(fc.y + r_start + 30.0 * u, size.y - 56.0 * u))
		var cap_col = Color(0.1, 0.1, 0.14, 0.78)
		var cap_txt = Color(1, 1, 1, 0.9)
		draw_rect(Rect2(kc + Vector2(-17, -17) * u, Vector2(34, 34) * u), cap_col)
		draw_rect(Rect2(kc + Vector2(-17, -17) * u, Vector2(34, 34) * u), Color(1, 1, 1, 0.9), false, 2.0)
		draw_string(font, kc + Vector2(-17 * u, 9.0 * u), "E", HORIZONTAL_ALIGNMENT_CENTER, 34 * u, int(24 * u), cap_txt)

# TOP-RIGHT under the stamina bar: a racing tachometer. Segments climb from low yellow ones to tall red ones; the speed in big numbers below.
# A white tick marks the top speed you can reach right now (red fries move it), a small caret marks the speed the fry in view needs.
class Tach extends HC:
	var hud
	var shown = 0.0
	const N = 26
	const VMAX = 160.0
	func _seg_col(i):
		var t = float(i) / float(N - 1)
		if t < 0.45:
			return Color(1.0, 0.9, 0.22).lerp(Color(1.0, 0.62, 0.14), t / 0.45)
		return Color(1.0, 0.62, 0.14).lerp(Color(0.96, 0.16, 0.1), (t - 0.45) / 0.55)
	func _draw():
		var p = hud.player
		if p == null:
			return
		var s = p.snatch
		var font = ThemeDB.fallback_font
		var u = size.y / 720.0
		var spd = p.speed * GS.SPEED_UNIT
		shown = lerp(shown, spd, 0.3)
		var seg_w = 7.2 * u
		var gap = 2.6 * u
		var total_w = N * (seg_w + gap) - gap
		var x1 = size.x - 26.0 * u
		var x0 = x1 - total_w
		var yb = 134.0 * u
		var lit = clamp(shown / VMAX, 0.0, 1.0) * N
		var t = GS.msec() * 0.001
		var maxv = GS.boost_speed() * GS.SPEED_UNIT
		var hot = p.boosting and shown > maxv * 0.92
		for i in N:
			var k = float(i) / float(N - 1)
			var h = (7.0 + 30.0 * pow(k, 1.25)) * u
			var x = x0 + i * (seg_w + gap)
			var col = _seg_col(i)
			draw_rect(Rect2(x, yb - h, seg_w, h), Color(0, 0, 0, 0.42))
			var f = clamp(lit - i, 0.0, 1.0)
			if f > 0.0:
				var jit = 0.0
				if hot and i > N - 7:
					jit = sin(t * 60.0 + i) * 1.2 * u
				draw_rect(Rect2(x, yb - h * f + jit, seg_w, h * f), col)
				if hot and i > N - 5:
					draw_rect(Rect2(x - 1, yb - h * f - 1 + jit, seg_w + 2, 3), Color(1, 1, 1, 0.55 + 0.4 * sin(t * 40.0)))
		# the top speed available now
		var mx = x0 + clamp(maxv / VMAX, 0.0, 1.0) * (total_w - seg_w) + seg_w * 0.5
		draw_colored_polygon(PackedVector2Array([Vector2(mx - 4 * u, yb + 4 * u), Vector2(mx + 4 * u, yb + 4 * u), Vector2(mx, yb - 2 * u)]), Color(1, 1, 1, 0.8))
		# the speed the fry in view needs
		var nt0 = s.near_target
		if nt0 != null and is_instance_valid(nt0) and nt0.ftype != "ordinary":
			var need = s.need_speed * GS.SPEED_UNIT
			var nx = x0 + clamp(need / VMAX, 0.0, 1.0) * (total_w - seg_w) + seg_w * 0.5
			var tc = Color("5FC8F5")
			if s.need_tier <= 4:
				tc = GS.RARITY_COLORS[clamp(s.need_tier, 0, 4)]
			var ok = spd >= need - 0.2 and p.mode == 0
			draw_line(Vector2(nx, yb - 44 * u), Vector2(nx, yb + 2 * u), Color(tc.r, tc.g, tc.b, 1.0 if ok else 0.8), 3.0 if ok else 2.0)
			shadow(font, Vector2(nx - 30 * u, yb - 48 * u), "%d" % int(round(need)), int(13 * u), Color(tc.r, tc.g, tc.b, 0.95), HORIZONTAL_ALIGNMENT_CENTER, 60 * u)
		# the number
		var ncol = Color(1, 0.97, 0.85, 0.98)
		if hot:
			ncol = Color(1.0, 0.45 + 0.3 * sin(t * 30.0), 0.25)
		shadow(font, Vector2(x1 - 160 * u, yb + 36 * u), str(int(round(spd))), int(34 * u), ncol, HORIZONTAL_ALIGNMENT_RIGHT, 160 * u)
		shadow(font, Vector2(x1 - 160 * u, yb + 52 * u), "SPEED", int(11 * u), Color(1, 1, 1, 0.5), HORIZONTAL_ALIGNMENT_RIGHT, 160 * u)

class Vignette extends Control:
	var hud
	var tex
	func _ready():
		var g = Gradient.new()
		g.set_color(0, Color(0, 0, 0, 0))
		g.add_point(0.55, Color(0, 0, 0, 0.05))
		g.set_color(2, Color(0.02, 0.04, 0.1, 0.78))
		tex = GradientTexture2D.new()
		tex.gradient = g
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.05, 0.5)
		tex.width = 256
		tex.height = 256
	func _draw():
		var a = hud.focus_a
		if a <= 0.01:
			return
		draw_texture_rect(tex, Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, a))
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.35, 0.5, 0.8, 0.07 * a))

# World-to-screen pointers: the first fries ("where is it?") in gold, and the faint "go back there" hint for the plain fry.
class Guide extends HC:
	var hud
	func _draw():
		if hud.guide_pos != null:
			_one(hud.guide_pos, "FRY", Color(1.0, 0.82, 0.3, 0.95), 1.0)
		if hud.hint_pos != null:
			_one(hud.hint_pos, hud.hint_text, Color(1.0, 0.9, 0.7, 0.8), 0.55)
	func _one(pos, label0, gold, alpha):
		var cam = get_viewport().get_camera_3d()
		if cam == null:
			return
		var font = ThemeDB.fallback_font
		var wp = pos + Vector3(0, 0.9, 0)
		var t = GS.msec() * 0.001
		var behind = cam.is_position_behind(wp)
		var sp = cam.unproject_position(wp)
		var dist = cam.global_position.distance_to(pos)
		var rect = Rect2(Vector2(70, 110), size - Vector2(140, 220))
		var label = "%s  %dm" % [label0, int(dist)]
		gold.a *= alpha
		if (not behind) and rect.has_point(sp):
			var bob = sin(t * 4.0) * 6.0
			var tip = sp + Vector2(0, -26.0 + bob)
			draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-13, -22), tip + Vector2(13, -22)]), gold)
			shadow(font, tip + Vector2(-90, -30), label, 18, Color(1, 0.95, 0.75, 0.95 * alpha), HORIZONTAL_ALIGNMENT_CENTER, 180)
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
			var pos2 = rect.position + half + dir * min(kx, ky)
			var n = Vector2(-dir.y, dir.x)
			var pulse = 1.0 + 0.12 * sin(t * 5.0)
			draw_colored_polygon(PackedVector2Array([pos2 + dir * 20.0 * pulse, pos2 - dir * 12.0 + n * 16.0, pos2 - dir * 12.0 - n * 16.0]), gold)
			shadow(font, pos2 - dir * 30.0 + Vector2(-70, 6), label, 16, Color(1, 0.95, 0.75, 0.95 * alpha), HORIZONTAL_ALIGNMENT_CENTER, 140)

class Status extends HC:
	var hud
	func _draw():
		var p = hud.player
		if p == null:
			return
		var font = ThemeDB.fallback_font
		var w = size.x
		var ic = Vector2(w - 28, 28)
		draw_circle(ic, 11, Color(0.95, 0.95, 0.92, 0.95))
		draw_colored_polygon(PackedVector2Array([ic + Vector2(-10, 1), ic + Vector2(-20, 4), ic + Vector2(-10, 6)]), Color("F2A22E"))
		draw_circle(ic + Vector2(-4, -3), 1.8, Color(0.1, 0.1, 0.12))
		var ratio = clamp(1.0 - p.roll_cd / max(GS.roll_cooldown(), 0.1), 0.0, 1.0)
		draw_arc(ic, 20, -PI / 2, -PI / 2 + TAU, 40, Color(0, 0, 0, 0.35), 3.0, true)
		draw_arc(ic, 20, -PI / 2, -PI / 2 + TAU * ratio, 40, GOLD if ratio >= 1.0 else Color(0.7, 0.7, 0.7, 0.8), 3.0, true)
		if p.soaked_t > 0.0:
			draw_circle(ic + Vector2(14, 14), 4.0, Color(0.4, 0.7, 1.0, 0.9))
		var smax = GS.stamina_max()
		var bar_w = 110.0 + smax * 0.9
		var bx = w - 62 - bar_w
		draw_rect(Rect2(bx, 20, bar_w, 12), Color(0, 0, 0, 0.4))
		var col = Color(0.98, 0.93, 0.78, 0.95)
		if p.boosting:
			col = Color(1.0, 0.82, 0.35, 1.0)
		elif GS.sense_active:
			col = Color(0.6, 0.85, 1.0, 1.0)
		elif p.regen_active and p.mode == 1:
			col = Color(0.65, 0.95, 0.6, 1.0)
		if p.low_stamina:
			var pl = 0.5 + 0.5 * sin(GS.msec() * 0.008)
			col = Color(1.0, 0.55 + 0.2 * pl, 0.3, 0.7 + 0.3 * pl)
		draw_rect(Rect2(bx, 20, bar_w * p.stamina / smax, 12), col)
		if p.boost_locked:
			draw_rect(Rect2(bx, 20, bar_w * 15.0 / smax, 12), Color(1, 0.3, 0.2, 0.25))
		# CROWD WATCH: how closely the people around you are looking. More eyes = thinner timing bands.
		var wv = GS.watch
		var wc = Color(0.55, 0.92, 0.55)
		if wv >= 3.0:
			wc = Color(1.0, 0.35, 0.3)
		elif wv >= 2.0:
			wc = Color(1.0, 0.6, 0.3)
		elif wv >= 1.0:
			wc = Color(0.98, 0.88, 0.4)
		shadow(font, Vector2(bx, 50), "CROWD", 12, Color(1, 1, 1, 0.7))
		var filled = clamp(wv / 4.0, 0.0, 1.0) * 8.0
		for i in 8:
			var pa = clamp(filled - i, 0.0, 1.0)
			var pr = Rect2(bx + 50 + i * 13, 41, 10, 10)
			draw_rect(pr, Color(1, 1, 1, 0.15))
			if pa > 0.0:
				draw_rect(Rect2(pr.position, Vector2(10 * pa, 10)), wc)
		shadow(font, Vector2(bx + 158, 50), GS.watch_label(), 12, Color(wc.r, wc.g, wc.b, 0.95))
		# a drink in effect: a little bar that runs down
		if GS.drink != "":
			var dc = Color("F0A040") if GS.drink == "coffee" else Color("C86AE0")
			var nm = "COFFEE  -  FAST" if GS.drink == "coffee" else "DIZZY  -  SLOW"
			shadow(font, Vector2(bx, 72), nm, 13, dc)
			draw_rect(Rect2(bx + 120, 62, 70, 8), Color(0, 0, 0, 0.4))
			draw_rect(Rect2(bx + 120, 62, 70.0 * clamp(GS.drink_t / 15.0, 0.0, 1.0), 8), dc)
		elif GS.has["blue"]:
			shadow(font, Vector2(bx, 70), "ALT %d" % int(p.global_position.y), 13, Color(1, 1, 1, 0.75))

# TOP-LEFT: the half-rainbow of fries. Eight bands around the top-left corner: the three yellow starter fries, then one band per colour
# (silver / gold / diamond fill it, a third each). Each band is a row of little fries standing on the arc. Below it, the tiny mission board.
class Arc extends HC:
	var hud
	var lit_t = {}
	var was = {}
	const STICKS = 12
	func _band_tiers(i):
		if i == 0:
			return [min(GS.gull_sense_count, 3), Color("F1C94B")]
		var k = GS.FRY_TYPES[i - 1]
		return [GS.lv[k], GS.TYPE_COLORS[k]]
	func band_pos(i, frac, u):
		var r = (60.0 + i * 19.0) * u
		var a = deg_to_rad(8.0 + 74.0 * frac)
		return Vector2(cos(a), sin(a)) * r
	func _draw():
		var p = hud.player
		if p == null:
			return
		var u = size.y / 720.0
		var font = ThemeDB.fallback_font
		var rows = 8 if hud.slots_visible else 1
		var dt = get_process_delta_time() / max(Engine.time_scale, 0.1)
		for i in rows:
			var bt = _band_tiers(i)
			var n = bt[0]
			var col = bt[1]
			var key = "b%d" % i
			if n > was.get(key, 0):
				lit_t[key] = 0.0
			was[key] = n
			if lit_t.has(key):
				lit_t[key] += dt
			var fl = clamp(1.0 - lit_t.get(key, 9.0) / 0.9, 0.0, 1.0)
			var r = (60.0 + i * 19.0) * u
			var lit_n = int(round(float(n) / 3.0 * STICKS))
			for j in STICKS:
				var a = deg_to_rad(8.0 + 74.0 * (float(j) + 0.5) / STICKS)
				var d = Vector2(cos(a), sin(a))
				var c0 = d * r
				var lit = j < lit_n
				var cc = col if lit else Color(col.r, col.g, col.b, 0.2)
				if lit:
					cc = cc.lerp(Color(1, 1, 1), 0.35 * fl)
				# a fry: a short thick stick standing along the radius, a lighter tip
				draw_line(c0 - d * 8.5 * u, c0 + d * 8.5 * u, Color(0, 0, 0, 0.45 if lit else 0.25), 7.5 * u)
				draw_line(c0 - d * 8.0 * u, c0 + d * 8.0 * u, cc, 6.0 * u)
				if lit:
					draw_line(c0 + d * 4.0 * u, c0 + d * 8.0 * u, Color(1, 0.96, 0.8, 0.9), 6.0 * u)
			# the rainbow count: a tiny "+3" at the top-edge end
			if i > 0 and GS.rainbow[GS.FRY_TYPES[i - 1]] > 0:
				var rb_ = GS.rainbow[GS.FRY_TYPES[i - 1]]
				var tp = Vector2(r + 11.0 * u, 12.0 * u)
				shadow(font, tp, "+%d" % rb_, int(10 * u), Color(1.0, 0.7, 0.95, 0.95))
		# the fries flying into their bands
		var i2 = 0
		while i2 < hud.gains.size():
			var g = hud.gains[i2]
			g["t"] += dt
			var u2 = clamp(g["t"] / 0.8, 0.0, 1.0)
			var band = 0 if g["type"] == "tutorial" else GS.FRY_TYPES.find(g["type"]) + 1
			var frac = clamp(float(g.get("slot", 0)) / 3.0 + 0.16, 0.0, 1.0)
			var target = band_pos(band, frac, u)
			var from = size * 0.5
			var e = u2 * u2 * (3.0 - 2.0 * u2)
			var mid = from.lerp(target, 0.5) + Vector2(60.0 * u, 90.0 * u)
			var pos = from.lerp(mid, e).lerp(mid.lerp(target, e), e)
			var col2 = Color("F1C94B") if g["type"] == "tutorial" else GS.TYPE_COLORS[g["type"]]
			var rs = (1.0 - e * 0.5) * 11.0 * u
			draw_circle(pos, rs * 1.8, Color(col2.r, col2.g, col2.b, 0.25 * (1.0 - u2)))
			draw_line(pos - Vector2(0, rs), pos + Vector2(0, rs), col2, 6.0 * u)
			draw_line(pos + Vector2(0, rs * 0.3), pos + Vector2(0, rs), Color(1, 0.96, 0.8), 6.0 * u)
			if g["t"] > 1.0:
				hud.gains.remove_at(i2)
			else:
				i2 += 1
		# the little name tag
		var pl = hud.plate
		if pl != null:
			pl["t"] += dt
			var a2 = clamp(min(pl["t"] / 0.25, (2.8 - pl["t"]) / 0.5), 0.0, 1.0)
			if pl["t"] > 2.8:
				hud.plate = null
			else:
				var col3 = Color("F1C94B") if pl["type"] == "tutorial" else GS.TYPE_COLORS[pl["type"]]
				var rc = GS.RARITY_COLORS[clamp(pl["tier"], 0, 4)]
				var px = 14.0 * u + (1.0 - a2) * -30.0 * u
				var py = 214.0 * u
				draw_rect(Rect2(px, py, 250.0 * u, 40.0 * u), Color(0.04, 0.05, 0.09, 0.68 * a2))
				draw_rect(Rect2(px, py, 5.0 * u, 40.0 * u), Color(col3.r, col3.g, col3.b, a2))
				shadow(font, Vector2(px + 12.0 * u, py + 17.0 * u), pl["name"], int(15 * u), Color(1, 1, 1, a2))
				shadow(font, Vector2(px + 12.0 * u, py + 33.0 * u), pl["line"], int(11 * u), Color(rc.r, rc.g, rc.b, 0.95 * a2))
				if pl["tier"] >= 1:
					shadow(font, Vector2(px + 148.0 * u, py + 17.0 * u), GS.RARITY_NAMES[clamp(pl["tier"], 0, 4)], int(12 * u), Color(rc.r, rc.g, rc.b, a2), HORIZONTAL_ALIGNMENT_RIGHT, 90.0 * u)
		# the mission board: small, faint, two lines and a hint
		var my = 268.0 * u if hud.plate != null else 224.0 * u
		var mx = 16.0 * u
		var tgt = GS.mission_target()
		var tot = GS.fry_total()
		var line1 = ""
		if tgt < 0:
			line1 = "ALL %d FRIES   %d / %d" % [GS.FRY_CAP, GS.FRY_CAP, GS.FRY_CAP]
		elif tgt == 3:
			line1 = "GET 3 VISION FRIES   %d / 3" % tot
		else:
			line1 = "GET %d FRIES   %d / %d" % [tgt, tot, tgt]
		var c1 = Color(0.75, 1.0, 0.75, 0.8) if tgt < 0 else Color(1, 0.96, 0.82, 0.8)
		draw_rect(Rect2(mx - 6.0 * u, my - 14.0 * u, 3.0 * u, 34.0 * u), Color(1, 1, 1, 0.2))
		shadow(font, Vector2(mx, my), line1, int(13 * u), c1)
		shadow(font, Vector2(mx, my + 17.0 * u), "NO LONGER HUNGRY   0 / 1", int(13 * u), Color(1.0, 0.82, 0.7, 0.72))
		var hint = ""
		for h in MISSION_HINTS:
			if tot >= h[0]:
				hint = h[1]
		shadow(font, Vector2(mx, my + 34.0 * u), hint, int(11 * u), Color(1, 1, 1, 0.42))

class Streaks extends Control:
	var hud
	var seeds = []
	func _ready():
		for i in 30:
			seeds.append([randf() * TAU, randf(), randf()])
	func _draw():
		var p = hud.player
		if p == null:
			return
		var n = clamp((p.speed - 14.0) / 10.0, 0.0, 1.0)
		if n <= 0.02:
			return
		var c = size * 0.5
		var t = GS.msec() * 0.001
		for s in seeds:
			var ang = s[0]
			var ph = fmod(t * (1.2 + s[2]) + s[1], 1.0)
			var r0 = size.length() * (0.30 + 0.14 * ph)
			var r1 = r0 + size.length() * (0.06 + 0.1 * n) * (0.4 + s[2])
			var d = Vector2(cos(ang), sin(ang))
			draw_line(c + d * r0, c + d * r1, Color(1, 1, 1, 0.22 * n * (1.0 - ph)), 2.0)
		var vg = clamp((p.speed - 17.0) / 9.0, 0.0, 1.0) * 0.14
		if vg > 0.01:
			draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.06)), Color(0, 0, 0, vg))
			draw_rect(Rect2(Vector2(0, size.y * 0.94), Vector2(size.x, size.y * 0.06)), Color(0, 0, 0, vg))

class Bars extends Control:
	var hud
	func _draw():
		var h = size.y * 0.11 * hud.lb
		if h > 0.5:
			draw_rect(Rect2(0, 0, size.x, h), Color(0, 0, 0, 1))
			draw_rect(Rect2(0, size.y - h, size.x, h), Color(0, 0, 0, 1))

# ---------------------------------------------------------------- build
func _lbl(text, sz, col = Color(1, 1, 1), outline = 6):
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	l.add_theme_constant_override("outline_size", outline)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _full(c):
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready():
	layer = 5
	ui_root = Control.new()
	_full(ui_root)
	add_child(ui_root)
	vignette = Vignette.new()
	vignette.hud = self
	_full(vignette)
	ui_root.add_child(vignette)
	vision = Vision.new()
	vision.hud = self
	_full(vision)
	vision.visible = false
	ui_root.add_child(vision)
	streaks = Streaks.new()
	streaks.hud = self
	_full(streaks)
	ui_root.add_child(streaks)
	guide = Guide.new()
	guide.hud = self
	_full(guide)
	ui_root.add_child(guide)
	reticle = Reticle.new()
	reticle.hud = self
	_full(reticle)
	ui_root.add_child(reticle)
	gauge = Tach.new()
	gauge.hud = self
	_full(gauge)
	ui_root.add_child(gauge)
	comic = ComicPop.new()
	_full(comic)
	ui_root.add_child(comic)
	var top = VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top.anchor_left = 0.0
	top.anchor_right = 1.0
	top.offset_top = 28
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("separation", 2)
	ui_root.add_child(top)
	objective_title = _lbl("", 30)
	objective_count = _lbl("", 24, GOLD)
	top.add_child(objective_title)
	top.add_child(objective_count)
	arc = Arc.new()
	arc.hud = self
	_full(arc)
	ui_root.add_child(arc)
	status = Status.new()
	status.hud = self
	status.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	status.offset_left = -520
	status.offset_right = -28
	status.offset_top = 14
	status.offset_bottom = 90
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(status)
	center_msg = _lbl("", 54, Color(1, 0.95, 0.8), 10)
	center_msg.anchor_left = 0.0
	center_msg.anchor_right = 1.0
	center_msg.anchor_top = 0.3
	center_msg.anchor_bottom = 0.3
	center_msg.modulate.a = 0.0
	ui_root.add_child(center_msg)
	small_msg = _lbl("", 22, Color(1, 1, 1), 5)
	small_msg.anchor_left = 0.0
	small_msg.anchor_right = 1.0
	small_msg.anchor_top = 0.58
	small_msg.anchor_bottom = 0.58
	small_msg.modulate.a = 0.0
	ui_root.add_child(small_msg)
	hint_label = _lbl("", 22, Color(1, 0.96, 0.85), 6)
	hint_label.anchor_left = 0.0
	hint_label.anchor_right = 1.0
	hint_label.anchor_top = 0.86
	hint_label.anchor_bottom = 0.86
	hint_label.modulate.a = 0.0
	ui_root.add_child(hint_label)
	whisper_label = _lbl("", 17, Color(1, 0.96, 0.88), 4)
	whisper_label.anchor_left = 0.0
	whisper_label.anchor_right = 1.0
	whisper_label.anchor_top = 0.93
	whisper_label.anchor_bottom = 0.93
	whisper_label.modulate.a = 0.0
	ui_root.add_child(whisper_label)
	prompt_label = _lbl("", 26, Color(1, 0.96, 0.8), 8)
	prompt_label.anchor_left = 0.0
	prompt_label.anchor_right = 1.0
	prompt_label.anchor_top = 0.80
	prompt_label.anchor_bottom = 0.80
	prompt_label.modulate.a = 0.0
	ui_root.add_child(prompt_label)
	toast_box = PanelContainer.new()
	toast_box.anchor_left = 1.0
	toast_box.anchor_right = 1.0
	toast_box.anchor_top = 1.0
	toast_box.anchor_bottom = 1.0
	toast_box.offset_left = -300
	toast_box.offset_right = -24
	toast_box.offset_top = -86
	toast_box.offset_bottom = -30
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tsb = StyleBoxFlat.new()
	tsb.bg_color = Color(0.08, 0.09, 0.12, 0.8)
	tsb.set_corner_radius_all(8)
	tsb.set_border_width_all(2)
	tsb.border_color = GOLD
	tsb.content_margin_left = 14
	tsb.content_margin_right = 14
	tsb.content_margin_top = 6
	tsb.content_margin_bottom = 6
	toast_box.add_theme_stylebox_override("panel", tsb)
	toast_label = _lbl("", 20, GOLD, 0)
	toast_box.add_child(toast_label)
	toast_box.modulate.a = 0.0
	ui_root.add_child(toast_box)
	bars = Bars.new()
	bars.hud = self
	_full(bars)
	add_child(bars)
	fade_rect = ColorRect.new()
	fade_rect.color = Color(1, 1, 1, 0)
	_full(fade_rect)
	add_child(fade_rect)
	ending_fry = _lbl("FRY", 96, Color(1, 0.96, 0.85), 12)
	ending_fry.anchor_left = 0.0
	ending_fry.anchor_right = 1.0
	ending_fry.anchor_top = 0.16
	ending_fry.anchor_bottom = 0.16
	ending_fry.modulate.a = 0.0
	add_child(ending_fry)
	ending_text = _lbl("Tastes good.", 28, Color(1, 0.96, 0.85), 6)
	ending_text.anchor_left = 0.0
	ending_text.anchor_right = 1.0
	ending_text.anchor_top = 0.3
	ending_text.anchor_bottom = 0.3
	ending_text.modulate.a = 0.0
	add_child(ending_text)
	GS.gull_sense_changed.connect(_on_gull_sense)
	GS.progress_changed.connect(_on_progress)
	GS.achievement.connect(_on_achievement)
	GS.player_hurt.connect(_on_hurt)
	GS.fry_got.connect(_on_fry_got)
	GS.comic.connect(func(cid, cap, extra): show_comic(cid, cap, 2.8, extra))
	reset_ui()

func reset_ui():
	collected = {}
	slots_visible = false
	gains = []
	plate = null
	objective_title.text = ""
	objective_count.text = ""

func _process(delta):
	if player == null:
		return
	if reticle.pulse_t > 0.0:
		reticle.pulse_t = max(reticle.pulse_t - delta, 0.0)
	var real_dt = delta / max(Engine.time_scale, 0.05)
	lb = lerp(lb, player.snatch.letterbox, 1.0 - exp(-14.0 * real_dt))
	var focusing = (player.snatch.lock_fry != null and player.snatch.state == "idle") or player.snatch.state == "cine" or player.snatch.state == "flee"
	focus_a = move_toward(focus_a, 1.0 if focusing else 0.0, 5.0 * real_dt)
	var pa = 1.0 if prompt_text != "" else 0.0
	prompt_label.modulate.a = move_toward(prompt_label.modulate.a, pa, 4.0 * real_dt)
	if prompt_text != "" and prompt_label.text != prompt_text:
		prompt_label.text = prompt_text
	# during focus the middle of the screen is busy: the instruction moves up under the title
	var ay = 0.21 if (player.snatch.lock_fry != null or player.snatch.state == "flee") else 0.82
	if abs(prompt_label.anchor_top - ay) > 0.001:
		prompt_label.anchor_top = ay
		prompt_label.anchor_bottom = ay
	vignette.queue_redraw()
	guide.queue_redraw()
	reticle.queue_redraw()
	gauge.queue_redraw()
	status.queue_redraw()
	arc.queue_redraw()
	streaks.queue_redraw()
	bars.queue_redraw()

# ---------------------------------------------------------------- messages
func _show_center(text, hold = 1.4, size = 54):
	center_msg.text = text
	center_msg.add_theme_font_size_override("font_size", size)
	if msg_tween:
		msg_tween.kill()
	center_msg.scale = Vector2(0.85, 0.85)
	center_msg.pivot_offset = Vector2(center_msg.size.x * 0.5, 30)
	msg_tween = create_tween()
	msg_tween.tween_property(center_msg, "modulate:a", 1.0, 0.15)
	msg_tween.parallel().tween_property(center_msg, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	msg_tween.tween_interval(hold)
	msg_tween.tween_property(center_msg, "modulate:a", 0.0, 0.5)

# persistent prompt (stays until cleared) - used by the first-fry tutorial director in main.gd
func set_prompt(text):
	prompt_text = text

func hint(key, text, sec = 3.5):
	if hint_shown.has(key):
		return
	hint_shown[key] = true
	hint_label.text = text
	if hint_tween:
		hint_tween.kill()
	hint_tween = create_tween()
	hint_tween.tween_property(hint_label, "modulate:a", 1.0, 0.3)
	hint_tween.tween_interval(sec)
	hint_tween.tween_property(hint_label, "modulate:a", 0.0, 0.6)

# faint small print: story whispers and gentle "why did that happen" notes
func whisper(text, sec = 5.0):
	whisper_label.text = text
	if whisper_tween:
		whisper_tween.kill()
	whisper_tween = create_tween().set_ignore_time_scale(true)
	whisper_tween.tween_property(whisper_label, "modulate:a", 0.62, 0.8)
	whisper_tween.tween_interval(sec)
	whisper_tween.tween_property(whisper_label, "modulate:a", 0.0, 1.2)

func show_comic(id, caption, hold = 2.8, extra = {}):
	var now = GS.msec() / 1000.0
	if last_comic["id"] == id and now - last_comic["t"] < 1.5:
		return
	last_comic = {"id": id, "t": now}
	comic.show_comic(id, caption, hold, extra)

func _on_hurt(kind, lost):
	flash_screen(Color(1.0, 0.25, 0.2), 0.18, 0.45)
	var caps = HURT_CAPTIONS.get(kind, ["OUCH."])
	var cap = caps[randi() % caps.size()]
	show_comic("hit_" + kind, cap, 3.0, {})
	if lost:
		whisper("the fry hit the floor. it's gone.", 3.0)

func _on_achievement(title):
	toast_queue.append(title)
	if not toast_busy:
		_next_toast()

func _next_toast():
	if toast_queue.is_empty():
		toast_busy = false
		return
	toast_busy = true
	toast_label.text = toast_queue.pop_front()
	var tw = create_tween()
	tw.tween_property(toast_box, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.0)
	tw.tween_property(toast_box, "modulate:a", 0.0, 0.5)
	tw.tween_callback(_next_toast)

func _on_gull_sense(n):
	if n < 3:
		_show_center("%d / 3" % n, 0.8, 44)
	else:
		_show_center("GULL SIGHT UNLOCKED", 2.0, 50)
		get_tree().create_timer(1.2, true, false, true).timeout.connect(reveal_specials)

func reveal_specials():
	slots_visible = true
	objective_title.text = ""
	objective_count.text = ""

func _on_progress(cur, _target):
	if cur >= GS.TOTAL_BASE:
		get_tree().create_timer(1.8, true, false, true).timeout.connect(still_hungry)

func still_hungry():
	objective_count.text = ""
	objective_title.text = "STILL HUNGRY."
	objective_title.add_theme_font_size_override("font_size", 44)
	var tw = create_tween()
	tw.tween_interval(3.2)
	tw.tween_property(objective_title, "modulate:a", 0.0, 1.5)
	tw.tween_callback(func():
		objective_title.text = ""
		objective_title.modulate.a = 1.0
		objective_title.add_theme_font_size_override("font_size", 30))

# the light "you got a fry" moment (never pauses): the fry flies into its slot of the rainbow, a small tag fades in
func _on_fry_got(type, tier):
	var slot = 0
	if type == "tutorial":
		slot = clamp(GS.gull_sense_count - 1, 0, 2)
	elif tier >= 1 and tier <= 3:
		slot = tier - 1
	elif tier >= 4:
		slot = 2
	gains.append({"type": type, "tier": tier, "t": 0.0, "slot": slot})
	var nm = ""
	var ln = ""
	if type == "tutorial":
		nm = ["CORNER TABLE FRY", "SEASIDE PLATE FRY", "HOT HANDHELD FRY"][clamp(GS.gull_sense_count - 1, 0, 2)]
		ln = "VISION FRY   %d / 3" % GS.gull_sense_count
	elif tier >= 4:
		nm = GS.fry_name(type, 4)
		ln = GS.rainbow_text(type)
	else:
		nm = GS.fry_name(type, tier)
		ln = GS.STAT_NAMES[type] + "   " + GS.ability_text(type, tier).split("   -   ")[0]
	plate = {"type": type, "tier": tier, "name": nm, "line": ln, "t": 0.0}

func collect_special(key):
	collected[key] = true
	reticle.pulse_col = GS.TYPE_COLORS[key] if GS.TYPE_COLORS.has(key) else Color("F1C94B")
	reticle.pulse_t = 0.7

func flash_screen(col, a, sec):
	fade_rect.color = Color(col.r, col.g, col.b, a)
	var tw = create_tween()
	tw.tween_property(fade_rect, "color:a", 0.0, sec)

func ending_sequence():
	var tw = create_tween()
	tw.tween_property(ui_root, "modulate:a", 0.0, 2.5)
	var t2 = create_tween()
	t2.tween_interval(0.9)
	t2.tween_property(ending_fry, "modulate:a", 1.0, 1.4)
	t2.tween_interval(0.5)
	t2.tween_property(ending_text, "modulate:a", 1.0, 1.4)
	t2.tween_interval(8.0)
	t2.tween_property(ending_fry, "modulate:a", 0.0, 3.0)
	t2.parallel().tween_property(ending_text, "modulate:a", 0.0, 3.0)
