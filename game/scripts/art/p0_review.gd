extends Node
## Dev-only --cams --art-p0 --art-review; no reference from normal gameplay.
const ArtLoader = preload("res://scripts/art/art_loader.gd")
const ASSET = "res://assets/models/p0_rounded_cube.glb"
const BASE = Vector3(-8.9, 4.82, -0.9)
var report = {}
var folder = ""
var camera: Camera3D
var governor

func run(main, output):
	process_mode = Node.PROCESS_MODE_ALWAYS
	folder = output
	# The launcher redirects APPDATA/LOCALAPPDATA before Godot even starts.
	if not OS.get_user_data_dir().replace("\\", "/").contains("/art_src/p0/runtime/"):
		push_error("P0 review requires isolated art_src/p0/runtime user data; use run_p0.ps1")
		get_tree().quit(1)
		return
	await RenderingServer.frame_post_draw
	report["first_review_frame_since_engine_ms"] = Time.get_ticks_msec()
	get_tree().paused = true
	Engine.max_fps = 30
	for child in main.get_children():
		if child is CanvasLayer:
			child.visible = false
		if child.get_script() != null and child.get_script().resource_path.ends_with("perf_governor.gd"):
			governor = child
	main.player.input_locked = true
	# Round 13 scatter finishes asynchronously. Wait for its fourth MultiMesh,
	# not a guessed sleep that could compare two different scene populations.
	var deadline = Time.get_ticks_msec() + 30000
	while main.find_children("*", "MultiMeshInstance3D", true, false).size() < 4:
		await get_tree().process_frame
		if Time.get_ticks_msec() > deadline:
			push_error("P0: timed out waiting for all four flora MultiMeshes")
			get_tree().quit(1)
			return
	report["flora_multimeshes"] = main.find_children("*", "MultiMeshInstance3D", true, false).size()
	camera = Camera3D.new()
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(camera)
	camera.make_current()
	var packed = ArtLoader.instantiate(ASSET)
	assert(packed != null, "GLB import failed")
	add_child(packed)
	packed.position = BASE
	packed.visible = false
	var parts = ArtLoader.meshes(packed)
	var colours: PackedColorArray = parts[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var unique = {}
	for colour in colours:
		unique[colour.to_html()] = true
	assert(unique.size() > 16, "COLOR_0 lost or flattened during GLB import")
	assert(ArtLoader.instantiate("res://assets/models/p0_missing.glb") == null)
	var duplicate = ArtLoader.instantiate(ASSET)
	assert(ArtLoader.meshes(duplicate)[0].material_override == parts[0].material_override)
	duplicate.free()
	report["asset"] = {"mesh_instances": parts.size(), "surfaces": parts[0].mesh.get_surface_count(),
		"unique_imported_colours": unique.size(), "vertices": colours.size(),
		"local_aabb": str(parts[0].get_aabb()), "missing_fallback": "PASS", "shared_material": "PASS"}
	var before = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3.ONE
	before.mesh = box
	var flat = StandardMaterial3D.new()
	flat.albedo_color = Color("D99B87")
	flat.roughness = 0.92
	before.material_override = flat
	add_child(before)
	before.position = BASE + Vector3(0, 0.5, 0)
	var views = JSON.parse_string(FileAccess.get_file_as_string("res://../art_src/p0/cams.json"))
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	report["samples"] = []
	for view in views:
		camera.position = Vector3(view[1], view[2], view[3])
		camera.look_at(Vector3(view[4], view[5], view[6]))
		camera.fov = view[7]
		for style in ["before", "after"]:
			before.visible = style == "before"
			packed.visible = style == "after"
			await settle()
			var sample = await measure()
			sample["name"] = str(view[0]) + "_" + style
			sample["camera_distance_m"] = camera.position.distance_to(BASE + Vector3(0, 0.5, 0))
			report["samples"].append(sample)
			await shot(sample["name"])
	# Same geometry/shader, set imported COLOR_0 to white: visible colour proof.
	var close = views[0]
	camera.position = Vector3(close[1], close[2], close[3])
	camera.look_at(BASE + Vector3(0, 0.5, 0))
	var original = parts[0].mesh
	var arrays = original.surface_get_arrays(0)
	var white: PackedColorArray = arrays[Mesh.ARRAY_COLOR].duplicate()
	white.fill(Color.WHITE)
	arrays[Mesh.ARRAY_COLOR] = white
	var ablation = ArrayMesh.new()
	ablation.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	parts[0].mesh = ablation
	await settle()
	await shot("close_white_vertex_ablation")
	parts[0].mesh = original
	# Exercise the existing governor's lowest level on this same review scene.
	governor.level = 3
	governor._apply()
	await settle()
	await shot("close_governor3")
	report["governor3"] = await measure()
	governor.level = 0
	governor._apply()
	report["resolution"] = str(get_window().size)
	report["fps_cap"] = 30
	report["user_data"] = OS.get_user_data_dir()
	report["scope"] = "Frozen full island, same camera per pair; desktop Compatibility only, no web export. Timings include 30 fps cap; CPU/GPU render timing may be unavailable."
	var file = FileAccess.open(folder + "metrics.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("[ART_P0] PASS imported COLOR_0, fallback, material sharing, paired cameras, governor 3; " + folder)
	get_tree().quit()

func settle():
	for i in 15:
		await RenderingServer.frame_post_draw

func measure():
	var draws = []
	var frames = []
	var cpu = []
	var gpu = []
	var last = Time.get_ticks_usec()
	for i in 30:
		await RenderingServer.frame_post_draw
		var now = Time.get_ticks_usec()
		frames.append((now - last) / 1000.0)
		last = now
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(get_viewport().get_viewport_rid()))
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()))
	frames.sort()
	draws.sort()
	cpu.sort()
	gpu.sort()
	return {"draw_calls_median": draws[15], "draw_calls_min": draws[0], "draw_calls_max": draws[-1],
		"frame_ms_median": frames[15], "frame_ms_p95": frames[28],
		"render_cpu_ms_median": cpu[15], "render_gpu_ms_median": gpu[15],
		"governor_level": governor.level, "scale_3d": get_viewport().scaling_3d_scale}

func shot(name_):
	await RenderingServer.frame_post_draw
	var image = get_viewport().get_texture().get_image()
	if image.get_width() > 512:
		image.resize(512, roundi(image.get_height() * 512.0 / image.get_width()))
	assert(image.save_png(folder + name_ + ".png") == OK)
