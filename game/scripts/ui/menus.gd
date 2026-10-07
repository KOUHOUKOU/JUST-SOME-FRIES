extends CanvasLayer
# Title screen (the cover illustration, a slow camera drift, golden dust, a quiet row of three words), pause menu (with SAVE and a controls page).
# The first second of the game is the cover: it fades in from black, drifts, and the menu words rise one after the other. Nothing else on screen.

signal continue_pressed
signal save_pressed
signal start_pressed
signal resume_pressed
signal restart_pressed
signal quit_to_menu_pressed

const GOLD = Color("F5C65A")
const CREAM = Color("F8F0DC")

var main_panel
var controls_panel
var pause_panel
var in_game = false
var paused = false
var continue_btn = null           # kept for old call sites (tests ask for .disabled)
var save_btn
var save_note
var cover

# ---------------------------------------------------------------- the cover
class Cover extends Control:
	signal chosen(id)
	var tex = null
	var bold
	var t = 0.0
	var intro_t = 0.0
	var items = []               # [{"id", "label", "on"}]
	var sel = 0
	var anim = [0.0, 0.0, 0.0]
	var rects = []
	var motes = []
	var mpos = Vector2(0.5, 0.5)
	var leaving = -1.0
	var leave_id = ""
	var last_hover = -1

	func _ready():
		mouse_filter = Control.MOUSE_FILTER_STOP
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if ResourceLoader.exists("res://assets/ui/cover.jpg"):
			tex = load("res://assets/ui/cover.jpg")
		var fv = FontVariation.new()
		fv.base_font = ThemeDB.fallback_font
		fv.variation_embolden = 0.55
		bold = fv
		for i in 54:
			motes.append([randf(), randf(), randf(), randf()])
		items = [{"id": "start", "label": "START", "on": true}, {"id": "continue", "label": "CONTINUE", "on": false}]
		if not OS.has_feature("web"):
			items.append({"id": "quit", "label": "QUIT", "on": true})

	func reset_intro():
		intro_t = 0.0
		leaving = -1.0
		sel = 0 if not items[1]["on"] else 1

	func set_save(has):
		items[1]["on"] = has
		sel = 1 if has else 0

	func _process(delta):
		if not visible:
			return
		t += delta
		intro_t += delta
		for i in anim.size():
			if i < items.size():
				anim[i] = move_toward(anim[i], 1.0 if (i == sel and items[i]["on"]) else 0.0, delta * 6.0)
		if leaving >= 0.0:
			leaving += delta
			if leaving > 0.75:
				leaving = -1.0
				chosen.emit(leave_id)
		queue_redraw()

	func _next(dir):
		for k in items.size():
			sel = (sel + dir + items.size()) % items.size()
			if items[sel]["on"]:
				break
		Sfx.play("tick_ui", -16.0, 1.0)

	func _pick(i):
		if leaving >= 0.0 or not items[i]["on"]:
			Sfx.play("tooslow", -16.0)
			return
		sel = i
		leaving = 0.0
		leave_id = items[i]["id"]
		Sfx.play("ui_go", -8.0)

	func _input(event):
		if not visible or leaving >= 0.0:
			return
		if event is InputEventKey and event.pressed and not event.echo:
			match event.keycode:
				KEY_DOWN, KEY_S, KEY_RIGHT, KEY_D:
					_next(1)
					get_viewport().set_input_as_handled()
				KEY_UP, KEY_W, KEY_LEFT, KEY_A:
					_next(-1)
					get_viewport().set_input_as_handled()
				KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E:
					_pick(sel)
					get_viewport().set_input_as_handled()

	func _gui_input(event):
		if leaving >= 0.0:
			return
		if event is InputEventMouseMotion:
			mpos = Vector2(event.position.x / max(size.x, 1.0), event.position.y / max(size.y, 1.0))
			for i in rects.size():
				if rects[i].has_point(event.position) and items[i]["on"]:
					if sel != i:
						sel = i
						Sfx.play("tick_ui", -16.0, 1.0)
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			for i in rects.size():
				if rects[i].has_point(event.position):
					_pick(i)

	func _word(text, pos, fs, col, gap):
		var x = pos.x
		for ch in text:
			draw_string(bold, Vector2(x + 2.0, pos.y + 2.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, col.a * 0.55))
			draw_string(bold, Vector2(x, pos.y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
			x += bold.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + gap
		return x - pos.x - gap

	func _width(text, fs, gap):
		var w = 0.0
		for ch in text:
			w += bold.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + gap
		return w - gap

	# a small golden fry stick that leans on the chosen word
	func _fry(c, s, a):
		var d = Vector2(cos(-0.5), sin(-0.5))
		var n = Vector2(-d.y, d.x)
		var l = s
		var w = s * 0.17
		draw_colored_polygon(PackedVector2Array([c - d * l - n * w, c + d * l - n * w, c + d * l + n * w, c - d * l + n * w]), Color(0.98, 0.78, 0.26, a))
		draw_colored_polygon(PackedVector2Array([c - d * l - n * w * 0.2, c + d * l - n * w * 0.2, c + d * l + n * w * 0.9, c - d * l + n * w * 0.9]), Color(1.0, 0.9, 0.55, a * 0.55))
		draw_line(c - d * l * 0.2 - n * w, c - d * l * 0.2 + n * w, Color(0.8, 0.55, 0.12, a), 1.6)
		draw_line(c + d * l * 0.35 - n * w, c + d * l * 0.35 + n * w, Color(0.8, 0.55, 0.12, a), 1.6)

	func _draw():
		var W = size.x
		var H = size.y
		if H < 20.0:
			return
		var u = H / 720.0
		var fade_in = clamp(intro_t / 1.3, 0.0, 1.0)
		if tex != null:
			var e = 1.0 - pow(1.0 - clamp(intro_t / 4.0, 0.0, 1.0), 3.0)
			var k = lerp(1.12, 1.035, e) + 0.012 * sin(t * 0.13) + (leaving * 0.12 if leaving > 0.0 else 0.0)
			var sc = max(W / 1672.0, H / 941.0)
			var ts = Vector2(1672.0, 941.0) * sc * k
			var par = (mpos - Vector2(0.5, 0.5)) * -16.0 * u
			draw_texture_rect(tex, Rect2((size - ts) * 0.5 + par + Vector2(sin(t * 0.17) * 6.0, cos(t * 0.11) * 4.0) * u, ts), false, Color(1, 1, 1, 1))
		else:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.12, 0.2))
		# a quiet scrim under the words (a film poster's footer) and a soft vignette
		var sy = H * 0.66
		draw_polygon(PackedVector2Array([Vector2(0, sy), Vector2(W, sy), Vector2(W, H), Vector2(0, H)]),
			PackedColorArray([Color(0.03, 0.04, 0.1, 0.0), Color(0.03, 0.04, 0.1, 0.0), Color(0.03, 0.04, 0.1, 0.82), Color(0.03, 0.04, 0.1, 0.82)]))
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H * 0.14), Vector2(0, H * 0.14)]),
			PackedColorArray([Color(0.02, 0.02, 0.06, 0.35), Color(0.02, 0.02, 0.06, 0.35), Color(0.02, 0.02, 0.06, 0.0), Color(0.02, 0.02, 0.06, 0.0)]))
		# golden dust drifting up through the picture
		for m in motes:
			var life = fmod(t * (0.018 + m[2] * 0.03) + m[3], 1.0)
			var px = fmod(m[0] + sin(t * 0.3 + m[3] * 9.0) * 0.02, 1.0) * W
			var py = H * (1.05 - life * 1.1)
			var tw = 0.5 + 0.5 * sin(t * (1.0 + m[2] * 2.0) + m[3] * 20.0)
			var r = (1.2 + m[2] * 2.6) * u
			draw_circle(Vector2(px, py), r * 2.4, Color(1.0, 0.86, 0.5, 0.05 * tw * fade_in))
			draw_circle(Vector2(px, py), r, Color(1.0, 0.93, 0.7, (0.25 + 0.5 * tw) * fade_in * sin(life * PI)))
		# the three words
		rects.clear()
		var fs = int(30.0 * u)
		var gap = 5.0 * u
		var total = 0.0
		var widths = []
		for it in items:
			var w = _width(it["label"], fs, gap)
			widths.append(w)
			total += w
		var spacing = 96.0 * u
		total += spacing * (items.size() - 1)
		var x = (W - total) * 0.5
		var y = H * 0.905
		for i in items.size():
			var it2 = items[i]
			var al = clamp((intro_t - 1.5 - i * 0.2) / 0.55, 0.0, 1.0)
			var yy = y + (1.0 - al) * 16.0 * u
			var s = anim[i]
			var col = CREAM if it2["on"] else Color(0.7, 0.72, 0.8)
			col = col.lerp(GOLD, s)
			col.a = al * (1.0 if it2["on"] else 0.38)
			_word(it2["label"], Vector2(x, yy - s * 3.0 * u), fs, col, gap)
			rects.append(Rect2(Vector2(x - 20.0 * u, y - 36.0 * u), Vector2(widths[i] + 40.0 * u, 54.0 * u)))
			# the underline grows under the chosen word, a fry stick leans on it
			if s > 0.01:
				var ux = x + widths[i] * 0.5
				draw_line(Vector2(ux - widths[i] * 0.5 * s, yy + 11.0 * u), Vector2(ux + widths[i] * 0.5 * s, yy + 11.0 * u), Color(GOLD.r, GOLD.g, GOLD.b, 0.9 * al), 2.5 * u)
				_fry(Vector2(x - 30.0 * u, yy - 10.0 * u + sin(t * 3.0) * 1.5 * u), 15.0 * u * s, 0.95 * al * s)
			x += widths[i] + spacing
		# footer: one line of small print
		var fa = clamp((intro_t - 2.4) / 1.0, 0.0, 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(30.0 * u, H - 20.0 * u), "a game about one gull, one pier and one fry", HORIZONTAL_ALIGNMENT_LEFT, -1, int(13 * u), Color(1, 1, 1, 0.45 * fa))
		draw_string(ThemeDB.fallback_font, Vector2(W - 330.0 * u, H - 20.0 * u), "W / S or mouse  -  E / click", HORIZONTAL_ALIGNMENT_RIGHT, 300.0 * u, int(13 * u), Color(1, 1, 1, 0.3 * fa))
		# fade in from black, and out to black when a word is chosen
		if fade_in < 1.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 1.0 - fade_in))
		if leaving >= 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, clamp(leaving / 0.7, 0.0, 1.0)))

func _ready():
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	var ui_theme = _make_theme()
	cover = Cover.new()
	cover.chosen.connect(_on_cover_chosen)
	add_child(cover)
	main_panel = cover
	controls_panel = _panel(0.8)
	controls_panel.theme = ui_theme
	var c = _vbox(controls_panel)
	c.add_child(_lbl("CONTROLS", 56, Color(1, 0.93, 0.7)))
	c.add_child(_spacer(14))
	for line in ["Mouse - steer          W - throttle          S - brake", "Shift - boost          Ctrl - land now          Space - flap          A / D - bank (double-tap: roll)",
			"Reach the speed a fry needs (the number on the speed meter) and fly straight at it.",
			"Circles appear around it. Press E when a white wave shrinks onto the green ring; the gold ring inside it counts double.",
			"E while flying free - points out the nearest fry that you can really catch.",
			"Hold Tab - Gull Sight (free on the ground). It shows fries, things to take, and where a fish is about to jump.",
			"C - Codex (fries, wardrobe, fish book; right-click a taken item to wear it)          F - yell",
			"Every drink gives breath back and adds its time. All three drinks at once: STARLIGHT.",
			"Land anywhere to rest - higher is faster. Trees and roofs count."]:
		c.add_child(_lbl(line, 20))
	c.add_child(_spacer(20))
	c.add_child(_btn("BACK", func():
		controls_panel.visible = false
		(pause_panel if in_game else main_panel).visible = true))
	controls_panel.visible = false
	pause_panel = _panel(0.6)
	pause_panel.theme = ui_theme
	var p = _vbox(pause_panel)
	p.add_child(_lbl("PAUSED", 56, Color(1, 0.93, 0.7)))
	p.add_child(_spacer(14))
	p.add_child(_btn("RESUME", func(): set_paused(false)))
	save_btn = _btn("SAVE", func(): save_pressed.emit())
	p.add_child(save_btn)
	save_note = _lbl("", 18, Color(0.7, 1.0, 0.75))
	p.add_child(save_note)
	p.add_child(_btn("RESTART RUN", func():
		set_paused(false)
		restart_pressed.emit()))
	p.add_child(_lbl("MOUSE SENSITIVITY", 20))
	var sl = HSlider.new()
	sl.min_value = 0.4
	sl.max_value = 2.5
	sl.step = 0.05
	sl.value = GS.mouse_sens_mult
	sl.custom_minimum_size = Vector2(300, 24)
	sl.value_changed.connect(func(val): GS.mouse_sens_mult = val)
	p.add_child(sl)
	var inv = CheckBox.new()
	inv.text = "INVERT MOUSE Y"
	inv.add_theme_font_size_override("font_size", 20)
	inv.button_pressed = GS.invert_y
	inv.toggled.connect(func(on): GS.invert_y = on)
	p.add_child(inv)
	p.add_child(_btn("CONTROLS", func():
		pause_panel.visible = false
		controls_panel.visible = true))
	p.add_child(_btn("SAVE & QUIT TO MENU", func():
		save_pressed.emit()
		set_paused(false)
		quit_to_menu_pressed.emit()))
	pause_panel.visible = false
	# a stand-in for the old CONTINUE button so that the test bots can still read `.disabled`
	continue_btn = Button.new()
	continue_btn.disabled = true

func _on_cover_chosen(id):
	match id:
		"start":
			start_pressed.emit()
		"continue":
			continue_pressed.emit()
		"quit":
			get_tree().quit()

func show_main():
	in_game = false
	main_panel.visible = true
	cover.reset_intro()
	var has = GS.has_save()
	cover.set_save(has)
	continue_btn.disabled = not has
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func begin_game():
	in_game = true
	main_panel.visible = false
	controls_panel.visible = false
	pause_panel.visible = false

func note_saved(ok):
	save_note.text = "saved." if ok else "could not save."
	get_tree().create_timer(2.0, true, false, true).timeout.connect(func():
		if save_note != null:
			save_note.text = "")

func set_paused(p):
	paused = p
	if p and save_note != null:
		save_note.text = ""
	Engine.max_fps = 30 if p else 60
	get_tree().paused = p
	pause_panel.visible = p
	controls_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if p else Input.MOUSE_MODE_CAPTURED
	resume_pressed.emit()

func _notification(what):
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and in_game and not paused and not GS.showcase_active and not GS.no_focus_pause:
		set_paused(true)

func _unhandled_input(event):
	if in_game and not GS.showcase_active and event.is_action_pressed("pause_game"):
		if controls_panel.visible:
			controls_panel.visible = false
			pause_panel.visible = true
		else:
			set_paused(not paused)

func _panel(a):
	var r = ColorRect.new()
	r.color = Color(0.04, 0.06, 0.1, a)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(r)
	return r

func _vbox(parent):
	var cc = CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(cc)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	cc.add_child(v)
	return v

func _lbl(text, sz, col = Color(1, 1, 1)):
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _spacer(h):
	var s = Control.new()
	s.custom_minimum_size = Vector2(0, h)
	return s

func _btn(text, cb):
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 52)
	b.add_theme_font_size_override("font_size", 26)
	b.pressed.connect(cb)
	b.mouse_entered.connect(func(): Sfx.play("tick_ui", -18.0))
	return b

# flat, warm buttons instead of the engine's grey ones
func _make_theme():
	var th = Theme.new()
	var mk = func(bg, border):
		var sb = StyleBoxFlat.new()
		sb.bg_color = bg
		sb.border_color = border
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		return sb
	th.set_stylebox("normal", "Button", mk.call(Color(0.08, 0.1, 0.16, 0.8), Color(1, 0.9, 0.6, 0.25)))
	th.set_stylebox("hover", "Button", mk.call(Color(0.14, 0.15, 0.2, 0.9), GOLD))
	th.set_stylebox("pressed", "Button", mk.call(Color(0.22, 0.2, 0.14, 0.95), GOLD))
	th.set_stylebox("focus", "Button", mk.call(Color(0.14, 0.15, 0.2, 0.9), GOLD))
	th.set_stylebox("disabled", "Button", mk.call(Color(0.06, 0.07, 0.1, 0.6), Color(1, 1, 1, 0.08)))
	th.set_color("font_color", "Button", CREAM)
	th.set_color("font_hover_color", "Button", GOLD)
	th.set_color("font_pressed_color", "Button", GOLD)
	th.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.3))
	return th
