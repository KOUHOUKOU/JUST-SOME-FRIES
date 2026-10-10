extends "res://scripts/art/s3_review.gd"
const Human = preload("res://scripts/npc/human_rig.gd")
var actors=[]
var label="baseline"

func run(main,_out):
	process_mode=Node.PROCESS_MODE_ALWAYS
	assert(OS.get_user_data_dir().replace("\\","/").contains("/art_src/s5/runtime/"))
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--s5-label="):label=a.trim_prefix("--s5-label=")
	folder=ProjectSettings.globalize_path("res://../art_src/s5/"+label+"/game/")
	DirAccess.make_dir_recursive_absolute(folder)
	report={"label":label,"samples":[],"people":[],"renderer":RenderingServer.get_current_rendering_method()}
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
	player=main.player;player.visible=false;main.bro.visible=false
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	var physics=[]
	for cs in main.find_children("*","CollisionShape3D",true,false):
		var sh=cs.shape;var data=[sh.get_class(),str(cs.transform)]
		for prop in sh.get_property_list():
			if prop.usage & PROPERTY_USAGE_STORAGE and not str(prop.name) in ["resource_name","resource_local_to_scene","script"]:data.append([prop.name,str(sh.get(prop.name))])
		physics.append(JSON.stringify(data))
	physics.sort();report.physics_shapes_sha256=JSON.stringify(physics).sha256_text();report.colliders=physics.size();report.anchors=str(main.world.anchors)
	# Settle only visual rigs, at a fixed clock; controllers/world stay paused.
	for h in main.find_children("*","Node3D",true,false):
		if h.get_script()==Human:
			h.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
			settle(h,h.mode);report.people.append({"position":str(h.global_position),"style":h.style})
	main.day.t=.72;main.day._apply(0)
	var cafe=Vector3(-5,1.05,7.3)
	for d in [3,15]:await capture(["cafe_people_"+str(d)+"m",cafe+Vector3(.35,.14,1).normalized()*d,cafe,55.0],"golden",0)
	var pier=Vector3(2,1.3,40)
	for d in [15,60]:await capture(["pier_crowd_"+str(d)+"m",pier+Vector3(1,.22,.5).normalized()*d,pier,55.0],"golden",0)
	await capture(["cafe_paving",Vector3(-3,8,18),Vector3(-9,.6,5),55.0],"golden",0)
	await capture(["headland",Vector3(-58,40,86),Vector3(-100,17,38),62.0],"golden",0)
	await capture(VIEWS[1],"golden",0)
	governor.level=2;governor._apply()
	await capture(["pier_crowd_60m",pier+Vector3(1,.22,.5).normalized()*60,pier,55.0],"golden",2)
	governor.level=0;governor._apply()
	var styles=JSON.parse_string(FileAccess.get_file_as_string("res://../art_src/p1b/cast_styles.json"))
	var origin=Vector3(0,65,0)
	for i in styles.size():
		var h=fixture(main,styles[i]);h.position=origin+Vector3((i-3.5)*1.1,0,0);settle(h,"idle")
	for tm in [["noon",0.0],["golden",.72],["dusk",1.0]]:
		main.day.t=tm[1];main.day._apply(0)
		await capture(["cast",origin+Vector3(.3,1.5,10),origin+Vector3(0,1.03,0),53.0],tm[0],0)
	for h in actors:h.visible=false
	if label!="baseline":await close_cast(main,styles,origin)
	main.day.t=.72;main.day._apply(0)
	var modes=["idle","walk","jog","eat","chat","fish","paint","sit","lie","wave","alarm","play","recline"]
	for batch in 4:
		for j in 4:
			var i=batch*4+j
			if i>=modes.size():break
			var h=fixture(main,styles[i%8]);h.position=origin+Vector3((j-1.5)*1.7,0,0);settle(h,modes[i])
		set_view(["modes",origin+Vector3(.8,1.9,7),origin+Vector3(0,.95,0),53.0]);await shot("modes_"+str(batch))
		for h in actors:h.visible=false
	var garment=fixture(main,{"hair_style":"bun","backpack":true,"apron":true,"vest":true,"fat":1.3,"glasses":true});garment.position=origin;settle(garment,"idle")
	for view in [["front",Vector3(1,1.2,3)],["back",Vector3(-1,1.2,-3)]]:
		set_view(["garment",origin+view[1],origin+Vector3(0,1,0),48.0]);await shot("garment_"+view[0])
	garment.visible=false
	await portraits(main,styles,origin)
	player.visible=true;player.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	player.position=Vector3(25,24,72);player.rotation=Vector3.ZERO;player.visual_root.rotation=Vector3.ZERO;pose_gull(player.gull,"glide")
	for tm in [["noon",0.0],["golden",.72],["dusk",1.0]]:
		main.day.t=tm[1];main.day._apply(0)
		set_view(["gull",player.position+Vector3(1.3,.65,-3),player.position,44.0]);await shot("gull_"+tm[0])
	FileAccess.open(folder+"metrics.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("[S5] COMPLETE ",label);get_tree().quit()

func fixture(main,st):
	var h=Human.new();main.add_child(h);h.build(st);h.set_process(false);h.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	actors.append(h);return h

func settle(h,mode_):
	h.seed_off=.25;h.t=0;h.phase=0;h.mode=mode_
	for k in 40:h._process(1.0/30.0)
	h.reset_physics_interpolation()

func portraits(main,styles,origin):
	camera.cull_mask=camera.cull_mask & ~(1<<19)
	var st=main.story;st.visible=true;st.active=true;st.page.show();st.cam=null
	if st.pback.get_parent()==null:main.add_child(st.pback)
	st.pcam.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	report.portraits=[]
	for idx in [4,3,6]:
		var h=fixture(main,styles[idx]);h.position=origin;settle(h,"idle")
		set_view(["vn",origin+Vector3(.8,1.2,3),origin+Vector3(0,1.2,0),48.0])
		# The production box and live viewport, with a review-only line, no story changes.
		var line="Portrait framing review."
		st.vn={"a":1.0,"who":["ELDER","CHILD","SUNHAT"][report.portraits.size()],"sub":"S5 visual fixture","text":line,"shown":line.length(),"head":func():return h,"tint":Color("F5C65A"),"pop":0,"look":{"yaw":PI+.25,"dist":1.65,"up":.10,"fov":34.0},"closing":false}
		st.pvp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;st._portrait_tick();st.pcam.reset_physics_interpolation();st.page.queue_redraw()
		await shot("vn_box_"+str(idx));st.pvp.get_texture().get_image().save_png(folder+"portrait_"+str(idx)+".png")
		report.portraits.append({"style":idx,"camera":str(st.pcam.global_transform),"fixture":true});h.visible=false
	st.vn=null;st.pvp.render_target_update_mode=SubViewport.UPDATE_DISABLED;st.pback.visible=false;st.visible=false;st.active=false

func close_cast(main,styles,origin):
	# Load the retained old GLB in memory. No import/copy into production assets.
	var doc=GLTFDocument.new();var state=GLTFState.new()
	assert(doc.append_from_file(ProjectSettings.globalize_path("res://../art_src/s5/baseline/game/assets/models/person_parts.glb"),state)==OK)
	var old_scene=doc.generate_scene(state);var old_parts={}
	for mi in Art.meshes(old_scene):old_parts[str(mi.name)]=mi.mesh
	Human.PersonParts.sources["s5_previous"]=old_parts;old_scene.free()
	main.day.t=.72;main.day._apply(0)
	for old in [true,false]:
		for i in 8:
			var h=Human.new();main.add_child(h)
			if old:h.authored_path="s5_previous"
			h.build(styles[i]);h.mouth.visible=old;h.set_process(false);h.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
			h.position=origin+Vector3((i-3.5)*1.1,0,0);settle(h,"idle");actors.append(h)
		set_view(["cast_close",origin+Vector3(.2,1.35,9),origin+Vector3(0,1.05,0),34.0]);await shot("cast_close_"+("previous" if old else "new"))
		for h in actors:h.visible=false
