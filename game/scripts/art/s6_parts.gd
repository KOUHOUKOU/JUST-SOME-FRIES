extends RefCounted
## Optional, static visual dressing only. Every replacement returns false on failure.
const Art=preload("res://scripts/art/art_loader.gd")
const LIMIT={"wheat":120,"leaves":120,"ivy":120,"headland":300}
static var enabled=true
static var cache={}
static var used={}
static var crop_tools={}

static func mesh_at(key):
	if not enabled or not LIMIT.has(key):return null
	if cache.has(key):return cache[key]
	var node=Art.instantiate("res://assets/models/s6/"+key+".glb")
	if node==null:return null
	var parts=Art.meshes(node)
	if parts.size()!=1 or parts[0].mesh.get_surface_count()!=1:node.free();return null
	var mesh=parts[0].mesh;var a=mesh.surface_get_arrays(0)
	if a[Mesh.ARRAY_INDEX]==null or a[Mesh.ARRAY_INDEX].size()/3>LIMIT[key]:node.free();return null
	mesh.surface_set_material(0,Art.material());cache[key]=mesh;node.free();return mesh

static func place(w,key,p,scale_v=Vector3.ONE,yaw=0.0):
	var mesh=mesh_at(key)
	if mesh==null:return false
	w.B.authored(mesh,Transform3D(Basis.from_euler(Vector3(0,yaw,0)).scaled(scale_v),p))
	used[key]=used.get(key,0)+1
	return true

static func crops(w,p,row):
	if mesh_at("leaves")==null or mesh_at("wheat")==null:return false
	var key=Vector2i(floori(p.x/50),floori(p.z/50))
	if not crop_tools.has(key):
		var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_material(Art.material());crop_tools[key]=st
	if row%2==0:crop_tools[key].append_from(mesh_at("wheat"),0,Transform3D(Basis.IDENTITY,p))
	else:
		for dx in [-1.05,1.05]:
			crop_tools[key].append_from(mesh_at("leaves"),0,Transform3D(Basis.IDENTITY,Vector3(p.x+dx,w.gh(p.x+dx,p.z)+.03,p.z)))
	return true

static func flush_crops(w):
	for key in crop_tools:
		var mi=MeshInstance3D.new();mi.name="S6Crops_"+str(key);mi.mesh=crop_tools[key].commit();mi.material_override=Art.material()
		mi.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;w.map.add_child(mi)
	crop_tools.clear()

static func merge_rotor_visuals(rotor):
	# Same box vertices/transforms/material colours; the moving collider nodes stay.
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var old=[]
	for mi in rotor.get_children():
		if not mi is MeshInstance3D:continue
		var a=mi.mesh.get_mesh_arrays();var colours=PackedColorArray()
		for v in a[Mesh.ARRAY_VERTEX]:colours.append(mi.material_override.albedo_color.srgb_to_linear())
		a[Mesh.ARRAY_COLOR]=colours;var painted=ArrayMesh.new();painted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a)
		st.append_from(painted,0,mi.transform);old.append(mi)
	if old.is_empty():return
	for mi in old:mi.free()
	var result=MeshInstance3D.new();result.mesh=st.commit();result.material_override=Art.material();result.name="S6RotorVisual";rotor.add_child(result)

static func decorate(w):
	if mesh_at("ivy")==null:return
	var b=w.B
	# Marina office: visible bearing structure reaches the water; no added solids.
	b.box(Vector3(-36,-.14,22.5),Vector3(7.35,.25,5.35),"977753",false)
	for x in [-39.1,-36.0,-32.9]:
		for z in [20.1,24.9]:
			b.box(Vector3(x,-1.1,z),Vector3(.32,1.95,.32),"6B594A",false)
	for x in [-38.6,-36,-33.4]:
		b.box(Vector3(x,-.55,25.0),Vector3(2.3,.17,.17),"B29470",false,Vector3(0,0,20))
	# Existing windows become framed openings; the office footprint stays fixed.
	for x in [-38,-34]:
		b.box(Vector3(x,2.4,25.11),Vector3(1.42,1.32,.07),"F4E4C7",false)
		b.box(Vector3(x,2.4,25.16),Vector3(1.17,1.07,.06),"",false,Vector3.ZERO,0,"window")
	# Terraced rock ledges: sparse hanging foliage, deterministic and off the stairs.
	for z in [-30.8,-51.8,-72.8]:
		for x in [-60,-46,-34,-16,15,31,45]:
			place(w,"ivy",Vector3(x,w.gh(x,z)-1.7,z+.65),Vector3(.8+.18*sin(x),1,.8))
	# Warehouse in the crane yard: warm roof trim, pilasters, loading doors.
	for x in [87.15,92.6,98,103.4,108.85]:
		b.box(Vector3(x,4.0,-26.86),Vector3(.18,8.0,.12),"E7D4AF",false)
	for x in [93.5,102.5]:
		b.box(Vector3(x,1.7,-26.80),Vector3(3.4,3.4,.13),"55797E",false)
		for j in 4:b.box(Vector3(x, .5+j*.75,-26.70),Vector3(3.2,.045,.04),"91ABA0",false)
	b.box(Vector3(98,8.02,-26.5),Vector3(22.8,.18,.38),"ECD8AF",false)
	# Yard markings are small painted strips on the existing floor, not new routes.
	for x in [57,69,81,93,105]:
		b.box(Vector3(x,.015,-3.2),Vector3(4.3,.012,.12),"DEC991",false)
	# Church: red eaves, cream quoins and a bell opening on the visible tower side.
	var y=w.gh(-26,-62)
	for x in [-29.28,-22.72]:b.box(Vector3(x,y+3,-54),Vector3(.22,6,.16),"E8CA9C",false)
	for yy in [1.1,6.8,14.5,19.8]:b.box(Vector3(-26,y+yy,-67.5),Vector3(4.68,.20,4.68),"E7CFA8",false)
	for x in [-28.34,-23.66]:
		b.box(Vector3(x,y+16.6,-67.5),Vector3(.08,2.5,1.7),"53454B",false)
	# Farm barn: cream corner boards, gable vent and modest boarding at the door.
	var fy=w.gh(102,-66)
	for x in [97.0,107.0]:
		for z in [-72.98,-59.02]:b.box(Vector3(x,fy+3.2,z),Vector3(.16,6.4,.16),"ECD6AF",false)
	for z in [-72.8,-70.5,-68.2,-65.9,-63.6,-61.3,-59.2]:
		b.box(Vector3(96.95,fy+3.2,z),Vector3(.09,6.3,.10),"D87955",false)
	b.box(Vector3(96.87,fy+2.2,-66),Vector3(.08,4.15,.13),"D2B080",false,Vector3(45,0,0))
	# Playground slide: rolled edges follow the existing slope; tiny gable on canopy.
	for z in [7.52,8.48]:b.box(Vector3(40.6,1.05,z),Vector3(3.2,.12,.08),"EAC570",false,Vector3(0,0,-34))
	b.prism(Vector3(38,3.50,8),Vector3(2.85,.52,2.85),"C96743",false)
	for z in [7.0,9.0]:
		b.box(Vector3(38,2.38,z),Vector3(2.0,.08,.08),"F0DEC2",false)
		for x in [37.2,38.8]:b.box(Vector3(x,2.22,z),Vector3(.06,.40,.06),"F0DEC2",false)
