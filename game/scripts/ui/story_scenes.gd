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

# what this gull remembers, chronologically, at most 5 (the four strongest, and the first fry always)
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
		if ids.has(k) and keep.size() < 4:
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
	await st.bars_in(1.0)
	await st.wait(0.3)
	await st.narrate("...oh.")
	await st.wait(0.2)
	_chew(pl, 3)
	await st.wait(0.6)
	if is_instance_valid(fry):
		fry.consume()
	await st.wait(0.7)
	Sfx.play_theme("theme_mem", true, -9.0)
	await st.narrate("salt.")
	await st.narrate("warm.")
	await st.wait(0.5)
	# --- what the gull remembers
	var mems = _collect_memories()
	var k = 0
	for mm in mems:
		var left = (k % 2 == 0)
		st.card(mm[2], mm[0], 3.6, 0.2 if left else 0.8, 0.47, -5.0 if left else 4.0, {"col": mm[3]})
		if k % 2 == 0:
			_ground_shot(pl.gull, {"az": 28.0 + 34.0 * (k % 4), "spread": 40, "h": 0.06, "fov": 36, "size": 0.30, "side": 1.0 if left else -1.0, "push": 0.06}, 5.0, pl.yaw)
		await st.wait(1.7)
		k += 1
	# the last card is the fry that began it all, and the sound it made
	st.card("plain", "A FRY ON THE FLOOR", 4.2, 0.2 if k % 2 == 0 else 0.8, 0.47, -3.0)
	Sfx.play("drop_tick", -9.0, 1.0)
	_ground_shot(pl.gull, {"az": 40, "spread": 40, "h": 0.05, "fov": 34, "size": 0.34, "side": 1.0, "push": 0.1}, 5.0, pl.yaw)
	await st.wait(1.4)
	await st.narrate("it fell right at my feet.")
	await st.wait(0.4)
	orbit_id += 1
	await st.bars_out(1.0)
	# --- the big brother comes down from his roof
	Engine.time_scale = 1.0
	st.frame_in(0.8)
	var b = m.bro
	var land = Vector3(-6.9, fp.y + 0.2, 5.1)
	st.cam_set(Vector3(-7.8, 2.4, 14.6), Vector3(-7.7, 1.3, 5.0), 40.0, Vector3(-7.8, 2.0, 13.8), Vector3(-7.7, 0.95, 5.0), 38.0, 9.0)
	await st.wait(0.8)
	Sfx.crossfade_theme("theme_end", false, -8.0, 3.0)       # the memories melt into the Largo as he lands (it climbs to its high note at "...just some fries.")
	var largo_t0 = GS.msec()
	await _fly_bro_to(land, 3.0)
	b._face(spot, 1.0)
	await st.wait(0.5)
	st.cam_set(Vector3(-7.7, 1.8, 14.2), Vector3(-7.7, 0.8, 5.0), 34.0, Vector3(-7.7, 1.7, 13.4), Vector3(-7.7, 0.8, 5.0), 32.0, 10.0)
	await _bro_say("Word on the roof is you found it. The thing.", 0.7, {"dist": 1.05, "yaw": 0.5, "up": 0.07, "fov": 34.0})
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
	st.cam_set(Vector3(-7.7, 1.8, 14.2), Vector3(-7.7, 0.8, 5.0), 34.0, Vector3(-7.7, 1.7, 13.4), Vector3(-7.7, 0.8, 5.0), 32.0, 10.0)
	await _bro_say("...What do YOU want?", 0.7)
	print("[ENDING] 'just some fries' typed %.1f s after the Largo starts" % ((GS.msec() - largo_t0) / 1000.0))
	await _you_say("...just some fries.", 1.4, {"dist": 0.85, "yaw": -0.4, "up": 0.02, "fov": 32.0})
	await st.vn_end(0.3)
	# --- he takes his shades off and eats
	_ground_shot(b.gull, {"az": 45, "spread": 40, "h": 0.05, "fov": 34, "size": 0.26, "push": 0.08, "side": -1.0}, 8.0, b.global_rotation.y)
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
	print("[ENDING] '...same.' %.1f s after the Largo starts" % ((GS.msec() - largo_t0) / 1000.0))
	await _bro_say("...same.", 0.8, {"dist": 1.0, "yaw": 0.35, "up": 0.05, "fov": 32.0})
	await st.vn_end(0.3)
	el.rig.set_mode("wave")
	await st.wait(0.2)
	# --- pull back: a gull, a gull, an old man and a plain morning
	st.cam_set(Vector3(-7.8, 1.9, 10.8), Vector3(-7.8, 1.0, 4.8), 38.0, Vector3(-7.4, 3.6, 17.0), Vector3(-7.8, 1.2, 4.6), 46.0, 12.0, 0.004)
	await st.wait(3.0)
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
			await _bro_say("Saw you land. Three fries, and not one of them dropped.")
			await _bro_say("That's either talent or a very sleepy old man.")
			await _bro_say("Fast beats strong. Strong beats loud.  Go make the sky nervous.", 0.7)
		"chat2":
			await _bro_say("Ten fries. I can hear the sound barrier clearing its throat.")
			await _bro_say("I was fast like that once. Then I discovered accessories.")
			await _bro_say("...Hats are heavier than they look. So is wanting things.", 0.8)
		"chat3":
			await _bro_say("Eighteen. You're starting to look like me. Same squint. Same hunger.", 0.75)
			await _bro_say("Funny thing about having everything: it needs a lot of room. In here.")
			await _bro_say("Come find me when you've eaten the lot. I'll be here. Cool, and slightly peckish.", 0.8)
	await st.vn_end(0.25)
	b.look_at_player = true
	pl.input_locked = false
	pl.set_override(Transform3D.IDENTITY, 60.0, 0.0, 5.0)
	m.hud.visible = true
	st.finish()
	cine_busy = false

# ------------------------------------------------------------------ THE CINEMATIC MOMENTS (round 10: short, 4-9 seconds, each with a face of its own)
# The player's attention is something to soothe, not to interrupt: gulls collect these things one after another, so
#   * BEATS (st.beat, below): a splash of the thing's colour, ONE hand-lettered word, one or two lines of the gull's thoughts in a yellow caption box. 4-7 s.
#     The gull keeps flying; nothing is locked or slowed. First coffee / cocktail / ice cream, the first fish, a cloud, the fish book.
#   * FILM moments: letterbox bars, slow time, a real camera (ui/cine_cam.gd), a piece of music of their own, a word slammed on the picture. 8-9 s at most.
#     drinks3 (STARLIGHT), meteor, sun, skybow (the rainbow), all24. Each plays once per run.
var beat_busy = false
var beat_queue = []

# word, colour, lines, options (see story.gd `beat`)
const BEATS = {
	"drink_coffee": ["BZZZT!", Color("D99A5B"), ["coffee. my heart just learned drums.", "even the rings look slower. i look... less slow."],
		{"rot": -8.0, "shake": 0.8, "pitch": 1.3, "sfx": "buff_coffee", "pos": Vector2(0.66, 0.33),
		"extra": [["tk-tk-tk-tk", 0.8, 0.5, 5.0, Color("F1D6B0"), 34.0, 1.8]]}],
	"drink_alcohol": ["GLUG~", Color("FFD23A"), ["a cocktail. the clouds are giggling.", "no more tired wings. my aim is... artistic."],
		{"rot": 7.0, "shake": 0.2, "pitch": 0.8, "sfx": "buff_alcohol", "pos": Vector2(0.64, 0.34),
		"extra": [["hic!", 0.84, 0.5, -9.0, Color("FFF3A0"), 40.0, 1.6]]}],
	"drink_ice": ["BRRR!", Color("FF8AD8"), ["ice cream. so cold it hurts. so sweet i don't care.", "nothing can hurt me. brain freeze is just speed."],
		{"rot": -4.0, "shake": 0.9, "pitch": 1.6, "sfx": "buff_ice", "pos": Vector2(0.64, 0.34),
		"extra": [["*shiver*", 0.84, 0.5, 6.0, Color("CFF3E4"), 32.0, 1.8]]}],
	"quest_cloud": ["FLUFF!", Color("DDEBFF"), ["i caught a cloud.", "it was softer than i expected.", "and somehow... i'm still hungry."],
		{"rot": -5.0, "shake": 0.3, "pitch": 1.1, "pos": Vector2(0.64, 0.34), "size": 130.0, "life": 2.2}],
	"quest_fishbook": ["GULP.", Color("7FC3E4"), ["the whole sea, written down.", "every one of them wetter than i expected.", "and somehow... i'm still hungry."],
		{"rot": 4.0, "shake": 0.3, "pitch": 0.9, "pos": Vector2(0.64, 0.34), "size": 130.0, "life": 2.2}],
}

func beat_lines(id, extra):
	if id == "fish":
		var sp = GS.FISH_SPECIES.get(extra.get("sp", "sardine"), GS.FISH_SPECIES["sardine"])
		var nm = String(sp[0]).to_lower()
		var art = "an" if nm.substr(0, 1) in ["a", "e", "i", "o", "u"] else "a"
		var l = ["%s %s. %s, %s." % [art, nm, GS.fish_cm_text(extra.get("len", 20.0)), GS.fish_kg_text(extra.get("kg", 0.1))]]
		if sp[1] == 1:
			l.append("a good one. the sea does not hand those out.")
		elif sp[1] == 2:
			l.append("HUGE. the whole pier saw that. definitely.")
		else:
			l.append("not a fry. but it wriggled with real conviction.")
		return l
	return BEATS[id][2]

func has_beat(id):
	return id == "fish" or BEATS.has(id)

# the fish is the only beat whose colour and word depend on what was caught
func beat_moment(id, extra = {}):
	if beat_busy or cine_busy:
		beat_queue.append([id, extra])
		return
	beat_busy = true
	var m = main
	var word = "SPLASH!"
	var col = Color("7FC3E4")
	var o = {"rot": -6.0, "pitch": 1.0, "pos": Vector2(0.64, 0.34), "sfx": "chime"}
	if id == "fish":
		var rar = GS.FISH_SPECIES.get(extra.get("sp", "sardine"), GS.FISH_SPECIES["sardine"])[1]
		col = GS.FISH_RARITY_COLORS[rar]
		if rar == 2:
			word = "WHOA!!"
			o["size"] = 140.0
		elif rar == 1:
			word = "OOH!"
		o["extra"] = [["~ blub ~", 0.84, 0.5, 6.0, Color("D9F6FF"), 32.0, 1.8]]
	else:
		var b = BEATS[id]
		word = b[0]
		col = b[1]
		o = b[3].duplicate()
	var lines = beat_lines(id, extra)
	st = m.story
	var tw = m.hud.create_tween().set_ignore_time_scale(true)
	tw.tween_property(m.hud.ui_root, "modulate:a", 0.0, 0.25)
	m._burst(m.player.global_position + Vector3(0, 0.3, 0), col, 36, 4.0)
	m.player.fov_kick = 5.0
	await st.beat(word, col, lines, o)
	Sfx.schedule_growl(0.2)
	var tw2 = m.hud.create_tween().set_ignore_time_scale(true)
	tw2.tween_property(m.hud.ui_root, "modulate:a", 1.0, 0.4)
	await tw2.finished
	beat_busy = false
	cine_done_at = GS.msec()
	if not beat_queue.is_empty():
		var nx = beat_queue.pop_front()
		beat_moment(nx[0], nx[1])

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
	await st.bars_in(0.5)
	st.set_tag(tag_text, 2.4)

func _cine_end():
	var m = main
	var pl = m.player
	orbit_id += 1
	st.clear_words(0.3)
	await st.bars_out(0.5)
	Sfx.cine_music_end(1.4)
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
	if not beat_queue.is_empty():
		var nx = beat_queue.pop_front()
		beat_moment(nx[0], nx[1])

# ---- THE FILM MOMENTS (round 10, "flow"): the gull never stops flying. The world slows and softens, thin bars close in, other angles of the gull open as small
# comic panels (insets), and the gull's thoughts are typed under the picture, a little slower on the last line, which is where the thinking is. ~11-13 s each.
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
		"cloud":
			await _cine_cloud()
		"all24":
			await _cine_all24()

func _flow_begin(music, tag_text):
	var m = main
	st = m.story
	cine_busy = true
	m.get_tree().paused = false
	m._close_sense_if_open()
	st.director = cc()
	st.flow_begin(m.player, tag_text)
	var tw = m.hud.create_tween().set_ignore_time_scale(true)
	tw.tween_property(m.hud.ui_root, "modulate:a", 0.0, 0.4)
	Sfx.cine_music(music)
	await st.wait(0.8)

func _flow_end():
	var m = main
	orbit_id += 1
	st.clear_words(0.3)
	Sfx.cine_music_end(2.0)
	var tw = m.hud.create_tween().set_ignore_time_scale(true)
	tw.tween_property(m.hud.ui_root, "modulate:a", 1.0, 0.8)
	await st.flow_end()
	if is_instance_valid(GS.cine_hold):
		GS.cine_hold.queue_free()
	GS.cine_hold = null
	cine_busy = false
	cine_done_at = GS.msec()
	if not beat_queue.is_empty():
		var nx = beat_queue.pop_front()
		beat_moment(nx[0], nx[1])

# a small comic panel with another angle of the gull. `az` is degrees from the gull's heading (0 in front, 90 its right, 180 behind)
func _panel(id, nx, ny, w, rot, tint, tag, az, size, fov, h = 0.08, look_h = 0.12, swing = 12.0, look_fwd = 0.0):
	return st.inset_open(id, {"pos": Vector2(nx, ny), "w": w, "rot": rot, "tint": tint, "tag": tag,
		"follow": {"az": az, "size": size, "fov": fov, "h": h, "look_h": look_h, "look_fwd": look_fwd, "swing": swing, "dur": 8.0}})

# a big comic word on an ink-edged starburst of its own colour
func _word(text, nx, ny, sz, col, rot, star):
	var w = st.slam(text, nx, ny, sz, col, rot, 0.6, true)
	w["star"] = star
	return w

# the gull's thought: typed at 36 characters a second, then held
func _t(text, hold = 1.5, tint = Color(1.0, 0.97, 0.88)):
	await st.narrate(text, tint, 1.5, hold, 36.0)

# ---- ALL THREE DRINKS AT ONCE: STARLIGHT for the first time. A triple hit in three little panels, a rainbow, "very fast now". ~11 s
func _cine_drinks3():
	var m = main
	var pl = m.player
	await _flow_begin("cine_joy", "ALL THREE AT ONCE")
	var gp = pl.global_position
	_panel("a", 0.15, 0.31, 0.21, -4.0, GS.BUFF_COL["coffee"], "COFFEE", 35.0, 0.36, 42.0)
	m._burst(gp, GS.BUFF_COL["coffee"], 46, 5.0)
	st.sfx("BZZZT!", 0.3, 0.42, 7.0, Color("E8B27A"), 56.0, 1.1)
	Sfx.play("buff_coffee", -6.0)
	_later(0.9, func():
		_panel("b", 0.85, 0.31, 0.21, 2.0, GS.BUFF_COL["alcohol"], "COCKTAIL", -40.0, 0.34, 40.0)
		m._burst(gp, GS.BUFF_COL["alcohol"], 46, 5.0)
		st.sfx("GLUG~", 0.7, 0.42, -7.0, Color("FFE27A"), 56.0, 1.1)
		Sfx.play("buff_alcohol", -6.0))
	_later(1.8, func():
		_panel("c", 0.15, 0.68, 0.21, 4.0, GS.BUFF_COL["ice"], "ICE CREAM", 150.0, 0.30, 44.0, 0.12)
		m._burst(gp, GS.BUFF_COL["ice"], 46, 5.0)
		st.sfx("BRRR!", 0.3, 0.6, 5.0, Color("FFB6E8"), 56.0, 1.1)
		Sfx.play("buff_ice", -6.0))
	await _t("coffee. cocktail. ice cream. all at once.", 1.3)
	for k in ["a", "b", "c"]:
		st.inset_close(k)
	Sfx.play("star_riser", -6.0)
	_word("STARLIGHT", 0.5, 0.34, 118.0, Color("FFF6D8"), -3.0, Color("C27BEA"))
	st.flash = 0.5
	st.flash_col = Color(1, 0.95, 0.85)
	m._burst(gp + Vector3(0, 0.4, 0), Color(1, 0.9, 0.7), 80, 7.0)
	_panel("d", 0.85, 0.68, 0.24, 3.0, Color("FFE9A8"), "LOOK UP", 20.0, 0.26, 52.0, -0.34, 0.25)
	await _t("wait. hold on. i can SEE the wind.", 1.6)
	st.clear_words(0.3)
	st.inset_close("d")
	st.flow_pace(0.26, 1.0)
	await _t("okay. going very fast now.", 1.1)
	st.sfx("WHEEEEEE!", 0.5, 0.32, -5.0, Color("FFF3A0"), 84.0, 1.4)
	st.flash = 0.6
	pl.fov_kick = 12.0
	Sfx.play("star_on", -3.0)
	Sfx.cine_music_end(1.4)
	await st.wait(0.7)
	if GS.star_active():
		Sfx.set_star(true)                # the STARLIGHT piece takes over (no riser: the cinematic had its own)
	await _flow_end()

# ---- THE CATCH MOMENTS (round 12): a star, a cloud, the sun, a rainbow. The thing is held in the beak again for the length of the moment, three close-ups of
# THE catch sit in the corners of the picture (front, side, from above), and the gull's own words stand in the middle: three or four lines, the last one slow.
func _make_prop(kind):
	var n = Node3D.new()
	var fx = preload("res://scripts/world/meteor_fx.gd")
	var GV = preload("res://scripts/player/gull_visual.gd")
	match kind:
		"sun":
			var core = MeshInstance3D.new()
			var sm = SphereMesh.new()
			sm.radius = 0.2
			sm.height = 0.4
			core.mesh = sm
			var mat = StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = Color(1.0, 0.82, 0.3)
			core.material_override = mat
			core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n.add_child(core)
			n.add_child(fx.billboard(1.5, GV.soft_tex(), Color(1.0, 0.75, 0.3, 0.55)))
		"cloud":
			var cmat = StandardMaterial3D.new()
			cmat.albedo_color = Color(1, 1, 1, 0.92)
			cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			for c in [[0, 0, 0, 0.17], [0.16, -0.02, 0.02, 0.12], [-0.16, -0.03, 0.0, 0.12], [0.07, 0.08, 0, 0.11], [-0.08, 0.07, 0, 0.1]]:
				var mi = MeshInstance3D.new()
				var sp = SphereMesh.new()
				sp.radius = c[3]
				sp.height = c[3] * 2.0
				mi.mesh = sp
				mi.material_override = cmat
				mi.position = Vector3(c[0], c[1], c[2])
				mi.scale = Vector3(1.1, 0.85, 1.0)
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				n.add_child(mi)
		"meteor":
			n.add_child(fx.billboard(0.62, GV.soft_tex(), Color(1.0, 0.82, 0.38, 0.4)))
			n.add_child(fx.billboard(0.42, GV.star_tex(), Color(1.0, 0.85, 0.3, 1.0)))
		"skybow":
			var rbm = MeshInstance3D.new()
			rbm.mesh = preload("res://scripts/world/rainbow_pair.gd").arc_mesh(Vector3(1, 0, 0), 0.34, 0.3, 0.045, 0.028, 16, 0.95)
			var rbmat = StandardMaterial3D.new()
			rbmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			rbmat.vertex_color_use_as_albedo = true
			rbmat.cull_mode = BaseMaterial3D.CULL_DISABLED
			rbm.material_override = rbmat
			rbm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			rbm.position = Vector3(0, -0.12, 0)
			n.add_child(rbm)
	return n

# the caught thing appears in the beak (a pop, a flash); returns the node
func _prop_in(kind):
	var pl = main.player
	var p = _make_prop(kind)
	pl.beak_socket.add_child(p)
	p.position = Vector3(0, 0.02, -0.06)
	p.scale = Vector3.ONE * 0.2
	var tw = p.create_tween()
	tw.tween_property(p, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	main._burst(pl.beak_socket.global_position, Color(1.0, 0.92, 0.7), 40, 3.5)
	return p

# ...and it goes where it belongs (the head, the tail): shrinks away
func _prop_out(p, target_pos):
	if not is_instance_valid(p):
		return
	p.reparent(main, true)
	var tw = p.create_tween().set_parallel(true)
	tw.tween_property(p, "global_position", target_pos, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(p, "scale", Vector3.ONE * 0.1, 0.9)
	tw.chain().tween_callback(p.queue_free)

# the three close-ups of the catch: front, side, from above (corners, so the middle stays for the words)
func _triptych(tag_a, tag_b, tag_c, tint):
	_panel("a", 0.15, 0.33, 0.21, -3.0, tint, tag_a, 14.0, 1.0, 30.0, 0.05, 0.08, 5.0, 0.35)
	_later(0.6, func(): _panel("b", 0.85, 0.33, 0.21, 3.0, tint, tag_b, 80.0, 1.0, 30.0, 0.05, 0.08, 5.0, 0.3))
	_later(1.2, func(): _panel("c", 0.15, 0.68, 0.21, 2.0, tint, tag_c, 150.0, 0.7, 34.0, 0.55, 0.05, 8.0, 0.2))

func _close_triptych():
	for k in ["a", "b", "c"]:
		st.inset_close(k)

# ---- A CLOUD. ~12 s
func _cine_cloud():
	var m = main
	var pl = m.player
	await _flow_begin("cine_wish", "A CLOUD")
	var wn = pl.gull.worn.get("cloud")
	if wn != null and is_instance_valid(wn):
		wn.visible = false
	var prop = _prop_in("cloud")
	_word("FLUFF!", 0.5, 0.25, 90.0, Color("FFFFFF"), -4.0, Color("8EC8F0"))
	st.flash = 0.35
	_triptych("CLOSE-UP", "SOFT", "FROM ABOVE", Color("CFE6FF"))
	await st.think(["i caught a cloud.", "it was softer than i expected.", "i think it's a little shy.", "and somehow... i'm still hungry."], 1.05, 38.0, 2.2,
		func():
			st.clear_words(0.3)
			_close_triptych()
			st.flow_pace(0.22, 1.2))
	_prop_out(prop, pl.gull.global_position + Vector3(0, 0.7, 0.1))
	await st.wait(0.9)
	if wn != null and is_instance_valid(wn):
		wn.visible = true
	await _flow_end()

# ---- THE FIRST SHOOTING STAR. It decides to stay and trails a tail. ~12 s
func _cine_meteor():
	var m = main
	var pl = m.player
	await _flow_begin("cine_wish", "A FALLING STAR")
	var s = GS.cine_hold
	if is_instance_valid(s):
		s.queue_free()
	GS.cine_hold = null
	var prop = _prop_in("meteor")
	Sfx.play("meteor_get", -6.0, 1.1)
	st.sfx("ZING!", 0.5, 0.2, 8.0, Color("FFF3B0"), 76.0, 1.4)
	_triptych("CLOSE-UP", "STILL WARM", "FROM ABOVE", Color("FFE9A8"))
	await st.think(["it was falling. so i caught it.", "everybody says: make a wish.", "my beak is full.", "...oh. it's staying. i have a tail now."], 1.0, 38.0, 2.2,
		func():
			_close_triptych()
			st.flow_pace(0.22, 1.2)
			_prop_out(prop, pl.global_position + Vector3(0, 0.25, 0) + Vector3(sin(pl.yaw), 0, cos(pl.yaw)) * 0.45)
			Sfx.play("star_on", -6.0, 1.2)
			pl.gull.wear("meteor")
			st.flash = 0.4
			st.flash_col = Color(1.0, 0.95, 0.8)
			m._burst(pl.global_position, Color(1.0, 0.92, 0.65), 70, 6.0))
	await st.wait(0.4)
	await _flow_end()

# ---- THE SUN. ~12 s
func _cine_sun():
	var m = main
	var pl = m.player
	await _flow_begin("cine_sun", "THE SUN")
	var wn = pl.gull.worn.get("sun")
	if wn != null and is_instance_valid(wn):
		wn.visible = false
	var prop = _prop_in("sun")
	st.flash = 0.6
	st.flash_col = Color(1.0, 0.9, 0.6)
	_word("FWOOM!", 0.5, 0.25, 96.0, Color("FFF6D8"), -6.0, Color("FFA62B"))
	_triptych("CLOSE-UP", "SO BRIGHT", "FROM ABOVE", Color("FFD36A"))
	await st.think(["i caught the sun.", "it was warm. something in me changed.", "everything went gold for a moment.", "and somehow... i'm still hungry."], 1.05, 38.0, 2.4,
		func():
			st.clear_words(0.3)
			_close_triptych()
			st.flow_pace(0.2, 1.4)
			Sfx.play("growl", -9.0))
	_prop_out(prop, pl.gull.global_position + Vector3(0, 0.8, 0.3))
	await st.wait(0.9)
	if wn != null and is_instance_valid(wn):
		wn.visible = true
	await _flow_end()

# ---- A RAINBOW IN THE SKY. ~12 s
func _cine_skybow():
	var m = main
	var pl = m.player
	await _flow_begin("cine_wish", "A WHOLE RAINBOW")
	var prop = _prop_in("skybow")
	st.flash = 0.4
	st.flash_col = Color(1.0, 0.95, 0.9)
	_word("TA-DAA!", 0.5, 0.25, 90.0, Color("FFFFFF"), -4.0, Color("FF8FC4"))
	_triptych("CLOSE-UP", "ALL SEVEN", "FROM ABOVE", Color("FFD0E8"))
	await st.think(["i caught a rainbow.", "from the inside it has more colours than i thought.", "i'm keeping a little one, right over my head.", "and somehow... i'm still hungry."], 1.05, 38.0, 2.2,
		func():
			st.clear_words(0.3)
			_close_triptych()
			st.flow_pace(0.22, 1.2))
	_prop_out(prop, pl.gull.global_position + Vector3(0, 0.5, -0.1))
	pl.gull.wear("skybow")
	Sfx.play("star_on", -6.0, 1.3)
	await st.wait(0.8)
	await _flow_end()

# ---- ALL TWENTY-FOUR: every kind of magic there is, and still... it rumbles. The slowest of them. ~13 s
func _cine_all24():
	var m = main
	var pl = m.player
	await _flow_begin("cine_home", "TWENTY-FOUR")
	_word("24 / 24", 0.62, 0.32, 120.0, Color("FFFFFF"), -4.0, Color("F2B830"))
	_panel("a", 0.2, 0.30, 0.26, -3.0, Color("FFE08A"), "FASTER", 38.0, 0.34, 40.0, 0.06)
	await _t("faster than the wind. stronger than the tide.", 1.8)
	st.clear_words(0.4)
	st.inset_close("a")
	_panel("b", 0.8, 0.30, 0.28, 3.0, Color("BFE6F8"), "EVERYTHING", 104.0, 0.3, 46.0, 0.2, 0.1, 20.0)
	await _t("everything this island had to give, i have.", 2.0)
	st.inset_close("b")
	# a high, wide picture: the gull small over the town, to where the morning began
	_panel("c", 0.5, 0.28, 0.36, -2.0, Color("D7B27A"), "BELOW", 200.0, 0.2, 50.0, 0.45, 0.1, 30.0)
	st.flow_pace(0.2, 1.4)
	await st.wait(0.4)
	Sfx.play("growl", -6.0)
	st.sfx("grrrmmbl...", 0.7, 0.5, 4.0, Color("D7B27A"), 44.0, 2.4)
	await _t("so why does it still... rumble?", 2.6)
	await _flow_end()
