extends Node
# The story scenes, written as comic panels + a visual-novel box (see story.gd for the lettering, the portraits and the film mode):
#   opening()   establishing panels, the old man's cafe (a small close-up: one fry slips from his fingers and just lies there), the hungry gull, the
#               big brother's speech in a visual-novel box with his name and his face, then "HOLD E TO FLY"
#   ending()    the flight home, the question, the silence, JUST... (the finery falls away) ...SOME... FRIES.  The big brother takes his shades off.
#   cinema(id)  the four cinematic moments of the game, in film mode (letterbox bars, the gull's own thoughts under the picture, slow time, its own music):
#               drinks3 (STARLIGHT for the first time), fish (the first catch), meteor (the first shooting star), all24 (every fry, and still...)
# The director's notes live in docs/26_ROUND7_CHANGES.md and docs/28_ROUND8_CHANGES.md.

const CineCam = preload("res://scripts/ui/cine_cam.gd")
var main
var st
var cine_busy = false
var orbit_id = 0
var cam_dir = null
var cine_done_at = -99999

const BRO_NAME = "BIG BRO"
const BRO_SUB = "gull of many accessories"
const BRO_TINT = Color("F5C65A")
const YOU_NAME = "YOU"
const YOU_SUB = "a seagull. hungry."
const YOU_TINT = Color("BFE3FF")
const BRO_LOOK = {"dist": 1.05, "yaw": 0.5, "up": 0.07, "fov": 34.0}
const YOU_LOOK = {"dist": 0.82, "yaw": -0.45, "up": 0.02, "fov": 32.0}

func _bro_head():
	return main.bro.gull.head.global_position + Vector3(0, 0.1, 0)

func _gull_head():
	return main.player.gull.head.global_position + Vector3(0, 0.05, 0)

func _bro_gull():
	return main.bro.gull

func _you_gull():
	return main.player.gull

func _you_pos():
	return main.player.gull.head.global_position

func _bro_pos():
	return main.bro.gull.head.global_position

func _bro_say(text, pitch = 0.6, look = BRO_LOOK):
	var lk = look.duplicate()
	lk["avoid"] = Callable(self, "_you_pos")
	await st.say_vn(BRO_NAME, BRO_SUB, text, Callable(self, "_bro_gull"), pitch, BRO_TINT, lk)

func _you_say(text, pitch = 1.5, look = YOU_LOOK):
	var lk = look.duplicate()
	lk["avoid"] = Callable(self, "_bro_pos")
	await st.say_vn(YOU_NAME, YOU_SUB, text, Callable(self, "_you_gull"), pitch, YOU_TINT, lk)

func _frames(n):
	for i in n:
		await get_tree().process_frame

# ------------------------------------------------------------------ OPENING
# the old man drops the first fry: a small, quiet close-up. Not a flourish: the fry just slips and lies there (the player will remember it - or will not).
func _old_man_drops(fry = null, target = null, with_cam = true):
	var m = main
	var el = m.elder
	var WB = preload("res://scripts/world/world_builder.gd")
	if fry == null:
		fry = m.ordinary
	if target == null:
		target = WB.ORDINARY_POS
	fry.visible = true
	el.rig.override_arm_r = -2.1
	el.rig.override_arm_r_z = -0.15
	await _frames(2)
	var t0 = GS.msec()
	var hand = el.rig.hand_r.global_position
	if with_cam:
		cc().insert_shot(st, hand + Vector3(0, 0.05, 0), 1.5, 0.0, {"size": 0.36, "fov": 34, "az": 60, "spread": 120, "h": 0.1, "push": 0.07}, 5.0)
	while GS.msec() - t0 < 1500:
		fry.global_position = el.rig.hand_r.global_position + Vector3(0, 0.0, 0.05)
		fry.rotation = Vector3(0, 0.6, 0)
		await get_tree().process_frame
	# it slips
	el.rig.override_arm_r = null
	fry.rotation = Vector3(0, 0.3, 0)
	var tw = create_tween()
	tw.tween_property(fry, "global_position", target + Vector3(0, 0.04, 0), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(fry, "global_position", target, 0.12)
	tw.parallel().tween_property(fry, "rotation", Vector3.ZERO, 0.6)
	if with_cam:
		st.cam_set(target + Vector3(1.0, 0.85, 1.55), target + Vector3(0, 0.1, 0), 25.0, target + Vector3(0.9, 0.8, 1.45), target + Vector3(0, 0.12, 0), 24.0, 4.0, 0.003)
	await get_tree().create_timer(0.55, true, false, true).timeout
	Sfx.play("drop_tick", -9.0, 1.0)
	if with_cam:
		st.sfx("tk.", 0.62, 0.62, -4.0, Color("D9CBB0"), 30.0, 0.9)
	el.look_at_pos(el.global_position + Vector3(0, 0, 8), 3.0)
	await st.wait(1.7 if with_cam else 0.9)

func opening():
	var m = main
	st = m.story
	var pl = m.player
	m.get_tree().paused = false
	pl.input_locked = true
	m.hud.visible = false
	m.ordinary.visible = false
	pl.yaw = atan2(-1.0, 0.0)               # the little gull looks at its big brother (east)
	pl.aim_yaw = pl.yaw
	pl.mode = 1
	m.bro.look_at_player = true
	st.begin(pl)
	st.dim = 1.0
	st.frame = 0.0
	st.cam_set(Vector3(-46.0, 30.0, 58.0), Vector3(-4.0, 5.0, 8.0), 56.0, Vector3(-38.0, 23.0, 48.0), Vector3(-4.0, 5.0, 8.0), 54.0, 12.0)
	await _frames(3)
	# --- panel 1: the age of magic
	st.set_art("o1_age")
	st.frame_in(0.6)
	await st.fade_black(0.0, 0.9)
	st.sfx("*shimmer*", 0.8, 0.74, 6.0, Color("BFEFFF"), 40.0, 2.2)
	await st.caption("THIS IS AN AGE OF MAGIC.")
	# --- panel 2: the wind listens
	await st.cut(func():
		st.set_art("o2_wind")
		st.cam_set(Vector3(-6.8, 1.55, 6.7), Vector3(-8.0, 0.95, 4.3), 40.0, Vector3(-6.4, 1.2, 6.2), Vector3(-8.0, 1.0, 4.3), 34.0, 9.0))
	st.burst_at(0.6, 0.55)
	st.sfx("WHOOOOSH", 0.26, 0.66, -10.0, Color("BDE8FF"), 62.0, 2.0)
	Sfx.play("whoosh", -10.0, 0.8)
	await st.caption("THE WIND LISTENS TO CERTAIN FRIES.")
	# --- panel 3: breath by the carton
	await st.cut(func():
		st.set_art("o3_carton")
		st.cam_set(Vector3(5.8, 3.0, -9.5), Vector3(3.0, 5.2, -17.0), 46.0, Vector3(6.8, 3.1, -11.0), Vector3(3.0, 5.3, -17.0), 42.0, 9.0))
	st.sfx("pssshhh!", 0.72, 0.28, 7.0, Color("FFE9A0"), 54.0, 1.8)
	Sfx.play("sip", -10.0, 0.7)
	await st.caption("BREATH IS SOLD BY THE CARTON.")
	# --- panel 4: the cafe, and an old man who does not notice a fry slip from his fingers
	await st.cut(func():
		st.set_art("o3b_cafe")
		st.cam_set(Vector3(-5.4, 1.3, 7.2), Vector3(-8.3, 1.25, 3.5), 36.0, Vector3(-5.9, 1.35, 7.0), Vector3(-8.3, 1.3, 3.5), 34.0, 8.0))
	st.sfx("clink", 0.7, 0.7, 6.0, Color("E9F2FF"), 34.0, 1.4)
	await st.caption("A SLOW MORNING AT THE CAFE.")
	await _old_man_drops()
	# --- panel 5: a pier
	await st.cut(func():
		st.set_art("o4_pier")
		st.cam_set(Vector3(1.8, 2.2, 104.0), Vector3(2.0, 8.0, 54.0), 50.0, Vector3(1.5, 3.0, 90.0), Vector3(2.0, 10.0, 54.0), 52.0, 10.0))
	st.sfx("lap... lap...", 0.2, 0.72, 5.0, Color("D8F2FF"), 36.0, 2.6)
	await st.caption("AND SOMEWHERE ON A PIER,")
	# --- panel 6: a seagull is hungry
	await st.cut(func():
		st.set_art("o5_gull")
		m.bro.visible = false
		cc().gull_shot(st, pl.gull, {"az": 38, "spread": 50, "h": 0.07, "fov": 38, "size": 0.32, "push": 0.07}, 9.0, false, 0.4, pl.yaw))
	Sfx.play("growl", -8.0)
	st.sfx("grrrmmbl...", 0.3, 0.7, -5.0, Color("FFC27A"), 48.0, 2.4)
	await st.caption("A SEAGULL IS HUNGRY.")
	# --- the big brother (a visual-novel box with his name and his face)
	await st.cut(func():
		m.bro.visible = true
		st.set_art("")
		st.cam_set(Vector3(-12.8, 6.0, 2.6), Vector3(-8.0, 5.5, -1.0), 38.0, Vector3(-12.2, 5.95, 2.2), Vector3(-7.9, 5.5, -1.0), 36.0, 16.0))
	await st.wait(0.4)
	st.sfx("CLINK", 0.74, 0.3, 8.0, Color("FFE27A"), 50.0, 1.0)
	Sfx.play("equip", -10.0, 0.8)
	await _bro_say("I got the chain.")
	st.sfx("flick", 0.7, 0.26, -6.0, Color("FFFFFF"), 36.0, 0.8)
	await _bro_say("The shades. The hat. The coat.")
	await _bro_say("I got everything.")
	st.sfx("*puff*", 0.62, 0.2, 4.0, Color("E8E8F0"), 38.0, 1.6)
	Sfx.play("whoosh", -16.0, 0.6)
	await st.vn_end(0.25)
	await st.wait(0.8)
	# close on him
	await st.cut(func():
		st.cam_set(Vector3(-10.2, 6.2, 2.2), Vector3(-6.2, 5.9, -1.3), 34.0, Vector3(-9.6, 6.1, 1.7), Vector3(-6.2, 5.9, -1.3), 32.0, 9.0))
	await _bro_say("...and I'm still hungry.", 0.8, {"dist": 1.0, "yaw": 0.4, "up": 0.04, "fov": 34.0, "roll": 0.05})
	await _bro_say("So.  What do YOU want?", 0.7)
	await st.vn_end(0.25)
	# the little gull has no answer
	await st.cut(func():
		st.cam_set(Vector3(-5.6, 5.8, 0.6), Vector3(-9.5, 5.4, -0.8), 30.0, Vector3(-5.9, 5.75, 0.3), Vector3(-9.5, 5.4, -0.8), 28.0, 8.0))
	st.sfx("?", 0.34, 0.3, -8.0, Color("FFFFFF"), 90.0, 1.2)
	await _you_say("...")
	await st.vn_end(0.25)
	# it looks away at the sea... and then at the cafe below
	var t0 = GS.msec()
	var y0 = pl.yaw
	var y1 = atan2(0.2, -1.0)
	st.cam_set(Vector3(-12.8, 6.0, 2.6), Vector3(-8.0, 5.5, -1.0), 38.0, Vector3(-12.2, 5.95, 2.2), Vector3(-8.6, 5.45, -0.6), 36.0, 4.0)
	while (GS.msec() - t0) < 2600:
		var u = clamp((GS.msec() - t0) / 1800.0, 0.0, 1.0)
		pl.yaw = lerp_angle(y0, y1, u * u * (3.0 - 2.0 * u))
		pl.aim_yaw = pl.yaw
		await get_tree().process_frame
	st.sfx("sniff sniff", 0.28, 0.7, -5.0, Color("FFE9B0"), 40.0, 1.8)
	await st.wait(0.4)
	# from up here the cafe is small and far; the table, the old man, a warm morning. Nothing is pointed at.
	await st.cut(func():
		pl.yaw = atan2(0.2, -1.0)
		st.cam_set(Vector3(-7.3, 5.95, 1.4), Vector3(-9.0, 3.2, 3.2), 40.0, Vector3(-7.7, 5.9, 1.0), Vector3(-9.0, 2.6, 3.4), 36.0, 14.0))
	await st.caption("SOMETHING BELOW SMELLS WARM.")
	# the last thing of the opening: hold E (a stray key does nothing)
	await st.hold_to("TO FLY", 0.9)
	m.start_after_opening()

# ------------------------------------------------------------------ ENDING (round 8)
# The plain fry is eaten where it has been lying all along. While it is chewed the gull remembers - only what it really did, in the order it did it - and the last
# memory is the sound the fry made when the old man dropped it. Then the big brother comes down from his roof, asks the question again, the old man drops one more
# fry (the same little "tk.") and the gull answers for the first time in words. Nothing is explained.
const MEM_TEXT = {
	"fry1": ["THE FIRST FRY", "the first fry. i shook so much i nearly dropped it.", "fry"],
	"coffee": ["A COFFEE", "coffee. my heart did a little drum solo.", "coffee"],
	"alcohol": ["A COCKTAIL", "a cocktail. the clouds were giggling at me.", "alcohol"],
	"ice": ["ICE CREAM", "ice cream. cold, sweet, extremely questionable.", "ice"],
	"starlight": ["STARLIGHT", "the afternoon i could see the wind.", "starlight"],
	"cloud": ["A CLOUD", "i wore a whole cloud. it was softer than i expected.", "cloud"],
	"sun": ["THE SUN", "i held the sun. it was so warm.", "sun"],
	"skybow": ["A RAINBOW", "i flew right through a rainbow. it tasted of every colour.", "skybow"],
	"meteor": ["A FALLING STAR", "a star fell. my beak was full, so i couldn't wish.", "meteor"],
	"friend": ["A FRIEND", "somebody landed next to me, just to say hello.", "friend"],
	"gift": ["A GIFT", "a stranger gave me a fry for no reason at all.", "gift"],
	"kid": ["A KIND CHILD", "a child with a heart over its head fed me.", "kid"],
	"rainbow": ["A RAINBOW FRY", "a fry the colour of everything.", "rainbow"],
	"thermal": ["UP", "a warm wind carried me all the way up, for free.", "thermal"],
	"skim": ["SKIMMING", "i flew so low the sea tickled my feet.", "skim"],
	"wall": ["A WALL", "i met a wall. we agreed not to talk about it.", "wall"],
	"armed": ["A FINE WARDROBE", "i owned more hats than a gull should.", "armed"],
	"all24": ["EVERYTHING", "every kind of magic there was. i had it.", "all24"],
}
const MEM_PRIORITY = ["sun", "skybow", "meteor", "cloud", "starlight", "bigfish", "fish", "all24", "coffee", "alcohol", "ice", "friend", "gift", "rainbow", "kid", "thermal", "wall", "skim", "armed"]

func _fish_mem(id):
	var best = null
	var best_kg = -1.0
	for sp in GS.fish_book:
		var e = GS.fish_book[sp]
		if e["kg"] > best_kg:
			best_kg = e["kg"]
			best = sp
	if best == null:
		return null
	var d = GS.FISH_SPECIES[best]
	var nm = String(d[0]).to_lower()
	var col = Color(d[6])
	if id == "bigfish":
		return ["THE BIG ONE", "the %s. %s. nobody on the pier believed me." % [nm, GS.fish_cm_text(GS.fish_book[best]["cm"])], "bigfish", col]
	var f = GS.memories.get("fish", {})
	var sp1 = f.get("sp", best)
	var d1 = GS.FISH_SPECIES.get(sp1, d)
	var n1 = String(d1[0]).to_lower()
	var art = "an" if n1.substr(0, 1) in ["a", "e", "i", "o", "u"] else "a"
	return ["A FISH", "%s %s. the wettest thing i had ever held." % [art, n1], "fish", Color(d1[6])]

# what this gull remembers, chronologically, at most 8 (and the first fry always)
func _collect_memories():
	var ids = []
	for k in GS.memories:
		if k == "fish" or MEM_TEXT.has(k):
			ids.append(k)
	if GS.fish_book.size() > 1:
		var heavy = false
		for sp in GS.fish_book:
			if GS.FISH_SPECIES[sp][1] >= 1 and sp != GS.memories.get("fish", {}).get("sp", ""):
				heavy = true
		if heavy and not ids.has("bigfish"):
			ids.append("bigfish")
			GS.memories["bigfish"] = {"t": GS.memories.get("fish", {}).get("t", 0.0) + 1.0}
	var keep = []
	for k in MEM_PRIORITY:
		if ids.has(k) and keep.size() < 7:
			keep.append(k)
	keep.append("fry1")
	keep.sort_custom(func(a, b): return GS.memories.get(a, {"t": 0.0})["t"] < GS.memories.get(b, {"t": 0.0})["t"])
	var out = []
	for k in keep:
		if k == "fish" or k == "bigfish":
			var fm = _fish_mem(k)
			if fm != null:
				out.append(fm)
		elif MEM_TEXT.has(k):
			var m = MEM_TEXT[k]
			out.append([m[0], m[1], m[2], Color.WHITE])
	return out

func _chew(pl, n = 3):
	for i in n:
		var tw = pl.create_tween()
		tw.tween_property(pl.gull, "head_lunge", 0.08, 0.1)
		tw.tween_property(pl.gull, "head_lunge", 0.0, 0.25)
		Sfx.play("crunch", -9.0, 1.0 + 0.08 * i)
		await st.wait(0.5)

func _new_plain_fry(pos):
	var f = Node3D.new()
	f.set_script(preload("res://scripts/fries/fry.gd"))
	main.add_child(f)
	f.setup("PLAIN_%d" % GS.msec(), "ordinary", "none")
	for g in ["fries", "special_fries", "star_fries"]:
		if f.is_in_group(g):
			f.remove_from_group(g)
	f.global_position = pos
	return f

func _fly_bro_to(land, secs = 2.8):
	var b = main.bro
	b.look_at_player = false
	b.pose_mode = "throttle"
	var from = b.global_position
	var t0 = GS.msec()
	var dirv = land - from
	var yaw = atan2(-dirv.x, -dirv.z)
	while true:
		var u = clamp((GS.msec() - t0) / 1000.0 / secs, 0.0, 1.0)
		var e = u * u * (3.0 - 2.0 * u)
		var pos = from.lerp(land, e)
		pos.y += sin(e * PI) * 1.4
		b.global_position = pos
		b.rotation.y = lerp_angle(b.rotation.y, yaw, 0.12)
		if u >= 1.0:
			break
		await get_tree().process_frame
	b.pose_mode = "ground"
	Sfx.play("land", -9.0, 0.8)

func ending(fry):
	var m = main
	st = m.story
	var pl = m.player
	var WB = preload("res://scripts/world/world_builder.gd")
	cine_busy = true
	m.get_tree().paused = false
	pl.input_locked = true
	pl.scripted_move = true
	pl.throttling = false
	pl.mode = 1
	pl.velocity = Vector3.ZERO
	pl.speed = 0.0
	m.hud.visible = false
	m._close_sense_if_open()
	var fp = WB.ORDINARY_POS
	var spot = Vector3(-8.5, fp.y + 0.42, 5.0)            # open floor in front of the table: the gull steps out of the corner for the last scene
	pl.global_position = spot
	var el = m.elder
	pl.yaw = atan2(-1.0, 0.0)                              # facing east: the camera sees its face, the old man and his table behind it
	pl.aim_yaw = pl.yaw
	pl.rotation = Vector3(0, pl.yaw, 0)
	for grp in ["ambient", "npcs"]:
		for n in m.get_tree().get_nodes_in_group(grp):
			if n != el and is_instance_valid(n) and n.global_position.distance_to(spot) < 12.0:
				n.set_meta("cine_hidden", true)
				n.visible = false
	for dg in m.get_tree().get_nodes_in_group("dogs"):
		if dg.global_position.distance_to(spot) < 8.0:
			dg.visible = false
	st.begin(pl)
	st.frame = 0.0
	st.cam = null
	Engine.time_scale = 0.35
	Sfx.muffle(false, 0.1)
	# --- the bite: the same low corner that the opening looked at
	_ground_shot(pl.gull, {"az": 55, "spread": 30, "h": -0.02, "fov": 30, "size": 0.40, "push": 0.08, "look_h": 0.0}, 9.0, pl.yaw)
	await st.bars_in(1.2)
	await st.wait(0.4)
	await st.narrate("...oh.")
	await st.wait(0.3)
	_chew(pl, 3)
	await st.wait(0.7)
	if is_instance_valid(fry):
		fry.consume()
	await st.wait(0.9)
	Sfx.play_theme("theme_mem", true, -9.0)
	await st.narrate("salt.")
	await st.narrate("warm.")
	await st.wait(0.4)
	await st.narrate("...that's it?")
	await st.wait(0.5)
	await st.narrate("...that's it.")
	# --- what the gull remembers
	var mems = _collect_memories()
	var k = 0
	for mm in mems:
		var left = (k % 2 == 0)
		st.card(mm[2], mm[0], 4.2, 0.2 if left else 0.8, 0.47, -5.0 if left else 4.0, {"col": mm[3]})
		_ground_shot(pl.gull, {"az": 28.0 + 34.0 * (k % 4), "spread": 40, "h": 0.06, "fov": 36, "size": 0.30, "side": 1.0 if left else -1.0, "push": 0.06}, 5.2, pl.yaw)
		await st.narrate(mm[1])
		k += 1
	# the last card is the fry that began it all, and the sound it made
	st.card("plain", "A FRY ON THE FLOOR", 5.0, 0.2 if k % 2 == 0 else 0.8, 0.47, -3.0)
	Sfx.play("drop_tick", -9.0, 1.0)
	_ground_shot(pl.gull, {"az": 40, "spread": 40, "h": 0.05, "fov": 34, "size": 0.34, "side": 1.0, "push": 0.1}, 6.0, pl.yaw)
	await st.narrate("i heard it fall, that first morning. i didn't know it was for me.")
	await st.wait(0.4)
	await st.narrate("everything was warm. the sun, the star... this was warm too.")
	await st.wait(0.6)
	orbit_id += 1
	await st.bars_out(1.0)
	# --- the big brother comes down from his roof
	Engine.time_scale = 1.0
	st.frame_in(0.8)
	var b = m.bro
	var land = Vector3(-6.9, fp.y + 0.2, 5.1)
	st.cam_set(Vector3(-7.8, 2.0, 11.2), Vector3(-7.7, 1.1, 5.0), 40.0, Vector3(-7.8, 1.7, 10.4), Vector3(-7.7, 0.95, 5.0), 38.0, 9.0)
	await st.wait(0.8)
	Sfx.crossfade_theme("theme_end", false, -8.0, 3.0)       # the memories melt into the Largo as he lands (it climbs to its high note at "...just some fries.")
	await _fly_bro_to(land, 3.0)
	b._face(spot, 1.0)
	await st.wait(0.5)
	st.cam_set(Vector3(-7.7, 1.3, 11.0), Vector3(-7.7, 0.4, 5.0), 34.0, Vector3(-7.7, 1.2, 10.2), Vector3(-7.7, 0.4, 5.0), 32.0, 10.0)
	await _bro_say("...word is, you found the thing you wanted.", 0.7, {"dist": 1.05, "yaw": 0.5, "up": 0.07, "fov": 34.0})
	await _bro_say("I've been up on that roof, thinking about it.", 0.7)
	await _bro_say("Chain. Shades. Hat. Coat.  I got everything.", 0.7)
	await _bro_say("So why am I still hungry?", 0.75, {"dist": 1.0, "yaw": 0.42, "up": 0.04, "fov": 34.0, "roll": 0.05})
	await st.vn_end(0.3)
	# --- the old man, who has been there all along, drops another one
	el.look_at_pos(el.global_position + Vector3(0, 0, 8), 2.0)
	var f2 = _new_plain_fry(Vector3(0, -5, 0))
	var drop_at = Vector3(-7.7, fp.y, 5.0)
	await _old_man_drops(f2, drop_at, false)
	st.cam_set(drop_at + Vector3(0.9, 0.7, 1.5), drop_at + Vector3(0, 0.1, 0), 26.0, drop_at + Vector3(0.8, 0.65, 1.4), drop_at + Vector3(0, 0.12, 0), 24.0, 6.0, 0.003)
	await st.wait(1.2)
	st.cam_set(Vector3(-7.7, 1.3, 11.0), Vector3(-7.7, 0.4, 5.0), 34.0, Vector3(-7.7, 1.2, 10.2), Vector3(-7.7, 0.4, 5.0), 32.0, 10.0)
	await _bro_say("...What do YOU want?", 0.7)
	await _you_say("...just some fries.", 1.4, {"dist": 0.85, "yaw": -0.4, "up": 0.02, "fov": 32.0})
	await st.vn_end(0.3)
	# --- he takes his shades off and eats
	_ground_shot(b.gull, {"az": 45, "spread": 40, "h": 0.05, "fov": 34, "size": 0.42, "push": 0.08, "side": -1.0}, 8.0, b.global_rotation.y)
	b.gull.unwear("shades")
	Sfx.play("equip", -8.0, 0.6)
	await st.wait(1.0)
	var bt = b.gull.create_tween()
	bt.tween_property(b.gull, "head_lunge", 0.1, 0.12)
	bt.tween_property(b.gull, "head_lunge", 0.0, 0.3)
	Sfx.play("crunch", -9.0, 0.9)
	if is_instance_valid(f2):
		f2.consume()
	await st.wait(1.4)
	await _bro_say("...same.", 0.8, {"dist": 1.0, "yaw": 0.35, "up": 0.05, "fov": 32.0})
	await st.vn_end(0.3)
	# --- one more, for the road
	var f3 = _new_plain_fry(Vector3(0, -5, 0))
	el.rig.set_mode("wave")
	await _old_man_drops(f3, Vector3(-7.7, fp.y, 5.5), false)
	await st.wait(0.8)
	await _bro_say("...keep them coming.", 0.8, {"dist": 1.0, "yaw": 0.35, "up": 0.05, "fov": 32.0})
	await st.vn_end(0.3)
	await st.wait(0.3)
	# --- pull back: a gull, a gull, an old man and a plain morning
	st.cam_set(Vector3(-7.8, 1.5, 8.6), Vector3(-7.8, 0.8, 4.8), 38.0, Vector3(-7.4, 3.4, 15.0), Vector3(-7.8, 1.2, 4.6), 46.0, 14.0, 0.004)
	await st.wait(3.2)
	await st.frame_out(0.8)
	await st.fade_black(1.0, 1.6)
	el.rig.set_mode("idle")
	Engine.time_scale = 1.0
	cine_busy = false
	m.title.finished.connect(func(): m.title.play_credits(), CONNECT_ONE_SHOT)
	m.title.play_ending()
	await get_tree().create_timer(2.2, true, false, true).timeout
	st.finish()

# ------------------------------------------------------------------ the big brother, on his roof (round 8): three short talks, each the first time the gull sits next to him
func bro_chat(id):
	var m = main
	st = m.story
	var pl = m.player
	cine_busy = true
	pl.input_locked = true
	m.hud.visible = false
	m._close_sense_if_open()
	var b = m.bro
	b.look_at_player = false
	b._face(pl.global_position, 1.0)
	st.begin(pl)
	st.frame = 0.0
	var mid = (pl.global_position + b.global_position) * 0.5 + Vector3(0, 0.45, 0)
	var line = (b.global_position - pl.global_position)
	line.y = 0.0
	var sep = max(line.length(), 1.0)
	line = line.normalized()
	orbit_id += 1
	cc().shoot(st, mid, sep + 3.2, atan2(-line.x, -line.z), {"size": 0.62, "fov": 36, "az": 90, "spread": 70, "h": 0.1, "push": 0.07, "third": false, "look_h": 0.2, "lift": 0.14}, 14.0, 0.004)
	await st.wait(0.5)
	match id:
		"chat1":
			await _bro_say("Hm. Three fries in. You've got a beak for this.")
			await _bro_say("Go on. Get strong.  Then get stronger.")
		"chat2":
			await _bro_say("Fast now, aren't you.")
			await _bro_say("I was fast once. Then I got a hat.")
			await _bro_say("...Hats are heavy.", 0.8)
		"chat3":
			await _bro_say("...You're starting to look like me.", 0.75)
			await _bro_say("That's not a compliment. It's not an insult either.")
			await _bro_say("Come and find me when you're full.", 0.8)
	await st.vn_end(0.25)
	b.look_at_player = true
	pl.input_locked = false
	pl.set_override(Transform3D.IDENTITY, 60.0, 0.0, 5.0)
	m.hud.visible = true
	st.finish()
	cine_busy = false

# ------------------------------------------------------------------ THE CINEMATIC MOMENTS (round 9)
# Two sizes, and the player's attention is treated as something to soothe, not to interrupt:
#   * LIGHT film mode (hud.quiet_moment): the gull keeps flying, one to four lines appear in the middle of the picture. First coffee / cocktail / ice cream, the
#     first fish, a cloud, the fish book. Their words live in QUIET below.
#   * REAL cinematic moments (this file): letterbox bars, slow time, the gull's thought typed under the picture, its own music - and a real camera
#     (ui/cine_cam.gd: shots are asked for by size and background, never by metres). Each one lasts 10-20 seconds, only once per run:
#     drinks3 (STARLIGHT for the first time), meteor, sun, skybow (the rainbow), all24 (every kind of fry).
const QUIET = {
	"drink_coffee": ["coffee. oh. oh no. oh yes.", "everything is brighter, and a little slower.", "even the rings look easier to catch."],
	"drink_alcohol": ["a cocktail. it tastes like a sunset somebody left in the sun.", "i don't think flying tires me out anymore.", "my aim, though, is... artistic."],
	"drink_ice": ["ice cream. so cold it hurts. so sweet i don't care.", "nothing could hurt me right now. nothing would dare.", "also, weirdly, i'm faster. brain freeze is speed."],
}

func quiet_lines(id, extra = {}):
	if QUIET.has(id):
		return QUIET[id]
	if id == "fish":
		var sp = GS.FISH_SPECIES.get(extra.get("sp", "sardine"), GS.FISH_SPECIES["sardine"])
		var nm = String(sp[0]).to_lower()
		var art = "an" if nm.substr(0, 1) in ["a", "e", "i", "o", "u"] else "a"
		var l = ["a fish. not a fry. but still.", "%s %s. %s, %s." % [art, nm, GS.fish_cm_text(extra.get("len", 20.0)), GS.fish_kg_text(extra.get("kg", 0.1))]]
		if sp[1] == 1:
			l.append("a good one, i think. the sea does not hand those out.")
		elif sp[1] == 2:
			l.append("that was HUGE. everyone on the pier definitely saw that.")
		else:
			l.append("it wriggled with real conviction.")
		l.append("...okay. back you go. thank you for your service.")
		return l
	return []

func cc():
	if cam_dir == null:
		cam_dir = CineCam.new(main)
	return cam_dir

# the player's gull, filmed in the air (wings out): `o` is a CineCam.plan option set
func _fly_shot(o, dur):
	orbit_id += 1
	return cc().gull_shot(st, main.player.gull, o, dur, true, 0.1, main.player.yaw)

# a gull on the ground / a roof
func _ground_shot(g, o, dur, yaw = null):
	orbit_id += 1
	return cc().gull_shot(st, g, o, dur, false, 0.4, yaw)

func _later(sec, fn):
	get_tree().create_timer(sec, true, false, true).timeout.connect(fn)

func _cine_begin(music, tag_text, flap = true):
	var m = main
	st = m.story
	var pl = m.player
	cine_busy = true
	m.get_tree().paused = false
	m._close_sense_if_open()
	st.begin(pl)
	st.frame = 0.0
	pl.input_locked = true
	pl.scripted_move = true
	pl.throttling = flap
	m.hud.visible = false
	Engine.time_scale = 0.22
	Sfx.muffle(false, 0.1)
	Sfx.cine_music(music)
	await st.bars_in(0.9)
	st.set_tag(tag_text, 3.4)

func _cine_end():
	var m = main
	var pl = m.player
	orbit_id += 1
	await st.bars_out(0.8)
	Sfx.cine_music_end(2.2)
	Engine.time_scale = 1.0
	pl.scripted_move = false
	pl.throttling = false
	pl.input_locked = false
	pl.set_override(Transform3D.IDENTITY, 60.0, 0.0, 5.0)
	m.hud.visible = true
	st.finish()
	if is_instance_valid(GS.cine_hold):
		GS.cine_hold.queue_free()
	GS.cine_hold = null
	cine_busy = false
	cine_done_at = GS.msec()

func cinema(id, extra = {}):
	match id:
		"drinks3":
			await _cine_drinks3()
		"meteor":
			await _cine_meteor()
		"sun":
			await _cine_sun()
		"skybow":
			await _cine_skybow()
		"all24":
			await _cine_all24()

# ---- ALL THREE DRINKS AT ONCE: STARLIGHT for the first time. Excited, brand new, a little silly. ~17 s.
func _cine_drinks3():
	var m = main
	var pl = m.player
	await _cine_begin("cine_joy", "ALL THREE AT ONCE")
	var gp = pl.global_position
	# 1: the gull from the front, three-quarter view, the whole bird with the sea behind it; the three drinks go off one after the other
	_fly_shot({"az": 32, "spread": 60, "h": 0.04, "fov": 42, "size": 0.30, "push": 0.07}, 6.0)
	m._burst(gp, GS.BUFF_COL["coffee"], 46, 5.0)
	st.sfx("BZZZT!", 0.7, 0.3, 7.0, Color("E8B27A"), 56.0, 1.3)
	Sfx.play("buff_coffee", -6.0)
	_later(1.1, func():
		m._burst(gp, GS.BUFF_COL["alcohol"], 46, 5.0)
		st.sfx("FIZZ!", 0.3, 0.3, -7.0, Color("FFE27A"), 56.0, 1.3)
		Sfx.play("buff_alcohol", -6.0))
	_later(2.1, func():
		m._burst(gp, GS.BUFF_COL["ice"], 46, 5.0)
		st.sfx("chill~", 0.7, 0.72, 5.0, Color("FFB6E8"), 46.0, 1.3)
		Sfx.play("buff_ice", -6.0))
	await st.narrate("coffee. cocktail. ice cream. all at once.")
	# 2: from below, the sky behind it: the world turns rainbow
	_fly_shot({"az": 20, "spread": 30, "h": -0.34, "fov": 52, "size": 0.26, "push": 0.0, "look_h": 0.25}, 5.0)
	Sfx.play("star_riser", -6.0)
	st.flash = 0.5
	st.flash_col = Color(1, 0.95, 0.85)
	await st.narrate("wait. hold on. i can SEE the wind.")
	m._burst(gp + Vector3(0, 0.4, 0), Color(1, 0.9, 0.7), 80, 7.0)
	# 3: wide, from behind and above: the gull small against the island
	_fly_shot({"az": 150, "spread": 40, "h": 0.1, "fov": 54, "size": 0.2, "push": 0.1}, 5.0)
	await st.narrate("it's mostly blue. a little pink near the edges.")
	# 4: and the last beat, face to face
	_fly_shot({"az": 8, "spread": 24, "h": 0.03, "fov": 36, "size": 0.34, "push": 0.1}, 5.0)
	await st.narrate("okay. okay okay okay. i'm going to go very fast now.")
	st.sfx("WHEEEEEE!", 0.5, 0.34, -5.0, Color("FFF3A0"), 76.0, 1.6)
	st.slam("", 0.5, 0.5, 10.0, Color.WHITE, 0.0, 0.5, true)
	st.flash = 0.7
	pl.fov_kick = 12.0
	Sfx.play("star_on", -3.0)
	Sfx.cine_music_end(1.4)
	await st.wait(0.6)
	if GS.star_active():
		Sfx.set_star(true)                # the STARLIGHT piece takes over (no riser: the cinematic had its own)
	await st.wait(0.3)
	await _cine_end()

# ---- THE FIRST SHOOTING STAR. ~16 s
func _cine_meteor():
	var m = main
	var pl = m.player
	await _cine_begin("cine_wish", "A FALLING STAR", false)
	_fly_shot({"az": 24, "spread": 40, "h": 0.04, "fov": 34, "size": 0.34, "push": 0.08, "look_h": 0.12}, 5.5)
	await st.narrate("it was falling. so i caught it.")
	await st.narrate("it's warm. and it hums.")
	_fly_shot({"az": 100, "spread": 40, "h": 0.1, "fov": 40, "size": 0.30, "push": 0.06}, 5.0)
	await st.narrate("everybody says: make a wish. but my beak is full.")
	# the star slips out of the beak... and decides to stay: it settles behind the gull and trails a tail of light
	var s = GS.cine_hold
	if is_instance_valid(s):
		s.reparent(m, true)
		s.carried = true
		s.tail.visible = false
		var tw = s.create_tween().set_parallel(true)
		tw.tween_property(s, "global_position", pl.global_position + Vector3(0, 0.25, 0) + Vector3(sin(pl.yaw), 0, cos(pl.yaw)) * 0.45, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(s, "scale", Vector3(0.35, 0.35, 0.35), 1.1)
		tw.chain().tween_callback(s.queue_free)
		Sfx.play("meteor_get", -6.0, 1.1)
		GS.cine_hold = null
	await st.wait(0.6)
	pl.gull.wear("meteor")
	st.flash = 0.45
	st.flash_col = Color(1.0, 0.95, 0.8)
	m._burst(pl.global_position, Color(1.0, 0.92, 0.65), 70, 6.0)
	Sfx.play("star_on", -6.0, 1.2)
	_fly_shot({"az": 160, "spread": 30, "h": 0.3, "fov": 46, "size": 0.22, "push": 0.1}, 6.0)
	await st.narrate("...oh. it's staying.")
	await st.narrate("i have a tail now. a very, very good tail.")
	await _cine_end()

# ---- THE SUN. A short film with the same three lines that used to be the whole moment. ~12 s
func _cine_sun():
	var m = main
	var pl = m.player
	await _cine_begin("cine_home", "THE SUN", false)
	pl.throttling = false
	_fly_shot({"az": 18, "spread": 30, "h": -0.16, "fov": 44, "size": 0.30, "push": 0.08, "look_h": 0.2}, 5.0)
	st.flash = 0.6
	st.flash_col = Color(1.0, 0.9, 0.6)
	m._burst(pl.global_position + Vector3(0, 0.5, 0), Color(1.0, 0.82, 0.35), 70, 6.0)
	await st.narrate("i caught the sun.")
	_fly_shot({"az": 96, "spread": 40, "h": 0.08, "fov": 40, "size": 0.28, "push": 0.07}, 4.5)
	await st.narrate("it was warm. something in me changed.")
	_fly_shot({"az": 168, "spread": 40, "h": 0.4, "fov": 50, "size": 0.2, "push": 0.1}, 6.0)
	await st.wait(0.5)
	Sfx.play("growl", -9.0)
	await st.narrate("and somehow... i'm still hungry.")
	await st.wait(0.4)
	await _cine_end()

# ---- A RAINBOW IN THE SKY. ~15 s
func _cine_skybow():
	var m = main
	var pl = m.player
	await _cine_begin("cine_wish", "A WHOLE RAINBOW", false)
	pl.throttling = false
	# wide: the arch from the side with the gull small beneath it
	var focus = m.skybow_focus()
	orbit_id += 1
	var pos = focus["pos"]
	var look = focus["look"]
	st.cam_set(pos, look, 52.0, pos + (look - pos).normalized() * 6.0, look, 50.0, 6.0, 0.004)
	st.flash = 0.4
	st.flash_col = Color(1.0, 0.95, 0.9)
	await st.narrate("a rainbow. a whole one.")
	_fly_shot({"az": 28, "spread": 50, "h": 0.1, "fov": 38, "size": 0.32, "push": 0.07}, 5.5)
	m._burst(pl.global_position + Vector3(0, 0.3, 0), Color(1.0, 0.8, 0.9), 70, 6.0)
	await st.narrate("from the inside it has more colours than i thought.")
	pl.gull.wear("skybow")
	Sfx.play("star_on", -6.0, 1.3)
	_fly_shot({"az": 150, "spread": 40, "h": 0.2, "fov": 46, "size": 0.18, "push": 0.1}, 5.5)
	await st.narrate("...it's staying. a little one, right over my head.")
	await _cine_end()

# ---- ALL TWENTY-FOUR: it has every kind of magic there is, and it is still hungry. It has forgotten something. ~19 s
func _cine_all24():
	var m = main
	var pl = m.player
	await _cine_begin("cine_home", "TWENTY-FOUR", false)
	pl.throttling = false
	_fly_shot({"az": 38, "spread": 50, "h": 0.06, "fov": 40, "size": 0.30, "push": 0.07}, 6.0)
	await st.narrate("faster than the wind. stronger than the tide.")
	_fly_shot({"az": 104, "spread": 50, "h": 0.3, "fov": 50, "size": 0.2, "push": 0.08}, 5.5)
	await st.narrate("everything this island had to give, i have.")
	await st.narrate("so why does it still...")
	Sfx.play("growl", -6.0)
	st.sfx("grrrmmbl...", 0.7, 0.3, 4.0, Color("D7B27A"), 40.0, 2.2)
	await st.wait(0.4)
	await st.narrate("...rumble?")
	# the camera rises away from the gull and looks back over the town, slowly, to where the morning began
	var gp = pl.global_position
	orbit_id += 1
	var back = Vector3(-9.0, 5.0, 4.0)
	var away = (gp - back)
	away.y = 0.0
	away = away.normalized() if away.length() > 1.0 else Vector3(0, 0, 1)
	var d = CineCam.dist_for(cc().gull_width(pl.gull, true), 0.26, 40.0)
	st.cam_set(gp + away * d + Vector3(0, 0.7, 0), gp, 40.0, gp + away * d * 2.6 + Vector3(0, 7.0, 0), gp.lerp(back, 0.5), 48.0, 11.0, 0.002)
	await st.narrate("i'm forgetting something small. something warm.")
	await st.wait(0.2)
	await _cine_end()
