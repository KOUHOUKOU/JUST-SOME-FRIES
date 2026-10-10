extends "res://scripts/art/p2_review.gd"
## Opt-in, isolated Review 6 fixtures. No production story or world changes.
var origin=Vector3(30,18,140)

func run(main,_output):
	process_mode=Node.PROCESS_MODE_ALWAYS
	assert(OS.get_user_data_dir().replace("\\","/").contains("/art_src/p2_review2/runtime/"))
	var iteration="1";var part="Fish"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--art-iteration="):iteration=arg.get_slice("=",1)
		if arg.begins_with("--review-part="):part=arg.get_slice("=",1)
	folder=ProjectSettings.globalize_path("res://../art_src/p2_review2/iteration_"+iteration+"/"+part.to_lower()+"/")
	DirAccess.make_dir_recursive_absolute(folder)
	report.first_review_frame_ms=Time.get_ticks_msec()
	get_tree().paused=true;Engine.max_fps=30
	for child in main.get_children():
		if child is CanvasLayer:child.visible=false
		if child.get_script()!=null and child.get_script().resource_path.ends_with("perf_governor.gd"):governor=child
	var deadline=Time.get_ticks_msec()+30000
	while main.find_children("*","MultiMeshInstance3D",true,false).size()<9:
		await get_tree().process_frame
		assert(Time.get_ticks_msec()<deadline)
	camera=Camera3D.new();add_child(camera);camera.make_current()
	camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.cull_mask &= ~(1<<19)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	main.player.visible=false;main.bro.visible=false;mood(main,0)
	if part=="Fish":await fish_review(main)
	if part=="VN":await vn_review(main)
	if part=="Fries":await fries_review(main)
	report.governor=governor.level
	report.performance=await measure()
	FileAccess.open(folder+"metrics.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("[P2 R2 ",part," PASS] ",report)
	get_tree().quit()

func fish_review(main):
	get_window().size=Vector2i(960,540)
	report.fish={}
	for i in GS.FISH_ORDER.size():
		var sp=GS.FISH_ORDER[i];var fish=FishSpot.Fish.new();main.add_child(fish)
		fish.setup(null,{"sp":sp,"len":20,"kg":.1})
		fish.position=origin+Vector3((i%3-1)*.78,(i/3)*.46,0);fish.rotation.y=PI/2;stage.append(fish)
		var meshes=Art.meshes(fish.visual)
		assert(meshes.size()==2 and fish.visual.has_node("Body") and fish.visual.has_node("Tail"))
		for mi in meshes:assert(mi.mesh is ArrayMesh)
		report.fish[sp]=counts(fish.visual)
	aim(origin+Vector3(0,.46,0),Vector3(0,.04,-1),3,44);await shot("fish_nine_3m")
	get_window().size=Vector2i(512,288)
	aim(origin+Vector3(0,.46,0),Vector3(0,.04,-1),15,44);await shot("fish_nine_15m")
	for fish in stage:fish.visible=false
	var g=Gull.new();g.plain=true;main.add_child(g);g.build();g.position=origin;pose_gull(g,"glide")
	var fish=FishSpot.Fish.new();main.add_child(fish);fish.setup(null,{"sp":"mackerel","len":32,"kg":.4});fish.attach(g.beak_socket)
	fish.position=Vector3(0,-.02,-.08);fish.rotation=Vector3(0,PI/2,0);fish.scale=Vector3.ONE*.55/max(fish.scl*.7,.7)
	aim(origin,Vector3(.8,.4,-1),3,44);await shot("fish_catch_socket")

func vn_review(main):
	get_window().size=Vector2i(960,540)
	var child=null
	for n in main.find_children("*","Node3D",true,false):
		if n.get_script()==Human and n.style.get("scale",1.0)<.8:child=n;break
	assert(child!=null)
	main.bro.visible=true;pose_gull(main.bro.gull,"ground")
	var st=main.story
	st.visible=true;st.active=true;st.page.show();st.cam=null
	if st.pback.get_parent()==null:main.add_child(st.pback)
	st.pcam.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	var subjects=[main.elder.rig,child,main.bro.gull]
	report.vn=[]
	for i in 3:
		var who=subjects[i]
		aim(who.head.global_position,Vector3(.6,.35,1),4 if i<2 else 6,44)
		var look={"yaw":PI+.45,"dist":1.55,"up":.10,"fov":34.0} if i<2 else {"dist":1.05,"yaw":.5,"up":.07,"fov":34.0,"avoid":true}
		var name_=["OLD MAN","CHILD","BIG BRO"][i]
		var line="Live portrait review." if i<2 else "The shades. The hat. The coat."
		await st.say_vn(name_,"art review fixture" if i<2 else "gull of many accessories",line,func():return who,1.0,Color("F5C65A"),look)
		st._portrait_tick();st.pcam.reset_physics_interpolation();st.page.queue_redraw()
		assert(st.visible and st.page.is_visible_in_tree() and st.vn.shown==line.length())
		await shot("vn_box_"+name_.to_lower().replace(" ","_"))
		st.pvp.get_texture().get_image().save_png(folder+"portrait_"+name_.to_lower().replace(" ","_")+".png")
		report.vn.append({"speaker":name_,"fixture":i<2,"shown":st.vn.shown,"portrait_camera":str(st.pcam.global_transform),"look":look})
	await st.vn_end();st.visible=false;st.active=false

func fries_review(main):
	get_window().size=Vector2i(960,540)
	report.fries={}
	for key in ["TUTORIAL_01","TUTORIAL_02","TUTORIAL_03"]:
		var f=main.world.fries[key]
		# Advance only the existing visual rig to its held pose before freezing it.
		if f.npc!=null:
			for frame in 30:f.npc.rig._process(1.0/30.0)
			f.npc.rig.reset_physics_interpolation();f.reset_physics_interpolation()
		report.fries[key]={"carrier":f.carrier,"counts":counts(f.visual)}
		aim(f.global_position+Vector3(0,.25,0),Vector3(.45,.48,-1),3,40)
		await shot("fry_3m_"+f.carrier)
