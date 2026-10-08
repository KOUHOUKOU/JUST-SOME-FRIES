extends RefCounted
# THE CAMERA DIRECTOR (round 9). Every film shot of the game is asked for by what it should SHOW, never by metres:
#   "the gull's whole body, a third of the picture wide, with a nice background"  ->  plan() solves the distance from the field of view and searches
#   the circle around the subject for the angle with the best background that nothing blocks.
# Why: the old shots put the camera 1.3-2.4 m from a gull with a 3 m wingspan, so the picture was all feathers (see docs/29_ROUND9_PLAN.md).
#
# Shot sizes (fraction of the picture WIDTH that the subject should fill):
#   WIDE   0.10  the place with a small gull in it (sea, town, horizon)
#   MEDIUM 0.30  the whole gull, its surroundings still readable            <- the default
#   TIGHT  0.45  the gull from the chest up, still not a wall of feathers (at most once per scene)
#   INSERT 0.22  a small object (a fry on the floor, a hand) - the subject IS the object
# Composition: the subject sits on a third of the frame, with room in front of where it looks; the camera only ever pushes in slowly (<= 9 %).

const Terrain = preload("res://scripts/world/terrain.gd")
const ASPECT = 1.78
const SIZES = {"wide": 0.10, "medium": 0.30, "tight": 0.45, "insert": 0.22}

var main

func _init(m):
	main = m

# ---- the size of things
# a gull's width: spread wings in the air, folded on the ground
func gull_width(g, flying = false):
	var s = 1.0
	if g != null and is_instance_valid(g):
		s = g.global_transform.basis.get_scale().x
	return (2.7 if flying else 1.5) * s

static func dist_for(width, frac, fov):
	return width / (max(frac, 0.02) * 2.0 * tan(deg_to_rad(fov * 0.5)) * ASPECT)

# ---- the world
func _space():
	return main.get_world_3d().direct_space_state

func ray(a, b, mask = 1):
	var q = PhysicsRayQueryParameters3D.create(a, b, mask)
	return _space().intersect_ray(q)

func floor_y(p):
	return max(Terrain.H(p.x, p.z), 0.0)

# is the straight line from the subject to the camera free?
func clear(center, cam_pos, margin = 0.6):
	var h = ray(center, cam_pos)
	if not (h.is_empty() or h["position"].distance_to(cam_pos) < margin):
		return false
	# people and dogs are not solid for the physics rays: keep them out of the line of sight and out of the lens
	var seg = cam_pos - center
	var l2 = max(seg.length_squared(), 0.01)
	for grp in ["ambient", "npcs", "dogs", "fries"]:
		for n in main.get_tree().get_nodes_in_group(grp):
			if not (n is Node3D) or not n.is_visible_in_tree():
				continue
			var q = n.global_position + Vector3(0, 0.9, 0)
			if q.distance_to(center) < 0.9:
				continue
			var u = clamp((q - center).dot(seg) / l2, 0.0, 1.0)
			if q.distance_to(center + seg * u) < 1.0 or q.distance_to(cam_pos) < 2.2:
				return false
	return true

# how good is the view BEHIND the subject for a camera at cam? Follow the real line of sight through the subject: scenery at a pleasant distance (a town,
# trees, a hill: something DARKER than a white gull) is good, a wall right behind it is bad, open sea or sky is fine but flat (a white gull on pale water vanishes)
func backdrop_score(center, cam):
	var sight = (center - cam).normalized()
	var sc = 0.0
	for dyaw in [-0.3, 0.0, 0.3]:
		var d = sight.rotated(Vector3.UP, dyaw)
		var h = ray(center + d * 0.6, center + d * 300.0)
		if h.is_empty():
			sc += 0.15 if d.y < -0.04 else 0.7          # sea (pale) / sky
		else:
			var dd = center.distance_to(h["position"])
			if dd < 5.0:
				sc += -3.0
			elif dd < 14.0:
				sc += -0.8
			else:
				sc += 2.0
	return sc / 3.0

# ---- the planner
# center: the thing to film. width: how wide it is in metres. yaw: which way it faces (radians, the game's yaw: forward = (-sin, 0, -cos)).
# o: {"size": "medium" | frac, "fov": 40, "az": degrees relative to the subject's facing (0 = the camera in front of it, 90 = on its right, 180 = behind),
#     "spread": search +- degrees, "h": camera height above the subject as a fraction of the distance, "push": slow push-in 0..0.09, "avoid": a world azimuth to stay away from,
#     "face": prefer seeing its face, "look_h": where on the subject the camera looks (metres above center), "third": rule of thirds on/off}
# returns {"p0","l0","f0","p1","l1","f1","az"} for story.cam_set
func plan(center, width, yaw, o = {}):
	var fov = o.get("fov", 40.0)
	var frac = o.get("size", "medium")
	if typeof(frac) == TYPE_STRING:
		frac = SIZES.get(frac, 0.3)
	var d0 = dist_for(width, frac, fov)
	var hk = o.get("h", 0.12)
	var az0 = deg_to_rad(o.get("az", 35.0))
	var spread = deg_to_rad(o.get("spread", 120.0))
	var fwd = Vector3(-sin(yaw), 0, -cos(yaw))
	var look_h = o.get("look_h", 0.0)
	var lookp = center + Vector3(0, look_h, 0)
	var best = null
	var best_s = -1e9
	var d = d0
	for attempt in 4:
		var hh = hk * d + (0.45 if attempt >= 2 else 0.0) * d
		var k = -spread
		while k <= spread + 0.001:
			var az = az0 + k
			var dirh = fwd.rotated(Vector3.UP, -az)            # +az = towards the subject's right
			var cam = lookp + dirh * d + Vector3(0, hh, 0)
			var s = -abs(k) * 0.9
			if cam.y < floor_y(cam) + 0.5:
				s -= 200.0
			if not clear(lookp, cam):
				s -= 200.0
			else:
				s += backdrop_score(lookp, cam) * 3.0
			if o.has("avoid"):
				var da = abs(wrapf(atan2(dirh.x, dirh.z) - o["avoid"], -PI, PI))
				if da < 0.6:
					s -= 3.0
			if o.get("face", false):
				s += dirh.dot(fwd) * 2.0
			if s > best_s:
				best_s = s
				best = {"cam": cam, "az": az}
			k += deg_to_rad(12.0)
		if best_s > -100.0:
			break
		d *= 0.78                                                  # everything was blocked: come closer, then higher
	var cam_pos = best["cam"]
	var look = lookp
	if o.get("third", true):
		# put the subject on a third of the picture, with lead room in front of it
		var cdir = (lookp - cam_pos).normalized()
		var right = cdir.cross(Vector3.UP).normalized()
		var side = 1.0 if fwd.dot(right) > 0.0 else -1.0       # facing right of the frame -> the subject sits on the left third
		if o.has("side"):
			side = -o["side"]                                  # forced: +1 = the subject on the right third
		look = lookp + right * side * (cam_pos.distance_to(lookp) * tan(deg_to_rad(fov * 0.5)) * ASPECT * 0.30)
	if o.has("lift"):
		# something (a dialogue box) covers the bottom of the picture: carry the subject higher up
		look.y -= o["lift"] * 2.0 * cam_pos.distance_to(lookp) * tan(deg_to_rad(fov * 0.5))
	var push = o.get("push", 0.05)
	var p1 = cam_pos.lerp(look, push)
	return {"p0": cam_pos, "l0": look, "f0": fov, "p1": p1, "l1": look, "f1": fov, "az": best["az"], "score": best_s, "dist": d}

# plan + hand to the story camera
func shoot(st, center, width, yaw, o = {}, dur = 5.0, bob = 0.006):
	var pl = plan(center, width, yaw, o)
	st.cam_set(pl["p0"], pl["l0"], pl["f0"], pl["p1"], pl["l1"], pl["f1"], dur, bob)
	return pl

# a gull, medium shot
func gull_shot(st, g, o = {}, dur = 5.0, flying = false, up = 0.3, yaw = null):
	var o2 = o.duplicate()
	if not o2.has("size"):
		o2["size"] = "medium"
	var sc = g.global_transform.basis.get_scale().x
	var c = g.global_position + Vector3(0, up * sc, 0)
	return shoot(st, c, gull_width(g, flying), g.global_rotation.y if yaw == null else yaw, o2, dur)

# an object (a fry, a hand): the insert
func insert_shot(st, center, width, yaw, o = {}, dur = 4.0):
	var o2 = o.duplicate()
	if not o2.has("size"):
		o2["size"] = "insert"
	if not o2.has("fov"):
		o2["fov"] = 30.0
	return shoot(st, center, width, yaw, o2, dur, 0.003)

# ---- a camera that follows a flying gull (the gull keeps moving; the camera keeps its composition). Runs until `stop` returns true or dur seconds pass.
# o: plan() options (az is relative to the gull's heading, "size": usually medium), plus "swing": degrees of slow drift over the shot, "rate": smoothing
func follow(st, pl, o, dur, tag_id):
	var ctl = {"id": tag_id}
	var t0 = GS.msec()
	var fov0 = o.get("fov", 40.0)
	var fov1 = o.get("fov_to", fov0)
	var width = gull_width(pl.gull, true)
	var frac = o.get("size", "medium")
	if typeof(frac) == TYPE_STRING:
		frac = SIZES.get(frac, 0.3)
	var frac1 = o.get("size_to", frac)
	var az0 = deg_to_rad(o.get("az", 150.0))
	var swing = deg_to_rad(o.get("swing", 20.0))
	var hk = o.get("h", 0.14)
	var rate = o.get("rate", 4.0)
	var look_up = o.get("look_h", 0.1)
	var cur = null
	var last = GS.msec()
	var az_fix = 0.0                  # extra swing the obstruction search added
	while true:
		await st.get_tree().process_frame
		if ctl["id"] != main.scenes.orbit_id:
			return
		var now = GS.msec()
		var dt = clamp((now - last) / 1000.0, 0.0, 0.1)
		last = now
		var u = clamp((now - t0) / 1000.0 / max(dur, 0.1), 0.0, 1.0)
		var e = u * u * (3.0 - 2.0 * u)
		var fov = lerp(fov0, fov1, e)
		var d = dist_for(width, lerp(frac, frac1, e), fov)
		var center = pl.global_position + Vector3(0, 0.4, 0)
		var yaw = pl.yaw
		var fwd = Vector3(-sin(yaw), 0, -cos(yaw))
		var az = az0 + swing * (e - 0.5) * 2.0
		var want = null
		# search a few azimuth offsets for the first free, high-enough position (closest to the wished angle first)
		for off in [0.0, 0.35, -0.35, 0.7, -0.7, 1.1, -1.1, 1.6, -1.6]:
			var dirh = fwd.rotated(Vector3.UP, -(az + off + az_fix))
			var cam = center + dirh * d + Vector3(0, hk * d + 0.2, 0)
			if cam.y < floor_y(cam) + 0.8:
				cam.y = floor_y(cam) + 0.8
			if clear(center, cam):
				want = cam
				break
		if want == null:
			want = center + Vector3(0, d * 0.8, 0) + fwd * -d * 0.5          # everything blocked: from above
		if cur == null:
			cur = want
		else:
			cur = cur.lerp(want, 1.0 - exp(-rate * dt))
		var look = center + Vector3(0, look_up, 0)
		if o.get("third", true):
			var cdir = (look - cur).normalized()
			var right = cdir.cross(Vector3.UP).normalized()
			var side = 1.0 if fwd.dot(right) > 0.0 else -1.0
			look += right * side * (cur.distance_to(look) * tan(deg_to_rad(fov * 0.5)) * ASPECT * 0.24)
		st.cam_set(cur, look, fov, null, null, -1.0, 1.0, 0.002)
		if u >= 1.0:
			return

# ---- round 10: a follower for the little extra pictures (insets) of the flow moments. The gull keeps flying; the inset camera keeps its composition around it.
# o: az (degrees from the gull's heading, 0 = in front of it, 90 = its right, 180 = behind), size (fraction of the inset's width), fov, h, look_h, swing (degrees of drift)
func follow_make(o):
	return {"o": o, "t0": GS.msec(), "cur": null, "az_fix": 0.0, "search_t": 0.0}

func follow_step(s, gull, yaw, dt):
	var o = s["o"]
	var fov = o.get("fov", 40.0)
	var frac = o.get("size", 0.3)
	var d = dist_for(gull_width(gull, true), frac, fov)
	var center = gull.global_position + Vector3(0, 0.4, 0)
	var fwd = Vector3(-sin(yaw), 0, -cos(yaw))
	var u = clamp((GS.msec() - s["t0"]) / 1000.0 / max(o.get("dur", 6.0), 0.1), 0.0, 1.0)
	var az = deg_to_rad(o.get("az", 150.0)) + deg_to_rad(o.get("swing", 14.0)) * (u - 0.5) * 2.0
	var hk = o.get("h", 0.14)
	s["search_t"] -= dt
	if s["search_t"] <= 0.0 or s["cur"] == null:
		s["search_t"] = 0.35
		s["az_fix"] = 0.0
		for off in [0.0, 0.35, -0.35, 0.7, -0.7, 1.1, -1.1, 1.6, -1.6]:
			var dirh = fwd.rotated(Vector3.UP, -(az + off))
			var cam = center + dirh * d + Vector3(0, hk * d + 0.2, 0)
			if cam.y >= floor_y(cam) + 0.8 and clear(center, cam):
				s["az_fix"] = off
				break
	var dirh2 = fwd.rotated(Vector3.UP, -(az + s["az_fix"]))
	var want = center + dirh2 * d + Vector3(0, hk * d + 0.2, 0)
	if want.y < floor_y(want) + 0.8:
		want.y = floor_y(want) + 0.8
	# smooth the OFFSET from the gull, not the position (the gull flies at 30 m/s: a smoothed position would be left far behind)
	if s["cur"] == null:
		s["cur"] = want - center
	else:
		s["cur"] = s["cur"].lerp(want - center, 1.0 - exp(-7.0 * dt))
	return {"pos": center + s["cur"], "look": center + Vector3(0, o.get("look_h", 0.1), 0), "fov": fov}

# ---- quality check (dev tools): how much of the picture's WIDTH does this gull take, and how close is the camera to it?
func _meshes(n, out):
	if n is MeshInstance3D and n.visible and n.mesh != null and not (n.mesh is QuadMesh):
		var bb = n.get_aabb()
		if bb.size.length() < 6.0:
			out.append(n)
	for c in n.get_children():
		if c is Node3D and not c.visible:
			continue
		_meshes(c, out)
	return out

func screen_cover(cam, root):
	var vp = cam.get_viewport().get_visible_rect().size
	var lo = Vector2(1e9, 1e9)
	var hi = Vector2(-1e9, -1e9)
	var near = 1e9
	var any = false
	for mi in _meshes(root, []):
		var bb = mi.get_aabb()
		near = min(near, cam.global_position.distance_to(mi.global_transform * bb.get_center()))
		for i in 8:
			var c = mi.global_transform * bb.get_endpoint(i)
			if cam.is_position_behind(c):
				continue
			var sp = cam.unproject_position(c)
			lo = Vector2(min(lo.x, sp.x), min(lo.y, sp.y))
			hi = Vector2(max(hi.x, sp.x), max(hi.y, sp.y))
			any = true
	if not any:
		return {"w": 0.0, "h": 0.0, "near": near}
	return {"w": (hi.x - lo.x) / vp.x, "h": (hi.y - lo.y) / vp.y, "near": near, "cx": (lo.x + hi.x) * 0.5 / vp.x, "cy": (lo.y + hi.y) * 0.5 / vp.y}

# the same question answered from the camera alone (dev tools): a perched gull is about 1.5 m x scale wide; how much of the picture's width is that at this distance?
func approx_cover(cam, g, width = 1.5):
	var sc = g.global_transform.basis.get_scale().x
	var c = g.global_position + Vector3(0, 0.4 * sc, 0)
	var d = cam.global_position.distance_to(c)
	if cam.is_position_behind(c):
		return {"w": 0.0, "near": d}
	var vp = cam.get_viewport().get_visible_rect().size
	var sp = cam.unproject_position(c)
	if sp.x < -0.1 * vp.x or sp.x > 1.1 * vp.x or sp.y < -0.1 * vp.y or sp.y > 1.1 * vp.y:
		return {"w": 0.0, "near": d}
	var vis = 2.0 * d * tan(deg_to_rad(cam.fov * 0.5)) * ASPECT
	return {"w": width * sc / max(vis, 0.01), "near": d}
