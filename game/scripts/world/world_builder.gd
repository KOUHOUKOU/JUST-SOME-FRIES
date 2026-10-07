extends RefCounted
# Builds the whole seaside town (docs/18 §8): terrain, nine districts, props, fry encounters, ambient people.
# Everything is made of primitives merged by material (see batcher.gd).

const Terrain = preload("res://scripts/world/terrain.gd")
const Batcher = preload("res://scripts/world/batcher.gd")
const NPC_SCRIPT = preload("res://scripts/npc/npc_controller.gd")
const AMBIENT_SCRIPT = preload("res://scripts/npc/ambient_npc.gd")
const FRY_SCRIPT = preload("res://scripts/fries/fry.gd")
const ANIM_SCRIPT = preload("res://scripts/world/props_anim.gd")
const GullVisual = preload("res://scripts/player/gull_visual.gd")
const ORBIT_SCRIPT = preload("res://scripts/world/gull_orbit.gd")
const DOG_SCRIPT = preload("res://scripts/npc/dog.gd")
const EXTRA_SCRIPT = preload("res://scripts/world/world_extra.gd")
const TOWN_SCRIPT = preload("res://scripts/world/world_town.gd")
const HOMES_SCRIPT = preload("res://scripts/world/world_homes.gd")
const FLORA_SCRIPT = preload("res://scripts/world/world_flora.gd")
const MISCHIEF = preload("res://scripts/fries/mischief.gd")
const SkyBuilder = preload("res://scripts/world/sky.gd")

const CHALK = "E8E2D2"
const SAGE = "879B82"
const CORAL = "D96D5F"
const FADED_BLUE = "7396A8"
const WOOD = "8B6A4D"
const DARKWOOD = "6F5238"
const TERRA = "B96F50"
const SLATE = "586169"
const OCHRE = "D9B25F"
const CREAM = "EFE3C6"
const WHITE = "F4F1E8"
const PALETTE_WALLS = ["E8E2D2", "7396A8", "D96D5F", "879B82", "D9B25F", "EFE3C6", "C9A68A", "A9BCC4"]
const PALETTE_ROOFS = ["B96F50", "586169", "A25A44", "6F7C84", "8B4A3A"]
const SKINS = ["F0C6A0", "E3B590", "C98F65", "A66E4B", "7A4B33"]
const SHIRTS = ["D96D5F", "7396A8", "879B82", "E2C25A", "A98FB8", "3E6F8E", "E8E2D2", "C65A3A", "5E8F6B", "D98F5F"]
const PANTS = ["4B5566", "3A3F4A", "6B5A48", "2F4A5E", "7A6A52"]
const HAIRS = ["2A2420", "4A3426", "7A4B22", "B58A4B", "D8D8D8", "1E1A18"]

const ORDINARY_POS = Vector3(-8.65, 0.10, 3.65)
const SPAWN_POS = Vector3(-9.5, 5.22, -0.8)

var root
var map
var B
var out = {}
var player
var rng = RandomNumberGenerator.new()
var reserved = []
var win_mat
var lamp_mat
var anchors = {}
var zones = []
var hill_doors = []
var volley = null
var hill_flat = []          # flat roofs on the hill (laundry roofs are built on them)
var town
var extra
var homes
var sea_boats = []
var beach_loungers = []
var flora
var foot = []            # footprints of buildings and yards: [Vector2 centre, half width, half depth] (flowers, trees and people keep out)

func gh(x, z):
	return Terrain.H(x, z)

func add_foot(x, z, hw, hd):
	foot.append([Vector2(x, z), hw, hd])

func is_clear(x, z, margin = 0.0):
	for f in foot:
		if abs(x - f[0].x) < f[1] + margin and abs(z - f[0].y) < f[2] + margin:
			return false
	return true

# a sun lounger (frame, cushion, a backrest propped up at 40 degrees). Returns where a reclining person's hips go (give that to a "recline" NPC).
func lounger(x, y, z, yaw_deg, cushion = "F4F1E8"):
	var basis = Basis.from_euler(Vector3(0, deg_to_rad(yaw_deg), 0))
	var P = Vector3(x, y, z)
	B.box(P + basis * Vector3(0, 0.26, 0.1), Vector3(0.78, 0.07, 1.2), "E8E2D2", true, Vector3(0, yaw_deg, 0))
	B.box(P + basis * Vector3(0, 0.31, 0.1), Vector3(0.7, 0.05, 1.1), cushion, false, Vector3(0, yaw_deg, 0))
	var hinge = Vector3(0, 0.34, -0.5)
	B.box(P + basis * (hinge + Vector3(0, 0.3, -0.36)), Vector3(0.78, 0.07, 0.95), "E8E2D2", false, Vector3(40, yaw_deg, 0))
	B.box(P + basis * (hinge + Vector3(0, 0.34, -0.4)), Vector3(0.7, 0.05, 0.85), cushion, false, Vector3(40, yaw_deg, 0))
	for sx in [-0.33, 0.33]:
		for sz in [-0.45, 0.65]:
			B.box(P + basis * Vector3(sx, 0.11, sz), Vector3(0.06, 0.22, 0.06), "B8BEC4", false)
	return P + basis * Vector3(0, 0.0, -0.36)

# a beach towel (flat, a person may lie on it: its top is at +0.04)
func towel(x, z, yaw_deg, col, y = -999.0):
	if y < -900.0:
		y = gh(x, z)
	B.box(Vector3(x, y + 0.02, z), Vector3(1.0, 0.04, 2.0), col, false, Vector3(0, yaw_deg, 0))
	B.box(Vector3(x, y + 0.045, z), Vector3(0.9, 0.012, 0.3), "FFFFFF", false, Vector3(0, yaw_deg, 0))

func _free(x, z, r = 2.0):
	for rv in reserved:
		if Vector2(x, z).distance_to(rv[0]) < rv[1] + r:
			return false
	return true

func _pick(arr):
	return arr[rng.randi() % arr.size()]

func rand_style(extra = {}):
	var d = {"skin": _pick(SKINS), "shirt": _pick(SHIRTS), "pants": _pick(PANTS), "hair": _pick(HAIRS),
		"hair_style": _pick(["short", "short", "long", "bun", "bald", "cap", "beanie"]), "hat": _pick(SHIRTS),
		"scale": rng.randf_range(0.94, 1.06), "fat": rng.randf_range(0.9, 1.2)}
	d.merge(extra, true)
	return d

# ====================================================================== build
func build(root_node, p_player):
	root = root_node
	player = p_player
	rng.seed = 42
	map = Node3D.new()
	map.name = "MapGeometry"
	root.add_child(map)
	B = Batcher.new(map)
	win_mat = StandardMaterial3D.new()
	win_mat.albedo_color = Color("2B3A44")
	win_mat.roughness = 0.15
	win_mat.emission_enabled = true
	win_mat.emission = Color(1.0, 0.8, 0.5)
	win_mat.emission_energy_multiplier = 0.0
	lamp_mat = StandardMaterial3D.new()
	lamp_mat.albedo_color = Color("FFE2A8")
	lamp_mat.emission_enabled = true
	lamp_mat.emission = Color(1.0, 0.85, 0.55)
	lamp_mat.emission_energy_multiplier = 0.6
	B.set_special("window", win_mat)
	B.set_special("lamp", lamp_mat)
	out = {"fries": {}, "npcs": [], "ordinary": null, "window_mat": win_mat, "lamp_mat": lamp_mat, "ground_h": Callable(Terrain, "H")}
	reserved = [[Vector2(-8, 3), 5.5], [Vector2(-2.5, 5.5), 4.0], [Vector2(-9.5, -2.5), 8.0], [Vector2(-16.5, 15), 4.0],
		[Vector2(-11, 11.5), 5.0], [Vector2(20, 19), 5.0], [Vector2(27, 14.5), 6.0], [Vector2(1.5, 66), 7.0]]
	MISCHIEF.reset_claims()
	foot = []
	extra = EXTRA_SCRIPT.new()
	extra.setup(self)
	town = TOWN_SCRIPT.new()
	town.setup(self)
	homes = HOMES_SCRIPT.new()
	homes.setup(self)
	flora = FLORA_SCRIPT.new()
	flora.setup(self)
	_environment()
	_terrain()
	_cafe()
	_boardwalk()
	_market()
	_kiosk()
	_beach()
	_playground()
	_pier()
	_marina()
	_hill()
	_church()
	_park()
	_harbor()
	_headland()
	_islet()
	_distant()
	_thermals()
	extra.build_places()
	town.build_places()
	_encounters()
	_prism_anchors()
	_dogs()
	_ambient()
	extra.build_life()
	town.build_life()
	homes.build_life()
	out["fish_spots"] = extra.build_fish_spots()
	out["volley"] = volley
	_mischief_balls()
	_ambient_gulls()
	flora.build()
	B.flush()
	out["anchors"] = anchors
	out["air_zones"] = zones
	out["spawn"] = SPAWN_POS
	return out

# ====================================================================== environment
func _environment():
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 10, 0)
	sun.light_color = Color("FFF1D6")
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 140.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY          # the sun in the sky is drawn by us (sky.gd): a crisp disc you can fly to
	root.add_child(sun)
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("4C7FB8")
	sky_mat.sky_horizon_color = Color("BFD8E8")
	sky_mat.ground_horizon_color = Color("BFD8E8")
	sky_mat.ground_bottom_color = Color("4A5A6A")
	sky_mat.sun_angle_max = 25.0
	sky_mat.sky_curve = 0.12
	var sky = Sky.new()
	sky.sky_material = sky_mat
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.fog_enabled = true
	env.fog_light_color = Color("D8E6EE")
	env.fog_density = 0.0004
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.0
	var we = WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	out["sun"] = sun
	out["env"] = env
	out["sky_mat"] = sky_mat
	var clouds = SkyBuilder.build_clouds(map, rng, [Vector3(22.0, 92.0, 74.0)])
	out["cloud_mat"] = clouds["mat"]
	out["sun_disc"] = SkyBuilder.build_sun(root)

func _terrain():
	var mesh = Terrain.build_mesh()
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.name = "Terrain"
	map.add_child(mi)
	var sb = StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask = 0
	var cs = CollisionShape3D.new()
	cs.shape = mesh.create_trimesh_shape()
	sb.add_child(cs)
	map.add_child(sb)
	var sea = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = Vector2(2600, 2600)
	pm.subdivide_width = 180
	pm.subdivide_depth = 180
	sea.mesh = pm
	var sm = ShaderMaterial.new()
	sm.shader = load("res://shaders/sea.gdshader")
	sea.material_override = sm
	sea.position = Vector3(0, Terrain.WATER_Y, 0)
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	map.add_child(sea)
	var floor_body = StaticBody3D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var fcs = CollisionShape3D.new()
	var fsh = BoxShape3D.new()
	fsh.size = Vector3(2600, 2, 2600)
	fcs.shape = fsh
	fcs.position = Vector3(0, -6.0, 0)
	floor_body.add_child(fcs)
	map.add_child(floor_body)

# ====================================================================== generic props
func lamp(x, z, y = -999.0, h = 3.4):
	if y < -900.0:
		y = gh(x, z)
	B.cyl(Vector3(x, y + h * 0.5, z), 0.07, h, "30343A", true)
	B.cyl(Vector3(x, y + h + 0.05, z), 0.2, 0.1, "30343A", true)
	B.ball(Vector3(x, y + h + 0.3, z), 0.2, "FFE2A8", Vector3.ONE, 0.0, false, "lamp")

func bench(x, z, yaw_deg, y = -999.0):
	if y < -900.0:
		y = gh(x, z)
	var yaw = deg_to_rad(yaw_deg)
	var f = Vector3(sin(yaw), 0, cos(yaw))
	var r = Vector3(cos(yaw), 0, -sin(yaw))
	var p = Vector3(x, y, z)
	B.box(p + Vector3(0, 0.45, 0), Vector3(1.7, 0.07, 0.5), WOOD, true, Vector3(0, yaw_deg, 0))
	B.box(p + Vector3(0, 0.8, 0) - f * 0.22, Vector3(1.7, 0.42, 0.06), WOOD, false, Vector3(0, yaw_deg, 0))
	B.box(p + Vector3(0, 0.22, 0) + r * 0.7, Vector3(0.08, 0.44, 0.44), SLATE, false, Vector3(0, yaw_deg, 0))
	B.box(p + Vector3(0, 0.22, 0) - r * 0.7, Vector3(0.08, 0.44, 0.44), SLATE, false, Vector3(0, yaw_deg, 0))

func chair(x, z, yaw_deg, y = -999.0):
	if y < -900.0:
		y = gh(x, z)
	var p = Vector3(x, y, z)
	var yaw = deg_to_rad(yaw_deg)
	var back = Vector3(sin(yaw), 0, cos(yaw)) * -0.2
	B.box(p + Vector3(0, 0.45, 0), Vector3(0.46, 0.05, 0.46), WOOD, true, Vector3(0, yaw_deg, 0))
	B.box(p + Vector3(0, 0.72, 0) + back, Vector3(0.46, 0.5, 0.05), WOOD, false, Vector3(0, yaw_deg, 0))
	for sx in [-0.19, 0.19]:
		for sz in [-0.19, 0.19]:
			B.box(p + Vector3(sx, 0.22, sz), Vector3(0.05, 0.44, 0.05), DARKWOOD, false)

func table(x, z, yaw_rad, y = -999.0, w = 1.0, d = 0.8):
	if y < -900.0:
		y = gh(x, z)
	var p = Vector3(x, y, z)
	var yd = rad_to_deg(yaw_rad)
	B.box(p + Vector3(0, 0.78, 0), Vector3(w, 0.06, d), WOOD, true, Vector3(0, yd, 0))
	B.box(p + Vector3(0, 0.38, 0), Vector3(0.1, 0.76, 0.1), DARKWOOD, false)
	B.box(p + Vector3(0, 0.02, 0), Vector3(0.5, 0.04, 0.5), DARKWOOD, false)

func patio_umbrella(x, z, col, y = -999.0):
	if y < -900.0:
		y = gh(x, z)
	B.cyl(Vector3(x, y + 1.25, z), 0.04, 2.5, "E8E2D2", false)
	B.cyl(Vector3(x, y + 2.55, z), 1.6, 0.4, col, true, 0.0)

func planter(x, z, y = -999.0):
	if y < -900.0:
		y = gh(x, z)
	B.box(Vector3(x, y + 0.3, z), Vector3(0.8, 0.6, 0.8), TERRA, true)
	B.ball(Vector3(x, y + 0.85, z), 0.5, "5F8F55", Vector3(1, 0.8, 1))
	for k in 3:
		B.ball(Vector3(x + rng.randf_range(-0.3, 0.3), y + 1.15, z + rng.randf_range(-0.3, 0.3)), 0.1, _pick(["E85745", "F1C94B", "F7C7D4", "FFFFFF"]))

func crate(x, z, s = 0.8, y = -999.0):
	if y < -900.0:
		y = gh(x, z)
	B.box(Vector3(x, y + s * 0.5, z), Vector3(s, s, s), "A98860", true, Vector3(0, rng.randf_range(0, 90), 0))

func bin(x, z, y = -999.0):
	if y < -900.0:
		y = gh(x, z)
	B.cyl(Vector3(x, y + 0.45, z), 0.28, 0.9, "586169", true)

func line(a, b, col = "D8D2C0", collide = true, flags = false):
	var d = b - a
	var len_ = d.length()
	var rot = Vector3(rad_to_deg(-asin(clamp(d.y / len_, -1.0, 1.0))), rad_to_deg(atan2(d.x, d.z)), 0)
	B.box((a + b) * 0.5, Vector3(0.05, 0.05, len_), col, collide, rot)
	if flags:
		var n = int(len_ / 1.1)
		for i in n:
			var u = (i + 0.5) / n
			var p = a.lerp(b, u) - Vector3(0, 0.22, 0)
			B.box(p, Vector3(0.28, 0.36, 0.02), _pick([CORAL, OCHRE, FADED_BLUE, SAGE, WHITE]), false, Vector3(0, rot.y, 0))

func tree(x, z, kind = 0, scale_v = 1.0):
	var y = gh(x, z)
	var s = scale_v
	match kind:
		0:
			var h = 5.5 * s
			B.cyl(Vector3(x, y + h * 0.5, z), 0.28 * s, h, "6B4E33", true)
			var gcol = _pick(["4F8A45", "5F9A4F", "447F3E"])
			B.ball(Vector3(x, y + h + 1.2 * s, z), 2.3 * s, gcol, Vector3(1, 0.85, 1))
			B.ball(Vector3(x + 1.4 * s, y + h + 0.4 * s, z + 0.5 * s), 1.6 * s, gcol)
			B.ball(Vector3(x - 1.2 * s, y + h + 0.6 * s, z - 0.8 * s), 1.5 * s, gcol)
			B.perch_pad(Vector3(x, y + h + 2.6 * s, z), 0.7)
		1:
			var h1 = 9.0 * s
			B.cyl(Vector3(x, y + h1 * 0.4, z), 0.25 * s, h1 * 0.8, "5A4332", true)
			for k in 4:
				B.cone(Vector3(x, y + 2.5 * s + k * 2.0 * s, z), (2.6 - k * 0.5) * s, 3.0 * s, "3F7A4A")
			B.perch_pad(Vector3(x, y + 9.4 * s, z), 0.4)
		_:
			var h2 = 7.5 * s
			B.cyl(Vector3(x, y + h2 * 0.5, z), 0.22 * s, h2, "8A6B4A", true)
			for k in 8:
				var a = k * TAU / 8.0
				B.box(Vector3(x + cos(a) * 1.2 * s, y + h2 - 0.15, z + sin(a) * 1.2 * s), Vector3(2.6 * s, 0.07, 0.55 * s), "4E8F4A" if k % 2 == 0 else "5FA050", false, Vector3(0, -rad_to_deg(a), -22))
			B.perch_pad(Vector3(x, y + h2 + 0.3, z), 0.6)

const SHUTTERS = ["4F7A66", "3E6F8E", "A94F3E", "6B4E7A", "2D6F5E", "C9A24A"]
const DOORS = ["6F5238", "A94F3E", "3E6F8E", "2D6F5E", "C9A24A", "3A3F4A"]

# a windowed wall seen from the front (+Z) and the back: frame, glass, shutters, sills, sometimes a flower box
func _facade(x, base, z, w, d, h, shutter, floors_override = -1):
	var floors = floors_override if floors_override > 0 else max(int(h / 3.0), 1)
	var cols = max(int(w / 3.2), 1)
	for f in floors:
		for c in cols:
			var wx = x - w * 0.5 + (c + 0.5) * w / cols
			var wy = base + 1.7 + f * 2.8
			if wy + 0.8 > base + h:
				continue
			if f == 0 and abs(wx - (x - w * 0.25)) < 1.2:
				continue            # the door is there
			B.box(Vector3(wx, wy, z + d * 0.5 + 0.03), Vector3(0.9, 1.2, 0.08), "", false, Vector3.ZERO, 0.0, "window")
			B.box(Vector3(wx, wy, z + d * 0.5 + 0.02), Vector3(1.2, 1.5, 0.05), CHALK, false)
			B.box(Vector3(wx, wy - 0.78, z + d * 0.5 + 0.1), Vector3(1.4, 0.08, 0.22), CHALK, false)
			B.box(Vector3(wx - 0.72, wy, z + d * 0.5 + 0.06), Vector3(0.28, 1.45, 0.06), shutter, false)
			B.box(Vector3(wx + 0.72, wy, z + d * 0.5 + 0.06), Vector3(0.28, 1.45, 0.06), shutter, false)
			if f > 0 and rng.randf() < 0.35:
				B.box(Vector3(wx, wy - 0.95, z + d * 0.5 + 0.28), Vector3(1.2, 0.26, 0.3), TERRA, false)
				for k in 4:
					B.ball(Vector3(wx - 0.45 + k * 0.3, wy - 0.76, z + d * 0.5 + 0.28), 0.1, _pick(["E85745", "F1C94B", "F7C7D4", "FFFFFF"]))
			B.box(Vector3(wx, wy, z - d * 0.5 - 0.03), Vector3(0.9, 1.2, 0.08), "", false, Vector3.ZERO, 0.0, "window")

# the house. Round 6: a real roof solid (you can stand on the tiles), a chimney that grows out of the slope, shutters, sills, a door with a hood.
# opts: {"door": colour, "shutter": colour, "floors": n, "chimney": bool}
func house(x, z, w, d, h, wall, roof_col, roof_kind = "pitched", opts = {}):
	var g1 = gh(x - w * 0.5, z - d * 0.5)
	var g2 = gh(x + w * 0.5, z - d * 0.5)
	var g3 = gh(x - w * 0.5, z + d * 0.5)
	var g4 = gh(x + w * 0.5, z + d * 0.5)
	var y0 = min(min(g1, g2), min(g3, g4))
	var yb = max(max(g1, g2), max(g3, g4))
	B.box(Vector3(x, (y0 - 5.0 + yb) * 0.5, z), Vector3(w + 0.2, yb - y0 + 5.0, d + 0.2), "9A9484", true)
	var base = yb
	var wallc = Color(wall)
	B.box(Vector3(x, base + h * 0.5, z), Vector3(w, h, d), wall, true)
	B.box(Vector3(x, base + 0.3, z), Vector3(w + 0.14, 0.6, d + 0.14), wallc.darkened(0.18), false)         # a darker skirting
	var shutter = opts.get("shutter", _pick(SHUTTERS))
	var top = base + h
	if roof_kind == "pitched":
		var along_x = w >= d
		var span = d if along_x else w
		var rh = min(span * 0.36, 3.4)
		if along_x:
			B.prism(Vector3(x, base + h + rh * 0.5, z), Vector3(w + 0.9, rh, d + 0.9), roof_col, true)
		else:
			B.prism(Vector3(x, base + h + rh * 0.5, z), Vector3(d + 0.9, rh, w + 0.9), roof_col, true, Vector3(0, 90, 0))
		# the chimney: its foot is inside the roof, its top above the ridge (the roof is lower where it is further from the ridge)
		if opts.get("chimney", rng.randf() < 0.55) and span > 5.0:
			var off = span * 0.2 * (1.0 if rng.randf() < 0.5 else -1.0)
			var roof_here = rh * (1.0 - abs(off) / (span * 0.5 + 0.45))
			var ch_h = roof_here + 1.3
			var along = (rng.randf() - 0.5) * (w if along_x else d) * 0.5
			var cp = Vector3(x + (along if along_x else off), base + h + (ch_h - 0.6) * 0.5, z + (off if along_x else along))
			B.box(cp, Vector3(0.7, ch_h + 0.6, 0.7), "8B6A5A", true)
			B.box(cp + Vector3(0, (ch_h + 0.6) * 0.5 + 0.08, 0), Vector3(0.9, 0.16, 0.9), "6F5238", false)
	else:
		B.box(Vector3(x, base + h + 0.15, z), Vector3(w + 0.6, 0.3, d + 0.6), roof_col, true)
		for sx in [-1.0, 1.0]:
			B.box(Vector3(x + sx * (w * 0.5 + 0.25), base + h + 0.55, z), Vector3(0.2, 0.5, d + 0.6), wall, true)
		for sz in [-1.0, 1.0]:
			B.box(Vector3(x, base + h + 0.55, z + sz * (d * 0.5 + 0.25)), Vector3(w + 0.6, 0.5, 0.2), wall, true)
		top = base + h + 0.3
	_facade(x, base, z, w, d, h, shutter, opts.get("floors", -1))
	var dcol = opts.get("door", _pick(DOORS))
	B.box(Vector3(x - w * 0.25, base + 1.05, z + d * 0.5 + 0.03), Vector3(0.95, 2.1, 0.08), dcol, false)
	B.box(Vector3(x - w * 0.25, base + 2.28, z + d * 0.5 + 0.22), Vector3(1.5, 0.12, 0.6), roof_col, false)    # a little hood over the door
	if rng.randf() < 0.4 and h > 4.5:
		B.box(Vector3(x + w * 0.25, base + 3.2, z + d * 0.5 + 0.6), Vector3(1.8, 0.1, 1.1), WOOD, true)
		B.box(Vector3(x + w * 0.25, base + 3.75, z + d * 0.5 + 1.1), Vector3(1.8, 0.8, 0.05), WOOD, false)
	return base + h


# ====================================================================== districts
func _cafe():
	B.box(Vector3(-9.5, 2.25, -2.5), Vector3(12, 4.5, 5), CHALK)
	B.box(Vector3(-9.5, 4.65, -2.5), Vector3(12.8, 0.3, 5.8), TERRA)
	B.box(Vector3(-9.5, 3.55, 0.9), Vector3(11.5, 0.12, 2.6), SAGE, true, Vector3(10, 0, 0))
	for x in [-14.5, -9.5, -4.5]:
		B.box(Vector3(x, 1.7, 1.9), Vector3(0.08, 3.4, 0.08), DARKWOOD, false)
	for x in [-13.0, -9.5, -6.0]:
		B.box(Vector3(x, 1.9, 0.03), Vector3(1.6, 1.4, 0.08), "", false, Vector3.ZERO, 0.0, "window")
		B.box(Vector3(x, 1.9, 0.02), Vector3(2.0, 1.7, 0.05), CREAM, false)
	B.box(Vector3(-11.5, 1.1, 0.03), Vector3(1.1, 2.2, 0.08), DARKWOOD, false)
	B.box(Vector3(-9.5, 4.1, 0.1), Vector3(3.4, 0.55, 0.12), CORAL, false)
	B.box(Vector3(-14.0, 5.6, -3.5), Vector3(0.7, 1.6, 0.7), "8B6A5A", true)
	for p in [Vector2(-14.5, 1.0), Vector2(-4.0, 1.2), Vector2(0.2, 3.0), Vector2(-15.5, 3.4)]:
		planter(p.x, p.y)
	for x in range(-16, 2, 2):
		B.box(Vector3(x, 0.3, 8.2), Vector3(0.08, 0.6, 0.08), CHALK, false)
	B.box(Vector3(-7, 0.55, 8.2), Vector3(18, 0.05, 0.05), CHALK, false)
	table(-11.5, 6.2, 0.0)
	table(-5.0, 8.4, 0.0)
	table(-1.0, 1.4, 0.3)
	patio_umbrella(-11.5, 6.2, CORAL)
	patio_umbrella(-1.0, 1.4, FADED_BLUE)
	for c in [[-11.5, 7.2, 180], [-12.5, 6.2, 90], [-5.0, 9.3, 180], [-0.2, 0.7, 20], [-9.2, 1.6, 0], [-6.8, 2.6, 30], [-13.4, 4.3, 90], [-10.5, 4.3, 270]]:
		chair(c[0], c[1], c[2])
	bin(-16.5, 5.0)
	bench(-17.5, 6.5, 90)
	lamp(-17.0, 2.0)
	lamp(1.8, 6.0)
	B.perch_pad(Vector3(-9.5, 4.8, -0.8), 1.2)

func _boardwalk():
	B.box(Vector3(-22, 0.03, 11.25), Vector3(84, 0.06, 4.5), "A8896A", false)
	B.box(Vector3(1, 0.03, 19.75), Vector3(6, 0.06, 12.5), "A8896A", false)
	for x in range(-66, 20, 12):
		lamp(x, 9.2)
	bench(-6, 13.2, 180)
	bench(8, 13.2, 180)
	bench(-20, 9.6, 0)
	bench(-34, 13.0, 180)
	bin(-9.0, 13.3)
	bin(-14.0, 9.4)
	bin(-40.0, 13.3)
	for x in range(-66, -3, 2):
		B.box(Vector3(x, 0.45, 14.0), Vector3(0.06, 0.9, 0.06), CHALK, false)
	B.box(Vector3(-34.5, 0.9, 14.0), Vector3(63, 0.05, 0.05), CHALK, false)
	for x in range(6, 17, 2):
		B.box(Vector3(x, 0.45, 14.0), Vector3(0.06, 0.9, 0.06), CHALK, false)
	B.box(Vector3(11, 0.9, 14.0), Vector3(10, 0.05, 0.05), CHALK, false)
	planter(-3.0, 9.2)
	planter(5.0, 9.2)
	planter(-26.0, 9.2)
	for pair in [[-42, -54], [-54, -66]]:
		line(Vector3(pair[0], 3.5, 9.2), Vector3(pair[1], 3.5, 9.2), "D8D2C0", true, true)
	line(Vector3(-10, 3.5, 9.2), Vector3(2, 3.5, 9.2), "D8D2C0", true, true)

func _market():
	var cols = [CORAL, FADED_BLUE, OCHRE, SAGE, CORAL]
	var xs = [-34, -40, -46, -52, -58]
	for i in xs.size():
		var x = xs[i]
		var z = 18.0
		B.box(Vector3(x, 0.5, z), Vector3(2.6, 1.0, 1.1), WOOD, true)
		B.box(Vector3(x, 1.4, z + 0.6), Vector3(2.6, 2.8, 0.1), CHALK, true)
		for sx in [-1.3, 1.3]:
			B.box(Vector3(x + sx, 1.5, z - 0.5), Vector3(0.08, 3.0, 0.08), DARKWOOD, false)
		for k in 4:
			B.box(Vector3(x - 1.1 + k * 0.74, 3.05, z - 0.05), Vector3(0.74, 0.1, 1.9), cols[i] if k % 2 == 0 else WHITE, true, Vector3(-10, 0, 0))
		for k in 5:
			B.ball(Vector3(x - 1.0 + k * 0.5, 1.12, z - 0.1), 0.13, _pick(["E85745", "F1A93A", "7FB04B", "F7D56A"]))
		crate(x + 1.9, z - 0.2, 0.7)
	table(-30.0, 16.0, 0.0)
	chair(-30.0, 17.0, 180)
	bench(-46, 22.5, 0)

func _kiosk():
	B.box(Vector3(-21, 1.5, 17), Vector3(4.5, 3.0, 3.0), CREAM)
	B.box(Vector3(-21, 3.1, 17), Vector3(4.9, 0.2, 3.4), CORAL)
	B.box(Vector3(-18.72, 1.8, 17), Vector3(0.1, 1.0, 2.2), "", false, Vector3.ZERO, 0.0, "window")
	B.box(Vector3(-18.2, 2.7, 17), Vector3(1.6, 0.1, 3.4), CREAM, false)
	B.box(Vector3(-18.64, 2.35, 17), Vector3(0.1, 0.5, 3.0), CORAL, false, Vector3.ZERO, 0.4)
	B.box(Vector3(-18.9, 1.2, 17), Vector3(0.5, 0.08, 2.2), WOOD, false)
	for z in [16.2, 17.0, 17.8]:
		B.box(Vector3(-18.9, 1.34, z), Vector3(0.22, 0.2, 0.12), "C8372D", false)
	table(-13.5, 17.5, 0.0)
	chair(-13.5, 18.5, 180)
	chair(-14.5, 17.5, 90)
	table(-14.0, 11.0, 0.0)
	chair(-20, 10, 0)
	patio_umbrella(-13.5, 17.5, CORAL)
	bin(-16.0, 19.0)

func _free_pos(x0, x1, z0, z1, r = 2.5, tries = 20):
	for i in tries:
		var x = rng.randf_range(x0, x1)
		var z = rng.randf_range(z0, z1)
		if Terrain.is_land(x, z) and gh(x, z) > -0.2 and _free(x, z, r):
			return Vector2(x, z)
	return null

func _beach():
	var ucols = [CORAL, FADED_BLUE, OCHRE, WHITE, SAGE]
	for i in 11:
		var p = _free_pos(14, 72, 8, 36, 4.0)
		if p == null:
			continue
		var gy = gh(p.x, p.y)
		B.cyl(Vector3(p.x, gy + 1.1, p.y), 0.04, 2.2, WHITE, false)
		B.cyl(Vector3(p.x, gy + 2.3, p.y), 1.5, 0.45, ucols[i % 5], true, 0.0)
		var hip = lounger(p.x + 0.9, gy, p.y + 0.9, 0.0, ucols[(i + 2) % 5])
		if i % 3 == 0:
			beach_loungers.append(hip)
		B.box(Vector3(p.x - 0.9, gy + 0.02, p.y - 0.6), Vector3(1.8, 0.04, 0.9), _pick(ucols), false, Vector3(0, rng.randf_range(-30, 30), 0))
	for i in 10:
		var p2 = _free_pos(12, 76, 6, 40, 2.0)
		if p2 != null:
			B.box(Vector3(p2.x, gh(p2.x, p2.y) + 0.02, p2.y), Vector3(1.8, 0.04, 0.9), _pick(ucols), false, Vector3(0, rng.randf_range(-30, 30), 0))
	B.cyl(Vector3(52, 1.3, 14), 0.06, 2.6, WHITE, true)
	B.cyl(Vector3(52, 1.3, 23), 0.06, 2.6, WHITE, true)
	B.box(Vector3(52, 1.9, 18.5), Vector3(0.04, 0.9, 9.0), "DDD8CC", true)
	B.box(Vector3(34, 0.3, 30), Vector3(1.6, 0.6, 1.6), "C7B38A", true)
	B.box(Vector3(34, 0.85, 30), Vector3(1.0, 0.5, 1.0), "C7B38A", false)
	B.box(Vector3(33.2, 0.5, 30.8), Vector3(0.5, 1.0, 0.5), "C7B38A", false)
	B.ball(Vector3(26.0, 0.3, 24.0), 0.3, CORAL)
	for i in 8:
		var p3 = _free_pos(10, 80, 8, 44, 1.0)
		if p3 != null:
			B.ball(Vector3(p3.x, gh(p3.x, p3.y) + 0.15, p3.y), rng.randf_range(0.25, 0.7), "8D8A80", Vector3(1, 0.7, 1), 0.0, true)
	var lx = 40.0
	var lz = 36.0
	var ly = gh(lx, lz)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			B.cyl(Vector3(lx + sx * 1.2, ly + 1.4, lz + sz * 1.2), 0.1, 2.8, WOOD, true)
	B.box(Vector3(lx, ly + 2.9, lz), Vector3(3.2, 0.2, 3.2), WOOD, true)
	B.box(Vector3(lx, ly + 4.1, lz - 1.3), Vector3(3.0, 2.2, 0.15), WHITE, true)
	B.box(Vector3(lx - 1.4, ly + 4.1, lz), Vector3(0.15, 2.2, 2.6), WHITE, true)
	B.box(Vector3(lx + 1.4, ly + 4.1, lz), Vector3(0.15, 2.2, 2.6), WHITE, true)
	B.box(Vector3(lx, ly + 5.3, lz), Vector3(3.6, 0.2, 3.6), CORAL, true)
	B.cyl(Vector3(lx + 1.6, ly + 6.5, lz + 1.6), 0.04, 2.4, WHITE, false)
	B.box(Vector3(lx + 2.0, ly + 7.3, lz + 1.6), Vector3(0.8, 0.5, 0.03), CORAL, false)
	B.box(Vector3(lx, ly + 1.5, lz + 2.4), Vector3(0.7, 3.2, 0.08), WOOD, false, Vector3(-18, 0, 0))
	anchors["lifeguard"] = Vector3(lx, ly + 6.5, lz)
	for i in 5:
		var hx = 22.0 + i * 9.0
		var hc = ucols[i % 5]
		B.box(Vector3(hx, 1.2, 6.5), Vector3(2.4, 2.4, 2.2), hc, true)
		B.prism(Vector3(hx, 2.9, 6.5), Vector3(2.8, 0.9, 2.6), WHITE, true)
		B.box(Vector3(hx, 1.0, 7.65), Vector3(0.8, 2.0, 0.08), WHITE, false)
	for i in 9:
		var pp = _free_pos(12, 80, 28, 46, 3.0)
		if pp != null and gh(pp.x, pp.y) > -0.3:
			tree(pp.x, pp.y, 2, rng.randf_range(0.9, 1.3))
	var kite_cols = [CORAL, OCHRE, FADED_BLUE, SAGE, "F7C7D4", "E85745"]
	for i in 6:
		var kx = rng.randf_range(24, 70)
		var kz = rng.randf_range(10, 34)
		var ky = rng.randf_range(11, 24)
		var kt = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(1.1, 1.1, 0.04)
		kt.mesh = bm
		var km = StandardMaterial3D.new()
		km.albedo_color = Color(kite_cols[i])
		kt.material_override = km
		kt.rotation_degrees = Vector3(20, rng.randf_range(0, 360), 45)
		kt.position = Vector3(kx, ky, kz)
		map.add_child(kt)
		var kstr = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = 0.01
		cm.bottom_radius = 0.01
		cm.height = ky
		kstr.mesh = cm
		kstr.material_override = km
		kstr.position = Vector3(kx - 3.0, ky * 0.5, kz)
		kstr.rotation_degrees = Vector3(0, 0, -12)
		map.add_child(kstr)
		if i == 3:
			anchors["kite"] = Vector3(kx, ky - 1.0, kz)

func _playground():
	var px = 31.0
	var pz = 8.0
	for sx in [-1.0, 1.0]:
		B.box(Vector3(px + sx * 1.6, 1.4, pz - 1.0), Vector3(0.12, 2.8, 0.12), CORAL, true, Vector3(0, 0, -sx * 10))
		B.box(Vector3(px + sx * 1.6, 1.4, pz + 1.0), Vector3(0.12, 2.8, 0.12), CORAL, true, Vector3(0, 0, sx * 10))
	B.box(Vector3(px, 2.7, pz), Vector3(3.6, 0.12, 0.12), CORAL, true)
	for sx in [-0.6, 0.6]:
		B.box(Vector3(px + sx, 1.5, pz), Vector3(0.03, 2.4, 0.03), "30343A", false)
		B.box(Vector3(px + sx, 0.4, pz), Vector3(0.5, 0.06, 0.25), WOOD, false)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			B.box(Vector3(px + 7 + sx, 1.0, pz + sz), Vector3(0.12, 2.0, 0.12), CORAL, true)
	B.box(Vector3(px + 7, 2.0, pz), Vector3(2.4, 0.12, 2.4), OCHRE, true)
	B.box(Vector3(px + 9.6, 1.0, pz), Vector3(3.2, 0.1, 0.9), FADED_BLUE, true, Vector3(0, 0, -34))
	B.box(Vector3(px + 7, 3.2, pz), Vector3(2.6, 0.12, 2.6), FADED_BLUE, true)
	B.box(Vector3(px - 6, 0.15, pz + 4), Vector3(3.2, 0.3, 3.2), WOOD, true)
	B.box(Vector3(px - 6, 0.32, pz + 4), Vector3(2.9, 0.05, 2.9), "E5D3A6", false)
	B.box(Vector3(px - 6, 0.5, pz - 3), Vector3(3.4, 0.1, 0.3), OCHRE, true, Vector3(0, 0, 8))
	B.box(Vector3(px - 6, 0.25, pz - 3), Vector3(0.3, 0.5, 0.3), SLATE, true)
	anchors["playground_top"] = Vector3(px + 7, 4.2, pz)

func _pier():
	B.box(Vector3(1, 0.2, 50), Vector3(8, 0.4, 52), WOOD, true)
	B.box(Vector3(2, 0.2, 55), Vector3(26, 0.4, 14), WOOD, true)
	for z in range(26, 76, 4):
		for x in [-2.7, 4.7]:
			B.cyl(Vector3(x, -1.4, z), 0.18, 3.2, "5A4332", false)
	for z in range(26, 77, 2):
		B.box(Vector3(-2.9, 0.95, z), Vector3(0.07, 1.1, 0.07), CHALK, false)
		B.box(Vector3(4.9, 0.95, z), Vector3(0.07, 1.1, 0.07), CHALK, false)
	B.box(Vector3(-2.9, 1.45, 51), Vector3(0.06, 0.06, 52), CHALK, false)
	B.box(Vector3(4.9, 1.45, 51), Vector3(0.06, 0.06, 52), CHALK, false)
	B.box(Vector3(1, 1.45, 76.5), Vector3(8, 0.06, 0.06), CHALK, false)
	for z in [30, 38, 46, 66, 74]:
		lamp(-2.7, z, 0.4, 3.0)
		lamp(4.7, z, 0.4, 3.0)
	bench(-1.6, 33.0, 90, 0.4)
	bench(3.6, 41.0, 270, 0.4)
	for p in [[3.6, 69.0], [-1.8, 74.0], [3.6, 30.0]]:
		crate(p[0], p[1], 0.85, 0.4)
	B.box(Vector3(-2.5, 0.6, 52), Vector3(0.4, 0.4, 0.4), "3A3F4A", true)
	var lb = MeshInstance3D.new()
	var tm = TorusMesh.new()
	tm.inner_radius = 0.12
	tm.outer_radius = 0.32
	lb.mesh = tm
	var lm = StandardMaterial3D.new()
	lm.albedo_color = Color(CORAL)
	lb.material_override = lm
	lb.position = Vector3(4.85, 1.0, 34)
	lb.rotation_degrees = Vector3(0, 0, 90)
	map.add_child(lb)
	var hub = Vector3(2, 13.0, 55)
	B.box(Vector3(-4, 6.5, 55), Vector3(0.6, 13.5, 0.6), SLATE, true, Vector3(0, 0, -13))
	B.box(Vector3(8, 6.5, 55), Vector3(0.6, 13.5, 0.6), SLATE, true, Vector3(0, 0, 13))
	B.box(Vector3(-4, 6.5, 52.4), Vector3(0.6, 13.5, 0.6), SLATE, true, Vector3(0, 0, -13))
	B.box(Vector3(8, 6.5, 52.4), Vector3(0.6, 13.5, 0.6), SLATE, true, Vector3(0, 0, 13))
	var wheel = AnimatableBody3D.new()
	wheel.set_script(ANIM_SCRIPT)
	wheel.collision_layer = 1
	wheel.collision_mask = 0
	wheel.axis = Vector3(0, 0, 1)
	wheel.rate = 0.17
	wheel.position = hub
	map.add_child(wheel)
	var R = 10.0
	var rimc = [CORAL, OCHRE, FADED_BLUE, SAGE]
	for i in 16:
		var a = i * TAU / 16.0
		var seg_len = 2 * R * sin(PI / 16.0) + 0.1
		_mesh_box(wheel, Vector3(cos(a) * R, sin(a) * R, 0), Vector3(seg_len, 0.35, 0.35), WHITE, rad_to_deg(a) + 90.0)
		_coll_box(wheel, Vector3(cos(a) * R, sin(a) * R, 0), Vector3(seg_len, 0.35, 0.35), rad_to_deg(a) + 90.0)
	for i in 8:
		var a2 = i * TAU / 8.0
		_mesh_box(wheel, Vector3(cos(a2) * R * 0.5, sin(a2) * R * 0.5, 0), Vector3(R, 0.22, 0.22), SLATE, rad_to_deg(a2))
		_coll_box(wheel, Vector3(cos(a2) * R * 0.5, sin(a2) * R * 0.5, 0), Vector3(R, 0.22, 0.22), rad_to_deg(a2))
	_mesh_box(wheel, Vector3.ZERO, Vector3(1.2, 1.2, 1.4), SLATE, 0.0)
	var gondolas = []
	for i in 10:
		var a3 = i * TAU / 10.0
		var g = Node3D.new()
		g.position = Vector3(cos(a3) * R, sin(a3) * R, 0)
		wheel.add_child(g)
		_mesh_box(g, Vector3(0, -0.9, 0), Vector3(1.4, 1.1, 1.2), rimc[i % 4], 0.0)
		_mesh_box(g, Vector3(0, -0.25, 0), Vector3(1.5, 0.08, 1.3), WHITE, 0.0)
		gondolas.append(g)
	wheel.upright = gondolas
	anchors["ferris"] = hub + Vector3(0, 4.5, 0)
	anchors["buoy"] = Vector3(16, 0.9, 74)
	B.cyl(Vector3(16, 0.1, 74), 0.5, 0.9, CORAL, false)
	B.cyl(Vector3(16, 0.9, 74), 0.3, 0.9, WHITE, false)

func _mesh_box(parent, pos, size, col, rot_z_deg):
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(col)
	m.roughness = 0.9
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = Vector3(0, 0, rot_z_deg)
	parent.add_child(mi)
	return mi

func _coll_box(parent, pos, size, rot_z_deg):
	var cs = CollisionShape3D.new()
	var sh = BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position = pos
	cs.rotation_degrees = Vector3(0, 0, rot_z_deg)
	parent.add_child(cs)

func _marina():
	for x in [-12.0, -20.0, -28.0]:
		B.box(Vector3(x, 0.15, 35.5), Vector3(1.6, 0.3, 17), WOOD, true)
		for z in range(28, 44, 4):
			B.cyl(Vector3(x - 0.7, -1.2, z), 0.14, 2.8, "5A4332", false)
			B.cyl(Vector3(x + 0.7, -1.2, z), 0.14, 2.8, "5A4332", false)
	var bcols = [CHALK, FADED_BLUE, CORAL, SAGE, OCHRE]
	var bi = 0
	for x in [-16.0, -24.0, -32.0, -8.0]:
		for z in [33.0, 40.0]:
			_boat(Vector3(x, -0.45, z), 0.0, bcols[bi % 5], x == -16.0 and z == 40.0)
			bi += 1
	B.box(Vector3(-36, 2.0, 22.5), Vector3(7, 4.0, 5), CREAM, true)
	B.prism(Vector3(-36, 4.7, 22.5), Vector3(7.8, 1.6, 5.8), TERRA, true)
	B.box(Vector3(-36, 1.9, 25.05), Vector3(1.0, 2.0, 0.08), DARKWOOD, false)
	for x in [-38.5, -33.5]:
		B.box(Vector3(x, 2.4, 25.05), Vector3(1.2, 1.1, 0.08), "", false, Vector3.ZERO, 0.0, "window")
	bin(-30.0, 24.0)
	lamp(-26.0, 25.0)

const BOAT_ROOFS = ["D96D5F", "2D6F5E", "C9A24A", "3E6F8E", "A94F3E"]

# a little sailing boat (bow towards +Z before the yaw): hull with a pointed bow, deck, cabin, mast, boom, sail and a flag. Returns the deck spot
# where somebody can stand (it is solid: a gull can land on it).
func _boat(p, yaw_deg, col, mast_anchor = false):
	var bs = Basis.from_euler(Vector3(0, deg_to_rad(yaw_deg), 0))
	var yw = Vector3(0, yaw_deg, 0)
	B.box(p + bs * Vector3(0, 0, -0.3), Vector3(2.0, 0.85, 4.2), col, true, yw)
	for s in [-1.0, 1.0]:
		B.box(p + bs * Vector3(s * 0.5, 0, 2.15), Vector3(1.1, 0.85, 1.9), col, true, Vector3(0, yaw_deg - s * 28.0, 0))
	B.box(p + bs * Vector3(0, 0.2, -0.3), Vector3(2.06, 0.12, 4.3), "F4F4F0", false, yw)
	B.box(p + bs * Vector3(0, 0.46, 0.2), Vector3(1.8, 0.08, 4.8), "B8A07A", true, yw)
	var roof = BOAT_ROOFS[int(abs(p.x * 3.0 + p.z)) % BOAT_ROOFS.size()]
	B.box(p + bs * Vector3(0, 1.0, -1.3), Vector3(1.4, 1.0, 1.4), WHITE, true, yw)
	B.box(p + bs * Vector3(0, 1.55, -1.3), Vector3(1.6, 0.1, 1.6), roof, true, yw)
	B.box(p + bs * Vector3(0, 1.1, -0.58), Vector3(1.0, 0.4, 0.05), "", false, yw, 0.0, "window")
	B.cyl(p + bs * Vector3(0, 2.9, 0.9), 0.06, 4.9, "E8E2D2", false)
	B.box(p + bs * Vector3(0, 1.3, -0.1), Vector3(0.06, 0.06, 2.3), "E8E2D2", false, yw)
	B.prism(p + bs * Vector3(0, 3.3, -0.1), Vector3(0.05, 3.4, 2.2), "F7F4EA", false, yw)
	B.box(p + bs * Vector3(0, 5.2, 0.62), Vector3(0.04, 0.34, 0.5), roof, false, yw)
	B.perch_pad(p + bs * Vector3(0, 5.42, 0.9), 0.3)
	for s2 in [-1.0, 1.0]:
		B.ball(p + bs * Vector3(s2 * 1.04, 0.1, -0.6), 0.14, "F4F1E8", Vector3.ONE, 0.0, false)
	if mast_anchor:
		anchors["mast"] = p + bs * Vector3(0, 6.0, 0.9)
	return p + bs * Vector3(0, 0.5, 0.9)

func _hill():
	homes.build_hill()
	# trees on the shelves and banks, only where there is room
	var placed = 0
	for i in 140:
		if placed >= 46:
			break
		var tx = rng.randf_range(-70, 70)
		var tz = rng.randf_range(-92, -24)
		if abs(tx) > 4.5 and Terrain.is_land(tx, tz) and gh(tx, tz) > 0.2 and not extra.in_plaza(tx, tz, 6.0) and not (tx > 66.0 and tz < -48.0) and is_clear(tx, tz, 1.5):
			if Vector2(tx, tz).distance_to(Vector2(-26, -61)) < 14.0:
				continue
			tree(tx, tz, 1 if rng.randf() < 0.6 else 0, rng.randf_range(0.8, 1.3))
			placed += 1

func _pocket(cx, cz, w_, d_):
	var y = gh(cx, cz)
	B.box(Vector3(cx, y + 0.12, cz), Vector3(w_, 0.24, d_), "6FA04A", true)
	for k in 8:
		B.ball(Vector3(cx - w_ * 0.4 + k * w_ * 0.11, y + 0.34, cz + d_ * 0.38), 0.14, _pick(["E85745", "F1C94B", "F7C7D4", "FFFFFF", "A98FB8"]))
	bench(cx, cz + d_ * 0.25, 0, y + 0.24)
	tree(cx - w_ * 0.3, cz - d_ * 0.15, 0, 0.9)
	if rng.randf() < 0.4:
		B.cyl(Vector3(cx + w_ * 0.28, y + 0.5, cz - d_ * 0.1), 0.9, 0.5, "B8BEC4", true)
		B.cyl(Vector3(cx + w_ * 0.28, y + 0.78, cz - d_ * 0.1), 0.75, 0.06, "5B9AA8", false)

func _church():
	var cx = -26.0
	var cz = -62.0
	var y = gh(cx, cz)
	B.box(Vector3(cx, y - 3.0, cz + 2.0), Vector3(12.0, 8.0, 22.0), "9A9484", true)        # the plinth and forecourt
	B.box(Vector3(cx, y + 3.0, cz + 2.0), Vector3(6.5, 6.0, 12.0), CHALK, true)
	B.prism(Vector3(cx, y + 6.5, cz + 2.0), Vector3(13.0, 2.8, 7.4), SLATE, true, Vector3(0, 90, 0))
	B.box(Vector3(cx, y + 10.0, cz - 5.5), Vector3(4.6, 20.0, 4.6), CHALK, true)
	B.box(Vector3(cx, y + 17.0, cz - 3.2), Vector3(2.4, 3.0, 0.2), "2B3A44", false)
	B.box(Vector3(cx, y + 20.2, cz - 5.5), Vector3(5.2, 0.5, 5.2), TERRA, true)
	B.box(Vector3(cx, y + 21.6, cz - 5.5), Vector3(0.25, 2.4, 0.25), "30343A", false)
	B.box(Vector3(cx, y + 22.2, cz - 5.5), Vector3(1.2, 0.25, 0.25), "30343A", false)
	B.perch_pad(Vector3(cx + 1.8, y + 20.5, cz - 5.5 + 1.8), 0.7)
	B.box(Vector3(cx, y + 2.0, cz + 8.05), Vector3(1.6, 3.2, 0.1), DARKWOOD, false)
	for sx in [-1.0, 1.0]:
		B.box(Vector3(cx + sx * 2.6, y + 3.0, cz + 8.03), Vector3(0.9, 1.6, 0.08), "", false, Vector3.ZERO, 0.0, "window")
	anchors["church"] = Vector3(cx + 1.8, y + 22.0, cz - 3.0)
	add_foot(cx, cz + 2.0, 7.0, 13.0)

func _park():
	var pond = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 8.0
	cm.bottom_radius = 8.0
	cm.height = 0.06
	cm.radial_segments = 24
	pond.mesh = cm
	var pm = StandardMaterial3D.new()
	pm.albedo_color = Color("5B9AA8")
	pm.roughness = 0.1
	pond.material_override = pm
	pond.position = Vector3(-60, 0.04, -12)
	map.add_child(pond)
	B.cyl(Vector3(-45, 0.3, -6), 2.4, 0.6, "B8BEC4", true)
	B.cyl(Vector3(-45, 0.9, -6), 0.6, 1.2, "B8BEC4", true)
	B.cyl(Vector3(-45, 1.6, -6), 1.2, 0.2, "B8BEC4", true)
	for k in 8:
		var a = k * TAU / 8.0
		B.box(Vector3(-45 + cos(a) * 4.0, 0.03, -6 + sin(a) * 4.0), Vector3(1.6, 0.05, 6.0), "CFC6B0", false, Vector3(0, -rad_to_deg(a), 0))
	for z in range(-30, 12, 7):
		for x in range(-84, -32, 7):
			var tx = x + rng.randf_range(-2.5, 2.5)
			var tz = z + rng.randf_range(-2.5, 2.5)
			if Vector2(tx, tz).distance_to(Vector2(-60, -12)) < 10.5 or Vector2(tx, tz).distance_to(Vector2(-45, -6)) < 6.5:
				continue
			if not Terrain.is_land(tx, tz):
				continue
			var k2 = rng.randf()
			tree(tx, tz, 0 if k2 < 0.55 else (1 if k2 < 0.85 else 2), rng.randf_range(0.85, 1.3))
	bench(-40.0, -6.0, 90)
	bench(-50.0, -6.0, 270)
	bench(-45.0, 0.0, 180)
	bench(-45.0, -12.0, 0)
	for p in [[-52.0, -2.0], [-38.0, -12.0], [-70.0, -4.0], [-56.0, 6.0]]:
		lamp(p[0], p[1])
	table(-70.0, 4.0, 0.0)
	chair(-70.0, 5.0, 180)
	chair(-70.0, 3.0, 0)
	for i in 30:
		var fx = rng.randf_range(-82, -34)
		var fz = rng.randf_range(-32, 10)
		if Vector2(fx, fz).distance_to(Vector2(-60, -12)) > 9.0:
			B.ball(Vector3(fx, gh(fx, fz) + 0.15, fz), 0.12, _pick(["E85745", "F1C94B", "F7C7D4", "FFFFFF", "A98FB8"]))

func _harbor():
	var ccols = ["7396A8", "D96D5F", "879B82", "D9B25F", "8B6A5A", "586169"]
	for row in 3:
		for col in 4:
			var cx = 58.0 + col * 11.0
			var cz = -40.0 + row * 14.0
			var stack = rng.randi_range(1, 3)
			for lvl in stack:
				B.box(Vector3(cx, 1.3 + lvl * 2.6, cz), Vector3(6.0, 2.6, 2.5), ccols[(row * 4 + col + lvl) % 6], true)
			if row == 1 and col == 2:
				anchors["containers"] = Vector3(cx, 2.6 * stack + 2.2 + gh(cx, cz), cz)   # always just above the stack, whatever its height
	for cxx in [72.0, 100.0]:
		for dz in [-8.0, 8.0]:
			B.box(Vector3(cxx, 11.0, 4.0 + dz), Vector3(1.2, 22.0, 1.2), "D9A441", true)
		B.box(Vector3(cxx, 22.5, 4.0), Vector3(1.6, 1.6, 22.0), "D9A441", true)
		B.box(Vector3(cxx, 23.5, 4.0), Vector3(2.4, 0.4, 4.0), SLATE, true)
		B.cyl(Vector3(cxx, 18.0, 4.0), 0.05, 9.0, "30343A", false)
		B.box(Vector3(cxx, 13.4, 4.0), Vector3(0.7, 0.4, 0.7), SLATE, true)
		B.perch_pad(Vector3(cxx, 23.9, 4.0), 0.9)
	anchors["crane_hook"] = Vector3(72.0, 11.4, 4.0)
	B.box(Vector3(98.0, 4.0, -34.0), Vector3(22.0, 8.0, 14.0), "A9BCC4", true)
	B.prism(Vector3(98.0, 8.9, -34.0), Vector3(23.0, 2.4, 15.0), SLATE, true)
	for x in range(2, 20, 4):
		B.box(Vector3(88.0 + x, 4.0, -26.95), Vector3(2.4, 3.0, 0.08), "", false, Vector3.ZERO, 0.0, "window")
	for i in 8:
		B.cyl(Vector3(58.0 + i * 6.0, 0.6, 9.0), 0.4, 1.2, "6B4E33", true)
	for i in 3:
		var sx = 60.0 + i * 8.0
		B.box(Vector3(sx, 0.5, 4.0), Vector3(2.6, 1.0, 1.1), WOOD, true)
		B.box(Vector3(sx, 1.5, 4.6), Vector3(2.6, 3.0, 0.1), CHALK, true)
		for k in 4:
			B.box(Vector3(sx - 1.1 + k * 0.74, 3.1, 4.0), Vector3(0.74, 0.1, 1.9), FADED_BLUE if k % 2 == 0 else WHITE, true, Vector3(-10, 0, 0))
	for p in [[56.0, -2.0], [90.0, -4.0], [108.0, -18.0]]:
		lamp(p[0], p[1])
	for i in 3:
		_boat(Vector3(113.0, -0.45, -22.0 + i * 12.0), 90.0, _pick([CHALK, CORAL, FADED_BLUE]))

func _headland():
	var cx = -102.0
	var cz = 40.0
	var y = gh(cx, cz)
	B.cyl(Vector3(cx, y + 7.0, cz), 3.4, 14.0, WHITE, true)
	for i in 3:
		B.cyl(Vector3(cx, y + 3.0 + i * 4.5, cz), 3.45 - i * 0.2, 1.2, "D96D5F", false)
	B.cyl(Vector3(cx, y + 14.4, cz), 3.6, 0.4, "30343A", true)
	B.cyl(Vector3(cx, y + 16.0, cz), 1.6, 3.0, "FFE2A8", false, -1.0, 0.0, Vector3.ZERO, "lamp")
	B.cone(Vector3(cx, y + 18.2, cz), 2.2, 1.8, CORAL, false)
	B.perch_pad(Vector3(cx, y + 19.0, cz), 0.4)
	for k in 8:
		var a = k * TAU / 8.0
		B.box(Vector3(cx + cos(a) * 3.3, y + 15.0, cz + sin(a) * 3.3), Vector3(0.1, 1.0, 0.1), "30343A", false)
	B.box(Vector3(cx, y + 15.5, cz), Vector3(7.0, 0.08, 7.0), "30343A", false)
	anchors["lighthouse"] = Vector3(cx + 3.0, y + 15.6, cz)
	var beam = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.8, 0.8, 90.0)
	beam.mesh = bm
	var bmat = StandardMaterial3D.new()
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bmat.albedo_color = Color(1.0, 0.9, 0.6, 0.0)
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material_override = bmat
	beam.position = Vector3(0, 0, 45)
	var spinner = AnimatableBody3D.new()
	spinner.set_script(ANIM_SCRIPT)
	spinner.collision_layer = 0
	spinner.collision_mask = 0
	spinner.axis = Vector3(0, 1, 0)
	spinner.rate = 0.6
	spinner.position = Vector3(cx, y + 16.0, cz)
	spinner.add_child(beam)
	map.add_child(spinner)
	out["beam_mat"] = bmat
	house(cx + 9.0, cz - 12.0, 7.0, 5.0, 3.6, CHALK, CORAL)
	for a in range(0, 360, 20):
		var rr = 22.5
		var fx = cx + cos(deg_to_rad(a)) * rr
		var fz = cz + sin(deg_to_rad(a)) * rr
		if Terrain.H(fx, fz) > 20.0:
			B.box(Vector3(fx, Terrain.H(fx, fz) + 0.5, fz), Vector3(0.1, 1.0, 0.1), CHALK, false)
	for tpos in [Vector2(-118, 26), Vector2(-112, 58), Vector2(-86, 52)]:
		_turbine(tpos.x, tpos.y)
	for i in 8:
		var rx = cx + rng.randf_range(-20, 20)
		var rz = cz + rng.randf_range(-20, 20)
		if Terrain.H(rx, rz) > 20.0 and Vector2(rx - cx, rz - cz).length() > 5.0:
			B.ball(Vector3(rx, Terrain.H(rx, rz) + 0.2, rz), rng.randf_range(0.5, 1.2), "8D8A80", Vector3(1, 0.7, 1), 0.0, true)
	bench(cx + 8.0, cz + 12.0, 200)
	for i in 6:
		var gx = cx + rng.randf_range(-18, 18)
		var gz = cz + rng.randf_range(-18, 18)
		if Terrain.H(gx, gz) > 20.0 and Vector2(gx - cx, gz - cz).length() > 6.0:
			tree(gx, gz, 1, rng.randf_range(0.8, 1.1))

func _turbine(x, z):
	var y = Terrain.H(x, z)
	B.cyl(Vector3(x, y + 8.0, z), 0.45, 16.0, WHITE, true)
	B.box(Vector3(x, y + 16.3, z - 0.3), Vector3(1.0, 1.0, 2.2), WHITE, true)
	var rotor = AnimatableBody3D.new()
	rotor.set_script(ANIM_SCRIPT)
	rotor.collision_layer = 1
	rotor.collision_mask = 0
	rotor.axis = Vector3(0, 0, 1)
	rotor.rate = 0.9
	rotor.position = Vector3(x, y + 16.3, z + 1.0)
	map.add_child(rotor)
	_mesh_box(rotor, Vector3.ZERO, Vector3(0.7, 0.7, 0.6), SLATE, 0.0)
	for i in 3:
		var a = i * TAU / 3.0
		var rz = rad_to_deg(a)
		_mesh_box(rotor, Vector3(-sin(a) * 4.5, cos(a) * 4.5, 0), Vector3(0.55, 9.0, 0.16), WHITE, rz)
		_coll_box(rotor, Vector3(-sin(a) * 4.5, cos(a) * 4.5, 0), Vector3(0.55, 9.0, 0.16), rz)
	if not anchors.has("turbine"):
		anchors["turbine"] = Vector3(x + 5.5, y + 20.5, z + 1.0)

func _islet():
	var cx = 0.0
	var cz = 118.0
	var y = gh(cx, cz)
	house(cx + 3.0, cz + 2.0, 5.0, 4.0, 3.0, CREAM, CORAL)
	tree(cx - 3.0, cz - 1.0, 2, 1.5)
	tree(cx + 6.0, cz - 3.0, 2, 1.1)
	B.box(Vector3(cx, 0.15, cz - 14), Vector3(1.8, 0.3, 9), WOOD, true)
	B.ball(Vector3(cx + 6, y + 0.3, cz + 5), 0.5, "8D8A80", Vector3(1, 0.7, 1), 0.0, true)
	anchors["islet"] = Vector3(cx - 3.0, gh(cx - 3.0, cz - 1.0) + 7.5 * 1.5 + 2.0, cz - 1.0)

func _distant():
	var mc = ["56707F", "607A8B", "4E687A", "6A8596"]
	for i in 9:
		var a = -2.7 + i * 0.6
		var mx = 700.0 * sin(a)
		var mz = -700.0 * cos(a) - 100.0
		B.cone(Vector3(mx, 70.0, mz), 150.0 + (i % 3) * 40.0, 140.0 + (i % 4) * 30.0, mc[i % 4])
	for i in 6:
		B.cone(Vector3(-600, 40.0, 100.0 + i * 120.0), 140.0, 90.0, mc[i % 4])
		B.cone(Vector3(600, 40.0, -80.0 + i * 120.0), 140.0, 90.0, mc[(i + 1) % 4])
	# sailing boats out on the open water, each with somebody on board (and a cup, a cone or a deck chair)
	var cols = ["F4F1E8", "7396A8", "D96D5F", "879B82", "D9B25F"]
	var k = 0
	for spec in [[Vector3(-62, -0.45, 96), 20.0, "stand"], [Vector3(56, -0.45, 90), 200.0, "fish"], [Vector3(92, -0.45, 58), 110.0, "chat"], [Vector3(-34, -0.45, 128), 300.0, "stand"],
			[Vector3(30, -0.45, 150), 160.0, "fish"], [Vector3(-98, -0.45, 112), 60.0, "paint"]]:
		var deck = _boat(spec[0], spec[1], cols[k % 5], k == 1)
		sea_boats.append({"deck": deck, "mode": spec[2], "yaw": spec[1], "k": k})
		k += 1

func _thermals():
	var spots = [[Vector3(34, 0, 26), 16, 34, 4.2], [Vector3(-9.5, 0, 0), 7, 28, 3.6], [Vector3(84, 0, -24), 14, 30, 4.0],
		[Vector3(10, 10, -52), 14, 28, 3.6], [Vector3(-84, 8, 40), 14, 30, 4.2], [Vector3(0, 0, 118), 8, 24, 3.2],
		[Vector3(-55, 0, -10), 10, 24, 3.4], [Vector3(18, 0, 68), 13, 104, 4.8], [Vector3(-40, 0, 90), 12, 92, 4.6]]
	var tmat = ShaderMaterial.new()
	tmat.shader = load("res://shaders/thermal.gdshader")
	for s in spots:
		zones.append({"pos": s[0], "r": float(s[1]), "h": float(s[2]), "lift": s[3]})
		var mi = MeshInstance3D.new()
		var cm = CylinderMesh.new()
		cm.top_radius = s[1] * 0.8
		cm.bottom_radius = s[1] * 0.8
		cm.height = s[2]
		cm.radial_segments = 16
		cm.cap_top = false
		cm.cap_bottom = false
		mi.mesh = cm
		mi.material_override = tmat
		mi.position = s[0] + Vector3(0, s[2] * 0.5, 0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		map.add_child(mi)

# ====================================================================== fry encounters
func _encounters():
	var holder = Node3D.new()
	holder.name = "EncounterRoot"
	root.add_child(holder)
	var defs = [
		{"id": "TUTORIAL_01", "type": "tutorial", "arch": "elder", "carrier": "box", "behavior": "stand",
			"pos": Vector3(-8, 0, 3), "face": Vector3(0, 0, 1), "tdist": 1.3,
			"style": {"shirt": "8C8F96", "hair": "E8E8E8", "hair_style": "short", "glasses": true, "item_r": "cup", "pants": "4B5566"}},
		{"id": "TUTORIAL_02", "type": "tutorial", "arch": "elder_poke", "carrier": "plate", "behavior": "sit_eat",
			"pos": Vector3(-2.5, 0, 5.5), "face": Vector3(-1, 0, 0), "tdist": 1.0, "seated": true,
			"style": {"shirt": "A98FB8", "hair": "D8D8D8", "hair_style": "bun", "item_r": "umbrella", "pants": "6B5A48"}},
		{"id": "TUTORIAL_03", "type": "tutorial", "arch": "adult", "carrier": "hand", "behavior": "stand",
			"pos": Vector3(-16.5, 0, 15), "face": Vector3(0, 0, -1),
			"style": {"shirt": "D96D5F", "hair": "4A3426", "hair_style": "cap", "hat": "3E6F8E", "item_r": "cup"}},
		{"id": "SPECIAL_RED", "type": "red", "arch": "adult", "carrier": "hand", "behavior": "patrol",
			"pos": Vector3(1.5, 0.4, 70), "face": Vector3(0, 0, -1), "speed": 1.1,
			"path": [Vector3(-1.2, 0.4, 72), Vector3(3.2, 0.4, 72), Vector3(3.2, 0.4, 66), Vector3(-1.2, 0.4, 66)],
			"alts": [{"pos": Vector3(1.5, 0.4, 40), "face": Vector3(0, 0, -1)}, {"pos": Vector3(0, 0.4, 32), "face": Vector3(0, 0, -1)}],
			"style": {"shirt": "3E6F8E", "hair": "2A2420", "hair_style": "short", "item_r": "cup"}},
		{"id": "SPECIAL_BLUE", "type": "blue", "arch": "parent", "carrier": "plate", "behavior": "sit_eat",
			"pos": Vector3(20, 0, 19), "face": Vector3(-0.6, 0, -0.8), "tdist": 1.1, "seated": true,
			"alts": [{"pos": Vector3(36, 0, 26), "face": Vector3(-0.6, 0, -0.8), "table": Vector3(35.3, 0, 25.1)}, {"pos": Vector3(14, 0, 28), "face": Vector3(0.6, 0, -0.8), "table": Vector3(14.7, 0, 27.1)}],
			"style": {"shirt": "E2C25A", "hair": "6B4A2B", "hair_style": "sunhat", "hat": "F0D9A0", "item_r": "umbrella"}},
		{"id": "SPECIAL_YELLOW", "type": "purple", "arch": "vendor", "carrier": "hand", "behavior": "patrol",
			"pos": Vector3(-11, 0, 11.5), "face": Vector3(0.8, 0, 0.2), "speed": 1.0,
			"path": [Vector3(-14.5, 0, 11.8), Vector3(-7.5, 0, 11.8)],
			"alts": [{"pos": Vector3(-30, 0, 12.0), "face": Vector3(1, 0, 0)}, {"pos": Vector3(-2, 0, 12.0), "face": Vector3(1, 0, 0)}],
			"style": {"shirt": "5E8F6B", "hair": "1E1A18", "hair_style": "cap", "hat": "D96D5F", "apron": true, "item_r": "broom"}},
		{"id": "SPECIAL_GREEN", "type": "green", "arch": "child", "carrier": "hand", "behavior": "kid",
			"pos": Vector3(27, 0, 14.5), "face": Vector3(-1, 0, 0), "speed": 2.4,
			"path": [Vector3(31, 0, 14.5), Vector3(29.5, 0, 18), Vector3(26, 0, 19), Vector3(23, 0, 16), Vector3(23.5, 0, 12), Vector3(27, 0, 10.5), Vector3(30.5, 0, 11.5)],
			"alts": [{"pos": Vector3(46, 0, 22), "face": Vector3(-1, 0, 0)}, {"pos": Vector3(20, 0, 34), "face": Vector3(0, 0, -1)}],
			"style": {"shirt": "E8573A", "hair": "7A4B22", "hair_style": "cap", "hat": "3D8CD9", "item_r": "watergun"}},
		{"id": "SPECIAL_ROSE", "type": "pink", "arch": "adult", "carrier": "hand", "behavior": "patrol",
			"pos": Vector3(-41, 0, -1.5), "face": Vector3(-1, 0, 0), "speed": 0.9,
			"path": [Vector3(-39.5, 0, -1.5), Vector3(-50.5, 0, -1.5)],
			"alts": [{"pos": Vector3(-62, 0, -4), "face": Vector3(1, 0, 0)}, {"pos": Vector3(-30, 0, -9), "face": Vector3(1, 0, 0)}],
			"style": {"shirt": "6F8F7A", "hair": "D8D8D8", "hair_style": "sunhat", "hat": "F0D9A0", "item_r": "paper"}},
	]
	defs.append_array(extra.owner_defs())
	for e in defs:
		e["base_carrier"] = e["carrier"]
		var face = e["face"].normalized()
		e["face"] = face
		e["style"]["skin"] = "F0C6A0" if e["arch"] == "child" else _pick(SKINS)
		var npc = Node3D.new()
		npc.set_script(NPC_SCRIPT)
		holder.add_child(npc)
		npc.setup(e, player)
		out["npcs"].append(npc)
		if e.get("seated", false):
			npc.rig.seated = true
		var fry = Node3D.new()
		fry.set_script(FRY_SCRIPT)
		holder.add_child(fry)
		fry.setup(e["id"], e["type"], e["carrier"])
		fry.npc = npc
		npc.fry = fry
		if e["carrier"] == "hand":
			fry.reparent(npc.hand_anchor, false)
			fry.position = Vector3.ZERO
			fry.home_parent = npc.hand_anchor
		else:
			var td = e.get("tdist", 1.2)
			var tpos = e["pos"] + face * td
			var yaw = atan2(face.x, face.z)
			table(tpos.x, tpos.z, yaw, e["pos"].y)
			fry.position = tpos + Vector3(0, 0.81, 0)
			fry.home_parent = holder
			fry.home_pos = fry.global_position
			chair(e["pos"].x - face.x * 0.45, e["pos"].z - face.z * 0.45, rad_to_deg(yaw), e["pos"].y)
		out["fries"][e["id"]] = fry
		for a in e.get("alts", []):
			if a.has("table"):
				table(a["table"].x, a["table"].z, atan2(a["face"].x, a["face"].z), a["table"].y)
	var of = Node3D.new()
	of.set_script(FRY_SCRIPT)
	of.position = ORDINARY_POS
	holder.add_child(of)
	of.setup("ORDINARY", "ordinary", "none")
	of.home_parent = holder
	of.home_pos = ORDINARY_POS
	out["ordinary"] = of

func _dogs():
	var specs = [[Vector3(-14.6, 0, 16.4), 2.4, "B58A4B", "TUTORIAL_03"], [Vector3(22.3, 0, 17.2), 0.6, "F1E6D2", "SPECIAL_BLUE"], [Vector3(26.0, 0, 22.0), 1.0, "3A2A20", ""]]
	for s in specs:
		var d = Node3D.new()
		d.set_script(DOG_SCRIPT)
		root.add_child(d)
		var own = null
		if out["fries"].has(s[3]):
			own = out["fries"][s[3]].npc
		d.setup(player, s[0], s[1], s[2], own)

func _prism_anchors():
	var list = ["ferris", "lighthouse", "turbine", "church", "crane_hook", "containers", "buoy", "islet", "lifeguard", "chimney", "mast", "kite", "playground_top",
		"windmill", "clock_tower", "crane_hook2", "barn", "bar_shelf", "cafe_table", "market_stall", "boat_deck", "roof_laundry", "villa_bbq", "villa_pool", "fry_sign"]
	var res = []
	for k in list:
		if anchors.has(k):
			res.append({"name": k, "pos": anchors[k]})
	out["prism_spots"] = res

# ====================================================================== ambient life
func _amb(mode, pos, face, extra = {}, path = [], speed = 1.1):
	var n = Node3D.new()
	n.set_script(AMBIENT_SCRIPT)
	root.add_child(n)
	var st = rand_style(extra)
	n.setup(mode, st, pos, face.normalized(), path, speed, player)
	return n

func _gp(x, z, y = -999.0):
	return Vector3(x, gh(x, z) if y < -900.0 else y, z)

func _ambient():
	_amb("stroll", _gp(-30, 11), Vector3(1, 0, 0), {}, [_gp(-40, 11), _gp(10, 11.5)], 1.1)
	_amb("stroll", _gp(0, 12), Vector3(-1, 0, 0), {"mischief": "icecream"}, [_gp(8, 12.2), _gp(-26, 11.0)], 1.0)
	_amb("stroll", _gp(-52, 12), Vector3(1, 0, 0), {"mischief": "balloon"}, [_gp(-60, 11.5), _gp(-34, 12.0)], 0.9)
	_amb("jog", _gp(-20, 10), Vector3(1, 0, 0), {"shirt": "E8573A", "hair_style": "cap"}, [_gp(-64, 10.2), _gp(14, 10.2)], 2.8)
	_amb("chat", _gp(-12.9, 6.2), Vector3(1, 0, 0), {"seated": true, "item_r": "cup", "hair_style": "short", "mischief": "hat"})
	_amb("chat", _gp(-10.1, 6.2), Vector3(-1, 0, 0), {"seated": true})
	_amb("chat", _gp(-5.0, 7.3), Vector3(0, 0, 1), {"item_r": "cup"})
	_amb("chat", _gp(-5.0, 9.6), Vector3(0, 0, -1), {"grumpy": true})
	for x in [-34, -40, -52, -58]:
		_amb("stand", _gp(x, 19.1), Vector3(0, 0, -1), {"apron": true, "hair_style": "cap", "grumpy": true})
	_amb("stroll", _gp(-46, 14.5), Vector3(1, 0, 0), {"backpack": true}, [_gp(-60, 14.8), _gp(-30, 14.8)], 0.8)
	_amb("stand", _gp(-16.5, 17.2), Vector3(-1, 0, 0), {"item_r": "icecream"})
	_amb("stand", _gp(-16.5, 18.6), Vector3(-1, 0, 0), {})
	# the sunbathers: on the sun loungers (leaning back) or on towels (flat), never half inside a deck chair
	var li = 0
	for hip in beach_loungers:
		var st = {"hair_style": ["short", "long", "bun", "beanie"][li % 4], "shirt": ["F277B5", "3FB8E0", "F1C94B", "E85745"][li % 4], "pants": ["3E6F8E", "F4F1E8", "2D6F5E"][li % 3]}
		if li == 0:
			st["mischief"] = "shades"
		_amb("recline", hip, Vector3(0, 0, 1), st)
		li += 1
		if li >= 3:
			break
	towel(20.5, 13.2, 0.0, "F277B5")
	_amb("lie", Vector3(20.5, gh(20.5, 13.2) + 0.04, 13.2), Vector3(0, 0, 1), {"hair_style": "short"})
	towel(60.0, 22.0, 30.0, "3FB8E0")
	_amb("lie", Vector3(60.0, gh(60.0, 22.0) + 0.04, 22.0), Vector3(sin(deg_to_rad(30.0)), 0, cos(deg_to_rad(30.0))), {})
	_amb("stand", _gp(25, 30), Vector3(0, 0, 1), {"item_l": "kite", "item_r": "paper", "scale": 0.7, "chaser": true})
	_amb("stroll", _gp(30, 30), Vector3(1, 0, 0), {"hair_style": "short"}, [_gp(10, 35), _gp(70, 35)], 0.9)
	_amb("stand", _gp(40, 41), Vector3(0, 0, 1), {"vest": true, "vest_color": "E8573A"})
	_amb("stand", _gp(33, 11.5), Vector3(1, 0, 0), {"scale": 0.7, "chaser": true})
	_amb("fish", Vector3(4.2, 0.4, 36), Vector3(1, 0, 0), {"item_r": "rod", "hair_style": "beanie"})
	_amb("fish", Vector3(4.2, 0.4, 47), Vector3(1, 0, 0), {"item_r": "rod", "hair_style": "cap"})
	_amb("fish", Vector3(-2.2, 0.4, 61), Vector3(-1, 0, 0), {"item_r": "rod"})
	_amb("paint", Vector3(-2.0, 0.4, 28), Vector3(-1, 0, 0), {"item_r": "brush", "hair_style": "beanie"})
	_amb("stroll", Vector3(0, 0.4, 30), Vector3(0, 0, 1), {"mischief": "icecream"}, [Vector3(1, 0.4, 30), Vector3(1, 0.4, 48)], 0.9)
	_amb("jog", _gp(-45, -14), Vector3(1, 0, 0), {"shirt": "7396A8"}, [_gp(-45, -14), _gp(-32, -6), _gp(-45, 3), _gp(-58, -6)], 2.6)
	_amb("stroll", _gp(-50, 4), Vector3(1, 0, 0), {"item_r": "paper"}, [_gp(-38, 2), _gp(-66, 2)], 0.8)
	_amb("paint", _gp(-67, 4), Vector3(0, 0, -1), {"item_r": "brush", "hair_style": "bun", "mischief": "scarf"})
	_amb("play", _gp(-60, -2), Vector3(0, 0, 1), {"item_l": "guitar", "hair_style": "beanie"})
	_amb("stroll", _gp(70, -2), Vector3(1, 0, 0), {"vest": true, "vest_color": "E8A23A", "hair_style": "cap"}, [_gp(60, -2), _gp(104, -2)], 1.2)
	_amb("stand", _gp(64, 6.5), Vector3(0, 0, -1), {"apron": true})
	_amb("stroll", _gp(0, -36), Vector3(0, 0, -1), {}, [_gp(0, -36), _gp(0, -70)], 0.9)
	_amb("stand", _gp(-40, -36), Vector3(0, 0, 1), {})
	_amb("stroll", _gp(-96, 28), Vector3(1, 0, 0), {"item_l": "ball"}, [_gp(-96, 28), _gp(-85, 40)], 0.9)
	# the marina: one person on each of the nearest boats, the others are out sailing
	var mi = 0
	for spec in [[-16.0, 40.0, "fish"], [-24.0, 33.0, "stand"], [-8.0, 33.0, "chat"], [-32.0, 40.0, "paint"]]:
		var ex = {"hair_style": ["cap", "beanie", "bun", "short"][mi % 4], "shirt": ["3E6F8E", "C65A3A", "879B82", "E2C25A"][mi % 4]}
		if spec[2] == "fish":
			ex["item_r"] = "rod"
		elif spec[2] == "paint":
			ex["item_r"] = "brush"
		elif spec[2] == "chat":
			ex["seated"] = true
			ex["item_r"] = "mug"
		_amb(spec[2], Vector3(spec[0], 0.05, spec[1] + 0.9), Vector3(1, 0, 0), ex)
		mi += 1
	for sb in sea_boats:
		var ex2 = {"hair_style": ["cap", "bun", "beanie", "short", "long", "cap"][sb["k"] % 6], "shirt": ["3E6F8E", "C65A3A", "879B82", "E2C25A", "7A5A8B", "2BA7A0"][sb["k"] % 6]}
		if sb["mode"] == "fish":
			ex2["item_r"] = "rod"
		elif sb["mode"] == "paint":
			ex2["item_r"] = "brush"
		elif sb["mode"] == "chat":
			ex2["seated"] = true
			ex2["item_r"] = "cup"
		var face = Vector3(sin(deg_to_rad(sb["yaw"])), 0, cos(deg_to_rad(sb["yaw"])))
		_amb(sb["mode"], sb["deck"] + Vector3(0, 0.06, 0), face, ex2)
		if sb["k"] == 2:
			# a cooler with an ice cream on the deck of this one (it comes back after a while)
			var m = Node3D.new()
			m.set_script(MISCHIEF)
			m.setup("icecream", root, sb["deck"] + Vector3(0.5, 0.45, -0.6))
			B.box(sb["deck"] + Vector3(0.5, 0.2, -0.6), Vector3(0.6, 0.4, 0.4), "3FB8E0", true)
		elif sb["k"] == 3:
			var m2 = Node3D.new()
			m2.set_script(MISCHIEF)
			m2.setup("coffee", root, sb["deck"] + Vector3(-0.4, 0.45, -0.8))
			B.box(sb["deck"] + Vector3(-0.4, 0.2, -0.8), Vector3(0.6, 0.4, 0.4), "E8E2D2", true)

func _mischief_balls():
	var p = Vector2(46, 28)
	var m = Node3D.new()
	m.set_script(MISCHIEF)
	m.setup("ball", root, Vector3(p.x, gh(p.x, p.y) + 0.02, p.y))

func _ambient_gulls():
	for i in 7:
		var g = Node3D.new()
		g.set_script(GullVisual)
		root.add_child(g)
		g.build()
		var tick = Node.new()
		tick.set_script(ORBIT_SCRIPT)
		tick.gull = g
		tick.center = Vector3(rng.randf_range(-60, 90), rng.randf_range(24, 46), rng.randf_range(-20, 70))
		tick.radius = rng.randf_range(12, 26)
		tick.angle = rng.randf() * TAU
		tick.rate = rng.randf_range(0.18, 0.3) * (1.0 if i % 2 == 0 else -1.0)
		root.add_child(tick)
