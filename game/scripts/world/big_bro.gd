extends Node3D
# THE BIG BROTHER: a very cool gull who has everything (gold chain, shades, a pipe, a top hat, a long coat) and is still hungry.
# He asks the player's gull what it wants in the opening, waits on the cafe roof for the whole game, and asks again in the ending.
# Purely a visual with a few little lines; nothing about him ever matters for the flight or the fries.

const GullVisual = preload("res://scripts/player/gull_visual.gd")
const BroTalks = preload("res://scripts/ui/bro_talks.gd")

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
var calm_head = false          # the ending: his head stays turned to whoever he talks to
var talk_cd = 0.0
var away = true                # round 20: the gull has been away from the roof since his last talk (an automatic talk needs a new visit; E can always ask for one)
var pose_mode = "ground"      # "throttle" while he flies down to the cafe in the ending

const EARLY = ["Chin up, kid. The wind's free.", "Fly like the sea owes you rent.", "Careful. The old man's watching. Or sleeping. Hard to tell.", "Nice landing. I'd give it a 7. I'm a tough crowd."]
const MID = ["Still hungry. Still fabulous.", "Everything's shinier. Nothing's tastier.", "I'd say don't copy me. But look at that hat.", "The view's great up here. The menu isn't."]
const LATE = ["...you too?", "The sky's full of things. Nothing's quite it.", "Hungry suits you. Don't tell anyone I said so.", "You've got the squint now. Welcome.", "Where do you think we're headed, kid? ...No. Don't answer.", "Big picture: it has something to do with fries. I just can't prove it."]
const OUTFIT = ["topper", "shades", "necklace", "pipe", "coat"]

# round 15: the talk he has for the gull NOW. If the gull comes to see him late (a lot of fries already), the early talks are out of date: it hears the newest one it has
# earned and the older ones count as heard. The sky talk is its own thing (after the whole sky has been caught).
const CHATS = ["chat1", "chat2", "chat3", "chat4"]
const CHAT_AT = [3, 10, 18, 24]
func _next_chat():
	var n0 = GS.fry_total()
	var best = -1
	for i in CHATS.size():
		if n0 >= CHAT_AT[i]:
			best = i
	if best >= 0 and not GS.cine_seen.has(CHATS[best]):
		for j in best + 1:
			GS.cine_seen[CHATS[j]] = true        # (the last one is set again by the caller; the older ones are simply out of date)
		GS.cine_seen.erase(CHATS[best])
		return CHATS[best]
	return ""

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
	gull.head.rotation.y = lerp(gull.head.rotation.y, 0.0, 0.1) if calm_head else sin(t * 0.4) * 0.35
	gull.head.rotation.x = 0.0 if calm_head else sin(t * 0.23) * 0.06
	if main != null and main.scenes != null and main.scenes.cine_busy and not scripted_talk:
		bubble_t = 0.0                     # round 20: never a floating line over a talk in the visual-novel box
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
	if d > 14.0:
		away = true
	# round 16: after the end he is somebody to talk to: E next to him. Round 20: before the end too (once the gull has three fries): every press is ONE talk
	talk_cd = max(talk_cd - delta, 0.0)
	var can_talk = GS.free_play or (GS.gull_sense_count >= 3 and not GS.ordinary_eaten)
	if main != null:
		main.bro_prompt = ""
		if can_talk and d < 6.8 and near_t > 0.4 and player.mode == 1 and not main.autotest and not main.scenes.cine_busy and not GS.showcase_active and not player.input_locked:
			main.bro_prompt = "E  -  TALK TO BIG BRO"
			if Input.is_action_just_pressed("interact") and talk_cd <= 0.0:
				talk_cd = 2.0
				away = false
				main.scenes.bro_chat("talk")
				return
	# one talk when the gull comes to sit next to him (round 8: he is part of the story, not a prop; round 20: a key talk that it has earned and not heard, once per visit)
	if near_t > 1.0 and away and player.mode == 1 and main != null and not main.autotest and not GS.showcase_active and not main.scenes.cine_busy and can_talk and not player.input_locked:
		var cid = BroTalks.next_talk(self)
		if cid != "":
			GS.cine_seen[cid] = true
			away = false
			main.scenes.bro_chat(cid)
			return
	if near_t > 1.2 and line_cd <= 0.0 and not GS.ordinary_eaten and player.mode == 1 and GS.gull_sense_count >= 3 and not (main != null and main.scenes.cine_busy):
		line_cd = 40.0
		var n = GS.fry_total()
		var pool = EARLY if n < 10 else (MID if n < 20 else LATE)
		speak(pool[randi() % pool.size()], 3.8)
