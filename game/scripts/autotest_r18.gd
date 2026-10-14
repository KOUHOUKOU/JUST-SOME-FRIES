extends Node
# Round 18 tests (difficulty, the coach, TAB lock, the tunes, hostility, drink stations, the board). Started by autotest.gd (--r18a logic, --r18b play, --r18v screenshots, --r18m menus).
var at
var main

func chk(name_, ok, extra = ""):
	at.say("[R18] %s %s %s" % ["PASS" if ok else "FAIL", name_, extra])

func _setup(diff):
	GS.set_diff(diff)
	var p = main.player
	GS.gull_sense_count = 3
	GS.tutorial_done = {"TUTORIAL_01": true, "TUTORIAL_02": true, "TUTORIAL_03": true}
	for i in 7:
		GS.set_level(GS.FRY_TYPES[i], 1)
	main._reveal_specials()
	main.meteors.set_process(false)
	p.input_locked = false
	return p

# --r18a: the numbers
func r18a():
	await get_tree().create_timer(1.0).timeout
	var p = _setup("classic")
	var sn = p.snatch
	# ---- the three tables
	for d in ["classic", "easy", "hard"]:
		GS.set_diff(d)
		GS.lv["blue"] = 0
		at.say("[R18] %s: breath %.0f, glide regen %.1f, perch regen %.1f, drain x%.2f, TAB cost %.2f, hostile at %.1f, friend x%.2f" % [d, GS.stamina_max(), GS.regen_glide(), GS.regen_perch(false), GS.drain_mult(), GS.vision_cost(), GS.hostile_line(), GS.friend_mult()])
	GS.set_diff("easy")
	chk("easy has more breath than hard", GS.stamina_max() > 90.0)
	GS.set_diff("hard")
	chk("hard has the old breath", abs(GS.stamina_max() - 60.0) < 0.1)
	GS.lv["pink"] = 0                                      # (the CHARM fry raises the hostile line in HARD)
	# ---- hostility: nothing attacks below the line
	GS.set_diff("easy")
	GS.watch = 2.4
	chk("easy: a wary crowd (2.4) is not hostile", not GS.hostile())
	GS.watch = 3.2
	chk("easy: a crowd on full alert (3.2) is hostile", GS.hostile())
	GS.set_diff("hard")
	GS.watch = 1.7
	chk("hard: 1.7 is hostile", GS.hostile())
	GS.watch = 0.0
	GS.lv["pink"] = 1
	# ---- the judgement tables for every family, in every difficulty
	var fr = main.world["fries"]
	var tut = fr["TUTORIAL_01"]
	var silver = null
	var gold = null
	var diamond = null
	for k in fr:
		var f = fr[k]
		if f.is_special() and f.tier == 1 and silver == null:
			silver = f
	var gstar = at.make_star("red", 2, Vector3(0, 120, 0), "STAR_RED_2")
	var dstar = at.make_star("red", 3, Vector3(0, 125, 0), "STAR_RED_3")
	var rbf = Node3D.new()
	rbf.set_script(preload("res://scripts/fries/fry.gd"))
	main.add_child(rbf)
	rbf.setup("RB_T", "red", "hand", 0, 4)
	GS.quests = {"sky": "active"}
	GS.gull_sense_count = 3
	main._quest_tick(1.0)
	var sun = main.quest_items["sun"]
	var cloud = main.quest_items["cloud"]
	var table = {}
	for d in ["classic", "easy", "hard"]:
		GS.set_diff(d)
		var row = []
		for pair in [["tut1", tut], ["silver", silver], ["gold", gstar], ["diamond", dstar], ["rainbow fry", rbf], ["cloud", cloud], ["sun", sun]]:
			var prm = sn._seq_params(pair[1])
			row.append("%s %dx%d (need %d) lead %.2f appr0 %.2f gw %.3f gg %.3f ticks %d" % [pair[0], prm["c"], prm["w"], prm["need"], prm["lead"], prm["appr0"], prm["gw"], prm["gg"], prm["ticks"]])
		table[d] = row
		for r in row:
			at.say("[R18] %-8s %s" % [d, r])
	GS.set_diff("easy")
	var pe = sn._seq_params(silver)
	GS.set_diff("hard")
	var ph = sn._seq_params(silver)
	GS.set_diff("easy")
	chk("easy: a silver fry is 2 circles of one wave, hard: 2 circles of three", pe["w"] == 1 and ph["w"] == 3 and pe["c"] == 2, "easy w=%d hard w=%d" % [pe["w"], ph["w"]])
	var prb = sn._seq_params(rbf)
	chk("a rainbow fry has SEVEN circles", prb["c"] == 7, "c=%d" % prb["c"])
	var pcloud = sn._seq_params(cloud)
	chk("easy: the sky asks for 60% of the points only", pcloud["need"] < pcloud["n"] and pcloud["need"] >= int(pcloud["n"] * 0.5), "%d of %d" % [pcloud["need"], pcloud["n"]])
	chk("the first wave is as fast as the others (round 18b)", abs(pe["appr0"] - pe["appr"]) < 0.001 and abs(ph["appr0"] - ph["appr"]) < 0.001, "%.2f vs %.2f" % [pe["appr0"], pe["appr"]])
	chk("the lead leaves room for the first wave and the ticks", pe["lead"] >= pe["appr0"] + 0.1 and pe["lead"] >= 2 * pe["gap"], "lead %.2f" % pe["lead"])
	# the ladder: the families speed up (EASY and HARD), the bands of EASY get thinner
	GS.set_diff("easy")
	var pe_g = sn._seq_params(gstar)
	var pe_d = sn._seq_params(dstar)
	var pe_t = sn._seq_params(tut)
	chk("easy: the waves of silver / gold / diamond come faster and faster", pe_t["appr"] > pe["appr"] and pe["appr"] > pe_g["appr"] and pe_g["appr"] > pe_d["appr"] and pe["gap"] > pe_d["gap"], "appr %.2f %.2f %.2f %.2f" % [pe_t["appr"], pe["appr"], pe_g["appr"], pe_d["appr"]])
	chk("easy: the bands of the diamond are thinner than the silver ones", pe_d["gg"] < pe["gg"] * 0.95, "%.3f vs %.3f" % [pe_d["gg"], pe["gg"]])
	GS.set_diff("hard")
	var ph_g = sn._seq_params(gstar)
	var ph_d = sn._seq_params(dstar)
	chk("hard: the same ladder", ph["appr"] > ph_g["appr"] and ph_g["appr"] > ph_d["appr"], "appr %.2f %.2f %.2f" % [ph["appr"], ph_g["appr"], ph_d["appr"]])
	chk("hard: ONE band (gold) as wide as the old green band", ph["single"] and ph["gg"] == 0.0 and ph["gw"] > 0.07, "gw %.3f gg %.3f" % [ph["gw"], ph["gg"]])
	chk("hard: a quarter of the beats may be missed", ph["need"] == ph["n"] - int(ph["n"] / 4), "need %d of %d" % [ph["need"], ph["n"]])
	chk("the rings are smaller than they were (easy 0.68, hard 0.62)", GS.DP["easy"]["ring"] <= 0.7 and GS.DP["hard"]["ring"] <= 0.65)
	GS.set_diff("easy")
	# a real sequence: per-note windows and the first wave
	sn._seq_begin("grab", silver, silver.aim_point())
	var s = sn.seq
	chk("note 0 has the same window as note 1", abs(s["notes"][0]["gw"] - s["notes"][1]["gw"]) < 0.0001, "%.3f vs %.3f" % [s["notes"][0]["gw"], s["notes"][1]["gw"]])
	chk("two count-in ticks", s["ticks"].size() == 2)
	chk("a tune with as many notes as judgements", s["tune"]["notes"].size() == s["n"], "%s %d" % [s["tune"]["name"], s["tune"]["notes"].size()])
	sn.seq = null
	sn.lock_fry = null
	# ---- the speed needed (the sky keeps its speeds)
	for d in ["classic", "easy", "hard"]:
		GS.set_diff(d)
		at.say("[R18] need %-7s tut1 %3d  silver %3d  gold %3d  diamond %3d  rainbow %3d  cloud %3d  sun %3d" % [d, int(GS.need_speed(tut) * 6), int(GS.need_speed(silver) * 6), int(GS.need_speed(gstar) * 6), int(GS.need_speed(dstar) * 6), int(GS.need_speed(rbf) * 6), int(GS.need_speed(cloud) * 6), int(GS.need_speed(sun) * 6)])
	GS.set_diff("easy")
	var e_s = GS.need_speed(silver)
	var e_c = GS.need_speed(cloud)
	GS.set_diff("hard")
	chk("hard asks for more speed than easy, the sky for the same", GS.need_speed(silver) > e_s and abs(GS.need_speed(cloud) - e_c) < 0.01)
	# ---- the tunes
	var T = preload("res://scripts/systems/tunes.gd")
	var bad = 0
	var names = {}
	for cls in ["fry", "rb", "fish", "sky"]:
		for tier in [0, 1, 2, 3, 9, 5, 7, 8, 6, 10, 11, 12, 13]:
			for n in [1, 2, 3, 4, 6, 7, 9, 10, 12, 14, 15, 18, 21, 27]:
				for key in ["", "sun", "moon", "cloud", "raincloud", "skybow", "meteor"]:
					var tn = T.pick(tier, n, cls, key)
					names[tn["name"] + "/" + tn["inst"]] = true
					var ok = tn["notes"].size() == n
					for m in tn["notes"]:
						if m < 48 or m > 91:
							ok = false
					if not ok:
						bad += 1
	chk("every tune has exactly n notes, all in range", bad == 0, "%d bad; used: %s" % [bad, str(names.keys())])
	# ---- the drink stations
	var n_by = {"coffee": 0, "alcohol": 0, "icecream": 0}
	for m in get_tree().get_nodes_in_group("mischief"):
		if is_instance_valid(m) and n_by.has(m.kind):
			n_by[m.kind] += 1
	chk("drinks: at most 5 coffee, 5 cocktails, 4 ice creams", n_by["coffee"] <= 5 and n_by["alcohol"] <= 5 and n_by["icecream"] <= 4 and n_by["coffee"] >= 3, str(n_by))
	chk("a drink lasts 30 s", abs(GS.BUFF_SEC - 30.0) < 0.01)
	GS.set_drink("")
	GS.add_buff("coffee")
	chk("a cup gives 30 s", abs(GS.buff["coffee"] - 30.0) < 0.5, "%.1f" % GS.buff["coffee"])
	GS.set_drink("")
	# ---- the quest board knows its rewards
	for id in GS.QUESTS:
		chk("quest %s has a reward name and a line" % id, GS.QUESTS[id].size() >= 5 and GS.QUESTS[id][3] != "" and GS.QUESTS[id][4] != "")
	chk("the pink fry is the CHARM fry", GS.NAMES["pink"][0] == "CHARM FRY" and GS.STAT_NAMES["pink"] == "CHARM")
	get_tree().quit()

# --r18b: play (EASY): bumps, quick turn, TAB lock
func r18b():
	await get_tree().create_timer(1.0).timeout
	var p = _setup("easy")
	var sn = p.snatch
	# a bump in EASY costs nothing
	p.stamina = GS.stamina_max()
	var st0 = p.stamina
	GS.watch = 3.4                                   # even on full alert: a bump
	p.mode = 0
	p.global_position = Vector3(-9.0, 12.0, 4.0)
	p.speed = 8.0
	p.get_swatted(main.elder, "punch")
	await at.real(0.3)
	chk("easy: a swat is a bump (no tumble, no breath lost)", p.mode == 0 and p.stamina >= st0 - 0.5, "mode %d stamina %.0f -> %.0f" % [p.mode, st0, p.stamina])
	GS.watch = 0.0
	GS.set_diff("hard")
	p.get_swatted(main.elder, "punch")
	await at.real(0.1)
	chk("hard: a swat is a tumble", p.mode == 2, "mode %d" % p.mode)
	await at.real(2.0)
	GS.set_diff("easy")
	# quick turn
	p.mode = 0
	p.global_position = Vector3(-9.0, 14.0, 4.0)
	p.speed = 11.0
	p.yaw = 0.0
	p.aim_yaw = 0.0
	var y0 = p.yaw
	Input.action_press("move_forward")
	at.tap("turn_back")
	await at.real(1.2)
	Input.action_release("move_forward")
	var dy = abs(angle_difference(y0, p.yaw))
	chk("R turns the gull round (about 180 degrees)", dy > 2.6, "turned %.0f degrees" % rad_to_deg(dy))
	# TAB lock: a fry in front, enough speed, Gull Sight held
	var f = main.world["fries"]["TUTORIAL_01"]
	f.consumed = false
	GS.tutorial_done.erase("TUTORIAL_01")
	GS.gull_sense_count = 3
	var tgt = f.aim_point()
	var start = tgt + Vector3(0, 6.0, 26.0)
	at.place(start, tgt, 11.0)
	main._open_sense()
	GS.tab_lesson = 2
	Input.action_press("move_forward")
	Input.action_press("dash")
	var locked = false
	for i in 400:
		await get_tree().process_frame
		if sn.lock_fry != null:
			locked = true
			break
		at.aim_at(p, tgt)
	Input.action_release("move_forward")
	Input.action_release("dash")
	await at.real(0.4)
	chk("flying at a fry with TAB held opens the circles", locked)
	chk("...and Gull Sight is closed by it", not GS.sense_active)
	chk("...with a first wave at the normal speed", sn.seq != null and abs(sn.seq["notes"][0]["appr"] - sn.seq["appr"]) < 0.001 if sn.seq != null else locked)
	sn._unlock()
	get_tree().quit()

# --r18v: the screens (coach, rhythm, Gull Sight, board, breath bar, clock)
func r18v():
	await get_tree().create_timer(1.5).timeout
	var p = main.player
	var sn = p.snatch
	GS.set_diff("easy")
	# 1 the coach on the very first fry (on the ground, then in the air)
	GS.gull_sense_count = 0
	GS.tutorial_done = {}
	p.input_locked = false
	main.hud.visible = true
	await at.real(1.2)
	await at.shot("r18v_1_coach_ground")
	var f1 = main.world["fries"]["TUTORIAL_01"]
	var tgt = f1.aim_point()
	at.place(Vector3(-8.0, 12.0, 20.0), tgt, 9.0)
	await at.real(0.8)
	await at.shot("r18v_2_coach_climb")
	at.place(Vector3(-8.0, 4.0, 22.0), tgt, 9.0)
	await at.real(0.6)
	await at.shot("r18v_3_coach_aim")
	# 4 the rhythm: lock the fry
	at.place(Vector3(-8.0, 3.2, 17.0), tgt, 9.0)
	Input.action_press("move_forward")
	Input.action_press("dash")
	var shot_n = 0
	for i in 600:
		await get_tree().process_frame
		if sn.lock_fry == null:
			at.aim_at(p, tgt)
		elif sn.seq != null:
			var now = sn.seq_now()
			if shot_n == 0 and now > 0.5:
				shot_n = 1
				await at.shot("r18v_4_rhythm_ready")
			elif shot_n == 1 and now > 1.0:
				shot_n = 2
				await at.shot("r18v_5_rhythm_first_wave")
			elif shot_n == 2 and now > 1.45:
				shot_n = 3
				await at.shot("r18v_6_rhythm_later")
				break
	Input.action_release("move_forward")
	Input.action_release("dash")
	sn._unlock()
	Engine.time_scale = 1.0
	# 7 Gull Sight with the new emblems; the first three fries are in
	GS.tutorial_done = {"TUTORIAL_01": true, "TUTORIAL_02": true, "TUTORIAL_03": true}
	GS.gull_sense_count = 3
	for i in 3:
		GS.set_level(GS.FRY_TYPES[i], 1)
	main._reveal_specials()
	GS.tab_lesson = 2
	p.mode = 0
	var nf = GS.nearest_fry(Vector3(-6.0, 14.0, 10.0), false)
	var look = nf.global_position if nf != null else Vector3(10.0, 8.0, -4.0)
	p.global_position = look + Vector3(-9.0, 6.0, 16.0)
	p.velocity = Vector3.ZERO
	p.speed = 6.0
	at.aim_at(p, look)
	at.say("[R18] gull sight looks at %s at %s" % [nf.id if nf != null else "-", str(look)])
	Input.action_press("gull_sense")
	main._open_sense()
	await at.real(1.0)
	await at.shot("r18v_7_gull_sight")
	Input.action_release("gull_sense")
	main._close_sense()
	await at.real(0.4)
	await at.shot("r18v_8_beacons")
	# 9 the board with quests, low breath, a drink, rainbow time
	GS.quests = {"star": "active", "fish": "active", "drink": "done", "wear": "active", "rainbow": "active", "sky": "active"}
	GS.quest_done_at["drink"] = GS.msec() / 1000.0
	for i in 7:
		GS.set_level(GS.FRY_TYPES[i], 2 if i < 3 else 1)
	GS.add_buff("coffee")
	p.stamina = 12.0
	p.mode = 1
	await at.real(1.0)
	await at.shot("r18v_9_board_low_breath")
	# 10 HARD: the clock
	GS.set_diff("hard")
	GS.hard_clock = 201.0
	GS.hard_best = 745.0
	p.stamina = GS.stamina_max()
	await at.real(0.8)
	await at.shot("r18v_10_hard")
	get_tree().quit()

# --r18m: the menus (cover, slots, the difficulty card, the pause menu, the controls page)
func r18m():
	await get_tree().create_timer(1.0).timeout
	GS.set_diff("easy")
	var m = main.menus
	main.player.input_locked = true
	m.show_main()
	await at.real(3.0)
	await at.shot("r18m_1_cover")
	m._open_slots("new")
	await at.real(0.6)
	await at.shot("r18m_2_slots")
	m._slot_pressed(1)
	m._slot_pressed(1)
	await at.real(0.6)
	await at.shot("r18m_3_difficulty")
	GS.set_diff("hard")
	GS.hard_best = 725.0
	m._open_diff()
	await at.real(0.4)
	await at.shot("r18m_3b_difficulty_hard_record")
	m.diff_panel.visible = false
	m.begin_game()
	m.set_paused(true)
	await at.real(0.6)
	await at.shot("r18m_4_pause")
	m.pause_panel.visible = false
	m.controls_panel.visible = true
	await at.real(0.4)
	await at.shot("r18m_5_controls")
	m.set_paused(false)
	get_tree().quit()

# --r18n: THE NOVICE. A clumsy player (looks at the fry every 0.4 s with an error of ~8 degrees, starts the dive late, presses E with a spread of +-0.1 s) tries to get the first fries.
# It reports how long it took and how many tries. The numbers of the first ten minutes were never tested with anybody but experts; this is the check.
func _novice(f, label, secs = 100.0, sigma = 0.1):
	var p = main.player
	var sn = p.snatch
	var tgt = f.aim_point()
	p.mode = 0
	p.global_position = Vector3(-11.6, 6.4, -0.8)
	p.velocity = Vector3.ZERO
	p.speed = 5.0
	p.yaw = randf() * TAU                    # (it looks the wrong way at first)
	p.aim_yaw = p.yaw
	p.pitch = 0.0
	p.aim_pitch = 0.0
	p.stamina = GS.stamina_max()
	var t0 = GS.msec()
	var noise = Vector3.ZERO
	var look_t = 0.0
	var tries = 0
	var was_lock = false
	var press_at = {}
	var dbg_t = 0.0
	var result = "timeout"
	Input.action_press("move_forward")
	while (GS.msec() - t0) < secs * 1000.0:
		await get_tree().process_frame
		if not is_instance_valid(f) or f.consumed:
			result = "ok"
			break
		p.stamina = max(p.stamina, 20.0) if GS.is_easy() else p.stamina
		var to = tgt - p.global_position
		if sn.lock_fry == null and sn.state == "idle":
			look_t -= 1.0 / 30.0
			if look_t <= 0.0:
				look_t = 0.4
				noise = Vector3(randfn(0.0, to.length() * 0.14), randfn(0.0, to.length() * 0.08), randfn(0.0, to.length() * 0.14))
			at.soft_aim(tgt + noise, 0.9)
			var fwd = -p.global_transform.basis.z
			var ang = acos(clamp(fwd.dot(to.normalized()), -1.0, 1.0))
			dbg_t += 1.0 / 30.0
			if dbg_t > 4.0 and OS.get_cmdline_user_args().has("--dbg"):
				dbg_t = 0.0
				at.say("[R18]   novice dbg pos %s spd %.1f d %.1f ang %.0f near %s hud %s need %.1f" % [str(p.global_position.snapped(Vector3.ONE)), p.speed, to.length(), rad_to_deg(ang), str(sn.near_target.id if sn.near_target != null else "-"), sn.hud_state, GS.need_speed(f)])
			var above = p.global_position.y > tgt.y + 3.0
			# dive when roughly pointing at it, not before
			if ang < deg_to_rad(18.0) and above and to.length() < 45.0:
				Input.action_press("dash")
			else:
				Input.action_release("dash")
			if p.mode == 1 or (p.global_position.y < tgt.y + 1.0 and to.length() > 12.0 and p.speed < 6.0):
				at.tap("flap")
		elif sn.seq != null:
			if not was_lock:
				was_lock = true
				tries += 1
				press_at = {}
			Input.action_release("dash")
			var s = sn.seq
			var idx = sn._first_pending(s)
			if idx >= 0 and not press_at.has(idx):
				var nt = s["notes"][idx]
				press_at[idx] = nt["t"] - (nt["gw"] + nt["gg"] * 0.5) + randfn(0.0, sigma)
				if s["single"]:
					press_at[idx] = nt["t"] - nt["gw"] * 0.5 + randfn(0.0, sigma)
			if idx >= 0 and sn.seq_now() >= press_at.get(idx, 99.0):
				press_at[idx] = 99.0
				at.tap("interact")
		else:
			was_lock = false
	Input.action_release("move_forward")
	Input.action_release("dash")
	var took = (GS.msec() - t0) / 1000.0
	at.say("[R18] novice %s: %s in %.0f s, %d circles" % [label, result, took, tries])
	sn._unlock()
	Engine.time_scale = 1.0
	return {"ok": result == "ok", "t": took, "tries": tries}

func r18n():
	await get_tree().create_timer(1.5).timeout
	var p = main.player
	GS.gull_sense_count = 0
	GS.tutorial_done = {}
	p.input_locked = false
	var dname = "hard" if OS.get_cmdline_user_args().has("--hard") else "easy"
	GS.set_diff(dname)
	var total = 0.0
	var all_ok = true
	var only = ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
	at.say("[R18] novice only='%s' args=%s" % [only, str(OS.get_cmdline_user_args())])
	for id in ["TUTORIAL_01", "TUTORIAL_02", "TUTORIAL_03"]:
		if only != "" and id != only:
			GS.tutorial_done[id] = true
			GS.gull_sense_count += 1
			continue
		var f = main.world["fries"][id]
		if GS.tutorial_done.has(id):
			continue
		if not is_instance_valid(f) or f.consumed:
			# (the clumsy bot flew at the next fry by mistake and caught that one: the game counted it, so the bot has it)
			at.say("[R18]   %s was already caught on the way" % id)
			GS.tutorial_done[id] = true
			GS.gull_sense_count += 1
			continue
		var wt = 0.0
		while wt < 40.0 and (not is_instance_valid(f) or not f.is_snatchable()):
			await at.real(0.5)
			wt += 0.5
			for g in get_tree().get_nodes_in_group("fries"):
				if is_instance_valid(g) and g.id == id:
					f = g
		at.say("[R18]   %s ready after %.1f s (valid %s)" % [id, wt, str(is_instance_valid(f))])
		var r = await _novice(f, dname + " " + id, 120.0, 0.12)
		total += r["t"]
		all_ok = all_ok and r["ok"]
		if r["ok"]:
			GS.tutorial_done[id] = true
			GS.gull_sense_count += 1
			await at.real(3.0)                     # (the item card of the fry, the carry, the comic...)
			at.say("[R18]   after the fry: showcase %s state %s input_locked %s paused %s" % [str(main.showcase.active), main.player.snatch.state, str(main.player.input_locked), str(get_tree().paused)])
	chk("the novice gets the three starter fries in EASY within 120 s each", all_ok, "%.0f s in all" % total)
	get_tree().quit()


# --r18h: HARD is a rhythm game: one gold band, the tune plays by itself, presses outside the band do not count; EASY keeps its two bands and gold = two points; the goals board folds with Q
func _press_at(sn, secs):
	sn.presses.append(sn.seq["t0"] + int(secs * 1000000.0))

func r18h():
	await get_tree().create_timer(1.0).timeout
	var p = _setup("hard")
	var sn = p.snatch
	var fr = main.world["fries"]
	var silver = null
	for k in fr:
		var f = fr[k]
		if f.is_special() and f.tier == 1 and silver == null:
			silver = f
	GS.tutorial_done = {"TUTORIAL_01": true, "TUTORIAL_02": true, "TUTORIAL_03": true}
	# every beat hit in the middle of the band
	sn._seq_begin("grab", silver, silver.aim_point())
	var s = sn.seq
	chk("hard: the sequence is single-band", s["single"] and s["notes"][0]["gg"] == 0.0)
	for i in s["notes"].size():
		_press_at(sn, s["notes"][i]["t"] - s["notes"][i]["gw"] * 0.5)
	var done = sn._seq_judge()
	chk("hard: hitting the middle of the band is a gold hit for every beat", done and s["ok"] and s["misses"] == 0 and s["golds"] == s["need"], "points %d need %d golds %d" % [s["points"], s["need"], s["golds"]])
	chk("hard: a hit is worth ONE point", s["points"] == s["golds"])
	# early presses (before the band) are misses and the rest cannot save it
	sn._seq_begin("grab", silver, silver.aim_point())
	s = sn.seq
	for i in s["notes"].size():
		_press_at(sn, s["notes"][i]["t"] - s["notes"][i]["gw"] - 0.06)
	done = sn._seq_judge()
	chk("hard: a press before the band does not count", done and not s["ok"] and s["golds"] == 0, "golds %d misses %d" % [s["golds"], s["misses"]])
	# a quarter of the beats may be missed
	sn._seq_begin("grab", silver, silver.aim_point())
	s = sn.seq
	var n = s["n"]
	var allowed = n - s["need"]
	for i in n:
		if i < allowed:
			_press_at(sn, s["notes"][i]["t"] - s["notes"][i]["gw"] - 0.07)
		else:
			_press_at(sn, s["notes"][i]["t"] - s["notes"][i]["gw"] * 0.5)
	done = sn._seq_judge()
	chk("hard: with the allowed misses it still counts", done and s["ok"], "n %d need %d allowed misses %d -> points %d" % [n, s["need"], allowed, s["points"]])
	# the music plays by itself: every beat is a sound at its time
	sn._seq_begin("grab", silver, silver.aim_point())
	s = sn.seq
	s["t0"] -= 30000000
	sn._seq_ticks()
	var all_bk = true
	for nt in s["notes"]:
		all_bk = all_bk and nt.get("bk", false)
	chk("hard: the tune plays by itself on every beat", all_bk)
	sn.seq = null
	# EASY: two bands, a gold press pays two points
	GS.set_diff("easy")
	sn._seq_begin("grab", silver, silver.aim_point())
	s = sn.seq
	chk("easy: two bands", not s["single"] and s["notes"][0]["gg"] > 0.0)
	_press_at(sn, s["notes"][0]["t"] - s["notes"][0]["gw"] * 0.5)
	done = sn._seq_judge()
	chk("easy: one gold press on a 2-circle silver fry is enough (two points)", done and s["ok"] and s["points"] == 2, "points %d need %d" % [s["points"], s["need"]])
	sn.seq = null
	sn.lock_fry = null
	# the tune functions do not crash and the tunes are in the right register
	var T = preload("res://scripts/systems/tunes.gd")
	var tn = T.pick(1, 6, "fry", "")
	T.play(tn, 0, false)
	T.gold(tn, 0)
	T.beat(tn, 1)
	T.hit(tn, 2, 5)
	var hi_ok = true
	for i in tn["notes"].size():
		hi_ok = hi_ok and T.note_of(tn, i) <= 96 and T.note_of(tn, i) >= 55
	chk("the cheerful families sing an octave higher, inside the bank", hi_ok and tn["lift"] == 12, "lift %d first note %d" % [tn["lift"], T.note_of(tn, 0)])
	chk("the Ode to Joy is gone from the silver and diamond families", not T.FAMILIES["silver"]["songs"].has("ode") and not T.FAMILIES["diamond"]["songs"].has("ode"))
	# the goals board folds with Q
	GS.board_open = true
	var b0 = GS.board_open
	at.tap("board_toggle")
	await at.real(0.2)
	var b1 = GS.board_open
	at.tap("board_toggle")
	await at.real(0.2)
	chk("Q folds the goals board away and brings it back", b0 and not b1 and GS.board_open, "%s %s %s" % [str(b0), str(b1), str(GS.board_open)])
	GS.board_open = false
	await at.real(0.4)
	await at.shot("r18h_board_folded")
	GS.board_open = true
	await at.real(0.4)
	await at.shot("r18h_board_open")
	get_tree().quit()

# --r18f: OCEAN TIME: fish in the air near the gull of every rarity, TAB locks the fish in the middle of the view, SPACE launches at it
func r18f():
	await get_tree().create_timer(1.5).timeout
	var p = _setup("easy")
	var sn = p.snatch
	GS.fish_t = 80.0
	GS.fish_streak = 1
	GS.fish_streak_t = 14.0
	GS.tab_lesson = 2
	GS.vision_tired = false
	p.global_position = Vector3(14.0, -0.7, 66.0)
	p.velocity = Vector3.ZERO
	p.yaw = PI
	p.aim_yaw = PI
	p._enter_water(true)
	p.stamina = GS.stamina_max()
	var have_all = 0
	var samples = 0
	var min_air = 99
	var t0 = GS.msec()
	var locked_ok = false
	var shot_done = false
	var launched = false
	var dist0 = 0.0
	var fish_at_lock = null
	var dbg_last = -1
	while (GS.msec() - t0) < 40000:
		await get_tree().process_frame
		GS.fish_t = max(GS.fish_t, 60.0)
		p.stamina = GS.stamina_max()
		var seen = [0, 0, 0]
		for f in get_tree().get_nodes_in_group("fish_live"):
			if is_instance_valid(f) and f.global_position.distance_to(p.global_position) < 85.0:
				seen[clamp(f.rarity, 0, 2)] += 1
		var t = (GS.msec() - t0) / 1000.0
		if int(t * 2.0) != dbg_last and OS.get_cmdline_user_args().has("--dbg"):
			dbg_last = int(t * 2.0)
			var stc = {}
			var near_sp = 0
			for sp in get_tree().get_nodes_in_group("fish_spots"):
				stc[sp.state] = stc.get(sp.state, 0) + 1
				if sp.global_position.distance_to(p.global_position) < 85.0:
					near_sp += 1
			at.say("[R18]   t %.1f seen %s spots %s near spots %d live %d %s fish_t %.0f on_water %s mode %d" % [t, str(seen), str(stc), near_sp, preload("res://scripts/world/fish_spot.gd").live, str(preload("res://scripts/world/fish_spot.gd").live_rar), GS.fish_t, str(p.on_water), p.mode])
		if t > 8.0 and not launched:
			samples += 1
			if seen[0] > 0 and seen[1] > 0 and seen[2] > 0:
				have_all += 1
			min_air = min(min_air, seen[0] + seen[1] + seen[2])
		# lock: look at the nearest fish and hold TAB
		if t > 10.0 and not locked_ok and not launched:
			var best = null
			var bd = 999.0
			for f in get_tree().get_nodes_in_group("fish_live"):
				if is_instance_valid(f) and not f.taken and f.available and f.spot != null and f.spot.leap_dur - f.spot.st > 2.8:
					var dd = f.global_position.distance_to(p.global_position)
					if dd < bd and dd < 60.0 and dd > 8.0:
						bd = dd
						best = f
			if best != null:
				Input.action_press("gull_sense")
				if not GS.sense_active:
					main._open_sense()
				# the camera lags a little behind the beak: keep looking at the fish for a moment, TAB held
				var wait_t = 0.0
				while wait_t < 4.0 and sn.fish_lock == null and is_instance_valid(best):
					at.aim_at(p, best.global_position)
					await get_tree().process_frame
					wait_t += get_process_delta_time() / max(Engine.time_scale, 0.05)
				if sn.fish_lock != null:
					locked_ok = true
					fish_at_lock = sn.fish_lock
					at.say("[R18] locked a %s (rarity %d) at %.0f m after %.1f s" % [fish_at_lock.species, fish_at_lock.rarity, bd, wait_t])
					await at.shot("r18f_1_locked")
					Input.action_release("gull_sense")
					main._close_sense()
					await at.real(0.3)
					dist0 = fish_at_lock.global_position.distance_to(p.global_position)
					at.tap("flap")
					launched = true
					await at.real(0.25)
					await at.shot("r18f_2_launch")
				else:
					var cam = get_viewport().get_camera_3d()
					var dd2 = 0.0
					if cam != null and is_instance_valid(best):
						dd2 = (-cam.global_transform.basis.z).dot((best.global_position - cam.global_position).normalized())
					at.say("[R18]   no lock: dot %.2f sense %s on_water %s mode %d input_locked %s fish_active %s state %s dist %.0f valid %s" % [dd2, str(GS.sense_active), str(p.on_water), p.mode, str(p.input_locked), str(GS.fish_active()), sn.state, bd, str(is_instance_valid(best))])
					Input.action_release("gull_sense")
					main._close_sense()
		if launched and not shot_done:
			if is_instance_valid(fish_at_lock):
				var dn = (fish_at_lock.global_position - p.global_position).normalized()
				var fwd = -p.global_transform.basis.z
				var ang = rad_to_deg(acos(clamp(fwd.dot(dn), -1.0, 1.0)))
				at.say("[R18] launched: mode %d speed %.0f angle to the fish %.0f deg, distance %.0f (was %.0f)" % [p.mode, p.speed * GS.SPEED_UNIT, ang, fish_at_lock.global_position.distance_to(p.global_position), dist0])
				shot_done = true
				chk("OCEAN TIME: the launch points at the locked fish (within 45 degrees)", p.mode == 0 and ang < 45.0, "%.0f deg" % ang)
				await at.real(0.8)
				if is_instance_valid(fish_at_lock):
					var d1 = fish_at_lock.global_position.distance_to(p.global_position)
					chk("OCEAN TIME: a second later the gull is closer to the fish", d1 < dist0 + 2.0, "%.0f -> %.0f" % [dist0, d1])
				break
	chk("OCEAN TIME: a fish of every rarity in the air near the gull (90 % of the samples)", samples > 0 and float(have_all) / float(samples) >= 0.9, "%d of %d samples, fewest fish in the air %d" % [have_all, samples, min_air])
	chk("OCEAN TIME: TAB locked a fish", locked_ok)
	get_tree().quit()

# --r18w: the HARD rhythm on screen (one gold band) and the EASY one for comparison: a silver fry locked by hand, the bot presses E in the middle of the band
func _show_rhythm(f, tag, press_from = 1):
	var p = main.player
	var sn = p.snatch
	var tgt = f.aim_point()
	at.place(tgt + Vector3(0.0, 4.0, 9.0), tgt, 9.0)
	await at.real(0.3)
	sn.snatch_cd = 0.0
	sn._lock_on(f)
	var shots = 0
	var k = 0
	var t_end = GS.msec() + 14000
	while sn.seq != null and GS.msec() < t_end:
		await get_tree().process_frame
		if sn.seq == null:
			break
		var s = sn.seq
		var now = sn.seq_now()
		var idx = sn._first_pending(s)
		if idx < 0:
			continue
		var nt = s["notes"][idx]
		var mid = nt["t"] - (nt["gw"] + nt["gg"] * 0.5) if not s["single"] else nt["t"] - nt["gw"] * 0.5
		# the shots: the first wave on its way, one in the band, one after a hit
		if shots == 0 and now > nt["t"] - nt["appr"] * 0.5 and idx == 0:
			shots = 1
			await at.shot("r18w_%s_1_first_wave" % tag)
		if idx >= press_from and now >= mid:
			if shots == 1 and idx == press_from:
				shots = 2
				await at.shot("r18w_%s_2_in_the_band" % tag)
			at.tap("interact")
			if shots == 2:
				await get_tree().process_frame
				shots = 3
				await at.shot("r18w_%s_3_after_a_hit" % tag)
		elif idx < press_from and now >= nt["t"] + 0.2:
			pass
	at.say("[R18] %s rhythm shown: seq %s" % [tag, "running" if sn.seq != null else "over"])
	sn._unlock()
	Engine.time_scale = 1.0
	await at.real(1.0)

func r18w():
	await get_tree().create_timer(1.5).timeout
	var p = _setup("hard")
	var fr = main.world["fries"]
	var silver = null
	for k in fr:
		var f = fr[k]
		if f.is_special() and f.tier == 1 and silver == null:
			silver = f
	GS.tutorial_done = {"TUTORIAL_01": true, "TUTORIAL_02": true, "TUTORIAL_03": true}
	GS.gull_sense_count = 3
	await _show_rhythm(silver, "hard", 1)
	GS.set_diff("easy")
	await _show_rhythm(silver, "easy", 0)
	get_tree().quit()
