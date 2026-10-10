extends RefCounted
const Prof=preload("res://scripts/art/s7_profile.gd")
## Optional visual-only GLB loader. A null result means: keep building primitives.
## No gameplay nodes, animation replacement, per-frame work, textures or extra passes.

const SOFT_TOON = preload("res://shaders/soft_toon.gdshader")
static var _shared_material: ShaderMaterial

static func material() -> ShaderMaterial:
	if _shared_material == null:
		_shared_material = ShaderMaterial.new()
		_shared_material.shader = SOFT_TOON
	return _shared_material

static func meshes(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		found.append(node)
	for child in node.get_children():
		found.append_array(meshes(child))
	return found

static func instantiate(path: String) -> Node3D:
	if not (path.begins_with("res://assets/models/") or path.begins_with("res://assets/art/kenney/")) or not path.ends_with(".glb"):
		return null
	if not ResourceLoader.exists(path, "PackedScene"):
		return null
	var profile_t=Prof.start()
	var packed = ResourceLoader.load(path, "PackedScene")
	if not packed is PackedScene:
		return null
	Prof.end("GLB load",profile_t)
	profile_t=Prof.start()
	var instance = packed.instantiate()
	if not instance is Node3D:
		instance.free()
		return null
	var parts = meshes(instance)
	var valid = not parts.is_empty()
	for part in parts:
		if part.mesh == null or part.mesh.get_surface_count() == 0:
			valid = false
			continue
		for surface in part.mesh.get_surface_count():
			if not (part.mesh.surface_get_format(surface) & Mesh.ARRAY_FORMAT_COLOR):
				valid = false
	if not valid:
		push_warning("Art GLB lacks mesh/COLOR_0; keep procedural fallback: " + path)
		instance.free()
		return null
	for part in parts:
		part.material_override = material()
	Prof.end("GLB instantiate validate",profile_t)
	return instance

static func attach(parent: Node3D, path: String) -> Node3D:
	var instance = instantiate(path)
	if instance != null:
		parent.add_child(instance)
	return instance
