extends RefCounted
const Prof=preload("res://scripts/art/s7_profile.gd")
## Authored scenery, bounded shared batches; all original collision/RNG calls still run.
const Art = preload("res://scripts/art/art_loader.gd")
static var catalog = {"houses":[],"trees":[]}
static var _meshes = {}
static var _index = {}
static var _trees = {}
static var enabled = true

static func reset():
	catalog = {"houses":[],"trees":[]}
	_trees = {}

static func mesh_at(path):
	if _meshes.has(path):return _meshes[path]
	var scene = Art.instantiate(path)
	if scene == null:return null
	var found = Art.meshes(scene)
	if found.size() != 1 or found[0].mesh.get_surface_count() != 1:
		scene.free()
		return null
	var mesh = found[0].mesh
	var a = mesh.surface_get_arrays(0)
	var limit = 500 if path.get_file().begins_with("tree_leaf") else (450 if path.get_file().begins_with("tree_pine") else 1200)
	if a[Mesh.ARRAY_INDEX] == null or a[Mesh.ARRAY_INDEX].size()/3 > limit:
		scene.free();return null
	if path.get_file().begins_with("tree_"):
		var low = 1.0
		var high = 0.0
		for c in a[Mesh.ARRAY_COLOR]:low = minf(low,c.a);high = maxf(high,c.a)
		if low > .01 or high < .99:
			scene.free();return null
	mesh.surface_set_material(0,Art.material())
	_meshes[path] = mesh
	scene.free()
	return mesh

static func signature(p):
	return "%.3f,%.3f,%.3f,%.3f,%.3f,%s" % [p[0],p[1],p[2],p[3],p[4],p[7]]

static func house_mesh(params):
	if not enabled:return null
	if _index.is_empty() and FileAccess.file_exists("res://assets/models/house_catalog.json"):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/house_catalog.json"))
		if not parsed is Dictionary:return null
		_index = parsed
	var key = signature(params)
	if not _index.has(key):return null
	if not _index[key] is Dictionary or not _index[key].get("file",null) is String:return null
	return mesh_at("res://assets/models/"+_index[key]["file"])

static func tree_mesh(kind,x,z):
	if not enabled or not kind in [0,1]:return null
	var variant = posmod(roundi(x*13+z*7),3 if kind==0 else 2)
	return mesh_at("res://assets/models/tree_%s_%d.glb" % ["leaf" if kind==0 else "pine",variant])

static func record_house(w, mesh, params, commands):
	var base = commands[1]["pos"][1]-params[4]*.5
	catalog.houses.append({"params":params,"base":base,"signature":signature(params),"commands":commands})
	if mesh != null:
		w.B.authored(mesh,Transform3D(Basis.IDENTITY,Vector3(params[0],base,params[1])))

static func record_tree(w, mesh, x,z,kind,scale_v,commands):
	catalog.trees.append({"x":x,"z":z,"kind":kind,"scale":scale_v,"commands":commands})
	if mesh == null:return
	var key = mesh.get_instance_id()
	if not _trees.has(key):_trees[key] = {"mesh":mesh,"instances":[]}
	var tint = Color.WHITE
	if kind==0:
		var c = Color(commands[1].colour)
		var ref = Color("4F8A45")
		tint = Color(c.r/ref.r,c.g/ref.g,c.b/ref.b,1)
	_trees[key].instances.append([Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*scale_v),Vector3(x,w.gh(x,z),z)),tint])

static func flush_trees(w):
	var profile_t=Prof.start()
	for group in _trees.values():
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = group.mesh
		mm.instance_count = group.instances.size()
		for i in group.instances.size():
			mm.set_instance_transform(i,group.instances[i][0])
			mm.set_instance_color(i,group.instances[i][1])
		var mi = MultiMeshInstance3D.new()
		mi.name = "AuthoredTrees"
		mi.multimesh = mm
		mi.material_override = Art.material()
		mi.add_to_group("p1b_new_world")
		w.map.add_child(mi)
	_trees.clear()
	Prof.end("tree MultiMesh setup",profile_t)
