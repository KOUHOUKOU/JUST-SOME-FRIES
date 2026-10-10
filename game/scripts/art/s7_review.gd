extends "res://scripts/art/s3_review.gd"
## S7 fixed whole-island audit, driven only by --cams --art-s7.
const Human=preload("res://scripts/npc/human_rig.gd")
func run(main,_out):
	process_mode=Node.PROCESS_MODE_ALWAYS
	assert(OS.get_user_data_dir().replace("\\","/").contains("/art_src/s7/runtime/"))
	var label="baseline"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--s7-label="):label=a.trim_prefix("--s7-label=")
	folder=ProjectSettings.globalize_path("res://../art_src/s7/"+label+"/game/")
	DirAccess.make_dir_recursive_absolute(folder)
	report={"label":label,"samples":[],"people":[],"renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name()}
	assert(Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS))
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
	camera=Camera3D.new();add_child(camera);camera.make_current();camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	player=main.player;player.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	player.rotation=Vector3.ZERO;player.visual_root.rotation=Vector3.ZERO;player.visual_root.position=Vector3.ZERO
	main.bro.visible=false
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	var physics=[]
	for cs in main.find_children("*","CollisionShape3D",true,false):
		var sh=cs.shape;var data=[sh.get_class(),str(cs.global_transform)]
		for prop in sh.get_property_list():
			if prop.usage & PROPERTY_USAGE_STORAGE and not str(prop.name) in ["resource_name","resource_local_to_scene","script"]:data.append([prop.name,str(sh.get(prop.name))])
		physics.append(JSON.stringify(data))
	physics.sort();report.physics_shapes_sha256=JSON.stringify(physics).sha256_text();report.colliders=physics.size();report.anchors=str(main.world.anchors);report.thermals=str(main.world.air_zones)
	for h in main.find_children("*","Node3D",true,false):
		if h.get_script()==Human:
			h.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
			h.seed_off=.25;h.t=0;h.phase=0
			for k in 40:h._process(1.0/30.0)
			h.reset_physics_interpolation();report.people.append({"position":str(h.global_position),"style":h.style})
	main.day.t=.72;main.day._apply(0)
	var views=JSON.parse_string(FileAccess.get_file_as_string("res://../art_src/s7/cams.json"))
	for v in views:
		player.visible=v[0] in ["01_opening_roof","17_sea_low","18_sea_high","19_fast_rush","20_ending_floor","21_opening_close"]
		player.position=Vector3(-11.6,5.32,-.8);pose_gull(player.gull,"ground")
		player.rotation=Vector3.ZERO
		if v[0] in ["17_sea_low","18_sea_high","19_fast_rush"]:
			var eye=Vector3(v[1][0],v[1][1],v[1][2]);var target=Vector3(v[2][0],v[2][1],v[2][2])
			player.position=eye+(target-eye).normalized()*5-Vector3(0,.6,0)
			player.rotation.y=atan2(target.x-eye.x,target.z-eye.z)+PI
			pose_gull(player.gull,"glide")
			if v[0]=="19_fast_rush":
				player.speed=24.0;player.velocity=(target-eye).normalized()*24.0
				player.gull.pose("boost",0.0,false,0.0)
				report.rush={"speed_mps":24.0,"fixed_pose":true,"not_a_motion_benchmark":true}
		elif v[0]=="20_ending_floor":player.position=Vector3(-9.2,.42,5.0)
		if v[0]=="21_opening_close":main.bro.visible=true
		player.reset_physics_interpolation()
		await capture([v[0],Vector3(v[1][0],v[1][1],v[1][2]),Vector3(v[2][0],v[2][1],v[2][2]),v[3]],"golden",0)
		main.bro.visible=false
	governor.level=2;governor._apply();check_lite(main)
	for idx in [0,3,4,5]:
		var v=views[idx]
		await capture([v[0],Vector3(v[1][0],v[1][1],v[1][2]),Vector3(v[2][0],v[2][1],v[2][2]),v[3]],"golden",2,false)
	governor.level=3;governor._apply();check_lite(main)
	assert(not main.world.sun.shadow_enabled)
	governor.level=0;governor._apply()
	GS.web=true;governor._apply();check_lite(main);GS.web=false
	report.governor={"forced_2_3_and_web_lite":"PASS","auto_adjustment":"disabled by existing <=30fps/paused guard"}
	FileAccess.open(folder+"metrics.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("[S7] COMPLETE ",label);get_tree().quit()
