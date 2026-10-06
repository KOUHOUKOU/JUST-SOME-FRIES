extends CanvasLayer
# "Item get" showcase: the game freezes, a band wipes in from the left, a close-up of the real fry model slides out
# of the left edge, and the card tells you what it is, where it came from and what it does. First time: NEW!
# Every named fry gets one - so the plain fry at the very end reads as the odd one out.
#   open(info, callback)  full pause + close-up (tutorial / special / ordinary / first prism)
#   banner(info)          small non-blocking slide-in (new prism varieties)

signal closed

const FRY = preload("res://scripts/fries/fry.gd")

var active = false
var fast = false            # autotests: skip the lingering
var info = {}
var cb = null
var queue = []
var t = 0.0
var min_t = 1.1
var auto_t = 9.0
var can_close = false
var closing = false

var root
var dim
var band
var band_bg
var line_a
var line_b
var flash
var vpc
var vp
var cam
var fry_node
var spin = 0.0
var tilt = Vector3.ZERO
var final_x = -1.1
var items = []              # [control, final_x, delay]
var badge
var badge_lbl
var cat_lbl
var name_lbl
var src_lbl
var desc_lbl
var abil_panel
var abil_title
var abil_lbl
var footer
var banner_box
var banner_tw
var rays

class Rays extends Control:
	var col = Color.WHITE
	var tier = 0
	var t = 0.0
	func _process(delta):
		t += delta
		if visible:
			queue_redraw()
	func _draw():
		if tier <= 0:
			return
		var c = Vector2(size.x * 0.215, size.y * 0.5)
		var n = 14 + 4 * tier
		var a_ray = 0.10 + 0.05 * tier
		for i in n:
			var a0 = t * (0.12 + 0.04 * tier) + TAU * i / n
			var a1 = a0 + TAU / n * 0.5
			draw_colored_polygon(PackedVector2Array([c, c + Vector2(cos(a0), sin(a0)) * 900.0, c + Vector2(cos(a1), sin(a1)) * 900.0]), Color(col.r, col.g, col.b, a_ray))
		for k in tier:
			draw_arc(c, 150.0 + k * 22.0 + 4.0 * sin(t * 2.0 + k), 0, TAU, 72, Color(col.r, col.g, col.b, 0.55 - 0.12 * k), 4.0 - k, true)
		draw_circle(c, 150.0, Color(col.r, col.g, col.b, 0.10 + 0.03 * tier))
		if tier >= 3:
			for k in 10:
				var ang = t * 0.5 + TAU * k / 10.0
				var rr = 175.0 + 12.0 * sin(t * 3.0 + k)
				draw_circle(c + Vector2(cos(ang), sin(ang)) * rr, 4.0, Color(1, 0.95, 0.7, 0.9))

func _ready():
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.visible = false
	add_child(root)
	dim = ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	band = Control.new()
	band.set_anchors_preset(Control.PRESET_FULL_RECT)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(band)
	band_bg = ColorRect.new()
	band_bg.color = Color(0.07, 0.08, 0.12, 0.93)
	band_bg.anchor_left = 0.0
	band_bg.anchor_right = 1.0
	band_bg.anchor_top = 0.26
	band_bg.anchor_bottom = 0.78
	band_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(band_bg)
	line_a = ColorRect.new()
	line_a.anchor_left = 0.0
	line_a.anchor_right = 1.0
	line_a.anchor_top = 0.26
	line_a.anchor_bottom = 0.26
	line_a.offset_bottom = 5
	line_a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(line_a)
	line_b = ColorRect.new()
	line_b.anchor_left = 0.0
	line_b.anchor_right = 1.0
	line_b.anchor_top = 0.78
	line_b.anchor_bottom = 0.78
	line_b.offset_top = -5
	line_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(line_b)
	# rarity backdrop: rays + rings in the fry's rarity colour (white / blue / purple / gold) behind the close-up
	rays = Rays.new()
	rays.set_anchors_preset(Control.PRESET_FULL_RECT)
	rays.anchor_top = 0.26
	rays.anchor_bottom = 0.78
	rays.offset_top = 0
	rays.offset_bottom = 0
	rays.clip_contents = true
	rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rays.visible = false
	root.add_child(rays)
	# 3D close-up lives in its own world so it can never touch the game's lights / groups
	vpc = SubViewportContainer.new()
	vpc.stretch = true
	vpc.anchor_left = 0.0
	vpc.anchor_right = 1.0
	vpc.anchor_top = 0.14
	vpc.anchor_bottom = 0.90
	vpc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vpc)
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED   # only rendered while a card is open
	vpc.add_child(vp)
	var world = Node3D.new()
	vp.add_child(world)
	cam = Camera3D.new()
	cam.fov = 32.0
	world.add_child(cam)
	cam.position = Vector3(0, 0.15, 2.6)
	cam.look_at_from_position(cam.position, Vector3(0, 0.1, 0), Vector3.UP)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -28, 0)
	sun.light_energy = 1.25
	world.add_child(sun)
	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-10, 150, 0)
	fill.light_energy = 0.45
	world.add_child(fill)
	var env = Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.95, 0.88)
	env.ambient_light_energy = 0.75
	var we = WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	# text column
	badge = PanelContainer.new()
	var bsb = StyleBoxFlat.new()
	bsb.bg_color = Color(1.0, 0.86, 0.2)
	bsb.set_corner_radius_all(6)
	bsb.set_border_width_all(3)
	bsb.border_color = Color(0.85, 0.2, 0.15)
	bsb.content_margin_left = 14
	bsb.content_margin_right = 14
	bsb.content_margin_top = 2
	bsb.content_margin_bottom = 2
	badge.add_theme_stylebox_override("panel", bsb)
	badge_lbl = _lbl("NEW!", 34, Color(0.8, 0.12, 0.1), 0)
	badge.add_child(badge_lbl)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(badge)
	cat_lbl = _lbl("", 20, Color(0.8, 0.85, 1.0, 0.85), 3)
	name_lbl = _lbl("", 58, Color(1, 1, 1), 8)
	src_lbl = _lbl("", 19, Color(1.0, 0.85, 0.5), 3)
	desc_lbl = _lbl("", 23, Color(0.9, 0.9, 0.95), 4)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	abil_panel = PanelContainer.new()
	abil_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	abil_panel.add_child(vb)
	abil_title = _lbl("ABILITY", 15, Color(1, 1, 1, 0.6), 0)
	abil_lbl = _lbl("", 31, Color(1.0, 0.86, 0.35), 5)
	vb.add_child(abil_title)
	vb.add_child(abil_lbl)
	footer = _lbl("", 17, Color(1, 1, 1, 0.7), 3)
	for c in [cat_lbl, name_lbl, src_lbl, desc_lbl, abil_panel, footer]:
		root.add_child(c)
	for c in [cat_lbl, name_lbl, src_lbl, desc_lbl, abil_title, abil_lbl, footer, badge_lbl]:
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash)

func _lbl(text, sz, col, outline = 5):
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("outline_size", outline)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _tw():
	var tw = create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_ignore_time_scale(true)
	return tw

# ------------------------------------------------------------------ full showcase
func open(p_info, p_cb = null):
	if active:
		queue.append([p_info, p_cb])
		return
	active = true
	closing = false
	can_close = false
	info = p_info
	cb = p_cb
	t = 0.0
	min_t = 0.25 if fast else float(info.get("min_t", 1.1))
	auto_t = 0.35 if fast else float(info.get("auto_t", 9.0))
	GS.showcase_active = true
	Engine.time_scale = 1.0
	get_tree().paused = true
	Sfx.muffle(true, 0.15, 3600.0)
	Sfx.play("chime", -7.0, 1.25)
	var accent = info["color"]
	var rcol = info.get("rarity_col", accent)
	var tier = int(info.get("tier", 0))
	line_a.color = rcol
	line_b.color = rcol
	band_bg.color = Color(0.06, 0.07, 0.11, 0.94).lerp(rcol, 0.07)
	rays.col = rcol
	rays.tier = tier
	rays.visible = true
	cat_lbl.text = info.get("category", "")
	cat_lbl.add_theme_color_override("font_color", rcol.lightened(0.25) if tier > 0 else Color(0.8, 0.85, 1.0, 0.85))
	name_lbl.text = info["name"]
	src_lbl.text = info.get("source", "")
	desc_lbl.text = info.get("desc", "")
	abil_title.text = info.get("ability_title", "ABILITY")
	abil_lbl.text = info.get("ability", "")
	abil_lbl.add_theme_color_override("font_color", accent.lerp(Color(1, 1, 1), 0.35))
	var asb = StyleBoxFlat.new()
	asb.bg_color = Color(0, 0, 0, 0.35)
	asb.set_corner_radius_all(8)
	asb.set_border_width_all(2)
	asb.border_color = accent
	asb.content_margin_left = 16
	asb.content_margin_right = 16
	asb.content_margin_top = 6
	asb.content_margin_bottom = 8
	abil_panel.add_theme_stylebox_override("panel", asb)
	badge.visible = info.get("new", true)
	footer.text = ""
	_build_fry()
	root.visible = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	_layout()
	_animate_in()

func _layout():
	var sz = get_viewport().get_visible_rect().size
	var x0 = sz.x * 0.43
	var w = sz.x * 0.52
	var y0 = sz.y * 0.26 + 26.0
	badge.position = Vector2(x0, y0)
	badge.size = Vector2(120, 44)
	badge.pivot_offset = Vector2(60, 22)
	badge.rotation = -0.07
	cat_lbl.position = Vector2(x0 + 140, y0 + 10)
	cat_lbl.size = Vector2(w, 28)
	name_lbl.position = Vector2(x0, y0 + 50)
	name_lbl.size = Vector2(w, 74)
	src_lbl.position = Vector2(x0, y0 + 126)
	src_lbl.size = Vector2(w, 26)
	desc_lbl.position = Vector2(x0, y0 + 160)
	desc_lbl.size = Vector2(w, 64)
	abil_panel.position = Vector2(x0, y0 + 236)
	abil_panel.size = Vector2(w * 0.96, 74)
	footer.position = Vector2(x0, y0 + 310)
	footer.size = Vector2(w, 24)
	items = [[cat_lbl, 0.30], [name_lbl, 0.38], [src_lbl, 0.48], [desc_lbl, 0.56], [abil_panel, 0.68], [footer, 0.8]]
	band.pivot_offset = Vector2(0, sz.y * 0.5)

func _build_fry():
	if fry_node != null and is_instance_valid(fry_node):
		fry_node.queue_free()
	fry_node = Node3D.new()
	fry_node.set_script(FRY)
	vp.get_child(0).add_child(fry_node)
	var ft = info.get("ftype", "tutorial")
	fry_node.setup("SHOWCASE", ft, info.get("carrier", "box"), int(info.get("kind", 0)), int(info.get("tier", -1)))
	# the real fries are found through these groups: the display copy must never be snatchable
	for g in ["fries", "special_fries", "star_fries"]:
		fry_node.remove_from_group(g)
	fry_node.revealed = true
	fry_node.visible = true
	spin = 0.4
	final_x = -1.1
	if ft != "ordinary":
		fry_node.halo_alpha = fry_node.halo_base * 0.35   # the in-world glow washes out a close-up
		fry_node._apply_halo()
	match ft:
		"ordinary":
			fry_node.scale = Vector3.ONE * 1.35
			fry_node.position = Vector3(-4.0, -0.05, 0)
			tilt = Vector3(-0.5, 0.0, 0.0)
			final_x = -0.6
		"star":
			fry_node.scale = Vector3.ONE * 1.5
			fry_node.position = Vector3(-4.0, 0.1, 0)
			tilt = Vector3(-0.55, 0.0, 0.0)
			final_x = -0.95
		_:
			fry_node.scale = Vector3.ONE * 1.4
			fry_node.position = Vector3(-4.0, -0.5, 0)
			tilt = Vector3.ZERO
			final_x = -1.1
	fry_node.rotation = tilt

func _animate_in():
	var sz = get_viewport().get_visible_rect().size
	dim.modulate.a = 0.0
	band.scale = Vector2(0.0, 1.0)
	vpc.modulate.a = 1.0
	var tw = _tw()
	tw.set_parallel(true)
	tw.tween_property(dim, "modulate:a", 1.0, 0.18)
	rays.modulate.a = 0.0
	tw.tween_property(rays, "modulate:a", 1.0, 0.45).set_delay(0.15)
	tw.tween_property(band, "scale:x", 1.0, 0.30).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	# the close-up is pulled out of the left edge
	var final_y = fry_node.position.y
	tw.tween_property(fry_node, "position:x", final_x, 0.65).set_delay(0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for it in items:
		var c = it[0]
		var fx = c.position.x
		c.position.x = fx - 130.0
		c.modulate.a = 0.0
		tw.tween_property(c, "position:x", fx, 0.36).set_delay(it[1]).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "modulate:a", 1.0, 0.26).set_delay(it[1])
	# NEW! slams in after the name
	badge.modulate.a = 0.0
	badge.scale = Vector2(2.6, 2.6)
	tw.tween_property(badge, "modulate:a", 1.0, 0.08).set_delay(0.52)
	tw.tween_property(badge, "scale", Vector2.ONE, 0.26).set_delay(0.52).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if badge.visible:
		tw.tween_callback(func():
			Sfx.play("perfect", -9.0)
			flash.color = Color(1, 1, 1, 0.45)
			var f2 = _tw()
			f2.tween_property(flash, "color:a", 0.0, 0.3)).set_delay(0.6)
	if fast:
		return

func _process(delta):
	if not active:
		return
	t += delta
	spin += delta * 1.15
	if fry_node != null and is_instance_valid(fry_node):
		fry_node.rotation = Vector3(tilt.x, spin, tilt.z)
	if not can_close and t >= min_t:
		can_close = true
	if can_close and not closing:
		footer.text = "PRESS  E  TO CONTINUE"
		footer.modulate.a = 0.55 + 0.45 * sin(t * 5.0)
		if t >= auto_t:
			_close()

func _input(event):
	if not active:
		return
	if event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()
		return
	if closing:
		return
	var press = event.is_action_pressed("interact") or event.is_action_pressed("flap") \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER)
	if press:
		get_viewport().set_input_as_handled()
		if can_close:
			_close()

func _close():
	if closing:
		return
	closing = true
	var sz = get_viewport().get_visible_rect().size
	band.pivot_offset = Vector2(sz.x, sz.y * 0.5)
	var tw = _tw()
	tw.set_parallel(true)
	tw.tween_property(band, "scale:x", 0.0, 0.22).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tw.tween_property(dim, "modulate:a", 0.0, 0.22)
	tw.tween_property(vpc, "modulate:a", 0.0, 0.16)
	tw.tween_property(rays, "modulate:a", 0.0, 0.16)
	for it in items:
		tw.tween_property(it[0], "modulate:a", 0.0, 0.12)
	tw.tween_property(badge, "modulate:a", 0.0, 0.12)
	tw.chain().tween_callback(_finish)

func _finish():
	root.visible = false
	rays.visible = false
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if fry_node != null and is_instance_valid(fry_node):
		fry_node.queue_free()
		fry_node = null
	active = false
	GS.showcase_active = false
	get_tree().paused = false
	Sfx.muffle(false, 0.3)
	var c = cb
	cb = null
	if c != null:
		c.call()
	closed.emit()
	if not queue.is_empty():
		var q = queue.pop_front()
		open(q[0], q[1])

# ------------------------------------------------------------------ small banner (no pause)
func banner(p_info):
	if banner_box != null and is_instance_valid(banner_box):
		banner_box.queue_free()
	if banner_tw != null:
		banner_tw.kill()
	var accent = p_info["color"]
	banner_box = PanelContainer.new()
	banner_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.11, 0.9)
	sb.set_corner_radius_all(8)
	sb.set_border_width_all(3)
	sb.border_color = p_info.get("rarity_col", accent)
	sb.content_margin_left = 16
	sb.content_margin_right = 20
	sb.content_margin_top = 8
	sb.content_margin_bottom = 10
	banner_box.add_theme_stylebox_override("panel", sb)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	banner_box.add_child(v)
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	v.add_child(h)
	if p_info.get("new", true):
		var nb = _lbl("NEW!", 22, Color(0.8, 0.12, 0.1), 0)
		var nsb = StyleBoxFlat.new()
		nsb.bg_color = Color(1.0, 0.86, 0.2)
		nsb.set_corner_radius_all(4)
		nsb.content_margin_left = 8
		nsb.content_margin_right = 8
		var np = PanelContainer.new()
		np.add_theme_stylebox_override("panel", nsb)
		np.add_child(nb)
		h.add_child(np)
	h.add_child(_lbl(p_info["name"], 26, Color(1, 1, 1), 5))
	v.add_child(_lbl(p_info.get("ability", ""), 18, accent.lerp(Color(1, 1, 1), 0.4), 3))
	root_banner_add(banner_box)
	banner_box.position = Vector2(-520, 0)
	var sz = get_viewport().get_visible_rect().size
	var y = sz.y * 0.17
	banner_box.position = Vector2(-520, y)
	banner_tw = create_tween().set_ignore_time_scale(true)
	banner_tw.tween_property(banner_box, "position:x", 28.0, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	banner_tw.tween_interval(2.6)
	banner_tw.tween_property(banner_box, "position:x", -560.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	banner_tw.tween_callback(banner_box.queue_free)
	Sfx.play("perfect", -12.0)

func root_banner_add(c):
	add_child(c)
