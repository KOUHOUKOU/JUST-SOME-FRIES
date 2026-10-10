extends RefCounted
## Optional one-surface kit meshes. Static repeats share per-district vertex batches.
const Art=preload("res://scripts/art/art_loader.gd")
const LIMIT={"crag":200,"cliff":200,"rock":200,"bush":200,"flower":100,"rowboat":200,"barrel":200,"crate":200,"planks":200,"palm":500,"table":200,"chair":200,"plant":200,"plate":200,"drink":200}
static var enabled=true
static var cache={}
static var used={}

static func mesh_at(asset):
	if not enabled or not LIMIT.has(asset):return null
	if cache.has(asset):return cache[asset]
	var node=Art.instantiate("res://assets/art/kenney/"+asset+".glb")
	if node==null:return null
	var parts=Art.meshes(node)
	if parts.size()!=1 or parts[0].mesh.get_surface_count()!=1:
		node.free();return null
	var mesh=parts[0].mesh
	var a=mesh.surface_get_arrays(0)
	if a[Mesh.ARRAY_INDEX]==null or a[Mesh.ARRAY_INDEX].size()/3>LIMIT[asset]:
		node.free();return null
	# Importer guarantees base centre, metre units, baked transforms, COLOR_0.
	mesh.surface_set_material(0,Art.material());cache[asset]=mesh;node.free();return mesh

static func place(w,asset,p,scale_v=Vector3.ONE,yaw=0.0):
	var mesh=mesh_at(asset)
	if mesh==null:return false
	w.B.authored(mesh,Transform3D(Basis.from_euler(Vector3(0,yaw,0)).scaled(scale_v),p))
	used[asset]=used.get(asset,0)+1
	return true

static func setup(w):
	used={}
	# If the kit is unavailable the original primitives/materials remain the fallback.
	w.B.cover_batch=mesh_at("table")!=null
	var m=ShaderMaterial.new();m.shader=preload("res://shaders/decking.gdshader")
	w.B.set_special("deck",m)

static func ground(w):
	if mesh_at("rock")==null:return
	# Replace the S3 applied crags with a continuous, non-solid faceted rock skirt.
	# Terrain's original mesh/height and collision are retained below it.
	headland(w)
	# Break the town's three straight terrace banks with sparse inset rock faces.
	for z in [-29.3,-50.3,-71.3]:
		for x in [-62,-52,-42,-32,-20,-10,12,22,34,44]:
			var p=Vector3(x,w.gh(x,z)-1.7,z)
			var h=clampf((w.gh(x,z-2)-p.y-.1)/4.0,.15,.8)
			place(w,"cliff",p,Vector3(1.24+.24*sin(x*.31+z),h,.62),sin(x*.7)*.10)
	for p in [Vector2(-122,33),Vector2(-114,59),Vector2(-90,57),Vector2(-83,35),Vector2(-36,-32),Vector2(13,-53)]:
		place(w,"bush",Vector3(p.x,w.gh(p.x,p.y),p.y),Vector3.ONE*1.6)
		place(w,"flower",Vector3(p.x+.8,w.gh(p.x+.8,p.y),p.y))

static func headland(w):
	var mesh=preload("res://scripts/art/scenery_parts.gd").mesh_at("res://assets/models/s7/headland.glb")
	if mesh!=null:
		w.B.authored(mesh,Transform3D(Basis.IDENTITY,Vector3(-102,0,40)))
		# Low broken tidal fragments, single-surface CC0 rocks in existing batches.
		var skirt=SurfaceTool.new();skirt.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in 12:
			var a=TAU*i/12.0+.12
			var radius=52.0+3.6*sin(a*3+.5)+1.8*sin(a*7)-maxf(0,cos(a))*13.0
			var p=Vector3(-102+cos(a)*radius,-.85,40+sin(a)*radius)
			var rock=mesh_at("rock")
			if rock!=null:skirt.append_from(rock,0,Transform3D(Basis.from_euler(Vector3(0,a+.4,0)).scaled(Vector3(1.2+.6*sin(i*2.1),.65+.4*cos(i),1.3)),p-Vector3(-102,0,40)))
		w.B.authored(skirt.commit(),Transform3D(Basis.IDENTITY,Vector3(-102,0,40)))
		w.map.get_node("Terrain").mesh.surface_get_material(0).set_shader_parameter("headland_shell",true)
		w.atmosphere.sea_mat.set_shader_parameter("headland_foam",true)
		return
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Procedural fallback follows the S7 12m cap. Only Terrain owns the solids.
	# This skirt is non-solid scenery, as is the authored replacement above.
	var rings=[[55.0,.0],[47.0,2.1],[36.0,7.0],[26.2,11.7],[24.25,12.02]]
	var colours=["796356","867060","756255","687C32"]
	for j in rings.size()-1:
		for i in 18:
			var points=[]
			for spec in [[j,i],[j,(i+1)%18],[j+1,i],[j+1,(i+1)%18]]:
				var k=int(spec[0]);var a=TAU*spec[1]/18.0
				if k>0 and k<4:a+=sin(a*7.0+k*.9)*.026
				var wobble=(sin(a*3.0+.8)+.6*sin(a*7.0+k*.7))*sin(PI*k/4.0)*1.15
				var coast=1.0 + (1.0-k/4.0)*(.09*sin(a*3.0+.4)+.05*cos(a*5.0))
				var radius=rings[k][0]*coast+wobble
				# Taper the east foot back into the existing coast beside the town.
				radius-=maxf(0.0,cos(a))*pow(1.0-k/4.0,2)*11.0
				var height=rings[k][1]+sin(a*5.0+k*.4)*sin(PI*k/4.0)*2.1
				points.append(Vector3(cos(a)*radius,height,sin(a)*radius))
			var shade=.94+.25*sin(i*2.1+j*.8)
			var c=Color(colours[j]);c=c.lerp(Color("514B64"),.40 if i%5 in [2,3] and j<3 else 0.0)
			c=Color(c.r*shade,c.g*shade,c.b*shade)
			st.set_color(c.srgb_to_linear())
			for idx in [0,1,2,1,3,2]:st.add_vertex(points[idx])
	st.generate_normals();st.index()
	w.B.authored(st.commit(),Transform3D(Basis.IDENTITY,Vector3(-102,0,40)))
	w.map.get_node("Terrain").mesh.surface_get_material(0).set_shader_parameter("headland_shell",true)

static func pier(w):
	if mesh_at("barrel")==null:return
	for p in [Vector3(-1.6,.4,29),Vector3(3.5,.4,72),Vector3(-10,.4,58),Vector3(-27,.3,29)]:
		place(w,"barrel",p)
	for p in [Vector3(3.5,.4,68),Vector3(-10,.4,59)]:
		place(w,"planks",p,Vector3(.8,1,2),.2)
	# Rowboats are non-solid moored decor, outside existing landing decks and routes.
	place(w,"rowboat",Vector3(-23,-.93,44.5),Vector3(1.3,1,1),.12)
	place(w,"rowboat",Vector3(-30,-.91,27.3),Vector3(1.1,1,.9),-.2)
	for p in [Vector3(-12,.34,29),Vector3(-20,.34,36),Vector3(-28,.34,42)]:
		w.B.cyl(p+Vector3(0,.14,0),.13,.28,"AF895E",false)
		w.B.cyl(p+Vector3(0,.29,0),.22,.10,"E3C38D",false)
		var ring=TorusMesh.new();ring.inner_radius=.22;ring.outer_radius=.32;ring.rings=12;ring.ring_segments=6
		w.B.cover_piece(ring,Color("CEB789"),Transform3D(Basis.IDENTITY,p+Vector3(.3,.04,0)))

static func cafe(w):
	if mesh_at("plate")==null:return
	for p in [Vector3(-11.75,.82,6.4),Vector3(-5.25,.82,8.4),Vector3(-1.2,.82,1.35)]:
		place(w,"plate",p)
		place(w,"drink",p+Vector3(.34,0,-.19))
	# Existing authored gameplay fries remain their only interactive counterparts.
	# Two small additional canopies over the existing tables; no added solids.
	umbrella(w,-5,.0,8,"C64E32",2.9,1.40)
	umbrella(w,-1,.0,1,"CC7732",2.9,1.20)
	for p in [Vector2(-14.5,1),Vector2(-4,1.2),Vector2(-15.5,3.4)]:
		place(w,"plant",Vector3(p.x+.5,w.gh(p.x,p.y)+.6,p.y),Vector3(.5,.5,.5))
	# Striped cloth fitted to the original cafe awning, with no extra collision.
	for k in 12:
		w.B.box(Vector3(-14.77+k*.96,3.626,.9),Vector3(.47,.018,2.59),"F4E8CC",false,Vector3(10,0,0))
	# Service counter under the existing canopy: non-solid visual frontage.
	w.B.box(Vector3(-6.1,.68,.2),Vector3(1.8,1.3,.48),"D58A68",false)
	w.B.box(Vector3(-6.1,1.35,.22),Vector3(1.95,.06,.58),"E9D0A1",false)

static func umbrella(w,x,y,z,col,height=2.75,radius=1.6):
	# 12 alternating canvas panels, fitted inside the old cone collider.
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 12:
		var a=i*TAU/12;var b=(i+1)*TAU/12
		st.set_color(Color(col if i%2==0 else "F4E9D3").srgb_to_linear())
		for p in [Vector3(0,height,0),Vector3(cos(b)*radius,height-.4,sin(b)*radius),Vector3(cos(a)*radius,height-.4,sin(a)*radius)]:st.add_vertex(p)
		# Valance and underside (opaque, no extra pass).
		var a0=Vector3(cos(a)*radius,height-.4,sin(a)*radius);var b0=Vector3(cos(b)*radius,height-.4,sin(b)*radius)
		for p in [a0,b0,b0-Vector3(0,.12,0),a0,b0-Vector3(0,.12,0),a0-Vector3(0,.12,0),Vector3(0,height-.03,0),a0,b0]:st.add_vertex(p)
	st.generate_normals();st.index();w.B.authored(st.commit(),Transform3D(Basis.IDENTITY,Vector3(x,y,z)))
	w.B.cyl(Vector3(x,y+(height-.15)*.5,z),.04,height-.15,"E8D6B0",false)
