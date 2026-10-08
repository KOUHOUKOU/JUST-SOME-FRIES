extends CanvasLayer
# STORY (round 7): the COMIC-PAGE look of the opening and the ending.
# The 3D world is the artwork. This layer frames it like a comic panel (paper margin, thick ink border, halftone shading in the corners), puts the
# narrator in yellow caption boxes, the characters in real speech balloons with tails (that follow the head of whoever is talking and never sit on the face),
# adds the sound-effect lettering ("CLINK", "JUST", "SOME", "FRIES"), impact lines, flashes and a diagonal shutter wipe between panels.
# Pacing: a sentence is typed out; ANY key finishes the sentence that is being typed, and a second press goes on to the next one. Nothing is ever skipped
# in one go, and nothing tells the player that they could. Without a key the sentences move on by themselves after a reading time that fits their length.
#   await say("BIG BRO", "I got the chain.", func(): return head_pos, "right")
#   await caption("THIS IS AN AGE OF MAGIC.")
#   sfx("CLINK", 0.7, 0.35)     slam("JUST", ...)     await cut(func(): ...)     await hold_to("TO FLY")
# ROUND 8: the visual-novel box (say_vn: a name plate, a LIVE 3D PORTRAIT of whoever is speaking, a typed line and a blinking arrow) and the film mode
# (bars_in / narrate / set_tag: letterbox bars, the gull's own thoughts typed under the picture, a small chapter tag) used by the cinematic moments.

const INK = Color(0.05, 0.04, 0.07)
const PAPER = Color("F3EAD3")
const CAP_FILL = Color("F8E9A6")
const GOLD = Color("F5C65A")

class Page extends Control:
	var st
	func _draw():
		st.draw_page(self)

var page
var player = null
var active = false
var font
var bold
var frame = 0.0               # 0 = no frame, 1 = framed panel
var shake = 0.0
var flash = 0.0
var flash_col = Color.WHITE
var shutter = -1.0            # -1 = off; 0..1 covers the screen, 1..2 uncovers it
var dim = 0.0                 # black overlay
var cap = null                # the narrator's caption box
var bal = null                # the speech balloon being shown
var sfx_items = []            # sound-effect words
var words = []                # the big slammed words (they stay until cleared)
var bursts = []               # impact lines
var poster_tex = null
var poster_a = 0.0
var poster_t0 = 0.0
var hold = {"on": false, "p": 0.0, "label": ""}
var last_press = 0
var cam = null
var halftone = null
var typing_blip = 0
var hush = false
var art_tex = null            # an optional illustration for the panel (assets/ui/story/<id>.png): when it exists it replaces the 3D picture
var art_t0 = 0
var art_id = ""
var cam_roll = 0.0            # the picture leans (a wobbly cocktail)
var bars = 0.0                # film mode: 0 = none, 1 = full letterbox bars
var light = false             # round 10: a BEAT (a short comic moment while the gull keeps flying): only the lettering, the burst and the caption are drawn; nothing is locked or swallowed
var cards = []                # the memory polaroids of the ending
var narr = null               # the gull's thought, typed under the picture in film mode
var tag = null                # a small chapter tag in the upper bar
var vn = null                 # the visual-novel box being shown
var pvp = null                # the portrait viewport (it shares the 3D world, its camera looks at the speaker's face)
var pcam = null
var pback = null               # a soft coloured backdrop behind the speaker (on layer 20: only the portrait camera sees it)
var pback_mat = null
var pset = {"dist": 1.0, "yaw": 0.45, "up": 0.03, "fov": 30.0, "roll": 0.0}

func _ready():
	layer = 38
	process_mode = Node.PROCESS_MODE_ALWAYS
	page = Page.new()
	page.st = self
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(page)
	font = ThemeDB.fallback_font
	var fv = FontVariation.new()
	fv.base_font = ThemeDB.fallback_font
	fv.variation_embolden = 1.1
	bold = fv
	if ResourceLoader.exists("res://assets/ui/cover.jpg"):
		poster_tex = load("res://assets/ui/cover.jpg")
	_make_halftone()
	_make_portrait()
	visible = false

func _make_portrait():
	pvp = SubViewport.new()
	pvp.size = Vector2i(320, 320)
	pvp.transparent_bg = false
	pvp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	pvp.audio_listener_enable_3d = false
	pvp.handle_input_locally = false
	add_child(pvp)
	pcam = Camera3D.new()
	pcam.fov = 30.0
	pvp.add_child(pcam)
	pcam.current = true
	pcam.cull_mask = 0xFFFFF
	var g = Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(0.55, 0.55, 0.6, 1))
	var gt = GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.45)
	gt.fill_to = Vector2(1.0, 0.95)
	gt.width = 128
	gt.height = 128
	pback = MeshInstance3D.new()
	var qm = QuadMesh.new()
	qm.size = Vector2(5.0, 5.0)
	pback.mesh = qm
	pback_mat = StandardMaterial3D.new()
	pback_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pback_mat.albedo_texture = gt
	pback_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	pback.material_override = pback_mat
	pback.layers = 1 << 19
	pback.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pback.visible = false

func _make_halftone():
	var n = 192
	var img = Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var cx = (x / 8) * 8 + 4
			var cy = (y / 8) * 8 + 4
			var d = Vector2(cx, cy).length() / float(n)
			var r = (1.0 - d) * 4.4
			var inside = Vector2(x - cx + 0.5, y - cy + 0.5).length() < r
			img.set_pixel(x, y, Color(0, 0, 0, 0.5 if inside else 0.0))
	halftone = ImageTexture.create_from_image(img)

func _input(event):
	if not active:
		return
	var press = (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed)
	if press:
		last_press = GS.msec()
		get_viewport().set_input_as_handled()

# ------------------------------------------------------------------ switching the story layer on and off
func begin(p):
	player = p
	if p != null:
		p.cam.cull_mask = 0xFFFFF & ~(1 << 19)
		p.cine_cam.cull_mask = 0xFFFFF & ~(1 << 19)
	if pback != null and pback.get_parent() == null:
		get_tree().current_scene.add_child(pback)
	active = true
	visible = true
	GS.showcase_active = true
	cap = null
	bal = null
	sfx_items = []
	words = []
	bursts = []
	dim = 0.0
	flash = 0.0
	shutter = -1.0
	hold = {"on": false, "p": 0.0, "label": ""}
	bars = 0.0
	cam_roll = 0.0
	cards = []
	narr = null
	tag = null
	vn = null

func finish():
	active = false
	cam = null
	frame = 0.0
	visible = false
	cap = null
	bal = null
	words = []
	sfx_items = []
	poster_a = 0.0
	bars = 0.0
	cards = []
	narr = null
	tag = null
	vn = null
	pvp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	GS.showcase_active = false

func tween_prop(prop, to, sec):
	var tw = create_tween().set_ignore_time_scale(true)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(self, prop, to, sec).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return tw

func frame_in(sec = 0.5):
	var tw = tween_prop("frame", 1.0, sec)
	await tw.finished

func frame_out(sec = 0.6):
	var tw = tween_prop("frame", 0.0, sec)
	await tw.finished

# a panel can be drawn by hand instead: drop assets/ui/story/<id>.png in the project (see docs/27_STORY_ART_PROMPTS.md). Without the file nothing changes.
func set_art(id):
	art_id = id
	art_tex = null
	if id != "" and ResourceLoader.exists("res://assets/ui/story/%s.png" % id):
		art_tex = load("res://assets/ui/story/%s.png" % id)
		art_t0 = GS.msec()

# ------------------------------------------------------------------ the camera: a start pose, an optional end pose, a duration; always a little handheld
func cam_set(pos, look, fov, to_pos = null, to_look = null, to_fov = -1.0, dur = 6.0, bob = 0.012):
	cam = {"p0": pos, "l0": look, "f0": fov, "p1": to_pos if to_pos != null else pos, "l1": to_look if to_look != null else look,
		"f1": to_fov if to_fov > 0.0 else fov, "t0": GS.msec(), "dur": dur, "bob": bob}

func _cam_tick():
	if cam == null or player == null:
		return
	var u = clamp((GS.msec() - cam["t0"]) / 1000.0 / max(cam["dur"], 0.01), 0.0, 1.0)
	var e = u * u * (3.0 - 2.0 * u)
	var t = GS.msec() * 0.001
	var pos = cam["p0"].lerp(cam["p1"], e)
	var look = cam["l0"].lerp(cam["l1"], e)
	var b = cam["bob"]
	pos += Vector3(sin(t * 0.9) * b, sin(t * 1.3) * b * 0.8, cos(t * 0.7) * b)
	if shake > 0.01:
		pos += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * shake * 0.08
	var xf = Transform3D(Basis.IDENTITY, pos).looking_at(look, Vector3.UP)
	if abs(cam_roll) > 0.0005:
		xf.basis = xf.basis.rotated(xf.basis.z.normalized(), cam_roll)
	player.set_override(xf, lerp(cam["f0"], cam["f1"], e), 1.0, 40.0)

func _process(delta):
	if not active and not light:
		return
	var dt = delta / max(Engine.time_scale, 0.05)
	shake = move_toward(shake, 0.0, 2.2 * dt)
	flash = move_toward(flash, 0.0, 3.0 * dt)
	if active:
		_cam_tick()
		_portrait_tick()
	page.queue_redraw()

# ------------------------------------------------------------------ words, balloons, captions
func _wait_press(p0, min_sec, auto_sec):
	var t1 = GS.msec()
	while true:
		await get_tree().process_frame
		var el = (GS.msec() - t1) / 1000.0
		if el >= auto_sec:
			return
		if last_press > p0 and el > min_sec:
			return

func wait(sec):
	var t0 = GS.msec()
	while GS.msec() - t0 < sec * 1000.0:
		await get_tree().process_frame

# a sentence that is typed out. A press finishes the typing; the next press (or the reading time) goes on.
func _speak(d, text, voice_pitch, hold = -1.0, cps = 34.0):
	var n = text.length()
	var t0 = GS.msec()
	var p0 = last_press
	d["shown"] = 0
	var last_n = 0
	while d["shown"] < n:
		var k = int((GS.msec() - t0) / 1000.0 * cps) + 1
		d["shown"] = min(k, n)
		if d["shown"] > last_n and (d["shown"] % 2 == 0) and text[d["shown"] - 1] != " ":
			Sfx.play("blip", -24.0, voice_pitch * randf_range(0.93, 1.07))
		last_n = d["shown"]
		if last_press > p0:
			d["shown"] = n
			p0 = last_press
			break
		await get_tree().process_frame
	d["shown"] = n
	var auto = clamp(1.0 + n * 0.06, 1.9, 7.0) if hold < 0.0 else hold
	await _wait_press(p0, 0.3, auto)

func say(who, text, anchor_fn, side = "right", style = "speech", voice_pitch = 1.0):
	bal = {"who": who, "text": text, "anchor": anchor_fn, "side": side, "style": style, "shown": 0, "a": 0.0, "t0": GS.msec(), "closing": false}
	var d = bal
	var tw = create_tween().set_ignore_time_scale(true)
	tw.tween_method(func(v): d["a"] = v, 0.0, 1.0, 0.16)
	await _speak(d, text, voice_pitch)
	d["closing"] = true
	var tw2 = create_tween().set_ignore_time_scale(true)
	tw2.tween_method(func(v): d["a"] = v, 1.0, 0.0, 0.14)
	await tw2.finished
	if bal == d:
		bal = null

func caption(text, hold = -1.0, cps = 34.0):
	cap = {"text": text, "shown": 0, "a": 0.0, "t0": GS.msec()}
	var d = cap
	var tw = create_tween().set_ignore_time_scale(true)
	tw.tween_method(func(v): d["a"] = v, 0.0, 1.0, 0.18)
	await _speak(d, text, 0.7, hold, cps)
	var tw2 = create_tween().set_ignore_time_scale(true)
	tw2.tween_method(func(v): d["a"] = v, 1.0, 0.0, 0.2)
	await tw2.finished
	if cap == d:
		cap = null

# ------------------------------------------------------------------ the visual-novel box
# say_vn("BIG BRO", "gull of many accessories", "I got the chain.", Callable(self, "_bro_gull"), 0.6, GOLD)
#   head_fn returns the GullVisual of the speaker; its face is shown live in the portrait frame.
func say_vn(who, sub, text, head_fn, voice_pitch = 1.0, tint = GOLD, look = {}):
	var fresh = vn == null
	if fresh:
		vn = {"a": 0.0, "who": "", "sub": "", "text": "", "shown": 0, "head": null, "tint": tint, "pop": 0, "look": {}, "closing": false}
		pvp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		var tw = create_tween().set_ignore_time_scale(true)
		var dd = vn
		tw.tween_method(func(v): dd["a"] = v, 0.0, 1.0, 0.22)
	var d = vn
	d["closing"] = false
	if d["who"] != who:
		d["pop"] = GS.msec()
		Sfx.play("vn_pop", -13.0, 0.9 if who == "YOU" else 1.0)
	d["who"] = who
	d["sub"] = sub
	d["text"] = text
	d["head"] = head_fn
	d["tint"] = tint
	d["look"] = look
	d["shown"] = 0
	await _speak(d, text, voice_pitch)
	Sfx.play("vn_next", -16.0)

func vn_end(sec = 0.2):
	if vn == null:
		return
	var d = vn
	d["closing"] = true
	var tw = create_tween().set_ignore_time_scale(true)
	tw.tween_method(func(v): d["a"] = v, d["a"], 0.0, sec)
	await tw.finished
	if vn == d:
		vn = null
		pvp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		if pback != null:
			pback.visible = false

func _portrait_tick():
	if vn == null or pcam == null:
		return
	var fn = vn["head"]
	if fn == null:
		return
	var g = fn.call()
	if g == null or not is_instance_valid(g) or g.head == null:
		return
	var look = vn["look"]
	var hp = g.head.global_position
	var gb = g.global_transform.basis
	var sc = gb.get_scale().x
	var fwd = -gb.z.normalized()
	var up = gb.y.normalized()
	var yaw = look.get("yaw", pset["yaw"])
	var t = GS.msec() * 0.001
	var talking = vn["shown"] < vn["text"].length()
	var bob = (sin(t * 11.0) * 0.012 if talking else sin(t * 1.7) * 0.004)
	var dir = fwd.rotated(up, yaw)
	if look.has("avoid"):
		# the camera looks at the face from the side, away from whoever it is talking to (so that nobody's hat is in the way)
		var da = fwd.rotated(up, 0.95)
		var db = fwd.rotated(up, -0.95)
		var mc = get_viewport().get_camera_3d()
		var to_main = (mc.global_position - hp).normalized() if mc != null else Vector3.ZERO
		dir = da if da.dot(to_main) >= db.dot(to_main) else db
	var dist = look.get("dist", pset["dist"]) * sc
	var tgt = hp + up * (look.get("up", pset["up"]) * sc + bob * sc)
	pcam.global_position = hp + dir * dist + up * (0.05 * sc)
	pcam.look_at(tgt, up)
	pcam.rotate_object_local(Vector3(0, 0, 1), look.get("roll", pset["roll"]) + (sin(t * 7.0) * 0.02 if talking else 0.0))
	pcam.fov = look.get("fov", pset["fov"])
	if pback != null and pback.get_parent() != null:
		pback.visible = true
		var away = (hp - pcam.global_position).normalized()
		pback.global_position = hp + away * (0.9 * sc) + up * (0.02 * sc)
		pback.look_at(pcam.global_position, up)
		pback.scale = Vector3.ONE * sc
		var tn = vn["tint"]
		pback_mat.albedo_color = Color(tn.r, tn.g, tn.b, 1.0).lerp(Color(1, 1, 1, 1), 0.25)

# a sound-effect word at a place of the panel (nx, ny in 0..1)
func sfx(text, nx, ny, rot = -6.0, col = GOLD, sz = 58.0, life = 1.2):
	sfx_items.append({"text": text, "pos": Vector2(nx, ny), "rot": rot, "col": col, "size": sz, "t0": GS.msec(), "life": life})

# a big word that is slammed onto the page and stays (JUST / SOME / FRIES)
func slam(text, nx, ny, sz = 150.0, col = Color("FFF3D0"), rot = -4.0, shake_amt = 0.6, burst = true, key = ""):
	var w = {"text": text, "pos": Vector2(nx, ny), "size": sz, "col": col, "rot": rot, "t0": GS.msec(), "a": 1.0, "key": key if key != "" else text}
	words.append(w)
	shake = max(shake, shake_amt)
	flash = max(flash, 0.35 if burst else 0.0)
	flash_col = Color(1, 0.97, 0.85)
	if burst:
		bursts.append({"pos": Vector2(nx, ny), "t0": GS.msec(), "life": 0.6})
	return w

func clear_words(sec = 0.5):
	var tw = create_tween().set_ignore_time_scale(true)
	for w in words:
		var ww = w
		tw.parallel().tween_method(func(v): ww["a"] = v, 1.0, 0.0, sec)
	await get_tree().create_timer(sec, true, false, true).timeout
	words = []

func burst_at(nx, ny):
	bursts.append({"pos": Vector2(nx, ny), "t0": GS.msec(), "life": 0.6})

# ------------------------------------------------------------------ BEATS (round 10): the short comic moments, 4-8 s, the gull keeps flying
# A beat is a few panels' worth of comic rhythm laid over the game as it is: a splash of the thing's colour, ONE big hand-lettered word that slams in with impact
# lines, then the gull's thoughts in a yellow caption box (a line at a time, typed fast). Nothing is locked, slowed or hidden but the interface.
#   await st.beat("BZZZT!", Color("E8B27A"), ["coffee. my heart just learned drums."], {"rot": -7})
func beat_begin():
	light = true
	visible = true
	cap = null
	sfx_items = []
	words = []
	bursts = []
	flash = 0.0
	cards = []

func beat_end():
	light = false
	if not active:
		visible = false
	cap = null
	words = []
	sfx_items = []
	bursts = []

func beat(word, col, lines, o = {}):
	if active:
		return
	beat_begin()
	var life = o.get("life", 1.7)
	var rot = o.get("rot", -6.0)
	var pos = o.get("pos", Vector2(0.62, 0.36))
	var wsz = o.get("size", 118.0)
	# the word: a hit (impact lines, a flash of the thing's colour, a little shake), then it fades while the thoughts go on
	flash_col = col.lerp(Color.WHITE, 0.55)
	var w = slam(word, pos.x, pos.y, wsz, Color.WHITE.lerp(col, 0.15), rot, o.get("shake", 0.5), true, "beat")
	w["star"] = col.lightened(0.15)
	Sfx.play(o.get("sfx", "vn_pop"), -8.0, o.get("pitch", 0.9))
	for e in o.get("extra", []):
		# small extra words round the big one: sfx(text, nx, ny, rot, col, size, life)
		sfx(e[0], e[1], e[2], e[3], e[4], e[5], e[6])
	get_tree().create_timer(life, true, false, true).timeout.connect(func():
		if is_instance_valid(self) and light:
			var tw = create_tween().set_ignore_time_scale(true)
			tw.tween_method(func(v): w["a"] = v, 1.0, 0.0, 0.35)
			tw.tween_callback(func(): words.erase(w)))
	await wait(0.35)
	var k = 0
	for l in lines:
		await caption(l, o.get("hold", 1.15) if k < lines.size() - 1 else o.get("hold_last", 1.5), o.get("cps", 46.0))
		k += 1
	await wait(0.15)
	beat_end()

# ------------------------------------------------------------------ film mode (the cinematic moments)
func bars_in(sec = 0.9):
	Sfx.play("cine_in", -10.0)
	var tw = tween_prop("bars", 1.0, sec)
	await tw.finished

func bars_out(sec = 0.8):
	Sfx.play("cine_out", -12.0)
	var tw = tween_prop("bars", 0.0, sec)
	await tw.finished

# the gull's own thought, typed under the picture. A press finishes the sentence; the next one goes on (or the reading time runs out).
func narrate(text, tint = Color(1.0, 0.97, 0.88), pitch = 1.5, hold = -1.0, cps = 34.0):
	narr = {"text": text, "shown": 0, "a": 0.0, "t0": GS.msec(), "tint": tint}
	var d = narr
	var tw = create_tween().set_ignore_time_scale(true)
	tw.tween_method(func(v): d["a"] = v, 0.0, 1.0, 0.2)
	await _speak(d, text, pitch, clamp(0.55 + text.length() * 0.035, 1.3, 4.2) if hold < 0.0 else hold, cps)
	var tw2 = create_tween().set_ignore_time_scale(true)
	tw2.tween_method(func(v): d["a"] = v, 1.0, 0.0, 0.2)
	await tw2.finished
	if narr == d:
		narr = null

# a small chapter tag in the upper bar
func set_tag(text, sec = 3.2):
	var d = {"text": text, "t0": GS.msec(), "life": sec}
	tag = d
	get_tree().create_timer(sec + 0.1, true, false, true).timeout.connect(func():
		if tag == d:
			tag = null)

# the diagonal shutter: it sweeps over the page, `mid` runs while the page is covered, then it sweeps off again
func cut(mid = Callable(), sec = 0.36):
	var tw = create_tween().set_ignore_time_scale(true)
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	shutter = 0.0
	tw.tween_property(self, "shutter", 1.0, sec * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	Sfx.play("whoosh", -14.0, 1.5)
	if mid.is_valid():
		mid.call()
	await get_tree().process_frame
	var tw2 = create_tween().set_ignore_time_scale(true)
	tw2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw2.tween_property(self, "shutter", 2.0, sec * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw2.finished
	shutter = -1.0

func fade_black(to, sec):
	var tw = tween_prop("dim", to, sec)
	await tw.finished

func show_poster(on, sec = 1.6):
	if on:
		poster_t0 = GS.msec()
	var tw = tween_prop("poster_a", 1.0 if on else 0.0, sec)
	await tw.finished

# "hold E to ...": a little key with a ring that fills while the key is held; nothing happens on a stray tap
func hold_to(label, secs = 0.9):
	hold = {"on": true, "p": 0.0, "label": label}
	var tick = 0
	while hold["p"] < 1.0:
		await get_tree().process_frame
		var dt = get_process_delta_time()
		if Input.is_action_pressed("interact"):
			hold["p"] = min(hold["p"] + dt / secs, 1.0)
			if int(hold["p"] * 8.0) > tick:
				tick = int(hold["p"] * 8.0)
				Sfx.play("blip", -20.0, 0.8 + 0.12 * tick)
		else:
			hold["p"] = max(hold["p"] - dt * 2.4, 0.0)
			tick = int(hold["p"] * 8.0)
	hold["on"] = false
	flash = 0.6
	flash_col = Color(1, 0.95, 0.8)
	Sfx.play("land", -8.0, 1.6)

# ------------------------------------------------------------------ drawing
func inner_rect(ci):
	var u = ci.size.y / 720.0
	var e = frame * frame * (3.0 - 2.0 * frame)
	var m = Vector2(34.0, 28.0) * u * e
	return Rect2(m, ci.size - m * 2.0)

func _wrap(text, f, fs, maxw):
	var out = []
	for para in text.split("\n"):
		var cur = ""
		for w in para.split(" "):
			var test = w if cur == "" else cur + " " + w
			if cur != "" and f.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > maxw:
				out.append(cur)
				cur = w
			else:
				cur = test
		out.append(cur)
	return out

func _stroke_text(ci, f, pos, text, fs, col, outline, ink = INK, width = -1.0):
	ci.draw_string_outline(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, fs, int(outline), ink)
	ci.draw_string(f, pos, text, HORIZONTAL_ALIGNMENT_LEFT, width, fs, col)

# one big comic word: an extruded block of colour, an ink outline, a white sheen
func _lettering(ci, text, centre, fs, col, rot_deg, a, pop):
	var u = ci.size.y / 720.0
	var sz = int(fs * u * pop)
	var w = bold.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
	ci.draw_set_transform(centre, deg_to_rad(rot_deg), Vector2.ONE)
	var base = Vector2(-w * 0.5, sz * 0.34)
	var depth = int(max(sz * 0.07, 4.0))
	for k in range(depth, 0, -1):
		ci.draw_string_outline(bold, base + Vector2(k, k) * 1.1, text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, int(sz * 0.12), Color(INK.r, INK.g, INK.b, a))
	ci.draw_string_outline(bold, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, int(sz * 0.12), Color(INK.r, INK.g, INK.b, a))
	for k in range(depth, 0, -1):
		ci.draw_string(bold, base + Vector2(k, k) * 1.1, text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(col.r * 0.55, col.g * 0.5, col.b * 0.45, a))
	ci.draw_string(bold, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(col.r, col.g, col.b, a))
	ci.draw_string(bold, base + Vector2(-sz * 0.015, -sz * 0.025), text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, Color(1, 1, 1, 0.22 * a))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _starburst(ci, c, r, spikes, col, a, rot = 0.0, jag = 0.62):
	var pts = PackedVector2Array()
	for i in spikes * 2:
		var ang = rot + PI * i / spikes
		var rr = r if i % 2 == 0 else r * jag
		pts.append(c + Vector2(cos(ang), sin(ang)) * rr)
	ci.draw_colored_polygon(pts, Color(col.r, col.g, col.b, a))

func _balloon(ci, R, u):
	var b = bal
	if b == null or b["a"] <= 0.01:
		return
	var cam3 = get_viewport().get_camera_3d()
	var anchor_screen = Vector2(R.position.x + R.size.x * 0.5, R.position.y + R.size.y * 0.6)
	var has_anchor = false
	if cam3 != null and b["anchor"] != null:
		var wp = b["anchor"].call()
		if not cam3.is_position_behind(wp):
			anchor_screen = cam3.unproject_position(wp)
			has_anchor = true
	var style = b["style"]
	var fs = int((32.0 if style == "shout" else 25.0) * u)
	var f = bold if style == "shout" else font
	var maxw = (330.0 if style != "shout" else 380.0) * u
	var lines = _wrap(b["text"], f, fs, maxw)
	var lw = 0.0
	for l in lines:
		lw = max(lw, f.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var lh = fs * 1.22
	var padx = 26.0 * u
	var pady = 16.0 * u
	var size_ = Vector2(lw + padx * 2.0, lines.size() * lh + pady * 2.0 + (14.0 * u if b["who"] != "" else 0.0))
	var side = b["side"]
	var off = Vector2(0, -(size_.y * 0.5 + 70.0 * u))
	if side == "left":
		off = Vector2(-(size_.x * 0.5 + 30.0 * u), -(size_.y * 0.5 + 56.0 * u))
	elif side == "right":
		off = Vector2(size_.x * 0.5 + 30.0 * u, -(size_.y * 0.5 + 56.0 * u))
	var centre = anchor_screen + off
	var lim = 26.0 * u
	centre.x = clamp(centre.x, R.position.x + lim + size_.x * 0.5, R.end.x - lim - size_.x * 0.5)
	centre.y = clamp(centre.y, R.position.y + lim + size_.y * 0.5, R.end.y - lim - size_.y * 0.5)
	var pop = 1.0 + 0.12 * (1.0 - clamp((GS.msec() - b["t0"]) / 260.0, 0.0, 1.0))
	var rect = Rect2(centre - size_ * 0.5 * pop, size_ * pop)
	var a = b["a"]
	var ink = Color(INK.r, INK.g, INK.b, a)
	var white = Color(1, 0.99, 0.96, a)
	# the tail points at the speaker (never over the face: the tip stops a little above the head)
	var tip = anchor_screen + Vector2(0, -18.0 * u)
	var from_x = clamp(tip.x, rect.position.x + rect.size.x * 0.2, rect.end.x - rect.size.x * 0.2)
	var base_y = rect.end.y - 2.0
	if style == "thought":
		for i in 3:
			var k = (i + 1) / 4.0
			var cpos = Vector2(from_x, base_y + 8.0 * u).lerp(tip, k)
			var rr = (13.0 - i * 3.2) * u
			ci.draw_circle(cpos, rr + 3.0, ink)
			ci.draw_circle(cpos, rr, white)
		var nb = max(int(rect.size.x / (30.0 * u)), 4)
		for i in nb:
			var xx = rect.position.x + (i + 0.5) * rect.size.x / nb
			for yy in [rect.position.y, rect.end.y]:
				ci.draw_circle(Vector2(xx, yy), 13.0 * u + 3.0, ink)
		var sb0 = StyleBoxFlat.new()
		sb0.bg_color = ink
		sb0.set_corner_radius_all(int(rect.size.y * 0.5))
		ci.draw_style_box(sb0, Rect2(rect.position - Vector2(3, 3), rect.size + Vector2(6, 6)))
		for i in nb:
			var xx2 = rect.position.x + (i + 0.5) * rect.size.x / nb
			for yy2 in [rect.position.y, rect.end.y]:
				ci.draw_circle(Vector2(xx2, yy2), 13.0 * u, white)
		var sb1 = StyleBoxFlat.new()
		sb1.bg_color = white
		sb1.set_corner_radius_all(int(rect.size.y * 0.5))
		ci.draw_style_box(sb1, rect)
	elif style == "shout":
		var rr2 = max(rect.size.x, rect.size.y) * 0.62
		_starburst(ci, rect.get_center(), rr2 + 8.0 * u, 14, ink, a, 0.2, 0.7)
		_starburst(ci, rect.get_center(), rr2, 14, Color(1.0, 0.93, 0.5, a), a, 0.2, 0.7)
	else:
		var tail = PackedVector2Array([Vector2(from_x - 18.0 * u, base_y - 6.0 * u), Vector2(from_x + 22.0 * u, base_y - 6.0 * u), tip])
		var tail_o = PackedVector2Array([Vector2(from_x - 22.0 * u, base_y - 6.0 * u), Vector2(from_x + 26.0 * u, base_y - 6.0 * u), tip + Vector2(0, 5.0 * u)])
		ci.draw_colored_polygon(tail_o, ink)
		var sb = StyleBoxFlat.new()
		sb.bg_color = white
		sb.border_color = ink
		sb.set_border_width_all(int(4.0 * u))
		sb.set_corner_radius_all(int(min(rect.size.y * 0.42, 34.0 * u)))
		sb.anti_aliasing = true
		ci.draw_style_box(sb, rect)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(from_x - 15.0 * u, base_y - 9.0 * u), Vector2(from_x + 19.0 * u, base_y - 9.0 * u), tip + Vector2(0, -2.0 * u)]), white)
	# the words
	var ty = rect.position.y + pady + fs * 0.9
	if b["who"] != "":
		ci.draw_string(bold, Vector2(rect.position.x + padx, ty - 6.0 * u), b["who"], HORIZONTAL_ALIGNMENT_LEFT, -1, int(12 * u), Color(0.55, 0.32, 0.1, a))
		ty += 14.0 * u
	var left = b["shown"]
	for l in lines:
		if left <= 0:
			break
		var part = l.substr(0, left)
		left -= l.length() + 1
		var tx = rect.position.x + padx
		if style == "shout":
			tx = rect.get_center().x - f.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x * 0.5
		ci.draw_string(f, Vector2(tx, ty), part, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(INK.r, INK.g, INK.b, a))
		ty += lh

func _caption(ci, R, u):
	var c = cap
	if c == null or c["a"] <= 0.01:
		return
	var big = light          # a beat's caption is bigger and sits at the lower left, close to the action
	var fs = int((27.0 if big else 19.0) * u)
	var maxw = min(R.size.x * (0.62 if big else 0.55), (700.0 if big else 520.0) * u)
	var lines = _wrap(c["text"], bold, fs, maxw)
	var lw = 0.0
	for l in lines:
		lw = max(lw, bold.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
	var lh = fs * 1.25
	var sz = Vector2(lw + 36.0 * u, lines.size() * lh + 24.0 * u)
	var slide = (1.0 - c["a"]) * -26.0 * u
	var rect = Rect2(R.position + Vector2(22.0 * u + slide, 20.0 * u), sz)
	if big:
		rect = Rect2(Vector2(R.position.x + 34.0 * u + slide, R.end.y - sz.y - 44.0 * u), sz)
	var a = c["a"]
	ci.draw_rect(Rect2(rect.position + Vector2(6, 6) * u, rect.size), Color(INK.r, INK.g, INK.b, 0.85 * a))
	ci.draw_rect(rect, Color(CAP_FILL.r, CAP_FILL.g, CAP_FILL.b, a))
	ci.draw_rect(rect, Color(INK.r, INK.g, INK.b, a), false, 3.0 * u)
	var left = c["shown"]
	var ty = rect.position.y + 12.0 * u + fs * 0.92
	for l in lines:
		if left <= 0:
			break
		ci.draw_string(bold, Vector2(rect.position.x + 18.0 * u, ty), l.substr(0, left), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(INK.r, INK.g, INK.b, a))
		left -= l.length() + 1
		ty += lh

# the visual-novel box: a live portrait, a name plate, the typed line, a blinking arrow
func _vn(ci, R, u):
	var v = vn
	if v == null or v["a"] <= 0.01:
		return
	var a = v["a"]
	var tint = v["tint"]
	var slide = (1.0 - a) * 46.0 * u
	var bh = 152.0 * u
	var bx0 = R.position.x + 30.0 * u
	var bx1 = R.end.x - 30.0 * u
	var by1 = R.end.y - 24.0 * u + slide
	var by0 = by1 - bh
	var box = Rect2(bx0, by0, bx1 - bx0, bh)
	var ink = Color(INK.r, INK.g, INK.b, a)
	var gold = Color(0.96, 0.78, 0.36, a)
	var cream = Color(1.0, 0.97, 0.88, a)
	# the box
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.06, 0.13, 0.9 * a)
	sb.border_color = gold
	sb.set_border_width_all(int(max(3.0 * u, 2.0)))
	sb.set_corner_radius_all(int(16.0 * u))
	sb.anti_aliasing = true
	sb.shadow_color = Color(0, 0, 0, 0.45 * a)
	sb.shadow_size = int(10.0 * u)
	ci.draw_style_box(sb, box)
	var inner = StyleBoxFlat.new()
	inner.bg_color = Color(0, 0, 0, 0)
	inner.border_color = Color(1, 0.95, 0.8, 0.28 * a)
	inner.set_border_width_all(1)
	inner.set_corner_radius_all(int(11.0 * u))
	inner.anti_aliasing = true
	ci.draw_style_box(inner, Rect2(box.position + Vector2(6, 6) * u, box.size - Vector2(12, 12) * u))
	# the portrait frame (it pops when the speaker changes)
	var pk = clamp((GS.msec() - v["pop"]) / 220.0, 0.0, 1.0)
	var psz = 176.0 * u * (1.0 + 0.13 * (1.0 - pk) * (1.0 - pk))
	var pc = Vector2(bx0 + 20.0 * u + 88.0 * u, by1 - 10.0 * u - 88.0 * u)
	var prect = Rect2(pc - Vector2(psz, psz) * 0.5, Vector2(psz, psz))
	ci.draw_set_transform(pc, deg_to_rad(-2.0), Vector2.ONE)
	var prel = Rect2(-Vector2(psz, psz) * 0.5, Vector2(psz, psz))
	ci.draw_rect(Rect2(prel.position + Vector2(6, 6) * u, prel.size), Color(0, 0, 0, 0.5 * a))
	ci.draw_rect(prel.grow(5.0 * u), Color(tint.r, tint.g, tint.b, a))
	if pvp != null:
		ci.draw_texture_rect(pvp.get_texture(), prel, false, Color(1, 1, 1, a))
	ci.draw_rect(prel, ink, false, 3.0 * u)
	# a soft vignette on the picture
	ci.draw_rect(Rect2(prel.position, Vector2(prel.size.x, prel.size.y * 0.16)), Color(0, 0, 0, 0.18 * a))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# the name plate
	var tx = prect.end.x + 26.0 * u
	var nm = v["who"]
	var nw = bold.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, int(21 * u)).x + 40.0 * u
	var plate = Rect2(tx - 8.0 * u, by0 - 22.0 * u, nw, 36.0 * u)
	ci.draw_rect(Rect2(plate.position + Vector2(4, 4) * u, plate.size), Color(0, 0, 0, 0.5 * a))
	ci.draw_rect(plate, Color(tint.r, tint.g, tint.b, a))
	ci.draw_rect(plate, ink, false, 3.0 * u)
	ci.draw_string(bold, Vector2(plate.position.x + 20.0 * u, plate.position.y + 26.0 * u), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, int(21 * u), ink)
	if v["sub"] != "":
		ci.draw_string(font, Vector2(plate.end.x + 12.0 * u, plate.position.y + 24.0 * u), v["sub"], HORIZONTAL_ALIGNMENT_LEFT, -1, int(13 * u), Color(1, 0.93, 0.75, 0.7 * a))
	# the line
	var fs = int(24.0 * u)
	var maxw = box.end.x - 30.0 * u - tx
	var lines = _wrap(v["text"], font, fs, maxw)
	var left = v["shown"]
	var ty = by0 + 52.0 * u
	for l in lines:
		if left <= 0:
			break
		var part = l.substr(0, left)
		ci.draw_string(font, Vector2(tx + 1.5, ty + 1.5), part, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.5 * a))
		ci.draw_string(font, Vector2(tx, ty), part, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, cream)
		left -= l.length() + 1
		ty += fs * 1.3
	# the arrow: the line is finished, a press goes on
	if v["shown"] >= v["text"].length() and not v["closing"]:
		var blink = 0.5 + 0.5 * sin(GS.msec() * 0.008)
		var ap = Vector2(box.end.x - 34.0 * u, box.end.y - 26.0 * u + 3.0 * u * sin(GS.msec() * 0.008))
		ci.draw_colored_polygon(PackedVector2Array([ap + Vector2(-8, -6) * u, ap + Vector2(8, -6) * u, ap + Vector2(0, 7) * u]), Color(gold.r, gold.g, gold.b, a * (0.4 + 0.6 * blink)))

# film mode: letterbox bars, the chapter tag, the gull's thought
func _film(ci, u):
	if bars <= 0.001 and narr == null and tag == null:
		return
	var e = bars * bars * (3.0 - 2.0 * bars)
	var bh = ci.size.y * 0.135 * e
	ci.draw_rect(Rect2(0, 0, ci.size.x, bh), Color(0, 0, 0, 1))
	ci.draw_rect(Rect2(0, ci.size.y - bh, ci.size.x, bh), Color(0, 0, 0, 1))
	if tag != null:
		var age = (GS.msec() - tag["t0"]) / 1000.0
		var ta = clamp(min(age / 0.5, (tag["life"] - age) / 0.5), 0.0, 1.0)
		var txt = tag["text"]
		var ty = bh * 0.5 + 6.0 * u
		var tw_ = bold.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, int(15 * u)).x
		var tx = ci.size.x * 0.5 - (tw_ + (txt.length() - 1) * 4.0 * u) * 0.5
		for ch in txt:
			ci.draw_string(bold, Vector2(tx, ty), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, int(15 * u), Color(1.0, 0.86, 0.5, 0.85 * ta * e))
			tx += bold.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, int(15 * u)).x + 4.0 * u
	if narr != null and narr["a"] > 0.01:
		var n = narr
		var fs = int(29.0 * u)
		var lines = _wrap(n["text"], font, fs, ci.size.x * 0.72)
		var lh = fs * 1.3
		var total_h = lines.size() * lh
		var y0 = ci.size.y - bh * 0.5 - total_h * 0.5 + fs * 0.85
		var left = n["shown"]
		var tint = n["tint"]
		for l in lines:
			if left <= 0:
				break
			var part = l.substr(0, left)
			var w = font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var x = ci.size.x * 0.5 - w * 0.5
			ci.draw_string(font, Vector2(x + 1.5, y0 + 1.5), part, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0, 0, 0, 0.6 * n["a"]))
			ci.draw_string(font, Vector2(x, y0), part, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(tint.r, tint.g, tint.b, n["a"]))
			left -= l.length() + 1
			y0 += lh

# ------------------------------------------------------------------ memory cards (the ending): small tilted polaroids with a drawn picture and a title
const CARD_COL = {"fry": [Color("FFE9A8"), Color("F6C453")], "plain": [Color("F6E7C4"), Color("D8C9A6")], "coffee": [Color("F2D3B0"), Color("C98A4B")], "alcohol": [Color("FFE9A0"), Color("FFB05A")],
	"ice": [Color("FFD6EC"), Color("BFEBD2")], "starlight": [Color("2A2E6A"), Color("C689E8")], "fish": [Color("BFE6F8"), Color("5FA8D8")], "bigfish": [Color("BFE6F8"), Color("4F86C8")],
	"cloud": [Color("A9D4F5"), Color("E8F4FF")], "sun": [Color("FFE08A"), Color("FF9E4A")], "skybow": [Color("CFE8FF"), Color("FFD9EC")], "meteor": [Color("1B1F4E"), Color("5A63B8")], "friend": [Color("FFD3DE"), Color("FFB2C6")],
	"gift": [Color("FFD3DE"), Color("FFE1A8")], "kid": [Color("FFD3DE"), Color("FFC8A8")], "rainbow": [Color("FFE1F2"), Color("BDE8FF")], "thermal": [Color("CFE9FF"), Color("FFE7B0")],
	"skim": [Color("BFE6F8"), Color("7FC3E4")], "wall": [Color("E9D8C4"), Color("C9AE94")], "armed": [Color("D8D8E6"), Color("A8A8C4")], "all24": [Color("FFF1C8"), Color("FFC9E8")]}

func card(kind, title, life = 3.8, nx = 0.5, ny = 0.46, rot = -4.0, extra = {}):
	cards.append({"kind": kind, "title": title, "t0": GS.msec(), "life": life, "pos": Vector2(nx, ny), "rot": rot, "extra": extra})
	Sfx.play("vn_pop", -12.0, 1.3)

func _cards(ci, R, u):
	var i = 0
	while i < cards.size():
		var c = cards[i]
		var age = (GS.msec() - c["t0"]) / 1000.0
		if age > c["life"]:
			cards.remove_at(i)
			continue
		i += 1
		var e_in = clamp(age / 0.5, 0.0, 1.0)
		var e = 1.0 - pow(1.0 - e_in, 3.0)
		var a = clamp(min(age / 0.35, (c["life"] - age) / 0.6), 0.0, 1.0)
		var w = 236.0 * u
		var h = 288.0 * u
		var centre = Vector2(R.position.x + R.size.x * c["pos"].x, R.position.y + R.size.y * c["pos"].y)
		centre += Vector2((-1.0 if c["pos"].x > 0.5 else 1.0) * 46.0 * u * (1.0 - e), 36.0 * u * (1.0 - e) + sin(age * 1.2) * 3.0 * u)
		ci.draw_set_transform(centre, deg_to_rad(c["rot"] + 5.0 * (1.0 - e)), Vector2.ONE * (0.92 + 0.08 * e))
		var rect = Rect2(-w * 0.5, -h * 0.5, w, h)
		ci.draw_rect(Rect2(rect.position + Vector2(7, 9) * u, rect.size), Color(0, 0, 0, 0.38 * a))
		ci.draw_rect(rect, Color(0.99, 0.97, 0.92, a))
		var photo = Rect2(rect.position + Vector2(14, 14) * u, Vector2(w - 28.0 * u, h - 82.0 * u))
		var pc = CARD_COL.get(c["kind"], [Color("FFE9A8"), Color("F6C453")])
		var strips = 14
		for k in strips:
			var kk = float(k) / float(strips - 1)
			ci.draw_rect(Rect2(photo.position + Vector2(0, photo.size.y * k / strips), Vector2(photo.size.x, photo.size.y / strips + 1.0)), Color(pc[0].r, pc[0].g, pc[0].b, a).lerp(Color(pc[1].r, pc[1].g, pc[1].b, a), kk))
		_mem_icon(ci, c["kind"], photo.get_center() + Vector2(0, 4.0 * u), photo.size.x * 0.3, a, c["extra"], age)
		ci.draw_rect(photo, Color(0.1, 0.08, 0.14, 0.55 * a), false, 2.0 * u)
		# the title, like a pencil line on the white strip
		ci.draw_string(bold, Vector2(rect.position.x, rect.end.y - 26.0 * u), c["title"], HORIZONTAL_ALIGNMENT_CENTER, w, int(18 * u), Color(0.16, 0.13, 0.18, a))
		# a little tape
		ci.draw_rect(Rect2(-34.0 * u, rect.position.y - 8.0 * u, 68.0 * u, 20.0 * u), Color(1.0, 0.93, 0.6, 0.55 * a))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# the small pictures: drawn, flat, friendly (s = a unit in pixels)
func _mem_icon(ci, kind, c, s, a, extra, age):
	var ink = Color(0.16, 0.12, 0.2, a)
	var white = Color(1, 1, 1, a)
	var lw = max(s * 0.1, 2.0)
	match kind:
		"fry", "plain":
			var col = Color(0.98, 0.78, 0.26, a)
			if kind == "plain":
				ci.draw_line(c + Vector2(-s * 1.0, s * 0.55), c + Vector2(s * 1.0, s * 0.55), Color(0.5, 0.4, 0.3, 0.35 * a), lw * 0.8)
				ci.draw_line(c + Vector2(-s * 0.9, s * 0.3), c + Vector2(s * 0.9, s * 0.15), col, s * 0.34)
				ci.draw_line(c + Vector2(s * 1.0, s * 0.5), c + Vector2(s * 1.2, s * 0.35), Color(0.4, 0.3, 0.2, 0.7 * a), lw * 0.7)
				ci.draw_line(c + Vector2(s * 1.1, s * 0.62), c + Vector2(s * 1.36, s * 0.62), Color(0.4, 0.3, 0.2, 0.7 * a), lw * 0.7)
			else:
				for k in 3:
					ci.draw_line(c + Vector2(-s * 0.55 + k * s * 0.5, s * 0.75), c + Vector2(-s * 0.7 + k * s * 0.6, -s * 0.7), col, s * 0.3)
				ci.draw_rect(Rect2(c + Vector2(-s * 0.8, s * 0.3), Vector2(s * 1.6, s * 0.7)), Color(0.86, 0.22, 0.22, a))
		"coffee":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.6, -s * 0.25), Vector2(s * 1.2, s * 0.95)), Color(0.98, 0.95, 0.9, a))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.6, -s * 0.25), Vector2(s * 1.2, s * 0.22)), Color(0.45, 0.28, 0.16, a))
			ci.draw_arc(c + Vector2(s * 0.62, s * 0.2), s * 0.32, -PI * 0.5, PI * 0.5, 12, white, lw, true)
			for k in 3:
				var ph = age * 2.0 + k
				ci.draw_line(c + Vector2(-s * 0.3 + k * s * 0.3, -s * 0.4), c + Vector2(-s * 0.3 + k * s * 0.3 + sin(ph) * s * 0.12, -s * 0.95), Color(1, 1, 1, 0.8 * a), lw * 0.8)
		"alcohol":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.8, -s * 0.6), c + Vector2(s * 0.8, -s * 0.6), c + Vector2(0, s * 0.25)]), Color(1.0, 0.72, 0.3, a))
			ci.draw_line(c + Vector2(0, s * 0.25), c + Vector2(0, s * 0.85), white, lw)
			ci.draw_line(c + Vector2(-s * 0.4, s * 0.88), c + Vector2(s * 0.4, s * 0.88), white, lw)
			ci.draw_line(c + Vector2(s * 0.2, -s * 0.5), c + Vector2(s * 0.6, -s * 1.1), Color(0.9, 0.3, 0.3, a), lw * 0.8)
			ci.draw_circle(c + Vector2(-s * 0.1, -s * 0.28), s * 0.13, Color(0.5, 0.7, 0.3, a))
		"ice":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.45, -s * 0.05), c + Vector2(s * 0.45, -s * 0.05), c + Vector2(0, s * 1.05)]), Color(0.9, 0.7, 0.35, a))
			ci.draw_circle(c + Vector2(0, -s * 0.28), s * 0.55, Color(1.0, 0.7, 0.85, a))
			ci.draw_circle(c + Vector2(0, -s * 0.8), s * 0.4, Color(0.72, 0.95, 0.85, a))
			ci.draw_circle(c + Vector2(s * 0.05, -s * 1.15), s * 0.1, Color(0.9, 0.25, 0.3, a))
		"fish", "bigfish":
			var fc = Color(extra.get("col", Color("5FA8D8")).r, extra.get("col", Color("5FA8D8")).g, extra.get("col", Color("5FA8D8")).b, a)
			var sw = 1.0 if kind == "fish" else 1.25
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.9, 0) * sw, c + Vector2(-s * 0.2, -s * 0.5) * sw, c + Vector2(s * 0.5, -s * 0.1) * sw, c + Vector2(s * 0.5, s * 0.1) * sw, c + Vector2(-s * 0.2, s * 0.5) * sw]), fc)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.45, 0) * sw, c + Vector2(s * 1.0, -s * 0.45) * sw, c + Vector2(s * 1.0, s * 0.45) * sw]), fc.darkened(0.15))
			ci.draw_circle(c + Vector2(-s * 0.55, -s * 0.1) * sw, s * 0.07, ink)
			for k in 3:
				ci.draw_arc(c + Vector2(-s * 0.4 - 0.0, s * 0.9 + k * s * 0.18), s * (0.2 + 0.1 * k), PI, TAU, 8, Color(1, 1, 1, 0.6 * a), lw * 0.6, true)
		"cloud":
			ci.draw_circle(c + Vector2(-s * 0.55, s * 0.15), s * 0.5, white)
			ci.draw_circle(c + Vector2(0.0, -s * 0.2), s * 0.7, white)
			ci.draw_circle(c + Vector2(s * 0.6, s * 0.15), s * 0.5, white)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.55, s * 0.15), Vector2(s * 1.15, s * 0.5)), white)
		"sun":
			ci.draw_circle(c, s * 0.6, Color(1.0, 0.82, 0.25, a))
			for k in 12:
				var an = k * TAU / 12.0 + age * 0.4
				ci.draw_line(c + Vector2(cos(an), sin(an)) * s * 0.85, c + Vector2(cos(an), sin(an)) * s * (1.2 + 0.1 * (k % 2)), Color(1.0, 0.7, 0.2, a), lw)
		"skybow":
			for k in 7:
				ci.draw_arc(c + Vector2(0, s * 0.6), s * (1.35 - k * 0.14), PI, TAU, 24, Color.from_hsv(float(k) / 8.0, 0.65, 1.0, a), lw * 1.3, true)
		"meteor":
			var st0 = c + Vector2(s * 0.4, -s * 0.4)
			ci.draw_colored_polygon(PackedVector2Array([st0 + Vector2(0, -s * 0.7), st0 + Vector2(s * 0.17, -s * 0.17), st0 + Vector2(s * 0.7, 0), st0 + Vector2(s * 0.17, s * 0.17),
				st0 + Vector2(0, s * 0.7), st0 + Vector2(-s * 0.17, s * 0.17), st0 + Vector2(-s * 0.7, 0), st0 + Vector2(-s * 0.17, -s * 0.17)]), Color(1.0, 0.95, 0.7, a))
			for k in 4:
				ci.draw_line(st0 + Vector2(-s * 0.2, s * 0.2) * (1.0 + k * 0.1), c + Vector2(-s * (1.1 - k * 0.1), s * (1.1 - k * 0.2)), Color(1.0, 0.9, 0.6, a * (0.9 - k * 0.2)), lw * (1.6 - k * 0.3))
		"starlight":
			for k in 5:
				var col2 = Color.from_hsv(float(k) / 5.0, 0.5, 1.0, a)
				ci.draw_arc(c + Vector2(0, s * 0.6), s * (1.3 - k * 0.2), PI, TAU, 24, col2, lw * 1.3, true)
			ci.draw_circle(c + Vector2(s * 0.7, -s * 0.4), s * 0.08, white)
			ci.draw_circle(c + Vector2(-s * 0.8, -s * 0.2), s * 0.06, white)
		"friend", "gift", "kid":
			var hp = PackedVector2Array()
			for k in 40:
				var tt = TAU * k / 40.0
				hp.append(c + Vector2(16.0 * pow(sin(tt), 3.0), -(13.0 * cos(tt) - 5.0 * cos(2 * tt) - 2.0 * cos(3 * tt) - cos(4 * tt))) * s * 0.052 + Vector2(0, -s * 0.05))
			ci.draw_colored_polygon(hp, Color(0.95, 0.35, 0.5, a))
			if kind == "gift":
				ci.draw_line(c + Vector2(-s * 0.3, -s * 0.2), c + Vector2(s * 0.3, -s * 0.2), white, lw)
		"rainbow":
			for k in 6:
				ci.draw_arc(c + Vector2(0, s * 0.6), s * (1.3 - k * 0.15), PI, TAU, 24, Color.from_hsv(float(k) / 6.0, 0.55, 1.0, a), lw * 1.2, true)
		"thermal":
			for k in 3:
				var xo = (k - 1) * s * 0.6
				ci.draw_line(c + Vector2(xo, s * 0.7), c + Vector2(xo + sin(age * 2.0 + k) * s * 0.1, -s * 0.6), Color(1, 1, 1, 0.8 * a), lw)
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(xo - s * 0.18, -s * 0.5), c + Vector2(xo + s * 0.18, -s * 0.5), c + Vector2(xo, -s * 0.85)]), Color(1, 1, 1, 0.9 * a))
		"skim":
			for k in 4:
				ci.draw_arc(c + Vector2(-s * 0.6 + k * s * 0.4, s * 0.35), s * 0.3, PI, TAU, 8, white, lw, true)
			ci.draw_arc(c + Vector2(0, -s * 0.2), s * 0.55, PI * 1.1, PI * 1.9, 10, Color(1, 1, 1, 0.9 * a), lw, true)
		"wall":
			for r in 3:
				for k in 3:
					var off = s * 0.45 if r % 2 == 1 else 0.0
					ci.draw_rect(Rect2(c + Vector2(-s * 0.9 + k * s * 0.62 - off, -s * 0.7 + r * s * 0.42), Vector2(s * 0.58, s * 0.38)), Color(0.78, 0.4, 0.3, a))
			ci.draw_string(bold, c + Vector2(-s * 0.4, s * 1.0), "BONK", HORIZONTAL_ALIGNMENT_CENTER, s * 0.8, int(s * 0.34), ink)
		"armed":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.4, -s * 0.9), Vector2(s * 0.8, s * 1.1)), Color(0.16, 0.17, 0.21, a))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.85, s * 0.15), Vector2(s * 1.7, s * 0.18)), Color(0.16, 0.17, 0.21, a))
			ci.draw_rect(Rect2(c + Vector2(-s * 0.4, -s * 0.1), Vector2(s * 0.8, s * 0.16)), Color(0.96, 0.78, 0.35, a))
		"all24":
			for k in 7:
				var an = TAU * k / 7.0 - PI * 0.5
				var tc = GS.TYPE_COLORS[GS.FRY_TYPES[k]]
				ci.draw_circle(c + Vector2(cos(an), sin(an)) * s * 0.85, s * 0.24, Color(tc.r, tc.g, tc.b, a))
			ci.draw_circle(c, s * 0.32, Color(1, 0.95, 0.7, a))
		_:
			ci.draw_circle(c, s * 0.5, white)

func draw_page(ci):
	if not (active or light) or ci.size.y < 20.0:
		return
	var u = ci.size.y / 720.0
	var t = GS.msec() * 0.001
	var R = inner_rect(ci)
	var jitter = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * 6.0 * u
	# the poster (the cover art) covers the page
	if poster_a > 0.01 and poster_tex != null:
		var k = 1.0 + 0.06 * clamp((GS.msec() - poster_t0) / 24000.0, 0.0, 1.0)
		var ps = Vector2(ci.size.y * 16.0 / 9.0, ci.size.y)
		ps = Vector2(max(ps.x, ci.size.x), max(ps.y, ci.size.y)) * k
		ci.draw_texture_rect(poster_tex, Rect2(ci.size * 0.5 - ps * 0.5, ps), false, Color(1, 1, 1, poster_a))
	if art_tex != null:
		var kz = 1.0 + 0.05 * clamp((GS.msec() - art_t0) / 14000.0, 0.0, 1.0)
		var asz = Vector2(R.size.y * art_tex.get_width() / float(art_tex.get_height()), R.size.y)
		asz = Vector2(max(asz.x, R.size.x), max(asz.y, R.size.y)) * kz
		var clip = Rect2(R.position, R.size)

		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var src_w = art_tex.get_width() / kz
		var src_h = art_tex.get_height() / kz
		var aspect = R.size.x / R.size.y
		var sw = min(src_w, src_h * aspect)
		var sh = sw / aspect
		var sx = (art_tex.get_width() - sw) * 0.5
		var sy = (art_tex.get_height() - sh) * 0.5
		ci.draw_texture_rect_region(art_tex, R, Rect2(sx, sy, sw, sh))
	# halftone shading in the corners of the panel
	if frame > 0.01 and halftone != null:
		var hs = Vector2(192, 192) * 1.25 * u
		ci.draw_set_transform(Vector2(R.position.x, R.end.y), 0.0, Vector2(1, -1))
		ci.draw_texture_rect(halftone, Rect2(Vector2.ZERO, hs), false, Color(1, 1, 1, frame * 0.55))
		ci.draw_set_transform(Vector2(R.end.x, R.position.y), 0.0, Vector2(-1, 1))
		ci.draw_texture_rect(halftone, Rect2(Vector2.ZERO, hs), false, Color(1, 1, 1, frame * 0.4))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# impact lines
	var i = 0
	while i < bursts.size():
		var bu = bursts[i]
		var age = (GS.msec() - bu["t0"]) / 1000.0
		if age > bu["life"]:
			bursts.remove_at(i)
			continue
		var cc = Vector2(R.position.x + R.size.x * bu["pos"].x, R.position.y + R.size.y * bu["pos"].y) + jitter
		var kk = age / bu["life"]
		for q in 28:
			var ang = TAU * q / 28.0 + 0.1 * q
			var r0 = (110.0 + 300.0 * kk) * u
			var r1 = r0 + (90.0 + 160.0 * float((q * 7) % 5) / 4.0) * u
			ci.draw_line(cc + Vector2(cos(ang), sin(ang)) * r0, cc + Vector2(cos(ang), sin(ang)) * r1, Color(INK.r, INK.g, INK.b, (1.0 - kk) * 0.8), (2.0 + 4.0 * (1.0 - kk)) * u)
		i += 1
	# the slammed words
	for w in words:
		var age2 = (GS.msec() - w["t0"]) / 1000.0
		var pop = 1.0
		if age2 < 0.3:
			pop = lerp(2.4, 1.0, 1.0 - pow(1.0 - age2 / 0.3, 3.0))
		var wc = Vector2(R.position.x + R.size.x * w["pos"].x, R.position.y + R.size.y * w["pos"].y) + jitter * (1.0 if age2 < 0.5 else 0.0)
		if w.has("star"):
			# a beat's word sits on an ink-edged starburst of its own colour (it pops in with the word and turns very slowly)
			var sa = w["a"] * clamp(age2 / 0.06, 0.0, 1.0)
			var sr = w["size"] * u * 1.25 * pop * (1.0 + 0.04 * sin(age2 * 9.0))
			var sc2 = w["star"]
			_starburst(ci, wc, sr * 1.08, 13, INK, sa, age2 * 0.12 + 0.3, 0.66)
			_starburst(ci, wc, sr, 13, Color(sc2.r, sc2.g, sc2.b), sa * 0.95, age2 * 0.12 + 0.3, 0.66)
		_lettering(ci, w["text"], wc, w["size"], w["col"], w["rot"], w["a"] * clamp(age2 / 0.06, 0.0, 1.0), pop)
	# the sound effects
	i = 0
	while i < sfx_items.size():
		var s = sfx_items[i]
		var age3 = (GS.msec() - s["t0"]) / 1000.0
		if age3 > s["life"]:
			sfx_items.remove_at(i)
			continue
		var pp = 1.0 + 0.5 * max(0.0, 1.0 - age3 / 0.22) + 0.04 * sin(age3 * 18.0)
		var fa = clamp(min(age3 / 0.05, (s["life"] - age3) / 0.3), 0.0, 1.0)
		var sc = Vector2(R.position.x + R.size.x * s["pos"].x, R.position.y + R.size.y * s["pos"].y)
		_lettering(ci, s["text"], sc, s["size"], s["col"], s["rot"], fa, pp)
		i += 1
	_balloon(ci, R, u)
	_caption(ci, R, u)
	_vn(ci, R, u)
	_cards(ci, R, u)
	_film(ci, u)
	# the frame: paper margin, thick ink border
	if frame > 0.01:
		var e = frame * frame * (3.0 - 2.0 * frame)
		var pa = clamp(frame * 1.6, 0.0, 1.0)
		var paper = Color(PAPER.r, PAPER.g, PAPER.b, pa)
		ci.draw_rect(Rect2(Vector2.ZERO, Vector2(ci.size.x, R.position.y)), paper)
		ci.draw_rect(Rect2(Vector2(0, R.end.y), Vector2(ci.size.x, ci.size.y - R.end.y)), paper)
		ci.draw_rect(Rect2(Vector2(0, R.position.y), Vector2(R.position.x, R.size.y)), paper)
		ci.draw_rect(Rect2(Vector2(R.end.x, R.position.y), Vector2(ci.size.x - R.end.x, R.size.y)), paper)
		ci.draw_rect(R, Color(INK.r, INK.g, INK.b, pa), false, 7.0 * u * e + 1.0)
		for corner in [R.position, Vector2(R.end.x, R.position.y), Vector2(R.position.x, R.end.y), R.end]:
			ci.draw_circle(corner, 3.4 * u * e, Color(INK.r, INK.g, INK.b, pa))
	# hold E
	if hold["on"]:
		var base = Vector2(ci.size.x - 74.0 * u, ci.size.y - 66.0 * u)
		var pulse = 1.0 + 0.04 * sin(t * 5.0)
		var cs = 46.0 * u * pulse
		ci.draw_rect(Rect2(base - Vector2(cs, cs) * 0.5, Vector2(cs, cs)), Color(0.07, 0.07, 0.1, 0.85))
		ci.draw_rect(Rect2(base - Vector2(cs, cs) * 0.5, Vector2(cs, cs)), Color(1, 0.95, 0.8, 0.95), false, 2.5 * u)
		ci.draw_string(bold, base + Vector2(-cs * 0.5, cs * 0.3), "E", HORIZONTAL_ALIGNMENT_CENTER, cs, int(30 * u), Color(1, 0.97, 0.88))
		ci.draw_arc(base, cs * 0.82, -PI * 0.5, -PI * 0.5 + TAU * hold["p"], 40, GOLD, 4.0 * u, true)
		ci.draw_arc(base, cs * 0.82, 0, TAU, 40, Color(1, 1, 1, 0.18), 2.0 * u, true)
		var lab = "HOLD   " + hold["label"]
		ci.draw_string_outline(bold, base + Vector2(-cs * 0.7 - 300.0 * u, 7.0 * u), lab, HORIZONTAL_ALIGNMENT_RIGHT, 300.0 * u, int(19 * u), 6, Color(0, 0, 0, 0.75))
		ci.draw_string(bold, base + Vector2(-cs * 0.7 - 300.0 * u, 7.0 * u), lab, HORIZONTAL_ALIGNMENT_RIGHT, 300.0 * u, int(19 * u), Color(1, 0.97, 0.88, 0.95))
	# shutter / black / flash
	if shutter >= 0.0:
		var sl = 180.0 * u
		var W = ci.size.x
		var H = ci.size.y
		if shutter <= 1.0:
			var x = lerp(-sl, W + sl, shutter)
			var top = clamp(x + sl, -10.0, W + 10.0)
			var bot = clamp(x - sl, -10.0, W + 10.0)
			if top > -9.0:
				ci.draw_colored_polygon(PackedVector2Array([Vector2(-10, -10), Vector2(top, -10), Vector2(bot, H + 10), Vector2(-10, H + 10)]), INK)
		else:
			var x2 = lerp(-sl, W + sl, shutter - 1.0)
			var top2 = clamp(x2 + sl, -10.0, W + 10.0)
			var bot2 = clamp(x2 - sl, -10.0, W + 10.0)
			if bot2 < W + 9.0:
				ci.draw_colored_polygon(PackedVector2Array([Vector2(top2, -10), Vector2(W + 10, -10), Vector2(W + 10, H + 10), Vector2(bot2, H + 10)]), INK)
	if dim > 0.001:
		ci.draw_rect(Rect2(Vector2.ZERO, ci.size), Color(0, 0, 0, dim))
	if flash > 0.01:
		ci.draw_rect(Rect2(Vector2.ZERO, ci.size), Color(flash_col.r, flash_col.g, flash_col.b, flash))
