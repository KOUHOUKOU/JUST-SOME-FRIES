extends Node3D
# THE RAINBOW IN THE SKY (round 9): a rain cloud and a white cloud drift together out over the southern sea, and between them hangs a rainbow - seven bands,
# red on the outside to violet inside. It is scenery all the time; once the quest "CATCH A RAINBOW" is on the board it is also the hardest thing a gull can grab
# (7 circles x 2 judgements, 266 on the speed gauge). The catch point is always the place on the arc nearest to the gull.

const SkyBuilder = preload("res://scripts/world/sky.gd")
const BAND_COLS = [Color("EF4444"), Color("F9892E"), Color("FFD83A"), Color("46C45A"), Color("3AA8F0"), Color("4B5BDB"), Color("A55CE0")]

var half = 55.0            # half the span between the two clouds
var arch = 42.0            # how high the arch rises above the clouds
var dir = Vector3(1, 0, 0.3).normalized()
var mat
var arc_mi
var rain_cloud
var white_cloud
var fade = 1.0
var taken = false
var taken_t = 0.0

func build(rng, mats):
	dir = Vector3(cos(0.35), 0, sin(0.35))
	rain_cloud = SkyBuilder.make_cloud(rng, 58.0, "rain", mats)
	rain_cloud.position = -dir * half
	add_child(rain_cloud)
	white_cloud = SkyBuilder.make_cloud(rng, 52.0, "white", mats)
	white_cloud.position = dir * half + Vector3(0, 3.0, 0)
	add_child(white_cloud)
	mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(1, 1, 1, 1)
	arc_mi = MeshInstance3D.new()
	arc_mi.mesh = _arc_mesh()
	arc_mi.material_override = mat
	arc_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(arc_mi)
	add_to_group("rainbow_pair")

# a point of band k (0 outer .. 6 inner) at angle th (0 .. PI) in the local frame
func band_point(th, off = 0.0):
	return dir * (cos(th) * (half + off)) + Vector3(0, sin(th) * (arch + off), 0)

func _arc_mesh():
	return arc_mesh(dir, half, arch, 1.7, 0.95, 44, 0.52)

# a rainbow arch (seven stacked tubes, red outside, violet inside) in the vertical plane that contains `dir`
static func arc_mesh(dir_, half_, arch_, bw, tube, N, alpha):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var R = 6
	var perp = dir_.cross(Vector3.UP).normalized()
	for k in 7:
		var off = (3 - k) * bw
		var col = BAND_COLS[k]
		col.a = alpha
		var rings = []
		for i in N + 1:
			var th = PI * float(i) / float(N)
			var c = dir_ * (cos(th) * (half_ + off)) + Vector3(0, sin(th) * (arch_ + off), 0)
			var th2 = th + 0.01
			var th1 = th - 0.01
			var tg = ((dir_ * (cos(th2) * (half_ + off)) + Vector3(0, sin(th2) * (arch_ + off), 0)) - (dir_ * (cos(th1) * (half_ + off)) + Vector3(0, sin(th1) * (arch_ + off), 0))).normalized()
			var nrm = tg.cross(perp).normalized()
			var ring = []
			for j in R:
				var a = TAU * float(j) / float(R)
				ring.append(c + (nrm * cos(a) + perp * sin(a)) * tube)
			rings.append(ring)
		for i in N:
			for j in R:
				var j2 = (j + 1) % R
				var a0 = rings[i][j]
				var a1 = rings[i][j2]
				var b0 = rings[i + 1][j]
				var b1 = rings[i + 1][j2]
				for v in [a0, b0, a1, a1, b0, b1]:
					st.set_color(col)
					st.add_vertex(v)
	return st.commit()

func raining():
	return rain_cloud != null and rain_cloud.get_meta("raining", false)

# the world positions
func apex():
	return to_global(band_point(PI * 0.5))

# the nearest point of the middle band to a position in the world
func nearest(p):
	var best = apex()
	var bd = 1e9
	for i in 61:
		var th = PI * float(i) / 60.0
		var w = to_global(band_point(th))
		var d = p.distance_squared_to(w)
		if d < bd:
			bd = d
			best = w
	return best

# a camera position + look-at that shows the whole arch from the side (for the cinematic)
func wide_view(from_point):
	var c = to_global(Vector3(0, arch * 0.45, 0))
	var perp = dir.cross(Vector3.UP).normalized()
	var s = 1.0 if (from_point - c).dot(perp) > 0.0 else -1.0
	return {"pos": c + perp * s * 150.0 + Vector3(0, 10.0, 0), "look": c}

func is_visible_scenery():
	return fade > 0.05

func _process(delta):
	if taken:
		taken_t += delta
		if taken_t > 150.0:
			taken = false
			taken_t = 0.0
	var want = 1.0 if (raining() and not taken) else 0.0
	fade = move_toward(fade, want, delta / 12.0)
	mat.albedo_color = Color(1, 1, 1, fade)
	arc_mi.visible = fade > 0.02
