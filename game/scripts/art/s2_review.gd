extends "res://scripts/art/p1a_review.gd"
var player
## Fixed, real-world cameras. Only opt-in --cams --art-s2; never desktop input.
const VIEWS = [
	["roof", Vector3(-19,9,-6), Vector3(-1,5,44), 64.0],
	["pier", Vector3(35,16,82), Vector3(-3,7,40), 62.0],
	["town", Vector3(-35,24,10), Vector3(-20,16,-53), 60.0],
	["flight", Vector3(25,25,67), Vector3(32,28,153), 65.0]]
const TIMES = [["morning",0.0],["afternoon",0.35],["golden",0.72],["dusk",1.0]]

func run(main, _output):
	process_mode=Node.PROCESS_MODE_ALWAYS
	assert(OS.get_user_data_dir().replace("\\","/").contains("/art_src/s2/runtime/"))
	var label="baseline"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--s2-label="):label=a.trim_prefix("--s2-label=")
	folder=ProjectSettings.globalize_path("res://../art_src/s2/"+label+"/")
	DirAccess.make_dir_recursive_absolute(folder)
	report={"label":label,"first_review_frame_ms":Time.get_ticks_msec(),"samples":[],"renderer":RenderingServer.get_current_rendering_method(),"gpu":RenderingServer.get_video_adapter_name()}
	assert(Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED)
	assert(DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS))
	report.test_window={"no_focus":true,"mouse_captured":false}
	get_tree().paused=true;Engine.max_fps=30;get_window().size=Vector2i(960,540)
	for c in main.get_children():
		if c is CanvasLayer:c.visible=false
		if c.get_script()!=null and c.get_script().resource_path.ends_with("perf_governor.gd"):governor=c
	governor.level=0;governor._apply()
	# Wait for the actual four deferred flora batches, excluding authored trees.
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
	for tm in TIMES:
		main.day.t=tm[1];main.day._apply(0)
		for v in VIEWS:
			set_view(v)
			player.position=Vector3(-11.6,5.32,-.8) if v[0]!="flight" else Vector3(25,24,72)
			pose_gull(player.gull,"ground" if v[0]!="flight" else "glide")
			await shot(v[0]+"_"+tm[0])
			var row=await measure();row["view"]=v[0];row["time"]=tm[0];row["governor"]=governor.level
			report.samples.append(row)
	# Controlled native bloom A/B: shaders frozen, no postprocess difference hidden by motion.
	set_view(VIEWS[0]);main.day.t=1;main.day._apply(0)
	main.world.env.glow_enabled=false;await shot("native_glow_off")
	main.world.env.glow_enabled=true;await shot("native_glow_on")
	if label!="baseline":
		governor.level=2;governor._apply();check_lite(main);await shot("governor_2");report.gov2=await measure()
		governor.level=3;governor._apply();check_lite(main);await shot("governor_3");report.gov3=await measure()
		governor.level=0;governor._apply()
		GS.web=true;governor._apply();check_lite(main);await shot("web_lite_native");GS.web=false;main.world.sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS;governor._apply()
		GS.sense_active=true;main.day._apply(8);await shot("gull_sense");GS.sense_active=false
		GS.ordinary_eaten=true;main.day._apply(8);await shot("ending_palette");GS.ordinary_eaten=false
		report.ending_saturation=main.day.sat;report.ending_glow=main.day.glow
		for key in GS.lv:GS.lv[key]=3
		main.day._apply(20);await shot("late_progress")
		assert(main.day.sat<=1.081 and main.day.glow<=.421)
		report.late_saturation=main.day.sat;report.late_glow=main.day.glow
		for key in GS.lv:GS.lv[key]=0
		player.position=Vector3(25,24,72);player.rotation.y=PI;pose_gull(player.gull,"glide");set_view(VIEWS[3])
		main.day._apply(20);await shot("flight_rear_dusk")
		player.rotation.y=0
		# White gull and the lightened wings at a readable distance, all four colour keys.
		for tm in TIMES:
			main.day.t=tm[1];main.day._apply(0)
			camera.position=player.position+Vector3(1.3,.65,-3);camera.look_at(player.position);camera.fov=44
			await shot("gull_"+tm[0])
		report.atmosphere={"halos":main.day.atmosphere.halos.size(),"halo_batches":main.day.atmosphere.halo_nodes.size(),"extra_layers":main.day.atmosphere.heavy_nodes.size(),"omni_lights":main.find_children("*","OmniLight3D",true,false).size()}

	FileAccess.open(folder+"metrics.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("[S2] COMPLETE ",label);get_tree().quit()

func set_view(v):
	camera.position=v[1];camera.look_at(v[2]);camera.fov=v[3];camera.reset_physics_interpolation()

func shot(label):
	# Deterministic shader phase independent of how fast the machine loads.
	Engine.time_scale=0.0
	for i in 8:await RenderingServer.frame_post_draw
	var im=get_viewport().get_texture().get_image()
	assert(im.get_width()<=960 and im.get_height()<=540)
	assert(im.save_png(folder+label+".png")==OK)

func check_lite(main):
	var a=main.day.atmosphere
	assert(not main.world.env.glow_enabled)
	assert(not a.sea_mat.get_shader_parameter("glitter_enabled"))
	for n in a.heavy_nodes:assert(not n.visible)
	for n in a.halo_nodes:assert(not n.visible)
