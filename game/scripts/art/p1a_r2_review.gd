extends "res://scripts/art/p1a_review.gd"
## Review 2 only. Paused native island; no gameplay state or save mutations.
var actor
var player
var mask_material: ShaderMaterial

func run(main, _output):
	process_mode = Node.PROCESS_MODE_ALWAYS
	assert(OS.get_user_data_dir().replace("\\", "/").contains("/art_src/p1a_review2/runtime/"))
	var iteration = "1"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--art-iteration="):
			iteration = arg.get_slice("=", 1)
	folder = ProjectSettings.globalize_path("res://../art_src/p1a_review2/iteration_" + iteration + "/")
	if "--joints-only" in OS.get_cmdline_user_args():folder += "joints_valid/"
	DirAccess.make_dir_recursive_absolute(folder)
	get_tree().paused = true
	Engine.max_fps = 30
	get_window().size = Vector2i(960, 540)
	get_viewport().scaling_3d_scale = 1.0
	for child in main.get_children():
		if child is CanvasLayer:
			child.visible = false
		if child.get_script() != null and child.get_script().resource_path.ends_with("perf_governor.gd"):
			governor = child
	var deadline = Time.get_ticks_msec() + 30000
	while main.find_children("*", "MultiMeshInstance3D", true, false).size() < 4:
		await get_tree().process_frame
		assert(Time.get_ticks_msec() < deadline)
	camera = Camera3D.new()
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(camera)
	camera.make_current()
	camera.fov = 44
	player = main.player
	actor = player.gull
	assert(actor.authored)
	player.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	player.rotation = Vector3.ZERO
	player.visual_root.rotation = Vector3.ZERO
	player.visual_root.position = Vector3.ZERO
	actor.scale = Vector3.ONE
	actor.strip_all()
	main.bro.visible = false
	report["asset"] = counts(actor)
	report["governor"] = governor.level
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	if iteration != "2":
		await colour_checks(main)
	if not "--colour-only" in OS.get_cmdline_user_args():
		await shape_checks(main)
	var file = FileAccess.open(folder + "metrics.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("[P1A R2] capture complete: ", folder)
	get_tree().quit()

func shot(name_):
	for i in 6:
		await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	assert(img.get_width() <= 960 and img.get_height() <= 540)
	assert(img.save_png(folder + name_ + ".png") == OK)

func colour_checks(main):
	pose_gull(actor, "glide")
	# The mask is diagnostic only, never attached in normal play. Magenta marks
	# cream body/chest/head regions facing the sun at N.L > .5; green the remainder.
	# Eyes, beak, wings, outlines and background are excluded from sampling.
	mask_material = ShaderMaterial.new()
	mask_material.shader = Shader.new()
	mask_material.shader.code = """shader_type spatial;
render_mode unshaded, cull_back, fog_disabled;
uniform vec3 sun_view;
void fragment() {
 float region = floor(UV.x * 7.0 + .5);
 bool body = region == 1.0 || region == 2.0;
 ALBEDO = body ? (dot(normalize(NORMAL), sun_view) > .5 ? vec3(1,0,1) : vec3(0,1,0)) : vec3(0);
}
"""
	for config in [["colour_noon_3m", 0.0, 3.0, Vector3(30,8,100), Vector3(3,1.3,.3)],
		["colour_golden_15m", .55, 15.0, Vector3(-9.5,5.8,-1), Vector3(3,9,5)]]:
		mood(main, config[1])
		player.global_position = config[3]
		var target = player.global_position + Vector3(0,.02,-.10)
		camera.position = target + config[4].normalized() * config[2]
		camera.look_at(target)
		await shot(config[0])
		mask_material.set_shader_parameter("sun_view", (camera.global_basis.inverse() * main.world["sun"].global_basis.z).normalized())
		for mi in actor.authored_parts.values():
			mi.material_override = mask_material
		await shot(config[0] + "_mask")
		for mi in actor.authored_parts.values():
			mi.material_override = Art.material()
	report["colour_mask"] = "UV regions 1/2; visible sun-facing N.L > .5, magenta, all other body green. Pixel measurement offline; self-shadow may be included."

func set_pose(g, values):
	g.cur = {"a":float(values[0]), "e":float(values[1]), "s":float(values[2]), "legs":float(values[3])}
	g.pose("glide", 0.0, false, 0.0)

func shape_checks(main):
	var old = Gull.new()
	old.plain = true
	old.authored_path = "res://assets/models/missing_r2.glb"
	player.visual_root.add_child(old)
	old.build()
	old.visible = false
	report["before"] = counts(old)
	report["pairs"] = []
	mood(main, 0.0)
	var views = [] if "--joints-only" in OS.get_cmdline_user_args() else [["flight", Vector3(1.8,1.2,-3), "glide"], ["perch",Vector3(2,.7,-3),"ground"]]
	pose_gull(actor,"glide");pose_gull(old,"glide")
	for v in views:
		player.position = Vector3(-9.5,5.34 if v[0]=="perch" else 18,-1)
		pose_gull(actor,v[2]);pose_gull(old,v[2])
		var target = player.position + Vector3(0,-.04,0)
		camera.position = target + v[1].normalized()*3.0
		camera.look_at(target)
		actor.visible = false;old.visible = true
		await shot(v[0]+"_before")
		var before = await measure()
		old.visible = false;actor.visible = true
		await shot(v[0]+"_after")
		var after = await measure()
		report["pairs"].append({"view":v[0],"before":before,"after":after})
	# Existing animated angle envelope; only meshes get the authored perch fold.
	# Head/pivots/sockets are compared through a bounded 128-sample animation sweep.
	var sweep = 0
	for mode_ in ["throttle","tumble","brake","boost","ground","glide","throttle","ground"]:
		for i in 16:
			var ft = float(i)/16.0
			actor.pose(mode_,ft,false,1.0/30.0);old.pose(mode_,ft,false,1.0/30.0)
			for side in [-1.0,1.0]:
				assert(actor.shoulder[side].transform.is_equal_approx(old.shoulder[side].transform))
				assert(actor.elbow[side].transform.is_equal_approx(old.elbow[side].transform))
			assert(actor.beak_socket.position.is_equal_approx(old.beak_socket.position))
			sweep += 1
	report["animated_pivot_samples"] = sweep
	get_window().size = Vector2i(512,288)
	pose_gull(actor,"ground")
	player.position = Vector3(-9.5,5.34,-1)
	camera.position = player.position + Vector3(3,.5,.65).normalized()*3.0
	camera.look_at(player.position + Vector3(0,-.04,.02))
	await shot("perch_profile")
	player.position = Vector3(30,8,100)
	var target = player.position + Vector3(0,0,0)
	camera.position = target + Vector3(1.4,.9,-3).normalized()*3.2
	camera.look_at(target)
	for v in [["max_up",[1.50,-.35,.15,0]], ["max_down",[-1.30,.95,.15,0]],
		["flare",[.55,.2,-.35,1]], ["dive",[-.05,.55,.85,0]], ["fold_mid",[-.24,.55,0,.7]]]:
		set_pose(actor,v[1])
		var aim = target + Vector3(0,.4 if v[0]=="max_up" else (-.5 if v[0]=="max_down" else 0.0),0)
		camera.position = aim + Vector3(1.4,.9,-3).normalized()*3.7
		camera.look_at(aim)
		await shot("joint_"+v[0])
	pose_gull(actor,"glide")
	for m in [MOODS[1], MOODS[2]]:
		mood(main,m[1])
		await shot("flight_"+m[0])
	if not "--joints-only" in OS.get_cmdline_user_args():
		await palette(main)
		mood(main,0.0)
		var fry = main.world["fries"]["TUTORIAL_01"].visual.duplicate()
		actor.beak_socket.add_child(fry)
		fry.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*.42),Vector3(0,-.06,-.04))
		actor.head_lunge = .08
		pose_gull(actor,"glide")
		camera.position = player.position + Vector3(3,.8,-1.1).normalized()*3.0
		camera.look_at(player.position)
		await shot("snatch_socket")
		actor.head_lunge = 0.0
		fry.queue_free()
	await silhouette_checks()
	old.queue_free()

func silhouette_checks():
	# Isolated test viewport, same real gull builders and exact same 128px camera.
	var vp = SubViewport.new()
	vp.size = Vector2i(128,128)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var env = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("91BBD6")
	vp.add_child(env)
	var cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.65
	cam.position = Vector3(.35,1.8,-4)
	vp.add_child(cam)
	cam.look_at(Vector3(0,.16,.05))
	var black = StandardMaterial3D.new()
	black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	black.albedo_color = Color.BLACK
	report["silhouette"] = {}
	for type_ in ["old","new"]:
		var g = Gull.new()
		g.plain = true
		if type_ == "old":g.authored_path = "res://assets/models/missing_r2.glb"
		vp.add_child(g)
		g.build()
		for mi in Art.meshes(g):mi.material_override = black
		for label in ["level","up"]:
			set_pose(g,[.12,.3,0,0] if label == "level" else [.70,.12,0,0])
			var low = INF;var high = -INF
			for mi in Art.meshes(g):
				if not mi.is_visible_in_tree():continue
				for point in mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
					var x = (mi.global_transform * point).x
					low = min(low,x);high = max(high,x)
			report["silhouette"][type_+"_"+label+"_span_m"] = high-low
			for i in 6:await RenderingServer.frame_post_draw
			assert(vp.get_texture().get_image().save_png(folder+"silhouette_"+type_+"_"+label+".png")==OK)
		g.queue_free()
		await get_tree().process_frame
	vp.queue_free()
