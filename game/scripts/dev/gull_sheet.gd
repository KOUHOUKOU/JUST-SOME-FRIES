extends Node
# DEV ONLY (round 15): a contact sheet of the hero gull (and the big brother) from several sides, in several poses and wearing sets of clothes.
#   godot --path game --resolution 64x64 res://scenes/dev_gull_sheet.tscn -- --out=<png> [--mode=base|wear|bro] [--sets="hat,glasses;coat;stripes"]
# Own little world in a SubViewport: no island, quiet to run.

const GullVisual = preload("res://scripts/player/gull_visual.gd")
var CELL = 340

var out_path = "res://../art_src/r15/gull/sheet.png"
var mode = "base"
var sets = []

func _ready():
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_path = a.substr(6)
		elif a.begins_with("--cell="):
			CELL = int(a.substr(7))
		elif a.begins_with("--mode="):
			mode = a.substr(7)
		elif a.begins_with("--sets="):
			for s in a.substr(7).split(";"):
				sets.append(s.split(",", false))
	run.call_deferred()

func _cell_world(sv, gull, cam_dir, dist, fov, height_off = 0.0):
	var cam = sv.get_node("Cam")
	var c = gull.global_position + Vector3(0, 0.12 + height_off, 0)
	cam.fov = fov
	cam.global_position = c + cam_dir.normalized() * dist
	cam.look_at(c, Vector3.UP)

func run():
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	var sv = SubViewport.new()
	sv.size = Vector2i(CELL, CELL)
	sv.own_world_3d = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.msaa_3d = Viewport.MSAA_4X
	add_child(sv)
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.78, 0.84, 0.92)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.75, 0.9)
	env.ambient_light_energy = 0.0
	var we = WorldEnvironment.new()
	we.environment = env
	sv.add_child(we)
	var key = DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.93, 0.82)
	key.light_energy = 0.6
	key.rotation_degrees = Vector3(-42, -35, 0)
	sv.add_child(key)
	var fill = DirectionalLight3D.new()
	fill.light_color = Color(0.7, 0.8, 1.0)
	fill.light_energy = 0.12
	fill.rotation_degrees = Vector3(-15, 150, 0)
	sv.add_child(fill)
	var cam = Camera3D.new()
	cam.name = "Cam"
	sv.add_child(cam)
	var gull = Node3D.new()
	gull.set_script(GullVisual)
	if mode == "bro":
		gull.plain = true
		gull.bro_style = true
	sv.add_child(gull)
	gull.build()
	gull.plain = true       # (no growth looks from the stat state: this is a bare gull unless wearing)
	var cells = []     # [pose, cam_dir, dist, fov, wear_set]
	if mode == "base":
		cells = [["glide", Vector3(-1, 0.1, 0), 4.3, 32, []], ["glide", Vector3(0, 0.15, -1), 5.0, 32, []], ["glide", Vector3(0, 1, 0.001), 5.2, 32, []], ["glide", Vector3(-0.7, 0.35, -0.8), 4.6, 32, []],
			["throttle", Vector3(-0.7, 0.35, -0.8), 4.6, 32, []], ["boost", Vector3(-0.7, 0.35, -0.8), 4.6, 32, []], ["ground", Vector3(-0.7, 0.25, -0.8), 2.3, 32, []], ["glide", Vector3(0.0, 0.2, 1.0), 5.0, 32, []]]
	else:
		for s in sets:
			cells.append(["ground", Vector3(-0.75, 0.25, -0.75), 2.3, 30, s])
			cells.append(["ground", Vector3(0.7, 0.3, 0.8), 2.3, 30, s])
	var cols = 4
	var rows = int(ceil(cells.size() / float(cols)))
	var sheet = Image.create(CELL * cols, CELL * rows, false, Image.FORMAT_RGBA8)
	sheet.fill(Color.WHITE)
	var idx = 0
	for c in cells:
		for k in gull.worn.keys():
			gull.unwear(k)
		for w in c[4]:
			gull.wear(w, true)
		for i in 6:
			gull.pose(c[0], 0.0, c[0] == "throttle", 0.5)
		_cell_world(sv, gull, c[1], c[2], c[3])
		for i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img = sv.get_texture().get_image()
		sheet.blit_rect(img, Rect2i(0, 0, CELL, CELL), Vector2i((idx % cols) * CELL, (idx / cols) * CELL))
		idx += 1
	var path = out_path
	if path.begins_with("res://"):
		path = ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	sheet.save_png(path)
	print("[GULL SHEET] ", path)
	get_tree().quit()
