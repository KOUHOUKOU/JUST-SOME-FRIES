extends SceneTree
const Art = preload("res://scripts/art/art_loader.gd")
const Person = preload("res://scripts/art/person_parts.gd")
const Scenery = preload("res://scripts/art/scenery_parts.gd")
var Human
var report = {"styles":[],"tree_alpha":{},"house_triangles":{}}

func _initialize():call_deferred("check")

func tri(mesh):
	return mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size()/3

func check():
	Human = load("res://scripts/npc/human_rig.gd")
	var styles = JSON.parse_string(FileAccess.get_file_as_string("res://../art_src/p1b/cast_styles.json"))
	styles.append({"skin":"7A4B33","shirt":"E3B590","pants":"AEB8C0","hair":"9A7654","hair_style":"sunhat","glasses":true,"apron":true,"vest":true,"backpack":true,"fat":1.3,"scale":.7,"item_l":"cup","item_r":"rod"})
	var modes = ["idle","walk","jog","eat","chat","fish","paint","sit","lie","wave","alarm","play","recline"]
	for st in styles:
		var h = Human.new();root.add_child(h);h.build(st);h.set_process(false)
		var old = Human.new();root.add_child(old);old.force_procedural = true;old.build(st);old.set_process(false)
		assert(h.authored)
		var meshes = Person.for_style(st)
		assert(Person.for_style(st)==meshes,"Style cache not reused")
		var tris = 0
		for mesh in meshes.values():
			assert(mesh.get_surface_count()==1 and mesh.surface_get_material(0)==Art.material())
			tris += tri(mesh)
		assert(meshes.size()==9 and tris<=1800)
		var before = 0
		for mi in Art.meshes(old):before += tri(mi.mesh)
		report.styles.append({"style":st,"tris":tris,"draw_parts":9,"old_total_tris":before,"old_parts_including_items":Art.meshes(old).size(),"new_parts_including_items":Art.meshes(h).size()})
		assert(Art.meshes(h).size()<=Art.meshes(old).size())
		for mode_ in modes:
			for flags in 3:
				for n in [h,old]:
					n.seed_off = .25;n.t = 0;n.phase = 0;n.mode = mode_
					n.holding = flags==1;n.seated = flags==1
					n.override_arm_r = -1.7 if flags==2 else null;n.override_arm_r_z = .25
					n.emote("surprise",.6)
				for k in 45:
					h._process(1.0/30);old._process(1.0/30)
					for key in ["root","upper","torso","head","arm_l","arm_r","hand_l","hand_r","leg_l","leg_r","hand_anchor"]:
						assert(h.get(key).transform.is_equal_approx(old.get(key).transform),"Pivot changed: "+key+" "+mode_)
					assert(h.eye_l.scale.is_equal_approx(old.eye_l.scale) and h.mouth.scale.is_equal_approx(old.mouth.scale))
		h.free();old.free()
	for path in ["res://assets/models/missing_p1b.glb","res://assets/models/p0_rounded_cube.glb"]:
		var h = Human.new();root.add_child(h);h.authored_path=path;h.build({})
		assert(not h.authored and h.hand_anchor != null);h.free()
	for kind in ["leaf","pine"]:
		for i in (3 if kind=="leaf" else 2):
			var name_ = "tree_%s_%d.glb" % [kind,i]
			var mesh = Scenery.mesh_at("res://assets/models/"+name_)
			assert(mesh != null)
			var a = mesh.surface_get_arrays(0);var low=1.0;var high=0.0
			for c in a[Mesh.ARRAY_COLOR]:low=minf(low,c.a);high=maxf(high,c.a)
			assert(low<.01 and high>.99)
			assert(mesh.surface_get_material(0)==Art.material())
			report.tree_alpha[name_] = {"min":low,"max":high,"triangles":tri(mesh)}
	var index = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/house_catalog.json"))
	for data in index.values():
		var mesh = Scenery.mesh_at("res://assets/models/"+data.file)
		assert(mesh != null and tri(mesh)<=1200)
		report.house_triangles[data.file] = tri(mesh)
	Scenery.enabled = false
	assert(Scenery.tree_mesh(0,0,0)==null and Scenery.house_mesh([])==null)
	Scenery.enabled = true
	assert(Scenery.tree_mesh(2,0,0)==null and Scenery.mesh_at("res://assets/models/missing_p1b.glb")==null)
	report["result"] = "PASS: 9 styles x 13 modes x 3 modifier sets x 45 frames; pivots, held anchors, emotes, cache, fallback, shader, triangle/alpha budgets"
	FileAccess.open("res://../art_src/"+("p1b_review2" if "--p1b-r2" in OS.get_cmdline_user_args() else "p1b")+"/contract.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("[P1B CONTRACT] ",report.result)
	quit()
