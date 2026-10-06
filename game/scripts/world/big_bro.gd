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

const OUTFIT = ["topper", "shades", "necklace", "pipe", "coat"]

func setup(p_player, pos, face_pos):
	player = p_player
	gull = Node3D.new()
	gull.set_script(GullVisual)
	gull.plain = true
	add_child(gull)
	gull.build()
	gull.scale = Vector3.ONE * 1.55
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
	bubble.position = Vector3(0, 1.5, 0)
	bubble.render_priority = 5
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

func _process(delta):
	t += delta
	if gull == null:
		return
	gull.pose("ground", 0.0, false, delta)
	# idle life: a slow head turn, now and then a puff on the pipe
	gull.head.rotation.y = sin(t * 0.4) * 0.35
	gull.head.rotation.x = sin(t * 0.23) * 0.06
	if bubble_t > 0.0:
		bubble_t -= delta
		bubble.modulate.a = clamp(min(bubble_t, 0.6) / 0.6, 0.0, 1.0) * 0.95
	else:
		bubble.modulate.a = 0.0
	if player == null or not player.active:
		return
	var d = global_position.distance_to(player.global_position)
	if d < 40.0 and look_at_player:
		_face(player.global_position, 0.04)
	# a hint, now and then, when the gull comes close: the big brother knows where this is going
	line_cd = max(line_cd - delta, 0.0)
	near_t = near_t + delta if d < 7.0 else 0.0
	if near_t > 1.2 and line_cd <= 0.0 and not GS.ordinary_eaten and player.mode == 1 and GS.gull_sense_count >= 3:
		line_cd = 40.0
		var n = GS.fry_total()
		if n < 10:
			speak("Go on. Get strong.", 3.2)
		elif n < 20:
			speak("I have everything. Still hungry.", 3.6)
		else:
			speak("Look where you started.", 3.6)
