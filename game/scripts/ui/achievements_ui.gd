extends CanvasLayer
# THE ACHIEVEMENTS GALLERY (round 15). Twenty-four small pictures in a grid; point at one (or use the arrow keys) and the card on the right says what it is, what to do,
# what the game thinks of you, and the day you got it. A locked one shows its picture in the dark, still with the thing to do (a hint is not a spoiler here).
# Opened from the title screen and the pause menu. It lives in the player's profile (GS.ach_profile), not in one run.

signal closed

const GOLD = Color("F5C65A")
const CREAM = Color("F8F0DC")

var view

class View extends Control:
	var ui
	var sel = 0
	var cells = []
	var tex = {}
	var t = 0.0
	var back_rect = Rect2()
	var bold

	func _ready():
		mouse_filter = Control.MOUSE_FILTER_STOP
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var fv = FontVariation.new()
		fv.base_font = ThemeDB.fallback_font
		fv.variation_embolden = 0.5
		bold = fv

	func _icon(id):
		if tex.has(id):
			return tex[id]
		var p = "res://assets/ui/achv/%s.png" % id
		tex[id] = load(p) if ResourceLoader.exists(p) else null
		return tex[id]

	func _process(delta):
		if visible:
			t += delta
			queue_redraw()

	func _ids():
		return GS.ACH.keys()

	func _input(event):
		if not visible:
			return
		if event is InputEventKey and event.pressed and not event.echo:
			var n = _ids().size()
			match event.keycode:
				KEY_ESCAPE, KEY_BACKSPACE, KEY_TAB:
					ui.close()
				KEY_RIGHT, KEY_D:
					sel = (sel + 1) % n
					Sfx.play("tick_ui", -16.0)
				KEY_LEFT, KEY_A:
					sel = (sel + n - 1) % n
					Sfx.play("tick_ui", -16.0)
				KEY_DOWN, KEY_S:
					sel = (sel + 6) % n
					Sfx.play("tick_ui", -16.0)
				KEY_UP, KEY_W:
					sel = (sel + n - 6) % n
					Sfx.play("tick_ui", -16.0)
				KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E:
					pass
				_:
					return
			get_viewport().set_input_as_handled()

	func _gui_input(event):
		if event is InputEventMouseMotion:
			for i in cells.size():
				if cells[i].has_point(event.position) and sel != i:
					sel = i
					Sfx.play("tick_ui", -18.0)
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if back_rect.has_point(event.position):
				ui.close()

	func _wrap(font, text, width, fs):
		var words = text.split(" ")
		var lines = []
		var cur = ""
		for w in words:
			var test = w if cur == "" else cur + " " + w
			if font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > width and cur != "":
				lines.append(cur)
				cur = w
			else:
				cur = test
		lines.append(cur)
		return lines

	func _draw():
		var W = size.x
		var H = size.y
		if H < 20.0:
			return
		var u = H / 720.0
		var font = ThemeDB.fallback_font
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.04, 0.09, 0.985))
		# a faint warm glow in the corner, like the cover
		for k in 6:
			draw_circle(Vector2(W * 0.85, H * 0.2), (420.0 - k * 60.0) * u, Color(1.0, 0.75, 0.4, 0.02))
		var ids = _ids()
		var got = GS.ach_count()
		# title
		var title = "ACHIEVEMENTS"
		var x = 54.0 * u
		for ch in title:
			draw_string(bold, Vector2(x + 2, 74.0 * u + 2), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, int(42 * u), Color(0, 0, 0, 0.5))
			draw_string(bold, Vector2(x, 74.0 * u), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, int(42 * u), GOLD)
			x += bold.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, int(42 * u)).x + 4.0 * u
		draw_string(font, Vector2(x + 24.0 * u, 74.0 * u), "%d / %d" % [got, ids.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, int(26 * u), Color(1, 0.96, 0.85, 0.85))
		# the grid
		cells.clear()
		var cs = 106.0 * u
		var gap = 14.0 * u
		var gx = 54.0 * u
		var gy = 112.0 * u
		for i in ids.size():
			var id = ids[i]
			var col = i % 6
			var row = i / 6
			var r = Rect2(Vector2(gx + col * (cs + gap), gy + row * (cs + gap)), Vector2(cs, cs))
			cells.append(r)
			var have = GS.ach_has(id)
			var tx = _icon(id)
			var is_sel = i == sel
			if is_sel:
				draw_rect(r.grow(7.0 * u), Color(1.0, 0.84, 0.4, 0.28 + 0.1 * sin(t * 5.0)))
			if tx != null:
				draw_texture_rect(tx, r, false, Color(1, 1, 1, 1) if have else Color(0.22, 0.24, 0.32, 1.0))
			else:
				draw_rect(r, Color(0.2, 0.2, 0.3))
			if not have:
				draw_string(bold, r.position + Vector2(0, cs * 0.66), "?", HORIZONTAL_ALIGNMENT_CENTER, cs, int(46 * u), Color(1, 1, 1, 0.35))
			else:
				draw_circle(r.position + Vector2(cs - 12.0 * u, 12.0 * u), 8.0 * u, Color(0.4, 0.95, 0.6, 0.95))
				draw_polyline(PackedVector2Array([r.position + Vector2(cs - 16.0 * u, 12.0 * u), r.position + Vector2(cs - 13.0 * u, 15.0 * u), r.position + Vector2(cs - 8.0 * u, 9.0 * u)]), Color(0.05, 0.15, 0.08), 2.0)
			if is_sel:
				draw_rect(r, Color(1.0, 0.9, 0.5, 0.95), false, 3.0)
		# the card
		var cx = gx + 6.0 * (cs + gap) + 22.0 * u
		var cw = W - cx - 46.0 * u
		var cr = Rect2(Vector2(cx, 112.0 * u), Vector2(cw, 4.0 * (cs + gap) - gap))
		draw_rect(cr, Color(0.07, 0.09, 0.15, 0.9))
		draw_rect(Rect2(cr.position, Vector2(4.0 * u, cr.size.y)), GOLD)
		var sid = ids[clamp(sel, 0, ids.size() - 1)]
		var d = GS.ACH[sid]
		var have2 = GS.ach_has(sid)
		var tx2 = _icon(sid)
		var ir = Rect2(cr.position + Vector2(22.0 * u, 22.0 * u), Vector2(150.0 * u, 150.0 * u))
		if tx2 != null:
			draw_texture_rect(tx2, ir, false, Color(1, 1, 1, 1) if have2 else Color(0.22, 0.24, 0.32, 1.0))
		if not have2:
			draw_string(bold, ir.position + Vector2(0, 98.0 * u), "?", HORIZONTAL_ALIGNMENT_CENTER, ir.size.x, int(80 * u), Color(1, 1, 1, 0.3))
		var nx = ir.position.x + ir.size.x + 22.0 * u
		var nw = cr.end.x - nx - 18.0 * u
		var ny = cr.position.y + 44.0 * u
		var name_fs = int(25 * u)
		for ln in _wrap(bold, d[0] if have2 else d[0], nw, name_fs):
			draw_string(bold, Vector2(nx, ny), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, name_fs, CREAM if have2 else Color(0.8, 0.82, 0.9))
			ny += 29.0 * u
		var status = ("OBTAINED   " + GS.ach_date(sid)) if have2 else "NOT YET"
		draw_string(font, Vector2(nx, ny + 4.0 * u), status, HORIZONTAL_ALIGNMENT_LEFT, -1, int(15 * u), Color(0.55, 0.95, 0.7) if have2 else Color(1, 1, 1, 0.45))
		var dy = ir.end.y + 40.0 * u
		draw_string(font, Vector2(cr.position.x + 22.0 * u, dy), "WHAT TO DO", HORIZONTAL_ALIGNMENT_LEFT, -1, int(12 * u), Color(GOLD.r, GOLD.g, GOLD.b, 0.85))
		dy += 24.0 * u
		for ln in _wrap(font, d[1], cr.size.x - 44.0 * u, int(19 * u)):
			draw_string(font, Vector2(cr.position.x + 22.0 * u, dy), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, int(19 * u), Color(1, 1, 1, 0.9))
			dy += 25.0 * u
		dy += 20.0 * u
		draw_string(font, Vector2(cr.position.x + 22.0 * u, dy), "THE GAME'S OPINION", HORIZONTAL_ALIGNMENT_LEFT, -1, int(12 * u), Color(GOLD.r, GOLD.g, GOLD.b, 0.85))
		dy += 24.0 * u
		if have2:
			for ln in _wrap(font, d[2], cr.size.x - 44.0 * u, int(19 * u)):
				draw_string(font, Vector2(cr.position.x + 22.0 * u, dy), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, int(19 * u), Color(1.0, 0.93, 0.7, 0.95))
				dy += 25.0 * u
		else:
			draw_string(font, Vector2(cr.position.x + 22.0 * u, dy), "(it is not telling yet)", HORIZONTAL_ALIGNMENT_LEFT, -1, int(17 * u), Color(1, 1, 1, 0.35))
		# the way back
		back_rect = Rect2(Vector2(W - 190.0 * u, H - 78.0 * u), Vector2(140.0 * u, 44.0 * u))
		var hov = back_rect.has_point(get_local_mouse_position())
		draw_rect(back_rect, Color(0.08, 0.1, 0.16, 0.9))
		draw_rect(back_rect, GOLD if hov else Color(1, 0.9, 0.6, 0.35), false, 2.0)
		draw_string(bold, back_rect.position + Vector2(0, 30.0 * u), "BACK", HORIZONTAL_ALIGNMENT_CENTER, back_rect.size.x, int(22 * u), GOLD if hov else CREAM)
		draw_string(font, Vector2(54.0 * u, H - 40.0 * u), "mouse or arrow keys  -  Esc to go back", HORIZONTAL_ALIGNMENT_LEFT, -1, int(13 * u), Color(1, 1, 1, 0.4))

func _ready():
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	view = View.new()
	view.ui = self
	add_child(view)
	view.visible = false

func open():
	view.sel = 0
	view.visible = true
	Sfx.play("chime", -14.0, 1.2)

func close():
	if not view.visible:
		return
	view.visible = false
	Sfx.play("tick_ui", -14.0, 0.8)
	closed.emit()

func is_open():
	return view != null and view.visible
