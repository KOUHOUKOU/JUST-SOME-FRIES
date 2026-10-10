extends RefCounted
const Prof=preload("res://scripts/art/s7_profile.gd")
## Cached vertex tints and merged clothes; nine opaque surfaces per person.
const Art = preload("res://scripts/art/art_loader.gd")
const PATH = "res://assets/models/person_parts.glb"
const BASE = ["Torso", "ArmL", "ArmR", "LegL", "LegR", "Head", "EyeL", "EyeR", "Mouth"]
const EXTRA = ["Hair_short", "Hair_bun", "Hair_long", "Hair_cap", "Hair_beanie", "Hair_sunhat", "Apron", "Pack", "Vest", "Glasses"]
const REF = ["FFFFFF", "E3B590", "8C8F96", "4B5566", "3A2A20", "3A3330", "3D8CD9", "C65A3A", "E8573A", "D89A8E", "F4F1E8"]
static var sources = {}
static var variants = {}
const CACHE_PATH="res://assets/models/s7/person_variants.res"
const CACHE_VERSION="S5-flat-tint-v1"
static var baked={}
static var bake_checked=false
static var recorded_styles={}

static func source_signature(src):
	var hashes=[]
	for n in BASE+EXTRA:hashes.append(var_to_bytes(src[n].surface_get_arrays(0)).hex_encode().sha256_text())
	return str(hashes).sha256_text()+CACHE_VERSION

static func load_baked(src):
	if bake_checked:return
	bake_checked=true
	if "--s7-bake" in OS.get_cmdline_user_args() or "--s7-no-cache" in OS.get_cmdline_user_args():return
	if not ResourceLoader.exists(CACHE_PATH):return
	var t=Prof.start();var r=load(CACHE_PATH)
	if r.get_meta("source","")==source_signature(src):
		baked=r.get_meta("variants",{})
		for parts in baked.values():
			for m in parts.values():m.surface_set_material(0,Art.material())
	Prof.end("person baked resource load",t)

static func load_parts(path = PATH) -> Dictionary:
	if sources.has(path):return sources[path]
	var scene = Art.instantiate(path)
	if scene == null:return {}
	var found = {}
	for mi in Art.meshes(scene):
		var n = str(mi.name)
		if not n in BASE + EXTRA or found.has(n) or mi.mesh.get_surface_count() != 1:
			scene.free();return {}
		var a = mi.mesh.surface_get_arrays(0)
		if a[Mesh.ARRAY_TEX_UV] == null or a[Mesh.ARRAY_COLOR] == null:
			scene.free();return {}
		for uv in a[Mesh.ARRAY_TEX_UV]:
			if uv.x < 0 or roundi(uv.x * 15) >= REF.size():
				scene.free();return {}
		found[n] = mi.mesh
	scene.free()
	if found.size() != BASE.size() + EXTRA.size():return {}
	sources[path] = found
	return found

static func for_style(st, path = PATH) -> Dictionary:
	var src = load_parts(path)
	if src.is_empty():return {}
	var palette = REF.duplicate()
	for pair in [[1,"skin"],[2,"shirt"],[3,"pants"],[4,"hair"],[5,"shoes"],[6,"hat"],[7,"pack_color"],[8,"vest_color"]]:
		palette[pair[0]] = st.get(pair[1], REF[pair[0]])
	var hair = st.get("hair_style", "short")
	if not hair in ["short", "bun", "long", "cap", "beanie", "sunhat", "bald"]:hair = "short"
	if not st.has("hat"):
		if hair == "sunhat":palette[6] = "F0D9A0"
		elif hair == "beanie":palette[6] = "C65A3A"
	palette[9] = Color(palette[1]).lerp(Color("EA8B84"), .36).to_html(false)
	var fat = st.get("fat", 1.0)
	var key = str([path,palette,hair,fat,st.get("apron",false),st.get("backpack",false),st.get("vest",false),st.get("glasses",false)])
	if variants.has(key):return variants[key]
	if path==PATH:
		load_baked(src)
		if baked.has(key):
			variants[key]=baked[key];return variants[key]
	if "--s7-bake" in OS.get_cmdline_user_args():recorded_styles[key]=st.duplicate(true)
	var profile_t=Prof.start()
	# Reuse per-region factors instead of decoding two hex colours per vertex.
	var factors=[]
	for r in REF.size():
		var wanted=Color(palette[r]).srgb_to_linear();var reference=Color(REF[r]).srgb_to_linear()
		factors.append(Vector3(wanted.r/reference.r,wanted.g/reference.g,wanted.b/reference.b))
	var groups = {}
	for n in BASE:groups[n] = [n]
	if hair != "bald":groups.Head.append("Hair_" + hair)
	if st.get("glasses",false):groups.Head.append("Glasses")
	for pair in [["apron","Apron"],["backpack","Pack"],["vest","Vest"]]:
		if st.get(pair[0],false):groups.Torso.append(pair[1])
	var result = {}
	var triangles = 0
	for target in BASE:
		# S6 startup: singleton limbs/eyes need no second upload via SurfaceTool.
		var merged = SurfaceTool.new() if groups[target].size()>1 else null
		if merged!=null:merged.begin(Mesh.PRIMITIVE_TRIANGLES)
		for n in groups[target]:
			var a = src[n].surface_get_arrays(0)
			var colours: PackedColorArray = a[Mesh.ARRAY_COLOR].duplicate()
			var vertices: PackedVector3Array = a[Mesh.ARRAY_VERTEX].duplicate()
			var normals: PackedVector3Array = a[Mesh.ARRAY_NORMAL].duplicate()
			for i in colours.size():
				var region = roundi(a[Mesh.ARRAY_TEX_UV][i].x * 15)
				var c = colours[i]
				var factor=factors[region]
				colours[i] = Color(minf(c.r*factor.x,1),minf(c.g*factor.y,1),minf(c.b*factor.z,1),1)
				if n in ["Torso", "Vest", "Apron", "Pack"]:
					vertices[i] *= Vector3(fat,1,fat)
					normals[i] = (normals[i] / Vector3(fat,1,fat)).normalized()
			a[Mesh.ARRAY_COLOR] = colours;a[Mesh.ARRAY_VERTEX] = vertices;a[Mesh.ARRAY_NORMAL] = normals
			var tinted = ArrayMesh.new()
			tinted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a)
			triangles += a[Mesh.ARRAY_INDEX].size()/3
			if merged!=null:merged.append_from(tinted,0,Transform3D.IDENTITY)
			else:
				tinted.surface_set_material(0,Art.material());result[target]=tinted
		if merged!=null:
			merged.set_material(Art.material())
			result[target] = merged.commit()
	if triangles > 1800:return {}
	Prof.end("person tint merge upload",profile_t)
	variants[key] = result
	return result

static func attach(parent, mesh, name_):
	var mi = MeshInstance3D.new()
	mi.name = name_;mi.mesh = mesh;mi.material_override = Art.material()
	# Millimetre dot eyes lie inside the head's shadow silhouette. Keep their
	# visible/emote meshes but avoid hundreds of redundant shadow submissions.
	if name_ in ["EyeL","EyeR"]:mi.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi
