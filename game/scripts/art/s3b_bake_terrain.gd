extends SceneTree
## Bake the existing exact arrays, with no material, to avoid rebuilding static terrain.
func _initialize():
	var legacy=GDScript.new()
	legacy.source_code=FileAccess.get_file_as_string("res://../art_src/s3b/baseline/source/game/scripts/world/terrain.gd")
	assert(legacy.reload()==OK)
	var mesh=legacy.build_mesh();mesh.surface_set_material(0,null)
	assert(ResourceSaver.save(mesh,"res://assets/models/terrain_s3b.res",ResourceSaver.FLAG_COMPRESS)==OK)
	print("[S3b] Baked exact S3 terrain arrays; procedural fallback preserved")
	quit()
