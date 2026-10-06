extends RefCounted
# The ONE danger language of the game (round 5): whatever is about to hit the gull shows
#   a "!" that pops over it,
#   a red patch on the ground / a red line along its path (it grows until the hit),
#   and one soft low note.
# Nothing here hurts anybody: the owners of the danger (dogs, volleyball players, kids with water guns, grumpy strangers) do the hurting.

static var _bang_mat = null

# a "!" floating over `node` (at height `h`) for `sec` seconds
static func bang(node, h, sec, col = Color(1.0, 0.45, 0.25)):
	var l = Label3D.new()
	l.text = "!"
	l.font_size = 170
	l.pixel_size = 0.006
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.modulate = col
	l.outline_size = 16
	l.outline_modulate = Color(0.1, 0.02, 0.0, 0.9)
	l.render_priority = 6
	l.position = Vector3(0, h, 0)
	l.scale = Vector3(0.2, 0.2, 0.2)
	node.add_child(l)
	var tw = l.create_tween()
	tw.tween_property(l, "scale", Vector3.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(max(sec - 0.3, 0.05))
	tw.tween_property(l, "modulate:a", 0.0, 0.14)
	tw.tween_callback(l.queue_free)
	Sfx.play("warn", -9.0)
	return l

# a flat red disc on the ground that fills up like a clock until it fades (the landing spot of something)
static func disc(scene, center, radius, sec):
	var mi = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = 0.05
	cm.radial_segments = 28
	mi.mesh = cm
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.2, 0.15, 0.12)
	m.no_depth_test = true
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scene.add_child(mi)
	mi.global_position = center
	mi.scale = Vector3(0.35, 1.0, 0.35)
	var tw = mi.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE, sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(m, "albedo_color:a", 0.5, sec)
	tw.chain().tween_property(m, "albedo_color:a", 0.0, 0.18)
	tw.chain().tween_callback(mi.queue_free)
	return mi

# a thin red line between two points (the path of a ball or a squirt)
static func line(scene, a, b, sec):
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.1, 0.1, 1.0)
	mi.mesh = bm
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.25, 0.2, 0.15)
	m.no_depth_test = true
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scene.add_child(mi)
	var len_ = max(a.distance_to(b), 0.1)
	mi.global_position = (a + b) * 0.5
	mi.scale = Vector3(1, 1, len_)
	mi.look_at(b, Vector3.UP)
	var tw = mi.create_tween()
	tw.tween_property(m, "albedo_color:a", 0.6, sec)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.15)
	tw.tween_callback(mi.queue_free)
	return mi
