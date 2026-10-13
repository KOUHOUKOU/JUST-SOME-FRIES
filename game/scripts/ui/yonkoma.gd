extends CanvasLayer
# ROUND 16, the four-panel page. JUST SOME FRIES is, at heart, a tribute to a four-panel gull comic ("What Fries Ahead", False Knees by Joshua Barkman, 2018): two gulls on a
# ledge; one asks where they are headed; the other was going to get some fries on the pier; the first means the BIG picture (where does the path end?); and the second still
# feels it has something to do with the fries on the pier. Our game is that page, lived: a gull with a big brother who has everything, a world full of shiny things to
# collect, and a small voice that never stopped saying the same thing.
#
#   OPENING  play_comic_open(): the page is drawn panel by panel (ink wipes, speech bubbles typed letter by letter) in our own characters and words. Then the last panel
#            (the little gull, deadpan) opens up and the game is simply what happens next.
#   ENDING   play_ending(): the last picture of the game shrinks into the fourth panel of the same page; the first three panels come back (the question), and the fourth is
#            inked over the live picture: the same composition, two gulls and one plain fry, and this time the answer is in the picture.
#
# Pictures: assets/ui/yonkoma/o1..o4.png (the opening page) and p4.png (the ending's last panel). Without pictures the panels are empty ink frames (it still plays).

const PAPER = Color("F3EAD3")
const PAPER_DARK = Color("E4D7B8")
const INK = Color(0.07, 0.06, 0.09)

class Page extends Control:
	var yk
	func _draw():
		yk._paint(self)

var page
var shot = null                       # the frozen game picture (a Texture2D)
var tex = [null, null, null, null]
var paper_a = 0.0
var reveal = [0.0, 0.0, 0.0, 0.0]     # how much of every panel's drawing is inked in (a wipe, left to right)
var frame_a = [0.0, 0.0, 0.0, 0.0]    # how much of every panel's ink frame is there
var bubbles = [[], [], [], []]        # per panel: {text, rect (0..1 of the panel), tail (0..1), typed (characters shown), a (alpha)}
var shot_slot = -1                    # which slot the frozen game picture sits in
var shot_k = 0.0                      # 0 = the game picture fills the screen, 1 = it sits in its slot
var shot_a = 1.0
var ink_over = 0.0                    # the drawing of the shot's slot fades in over the game picture
var zoom_slot = -1                    # a slot that grows to fill the page
var zoom_k = 0.0
var strip_a = 1.0                     # the other panels' visibility during a zoom
var pen = -1.0
var pen_slot = -1
var wob_t = 0.0
var skip = false
var dim_a = 0.0                       # a black veil over everything
var echo_a = 1.0                      # how bright the old bubbles of the first three panels are (the ending shows them as a memory)

func _ready():
	layer = 39
	process_mode = Node.PROCESS_MODE_ALWAYS
	page = Page.new()
	page.yk = self
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page)
	visible = false

func _load(name_):
	var p = "res://assets/ui/yonkoma/%s.png" % name_
	return load(p) if ResourceLoader.exists(p) else null

func _input(event):
	if visible and event is InputEventKey and event.pressed and not event.echo:
		skip = true

func _process(delta):
	if visible:
		wob_t += delta
		page.queue_redraw()

# ------------------------------------------------------------------ layout: a 2 x 2 page, like the original
func slot_rect(i, vp):
	var s = min(vp.y * 0.452, vp.x * 0.25)
	var gap = s * 0.05
	var total = 2.0 * s + gap
	var x0 = (vp.x - total) * 0.5
	var y0 = (vp.y - total) * 0.5
	return Rect2(x0 + (i % 2) * (s + gap), y0 + (i / 2) * (s + gap), s, s)

func big_rect(vp):
	var s = vp.y * 0.94
	return Rect2((vp.x - s) * 0.5, (vp.y - s) * 0.5, s, s)

# ------------------------------------------------------------------ drawing
func _tilt(i):
	return sin(i * 2.3 + 0.7) * 0.007 + sin(wob_t * 0.9 + i) * 0.0015

func _wrap(font, text, fs, maxw):
	if Loc.cjk:
		return Loc.wrap(text, font, fs, maxw)
	var lines = []
	var cur = ""
	for w in text.split(" "):
		var t = w if cur == "" else cur + " " + w
		if font.get_string_size(Loc.t(t), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > maxw and cur != "":
			lines.append(cur)
			cur = w
		else:
			cur = t
	if cur != "":
		lines.append(cur)
	return lines

func _bubble(c, rr, b, alpha):
	var r = Rect2(rr.position + b["rect"].position * rr.size, b["rect"].size * rr.size)
	var cen = r.get_center()
	var rx = r.size.x * 0.5
	var ry = r.size.y * 0.5
	var pts = PackedVector2Array()
	for k in 40:
		var an = TAU * k / 40.0
		pts.append(cen + Vector2(cos(an) * rx, sin(an) * ry))
	# the tail
	var tp = rr.position + b["tail"] * rr.size
	var dir = (tp - cen)
	var ang = atan2(dir.y / max(ry, 1.0), dir.x / max(rx, 1.0))
	var p1 = cen + Vector2(cos(ang - 0.2) * rx, sin(ang - 0.2) * ry)
	var p2 = cen + Vector2(cos(ang + 0.2) * rx, sin(ang + 0.2) * ry)
	var white = Color(1, 1, 1, 0.97 * alpha)
	c.draw_colored_polygon(pts, white)
	c.draw_colored_polygon(PackedVector2Array([p1, tp, p2]), white)
	var line = Color(INK.r, INK.g, INK.b, alpha)
	var lw = max(rr.size.x * 0.009, 1.6)
	var closed = PackedVector2Array(pts)
	closed.append(pts[0])
	c.draw_polyline(closed, line, lw, true)
	c.draw_line(p1, tp, line, lw)
	c.draw_line(p2, tp, line, lw)
	c.draw_line(p1 + (p2 - p1) * 0.1, p2 + (p1 - p2) * 0.1, white, lw * 1.8)         # the bubble's edge does not cross the tail's mouth
	# the words, typed
	var font = ThemeDB.fallback_font
	var fs = int(max(rr.size.x * 0.05, 10.0))
	var inner = Rect2(r.position + r.size * Vector2(0.13, 0.15), r.size * Vector2(0.74, 0.7))
	var lines = _wrap(font, b["text"], fs, inner.size.x)
	var left = int(b["typed"]) if b["typed"] < b["text"].length() else 1 << 30
	var lh = fs * 1.2
	var y = inner.position.y + (inner.size.y - lines.size() * lh) * 0.5 + fs
	for ln in lines:
		var shown = ln.substr(0, left)
		left = max(left - ln.length() - 1, 0)
		if shown != "":
			var w = font.get_string_size(Loc.t(ln), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			c.draw_string(font, Vector2(cen.x - w * 0.5, y), shown, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(INK.r, INK.g, INK.b, alpha))
		y += lh

func _paint(c):
	var vp = c.size
	if paper_a > 0.001:
		c.draw_rect(Rect2(Vector2.ZERO, vp), Color(PAPER.r, PAPER.g, PAPER.b, paper_a))
		for k in 6:
			var e = 0.02 * (k + 1)
			c.draw_rect(Rect2(Vector2.ZERO, vp), Color(PAPER_DARK.r, PAPER_DARK.g, PAPER_DARK.b, 0.05 * paper_a), false, vp.y * e)
		var m = vp.y * 0.03
		c.draw_rect(Rect2(Vector2(m, m), vp - Vector2(m, m) * 2.0), Color(INK.r, INK.g, INK.b, 0.5 * paper_a), false, max(vp.y * 0.004, 2.0))
	var big = big_rect(vp)
	for i in 4:
		var r = slot_rect(i, vp)
		var a_other = strip_a if i != zoom_slot else 1.0
		if zoom_slot >= 0 and i == zoom_slot:
			r = Rect2(r.position.lerp(big.position, zoom_k), r.size.lerp(big.size, zoom_k))
		var alpha = paper_a * a_other
		var has_shot = i == shot_slot and shot != null
		if alpha <= 0.002 and not has_shot:
			continue
		var cen = r.get_center()
		var tl = _tilt(i) * (shot_k if has_shot else 1.0)
		c.draw_set_transform(cen, tl, Vector2.ONE)
		var rr = Rect2(-r.size * 0.5, r.size)
		if has_shot:
			var full0 = Rect2(-cen, vp)
			rr = Rect2(full0.position.lerp(rr.position, shot_k), full0.size.lerp(rr.size, shot_k))
		if frame_a[i] > 0.0:
			c.draw_rect(Rect2(rr.position + Vector2(r.size.x, r.size.x) * 0.018, rr.size), Color(0, 0, 0, 0.18 * alpha * frame_a[i]))
			c.draw_rect(rr, Color(1, 0.99, 0.95, alpha * frame_a[i]))
		if has_shot:
			var ssz = shot.get_size()
			var tgt_ar = rr.size.x / max(rr.size.y, 1.0)
			var src_w = ssz.y * tgt_ar
			var src = Rect2((ssz.x - src_w) * 0.5, 0.0, src_w, ssz.y) if src_w <= ssz.x else Rect2(0, 0, ssz.x, ssz.y)
			c.draw_texture_rect_region(shot, rr, src, Color(1, 1, 1, shot_a))
		if tex[i] != null and reveal[i] > 0.0:
			var wipe = ink_over if has_shot else clamp(reveal[i], 0.0, 1.0)
			if wipe > 0.0:
				var ts = tex[i].get_size()
				c.draw_texture_rect_region(tex[i], Rect2(rr.position, Vector2(rr.size.x * wipe, rr.size.y)), Rect2(0, 0, ts.x * wipe, ts.y), Color(1, 1, 1, alpha))
				if pen >= 0.0 and wipe < 1.0 and i == pen_slot:
					var px = rr.position.x + rr.size.x * wipe
					c.draw_line(Vector2(px, rr.position.y), Vector2(px, rr.end.y), Color(INK.r, INK.g, INK.b, 0.8), max(r.size.x * 0.012, 2.0))
		if frame_a[i] > 0.0 or has_shot:
			var fa = max(frame_a[i], 1.0 if has_shot else 0.0)
			c.draw_rect(rr, Color(INK.r, INK.g, INK.b, alpha * fa), false, max(r.size.x * 0.018, 3.0))
		# the speech bubbles (not while the panel is flying open)
		if zoom_k < 0.2 or i == zoom_slot:
			for b in bubbles[i]:
				if b["a"] > 0.01:
					_bubble(c, rr, b, alpha * b["a"] * (echo_a if b.get("echo", false) else 1.0))
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if dim_a > 0.001:
		c.draw_rect(Rect2(Vector2.ZERO, vp), Color(0, 0, 0, dim_a))

# ------------------------------------------------------------------ helpers
func _tw(prop, to, sec, trans = Tween.TRANS_CUBIC, ease_ = Tween.EASE_IN_OUT):
	var tw = create_tween().set_ignore_time_scale(true)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(self, prop, to, sec).set_trans(trans).set_ease(ease_)
	return tw

# wait `sec`, or until a key is pressed (the key is used up)
func _wait(sec):
	var t0 = GS.msec()
	skip = false
	while (GS.msec() - t0) < sec * 1000.0 and not skip:
		await get_tree().process_frame
	skip = false

func _ink(i, sec = 0.8):
	pen_slot = i
	pen = 0.0
	frame_a[i] = 1.0
	Sfx.play("vn_pop", -12.0, 1.1 + 0.08 * i)
	Sfx.play("whoosh", -22.0, 1.6)
	var tw = create_tween().set_ignore_time_scale(true)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_method(func(v): reveal[i] = v, 0.0, 1.0, sec).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished
	pen = -1.0

func _bubble_def(i, text, rect, tail, echo = false):
	var b = {"text": Loc.t(text), "rect": rect, "tail": tail, "typed": 0.0, "a": 0.0, "echo": echo}
	bubbles[i].append(b)
	return b

# one bubble: it pops, the words are typed (a key finishes the sentence), it is held a moment
func _say(b, hold = 1.0):
	var n = b["text"].length()
	b["a"] = 0.0
	var tw0 = create_tween().set_ignore_time_scale(true)
	tw0.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw0.tween_method(func(v): b["a"] = v, 0.0, 1.0, 0.18)
	Sfx.play("vn_pop", -14.0, 1.4)
	var t0 = GS.msec()
	skip = false
	var last = 0
	while true:
		var u = (GS.msec() - t0) / 1000.0 * Loc.cps(30.0)
		if skip or u >= n:
			b["typed"] = float(n)
			break
		b["typed"] = u
		if int(u) / 3 != last:
			last = int(u) / 3
			Sfx.play("blip", -26.0, randf_range(1.25, 1.55))
		await get_tree().process_frame
	skip = false
	await _wait(hold + 0.025 * Loc.read_len(b["text"]))

func _prep(shot_image):
	skip = false
	shot = ImageTexture.create_from_image(shot_image) if shot_image != null else null
	paper_a = 0.0
	reveal = [0.0, 0.0, 0.0, 0.0]
	frame_a = [0.0, 0.0, 0.0, 0.0]
	bubbles = [[], [], [], []]
	shot_slot = -1
	shot_k = 0.0
	shot_a = 1.0
	ink_over = 0.0
	zoom_slot = -1
	zoom_k = 0.0
	strip_a = 1.0
	pen = -1.0
	dim_a = 0.0
	echo_a = 1.0
	visible = true

func _end():
	visible = false
	shot = null

func release():
	dim_a = 0.0
	_end()

# a clean picture of what the player sees right now
func grab():
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	if img != null and not img.is_empty():
		img.convert(Image.FORMAT_RGB8)
	return img

# the words of the page (the original's four beats, ours in the detail). Rects and tails are fractions of the panel.
const W2A = "WHERE DO YOU THINK WE'RE HEADED?"
const W2B = "I WAS GOING TO GO GET SOME FRIES. DOWN AT THE PIER."
const W3 = "NO. BIG PICTURE. I'VE GOT THE CHAIN, THE HAT, THE COAT. I'VE GOT EVERYTHING. SO WHERE DOES IT END?"
const W4 = "I STILL FEEL LIKE IT HAS SOMETHING TO DO WITH THOSE FRIES ON THE PIER."
const R2A = Rect2(0.03, 0.03, 0.47, 0.27)
const R2B = Rect2(0.5, 0.02, 0.48, 0.34)
const R3 = Rect2(0.04, 0.03, 0.92, 0.46)
const R4 = Rect2(0.03, 0.03, 0.94, 0.42)

# ------------------------------------------------------------------ THE BEGINNING
func play_comic_open():
	_prep(null)
	for i in 4:
		tex[i] = _load("o%d" % (i + 1))
	_tw("paper_a", 1.0, 0.9)
	await _wait(0.7)
	# 1: two gulls on a roof, looking at the sea. Nobody says anything.
	await _ink(0, 0.9)
	await _wait(1.8)
	# 2: where do you think we're headed?
	await _ink(1, 0.8)
	var b1 = _bubble_def(1, W2A, R2A, Vector2(0.33, 0.40))
	var b2 = _bubble_def(1, W2B, R2B, Vector2(0.82, 0.47))
	await _say(b1, 0.7)
	await _say(b2, 1.0)
	# 3: big picture
	await _ink(2, 0.8)
	var b3 = _bubble_def(2, W3, R3, Vector2(0.34, 0.60))
	await _say(b3, 1.3)
	# 4: the little gull, deadpan
	await _ink(3, 0.8)
	await _wait(0.8)
	var b4 = _bubble_def(3, W4, R4, Vector2(0.62, 0.56))
	await _say(b4, 1.9)
	# the last panel opens up and the page lets go: the game is what happens next
	zoom_slot = 3
	_tw("strip_a", 0.0, 0.7)
	var t3 = _tw("zoom_k", 1.0, 1.2)
	await t3.finished
	await _tw("paper_a", 0.0, 0.8).finished
	_end()

# ------------------------------------------------------------------ THE END
func play_ending(shot_image):
	_prep(shot_image)
	for i in 3:
		tex[i] = _load("o%d" % (i + 1))
	tex[3] = _load("p4")
	shot_slot = 3
	frame_a[3] = 1.0
	# the old words of panels 2 and 3 are there from the start, but invisible until the panels are inked in
	var e1 = _bubble_def(1, W2A, R2A, Vector2(0.33, 0.40), true)
	var e2 = _bubble_def(1, W2B, R2B, Vector2(0.82, 0.47), true)
	var e3 = _bubble_def(2, W3, R3, Vector2(0.34, 0.60), true)
	for b in [e1, e2, e3]:
		b["typed"] = float(b["text"].length())
	# 1: the last picture of the game shrinks into the fourth slot of the page
	_tw("paper_a", 1.0, 1.0)
	var t1 = _tw("shot_k", 1.0, 1.3, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	await t1.finished
	await _wait(0.5)
	# 2: the question comes back: the first three panels are inked in and their old words come up faintly, like something remembered
	for i in 3:
		await _ink(i, 0.7)
	echo_a = 0.55
	for b in [e1, e2, e3]:
		b["a"] = 1.0
	await _wait(1.8)
	# 3: and the fourth is inked over the live picture. The answer is in the picture.
	pen_slot = 3
	pen = 0.0
	reveal[3] = 1.0
	Sfx.play("vn_pop", -10.0, 1.5)
	var t2 = _tw("ink_over", 1.0, 1.6, Tween.TRANS_QUAD, Tween.EASE_OUT)
	await t2.finished
	pen = -1.0
	await _wait(0.6)
	var a1 = _bubble_def(3, "...SAME.", Rect2(0.03, 0.04, 0.34, 0.2), Vector2(0.34, 0.5))
	var a2 = _bubble_def(3, "IT DID. IT HAD SOMETHING TO DO WITH THE FRIES.", Rect2(0.42, 0.04, 0.55, 0.3), Vector2(0.62, 0.52))
	await _say(a1, 0.8)
	await _say(a2, 2.2)
	# 4: the last panel opens up and fills the page; then black, and the credits
	zoom_slot = 3
	_tw("strip_a", 0.0, 1.0)
	var t3 = _tw("zoom_k", 1.0, 1.6)
	await t3.finished
	await _wait(1.4)
	await _tw("dim_a", 1.0, 1.3).finished        # (release() lets go of the layer)
