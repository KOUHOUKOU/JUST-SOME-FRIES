extends RefCounted
## Named GLB meshes in pivot-local coordinates; one shared opaque material.
## Recolour only on the existing cosmetic events. No per-frame mesh work.
const Art = preload("res://scripts/art/art_loader.gd")
const PATH = "res://assets/models/hero_gull_parts.glb"
const NAMES = ["Body", "Chest", "Head", "Tail", "UpperL", "ForeL", "HandL", "UpperR", "ForeR", "HandR", "Legs"]
const LEGACY = [Color.WHITE, Color("F6F6F1"), Color("F6F6F1"), Color("AEB8C0"), Color("2B2F36"), Color("AEB8C0"), Color("F2A22E"), Color("101015")]
static var _sources = {}
static var _variants = {}
static var _material: ShaderMaterial

static func material() -> ShaderMaterial:
	if _material == null:
		_material = Art.material().duplicate()
		_material.set_shader_parameter("plumage_fill", 1.0)
	return _material

static func load_parts(path = PATH) -> Dictionary:
	if _sources.has(path):
		return _sources[path]
	var instance = Art.instantiate(path)
	if instance == null:
		return {}
	var found = {}
	var triangles = 0
	for mi in Art.meshes(instance):
		if not mi.name in NAMES or mi.mesh.get_surface_count() != 1 or found.has(str(mi.name)):
			instance.free()
			return {}
		var arrays = mi.mesh.surface_get_arrays(0)
		triangles += arrays[Mesh.ARRAY_INDEX].size() / 3
		if arrays[Mesh.ARRAY_TEX_UV] == null:
			instance.free()
			return {}
		for uv in arrays[Mesh.ARRAY_TEX_UV]:
			if roundi(uv.x * 7.0) > 7 or uv.x < 0:
				instance.free()
				return {}
		found[str(mi.name)] = mi.mesh
	instance.free()
	if found.size() != NAMES.size() or triangles > 4000:
		return {}
	_sources[path] = found
	return found

static func attach(parent: Node3D, source: Mesh, name_: String) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.name = name_
	mi.mesh = source
	mi.material_override = material()
	parent.add_child(mi)
	return mi

static func recolour(parts: Dictionary, colours: Array):
	var unchanged = true
	for i in colours.size():
		unchanged = unchanged and colours[i].is_equal_approx(LEGACY[i])
	if unchanged:
		for name_ in NAMES:
			parts[name_].mesh = load_parts()[name_]
		return
	var key = ""
	for c in colours:
		key += c.to_html() + ":"
	if not _variants.has(key):
		var variant = {}
		var source = load_parts()
		for name_ in NAMES:
			var arrays = source[name_].surface_get_arrays(0)
			var painted: PackedColorArray = arrays[Mesh.ARRAY_COLOR].duplicate()
			for i in painted.size():
				var c = painted[i]
				var region = roundi(arrays[Mesh.ARRAY_TEX_UV][i].x * 7.0)
				if region == 0 or colours[region].is_equal_approx(LEGACY[region]):
					continue
				var wanted: Color = colours[region].srgb_to_linear()
				if region == 4:
					# Fade retains cream roots; only dark primary tips take growth red.
					var mask = clampf((0.55 - maxf(c.r, maxf(c.g, c.b))) / 0.47, 0.0, 1.0)
					var shade = clampf(c.b / Color("3A3D48").srgb_to_linear().b, 0.45, 1.0)
					var tint = c.lerp(wanted * shade, mask)
					painted[i] = Color(tint.r, tint.g, tint.b, c.a)
				else:
					var reference = LEGACY[region].srgb_to_linear()
					painted[i] = Color(minf(c.r * wanted.r / reference.r, 1.0), minf(c.g * wanted.g / reference.g, 1.0), minf(c.b * wanted.b / reference.b, 1.0), c.a)
			arrays[Mesh.ARRAY_COLOR] = painted
			var mesh = ArrayMesh.new()
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			variant[name_] = mesh
		_variants[key] = variant
	for name_ in NAMES:
		parts[name_].mesh = _variants[key][name_]
