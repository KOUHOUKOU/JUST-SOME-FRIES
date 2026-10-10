extends Node
const Art = preload("res://scripts/art/art_loader.gd")
var folder: String
var camera: Camera3D
var report = {}
var governor
const Gull = preload("res://scripts/player/gull_visual.gd")
const Parts = preload("res://scripts/art/gull_parts.gd")
const MOODS = [["noon", 0.0], ["golden", 0.55], ["dusk", 1.0]]

func run(main, _output):
	process_mode = Node.PROCESS_MODE_ALWAYS
	assert(OS.get_user_data_dir().replace("\\", "/").contains("/art_src/p1a/runtime/"))
	var iteration = "1"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--art-iteration="):
			iteration = arg.get_slice("=", 1)
	folder = ProjectSettings.globalize_path("res://../art_src/p1a/iteration_" + iteration + "/")
	DirAccess.make_dir_recursive_absolute(folder)
	report["first_review_frame_ms"] = Time.get_ticks_msec()
	get_tree().paused = true
	Engine.max_fps = 30
	for child in main.get_children():
		if child.get_script() != null and child.get_script().resource_path.ends_with("perf_governor.gd"):
			governor = child
		if child is CanvasLayer:
			child.visible = false
	var deadline = Time.get_ticks_msec() + 30000
	while main.find_children("*", "MultiMeshInstance3D", true, false).size() < 4:
		await get_tree().process_frame
		assert(Time.get_ticks_msec() < deadline, "flora timeout")
	camera = Camera3D.new()
	add_child(camera)
	camera.make_current()
	camera.fov = 44
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	if "--p1a-details" in OS.get_cmdline_user_args():
		await details(main)
	else:
		await palette(main)
		if not "--palette-only" in OS.get_cmdline_user_args():
			await gull_review(main)
	var f = FileAccess.open(folder + ("details_metrics.json" if "--p1a-details" in OS.get_cmdline_user_args() else "metrics.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "\t"))
	print("[P1A] review complete: ", folder)
	get_tree().quit()

func mood(main, value):
	main.day.t = value
	main.day._apply(0.0)

func palette(main):
	if FileAccess.file_exists(folder + "palette_dusk.png"):
		return
	var card = Art.attach(main, "res://assets/models/p1a_palette_card.glb")
	assert(card != null)
	card.position = Vector3(-9.5, 18.0, -1)
	var sun = main.world["sun"]
	report["bias"] = {"before": [sun.shadow_bias, sun.shadow_normal_bias], "after": [0.35, 1.25]}
	for m in MOODS:
		mood(main, m[1])
		camera.position = card.position + Vector3(1.5, 2.0, 9.3)
		camera.look_at(card.position + Vector3(0, 0.5, 0))
		sun.shadow_bias = 0.35
		sun.shadow_normal_bias = 1.25
		await shot("palette_" + m[0])
	card.queue_free()
	await get_tree().process_frame

func counts(g):
	var triangles = 0
	var materials = {}
	var meshes = Art.meshes(g)
	for mi in meshes:
		materials[mi.material_override.get_instance_id()] = true
		for k in mi.mesh.get_surface_count():
			var a = mi.mesh.surface_get_arrays(k)
			triangles += a[Mesh.ARRAY_INDEX].size() / 3 if a[Mesh.ARRAY_INDEX] != null else a[Mesh.ARRAY_VERTEX].size() / 3
	return {"triangles": triangles, "mesh_parts": meshes.size(), "materials": materials.size()}

func pose_gull(g, mode_):
	var values = {"glide": [0.12, 0.3, 0.0, 0.0], "brake": [0.55, 0.2, -0.35, 1.0], "ground": [-1.2, 1.1, 0.1, 1.0]}[mode_]
	g.cur = {"a": values[0], "e": values[1], "s": values[2], "legs": values[3]}
	g.pose(mode_, 0.0, false, 0.0)

func gull_review(main):
	var p = main.player
	var g = p.gull
	assert(g.authored, "player failed authored path")
	assert(main.bro.gull.authored and main.bro.gull.bro_style)
	var old = Gull.new()
	old.plain = true
	old.authored_path = "res://assets/models/intentionally_missing_p1a.glb"
	p.visual_root.add_child(old)
	old.build()
	old.visible = false
	assert(not old.authored and old.beak_socket != null)
	assert(Parts.load_parts("res://assets/models/p0_rounded_cube.glb").is_empty())
	report["fallback_missing_and_invalid"] = "PASS"
	report["before"] = counts(old)
	report["after"] = counts(g)
	assert(report["after"]["triangles"] <= 4000 and report["after"]["mesh_parts"] <= 12 and report["after"]["materials"] == 1)
	assert(p.beak_socket == g.beak_socket)
	p.rotation = Vector3.ZERO
	p.visual_root.rotation = Vector3.ZERO
	p.visual_root.position = Vector3.ZERO
	g.scale = Vector3.ONE
	g.strip_all()
	main.bro.visible = false
	# Actual existing fry mesh, at fry.attach()'s final local transform.
	var fry = main.world["fries"]["TUTORIAL_01"].visual.duplicate()
	g.beak_socket.add_child(fry)
	fry.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.42), Vector3(0, -0.06, -0.04))
	fry.visible = false
	var old_fry = fry.duplicate()
	old.beak_socket.add_child(old_fry)
	old_fry.visible = false
	var views = [
		["side", Vector3(3, 0.45, 0.45), "glide"],
		["chase", Vector3(1.3, 0.85, 3), "glide"],
		["flare", Vector3(1.6, 0.55, -3), "brake"],
		["perch", Vector3(1.6, 0.65, -3), "ground"],
		["snatch", Vector3(3, 0.8, -1.1), "glide"],
		["portrait", Vector3(-1.4, 0.25, -3), "ground"]]
	var full = folder.contains("iteration_4")
	var moods = MOODS if full else [MOODS[0]]
	report["pairs"] = []
	for m in moods:
		mood(main, m[1])
		for v in views:
			p.global_position = Vector3(-9.5, 5.34 if v[0] in ["perch", "portrait"] else 18.0, -1)
			pose_gull(g, v[2])
			pose_gull(old, v[2])
			g.head_lunge = 0.08 if v[0] == "snatch" else 0.0
			old.head_lunge = g.head_lunge
			g.pose(v[2], 0.0, false, 0.0)
			old.pose(v[2], 0.0, false, 0.0)
			fry.visible = v[0] == "snatch"
			old_fry.visible = fry.visible
			for distance in ([3, 15, 60] if full else [3]):
				camera.fov = 44.0
				var target = p.global_position + Vector3(0, 0.02, -0.12)
				camera.position = target + v[1].normalized() * distance
				camera.look_at(target)
				var label = "%s_%s_%dm" % [v[0], m[0], distance]
				if distance == 3 and m[0] == "noon":
					g.visible = false
					old.visible = true
					await shot(label + "_before")
					var before = await measure()
					old.visible = false
					g.visible = true
					await shot(label + "_after")
					var after = await measure()
					report["pairs"].append({"view": v[0], "before": before, "after": after})
				else:
					await shot(label + "_after")
		# Capture the real existing 320x320 VN viewport and camera code.
		fry.visible = false
		g.head_lunge = 0.0
		pose_gull(g, "ground")
		main.story.vn = {"head": func(): return g, "look": {}, "shown": 0, "text": "", "tint": Color("D8CFE6")}
		if main.story.pback.get_parent() == null:
			main.add_child(main.story.pback)
		main.story.pvp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		main.story.pcam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		main.story._portrait_tick()
		main.story.pcam.reset_physics_interpolation()
		for i in 6:
			await RenderingServer.frame_post_draw
		var portrait = main.story.pvp.get_texture().get_image()
		assert(portrait.save_png(folder + "vn_" + m[0] + ".png") == OK)
		main.story.pvp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		main.story.pback.visible = false
		main.story.vn = null
	fry.queue_free()
	old.queue_free()
	await get_tree().process_frame
	# Existing pale tint, growth colour channels, socket accessories, big brother.
	p.global_position = Vector3(-9.5, 18, -1)
	camera.position = p.global_position + Vector3(1.1, 0.3, -2.0)
	camera.look_at(p.global_position)
	mood(main, 0.0)
	g.tint_pale(Gull.pale_color(1))
	g.wear("hat", true)
	g.wear("glasses", true)
	await shot("pale_accessories")
	g.unwear("hat")
	g.unwear("glasses")
	g.white_mat.albedo_color = Gull.WHITE
	g.apply_growth()
	# Drive the same existing colour properties, without mutating GS progression.
	g.tip_mats[0].albedo_color = Color("E85745").darkened(0.1)
	g.tail_mat.albedo_color = Color("E85745").lightened(0.1)
	g.chest_mat.albedo_color = Color("3D8CD9").lightened(0.5)
	g.eye_mats[0].albedo_color = Color("F277B5").darkened(0.2)
	g.beak_mat.albedo_color = Color("F1C94B")
	g._sync_authored_colours()
	pose_gull(g, "brake")
	await shot("growth_colours")
	g.apply_growth()
	main.bro.visible = true
	camera.position = main.bro.global_position + Vector3(2.0, 1.0, 4.5)
	camera.look_at(main.bro.global_position + Vector3(0, 0.3, 0))
	await shot("big_brother")
	assert(g.head.get_children().size() >= 2 and g.trail_l.get_parent() == g.elbow[-1.0])
	report["cosmetics_and_sockets"] = "PASS; colour channels, pale tint, hats/glasses, 2.3x brother, original trail parents"
	# Existing historical camera, same framing as shots/cam_b1a.png.
	p.global_position = Vector3(-9.5, 5.22, -2)
	pose_gull(g, "ground")
	camera.position = Vector3(-9.2, 6.5, 6.6)
	camera.look_at(Vector3(-8.7, 5.7, -1.0))
	camera.fov = 40
	await shot("cam_b1a_after")
	report["governor_level"] = governor.level
	report["fps_cap"] = 30
	report["rendering"] = "Desktop Compatibility, 512x288, full frozen island, same-session pairs; no web export"

func measure():
	var draws = []
	var times = []
	var cpu = []
	var gpu = []
	var last = Time.get_ticks_usec()
	for i in 30:
		await RenderingServer.frame_post_draw
		var now = Time.get_ticks_usec()
		times.append((now - last) / 1000.0)
		last = now
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(get_viewport().get_viewport_rid()))
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()))
	draws.sort(); times.sort(); cpu.sort(); gpu.sort()
	return {"draw_calls": draws[15], "frame_ms": times[15], "render_cpu_ms": cpu[15], "render_gpu_ms": gpu[15]}


func shot(name_):
	for i in 6:
		await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	if img.get_width() > 512:
		img.resize(512, roundi(img.get_height() * 512.0 / img.get_width()))
	assert(img.save_png(folder + name_ + ".png") == OK)

func details(main):
	var p = main.player
	var g = p.gull
	assert(g.authored)
	p.rotation = Vector3.ZERO
	p.visual_root.rotation = Vector3.ZERO
	p.visual_root.position = Vector3.ZERO
	p.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	g.scale = Vector3.ONE
	g.strip_all()
	main.bro.visible = false
	p.global_position = Vector3(-9.5, 5.34, -1)
	pose_gull(g, "ground")
	mood(main, 0.0)
	main.story.vn = {"head": func(): return g, "look": {}, "shown": 0, "text": "", "tint": Color("D8CFE6")}
	if main.story.pback.get_parent() == null:
		main.add_child(main.story.pback)
	main.story.pvp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	main.story.pcam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	main.story._portrait_tick()
	main.story.pcam.reset_physics_interpolation()
	for i in 8:
		await RenderingServer.frame_post_draw
	assert(main.story.pvp.get_texture().get_image().save_png(folder + "vn_noon_fixed.png") == OK)
	report["vn_noon"] = {"head": str(g.head.global_position), "camera": str(main.story.pcam.global_position), "fov": main.story.pcam.fov, "note": "Reset frozen review camera interpolation; no story/camera production change"}
	main.story.pvp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	main.story.vn = null
	main.story.pback.visible = false
	for m in MOODS:
		mood(main, m[1])
		for v in [["perch", Vector3(1.6, 2.5, -3)], ["portrait", Vector3(-1.4, 2.5, -3)]]:
			var target = p.global_position + Vector3(0, .02, -.12)
			camera.position = target + v[1].normalized() * 60.0
			camera.look_at(target)
			camera.fov = 44
			await shot(v[0] + "_" + m[0] + "_60m_clear")
	p.visible = false
	var cube = Art.attach(main, "res://assets/models/p0_rounded_cube.glb")
	cube.position = Vector3(-8.9, 4.82, -.9)
	mood(main, .55)
	camera.position = cube.position + Vector3(1.6, 1.6, 2.8)
	camera.look_at(cube.position + Vector3(0, .5, 0))
	await shot("bevel_golden_close")
	cube.queue_free()
	p.visible = true
	main.bro.visible = true
	# Historical framing and original frozen spawn, separate from matched A/B fixtures.
	p.global_position = Vector3(-11.6, 5.22, -.8)
	p.visual_root.position.y = .4 * p.visual_root.scale.x - .38
	p.rotation.y = PI
	mood(main, 0.0)
	camera.position = Vector3(-9.2, 6.5, 6.6)
	camera.look_at(Vector3(-8.7, 5.7, -1.0))
	camera.fov = 40
	await shot("cam_b1a_matched_spawn")
