extends CanvasLayer
# Main menu (START / CONTINUE / QUIT - nothing else: the game teaches the rest), pause menu (with SAVE and a controls page).

signal continue_pressed
signal save_pressed
signal start_pressed
signal resume_pressed
signal restart_pressed
signal quit_to_menu_pressed

var main_panel
var controls_panel
var pause_panel
var in_game = false
var paused = false
var continue_btn
var save_btn
var save_note

func _ready():
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	main_panel = _panel(0.55)
	var v = _vbox(main_panel)
	v.add_child(_lbl("JUST SOME FRIES", 84, Color(1, 0.93, 0.7)))
	v.add_child(_spacer(30))
	v.add_child(_btn("START", func(): start_pressed.emit()))
	continue_btn = _btn("CONTINUE", func(): continue_pressed.emit())
	v.add_child(continue_btn)
	v.add_child(_btn("QUIT", func(): get_tree().quit()))
	controls_panel = _panel(0.8)
	var c = _vbox(controls_panel)
	c.add_child(_lbl("CONTROLS", 56, Color(1, 0.93, 0.7)))
	c.add_child(_spacer(14))
	for line in ["Mouse — Steer", "W — Throttle    S — Brake", "Shift — Boost (burns stamina)    Ctrl — Land now", "A / D — Bank   (double-tap: roll dodge)", "Space — Flap",
			"Reach the speed a fry needs (shown on the speed meter), fly at it, press E as the white ring passes through the green, then the gold",
			"Gold fries: three rings, three presses.    Diamond fries: five.    A green grab? Press E again to slip the owner's swing",
			"F — Yell", "Hold Tab — Gull Sight (free when you stand still, shows every fry nearby and the speed it needs)", "C — Codex (right-click a taken item to wear it)",
			"Land anywhere to rest — higher is faster"]:
		c.add_child(_lbl(line, 22))
	c.add_child(_spacer(20))
	c.add_child(_btn("BACK", func():
		controls_panel.visible = false
		(pause_panel if in_game else main_panel).visible = true))
	controls_panel.visible = false
	pause_panel = _panel(0.6)
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

func show_main():
	in_game = false
	main_panel.visible = true
	var has = GS.has_save()
	continue_btn.disabled = not has
	continue_btn.tooltip_text = "" if has else "no saved flight yet"
	if has:
		continue_btn.grab_focus()
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
	return b
