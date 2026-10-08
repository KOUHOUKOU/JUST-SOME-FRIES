extends CanvasLayer
# Opening title cards ("This is an age of magic...") and the end-credits roll (with the numbers of YOUR run, told as jokes).
#   play_opening()  -> emits `finished`
#   play_ending()   -> the opening's cards again, changed ("...a seagull ate one plain fry"), over a small drawn dusk; emits `finished`
#   play_credits()  -> emits `restart_requested` (E / Enter) or `menu_requested` (Esc) at the end

signal finished
signal restart_requested
signal menu_requested

const GOLD = Color("F5C65A")
const PAPER = Color(0.96, 0.93, 0.86)

# all the words of a card sit on ONE page: each line fades in under the last one, nothing fades out in between
const OPENING = ["THIS IS AN AGE OF MAGIC.", "THE WIND LISTENS TO CERTAIN FRIES.", "BREATH IS SOLD BY THE CARTON.", "AND SOMEWHERE ON A PIER,", "A SEAGULL IS HUNGRY."]
const OPENING_Y = [0.10, 0.21, 0.32, 0.45, 0.52]
const ENDING = ["THIS WAS AN AGE OF MAGIC.", "THE WIND STILL LISTENS TO CERTAIN FRIES.", "BREATH IS STILL SOLD BY THE CARTON.", "AND ON A PIER,", "TWO SEAGULLS SHARED ONE PLAIN FRY."]
const ENDING_Y = [0.10, 0.21, 0.32, 0.45, 0.52]

class Portrait extends Control:
	var col = Color(0.95, 0.92, 0.84)
	var fry = 0.0
	var t = 0.0
	func _process(delta):
		t += delta
		if visible and modulate.a > 0.01:
			queue_redraw()
	func _draw():
		var k = size.y / 260.0
		var pts = PackedVector2Array([Vector2(0, 108), Vector2(46, 96), Vector2(62, 70), Vector2(100, 52), Vector2(140, 66), Vector2(152, 100), Vector2(178, 150),
			Vector2(210, 220), Vector2(222, 260), Vector2(40, 260), Vector2(62, 200), Vector2(74, 138), Vector2(60, 122), Vector2(20, 118)])
		for i in pts.size():
			pts[i] = pts[i] * k + Vector2(size.x - 232.0 * k, 0.0)
		draw_colored_polygon(pts, col)
		draw_circle(Vector2(92, 82) * k + Vector2(size.x - 232.0 * k, 0.0), 5.0 * k, Color(0.05, 0.05, 0.08, 0.9))
		# the fry: golden, a little crinkled, slides in from the left and rests in the beak
		if fry > 0.001:
			var x0 = lerp(-70.0, 8.0, fry) * k + size.x - 232.0 * k
			var y0 = 110.0 * k
			var a = fry
			draw_line(Vector2(x0, y0 + 2.0 * k), Vector2(x0 - 78.0 * k, y0 - 3.0 * k), Color(0.98, 0.8, 0.28, a), 11.0 * k, true)
			draw_line(Vector2(x0 - 20.0 * k, y0 - 5.0 * k), Vector2(x0 - 20.0 * k, y0 + 9.0 * k), Color(0.85, 0.62, 0.15, a), 2.0 * k)
			draw_line(Vector2(x0 - 44.0 * k, y0 - 6.0 * k), Vector2(x0 - 44.0 * k, y0 + 7.0 * k), Color(0.85, 0.62, 0.15, a), 2.0 * k)

# a few shapes at dusk: the pier, the sea, the sun going down and a small gull with the one fry it wanted
class EndArt extends Control:
	var t = 0.0
	func _process(delta):
		t += delta
		if visible and modulate.a > 0.01:
			queue_redraw()
	func _draw():
		var w = size.x
		var h = size.y
		var hz = h * 0.62
		for i in 70:
			var u = float(i) / 69.0
			var c = Color(0.09, 0.10, 0.24).lerp(Color(0.97, 0.56, 0.36), pow(u, 1.6))
			draw_rect(Rect2(0, hz * u * 0.98, w, hz / 69.0 + 2.0), c)
		draw_circle(Vector2(w * 0.5, hz - 4.0), 74.0, Color(1.0, 0.86, 0.55, 0.95))
		draw_circle(Vector2(w * 0.5, hz - 4.0), 118.0, Color(1.0, 0.7, 0.4, 0.18))
		draw_rect(Rect2(0, hz, w, h - hz), Color(0.10, 0.13, 0.27))
		for k in 9:
			var yy = hz + 8.0 + k * (h - hz) / 9.0
			var ww = 40.0 + k * 26.0 + sin(t * 0.8 + k) * 14.0
			draw_rect(Rect2(w * 0.5 - ww * 0.5 + sin(t * 0.5 + k * 2.0) * 20.0, yy, ww, 2.0), Color(1.0, 0.75, 0.5, 0.35 - k * 0.03))
		var py = h * 0.74
		var ink = Color(0.04, 0.045, 0.09)
		draw_rect(Rect2(w * 0.18, py, w * 0.64, 16.0), ink)
		for k in 14:
			draw_rect(Rect2(w * 0.2 + k * w * 0.046, py, 7.0, h * 0.2), ink)
	
var art
var page = []
var portrait
var keep_black = false
var root
var bg
var lbl
var sub
var hintl
var scroll
var skipping = false
var mode = ""
var can_input = false
var poster = null
var dimmer = null
var hold_p = 0.0

func _ready():
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	poster = TextureRect.new()
	poster.set_anchors_preset(Control.PRESET_FULL_RECT)
	poster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	poster.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	poster.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists("res://assets/ui/cover.jpg"):
		poster.texture = load("res://assets/ui/cover.jpg")
	poster.modulate.a = 0.0
	root.add_child(poster)
	dimmer = ColorRect.new()
	dimmer.color = Color(0.02, 0.03, 0.08, 1.0)
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dimmer.modulate.a = 0.0
	root.add_child(dimmer)
	art = EndArt.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.modulate.a = 0.0
	root.add_child(art)
	lbl = _label(36, PAPER)
	lbl.anchor_top = 0.42
	lbl.anchor_bottom = 0.42
	root.add_child(lbl)
	sub = _label(22, Color(0.85, 0.82, 0.74))
	sub.anchor_top = 0.60
	sub.anchor_bottom = 0.60
	root.add_child(sub)
	hintl = _label(15, Color(1, 1, 1, 0.4))
	hintl.anchor_top = 0.94
	hintl.anchor_bottom = 0.94
	root.add_child(hintl)
	for i in 6:
		var pl = _label(34, PAPER)
		pl.anchor_top = 0.1
		pl.anchor_bottom = 0.1
		root.add_child(pl)
		page.append(pl)
	portrait = Portrait.new()
	portrait.anchor_left = 0.62
	portrait.anchor_right = 0.98
	portrait.anchor_top = 0.6
	portrait.anchor_bottom = 0.97
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.modulate.a = 0.0
	root.add_child(portrait)
	scroll = Control.new()
	scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(scroll)
	visible = false

func _label(sz, col):
	var l = Label.new()
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.anchor_left = 0.0
	l.anchor_right = 1.0
	l.modulate.a = 0.0
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _wait(sec):
	var t0 = GS.msec()
	while (GS.msec() - t0) < sec * 1000.0 and not skipping:
		await get_tree().process_frame

func _fade(node, to, sec):
	var tw = create_tween().set_ignore_time_scale(true)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(node, "modulate:a", to, sec)
	await tw.finished

func _process(delta):
	# credits are over: hold E to fly again (a stray tap does nothing)
	if mode == "credits" and can_input and visible:
		if Input.is_action_pressed("interact"):
			hold_p += delta / 0.9
			if hold_p >= 1.0:
				mode = ""
				hold_p = 0.0
				restart_requested.emit()
		else:
			hold_p = max(hold_p - delta * 2.4, 0.0)
		hintl.add_theme_color_override("font_color", Color(1, 0.9 + 0.1 * hold_p, 0.6 + 0.4 * hold_p, 0.5 + 0.5 * hold_p))

func _input(event):
	if not visible:
		return
	var press = event is InputEventKey and event.pressed and not event.echo
	if mode == "opening" and (press or (event is InputEventMouseButton and event.pressed)):
		get_viewport().set_input_as_handled()
		skipping = true
	elif mode == "ending" and press:
		skipping = true
	elif mode == "credits":
		if press and can_input:
			get_viewport().set_input_as_handled()
			if event.keycode == KEY_ESCAPE:
				mode = ""
				menu_requested.emit()
			elif false:
				pass
		elif press and event.keycode == KEY_ENTER:
			skipping = true

# ------------------------------------------------------------------ one page of words, then the little portrait in the corner
func pivot_poster():
	poster.pivot_offset = get_viewport().get_visible_rect().size * 0.5

func _reset_page():
	for pl in page:
		pl.modulate.a = 0.0
		pl.text = ""
		pl.add_theme_font_size_override("font_size", 34)
		pl.add_theme_color_override("font_color", PAPER)
	portrait.modulate.a = 0.0
	portrait.fry = 0.0

func _put(i, text, y, size_ = 34, col = PAPER):
	var pl = page[i]
	pl.text = text
	pl.anchor_top = y
	pl.anchor_bottom = y
	pl.add_theme_font_size_override("font_size", size_)
	pl.add_theme_color_override("font_color", col)
	_fade(pl, 1.0, 0.5)

func play_opening():
	mode = "opening"
	skipping = false
	visible = true
	bg.modulate.a = 1.0
	art.modulate.a = 0.0
	lbl.modulate.a = 0.0
	sub.modulate.a = 0.0
	GS.showcase_active = true
	_reset_page()
	portrait.col = PAPER
	hintl.text = "press any key to skip"
	hintl.modulate.a = 0.0
	_fade(hintl, 0.6, 0.8)
	await _wait(0.5)
	for i in OPENING.size():
		if skipping:
			break
		_put(i, OPENING[i], OPENING_Y[i])
		await _wait(0.85 if i != 3 else 0.5)
	if not skipping:
		_put(5, "JUST SOME FRIES", 0.68, 76, GOLD)
		Sfx.play("tonic", -10.0)
		await _wait(0.9)
		_fade(portrait, 1.0, 0.9)
		await _wait(1.9)
	hintl.modulate.a = 0.0
	mode = ""
	skipping = false
	GS.showcase_active = false
	finished.emit()
	for pl in page:
		_fade(pl, 0.0, 0.9)
	_fade(portrait, 0.0, 0.9)
	await _fade(bg, 0.0, 1.2)
	visible = false

# ------------------------------------------------------------------ the ending cards (the opening, answered)
func play_ending():
	mode = "ending"
	skipping = false
	visible = true
	GS.showcase_active = true
	bg.modulate.a = 0.0
	art.modulate.a = 0.0
	lbl.modulate.a = 0.0
	sub.modulate.a = 0.0
	hintl.text = ""
	_reset_page()
	portrait.col = Color(0.05, 0.05, 0.1, 0.92)
	await _fade(bg, 1.0, 1.4)
	_fade(art, 1.0, 3.0)
	await _wait(0.5)
	for i in ENDING.size():
		if skipping:
			break
		_put(i, ENDING[i], ENDING_Y[i])
		await _wait(0.85 if i != 3 else 0.5)
	if not skipping:
		_put(5, "IT WAS ENOUGH.", 0.68, 56, GOLD)
		await _wait(0.9)
		_fade(portrait, 1.0, 1.0)
		await _wait(1.8)
		# ...and now the gull in the corner has one
		var tw = create_tween().set_ignore_time_scale(true)
		tw.tween_property(portrait, "fry", 1.0, 1.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		Sfx.play("reward_3", -10.0)
		await _wait(3.6)
	for pl in page:
		_fade(pl, 0.0, 1.0)
	_fade(portrait, 0.0, 1.2)
	await _fade(art, 0.0, 1.4)
	# and then the picture that was waiting for this: the cover, with the gull and its fry. The name of the game is the answer.
	if poster.texture != null:
		pivot_poster()
		poster.scale = Vector2(1.0, 1.0)
		Sfx.play("reward_3", -9.0, 0.8)
		var tz = create_tween().set_ignore_time_scale(true)
		tz.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tz.tween_property(poster, "scale", Vector2(1.07, 1.07), 22.0)
		await _fade(poster, 1.0, 2.6)
		await _wait(4.2)
	mode = ""
	skipping = false
	keep_black = true
	finished.emit()

# ------------------------------------------------------------------ credits
func _lines():
	var secs = int(GS.end_time) if GS.end_time >= 0.0 else int(GS.run_time)
	var st = GS.stats
	var powered = GS.fry_total()
	var out = [
		["", 150, PAPER],
		["a game about one gull, one pier and one fry", 20, Color(0.8, 0.78, 0.7)],
		["", 56, PAPER],
		["STARRING", 16, Color(0.7, 0.7, 0.75)],
		["THE GULL", 30, PAPER], ["as Itself", 17, Color(0.7, 0.7, 0.75)], ["", 18, PAPER],
		["THE OLD MAN", 30, PAPER], ["as The Man Who Gave A Fry", 17, Color(0.7, 0.7, 0.75)], ["", 18, PAPER],
		["THE UMBRELLA LADY", 30, PAPER], ["as A Witness, With An Umbrella", 17, Color(0.7, 0.7, 0.75)], ["", 18, PAPER],
		["A VERY FAST KID", 30, PAPER], ["as A Very Fast Kid", 17, Color(0.7, 0.7, 0.75)], ["", 18, PAPER],
		["THE BIG BROTHER", 30, PAPER], ["as Someone Who Had Everything", 17, Color(0.7, 0.7, 0.75)], ["", 18, PAPER],
		["THE DOGS", 30, PAPER], ["as Concerned Authorities", 17, Color(0.7, 0.7, 0.75)], ["", 18, PAPER],
		["THE WALL", 30, PAPER], ["as Itself (you have met)", 17, Color(0.7, 0.7, 0.75)], ["", 48, PAPER],
		["MUSIC", 16, Color(0.7, 0.7, 0.75)],
		["Morning at the Pier  -  after Edvard Grieg, Morning Mood", 20, PAPER],
		["Home  -  after Antonin Dvorak, Largo from the New World Symphony", 20, PAPER],
		["played on GeneralUser GS (S. Christian Collins)", 17, Color(0.7, 0.7, 0.75)], ["", 48, PAPER],
		["BY THE NUMBERS", 16, Color(0.7, 0.7, 0.75)],
		["TIME ON THE PIER   %02d:%02d" % [secs / 60, secs % 60], 24, PAPER],
		["FRIES STOLEN   %d" % st["stolen"], 24, PAPER],
		["PERFECT GRABS   %d" % st["perfect"], 24, PAPER],
		["SWINGS SLIPPED   %d" % st["slipped"], 24, PAPER],
		["FRIES THAT HIT THE FLOOR   %d" % st["shot"], 24, PAPER],
		["TIMES YOU WERE SWATTED   %d" % st["swats"], 24, PAPER],
		["WALLS MET   %d" % st["walls"], 24, PAPER],
		["THINGS BORROWED FROM STRANGERS   %d" % GS.worn.size(), 24, PAPER],
		["DRINKS HAD   %d   (SOME OF THEM WERE A MISTAKE)" % st.get("drinks", 0), 24, PAPER],
		["RAINBOW FRIES   %d" % st.get("rainbow", 0), 24, PAPER],
		["KIND CHILDREN   %d     NEW FRIENDS   %d" % [st.get("fed", 0), st.get("friends", 0)], 24, PAPER],
		["FISH CAUGHT   %d   (NOT FRIES. SO NOT THE POINT.)" % st["fish"], 24, PAPER],
		["VOLLEYBALLS TO THE FACE   %d" % st["bops"], 24, PAPER],
		["KIDS THAT SHOUTED BOO   %d" % st["scares"], 24, PAPER],
		["SECONDS SPENT SQUINTING   %d" % int(st["vision_s"]), 24, PAPER],
		["", 24, PAPER],
		["FRIES WITH SPECIAL POWERS   %d / 24" % powered, 28, Color(1.0, 0.85, 0.5)],
		["FRIES YOU ACTUALLY WANTED   1", 28, GOLD],
		["", 60, PAPER],
		["NO FRIES WERE HARMED IN THE MAKING OF THIS GAME.", 20, PAPER],
		["SEVERAL WERE EATEN.", 20, PAPER],
		["", 40, PAPER],
		["(he would probably have given you one anyway.)", 17, Color(0.78, 0.76, 0.7)],
		["", 80, PAPER],
		["THANK YOU FOR PLAYING.", 34, GOLD],
	]
	return out

func play_credits():
	mode = "credits"
	skipping = false
	can_input = false
	visible = true
	GS.showcase_active = true
	if not keep_black:
		bg.modulate.a = 0.0
	lbl.modulate.a = 0.0
	sub.modulate.a = 0.0
	hintl.text = ""
	hold_p = 0.0
	if not keep_black:
		await _fade(bg, 1.0, 1.6)
	if poster.modulate.a > 0.1:
		_fade(dimmer, 0.66, 1.6)
	keep_black = false
	for c in scroll.get_children():
		c.queue_free()
	var vp = get_viewport().get_visible_rect().size
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.custom_minimum_size = Vector2(vp.x, 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(box)
	for ln in _lines():
		var l = Label.new()
		l.text = ln[0]
		l.add_theme_font_size_override("font_size", ln[1])
		l.add_theme_color_override("font_color", ln[2])
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
		l.add_theme_constant_override("outline_size", 4)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(l)
	await get_tree().process_frame
	await get_tree().process_frame
	var h = box.size.y
	scroll.position = Vector2(0, vp.y)
	var dur = clamp(h / 70.0, 20.0, 60.0)
	var tw = create_tween().set_ignore_time_scale(true)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(scroll, "position:y", vp.y * 0.5 - h + 40.0, dur)
	hintl.text = "enter: skip"
	_fade(hintl, 1.0, 1.0)
	while tw.is_running() and not skipping:
		await get_tree().process_frame
	tw.kill()
	scroll.position.y = vp.y * 0.5 - h + 40.0
	skipping = false
	can_input = true
	hintl.text = "HOLD  E  -  fly again          ESC  -  menu"
	hintl.modulate.a = 0.0
	hintl.anchor_top = 0.9
	hintl.anchor_bottom = 0.9
	hintl.add_theme_font_size_override("font_size", 22)
	await _fade(hintl, 0.9, 1.0)
