extends "res://scripts/art/p1a_review.gd"
const P2 = preload("res://scripts/art/p2_parts.gd")
const Fry = preload("res://scripts/fries/fry.gd")
const Dog = preload("res://scripts/npc/dog.gd")
const FishSpot = preload("res://scripts/world/fish_spot.gd")
const Human = preload("res://scripts/npc/human_rig.gd")
var stage=[]

func aim(target,direction,distance,fov_=44):
	camera.position=target+direction.normalized()*distance;camera.look_at(target);camera.fov=fov_

func make_fry(main,kind,carrier_,old=false,tier_=0):
	P2.enabled=not old
	var f=Fry.new();main.add_child(f);f.setup("REVIEW",kind,carrier_,0,tier_);f.set_process(false);stage.append(f)
	P2.enabled=true;return f

func run(main,_output):
	process_mode=Node.PROCESS_MODE_ALWAYS
	assert(OS.get_user_data_dir().replace("\\","/").contains("/art_src/p2/runtime/"))
	var iteration="3"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--art-iteration="):iteration=arg.get_slice("=",1)
	folder=ProjectSettings.globalize_path("res://../art_src/p2/iteration_"+iteration+"/game/")
	DirAccess.make_dir_recursive_absolute(folder)
	report["first_review_frame_ms"]=Time.get_ticks_msec()
	get_tree().paused=true;Engine.max_fps=30
	for child in main.get_children():
		if child is CanvasLayer:child.visible=false
		if child.get_script()!=null and child.get_script().resource_path.ends_with("perf_governor.gd"):governor=child
	var deadline=Time.get_ticks_msec()+30000
	while main.find_children("*","MultiMeshInstance3D",true,false).size()<9:
		await get_tree().process_frame
		assert(Time.get_ticks_msec()<deadline)
	camera=Camera3D.new();add_child(camera);camera.make_current();camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.cull_mask &= ~(1<<19)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	main.player.visible=false;main.bro.visible=false
	if "--p2-details" in OS.get_cmdline_user_args():
		await final_details(main);get_tree().quit();return
	var f=main.world.fries.TUTORIAL_01
	var old=make_fry(main,f.ftype,f.carrier,true);old.global_transform=f.global_transform
	# Existing real cafe table, existing halo/rim; same target and fixed time.
	var target=f.global_position+Vector3(0,.28,0)
	report.fries={"old":counts(old.visual),"new":counts(f.visual)}
	for m in MOODS:
		mood(main,m[1])
		for d in [3,15,60]:
			aim(target,Vector3(.3,1.15 if d==60 else .4,1),d)
			f.visible=false;old.visible=true;await shot("fry_%s_%dm_before"%[m[0],d])
			old.visible=false;f.visible=true;await shot("fry_%s_%dm_after"%[m[0],d])
	# Matched crowded A/B changes only P2 fry meshes (effects untouched).
	mood(main,0);aim(Vector3(-8,.7,4),Vector3(1,.55,1),18,58)
	var copies=[]
	for real in get_tree().get_nodes_in_group("fries"):
		if real==old or real in stage:continue
		P2.enabled=false
		var q=Fry.new();main.add_child(q);q.setup(real.id,real.ftype,real.carrier,real.kind,real.tier);q.set_process(false)
		q.visual.transform=real.visual.transform
		# Only duplicate the visual to preserve halo and gameplay state in the live object.
		var v=q.visual;v.reparent(real,false);v.visible=false;copies.append([real.visual,v]);q.free()
	P2.enabled=true
	for pair in copies:pair[0].visible=false;pair[1].visible=true
	await shot("cafe_before");report["perf_before"]=await measure()
	for pair in copies:pair[0].visible=true;pair[1].visible=false
	await shot("cafe_after");report["perf_after"]=await measure()
	for pair in copies:pair[1].free()
	old.free()
	# Carriers and identities at a clear review ledge, no invented gameplay objects.
	var origin=Vector3(30,18,100)
	for i in 7:
		var q=make_fry(main,["tutorial","tutorial","tutorial","red","green","blue","ordinary"][i],["box","plate","hand","box","box","box","box"][i],false,0 if i<3 or i==6 else 1)
		q.position=origin+Vector3((i-3)*.82,0,0);q.visible=true
	aim(origin+Vector3(0,.25,0),Vector3(.05,.5,1),7,50);await shot("fry_cast")
	for n in stage:
		if is_instance_valid(n):n.visible=false
	# Three existing outfits; full approved animated wings are present in engine.
	var g=Gull.new();g.plain=true;main.add_child(g);g.build();g.position=origin;stage.append(g)
	report.wardrobe={}
	for bro in [false,true]:
		g.bro_style=bro
		for kind in (Gull.SLOTS.keys() if not bro else ["coat","topper","shades","necklace"]):
			g.strip_all();P2.enabled=false;g.wear(kind,true);var before=counts(g.worn[kind]);g.strip_all()
			P2.enabled=true;g.wear(kind,true);report.wardrobe[("bro_" if bro else "")+kind]={"before":before,"after":counts(g.worn[kind])}
		g.strip_all()
	g.bro_style=false
	for i in 3:
		g.strip_all()
		for kind in [["hat","glasses","hawaii"],["sailor","scarf","stripes"],["topper","shades","coat"]][i]:g.wear(kind,true)
		pose_gull(g,"ground");aim(origin,Vector3(.85,.5,-1),2.6,44);await shot("outfit_%d_perch"%i)
		pose_gull(g,"glide");aim(origin,Vector3(.7,.65,-1),3.2,44);await shot("outfit_%d_flight"%i)
	g.strip_all();g.visible=false
	# Dog street + strict comparison under the same camera.
	var dogpos=Vector3(-7,.05,15)
	var dogs=[]
	for procedural in [true,false]:
		P2.enabled=not procedural;var d=Dog.new();main.add_child(d);d.setup(null,dogpos,0,"B98B61");d.set_physics_process(false);dogs.append(d)
	P2.enabled=true;report.dog={"old":counts(dogs[0]),"new":counts(dogs[1])}
	aim(dogpos+Vector3(0,.5,0),Vector3(.8,.3,1),3,44)
	dogs[1].visible=false;await shot("dog_before");dogs[0].visible=false;dogs[1].visible=true;await shot("dog_after")
	for d in dogs:d.free()
	# Nine species retain the old size/rarity data and live tail pivot.
	report.fish={}
	for i in GS.FISH_ORDER.size():
		var sp=GS.FISH_ORDER[i];var fish=FishSpot.Fish.new();main.add_child(fish);fish.setup(null,{"sp":sp,"len":20,"kg":.1})
		fish.position=origin+Vector3((i%3-1)*1.1,(i/3)*.70,0);fish.rotation.y=PI/2;stage.append(fish)
		P2.enabled=false;var legacy=FishSpot.Fish.new();main.add_child(legacy);legacy.setup(null,{"sp":sp,"len":20,"kg":.1});P2.enabled=true
		report.fish[sp]={"old":counts(legacy.visual),"new":counts(fish.visual)};legacy.free()
	aim(origin+Vector3(0,.7,0),Vector3(0,.10,-1),4,48);await shot("fish_nine")
	for n in stage:
		if is_instance_valid(n):n.visible=false
	# Actual held-fish transform (capture before the unchanged consume timer).
	g.visible=true;pose_gull(g,"glide")
	var catch_=FishSpot.Fish.new();main.add_child(catch_);catch_.setup(null,{"sp":"mackerel","len":32,"kg":.4});catch_.attach(g.beak_socket)
	catch_.position=Vector3(0,-.02,-.08);catch_.rotation=Vector3(0,PI/2,0);catch_.scale=Vector3.ONE*.55/max(catch_.scl*.7,.7)
	for j in 8:await get_tree().process_frame
	aim(origin,Vector3(.8,.4,-1),3,44);await shot("fish_catch_socket");catch_.free();g.visible=false
	await people(main,origin)
	await portraits(main,g,origin)
	# Exact current cinematic reveal camera math at pre-contact t=.2; no new camera design.
	g.visible=true;g.strip_all();pose_gull(g,"glide")
	var cinef=make_fry(main,"tutorial","box");cinef.position=origin+Vector3(0,-.25,-.82)
	var mid=(g.beak_socket.global_position+cinef.global_position+Vector3(0,.15,0))*.5
	camera.position=mid+Vector3(cos(.2*.35)*1.15,.35,sin(.2*.35)*-.5);camera.look_at(mid);camera.fov=38
	await shot("snatch_cine_before_contact")
	report.governor=governor.level
	report["notes"]="Desktop Compatibility, 512x288, 30 fps cap. Frozen world; 30-frame medians. Three portrait fixtures: two production speakers plus friend test."
	FileAccess.open(folder+"metrics.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("[P2 REVIEW] ",report.perf_before," -> ",report.perf_after)
	get_tree().quit()

func people(main,origin):
	var chosen=[main.elder.rig]
	var found={}
	for n in main.find_children("*","Node3D",true,false):
		if n.get_script()!=Human:continue
		assert(n.authored)
		for key in ["apron","vest","backpack","glasses"]:
			if n.style.get(key,false) and not found.has(key):chosen.append(n);found[key]=true
		if n.style.get("scale",1.0)<.8 and not found.has("child"):chosen.append(n);found.child=true
	report.people=[]
	var cast=[]
	for i in chosen.size():
		var src=chosen[i];var h=Human.new();main.add_child(h);h.build(src.style);h.set_process(false)
		h.position=origin+Vector3((i-chosen.size()*.5)*1.2,0,0);cast.append(h)
		report.people.append({"style":src.style,"counts":counts(h)})
	aim(origin+Vector3(-.6,1,0),Vector3(0,.12,1),8,55);await shot("special_cast")
	for i in mini(3,cast.size()):
		var h=cast[i];aim(h.head.global_position+Vector3(0,.15,0),Vector3(.25,.05,1),1.3,40);await shot("person_face_%d"%i)
	for h in cast:h.free()

func portraits(main,g,origin):
	var friend=Gull.new();friend.plain=true;main.add_child(friend);friend.build();friend.position=origin+Vector3(8,0,0);friend.tint_pale(Gull.pale_color(2));friend.wear("beret",true)
	main.bro.visible=true;g.visible=true
	var subjects=[g,main.bro.gull,friend]
	for i in 3:
		var who=subjects[i];pose_gull(who,"ground")
		var st=main.story;st.visible=true;st.active=true
		st.vn={"a":1.0,"who":["YOU","BIG BRO","FRIEND (review fixture)"][i],"sub":"","text":"","shown":0,"head":func():return who,"look":{},"tint":Color("D8CFE6"),"pop":0,"closing":false}
		if st.pback.get_parent()==null:main.add_child(st.pback)
		st.pvp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;st.pcam.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
		st._portrait_tick();st.pcam.reset_physics_interpolation();st.page.queue_redraw()
		await shot("vn_box_%d"%i)
		var img=st.pvp.get_texture().get_image();img.save_png(folder+"vn_portrait_%d.png"%i)
		st.vn=null;st.pvp.render_target_update_mode=SubViewport.UPDATE_DISABLED;st.pback.visible=false;st.visible=false;st.active=false
	main.bro.visible=false;g.visible=false;friend.free()

func shot(name_):
	for i in 6:await RenderingServer.frame_post_draw
	var img=get_viewport().get_texture().get_image()
	assert(img.get_width()<=960 and img.get_height()<=540)
	img.save_png(folder+name_+".png")

func final_details(main):
	folder=folder.get_base_dir()+"/details/";DirAccess.make_dir_recursive_absolute(folder)
	if "--p2-held" in OS.get_cmdline_user_args():
		folder=folder.get_base_dir()+"_held_final/";DirAccess.make_dir_recursive_absolute(folder)
		mood(main,0);await people(main,Vector3(30,18,100))
		for row in report.people:assert(row.counts.mesh_parts<=11)
		FileAccess.open(folder+"metrics.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
		return
	mood(main,0)
	get_window().size=Vector2i(960,540)
	var f=main.world.fries.TUTORIAL_01
	var old=make_fry(main,f.ftype,f.carrier,true);old.global_transform=f.global_transform
	aim(f.global_position+Vector3(0,.27,0),Vector3(.5,.27,-1),3,44)
	f.visible=false;await shot("fry_3m_before");old.visible=false;f.visible=true;await shot("fry_3m_after");old.free()
	main.bro.visible=true
	aim(main.bro.gull.global_position+Vector3(0,.15,0),Vector3(.8,.4,-1),4.5,44);await shot("bro_outfit")
	main.bro.visible=false
	var d=Dog.new();main.add_child(d);d.setup(null,Vector3(-7,.05,15),0,"B98B61");d.set_physics_process(false)
	aim(d.position+Vector3(0,.5,0),Vector3(.8,.3,1),3,44);await shot("dog_3m");d.free()
	get_window().size=Vector2i(512,288)
	await people(main,Vector3(30,18,100))
	var g=Gull.new();g.plain=true;main.add_child(g);g.build();g.position=Vector3(30,18,100);g.wear("meteor",true);pose_gull(g,"glide")
	aim(g.position,Vector3(.8,.3,-1),3,44);await shot("meteor_billboard")
	var hand=make_fry(main,"tutorial","hand");hand.position=Vector3(29,18,100)
	assert(hand.visual.scale==Vector3.ONE)
	# Restock resets visual.scale; mesh-local carrier scale must survive it.
	hand.visual.scale=Vector3.ONE
	for mi in Art.meshes(hand.visual):assert(mi.scale.is_equal_approx(Vector3.ONE*.8))
	aim(hand.position+Vector3(0,.25,0),Vector3(.5,.4,-1),3,40);g.visible=false;await shot("hand_after_restock_scale")
	FileAccess.open(folder+"metrics.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("[P2 DETAILS] final held-item budget and hand/restock scale checked")
