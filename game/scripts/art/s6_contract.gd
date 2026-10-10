extends "res://scripts/art/s5_contract.gd"
const S6=preload("res://scripts/art/s6_parts.gd")
func check():
	report.s6={"assets":{},"fallback":false,"person_geometry_equal":true}
	for name in S6.LIMIT:
		var mesh=S6.mesh_at(name);assert(mesh!=null)
		var a=mesh.surface_get_arrays(0);var v=a[Mesh.ARRAY_VERTEX];var idx=a[Mesh.ARRAY_INDEX];var ns=a[Mesh.ARRAY_NORMAL]
		for j in range(0,idx.size(),3):
			var normal=(v[idx[j+1]]-v[idx[j]]).cross(v[idx[j+2]]-v[idx[j]])
			assert(normal.length_squared()>1e-14)
			assert(ns[idx[j]].dot(ns[idx[j+1]])>.998)
			if name=="headland":
				var center=(v[idx[j]]+v[idx[j+1]]+v[idx[j+2]])/3
				# Grass lip can slope gently toward the cap; its normal points up.
				assert(ns[idx[j]].y>.95 or ns[idx[j]].dot(Vector3(center.x,0,center.z))>0,"Headland inward wall normal")
		report.s6.assets[name]={"tris":idx.size()/3,"surfaces":mesh.get_surface_count(),"bounds":str(mesh.get_aabb())}
	S6.enabled=false;assert(S6.mesh_at("headland")==null and not S6.crops(null,Vector3.ZERO,0));S6.enabled=true
	assert(S6.mesh_at("missing")==null);report.s6.fallback=true
	var old=load("res://../art_src/s6/bench_sources/game/scripts/art/person_parts.gd")
	for style in [{},{"hair_style":"sunhat","fat":1.3,"apron":true,"vest":true,"backpack":true,"glasses":true},{"skin":"7A4B33","shirt":"E3B590","hair_style":"bald"}]:
		var a=old.for_style(style);var b=Person.for_style(style)
		for key in a:
			var av=a[key].get_faces();var bv=b[key].get_faces();assert(av.size()==bv.size())
			for j in av.size():assert(av[j].is_equal_approx(bv[j]))
	super.check()
