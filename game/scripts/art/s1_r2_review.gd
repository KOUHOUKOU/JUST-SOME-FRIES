extends "res://scripts/art/s1_review.gd"
## Review 8, round 2. Existing island, isolated saves, sequential bounded captures.
func run(main,_output):
	process_mode=Node.PROCESS_MODE_ALWAYS
	assert(OS.get_user_data_dir().replace("\\","/").contains("/art_src/s1/round_2/runtime/"))
	folder=ProjectSettings.globalize_path("res://../art_src/s1/round_2/game/")
	DirAccess.make_dir_recursive_absolute(folder)
	report.first_review_frame_ms=Time.get_ticks_msec()
	get_tree().paused=true;Engine.max_fps=30;get_viewport().scaling_3d_scale=1
	for child in main.get_children():
		if child is CanvasLayer:child.visible=false
		if child.get_script()!=null and child.get_script().resource_path.ends_with("perf_governor.gd"):governor=child
	var deadline=Time.get_ticks_msec()+30000
	while main.find_children("*","MultiMeshInstance3D",true,false).size()<4:
		await get_tree().process_frame
		assert(Time.get_ticks_msec()<deadline)
	camera=Camera3D.new();add_child(camera);camera.make_current();camera.fov=44
	camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.cull_mask &= ~(1<<19)
	player=main.player;actor=player.gull;assert(actor.authored)
	player.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	player.rotation=Vector3.ZERO;player.visual_root.rotation=Vector3.ZERO;player.visual_root.position=Vector3.ZERO
	actor.scale=Vector3.ONE;actor.strip_all();main.bro.visible=false
	player.position=Vector3(30,8,100)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	var doc=GLTFDocument.new();var state=GLTFState.new()
	assert(doc.append_from_file(ProjectSettings.globalize_path("res://../art_src/s1/round_2/before/hero_gull_parts.glb"),state)==OK)
	var old_scene=doc.generate_scene(state);var meshes={}
	for mi in Art.meshes(old_scene):meshes[str(mi.name)]=mi.mesh
	var old=Gull.new();old.plain=true;player.visual_root.add_child(old);old.build()
	for n in Parts.NAMES:
		old.authored_parts[n].mesh=meshes[n];old.authored_parts[n].material_override=Art.material()
	old_scene.free();old.visible=false
	report.before=counts(old);report.after=counts(actor);report.governor=governor.level
	if "--s1-color" in OS.get_cmdline_user_args():
		get_window().size=Vector2i(960,540)
		pose_gull(actor,"glide");pose_gull(old,"glide")
		for m in MOODS:
			mood(main,m[1]);frame(Vector3(1.3,.65,-3),3)
			actor.visible=false;old.visible=true;await shot(m[0]+"_before")
			actor.visible=true;old.visible=false;await shot(m[0]+"_after")
			await body_mask(actor,m[0]+"_body_mask")
		old.free();write_report("color_metrics");get_tree().quit();return
	report.pairs=[]
	pose_gull(actor,"glide");pose_gull(old,"glide");mood(main,1);frame(Vector3(1.3,.9,3),3)
	actor.visible=false;old.visible=true;await shot("performance_before");var before=await measure()
	actor.visible=true;old.visible=false;await shot("performance_after");var after=await measure()
	report.pairs.append({"view":"flight_rear_512","before":before,"after":after})
	old.free()
	get_window().size=Vector2i(960,540);mood(main,1)
	# Exact existing cafe roof mesh: world_builder._cafe, centre y4.65 + .15.
	# Paused review physics has not flushed batched colliders; do not use its
	# stale ground-only ray result as a roof height (draft capture retained).
	var hit={"position":Vector3(-11.6,4.8,-.8)}
	place_on_roof(hit.position);report.perch_surface=str(hit.position)
	pose_gull(actor,"ground");frame(Vector3(1.4,.7,-3),3);await shot("perch")
	frame(Vector3(3,.5,.1),3);await shot("perch_side")
	player.position=Vector3(30,8,100);pose_gull(actor,"glide")
	for v in [["flight_rear",Vector3(1.3,.9,3)],["flight_side",Vector3(3,.5,.3)]]:
		frame(v[1],3);await shot(v[0])
	get_window().size=Vector2i(960,540)
	for dist in [15,60]:
		frame(Vector3(1.3,.65,-3),dist);await shot("distance_"+str(dist))
	frame(Vector3(1.5,.6,-3),4)
	for config in [["up",1.5,-.35,.15,0.0],["down",-1.3,.95,.15,0.0],["dive",-.05,.55,.85,0.0]]:
		actor.cur={"a":config[1],"e":config[2],"s":config[3],"legs":config[4]};actor.pose("glide",0,false,0);await shot(config[0])
	pose_gull(actor,"ground");await portrait(main,actor,"vn_you")
	actor.wear("topper",true);actor.wear("shades",true);frame(Vector3(1.3,.7,-3),3);await shot("topper_shades")
	await portrait(main,actor,"vn_you_hat");actor.strip_all()
	main.bro.visible=true;await portrait(main,main.bro.gull,"vn_big_bro")
	camera.position=main.bro.global_position+main.bro.global_transform.basis*Vector3(2,1.0,-4);camera.look_at(main.bro.global_position+Vector3(0,.4,0));await shot("bro_necklace")
	main.bro.visible=false
	place_on_roof(hit.position)
	# Existing shoulder/elbow DOFs; asymmetric raised wings echo the cover pose.
	actor.cur={"a":.8,"e":.6,"s":0.0,"legs":1.0};actor.pose("glide",0,false,0)
	actor.shoulder[1.0].rotation.z=1.00;actor.elbow[1.0].rotation.z=-.35
	actor.shoulder[-1.0].rotation.z=-.48;actor.elbow[-1.0].rotation.z=.6
	var fry=Art.instantiate("res://assets/models/fry_ordinary.glb");assert(fry!=null)
	actor.beak_socket.add_child(fry);fry.scale=Vector3.ONE*.42;fry.position=Vector3(0,.08,.018);fry.rotation.x=-.55
	get_window().size=Vector2i(960,540);frame(Vector3(1.4,.75,-3),3.6);await shot("cover_pose")
	frame(Vector3(1.4,.75,3),3.6);await shot("cover_rear")
	fry.free();write_report("metrics");print("[S1 R2 REVIEW] COMPLETE");get_tree().quit()

func body_mask(g,label):
	var previous={};var layer=camera.cull_mask
	camera.cull_mask=1<<18
	var white=StandardMaterial3D.new();white.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;white.albedo_color=Color.WHITE
	var black=white.duplicate();black.albedo_color=Color.BLACK
	for n in g.authored_parts:
		var mi=g.authored_parts[n];previous[n]=[mi.layers,mi.material_override]
		mi.layers=1<<18;mi.material_override=white if n in ["Body","Chest","Head"] else black
	await shot(label)
	for n in previous:g.authored_parts[n].layers=previous[n][0];g.authored_parts[n].material_override=previous[n][1]
	camera.cull_mask=layer

func write_report(label):
	FileAccess.open(folder+label+".json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))

func place_on_roof(surface):
	player.global_position=surface+Vector3(0,.6,0)
	var low=INF
	var feet=actor.authored_parts.Legs
	for vertex in feet.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		low=minf(low,(feet.global_transform*vertex).y)
	player.global_position.y+=surface.y-low
	var placed_low=INF
	for vertex in feet.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		placed_low=minf(placed_low,(feet.global_transform*vertex).y)
	report.foot_contact_error_m=placed_low-surface.y

func portrait(main,gull,label):
	await super.portrait(main,gull,label)
	var low=Vector2(INF,INF);var high=Vector2(-INF,-INF)
	for mi in Art.meshes(gull.head):
		if not mi.is_visible_in_tree():continue
		for vertex in mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			var p=main.story.pcam.unproject_position(mi.global_transform*vertex)
			low=low.min(p);high=high.max(p)
	if not report.has("portrait_bounds"):report.portrait_bounds={}
	report.portrait_bounds[label]={"min":[low.x,low.y],"max":[high.x,high.y],"viewport":[main.story.pvp.size.x,main.story.pvp.size.y]}
