extends CanvasLayer
# HUD (round 5, "less but clearer"): stamina + crowd WATCH (top right) with the racing-style SPEED TACH under it, the rhythm rings
# around the fry, the half-rainbow of fries (top-left) with a tiny mission board, Gull Sight overlay, lower-left comic panel,
# close-up letterbox, hints, achievement toasts, Still Hungry, ending.
# The "you got a fry" moment is light: the fry flies into its slot of the rainbow and a small name tag fades in. Nothing pauses.

const ComicPop = preload("res://scripts/ui/comic_pop.gd")
const Vision = preload("res://scripts/ui/vision_overlay.gd")
const FishArt = preload("res://scripts/ui/fish_art.gd")

const COMMON_FRY = Color("F6C453")
const GOLD = Color("F5C65A")
const RING_GREEN = Color(0.32, 0.92, 0.42)
const RING_ORANGE = Color(1.0, 0.52, 0.12)
const RING_BLUE = Color(0.3, 0.55, 1.0)
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

# where / how to do each side task (the line under the task that is "up next")
const QUEST_HINTS = {
	"star": "coffee + cocktail + ice cream running together: the best flying there is",
	"drink": "a cup or a cone in somebody's hand: take it",
	"wear": "hats, scarves, balloons: things strangers carry",
	"fish": "fish leap where the water bubbles",
	"rainbow": "a passer-by far from town holds one",
	"fishbook": "nine kinds of fish, three sizes of luck",
	"sky": "a cloud, a star, the moon, the sun, a rainbow: you need RAINBOW TIME",
}
# the mission board's small print: [fries needed, line]
const MISSION_HINTS = [
	[0, "the old man's table is a good start."],
	[3, "hold TAB. see what glows."],
	[6, "fries glow in colours. the colours mean things."],
	[10, "you are strong now. where do you think you are headed?"],
	[17, "you were going to get some fries. on the pier."],
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
var film_clean = false              # the trailer: no task board over the picture
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
var gains = []                  # the "you got a fry" moments: {type, tier, t, slot, name, line, rarity, dur}
var banner
var quiet_t = 0.0
var quiet_bar = 0.0              # a finished quest: every bit of UI fades away for a few seconds (and the black bars come in)
var quiet_label
var quiet_back
var quiet_lines = []
var starfx
var fishcard
var lesson_ui
var coach_ui
var clock_ui
var coach = null                  # round 18: the first-fry coach (main.gd `_coach_tick` fills it in): {show, step, steps, line}
var skypop
var achui
var lesson_line = ""            # what the TAB lesson says while Gull Sight is held (main.gd fills it in)
var lesson_done_t = 0.0
var lesson_idle = 0.0
var sky_pops = []               # {kind, n, t}
var ach_toasts = []             # {id, t}
const SKY_COL = {"cloud": Color("EAF2FF"), "raincloud": Color("A9BBD6"), "star": Color("FFE27A"), "moon": Color("9FD2FF"), "sun": Color("FFD66B"), "rainbow": Color("FF9AD0")}
const SKY_WORD = {"cloud": "CLOUD!", "raincloud": "RAIN CLOUD!", "star": "STAR!", "moon": "MOON!", "sun": "SUN!", "rainbow": "RAINBOW!"}
var fish_cards = []              # the "you caught a fish" cards: {info, t}

# ---------------------------------------------------------------- inner draw classes
class HC extends Control:
	func shadow(font, pos, text, size_, col, align = HORIZONTAL_ALIGNMENT_LEFT, width = -1.0):
		draw_string(font, pos + Vector2(1.5, 1.5), Loc.t(text), align, width, size_, Color(0, 0, 0, col.a * 0.75))
		draw_string(font, pos, Loc.t(text), align, width, size_, col)
	func chevron(c, up, col, w = 12.0):
		var s = -1.0 if up else 1.0
		draw_polyline(PackedVector2Array([c + Vector2(-w, -s * w * 0.45), c + Vector2(0, s * w * 0.45), c + Vector2(w, -s * w * 0.45)]), col, 3.0, true)

class Reticle extends HC:
	const RAINBOW_COLS = [Color("EF4444"), Color("F9892E"), Color("FFD83A"), Color("46C45A"), Color("3AA8F0"), Color("4B5BDB"), Color("A55CE0")]
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
			"locked":
				_rhythm(s)
		if s.fish_lock != null and is_instance_valid(s.fish_lock):
			_fish_lock_draw(s, s.fish_lock, u, font)
		if s.flash != 0 and s.hud_state != "locked":
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
	# round 18b, OCEAN TIME: the fish that TAB has locked: a ring that turns, four marks, its name and the speed it needs, and what SPACE does now
	func _fish_lock_draw(s, f, u, font):
		var cam = get_viewport().get_camera_3d()
		if cam == null:
			return
		var wp = f.global_position
		var rc = GS.FISH_RARITY_COLORS[clamp(f.rarity, 0, 2)]
		var nm = GS.FISH_SPECIES[f.species][0]
		var need = int(round(GS.need_speed(f) * GS.SPEED_UNIT))
		var t = GS.msec() * 0.001
		if cam.is_position_behind(wp):
			shadow(font, Vector2(size.x * 0.5 - 150.0 * u, size.y - 150.0 * u), "FISH LOCKED:  TURN ROUND TO SEE IT", int(16 * u), Color(rc.r, rc.g, rc.b, 0.9), HORIZONTAL_ALIGNMENT_CENTER, 300.0 * u)
			return
		var sp = cam.unproject_position(wp)
		var d = cam.global_position.distance_to(wp)
		var r = clamp(620.0 / max(d, 1.0), 26.0, 60.0) * u
		var a0 = t * 2.4
		for k in 4:
			var an = a0 + k * TAU / 4.0
			draw_arc(sp, r, an, an + 0.9, 12, Color(0, 0, 0, 0.5), 6.0 * u, true)
			draw_arc(sp, r, an, an + 0.9, 12, Color(rc.r, rc.g, rc.b, 0.95), 3.5 * u, true)
		draw_arc(sp, r * 0.62, 0, TAU, 28, Color(1, 1, 1, 0.45 + 0.3 * sin(t * 9.0)), 2.0 * u, true)
		sp.x = clamp(sp.x, 150.0 * u, size.x - 150.0 * u)
		sp.y = clamp(sp.y, 60.0 * u, size.y - 120.0 * u)
		shadow(font, sp + Vector2(-150.0 * u, -r - 26.0 * u), "LOCKED:  %s" % nm, int(18 * u), Color(rc.r, rc.g, rc.b, 1.0), HORIZONTAL_ALIGNMENT_CENTER, 300.0 * u)
		shadow(font, sp + Vector2(-150.0 * u, r + 22.0 * u), "NEED  %d" % need, int(15 * u), Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_CENTER, 300.0 * u)
		if p_sitting():
			shadow(font, sp + Vector2(-150.0 * u, r + 44.0 * u), "SPACE  -  LAUNCH AT IT", int(16 * u), Color(1.0, 0.95, 0.6, 0.75 + 0.25 * sin(t * 8.0)), HORIZONTAL_ALIGNMENT_CENTER, 300.0 * u)
	func p_sitting():
		var p = hud.player
		return p != null and p.on_water and p.mode == 1
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
	# THE RHYTHM. Target circles (a THICK green ring with a THIN gold ring just inside it) sit around the fry: one, two stacked, three stacked or five
	# in the shape of the olympic rings. Every circle sends two white waves shrinking onto it, circle after circle. Press E when a wave is in the
	# green band (1 point) or the gold band (2 points); you need as many points as there are waves.
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
		var font = ThemeDB.fallback_font
		var now = s.seq_now()
		var t = GS.msec() * 0.001
		var layout = sq["layout"]
		var multi = layout.size() > 1
		# round 7: big, easy-to-read circles. Radius where the wave starts / where the gold band ends / spacing of the circles, per number of circles
		var geo = {1: [158.0, 58.0, 0.0], 2: [136.0, 50.0, 270.0], 3: [92.0, 34.0, 188.0], 5: [128.0, 46.0, 256.0], 7: [90.0, 34.0, 180.0], 9: [86.0, 33.0, 176.0]}[layout.size()]       # round 19: one comfortable size from 1 to 9 circles (no tiny nine, no huge one)
		# round 18: bigger circles (EASY x1.35, HARD x1.1), shrunk back only as far as the whole picture needs to stay on the screen
		var ks = GS.dp("ring")
		var ew1 = geo[0] + 24.0
		var eh1 = geo[0] + 24.0
		for lay1 in layout:
			ew1 = max(ew1, abs(lay1[0]) * geo[2] + geo[0] + 24.0)
			eh1 = max(eh1, abs(lay1[1]) * geo[2] + geo[0] + 24.0)
		ks = max(min(ks, (size.x * 0.5 - 8.0) / (ew1 * u), (size.y * 0.5 - 60.0 * u) / (eh1 * u)), 0.6)
		var r_start = geo[0] * u * ks
		var r_ge = geo[1] * u * ks                            # the radius where the gold band ends
		var sep = geo[2] * u * ks
		var vpx = (r_start - r_ge) / max(sq["appr"], 0.2)    # pixels per second a wave shrinks
		var ext_w = r_start + 24.0 * u
		var ext_h = r_start + 24.0 * u
		for lay0 in layout:
			ext_w = max(ext_w, abs(lay0[0]) * sep + r_start + 24.0 * u)
			ext_h = max(ext_h, abs(lay0[1]) * sep + r_start + 24.0 * u)
		fc = Vector2(clamp(fc.x, ext_w, max(size.x - ext_w, ext_w)), clamp(fc.y, ext_h + 40.0 * u, max(size.y - ext_h - 70.0 * u, ext_h + 40.0 * u)))
		var gold_px = max(sq["gw"] * vpx, 5.0 * u)
		var single = sq.get("single", false)       # round 18b (HARD): one band only, the gold one
		var green_px = 0.0 if single else max(sq["gg"] * vpx, 8.0 * u)
		var r_gold_out = r_ge + gold_px
		var r_green_out = r_gold_out + green_px
		var g_mid = (r_gold_out + r_green_out) * 0.5
		var o_mid = (r_ge + r_gold_out) * 0.5
		var next_i = s._first_pending(sq)
		# round 16: the outer band of the sun is ORANGE, the moon's BLUE (everything else keeps its green); the halo, the pips and the shock rings follow
		var band = RING_GREEN
		if sq["tier"] == 12:
			band = RING_ORANGE
		elif sq["tier"] == 13:
			band = RING_BLUE
		# the target circles
		for ci in layout.size():
			var c = fc + Vector2(layout[ci][0], layout[ci][1]) * sep
			var live = false
			var pending = false
			for nt0 in sq["notes"]:
				if nt0["circle"] == ci and nt0["res"] == "":
					pending = true
					if now >= nt0["t"] - sq["appr"] - 0.05:
						live = true
			var base_a = 1.0 if live else (0.5 if pending else 0.22)
			# round 18: a dark, soft scrim under the whole target: the white waves have to stand out on a bright sky and on the sand, whatever is behind
			if pending:
				draw_circle(c, r_start * 0.97, Color(0.02, 0.04, 0.09, 0.16 * base_a))
			# a soft disc inside the target so that it reads at a glance, and a bright centre point
			draw_circle(c, r_ge, Color(1, 1, 1, 0.07 * base_a))
			draw_circle(c, 4.0 * u, Color(1, 1, 1, 0.55 * base_a))
			draw_arc(c, r_ge * 0.5, 0, TAU, 24, Color(1, 1, 1, 0.3 * base_a), 2.0, true)
			var gcol = band
			if sq["tier"] == 11:      # the rainbow in the sky: seven colours, each circle with its golden ring
				gcol = RAINBOW_COLS[ci % RAINBOW_COLS.size()]
			if not single:
				draw_arc(c, g_mid, 0, TAU, 96, Color(gcol.r, gcol.g, gcol.b, 0.14 * base_a), green_px + 5.0 * u, true)
				draw_arc(c, g_mid, 0, TAU, 96, Color(gcol.r, gcol.g, gcol.b, 0.8 * base_a), green_px, true)
			var bandc = gcol if (single and sq["tier"] == 11) else RING_GOLD
			draw_arc(c, o_mid, 0, TAU, 96, Color(bandc.r, bandc.g, bandc.b, 0.28 * base_a), gold_px + 4.0 * u, true)
			draw_arc(c, o_mid, 0, TAU, 96, Color(bandc.r, bandc.g, bandc.b, base_a), gold_px, true)
		# round 18: the count-in. At every tick a ring pulses out of the first circle; and a "READY" waits above it until the slow first wave is close
		var ct = sq.get("ticks", [])
		if not ct.is_empty():
			var c0 = fc + Vector2(layout[0][0], layout[0][1]) * sep
			for tk in ct:
				var ta = now - tk["t"]
				if ta >= 0.0 and ta < 0.42:
					var kk = ta / 0.42
					draw_arc(c0, r_ge * (0.6 + 1.5 * kk), 0, TAU, 48, Color(1.0, 0.92, 0.55, (1.0 - kk) * 0.9), 5.0 * u, true)
		if next_i == 0 and now < sq["notes"][0]["t"] - 0.12:
			var rdy_a = clamp((now - 0.05) / 0.25, 0.0, 1.0) * (0.75 + 0.25 * sin(t * 9.0))
			shadow(font, Vector2(fc.x - 110.0 * u, fc.y - r_start - 4.0 * u - 54.0 * u), "READY...", int(24 * u), Color(1.0, 0.95, 0.7, rdy_a), HORIZONTAL_ALIGNMENT_CENTER, 220.0 * u)
		# the waves
		for i in sq["notes"].size():
			var nt = sq["notes"][i]
			var napp = nt["appr"]
			var vpx_n = (r_start - r_ge) / max(napp, 0.2)         # the first wave is slower: every wave has its own speed
			var spawn = nt["t"] - napp
			if now < spawn - 0.01:
				continue
			var done = nt["res"] != ""
			var age = now - nt["res_t"] if done else 0.0
			if done and age > 0.5:
				continue
			var lay = layout[nt["circle"]]
			var c2 = fc + Vector2(lay[0], lay[1]) * sep
			var fade = clamp((now - spawn) / 0.1, 0.0, 1.0)
			if done:
				fade *= clamp(1.0 - age / 0.5, 0.0, 1.0)
			var tt = nt["res_t"] if done else now
			var r = r_ge + (nt["t"] - tt) * vpx_n
			if done:
				var rc2 = {"gold": RING_GOLD, "green": band, "miss": Color(1.0, 0.35, 0.3)}[nt["res"]]
				draw_arc(c2, max(r, 4.0) + age * 60.0 * u, 0, TAU, 56, Color(rc2.r, rc2.g, rc2.b, fade), 6.0 * u, true)
				if nt["res"] != "miss":
					draw_arc(c2, r_green_out + age * 110.0 * u, 0, TAU, 56, Color(rc2.r, rc2.g, rc2.b, 0.6 * fade), 4.0 * u, true)
				continue
			var dt = now - nt["t"]
			var zone = "none"
			if dt >= -nt["gw"] and dt <= 0.02:
				zone = "gold"
			elif dt >= -(nt["gw"] + nt["gg"]) and dt < -nt["gw"]:
				zone = "green"
			var is_next = i == next_i
			# round 19: a THIN, crisp ring: the one to press for is bright, the ones still on their way are faint and thinner, so that the contact with the band can be seen
			var rc = Color(1, 1, 1, (1.0 if is_next else 0.38) * fade)
			var rw = (3.4 if is_next else 2.0) * u
			if zone == "gold":
				rc = Color(1, 1, 1, 1.0).lerp(RING_GOLD, 0.5 + 0.5 * sin(t * 26.0))
				rw = 4.4 * u
			elif zone == "green":
				rw = 3.8 * u
			elif dt > 0.02:
				rc = Color(1.0, 0.45, 0.4, 0.8 * fade)
			# a thin dark rim under the white ring (it stays readable on a bright sky) and, for the next ring only, a narrow glow
			draw_arc(c2, max(r, 4.0), 0, TAU, 96, Color(0.0, 0.02, 0.06, (0.6 if is_next else 0.22) * fade), rw + 2.6 * u, true)
			if is_next:
				draw_arc(c2, max(r, 4.0), 0, TAU, 96, Color(rc.r, rc.g, rc.b, 0.16 * fade), rw + 5.0 * u, true)
			draw_arc(c2, max(r, 4.0), 0, TAU, 96, rc, rw, true)
		# the little scoreboard: one pip per wave (green / gold / red) and the points you still need
		var n = sq["n"]
		var half_h = 0.0
		for lay2 in layout:
			half_h = max(half_h, abs(lay2[1]) * sep)
		var top_y = fc.y - half_h - r_start - 26.0 * u
		for i in n:
			var res = sq["notes"][i]["res"]
			var pc = Color(1, 1, 1, 0.25)
			if res == "gold":
				pc = RING_GOLD
			elif res == "green":
				pc = band
			elif res == "miss":
				pc = Color(1.0, 0.35, 0.3)
			var px = fc.x + (i - (n - 1) * 0.5) * 16.0 * u
			draw_circle(Vector2(px, top_y), 5.0 * u, pc)
			draw_arc(Vector2(px, top_y), 5.0 * u, 0, TAU, 16, Color(0, 0, 0, 0.5), 1.5)
		if n > 1:
			shadow(font, Vector2(fc.x - 70.0 * u, top_y - 10.0 * u), "%d / %d" % [min(sq["points"], sq["need"]), sq["need"]], int(14 * u), Color(1, 1, 1, 0.75), HORIZONTAL_ALIGNMENT_CENTER, 140.0 * u)
		var kc = Vector2(fc.x, min(fc.y + half_h + r_start + 40.0 * u, size.y - 44.0 * u))
		var cap_col = Color(0.1, 0.1, 0.14, 0.82)
		var cap_txt = Color(1, 1, 1, 0.95)
		var pulse_k = 1.0
		if next_i >= 0:
			var dtn = now - sq["notes"][next_i]["t"]
			if dtn > -0.35 and dtn < 0.05:
				pulse_k = 1.0 + 0.22 * (1.0 - abs(dtn + 0.15) / 0.25)
		var cs = 46.0 * u * pulse_k
		draw_rect(Rect2(kc - Vector2(cs, cs) * 0.5, Vector2(cs, cs)), cap_col)
		draw_rect(Rect2(kc - Vector2(cs, cs) * 0.5, Vector2(cs, cs)), Color(1, 1, 1, 0.95), false, 2.5)
		draw_string(font, kc + Vector2(-cs * 0.5, cs * 0.3), "E", HORIZONTAL_ALIGNMENT_CENTER, cs, int(round(32 * u * pulse_k / 3.0) * 3), cap_txt)


# TOP-RIGHT under the stamina bar: a racing tachometer. Segments climb from low yellow ones to tall red ones; the speed in big numbers below.
# A white tick marks the top speed you can reach right now (red fries move it), a small caret marks the speed the fry in view needs.
class Tach extends HC:
	var hud
	var shown = 0.0
	const N = 26
	var vmax = 160.0          # the scale grows to 310 when a drink / STARLIGHT lifts the top speed past it
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
		var yb = 168.0 * u
		var t = GS.msec() * 0.001
		var maxv = GS.boost_speed() * GS.SPEED_UNIT
		var need_hi = 0.0
		if s.near_target != null and is_instance_valid(s.near_target):
			need_hi = s.need_speed * GS.SPEED_UNIT
		var vwant = 310.0 if (maxv > 155.0 or shown > 150.0 or need_hi > 150.0) else 160.0
		vmax = lerp(vmax, vwant, 0.06)
		var VMAX = vmax
		var lit = clamp(shown / VMAX, 0.0, 1.0) * N
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
			elif s.need_tier == 7:
				tc = GS.FISH_RARITY_COLORS[1]
			elif s.need_tier == 8:
				tc = GS.FISH_RARITY_COLORS[2]
			elif s.need_tier == 9:
				tc = Color.from_hsv(fmod(t * 0.5, 1.0), 0.5, 1.0)
			elif s.need_tier == 10:
				tc = Color("FFF3B0")
			elif s.need_tier == 6:
				tc = Color("BFEFFF")
			elif s.need_tier == 11:
				tc = Color.from_hsv(fmod(t * 0.5, 1.0), 0.5, 1.0)
			elif s.need_tier == 12:
				tc = RING_ORANGE
			elif s.need_tier == 13:
				tc = RING_BLUE
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
	# round 19: a good judgement lights the four corners of the screen for a moment: a pale glow in the colour of the band (green), a warmer and stronger one for gold
	func _hit_glow():
		var p = hud.player
		if p == null:
			return
		var sn = p.snatch
		if sn.hit_fx_res == "":
			return
		var age = (GS.msec() - sn.hit_fx_t) / 1000.0
		if age < 0.0 or age > 0.5:
			return
		var k = 1.0 - age / 0.5
		k = k * k
		var gold = sn.hit_fx_res == "gold"
		var col = RING_GOLD
		if not gold:
			col = RING_GREEN
			if sn.hit_fx_tier == 12:
				col = RING_ORANGE
			elif sn.hit_fx_tier == 13:
				col = RING_BLUE
		var al = (0.36 if gold else 0.2) * k
		var reach = size.y * (0.36 if gold else 0.28)
		var c0 = Color(col.r, col.g, col.b, al)
		var c1 = Color(col.r, col.g, col.b, 0.0)
		for corner in [Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(0, size.y)]:
			var sx = 1.0 if corner.x < 1.0 else -1.0
			var sy = 1.0 if corner.y < 1.0 else -1.0
			draw_polygon(PackedVector2Array([corner, corner + Vector2(sx * reach, 0), corner + Vector2(sx * reach, sy * reach), corner + Vector2(0, sy * reach)]), PackedColorArray([c0, c1, c1, c1]))
	func _draw():
		_hit_glow()
		var a = hud.focus_a
		if a <= 0.01:
			return
		draw_texture_rect(tex, Rect2(Vector2.ZERO, size), false, Color(1, 1, 1, a))
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.35, 0.5, 0.8, 0.07 * a))
		# round 10: the slow time has a name. Small, spaced out, at the top edge: bright for a new gull, a whisper for an old hand
		var u = size.y / 720.0
		var newbie = GS.fry_total() < 6
		var f = ThemeDB.fallback_font
		var txt = "G U L L   T I M E"
		var w = f.get_string_size(Loc.t(txt), HORIZONTAL_ALIGNMENT_LEFT, -1, int(15 * u)).x
		var pulse = 0.78 + 0.22 * sin(GS.msec() * 0.004) if newbie else 1.0
		var ta = a * (0.85 * pulse if newbie else 0.32)
		draw_string(f, Vector2(size.x * 0.5 - w * 0.5 + 1.0, size.y * 0.045 + 1.0), Loc.t(txt), HORIZONTAL_ALIGNMENT_LEFT, -1, int(15 * u), Color(0, 0, 0, ta * 0.7))
		draw_string(f, Vector2(size.x * 0.5 - w * 0.5, size.y * 0.045), Loc.t(txt), HORIZONTAL_ALIGNMENT_LEFT, -1, int(15 * u), Color(1.0, 0.9, 0.62, ta))

# World-to-screen pointers: the first fries ("where is it?") in gold, and the faint "go back there" hint for the plain fry.
class Guide extends HC:
	var hud
	func _draw():
		if hud.guide_pos != null:
			_one(hud.guide_pos, "FRY", Color(1.0, 0.82, 0.3, 0.95), 1.0)
		if hud.hint_pos != null:
			_one(hud.hint_pos, hud.hint_text, Color(1.0, 0.9, 0.7, 0.8), 0.55)
		var sn = GS.sniff_node
		if sn != null and GS.sniff_until > GS.msec() / 1000.0:
			if is_instance_valid(sn) and not sn.consumed and not sn.carried:
				var info = sn.vision_info()
				if info != null:
					var rc = info["col"]
					_one(info["pos"], "NEAREST FRY", Color(rc.r, rc.g, rc.b, 0.95), clamp((GS.sniff_until - GS.msec() / 1000.0) / 0.8, 0.0, 1.0))
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
	func _flames(x0, y, w, col, u, t, lift):
		# a row of little flames standing on the top edge of the bar (the stamina "burns" while a buff runs)
		var n = int(w / (6.0 * u))
		for i in n:
			var x = x0 + (i + 0.5) * 6.0 * u
			var h = (5.0 + 8.0 * abs(sin(t * 9.0 + i * 0.9)) + 4.0 * sin(t * 17.0 + i * 1.7)) * u * lift
			var wd = 6.0 * u
			draw_colored_polygon(PackedVector2Array([Vector2(x - wd * 0.5, y), Vector2(x + sin(t * 8.0 + i) * 1.5 * u, y - h), Vector2(x + wd * 0.5, y)]), Color(col.r, col.g, col.b, 0.85))
			draw_colored_polygon(PackedVector2Array([Vector2(x - wd * 0.25, y), Vector2(x, y - h * 0.55), Vector2(x + wd * 0.25, y)]), Color(1.0, 0.95, 0.7, 0.8))
	func _draw():
		var p = hud.player
		if p == null:
			return
		var font = ThemeDB.fallback_font
		var w = size.x
		var t = GS.msec() * 0.001
		# round 18: the whole corner scales with the picture (it used to be a fixed number of pixels: tiny on a big screen), pinned to the top-right corner
		var u0 = get_viewport_rect().size.y / 720.0
		draw_set_transform(Vector2(size.x * (1.0 - u0), 0.0), 0.0, Vector2(u0, u0))
		var ic = Vector2(w - 40, 31)
		draw_circle(ic, 14, Color(0.95, 0.95, 0.92, 0.95))
		draw_colored_polygon(PackedVector2Array([ic + Vector2(-10, 1), ic + Vector2(-20, 4), ic + Vector2(-10, 6)]), Color("F2A22E"))
		draw_circle(ic + Vector2(-4, -3), 1.8, Color(0.1, 0.1, 0.12))
		var ratio = clamp(1.0 - p.roll_cd / max(GS.roll_cooldown(), 0.1), 0.0, 1.0)
		draw_arc(ic, 24, -PI / 2, -PI / 2 + TAU, 40, Color(0, 0, 0, 0.35), 3.0, true)
		draw_arc(ic, 24, -PI / 2, -PI / 2 + TAU * ratio, 40, GOLD if ratio >= 1.0 else Color(0.7, 0.7, 0.7, 0.8), 3.0, true)
		if p.soaked_t > 0.0:
			draw_circle(ic + Vector2(14, 14), 4.0, Color(0.4, 0.7, 1.0, 0.9))
		var smax = GS.stamina_max()
		var bar_w = min(210.0 + smax * 0.8, 420.0)      # round 18: a big, framed breath bar (the players did not see the old thin one)
		var bx = w - 74 - bar_w
		draw_rect(Rect2(bx, 18, bar_w, 26), Color(0.02, 0.03, 0.06, 0.62))
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
		# a running buff sets the bar on fire: coffee red, cocktail yellow, ice cream every colour
		var act = []
		for k in ["coffee", "alcohol", "ice"]:
			if GS.buff[k] > 0.0:
				act.append(k)
		var filled_w = bar_w * p.stamina / smax
		# round 16: OCEAN TIME turns the bar into deep ocean blue (in the air RAINBOW TIME, when it runs, wins)
		var fishy = GS.fish_mode() or (GS.fish_active() and GS.star_t <= 0.0)
		if act.is_empty() and fishy:
			var segs2 = max(int(filled_w / 4.0), 1)
			for i in segs2:
				var sx2 = bx + i * 4.0
				var cw3 = min(4.0, filled_w - i * 4.0)
				var wv2 = 0.5 + 0.5 * sin(t * 3.2 - float(i) * 0.45)
				draw_rect(Rect2(sx2, 18, cw3, 26), Color(0.03, 0.2, 0.52).lerp(Color(0.16, 0.56, 0.96), wv2))
			draw_rect(Rect2(bx, 18, filled_w, 6), Color(0.7, 0.92, 1.0, 0.35))
		elif act.is_empty():
			draw_rect(Rect2(bx, 18, filled_w, 26), col)
		else:
			var kind = act[int(t * 1.3) % act.size()]
			var fc2 = {"coffee": Color(1.0, 0.2, 0.1), "alcohol": Color(1.0, 0.8, 0.12), "ice": Color(0.45, 0.88, 1.0)}[kind]
			if kind == "ice":
				var segs = max(int(filled_w / 5.0), 1)
				for i in segs:
					var sx = bx + i * 5.0
					var cw2 = min(5.0, filled_w - i * 5.0)
					draw_rect(Rect2(sx, 18, cw2, 26), Color(0.45, 0.85, 1.0).lerp(Color(0.92, 1.0, 1.0), 0.5 + 0.5 * sin(t * 3.0 - float(i) * 0.5)))
				fc2 = Color(0.55, 0.9, 1.0)
			else:
				draw_rect(Rect2(bx, 18, filled_w, 26), fc2.lerp(Color(1, 0.55, 0.2) if kind == "coffee" else Color(1, 0.95, 0.5), 0.35 + 0.25 * sin(t * 12.0)))
			_flames(bx, 18.0, filled_w, fc2, 1.0, t, 1.0)
			draw_rect(Rect2(bx, 18, filled_w, 26), Color(1, 1, 1, 0.08 + 0.06 * sin(t * 20.0)))
		if p.boost_locked:
			draw_rect(Rect2(bx, 18, bar_w * 15.0 / smax, 26), Color(1, 0.3, 0.2, 0.25))
		# round 18: the breath bar is a framed, readable thing: a gold frame (red and pulsing when the breath is low), quarter marks, the number, a name, and a call to rest
		var low = p.low_stamina
		var plow = 0.5 + 0.5 * sin(GS.msec() * 0.008)
		var fcol = Color(1.0, 0.84, 0.4, 0.95)
		if low:
			fcol = Color(1.0, 0.4 + 0.25 * plow, 0.28, 1.0)
		draw_rect(Rect2(bx - 3, 15, bar_w + 6, 32), fcol, false, 3.0)
		draw_rect(Rect2(bx - 6, 12, bar_w + 12, 38), Color(0, 0, 0, 0.3), false, 2.0)
		for q in range(1, 4):
			var qx = bx + bar_w * q / 4.0
			draw_line(Vector2(qx, 18), Vector2(qx, 44), Color(0, 0, 0, 0.32), 2.0)
		shadow(font, Vector2(bx, 63), "BREATH", 13, Color(1, 0.95, 0.8, 0.85))
		shadow(font, Vector2(bx, 37), "%d" % int(ceil(p.stamina)), 17, Color(1, 1, 1, 0.97), HORIZONTAL_ALIGNMENT_CENTER, bar_w)
		if low and p.mode == 0:
			shadow(font, Vector2(bx + 70, 63), "LOW BREATH:  CTRL - LAND AND REST", 13, Color(1.0, 0.62 + 0.2 * plow, 0.4, 0.8 + 0.2 * plow))

		# CROWD WATCH: how closely the people around you are looking. More eyes = thinner timing bands.
		var wv = GS.watch
		var wc = Color(0.55, 0.92, 0.55)
		if wv >= 3.0:
			wc = Color(1.0, 0.35, 0.3)
		elif wv >= 2.0:
			wc = Color(1.0, 0.6, 0.3)
		elif wv >= 1.0:
			wc = Color(0.98, 0.88, 0.4)
		shadow(font, Vector2(bx, 86), "CROWD", 12, Color(1, 1, 1, 0.7))
		var filled = clamp(wv / 4.0, 0.0, 1.0) * 8.0
		for i in 8:
			var pa = clamp(filled - i, 0.0, 1.0)
			var pr = Rect2(bx + 50 + i * 13, 77, 10, 10)
			draw_rect(pr, Color(1, 1, 1, 0.15))
			if pa > 0.0:
				draw_rect(Rect2(pr.position, Vector2(10 * pa, 10)), wc)
		shadow(font, Vector2(bx + 158, 86), GS.watch_label(), 12, Color(wc.r, wc.g, wc.b, 0.95))
		# the buff timers: a little bar that runs down (and rushes down once the gull has landed or been hit)
		var ry = 230.0
		for k in act:
			var dc = GS.BUFF_COL[k]
			if k == "ice":
				dc = GS.BUFF_COL["ice"]
			var blink = 1.0 if GS.buff[k] > 3.5 else 0.55 + 0.45 * sin(t * 14.0)
			shadow(font, Vector2(bx, ry + 9), GS.BUFF_NAME[k], 12, Color(dc.r, dc.g, dc.b, blink))
			draw_rect(Rect2(bx + 92, ry, 110, 8), Color(0, 0, 0, 0.4))
			draw_rect(Rect2(bx + 92, ry, 110.0 * clamp(GS.buff[k] / GS.BUFF_SEC, 0.0, 1.0), 8), Color(dc.r, dc.g, dc.b, blink))
			if GS.buff[k] > GS.BUFF_SEC:
				draw_rect(Rect2(bx + 92 + 104.0, ry, 6, 8), Color(1, 1, 1, 0.9))
			shadow(font, Vector2(bx + 208, ry + 9), "%d s" % int(ceil(GS.buff[k])), 11, Color(1, 1, 1, 0.7))
			ry += 15.0
		if GS.star_active():
			for i in 22:
				var fr = float(i) / 22.0
				if fr > GS.star_t / GS.star_sec():
					break
				draw_rect(Rect2(bx + 92 + i * 5.0, ry, 4.0, 8), Color.from_hsv(fmod(fr + t * 0.4, 1.0), 0.5, 1.0, 0.95))
			shadow(font, Vector2(bx, ry + 9), "RAINBOW TIME", 12, Color.from_hsv(fmod(t * 0.5, 1.0), 0.35, 1.0, 1.0))
			shadow(font, Vector2(bx + 208, ry + 9), "%d s" % int(ceil(GS.star_t)), 11, Color(1, 1, 1, 0.8))
			ry += 15.0
		if GS.fish_active():
			var fc3 = Color(0.3, 0.68, 1.0)
			var live_f = GS.fish_mode()
			for i in 22:
				var fr2 = float(i) / 22.0
				if fr2 > GS.fish_t / 40.0:
					break
				draw_rect(Rect2(bx + 92 + i * 5.0, ry, 4.0, 8), Color(fc3.r, fc3.g, fc3.b, 0.95 if live_f else 0.45))
			var fl = "OCEAN TIME" + ("  x%d" % GS.fish_streak if GS.fish_streak > 1 else "")
			shadow(font, Vector2(bx, ry + 9), fl, 12, Color(fc3.r, fc3.g, fc3.b, 1.0 if live_f else 0.6))
			shadow(font, Vector2(bx + 208, ry + 9), "%d s" % int(ceil(GS.fish_t)), 11, Color(1, 1, 1, 0.8))
			ry += 15.0
		if act.is_empty() and GS.has["blue"]:
			shadow(font, Vector2(bx + 250, 86), "ALT %d" % int(p.global_position.y), 13, Color(1, 1, 1, 0.75))
		elif not act.is_empty():
			shadow(font, Vector2(bx + 150, 50 + 0), "", 1, Color(1, 1, 1, 0))

# LOWER-LEFT: one short line when a buff starts / ends / shrugs something off (and the faint "tab" prompts live elsewhere)
class Banner extends HC:
	var hud
	func _draw():
		var age = GS.msec() / 1000.0 - GS.buff_msg_t
		if GS.buff_msg == "" or age > 3.6 or age < 0.0:
			return
		var u = size.y / 720.0
		var a = clamp(min(age / 0.18, (3.6 - age) / 0.5), 0.0, 1.0)
		var font = ThemeDB.fallback_font
		var y = size.y - 34.0 * u
		if hud.comic != null and hud.comic.slide > 0.05:
			y = size.y - 250.0 * u
		var txt = GS.buff_msg
		var wtxt = font.get_string_size(Loc.t(txt), HORIZONTAL_ALIGNMENT_LEFT, -1, int(16 * u)).x
		var x = 22.0 * u + (1.0 - a) * -24.0 * u
		var col = Color(1, 0.96, 0.8)
		if GS.drink != "":
			col = GS.BUFF_COL[GS.drink].lightened(0.35)
			if GS.drink == "ice":
				col = GS.BUFF_COL["ice"].lightened(0.2)
		draw_rect(Rect2(Vector2(x - 10.0 * u, y - 19.0 * u), Vector2(wtxt + 24.0 * u, 28.0 * u)), Color(0.04, 0.05, 0.09, 0.62 * a))
		draw_rect(Rect2(Vector2(x - 10.0 * u, y - 19.0 * u), Vector2(4.0 * u, 28.0 * u)), Color(col.r, col.g, col.b, a))
		shadow(font, Vector2(x + 4.0 * u, y), txt, int(16 * u), Color(col.r, col.g, col.b, a))

# TOP-LEFT: the box of fries. Eight little cartons in two rows (the three starter fries, then one per colour), each with four small squares
# under it: silver / gold / diamond / rainbow (the rainbow one is a bar that gets longer with every extra fry; press C for the exact numbers).
# A new fry flies into its square and lights it. Below the boxes: the mission board.
class FryGrid extends HC:
	var hud
	var lit_t = {}
	var was = {}
	var vtex
	const COLS = 4
	func _ready():
		var g = Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0))
		g.add_point(0.55, Color(1, 1, 1, 0.0))
		g.set_color(2, Color(1, 1, 1, 0.8))
		vtex = GradientTexture2D.new()
		vtex.gradient = g
		vtex.fill = GradientTexture2D.FILL_RADIAL
		vtex.fill_from = Vector2(0.5, 0.5)
		vtex.fill_to = Vector2(1.08, 0.5)
		vtex.width = 256
		vtex.height = 256
	# a small keycap (round 18b: the key of the board)
	func _key_cap(c, txt, u):
		var r = Rect2(c - Vector2(11.0, 11.0) * u, Vector2(22.0, 22.0) * u)
		draw_rect(Rect2(r.position + Vector2(0, 2.5 * u), r.size), Color(0, 0, 0, 0.45))
		draw_rect(r, Color(0.96, 0.94, 0.86, 0.95))
		draw_rect(r, Color(0.1, 0.1, 0.16, 0.95), false, 1.5)
		var f = ThemeDB.fallback_font
		draw_string(f, Vector2(c.x - 11.0 * u, c.y + 5.5 * u), txt, HORIZONTAL_ALIGNMENT_CENTER, 22.0 * u, int(14 * u), Color(0.12, 0.13, 0.2))
	func cell_size(u):
		return Vector2(72.0 * u, 76.0 * u)
	func cell_pos(i, u):
		var cs = cell_size(u)
		return Vector2(16.0 * u + (i % COLS) * cs.x, 12.0 * u + (i / COLS) * cs.y)
	# the centre of one of the four squares under cell i
	func square_pos(i, sq, u):
		var cp = cell_pos(i, u)
		return cp + Vector2((6.0 + sq * 10.5 + 4.0) * u, 58.0 * u)
	func _tiers(i):
		if i == 0:
			return [min(GS.gull_sense_count, 3), Color("F1C94B")]
		var k = GS.FRY_TYPES[i - 1]
		return [GS.lv[k], GS.TYPE_COLORS[k]]
	# a carton of fries: `sticks` 0..6 standing in it, tinted body
	func carton(c, w, col, sticks, a, glow = 0.0):
		var h = w * 1.05
		var top = c.y - h * 0.18
		var bot = c.y + h * 0.5
		if glow > 0.0:
			draw_circle(c, w * 0.95, Color(col.r, col.g, col.b, 0.16 * glow))
			draw_circle(c, w * 0.62, Color(col.r, col.g, col.b, 0.22 * glow))
		for k in 6:
			if k >= sticks:
				continue
			var sx = c.x - w * 0.34 + k * w * 0.136
			var sh = w * (0.46 + 0.1 * float((k * 5) % 3))
			draw_rect(Rect2(Vector2(sx, top - sh), Vector2(w * 0.11, sh + 2.0)), Color(0.96, 0.78, 0.33, a))
			draw_rect(Rect2(Vector2(sx, top - sh), Vector2(w * 0.11, w * 0.08)), Color(1.0, 0.94, 0.7, a))
		var pts = PackedVector2Array([Vector2(c.x - w * 0.5, top), Vector2(c.x + w * 0.5, top), Vector2(c.x + w * 0.38, bot), Vector2(c.x - w * 0.38, bot)])
		draw_colored_polygon(pts, Color(col.r, col.g, col.b, a * (1.0 if sticks > 0 else 0.55)))
		draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Color(1, 1, 1, 0.85 * a), 1.6, true)
		draw_rect(Rect2(Vector2(c.x - w * 0.22, c.y + h * 0.05), Vector2(w * 0.44, h * 0.22)), Color(1, 0.96, 0.84, 0.9 * a))
	func _square(c, s, col, lit, flash):
		var r = Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s))
		draw_rect(r, Color(col.r, col.g, col.b, 0.95 if lit else 0.14))
		draw_rect(r, Color(1, 1, 1, 0.85 if lit else 0.3), false, 1.2)
		if flash > 0.0:
			draw_arc(c, s * (0.7 + 2.2 * (1.0 - flash)), 0, TAU, 20, Color(1, 1, 1, flash), 2.0, true)
	func _bar(c0, s, count, flash):
		# the rainbow bar: one segment per extra fry, every segment its own hue
		var wmax = s + max(count, 0) * 3.0
		var r = Rect2(c0 - Vector2(s * 0.5, s * 0.5), Vector2(wmax, s))
		draw_rect(r, Color(1, 1, 1, 0.12))
		for q in max(count, 1):
			var seg = Rect2(r.position + Vector2(q * 3.0 + (0.0 if count > 0 else 0.0), 0), Vector2(s if q == 0 else 3.0, s))
			if q == 0:
				seg.size.x = s
			draw_rect(seg, Color.from_hsv(float(q) / 8.0, 0.55, 1.0, 0.95 if count > 0 else 0.0))
		draw_rect(r, Color(1, 1, 1, 0.85 if count > 0 else 0.3), false, 1.2)
		if flash > 0.0:
			draw_arc(r.position + Vector2(wmax, s) * 0.5, s * (0.8 + 2.0 * (1.0 - flash)), 0, TAU, 20, Color(1, 0.8, 1, flash), 2.0, true)
	func _spaced(font, pos, text, sz, col, gap):
		# letter-spaced text, centred on pos
		text = Loc.t(text)
		var total = 0.0
		for ch in text:
			total += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x + gap
		var x = pos.x - total * 0.5
		for ch in text:
			draw_string(font, Vector2(x + 1.5, pos.y + 1.5), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(0, 0, 0, col.a * 0.7))
			draw_string(font, Vector2(x, pos.y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
			x += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x + gap
	func _draw():
		var p = hud.player
		if p == null:
			return
		var u = size.y / 720.0
		var font = ThemeDB.fallback_font
		var t = GS.msec() * 0.001
		var dt = get_process_delta_time() / max(Engine.time_scale, 0.1)
		var unlocked = hud.slots_visible
		var rows = 8 if unlocked else 1
		# ---- the boxes
		for i in rows:
			var bt = _tiers(i)
			var n = bt[0]
			var col = bt[1]
			var cp = cell_pos(i, u)
			var key = "b%d" % i
			if n > was.get(key, 0):
				lit_t[key] = 0.0
			was[key] = n
			if lit_t.has(key):
				lit_t[key] += dt
			var fl = clamp(1.0 - lit_t.get(key, 9.0) / 0.9, 0.0, 1.0)
			var have = n >= 1 if i > 0 else n >= 3
			var sticks = 6 if have else (min(n * 2, 5) if i == 0 else 0)
			carton(cp + Vector2(36.0 * u, 26.0 * u), 30.0 * u, col, sticks, 1.0 if (have or i == 0) else 0.45, 1.0 if have else 0.0)
			if fl > 0.0:
				draw_arc(cp + Vector2(36.0 * u, 26.0 * u), (22.0 + 26.0 * (1.0 - fl)) * u, 0, TAU, 28, Color(1, 1, 1, fl), 2.5, true)
			# the squares
			if i == 0:
				for q in 3:
					_square(square_pos(i, q, u), 8.0 * u, Color("F1E6B0"), n > q, 0.0)
			else:
				var k2 = GS.FRY_TYPES[i - 1]
				for q in 3:
					var qk = "s%d_%d" % [i, q]
					var lit = n > q
					if lit and not was.get(qk, false):
						lit_t[qk] = 0.0
					was[qk] = lit
					if lit_t.has(qk):
						lit_t[qk] += dt
					_square(square_pos(i, q, u), 8.0 * u, GS.RARITY_COLORS[q + 1], lit, clamp(1.0 - lit_t.get(qk, 9.0) / 0.7, 0.0, 1.0))
				var rb = GS.rainbow[k2]
				var rk = "r%d" % i
				if rb > was.get(rk, 0):
					lit_t[rk] = 0.0
				was[rk] = rb
				if lit_t.has(rk):
					lit_t[rk] += dt
				_bar(square_pos(i, 3, u), 8.0 * u, rb, clamp(1.0 - lit_t.get(rk, 9.0) / 0.7, 0.0, 1.0))
		# ---- the "you got a fry" moment: nothing pauses, nothing covers the middle of the screen
		var i2 = 0
		var center = Vector2(size.x * 0.5, size.y * 0.7)
		while i2 < hud.gains.size():
			var g = hud.gains[i2]
			g["t"] += dt
			var gt = g["t"]
			var dur = g["dur"]
			var fly0 = dur - 0.85
			var type = g["type"]
			var tier = g["tier"]
			var rc = GS.RARITY_COLORS[clamp(tier, 0, 4)]
			if tier >= 4:
				rc = Color.from_hsv(fmod(t * 0.6, 1.0), 0.45, 1.0)
			var col2 = Color("F1C94B") if type == "tutorial" else GS.TYPE_COLORS[type]
			var cell = 0 if type == "tutorial" else GS.FRY_TYPES.find(type) + 1
			var sqi = g["slot"]
			var target = square_pos(cell, sqi, u) if sqi < 3 else square_pos(cell, 3, u) + Vector2((8.0 + GS.rainbow.get(type, 0) * 3.0) * u, 0)
			var edge = clamp(min(gt / 0.25, (fly0 + 0.3 - gt) / 0.7), 0.0, 1.0)
			if edge > 0.0:
				draw_texture_rect(vtex, Rect2(Vector2.ZERO, size), false, Color(rc.r, rc.g, rc.b, 0.5 * edge * (0.7 if tier <= 1 else 1.0)))
			var pos = center
			var sc = 1.0
			var ta = 1.0
			if gt < 0.35:
				var e0 = gt / 0.35
				pos = center + Vector2(0, (1.0 - e0) * 40.0 * u)
				sc = 0.5 + 0.5 * e0 + 0.15 * sin(e0 * PI)
				ta = e0
			elif gt > fly0:
				var e1 = clamp((gt - fly0) / 0.8, 0.0, 1.0)
				var ee = e1 * e1 * (3.0 - 2.0 * e1)
				var mid = center.lerp(target, 0.5) + Vector2(80.0 * u, -90.0 * u)
				pos = center.lerp(mid, ee).lerp(mid.lerp(target, ee), ee)
				sc = lerp(1.0, 0.28, ee)
				ta = clamp(1.0 - (gt - fly0) / 0.35, 0.0, 1.0)
			var w0 = 62.0 * u * sc
			# a ring that opens outwards once, and a slow pulse of light
			if gt < 0.9:
				var k3 = gt / 0.9
				draw_arc(pos, (30.0 + 150.0 * k3) * u, 0, TAU, 56, Color(rc.r, rc.g, rc.b, (1.0 - k3) * 0.8), 3.0 * u, true)
			carton(pos, w0, col2, 6, 1.0, 1.0 + 0.2 * sin(gt * 6.0))
			if tier >= 2 and tier <= 3 and gt < fly0:
				for q in 8:
					var a2 = gt * 1.6 + q * TAU / 8.0
					draw_circle(pos + Vector2(cos(a2), sin(a2)) * w0 * (0.9 + 0.12 * sin(gt * 5.0 + q)), 2.6 * u, Color(rc.r, rc.g, rc.b, 0.9 * ta))
			if ta > 0.01:
				var ly = pos.y + 52.0 * u
				var lw = 240.0 * u * clamp(gt / 0.5, 0.0, 1.0)
				draw_line(Vector2(pos.x - lw * 0.5, ly - 22.0 * u), Vector2(pos.x + lw * 0.5, ly - 22.0 * u), Color(rc.r, rc.g, rc.b, 0.7 * ta), 1.5)
				_spaced(font, Vector2(pos.x, ly - 5.0 * u), g["rarity"], int(13 * u), Color(rc.r, rc.g, rc.b, ta), 5.0 * u)
				_spaced(font, Vector2(pos.x, ly + 20.0 * u), g["name"], int(22 * u), Color(1, 0.98, 0.92, ta), 1.5 * u)
				shadow(font, Vector2(pos.x - 220.0 * u, ly + 40.0 * u), g["line"], int(13 * u), Color(1, 1, 1, 0.78 * ta), HORIZONTAL_ALIGNMENT_CENTER, 440.0 * u)
			if gt > dur:
				hud.gains.remove_at(i2)
				hud.fry_arrived(g)
			else:
				i2 += 1
		if hud.film_clean:
			return
		# ---- the mission board (round 18): ONE goal on top (stop being hungry), the step on the way to it (fries), and the BONUS GOALS, each with the REWARD it gives
		var mx = 26.0 * u
		var my = (12.0 + (2.0 * 76.0 if unlocked else 76.0) + 20.0) * u
		# round 19: a finished goal ALWAYS shows the board (even a folded one slides in and out again): the number runs up from 0 to its end, the line flashes twice,
		# a stroke is drawn through it, and the board slides away (or stays, when it was open)
		var now_s = GS.msec() / 1000.0
		while GS.quest_pops.size() > 0 and now_s > GS.quest_pops[0]["t0"] + GS.QUEST_POP_SEC:
			GS.quest_pops.pop_front()
		var pop_id = ""
		var pop_age = -1.0
		if GS.quest_pops.size() > 0 and now_s >= GS.quest_pops[0]["t0"]:
			pop_id = GS.quest_pops[0]["id"]
			pop_age = now_s - GS.quest_pops[0]["t0"]
		var forced = pop_id != "" and not GS.board_open
		if forced:
			var kin = clamp(min(pop_age / 0.45, (GS.QUEST_POP_SEC - pop_age) / 0.55), 0.0, 1.0)
			draw_set_transform(Vector2(-(1.0 - kin * kin * (3.0 - 2.0 * kin)) * 560.0 * u, 0.0))
		if not GS.board_open and not forced:
			# round 18b: the board is folded away: a small tab remembers that it is there (and which key brings it back)
			var tb = Rect2(Vector2(mx - 14.0 * u, my - 12.0 * u), Vector2(158.0 * u, 34.0 * u))
			draw_rect(tb, Color(0.03, 0.05, 0.1, 0.55))
			draw_rect(tb, Color(1.0, 0.84, 0.4, 0.45), false, 1.5)
			draw_rect(Rect2(tb.position, Vector2(4.0 * u, tb.size.y)), Color(1.0, 0.84, 0.4, 0.8))
			_key_cap(Vector2(tb.position.x + 24.0 * u, tb.position.y + tb.size.y * 0.5), "Q", u)
			shadow(font, Vector2(tb.position.x + 44.0 * u, tb.position.y + tb.size.y * 0.5 + 6.0 * u), "GOALS", int(15 * u), Color(1.0, 0.94, 0.75, 0.9))
			return
		var tgt = GS.mission_target()
		var tot = GS.fry_total()
		var shown_q = GS.quests_shown()
		var qn = shown_q.size()
		var focus_id = ""
		for id0 in shown_q:
			if GS.quest_state(id0) != "done":
				focus_id = id0
				break
		var pw = 400.0 * u
		var ph = (112.0 + 30.0 + (34.0 + 24.0 * qn + (34.0 if focus_id != "" else 0.0) + 16.0 if qn > 0 else 0.0) + 14.0) * u
		var panel = Rect2(Vector2(mx - 14.0 * u, my - 12.0 * u), Vector2(pw, ph))
		draw_rect(Rect2(panel.position + Vector2(4, 5), panel.size), Color(0, 0, 0, 0.28))
		draw_rect(panel, Color(0.03, 0.05, 0.1, 0.7))
		draw_rect(panel, Color(1.0, 0.84, 0.4, 0.55), false, 2.0)
		draw_rect(Rect2(panel.position, Vector2(5.0 * u, panel.size.y)), Color(1.0, 0.84, 0.4, 0.85 + 0.15 * sin(t * 2.4)))
		_key_cap(Vector2(panel.end.x - 58.0 * u, panel.position.y + 17.0 * u), "Q", u)
		shadow(font, Vector2(panel.end.x - 44.0 * u, panel.position.y + 23.0 * u), "HIDE", int(12 * u), Color(1, 1, 1, 0.65))
		# the goal
		var gy = my + 8.0 * u
		shadow(font, Vector2(mx, gy), "THE GOAL", int(12 * u), Color(1.0, 0.84, 0.4, 0.8))
		shadow(font, Vector2(mx, gy + 28.0 * u), "NO LONGER HUNGRY", int(26 * u), Color(1.0, 0.95, 0.78, 1.0))
		shadow(font, Vector2(panel.end.x - 90.0 * u, gy + 28.0 * u), "0 / 1", int(18 * u), Color(1.0, 0.82, 0.7, 0.85), HORIZONTAL_ALIGNMENT_RIGHT, 70.0 * u)
		# the belly: it fills with every fry, but not quite to the top. The last bite is not a magic one.
		var bw = 316.0 * u
		var bh = 12.0 * u
		var bxx = mx
		var byy = gy + 40.0 * u
		draw_rect(Rect2(bxx, byy, bw, bh), Color(0, 0, 0, 0.5))
		var full = 0.92 * clamp(float(tot) / float(GS.FRY_CAP), 0.0, 1.0)
		draw_rect(Rect2(bxx, byy, bw * full, bh), Color(1.0, 0.78, 0.3, 0.95))
		draw_rect(Rect2(bxx, byy, bw * full, bh * 0.4), Color(1.0, 0.95, 0.7, 0.45))
		for m in GS.MISSIONS:
			var mxp = bxx + bw * 0.92 * float(m) / float(GS.FRY_CAP)
			draw_line(Vector2(mxp, byy - 2.0 * u), Vector2(mxp, byy + bh + 2.0 * u), Color(1, 1, 1, 0.5), 1.5)
		draw_rect(Rect2(bxx, byy, bw, bh), Color(1, 1, 1, 0.55), false, 1.5)
		var qx = bxx + bw + 14.0 * u
		var qp = 0.6 + 0.4 * sin(t * 3.0)
		draw_circle(Vector2(qx, byy + bh * 0.5), 11.0 * u, Color(0.1, 0.1, 0.16, 0.8))
		draw_arc(Vector2(qx, byy + bh * 0.5), 11.0 * u, 0, TAU, 20, Color(1.0, 0.84, 0.4, qp), 2.0)
		shadow(font, Vector2(qx - 10.0 * u, byy + bh * 0.5 + 6.0 * u), "?", int(16 * u), Color(1.0, 0.9, 0.6, qp), HORIZONTAL_ALIGNMENT_CENTER, 20.0 * u)
		shadow(font, Vector2(mx, byy + bh + 18.0 * u), "%d / %d FRIES EATEN ON THE WAY" % [tot, GS.FRY_CAP], int(12 * u), Color(1, 1, 1, 0.6))
		# the step on the way
		var ny = byy + bh + 46.0 * u
		var line1 = ""
		if tgt < 0:
			line1 = "ALL %d FRIES   %d / %d" % [GS.FRY_CAP, GS.FRY_CAP, GS.FRY_CAP]
		elif tgt == 3:
			line1 = "NEXT:  FIND 3 VISION FRIES   %d / 3" % tot
		else:
			line1 = "NEXT:  EAT %d FRIES   %d / %d" % [tgt, tot, tgt]
		var c1 = Color(0.75, 1.0, 0.75, 0.95) if tgt < 0 else Color(1, 0.96, 0.82, 0.98)
		shadow(font, Vector2(mx, ny), line1, int(18 * u), c1)
		if tgt > 0:
			var prev = 0
			for m2 in GS.MISSIONS:
				if m2 < tgt:
					prev = m2
			var fr = clamp(float(tot - prev) / float(max(tgt - prev, 1)), 0.0, 1.0)
			draw_rect(Rect2(Vector2(mx, ny + 8.0 * u), Vector2(340.0 * u, 5.0 * u)), Color(1, 1, 1, 0.16))
			draw_rect(Rect2(Vector2(mx, ny + 8.0 * u), Vector2(340.0 * u * fr, 5.0 * u)), Color(1.0, 0.84, 0.4, 0.95))
		var hint = ""
		for h in hud.MISSION_HINTS:
			if tot >= h[0]:
				hint = h[1]
		shadow(font, Vector2(mx, ny + 30.0 * u), hint, int(12 * u), Color(1, 1, 1, 0.6))
		# the bonus goals, each with its reward
		var yy = ny + 56.0 * u
		if qn > 0:
			draw_line(Vector2(mx, yy - 18.0 * u), Vector2(panel.end.x - 24.0 * u, yy - 18.0 * u), Color(1, 1, 1, 0.18), 1.5)
			shadow(font, Vector2(mx, yy), "BONUS GOALS  -  EACH ONE GIVES A REWARD", int(12 * u), Color(1.0, 0.84, 0.4, 0.8))
			yy += 24.0 * u
		for id in shown_q:
			var st = GS.quest_state(id)
			var done = st == "done"
			var isf = id == focus_id
			var qa = 0.7 if done else (1.0 if isf else 0.85)
			var qc = Color(0.7, 1.0, 0.8, qa) if done else Color(1.0, 0.92, 0.6, qa)
			var bs = 14.0 * u
			var glow = 0.5 + 0.5 * sin(t * 3.2) if isf else 0.0
			draw_rect(Rect2(mx, yy - 12.0 * u, bs, bs), Color(qc.r, qc.g, qc.b, (0.22 + 0.25 * glow) * qa), true)
			draw_rect(Rect2(mx, yy - 12.0 * u, bs, bs), qc, false, 1.5)
			if done:
				draw_line(Vector2(mx + 2.0 * u, yy - 5.0 * u), Vector2(mx + 5.0 * u, yy - 2.0 * u), qc, 2.0)
				draw_line(Vector2(mx + 5.0 * u, yy - 2.0 * u), Vector2(mx + 12.0 * u, yy - 11.0 * u), qc, 2.0)
			var qfs = int((16 if isf else 14) * u)
			var qlab = GS.quest_label(id)
			var is_pop = id == pop_id and pop_age >= 0.0
			if is_pop and pop_age < 2.3:
				var prg = GS.quest_progress(id)
				var tot_n = prg[1] if prg.size() == 2 else 1
				qlab = "%s   %d / %d" % [GS.QUESTS[id][1], int(round(tot_n * clamp(pop_age / 0.9, 0.0, 1.0))), tot_n]
			shadow(font, Vector2(mx + 24.0 * u, yy), qlab, qfs, qc)
			var rw = GS.QUESTS[id][3]
			var rcol = Color.from_hsv(fmod(t * 0.3, 1.0), 0.4, 1.0, qa) if id == "star" else Color(1.0, 0.82, 0.35, qa)
			var rtxt = "REWARD:  %s" % rw
			var lw = font.get_string_size(Loc.t(qlab), HORIZONTAL_ALIGNMENT_LEFT, -1, qfs).x
			if is_pop:
				if pop_age >= 0.9 and pop_age < 1.5:
					var fl = abs(sin((pop_age - 0.9) / 0.6 * PI * 2.0))
					draw_rect(Rect2(mx - 6.0 * u, yy - 18.0 * u, pw - 36.0 * u, 26.0 * u), Color(1.0, 0.96, 0.7, 0.42 * fl))
				if pop_age >= 1.55:
					var sk = clamp((pop_age - 1.55) / 0.45, 0.0, 1.0)
					draw_line(Vector2(mx + 22.0 * u, yy - 5.0 * u), Vector2(mx + 26.0 * u + lw * sk, yy - 5.0 * u), Color(1.0, 0.95, 0.75, 0.95), 2.5 * u)
			var rwid = font.get_string_size(Loc.t(rtxt), HORIZONTAL_ALIGNMENT_LEFT, -1, int(12 * u)).x
			if not isf and 24.0 * u + lw + 12.0 * u + rwid < pw - 30.0 * u:
				shadow(font, Vector2(panel.end.x - 16.0 * u - rwid, yy), rtxt, int(12 * u), rcol)
				yy += 22.0 * u
			else:
				yy += 17.0 * u
				shadow(font, Vector2(mx + 24.0 * u, yy), rtxt, int(12 * u), rcol)
				if isf:
					yy += 16.0 * u
					shadow(font, Vector2(mx + 24.0 * u, yy), GS.QUESTS[id][4], int(11 * u), Color(1, 1, 1, 0.78))
				yy += 21.0 * u

# BOTTOM MIDDLE (round 15): THE LESSON OF THE MOST IMPORTANT KEY. A big TAB keycap that presses itself with a ring of "hold", the words HOLD TAB, and - once the player
# does hold it - what to look at while the sight is open. It stays (smaller when ignored) until Gull Sight has been held for a few seconds, then thanks the player.
class TabLesson extends HC:
	var hud
	var a = 0.0
	func _cap(c, u, press, tt):
		var kw = 132.0 * u
		var kh = 80.0 * u
		var base = Rect2(c - Vector2(kw * 0.5, kh * 0.5 - 12.0 * u), Vector2(kw, kh))
		draw_rect(Rect2(base.position + Vector2(0, 8.0 * u), base.size), Color(0, 0, 0, 0.35 * a))
		draw_rect(base, Color(0.16, 0.18, 0.26, 0.96 * a))
		var capr = Rect2(base.position + Vector2(5.0 * u, (4.0 + 9.0 * press) * u), base.size - Vector2(10.0 * u, 16.0 * u))
		var face = Color(0.97, 0.95, 0.88, a).lerp(Color(1.0, 0.9, 0.55, a), press)
		draw_rect(capr, face)
		draw_rect(capr, Color(0.1, 0.1, 0.16, a), false, 3.0)
		var font = ThemeDB.fallback_font
		var tw_ = font.get_string_size(Loc.t("TAB"), HORIZONTAL_ALIGNMENT_LEFT, -1, int(34 * u)).x
		draw_string(font, capr.position + Vector2((capr.size.x - tw_) * 0.5, capr.size.y * 0.66), Loc.t("TAB"), HORIZONTAL_ALIGNMENT_LEFT, -1, int(34 * u), Color(0.12, 0.13, 0.2, a))
		return capr
	func _draw():
		var dt = get_process_delta_time() / max(Engine.time_scale, 0.05)
		var showing = (GS.tab_lesson == 1 or hud.lesson_done_t > 0.0) and not hud.quiet_busy and hud.quiet_bar < 0.02 and not GS.codex_open
		a = move_toward(a, 1.0 if showing else 0.0, 3.0 * dt)
		if a <= 0.01:
			return
		var u = size.y / 720.0
		var t = GS.msec() * 0.001
		var font = ThemeDB.fallback_font
		var holding = GS.sense_active
		var done = hud.lesson_done_t > 0.0
		var small = hud.lesson_idle > 50.0 and not holding and not done
		if small:
			u *= 0.62
		var cx = size.x * 0.5
		var cy = size.y * (0.80 if holding else (0.865 if done else 0.84))
		var press = 0.0
		if holding or done:
			press = 1.0
		else:
			var ph = fmod(t, 2.8) / 2.8
			press = smoothstep(0.08, 0.16, ph) * (1.0 - smoothstep(0.78, 0.86, ph))
			# a ring of attention that opens from the key whenever it is pressed
			var rr = fmod(t, 2.8) / 2.8
			draw_arc(Vector2(cx, cy), (50.0 + 90.0 * rr) * u, 0, TAU, 48, Color(1.0, 0.9, 0.5, 0.5 * (1.0 - rr) * a), 3.0 * u, true)
		var capr = _cap(Vector2(cx, cy), u, press, t)
		# the progress of the lesson: a ring that closes while the key is held
		var prog = clamp(GS.sight_time / 3.4, 0.0, 1.0)
		if holding and not done:
			draw_arc(capr.get_center(), 62.0 * u, -PI * 0.5, -PI * 0.5 + TAU * prog, 48, Color(0.65, 0.9, 1.0, 0.95 * a), 5.0 * u, true)
			draw_arc(capr.get_center(), 62.0 * u, 0, TAU, 48, Color(1, 1, 1, 0.15 * a), 5.0 * u, true)
		# the words
		var l1 = "HOLD  TAB"
		var l2 = "GULL SIGHT: SEE EVERYTHING WORTH STEALING"
		var c1 = Color(1.0, 0.96, 0.8, a)
		if done:
			l1 = "GOOD.  TAB IS YOURS."
			l2 = "HOLD IT ANY TIME. IT IS FREE ON THE GROUND."
			c1 = Color(0.7, 1.0, 0.8, a)
		elif holding:
			l1 = hud.lesson_line
			l2 = "KEEP HOLDING..." if prog < 1.0 else "NOW LET GO."
			c1 = Color(0.8, 0.95, 1.0, a)
		var s1 = int((30 if not holding else 22) * u)
		var w1 = font.get_string_size(Loc.t(l1), HORIZONTAL_ALIGNMENT_LEFT, -1, s1).x
		var py = cy - 76.0 * u
		var pill = Rect2(Vector2(cx - w1 * 0.5 - 22.0 * u, py - 30.0 * u), Vector2(w1 + 44.0 * u, 58.0 * u))
		draw_rect(pill, Color(0.03, 0.05, 0.1, 0.5 * a))
		draw_rect(Rect2(pill.position, Vector2(4.0 * u, pill.size.y)), Color(c1.r, c1.g, c1.b, 0.9 * a))
		shadow(font, Vector2(cx - w1 * 0.5, py), l1, s1, c1)
		var s2 = int(13 * u)
		var w2 = font.get_string_size(Loc.t(l2), HORIZONTAL_ALIGNMENT_LEFT, -1, s2).x
		shadow(font, Vector2(cx - w2 * 0.5, py + 21.0 * u), l2, s2, Color(1, 1, 1, 0.7 * a))

# TOP MIDDLE (round 15): a thing of the sky was caught. A word in its colour, five pips (the sky quest), and nothing else: the gull keeps flying, nothing is covered.
class SkyPop extends HC:
	var hud
	func _draw():
		var dt = get_process_delta_time() / max(Engine.time_scale, 0.05)
		var u = size.y / 720.0
		var font = ThemeDB.fallback_font
		var i = 0
		var y0 = 112.0 * u
		while i < hud.sky_pops.size():
			var p = hud.sky_pops[i]
			p["t"] += dt
			var t = p["t"]
			var dur = 2.8
			var a = clamp(min(t / 0.18, (dur - t) / 0.6), 0.0, 1.0)
			var col = hud.SKY_COL.get(p["kind"], Color.WHITE)
			var pop = 1.0 + 0.35 * max(0.0, 1.0 - t / 0.35)
			var sz = int(40.0 * u * pop)
			var word = hud.SKY_WORD.get(p["kind"], "!")
			var ww = font.get_string_size(Loc.t(word), HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
			var cx = size.x * 0.5
			var y = y0 + float(i) * 70.0 * u
			draw_string(font, Vector2(cx - ww * 0.5 + 2.0, y + 2.0), Loc.t(word), HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(0, 0, 0, 0.55 * a))
			draw_string(font, Vector2(cx - ww * 0.5, y), Loc.t(word), HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(col.r, col.g, col.b, a))
			for k in 5:
				var pc = Vector2(cx + (k - 2) * 26.0 * u, y + 24.0 * u)
				var lit = k < p["n"]
				var newest = k == p["n"] - 1
				var r = (7.0 + (5.0 * max(0.0, 1.0 - t / 0.5) if newest else 0.0)) * u
				draw_circle(pc, r + 2.0, Color(0.02, 0.03, 0.08, 0.6 * a))
				draw_circle(pc, r, Color(col.r, col.g, col.b, a) if lit else Color(1, 1, 1, 0.18 * a))
			if t > dur:
				hud.sky_pops.remove_at(i)
			else:
				i += 1

# BOTTOM RIGHT (round 15): an achievement of the gallery: its picture, its name and a line of the game's opinion
class AchToast extends HC:
	var hud
	var tex_cache = {}
	func _icon(id):
		if tex_cache.has(id):
			return tex_cache[id]
		var p = "res://assets/ui/achv/%s.png" % id
		var t = load(p) if ResourceLoader.exists(p) else null
		tex_cache[id] = t
		return t
	func _draw():
		if hud.ach_toasts.is_empty():
			return
		var dt = get_process_delta_time() / max(Engine.time_scale, 0.05)
		var g = hud.ach_toasts[0]
		g["t"] += dt
		var t = g["t"]
		var dur = 4.6
		var a = clamp(min(t / 0.3, (dur - t) / 0.6), 0.0, 1.0)
		var u = size.y / 720.0
		var font = ThemeDB.fallback_font
		var w = 430.0 * u
		var h = 92.0 * u
		var slide = (1.0 - clamp(t / 0.35, 0.0, 1.0)) * 60.0 * u
		var r = Rect2(Vector2(size.x - w - 26.0 * u + slide, size.y - h - 30.0 * u), Vector2(w, h))
		draw_rect(Rect2(r.position + Vector2(5, 6), r.size), Color(0, 0, 0, 0.3 * a))
		draw_rect(r, Color(0.07, 0.08, 0.13, 0.9 * a))
		draw_rect(r, Color(1.0, 0.84, 0.4, 0.9 * a), false, 2.5)
		var ir = Rect2(r.position + Vector2(10, 10) * u, Vector2(72, 72) * u)
		var tex = _icon(g["id"])
		if tex != null:
			draw_texture_rect(tex, ir, false, Color(1, 1, 1, a))
		else:
			draw_rect(ir, Color(1.0, 0.84, 0.4, 0.5 * a))
		var d = GS.ACH[g["id"]]
		shadow(font, r.position + Vector2(94, 26) * u, "ACHIEVEMENT UNLOCKED", int(11 * u), Color(1.0, 0.84, 0.4, a))
		shadow(font, r.position + Vector2(94, 49) * u, d[0], int(18 * u), Color(1, 0.98, 0.9, a))
		shadow(font, r.position + Vector2(94, 70) * u, d[2], int(11 * u), Color(1, 1, 1, 0.65 * a), HORIZONTAL_ALIGNMENT_LEFT, w - 104.0 * u)
		if t > dur:
			hud.ach_toasts.pop_front()
			Sfx.play("chime", -14.0, 1.1)

# TOP-RIGHT, STARLIGHT: the corner fills with starlight (a rainbow glow, slow rays, twinkling four-pointed stars) while all three drinks are at work,
# and a rainbow bar runs along the top edge to show how long it lasts.
class StarCorner extends HC:
	var hud
	var a = 0.0
	var seeds = []
	func _ready():
		for i in 38:
			seeds.append([randf(), randf(), randf(), randf()])
	func _star(c, r, col):
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.2, -r * 0.2), c + Vector2(r, 0), c + Vector2(r * 0.2, r * 0.2), c + Vector2(0, r),
			c + Vector2(-r * 0.2, r * 0.2), c + Vector2(-r, 0), c + Vector2(-r * 0.2, -r * 0.2)]), col)
	func _draw():
		var dt = get_process_delta_time() / max(Engine.time_scale, 0.1)
		a = move_toward(a, 1.0 if GS.star_active() else 0.0, dt * 1.6)
		if a <= 0.01:
			return
		var u = size.y / 720.0
		var t = GS.msec() * 0.001
		var corner = Vector2(size.x - 30.0 * u, 30.0 * u)
		for k in 8:
			draw_circle(corner, (330.0 - k * 36.0) * u, Color.from_hsv(fmod(t * 0.12 + k * 0.09, 1.0), 0.45, 1.0, 0.05 * a))
		for k in 9:
			var ang = PI * 0.5 + (k / 8.0) * (PI * 0.5) + sin(t * 0.7 + k) * 0.05
			var d1 = Vector2(cos(ang), sin(ang))
			draw_line(corner + d1 * 40.0 * u, corner + d1 * (420.0 + 80.0 * sin(t * 1.3 + k * 2.0)) * u, Color.from_hsv(fmod(t * 0.1 + k * 0.11, 1.0), 0.35, 1.0, 0.1 * a), 3.0 * u)
		for sd in seeds:
			var px = size.x - sd[0] * size.x * 0.36
			var py = sd[1] * size.y * 0.44
			var tw = 0.5 + 0.5 * sin(t * (1.5 + sd[2] * 3.0) + sd[3] * 6.0)
			var r = (3.0 + 9.0 * sd[2]) * u * (0.4 + tw)
			_star(Vector2(px, py), r, Color.from_hsv(fmod(sd[3] + t * 0.1, 1.0), 0.3, 1.0, (0.35 + 0.6 * tw) * a))
		# round 15: the two side edges glow in running rainbow colours (never in the middle of the picture)
		for sx in [0, 1]:
			var x_out = 0.0 if sx == 0 else size.x
			var x_in = (46.0 if sx == 0 else size.x - 46.0) * u if false else (60.0 * u if sx == 0 else size.x - 60.0 * u)
			var n = 8
			for k in n:
				var y0 = size.y * k / n
				var y1 = size.y * (k + 1) / n
				var c0 = Color.from_hsv(fmod(t * 0.25 + float(k) / n, 1.0), 0.55, 1.0, 0.17 * a)
				var c1 = Color.from_hsv(fmod(t * 0.25 + float(k + 1) / n, 1.0), 0.55, 1.0, 0.17 * a)
				draw_polygon(PackedVector2Array([Vector2(x_out, y0), Vector2(x_in, y0), Vector2(x_in, y1), Vector2(x_out, y1)]),
					PackedColorArray([c0, Color(c0.r, c0.g, c0.b, 0.0), Color(c1.r, c1.g, c1.b, 0.0), c1]))
		# the time left: a rainbow thread along the top edge
		var frac = clamp(GS.star_t / GS.star_sec(), 0.0, 1.0)
		var segs = 48
		for i in segs:
			var x0 = size.x * i / segs
			if x0 > size.x * frac:
				break
			draw_rect(Rect2(Vector2(x0, 0), Vector2(size.x / segs + 1.0, 5.0 * u)), Color.from_hsv(fmod(float(i) / segs + t * 0.3, 1.0), 0.55, 1.0, 0.95 * a))

# BOTTOM MIDDLE: a fish was caught. The fish, its name and rarity, how long and how heavy it was, and whether it is new in the book or a record.
class FishCard extends HC:
	var hud
	func _spaced(font, pos, text, sz, col, gap):
		text = Loc.t(text)
		var total = 0.0
		for ch in text:
			total += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x + gap
		var x = pos.x - total * 0.5
		for ch in text:
			draw_string(font, Vector2(x + 1.5, pos.y + 1.5), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(0, 0, 0, col.a * 0.7))
			draw_string(font, Vector2(x, pos.y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
			x += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x + gap
	func _draw():
		var dt = get_process_delta_time() / max(Engine.time_scale, 0.1)
		var u = size.y / 720.0
		var font = ThemeDB.fallback_font
		var i = 0
		while i < hud.fish_cards.size():
			var g = hud.fish_cards[i]
			g["t"] += dt
			var gt = g["t"]
			var dur = 4.6
			var info = g["info"]
			var sp = info["sp"]
			var d = GS.FISH_SPECIES[sp]
			var rar = d[1]
			var rc = GS.FISH_RARITY_COLORS[rar]
			var a = clamp(min(gt / 0.3, (dur - gt) / 0.8), 0.0, 1.0)
			var c = Vector2(size.x * 0.5, size.y * 0.7 + (1.0 - clamp(gt / 0.35, 0.0, 1.0)) * 36.0 * u)
			draw_circle(c + Vector2(0, -34.0 * u), 130.0 * u, Color(rc.r, rc.g, rc.b, 0.1 * a))
			if gt < 1.0:
				draw_arc(c + Vector2(0, -34.0 * u), (36.0 + 150.0 * gt) * u, 0, TAU, 56, Color(rc.r, rc.g, rc.b, (1.0 - gt) * 0.8 * a), 3.0 * u, true)
			var bob = sin(gt * 3.0) * 3.0 * u
			FishArt.draw(self, c + Vector2(-8.0 * u, -38.0 * u + bob), 50.0 * u * (0.85 + 0.15 * clamp(gt / 0.4, 0.0, 1.0)), sp, a)
			if rar >= 1:
				for q in 6:
					var a2 = gt * 1.7 + q * TAU / 6.0
					draw_circle(c + Vector2(-8.0 * u, -38.0 * u) + Vector2(cos(a2) * 82.0, sin(a2) * 48.0) * u, 2.6 * u, Color(rc.r, rc.g, rc.b, 0.9 * a))
			var ly = c.y + 36.0 * u
			draw_line(Vector2(c.x - 120.0 * u, ly - 20.0 * u), Vector2(c.x + 120.0 * u, ly - 20.0 * u), Color(rc.r, rc.g, rc.b, 0.7 * a), 1.5)
			_spaced(font, Vector2(c.x, ly - 5.0 * u), GS.FISH_RARITY_NAMES[rar] + " FISH", int(13 * u), Color(rc.r, rc.g, rc.b, a), 5.0 * u)
			_spaced(font, Vector2(c.x, ly + 20.0 * u), d[0], int(22 * u), Color(1, 0.98, 0.92, a), 1.5 * u)
			shadow(font, Vector2(c.x - 200.0 * u, ly + 42.0 * u), "%s     %s" % [GS.fish_cm_text(info["len"]), GS.fish_kg_text(info["kg"])], int(15 * u), Color(1, 1, 1, 0.85 * a), HORIZONTAL_ALIGNMENT_CENTER, 400.0 * u)
			var tag = ""
			if info["new"]:
				tag = "NEW IN THE FISH BOOK"
			elif info["rec_len"] and info["rec_kg"]:
				tag = "NEW RECORD   LONGEST AND HEAVIEST"
			elif info["rec_len"]:
				tag = "NEW RECORD   LONGEST"
			elif info["rec_kg"]:
				tag = "NEW RECORD   HEAVIEST"
			if tag != "":
				shadow(font, Vector2(c.x - 200.0 * u, ly + 62.0 * u), tag, int(13 * u), Color(1.0, 0.86, 0.45, (0.75 + 0.25 * sin(gt * 6.0)) * a), HORIZONTAL_ALIGNMENT_CENTER, 400.0 * u)
			if gt > dur:
				hud.fish_cards.remove_at(i)
			else:
				i += 1

# TOP MIDDLE (round 18): the COACH. Four steps of getting a fry, with the key of each, the one you are on lit up, the ones you did ticked off, and one line of what to do right now.
# main.gd `_coach_tick` decides the step from what the gull is really doing; the card is there for the first fries and comes back whenever a player has been stuck for a while.
class Coach extends HC:
	var hud
	var a = 0.0
	func _key(c, w, h, txt, col, a2, u):
		var r = Rect2(c - Vector2(w, h) * 0.5, Vector2(w, h))
		draw_rect(Rect2(r.position + Vector2(0, 4.0 * u), r.size), Color(0, 0, 0, 0.4 * a2))
		draw_rect(r, Color(0.96, 0.94, 0.86, a2))
		draw_rect(r, Color(0.1, 0.1, 0.16, a2), false, 2.0)
		var f = ThemeDB.fallback_font
		var sz = int(15 * u)
		var tw = f.get_string_size(Loc.t(txt), HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		draw_string(f, Vector2(c.x - tw * 0.5, c.y + 5.5 * u), Loc.t(txt), HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(0.12, 0.13, 0.2, a2))
	func _draw():
		var dt = get_process_delta_time() / max(Engine.time_scale, 0.05)
		var cd = hud.coach
		var show = cd != null and cd.get("show", false) and not hud.quiet_busy and hud.quiet_bar < 0.02 and not GS.codex_open
		a = move_toward(a, 1.0 if show else 0.0, 3.5 * dt)
		if a <= 0.01 or cd == null:
			return
		var u = size.y / 720.0
		var t = GS.msec() * 0.001
		var font = ThemeDB.fallback_font
		var steps = cd["steps"]
		var cur = int(cd["step"])
		var n = steps.size()
		var cw = 94.0 * u
		var gap = 8.0 * u
		var total = n * cw + (n - 1) * gap
		var x0 = size.x * 0.33
		var y0 = (14.0 + (46.0 if GS.is_hard() else 0.0)) * u
		var ch = 58.0 * u
		draw_rect(Rect2(Vector2(x0 - 12.0 * u, y0 - 8.0 * u), Vector2(total + 24.0 * u, ch + 86.0 * u)), Color(0.03, 0.05, 0.1, 0.62 * a))
		draw_rect(Rect2(Vector2(x0 - 12.0 * u, y0 - 8.0 * u), Vector2(total + 24.0 * u, ch + 86.0 * u)), Color(1.0, 0.84, 0.4, 0.4 * a), false, 1.5)
		for i in n:
			var st = steps[i]
			var px = x0 + i * (cw + gap)
			var done = i < cur
			var on = i == cur
			var pul = 0.5 + 0.5 * sin(t * 6.0) if on else 0.0
			var bc = Color(0.55, 0.9, 0.6, 0.9 * a) if done else (Color(1.0, 0.84 + 0.1 * pul, 0.35, (0.9 + 0.1 * pul) * a) if on else Color(1, 1, 1, 0.25 * a))
			var fillc = Color(0.2, 0.3, 0.22, 0.7 * a) if done else (Color(0.3, 0.26, 0.1, 0.75 * a) if on else Color(0.08, 0.1, 0.16, 0.6 * a))
			draw_rect(Rect2(Vector2(px, y0), Vector2(cw, ch)), fillc)
			draw_rect(Rect2(Vector2(px, y0), Vector2(cw, ch)), bc, false, (3.5 if on else 2.0))
			if on:
				draw_rect(Rect2(Vector2(px - 4.0 * u, y0 - 4.0 * u), Vector2(cw + 8.0 * u, ch + 8.0 * u)), Color(1.0, 0.9, 0.5, 0.25 * pul * a), false, 2.0)
			var kw = max(36.0 * u, 18.0 * u + 8.0 * u * str(st["key"]).length())
			_key(Vector2(px + 10.0 * u + kw * 0.5, y0 + 22.0 * u), kw, 26.0 * u, st["key"], bc, a * (1.0 if (on or done) else 0.6), u)
			var lbl = st["label"]
			var lc = Color(1, 1, 1, (0.95 if on else 0.7) * a)
			shadow(font, Vector2(px + 8.0 * u, y0 + 50.0 * u), lbl, int(12 * u), lc)
			if done:
				var ck = Vector2(px + cw - 16.0 * u, y0 + 20.0 * u)
				draw_line(ck + Vector2(-8, 0) * u, ck + Vector2(-2, 7) * u, Color(0.6, 1.0, 0.7, a), 3.5)
				draw_line(ck + Vector2(-2, 7) * u, ck + Vector2(9, -8) * u, Color(0.6, 1.0, 0.7, a), 3.5)
			if i < n - 1:
				var ax = px + cw + gap * 0.5
				draw_colored_polygon(PackedVector2Array([Vector2(ax - 5.0 * u, y0 + ch * 0.5 - 7.0 * u), Vector2(ax + 6.0 * u, y0 + ch * 0.5), Vector2(ax - 5.0 * u, y0 + ch * 0.5 + 7.0 * u)]), Color(1, 1, 1, 0.45 * a))
		var line = str(cd.get("line", ""))
		if line != "":
			var lt = Loc.t(line)
			draw_multiline_string(font, Vector2(x0 - 5.0 * u, y0 + ch + 23.0 * u), lt, HORIZONTAL_ALIGNMENT_LEFT, total + 10.0 * u, int(14 * u), 2, Color(0, 0, 0, 0.7 * a))
			draw_multiline_string(font, Vector2(x0 - 6.0 * u, y0 + ch + 22.0 * u), lt, HORIZONTAL_ALIGNMENT_LEFT, total + 10.0 * u, int(14 * u), 2, Color(1.0, 0.96, 0.8, a))

# TOP MIDDLE (round 18, HARD): the race clock. The time of this run so far and the best time to the 24 fries.
class RaceClock extends HC:
	var hud
	func _draw():
		if not GS.is_hard() or hud.film_clean or GS.codex_open:
			return
		var u = size.y / 720.0
		var font = ThemeDB.fallback_font
		var tx = GS.time_text(GS.hard_clock)
		var best = ("BEST  %s" % GS.time_text(GS.hard_best)) if GS.hard_best > 0.0 else "NO RECORD YET"
		var run_done = GS.hard_last > 0.0
		var col = Color(0.7, 1.0, 0.8, 0.95) if run_done else Color(1.0, 0.82, 0.55, 0.95)
		var w = 300.0 * u
		var r = Rect2(Vector2(size.x * 0.5 - w * 0.5, 8.0 * u), Vector2(w, 38.0 * u))
		draw_rect(r, Color(0.03, 0.05, 0.1, 0.55))
		draw_rect(r, Color(col.r, col.g, col.b, 0.5), false, 1.5)
		shadow(font, r.position + Vector2(12.0 * u, 26.0 * u), "HARD", int(13 * u), Color(1.0, 0.55, 0.4, 0.95))
		shadow(font, r.position + Vector2(60.0 * u, 27.0 * u), tx if not run_done else GS.time_text(GS.hard_last), int(22 * u), col)
		shadow(font, r.position + Vector2(w - 12.0 * u - 150.0 * u, 25.0 * u), best, int(12 * u), Color(1, 1, 1, 0.65), HORIZONTAL_ALIGNMENT_RIGHT, 150.0 * u)

class Streaks extends Control:
	var hud
	var seeds = []
	func _ready():
		for i in 64:
			seeds.append([randf() * TAU, randf(), randf()])
	func _draw():
		var p = hud.player
		if p == null:
			return
		var sv = p.star_t_vis
		var n = clamp((p.speed - 14.0) / 10.0, 0.0, 1.0)
		n = max(n, clamp((p.speed - 10.0) / 14.0, 0.0, 1.0) * sv)
		if n <= 0.02:
			return
		var c = size * 0.5
		var t = GS.msec() * 0.001
		var cnt = 30 + int(34.0 * sv)
		for si in cnt:
			var s = seeds[si]
			var ang = s[0]
			var ph = fmod(t * (1.2 + s[2] * (1.0 + 1.6 * sv)) + s[1], 1.0)
			var r0 = size.length() * (0.30 + 0.14 * ph - 0.06 * sv)
			var r1 = r0 + size.length() * (0.06 + 0.1 * n + 0.1 * sv) * (0.4 + s[2])
			var d = Vector2(cos(ang), sin(ang))
			var col = Color(1, 1, 1, 0.22 * n * (1.0 - ph))
			if sv > 0.05:
				col = Color.from_hsv(fmod(s[1] + t * 0.2, 1.0), 0.35 * sv, 1.0, (0.2 + 0.2 * sv) * n * (1.0 - ph))
			draw_line(c + d * r0, c + d * r1, col, 2.0 + 1.5 * sv)
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
	starfx = StarCorner.new()
	starfx.hud = self
	_full(starfx)
	ui_root.add_child(starfx)
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
	arc = FryGrid.new()
	arc.hud = self
	_full(arc)
	ui_root.add_child(arc)
	banner = Banner.new()
	banner.hud = self
	_full(banner)
	ui_root.add_child(banner)
	fishcard = FishCard.new()
	fishcard.hud = self
	_full(fishcard)
	ui_root.add_child(fishcard)
	lesson_ui = TabLesson.new()
	lesson_ui.hud = self
	_full(lesson_ui)
	ui_root.add_child(lesson_ui)
	coach_ui = Coach.new()
	coach_ui.hud = self
	_full(coach_ui)
	ui_root.add_child(coach_ui)
	clock_ui = RaceClock.new()
	clock_ui.hud = self
	_full(clock_ui)
	ui_root.add_child(clock_ui)
	skypop = SkyPop.new()
	skypop.hud = self
	_full(skypop)
	ui_root.add_child(skypop)
	achui = AchToast.new()
	achui.hud = self
	_full(achui)
	ui_root.add_child(achui)
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
	hint_label.anchor_top = 0.875
	hint_label.anchor_bottom = 0.875
	hint_label.modulate.a = 0.0
	ui_root.add_child(hint_label)
	whisper_label = _lbl("", 17, Color(1, 0.96, 0.88), 4)
	whisper_label.anchor_left = 0.0
	whisper_label.anchor_right = 1.0
	whisper_label.anchor_top = 0.94
	whisper_label.anchor_bottom = 0.94
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
	toast_box.offset_left = -520
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
	GS.achievement_unlocked.connect(func(id): ach_toasts.append({"id": id, "t": 0.0}); Sfx.play("reward_2", -10.0, 1.3))
	GS.sky_caught.connect(func(kind, n): sky_pops.append({"kind": kind, "n": n, "t": 0.0}))
	GS.player_hurt.connect(_on_hurt)
	GS.fry_got.connect(_on_fry_got)
	GS.quest_done.connect(_on_quest_done)
	GS.fish_caught.connect(func(info):
		fish_cards.append({"info": info, "t": 0.0})
		Sfx.play("fry_fly", -12.0, 1.3))
	GS.comic.connect(func(cid, cap, extra): show_comic(cid, cap, 2.8, extra))
	quiet_label = VBoxContainer.new()
	quiet_label.anchor_left = 0.0
	quiet_label.anchor_right = 1.0
	quiet_label.anchor_top = 0.4
	quiet_label.anchor_bottom = 0.4
	quiet_label.add_theme_constant_override("separation", 14)
	quiet_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 4:
		var ql = _lbl("", 34 if i == 0 else 27, Color(1, 0.97, 0.88), 10)
		ql.modulate.a = 0.0
		quiet_label.add_child(ql)
	quiet_back = ColorRect.new()
	quiet_back.anchor_left = 0.0
	quiet_back.anchor_right = 1.0
	quiet_back.anchor_top = 0.36
	quiet_back.anchor_bottom = 0.66
	quiet_back.color = Color(0.02, 0.04, 0.1, 0.0)
	quiet_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(quiet_back)
	move_child(quiet_back, quiet_label.get_index())
	add_child(quiet_label)
	reset_ui()

func reset_ui():
	fish_cards = []
	collected = {}
	slots_visible = false
	gains = []
	objective_title.text = ""
	objective_count.text = ""

func _process(delta):
	if player == null:
		return
	if reticle.pulse_t > 0.0:
		reticle.pulse_t = max(reticle.pulse_t - delta, 0.0)
	var real_dt = delta / max(Engine.time_scale, 0.05)
	lb = lerp(lb, max(player.snatch.letterbox, quiet_bar), 1.0 - exp(-14.0 * real_dt))
	var focusing = (player.snatch.lock_fry != null and player.snatch.state == "idle") or player.snatch.state == "cine"
	focus_a = move_toward(focus_a, 1.0 if focusing else 0.0, 5.0 * real_dt)
	banner.queue_redraw()
	starfx.queue_redraw()
	fishcard.queue_redraw()
	lesson_ui.queue_redraw()
	coach_ui.queue_redraw()
	clock_ui.queue_redraw()
	skypop.queue_redraw()
	achui.queue_redraw()
	lesson_done_t = max(lesson_done_t - real_dt, 0.0)
	lesson_idle = lesson_idle + real_dt if (GS.tab_lesson == 1 and not GS.sense_active) else 0.0
	var pa = 1.0 if prompt_text != "" else 0.0
	prompt_label.modulate.a = move_toward(prompt_label.modulate.a, pa, 4.0 * real_dt)
	if prompt_text != "" and prompt_label.text != prompt_text:
		prompt_label.text = prompt_text
	# during focus the middle of the screen is busy: the instruction moves up under the title
	var ay = 0.14 if player.snatch.lock_fry != null else 0.82
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

# the "you got a fry" moment (never pauses, never covers the middle of the screen): the fry rises from the lower middle with its rarity in
# light and one line of what it does, then flies into its square of the top-left box and lights it (see FryGrid)
func _on_fry_got(type, tier):
	var slot = 0
	if type == "tutorial":
		slot = clamp(GS.gull_sense_count - 1, 0, 2)
	elif tier >= 1 and tier <= 3:
		slot = tier - 1
	elif tier >= 4:
		slot = 3
	var nm = ""
	var ln = ""
	var rar = ""
	if type == "tutorial":
		nm = ["CORNER TABLE FRY", "SEASIDE PLATE FRY", "HOT HANDHELD FRY"][clamp(GS.gull_sense_count - 1, 0, 2)]
		ln = "VISION FRY   %d / 3" % GS.gull_sense_count
		rar = "COMMON"
	elif tier >= 4:
		nm = GS.fry_name(type, 4)
		ln = GS.rainbow_text(type)
		rar = "RAINBOW"
	else:
		nm = GS.fry_name(type, tier)
		ln = GS.STAT_NAMES[type] + "   " + GS.ability_text(type, tier).split("   -   ")[0]
		rar = GS.RARITY_NAMES[clamp(tier, 0, 4)]
	var dur = 3.2
	if tier >= 4:
		dur = 2.0
	elif type == "tutorial":
		dur = 2.6
	gains.append({"type": type, "tier": tier, "t": 0.0, "slot": slot, "name": nm, "line": ln, "rarity": rar, "dur": dur})
	# the gull works it out for itself (small print, only for the first two fries): the slow time was the whole trick
	if type == "tutorial":
		var wl = ["that slow moment... that's a gull's whole trick.", "the closer the fry, the slower the world. it's called gull time."]
		var wi = GS.gull_sense_count - 1
		if wi >= 0 and wi < wl.size():
			get_tree().create_timer(2.6, true, false, true).timeout.connect(func(): whisper(wl[wi], 5.0))
	Sfx.play("fry_fly", -10.0)

# the fry reached its square
func fry_arrived(g):
	Sfx.play("equip", -14.0, 1.4)

# a side quest is finished (fish / cloud / sun): all the UI melts away, the bars come in, and the gull thinks out loud:
# "i caught the sun... and somehow i'm still hungry." Then everything returns. It is a moment of quiet, not a prize screen.
func _on_quest_done(id):
	if not (id in GS.BIG_QUESTS):
		# a small task: the board slides in, the number runs up, the line flashes and is struck through (round 19: no more toast), with a soft chime
		GS.quest_pop(id)
		Sfx.play("chime", -12.0, 1.25)
		return
	if id == "sun" or id == "skybow" or id == "cloud":
		return                      # round 9: these two have a short cinematic of their own (story_scenes.gd), with the same words
	# round 19: the thing that was caught comes FIRST (its own little moment), then the goal board ticks off the whole sky, then the film of the whole sky
	_when_scenes_free(func():
		GS.quest_pop(id)
		Sfx.play("chime", -12.0, 1.25)
		get_tree().create_timer(GS.QUEST_POP_SEC - 0.3, true, false, true).timeout.connect(func(): _big_quest_film(id)))

func _when_scenes_free(cb, tries = 0):
	var m = get_tree().current_scene
	var busy = (not m.cine_queue.is_empty()) or m.scenes.cine_busy or m.scenes.beat_busy or quiet_busy or GS.msec() - m.scenes.cine_done_at < 1800
	if busy and tries < 160:
		get_tree().create_timer(0.5, true, false, true).timeout.connect(func(): _when_scenes_free(cb, tries + 1))
		return
	cb.call()

func _big_quest_film(id):
	var sc = get_tree().current_scene.scenes
	if sc.has_beat("quest_" + id):
		sc.beat_moment("quest_" + id)       # round 10: a beat (a word and three short lines), not a minute of bars
	else:
		quiet_moment(Array(GS.QUESTS[id][2].split("|")))

# ROUND 9: the "light film mode". The gull keeps flying (nothing is locked, time does not slow); the interface melts away, two thin bars come in, and 1-4 short
# lines appear in the middle of the picture one after the other. Used for the first coffee / cocktail / ice cream, the first fish, a cloud, the fish book.
var quiet_queue = []
var quiet_busy = false
func quiet_moment(lines):
	if quiet_busy:
		quiet_queue.append(lines)
		return
	quiet_busy = true
	var n = min(lines.size(), 4)
	var tw = create_tween().set_ignore_time_scale(true)
	for i in 4:
		quiet_label.get_child(i).text = lines[i] if i < n else ""
		quiet_label.get_child(i).modulate.a = 0.0
	tw.tween_property(ui_root, "modulate:a", 0.0, 0.6)
	tw.parallel().tween_property(self, "quiet_bar", 0.34, 0.8)
	tw.tween_interval(0.35)
	tw.tween_property(quiet_back, "color:a", 0.3, 0.7)
	for i in n:
		if i == 0:
			tw.parallel().tween_property(quiet_label.get_child(i), "modulate:a", 1.0, 0.7)
		else:
			tw.tween_property(quiet_label.get_child(i), "modulate:a", 1.0, 0.7)
		tw.tween_interval(clamp(0.9 + String(lines[i]).length() * 0.03, 1.3, 2.5) if i < n - 1 else 2.3)
	tw.tween_callback(func(): Sfx.schedule_growl(0.2))
	for i in n:
		tw.tween_property(quiet_label.get_child(i), "modulate:a", 0.0, 0.7 if i == 0 else 0.0)
	tw.tween_property(quiet_back, "color:a", 0.0, 0.7)
	tw.tween_property(ui_root, "modulate:a", 1.0, 0.8)
	tw.parallel().tween_property(self, "quiet_bar", 0.0, 0.9)
	tw.tween_callback(func():
		quiet_busy = false
		if quiet_queue.size() > 0:
			quiet_moment(quiet_queue.pop_front()))

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
