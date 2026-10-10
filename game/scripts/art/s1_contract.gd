extends SceneTree
const Art=preload("res://scripts/art/art_loader.gd")
const Parts=preload("res://scripts/art/gull_parts.gd")
const Wear=preload("res://scripts/art/p2_parts.gd")
var Gull
func _initialize():call_deferred("check")
func check():
	assert(OS.get_user_data_dir().replace("\\","/").contains("/art_src/s1/runtime/"))
	Gull=load("res://scripts/player/gull_visual.gd")
	var g=Gull.new();g.plain=true;root.add_child(g);g.build();assert(g.authored)
	var fallback=Gull.new();fallback.plain=true;fallback.authored_path="res://assets/models/missing_s1.glb"
	root.add_child(fallback);fallback.build();assert(not fallback.authored)
	assert(Parts.load_parts("res://assets/models/p0_rounded_cube.glb").is_empty())
	var tris=0;var flat_triangles=0
	for mi in g.authored_parts.values():
		assert(mi.material_override==Art.material());assert(mi.mesh.get_surface_count()==1)
		var a=mi.mesh.surface_get_arrays(0);var idx=a[Mesh.ARRAY_INDEX];var normals=a[Mesh.ARRAY_NORMAL]
		tris+=idx.size()/3
		for t in range(0,idx.size(),3):
			assert(normals[idx[t]].is_equal_approx(normals[idx[t+1]]) and normals[idx[t]].is_equal_approx(normals[idx[t+2]]),"smoothed triangle")
			flat_triangles+=1
	assert(tris>=500 and tris<=900)
	var samples=0
	for mode_ in ["throttle","tumble","brake","boost","ground","glide","throttle","ground"]:
		for i in 16:
			g.pose(mode_,float(i)/16,false,1.0/30);fallback.pose(mode_,float(i)/16,false,1.0/30)
			for side in [-1.0,1.0]:
				assert(g.shoulder[side].transform.is_equal_approx(fallback.shoulder[side].transform))
				assert(g.elbow[side].transform.is_equal_approx(fallback.elbow[side].transform))
			assert(g.head.transform.is_equal_approx(fallback.head.transform))
			assert(g.tail.transform.is_equal_approx(fallback.tail.transform));assert(g.legs.visible==fallback.legs.visible)
			assert(g.beak_socket.transform.is_equal_approx(fallback.beak_socket.transform))
			samples+=1
	assert(g.trail_l.get_parent()==g.elbow[-1.0] and g.trail_r.get_parent()==g.elbow[1.0])
	assert(g.trail_l.position==fallback.trail_l.position and g.trail_r.position==fallback.trail_r.position)
	var original=g.authored_parts.Head.mesh;g.tint_pale(Gull.pale_color(1));assert(g.authored_parts.Head.mesh!=original)
	g.reset_plain();g.white_mat.albedo_color=Gull.WHITE;g._sync_authored_colours();assert(g.authored_parts.Head.mesh==original)
	var kinds=["hat","sailor","topper","beret","glasses","shades","necklace","bowtie","scarf","pipe","hawaii","stripes","coat","balloon","socks","cloud","sun","skybow","meteor"]
	var checked=0
	for bro in [false,true]:
		g.bro_style=bro;fallback.bro_style=bro
		for kind in (kinds if not bro else ["topper","shades","necklace","coat"]):
			g.wear(kind,true);fallback.wear(kind,true)
			assert(g.worn[kind].transform.is_equal_approx(fallback.worn[kind].transform))
			assert(g.worn[kind].get_node_or_null("Item" if kind!="meteor" else "Spin")!=null)
			if kind!="meteor":assert(fallback.worn[kind].get_node_or_null("Item")==null)
			checked+=1;g.strip_all();fallback.strip_all()
	# Missing wearable keeps the original pieces; never partially clear a root.
	Wear.cache["wear_hat"]={};g.wear("hat",true);assert(g.worn.hat.get_node_or_null("Item")==null)
	var report={"triangles":tris,"parts":g.authored_parts.size(),"materials":1,"flat_triangles":flat_triangles,"pivot_samples":samples,"wearable_cases":checked,"fallback":"missing gull, invalid gull, missing wearable PASS","tints_trails_socket":"PASS"}
	var f=FileAccess.open("res://../art_src/s1/contract.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"\t"))
	print("[S1 CONTRACT] PASS ",JSON.stringify(report));g.free();fallback.free();quit()
