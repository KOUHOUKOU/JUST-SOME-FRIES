extends SceneTree
const P2=preload("res://scripts/art/p2_parts.gd")
const Art=preload("res://scripts/art/art_loader.gd")
var report={"fries":[],"wear":{},"fish":{},"dog":{}}
func _initialize():call_deferred("check")
func counts(n):
	var tris=0;var draws=0
	for mi in Art.meshes(n):
		for s in mi.mesh.get_surface_count():
			var a=mi.mesh.surface_get_arrays(s);tris+=a[Mesh.ARRAY_INDEX].size()/3 if a[Mesh.ARRAY_INDEX]!=null else a[Mesh.ARRAY_VERTEX].size()/3;draws+=1
	return {"tris":tris,"draws":draws}
func check():
	var Fry=load("res://scripts/fries/fry.gd");var Gull=load("res://scripts/player/gull_visual.gd")
	var Dog=load("res://scripts/npc/dog.gd");var FishSpot=load("res://scripts/world/fish_spot.gd")
	assert(P2.parts("intentionally_missing_p2").is_empty())
	for kind in ["tutorial","red","orange","green","cyan","blue","purple","pink","star","ordinary"]:
		for carrier in ["box","plate","hand","cone"]:
			for tier in ([0] if kind in ["tutorial","ordinary"] else [1,2,3,4]):
				var pair=[]
				for old in [true,false]:
					P2.enabled=not old;var f=Fry.new();root.add_child(f);f.setup("FIXED_CONTRACT",kind,carrier,2,tier);f.set_process(false);pair.append(f)
				var old=pair[0];var f=pair[1];var c=counts(f.visual)
				assert(f.visual.get_node_or_null("Sticks")!=null,"Missing authored fry "+kind+carrier)
				assert(c.tris<=600 and c.draws<=2)
				assert(f.aim_point()==old.aim_point() and f.vision_info()==old.vision_info() and f.is_snatchable()==old.is_snatchable())
				assert(f.rng.state==old.rng.state and f.halo_base==old.halo_base and f.revealed==old.revealed)
				if kind=="ordinary":
					assert(f.vision_info()==null and f.visual.get_child(0).material_override==Art.material())
					f.go_plain();assert(f.halo_alpha==0 and f.plain)
				report.fries.append({"kind":kind,"carrier":carrier,"tier":tier,"old":counts(old.visual),"new":c})
				for q in pair:q.free()
	P2.enabled=true
	for bro in [false,true]:
		for kind in (Gull.SLOTS.keys() if not bro else ["coat","topper","shades","necklace"]):
			var pair=[]
			for old in [true,false]:
				P2.enabled=not old;var g=Gull.new();g.plain=true;g.bro_style=bro;root.add_child(g);g.build();g.wear(kind,true);pair.append(g)
			var a=pair[0].worn[kind];var b=pair[1].worn[kind]
			assert(a.transform.is_equal_approx(b.transform))
			assert(a.get_parent()==pair[0].head if b.get_parent()==pair[1].head else true)
			assert(counts(b).draws<=counts(a).draws)
			if kind=="meteor":assert(b.has_node("Spin") and b.has_node("Sparks"))
			if kind=="scarf":assert(b.has_node("ScarfTail"))
			if kind=="balloon":assert(b.has_node("Balloon"))
			var asset="wear_"+("bro_" if bro else "")+kind;var tris=0
			for mesh in P2.parts(asset).values():tris+=mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size()/3
			assert(tris>0 and tris<=250)
			report.wear[("bro_" if bro else "")+kind]={"old":counts(a),"new":counts(b),"authored_tris":tris}
			for g in pair:g.free()
	P2.enabled=true
	var dp=[]
	for old in [true,false]:
		P2.enabled=not old;var d=Dog.new();root.add_child(d);d.setup(null,Vector3.ZERO,0,"B98B61");dp.append(d)
	assert(counts(dp[1]).tris<=1200 and counts(dp[1]).draws<=counts(dp[0]).draws)
	for key in ["body","head","tail"]:assert(dp[0].get(key).transform.is_equal_approx(dp[1].get(key).transform))
	for i in 4:assert(dp[0].legs[i].transform.is_equal_approx(dp[1].legs[i].transform))
	report.dog={"old":counts(dp[0]),"new":counts(dp[1])}
	for d in dp:d.free()
	var gs=root.get_node("GS")
	for sp in gs.FISH_ORDER:
		var fp=[]
		for old in [true,false]:
			P2.enabled=not old;var f=FishSpot.Fish.new();root.add_child(f);f.setup(null,{"sp":sp,"len":32,"kg":.4});fp.append(f)
		assert(fp[1].visual.has_node("Body") and counts(fp[1].visual).draws==2)
		assert(fp[0].visual.get_node("Tail").transform.is_equal_approx(fp[1].visual.get_node("Tail").transform))
		for key in ["species","rarity","len_cm","kg","scl","min_speed"]:assert(fp[0].get(key)==fp[1].get(key))
		report.fish[sp]={"old":counts(fp[0].visual),"new":counts(fp[1].visual)}
		for f in fp:f.free()
	P2.enabled=true
	report["held_items"]={}
	var Human=load("res://scripts/npc/human_rig.gd")
	for kind in ["broom","umbrella","watergun","rod","brush","cup","icecream","paper","tray","guitar","balloon","kite","ball","fries","mug","cocktail","basket","clothes"]:
		var pair=[]
		for old in [true,false]:
			P2.enabled=not old
			var h=Human.new();root.add_child(h);h.build({"item_l":kind,"item_r":kind});h.set_process(false);pair.append(h)
		assert(counts(pair[1]).draws<=11)
		assert(counts(pair[0]).tris==counts(pair[1]).tris)
		for key in ["root","upper","head","hand_l","hand_r","hand_anchor","item_node_l","item_node_r"]:
			assert(pair[0].get(key).transform.is_equal_approx(pair[1].get(key).transform))
		report.held_items[kind]={"old":counts(pair[0]),"new":counts(pair[1])}
		for h in pair:h.free()
	P2.enabled=true
	FileAccess.open("res://../art_src/p2/contract.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("[P2 CONTRACT PASS] ",report.fries.size()," fry cases; 23 wear items, 9 fish, dog pivots, plain rules, RNG, materials, fallbacks")
	quit()
