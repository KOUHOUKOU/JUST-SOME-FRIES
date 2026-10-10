extends SceneTree
func _initialize():
	var box=BoxMesh.new();var prism=PrismMesh.new();var sphere=SphereMesh.new();sphere.radial_segments=10;sphere.rings=6
	var cylinder=CylinderMesh.new();cylinder.radial_segments=10
	var cone=CylinderMesh.new();cone.radial_segments=10;cone.top_radius=0
	var meshes={"box":box,"prism":prism,"ball":sphere,"cyl":cylinder,"cone":cone}
	var tris={}
	for k in meshes:tris[k]=meshes[k].surface_get_arrays(0)[Mesh.ARRAY_INDEX].size()/3
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://../art_src/p1b/baseline/catalog.json"))
	var out={"primitive_tris":tris,"houses":[],"trees":[],"house_district_batches":{},"house_colours":{},"tree_colours":{}}
	for h in data.houses:
		var count=0;var colours={}
		for c in h.commands:
			count+=tris[c.kind];colours[c.key if c.key!="" else c.colour]=true
			out.house_colours[c.key if c.key!="" else c.colour]=true
		out.houses.append({"signature":h.signature,"old_tris":count,"old_primitives":h.commands.size(),"old_material_groups":colours.size()})
		out.house_district_batches[str(Vector2i(floori(h.params[0]/50),floori(h.params[1]/50)))]=true
	for t in data.trees:
		if t.kind==2:continue
		var count=0;var colours={}
		for c in t.commands:
			count+=tris[c.kind];colours[c.colour]=true;out.tree_colours[c.colour]=true
		out.trees.append({"kind":t.kind,"old_tris":count,"old_primitives":t.commands.size(),"old_material_groups":colours.size()})
	FileAccess.open("res://../art_src/p1b/numbers.json",FileAccess.WRITE).store_string(JSON.stringify(out,"\t"))
	print("[P1B NUMBERS] old primitive triangles ",tris," house batches ",out.house_district_batches.size())
	quit()
