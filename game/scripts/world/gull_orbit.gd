extends Node
# Ambient gulls lazily circling a thermal. Purely decorative life in the sky.

var gull
var center = Vector3.ZERO
var radius = 18.0
var angle = 0.0
var rate = 0.2
var bob_t = 0.0

func _ready():
	if gull != null:
		gull.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		GS.cull_tree(gull, 140.0, true)

func _process(delta):
	if gull == null:
		return
	angle += rate * delta
	bob_t += delta
	var p = center + Vector3(cos(angle) * radius, sin(bob_t * 0.5) * 1.5, sin(angle) * radius)
	gull.global_position = p
	var tangent = Vector3(-sin(angle), 0, cos(angle)) * sign(rate)
	gull.rotation.y = atan2(-tangent.x, -tangent.z)
	gull.rotation.z = -0.35 * sign(rate)
	gull.pose("glide", 0.0, false, delta)
