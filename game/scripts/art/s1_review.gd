extends "res://scripts/art/p1a_review.gd"
## Bounded S1 fixture on the paused actual island. No production camera changes.
var actor
var player

func run(main, _output):
	process_mode = Node.PROCESS_MODE_ALWAYS
	assert(OS.get_user_data_dir().replace("\\", "/").contains("/art_src/s1/runtime/"))
	var iteration = "4"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--art-iteration="):iteration = arg.get_slice("=",1)
	folder=ProjectSettings.globalize_path("res://../art_src/s1/iteration_"+iteration+"/game/")
	DirAccess.make_dir_recursive_absolute(folder)
	report["first_review_frame_ms"]=Time.get_ticks_msec()
	get_tree().paused=true;Engine.max_fps=30
	get_viewport().scaling_3d_scale=1.0
	for child in main.get_children():
		if child is CanvasLayer:child.visible=false
		if child.get_script()!=null and child.get_script().resource_path.ends_with("perf_governor.gd"):governor=child
	var deadline=Time.get_ticks_msec()+30000
	while main.find_children("*","MultiMeshInstance3D",true,false).size()<4:
		await get_tree().process_frame
		assert(Time.get_ticks_msec()<deadline)
	camera=Camera3D.new();camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(camera);camera.make_current();camera.fov=44
	player=main.player;actor=player.gull;assert(actor.authored)
	player.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	player.rotation=Vector3.ZERO;player.visual_root.rotation=Vector3.ZERO;player.visual_root.position=Vector3.ZERO
	actor.scale=Vector3.ONE;actor.strip_all();main.bro.visible=false
	player.position=Vector3(30,8,100)
	report["after"]=counts(actor);report["governor"]=governor.level
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	mood(main,.55)
	pose_gull(actor,"glide");frame(Vector3(1.3,.9,3),3)
	if "--s1-preview" in OS.get_cmdline_user_args():
		await shot("preview_rear")
		pose_gull(actor,"ground");frame(Vector3(1.4,.5,-3),3);await shot("preview_perch")
		actor.wear("topper",true);actor.wear("shades",true);await shot("preview_wear")
		get_tree().quit();return
	# Rejected smooth asset, loaded directly from the project-local backup.
	var doc=GLTFDocument.new();var state=GLTFState.new()
	assert(doc.append_from_file(ProjectSettings.globalize_path("res://../art_src/s1/before/hero_gull_parts.glb"),state)==OK)
	var legacy_scene=doc.generate_scene(state);var legacy_meshes={}
	for mi in Art.meshes(legacy_scene):legacy_meshes[str(mi.name)]=mi.mesh
	var old=Gull.new();old.plain=true;player.visual_root.add_child(old);old.build()
	for n in Parts.NAMES:old.authored_parts[n].mesh=legacy_meshes[n]
	legacy_scene.free();old.visible=false;report["before"]=counts(old)
	report["pairs"]=[]
	if "--s1-finish" in OS.get_cmdline_user_args():
		folder+="corrected/";DirAccess.make_dir_recursive_absolute(folder)
		# Camera-only evidence repair: show a real roof perch, not ground pose aloft.
		# These A/B samples run after all Blender/full-test jobs have finished.
		for view in [["flight_dusk",Vector3(1.3,.7,3),"glide"],["perch_dusk",Vector3(1.4,.7,-3),"ground"]]:
			mood(main,1.0)
			if view[2]=="ground":
				var query=PhysicsRayQueryParameters3D.create(Vector3(-11.6,40,-.8),Vector3(-11.6,-2,-.8))
				query.exclude=[player.get_rid()]
				var hit=player.get_world_3d().direct_space_state.intersect_ray(query)
				assert(not hit.is_empty());player.global_position=hit.position+Vector3(0,.52,0)
				report["perch_surface"]=str(hit.position)
			pose_gull(actor,view[2]);pose_gull(old,view[2]);frame(view[1],3)
			actor.visible=false;old.visible=true;await shot(view[0]+"_before");var before=await measure()
			actor.visible=true;old.visible=false;await shot(view[0]+"_after");var after=await measure()
			report["pairs"].append({"view":view[0],"before":before,"after":after})
		old.free();player.position=Vector3(30,8,100);frame(Vector3(1.5,.6,-3),4.0)
		actor.cur={"a":1.5,"e":-.35,"s":.15,"legs":0.0};actor.pose("glide",0.0,false,0.0);await shot("wings_up_uncropped")
		var result=FileAccess.open(folder+"metrics.json",FileAccess.WRITE);result.store_string(JSON.stringify(report,"\t"))
		print("[S1 FINISH] COMPLETE ",folder);get_tree().quit();return
	for view in [["flight_rear",Vector3(1.3,.9,3),"glide"],["perch",Vector3(1.4,.5,-3),"ground"]]:
		pose_gull(actor,view[2]);pose_gull(old,view[2]);frame(view[1],3)
		get_window().size=Vector2i(960,540)
		actor.visible=false;old.visible=true;await shot(view[0]+"_before")
		var before=await measure()
		actor.visible=true;old.visible=false;await shot(view[0]+"_after")
		var after=await measure()
		report["pairs"].append({"view":view[0],"before":before,"after":after})
	old.free();get_window().size=Vector2i(512,288)
	pose_gull(actor,"glide");frame(Vector3(3,.6,.3),3);await shot("flight_side")
	for config in [["noon_3m",0.0,3.0],["golden_15m",.55,15.0],["dusk_60m",1.0,60.0],["dusk_3m",1.0,3.0]]:
		mood(main,config[1]);frame(Vector3(1.3,.65,-3),config[2]);await shot(config[0])
	mood(main,.55);frame(Vector3(1.8,.6,-3),3)
	var fry=main.world["fries"]["TUTORIAL_01"].visual.duplicate()
	actor.beak_socket.add_child(fry)
	fry.transform=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*.42),Vector3(0,-.06,-.04))
	actor.head_lunge=.08;actor.pose("glide",0.0,false,0.0);await shot("snatch_socket")
	fry.free();actor.head_lunge=0;pose_gull(actor,"ground")
	await portrait(main,actor,"vn_you")
	for config in [["straw_glasses",["hat","glasses","hawaii"]],["topper_shades",["topper","shades","coat","necklace"]],["sailor_scarf",["sailor","scarf"]],["beret_bowtie",["beret","bowtie","pipe","stripes"]]]:
		actor.strip_all()
		for item in config[1]:actor.wear(item,true)
		frame(Vector3(1.2,.5,-3),3);await shot(config[0])
	actor.strip_all()
	main.bro.visible=true
	camera.position=main.bro.global_position+Vector3(3,1.5,-6)
	camera.look_at(main.bro.global_position+Vector3(0,.4,0));await shot("big_bro_23x")
	await portrait(main,main.bro.gull,"vn_big_bro")
	main.bro.visible=false
	frame(Vector3(1.5,.6,-3),3)
	for config in [["wings_up",1.5,-.35,.15,0.0],["wings_down",-1.3,.95,.15,0.0],["dive",-.05,.55,.85,0.0]]:
		actor.cur={"a":config[1],"e":config[2],"s":config[3],"legs":config[4]}
		actor.pose("glide",0.0,false,0.0);await shot(config[0])
	var f=FileAccess.open(folder+"metrics.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"))
	print("[S1 REVIEW] COMPLETE ",folder);get_tree().quit()

func frame(direction, distance):
	var target=player.position+Vector3(0,.14,-.05)
	camera.position=target+direction.normalized()*distance;camera.look_at(target)

func shot(name_):
	for i in 6:await RenderingServer.frame_post_draw
	var im=get_viewport().get_texture().get_image()
	assert(im.get_width()<=960 and im.get_height()<=540)
	assert(im.save_png(folder+name_+".png")==OK)

func portrait(main, gull, label):
	main.story.vn={"head":func():return gull,"look":{},"shown":0,"text":"","tint":Color("D8CFE6")}
	if main.story.pback.get_parent()==null:main.add_child(main.story.pback)
	main.story.pvp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	main.story.pcam.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	main.story._portrait_tick();main.story.pcam.reset_physics_interpolation()
	for i in 6:await RenderingServer.frame_post_draw
	main.story.pvp.get_texture().get_image().save_png(folder+label+".png")
	main.story.pvp.render_target_update_mode=SubViewport.UPDATE_DISABLED
	main.story.pback.visible=false;main.story.vn=null
