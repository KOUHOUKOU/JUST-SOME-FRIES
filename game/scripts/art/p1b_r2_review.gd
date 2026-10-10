extends Node
## Paused, isolated review only. All masks use geometry, never RGB thresholds on foliage.
const Art = preload("res://scripts/art/art_loader.gd")
var r
var main
var leaf_colours = []

func shot(label):
	for i in 6:await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	assert(img.get_width() <= 960 and img.get_height() <= 540)
	assert(img.save_png(r.folder+label+".png") == OK)

func run(main_,review):
	main = main_;r = review;process_mode = Node.PROCESS_MODE_ALWAYS
	get_window().size = Vector2i(960,540)
	get_viewport().scaling_3d_scale = 1.0
	for tree in r.Scenery.catalog.trees:
		if tree.kind == 2:continue
		for c in tree.commands.slice(1):
			var colour = str(c.colour).to_lower()
			if not colour in leaf_colours:leaf_colours.append(colour)
	r.report["foliage_materials"] = leaf_colours
	for distance in [15,60]:
		var target = Vector3(-38,6.5,-32.8)
		var direction = Vector3(1,.05,.08) if distance==15 else Vector3(.22,.18,1)
		r.camera.position = target+direction.normalized()*distance;r.camera.look_at(target);r.camera.fov = 44
		for m in [["noon",0.0],["golden",.55]]:
			if "--p1b-masks-only" in OS.get_cmdline_user_args():continue
			r.mood(main,m[1])
			for old in [true,false]:
				r.before(old)
				await shot("street_%s_%dm_%s" % [m[0],distance,"before" if old else "after"])
		for old in [true,false]:
			r.before(old);await foliage_mask("mask_%dm_%s" % [distance,"before" if old else "after"])
	if "--p1b-masks-only" in OS.get_cmdline_user_args():return
	get_window().size = Vector2i(512,288)
	r.mood(main,0.0);r.camera.position=Vector3(5,24,14);r.camera.look_at(Vector3(-22,8,-38));r.camera.fov=58
	r.before(true);await shot("crowded_before");var before = await r.measure()
	r.before(false);await shot("crowded_after");var after = await r.measure()
	r.report["crowded"] = {"before":before,"after":after,"props_matched":true,"size":"512x288","fps_cap":30}
	await people()
	# Reuse the exact approved gull colour test with the revised shared shader.
	var gull_test = load("res://scripts/art/p1a_r2_review.gd").new();add_child(gull_test)
	gull_test.camera=r.camera;gull_test.folder=r.folder;gull_test.player=main.player;gull_test.actor=main.player.gull
	main.player.visible=true;main.player.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	main.player.rotation=Vector3.ZERO;main.player.visual_root.rotation=Vector3.ZERO;main.player.visual_root.position=Vector3.ZERO
	main.player.gull.scale=Vector3.ONE;main.player.gull.strip_all();r.camera.fov=44
	await gull_test.colour_checks(main)
	r.report["colour_mask"] = gull_test.report.colour_mask
	r.report["rendering"]="Godot desktop Compatibility; street 960x540; crowd/people/gull 512x288; capped 30fps; same-session medians of 30 frames; no web export"
	FileAccess.open(r.folder+"metrics.json",FileAccess.WRITE).store_string(JSON.stringify(r.report,"\t"))
	print("[P1B R2] ",r.report.crowded," output=",r.folder)

func mask_mat(code):
	var mat=ShaderMaterial.new();mat.shader=Shader.new()
	mat.shader.code="shader_type spatial; render_mode unshaded,cull_back,fog_disabled; void fragment(){ALBEDO="+code+";}"
	return mat

func foliage_mask(label):
	var black=mask_mat("vec3(0)");var white=mask_mat("vec3(1)");var crown=mask_mat("vec3(step(0.04,UV.x))")
	var saved=[]
	for n in main.find_children("*","GeometryInstance3D",true,false):
		if not n is MeshInstance3D and not n is MultiMeshInstance3D:continue
		saved.append([n,n.material_override,n.visible]);var source=n.material_override
		if source == null:
			var mesh=n.mesh if n is MeshInstance3D else n.multimesh.mesh
			if mesh != null and mesh.get_surface_count()>0:source=mesh.surface_get_material(0)
		# Do not turn invisible/additive thermal, glow or warning volumes into opaque occluders.
		if (source is StandardMaterial3D and source.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED) or (source is ShaderMaterial and source.shader.code.contains("ALPHA =")):
			n.visible=false;continue
		var mat=black
		if n is MultiMeshInstance3D and n.is_in_group("p1b_new_world"):mat=crown
		elif source is StandardMaterial3D and source.albedo_color.to_html(false).to_lower() in leaf_colours:mat=white
		n.material_override=mat
	var envs=[]
	for we in main.find_children("*","WorldEnvironment",true,false):
		var env=we.environment;envs.append([we,env]);var clean=env.duplicate()
		clean.background_mode=Environment.BG_COLOR;clean.background_color=Color.BLACK;clean.fog_enabled=false
		we.environment=clean
	await shot(label)
	for pair in saved:pair[0].material_override=pair[1];pair[0].visible=pair[2]
	for pair in envs:pair[0].environment=pair[1]

func people():
	var styles=JSON.parse_string(FileAccess.get_file_as_string("res://../art_src/p1b/cast_styles.json"))
	var origin=Vector3(-8,45,12);r.mood(main,0.0);r.camera.fov=30
	for i in 8:
		var c=r.fixture(main,styles[i]);c.position=origin+Vector3((i-3.5),0,0);r.settle(c,"idle")
	r.camera.position=origin+Vector3(0,1.1,9);r.camera.look_at(origin+Vector3(0,1.05,0));await shot("cast_noon")
	for c in r.stage:c.visible=false
	var actors=[]
	for i in 3:
		var c=r.fixture(main,styles[[1,4,2][i]]);c.position=origin+Vector3((i-1)*1.2,0,0);r.settle(c,"idle");actors.append(c)
	r.camera.fov=38
	for view in [["front",Vector3(.8,1.4,5.3)],["back",Vector3(-1,1.4,-5.3)]]:
		r.camera.position=origin+view[1];r.camera.look_at(origin+Vector3(0,1.05,0));await shot("garments_"+view[0])
	for c in actors:c.visible=false
	for i in 4:
		var c=r.fixture(main,styles[[1,4,2,7][i]]);c.position=origin+Vector3((i-1.5)*1.5,0,0)
		r.settle(c,["wave","sit","jog","recline"][i],.3)
	r.camera.position=origin+Vector3(.6,1.8,7);r.camera.look_at(origin+Vector3(0,1,0));r.camera.fov=35
	await shot("limbs_wave_sit_jog_recline")
	for c in r.stage:c.visible=false
