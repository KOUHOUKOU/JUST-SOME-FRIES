extends Node
# While the cover illustration is on screen nothing of the 3D world is visible, so it is not drawn at all (this saves the GPU on a weak laptop and in the browser).
# The world switches back on the moment the cover is gone.

var player
var menus
var t = 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta):
	if player == null or menus == null:
		return
	var on_cover = menus.main_panel.visible and not player.active
	get_viewport().disable_3d = on_cover
	if on_cover:
		# a camera for the first frame after the cover (the opening takes over straight away)
		var c = Vector3(-6.0, 4.0, 14.0)
		var xf = Transform3D(Basis.IDENTITY, c + Vector3(30.0, 12.0, 20.0)).looking_at(c + Vector3(0, 2.0, 0), Vector3.UP)
		player.cine_cam.global_transform = xf
		player.cine_cam.fov = 58.0
		player.cine_cam.current = true
