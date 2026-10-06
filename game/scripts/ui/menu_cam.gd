extends Node
# The title screen's camera: a slow, wide orbit around the cafe and the pier at dawn (runs while the game is paused).

var player
var menus
var t = 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta):
	if player == null or menus == null or player.active:
		return
	if not menus.main_panel.visible:
		return
	t += delta
	var a = -0.9 + t * 0.045
	var c = Vector3(-6.0, 4.0, 14.0)
	var pos = c + Vector3(sin(a) * 34.0, 10.0 + sin(t * 0.13) * 2.0, cos(a) * 30.0 - 6.0)
	var xf = Transform3D(Basis.IDENTITY, pos).looking_at(c + Vector3(0, 2.0, 0), Vector3.UP)
	player.cine_cam.global_transform = xf
	player.cine_cam.fov = 58.0
	player.cine_cam.current = true
