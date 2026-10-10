extends Node
## Identical dev-only review harness for ORIGINAL and FINAL. No gameplay changes.
var camera
var folder
var report={"samples":[]}
func run(main):
	process_mode=Node.PROCESS_MODE_ALWAYS
	var root=""
	var label="final"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--s4-root="):root=a.trim_prefix("--s4-root=")
		if a.begins_with("--s4-label="):label=a.trim_prefix("--s4-label=")
	assert(root!="" and OS.get_user_data_dir().replace("\\","/").contains("/art_src/final/runtime/"))
	folder=root+"/art_src/final/"+label+"/"
	DirAccess.make_dir_recursive_absolute(folder)
	get_tree().paused=true;Engine.max_fps=30;get_window().size=Vector2i(960,540)
	assert(Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS))
	report.test_window={"no_focus":true,"mouse_captured":false}
	for c in main.get_children():
		if c is CanvasLayer:c.visible=false
		if c.get_script()!=null and c.get_script().resource_path.ends_with("perf_governor.gd"):
			c.level=0;c._apply()
	for i in 90:await get_tree().process_frame
	camera=Camera3D.new();add_child(camera);camera.make_current();camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	var p=main.player
	p.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	p.rotation=Vector3.ZERO;p.visual_root.rotation=Vector3.ZERO;p.visual_root.position=Vector3.ZERO
	main.bro.visible=false
	for h in main.find_children("*","Node3D",true,false):
		if h.get_script()!=null and h.get_script().resource_path.ends_with("human_rig.gd"):
			h.seed_off=.25;h.t=0;h.phase=0;h.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
			for i in 40:h._process(1.0/30.0)
			h.reset_physics_interpolation()
	main.day.t=.72;main.day._apply(0);Engine.time_scale=0
	var views=JSON.parse_string(FileAccess.get_file_as_string(root+"/art_src/final/cameras.json"))
	var details="--s4-details" in OS.get_cmdline_user_args()
	if details:report=JSON.parse_string(FileAccess.get_file_as_string(folder+"metrics.json"));report.samples=report.samples.filter(func(r):return not r.view in ["gull_fry","fry_table"])
	var held=null
	for v in views:
		if details and not v[0] in ["gull_fry","fry_table"]:continue
		p.visible=v[0] in ["01_opening_roof","17_sea_low","gull_fry"]
		p.position=Vector3(-11.6,5.32,-.8);p.rotation=Vector3.ZERO
		for i in 45:p.gull.pose("ground",.7,false,1.0/30.0)
		if v[0]=="17_sea_low":
			p.position=Vector3(29.5,2.5,116);p.rotation.y=PI
			for i in 45:p.gull.pose("glide",.7,false,1.0/30.0)
		if v[0]=="gull_fry":
			for i in 45:p.gull.pose("glide",.7,false,1.0/30.0)
			# Use each version's real ordinary-fry visual at the unchanged beak socket.
			held=main.ordinary.visual.duplicate();p.gull.beak_socket.add_child(held)
			held.position=Vector3(0,.02,0);held.rotation=Vector3(-.55,0,0);held.scale=Vector3.ONE*.42
		p.reset_physics_interpolation()
		set_view(v)
		await shot(v[0])
		report.samples.append({"view":v[0],"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"tris":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"camera":v,"golden_t":.72,"governor":0})
		if held!=null:held.free();held=null
	# The game's real VN SubViewport and frame, identical elder and camera parameters.
	p.visible=false
	camera.cull_mask=camera.cull_mask & ~(1<<19)
	var st=main.story;st.visible=true;st.active=true;st.page.show();st.cam=null
	if st.pback.get_parent()==null:main.add_child(st.pback)
	st.pcam.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	var elder=main.elder.rig
	st.vn={"a":1.0,"who":"THE OLD MAN","sub":"","text":"...","shown":3,"head":func():return elder,"tint":Color("F5C65A"),"pop":0,"look":{"yaw":PI+.25,"dist":1.65,"up":.10,"fov":34.0},"closing":false}
	st.pvp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;st._portrait_tick();st.pcam.reset_physics_interpolation();st.page.queue_redraw()
	await shot("vn_portrait")
	st.pvp.render_target_update_mode=SubViewport.UPDATE_DISABLED
	report.label=label;report.engine=Engine.get_version_info();report.fixture_note="Frozen live world; gull holding fry and VN are staged review poses."
	FileAccess.open(folder+"metrics.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("[S4] COMPLETE ",label)
	get_tree().quit()
func set_view(v):
	camera.position=Vector3(v[1][0],v[1][1],v[1][2]);camera.look_at(Vector3(v[2][0],v[2][1],v[2][2]));camera.fov=v[3];camera.reset_physics_interpolation()
func shot(label):
	for i in 8:await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(folder+label+".png")==OK)
