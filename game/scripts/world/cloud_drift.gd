extends Node3D
# The clouds drift slowly east and come back round on the west side: the sky is never still.
# Round 9: some of them are rain clouds. They rain only while there is open sea under them (the land - the town, the hill, the farm - never gets wet).

const SkyBuilder = preload("res://scripts/world/sky.gd")
var rain_t = 0.0

func _process(delta):
	for c in get_children():
		if c.has_meta("drift"):
			c.position.x += c.get_meta("drift") * delta
			if c.position.x > 330.0:
				c.position.x = -330.0
	rain_t -= delta
	if rain_t > 0.0:
		return
	rain_t = 0.4
	for c in get_tree().get_nodes_in_group("rain_cloud"):
		if not is_instance_valid(c) or not c.has_meta("rain"):
			continue
		var rn = c.get_meta("rain")
		var gp = c.global_position
		var on = SkyBuilder.over_sea(gp.x, gp.z, 22.0)
		rn.emitting = on
		c.set_meta("raining", on)
