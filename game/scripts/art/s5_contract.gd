extends SceneTree
const Art = preload("res://scripts/art/art_loader.gd")
const Person = preload("res://scripts/art/person_parts.gd")
var Human
var report = {"styles":[],"flat_triangles":0}

func _initialize():call_deferred("check")

func tri(mesh):
	return mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size()/3

func check():
	Human = load("res://scripts/npc/human_rig.gd")
	# All colour regions use the original CPU tint ratios after the cache optimization.
	var all_style={"hair_style":"sunhat","apron":true,"backpack":true,"vest":true,"glasses":true,"skin":"7A4B33","shirt":"6DBE6A","pants":"BEB4A0","hair":"DCCFAB","shoes":"AF5530","hat":"E86343","pack_color":"3073AC","vest_color":"8C659C"}
	var targets={1:"skin",2:"shirt",3:"pants",4:"hair",5:"shoes",6:"hat",7:"pack_color",8:"vest_color"}
	var region_seen={}
	for hair_kind in ["sunhat","short"]:
		all_style.hair_style=hair_kind
		var tinted=Person.for_style(all_style)
		for mesh in tinted.values():
			var a=mesh.surface_get_arrays(0)
			for i in a[Mesh.ARRAY_VERTEX].size():
				var r=roundi(a[Mesh.ARRAY_TEX_UV][i].x*15)
				if not targets.has(r):continue
				var wanted=Color(all_style[targets[r]]).srgb_to_linear();var c=a[Mesh.ARRAY_COLOR][i]
				var ref=Color(Person.REF[r]).srgb_to_linear()
				# GLB import and ArrayMesh each quantize colours to UNORM8. Account
				# for both steps, magnified by the tint ratio; paint varies .984..1.
				for ch in 3:
					var quantum=(1.0+wanted[ch]/ref[ch])/255.0
					assert(c[ch]>=wanted[ch]*.984-quantum-.0001 and c[ch]<=wanted[ch]+quantum+.0001)
				region_seen[r]=true
	assert(region_seen.size()==targets.size())
	report.tint_regions=region_seen
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
			var a=mesh.surface_get_arrays(0);var ids=a[Mesh.ARRAY_INDEX];var normals=a[Mesh.ARRAY_NORMAL]
			for i in range(0,ids.size(),3):
				assert(normals[ids[i]].dot(normals[ids[i+1]])>.999 and normals[ids[i]].dot(normals[ids[i+2]])>.999,"Non-flat face")
				report.flat_triangles+=1
		assert(meshes.size()==9 and tris<=1800)
		var before = 0
		for mi in Art.meshes(old):before += tri(mi.mesh)
		var visible_parts=Art.meshes(h).filter(func(mi):return mi.is_visible_in_tree()).size()
		assert(visible_parts<=10)
		report.styles.append({"style":st,"tris":tris,"body_visible_parts":8,"visible_parts_including_items":visible_parts,"old_total_tris":before,"old_parts_including_items":Art.meshes(old).size(),"new_parts_including_items":Art.meshes(h).size()})
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
	report["result"] = "PASS: 9 styles x 13 modes x 3 modifier sets x 45 frames; pivots, held anchors, emotes, cache, fallback, shader, triangle budgets and flat normals"
	var out="res://../art_src/s6/contract.json" if "--art-s6" in OS.get_cmdline_user_args() else "res://../art_src/s5/contract.json"
	if "--art-s7" in OS.get_cmdline_user_args():out="res://../art_src/s7/contract.json"
	FileAccess.open(out,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("[S5 CONTRACT] ",report.result)
	quit()
