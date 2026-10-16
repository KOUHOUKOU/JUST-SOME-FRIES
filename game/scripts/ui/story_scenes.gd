extends Node
# The story scenes, written as comic panels + a visual-novel box (see story.gd for the lettering, the portraits and the film mode):
#   opening()   establishing panels, the old man's cafe (a small close-up: one fry slips from his fingers and just lies there), the hungry gull, the
#               big brother's speech in a visual-novel box with his name and his face, then "HOLD E TO FLY"
#   ending()    the flight home, the question, the silence, JUST... (the finery falls away) ...SOME... FRIES.  The big brother takes his shades off.
#   cinema(id)  the four cinematic moments of the game, in film mode (letterbox bars, the gull's own thoughts under the picture, slow time, its own music):
#               drinks3 (STARLIGHT for the first time), fish (the first catch), meteor (the first shooting star), all24 (every fry, and still...)
# The director's notes live in docs/26_ROUND7_CHANGES.md and docs/28_ROUND8_CHANGES.md.

const CineCam = preload("res://scripts/ui/cine_cam.gd")
const BroTalks = preload("res://scripts/ui/bro_talks.gd")
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
	# --- round 16: the big brother and the little gull talk in the four panels of the old comic (a tribute: where are we headed? / some fries on the pier / the big picture /
	# "i still feel like it has something to do with the fries on the pier"). The page draws itself; the game picture comes back under it, the little gull looking at the sea.
	if m.yk != null and not m.autotest:
		await st.cut(func():
			m.bro.visible = true
			st.set_art("")
			st.cam_set(Vector3(-14.2, 6.0, 2.6), Vector3(-11.4, 5.5, -1.0), 38.0, Vector3(-13.6, 5.95, 2.2), Vector3(-11.8, 5.45, -0.6), 36.0, 14.0))
		await m.yk.play_comic_open()
	else:
		# --- the big brother (a visual-novel box with his name and his face)
		await st.cut(func():
			m.bro.visible = true
			st.set_art("")
			st.cam_set(Vector3(-8.8, 6.6, 6.9), Vector3(-8.3, 5.7, -1.0), 43.0, Vector3(-8.3, 6.5, 6.3), Vector3(-8.3, 5.7, -1.0), 41.0, 16.0))
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
			st.cam_set(Vector3(-8.8, 6.3, 2.0), Vector3(-5.9, 5.9, -1.3), 34.0, Vector3(-8.3, 6.2, 1.6), Vector3(-5.9, 5.9, -1.3), 32.0, 9.0))
		await _bro_say("...and I'm still hungry.", 0.8, {"dist": 1.0, "yaw": 0.4, "up": 0.04, "fov": 34.0, "roll": 0.05})
		await _bro_say("So.  What do YOU want?", 0.7)
		await st.vn_end(0.25)
		# the little gull has no answer
		await st.cut(func():
			st.cam_set(Vector3(-6.9, 5.9, 1.9), Vector3(-11.4, 5.4, -0.8), 28.0, Vector3(-7.3, 5.85, 1.6), Vector3(-11.4, 5.4, -0.8), 26.0, 8.0))
		st.sfx("?", 0.34, 0.3, -8.0, Color("FFFFFF"), 90.0, 1.2)
		await _you_say("...")
		await st.vn_end(0.25)
	# it looks away at the sea... and then at the cafe below
	var t0 = GS.msec()
	var y0 = pl.yaw
	var y1 = atan2(0.2, -1.0)
	st.cam_set(Vector3(-14.2, 6.0, 2.6), Vector3(-11.4, 5.5, -1.0), 38.0, Vector3(-13.6, 5.95, 2.2), Vector3(-11.8, 5.45, -0.6), 36.0, 4.0)
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
	"starlight": ["RAINBOW TIME", "the afternoon i could see the wind.", "starlight"],
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
	"moon": ["THE MOON", "i held the moon. no cheese. a surprising amount of mouse.", "moon"],
	"raincloud": ["A RAIN CLOUD", "i carried my own weather. it only rained on me.", "raincloud"],
	"fishtime": ["OCEAN TIME", "the sea gave me a ride. i gave it a fish.", "fishtime"],
}
const MEM_PRIORITY = ["sun", "moon", "skybow", "meteor", "cloud", "raincloud", "starlight", "fishtime", "bigfish", "fish", "all24", "coffee", "alcohol", "ice", "friend", "gift", "rainbow", "kid", "thermal", "wall", "skim", "armed"]

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
				fm.append("fish")
				out.append(fm)
		elif MEM_TEXT.has(k):
			var m = MEM_TEXT[k]
			out.append([m[0], m[1], m[2], Color.WHITE, k])
	return out

func _chew(pl, n = 3):
	# round 16: it is the best fry of its life, and the comic lettering says so (each bite gets its own word, a little more blissful than the last)
	var words = [["CHOMP!", 0.30, 0.30, -7.0, Color("FFE27A")], ["NOM NOM!", 0.66, 0.36, 6.0, Color("FFB6A0")], ["MMMMF.", 0.40, 0.52, -4.0, Color("FFF1C8")]]
	for i in n:
		var tw = pl.create_tween()
		tw.tween_property(pl.gull, "head_lunge", 0.08, 0.1)
		tw.tween_property(pl.gull, "head_lunge", 0.0, 0.25)
		Sfx.play("crunch", -9.0, 1.0 + 0.08 * i)
		var w = words[i % words.size()]
		st.sfx(w[0], w[1], w[2], w[3], w[4], 56.0 + 8.0 * i, 0.9)
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

# people near the two gulls, and whoever could stroll through the picture between the camera (at the boardwalk) and the gulls, are hidden for the scene
func _clear_picture(spot, el):
	for grp in ["ambient", "npcs"]:
		for n in main.get_tree().get_nodes_in_group(grp):
			if n == el or not is_instance_valid(n):
				continue
			var np_ = n.global_position
			if np_.distance_to(spot) < 12.0 or (np_.x > spot.x - 8.0 and np_.x < spot.x + 12.0 and np_.z > spot.z and np_.z < 17.0):
				n.set_meta("cine_hidden", true)
				n.visible = false

func _keep_picture_clear(spot, el):
	while cine_busy and is_instance_valid(main):
		await get_tree().create_timer(0.25, true, false, true).timeout
		_clear_picture(spot, el)

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
	var spot = Vector3(-9.2, fp.y + 0.42, 5.0)            # open floor in front of the table: the gull steps out of the corner for the last scene (3.7 m from where the 2.3x big brother lands)
	pl.global_position = spot
	var el = m.elder
	pl.yaw = atan2(-1.0, 0.0)                              # facing east: the camera sees its face, the old man and his table behind it
	pl.aim_yaw = pl.yaw
	pl.rotation = Vector3(0, pl.yaw, 0)
	_clear_picture(spot, el)
	_keep_picture_clear(spot, el)                                # (and again every moment: whoever strolls into the picture later is cleared too)
	for dg in m.get_tree().get_nodes_in_group("dogs"):
		if dg.global_position.distance_to(spot) < 8.0:
			dg.visible = false
	st.begin(pl)
	st.ff_ok = true                       # round 20: HOLD E fast-forwards the talk of the ending
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
		# round 16: the gull stands in the MIDDLE of the picture, and every memory is a little film of the real moment (the frames the game kept), on the left or the right
		var ex = {"col": mm[3]}
		if m.reel != null and mm.size() > 4:
			var rl = m.reel.reel(mm[4])
			if rl.size() >= 3:
				ex["reel"] = rl
		st.card(mm[2], mm[0], 3.9, 0.19 if left else 0.81, 0.47, -5.0 if left else 4.0, ex)
		if k % 2 == 0:
			_ground_shot(pl.gull, {"az": 28.0 + 34.0 * (k % 4), "spread": 40, "h": 0.06, "fov": 36, "size": 0.30, "side": 0.0, "push": 0.06}, 5.0, pl.yaw)
		await st.wait(1.8)
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
	# --- ROUND 15, the last part. The old man drops one more. The little gull does not eat it: it takes it up to the roof, to the one who has everything and is still hungry.
	# Everything below happens on ONE flat roof, side-on: both gulls on the same line, the same plane, nothing between the camera and their faces.
	Engine.time_scale = 1.0
	st.frame_in(0.8)
	var b = m.bro
	b.look_at_player = false
	b.calm_head = true
	var drop_at = Vector3(-8.0, fp.y, 4.3)
	st.cam_set(Vector3(-4.6, 1.3, 9.8), Vector3(-8.2, 0.8, 4.3), 36.0, Vector3(-5.0, 1.2, 9.2), Vector3(-8.2, 0.8, 4.3), 34.0, 8.0)
	await st.wait(0.4)
	var f2 = _new_plain_fry(Vector3(0, -5, 0))
	await _old_man_drops(f2, drop_at, false)
	await st.caption("he dropped another one.", 1.8)
	f2.attach(pl.beak_socket)
	Sfx.play("snatch", -8.0, 1.3)
	await st.wait(0.35)
	await st.caption("i know who is still hungry.", 1.8)
	# the flight up to the roof: filmed from the street, a smooth arc, the fry in its beak
	var roof_y = _roof_y(-8.9, -1.3)
	var land = Vector3(-8.9, roof_y + 0.38, -1.3)
	var from = pl.global_position
	pl.mode = 0
	pl.speed = 7.0
	pl.throttling = true
	var t0 = GS.msec()
	var dur = 3.4
	st.cam_set(Vector3(-13.0, 2.0, 9.5), Vector3(-9.0, 3.2, 1.8), 42.0, Vector3(-12.0, 4.4, 8.0), Vector3(-8.9, roof_y + 0.6, -1.0), 38.0, dur + 0.4)
	b._face(Vector3(-30.0, 0.0, -1.3), 1.0)
	while true:
		var u = clamp((GS.msec() - t0) / 1000.0 / dur, 0.0, 1.0)
		var e = u * u * (3.0 - 2.0 * u)
		var pos = from.lerp(land, e)
		pos.y += sin(e * PI) * 1.8
		var dirv = land - from
		dirv.y = 0.0
		pl.global_position = pos
		pl.yaw = lerp_angle(pl.yaw, atan2(-dirv.x, -dirv.z), 0.1)
		pl.rotation = Vector3(-0.12 * sin(e * PI), pl.yaw, 0.0)
		if u >= 1.0:
			break
		await get_tree().process_frame
	pl.throttling = false
	pl.mode = 1
	pl.speed = 0.0
	var yaw_e = atan2(-1.0, 0.0)               # facing east, to the big brother
	pl.global_position = land
	pl.yaw = yaw_e
	pl.aim_yaw = yaw_e
	pl.rotation = Vector3(0, yaw_e, 0)
	Sfx.play("land", -8.0)
	# the two of them on one line, facing each other, 3.1 m apart, in the same plane of the picture
	b.global_position = Vector3(-5.8, roof_y + 0.92, -1.3)
	b.rotation = Vector3(0, atan2(1.0, 0.0), 0)       # facing west
	b.pose_mode = "ground"
	var side = Vector3(-7.35, roof_y + 1.6, 6.4)
	var tgt = Vector3(-7.35, roof_y + 1.05, -1.3)
	st.cam_set(side, tgt, 33.0, side + Vector3(0.25, 0.0, -0.5), tgt, 31.5, 22.0, 0.004)
	await st.wait(1.0)
	# round 20, the roof. He starts short and cool (he is the one who has everything); he is moved by something small and does not say so. Never explained.
	await _bro_say("...That's a lot of hats, kid.", 0.7, {"dist": 1.05, "yaw": 0.5, "up": 0.07, "fov": 34.0})
	await _bro_say("I'd know.", 0.75, {"dist": 1.0, "yaw": 0.42, "up": 0.04, "fov": 34.0, "roll": 0.05})
	await st.vn_end(0.3)
	# the little gull puts the fry down between them
	var mid_spot = Vector3(-7.35, roof_y + 0.04, -1.3)
	f2.reparent(m, true)
	var tw = create_tween()
	tw.tween_property(f2, "global_position", mid_spot + Vector3(0, 0.5, 0), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(f2, "global_position", mid_spot, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(f2, "rotation", Vector3.ZERO, 0.6)
	f2.scale = Vector3.ONE
	await st.wait(0.7)
	Sfx.play("drop_tick", -9.0, 1.0)
	await st.wait(0.9)
	var close_b = {"dist": 1.0, "yaw": 0.35, "up": 0.05, "fov": 32.0}
	var close_y = {"dist": 0.85, "yaw": -0.4, "up": 0.02, "fov": 32.0}
	await _bro_say("...What's that.", 0.7)
	await _you_say("...it's just a fry.", 1.4, close_y)
	await _bro_say("It doesn't glow.", 0.72)
	await _bro_say("It doesn't make you fast.", 0.72)
	await _bro_say("...It doesn't do anything.", 0.78, close_b)
	await _you_say("...just some fries.", 1.4, close_y)
	await st.vn_end(0.3)
	# everything the little gull wore falls away: it never needed any of it
	if not pl.gull.worn.is_empty():
		m._burst(pl.global_position + Vector3(0, 0.5, 0), Color(1.0, 0.9, 0.6), 60, 4.0)
		pl.gull.reset_plain()
		Sfx.play("equip", -6.0, 0.6)
		Sfx.play("whoosh", -9.0, 1.4)
		await st.wait(1.0)
	# his answer to the question he asked at the start (and the last word of the comic)
	_ground_shot(b.gull, {"az": 40, "spread": 36, "h": 0.04, "fov": 33, "size": 0.27, "push": 0.07, "side": -1.0}, 8.0, b.global_rotation.y)
	await st.wait(0.9)
	await _bro_say("...same.", 0.8, {"dist": 1.0, "yaw": 0.35, "up": 0.05, "fov": 32.0})
	await st.wait(0.5)
	await _bro_say("Mine took years to put on.", 0.75)
	await _bro_say("I never tried the other direction.", 0.75)
	await st.vn_end(0.3)
	# the shades come off: his eyes, for the first time
	await st.wait(0.5)
	b.gull.unwear("shades")
	Sfx.play("equip", -8.0, 0.6)
	await st.wait(1.1)
	await _bro_say("...It's the colour I remembered.", 0.8, close_b)
	await _bro_say("You carried it all the way up here.", 0.75)
	await _bro_say("...It's still warm.", 0.8)
	await st.vn_end(0.3)
	# he eats it, slowly
	var bt = b.gull.create_tween()
	bt.tween_property(b.gull, "head_lunge", 0.1, 0.12)
	bt.tween_property(b.gull, "head_lunge", 0.0, 0.3)
	Sfx.play("crunch", -9.0, 0.9)
	await st.wait(0.35)
	if is_instance_valid(f2):
		f2.consume()
	await st.wait(1.6)
	await _bro_say("...Oh.", 0.8, close_b)
	await _bro_say("Salt.", 0.8)
	await _bro_say("I'd forgotten it was this small.", 0.75)
	await _you_say("...yeah.", 1.4, close_y)
	await st.vn_end(0.3)
	# both turn to the sea and sit there: the old man waves from far below, the sun goes down on a town that was always plain
	var t1 = GS.msec()
	var yaw_s = PI
	var camp = Vector3(-7.35, roof_y + 2.5, -9.0)
	st.cam_set(camp, Vector3(-7.35, roof_y + 1.2, 6.0), 36.0, camp + Vector3(0.6, 0.6, 0.0), Vector3(-7.35, roof_y + 1.5, 6.0), 40.0, 26.0, 0.004)
	while GS.msec() - t1 < 1600:
		pl.yaw = lerp_angle(pl.yaw, yaw_s, 0.08)
		pl.aim_yaw = pl.yaw
		pl.rotation = Vector3(0, pl.yaw, 0)
		b.rotation.y = lerp_angle(b.rotation.y, yaw_s, 0.08)
		await get_tree().process_frame
	el.rig.set_mode("wave")
	Sfx.set_surf(true, -27.0, 4.0)          # round 20: the calm sea under the last quiet minute
	await st.wait(1.2)
	# the chain: the one thing he lets go of (nobody asks him to), and the hat that he keeps
	b.gull.unwear("necklace")
	Sfx.play("equip", -10.0, 0.6)
	await st.caption("he took off the chain. nobody asked him to.", 2.4)
	await _bro_say("I'm keeping the hat.", 0.75)
	await _you_say("...good hat.", 1.4)
	await _bro_say("...It is a good hat.", 0.75)
	await st.vn_end(0.3)
	await st.wait(1.0)
	await _bro_say("That old man. Does he still drop them?", 0.72)
	await _you_say("...every morning.", 1.4)
	Sfx.play("drop_tick", -22.0, 0.8)           # far below: tk.
	await st.wait(0.9)
	await _bro_say("...Good.", 0.8)
	await st.vn_end(0.4)
	await st.wait(0.8)
	await st.caption("nothing shiny. nothing fast.", 2.0)
	await st.caption("just a fry, and somebody to eat it with.", 2.8)
	await st.wait(0.6)
	await st.frame_out(0.8)
	Sfx.set_surf(false, 0.0, 5.0)
	# round 16: the last picture of the game is the fourth panel of the strip it came from: the game turns into the comic
	if m.yk != null and not m.autotest:
		var last = await m.yk.grab()
		await m.yk.play_ending(last)
		await st.fade_black(1.0, 0.05)
		m.yk.release()
	else:
		await st.fade_black(1.0, 1.6)
	el.rig.set_mode("idle")
	Engine.time_scale = 1.0
	cine_busy = false
	m.title.finished.connect(func(): m.title.play_credits(), CONNECT_ONE_SHOT)
	m.title.play_ending()
	await get_tree().create_timer(2.2, true, false, true).timeout
	st.finish()

# the height of the roof under (x, z): a ray from above (the little gull and the big brother both stand on it)
func _roof_y(x, z):
	var space = main.get_world_3d().direct_space_state
	var q = PhysicsRayQueryParameters3D.create(Vector3(x, 14.0, z), Vector3(x, 0.0, z), 1)
	var hit = space.intersect_ray(q)
	return hit["position"].y if not hit.is_empty() else 4.84

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
	# he is 2.3 times a gull: if the little gull landed right beside him, it steps west along the roof so the two never overlap in the picture
	var gap = pl.global_position - b.global_position
	gap.y = 0.0
	if gap.length() < 4.0:
		var np = b.global_position + Vector3(-4.2, 0.0, 0.0)
		np.y = pl.global_position.y
		np.z = clamp(pl.global_position.z, -4.6, 0.0)
		pl.global_position = np
		pl.velocity = Vector3.ZERO
		pl.yaw = atan2(-1.0, 0.0)               # facing east, towards him
		pl.aim_yaw = pl.yaw
		pl.rotation = Vector3(0, pl.yaw, 0)
	b._face(pl.global_position, 1.0)
	st.begin(pl)
	st.frame = 0.0
	var mid =(pl.global_position + b.global_position) * 0.5 + Vector3(0, 0.45, 0)
	var line = (b.global_position - pl.global_position)
	line.y = 0.0
	var sep = max(line.length(), 1.0)
	line = line.normalized()
	orbit_id += 1
	cc().shoot(st, mid, sep + 3.2, atan2(-line.x, -line.z), {"size": 0.62, "fov": 36, "az": 90, "spread": 70, "h": 0.1, "push": 0.07, "third": false, "look_h": 0.2, "lift": 0.14}, 14.0, 0.004)
	await st.wait(0.5)
	# round 20: one TALK per visit (ui/bro_talks.gd): "talk" = the first key talk the gull has earned and not heard yet, else a small talk that fits how far it has come
	var lines = []
	if id == "talk":
		id = BroTalks.next_talk(b)
		if id != "":
			GS.cine_seen[id] = true
	if id == "" or id == "free" or id == "talk":
		lines = BroTalks.small_talk()
	else:
		lines = BroTalks.lines(id)
	for ln in lines:
		if ln.begins_with("Y|"):
			await _you_say(ln.substr(2), 1.4)
		else:
			await _bro_say(ln, 0.72)
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
	"quest_cloud": ["FLUFF!", Color("DDEBFF"), ["i caught a cloud.", "it was softer than i expected, and a little shy.", "and somehow i'm still hungry."],
		{"rot": -5.0, "shake": 0.3, "pitch": 1.1, "pos": Vector2(0.64, 0.34), "size": 130.0, "life": 2.2}],
	"quest_sky": ["WHOOSH!", Color("BFE3FF"), ["the whole sky, in one beak.", "it was softer, warmer and louder than i expected.", "and somehow i'm still hungry."],
		{"rot": -5.0, "shake": 0.3, "pitch": 1.1, "pos": Vector2(0.64, 0.34), "size": 130.0, "life": 2.2}],
	"quest_fishbook": ["GULP.", Color("7FC3E4"), ["the whole sea, written down.", "every one of them wetter than i expected.", "and somehow i'm still hungry."],
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
		"raincloud":
			await _cine_raincloud()
		"moon":
			await _cine_moon()
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
	_word("RAINBOW TIME", 0.5, 0.34, 96.0, Color("FFF6D8"), -3.0, Color("C27BEA"))
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
		"moon":
			var mcore = MeshInstance3D.new()
			var msm = SphereMesh.new()
			msm.radius = 0.2
			msm.height = 0.4
			mcore.mesh = msm
			var mmat = StandardMaterial3D.new()
			mmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mmat.albedo_color = Color(0.86, 0.92, 1.0)
			mcore.material_override = mmat
			mcore.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n.add_child(mcore)
			n.add_child(fx.billboard(1.2, GV.soft_tex(), Color(0.6, 0.8, 1.0, 0.45)))
		"raincloud":
			var rmat = StandardMaterial3D.new()
			rmat.albedo_color = Color(0.55, 0.6, 0.72, 0.95)
			rmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			for c in [[0, 0, 0, 0.17], [0.16, -0.02, 0.02, 0.12], [-0.16, -0.03, 0.0, 0.12], [0.07, 0.08, 0, 0.11], [-0.08, 0.07, 0, 0.1]]:
				var rmi = MeshInstance3D.new()
				var rsp = SphereMesh.new()
				rsp.radius = c[3]
				rsp.height = c[3] * 2.0
				rmi.mesh = rsp
				rmi.material_override = rmat
				rmi.position = Vector3(c[0], c[1], c[2])
				rmi.scale = Vector3(1.1, 0.85, 1.0)
				rmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				n.add_child(rmi)
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

# ---- THE THINGS OF THE SKY (round 16: the words and the white space again; no little pictures, nothing in the middle of the view). The gull keeps flying, the world softens,
# thin bars close in, one hand-lettered word on a starburst, and the gull's own thoughts typed in the empty middle, the last one slow. ~10 s each.
const SKY_FLOW = {
	"cloud": {"tag": "A CLOUD", "music": "cine_wish", "word": "FLUFF!", "col": Color("FFFFFF"), "star": Color("8EC8F0"), "prop": "cloud",
		"lines": ["i caught a cloud.", "it was softer than i expected, and a little shy, like it had never been held.", "it left a bit of morning on my feathers.", "and somehow i'm still hungry."]},
	"raincloud": {"tag": "A RAIN CLOUD", "music": "cine_wish", "word": "DRIP.", "col": Color("DDE6F5"), "star": Color("7F93B8"), "prop": "raincloud",
		"lines": ["i caught a rain cloud.", "it only rains on me, which feels a little personal.", "somebody has to be rained on. i volunteered.", "and somehow i'm still hungry."]},
	"moon": {"tag": "THE MOON", "music": "cine_wish", "word": "HUSH.", "col": Color("EAF2FF"), "star": Color("5C78C8"), "prop": "moon",
		"lines": ["i caught the moon.", "no cheese. just something very large and very quiet.", "i wanted to tell someone. the whole island was asleep.", "and somehow i'm still hungry."]},
	"sun": {"tag": "THE SUN", "music": "cine_sun", "word": "FWOOM!", "col": Color("FFF6D8"), "star": Color("FFA62B"), "prop": "sun",
		"lines": ["i caught the sun.", "it was warm in a way that went all the way through.", "for a moment the whole world turned gold, and so did my beak.", "and somehow i'm still hungry."]},
	"skybow": {"tag": "A WHOLE RAINBOW", "music": "cine_wish", "word": "TA-DAA!", "col": Color("FFFFFF"), "star": Color("FF8FC4"), "prop": "skybow",
		"lines": ["i caught a rainbow.", "from the inside it has more colours than anyone told me.", "it doesn't taste of anything. it tastes of leaving.", "and somehow i'm still hungry."]},
	"meteor": {"tag": "A FALLING STAR", "music": "cine_wish", "word": "ZING!", "col": Color("FFF3B0"), "star": Color("F2B830"), "prop": "meteor",
		"lines": ["it was falling, so i caught it.", "everybody says you should make a wish.", "my beak was full.", "it would have been fries again, wouldn't it."]},
}

func _cine_sky(kind):
	var m = main
	var pl = m.player
	var d = SKY_FLOW[kind]
	await _flow_begin(d["music"], d["tag"])
	var wn = pl.gull.worn.get(kind if kind != "meteor" else "meteor")
	if kind in ["cloud", "raincloud", "sun", "moon", "skybow"] and wn != null and is_instance_valid(wn):
		wn.visible = false
	if kind == "meteor":
		var s = GS.cine_hold
		if is_instance_valid(s):
			s.queue_free()
		GS.cine_hold = null
	var prop = _prop_in(d["prop"])
	st.flash = 0.45
	st.flash_col = Color(1.0, 0.95, 0.85)
	_word(d["word"], 0.5, 0.18, 74.0, d["col"], -4.0, d["star"])
	Sfx.play("meteor_get", -8.0, 0.9 if kind in ["moon", "raincloud"] else 1.1)
	await st.think(d["lines"], 1.05, 38.0, 2.3,
		func():
			st.clear_words(0.3)
			st.flow_pace(0.24, 1.2))
	_prop_out(prop, pl.gull.global_position + Vector3(0, 0.7, 0.1))
	if kind == "meteor":
		if not GS.worn.has("meteor"):
			pl.gull.wear("meteor")
		Sfx.play("star_on", -6.0, 1.2)
		m._burst(pl.global_position, Color(1.0, 0.92, 0.65), 70, 6.0)
	await st.wait(0.7)
	if wn != null and is_instance_valid(wn):
		wn.visible = true
	await _flow_end()

func _cine_cloud():
	await _cine_sky("cloud")

func _cine_raincloud():
	await _cine_sky("raincloud")

func _cine_moon():
	await _cine_sky("moon")

func _cine_meteor():
	await _cine_sky("meteor")

func _cine_sun():
	await _cine_sky("sun")

func _cine_skybow():
	await _cine_sky("skybow")

# ---- ALL TWENTY-FOUR: every kind of magic there is, and the path leads... where? The slowest of them. Only words and white space. ~14 s
func _cine_all24():
	var m = main
	await _flow_begin("cine_home", "TWENTY-FOUR")
	_word("24 / 24", 0.5, 0.19, 88.0, Color("FFFFFF"), -4.0, Color("F2B830"))
	await st.think(["faster than the wind. stronger than the tide.", "everything this island had to give, i have.", "so where does the path end?"], 1.1, 38.0, 2.0,
		func():
			st.clear_words(0.4)
			st.flow_pace(0.2, 1.4))
	await st.wait(0.4)
	Sfx.play("growl", -6.0)
	st.sfx("grrrmmbl...", 0.7, 0.5, 4.0, Color("D7B27A"), 44.0, 2.4)
	await _t("...why does it still rumble?", 2.0)
	await _t("i think it has something to do with the fries.", 2.5)
	await _flow_end()
