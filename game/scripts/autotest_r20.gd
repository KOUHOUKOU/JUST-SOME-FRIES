extends Node
# Round 20 tests. Started by autotest.gd (--r20j: the ocean launch in slow motion; how smooth is the camera?).
var at
var main

func say(s):
	at.say("[R20] " + s)

# one launch from the water: `slow` = Gull Sight (TAB) is held, the world runs at 0.3. Returns the frame-by-frame camera record.
func _launch_run(slow):
	var p = main.player
	GS.fish_t = 80.0
	GS.fish_streak = 1
	GS.fish_streak_t = 14.0
	p.global_position = Vector3(14.0, -0.7, 66.0)
	p.velocity = Vector3.ZERO
	p.yaw = PI
	p.aim_yaw = PI
	p.pitch = 0.0
	p._enter_water(true)
	await at.real(1.2)
	if slow:
		Input.action_press("gull_sense")
		main._open_sense()
	await at.real(0.6)
	var cam = p.get_viewport().get_camera_3d()
	var rec = []
	at.tap("flap")
	var t0 = Time.get_ticks_usec()
	for i in 150:
		await RenderingServer.frame_pre_draw        # (what is actually drawn: after every _process of the frame)
		var b = cam.global_transform.basis
		rec.append({"t": (Time.get_ticks_usec() - t0) / 1e6, "pos": cam.global_position, "fwd": -b.z, "fov": cam.fov, "ts": Engine.time_scale, "ph": p.global_position, "mode": p.mode, "rig": p.rig.global_position, "hit": p.arm.get_hit_length(), "len": p.arm.spring_length, "tgt": p.get_global_transform_interpolated().origin})
	if slow:
		Input.action_release("gull_sense")
		main._close_sense()
	await at.real(0.5)
	return rec

# second differences of the camera: a smooth motion has small ones; a jitter has big ones
func _stats(rec, label):
	var n = rec.size()
	var worst_p = 0.0
	var sum_p = 0.0
	var worst_f = 0.0
	var sum_f = 0.0
	var worst_v = 0.0
	var sum_v = 0.0
	var worst_i = 0
	var cnt = 0
	for i in range(2, n):
		var d1 = rec[i]["pos"] - rec[i - 1]["pos"]
		var d0 = rec[i - 1]["pos"] - rec[i - 2]["pos"]
		var dd = (d1 - d0).length()
		var f1 = rec[i]["fwd"] - rec[i - 1]["fwd"]
		var f0 = rec[i - 1]["fwd"] - rec[i - 2]["fwd"]
		var ff = (f1 - f0).length()
		var v = abs(rec[i]["fov"] - rec[i - 1]["fov"])
		sum_p += dd
		sum_f += ff
		sum_v += v
		cnt += 1
		if dd > worst_p:
			worst_p = dd
			worst_i = i
		worst_f = max(worst_f, ff)
		worst_v = max(worst_v, v)
	var line = ""
	for i in range(1, min(n, 46)):
		line += "%.2f " % (rec[i]["pos"] - rec[i - 1]["pos"]).length()
	say(label + " step per frame: " + line)
	var lf = ""
	for i in range(1, min(n, 46)):
		lf += "%.1f " % (rec[i]["fov"])
	say(label + " fov: " + lf)
	var lt = ""
	for i in range(1, min(n, 46)):
		lt += "%.2f " % (rec[i]["ph"] - rec[i - 1]["ph"]).length()
	say(label + " gull step per frame: " + lt)
	var lr = ""
	var lh = ""
	var lg = ""
	for i in range(1, min(n, 46)):
		lr += "%.2f " % (rec[i]["rig"] - rec[i - 1]["rig"]).length()
		lh += "%.1f/%.1f " % [rec[i]["hit"], rec[i]["len"]]
		lg += "%.2f " % (rec[i]["tgt"] - rec[i - 1]["tgt"]).length()
	say(label + " rig step: " + lr)
	say(label + " arm hit/len: " + lh)
	say(label + " interpolated gull step: " + lg)
	say("%s: camera position 2nd-diff mean %.3f worst %.3f (frame %d), direction 2nd-diff mean %.4f worst %.4f, fov step mean %.3f worst %.3f, time_scale %.2f..%.2f, %d frames in %.2f s" % [label, sum_p / cnt, worst_p, worst_i, sum_f / cnt, worst_f, sum_v / cnt, worst_v, rec[0]["ts"], rec[n - 1]["ts"], n, rec[n - 1]["t"]])
	return {"p": worst_p, "f": worst_f, "v": worst_v}

func r20j():
	await get_tree().create_timer(1.5).timeout
	var p = main.player
	GS.gull_sense_count = 3
	GS.tutorial_done = {"TUTORIAL_01": true, "TUTORIAL_02": true, "TUTORIAL_03": true}
	for i in 7:
		GS.set_level(GS.FRY_TYPES[i], 1)
	main._reveal_specials()
	main.meteors.set_process(false)
	GS.tab_lesson = 2
	GS.vision_tired = false
	p.input_locked = false
	GS.set_diff("easy")
	var a = _stats(await _launch_run(false), "normal time")
	var b = _stats(await _launch_run(true), "slow time (TAB)")
	var verdict = b["p"] < max(a["p"] * 2.5, 0.35)
	say("%s the launch in slow motion is as smooth as in normal time (worst position jump %.3f vs %.3f)" % ["PASS" if verdict else "FAIL", b["p"], a["p"]])
	get_tree().quit()

func chk(name_, ok, extra = ""):
	say("%s %s %s" % ["PASS" if ok else "FAIL", name_, extra])

# --r20t: the big brother's talks (which one when, one per visit, small talks by stage, every line translated)
func r20t():
	await get_tree().create_timer(1.0).timeout
	var BT = load("res://scripts/ui/bro_talks.gd")
	var bro = main.bro
	GS.reset()
	GS.cine_seen = {}
	GS.gull_sense_count = 3
	chk("a gull with three fries hears the first talk", BT.next_talk(bro) == "chat1")
	GS.cine_seen["chat1"] = true
	chk("then nothing new is left (no accessory, no fish, no sky)", BT.next_talk(bro) == "")
	GS.worn["hat"] = true
	chk("a gull with an accessory gets the hat talk", BT.next_talk(bro) == "bro_hat")
	GS.cine_seen["bro_hat"] = true
	GS.memories["fish"] = {"t": 5.0}
	GS.memories["sky_moon"] = {"t": 9.0}
	GS.memories["sky_star"] = {"t": 8.0}
	chk("fish before the sky", BT.next_talk(bro) == "bro_fish")
	GS.cine_seen["bro_fish"] = true
	chk("the star talk comes before the moon talk", BT.next_talk(bro) == "bro_sky_star")
	GS.cine_seen["bro_sky_star"] = true
	chk("then the moon", BT.next_talk(bro) == "bro_sky_moon")
	GS.cine_seen["bro_sky_moon"] = true
	GS.sky_got = {"cloud": true, "star": true, "moon": true, "sun": true, "rainbow": true}
	GS.memories["sky_sun"] = {"t": 10.0}
	GS.memories["sky_cloud"] = {"t": 11.0}
	GS.memories["sky_rainbow"] = {"t": 12.0}
	var order = []
	for i in 6:
		var c = BT.next_talk(bro)
		if c == "":
			break
		order.append(c)
		GS.cine_seen[c] = true
	chk("the three remaining sky talks come one by one, then the whole-sky talk", order == ["bro_sky_cloud", "bro_sky_sun", "bro_sky_rainbow", "chat_sky"], str(order))
	chk("and then nothing", BT.next_talk(bro) == "")
	# the ladder: a gull that comes late hears the newest talk and the older ones count as heard
	GS.cine_seen = {}
	for t in GS.FRY_TYPES:
		GS.set_level(t, 3)
	chk("24 fries: the last talk of the ladder", BT.next_talk(bro) == "chat4")
	GS.cine_seen = {"chat1": true, "chat2": true, "chat3": true}
	chk("the last talk does not mention going back to the start", true)
	for ln in BT.lines("chat4"):
		if "table" in ln or "start" in ln.to_lower() or "go look" in ln.to_lower():
			chk("chat4 line without a direct instruction", false, ln)
	# small talks
	GS.reset()
	GS.gull_sense_count = 3
	var seen = {}
	var prev = null
	var repeats = 0
	for i in 40:
		var t = BT.small_talk()
		if prev != null and str(t) == str(prev):
			repeats += 1
		prev = t
		seen[str(t)] = true
	chk("small talks never repeat twice in a row, and there are several", repeats == 0 and seen.size() >= 4, "%d kinds" % seen.size())
	GS.free_play = true
	chk("after the end the first talk is free_intro", BT.next_talk(bro) == "free_intro")
	GS.cine_seen["free_intro"] = true
	chk("then only small talks", BT.next_talk(bro) == "")
	var st3 = BT.small_talk()
	chk("an after-the-end small talk has lines", st3.size() >= 2)
	GS.free_play = false
	# every line has a translation in all three languages
	var texts = []
	for id in BT.KEY:
		for ln in BT.KEY[id]:
			texts.append(ln.substr(2) if ln.begins_with("Y|") else ln)
	for stage in BT.SMALL:
		for tk in stage:
			for ln in tk:
				texts.append(ln.substr(2) if ln.begins_with("Y|") else ln)
	for ln in ["...That's a lot of hats, kid.", "I'd know.", "...What's that.", "It doesn't glow.", "...same.", "Mine took years to put on.", "...It's still warm.", "I'd forgotten it was this small.", "he took off the chain. nobody asked him to.", "I'm keeping the hat.", "That old man. Does he still drop them?", "...Good.", "hold E: fast-forward"]:
		texts.append(ln)
	for lang in ["zh_CN", "zh_TW", "ja"]:
		Loc.set_lang(lang)
		var missing = []
		for t in texts:
			if Loc.t(t) == t:
				missing.append(t)
		chk("every line of the big brother is translated (%s)" % lang, missing.is_empty(), "%d missing, e.g. %s" % [missing.size(), str(missing.slice(0, 3))])
	Loc.set_lang("en")
	# no two key talks are the same, and none is empty
	var bad = []
	for id in BT.KEY:
		if BT.KEY[id].size() < 3:
			bad.append(id)
	chk("every key talk has at least three lines", bad.is_empty(), str(bad))
	get_tree().quit()

# --r20s: screenshots of a big brother talk (layout of the long lines in three languages)
func r20s():
	await get_tree().create_timer(1.5).timeout
	var p = main.player
	GS.gull_sense_count = 3
	main._reveal_specials()
	p.gull.wear("hat")
	for lang in ["en", "zh_CN", "ja"]:
		Loc.set_lang(lang)
		GS.cine_seen.erase("chat4")
		main.bro.near_t = 0.0
		p.mode = 1
		p.global_position = Vector3(-7.0, 5.4, -0.3)
		p.velocity = Vector3.ZERO
		main.scenes.bro_chat("chat4")
		var k = 0
		while main.scenes.cine_busy and k < 60:
			await at.real(1.0)
			if k % 3 == 2:
				await at.shot("r20s_%s_%02d" % [lang, k])
			k += 1
		await at.real(1.5)
	Loc.set_lang("en")
	get_tree().quit()

# ================================================================== the round-20 trailer: two more film segments (the rest are autotest.gd film_seg*)
# 40: THE RAINBOW. The arch over the sea, a long dive through it, the 14 judgements, and the film moment that follows
func film_seg40():
	var p = await at.film_clean_start()
	at.film16_ready(3)
	main.hud.film_clean = true
	GS.cine_seen.erase("skybow")
	GS.test_boost_bonus = 30.0
	main.meteors.set_process(false)
	main.quest_t = 1.0e9
	var rp = get_tree().get_first_node_in_group("rainbow_pair")
	GS.quests["skybow"] = "active"
	var it = main.quest_items.get("skybow", null)
	if it == null:
		it = Node3D.new()
		it.set_script(load("res://scripts/fries/mischief.gd"))
		it.setup("skybow", main, rp.apex())
		main.quest_items["skybow"] = it
	GS.add_buff("coffee")
	GS.add_buff("alcohol")
	GS.add_buff("ice")
	rp.fade = 1.0
	var ap = rp.apex()
	var wv = rp.wide_view(Vector3(0, 60, 100))
	# the approach: from far out on the side, a slow glide towards the arch (it fills the picture), then the dive
	var side = (wv["pos"] - wv["look"]).normalized()
	var start = ap + side * 120.0 + Vector3(0, -10.0, 0)
	at.place(start, ap, 22.0)
	p.input_locked = false
	await at.real(2.0)
	say("[film] rainbow at %s" % str(ap))
	var r = await at.attempt(it, Vector3(side.x, 0.1, side.z), 90.0, 0.0, -1.0, {"soft": true, "no_place": true, "max_frames": 1500})
	clock("rainbow %s" % str(r))
	Input.action_press("move_forward")
	var t0 = GS.msec()
	var seen = false
	while GS.msec() - t0 < 30000:
		await at.real(0.5)
		if main.scenes.cine_busy:
			seen = true
		elif seen:
			break
	clock("rainbow film done")
	await at.real(2.0)
	Input.action_release("move_forward")

# 41: THE STAR. RAINBOW TIME high over the sea, a falling star, the chase (the bot presses on the beat), the new tail
func film_seg41():
	var p = await at.film_clean_start()
	at.film16_ready(3)
	main.hud.film_clean = true
	GS.cine_seen.erase("meteor")
	main.meteors.set_process(true)
	GS.add_buff("coffee")
	GS.add_buff("alcohol")
	GS.add_buff("ice")
	GS.star_t = max(GS.star_t, 40.0)
	at.place(Vector3(60.0, 80.0, 110.0), Vector3(60.0, 80.0, 40.0), 30.0)
	p.input_locked = false
	Input.action_press("move_forward")
	Input.action_press("dash")
	await at.real(2.5)
	main.meteors.star_pending = 0.0
	main.meteors._plan_star()
	var star = null
	var t1 = GS.msec()
	while GS.msec() - t1 < 24000:
		await at.real(0.1)
		p.aim_yaw += 0.01
		GS.star_t = max(GS.star_t, 30.0)
		if main.meteors.star != null and is_instance_valid(main.meteors.star) and main.meteors.star.age > 1.0:
			star = main.meteors.star
			break
	say("[film] star=%s" % str(star))
	if star != null:
		var d = star.vel.normalized()
		var start = star.global_position - d * 40.0
		start.y = max(start.y, 30.0)
		at.place(start, star.global_position, GS.need_speed(star) + 1.0)
		Input.action_press("move_forward")
		Input.action_press("dash")
		for i in 1800:
			await get_tree().process_frame
			if not is_instance_valid(star) or star.taken:
				break
			GS.star_t = max(GS.star_t, 30.0)
			if p.snatch.state == "idle" and p.snatch.lock_fry == null:
				at.aim_at(p, star.global_position)
				p.stamina = 60.0
			var sq = p.snatch.seq
			if sq != null:
				var idx = p.snatch._first_pending(sq)
				if idx >= 0:
					var nt = sq["notes"][idx]
					var now = p.snatch.seq_now()
					if now >= nt["t"] - sq["gw"] - sq["gg"] * 0.55 and not sq.has("p%d" % idx):
						sq["p%d" % idx] = true
						at.tap("interact")
	Input.action_release("dash")
	await at.real(1.0)
	clock("meteor caught=%s" % str(GS.stats["meteors"]))
	Input.action_press("move_forward")
	var t2 = GS.msec()
	var seen_cine = false
	while GS.msec() - t2 < 40000:
		await at.real(0.5)
		if main.scenes.cine_busy:
			seen_cine = true
		elif seen_cine:
			break
	clock("star film done")
	Input.action_press("dash")
	for i in 150:
		p.aim_yaw += 0.012
		p.aim_pitch = 0.05
		await at.real(1.0 / 30.0)
	Input.action_release("dash")
	Input.action_release("move_forward")
	await at.real(1.0)

func clock(s):
	at.clock(s)
