extends SceneTree
const Art=preload("res://scripts/art/art_loader.gd")
const Kits=preload("res://scripts/art/kenney_parts.gd")
func _initialize():call_deferred("run")
func run():
	var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://../art_src/s3/kit_catalog.json"))
	var report={"assets":{},"failures":[]}
	for key in Kits.LIMIT:
		var mesh=Kits.mesh_at(key)
		assert(mesh!=null)
		var a=mesh.surface_get_arrays(0);var bounds=mesh.get_aabb();var expected=catalog[key].size_m
		var bad=[];var degenerate=0
		var flat=true;var idx=a[Mesh.ARRAY_INDEX];var normals=a[Mesh.ARRAY_NORMAL]
		for i in range(0,idx.size(),3):
			var verts=a[Mesh.ARRAY_VERTEX]
			if (verts[idx[i+1]]-verts[idx[i]]).cross(verts[idx[i+2]]-verts[idx[i]]).length_squared()<1e-16:
				degenerate+=1;continue
			if normals[idx[i]].dot(normals[idx[i+1]])<.995 or normals[idx[i]].dot(normals[idx[i+2]])<.995:
				flat=false
				if bad.size()<2:bad.append([str(normals[idx[i]]),str(normals[idx[i+1]]),str(normals[idx[i+2]])])
		var dims=Vector3(expected[0],expected[1],expected[2])
		var good_size=bounds.size.distance_to(dims)<.08
		report.assets[key]={"tris":idx.size()/3,"bad_normals":bad,"degenerate_triangles":degenerate,"bounds":str(bounds),"expected_m":expected,"size_pass":good_size,"flat":flat,"surfaces":mesh.get_surface_count(),"shared_material":mesh.surface_get_material(0)==Art.material()}
		if not good_size or not flat:report.failures.append(key)
	Kits.enabled=false;assert(Kits.mesh_at("table")==null);Kits.enabled=true
	assert(Kits.mesh_at("missing")==null)
	assert(Art.instantiate("res://assets/art/kenney/no_such_model.glb")==null)
	report.fallback_checks=true
	var host=Node3D.new();root.add_child(host)
	var w={"B":preload("res://scripts/world/batcher.gd").new(host)}
	Kits.umbrella(w,0,0,0,"D96D5F")
	var canopy=w.B.art_tools[Vector2i.ZERO].commit();var ca=canopy.surface_get_arrays(0)
	report.umbrella_triangles=ca[Mesh.ARRAY_INDEX].size()/3 if ca[Mesh.ARRAY_INDEX]!=null else ca[Mesh.ARRAY_VERTEX].size()/3
	assert(report.umbrella_triangles==48)
	host.free()
	var old=GDScript.new();old.source_code=FileAccess.get_file_as_string("res://../art_src/s3/baseline/source/game/scripts/world/terrain.gd");assert(old.reload()==OK)
	var old_mesh=old.build_mesh();var new_mesh=preload("res://scripts/world/terrain.gd").build_mesh()
	var before=old_mesh.surface_get_arrays(0);var after=new_mesh.surface_get_arrays(0)
	report.terrain_vertices_identical=before[Mesh.ARRAY_VERTEX]==after[Mesh.ARRAY_VERTEX]
	report.terrain_colours_identical=before[Mesh.ARRAY_COLOR]==after[Mesh.ARRAY_COLOR]
	report.terrain_normals_identical=before[Mesh.ARRAY_NORMAL]==after[Mesh.ARRAY_NORMAL]
	assert(report.terrain_vertices_identical and report.terrain_colours_identical and report.terrain_normals_identical)
	var phase="s3b" if "--art-s3b" in OS.get_cmdline_user_args() else "s3"
	FileAccess.open("res://../art_src/"+phase+"/contract.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("[S3 CONTRACT] failures=",report.failures," terrain vertices/colours/normals identical; fallbacks PASS")
	quit(0 if report.failures.is_empty() else 1)
