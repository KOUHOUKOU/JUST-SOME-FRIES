extends Node
# Dev-only test bot. `godot --path game -- <mode>`:
#   --autotest   scripted playthrough of the whole game with a bot pilot
#   --rhythm --flee --star --tiers --land --hud --rainbow   round 5 systems
#   --tour --world --intro --ui --cam --systems --census --soak --fuzz --menu --save --hunger --ending --hazards --fish --rival --volley --wear --comics --title --credits
var main
var shots = "C:/Users/ROG/Desktop/JUST_SOME_FRIES_CODEX_WORKSPACE_v1.0/JUST_SOME_FRIES/shots/"
var metrics = {}

# ECO MODE (round 9): the test bots run on a laptop that must stay quiet: 30 fps, a small window, a lighter 3D resolution. `--full` turns it off (and `--film` never uses it).
var eco = false

func _process(_delta):
	if eco and Engine.max_fps != 30:
		Engine.max_fps = 30

func _ready():
	DirAccess.make_dir_recursive_absolute(shots)
	var args = OS.get_cmdline_user_args()
	if not ("--full" in args) and not ("--film" in args):
		eco = true
		Engine.max_fps = 30
		get_window().size = Vector2i(960, 540)
		get_viewport().scaling_3d_scale = 0.75
	var table = {"--tour": "tour", "--intro": "intro_shots", "--ui": "ui_shots", "--cam": "cam_shots", "--systems": "systems_test", "--early": "early_test", "--fuzz": "fuzz_test",
		"--mischief": "mischief_test", "--star": "star_test", "--prism": "star_test", "--audio": "audio_report", "--cone": "cone_test", "--restart": "restart_test", "--soak": "soak_test",
		"--census": "census", "--flee": "flee_test", "--comics": "comics_test", "--title": "title_test", "--credits": "credits_test", "--menu": "menu_test", "--world": "world_test",
		"--hud": "hud_test", "--tiers": "tiers_test", "--fish": "fish_test", "--rival": "rival_test", "--volley": "volley_test", "--wear": "wear_test", "--save": "save_test",
		"--hunger": "hunger_test", "--ending": "ending_test", "--hazards": "hazards_test", "--rhythm": "rhythm_test", "--land": "land_test", "--rainbow": "rainbow_test", "--one": "one_test", "--topdown": "topdown", "--places": "places_test", "--rest": "rest_test", "--codex": "codex_test", "--drink": "drink_test", "--smash": "smash_test", "--film": "film", "--stand": "stand_test", "--sky": "sky_test", "--census2": "mischief_census", "--reach": "reach_test", "--bank": "bank_test", "--cams": "cams_test", "--r7": "round7_test", "--r7b": "round7b_test", "--r8": "round8_test", "--r8b": "r8cine", "--r8c": "r8open", "--r8t": "r8tab", "--r8e": "r8end", "--r8m": "r8bro", "--r9speed": "r9speed", "--r9cine": "r9cine", "--r9sky": "r9sky", "--r9tab": "r9tab", "--r9trail": "r9trail", "--r9quiet": "r9quiet", "--shotcheck": "shotcheck"}
	for k in table:
		if k in args:
			call(table[k])
			return
	run()

func shot(n):
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shots + n + ".png")


func view(pos, target, fov = 70.0):
	var xf = Transform3D(Basis.IDENTITY, pos).looking_at(target, Vector3.UP)
	main.player.set_override(xf, fov, 1.0, 200.0)


func tour():
	await get_tree().create_timer(1.0).timeout
	main.player.input_locked = true
	var pre = ""
	if "--clean" in OS.get_cmdline_user_args():
		pre = "cl_"
		for c in main.get_children():
			if c is CanvasLayer and c != main.showcase:
				c.visible = false
	var views = {
		"t01_spawn": [Vector3(-9.5, 8.0, -9.0), Vector3(-9.5, 3.0, 4.0), 70.0],
		"t02_cafe_fry": [Vector3(-5.0, 2.6, 8.0), Vector3(-8.0, 0.6, 3.6), 60.0],
		"t03_t2_plate": [Vector3(-5.5, 2.2, 3.6), Vector3(-3.0, 0.9, 5.6), 55.0],
		"t04_kiosk": [Vector3(-10.0, 3.0, 22.0), Vector3(-17.0, 1.2, 15.0), 65.0],
		"t05_beach": [Vector3(20.0, 6.0, 40.0), Vector3(30.0, 1.0, 14.0), 70.0],
		"t06_pier_wheel": [Vector3(2.0, 8.0, 98.0), Vector3(2.0, 12.0, 55.0), 65.0],
		"t07_lighthouse": [Vector3(-50.0, 30.0, 70.0), Vector3(-102.0, 20.0, 40.0), 65.0],
		"t08_hill": [Vector3(0.0, 24.0, -6.0), Vector3(0.0, 10.0, -50.0), 70.0],
		"t09_park": [Vector3(-45.0, 14.0, 20.0), Vector3(-58.0, 0.0, -10.0), 70.0],
		"t10_harbor": [Vector3(55.0, 28.0, 12.0), Vector3(85.0, 5.0, -25.0), 70.0],
		"t11_overview": [Vector3(10.0, 110.0, 150.0), Vector3(0.0, 0.0, 10.0), 70.0],
		"t12_market": [Vector3(-30.0, 5.0, 28.0), Vector3(-46.0, 1.0, 16.0), 70.0],
		"t13_marina": [Vector3(-5.0, 10.0, 52.0), Vector3(-22.0, 0.0, 35.0), 70.0],
		"t14_islet": [Vector3(0.0, 14.0, 96.0), Vector3(0.0, 4.0, 118.0), 70.0],
		"t15_green_kid": [Vector3(21.0, 3.0, 22.0), Vector3(27.0, 1.0, 14.5), 60.0],
		"t16_red_pier": [Vector3(1.0, 5.0, 82.0), Vector3(1.5, 1.0, 70.0), 60.0],
		"t19_gull": [Vector3(-8.2, 5.9, 1.2), Vector3(-9.5, 5.5, -0.8), 45.0],
		"t20_kid_yellow": [Vector3(-9.0, 2.6, 15.5), Vector3(-11.0, 1.2, 11.5), 55.0],
		"t21_rose_park": [Vector3(-33.0, 3.0, 10.0), Vector3(-38.0, 1.0, 3.0), 55.0],
	}
	GS.gull_sense_count = 3
	main._reveal_specials()
	for k in views:
		var v = views[k]
		view(v[0], v[1], v[2])
		await get_tree().create_timer(0.5).timeout
		await shot(pre + k)
	# dusk look
	main.day.t = 1.0
	main.day.target = 1.0
	GS.hunger_t = 500.0
	view(Vector3(-5.0, 6.0, 12.0), Vector3(-14.0, 2.0, -2.0), 70.0)
	await get_tree().create_timer(0.6).timeout
	await shot(pre + "t17_dusk_cafe")
	view(Vector3(10.0, 12.0, 70.0), Vector3(2.0, 12.0, 55.0), 65.0)
	await get_tree().create_timer(0.4).timeout
	await shot(pre + "t18_dusk_wheel")
	get_tree().quit()

# ------------------------------------------------------------------ bot pilot

func press(action):
	var ev = InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().physics_frame
	var ev2 = InputEventAction.new()
	ev2.action = action
	ev2.pressed = false
	Input.parse_input_event(ev2)


func aim_at(p, tgt):
	var v = tgt - p.global_position
	if v.length() < 0.1:
		return
	v = v.normalized()
	p.yaw = atan2(-v.x, -v.z)
	p.aim_yaw = p.yaw
	p.pitch = asin(clamp(v.y, -1.0, 1.0))
	p.aim_pitch = p.pitch


func place(pos, tgt, speed = 11.0):
	var p = main.player
	p.mode = 0
	p.global_position = pos
	p.velocity = Vector3.ZERO
	p.speed = speed
	p.stamina = GS.stamina_max()
	aim_at(p, tgt)


func pick_dir(f, fallback):
	var tgt = f.aim_point()
	var space = main.get_world_3d().direct_space_state
	for slope in [0.3, 0.0, 0.7, 1.2]:
		for k in 8:
			var a = k * TAU / 8.0
			var d = Vector3(cos(a), slope, sin(a)).normalized()
			var q = PhysicsRayQueryParameters3D.create(tgt + d * 26.0, tgt + d * 1.5, 1)
			if space.intersect_ray(q).is_empty():
				if slope == 0.3 and k > 0 and fallback.dot(d) <= 0.5:
					continue
				return d
	return fallback

func intro_shots():
	for t in [0.8, 2.0, 3.2, 4.4, 5.6, 7.6]:
		await get_tree().create_timer(t - metrics.get("tt", 0.0)).timeout
		metrics["tt"] = t
		await shot("i_%02d" % int(t * 10))
	say("intro done active=%s" % main.intro_active)
	get_tree().quit()


func ui_shots():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	main._reveal_specials()
	GS.set_level("red", 1)
	GS.set_level("blue", 2)
	GS.set_level("pink", 1)
	main.hud.collected = {"red": true, "blue": true}
	main.hud.slots_visible = true
	p.mode = 0
	p.global_position = Vector3(-8.0, 4.0, 14.0)
	aim_at(p, Vector3(-8.0, 1.0, 3.0))
	p.speed = 5.0
	await get_tree().create_timer(0.5).timeout
	p.global_position = Vector3(-5.0, 3.5, 11.0)
	aim_at(p, Vector3(-8.0, 1.0, 3.0))
	GS.heat = 2.5
	await get_tree().create_timer(1.0).timeout
	await shot("u_hud")
	main._open_codex()
	main.codex_yaw = 0.15
	main.codex_pitch = 0.45
	p.global_position = Vector3(-6.0, 3.0, 8.0)
	await get_tree().create_timer(1.2).timeout
	await shot("u_codex")
	main._close_codex()
	var cone = main.elder.head.get_node_or_null("Cone")
	say("cone=%s vis=%s sense=%s" % [cone, cone.visible if cone else "-", GS.sense_active])
	say("fps=%d drawcalls=%d objects=%d" % [Engine.get_frames_per_second(), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)])
	main.menus.set_paused(true)
	await get_tree().create_timer(0.3).timeout
	await shot("u_pause")
	get_tree().quit()


func cam_shots():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	p.mode = 0
	p.global_position = Vector3(10, 30, 100)
	aim_at(p, Vector3(10, 24, 0))
	p.speed = 5.0
	await get_tree().create_timer(1.0).timeout
	await shot("c_glide")
	Input.action_press("move_forward")
	await get_tree().create_timer(2.5).timeout
	await shot("c_throttle")
	Input.action_press("dash")
	await get_tree().create_timer(1.6).timeout
	await shot("c_boost")
	# bank turn
	Input.action_press("bank_left")
	await get_tree().create_timer(0.8).timeout
	await shot("c_boost_turn")
	Input.action_release("bank_left")
	Input.action_release("dash")
	Input.action_release("move_forward")
	# low skim over water
	p.global_position = Vector3(40, 0.3, 110)
	aim_at(p, Vector3(40, 0.3, 40))
	p.speed = 11.0
	Input.action_press("move_forward")
	await get_tree().create_timer(1.2).timeout
	await shot("c_skim")
	Input.action_release("move_forward")
	get_tree().quit()


func systems_test():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	say("start mode=%d (1=ground) stamina=%.0f" % [p.mode, p.stamina])
	await press("flap")
	await get_tree().create_timer(0.5).timeout
	say("after takeoff mode=%d (0=fly) speed=%.1f" % [p.mode, p.speed])
	# double-tap roll
	p.global_position = Vector3(10, 30, 100)
	aim_at(p, Vector3(10, 30, 0))
	await press("bank_right")
	await get_tree().create_timer(0.1).timeout
	await press("bank_right")
	await get_tree().create_timer(0.1).timeout
	say("roll invuln=%.2f roll_t=%.2f stamina=%.0f" % [p.invuln_t, p.roll_t, p.stamina])
	await get_tree().create_timer(1.0).timeout
	# wall crash at speed
	place(Vector3(-9.5, 2.0, -20.0), Vector3(-9.5, 2.0, 0.0), 14.0)
	Input.action_press("move_forward")
	var crashed = false
	for i in 200:
		await get_tree().physics_frame
		if p.mode == 2:
			crashed = true
			break
	Input.action_release("move_forward")
	say("wall crash tumble=%s stamina=%.0f" % [crashed, p.stamina])
	await get_tree().create_timer(2.5).timeout
	say("after tumble mode=%d speed=%.1f" % [p.mode, p.speed])
	# dive into water
	place(Vector3(40, 3, 100), Vector3(40, -2, 90), 10.0)
	await get_tree().create_timer(1.5).timeout
	say("water soaked_t=%.1f" % p.soaked_t)
	# land on a tree top / roof, check perch regen and shake-off
	p.soaked_t = 10.0
	place(Vector3(-25.0, 4.4, 17.0), Vector3(-21.0, 3.4, 17.0), 5.0)
	p.stamina = 20.0
	for k in 10:
		await get_tree().create_timer(0.25).timeout
		say("   t=%.2f mode=%d pos=%s speed=%.1f vel=%s" % [k * 0.25, p.mode, str(p.global_position), p.speed, str(p.velocity)])
	say("church perch mode=%d high=%s y=%.1f stamina=%.0f regen=%s" % [p.mode, p.perch_high, p.global_position.y, p.stamina, p.regen_active])
	await get_tree().create_timer(2.0).timeout
	say("still: calm=%.2f soaked=%.1f stamina=%.0f" % [p.calm, p.soaked_t, p.stamina])
	await shot("s_perch")
	# codex
	main._open_codex()
	await get_tree().create_timer(0.5).timeout
	say("codex open ts=%.2f locked=%s" % [Engine.time_scale, p.input_locked])
	main._close_codex()
	say("codex closed ts=%.2f locked=%s" % [Engine.time_scale, p.input_locked])
	get_tree().quit()


func restart_test():
	await get_tree().create_timer(1.5).timeout
	say("before restart: skip_menu=%s" % GS.skip_menu)
	main.menus.restart_pressed.emit()


func cone_test():
	await get_tree().create_timer(1.0).timeout
	GS.sense_active = true
	main.player.input_locked = true
	view(Vector3(-8.0, 15.0, 4.0), Vector3(-8.0, 0.0, 6.0), 70.0)
	await get_tree().create_timer(0.8).timeout
	await shot("cone_top")
	get_tree().quit()


func audio_report():
	while not Sfx.ready_ok:
		await get_tree().create_timer(0.5).timeout
	DirAccess.make_dir_recursive_absolute("res://assets/audio/preview")
	var names = Sfx.sounds.keys()
	names.sort()
	for n in names:
		var st = Sfx.sounds[n]
		var data = st.data
		var cnt = data.size() / 2
		var peak = 0.0
		var sumsq = 0.0
		var zc = 0
		var prev = 0.0
		for i in cnt:
			var v = data.decode_s16(i * 2) / 32768.0
			peak = max(peak, abs(v))
			sumsq += v * v
			if (v >= 0.0) != (prev >= 0.0):
				zc += 1
			prev = v
		var dur = float(cnt) / st.mix_rate
		say("%-12s dur=%.2fs peak=%.2f rms=%.3f approx_hz=%d" % [n, dur, peak, sqrt(sumsq / max(cnt, 1)), int(zc / 2.0 / max(dur, 0.01))])
		st.save_to_wav("res://assets/audio/preview/%s.wav" % n)
	for k in ["wind", "waves", "murmur"]:
		var s2 = Sfx.get(k).stream
		s2.save_to_wav("res://assets/audio/preview/loop_%s.wav" % k)
	for i in 3:
		Sfx.music[i].stream.save_to_wav("res://assets/audio/preview/music_layer_%d.wav" % i)
	get_tree().quit()

# every spot where a star fry can hang: is it reachable, and is the (single-check) grab doable?

func mischief_test():
	await get_tree().create_timer(1.0).timeout
	GS.gull_sense_count = 3
	var items = get_tree().get_nodes_in_group("mischief")
	say("mischief items: %d" % items.size())
	var done = {}
	for m in items:
		var k = m.kind
		if done.has(k) and done[k] >= 1:
			continue
		var r = await attempt(m, pick_dir(m, Vector3(0, 0.3, 1)), 30.0, 0.0, 16.0)
		await get_tree().create_timer(0.5).timeout
		say("%s -> %s taken=%s" % [k, r, m.taken if is_instance_valid(m) else "freed"])
		done[k] = done.get(k, 0) + 1
	say("achievements=%s mischief=%s" % [str(GS.achievements_done.keys()), str(GS.mischief_counts)])
	await shot("m_gull_hat")
	get_tree().quit()


func fuzz_test():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	var rng = RandomNumberGenerator.new()
	rng.seed = 1234
	GS.gull_sense_count = 3
	main._reveal_specials()
	var acts = ["move_forward", "move_back", "bank_left", "bank_right", "flap", "dash", "interact", "squawk"]
	var held = {}
	var t_end = Time.get_ticks_msec() + 100000
	var n = 0
	while Time.get_ticks_msec() < t_end:
		await get_tree().physics_frame
		n += 1
		p.mouse_accum += Vector2(rng.randf_range(-12, 12), rng.randf_range(-8, 8))
		if n % 6 == 0:
			var a2 = acts[rng.randi() % acts.size()]
			if held.get(a2, false):
				Input.action_release(a2)
				held[a2] = false
			else:
				Input.action_press(a2)
				held[a2] = true
			if a2 in ["interact", "flap", "squawk"]:
				await press(a2)
		if n % 300 == 0:
			# occasionally hop to a random fry or spot
			var spots = main.world["prism_spots"]
			var sp = spots[rng.randi() % spots.size()]
			p.global_position = sp["pos"] + Vector3(rng.randf_range(-8, 8), rng.randf_range(0, 6), rng.randf_range(-8, 8))
			p.velocity = Vector3.ZERO
			if rng.randf() < 0.3:
				main._open_sense()
			elif GS.sense_active:
				main._close_sense()
			elif rng.randf() < 0.3:
				main._open_codex()
			elif main.codex_open:
				main._close_codex()
		if n % 900 == 0:
			GS.set_level("blue", min(GS.lv["blue"] + 1, 3))
			GS.phase = GS.Phase.STILL_HUNGRY
	for a3 in acts:
		Input.action_release(a3)
	main._close_sense_if_open()
	say("fuzz done frames=%d mode=%d stamina=%.0f ts=%.2f" % [n, p.mode, p.stamina, Engine.time_scale])
	get_tree().quit()


func early_test():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	var o = main.ordinary
	p.mode = 0
	p.global_position = o.global_position + Vector3(0.3, 0.7, 1.2)
	p.speed = 3.0
	aim_at(p, o.global_position)
	await get_tree().physics_frame
	await get_tree().physics_frame
	say("hud_state=%s" % p.snatch.hud_state)
	await press("interact")
	await get_tree().create_timer(5.0).timeout
	await shot("e_early_ending")
	say("early bird=%s ended=%s day_t=%.2f" % [GS.achievements_done.has("EARLY BIRD"), GS.ordinary_eaten, main.day.t])
	get_tree().quit()

# ------------------------------------------------------------------ soak: long run, logs engine monitors

func soak_test():
	var secs = 240.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--secs="):
			secs = float(a.substr(7))
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	var spots = [Vector3(-9, 8, 6), Vector3(0, 12, 70), Vector3(40, 10, 25), Vector3(-95, 35, 45), Vector3(-50, 15, -10), Vector3(70, 20, -10), Vector3(0, 20, -35), Vector3(-20, 6, 14), Vector3(0, 8, 110)]
	var t0 = Time.get_ticks_msec()
	var last_log = -100.0
	var wp = 0
	var timer = 0.0
	GS.gull_sense_count = 3
	main._reveal_specials()
	Input.action_press("move_forward")
	p.mode = 0
	while (Time.get_ticks_msec() - t0) / 1000.0 < secs:
		await get_tree().physics_frame
		timer += get_physics_process_delta_time()
		if p.mode == 2:
			continue
		if p.global_position.distance_to(spots[wp]) < 12.0 or timer > 25.0:
			wp = (wp + 1) % spots.size()
			timer = 0.0
		aim_at(p, spots[wp])
		if fmod(timer, 9.0) < 0.1:
			Input.action_press("dash")
		elif fmod(timer, 9.0) > 3.0:
			Input.action_release("dash")
		p.stamina = max(p.stamina, 40.0)
		var now = (Time.get_ticks_msec() - t0) / 1000.0
		if int(now) % 17 == 5 and not GS.sense_active and now - last_log > 0.5:
			main._open_sense()
			get_tree().create_timer(1.0, true, false, true).timeout.connect(func(): main._close_sense_if_open())
		if int(now) % 11 == 3:
			Input.action_press("squawk")
		else:
			Input.action_release("squawk")
		if now - last_log >= 10.0:
			last_log = now
			say("t=%03d fps=%d proc=%.1fms phys=%.1fms obj=%d nodes=%d orphans=%d memstat=%.0fMB vram=%.0fMB tex=%.0fMB buf=%.0fMB draws=%d prims=%dk objs_frame=%d" % [
				int(now), Performance.get_monitor(Performance.TIME_FPS),
				Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
				Performance.get_monitor(Performance.OBJECT_COUNT), Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
				Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
				Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
				Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000, Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)])
	Input.action_release("move_forward")
	Input.action_release("dash")
	say("soak done")
	get_tree().quit()


func census():
	await get_tree().create_timer(1.5).timeout
	var by = {}
	var total = 0
	var stack = [main]
	while not stack.is_empty():
		var n = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is MeshInstance3D and n.is_visible_in_tree():
			total += 1
			var top = n
			while top.get_parent() != main and top.get_parent() != null:
				top = top.get_parent()
			var key = "%s [%s]" % [top.name, top.get_script().resource_path.get_file() if top.get_script() != null else top.get_class()]
			by[key] = by.get(key, 0) + 1
	var keys = by.keys()
	keys.sort_custom(func(a, b): return by[a] > by[b])
	say("visible MeshInstance3D total=%d" % total)
	for k in keys.slice(0, 25):
		say("  %5d  %s" % [by[k], k])
	get_tree().quit()


func comics_test():
	await get_tree().create_timer(1.0).timeout
	var h = main.hud
	var cases = [["smug", "MINE NOW."], ["perfect", "PERFECT. EVEN THE FRY IS IMPRESSED."], ["mischief", "TROUBLE, BUT CUTE."],
		["hit_swat_punch", "POW. A PUNCH. FROM A GRANDPARENT."], ["hit_swat_poke", "POKED. WITH AN UMBRELLA."], ["hit_swat_sweep", "SWEPT UP WITH THE CRUMBS."],
		["hit_swat_squirt", "SQUIRTED. BY A CHILD."], ["hit_swat_lunge", "A DOG. OF COURSE."], ["hit_crash", "THE WALL WAS REAL."], ["soaked", "WET. DEEPLY DISGRUNTLED."],
		["hit_swat_ball", "VOLLEYBALL. THE NET WAS RIGHT THERE."], ["hit_swat_rival", "A GULL. THE AUDACITY."], ["hit_swat_grump", "SHOO'D. WITH A NEWSPAPER."], ["rival", "A GULL BEAT YOU TO IT."],
		["scare", "A KID. A VERY LOUD KID."], ["fish", "A FISH. NOT A FRY. STILL FUNNY."], ["cool", "FULLY ARMED. STILL HUNGRY."]]
	for c in cases:
		h.show_comic(c[0], c[1], 5.0, {"type": "red"})
		if c[0] == "fish":
			h.comic.tier = 1
		await get_tree().create_timer(0.7).timeout
		say("comic %s: slide=%.2f size=%s visible=%s id=%s hud_visible=%s" % [c[0], h.comic.slide, str(h.comic.size), h.comic.visible, h.comic.id, h.visible])
		await shot("cm_" + c[0])
		h.comic.slide = 0.0
		if h.comic.tw != null:
			h.comic.tw.kill()
		await get_tree().create_timer(1.6).timeout
	get_tree().quit()


func title_test():
	await get_tree().create_timer(0.5).timeout
	main.title.play_opening()
	for t in [1.6, 4.2, 7.0, 10.0, 13.5, 17.0]:
		await get_tree().create_timer(t - metrics.get("tt", 0.0)).timeout
		metrics["tt"] = t
		await shot("ti_%02d" % int(t))
	get_tree().quit()


func credits_test():
	await get_tree().create_timer(0.5).timeout
	GS.stats.merge({"stolen": 11, "perfect": 4, "shot": 3, "slipped": 6, "walls": 2, "missed": 5, "swats": 4, "vision_s": 63.0}, true)
	GS.end_time = 754.0
	GS.tutorial_done = {"TUTORIAL_01": true, "TUTORIAL_02": true, "TUTORIAL_03": true}
	GS.set_level("red", 3)
	GS.worn = {"hat": true, "pipe": true, "shades": true}
	main.title.play_credits()
	for t in [3.0, 10.0, 18.0, 28.0, 40.0]:
		await get_tree().create_timer(t - metrics.get("tt", 0.0)).timeout
		metrics["tt"] = t
		await shot("cr_%02d" % int(t))
	get_tree().quit()

# one fry, verbose: `--one --id=SPECIAL_ROSE`

func key(code):
	var ev = InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 = InputEventKey.new()
	ev2.keycode = code
	ev2.physical_keycode = code
	ev2.pressed = false
	Input.parse_input_event(ev2)

# the real START path: the cover, then the comic-page opening (a key finishes a sentence, nothing is ever skipped), then HOLD E
func menu_test():
	await get_tree().create_timer(1.2).timeout
	await shot("mn_cover_a")
	await get_tree().create_timer(2.5).timeout
	await shot("mn_cover_b")
	var fast = "--fastkeys" in OS.get_cmdline_user_args()
	main.menus.cover._pick(0)
	var t0 = Time.get_ticks_msec()
	var n = 0
	var held = false
	while Time.get_ticks_msec() - t0 < 170000 and not main.player.active:
		await get_tree().create_timer(1.0).timeout
		n += 1
		if n % 2 == 0 or n < 4:
			await shot("mn_%03d" % n)
		var st = main.story
		if fast and not st.hold["on"]:
			key(KEY_SPACE)
		if st.hold["on"] and not held:
			held = true
			say("HOLD E hint is up at t=%.1fs (caption=%s)" % [(Time.get_ticks_msec() - t0) / 1000.0, str(st.cap != null)])
			await shot("mn_hold")
			Input.action_press("interact")
			await get_tree().create_timer(1.3).timeout
			Input.action_release("interact")
	say("opening over after %.1fs active=%s hud=%s" % [(Time.get_ticks_msec() - t0) / 1000.0, main.player.active, main.hud.visible])
	await get_tree().create_timer(2.5).timeout
	await shot("mn_game")
	get_tree().quit()

func vp_screen(name_):
	await get_tree().create_timer(0.35).timeout
	await shot(name_)

# the new places, the doorsteps with people on them, the two new fry owners

func world_test():
	await get_tree().create_timer(1.0).timeout
	main.player.input_locked = true
	GS.gull_sense_count = 3
	main._reveal_specials()
	var py = main.world["ordinary"].get_parent() if false else 0.0
	var pz = main.get_node_or_null("MapGeometry")
	var by = main.world["fries"]["SPECIAL_ORANGE"].global_position
	say("baker fry at %s ; keeper fry at %s" % [str(by), str(main.world["fries"]["SPECIAL_SILVER"].global_position)])
	var views = {
		"w01_summit": [Vector3(0, 33, -52), Vector3(0, 24, -80), 70.0],
		"w02_baker": [Vector3(8, 27, -68), Vector3(7, 25, -81), 55.0],
		"w03_plaza_side": [Vector3(-26, 30, -70), Vector3(0, 25, -80), 70.0],
		"w04_clock": [Vector3(-24, 30, -64), Vector3(-11, 30, -84), 60.0],
		"w05_farm": [Vector3(60, 45, -40), Vector3(86, 22, -78), 70.0],
		"w06_windmill": [Vector3(70, 30, -62), Vector3(86, 29, -78), 60.0],
		"w07_barn": [Vector3(86, 30, -50), Vector3(102, 24, -66), 60.0],
		"w08_hill_doors": [Vector3(0, 30, -20), Vector3(-10, 10, -45), 70.0],
		"w09_church": [Vector3(-26, 22, -26), Vector3(-26, 15, -41), 60.0],
		"w10_beach_huts": [Vector3(40, 9, 22), Vector3(40, 1.5, 8), 70.0],
		"w11_volley": [Vector3(40, 8, 30), Vector3(52, 1.5, 18), 65.0],
		"w12_harbor": [Vector3(60, 12, 16), Vector3(84, 2, -6), 70.0],
		"w13_keeper": [Vector3(-80, 30, 52), Vector3(-92, 25, 44), 60.0],
		"w14_marina": [Vector3(-26, 8, 40), Vector3(-30, 1, 26), 70.0],
		"w15_overview": [Vector3(30, 120, 80), Vector3(20, 10, -40), 75.0],
		"w16_pier_wheel": [Vector3(-4, 6, 40), Vector3(-4, 3, 51), 65.0],
	}
	for k in views:
		var v = views[k]
		view(v[0], v[1], v[2])
		await vp_screen(k)
	get_tree().quit()

# the top-left fry slots, rings of every tier (one green ring, one gold ring), the gauge's need line

func fish_test():
	await get_tree().create_timer(1.0).timeout
	main.showcase.fast = true
	var p = main.player
	GS.gull_sense_count = 3
	var spot = main.world["fish_spots"][3]
	say("fish spots: %d, first at %s" % [main.world["fish_spots"].size(), str(spot.global_position)])
	spot.wait = 0.2
	place(Vector3(spot.global_position.x + 20, 14, spot.global_position.z + 30), spot.global_position, 8.0)
	var t0 = Time.get_ticks_msec()
	var shot_b = false
	while spot.state != "leap" and Time.get_ticks_msec() - t0 < 20000:
		await get_tree().physics_frame
		if spot.state == "bubbles" and not shot_b and spot.st > 1.5:
			shot_b = true
			view(spot.global_position + Vector3(8, 6, 12), spot.global_position, 60.0)
			await shot("f1_bubbles")
			main.player.set_override(Transform3D.IDENTITY, 60.0, 0.0, 20.0)
	say("state=%s after %.1fs" % [spot.state, (Time.get_ticks_msec() - t0) / 1000.0])
	var fish = spot.fish
	if fish == null:
		say("no fish!")
		get_tree().quit()
		return
	var res = await attempt(fish, Vector3(0.6, 0.15, 1.0), 24.0, 0.0, -1.0)
	say("fish catch -> %s fish=%d commit=%s stamina=%.0f" % [res, GS.stats["fish"], str(p.snatch.last_commit), p.stamina])
	await get_tree().create_timer(1.5).timeout
	await shot("f3_after")
	get_tree().quit()


func rival_test():
	await get_tree().create_timer(1.0).timeout
	main.showcase.fast = true
	var p = main.player
	GS.gull_sense_count = 3
	main._reveal_specials()
	GS.stats["stolen"] = 5
	var f = main.world["fries"]["SPECIAL_BLUE"]
	place(f.aim_point() + Vector3(-12, 6, -12), f.aim_point(), 5.0)
	main.rivals.force_next = true
	main.rivals.cd = 0.0
	var t0 = Time.get_ticks_msec()
	var seen = false
	while Time.get_ticks_msec() - t0 < 15000:
		await get_tree().physics_frame
		if main.rivals.rival != null and not seen:
			seen = true
			say("rival spawned at %s targeting %s" % [str(main.rivals.rival.global_position), str(main.rivals.rival.target.id)])
			view(f.aim_point() + Vector3(8, 4, 10), f.aim_point() + Vector3(0, 3, 0), 60.0)
		if seen and is_instance_valid(main.rivals.rival) and Engine.get_physics_frames() % 20 == 0:
			var rv = main.rivals.rival
			say("   rival state=%s d=%.1f ok=%s sn=%s lock=%s" % [rv.state, rv.global_position.distance_to(f.aim_point()), rv._target_ok(), p.snatch.state, str(p.snatch.lock_fry)])
		if seen and f.vanished:
			say("the rival took the fry after %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
			await shot("r1_taken")
			break
	say("rival result: seen=%s vanished=%s" % [seen, f.vanished])
	main.player.set_override(Transform3D.IDENTITY, 60.0, 0.0, 20.0)
	# and the yell
	await get_tree().create_timer(18.0).timeout
	say("fry restocked: vanished=%s" % f.vanished)
	get_tree().quit()


func volley_test():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	var v = main.world["volley"]
	say("volley ball at %s idx=%d" % [str(v.ball.global_position), v.idx])
	view(Vector3(40, 7, 30), Vector3(52, 2.5, 18), 65.0)
	await get_tree().create_timer(1.2).timeout
	await shot("v1_match")
	main.player.set_override(Transform3D.IDENTITY, 60.0, 0.0, 20.0)
	# sit in the ball's path
	var hits0 = GS.stats["bops"]
	var t0 = Time.get_ticks_msec()
	p.mode = 0
	while Time.get_ticks_msec() - t0 < 14000 and GS.stats["bops"] == hits0:
		await get_tree().physics_frame
		p.global_position = v.ball.global_position + Vector3(0.2, 0.0, 0.0)
		p.velocity = Vector3.ZERO
		p.speed = 3.0
		p.invuln_t = 0.0
	say("bops %d -> %d mode=%d stamina=%.0f" % [hits0, GS.stats["bops"], p.mode, p.stamina])
	await get_tree().create_timer(0.5).timeout
	await shot("v2_bop")
	get_tree().quit()


func wear_test():
	await get_tree().create_timer(1.0).timeout
	main.showcase.fast = true
	GS.gull_sense_count = 3
	var want = ["pipe", "shades", "necklace", "bowtie", "scarf", "hat", "balloon"]
	var got = {}
	for k in want:
		for m in get_tree().get_nodes_in_group("mischief"):
			if is_instance_valid(m) and m.kind == k and not got.has(k):
				var r = await attempt(m, Vector3(0, 0.3, 1), 30.0, 0.0, 16.5)
				say("%s -> %s taken=%s worn=%s" % [k, r, m.taken if is_instance_valid(m) else "freed", str(GS.worn.keys())])
				got[k] = true
				await get_tree().create_timer(0.6).timeout
				break
		if not got.has(k):
			say("%s: no donor found" % k)
	# show the gull in all its glory
	var gp = main.player.global_position
	main.player.input_locked = true
	main.player.mode = 1
	var cam_pos = gp + Vector3(0.9, 0.35, -1.1)
	for kk in GS.worn:
		pass
	var xf = Transform3D(Basis.IDENTITY, gp + (-main.player.global_transform.basis.z) * 1.4 + Vector3(0.5, 0.5, 0)).looking_at(gp + Vector3(0, 0.15, 0), Vector3.UP)
	main.player.set_override(xf, 40.0, 1.0, 100.0)
	await get_tree().create_timer(0.6).timeout
	await shot("wear_gull")
	say("worn=%s achievements=%s" % [str(GS.worn.keys()), str(GS.achievements_done.keys())])
	get_tree().quit()


func save_test():
	var marker = "user://save_test_phase"
	if FileAccess.file_exists(marker):
		# phase B: a fresh scene, the saved run comes back
		DirAccess.remove_absolute(ProjectSettings.globalize_path(marker))
		await get_tree().create_timer(1.0).timeout
		say("phase B: save exists=%s" % GS.has_save())
		main._on_continue_pressed()
		await get_tree().create_timer(1.5).timeout
		var p = main.player
		say("restored: sense=%d lv=%s worn=%s stars=%s phase=%d pos=%s active=%s" % [GS.gull_sense_count, str(GS.lv), str(GS.worn.keys()), str(GS.star_got.keys()), GS.phase, str(p.global_position), p.active])
		var f1 = main.world["fries"]["TUTORIAL_01"]
		var fr = main.world["fries"]["SPECIAL_RED"]
		var fg = main.world["fries"]["SPECIAL_GREEN"]
		say("tutorial fry gone=%s red owner fry gone=%s green fry visible=%s revealed=%s" % [(not is_instance_valid(f1)) or f1.consumed, (not is_instance_valid(fr)) or fr.consumed, fg.visible, fg.revealed])
		await shot("sv_restored")
		GS.delete_save()
		get_tree().quit()
		return
	# phase A: build a run, save it, reload the scene
	await get_tree().create_timer(1.0).timeout
	GS.gull_sense_count = 3
	GS.tutorial_done = {"TUTORIAL_01": true, "TUTORIAL_02": true, "TUTORIAL_03": true}
	GS.set_level("red", 2)
	GS.set_level("pink", 1)
	GS.set_level("cyan", 1)
	GS.star_got = {"red_2": true}
	GS.worn = {"pipe": true, "hat": true}
	GS.phase = GS.Phase.SPECIAL_HUNT
	GS.hunger_t = 0.0
	main.player.global_position = Vector3(10.0, 12.0, 20.0)
	var ok = main.save_now()
	say("phase A: saved=%s file=%s" % [ok, GS.has_save()])
	var f = FileAccess.open(marker, FileAccess.WRITE)
	f.store_string("b")
	f.close()
	GS.skip_menu = true
	get_tree().reload_current_scene()


func hunger_test():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	main._reveal_specials()
	for k in GS.FRY_TYPES:
		GS.set_level(k, 1)
	GS.phase = GS.Phase.STILL_HUNGRY
	main._begin_star_phase()
	view(Vector3(-4.0, 3.0, 12.0), Vector3(-8.65, 1.0, 3.6), 55.0)
	for stage in [0, 4, 8, 13]:
		GS.star_got = {}
		for i in stage:
			GS.star_got["x_%d" % i] = true
		GS.hunger_t = stage * 25.0
		main.ordinary.set_steam(clamp(GS.longing() / 14.0, 0.0, 1.0))
		say("stage %d: longing %.1f steam %.2f" % [stage, GS.longing(), clamp(GS.longing() / 14.0, 0.0, 1.0)])
		await get_tree().create_timer(2.5).timeout
		await shot("hg_%02d" % stage)
	# the whispers
	main.hunger_cstep = 0
	GS.star_got = {}
	for i in 14:
		GS.star_got["y_%d" % i] = true
	main._hunger_tick(0.1)
	say("count whispers shown up to step %d of %d" % [main.hunger_cstep, main.HUNGER_COUNT_STEPS.size()])
	get_tree().quit()


func ending_test():
	await get_tree().create_timer(1.0).timeout
	main.autotest = false
	main.showcase.fast = true
	GS.gull_sense_count = 3
	for k in ["hawaii", "sailor", "glasses", "necklace", "pipe", "topper"]:
		main.player.gull.wear(k)
	GS.stats.merge({"stolen": 12, "perfect": 4, "shot": 3, "slipped": 6, "walls": 2, "missed": 5, "swats": 4, "vision_s": 63.0, "fish": 1, "rivals": 2, "bops": 1, "scares": 2}, true)
	var o = main.ordinary
	o.visible = true
	main.player.mode = 0
	main.player.global_position = o.global_position + Vector3(0, 0.6, 1.4)
	main.player.speed = 3.0
	await get_tree().physics_frame
	await get_tree().physics_frame
	await press("interact")
	var t0 = Time.get_ticks_msec()
	var n = 0
	while Time.get_ticks_msec() - t0 < 150000 and not (main.title.mode == "credits" and main.title.can_input):
		await get_tree().create_timer(1.0).timeout
		n += 1
		if n % 2 == 0:
			await shot("en_%03d" % n)
	say("ending over after %.1fs; title mode=%s" % [(Time.get_ticks_msec() - t0) / 1000.0, main.title.mode])
	await shot("en_credits_end")
	get_tree().quit()


func hazards_test():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	# 1) a grumpy vendor swings at a gull that hangs in front of the stall
	var vendor = null
	for a in get_tree().get_nodes_in_group("ambient"):
		if a.grumpy and a.global_position.distance_to(Vector3(-40, 0, 19.1)) < 2.0:
			vendor = a
	say("grumpy vendor found=%s" % (vendor != null))
	if vendor != null:
		p.mode = 0
		var swats0 = GS.stats["swats"]
		var t0 = Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 6000 and GS.stats["swats"] == swats0:
			await get_tree().physics_frame
			if p.mode != 2:
				p.global_position = vendor.global_position + Vector3(0, 1.4, -1.6)
				p.velocity = Vector3.ZERO
				p.speed = 2.0
		say("grumpy swing: swats %d -> %d state=%s" % [swats0, GS.stats["swats"], vendor.swing_state])
		await get_tree().create_timer(2.0).timeout
	# 2) a kid chases a gull that has landed
	var kid = null
	for a2 in get_tree().get_nodes_in_group("ambient"):
		if a2.chaser and a2.global_position.distance_to(Vector3(25, 0, 30)) < 4.0:
			kid = a2
	say("chaser kid found=%s" % (kid != null))
	if kid != null:
		p.mode = 1
		p.global_position = kid.global_position + Vector3(8, 0.2, 0)
		p.velocity = Vector3.ZERO
		var sc0 = GS.stats["scares"]
		var t1 = Time.get_ticks_msec()
		while Time.get_ticks_msec() - t1 < 12000 and GS.stats["scares"] == sc0:
			await get_tree().physics_frame
			if p.mode == 0:
				p.mode = 1
			p.velocity = Vector3(0, -1, 0)
		say("kid chase: scares %d -> %d kid state=%s" % [sc0, GS.stats["scares"], kid.chase_state])
		await shot("hz_boo")
	# 3) a dog goes for a landed gull
	var dg = get_tree().get_nodes_in_group("dogs")
	say("dogs: %d" % dg.size())
	get_tree().quit()


# ================================================================== round 5 bot + tests

# an instant key tap (no waiting): the note timing of the rhythm needs finer steps than a physics frame at bullet time
func tap(action):
	var ev = InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 = InputEventAction.new()
	ev2.action = action
	ev2.pressed = false
	Input.parse_input_event(ev2)

# opts: gold (aim at the gold band on every grab note), gold_flee, fail_grab (press far too early on the grab), fail_flee, skip (note indexes the bot
# does not press on the grab), skip_flee, shot (screenshot name taken mid-rhythm), debug
func attempt(f, from_dir, dist = 24.0, offset = 0.0, spd = 11.0, opts = {}):
	if not is_instance_valid(f) or f.consumed:
		return "ok"
	if spd < 0.0:
		spd = GS.need_speed(f) + 1.3
	var p = main.player
	if f.ftype == "star" or (f.ftype in GS.FRY_TYPES):
		from_dir = pick_dir(f, from_dir)         # trees are solid now: come in along a free line
	var s = p.snatch
	var tgt = f.aim_point()
	var start = tgt + from_dir.normalized() * dist + Vector3(0, 2.0, 0)
	if f.id == "TUTORIAL_01":
		start = Vector3(-8.0, 3.2, 17.0)  # the caf茅 awning blocks every dive from the roof: come in from the south
	place(start, tgt, spd)
	p.stamina = GS.stamina_max()
	Input.action_press("move_forward")
	if spd > 11.5:
		Input.action_press("dash")
	var pressed_key = {}
	var any_press = false
	var locked_seen = false
	var flee_seen = false
	var result = "timeout"
	var shot_done = false
	var notes_seen = 0
	for i in 3600:
		await get_tree().process_frame
		if opts.get("debug", false) and i % 20 == 0 and i < 400:
			say("   i=%d state=%s hud=%s lock=%s spd=%.1f d=%.1f ts=%.2f stam=%.0f cine_t=%.2f pf=%d paused=%s" % [i, s.state, s.hud_state, str(s.lock_fry != null), p.speed, p.global_position.distance_to(f.aim_point()) if is_instance_valid(f) else -1.0, Engine.time_scale, p.stamina, s.cine.get("t", -1.0), Engine.get_physics_frames(), str(get_tree().paused)])
		if not is_instance_valid(f) or f.consumed:
			result = "ok"
			break
		if p.stamina < 30.0:
			p.stamina = 60.0
		if s.state == "idle" and s.lock_fry == null:
			var tg = f.aim_point()
			if (tg - p.global_position).length() > 1.0:
				aim_at(p, tg)
		var sq = s.seq
		if sq != null:
			var kind = sq["kind"]
			if kind == "grab":
				locked_seen = true
			else:
				flee_seen = true
			var now = s.seq_now()
			notes_seen = max(notes_seen, sq["n"])
			if opts.has("shot") and not shot_done and kind == "grab" and now > sq["appr"] * 0.55 and sq["n"] >= 1:
				shot_done = true
				await shot(opts["shot"])
			var fail_it = (kind == "grab" and opts.get("fail_grab", false)) or (kind == "flee" and opts.get("fail_flee", false))
			if fail_it:
				if not pressed_key.has(kind) and now > 0.3:
					pressed_key[kind] = true
					tap("interact")
					any_press = true
			else:
				var idx = s._first_pending(sq)
				if idx >= 0:
					var key = "%s:%d" % [kind, idx]
					if not pressed_key.has(key):
						var nt = sq["notes"][idx]
						var gold = opts.get("gold", false) if kind == "grab" else opts.get("gold_flee", false)
						var aim_t = nt["t"] - sq["gw"] * 0.45 if gold else nt["t"] - sq["gw"] - sq["gg"] * 0.5
						aim_t += offset
						var skips = opts.get("skip", []) if kind == "grab" else opts.get("skip_flee", [])
						if now >= aim_t:
							pressed_key[key] = true
							if not skips.has(idx):
								tap("interact")
								any_press = true
		if s.state == "cine" and not metrics.has("cine_shot") and s.cine.get("t", 0.0) > 0.3:
			metrics["cine_shot"] = true
			await shot("a_cine")
		if s.state == "flee" or s.state == "carry":
			var away = (p.global_position - f.npc.global_position) if (is_instance_valid(f) and f.npc != null) else Vector3(0, 0, 1)
			away.y = 0.0
			if away.length() < 0.1:
				away = Vector3(0, 0, 1)
			aim_at(p, p.global_position + away.normalized() * 12.0 + Vector3(0, 12.0, 0))
		if p.mode == 2 and any_press:
			result = "hit"
			break
		if s.state == "idle" and s.lock_fry == null and any_press and s.snatch_cd > 0.4 and not f.consumed:
			result = "missed"
			break
	Input.action_release("move_forward")
	Input.action_release("dash")
	metrics["last"] = {"locked": locked_seen, "flee": flee_seen, "commit": s.last_commit, "notes": notes_seen}
	say("   commit=%s locked_seen=%s flee_seen=%s notes=%d" % [str(s.last_commit), locked_seen, flee_seen, notes_seen])
	return result

func say(msg):
	print("[AUTOTEST] ", msg)

# a floating star fry of the given type / tier hung in the air at a world position
func make_star(type, tier, pos, name_ = "STAR_T"):
	var f = Node3D.new()
	f.set_script(preload("res://scripts/fries/fry.gd"))
	f.position = pos
	main.add_child(f)
	f.setup(name_, "star", "none", GS.FRY_TYPES.find(type), tier)
	f.home_parent = main
	f.home_pos = pos
	return f

func run():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	await shot("a00_start")
	var fr = main.world["fries"]
	# --- flight sanity: speeds, stamina and the new acceleration
	p.mode = 0
	p.speed = 5.0
	p.global_position = Vector3(0, 40, 90)
	aim_at(p, Vector3(0, 40, 0))
	Input.action_press("move_forward")
	var t_start = Time.get_ticks_msec()
	var t11 = -1.0
	while Time.get_ticks_msec() - t_start < 4000:
		await get_tree().physics_frame
		if t11 < 0.0 and p.speed >= 10.9:
			t11 = (Time.get_ticks_msec() - t_start) / 1000.0
	say("throttle speed=%.1f (want ~11) stamina=%.1f/%.0f; reached 11 m/s after %.2f s" % [p.speed, p.stamina, GS.stamina_max(), t11])
	Input.action_press("dash")
	await get_tree().create_timer(2.2).timeout
	say("boost speed=%.1f (want ~19 = gauge %d) stamina=%.1f fov=%.1f" % [p.speed, int(p.speed * 6), p.stamina, p.cam.fov])
	await shot("a01_boost")
	Input.action_release("dash")
	Input.action_release("move_forward")
	await get_tree().create_timer(2.0).timeout
	say("coast speed=%.1f (want ~5)" % p.speed)
	# --- tutorial fries
	for id in ["TUTORIAL_01", "TUTORIAL_02", "TUTORIAL_03"]:
		var f = fr[id]
		var d = Vector3(1, 0.2, 0)
		if id == "TUTORIAL_03":
			d = Vector3(0, 0.2, 1)
		var r = "?"
		for tries in 4:
			r = await attempt(f, d)
			say("%s try %d -> %s  (sense=%d, heat=%.1f, watch=%.1f)" % [id, tries + 1, r, GS.gull_sense_count, GS.heat, GS.watch])
			if r == "ok":
				break
			await get_tree().create_timer(2.0).timeout
		await get_tree().create_timer(1.0).timeout
	await shot("a02_gullsense")
	await get_tree().create_timer(4.0).timeout
	await shot("a03_revealed")
	var dirs = {"SPECIAL_RED": Vector3(0, 0, 1), "SPECIAL_BLUE": Vector3(-0.6, 0, -0.8), "SPECIAL_YELLOW": Vector3(0, 0, 1), "SPECIAL_GREEN": Vector3(1, 0, 0), "SPECIAL_ROSE": Vector3(0, 0.2, 1),
		"SPECIAL_ORANGE": Vector3(0, 0.3, 1), "SPECIAL_SILVER": Vector3(1, 0.3, 0)}
	for id in dirs:
		var f2 = fr[id]
		var res = "?"
		for tries in 4:
			res = await attempt(f2, dirs[id], 24.0, 0.0, -1.0)
			say("%s try %d -> %s (wary=%.1f)" % [id, tries + 1, res, f2.npc.wary if is_instance_valid(f2) else -1])
			if res == "ok":
				break
			await get_tree().create_timer(2.5).timeout
		if id == "SPECIAL_RED":
			await shot("a04_got")
		await get_tree().create_timer(1.5).timeout
	say("silvers=%d lv=%s total=%d" % [GS.special_count(), str(GS.lv), GS.fry_total()])
	await get_tree().create_timer(5.0).timeout
	await shot("a05_still_hungry")
	say("phase=%d star_queue=%d star_active=%d" % [GS.phase, main.star_queue.size(), main.star_active.size()])
	GS.test_boost_bonus = 8.0
	var guard = 0
	while not main.star_queue.is_empty() and guard < 90:
		guard += 1
		await get_tree().create_timer(2.5).timeout
		if main.star_active.size() > 0:
			var pf = main.star_active[0]
			var before = GS.star_count()
			var rr = await attempt(pf, Vector3(0, 0.3, 1), 24.0, 0.0, -1.0)
			say("star %s tier %d need %d -> %s stars=%d (was %d) lv=%s" % [pf.id, pf.tier, int(GS.need_speed(pf) * 6), rr, GS.star_count(), before, str(GS.lv)])
	GS.test_boost_bonus = 0.0
	say("all stars: queue=%d lv=%s total=%d/24 mission=%d" % [main.star_queue.size(), str(GS.lv), GS.fry_total(), GS.mission_target()])
	await shot("a06_all24")
	# --- rainbow fries: passers-by far from the start hold one of every finished colour
	for i in 5:
		main.rb_t = 0.0
		main.rb_wait = 0.0
		main._rainbow_tick(3.0)
	say("rainbow holders: %d" % main.rb_holders.size())
	if not main.rb_holders.is_empty():
		var rf = main.rb_holders[0]["fry"]
		p.global_position = rf.global_position + Vector3(0, 8, 20)
		var rr2 = await attempt(rf, Vector3(0, 0.3, 1), 24.0, 0.0, -1.0)
		say("rainbow grab -> %s rainbow=%s stamina_max=%.0f" % [rr2, str(GS.rainbow), GS.stamina_max()])
	GS.hunger_t = 400.0
	await get_tree().create_timer(1.5).timeout
	await shot("a07_halo")
	var o = main.ordinary
	p.mode = 0
	p.global_position = o.global_position + Vector3(0, 0.6, 1.4)
	p.speed = 3.0
	await get_tree().physics_frame
	await get_tree().physics_frame
	say("hud_state before eat=%s" % p.snatch.hud_state)
	await press("interact")
	await get_tree().create_timer(5.0).timeout
	await shot("a08_ending")
	say("ended=%s phase=%d stats=%s" % [GS.ordinary_eaten, GS.phase, str(GS.stats)])
	get_tree().quit()

# every spot where a star fry can hang: is it reachable and is the rhythm doable? gold ones at the gold spots, diamond ones at the diamond spots
func star_test():
	await get_tree().create_timer(1.0).timeout
	GS.phase = GS.Phase.STILL_HUNGRY
	GS.gull_sense_count = 3
	GS.test_boost_bonus = 8.0
	var idx = 0
	var only = []
	for a2 in OS.get_cmdline_user_args():
		if a2.begins_with("--only="):
			only = a2.substr(7).split(",")
	for sp in main.world["prism_spots"]:
		if not only.is_empty() and not only.has(sp["name"]):
			continue
		var tier = 2 if main.GOLD_SPOTS.has(sp["name"]) else 3
		var f = make_star(GS.FRY_TYPES[idx % 7], tier, sp["pos"])
		f.set_meta("spot", sp["name"])
		idx += 1
		var r = await attempt(f, Vector3(0, 0.3, 1), 26.0, 0.0, -1.0)
		var space = main.get_world_3d().direct_space_state
		var q = PhysicsShapeQueryParameters3D.new()
		var sh = SphereShape3D.new()
		sh.radius = 0.5
		q.shape = sh
		q.transform = Transform3D(Basis.IDENTITY, sp["pos"])
		q.collision_mask = 1
		var inside = not space.intersect_shape(q, 1).is_empty()
		say("%-14s tier %d need %3d -> %-8s embedded=%s pos=%s" % [sp["name"], tier, int(GS.need_speed(f) * 6), r, inside, str(sp["pos"])])
		var sn = main.player.snatch
		if sn.state != "idle" or Engine.time_scale < 0.99:
			say("   after: state=%s ts=%.2f locked=%s mode=%d" % [sn.state, Engine.time_scale, main.player.input_locked, main.player.mode])
		if is_instance_valid(f):
			f.queue_free()
		await get_tree().create_timer(0.5).timeout
	GS.test_boost_bonus = 0.0
	get_tree().quit()

# the judgement: silver / gold / diamond rhythms, misses, early presses, the escape check
func rhythm_test():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	GS.tutorial_done = {"TUTORIAL_01": true, "TUTORIAL_02": true, "TUTORIAL_03": true}
	main._reveal_specials()
	GS.test_boost_bonus = 8.0
	var fr = main.world["fries"]
	var s = p.snatch
	# 1: silver (2 circles, 4 waves): all in the green -> 4 points -> ok
	var r = await attempt(fr["SPECIAL_BLUE"], Vector3(-0.6, 0, -0.8), 24.0, 0.0, -1.0, {"shot": "r1_silver"})
	say("1 silver green -> %s commit=%s" % [r, str(s.last_commit)])
	await get_tree().create_timer(3.0).timeout
	# 2: silver, press far too early -> missed
	var f2 = fr["SPECIAL_GREEN"]
	r = await attempt(f2, Vector3(1, 0, 0), 24.0, 0.0, -1.0, {"fail_grab": true})
	say("2 silver early press -> %s commit=%s" % [r, str(s.last_commit)])
	await get_tree().create_timer(3.0).timeout
	# 3: the points: a gold press pays for two. Gold fry = 3 circles, 6 waves
	var spots = main.world["prism_spots"]
	var gp = null
	for sp in spots:
		if sp["name"] == "lifeguard":
			gp = sp["pos"]
	for case in [["all green", {"shot": "r2_gold"}], ["skip one", {"skip": [1]}], ["all gold", {"gold": true}]]:
		var g = make_star("blue", 2, gp, "STAR_T_" + case[0])
		GS.lv["blue"] = 1
		var rr = await attempt(g, Vector3(0, 0.3, 1), 24.0, 0.0, -1.0, case[1])
		say("3 gold fry %s -> %s commit=%s" % [case[0], rr, str(s.last_commit)])
		if is_instance_valid(g):
			g.queue_free()
		await get_tree().create_timer(2.5).timeout
	# 4: diamond fry = 5 circles (the olympic rings), 10 waves
	var dp = null
	for sp in spots:
		if sp["name"] == "ferris":
			dp = sp["pos"]
	for case in [["all green", {"shot": "r3_diamond"}], ["skip one", {"skip": [2]}], ["all gold", {"gold": true}]]:
		var g2 = make_star("red", 3, dp, "STAR_D_" + case[0])
		GS.lv["red"] = 2
		var rr2 = await attempt(g2, Vector3(0, 0.3, 1), 24.0, 0.0, -1.0, case[1])
		say("4 diamond fry %s -> %s commit=%s" % [case[0], rr2, str(s.last_commit)])
		if is_instance_valid(g2):
			g2.queue_free()
		await get_tree().create_timer(2.5).timeout
	GS.test_boost_bonus = 0.0
	get_tree().quit()

func flee_test():
	# round 6: there is no escape check any more; this just grabs the three tutorial fries with the new two-wave rhythm
	await get_tree().create_timer(1.0).timeout
	var fr = main.world["fries"]
	for id in ["TUTORIAL_01", "TUTORIAL_02", "TUTORIAL_03"]:
		var d = Vector3(1, 0.2, 0) if id != "TUTORIAL_03" else Vector3(0, 0.2, 1)
		var r = await attempt(fr[id], d, 24.0, 0.0, 11.0, {"gold": id == "TUTORIAL_03"})
		say("%s -> %s commit=%s" % [id, r, str(main.player.snatch.last_commit)])
		await get_tree().create_timer(2.0).timeout
	say("done: tutorial_done=%s stats=%s" % [str(GS.tutorial_done.keys()), str(GS.stats)])
	get_tree().quit()

func tiers_test():
	await get_tree().create_timer(1.0).timeout
	var s = main.player.snatch
	GS.gull_sense_count = 3
	for lvl in [0, 3]:
		GS.set_level("green", lvl)
		say("--- green lv%d (bands x%.2f, rings x%.2f slower)" % [lvl, GS.timing_mult(), GS.ring_speed_mult()])
		for id in ["TUTORIAL_01", "TUTORIAL_02", "TUTORIAL_03", "SPECIAL_RED", "SPECIAL_BLUE", "SPECIAL_GREEN"]:
			var f = main.world["fries"][id]
			var q = s._seq_params(f)
			say("  %-12s need %3d  %d circles x %d waves lead=%.2f gap=%.2f gold=%3dms green=%3dms (hit window %3dms)" % [id, int(GS.need_speed(f) * 6), q["c"], q["w"], q["lead"], q["gap"], int(q["gw"] * 1000), int(q["gg"] * 1000), int((q["gw"] + q["gg"]) * 1000)])
	GS.set_level("green", 0)
	for t in GS.FRY_TYPES:
		var line = "%-7s need:" % t
		for tier in [1, 2, 3]:
			line += " %3d" % int(GS.NEED_GAUGE[t][tier - 1])
		var f2 = make_star(t, 2, Vector3(0, 100, 0))
		var q2 = s._seq_params(f2)
		line += "   gold: %dx%d gold=%dms green=%dms" % [q2["c"], q2["w"], int(q2["gw"] * 1000), int(q2["gg"] * 1000)]
		var f3 = make_star(t, 3, Vector3(0, 100, 0))
		var q3 = s._seq_params(f3)
		line += "   diamond: %dx%d gold=%dms green=%dms" % [q3["c"], q3["w"], int(q3["gw"] * 1000), int(q3["gg"] * 1000)]
		say(line)
		f2.queue_free()
		f3.queue_free()
	say("boost speed by SONIC level: %s" % str([GS.BOOST_TAB[0] * 6, GS.BOOST_TAB[1] * 6, GS.BOOST_TAB[2] * 6, GS.BOOST_TAB[3] * 6]))
	get_tree().quit()

# Ctrl landing + Gull Sight on the ground (free) and in the air (costs unless diamond FARSIGHT)
func land_test():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	place(Vector3(0, 30, 90), Vector3(0, 30, 0), 11.0)
	Input.action_press("move_forward")
	Input.action_press("dash")
	await get_tree().create_timer(1.5).timeout
	say("before land: speed=%.1f y=%.1f mode=%d locked=%s active=%s" % [p.speed, p.global_position.y, p.mode, p.input_locked, p.active])
	Input.action_release("dash")
	Input.action_release("move_forward")
	Input.action_press("land")
	var t0 = Time.get_ticks_msec()
	while p.mode == 0 and Time.get_ticks_msec() - t0 < 12000:
		await get_tree().physics_frame
	Input.action_release("land")
	say("Ctrl landing: mode=%d after %.2f s, speed=%.1f y=%.1f" % [p.mode, (Time.get_ticks_msec() - t0) / 1000.0, p.speed, p.global_position.y])
	# TAB on the ground: free
	GS.gull_sense_count = 3
	main._reveal_specials()
	p.stamina = 40.0
	Input.action_press("gull_sense")
	main._open_sense()
	await get_tree().create_timer(1.2).timeout
	say("TAB on the ground: stamina 40 -> %.1f (should stay 40+)  radius=%.0f" % [p.stamina, GS.sight_radius()])
	await shot("tab_ground")
	Input.action_release("gull_sense")
	main._close_sense()
	# in the air
	place(Vector3(-9, 30, 20), Vector3(-9, 28, 0), 5.0)
	p.stamina = 40.0
	Input.action_press("gull_sense")
	main._open_sense()
	await get_tree().create_timer(1.2).timeout
	say("TAB in the air: stamina 40 -> %.1f (cost %.1f/s real)" % [p.stamina, GS.vision_cost()])
	await shot("tab_air")
	Input.action_release("gull_sense")
	main._close_sense()
	for lvl in [1, 2, 3]:
		GS.set_level("cyan", lvl)
		say("cyan lv%d: radius %d m, cost %.1f /s" % [lvl, int(GS.sight_radius()), GS.vision_cost()])
	get_tree().quit()

# HUD screenshots: the rainbow arc at several stages, the tach, the mission board, the rhythm of every tier
func hud_test():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 1
	GS.tutorial_done = {"TUTORIAL_01": true}
	place(Vector3(-8.0, 4.0, 14.0), Vector3(-8.0, 1.0, 3.0), 5.0)
	await vp_screen("h01_start")
	GS.gull_sense_count = 3
	main._reveal_specials()
	main.hud.slots_visible = true
	GS.set_level("red", 1)
	GS.set_level("blue", 2)
	GS.set_level("cyan", 3)
	GS.set_level("orange", 1)
	GS.rainbow["red"] = 2
	main.hud._on_fry_got("blue", 2)
	await get_tree().create_timer(0.45).timeout
	await shot("h02_get_rise")
	await get_tree().create_timer(1.2).timeout
	await shot("h03_get_hold")
	await get_tree().create_timer(1.55).timeout
	await shot("h03b_get_fly")
	await get_tree().create_timer(1.2).timeout
	GS.rainbow["red"] = 3
	main.hud._on_fry_got("red", 4)
	GS.quests["fish"] = "done"
	GS.quests["cloud"] = "active"
	await get_tree().create_timer(0.7).timeout
	await shot("h03c_rainbow_get")
	await get_tree().create_timer(2.0).timeout
	for t in GS.FRY_TYPES:
		GS.set_level(t, 3)
	GS.rainbow["blue"] = 3
	place(Vector3(0, 40, 100), Vector3(0, 40, 0), 5.0)
	Input.action_press("move_forward")
	Input.action_press("dash")
	await get_tree().create_timer(0.7).timeout
	await shot("h04_tach_low")
	await get_tree().create_timer(2.0).timeout
	await shot("h05_tach_boost")
	Input.action_release("dash")
	Input.action_release("move_forward")
	# a finished quest: the UI melts away and the gull thinks out loud
	GS.quest_finish("sun")
	await get_tree().create_timer(2.6).timeout
	await shot("h06_quiet_1")
	await get_tree().create_timer(3.0).timeout
	await shot("h07_quiet_2")
	get_tree().quit()

# the gull standing on the ground / a roof, from the side: the feet must touch it
func stand_test():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	main.player.input_locked = false
	var spots = {"ground": Vector3(-30.0, 0.5, 8.0), "roof": Vector3(-13.5, 0.0, -43.0)}
	for k in spots:
		var pos = spots[k]
		if k == "roof":
			# land on a flat roof of the first shelf
			pos.y = Terrain_top(pos)
		place(pos + Vector3(0, 1.5, 0), pos + Vector3(0, 1.0, 1.0), 4.0)
		p.mode = 0
		Input.action_press("land")
		var t0 = Time.get_ticks_msec()
		while p.mode == 0 and Time.get_ticks_msec() - t0 < 8000:
			await get_tree().physics_frame
		Input.action_release("land")
		await get_tree().create_timer(0.8).timeout
		var gp = p.global_position
		var right = p.global_transform.basis.x
		var xf = Transform3D(Basis.IDENTITY, gp + right * 1.6 + Vector3(0, 0.25, 0.3)).looking_at(gp + Vector3(0, -0.35, 0), Vector3.UP)
		p.set_override(xf, 40.0, 1.0, 200.0)
		await get_tree().create_timer(0.5).timeout
		await shot("st_" + k)
		p.set_override(Transform3D.IDENTITY, 60.0, 0.0, 200.0)
		say("%s: mode=%d y=%.2f" % [k, p.mode, gp.y])
	get_tree().quit()

func Terrain_top(pos):
	var space = main.get_world_3d().direct_space_state
	var q = PhysicsRayQueryParameters3D.create(Vector3(pos.x, 60.0, pos.z), Vector3(pos.x, -5.0, pos.z), 1)
	var hit = space.intersect_ray(q)
	return hit["position"].y if not hit.is_empty() else pos.y

func rainbow_test():
	await get_tree().create_timer(1.0).timeout
	GS.gull_sense_count = 3
	main._reveal_specials()
	for t in GS.FRY_TYPES:
		GS.set_level(t, 3)
	GS.phase = GS.Phase.STILL_HUNGRY
	for t in ["red", "blue"]:
		for k in 8:
			GS.add_rainbow(t)
		say("%s: rainbow %d  boost=%.2f stamina=%.0f accel=%.2f" % [t, GS.rainbow[t], GS.boost_speed(), GS.stamina_max(), GS.accel_mult()])
	say("fry_total=%d mission=%d (rainbow never counts)" % [GS.fry_total(), GS.mission_target()])
	get_tree().quit()

# one fry, verbose: `--one --id=SPECIAL_BLUE`
func one_test():
	await get_tree().create_timer(1.0).timeout
	var id = "SPECIAL_BLUE"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--id="):
			id = a.substr(5)
	GS.gull_sense_count = 3
	main._reveal_specials()
	var f = main.world["fries"][id]
	for k in 3:
		var dirs = {"SPECIAL_RED": Vector3(0, 0, 1), "SPECIAL_BLUE": Vector3(-0.6, 0, -0.8), "SPECIAL_YELLOW": Vector3(0, 0, 1), "SPECIAL_GREEN": Vector3(1, 0, 0), "SPECIAL_ROSE": Vector3(0, 0.2, 1),
			"SPECIAL_ORANGE": Vector3(0, 0.3, 1), "SPECIAL_SILVER": Vector3(1, 0.3, 0)}
		var r = await attempt(f, dirs.get(id, Vector3(0, 0.2, 1)), 24.0, 0.0, -1.0, {"debug": true})
		say("%s try %d -> %s" % [id, k + 1, r])
		if r == "ok":
			break
		await get_tree().create_timer(2.0).timeout
	get_tree().quit()


# top-down tiles of the whole town, to find free lots for new places
func topdown():
	await get_tree().create_timer(1.0).timeout
	main.player.input_locked = true
	var tiles = {"td_a": [-70, 55], "td_b": [10, 55], "td_c": [80, 25], "td_d": [-70, -30], "td_e": [10, -30], "td_f": [80, -50], "td_g": [-10, 105]}
	for k in tiles:
		var c = tiles[k]
		var xf = Transform3D(Basis.IDENTITY, Vector3(c[0], 170.0, c[1])).looking_at(Vector3(c[0], 0, c[1] - 0.01), Vector3.UP)
		main.player.set_override(xf, 50.0, 1.0, 200.0)
		await get_tree().create_timer(0.6).timeout
		await shot(k)
	get_tree().quit()



# the new open-air places and the laundry roofs
func places_test():
	await get_tree().create_timer(1.0).timeout
	main.player.input_locked = true
	GS.gull_sense_count = 3
	var views = {
		"np1_market": [Vector3(28, 7, 1.5), Vector3(28, 1.8, -14), 65.0],
		"np2_market_side": [Vector3(44, 5, -2), Vector3(28, 1.5, -10), 60.0],
		"np3_espresso": [Vector3(14, 5.5, -11), Vector3(14, 1.2, 1), 62.0],
		"np4_tiki": [Vector3(66, 7, 40), Vector3(66, 1.8, 28), 62.0],
		"np5_boat": [Vector3(90, 8, 33), Vector3(101, 1.0, 19.5), 62.0],
		"np6_beach": [Vector3(50, 6, 42), Vector3(56, 0.8, 32), 65.0],
		"np8_icecream": [Vector3(-24, 6, 2), Vector3(-24, 1.8, -14), 62.0],
		"np9_fry": [Vector3(3, 6, -4), Vector3(3, 2, -17), 62.0],
		"np10_bbq": [Vector3(37, 13, -22), Vector3(36, 6.5, -36), 62.0],
		"np11_pool": [Vector3(-38, 13, -22), Vector3(-38, 6.5, -35), 62.0],
		"np12_sea_boat": [Vector3(56, 9, 72), Vector3(56, 0.5, 90), 62.0],
		"np13_loungers": [Vector3(48, 4, 40), Vector3(48, 0.6, 31.5), 62.0],
		"np14_marina": [Vector3(-16, 7, 50), Vector3(-16, 0.5, 40), 62.0],
	}
	var roofs = main.world.get("laundry_list", [])
	say("laundry roofs: %d" % roofs.size())
	var i = 0
	for r in roofs:
		views["np7_roof_%d" % i] = [Vector3(r.x, r.y + 6.0, r.z + 13.0), Vector3(r.x, r.y + 1.0, r.z + 1.0), 60.0]
		i += 1
		if i >= 3:
			break
	for k in views:
		var v = views[k]
		view(v[0], v[1], v[2])
		await get_tree().create_timer(0.5).timeout
		await shot(k)
	get_tree().quit()


# the three rest events, forced one after the other
func rest_test():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	GS.tutorial_done = {"TUTORIAL_01": true, "TUTORIAL_02": true, "TUTORIAL_03": true}
	GS.set_level("red", 1)
	GS.set_level("orange", 1)
	GS.set_level("green", 1)
	GS.set_level("cyan", 1)
	var r = main.rest
	for kind in ["buddy", "kid", "dog"]:
		r.force_kind = kind
		r.cd = 0.0
		p.mode = 1
		p.global_position = Vector3(-30.0, 0.4, 8.0)
		p.velocity = Vector3.ZERO
		p.still_t = 3.0
		p.stamina = 20.0
		var st0 = p.stamina
		var rb0 = GS.stats["rainbow"]
		var shots_done = 0
		var t0 = Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 16000:
			await get_tree().physics_frame
			if p.mode == 1:
				p.still_t = max(p.still_t, 2.0)
			if r.ev != null and shots_done == 0 and r.ev.get("t", 0.0) > 1.6:
				shots_done = 1
				view(p.global_position + Vector3(-2.2, 1.6, 3.4), p.global_position + Vector3(0.5, 0.5, 0), 55.0)
				await get_tree().create_timer(0.3).timeout
				await shot("rest_%s_1" % kind)
			if r.ev != null and shots_done == 1 and r.ev.get("t", 0.0) > 3.2:
				shots_done = 2
				await shot("rest_%s_2" % kind)
				p.set_override(Transform3D.IDENTITY, 60.0, 0.0, 20.0)
			if r.ev == null and shots_done >= 1:
				break
		p.set_override(Transform3D.IDENTITY, 60.0, 0.0, 20.0)
		say("rest %s: done shots=%d stamina %.1f -> %.1f rainbow %d -> %d friends=%d fed=%d mode=%d" % [kind, shots_done, st0, p.stamina, rb0, GS.stats["rainbow"], GS.stats["friends"], GS.stats["fed"], p.mode])
		await get_tree().create_timer(2.0).timeout
	get_tree().quit()



# the pictorial codex with a rich state, plus a right-click wear toggle
func codex_test():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	GS.tutorial_done = {"TUTORIAL_01": true, "TUTORIAL_02": true, "TUTORIAL_03": true}
	main._reveal_specials()
	GS.set_level("red", 3)
	GS.set_level("orange", 2)
	GS.set_level("green", 1)
	GS.set_level("cyan", 3)
	GS.set_level("blue", 2)
	GS.set_level("purple", 1)
	GS.rainbow["red"] = 3
	GS.rainbow["cyan"] = 5
	for k in ["hat", "shades", "topper", "hawaii", "necklace", "pipe", "balloon"]:
		p.gull.wear(k)
		GS.mischief_counts[k] = 2
	p.gull.unwear("hat")
	p.gull.wear("sailor")
	GS.mischief_counts["coffee"] = 3
	p.mode = 1
	p.global_position = Vector3(-30.0, 0.4, 8.0)
	await get_tree().create_timer(0.5).timeout
	main._open_codex()
	await get_tree().create_timer(1.5).timeout
	await shot("cx_codex")
	# right-click the sunglasses tile: they come off
	var r = main.sense.panel.hit["shades"]
	var ev = InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_RIGHT
	ev.pressed = true
	ev.position = r.position + r.size * 0.5
	main.sense.panel._gui_input(ev)
	await get_tree().create_timer(0.3).timeout
	say("after right-click: shades equipped=%s owned=%s on gull=%s" % [GS.equipped.has("shades"), GS.worn.has("shades"), p.gull.is_on("shades")])
	await shot("cx_codex2")
	# the fish book
	GS.fish_book = {"sardine": {"n": 4, "kg": 0.09, "cm": 19.0}, "bass": {"n": 1, "kg": 4.2, "cm": 71.0}, "marlin": {"n": 1, "kg": 133.0, "cm": 281.0}, "mullet": {"n": 2, "kg": 0.4, "cm": 31.0}}
	main.sense.page = 1
	await get_tree().create_timer(0.5).timeout
	await shot("cx_fishbook")
	main._close_codex()
	get_tree().quit()


# coffee and alcohol: speeds, the sway, the wear-off on the ground; and really taking a cup from a table
func drink_test():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	main.hud.slots_visible = true
	# 1) what every buff does to the flight
	for d in ["", "coffee", "alcohol", "ice"]:
		GS.set_drink("")
		if d != "":
			GS.add_buff(d)
		place(Vector3(0, 60, 100), Vector3(0, 60, 0), 5.0)
		Input.action_press("move_forward")
		await get_tree().create_timer(2.5).timeout
		var cr = p.speed
		var st0 = p.stamina
		Input.action_press("dash")
		var t0 = Time.get_ticks_msec()
		var t_acc = -1.0
		while Time.get_ticks_msec() - t0 < 3500:
			await get_tree().physics_frame
			if t_acc < 0.0 and p.speed >= cr + 3.0:
				t_acc = (Time.get_ticks_msec() - t0) / 1000.0
		say("buff '%s': cruise %.1f  boost %.1f (gauge %d)  time to +3 m/s %.2f s  stamina used %.1f  slowmo x%.2f  window x%.2f" % [d, cr, p.speed, int(p.speed * 6), t_acc, st0 - p.stamina, GS.slowmo_mult(), GS.buff_window_mult()])
		if d != "":
			await shot("dr_%s_fly" % d)
		Input.action_release("dash")
		Input.action_release("move_forward")
	# 2) landing burns the buffs away fast
	GS.set_drink("")
	GS.add_buff("coffee")
	GS.add_buff("ice")
	say("timers coffee %.1f ice %.1f" % [GS.buff["coffee"], GS.buff["ice"]])
	p.mode = 1
	p.global_position = Vector3(-30.0, 0.4, 8.0)
	await get_tree().create_timer(1.0).timeout
	say("1 s after landing: coffee %.1f ice %.1f dying=%s" % [GS.buff["coffee"], GS.buff["ice"], str(GS.buff_dying)])
	await get_tree().create_timer(3.0).timeout
	say("4 s after landing: coffee %.1f ice %.1f" % [GS.buff["coffee"], GS.buff["ice"]])
	# 3) the ice cream makes the gull unhittable
	GS.set_drink("")
	GS.add_buff("ice")
	place(Vector3(-10, 6, 20), Vector3(-10, 6, 0), 5.0)
	var sw0 = GS.stats["swats"]
	p.get_swatted(main.elder, "punch")
	say("swatted with ice cream: swats %d -> %d mode=%d message='%s'" % [sw0, GS.stats["swats"], p.mode, GS.buff_msg])
	await get_tree().create_timer(0.4).timeout
	await shot("dr_shield")
	GS.set_drink("")
	p.get_swatted(main.elder, "punch")
	say("swatted without: mode=%d" % p.mode)
	await get_tree().create_timer(3.0).timeout
	# 4) a real ice cream and a real cup
	GS.test_boost_bonus = 0.0
	for k in ["coffee", "icecream"]:
		var cups = []
		for m in get_tree().get_nodes_in_group("mischief"):
			if m.kind == k:
				cups.append(m)
		say("%s in the world: %d" % [k, cups.size()])
		if cups.size() > 0:
			var r = await attempt(cups[0], Vector3(0, 0.2, 1), 22.0, 0.0, 14.0)
			await get_tree().create_timer(0.5).timeout
			say("took %s -> %s, buff=%s timer=%.1f" % [k, r, GS.drink, GS.drink_t])
			await shot("dr_took_" + k)
	get_tree().quit()


# the volleyball players aim a smash at a gull that hangs around the court (with a warning); a gull that keeps moving dodges it
func smash_test():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	var v = main.world["volley"]
	v.smash_cd = 0.0
	p.mode = 0
	var bops0 = GS.stats["bops"]
	var t0 = Time.get_ticks_msec()
	var wind_shot = false
	var states = {}
	while Time.get_ticks_msec() - t0 < 25000:
		await get_tree().physics_frame
		if p.mode != 2:
			p.global_position = Vector3(46.0, 3.0, 22.0)
			p.velocity = Vector3.ZERO
			p.speed = 3.0
		states[v.smash] = true
		if v.smash == "wind" and not wind_shot and v.smash_t > 0.6:
			wind_shot = true
			view(Vector3(46.0, 5.0, 28.0), Vector3(48.0, 2.5, 18.0), 60.0)
			await get_tree().create_timer(0.2).timeout
			await shot("smash_wind")
			p.set_override(Transform3D.IDENTITY, 60.0, 0.0, 20.0)
		if GS.stats["bops"] > bops0:
			break
	say("smash: states seen=%s bops %d -> %d mode=%d" % [str(states.keys()), bops0, GS.stats["bops"], p.mode])
	get_tree().quit()


# ================================================================== the walkthrough video
# `godot --path game --write-movie out.avi --fixed-fps 30 -- --film --movie-fps=30`
# The real menu, opening and ending; the bot flies the steals in between (each dive starts with a cut).
var film_t0 = 0
var film_f0 = 0

func real(t):
	await get_tree().create_timer(t, true, false, true).timeout

func clock(tag):
	# the rhythm runs on the wall clock, the movie on frames: they must agree
	var wall = (Time.get_ticks_msec() - film_t0) / 1000.0
	var game = GS.msec() / 1000.0
	var frames = (Engine.get_frames_drawn() - film_f0) / 30.0
	say("[film] %-14s wall %6.1f s  movie %6.1f s  game clock %6.1f s" % [tag, wall, frames, game])

func film_steal(f, dir, spd = -1.0, opts = {}):
	for tries in 3:
		var r = await attempt(f, dir, 24.0, 0.0, spd, opts)
		if r == "ok" or opts.has("fail_flee"):
			return r
		await real(1.5)
	return "?"

func film_old():
	film_t0 = Time.get_ticks_msec()
	film_f0 = Engine.get_frames_drawn()
	var p = main.player
	await real(3.0)
	clock("start")
	main.menus.start_pressed.emit()
	# opening cards + the big brother on the cafe roof
	var t0 = GS.msec()
	await real(3.0)
	while (main.intro_active or p.input_locked or not p.active) and GS.msec() - t0 < 70000:
		await get_tree().process_frame
	clock("intro done")
	Engine.max_fps = 30
	await real(1.2)
	# a little free flight: climb, then boost over the town
	Input.action_press("move_forward")
	await real(2.0)
	Input.action_press("dash")
	await real(2.5)
	Input.action_release("dash")
	Input.action_release("move_forward")
	await real(0.8)
	var fr = main.world["fries"]
	# the three tutorial fries: one clean, one shot down on the escape, one perfect
	await film_steal(fr["TUTORIAL_01"], Vector3(1, 0.2, 0), 11.0)
	await real(2.0)
	await film_steal(fr["TUTORIAL_02"], Vector3(1, 0.2, 0), 11.0, {})
	await real(3.5)
	await film_steal(fr["TUTORIAL_03"], Vector3(0, 0.2, 1), 11.0, {"gold": true})
	await real(2.0)
	var f2 = fr["TUTORIAL_02"]
	var tw = GS.msec()
	while is_instance_valid(f2) and not f2.consumed and (f2.vanished or not f2.available) and GS.msec() - tw < 15000:
		await get_tree().process_frame
	await film_steal(f2, Vector3(1, 0.2, 0), 11.0)
	await real(3.0)
	clock("tutorials")
	say("[film] tutorials done=%s" % str(GS.tutorial_done.keys()))
	if GS.gull_sense_count < 3:
		GS.gull_sense_count = 3
		main._reveal_specials()
	# Gull Sight over the town
	place(Vector3(0, 34, 70), Vector3(0, 10, 10), 5.0)
	await real(1.0)
	Input.action_press("gull_sense")
	main._open_sense()
	for i in 90:
		p.yaw += 0.006
		p.aim_yaw = p.yaw
		await real(1.0 / 30.0)
	Input.action_release("gull_sense")
	main._close_sense()
	await real(1.0)
	clock("gull sight")
	# silver fries of three colours
	var dirs = {"SPECIAL_RED": Vector3(0, 0, 1), "SPECIAL_GREEN": Vector3(1, 0, 0), "SPECIAL_ORANGE": Vector3(0, 0.3, 1)}
	for id in dirs:
		await film_steal(fr[id], dirs[id])
		await real(2.2)
	clock("silvers")
	# a hat off somebody's head
	for m in get_tree().get_nodes_in_group("mischief"):
		if is_instance_valid(m) and m.kind == "hat":
			await attempt(m, Vector3(0, 0.3, 1), 30.0, 0.0, 16.5)
			break
	await real(2.0)
	# the codex
	p.mode = 1
	p.global_position = Vector3(-30.0, 0.4, 8.0)
	p.velocity = Vector3.ZERO
	await real(0.6)
	main._open_codex()
	await real(4.0)
	main._close_codex()
	await real(0.5)
	clock("codex")
	# the volleyball players spike the ball at a gull that hangs around their court
	var v = main.world["volley"]
	v.smash_cd = 0.0
	var b0 = GS.stats["bops"]
	tw = GS.msec()
	place(Vector3(44.0, 3.0, 26.0), Vector3(48.0, 2.5, 18.0), 3.0)
	while GS.msec() - tw < 12000 and GS.stats["bops"] == b0:
		await get_tree().physics_frame
		if p.mode != 2:
			p.global_position = Vector3(44.0, 3.0, 26.0)
			p.velocity = Vector3.ZERO
			p.speed = 3.0
			aim_at(p, Vector3(48.0, 2.5, 18.0))
	await real(2.5)
	clock("smash")
	# a gold fry (3 rings, perfect) and a diamond fry (5 rings) up high
	GS.test_boost_bonus = 8.0
	var gp = null
	var dp = null
	for sp in main.world["prism_spots"]:
		if sp["name"] == "lifeguard":
			gp = sp["pos"]
		if sp["name"] == "ferris":
			dp = sp["pos"]
	GS.lv["blue"] = 1
	var g = make_star("blue", 2, gp, "STAR_FILM_G")
	await film_steal(g, Vector3(0, 0.3, 1), -1.0, {"gold": true})
	await real(2.5)
	GS.lv["red"] = 2
	var d = make_star("red", 3, dp, "STAR_FILM_D")
	await film_steal(d, Vector3(0, 0.3, 1))
	await real(3.0)
	GS.test_boost_bonus = 0.0
	clock("gold+diamond")
	# all dressed up, still hungry: the plain fry
	for k in ["topper", "shades", "necklace", "pipe", "coat"]:
		p.gull.wear(k)
	GS.hunger_t = 400.0
	var o = main.ordinary
	main.ordinary.set_steam(1.0)
	place(o.global_position + Vector3(0, 3.0, 9.0), o.global_position, 4.0)
	await real(2.5)
	p.mode = 0
	p.global_position = o.global_position + Vector3(0, 0.6, 1.4)
	p.speed = 3.0
	await get_tree().physics_frame
	await get_tree().physics_frame
	await press("interact")
	clock("ending")
	await real(62.0)
	clock("end")
	get_tree().quit()



# ------------------------------------------------------------------ the 2-minute promotional video (round 8): four segments recorded one by one, joined by tools/film/make_promo.py
#   --film --seg=1  the cover, the real opening (a key press every half second), HOLD E, the first seconds of flight
#   --film --seg=2  free flight, two tutorial fries (one PERFECT), Gull Sight with the four rarities
#   --film --seg=3  the three drinks -> STARLIGHT (the real cinematic moment), a shooting star chased and caught, the new tail
#   --film --seg=4  the real ending: the bite, the memories, the big brother, "just some fries."
# Record: godot --path game --write-movie out.avi --fixed-fps 30 -- --film --seg=N --movie-fps=30
func fkey():
	var ev = InputEventKey.new()
	ev.keycode = KEY_SPACE
	ev.physical_keycode = KEY_SPACE
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 = InputEventKey.new()
	ev2.keycode = KEY_SPACE
	ev2.physical_keycode = KEY_SPACE
	ev2.pressed = false
	Input.parse_input_event(ev2)

func film():
	film_t0 = Time.get_ticks_msec()
	film_f0 = Engine.get_frames_drawn()
	var seg = 1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--seg="):
			seg = int(a.substr(6))
	say("[film] segment %d" % seg)
	match seg:
		1:
			await film_seg1()
		2:
			await film_seg2()
		3:
			await film_seg3()
		4:
			await film_seg4()
	clock("segment %d done" % seg)
	get_tree().quit()

func film_start_game():
	# straight into the game (no cover, no opening): for the segments after the first
	GS.skip_intro = true
	main.menus.start_pressed.emit()
	await real(1.0)

func film_seg1():
	var p = main.player
	await real(3.6)
	clock("cover")
	main.menus.start_pressed.emit()
	var t0 = GS.msec()
	var k = 0
	while GS.msec() - t0 < 140000:
		await real(0.5)
		k += 1
		if main.story.hold["on"]:
			await real(0.6)
			Input.action_press("interact")
			await real(1.4)
			Input.action_release("interact")
			break
		if k % 2 == 0:
			fkey()
	clock("opening done")
	await real(4.5)

func film_seg2():
	var p = main.player
	await film_start_game()
	Engine.max_fps = 30
	clock("start")
	Input.action_press("move_forward")
	await real(1.5)
	Input.action_press("dash")
	await real(2.0)
	Input.action_release("dash")
	Input.action_release("move_forward")
	var fr = main.world["fries"]
	await film_steal(fr["TUTORIAL_01"], Vector3(1, 0.2, 0), 11.0)
	await real(1.5)
	await film_steal(fr["TUTORIAL_03"], Vector3(0, 0.2, 1), 11.0, {"gold": true})
	await real(1.2)
	GS.gull_sense_count = 3
	GS.tutorial_done = {"TUTORIAL_01": true, "TUTORIAL_02": true, "TUTORIAL_03": true}
	main._reveal_specials()
	clock("tutorials")
	# Gull Sight: the four rarities side by side
	var base = Vector3(8.0, 36.0, 40.0)
	var types = ["red", "orange", "green", "cyan"]
	var made = []
	for i in 4:
		made.append(make_star(types[i], i + 1 if i < 3 else 3, base + Vector3(-9.0 + i * 5.6, 0.5 + 0.6 * (i % 2), -18.0), "STAR_FILM_%d" % i))
	var rb = make_star("pink", 4, base + Vector3(13.0, 0.5, -18.0), "STAR_FILM_RB")
	rb.revealed = true
	rb.visible = true
	rb.tier = 4
	place(base, base + Vector3(0, 0, -20), 3.0)
	p.input_locked = false
	await real(1.2)
	Input.action_press("gull_sense")
	main._open_sense()
	for i in 90:
		p.yaw += 0.004
		p.aim_yaw = p.yaw
		await real(1.0 / 30.0)
	Input.action_release("gull_sense")
	main._close_sense()
	await real(1.5)

func film_seg3():
	var p = main.player
	await film_start_game()
	Engine.max_fps = 30
	GS.gull_sense_count = 3
	GS.tutorial_done = {"TUTORIAL_01": true, "TUTORIAL_02": true, "TUTORIAL_03": true}
	main._reveal_specials()
	for id in ["drink_coffee", "drink_alcohol", "drink_ice", "meteor", "fish"]:
		GS.cine_seen[id] = true
	place(Vector3(30.0, 34.0, 60.0), Vector3(30.0, 30.0, 20.0), 14.0)
	p.input_locked = false
	Input.action_press("move_forward")
	await real(2.0)
	Input.action_release("move_forward")
	# a coffee, a cocktail, an ice cream
	GS.add_buff("coffee")
	await real(0.4)
	GS.add_buff("alcohol")
	await real(0.4)
	GS.add_buff("ice")
	clock("three drinks")
	# the real cinematic moment (a key press every 0.7 s, the sentences go on a little faster)
	var t0 = GS.msec()
	var k = 0
	while GS.msec() - t0 < 90000:
		await real(0.5)
		if main.scenes.cine_busy:
			k += 1
			if k % 3 == 0:
				fkey()
		elif k > 4:
			break
	clock("starlight cinematic done")
	# STARLIGHT: out over the open sea (nothing else to lock on to), then a shooting star comes by
	place(Vector3(60.0, 80.0, 110.0), Vector3(60.0, 80.0, 40.0), 30.0)
	p.input_locked = false
	Input.action_press("move_forward")
	Input.action_press("dash")
	var star = null
	var t1 = GS.msec()
	while GS.msec() - t1 < 22000:
		await real(0.1)
		p.aim_yaw += 0.01
		if main.meteors.star != null and is_instance_valid(main.meteors.star) and main.meteors.star.age > 1.0:
			star = main.meteors.star
			break
	say("[film] star=%s" % str(star))
	if star != null:
		var d = star.vel.normalized()
		var start = star.global_position - d * 34.0
		start.y = max(start.y, 30.0)
		place(start, star.global_position, GS.need_speed(star) + 1.0)
		say("[film] chase start %s star %s need %.1f speed %.1f" % [str(start), str(star.global_position), GS.need_speed(star), p.speed])
		Input.action_press("move_forward")
		Input.action_press("dash")
		for i in 1500:
			await get_tree().process_frame
			if not is_instance_valid(star) or star.taken:
				break
			if p.snatch.state == "idle" and p.snatch.lock_fry == null:
				aim_at(p, star.global_position)
				p.stamina = 60.0
			var sq = p.snatch.seq
			if sq != null:
				var idx = p.snatch._first_pending(sq)
				if idx >= 0:
					var nt = sq["notes"][idx]
					var now = p.snatch.seq_now()
					if now >= nt["t"] - sq["gw"] - sq["gg"] * 0.55 and not sq.has("p%d" % idx):
						sq["p%d" % idx] = true
						tap("interact")
	Input.action_release("dash")
	say("[film] commit %s state=%s" % [str(p.snatch.last_commit), p.snatch.state])
	await real(1.0)
	say("[film] meteor caught=%s worn=%s" % [str(GS.stats["meteors"]), str(GS.worn.has("meteor"))])
	# the new tail, in the open sky
	Input.action_press("dash")
	for i in 120:
		p.aim_yaw += 0.012
		p.aim_pitch = 0.05
		await real(1.0 / 30.0)
	Input.action_release("dash")
	Input.action_release("move_forward")
	await real(1.0)

func film_seg4():
	var p = main.player
	await film_start_game()
	Engine.max_fps = 30
	GS.gull_sense_count = 3
	for t in GS.FRY_TYPES:
		GS.set_level(t, 3)
	GS.tutorial_done = {"TUTORIAL_01": true, "TUTORIAL_02": true, "TUTORIAL_03": true}
	main._reveal_specials()
	var ids = ["fry1", "coffee", "alcohol", "ice", "starlight", "cloud", "sun", "meteor", "friend"]
	for i in ids.size():
		GS.memories[ids[i]] = {"t": 100.0 + i * 40.0}
	GS.memories["fish"] = {"t": 340.0, "sp": "mackerel", "len": 31.0, "kg": 0.4}
	GS.fish_book = {"mackerel": {"n": 2, "kg": 0.6, "cm": 36.0}, "tuna": {"n": 1, "kg": 40.0, "cm": 150.0}}
	for kk in ["hat", "scarf", "necklace", "meteor"]:
		p.gull.wear(kk)
	var WB = preload("res://scripts/world/world_builder.gd")
	main.ordinary.visible = true
	place(WB.ORDINARY_POS + Vector3(0.3, 0.6, 0.3), WB.ORDINARY_POS, 3.0)
	await real(1.5)
	clock("ending start")
	p.mode = 1
	p.global_position = WB.ORDINARY_POS + Vector3(0.3, 0.45, 0.3)
	await real(0.5)
	await press("interact")
	var t0 = GS.msec()
	var k = 0
	while GS.msec() - t0 < 260000:
		await real(0.5)
		k += 1
		# the talking part goes a little faster: a press every 1.5 s once the big brother has landed
		if main.story.vn != null and k % 3 == 0:
			fkey()
		if k > 40 and not main.scenes.cine_busy and not main.title.visible:
			break
	clock("ending talk done")
	await real(9.0)


# the sky quests: a cloud and the sun appear on the board after enough fries; catching one is a single, hard wave
func sky_test():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	main._reveal_specials()
	for t in GS.FRY_TYPES:
		GS.set_level(t, 3)
	GS.test_boost_bonus = 30.0       # round 9: the sky wants STARLIGHT speeds (255-272); the bot borrows them
	main.hud.slots_visible = true
	await get_tree().create_timer(2.0).timeout
	say("quests: %s items=%s" % [str(GS.quests), str(main.quest_items.keys())])
	for id in ["cloud", "sun"]:
		var it = main.quest_items.get(id, null)
		if it == null:
			say("%s: no item!" % id)
			continue
		say("%s at %s need %d gauge" % [id, str(it.global_position), int(GS.need_speed(it) * 6)])
		var r = await attempt(it, Vector3(0, 0.1, 1), 30.0, 0.0, -1.0, {"shot": "sky_" + id})
		say("%s -> %s quests=%s worn=%s" % [id, r, str(GS.quests), str(GS.worn.keys())])
		await get_tree().create_timer(9.0).timeout
	await shot("sky_after")
	get_tree().quit()

# how many of every stealable kind exist in the world (wearables exactly once, drinks a few)
func mischief_census():
	await get_tree().create_timer(1.0).timeout
	var counts = {}
	for m in get_tree().get_nodes_in_group("mischief"):
		if is_instance_valid(m) and "kind" in m:
			counts[m.kind] = counts.get(m.kind, 0) + 1
	var keys = counts.keys()
	keys.sort()
	for k in keys:
		say("%-10s x%d" % [k, counts[k]])
	get_tree().quit()


# for every kind of thing: from how many of 16 compass directions (at 14 m, 3 m up) is the line to it clear?
func reach_test():
	await get_tree().create_timer(1.0).timeout
	var s = main.player.snatch
	GS.gull_sense_count = 3
	var done = {}
	for m in get_tree().get_nodes_in_group("mischief"):
		if not is_instance_valid(m) or done.has(m.kind):
			continue
		done[m.kind] = true
		var tgt = m.aim_point()
		var clear = 0
		for k in 16:
			var a = k * TAU / 16.0
			var from = tgt + Vector3(cos(a) * 14.0, 4.0, sin(a) * 14.0)
			if s._los(from, tgt):
				clear += 1
		say("%-9s at (%.1f, %.1f, %.1f) clear directions %d / 16  visible=%s snatchable=%s" % [m.kind, tgt.x, tgt.y, tgt.z, clear, str(m.is_visible_in_tree()), str(m.is_snatchable())])
	get_tree().quit()


func bank_test():
	await get_tree().create_timer(1.0).timeout
	main.player.input_locked = true
	var views = {"bk1": [Vector3(-14, 14, -16), Vector3(-14, 6, -34), 60.0], "bk2": [Vector3(20, 10, -28), Vector3(10, 7, -45), 60.0], "bk3": [Vector3(0, 40, 10), Vector3(0, 6, -40), 60.0]}
	for k in views:
		view(views[k][0], views[k][1], views[k][2])
		await get_tree().create_timer(0.6).timeout
		await shot(k)
	get_tree().quit()


# the comic-panel camera shots, read from shots/cams.json: [[name, px, py, pz, lx, ly, lz, fov], ...] (dev: tune the opening / ending shots without touching code)
func cams_test():
	await get_tree().create_timer(1.0).timeout
	var txt = FileAccess.get_file_as_string(shots + "cams.json")
	var list = JSON.parse_string(txt)
	main.player.input_locked = true
	main.story.begin(main.player)
	main.story.frame = 1.0
	main.hud.visible = false
	main.bro.look_at_player = true
	for c in list:
		if str(c[0]).begins_with("e"):
			main.player.global_position = Vector3(-8.15, 5.22, -1.2)
			main.player.yaw = atan2(-1.0, 0.0)
			main.player.rotation = Vector3(0, main.player.yaw, 0)
			main.bro.look_at_player = false
			main.bro._face(Vector3(-8.15, 5.22, -1.2), 1.0)
		view(Vector3(c[1], c[2], c[3]), Vector3(c[4], c[5], c[6]), c[7])
		await get_tree().create_timer(0.6).timeout
		await shot("cam_" + str(c[0]))
	get_tree().quit()


# round 7: everything new, one check at a time ("[R7] ... PASS/FAIL")
func chk(name_, ok, extra = ""):
	say("[R7] %s %s %s" % ["PASS" if ok else "FAIL", name_, extra])

func round7_test():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	var o = main.ordinary
	# --- A: the plain fry lies there from the start (round 8) but is inert (no glow, no prompt) until the three starter fries are in
	chk("plain fry lies on the floor at the start", o.visible and o.halo_alpha <= 0.01, "visible=%s halo=%s" % [o.visible, o.halo_alpha])
	place(o.global_position + Vector3(0, 0.6, 1.4), o.global_position, 3.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	tap("interact")
	await get_tree().create_timer(0.5).timeout
	chk("no prompt / toast near the plain fry before the starters", p.snatch.hud_state != "eat" and p.snatch.toast_t <= 0.0 and not GS.ordinary_eaten, "hud=%s toast=%s" % [p.snatch.hud_state, p.snatch.toast])
	# --- B: drinks stack their time, fill the breath, no burning on the ground; three of them = STARLIGHT
	GS.gull_sense_count = 3
	GS.tutorial_done = {"TUTORIAL_01": true, "TUTORIAL_02": true, "TUTORIAL_03": true}
	main._reveal_specials()
	place(Vector3(-9.5, 30.0, 20.0), Vector3(-9.5, 30.0, 90.0), 8.0)
	p.stamina = 10.0
	GS.add_buff("coffee")
	GS.add_buff("coffee")
	chk("two coffees stack time", GS.buff["coffee"] > 39.0, "t=%.1f" % GS.buff["coffee"])
	chk("a cup refills the breath", p.stamina >= GS.stamina_max() - 0.5, "stamina=%.0f/%.0f" % [p.stamina, GS.stamina_max()])
	chk("top speed with one coffee", abs(GS.boost_speed() - (15.0 + 4.2)) < 0.01, "%.1f m/s = %d" % [GS.boost_speed(), int(GS.boost_speed() * 6)])
	GS.add_buff("alcohol")
	chk("no star with two kinds", not GS.star_active())
	GS.add_buff("ice")
	chk("three kinds start STARLIGHT", GS.star_active() and abs(GS.star_t - 30.0) < 0.5, "star_t=%.1f" % GS.star_t)
	Input.action_press("move_forward")
	Input.action_press("dash")
	await get_tree().create_timer(2.5).timeout
	await shot("r7_star_a")
	chk("STARLIGHT: flying costs nothing", p.stamina >= GS.stamina_max() - 1.0, "stamina=%.0f" % p.stamina)
	chk("STARLIGHT: speed is high", p.speed > 28.0, "speed=%.1f m/s (%d)" % [p.speed, int(p.speed * 6)])
	chk("STARLIGHT: unhittable", GS.invincible())
	Input.action_release("dash")
	Input.action_release("move_forward")
	await get_tree().create_timer(1.0).timeout
	await shot("r7_star_b")
	# land: nothing burns away
	var c0 = GS.buff["coffee"]
	place(Vector3(-9.5, 5.22, -0.8), Vector3(-9.5, 5.22, 20.0), 1.0)
	p.mode = 1
	await get_tree().create_timer(3.0).timeout
	chk("buffs keep running on the ground", GS.buff["coffee"] > c0 - 5.0, "before=%.1f after=%.1f" % [c0, GS.buff["coffee"]])
	GS.star_t = 0.4
	await get_tree().create_timer(1.0).timeout
	chk("STARLIGHT ends", not GS.star_active())
	GS.set_drink("")
	# --- C: a round tree crown is solid: land on it
	var trees = main.world.get("trees", [])
	var landed_ok = 0
	var tested = 0
	for tr in trees:
		if tr["kind"] != 0 or tested >= 3:
			continue
		tested += 1
		place(tr["top"] + Vector3(0, 2.5, 0), tr["top"], 3.0)
		p.mode = 0
		Input.action_press("land")
		var t0 = Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 3500 and p.mode != 1:
			await get_tree().physics_frame
		Input.action_release("land")
		var dy = p.global_position.y - tr["top"].y
		say("   tree at %s top %.1f: mode=%d y=%.2f (dy %.2f)" % [str(tr["pos"]), tr["top"].y, p.mode, p.global_position.y, dy])
		if p.mode == 1 and dy > -1.5 and dy < 1.5:
			landed_ok += 1
		if tested == 1:
			await shot("r7_tree")
	chk("a gull can stand on a tree crown", landed_ok >= 2, "%d of %d" % [landed_ok, tested])
	# --- D: quests of the board
	GS.quests_refresh()
	say("   board: %s" % str(GS.quests_shown()))
	chk("quests show up after the tutorial", GS.quests_shown().size() >= 3)
	GS.add_buff("coffee")
	GS.stats["drinks"] += 1
	GS.quests_check()
	chk("GET A DRINK is ticked off", GS.quest_state("drink") == "done")
	# --- E: the nearest fry that the gull can really lock
	var nf = GS.nearest_fry(Vector3(-9.5, 5.2, -0.8))
	chk("nearest reachable fry exists and is reachable", nf != null and GS.reachable(nf), "%s need=%d boost=%d" % [str(nf.id) if nf != null else "-", int(GS.need_speed(nf) * 6) if nf != null else -1, int(GS.boost_speed() * 6)])
	# --- F: top speed ladder
	GS.set_drink("")
	GS.set_level("red", 1)
	chk("red silver covers every gold fry (114)", GS.boost_speed() * 6.0 >= 114.0, "%d" % int(GS.boost_speed() * 6))
	GS.set_level("red", 2)
	chk("red gold covers every diamond fry (144)", GS.boost_speed() * 6.0 >= 144.0, "%d" % int(GS.boost_speed() * 6))
	GS.set_level("red", 1)
	GS.add_buff("coffee")
	chk("red silver + coffee reaches a diamond fry", GS.boost_speed() * 6.0 >= 144.0, "%d" % int(GS.boost_speed() * 6))
	GS.set_drink("")
	GS.set_level("red", 0)
	# --- G: the early SONIC gold
	GS.set_level("red", 1)
	main._early_sonic()
	var gold = null
	for f in main.star_active:
		if is_instance_valid(f) and f.utype == "red" and f.tier == 2:
			gold = f
	chk("the SONIC gold fry hangs near the start", gold != null and gold.get_meta("spot") == "lifeguard", str(gold.get_meta("spot")) if gold != null else "none")
	GS.set_level("red", 0)
	# --- H: rainbow fries in the hands of passers-by
	for k in GS.FRY_TYPES:
		GS.set_level(k, 3)
	for i in 6:
		main.rb_t = 0.0
		main.rb_wait = 0.0
		main._rainbow_tick(3.0)
	var edge_ok = true
	for h in main.rb_holders:
		var hp = h["npc"].home_pos
		say("   rainbow holder at (%.0f, %.0f) type %s" % [hp.x, hp.z, h["fry"].utype])
		if Vector2(hp.x, hp.z).distance_to(Vector2(-9, 0)) < 40.0:
			edge_ok = false
	chk("rainbow fries are held by passers-by far from the start", main.rb_holders.size() >= 3 and edge_ok, "%d holders" % main.rb_holders.size())
	for k in GS.FRY_TYPES:
		GS.set_level(k, 0)
	# --- I: fish (forecast 5 s ahead, three rarities, a column free of the pier)
	p.mode = 0
	var spot = main.world["fish_spots"][1]
	spot.wait = 0.1
	say("   fish spot %s r=%.0f state=%s live=%d" % [str(spot.center), spot.region_r, spot.state, spot.get_script().live])
	spot.state = "idle"
	spot.get_script().live = 0
	place(Vector3(spot.center.x + 10.0, 12.0, spot.center.z + 20.0), spot.center, 8.0)
	var t1 = Time.get_ticks_msec()
	while spot.state == "idle" and Time.get_ticks_msec() - t1 < 20000:
		await get_tree().physics_frame
	var si = spot.sight_info()
	chk("a fish is announced before it jumps", si != null, "state=%s %s" % [spot.state, str(si)])
	if si != null:
		say("   forecast: %.1f s ahead, rarity %d (need %d)" % [si["t"], si["rarity"], int(si["need"])])
		Input.action_press("gull_sense")
		main._open_sense()
		place(spot.global_position + Vector3(8, 6, 16), spot.global_position, 4.0)
		await get_tree().create_timer(0.9).timeout
		await shot("r7_forecast")
		Input.action_release("gull_sense")
		main._close_sense()
		main.player.set_override(Transform3D.IDENTITY, 60.0, 0.0, 20.0)
	while spot.state != "leap" and Time.get_ticks_msec() - t1 < 20000:
		await get_tree().physics_frame
	var fish = spot.fish
	chk("the fish leaps", fish != null)
	if fish != null:
		say("   fish: %s  %s  %s  rarity %d  need %d" % [fish.species, GS.fish_cm_text(fish.len_cm), GS.fish_kg_text(fish.kg), fish.rarity, int(GS.need_speed(fish) * 6)])
		GS.test_boost_bonus = 12.0
		var res = await attempt(fish, Vector3(0.6, 0.15, 1.0), 24.0, 0.0, -1.0)
		GS.test_boost_bonus = 0.0
		chk("the fish can be caught", GS.stats["fish"] >= 1 and not GS.fish_book.is_empty(), "res=%s book=%s" % [res, str(GS.fish_book)])
		await get_tree().create_timer(1.2).timeout
		await shot("r7_fishcard")
	# --- J: every fish spot: is its leap column free (the pier, the marina, the boats)?
	var bad = 0
	var planned = 0
	for sp in main.world["fish_spots"]:
		for k in 6:
			if sp._plan_leap():
				planned += 1
				var a = sp.leap_from
				var b = sp.leap_to
				if sp._in_avoid(a.x, a.z, 1.0) or sp._in_avoid(b.x, b.z, 1.0):
					bad += 1
	chk("planned leaps stay off the pier, marina and boats", bad == 0 and planned > 30, "planned=%d bad=%d" % [planned, bad])
	# --- K: the flight record
	p.mode = 0
	GS.flight_begin()
	GS.flight["max"] = 120.0
	GS.flight["t"] = 12.0
	GS.flight["loot"] = 2
	await get_tree().create_timer(0.3).timeout
	await shot("r7_flightlog")
	get_tree().quit()


# friends on a tree crown and a roof, and the kind children with a heart
func round7b_test():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	GS.tutorial_done = {"TUTORIAL_01": true, "TUTORIAL_02": true, "TUTORIAL_03": true}
	for k in ["red", "orange", "green", "cyan"]:
		GS.set_level(k, 3)
	var r = main.rest
	var tr = null
	for t in main.world["trees"]:
		if t["kind"] == 0:
			tr = t
			break
	var places = [["tree crown", tr["top"] + Vector3(0, 0.6, 0)], ["roof of the cafe", Vector3(-9.5, 5.3, -0.8)]]
	for pl in places:
		p.mode = 0
		place(pl[1] + Vector3(0, 1.5, 0), pl[1], 3.0)
		Input.action_press("land")
		var t0 = Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 4000 and p.mode != 1:
			await get_tree().physics_frame
		Input.action_release("land")
		r.force_kind = "buddy"
		r.cd = 0.0
		r.gift_cd = 0.0
		p.still_t = 3.0
		var rb0 = GS.stats["rainbow"]
		var gf0 = GS.stats.get("gifts", 0)
		var shot_done = false
		t0 = Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 14000:
			await get_tree().physics_frame
			if p.mode == 1:
				p.still_t = max(p.still_t, 2.0)
			if r.ev != null and not shot_done and r.ev.get("t", 0.0) > 1.0 and r.ev.get("phase", "") == "sit":
				shot_done = true
				view(p.global_position + Vector3(-2.4, 1.4, 3.6), p.global_position + Vector3(0.6, 0.4, 0), 55.0)
				await get_tree().create_timer(0.3).timeout
				await shot("r7b_buddy_" + pl[0].replace(" ", "_"))
				p.set_override(Transform3D.IDENTITY, 60.0, 0.0, 20.0)
			if r.ev == null and shot_done:
				break
		say("[R7B] %s: friend visited=%s gifts %d -> %d rainbow %d -> %d mode=%d y=%.1f" % [pl[0], shot_done, gf0, GS.stats.get("gifts", 0), rb0, GS.stats["rainbow"], p.mode, p.global_position.y])
		await get_tree().create_timer(3.0).timeout
	r.force_kind = ""
	# a kind child
	var kid = null
	for a in get_tree().get_nodes_in_group("ambient"):
		if a.kind_kid:
			kid = a
			break
	say("[R7B] kind children in the world: %d" % get_tree().get_nodes_in_group("ambient").filter(func(a): return a.kind_kid).size())
	if kid != null:
		p.mode = 1
		var kp = kid.global_position + Vector3(6.0, 0.4, 0.0)
		p.global_position = kp
		p.velocity = Vector3.ZERO
		p.still_t = 3.0
		var fed0 = GS.stats["fed"]
		var t1 = Time.get_ticks_msec()
		var shot2 = false
		while Time.get_ticks_msec() - t1 < 14000:
			await get_tree().physics_frame
			p.still_t = max(p.still_t, 2.0)
			p.mode = 1 if p.mode != 0 else 0
			if not shot2:
				shot2 = true
				view(kid.global_position + Vector3(3.0, 1.8, 5.0), kid.global_position + Vector3(0, 1.2, 0), 55.0)
				await get_tree().create_timer(0.4).timeout
				await shot("r7b_kid_heart")
				p.set_override(Transform3D.IDENTITY, 60.0, 0.0, 20.0)
			if GS.stats["fed"] > fed0:
				break
		say("[R7B] kind child state=%s fed %d -> %d" % [kid.kk_state, fed0, GS.stats["fed"]])
	get_tree().quit()


# ---------------------------------------------------------------- round 8
# --r8c: the real opening, a contact sheet of screenshots every 2.5 s (the VN box, the portraits, the old man's fry)
func r8open():
	await get_tree().create_timer(1.0).timeout
	main.scenes.opening()
	for i in 44:
		await real(2.5)
		await shot("r8o_%02d" % i)
		if main.story.hold["on"]:
			Input.action_press("interact")
	Input.action_release("interact")
	await real(2.0)
	await shot("r8o_end")
	get_tree().quit()

# --r8b: the four cinematic moments, shots while they play
func r8cine():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	main._reveal_specials()
	var which = "all"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			which = a.substr(7)
	var ids = ["drinks3", "fish", "meteor", "all24"]
	if which != "all":
		ids = which.split(",")
	for id in ids:
		place(Vector3(-4.0, 40.0, 30.0), Vector3(-4.0, 40.0, 0.0), 6.0)
		p.mode = 0
		await real(0.5)
		GS.cine_seen.erase(id)
		GS.cine_seen[id] = true
		main.scenes.cinema(id, {"sp": "mackerel", "len": 31.0, "kg": 0.41})
		var t0 = GS.msec()
		var k = 0
		while main.scenes.cine_busy or GS.msec() - t0 < 1500:
			await real(1.6)
			await shot("r8c_%s_%02d" % [id, k])
			k += 1
			if k > 30:
				break
		say("[R8] cinematic %s finished after %d shots busy=%s" % [id, k, str(main.scenes.cine_busy)])
		await real(1.0)
	get_tree().quit()

# --r8t: Gull Sight emblems of every rarity, side by side
func r8tab():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	main._reveal_specials()
	var base = Vector3(-4.0, 40.0, 30.0)
	var types = ["red", "orange", "green", "cyan"]
	var made = []
	for i in 4:
		var f = make_star(types[i], i + 1 if i < 3 else 3, base + Vector3(-8.0 + i * 5.0, 1.0, -14.0), "STAR_EMB_%d" % i)
		made.append(f)
	var rb = make_star("pink", 4, base + Vector3(12.0, 1.0, -14.0), "STAR_EMB_RB")
	rb.revealed = true
	rb.visible = true
	rb.tier = 4
	place(base, base + Vector3(0, 0, -20), 4.0)
	p.input_locked = false
	await real(1.0)
	Input.action_press("gull_sense")
	main._open_sense()
	await real(1.2)
	await shot("r8t_tab")
	Input.action_release("gull_sense")
	main._close_sense()
	await real(0.8)
	await shot("r8t_world")
	# a shooting star: forecast, then flight, seen through Gull Sight and with the naked eye
	for f in made:
		f.consume()
	rb.consume()
	place(Vector3(-4.0, 70.0, 30.0), Vector3(-4.0, 70.0, 0.0), 4.0)
	main.meteors.star_pending = -1.0
	main.meteors._plan_star()
	await real(1.0)
	Input.action_press("gull_sense")
	main._open_sense()
	await real(1.0)
	await shot("r8t_meteor_forecast")
	await real(4.5)
	await shot("r8t_meteor_flight")
	Input.action_release("gull_sense")
	main._close_sense()
	await real(1.5)
	await shot("r8t_meteor_eye")
	get_tree().quit()

func round8_test():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	main._reveal_specials()
	main.autotest_no_cine = true
	# 1 the rainbow fry: five judgements and the speed to match
	var rb = make_star("green", 4, Vector3(-4.0, 40.0, -20.0), "STAR_RB_T")
	rb.tier = 4
	chk("rainbow needs 150", abs(GS.need_speed(rb) * GS.SPEED_UNIT - 150.0) < 0.1, str(GS.need_speed(rb) * GS.SPEED_UNIT))
	var prm = p.snatch._seq_params(rb)
	chk("rainbow = 5 circles x 2 judgements", prm["n"] == 10 and prm["c"] == 5, str(prm["n"]))
	# 2 the plain fry lies on the table, visible, with no glow, and is not eatable before the 3 starters
	GS.gull_sense_count = 0
	main.ordinary.visible = true
	chk("plain fry visible from the start", main.ordinary.visible)
	chk("plain fry has no halo", main.ordinary.halo_alpha <= 0.01)
	GS.gull_sense_count = 3
	# 3 the meteor: forecast, flight, trajectory, catch
	var mg = main.meteors
	GS.lv["red"] = 3
	mg._plan_star()
	var inf = mg.sight_info()
	chk("meteor forecast exists", inf != null and inf["t"] > 4.0, str(inf))
	await real(5.4)
	chk("meteor flies", mg.star != null and is_instance_valid(mg.star))
	var star = mg.star
	chk("meteor asks 262", abs(GS.need_speed(star) * GS.SPEED_UNIT - 262.0) < 0.1)
	var prm2 = p.snatch._seq_params(star)
	chk("meteor = 5 circles x 2 judgements", prm2["n"] == 10, str(prm2["n"]))
	GS.test_boost_bonus = 30.0
	var q0 = GS.quest_state("meteor")
	# chase it: start behind it on its own line
	var d = star.vel.normalized()
	var start = star.global_position - d * 26.0
	place(start, star.global_position, GS.need_speed(star) + 1.0)
	Input.action_press("move_forward")
	Input.action_press("dash")
	var got = false
	for i in 1500:
		await get_tree().process_frame
		if not is_instance_valid(star) or star.taken:
			got = star.taken if is_instance_valid(star) else GS.stats["meteors"] > 0
			break
		if i % 30 == 0:
			say("   i=%d state=%s hud=%s lock=%s spd=%.1f d=%.1f ts=%.2f snatchable=%s vanished=%s" % [i, p.snatch.state, p.snatch.hud_state, str(p.snatch.lock_fry != null), p.speed, p.global_position.distance_to(star.global_position), Engine.time_scale, str(star.is_snatchable()), str(star.vanished)])
		if p.snatch.state == "idle" and p.snatch.lock_fry == null:
			aim_at(p, star.global_position)
			p.stamina = 60.0
		var sq = p.snatch.seq
		if sq != null:
			var idx = p.snatch._first_pending(sq)
			if idx >= 0:
				var nt = sq["notes"][idx]
				var now = p.snatch.seq_now()
				if now >= nt["t"] - sq["gw"] * 0.5 and not sq.has("p%d" % idx):
					sq["p%d" % idx] = true
					tap("interact")
	Input.action_release("move_forward")
	Input.action_release("dash")
	chk("meteor caught", GS.stats["meteors"] > 0, "state=%s" % GS.quest_state("meteor"))
	chk("meteor quest done", GS.quest_state("meteor") == "done")
	# the first star is a cinematic moment of its own: the star stays in the beak, then it becomes the gull's tail
	main.autotest_no_cine = false
	if not main.scenes.cine_busy and not GS.cine_seen.has("meteor"):
		main.queue_cine("meteor")
	var tq = GS.msec()
	while GS.msec() - tq < 6000 and not main.scenes.cine_busy:
		await get_tree().process_frame
	chk("meteor cinematic started", main.scenes.cine_busy)
	var tm = GS.msec()
	while main.scenes.cine_busy and GS.msec() - tm < 90000:
		await real(0.5)
		fkey()
	chk("meteor cinematic ended and the star is worn", (not main.scenes.cine_busy) and GS.worn.has("meteor") and p.gull.is_on("meteor"))
	get_tree().quit()

# --r8e: the new ending, played for real with a plausible run behind it
func r8end():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	for t in GS.FRY_TYPES:
		GS.set_level(t, 3)
	GS.tutorial_done = {"TUTORIAL_01": true, "TUTORIAL_02": true, "TUTORIAL_03": true}
	main._reveal_specials()
	for id in ["fry1", "coffee", "alcohol", "ice", "starlight", "cloud", "sun", "meteor", "friend"]:
		GS.memories[id] = {"t": 100.0 + GS.memories.size() * 40.0}
	GS.memories["fish"] = {"t": 300.0, "sp": "mackerel", "len": 31.0, "kg": 0.4}
	GS.fish_book = {"mackerel": {"n": 2, "kg": 0.6, "cm": 36.0}, "tuna": {"n": 1, "kg": 40.0, "cm": 150.0}}
	for k in ["topper", "shades", "necklace", "meteor"]:
		p.gull.wear(k)
	var WB = preload("res://scripts/world/world_builder.gd")
	say("[R8] elder at %s, fry at %s, bro at %s" % [str(main.elder.global_position), str(WB.ORDINARY_POS), str(main.bro.global_position)])
	main.ordinary.visible = true
	place(WB.ORDINARY_POS + Vector3(0.3, 0.6, 0.3), WB.ORDINARY_POS, 3.0)
	await real(1.0)
	main.autotest = false
	main._on_ate_ordinary(main.ordinary)
	var t0 = Time.get_ticks_msec()
	var k = 0
	var ccx = main.scenes.cc()
	var worst_e = 0.0
	var near_e = 99.0
	while Time.get_ticks_msec() - t0 < 300000:
		await real(2.0)
		await shot("r8e_%03d" % k)
		var camx = get_viewport().get_camera_3d()
		if camx != null and main.story.active and main.story.cam != null:
			for pair in [["you", p.gull], ["bro", main.bro.gull]]:
				if pair[1].is_visible_in_tree():
					var cv = ccx.approx_cover(camx, pair[1])
					say("[R9] end t=%03d %s covers %d%% camera %.1f m" % [k * 2, pair[0], int(cv["w"] * 100.0), cv["near"]])
					if cv["w"] > 0.0:
						worst_e = max(worst_e, cv["w"])
						near_e = min(near_e, cv["near"])
		k += 1
		if k > 20 and not main.scenes.cine_busy:
			break
	chk9("the ending never puts a gull in the lens", worst_e <= 0.6 and near_e >= 2.4, "worst %d%% nearest %.1f m" % [int(worst_e * 100.0), near_e])
	say("[R8] ending finished after %d shots" % k)
	for i in 6:
		await real(2.0)
		await shot("r8e_%03d" % k)
		k += 1
	get_tree().quit()

# --r8m: the big brother's three talks on the roof
func r8bro():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	main._reveal_specials()
	p.gull.wear("hat")
	for n in [3, 10, 18]:
		GS.cine_seen.erase("chat%d" % [1 if n == 3 else (2 if n == 10 else 3)])
	for id in ["chat1"]:
		GS.cine_seen.erase(id)
		main.bro.near_t = 0.0
		p.mode = 1
		p.global_position = Vector3(-7.0, 5.4, -0.3)
		p.velocity = Vector3.ZERO
		say("[R8] bro talk %s" % id)
		main.scenes.bro_chat(id)
		var k = 0
		while main.scenes.cine_busy and k < 20:
			await real(1.5)
			await shot("r8m_%s_%02d" % [id, k])
			k += 1
	get_tree().quit()


# ================================================================== ROUND 9
func chk9(name_, ok, extra = ""):
	say("[R9] %s %s %s" % ["PASS" if ok else "FAIL", name_, extra])

# the real top speed a gull reaches in the air for a given ladder step with all three drinks (STARLIGHT on): must clear the sky's needs
func r9speed():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	main.meteors.set_process(false)
	for step in [1, 2, 3]:
		GS.lv["red"] = step
		GS.buff["coffee"] = 0.0
		GS.buff["alcohol"] = 0.0
		GS.buff["ice"] = 0.0
		GS.star_t = 0.0
		for k in ["coffee", "alcohol", "ice"]:
			GS.add_buff(k)
		p.input_locked = false
		place(Vector3(0, 150, 300), Vector3(0, 150, 100), 12.0)
		Input.action_press("move_forward")
		Input.action_press("dash")
		var top = 0.0
		for i in 900:
			await get_tree().process_frame
			if p.stamina < 40.0:
				p.stamina = 90.0
			GS.star_t = max(GS.star_t, 5.0)
			top = max(top, p.speed)
			if p.global_position.z < -250.0:
				place(Vector3(0, 150, 300), Vector3(0, 150, 100), p.speed)
		Input.action_release("move_forward")
		Input.action_release("dash")
		var g = top * 6.0
		var ceil_g = GS.boost_speed() * 6.0
		say("[R9] sonic step %d: reached %d gauge (formula ceiling %d)" % [step, int(g), int(ceil_g)])
		if step == 1:
			chk9("silver-SONIC gull cannot reach the cloud (255)", g < GS.CLOUD_NEED, "%d" % int(g))
		elif step == 2:
			chk9("gold-SONIC gull reaches the cloud (255)", g >= GS.CLOUD_NEED, "%d" % int(g))
			chk9("gold-SONIC gull reaches the sun (272)", g >= GS.SUN_NEED, "%d" % int(g))
		else:
			chk9("diamond-SONIC gull reaches the sun with room to spare", g >= GS.SUN_NEED + 14.0, "%d" % int(g))
	get_tree().quit()

# --r9cine: every real cinematic moment of round 9, one screenshot per second, with the gull's share of the picture width measured (--only=a,b)
func r9cine():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	main._reveal_specials()
	var ids = ["drinks3", "meteor", "sun", "skybow", "all24"]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			ids = a.substr(7).split(",")
	var cc = main.scenes.cc()
	for id in ids:
		place(Vector3(-4.0, 40.0, 30.0), Vector3(-4.0, 40.0, 0.0), 6.0)
		p.mode = 0
		await real(0.5)
		GS.cine_seen[id] = true
		if main.menus.paused:
			main.menus.set_paused(false)
		main.scenes.cinema(id, {})
		var t0 = GS.msec()
		var k = 0
		var worst = 0.0
		var nearest = 999.0
		await real(0.3)
		while main.scenes.cine_busy or GS.msec() - t0 < 1500:
			await real(1.0)
			await shot("r9c_%s_%02d" % [id, k])
			var cam = get_viewport().get_camera_3d()
			var cv = cc.screen_cover(cam, p.gull)
			if main.scenes.cine_busy:
				worst = max(worst, cv["w"])
				nearest = min(nearest, cv["near"])
			say("[R9] %s t=%02d gull covers %d%% of the width at x=%.2f y=%.2f, camera %.1f m away" % [id, k, int(cv["w"] * 100.0), cv.get("cx", -1.0), cv.get("cy", -1.0), cv["near"]])
			k += 1
			if k > 40:
				break
		var dur = (GS.msec() - t0) / 1000.0
		chk9("cinematic %s lasts 10-20 s" % id, dur >= 9.0 and dur <= 21.0, "%.1f s" % dur)
		chk9("cinematic %s never fills the picture with the gull" % id, worst <= 0.62 and nearest >= 2.6, "worst %d%% nearest %.1f m" % [int(worst * 100.0), nearest])
		await real(1.0)
	get_tree().quit()

# --r9sky: the weather (white / grey / rain clouds, rain only over the sea) and the rainbow in the sky: look at it, then catch it (7 circles x 2)
func r9sky():
	await get_tree().create_timer(1.5).timeout
	var p = main.player
	GS.gull_sense_count = 3
	main._reveal_specials()
	for t in GS.FRY_TYPES:
		GS.set_level(t, 3)
	GS.test_boost_bonus = 30.0
	var kinds = {"white": 0, "dark": 0, "rain": 0}
	var holder = main.get_node_or_null("Map/Clouds")
	if holder == null:
		holder = get_tree().get_first_node_in_group("rainbow_pair").get_parent()
	for c in holder.get_children():
		if c.has_meta("kind"):
			kinds[c.get_meta("kind")] += 1
	say("[R9] clouds: %s" % str(kinds))
	chk9("three kinds of clouds exist", kinds["white"] >= 10 and kinds["dark"] >= 3 and kinds["rain"] >= 3)
	await real(1.2)
	var bad = 0
	var wet = 0
	for c in get_tree().get_nodes_in_group("rain_cloud"):
		var gp = c.global_position
		var want = preload("res://scripts/world/sky.gd").over_sea(gp.x, gp.z, 22.0)
		var rn = c.get_meta("rain")
		if rn.emitting != want:
			bad += 1
		if rn.emitting:
			wet += 1
	chk9("every rain cloud rains exactly while it is over open sea", bad == 0, "%d raining, %d wrong" % [wet, bad])
	var rp = get_tree().get_first_node_in_group("rainbow_pair")
	chk9("the rainbow pair exists and it rains on it", rp != null and rp.raining(), "fade %.2f" % rp.fade)
	await real(14.0)
	chk9("the rainbow is visible", rp.fade > 0.95, "fade %.2f" % rp.fade)
	var wv = rp.wide_view(Vector3(0, 60, 100))
	p.input_locked = true
	view(wv["pos"], wv["look"], 55.0)
	await real(0.8)
	await shot("r9s_bow_wide")
	var ap = rp.apex()
	view(ap + Vector3(40, -25, 90), ap, 60.0)
	await real(0.5)
	await shot("r9s_bow_close")
	# rain: look at the first rain cloud from the side, a little below it
	for c in get_tree().get_nodes_in_group("rain_cloud"):
		if c.get_meta("rain").emitting:
			var gp = c.global_position
			view(gp + Vector3(90, -35, 60), gp + Vector3(0, -45, 0), 60.0)
			await real(0.8)
			await shot("r9s_rain")
			break
	# the catch
	p.input_locked = false
	GS.quests["skybow"] = "active"
	await real(1.2)
	var it = main.quest_items.get("skybow", null)
	chk9("the rainbow quest item exists", it != null)
	if it != null:
		say("[R9] rainbow at %s need %d gauge" % [str(it.global_position), int(GS.need_speed(it) * 6)])
		var r = await attempt(it, Vector3(0, 0.2, 1), 30.0, 0.0, -1.0, {"shot": "r9s_bow_rhythm"})
		var lc = main.player.snatch.last_commit
		say("[R9] rainbow -> %s commit=%s quests=%s worn=%s" % [r, str(lc), str(GS.quests.get("skybow")), str(GS.worn.keys())])
		chk9("the rainbow takes 14 judgements and can be caught", r == "ok" and lc.get("n", 0) == 14 and GS.quest_state("skybow") == "done" and GS.worn.has("skybow"), "n=%s" % str(lc.get("n", 0)))
	await real(1.0)
	GS.cine_seen.erase("skybow")
	main.scenes.cinema("skybow", {})
	var k = 0
	while main.scenes.cine_busy or k < 3:
		await real(1.0)
		await shot("r9s_cine_%02d" % k)
		k += 1
		if k > 30:
			break
	say("[R9] rainbow cinematic %d s" % k)
	await real(1.0)
	await shot("r9s_after")
	get_tree().quit()

# --r9tab: Gull Sight with the light pillars (silver / gold / diamond / rainbow) and the big emblems
func r9tab():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	main._reveal_specials()
	for t in GS.FRY_TYPES:
		GS.set_level(t, 2)
	var base = Vector3(-4.0, 30.0, 40.0)
	var types = ["red", "orange", "green", "cyan", "blue"]
	var made = []
	for i in 4:
		var f = make_star(types[i], i + 1 if i < 3 else 3, base + Vector3(-18.0 + i * 12.0, -22.0 + i * 4.0, -30.0 - i * 6.0), "STAR_EMB_%d" % i)
		made.append(f)
	var rb = make_star("pink", 4, base + Vector3(26.0, -10.0, -60.0), "STAR_EMB_RB")
	rb.revealed = true
	rb.visible = true
	rb.tier = 4
	place(base, base + Vector3(0, 0, -20), 4.0)
	p.input_locked = false
	await real(1.0)
	Input.action_press("gull_sense")
	main._open_sense()
	await real(1.3)
	await shot("r9t_tab_a")
	place(base + Vector3(0, 0, 30), base + Vector3(0, 8, -20), 3.0)
	await real(0.6)
	await shot("r9t_tab_b")
	Input.action_release("gull_sense")
	main._close_sense()
	await real(0.8)
	await shot("r9t_world")
	get_tree().quit()

# --r9trail: the caught star's trail of golden stars (slow, fast, from behind the gull)
func r9trail():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	for t in GS.FRY_TYPES:
		GS.set_level(t, 3)
	p.gull.wear("meteor")
	place(Vector3(60.0, 40.0, 150.0), Vector3(-80.0, 40.0, 110.0), 14.0)
	Input.action_press("move_forward")
	Input.action_press("dash")
	await real(5.0)
	await shot("r9r_fast_a")
	await real(1.0)
	await shot("r9r_fast_b")
	Input.action_release("dash")
	Input.action_release("move_forward")
	var gp = p.global_position
	p.input_locked = true
	var fwd = Vector3(-sin(p.yaw), 0, -cos(p.yaw))
	view(gp - fwd * 7.0 + Vector3(0, 2.5, 0), gp, 55.0)
	await real(0.6)
	await shot("r9r_behind")
	view(gp + Vector3(fwd.z, 0, -fwd.x) * 8.0 - fwd * 4.0 + Vector3(0, 1.0, 0), gp - fwd * 3.0, 50.0)
	await real(0.4)
	await shot("r9r_side")
	get_tree().quit()

# --r9quiet: the light film mode (first coffee / cocktail / ice cream / fish / cloud): the gull keeps flying, text in the middle, nothing locked
func r9quiet():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	GS.gull_sense_count = 3
	main._reveal_specials()
	main.autotest_no_cine = false
	GS.cine_seen.clear()
	place(Vector3(-4.0, 40.0, 30.0), Vector3(-4.0, 40.0, 0.0), 8.0)
	p.input_locked = false
	Input.action_press("move_forward")
	var jobs = [["drink_coffee", {}], ["drink_alcohol", {}], ["fish", {"sp": "tuna", "len": 140.0, "kg": 52.0}], ["drink_ice", {}]]
	var k = 0
	for j in jobs:
		main.queue_cine(j[0], j[1])
	var t0 = GS.msec()
	var locked_seen = false
	var slowed = false
	while GS.msec() - t0 < 45000:
		await real(1.5)
		if p.input_locked:
			locked_seen = true
		if Engine.time_scale < 0.9:
			slowed = true
		await shot("r9q_%02d" % k)
		k += 1
		if not main.hud.quiet_busy and main.hud.quiet_queue.is_empty() and main.cine_queue.is_empty() and k > 4:
			break
	Input.action_release("move_forward")
	chk9("the light film mode never locks the gull or slows time", not locked_seen and not slowed)
	chk9("all four quiet moments were shown", GS.cine_seen.has("drink_coffee") and GS.cine_seen.has("drink_alcohol") and GS.cine_seen.has("fish") and GS.cine_seen.has("drink_ice"))
	say("[R9] quiet moments done after %d shots" % k)
	get_tree().quit()

# --shotcheck: the real opening and the real ending, the share of the picture width that each gull takes and how close the camera is, every 0.8 s
func shotcheck():
	await get_tree().create_timer(1.0).timeout
	var p = main.player
	var cc = main.scenes.cc()
	var worst = {"w": 0.0, "near": 99.0}
	var tag = "opening"
	var run = [true]
	var sampler = func():
		var tt0 = GS.msec()
		var n = 0
		while run[0]:
			await real(0.8)
			var cam = get_viewport().get_camera_3d()
			if cam == null or not main.story.active or main.story.cam == null:
				continue
			for pair in [["you", p.gull], ["bro", main.bro.gull]]:
				if not pair[1].is_visible_in_tree():
					continue
				var cv = cc.approx_cover(cam, pair[1])
				var close = cv["near"] < 2.4 and cv["w"] > 0.3
				if cv["w"] > 0.62 or close:
					say("[R9] %s t=%03d %s covers %d%% camera %.1f m  <-- too close" % [tag, int((GS.msec() - tt0) / 1000.0), pair[0], int(cv["w"] * 100.0), cv["near"]])
					worst["w"] = max(worst["w"], cv["w"])
					worst["near"] = min(worst["near"], cv["near"])
			n += 1
	sampler.call()
	main.scenes.opening()
	for i in 46:
		await real(2.5)
		if main.story.hold["on"]:
			Input.action_press("interact")
		if not main.story.active and i > 8:
			break
	Input.action_release("interact")
	run[0] = false
	chk9("the opening never puts a gull in the lens", worst["w"] <= 0.62 and worst["near"] >= 2.4, "worst %d%% %.1f m" % [int(worst["w"] * 100.0), worst["near"]])
	get_tree().quit()
