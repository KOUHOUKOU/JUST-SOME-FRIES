extends Node
# DIVE -> LOCK -> RHYTHM -> close-up -> yours   (round 6: no more escape check, a much harder grab)
#
# One key, E, and a small rhythm game. The fry is surrounded by target CIRCLES (a thick green ring with a thin gold ring just inside it).
# Every circle sends TWO white waves shrinking onto it, one after the other; circle after circle, quickly. Each wave is one judgement:
#   press E when the wave is in the green band = 1 point; when it is in the gold band = 2 points; too early / too late = 0 points.
# You need as many points as there are waves (a gold press pays for two). The number of circles depends on the rarity of the fry:
#   tutorial / rainbow  1 circle   (2 waves)      silver (rare)    2 circles, top to bottom   (4 waves)
#   gold (epic)         3 circles, top to bottom   (6 waves)      diamond (legendary)  5 circles like the olympic rings  (10 waves)
#   things (hats, drinks, ice cream, fish...)  1 circle, 1 wave.
# Every E press judges the OLDEST wave that has not been judged yet. A press too early (before the green) or a wave that slips past is a miss.
# Enough points = the fry is yours (the rhythm ends at once). The waves run in REAL time (the world only slows down for atmosphere); presses are time-stamped.
# ROUND 18b: in HARD (`GS.dp("single")`) there is ONE band, the gold one, as wide as the old green band: the tune plays by itself, every wave is a beat of it and an E counts only
# when the white wave is in the band (a hit = 1 point, a quarter of the waves may be missed); a hit adds a bright note on top of the beat. EASY keeps the two bands, and the
# waves of the silver / gold / diamond fries run faster and faster (`ladder`), with thinner bands (`band_lad`).
# STEADY BEAK (green) fries widen the bands and slow the waves. The crowd's attention thins the bands. Coffee: wider bands and a deeper slow-motion.
const Tunes = preload("res://scripts/systems/tunes.gd")
const LOCK_GRACE = 0.14         # presses in the first moments of a rhythm are ignored (that E was meant for something else)
# ROUND 16 / 18: every good press plays the next note of a TUNE (systems/tunes.gd). The sequence of one catch is a little song as long as the catch has judgements (every point is a
# note): a green press plays one note, a gold press (worth two points) plays two (the second a breath later), so a perfect run still sings the whole tune. A miss is a hole in the
# song: the tune waits for the next good press. Round 18: the song is picked at random from a library of gentle public-domain melodies, one family per kind of catch.

const MISS_GRACE = 0.03         # a wave that has passed its gold by this much is a miss
const GOLD_GRACE = 0.02         # ...and a gold press may be this late
const SEQ_TS_MIN = 0.2
const SEQ_TS_MAX = 0.8
const STAND_OFF = 1.7           # the guided approach stops this far from the fry; the close-up does the last bit
const APPR = 0.56               # seconds a white wave takes to shrink onto its circle
# per tier: circles, waves per circle, time of the first wave, gap between waves, gold width, green (outer) width  - all in real seconds
const SEQ_TIER = {
	0: {"c": 1, "w": 2, "lead": 0.85, "gap": 0.40, "gw": 0.06, "gg": 0.115},     # things: hats, drinks, ice cream  (round 9: every circle is judged twice)
	1: {"c": 2, "w": 2, "lead": 0.85, "gap": 0.36, "gw": 0.05, "gg": 0.095},    # silver / rare
	2: {"c": 3, "w": 2, "lead": 0.85, "gap": 0.33, "gw": 0.045, "gg": 0.085},   # gold / epic
	3: {"c": 5, "w": 2, "lead": 0.85, "gap": 0.29, "gw": 0.04, "gg": 0.075},    # diamond / legendary
	4: {"c": 1, "w": 2, "lead": 0.85, "gap": 0.42, "gw": 0.06, "gg": 0.11},     # (old rainbow, unused)
	5: {"c": 1, "w": 2, "lead": 0.85, "gap": 0.48, "gw": 0.05, "gg": 0.10},     # fish, common: 1 circle x 2
	6: {"c": 5, "w": 2, "lead": 0.85, "gap": 0.29, "gw": 0.03, "gg": 0.06},     # cloud / sun: five circles x 2 like a diamond fry (STARLIGHT is always on, x1.5 bands)
	7: {"c": 3, "w": 2, "lead": 0.85, "gap": 0.36, "gw": 0.045, "gg": 0.09},    # fish, rare: 3 x 2
	8: {"c": 5, "w": 2, "lead": 0.85, "gap": 0.30, "gw": 0.04, "gg": 0.08},     # fish, legendary: 5 x 2
	9: {"c": 7, "w": 2, "lead": 0.85, "gap": 0.30, "gw": 0.04, "gg": 0.075},    # RAINBOW fry: round 18: SEVEN circles (the seven colours, laid out as an arch) x 2
	10: {"c": 5, "w": 2, "lead": 0.85, "gap": 0.29, "gw": 0.03, "gg": 0.06},    # a shooting star: five circles x 2
	11: {"c": 7, "w": 2, "lead": 0.85, "gap": 0.28, "gw": 0.03, "gg": 0.06},    # the rainbow in the sky: seven circles x 2 = 14 judgements
	12: {"c": 9, "w": 2, "lead": 0.85, "gap": 0.26, "gw": 0.03, "gg": 0.06},    # round 16: the SUN: nine suns, nine circles x 2 = 18 judgements (orange + gold)
	13: {"c": 9, "w": 2, "lead": 0.85, "gap": 0.26, "gw": 0.03, "gg": 0.06},    # round 16: the MOON asks as much as the sun (blue + gold)
}
const TUT_SEQ = {"TUTORIAL_01": {"c": 1, "w": 2, "lead": 1.1, "gap": 0.55, "gw": 0.09, "gg": 0.2}, "TUTORIAL_02": {"c": 1, "w": 2, "lead": 1.0, "gap": 0.5, "gw": 0.075, "gg": 0.16},
	"TUTORIAL_03": {"c": 1, "w": 2, "lead": 0.95, "gap": 0.46, "gw": 0.065, "gg": 0.13}}
const ARCH_MULT = {"elder": 1.0, "elder_poke": 1.0, "adult": 0.94, "parent": 0.94, "vendor": 0.94, "child": 0.85}
# where the circles sit around the fry (x, y in units of the layout spacing)
const LAYOUTS = {
	1: [[0.0, 0.0]],
	2: [[0.0, -0.5], [0.0, 0.5]],
	3: [[0.0, -1.0], [0.0, 0.0], [0.0, 1.0]],
	5: [[-1.0, -0.5], [0.0, -0.5], [1.0, -0.5], [-0.5, 0.5], [0.5, 0.5]],       # the olympic rings: three on top, two between them below, none touching
	7: [[-3.0, 0.6], [-2.0, -0.2], [-1.0, -0.7], [0.0, -0.9], [1.0, -0.7], [2.0, -0.2], [3.0, 0.6]],   # a rainbow: seven circles on an arch, left to right = red to violet
	9: [[-1.0, -1.0], [0.0, -1.0], [1.0, -1.0], [-1.0, 0.0], [0.0, 0.0], [1.0, 0.0], [-1.0, 1.0], [0.0, 1.0], [1.0, 1.0]],   # round 16: nine suns in a 3 x 3 square
}

var player
var state = "idle"        # idle | cine | carry
var hud_state = "none"    # none | slow | ok | locked | eat
var lock_fry = null
var seq = null            # the running rhythm (see _seq_begin) or null
var need_speed = 10.0     # speed the gauge marks as "GRAB" for the current target
var need_tier = 0         # rarity of that target (colours the GRAB line)
var ring_world = Vector3.ZERO

var carry_fry = null
var carry_t = 0.0
var carry_need = 0.6
var carry_perfect = false
var snatch_cd = 0.0
var flash = 0
var flash_t = 0.0
var toast = ""
var toast_t = 0.0
var note = ""             # faint small print under the reticle (e.g. "the crowd was on high alert")
var note_t = 0.0
var letterbox = 0.0
var near_target = null
var cine = {}
var clean_run = true
var perfect_streak = 0
var last_commit = {}
var focus_owned = false
var presses = []           # real-time (usec) stamps of E presses not judged yet
var seq_ts = 0.5           # the world speed the current rhythm wants
var seq_from = Vector3.ZERO
var seq_to = Vector3.ZERO
var last_step_usec = 0
var tut_assist = false     # kept for the tutorial director in main.gd
var slow_t = 0.0           # round 18: cool-down of the "TOO SLOW" line in Gull Sight
var fish_lock = null       # round 18b: the fish that TAB has locked while OCEAN TIME runs and the gull sits on the water (SPACE then launches straight at it)
var fish_pick_t = 0.0
var hit_fx_res = ""        # round 19: the last good judgement ("green" | "gold"), when (msec) and for which kind of catch: the corner glow of the hud
var hit_fx_t = -10000
var hit_fx_tier = 0

func _ready():
	pass

func _input(event):
	if event.is_action_pressed("interact") and not event.is_echo():
		presses.append(GS.usec() - int(GS.input_offset_ms * 1000.0))        # round 18: the player's timing offset (pause menu)
		if presses.size() > 8:
			presses.pop_front()

func on_hit():
	# the player was swatted
	if carry_fry != null:
		drop_carry()
	_seq_abort()
	clean_run = false
	flash = -1
	flash_t = 0.3

# the carried fry is lost: it falls to the floor and vanishes (the owner reorders a fresh one a little later)
func drop_carry():
	var f = carry_fry
	carry_fry = null
	state = "idle"
	hud_state = "none"
	snatch_cd = 1.5
	_seq_abort()
	if f != null and is_instance_valid(f):
		f.fall_and_vanish(8.0 if f.id.begins_with("TUTORIAL") else 16.0)
		if f.npc != null:
			f.npc.on_failed(1.0)
		GS.stats["shot"] += 1
		_fail_note()
	perfect_streak = 0

func step(delta):
	snatch_cd = max(snatch_cd - delta, 0.0)
	toast_t = max(toast_t - delta, 0.0)
	note_t = max(note_t - delta, 0.0)
	flash_t = max(flash_t - delta, 0.0)
	if flash_t <= 0.0:
		flash = 0
	if state == "idle" and lock_fry == null:
		presses.clear()
	hud_state = "none"
	near_target = null
	var now = GS.usec()
	if seq != null and last_step_usec > 0 and now - last_step_usec > 250000:
		seq["t0"] += now - last_step_usec     # the game was paused: the rhythm waits too
	last_step_usec = now
	# round 19, THE SEA FREEZE: a fish that leaves the water frees its node while the rhythm on it is still running. A freed lock reads as `null`, so nothing ever released the gull:
	# the rhythm stayed on, input stayed locked, the gull fell back on the sea and could neither move nor take off. A rhythm whose fry is gone is let go at once.
	if seq != null and state == "idle" and not is_instance_valid(lock_fry):
		_unlock()
		Engine.time_scale = 1.0
		focus_owned = false
	_focus_time(delta)
	_fish_lock_tick(delta)
	match state:
		"cine":
			_update_cine(delta / max(Engine.time_scale, 0.02))
			return
		"carry":
			_update_carry(delta)
			return
	_scan(delta)
	_sniff()

# ------------------------------------------------------------------ OCEAN TIME: TAB locks a fish, SPACE launches at it
# Sitting on the water while OCEAN TIME runs, TAB (Gull Sight) picks the fish that is nearest to the middle of the view, rings it and keeps it (the lock stays when TAB is let go
# until the fish is gone). SPACE then launches straight at the place where that fish WILL be (the launch is aimed, see `fish_aim_point`), and for the first moments of the climb
# the beak is drawn towards it. A fish caught in the air (a dive, a flat flight) is judged as ever.
func _fish_lock_tick(delta):
	var p = player
	var sitting = GS.fish_active() and p.on_water and p.mode == 1
	var launching = GS.fish_active() and p.mode == 0 and p.launch_t > 0.0
	if fish_lock != null:
		var f0 = fish_lock
		if not is_instance_valid(f0) or f0.taken or not f0.available or not (sitting or launching):
			_clear_fish_lock()
	if launching:
		if fish_lock != null and p.launch_t > 0.9:
			var tp = fish_aim_point(p.global_position, max(p.launch_speed, 20.0))
			if tp != null:
				var dn = (tp - p.global_position).normalized()
				var k = 1.0 - exp(-5.0 * delta / max(Engine.time_scale, 0.1))
				p.aim_yaw = lerp_angle(p.aim_yaw, atan2(-dn.x, -dn.z), k)
				p.aim_pitch = lerp(p.aim_pitch, clamp(asin(clamp(dn.y, -1.0, 1.0)), -0.2, 1.0), k)
		return
	if not sitting or p.input_locked or not GS.sense_active:
		return
	var cam = get_viewport().get_camera_3d()
	if cam == null:
		return
	var fwd = -cam.global_transform.basis.z
	var origin = cam.global_position
	var best = null
	var best_s = -9.0
	var cur_s = -9.0
	for f in get_tree().get_nodes_in_group("fish_live"):
		if not is_instance_valid(f) or f.taken or not f.available or not f.visible:
			continue
		var to = f.global_position - origin
		var d = to.length()
		if d > 95.0 or d < 1.0:
			continue
		var dot = fwd.dot(to / d)
		if dot < 0.5:
			continue
		var sc = dot - d / 260.0           # the middle of the view first, the nearer one breaks a tie
		if f == fish_lock:
			cur_s = sc
		if sc > best_s:
			best_s = sc
			best = f
	if best == null or best == fish_lock:
		return
	if fish_lock != null and best_s < cur_s + 0.06:
		return                             # no jumping about between two fish
	if fish_lock != null and is_instance_valid(fish_lock):
		fish_lock.set_marked(false)
	fish_lock = best
	fish_lock.set_marked(true)
	Sfx.play("alert", -13.0, 1.7)
	Sfx.play_note("tinkle", 91, -10.0)

func _clear_fish_lock():
	if fish_lock != null and is_instance_valid(fish_lock):
		fish_lock.set_marked(false)
	fish_lock = null

# where the locked fish will be when a gull that launches NOW (at `v` m/s) gets to it; null when nothing is locked
func fish_aim_point(from, v):
	var f = fish_lock
	if f == null or not is_instance_valid(f) or f.spot == null:
		return null
	var tp = f.global_position
	var t = 0.0
	for i in 4:
		var q = f.spot.predict(t)
		if q == null:
			return f.global_position
		tp = q
		t = from.distance_to(tp) / max(v * 0.9, 8.0)
	return tp

# E with nothing to aim at: the gull sniffs out the nearest fry that its top speed can actually lock, and points at it for a few seconds
func _sniff():
	if state != "idle" or lock_fry != null or near_target != null or player.input_locked or GS.sense_active:
		return
	if not Input.is_action_just_pressed("interact") or GS.gull_sense_count < 3 or player.mode == 2:
		return
	var f = GS.nearest_fry(player.global_position)
	if f == null:
		player.show_toast("NOTHING IN REACH YET", 1.0)
		Sfx.play("tooslow", -12.0)
		return
	GS.sniff_node = f
	GS.sniff_until = GS.msec() / 1000.0 + 5.0
	Sfx.play("chime", -14.0, 1.5)

func _fail_note():
	if GS.watch_high():
		note = "the crowd was on high alert, so the bands were thin"
		note_t = 4.0

func _los(from, to):
	var q = PhysicsRayQueryParameters3D.create(from, to, 1)
	var hit = player.get_world_3d().direct_space_state.intersect_ray(q)
	return hit.is_empty() or hit["position"].distance_to(to) < 0.9

# the beak has to point nearly at the fry before the game takes over the last metres
func lock_cos():
	return [0.95, 0.94, 0.93, 0.92][GS.lv["green"]]

# ------------------------------------------------------------------ scanning / lock
func _scan(delta):
	var p = player
	if p.mode == 2:
		_unlock()
		return
	var fwd = -p.global_transform.basis.z
	var origin = p.global_position
	var eat_target = null
	var cands = get_tree().get_nodes_in_group("fries")
	cands.append_array(get_tree().get_nodes_in_group("mischief"))
	var scored = []
	var lcos = lock_cos()
	for f in cands:
		if not f.is_snatchable():
			continue
		var decor = f.ftype == "mischief" or f.ftype == "fish"
		if decor and GS.gull_sense_count < 3:
			continue      # the decorative steals wait until the first three fries are done: nothing may compete with the lesson
		var to = f.aim_point() - origin
		var d = to.length()
		if f.ftype == "ordinary":
			# the plain fry lies on the table from the very first minute, but it is out of the game (no glow, no prompt, no reaction) until the three starter fries are in
			if GS.gull_sense_count >= 3 and d <= 2.6 and (fwd.dot(to / max(d, 0.01)) > 0.0 or d < 2.0):
				eat_target = f
			elif GS.gull_sense_count < 3 and d <= 2.4 and note_t <= 0.0 and p.mode != 0:
				note = "later. it will keep."
				note_t = 2.6
			continue
		if d > 26.0 or d < 0.05:
			continue
		var dot = fwd.dot(to / d)
		if dot < lcos + (0.03 if decor else 0.0):
			continue
		# whoever sits closest to the MIDDLE of the view wins (distance does not matter), fries before decorations
		scored.append([dot - (0.01 if decor else 0.0), f, d])
	if eat_target != null and lock_fry == null:
		hud_state = "eat"
		if Input.is_action_just_pressed("interact") and not p.input_locked:
			p.ate_ordinary.emit(eat_target)
		return
	if lock_fry != null:
		_update_lock(delta, fwd, origin)
		return
	# a fry always wins over a decoration (a cup standing in front of a shelf fry must not steal the lock)
	if scored.any(func(e): return not (e[1].ftype == "mischief" or e[1].ftype == "fish")):
		scored = scored.filter(func(e): return not (e[1].ftype == "mischief" or e[1].ftype == "fish"))
	scored.sort_custom(func(a, b): return a[0] > b[0])
	var best = null
	var best_d = 999.0
	for s in scored:
		if _los(origin, s[1].aim_point()):
			best = s[1]
			best_d = s[2]
			break
	if best == null:
		return
	near_target = best
	# round 18: Gull Sight (TAB) no longer keeps the circles away: flying at a fry with TAB held starts the judgement just the same (and ends the sight: main.gd closes it
	# the moment a fry is locked). Players with a slow hand fly at the fry in slow motion and nothing is skipped.
	var can = p.mode == 0 and not p.input_locked and not GS.film_flow
	var need = GS.need_speed(best)
	need_speed = need
	need_tier = _tier_of(best)
	slow_t = max(slow_t - get_physics_process_delta_time(), 0.0)
	if p.speed >= need - 0.04 and can:
		hud_state = "ok"
		var dir = (best.aim_point() - origin) / best_d
		var closing = p.velocity.dot(dir)
		# the rhythm starts within ~1 s of the fry at the current speed (a dive from far away is what makes it possible)
		var reach_d = min(closing * (1.4 if GS.sense_active else 1.05), 26.0)       # (in the slow world of TAB the circle opens a little earlier: nothing can be flown through)
		if snatch_cd <= 0.0 and closing >= max(7.0, need - 3.0) and best_d <= reach_d and best_d >= 3.5:
			_lock_on(best)
	elif can or p.mode == 1:
		hud_state = "slow"
		if Input.is_action_just_pressed("interact") and best_d < 8.0:
			p.show_toast("NEED %d" % int(round(need * GS.SPEED_UNIT)) if need > 12.0 else "TOO SLOW")
			Sfx.play("tooslow", -10.0)
		elif GS.sense_active and best_d < 9.0 and slow_t <= 0.0 and p.mode == 0:
			# nobody has to guess why the circle did not open
			slow_t = 2.6
			p.show_toast("TOO SLOW:  NEED %d  -  HOLD SHIFT" % int(round(need * GS.SPEED_UNIT)), 1.6)
			Sfx.play("tooslow", -14.0)
	# EASY: while Gull Sight is held the beak is drawn gently towards the fry in the middle of the view (the slow world is for aiming, not for wrestling the mouse)
	if GS.sense_active and GS.is_easy() and p.mode == 0 and not p.input_locked:
		var dn = (best.aim_point() - origin).normalized()
		var ty = atan2(-dn.x, -dn.z)
		var tp = asin(clamp(dn.y, -1.0, 1.0))
		var k = 1.0 - exp(-2.2 * get_physics_process_delta_time() / max(Engine.time_scale, 0.1))
		p.aim_yaw = lerp_angle(p.aim_yaw, ty, k)
		p.aim_pitch = lerp(p.aim_pitch, tp, k)

func _is_tut(f):
	return f != null and f.id.begins_with("TUTORIAL")

# 0 common (tutorial / decorative), 1 silver, 2 gold, 3 diamond, 4 (old rainbow), 5 fish, 6 cloud / sun, 7-8 rare / legendary fish,
# 9 rainbow fry, 10 shooting star, 11 the rainbow in the sky, 12 the sun (9 circles), 13 the moon (9 circles)
func _tier_of(f):
	if f.ftype == "fish":
		return [5, 7, 8][clamp(f.rarity, 0, 2)]
	if f.ftype == "mischief":
		if f.kind == "meteor":
			return 10
		if f.kind == "skybow":
			return 11
		if f.kind == "sun":
			return 12
		if f.kind == "moon":
			return 13
		return 6 if f.kind in ["cloud", "raincloud"] else 0
	if f.ftype == "tutorial":
		return 0
	if f.tier >= 4:
		return 9
	return clamp(f.tier, 0, 3)

# round 18: the four families of judgement (the difficulty table speaks of them): ordinary fries and things, rainbow fries, fish, the things of the sky
func _class_of(tier):
	if tier == 4 or tier == 9:
		return "rb"
	if tier == 5 or tier == 7 or tier == 8:
		return "fish"
	if tier == 6 or tier >= 10:
		return "sky"
	return "fry"

# the numbers of one rhythm (real seconds): circles, waves, lead, gap, gold width, green width
# round 18: the FIRST wave of every rhythm is slow (`slow0` x longer to arrive, the bands grow with it so that what you see is what is judged) and is announced by a count-in of
# soft ticks at the beat of the waves that follow; the difficulty sets the number of waves per circle, the width of the bands, the speed of the later waves
func _seq_params(f):
	var tier = _tier_of(f)
	var cls = _class_of(tier)
	var base = SEQ_TIER[tier].duplicate()
	if f.ftype == "tutorial" and TUT_SEQ.has(f.id) and not GS.tutorial_done.has(f.id):
		base.merge(TUT_SEQ[f.id], true)
		if GS.is_easy() and f.id == "TUTORIAL_01":
			base["w"] = 1       # the very first fry: one judgement, a huge band
	else:
		var wv = GS.dp("w_" + cls)
		if wv > 0:
			base["w"] = wv
	var mult = GS.timing_mult() * GS.buff_window_mult()
	var hw = GS.heat_window_mult()
	if _is_tut(f):
		hw = max(hw, 0.9)       # the crowd cannot thin the first lessons
	if f.npc != null:
		mult *= ARCH_MULT.get(f.npc.arch, 0.94)
	var bl = 1.0
	var lad = 1.0
	if cls == "fry" and tier <= 3:
		bl = GS.dp("band_lad")[tier]
		lad = GS.dp("ladder")[tier]
	var m = mult * hw * (GS.dp("band") * bl if cls == "fry" else GS.dp("band_x"))
	var rs = GS.ring_speed_mult()
	var gm = GS.dp("gap") * lad
	var sk = GS.dp("sky_slow") if cls == "sky" else 1.0
	base["gw"] = max(base["gw"] * m, 0.026)
	base["gg"] = max(base["gg"] * m, 0.05)
	base["single"] = GS.dp("single")
	if base["single"]:
		base["gw"] = base["gg"]          # one band, the gold one, as wide as the green one used to be
		base["gg"] = 0.0
	if GS.dp("beat") > 0.0:
		# round 19: ONE steady beat for every wave of every catch (no faster second wave, no hurried tiers): `appr` seconds to shrink, `beat` seconds between two judgements
		base["appr"] = GS.dp("appr") * rs * sk
		base["gap"] = GS.dp("beat") * lad * rs * sk
	else:
		base["appr"] = APPR * rs * gm * sk
		base["gap"] = base["gap"] * rs * gm * sk
	var s0 = GS.dp("first_slow")
	base["slow0"] = s0
	base["appr0"] = base["appr"] * s0
	var ticks = int(GS.dp("ticks"))
	var lead = base["lead"] * rs + GS.dp("first_lead")
	lead = max(lead, base["appr0"] + 0.14)
	if ticks > 0:
		lead = max(lead, ticks * max(base["gap"], 0.26) + 0.45)
	base["lead"] = lead
	base["ticks"] = ticks
	base["n"] = base["c"] * base["w"]
	base["need"] = base["n"]
	if base["single"]:
		base["need"] = base["n"] - int(base["n"] / 4)       # a quarter of the beats may be missed
		if _is_tut(f):
			base["need"] = max(base["n"] - 1, 1)            # the lessons forgive one beat
	if cls == "sky":
		base["need"] = max(int(ceil(base["need"] * GS.dp("sky_need"))), 1)       # EASY: the sky never sends the gull away empty-handed
	base["tier"] = tier
	base["cls"] = cls
	return base

# start a rhythm: world = where the circles are drawn (the fry)
func _seq_begin(kind, f, world):
	var prm = _seq_params(f)
	var layout = LAYOUTS[prm["c"]]
	var notes = []
	for i in prm["n"]:
		var sl = prm["slow0"] if i == 0 else 1.0
		notes.append({"t": prm["lead"] + i * prm["gap"], "circle": i / prm["w"], "wave": i % prm["w"], "res": "", "res_t": 0.0,
			"appr": prm["appr0"] if i == 0 else prm["appr"], "gw": prm["gw"] * sl, "gg": prm["gg"] * sl})
	var last_t = notes[notes.size() - 1]["t"]
	var ticks = []
	var gt = max(prm["gap"], 0.26)
	for k in prm["ticks"]:
		ticks.append({"t": prm["lead"] - (prm["ticks"] - k) * gt, "done": false})
	seq = {"kind": kind, "t0": GS.usec(), "notes": notes, "appr": prm["appr"], "gw": prm["gw"], "gg": prm["gg"], "need": prm["need"], "points": 0,
		"n": prm["n"], "circles": prm["c"], "waves": prm["w"], "layout": layout, "tier": prm["tier"], "dur": last_t + 0.2, "misses": 0, "golds": 0, "greens": 0,
		"reason": "", "done": false, "ok": false, "perfect": false, "world": world, "combo": 0, "ticks": ticks, "lead": prm["lead"], "cls": prm["cls"], "single": prm["single"]}
	seq["tune"] = Tunes.pick(prm["tier"], prm["n"], prm["cls"], f.kind if f.ftype == "mischief" else "")
	presses.clear()
	last_step_usec = GS.usec()

func seq_now():
	if seq == null:
		return 0.0
	return (GS.usec() - seq["t0"]) / 1000000.0

func _seq_abort():
	if seq == null:
		return
	seq = null
	if lock_fry != null and state == "idle":
		lock_fry = null
		player.input_locked = false

# judge the E presses and the waves that slipped by. Returns true when the rhythm is over (seq["done"]).
func _seq_judge():
	var s = seq
	var now = seq_now()
	var ps = presses.duplicate()
	presses.clear()
	for us in ps:
		var tp = (us - s["t0"]) / 1000000.0
		if tp < LOCK_GRACE:
			continue
		var idx = _first_pending(s)
		if idx < 0:
			break
		var nt = s["notes"][idx]
		var dt = tp - nt["t"]
		if dt > MISS_GRACE:
			continue
		var res = "miss"
		var reason = "late" if dt > 0.0 else "early"
		if dt >= -nt["gw"] and dt <= GOLD_GRACE:
			res = "gold"
		elif dt >= -(nt["gw"] + nt["gg"]) and dt < -nt["gw"]:
			res = "green"
		_note_result(s, idx, res, reason, tp)
		if s["done"]:
			return true
	# waves that have slipped past the gold: a miss, right now
	while true:
		var j = _first_pending(s)
		if j < 0:
			break
		if now > s["notes"][j]["t"] + MISS_GRACE:
			_note_result(s, j, "miss", "late", now)
			if s["done"]:
				return true
		else:
			break
	return s["done"]

# round 19: the note of a good press belongs to its BEAT, not to the instant of the key: a press that came a little early waits for the middle of the gold band (at most
# ON_BEAT_MAX), so that the tune comes out even whatever the hands do. Note i of the tune = wave i (a miss is a hole on its beat); a gold press is the same note with sparkle.
const ON_BEAT_MAX = 0.14
func _on_beat(nt, tp, fn):
	var d = clamp((nt["t"] - nt["gw"] * 0.4) - tp, 0.0, ON_BEAT_MAX)
	if d < 0.012:
		fn.call()
		return
	var tree = Engine.get_main_loop()
	if tree != null:
		tree.create_timer(d, true, false, true).timeout.connect(fn)

func _first_pending(s):
	for i in s["notes"].size():
		if s["notes"][i]["res"] == "":
			return i
	return -1

func _note_result(s, idx, res, reason, tp):
	var nt = s["notes"][idx]
	nt["res"] = res
	nt["res_t"] = tp
	if res != "miss":
		hit_fx_res = res            # round 19: a soft flash in the corners of the screen (the hud draws it): green = a pale glow, gold = a warmer, stronger one
		hit_fx_t = GS.msec()
		hit_fx_tier = s["tier"]
	match res:
		"gold":
			s["golds"] += 1
			s["combo"] += 1
			if s["single"]:
				# HARD: one point per beat; the tune is already playing by itself, a hit adds a bright voice on top of this beat
				s["points"] += 1
				var cmb = s["combo"]
				_on_beat(nt, tp, func(): Tunes.hit(s["tune"], idx, cmb))
			else:
				s["points"] += 2
				_on_beat(nt, tp, func(): Tunes.gold(s["tune"], idx))
		"green":
			s["greens"] += 1
			s["points"] += 1
			s["combo"] += 1
			_on_beat(nt, tp, func(): Tunes.play(s["tune"], idx, false))
		_:
			s["misses"] += 1
			s["combo"] = 0
			if s["reason"] == "":
				s["reason"] = reason
			Sfx.play("ring_miss", -19.0 if s["single"] else -13.0)
	var remaining = 0
	for q in s["notes"]:
		if q["res"] == "":
			remaining += 1
	var judged = s["n"] - remaining
	# round 19: the WHOLE piece is played to its last note, whatever the points say (every note matters; no early "enough"), and only then it is counted: a gold press is worth
	# two points, so after a gold one miss is forgiven
	if remaining == 0:
		s["done"] = true
		s["ok"] = s["points"] >= s["need"]
	if s["done"]:
		s["perfect"] = s["ok"] and s["misses"] == 0 and (s["single"] or s["golds"] >= int(ceil(judged * 0.7)))

# ------------------------------------------------------------------ lock: the guided last metres + the grab rhythm
func _lock_on(f):
	lock_fry = f
	var p = player
	var tgt = f.aim_point()
	var to = tgt - p.global_position
	var dist = to.length()
	var dir = to / max(dist, 0.01)
	_seq_begin("grab", f, tgt)
	seq_from = p.global_position
	seq_to = tgt - dir * min(STAND_OFF, max(dist - 0.5, 0.0))
	var v = max(p.speed, 6.0)
	seq_ts = clamp(clamp(seq_from.distance_to(seq_to) / (seq["dur"] * v), SEQ_TS_MIN, SEQ_TS_MAX) * GS.slowmo_mult(), 0.1, 1.0)
	p.input_locked = true
	Sfx.play("alert", -16.0, 1.5)

func _update_lock(delta, fwd, origin):
	var p = player
	var f = lock_fry
	if not is_instance_valid(f) or seq == null:
		_unlock()
		return
	if not f.is_snatchable():
		_unlock()
		return
	hud_state = "locked"
	near_target = f
	tut_assist = f.id == "TUTORIAL_01" and not GS.tutorial_done.has("TUTORIAL_01")
	ring_world = f.aim_point()
	seq["world"] = ring_world
	# the guided last metres: the gull glides onto the fry along a straight line, the whole rhythm long
	var u = clamp(seq_now() / seq["dur"], 0.0, 1.0)
	var e = u * u * (3.0 - 2.0 * u) * 0.5 + u * 0.5
	var tgt = f.aim_point()
	var dir = (tgt - seq_from)
	var to_end = tgt - dir.normalized() * STAND_OFF
	if seq_from.distance_to(tgt) < STAND_OFF + 0.5:
		to_end = seq_from
	var pos = seq_from.lerp(to_end, e)
	var prev = p.global_position
	p.global_position = pos
	p.velocity = (pos - prev) / max(delta, 0.0001)
	var d2 = tgt - pos
	if d2.length() > 0.1:
		var dn = d2.normalized()
		p.aim_yaw = atan2(-dn.x, -dn.z)
		p.aim_pitch = asin(clamp(dn.y, -1.0, 1.0))
	_seq_ticks()
	if _seq_judge():
		var sq = seq
		_commit(f, sq["ok"], sq["perfect"], sq["reason"] if sq["reason"] != "" else "press")

# the count-in: soft ticks at the beat of the waves, so that the slow first wave arrives on a beat the player has already heard (EASY two ticks, HARD one)
func _seq_ticks():
	var s = seq
	if s == null or not s.has("ticks"):
		return
	var now = seq_now()
	if s["single"]:
		# HARD: the music plays by itself, a beat for every wave, in the middle of its band (what you press is what you hear)
		for i in s["notes"].size():
			var nb = s["notes"][i]
			if not nb.get("bk", false) and now >= nb["t"] - nb["gw"] * 0.5:
				nb["bk"] = true
				Tunes.beat(s["tune"], i)
	for tk in s["ticks"]:
		if not tk["done"] and now >= tk["t"]:
			tk["done"] = true
			Sfx.play("count_tick", -9.0, 1.0 + 0.12 * s["ticks"].find(tk))

func _unlock():
	var had = lock_fry != null or seq != null
	lock_fry = null
	seq = null
	if had and state == "idle":
		player.input_locked = false

# bullet time ("held breath"): eases Engine.time_scale during the grab and escape checks, hands it back afterwards.
func _focus_time(delta):
	if state == "cine":
		focus_owned = false
		return
	var real_dt = delta / max(Engine.time_scale, 0.05)
	var want = -1.0
	if state == "idle" and lock_fry != null and not GS.sense_active and seq != null:
		want = seq_ts
		if tut_assist:
			want *= 0.85
	if want > 0.0:
		if not focus_owned:
			focus_owned = true
			Sfx.muffle(true, 0.12, 5200.0)
			Sfx.play("whoosh", -12.0, 0.8)
		Engine.time_scale = move_toward(Engine.time_scale, want, 7.0 * real_dt)
	elif focus_owned:
		Engine.time_scale = move_toward(Engine.time_scale, 1.0, 5.0 * real_dt)
		if Engine.time_scale >= 0.999:
			focus_owned = false
			Sfx.muffle(false, 0.25)

# ------------------------------------------------------------------ cinematic reveal
func _commit(f, success, perfect, reason):
	state = "cine"
	var sq = seq
	last_commit = {"ok": success, "perfect": perfect, "reason": reason, "id": f.id, "n": sq["n"] if sq != null else 1,
		"golds": sq["golds"] if sq != null else 0, "greens": sq["greens"] if sq != null else 0, "misses": sq["misses"] if sq != null else 0,
		"points": sq["points"] if sq != null else 0, "need": sq["need"] if sq != null else 1}
	seq = null
	lock_fry = null
	cine = {"fry": f, "ok": success, "perfect": perfect, "t": 0.0, "dur": 0.8 + (0.3 if perfect else 0.0),
		"done_beat": false, "reason": reason, "angle": randf_range(-0.4, 0.4),
		"from": player.global_position, "beak_off": player.beak_socket.global_position - player.global_position}
	player.input_locked = true
	focus_owned = false
	Engine.time_scale = 0.2
	Sfx.muffle(true, 0.1)
	if f.npc != null:
		f.npc.react("surprise")
	if perfect and success:
		perfect_streak += 1
		GS.stats["perfect"] += 1
		GS.award("PERFECT")
	elif not success:
		perfect_streak = 0

func _update_cine(dt):
	var p = player
	var f = cine["fry"]
	if not is_instance_valid(f):
		_end_cine()
		return
	cine["t"] += dt
	if cine["t"] > cine["dur"] + 1.5:
		_end_cine()
		return
	var t = cine["t"]
	# the gull dashes the rest of the way, beak first, so the close-up is always on the fry
	if cine["ok"]:
		var to = f.aim_point() - cine["beak_off"]
		var u0 = smoothstep(0.0, 0.34, t)
		p.global_position = (cine["from"] as Vector3).lerp(to, u0)
		p.velocity = Vector3.ZERO
	var m = (p.beak_socket.global_position + f.global_position + Vector3(0, 0.15, 0)) * 0.5
	var b = p.global_transform.basis
	var ang = cine["angle"] + t * 0.35
	var off = b.x * cos(ang) * 1.15 + b.z * sin(ang) * -0.5 + Vector3(0, 0.35, 0)
	var xf = Transform3D(Basis.IDENTITY, m + off).looking_at(m, Vector3.UP)
	p.set_override(xf, 38.0, 1.0, 12.0)
	letterbox = 1.0
	# beak lunge
	var lunge = 0.0
	if t > 0.12 and t < 0.5:
		lunge = sin((t - 0.12) / 0.38 * PI) * 0.2
	p.gull.head_lunge = lunge
	if not cine["done_beat"] and t >= 0.34:
		cine["done_beat"] = true
		if cine["ok"]:
			f.attach(p.beak_socket)
			Sfx.play("snatch", -3.0)
			_sparkle(p.beak_socket.global_position, Color(1.0, 0.9, 0.5), 18 if cine["perfect"] else 8)
			p.shake = 0.2
		else:
			if f.npc != null:
				f.npc.react("guard")
			_sparkle(p.beak_socket.global_position, Color(1, 1, 1), 5)
	if t >= cine["dur"] - 0.25:
		var u = clamp((t - (cine["dur"] - 0.25)) / 0.25, 0.0, 1.0)
		Engine.time_scale = lerp(0.2, 1.0, u)
		letterbox = 1.0 - u
		if u > 0.1:
			p.set_override(xf, 38.0, 0.0, 6.0)
	if t >= cine["dur"]:
		_end_cine()

func _sparkle(pos, col, amount):
	var pr = CPUParticles3D.new()
	pr.amount = amount
	pr.one_shot = true
	pr.explosiveness = 1.0
	pr.lifetime = 0.8
	pr.direction = Vector3.UP
	pr.spread = 180.0
	pr.initial_velocity_min = 0.8
	pr.initial_velocity_max = 2.5
	pr.gravity = Vector3(0, -2.5, 0)
	var q = QuadMesh.new()
	q.size = Vector2(0.06, 0.06)
	var mt = StandardMaterial3D.new()
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mt.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mt.albedo_color = col
	mt.albedo_texture = preload("res://scripts/player/gull_visual.gd").soft_tex()
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = mt
	pr.mesh = q
	player.get_parent().add_child(pr)
	pr.global_position = pos
	pr.emitting = true
	get_tree().create_timer(1.5).timeout.connect(pr.queue_free)

func _end_cine():
	var f = cine["fry"] if cine.has("fry") else null
	var ok = cine.get("ok", false)
	var perfect = cine.get("perfect", false)
	var reason = cine.get("reason", "")
	Engine.time_scale = 1.0
	Sfx.muffle(false, 0.25)
	letterbox = 0.0
	player.gull.head_lunge = 0.0
	player.input_locked = false
	player.set_override(Transform3D.IDENTITY, 60.0, 0.0, 6.0)
	cine = {}
	if f == null or not is_instance_valid(f):
		state = "idle"
		return
	if ok and (f.ftype == "mischief" or f.ftype == "fish"):
		state = "idle"
		snatch_cd = 0.6
		flash = 1
		flash_t = 0.25
		if f.ftype == "fish":
			player.show_toast("PERFECT CATCH!" if perfect else "CAUGHT A FISH", 0.9)
			f.stolen(player)
			GS.comic.emit("fish", _pick(["A FISH. NOT A FRY. STILL FUNNY.", "THE SEA PAYS WELL.", "WET, SHINY AND NOT WHAT I WANTED."]), {"tier": 3 if perfect else 1, "col": Color("5FC8F5")})
		else:
			player.show_toast("PERFECT" if perfect else "GOT IT", 0.8)
			f.stolen(player)
		return
	if ok:
		player.speed = min(player.speed, 11.0)      # the grab costs speed: a boost run-up does not carry you into the wall behind the fry
		carry_fry = f
		carry_t = 0.0
		carry_perfect = perfect
		flash = 1
		flash_t = 0.25
		player.show_toast("PERFECT!" if perfect else "GOT IT", 0.7)
		var n = f.npc
		if n != null:
			n.on_snatched()
		state = "carry"
		carry_need = 0.55 if perfect else 0.4
	else:
		state = "idle"
		flash = -1
		flash_t = 0.25
		snatch_cd = 1.0
		player.swat_window = 2.0
		clean_run = false
		GS.stats["missed"] += 1
		var msg = {"late": "TOO LATE", "early": "TOO EARLY"}.get(reason, "MISSED")
		player.show_toast(msg, 0.9)
		_fail_note()
		GS.add_heat(0.5)
		if f.ftype == "star":
			# a gold / diamond fry is not forgiving: a miss costs breath and the fry stays spooked for longer
			player.spend(6.0 + 5.0 * (f.tier - 2))
			f.guard(1.8 + 0.9 * (f.tier - 2))
		elif f.ftype == "fish":
			f.escape()
		else:
			f.guard(1.2)
		if f.ftype == "mischief" and f.owner_amb != null:
			f.owner_amb.theft_reaction()
		if f.npc != null:
			f.npc.on_failed(1.0)
			f.npc.notice_boost(0.4)

func _pick(arr):
	return arr[randi() % arr.size()]

func _update_carry(delta):
	carry_t += delta
	var f = carry_fry
	if f == null or not is_instance_valid(f):
		carry_fry = null
		state = "idle"
		return
	if carry_t >= carry_need:
		_finish_snatch(f)

func _finish_snatch(f):
	var n = f.npc
	carry_fry = null
	state = "idle"
	snatch_cd = 0.4
	var clean = clean_run
	clean_run = true
	var was_perfect = carry_perfect
	carry_perfect = false
	f.consume()
	if n != null:
		n.on_escaped()
	GS.stats["stolen"] += 1
	GS.mark_steal()
	GS.add_heat(0.3)
	player.escaped.emit(f)
	if clean and f.ftype != "mischief":
		GS.award("CLEAN GETAWAY")
	if perfect_streak >= 3:
		GS.award("STEADY BEAK")
	var info = {"tier": f.tier, "type": f.utype if f.utype != "" else f.ftype, "perfect": was_perfect}
	if f.tier >= 1:
		info["col"] = GS.RARITY_COLORS[clamp(f.tier, 0, 4)]
	# one small caption only when it really was a moment (a perfect grab, or a gold / diamond / rainbow fry); everything else stays quiet
	if was_perfect:
		GS.comic.emit("perfect", _pick(["PERFECT. EVEN THE FRY IS IMPRESSED.", "NOBODY SAW A THING.", "SMOOTH. SALTY. SMOOTH."]), info)
	elif f.tier >= 2:
		GS.comic.emit("smug", _pick(["MINE NOW.", "SMUG, AND SALTY.", "CRISP. SLIGHTLY ILLEGAL.", "NO REGRETS. SOME KETCHUP."]), info)
