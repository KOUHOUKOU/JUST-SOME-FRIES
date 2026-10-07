extends RefCounted
# Tiny procedural textures for clothes, hats and glasses (stripes, dots, checks, flowers, plaid...): every wearable gets its own pattern,
# so a sailor's shirt, a flower shirt and a long coat no longer differ only by colour. Textures are cached per (kind, colours).

static var _cache = {}

static func _put(img, x, y, c):
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)

static func tex(kind, c1, c2, n = 4):
	var key = "%s|%s|%s|%d" % [kind, Color(c1).to_html(), Color(c2).to_html(), n]
	if _cache.has(key):
		return _cache[key]
	var a = Color(c1)
	var b = Color(c2)
	var S = 64
	var img = Image.create(S, S, true, Image.FORMAT_RGBA8)
	img.fill(a)
	match kind:
		"stripes":            # horizontal bands
			for y in S:
				if int(floor(float(y) / S * n * 2.0)) % 2 == 1:
					for x in S:
						img.set_pixel(x, y, b)
		"vstripes":           # vertical bands
			for x in S:
				if int(floor(float(x) / S * n * 2.0)) % 2 == 1:
					for y in S:
						img.set_pixel(x, y, b)
		"check":              # a checkerboard
			for y in S:
				for x in S:
					if (int(floor(float(x) / S * n)) + int(floor(float(y) / S * n))) % 2 == 1:
						img.set_pixel(x, y, b)
		"dots":               # polka dots
			var step = float(S) / n
			for gy in n:
				for gx in n:
					var cx = (gx + 0.5 + (0.5 if gy % 2 == 1 else 0.0)) * step
					var cy = (gy + 0.5) * step
					var r = step * 0.24
					for y in range(int(cy - r - 1), int(cy + r + 2)):
						for x in range(int(cx - r - 1), int(cx + r + 2)):
							if Vector2(x - cx, y - cy).length() <= r:
								_put(img, posmod(x, S), posmod(y, S), b)
		"floral":             # little five-petal flowers on a loud base (c2 = the petals, the centre is always yellow)
			var step2 = float(S) / n
			for gy in n:
				for gx in n:
					var cx2 = (gx + 0.5 + (0.5 if gy % 2 == 1 else 0.0)) * step2
					var cy2 = (gy + 0.5) * step2
					var pr = step2 * 0.17
					for k in 5:
						var ang = k * TAU / 5.0 + gx * 0.4
						var px = cx2 + cos(ang) * pr * 1.2
						var py = cy2 + sin(ang) * pr * 1.2
						for y in range(int(py - pr - 1), int(py + pr + 2)):
							for x in range(int(px - pr - 1), int(px + pr + 2)):
								if Vector2(x - px, y - py).length() <= pr:
									_put(img, posmod(x, S), posmod(y, S), b)
					for y in range(int(cy2 - pr * 0.7), int(cy2 + pr * 0.7) + 1):
						for x in range(int(cx2 - pr * 0.7), int(cx2 + pr * 0.7) + 1):
							if Vector2(x - cx2, y - cy2).length() <= pr * 0.7:
								_put(img, posmod(x, S), posmod(y, S), Color("FFE05A"))
		"plaid":              # tartan: broad pale lines both ways over a dark base
			for y in S:
				for x in S:
					var gx2 = float(x) / S * n
					var gy2 = float(y) / S * n
					var lx = abs(gx2 - round(gx2)) < 0.09
					var ly = abs(gy2 - round(gy2)) < 0.09
					var px2 = int(floor(gx2)) % 2 == 0
					var py2 = int(floor(gy2)) % 2 == 0
					var col = a
					if px2 and py2:
						col = a.lerp(b, 0.28)
					elif px2 or py2:
						col = a.lerp(b, 0.14)
					if lx or ly:
						col = b
					img.set_pixel(x, y, col)
		"herring":            # a woven zigzag
			for y in S:
				for x in S:
					var q = int(floor(float(y) / S * n * 2.0))
					var xo = x + (q % 2) * (S / (n * 2))
					if int(floor(float(xo) / S * n * 2.0)) % 2 == 1:
						img.set_pixel(x, y, b)
	img.generate_mipmaps()
	var t = ImageTexture.create_from_image(img)
	_cache[key] = t
	return t

static func mat(kind, c1, c2, n = 4, rough = 0.9, uv_scale = Vector3.ONE):
	var m = StandardMaterial3D.new()
	m.albedo_texture = tex(kind, c1, c2, n)
	m.albedo_color = Color.WHITE
	m.roughness = rough
	m.uv1_scale = uv_scale
	m.texture_repeat = true
	return m
