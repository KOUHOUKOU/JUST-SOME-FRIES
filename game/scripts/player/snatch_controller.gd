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
# STEADY BEAK (green) fries widen the bands and slow the waves. The crowd's attention thins the bands. Coffee: wider bands and a deeper slow-motion.
const LOCK_GRACE = 0.14         # presses in the first moments of a rhythm are ignored (that E was meant for something else)
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
	9: {"c": 5, "w": 2, "lead": 0.85, "gap": 0.30, "gw": 0.04, "gg": 0.075},    # RAINBOW fry: five circles x 2
	10: {"c": 5, "w": 2, "lead": 0.85, "gap": 0.29, "gw": 0.03, "gg": 0.06},    # a shooting star: five circles x 2
	11: {"c": 7, "w": 2, "lead": 0.85, "gap": 0.28, "gw": 0.03, "gg": 0.06},    # the rainbow in the sky: seven circles x 2 = 14 judgements
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

func _ready():
	pass

func _input(event):
	if event.is_action_pressed("interact") and not event.is_echo():
		presses.append(GS.usec())
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
	_focus_time(delta)
	match state:
		"cine":
			_update_cine(delta / max(Engine.time_scale, 0.02))
			return
		"carry":
			_update_carry(delta)
			return
	_scan(delta)
	_sniff()

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
	var can = p.mode == 0 and not GS.sense_active and not p.input_locked
	var need = GS.need_speed(best)
	need_speed = need
	need_tier = _tier_of(best)
	if p.speed >= need - 0.04 and can:
		hud_state = "ok"
		var dir = (best.aim_point() - origin) / best_d
		var closing = p.velocity.dot(dir)
		# the rhythm starts within ~1 s of the fry at the current speed (a dive from far away is what makes it possible)
		if snatch_cd <= 0.0 and closing >= max(7.0, need - 3.0) and best_d <= min(closing * 1.05, 26.0) and best_d >= 3.5:
			_lock_on(best)
	elif can or p.mode == 1:
		hud_state = "slow"
		if Input.is_action_just_pressed("interact") and best_d < 8.0:
			p.show_toast("NEED %d" % int(round(need * GS.SPEED_UNIT)) if need > 12.0 else "TOO SLOW")
			Sfx.play("tooslow", -10.0)

func _is_tut(f):
	return f != null and f.id.begins_with("TUTORIAL")

# 0 common (tutorial / decorative), 1 silver, 2 gold, 3 diamond, 4 (old rainbow), 5 fish, 6 cloud / sun, 7-8 rare / legendary fish,
# 9 rainbow fry, 10 shooting star, 11 the rainbow in the sky
func _tier_of(f):
	if f.ftype == "fish":
		return [5, 7, 8][clamp(f.rarity, 0, 2)]
	if f.ftype == "mischief":
		if f.kind == "meteor":
			return 10
		if f.kind == "skybow":
			return 11
		return 6 if f.kind in ["cloud", "sun"] else 0
	if f.ftype == "tutorial":
		return 0
	if f.tier >= 4:
		return 9
	return clamp(f.tier, 0, 3)

# the numbers of one rhythm (real seconds): circles, waves, lead, gap, gold width, green width
func _seq_params(f):
	var tier = _tier_of(f)
	var base = SEQ_TIER[tier].duplicate()
	if f.ftype == "tutorial" and TUT_SEQ.has(f.id) and not GS.tutorial_done.has(f.id):
		base.merge(TUT_SEQ[f.id], true)
	var mult = GS.timing_mult() * GS.buff_window_mult()
	var hw = GS.heat_window_mult()
	if _is_tut(f):
		hw = max(hw, 0.9)       # the crowd cannot thin the first lessons
	if f.npc != null:
		mult *= ARCH_MULT.get(f.npc.arch, 0.94)
	var m = mult * hw
	var rs = GS.ring_speed_mult()
	base["gw"] = max(base["gw"] * m, 0.026)
	base["gg"] = max(base["gg"] * m, 0.05)
	base["appr"] = APPR * rs
	base["lead"] = max(base["lead"] * rs, base["appr"] + 0.14)
	base["gap"] = base["gap"] * rs
	base["n"] = base["c"] * base["w"]
	base["tier"] = tier
	return base

# start a rhythm: world = where the circles are drawn (the fry)
func _seq_begin(kind, f, world):
	var prm = _seq_params(f)
	var layout = LAYOUTS[prm["c"]]
	var notes = []
	for i in prm["n"]:
		notes.append({"t": prm["lead"] + i * prm["gap"], "circle": i / prm["w"], "wave": i % prm["w"], "res": "", "res_t": 0.0})
	var last_t = notes[notes.size() - 1]["t"]
	seq = {"kind": kind, "t0": GS.usec(), "notes": notes, "appr": prm["appr"], "gw": prm["gw"], "gg": prm["gg"], "need": prm["n"], "points": 0,
		"n": prm["n"], "circles": prm["c"], "waves": prm["w"], "layout": layout, "tier": prm["tier"], "dur": last_t + 0.2, "misses": 0, "golds": 0, "greens": 0,
		"reason": "", "done": false, "ok": false, "perfect": false, "world": world, "combo": 0}
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
		if dt >= -s["gw"] and dt <= GOLD_GRACE:
			res = "gold"
		elif dt >= -(s["gw"] + s["gg"]) and dt < -s["gw"]:
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

func _first_pending(s):
	for i in s["notes"].size():
		if s["notes"][i]["res"] == "":
			return i
	return -1

func _note_result(s, idx, res, reason, tp):
	var nt = s["notes"][idx]
	nt["res"] = res
	nt["res_t"] = tp
	match res:
		"gold":
			s["golds"] += 1
			s["points"] += 2
			s["combo"] += 1
			Sfx.play("ring_gold", -7.0, Sfx.PENTA[min(s["combo"] - 1, 7) % Sfx.PENTA.size()])
		"green":
			s["greens"] += 1
			s["points"] += 1
			s["combo"] += 1
			Sfx.play("ring_ok", -8.0, Sfx.PENTA[min(s["combo"] - 1, 7) % Sfx.PENTA.size()])
		_:
			s["misses"] += 1
			s["combo"] = 0
			if s["reason"] == "":
				s["reason"] = reason
			Sfx.play("ring_miss", -9.0)
	var remaining = 0
	for q in s["notes"]:
		if q["res"] == "":
			remaining += 1
	var judged = s["n"] - remaining
	# enough points: it is yours (a gold press pays for two waves, so skilled players finish early)
	if s["points"] >= s["need"]:
		s["done"] = true
		s["ok"] = true
	elif s["points"] + 2 * remaining < s["need"]:
		s["done"] = true          # even all golds could not save it any more
		s["ok"] = false
	elif remaining == 0:
		s["done"] = true
		s["ok"] = false
	if s["done"]:
		s["perfect"] = s["ok"] and s["misses"] == 0 and s["golds"] >= int(ceil(judged * 0.7))

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
	if _seq_judge():
		var sq = seq
		_commit(f, sq["ok"], sq["perfect"], sq["reason"] if sq["reason"] != "" else "press")

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
	GS.flight_loot()
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
