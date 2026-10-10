extends "res://scripts/art/s5_contract.gd"
const Terrain=preload("res://scripts/world/terrain.gd")
const OldTerrain=preload("res://../art_src/s7/contract_baseline/scripts/world/terrain.gd")
func check():
	report.s7={}
	# Full 171-style cache, all saved mesh arrays including colour/normals/UV/index.
	var styles=JSON.parse_string(FileAccess.get_file_as_string("res://../art_src/s7/baked_styles.json"))
	Person.load_baked(Person.load_parts())
	var saved=Person.baked.duplicate();assert(saved.size()==171)
	Person.baked={};Person.variants={};Person.bake_checked=true
	for key in styles:
		var made=Person.for_style(styles[key]);assert(saved.has(key))
		for part in made:
			var a=made[part].surface_get_arrays(0);var b=saved[key][part].surface_get_arrays(0)
			assert(var_to_bytes(a)==var_to_bytes(b),"Baked person mismatch: "+part)
	report.s7.person_cached_styles_exact=styles.size()
	Person.variants={};Person.baked=saved
	# Noise cache pixel-for-pixel against the original native procedural images.
	for spec in [["ground_coarse",FastNoiseLite.TYPE_SIMPLEX_SMOOTH,.05,11],["ground_fine",FastNoiseLite.TYPE_CELLULAR,.045,5]]:
		var fn=FastNoiseLite.new();fn.noise_type=spec[1];fn.frequency=spec[2];fn.seed=spec[3]
		if spec[1]==FastNoiseLite.TYPE_CELLULAR:fn.cellular_return_type=FastNoiseLite.RETURN_DISTANCE
		assert(fn.get_image(256,256,false,false,true).get_data()==load("res://assets/models/s7/"+spec[0]+".res").get_data())
	report.s7.noise_pixels_exact=true
	var terrain=Terrain.build_mesh(true);var cached=Terrain.build_mesh()
	assert(var_to_bytes(terrain.surface_get_arrays(0))==var_to_bytes(cached.surface_get_arrays(0)))
	for x in range(-160,161,2):
		for z in range(-110,141,2):
			if Vector2(x+102,z-40).length()>=40:assert(Terrain.H(x,z)==OldTerrain.H(x,z))
	report.s7.terrain_cache_exact_and_outside_40m_unchanged=true
	var versions=[]
	for path in ["res://../art_src/s7/contract_baseline/scripts/world/world_builder.gd","res://scripts/world/world_builder.gd"]:
		root.get_node("GS").reset();paused=true
		var host=Node3D.new();root.add_child(host)
		var p=CharacterBody3D.new();p.set_script(load("res://scripts/player/gull_player.gd"));host.add_child(p)
		var wb=load(path).new();var out=wb.build(host,p)
		# Freeze rotor/crowd simulation while deferred grass is allowed to complete.
		var shapes=[]
		for cs in host.find_children("*","CollisionShape3D",true,false):
			shapes.append({"class":cs.shape.get_class(),"transform":cs.global_transform,"data":shape_data(cs.shape)})
		var tree_catalog=load(path.get_base_dir().get_base_dir()+"/art/scenery_parts.gd").catalog.trees.duplicate(true)
		versions.append({"shapes":shapes,"anchors":out.anchors.duplicate(),"zones":out.air_zones.duplicate(true),"trees":tree_catalog})
		if versions.size()==2:
			await physics_frame
			# Raycast landing checks on grass, original perch pad and keeper table.
			for point in [Vector3(-110,12,40),Vector3(-102,31,40),Vector3(-93.5,12.81,44)]:
				var hit=host.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3(0,2,0),point-Vector3(0,2,0),1))
				assert(not hit.is_empty() and absf(hit.position.y-point.y)<.16,"Landing mismatch "+str(point))
		while host.find_children("*","MultiMeshInstance3D",true,false).filter(func(n):return n.visibility_range_end>0).size()<4:await process_frame
		host.free();wb=null
	var before=versions[0];var after=versions[1]
	assert(before.shapes.size()==after.shapes.size() and after.shapes.size()==1498)
	var moved=0;var terrain_changed=0
	for i in before.shapes.size():
		var a=before.shapes[i];var b=after.shapes[i]
		assert(a.class==b.class and a.transform.basis.is_equal_approx(b.transform.basis),"Collider basis/order "+str(i)+" "+str(a)+" NEW "+str(b))
		if a.data!=b.data:
			assert(a.class=="ConcavePolygonShape3D");terrain_changed+=1
		var delta=b.transform.origin-a.transform.origin
		if delta.length()>.00001:
			assert(absf(delta.x)<.0001 and absf(delta.z)<.0001 and delta.y<0 and delta.y>=-12.001)
			if Vector2(a.transform.origin.x+102,a.transform.origin.z-40).length()>=40:
				var tree_child=false
				for tr in before.trees:
					if Vector2(a.transform.origin.x-tr.x,a.transform.origin.z-tr.z).length()<6 and absf(delta.y-(Terrain.H(tr.x,tr.z)-OldTerrain.H(tr.x,tr.z)))<.0001:tree_child=true
				assert(tree_child,"Moved outside headland without matching tree base "+str(i))
			moved+=1
	assert(terrain_changed==1 and before.zones==after.zones)
	var anchors=[]
	for key in before.anchors:
		if before.anchors[key]!=after.anchors[key]:
			assert(key in ["lighthouse","turbine"] and (after.anchors[key]-before.anchors[key]).is_equal_approx(Vector3(0,-12,0)))
			anchors.append(key)
	assert(anchors.size()==2)
	report.s7.world={"colliders":1498,"moved_down_with_ground":moved,"changed_shapes":terrain_changed,"anchors_moved_down_12":anchors,"other_anchors_exact":true,"thermals_exact":true,"landing_rays":"PASS"}
	# Missing GLB still has the procedural path; no invalid visual dependency.
	assert(preload("res://scripts/art/scenery_parts.gd").mesh_at("res://assets/models/missing_s7.glb")==null)
	super.check()

func shape_data(sh):
	var d=[]
	for prop in sh.get_property_list():
		if prop.usage & PROPERTY_USAGE_STORAGE and not str(prop.name) in ["resource_name","resource_local_to_scene","script"]:d.append([prop.name,str(sh.get(prop.name))])
	return JSON.stringify(d)
