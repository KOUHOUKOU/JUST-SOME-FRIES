extends CanvasLayer
# Subtitle lines for the two gull conversations (opening and ending). One line at a time, typed out, then held.
#   await say("BIG BRO", "I have everything.", 1.6)     (awaitable; returns early when `skipping` is set)
#   await shout("JUST", 1.4)                              (a big single word in the middle of the screen)

var skipping = false
var root
var panel
var who_lbl
var line_lbl
var big_lbl
var tint = Color.WHITE

func _ready():
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	panel = PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.78
	panel.anchor_bottom = 0.78
	panel.offset_left = -330
	panel.offset_right = 330
	panel.offset_top = -50
	panel.offset_bottom = 60
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.08, 0.66)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 10
	sb.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", sb)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	panel.add_child(v)
	who_lbl = Label.new()
	who_lbl.add_theme_font_size_override("font_size", 15)
	who_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	who_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(who_lbl)
	line_lbl = Label.new()
	line_lbl.add_theme_font_size_override("font_size", 32)
	line_lbl.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	line_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	line_lbl.add_theme_constant_override("outline_size", 6)
	line_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(line_lbl)
	root.add_child(panel)
	panel.modulate.a = 0.0
	big_lbl = Label.new()
	big_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	big_lbl.anchor_top = 0.22
	big_lbl.anchor_bottom = 0.5
	big_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	big_lbl.add_theme_font_size_override("font_size", 120)
	big_lbl.add_theme_color_override("font_color", Color(1, 0.95, 0.75))
	big_lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0, 0.8))
	big_lbl.add_theme_constant_override("outline_size", 14)
	big_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	big_lbl.modulate.a = 0.0
	root.add_child(big_lbl)

func _real_wait(sec):
	var t0 = GS.msec()
	while (GS.msec() - t0) < sec * 1000.0 and not skipping:
		await get_tree().process_frame

func say(who, text, hold = 1.4, col = Color(1, 0.97, 0.9)):
	if skipping:
		return
	who_lbl.text = who
	line_lbl.text = ""
	line_lbl.add_theme_color_override("font_color", col)
	panel.modulate.a = 1.0
	var n = text.length()
	var t0 = GS.msec()
	while not skipping:
		var k = int((GS.msec() - t0) / 1000.0 * 42.0)
		line_lbl.text = text.substr(0, min(k, n))
		if k >= n:
			break
		await get_tree().process_frame
	line_lbl.text = text
	await _real_wait(hold)
	var tw = create_tween().set_ignore_time_scale(true)
	tw.tween_property(panel, "modulate:a", 0.0, 0.18)
	await tw.finished

func shout(text, hold = 1.2, col = Color(1, 0.95, 0.75)):
	if skipping:
		return
	big_lbl.text = text
	big_lbl.add_theme_color_override("font_color", col)
	big_lbl.scale = Vector2(0.8, 0.8)
	big_lbl.pivot_offset = big_lbl.size * 0.5
	var tw = create_tween().set_ignore_time_scale(true)
	tw.set_parallel(true)
	tw.tween_property(big_lbl, "modulate:a", 1.0, 0.12)
	tw.tween_property(big_lbl, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	await _real_wait(hold)
	var tw2 = create_tween().set_ignore_time_scale(true)
	tw2.tween_property(big_lbl, "modulate:a", 0.0, 0.3)
	await tw2.finished

func hide_all():
	panel.modulate.a = 0.0
	big_lbl.modulate.a = 0.0
