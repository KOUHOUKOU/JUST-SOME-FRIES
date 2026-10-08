extends RefCounted
# ROUND 10: people and dogs must never walk into a wall. Every mover asks `Nav.step(node, move)` instead of `position += move`:
# a waist-high ball and a knee-high ball are swept a little ahead of the step (physics cast_motion, solid = collision layer 1: buildings, props, terrain).
# If something is there the person slides sideways along it (it tries 40 and 80 degrees to either side); if every way is shut it simply does not move,
# and the caller is told so it can skip a waypoint or give up a chase. A person who is already inside something is allowed to walk out of it.

const PROBES = [[0.95, 0.30], [0.55, 0.20]]       # [height, radius]
const AHEAD = 0.35
static var _terrain = null           # the ground is not an obstacle (people follow it); only buildings and props are

static func _ground(n):
	if _terrain == null or not is_instance_valid(_terrain):
		_terrain = n.get_tree().root.find_child("TerrainBody", true, false)
	var a: Array[RID] = []
	if _terrain != null:
		a.append(_terrain.get_rid())
	return a

# returns true when the step (or a slide along the obstacle) was made, false when the way is shut. `dy` = how far the ground rises or falls under the step
static func step(n, move, dy = 0.0):
	var flat = Vector3(move.x, 0.0, move.z)
	var len_ = flat.length()
	if len_ < 0.00001:
		return true
	var space = n.get_world_3d().direct_space_state
	var base = n.global_position
	var ex = _ground(n)
	if _overlaps(space, base, ex):
		n.global_position = base + move          # already in something: walk out of it, whichever way
		return true
	var dir = flat / len_
	var rise = Vector3(0, dy * (len_ + AHEAD) / len_, 0)
	if _clear(space, base, dir * (len_ + AHEAD) + rise, ex):
		n.global_position = base + Vector3(move.x, move.y + dy, move.z)
		return true
	for a in [0.7, -0.7, 1.4, -1.4]:
		var d2 = dir.rotated(Vector3.UP, a)
		if _clear(space, base, d2 * (len_ + AHEAD) + rise, ex):
			n.global_position = base + d2 * len_ + Vector3(0, move.y + dy, 0)
			return true
	return false

static func _shape(r):
	var sp = SphereShape3D.new()
	sp.radius = r
	return sp

static func _clear(space, base, v, ex):
	for pr in PROBES:
		var q = PhysicsShapeQueryParameters3D.new()
		q.shape = _shape(pr[1])
		q.collision_mask = 1
		q.exclude = ex
		q.transform = Transform3D(Basis.IDENTITY, base + Vector3(0, pr[0], 0))
		q.motion = v
		var res = space.cast_motion(q)
		if res.size() >= 2 and res[0] < 0.999:
			return false
	return true

static func _overlaps(space, base, ex):
	for pr in PROBES:
		var q = PhysicsShapeQueryParameters3D.new()
		q.shape = _shape(pr[1] - 0.04)
		q.collision_mask = 1
		q.exclude = ex
		q.transform = Transform3D(Basis.IDENTITY, base + Vector3(0, pr[0], 0))
		for h in space.intersect_shape(q, 4):
			var c = h["collider"]
			if c != null and c.name == "SolidBody":
				return true
	return false

# is the person standing inside a building or a prop right now? (the ground does not count)
static func inside_solid(n, what = "props"):
	var space = n.get_world_3d().direct_space_state
	if what == "props":
		return _overlaps(space, n.global_position, _ground(n))
	var sp = SphereShape3D.new()
	sp.radius = 0.22
	var q = PhysicsShapeQueryParameters3D.new()
	q.shape = sp
	q.collision_mask = 1
	q.transform = Transform3D(Basis.IDENTITY, n.global_position + Vector3(0, 0.95, 0))
	return not space.intersect_shape(q, 1).is_empty()

# a person who was placed inside a prop: the nearest free spot on a ring around (null if none within 3 m)
static func free_spot(n):
	var space = n.get_world_3d().direct_space_state
	var base = n.global_position
	var ex = _ground(n)
	for r in [0.4, 0.7, 1.0, 1.4, 1.9, 2.5, 3.0]:
		for k in 12:
			var ang = TAU * k / 12.0
			var p = base + Vector3(cos(ang), 0, sin(ang)) * r
			if not _overlaps(space, p, ex):
				var ok = true
				for pr in PROBES:
					var q = PhysicsShapeQueryParameters3D.new()
					q.shape = _shape(pr[1] + 0.1)
					q.collision_mask = 1
					q.exclude = ex
					q.transform = Transform3D(Basis.IDENTITY, p + Vector3(0, pr[0], 0))
					for h in space.intersect_shape(q, 2):
						var c = h["collider"]
						if c != null and c.name == "SolidBody":
							ok = false
				if ok:
					return p
	return null
