extends "res://scripts/art/s2_review.gd"
## Real scene / same S2 cameras plus near/middle/far cafe and priority ground views.
func run(main, _output):
	process_mode=Node.PROCESS_MODE_ALWAYS
	var phase="s3b" if "--art-s3b" in OS.get_cmdline_user_args() else "s3"
	assert(OS.get_user_data_dir().replace("\\","/").contains("/art_src/"+phase+"/runtime/"))
	var label="baseline"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--s3-label="):label=a.trim_prefix("--s3-label=")
	folder=ProjectSettings.globalize_path("res://../art_src/"+phase+"/"+label+"/")
	DirAccess.make_dir_recursive_absolute(folder)
	report={"label":label,"samples":[],"renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name()}
	assert(Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED)
	assert(DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS))
	report.test_window={"no_focus":true,"mouse_captured":false}
	get_tree().paused=true;Engine.max_fps=30;get_window().size=Vector2i(960,540)
	for c in main.get_children():
		if c is CanvasLayer:c.visible=false
		if c.get_script()!=null and c.get_script().resource_path.ends_with("perf_governor.gd"):governor=c
	governor.level=0;governor._apply()
	var deadline=Time.get_ticks_msec()+30000
	while main.find_children("*","MultiMeshInstance3D",true,false).filter(func(n):return n.visibility_range_end>0).size()<4:
		await get_tree().process_frame
		assert(Time.get_ticks_msec()<deadline)
	camera=Camera3D.new();add_child(camera);camera.make_current()
	camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	player=main.player;player.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	player.rotation=Vector3.ZERO;player.visual_root.rotation=Vector3.ZERO;player.visual_root.position=Vector3.ZERO
	main.bro.visible=false
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	report.colliders=main.find_children("*","CollisionShape3D",true,false).size()
	var physics=[]
	for cs in main.find_children("*","CollisionShape3D",true,false):
		var sh=cs.shape
		var data=[sh.get_class(),str(cs.transform)]
		for prop in sh.get_property_list():
			if prop.usage & PROPERTY_USAGE_STORAGE and not str(prop.name) in ["resource_name","resource_local_to_scene","script"]:data.append([prop.name,str(sh.get(prop.name))])
		physics.append(JSON.stringify(data))
	physics.sort();report.physics_shapes_sha256=JSON.stringify(physics).sha256_text()
	report.kits_used=preload("res://scripts/art/kenney_parts.gd").used
	report.anchors=str(main.world.anchors)
	for tm in [["golden",.72],["dusk",1.0]]:
		main.day.t=tm[1];main.day._apply(0)
		for v in VIEWS:
			player.position=Vector3(-11.6,5.32,-.8) if v[0]!="flight" else Vector3(25,24,72)
			pose_gull(player.gull,"ground" if v[0]!="flight" else "glide")
			await capture(v,tm[0],0)
	main.day.t=.72;main.day._apply(0)
	var target=Vector3(-11.5,.85,6.2)
	for d in [3,15,60]:await capture(["cafe_"+str(d)+"m",target+Vector3(1,.8,1.4).normalized()*d,target,55.0],"golden",0)
	await capture(["beach",Vector3(67,16,53),Vector3(44,2,24),62.0],"golden",0)
	await capture(["headland",Vector3(-58,40,86),Vector3(-100,17,38),62.0],"golden",0)
	# Same measurements at reduced governor quality; absolute CPU/GPU milliseconds.
	governor.level=2;governor._apply();check_lite(main)
	await capture(VIEWS[1],"golden",2)
	for d in [3,15,60]:await capture(["cafe_"+str(d)+"m",target+Vector3(1,.8,1.4).normalized()*d,target,55.0],"golden",2,false)
	if phase=="s3b":
		governor.level=0;governor._apply()
		player.position=Vector3(25,24,72);pose_gull(player.gull,"glide")
		for tm in [["noon",0.0],["golden",.72],["dusk",1.0]]:
			main.day.t=tm[1];main.day._apply(0)
			set_view(["gull",player.position+Vector3(1.3,.65,-3),player.position,44.0])
			await shot("gull_"+tm[0])
	FileAccess.open(folder+"metrics.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("[S3] COMPLETE ",label);get_tree().quit()

func capture(v, time, quality, save_image=true):
	set_view(v)
	if save_image:await shot(v[0]+"_"+time+("_gov2" if quality==2 else ""))
	else:
		for i in 8:await RenderingServer.frame_post_draw
	var row=await measure();row["view"]=v[0];row["time"]=time;row["governor"]=quality
	row["triangles"]=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	row["camera"]=[str(v[1]),str(v[2]),v[3]]
	report.samples.append(row)
