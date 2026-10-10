extends RefCounted
## Visual replacements only. Builders retain their complete procedural fallback.
const Art = preload("res://scripts/art/art_loader.gd")
static var enabled = true
static var cache = {}
static var tints = {}
static var transforms = {}
static var fry_materials = {}
static var held_cache = {}

static func parts(asset):
	if not enabled:return {}
	if cache.has(asset):return cache[asset]
	var scene = Art.instantiate("res://assets/models/"+asset+".glb")
	if scene == null:return {}
	var out = {}
	var xforms = {}
	for mi in Art.meshes(scene):
		if mi.mesh.get_surface_count()!=1:
			scene.free();return {}
		out[str(mi.name)] = mi.mesh
		xforms[str(mi.name)] = mi.transform
	scene.free();cache[asset] = out;transforms[asset]=xforms
	return out

static func tinted(mesh, colour, region = 2, reference = "D96554"):
	var key = str([mesh.get_instance_id(),colour,region,reference])
	if tints.has(key):return tints[key]
	var a = mesh.surface_get_arrays(0)
	var c: PackedColorArray = a[Mesh.ARRAY_COLOR].duplicate()
	var ref = Color(reference).srgb_to_linear()
	var target = Color(colour).srgb_to_linear()
	for i in c.size():
		if roundi(a[Mesh.ARRAY_TEX_UV][i].x*15)==region:
			c[i] = Color(c[i].r*target.r/ref.r,c[i].g*target.g/ref.g,c[i].b*target.b/ref.b,1)
	a[Mesh.ARRAY_COLOR] = c
	var result = ArrayMesh.new();result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a)
	tints[key] = result;return result

static func attach(parent, mesh, name_, material = null):
	var mi = MeshInstance3D.new();mi.name = name_;mi.mesh = mesh
	mi.material_override = Art.material() if material == null else material
	parent.add_child(mi);return mi

static func clear_meshes(root):
	for mi in Art.meshes(root):
		if is_instance_valid(mi):mi.free()

static func fry_material(glow):
	if not fry_materials.has(glow):
		var mat = ShaderMaterial.new()
		mat.shader = preload("res://shaders/fry_clay.gdshader")
		mat.set_shader_parameter("glow",glow);fry_materials[glow] = mat
	return fry_materials[glow]

static func fry(f):
	var kind = "ordinary" if f.ftype=="ordinary" else ("star" if f.ftype=="star" else f.carrier)
	if not kind in ["ordinary","star","plate","hand","cone"]:kind="box"
	var src = parts("fry_"+kind)
	if not src.has("Sticks") or (kind!="ordinary" and not src.has("Carrier")):return false
	clear_meshes(f.visual)
	var glow = 0.0 if kind=="ordinary" else (.9 if kind=="star" else (.25 if f.ftype=="tutorial" else .7))
	attach(f.visual,src.Sticks,"Sticks",Art.material() if kind=="ordinary" else fry_material(glow))
	if src.has("Carrier"):
		var col = f.type_color() if kind=="star" else f._body_color()
		var mesh = tinted(src.Carrier,col)
		attach(f.visual,mesh,"Carrier",fry_material(1.3 if kind=="star" else (.15 if f.ftype=="tutorial" else 1.0)))
	if kind=="hand":
		for mi in Art.meshes(f.visual):mi.scale=Vector3.ONE*.8
	return true

static func wear(g, root, kind):
	# S1 garments fit the authored big head. Missing gull keeps original garments.
	if not g.authored:return false
	var asset = "wear_"+("bro_" if g.bro_style and kind in ["coat","topper","shades","necklace"] else "")+kind
	var src = parts(asset)
	var required=["Item"]
	if kind=="meteor":required=["Spin"]
	elif kind=="scarf":required=["Item","ScarfTail"]
	elif kind=="balloon":required=["Item","Balloon"]
	if not src.has_all(required):return false
	# Preserve particle nodes and existing alpha/glow overlays. Animated names remain.
	for mi in Art.meshes(root):
		if kind=="meteor" and mi.name!="Spin":continue
		if kind=="sun" and mi.mesh is QuadMesh:continue
		mi.free()
	for name_ in src:
		var mat = Art.material()
		if kind=="meteor":
			mat=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true
			mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
		if kind in ["cloud","skybow"]:
			# Keep the original see-through effect and depth policy.
			mat = StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true
			mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED
			mat.albedo_color=Color(1,1,1,.6 if kind=="cloud" else .3);mat.roughness=.8
			if kind=="skybow":mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;mat.cull_mode=BaseMaterial3D.CULL_DISABLED
		attach(root,src[name_],name_,mat)
	return true

static func human_item(root, kind):
	if not enabled:return
	var source=Art.meshes(root)
	if source.size()<2:return
	# Existing held-item root remains removable/animatable. Merge only its static meshes.
	var key=kind
	for mi in source:key+=str([mi.transform,mi.material_override.albedo_color])
	if not held_cache.has(key):
		var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for mi in source:
			var a=mi.mesh.surface_get_arrays(0)
			var colours=PackedColorArray();colours.resize(a[Mesh.ARRAY_VERTEX].size())
			colours.fill(mi.material_override.albedo_color.srgb_to_linear())
			a[Mesh.ARRAY_COLOR]=colours
			var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a)
			st.append_from(mesh,0,mi.transform)
		st.set_material(Art.material());held_cache[key]=st.commit()
	clear_meshes(root);attach(root,held_cache[key],"HeldItem")

static func dog(d, coat):
	var src=parts("dog_parts")
	if not src.has_all(["Body","Head","Tail","Leg"]):return false
	# Mesh-only children; never remove the live head/tail/leg references.
	for mi in Art.meshes(d.body):
		if not mi in d.legs:mi.free()
	for pair in [[d.body,"Body"],[d.head,"Head"],[d.tail,"Tail"]]:
		attach(pair[0],tinted(src[pair[1]],coat,1,"B98B61"),pair[1])
	for leg in d.legs:
		leg.mesh=tinted(src.Leg,coat,1,"B98B61");leg.material_override=Art.material()
	return true

static func fish(f):
	var src=parts("fish_"+f.species)
	if not src.has_all(["Body","Tail"]):return false
	clear_meshes(f.visual)
	for n in src:
		var mi=attach(f.visual,src[n],n)
		mi.transform=transforms["fish_"+f.species][n]
	return true
