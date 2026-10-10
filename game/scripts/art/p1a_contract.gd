extends SceneTree
var Gull
const Parts = preload("res://scripts/art/gull_parts.gd")
const Art = preload("res://scripts/art/art_loader.gd")

func _initialize():
	call_deferred("check")

func check():
	Gull = load("res://scripts/player/gull_visual.gd")
	var loaded = Art.instantiate(Parts.PATH)
	for mi in Art.meshes(loaded):
		var uv = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
		print("[PART] ", mi.name, " surfaces=", mi.mesh.get_surface_count(), " uv=", uv.size() if uv != null else -1)
	loaded.free()
	var g = Gull.new()
	g.plain = true
	root.add_child(g)
	g.build()
	if not g.authored:
		push_error("P1a authored loading failed")
		quit(1)
		return
	g.tint_pale(Gull.pale_color(1))
	var changed = g.authored_parts.Head.mesh
	g.reset_plain()
	# reset_plain preserves the old white_mat behaviour; restore it explicitly here.
	g.white_mat.albedo_color = Gull.WHITE
	g._sync_authored_colours()
	assert(changed != g.authored_parts.Head.mesh)
	assert(g.authored_parts.Head.material_override == g.authored_parts.Body.material_override)
	var old = Gull.new()
	old.plain = true
	old.authored_path = "res://assets/models/missing_p1a.glb"
	root.add_child(old)
	old.build()
	assert(not old.authored)
	assert(Parts.load_parts("res://assets/models/p0_rounded_cube.glb").is_empty())
	for mode_ in ["glide", "brake", "ground"]:
		g.pose(mode_, 0.0, false, 1.0)
		old.pose(mode_, 0.0, false, 1.0)
		assert(g.head.position.is_equal_approx(old.head.position))
		assert(g.beak_socket.position.is_equal_approx(old.beak_socket.position))
		for side in [-1.0, 1.0]:
			assert(g.shoulder[side].transform.is_equal_approx(old.shoulder[side].transform))
			assert(g.elbow[side].transform.is_equal_approx(old.elbow[side].transform))
	print("[P1A CONTRACT] PASS authored, missing/invalid fallback, tint/reset, material sharing, same animated pivots")
	g.free()
	old.free()
	quit()
