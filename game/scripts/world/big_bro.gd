extends Node3D
# THE BIG BROTHER: a very cool gull who has everything (gold chain, shades, a pipe, a top hat, a long coat) and is still hungry.
# He asks the player's gull what it wants in the opening, waits on the cafe roof for the whole game, and asks again in the ending.
# Purely a visual with a few little lines; nothing about him ever matters for the flight or the fries.

const GullVisual = preload("res://scripts/player/gull_visual.gd")

var gull
var player = null
var bubble = null
var bubble_t = 0.0
var line_cd = 25.0
var near_t = 0.0
var t = 0.0
var look_at_player = true
var puff_t = 4.0
var main = null
var scripted_talk = false      # the ending: the line is part of the scene, whatever the distance
var pose_mode = "ground"      # "throttle" while he flies down to the cafe in the ending

const EARLY = ["Chin up, kid. The wind's free.", "Fly like the sea owes you rent.", "Careful. The old man's watching. Or sleeping. Hard to tell.", "Nice landing. I'd give it a 7. I'm a tough crowd."]
const MID = ["Still hungry. Still fabulous.", "Everything's shinier. Nothing's tastier.", "I'd say don't copy me. But look at that hat.", "The view's great up here. The menu isn't."]
const LATE = ["...you too?", "The sky's full of things. Nothing's quite it.", "Hungry suits you. Don't tell anyone I said so.", "You've got the squint now. Welcome."]
const OUTFIT = ["topper", "shades", "necklace", "pipe", "coat"]

func setup(p_player, pos, face_pos):
	player = p_player
	gull = Node3D.new()
	gull.set_script(GullVisual)
	gull.plain = true
	gull.bro_style = true
	add_child(gull)
	gull.build()
	gull.scale = Vector3.ONE * 2.3          # round 12: clearly the biggest gull on the island (the player's gull is the yardstick)
	for k in OUTFIT:
		gull.wear(k, true)
	global_position = pos
	_face(face_pos, 1.0)
	gull.pose("ground", 0.0, false, 0.5)
	bubble = Label3D.new()
	bubble.font_size = 70
	bubble.pixel_size = 0.008
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.no_depth_test = true
	bubble.modulate = Color(1, 0.95, 0.8, 0.0)
	bubble.outline_size = 14
	bubble.position = Vector3(0, 2.4, 0)
	bubble.render_priority = 120          # round 10: always above the sea / horizon haze
	bubble.outline_render_priority = 119
	bubble.sorting_offset = 50.0
	bubble.visible = false              # it exists only while he is talking (the outline of an invisible label used to stay)
	add_child(bubble)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

func _face(target, k = 0.15):
	var d = target - global_position
	d.y = 0.0
	if d.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(-d.x, -d.z), k)

func speak(text, sec = 3.0):
	bubble.text = text
	bubble_t = sec
	bubble.visible = true

func _process(delta):
	t += delta
	if gull == null:
		return
	gull.pose(pose_mode, 0.0, pose_mode == "throttle", delta)
	# idle life: a slow head turn, now and then a puff on the pipe
	gull.head.rotation.y = sin(t * 0.4) * 0.35
	gull.head.rotation.x = sin(t * 0.23) * 0.06
	if bubble_t > 0.0:
		bubble_t -= delta
		var ba = clamp(min(bubble_t, 0.6) / 0.6, 0.0, 1.0) * 0.95
		bubble.modulate.a = ba
		bubble.outline_modulate = Color(0.05, 0.04, 0.07, ba)
		# only for someone who is close (never a line floating over a far-away roof)
		if not scripted_talk and player != null and global_position.distance_to(player.global_position) > 14.0:
			bubble_t = 0.0
	else:
		bubble.modulate.a = 0.0
		bubble.visible = false
	if player == null or not player.active:
		return
	var d = global_position.distance_to(player.global_position)
	if d < 40.0 and look_at_player:
		_face(player.global_position, 0.04)
	# a hint, now and then, when the gull comes close: the big brother knows where this is going
	line_cd = max(line_cd - delta, 0.0)
	near_t = near_t + delta if d < 7.0 else 0.0
	# a little talk the first time the gull sits next to him after three / ten / eighteen fries (round 8: he is part of the story, not a prop)
	if near_t > 1.0 and player.mode == 1 and main != null and not main.autotest and not GS.showcase_active and not main.scenes.cine_busy and GS.gull_sense_count >= 3 and not GS.ordinary_eaten:
		var n0 = GS.fry_total()
		var cid = ""
		if n0 >= 18 and not GS.cine_seen.has("chat3"):
			cid = "chat3"
		elif n0 >= 10 and not GS.cine_seen.has("chat2"):
			cid = "chat2"
		elif n0 >= 3 and not GS.cine_seen.has("chat1"):
			cid = "chat1"
		if cid != "":
			GS.cine_seen[cid] = true
			main.scenes.bro_chat(cid)
			return
	if near_t > 1.2 and line_cd <= 0.0 and not GS.ordinary_eaten and player.mode == 1 and GS.gull_sense_count >= 3:
		line_cd = 40.0
		var n = GS.fry_total()
		var pool = EARLY if n < 10 else (MID if n < 20 else LATE)
		speak(pool[randi() % pool.size()], 3.8)
