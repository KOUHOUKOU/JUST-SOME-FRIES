extends RefCounted
## Visual-only batched decor; no per-lamp process, light, collision or gameplay RNG.
var halos=[]
var halo_nodes=[]
var heavy_nodes=[]
var halo_mat: ShaderMaterial
var haze_mat: ShaderMaterial
var sea_mat: ShaderMaterial
var quality=0
var lite=false
var night=0.0

func _init():
	halo_mat=ShaderMaterial.new();halo_mat.shader=preload("res://shaders/cover_halo.gdshader")
	haze_mat=ShaderMaterial.new();haze_mat.shader=preload("res://shaders/cover_haze.gdshader")

func lamp_at(pos, diameter=2.8):
	halos.append([pos,diameter])

func halo_batch(parent, points):
	var mesh=QuadMesh.new();mesh.size=Vector2.ONE
	var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=mesh;mm.instance_count=points.size()
	for i in points.size():mm.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*points[i][1]),points[i][0]))
	var mi=MultiMeshInstance3D.new();mi.name="CoverLightHalos";mi.multimesh=mm;mi.material_override=halo_mat
	mi.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi);halo_nodes.append(mi)
	return mi

func finish(w):
	# Same house windows, overlay outside glass, merged with the existing window material.
	for house in preload("res://scripts/art/scenery_parts.gd").catalog.houses:
		for c in house.commands:
			if c.key!="window":continue
			var p=Vector3(c.pos[0],c.pos[1],c.pos[2]);var front=p.z>house.params[1]
			p.z+=0.06 if front else -0.06
			w.B.box(p,Vector3(.86,1.16,.018),"FFFFFF",false,Vector3.ZERO,0.0,"window")
			lamp_at(p,2.3)
	for ends in [[Vector3(-16,4.1,2.5),Vector3(-3,4.1,2.5)],[Vector3(-14,3.5,9.2),Vector3(2,3.5,9.2)],[Vector3(-2.7,4.0,30),Vector3(-2.7,4.0,46)],[Vector3(4.7,4.0,30),Vector3(4.7,4.0,46)]]:
		var prev=ends[0]
		for i in range(1,13):
			var u=i/12.0;var p=ends[0].lerp(ends[1],u)-Vector3(0,sin(u*PI)*.62,0)
			var d=p-prev
			w.B.box((p+prev)*.5,Vector3(.025,.025,d.length()),"564951",false,Vector3(rad_to_deg(-asin(d.normalized().y)),rad_to_deg(atan2(d.x,d.z)),0))
			w.B.ball(p-Vector3(0,.12,0),.105,"FFE2A8",Vector3.ONE,0,false,"lamp")
			lamp_at(p-Vector3(0,.12,0),1.25);prev=p
	# Cafe rail globes reuse existing shared lamp and static district batches.
	for x in [-14.0,-6.0,2.0]:
		var p=Vector3(x,1.48,9.2)
		w.B.cyl(p-Vector3(0,.28,0),.045,.56,"685845",false)
		w.B.ball(p,.16,"FFE2A8",Vector3.ONE,0,false,"lamp")
		lamp_at(p,1.55)
	halo_batch(w.map,halos)
	set_quality(quality,lite)

func wheel_lights(wheel, lamp_material):
	var mesh=SphereMesh.new();mesh.radius=.19;mesh.height=.38;mesh.radial_segments=6;mesh.rings=3
	var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=mesh;mm.instance_count=24
	var points=[]
	for i in 24:
		var a=TAU*i/24.0;var p=Vector3(cos(a)*10,sin(a)*10,-.24)
		mm.set_instance_transform(i,Transform3D(Basis.IDENTITY,p));points.append([p,2.1])
	var mi=MultiMeshInstance3D.new();mi.name="CoverWheelBulbs";mi.multimesh=mm;mi.material_override=lamp_material
	mi.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;wheel.add_child(mi)
	halo_batch(wheel,points)

func distant(parent):
	var rng=RandomNumberGenerator.new();rng.seed=8042
	var sphere=SphereMesh.new();sphere.radial_segments=14;sphere.rings=6;sphere.radius=1;sphere.height=2
	# S6: one reusable low ridge mesh, with unequal shoulders instead of round domes.
	var ridge=_ridge_mesh()
	for layer in 3:
		var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in 15:
			var a=-2.75+i*.38+layer*.12;var dist=640+layer*170
			var p=Vector3(sin(a)*dist,-18+layer*4,-cos(a)*dist-90)
			var b=Basis.from_euler(Vector3(0,rng.randf()*TAU,0)).scaled(Vector3(rng.randf_range(100,165),rng.randf_range(37,73),rng.randf_range(70,130)))
			st.append_from(ridge,0,Transform3D(b,p))
		var mesh=st.commit();var arr=mesh.surface_get_arrays(0);var cols=PackedColorArray()
		for v in arr[Mesh.ARRAY_VERTEX]:cols.append(Color(.28+layer*.065,.39+layer*.04,.48+layer*.05))
		arr[Mesh.ARRAY_COLOR]=cols;var painted=ArrayMesh.new();painted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arr)
		var mi=MeshInstance3D.new();mi.name="CoverHills"+str(layer);mi.mesh=painted;mi.material_override=haze_mat
		mi.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(mi)
		if layer>0:heavy_nodes.append(mi)
	_horizon_island(parent)

func _ridge_mesh():
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings=[[1.0,-.35],[.85,.2],[.50,.52]]
	for j in 2:
		for i in 12:
			var pts=[]
			for spec in [[j,i],[j,(i+1)%12],[j+1,i],[j+1,(i+1)%12]]:
				var a=TAU*spec[1]/12.0;var k=int(spec[0]);var r=rings[k][0]*(1+.16*sin(a*3+.7))
				pts.append(Vector3(cos(a)*r,rings[k][1]+sin(a*2+.4)*.06*k,sin(a)*r))
			for idx in [0,1,2,1,3,2]:st.add_vertex(pts[idx])
	for i in 12:
		var a=i*TAU/12;var b=(i+1)*TAU/12
		for p in [Vector3(cos(a)*.50*(1+.16*sin(a*3+.7)),.52+sin(a*2+.4)*.12,sin(a)*.50*(1+.16*sin(a*3+.7))),Vector3(cos(b)*.50*(1+.16*sin(b*3+.7)),.52+sin(b*2+.4)*.12,sin(b)*.50*(1+.16*sin(b*3+.7))),Vector3(.03,.60,-.02)]:st.add_vertex(p)
	st.generate_normals();st.index();return st.commit()

func set_quality(level, web_lite):
	quality=level;lite=web_lite
	var heavy=level<2 and not web_lite
	for n in halo_nodes:n.visible=heavy and night>.005
	for n in heavy_nodes:n.visible=heavy
	if sea_mat!=null:sea_mat.set_shader_parameter("glitter_enabled",heavy)

func apply(u, horizon, sun_dir):
	night=smoothstep(.48,.93,u)
	halo_mat.set_shader_parameter("night",night)
	haze_mat.set_shader_parameter("haze_color",horizon.lerp(Color("969DC7"),.48))
	set_quality(quality,lite)
	if sea_mat!=null:
		sea_mat.set_shader_parameter("day_t",u)
		sea_mat.set_shader_parameter("sky_tint",horizon.lerp(Color("879CCA"),.32))
		sea_mat.set_shader_parameter("sun_direction",sun_dir)

func _painted(mesh, colour):
	var arrays=mesh.get_mesh_arrays();var colours=PackedColorArray()
	for v in arrays[Mesh.ARRAY_VERTEX]:colours.append(Color(colour))
	arrays[Mesh.ARRAY_COLOR]=colours
	var painted=ArrayMesh.new();painted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return painted

func _horizon_island(parent):
	# One non-solid, merged distant silhouette. Existing playable lighthouse stays intact.
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var at=Vector3(-95,0,340)
	var island=SphereMesh.new();island.radius=1;island.height=2;island.radial_segments=12;island.rings=5
	var coast=preload("res://scripts/art/s6_parts.gd").mesh_at("headland")
	if coast!=null:
		var arr=coast.surface_get_arrays(0);var cols:PackedColorArray=arr[Mesh.ARRAY_COLOR]
		for i in cols.size():cols[i]=cols[i].linear_to_srgb()
		arr[Mesh.ARRAY_COLOR]=cols
		var painted=ArrayMesh.new();painted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arr)
		st.append_from(painted,0,Transform3D(Basis.IDENTITY.scaled(Vector3(.92,.43,.68)),at))
		var cap=CylinderMesh.new();cap.top_radius=24.25;cap.bottom_radius=24.25;cap.height=.14;cap.radial_segments=24
		st.append_from(_painted(cap,"78835B"),0,Transform3D(Basis.IDENTITY.scaled(Vector3(.92,1,.68)),at+Vector3(0,10.3,0)))
	else:
		st.append_from(_painted(island,"59667B"),0,Transform3D(Basis.IDENTITY.scaled(Vector3(48,14,32)),at-Vector3(0,3,0)))
	for i in 5:
		var cyl=CylinderMesh.new();cyl.top_radius=2.3-i*.16;cyl.bottom_radius=2.4-i*.16;cyl.height=4.5;cyl.radial_segments=10
		st.append_from(_painted(cyl,"EFDACA" if i%2==0 else "BC6962"),0,Transform3D(Basis.IDENTITY,at+Vector3(3,12+i*4.5,0)))
	var roof=CylinderMesh.new();roof.top_radius=0;roof.bottom_radius=3;roof.height=2.7;roof.radial_segments=8
	st.append_from(_painted(roof,"AD626B"),0,Transform3D(Basis.IDENTITY,at+Vector3(3,34,0)))
	lamp_at(at+Vector3(3,31,0),9)
	for x in [-25.0,25.0]:
		var pole=CylinderMesh.new();pole.top_radius=.45;pole.bottom_radius=.65;pole.height=17;pole.radial_segments=6
		st.append_from(_painted(pole,"D8D6D8"),0,Transform3D(Basis.IDENTITY,at+Vector3(x,17,3)))
		var blade=BoxMesh.new();blade.size=Vector3(.7,9,.16)
		for i in 3:
			var a=TAU*i/3.0;var basis=Basis.from_euler(Vector3(0,0,a))
			st.append_from(_painted(blade,"E3DAD7"),0,Transform3D(basis,at+Vector3(x,25.5,3)+basis*Vector3(0,4.5,0)))
	var mi=MeshInstance3D.new();mi.name="CoverHorizonIsland";mi.mesh=st.commit();mi.material_override=haze_mat
	mi.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(mi);heavy_nodes.append(mi)
