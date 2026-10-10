extends "res://scripts/art/p1a_review.gd"
const Scenery = preload("res://scripts/art/scenery_parts.gd")
const Human = preload("res://scripts/npc/human_rig.gd")
var pairs = []
var stage = []

func capture_catalog(main):
	var data = Scenery.catalog.duplicate(true)
	data["collision"] = []
	for n in main.find_children("*","CollisionShape3D",true,false):
		if n.get_parent().name != "SolidBody":continue
		var shape = n.shape
		var entry = {"type":shape.get_class(),"transform":str(n.transform)}
		if shape is BoxShape3D:entry["size"] = str(shape.size)
		elif shape is CylinderShape3D:entry["radius"] = shape.radius;entry["height"] = shape.height
		elif shape is ConvexPolygonShape3D:entry["points"] = str(shape.points)
		data.collision.append(entry)
	return data

func run(main,_output):
	process_mode = Node.PROCESS_MODE_ALWAYS
	assert(OS.get_user_data_dir().replace("\\","/").contains("/art_src/p1b/runtime/") or OS.get_user_data_dir().replace("\\","/").contains("/art_src/p1b_review2/runtime/"))
	get_tree().paused = true
	var iteration = "1"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--art-iteration="):iteration = arg.get_slice("=",1)
	folder = ProjectSettings.globalize_path("res://../art_src/p1b/iteration_"+iteration+"/game/")
	if "--p1b-r2" in OS.get_cmdline_user_args():folder = folder.replace("/p1b/","/p1b_review2/")
	DirAccess.make_dir_recursive_absolute(folder)
	var data = capture_catalog(main)
	if "--p1b-catalog" in OS.get_cmdline_user_args():
		assert(not FileAccess.file_exists("res://../art_src/p1b/baseline/catalog.json"),"Baseline is immutable")
		FileAccess.open("res://../art_src/p1b/baseline/catalog.json",FileAccess.WRITE).store_string(JSON.stringify(data,"\t"))
		get_tree().quit();return
	FileAccess.open(folder+"catalog.json",FileAccess.WRITE).store_string(JSON.stringify(data,"\t"))
	var baseline = JSON.parse_string(FileAccess.get_file_as_string("res://../art_src/p1b/baseline/catalog.json"))
	# Canonical JSON normalizes engine Color/Vector values through the same serializer.
	var normalized = JSON.parse_string(JSON.stringify(data))
	report["collision_exact"] = JSON.stringify(normalized.collision) == JSON.stringify(baseline.collision)
	report["generation_exact"] = JSON.stringify(normalized.houses) == JSON.stringify(baseline.houses) and JSON.stringify(normalized.trees) == JSON.stringify(baseline.trees)
	assert(report.collision_exact and report.generation_exact,"Original world generation changed")
	Engine.max_fps = 30
	for child in main.get_children():
		if child is CanvasLayer:child.visible = false
		if child.get_script() != null and child.get_script().resource_path.ends_with("perf_governor.gd"):governor = child
	var deadline = Time.get_ticks_msec()+30000
	while main.find_children("*","MultiMeshInstance3D",true,false).size() < 9:
		await get_tree().process_frame
		assert(Time.get_ticks_msec()<deadline,"flora timeout")
	camera = Camera3D.new();add_child(camera);camera.make_current();camera.fov = 44
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	report["people"] = []
	for n in main.find_children("*","Node3D",true,false):
		if n.get_script() != Human:continue
		assert(n.authored)
		var old = Human.new();old.force_procedural = true;n.get_parent().add_child(old)
		old.build(n.style.duplicate(true));old.transform = n.transform;old.visible = false
		old.set_process(false);n.set_process(false)
		for key in ["root","upper","torso","head","arm_l","arm_r","leg_l","leg_r","hand_l","hand_r","hand_anchor"]:old.get(key).transform = n.get(key).transform
		# Controllers attach existing mischief props after build(); retain these in A/B too.
		for mi in Art.meshes(n):
			if mi.material_override == Art.material():continue
			if (n.item_node_l != null and n.item_node_l.is_ancestor_of(mi)) or (n.item_node_r != null and n.item_node_r.is_ancestor_of(mi)):continue
			var prop = MeshInstance3D.new();prop.mesh = mi.mesh;prop.material_override = mi.material_override
			for surface in mi.mesh.get_surface_count():prop.set_surface_override_material(surface,mi.get_surface_override_material(surface))
			prop.cast_shadow = mi.cast_shadow;prop.layers = mi.layers;prop.visible = mi.is_visible_in_tree()
			old.add_child(prop);prop.transform = n.global_transform.affine_inverse()*mi.global_transform
		pairs.append([n,old])
		report.people.append({"position":str(n.global_position),"style":n.style,"before":asset_counts(old),"after":asset_counts(n)})
	main.player.visible = false;main.bro.visible = false
	if "--p1b-r2" in OS.get_cmdline_user_args():
		var review = load("res://scripts/art/p1b_r2_review.gd").new();add_child(review)
		await review.run(main,self)
		get_tree().quit();return
	if "--p1b-perf" in OS.get_cmdline_user_args():
		mood(main,0.0);camera.position = Vector3(5,24,14);camera.look_at(Vector3(-22,8,-38));camera.fov = 58
		before(true);await shot("crowded_matched_before");var old_perf = await measure()
		before(false);await shot("crowded_matched_after");var new_perf = await measure()
		report["crowded"] = {"before":old_perf,"after":new_perf}
		report["props_matched"] = true
		FileAccess.open(folder+"matched_metrics.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
		print("[P1B MATCHED PERF] ",report.crowded)
		get_tree().quit();return
	if "--p1b-framing" in OS.get_cmdline_user_args():
		await street_framing(main)
		get_tree().quit();return
	mood(main,0.0)
	var target = Vector3(-45,6.55,-33.0)
	for m in MOODS:
		mood(main,m[1])
		for distance in [3,15,60]:
			camera.position = target+Vector3(.22,.85 if distance==15 else .14,1).normalized()*distance
			camera.look_at(target)
			var label = "street_%s_%dm" % [m[0],distance]
			if m[0] == "noon":
				before(true);await shot(label+"_before")
			before(false);await shot(label+"_after")
	mood(main,0.0)
	camera.position = Vector3(5,24,14);camera.look_at(Vector3(-22,8,-38));camera.fov = 58
	before(true);await shot("crowded_before");var old_perf = await measure()
	before(false);await shot("crowded_after");var new_perf = await measure()
	report["crowded"] = {"before":old_perf,"after":new_perf}
	camera.position = Vector3(-5,2.6,8);camera.look_at(Vector3(-8,.6,3.6));camera.fov = 48
	before(true);await shot("cafe_before");before(false);await shot("cafe_after")
	camera.position = Vector3(-20,11,-23);camera.look_at(Vector3(-26.25,10,-41.9));camera.fov = 48
	before(true);await shot("house_before");before(false);await shot("house_after")
	var tr = data.trees.filter(func(x):return x.kind == 0)[0]
	var tree_target = Vector3(tr.x,tr.commands[1].pos[1],tr.z)
	camera.position = tree_target+Vector3(4,2,13)*tr.scale;camera.look_at(tree_target);camera.fov = 44
	before(true);await shot("tree_before");before(false);await shot("tree_after")
	await person_fixtures(main)
	report["governor_level"] = governor.level
	report["rendering"] = "Desktop Compatibility 512x288, capped 30 fps; full frozen island; 30-frame medians; no web export"
	FileAccess.open(folder+"metrics.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("[P1B] review complete: ",folder," crowded=",report.crowded)
	get_tree().quit()

func before(old):
	for n in get_tree().get_nodes_in_group("p1b_old_world"):n.visible = old
	for n in get_tree().get_nodes_in_group("p1b_new_world"):n.visible = not old
	for pair in pairs:pair[0].visible = not old;pair[1].visible = old

func asset_counts(node):
	var triangles = 0
	var meshes = Art.meshes(node)
	for mi in meshes:
		for k in mi.mesh.get_surface_count():
			var a = mi.mesh.surface_get_arrays(k)
			triangles += a[Mesh.ARRAY_INDEX].size()/3 if a[Mesh.ARRAY_INDEX] != null else a[Mesh.ARRAY_VERTEX].size()/3
	return {"triangles":triangles,"parts":meshes.size()}

func fixture(main,st,old = false):
	var h = Human.new();h.force_procedural = old;main.add_child(h);h.build(st);h.set_process(false)
	h.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	stage.append(h);return h

func settle(h,mode_,time_ = 0.0):
	h.mode = mode_;h.seed_off = 0.0;h.t = time_;h.phase = time_
	for k in 32:h._process(1.0/30)

func person_fixtures(main):
	var styles = JSON.parse_string(FileAccess.get_file_as_string("res://../art_src/p1b/cast_styles.json"))
	var origin = Vector3(-8,45,12)
	var h = fixture(main,styles[1]);h.position = origin;settle(h,"idle")
	var old = fixture(main,styles[1],true);old.position = origin;settle(old,"idle")
	report["person_sample"] = {"before":asset_counts(old),"after":asset_counts(h)}
	camera.fov = 40;camera.position = origin+Vector3(.8,1.1,4.0);camera.look_at(origin+Vector3(0,1,0))
	h.visible = false;await shot("person_before");old.visible = false;h.visible = true;await shot("person_after")
	camera.position = origin+Vector3(.45,1.80,1.3);camera.look_at(origin+Vector3(0,1.78,0));await shot("person_face")
	for distance in [15,60]:
		camera.position = origin+Vector3(0,1,distance);camera.look_at(origin+Vector3(0,1,0));await shot("person_%dm" % distance)
	h.visible = false
	for i in 8:
		var c = fixture(main,styles[i]);c.position = origin+Vector3((i-3.5)*1.0,0,0);settle(c,"idle")
	camera.position = origin+Vector3(0,1.1,9);camera.look_at(origin+Vector3(0,1.05,0));camera.fov = 30
	for m in MOODS:mood(main,m[1]);await shot("cast_"+m[0])
	for c in stage:c.visible = false
	mood(main,0.0)
	var modes = ["idle","walk","jog","eat","chat","fish","paint","sit","lie","wave","alarm","play","recline"]
	for batch in 4:
		var shown = []
		for j in 4:
			var k = batch*4+j
			if k>=modes.size():break
			var c = fixture(main,styles[k%styles.size()]);c.position = origin+Vector3((j-1.5)*1.7,0,0)
			settle(c,modes[k],.3);shown.append(c)
		camera.position = origin+Vector3(.5,1.75,7);camera.look_at(origin+Vector3(0,1,0));camera.fov = 34
		await shot("modes_"+str(batch)+"_"+"_".join(modes.slice(batch*4,mini(batch*4+4,modes.size()))))
		for c in shown:c.visible = false
	report["npc_vn"] = "No existing NPC VN portrait in story; separate in-engine face close-up supplied. VN production code untouched."

func street_framing(main):
	# Final evidence correction: look along the open pavement below the crowns.
	var target = Vector3(-38,6.5,-32.8)
	for m in MOODS:
		mood(main,m[1])
		for distance in [3,15,60]:
			var direction = Vector3(1,.10,.35) if distance==3 else (Vector3(1,.05,.08) if distance==15 else Vector3(.22,.18,1))
			camera.position = target+direction.normalized()*distance;camera.look_at(target);camera.fov=44
			var label = "street_clear_%s_%dm" % [m[0],distance]
			if m[0]=="noon":before(true);await shot(label+"_before")
			before(false);await shot(label+"_after")
	print("[P1B FRAMING] twelve corrected pavement views complete")
