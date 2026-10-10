extends SceneTree
## Offline exact-result cache. Production fallbacks still run for missing/stale data.
const Person=preload("res://scripts/art/person_parts.gd")
func _initialize():call_deferred("run")
func run():
	var terrain=preload("res://scripts/world/terrain.gd").build_mesh(true)
	terrain.surface_set_material(0,null)
	terrain.set_meta("headland_height",preload("res://scripts/world/terrain.gd").HEADLAND_HEIGHT)
	assert(ResourceSaver.save(terrain,"res://assets/models/s7/terrain.res",ResourceSaver.FLAG_COMPRESS)==OK)
	var a=terrain.surface_get_arrays(0);var verts=a[Mesh.ARRAY_VERTEX];var kept=PackedInt32Array();var removed=0
	# Original terrain is unindexed; check every vertex, including radial extrema
	# along each edge, so no visible triangle is removed by a centroid shortcut.
	for i in range(0,verts.size(),3):
		var hidden=true
		for j in 3:
			var p=verts[i+j];var q=verts[i+(j+1)%3]
			var pp=Vector2(p.x+102,p.z-40);var qq=Vector2(q.x+102,q.z-40)
			var edge=qq-pp;var close=pp+edge*clampf(-pp.dot(edge)/edge.length_squared(),0,1)
			if p.y<=.4 or pp.length()>=40.2 or close.length()<=24.0:hidden=false
		if hidden:removed+=1
		else:kept.append_array(PackedInt32Array([i,i+1,i+2]))
	a[Mesh.ARRAY_INDEX]=kept
	var visible=ArrayMesh.new();visible.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a)
	visible.set_meta("headland_height",preload("res://scripts/world/terrain.gd").HEADLAND_HEIGHT)
	assert(ResourceSaver.save(visible,"res://assets/models/s7/terrain_visible.res",ResourceSaver.FLAG_COMPRESS)==OK)
	print("[S7 BAKE] omitted ",removed," already-discarded terrain triangles; collision complete")
	root.get_node("GS").reset();paused=true
	var host=Node3D.new();root.add_child(host)
	var p=CharacterBody3D.new();p.set_script(load("res://scripts/player/gull_player.gd"));host.add_child(p)
	var builder=load("res://scripts/world/world_builder.gd").new();builder.build(host,p)
	var r=Resource.new();r.set_meta("source",Person.source_signature(Person.load_parts()));r.set_meta("variants",Person.variants)
	assert(ResourceSaver.save(r,Person.CACHE_PATH,ResourceSaver.FLAG_COMPRESS)==OK)
	FileAccess.open("res://../art_src/s7/baked_styles.json",FileAccess.WRITE).store_string(JSON.stringify(Person.recorded_styles,"\t"))
	print("[S7 BAKE] ",Person.variants.size()," exact person styles")
	# Exact procedural images, moved out of the startup path without changing pixels.
	for spec in [["ground_coarse",FastNoiseLite.TYPE_SIMPLEX_SMOOTH,.05,11],["ground_fine",FastNoiseLite.TYPE_CELLULAR,.045,5]]:
		var fn=FastNoiseLite.new();fn.noise_type=spec[1];fn.frequency=spec[2];fn.seed=spec[3]
		if spec[1]==FastNoiseLite.TYPE_CELLULAR:fn.cellular_return_type=FastNoiseLite.RETURN_DISTANCE
		var im=fn.get_image(256,256,false,false,true)
		assert(ResourceSaver.save(im,"res://assets/models/s7/"+spec[0]+".res",ResourceSaver.FLAG_COMPRESS)==OK)
	while host.find_children("*","MultiMeshInstance3D",true,false).filter(func(n):return n.visibility_range_end>0).size()<4:await process_frame
	host.free();quit()
