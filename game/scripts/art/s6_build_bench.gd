extends SceneTree
## Synchronous world-builder timing, warm resources, empty per-style caches.
## Does not measure renderer startup, deferred flora completion, or browser load.
func _initialize():call_deferred("run")
func run():
	var scripts=[load("res://../art_src/s6/bench_sources/game/scripts/world/world_builder.gd"),load("res://scripts/world/world_builder.gd")]
	var persons=[load("res://../art_src/s6/bench_sources/game/scripts/art/person_parts.gd"),load("res://scripts/art/person_parts.gd")]
	var results=[]
	for which in [0,1,1,0,0,1,1,0]:
		root.get_node("GS").reset();paused=true
		persons[which].variants.clear()
		var host=Node3D.new();root.add_child(host)
		var p=CharacterBody3D.new();p.set_script(load("res://scripts/player/gull_player.gd"));host.add_child(p)
		var builder=scripts[which].new();var start=Time.get_ticks_usec()
		builder.build(host,p)
		var ms=(Time.get_ticks_usec()-start)/1000.0
		results.append({"version":"before" if which==0 else "after","ms":ms})
		print("[S6 BUILD BENCH] ",results.back())
		# Wait outside the timed region before releasing the deferred scatter's owner.
		while host.find_children("*","MultiMeshInstance3D",true,false).filter(func(n):return n.visibility_range_end>0).size()<4:
			await process_frame
		host.free();builder=null
		for i in 3:await process_frame
	FileAccess.open("res://../art_src/s6/build_bench.json",FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
	quit()
