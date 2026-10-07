extends Node3D
# The sun disc: the rays turn very slowly; when the sun has been caught it fades from the sky.

var fade = 1.0
var caught = false

func _process(delta):
	var rays = get_node_or_null("Rays")
	if rays != null:
		rays.rotation.z += delta * 0.04
	if caught:
		fade = move_toward(fade, 0.0, delta / 3.0)
	scale = Vector3.ONE * max(fade, 0.001)
	visible = fade > 0.01
