extends RefCounted
# Height-field terrain: coast, beach slope, hillside, headland plateau, islet. Pure function H(x,z) is shared
# with the player (water detection) and the builder (building bases). Water level is -0.75.

const WATER_Y = -0.75
const X0 = -160.0
const X1 = 160.0
const Z0 = -110.0
const Z1 = 140.0
const STEP = 2.5

static func rect_d(x, z, x0, x1, z0, z1):
	return min(min(x - x0, x1 - x), min(z - z0, z1 - z))

static func land(x, z):
	var s = clamp(rect_d(x, z, -72, 50, -92, 27) / 7.0, 0.0, 1.0)
	var bz1 = 46.0 + 5.0 * sin(x * 0.07)
	s = max(s, clamp(rect_d(x, z, 8, 82, -30, bz1) / 8.0, 0.0, 1.0))
	s = max(s, clamp(rect_d(x, z, 50, 118, -50, 14) / 6.0, 0.0, 1.0))
	s = max(s, clamp(rect_d(x, z, -140, -68, -12, 88) / 7.0, 0.0, 1.0))
	s = max(s, clamp(rect_d(x, z, 40, 118, -94, -44) / 7.0, 0.0, 1.0))      # the east meadow: farm, windmill, barn (grows out of the hill)
	var di = Vector2(x, z - 118.0).length()
	s = max(s, clamp((16.0 - di) / 8.0, 0.0, 1.0))
	return s

static func H(x, z):
	var s = land(x, z)
	var h = lerp(-3.0, 0.0, s)
	var hm = smoothstep(-24.0, -70.0, z)
	h += hm * s * (22.0 + 1.5 * sin(x * 0.09) + 1.0 * sin(z * 0.11 + x * 0.05))
	var dd = Vector2(x + 102.0, z - 40.0).length()
	h += 24.0 * (1.0 - smoothstep(24.0, 40.0, dd)) * clamp(s * 3.0, 0.0, 1.0)
	var di = Vector2(x, z - 118.0).length()
	h += 3.0 * clamp((10.0 - di) / 10.0, 0.0, 1.0) * s
	return h

static func is_land(x, z):
	return H(x, z) > -0.4

static func color_at(x, z, h, slope):
	var n = 0.5 + 0.5 * sin(x * 0.31) * sin(z * 0.27)
	var in_core = x > -72 and x < 50 and z > -26 and z < 27
	var in_beach = x > 8 and x < 90 and z > 4 and z < 52
	var in_harbor = x > 50 and z < 14 and z > -50
	var col = Color(0.46, 0.60, 0.38).lerp(Color(0.40, 0.54, 0.34), n)
	if in_core:
		col = Color(0.72, 0.68, 0.60).lerp(Color(0.68, 0.64, 0.57), n)
		if x < -30 and z < 14 and z > -26:
			col = Color(0.46, 0.62, 0.38).lerp(Color(0.40, 0.56, 0.33), n)
	if in_beach:
		col = Color(0.90, 0.76, 0.52).lerp(Color(0.86, 0.71, 0.47), n)
	if x > 52 and z < -50 and h > 5.0:
		# farmland: strips of crops and bare earth
		var strip = int(floor((z + 200.0) / 5.0)) % 2
		if x > 60 and x < 104 and z > -92 and z < -58:
			col = Color(0.50, 0.62, 0.28).lerp(Color(0.44, 0.55, 0.25), n) if strip == 0 else Color(0.62, 0.50, 0.32).lerp(Color(0.56, 0.45, 0.28), n)
	if in_harbor and not in_beach:
		col = Color(0.62, 0.63, 0.62).lerp(Color(0.57, 0.58, 0.57), n)
	if h < 0.2 and not in_core:
		col = Color(0.82, 0.74, 0.55)
	if h < -0.55:
		col = Color(0.88, 0.90, 0.86).lerp(Color(0.55, 0.65, 0.60), clamp((-0.55 - h) / 1.0, 0.0, 1.0))
	if h < -1.6:
		col = Color(0.35, 0.50, 0.50)
	if slope > 0.75 and h > 0.5:
		col = Color(0.52, 0.50, 0.46).lerp(Color(0.46, 0.44, 0.41), n)
	if h > -0.55:
		col = Color(col.r * 0.74, col.g * 0.76, col.b * 0.74)
	return col

static func build_mesh():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nx = int((X1 - X0) / STEP)
	var nz = int((Z1 - Z0) / STEP)
	for iz in nz:
		for ix in nx:
			var xa = X0 + ix * STEP
			var za = Z0 + iz * STEP
			var xb = xa + STEP
			var zb = za + STEP
			var ha = H(xa, za)
			var hb = H(xb, za)
			var hc = H(xa, zb)
			var hd = H(xb, zb)
			if max(max(ha, hb), max(hc, hd)) < -2.9:
				continue
			var sl = (max(max(ha, hb), max(hc, hd)) - min(min(ha, hb), min(hc, hd))) / STEP
			var p0 = Vector3(xa, ha, za)
			var p1 = Vector3(xb, hb, za)
			var p2 = Vector3(xa, hc, zb)
			var p3 = Vector3(xb, hd, zb)
			var c0 = color_at(xa, za, ha, sl)
			var c1 = color_at(xb, za, hb, sl)
			var c2 = color_at(xa, zb, hc, sl)
			var c3 = color_at(xb, zb, hd, sl)
			for v in [[p0, c0], [p1, c1], [p2, c2], [p1, c1], [p3, c3], [p2, c2]]:
				st.set_color(v[1])
				st.add_vertex(v[0])
	st.generate_normals()
	var mesh = st.commit()
	var m = StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.roughness = 1.0
	mesh.surface_set_material(0, m)
	return mesh
