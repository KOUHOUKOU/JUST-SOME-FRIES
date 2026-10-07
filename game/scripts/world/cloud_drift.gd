extends Node3D
# The clouds drift slowly east and come back round on the west side: the sky is never still.

func _process(delta):
	for c in get_children():
		if c.has_meta("drift"):
			c.position.x += c.get_meta("drift") * delta
			if c.position.x > 330.0:
				c.position.x = -330.0
