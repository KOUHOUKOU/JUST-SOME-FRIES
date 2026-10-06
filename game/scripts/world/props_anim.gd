extends AnimatableBody3D
# Tiny animated-prop helper: spins around a local axis (Ferris wheel, turbine rotor, lighthouse beam),
# optionally keeping child nodes upright (gondolas), or drifts / bobs (clouds, kites).

var axis = Vector3(0, 0, 1)
var rate = 0.2
var upright = []
var bob = 0.0
var bob_speed = 1.0
var drift = Vector3.ZERO
var base_pos = Vector3.ZERO
var t = 0.0
var spin = true

func _ready():
	sync_to_physics = false
	base_pos = position
	t = randf() * 10.0

func _physics_process(delta):
	t += delta
	if spin:
		rotate_object_local(axis, rate * delta)
		for u in upright:
			if is_instance_valid(u):
				u.global_transform.basis = Basis.IDENTITY
	if bob > 0.0:
		position.y = base_pos.y + sin(t * bob_speed) * bob
		rotation.z = sin(t * bob_speed * 0.7) * 0.08
	if drift != Vector3.ZERO:
		position += drift * delta
