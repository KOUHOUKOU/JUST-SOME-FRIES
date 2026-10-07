extends RefCounted
# Round 4 additions to the town, built from the same primitives as world_builder.gd:
#   * the SUMMIT PLAZA at the top of the hill stairs (bakery, fountain, clock tower, cafe tables, a musician...)
#   * the EAST MEADOW: a windmill, a barn, fields, a scarecrow (with a hat), a farmer
#   * life for the buildings that used to be empty: hill-town doorsteps, church steps, beach huts, harbour docks, marina office, ferris wheel
#   * two new fry owners (a baker and a lighthouse keeper), more dogs, kids that chase, grumpy people, the volleyball match, fish spots
# Placement helpers come from the world builder `w` (bench, table, lamp, ...).

const Terrain = preload("res://scripts/world/terrain.gd")
const ANIM_SCRIPT = preload("res://scripts/world/props_anim.gd")
const DOG_SCRIPT = preload("res://scripts/npc/dog.gd")
const FISH_SPOT = preload("res://scripts/world/fish_spot.gd")
const VOLLEY = preload("res://scripts/world/volleyball.gd")
const MISCHIEF = preload("res://scripts/fries/mischief.gd")

const CHALK = "E8E2D2"
const CORAL = "D96D5F"
const FADED_BLUE = "7396A8"
const WOOD = "8B6A4D"
const DARKWOOD = "6F5238"
const TERRA = "B96F50"
const SLATE = "586169"
const OCHRE = "D9B25F"
const CREAM = "EFE3C6"
const WHITE = "F4F1E8"
const SAGE = "879B82"

var w                       # the world builder
var B                       # its batcher
var py = 23.0               # floor height of the summit plaza
var plaza_cx = 0.0
var plaza_cz = -79.5
var plaza_hw = 15.5
var plaza_hd = 7.5
var farm_y = 21.0

func setup(p_w):
	w = p_w
	B = w.B

func in_plaza(x, z, margin = 0.0):
	return abs(x - plaza_cx) < plaza_hw + margin and abs(z - plaza_cz) < plaza_hd + margin

# ====================================================================== structures
func build_places():
	_summit()
	_farm()
	_small_props()

func _summit():
	var top = 0.0
	for ix in 7:
		for iz in 4:
			top = max(top, w.gh(plaza_cx - plaza_hw + ix * (2.0 * plaza_hw / 6.0), plaza_cz - plaza_hd + iz * (2.0 * plaza_hd / 3.0)))
	py = top + 0.4
	# the stone terrace (it grows out of the hill, so it can never float)
	B.box(Vector3(plaza_cx, py - 7.0, plaza_cz), Vector3(plaza_hw * 2.0, 14.0, plaza_hd * 2.0), "A89E88", true)
	B.box(Vector3(plaza_cx, py + 0.02, plaza_cz), Vector3(plaza_hw * 2.0 - 1.4, 0.05, plaza_hd * 2.0 - 1.4), "C9BFA6", false)
	for k in 6:
		B.box(Vector3(plaza_cx - 12.5 + k * 5.0, py + 0.05, plaza_cz), Vector3(0.12, 0.03, plaza_hd * 2.0 - 1.4), "B5AB92", false)
	# low wall round the edge (open at the stairs)
	var zs = plaza_cz + plaza_hd - 0.25
	B.box(Vector3(-9.0, py + 0.35, zs), Vector3(13.0, 0.7, 0.5), "CFC6B0", true)
	B.box(Vector3(9.0, py + 0.35, zs), Vector3(13.0, 0.7, 0.5), "CFC6B0", true)
	B.box(Vector3(plaza_cx - plaza_hw + 0.25, py + 0.35, plaza_cz), Vector3(0.5, 0.7, plaza_hd * 2.0), "CFC6B0", true)
	B.box(Vector3(plaza_cx + plaza_hw - 0.25, py + 0.35, plaza_cz), Vector3(0.5, 0.7, plaza_hd * 2.0), "CFC6B0", true)
	# the fountain
	var fx = plaza_cx
	var fz = plaza_cz + 0.5
	B.cyl(Vector3(fx, py + 0.3, fz), 2.5, 0.6, "B8BEC4", true)
	B.cyl(Vector3(fx, py + 0.62, fz), 2.2, 0.06, "5B9AA8", false)
	B.cyl(Vector3(fx, py + 1.1, fz), 0.45, 1.2, "B8BEC4", true)
	B.cyl(Vector3(fx, py + 1.8, fz), 1.1, 0.2, "B8BEC4", true)
	B.ball(Vector3(fx, py + 2.2, fz), 0.3, "D8E6EE", Vector3(1, 1.3, 1), 0.4)
	# the clock tower (north-west corner): a star fry can hang over its roof
	var tx = -11.5
	var tz = plaza_cz - plaza_hd + 2.2
	B.box(Vector3(tx, py + 6.5, tz), Vector3(4.2, 13.0, 4.2), CHALK, true)
	B.box(Vector3(tx, py + 13.2, tz), Vector3(5.0, 0.5, 5.0), TERRA, true)
	B.cone(Vector3(tx, py + 15.2, tz), 3.1, 3.6, SLATE, true)
	B.perch_pad(Vector3(tx, py + 17.2, tz), 0.35)
	for side in [[0.0, 1.0], [0.0, -1.0], [1.0, 0.0], [-1.0, 0.0]]:
		var fp = Vector3(tx + side[0] * 2.12, py + 10.2, tz + side[1] * 2.12)
		var fs = Vector3(0.1, 2.3, 2.3) if side[0] != 0.0 else Vector3(2.3, 2.3, 0.1)
		B.box(fp, fs, "F8F4E6", false)
		var hs = Vector3(0.12, 0.9, 0.14) if side[0] != 0.0 else Vector3(0.14, 0.9, 0.12)
		B.box(fp + Vector3(side[0] * 0.06, 0.3, side[1] * 0.06), hs, "2B2F36", false)
	B.box(Vector3(tx, py + 1.1, tz + 2.12), Vector3(1.3, 2.2, 0.1), DARKWOOD, false)
	w.anchors["clock_tower"] = Vector3(tx, py + 18.5, tz)
	# the bakery (north side)
	var bx = 7.0
	var bz = plaza_cz - plaza_hd + 2.6
	B.box(Vector3(bx, py + 2.4, bz), Vector3(11.0, 4.8, 4.4), CREAM, true)
	B.prism(Vector3(bx, py + 5.5, bz), Vector3(11.8, 1.6, 5.2), TERRA, true)
	B.box(Vector3(bx + 4.0, py + 6.6, bz - 1.0), Vector3(0.9, 2.4, 0.9), "8B6A5A", true)
	B.box(Vector3(bx, py + 3.7, bz + 3.0), Vector3(10.4, 0.12, 2.0), CORAL, false, Vector3(-12, 0, 0))
	B.box(Vector3(bx, py + 0.55, bz + 3.9), Vector3(9.0, 1.1, 0.9), WOOD, true)
	B.box(Vector3(bx, py + 1.15, bz + 3.9), Vector3(9.2, 0.08, 1.0), DARKWOOD, false)
	for k in 6:
		B.box(Vector3(bx - 3.6 + k * 1.44, py + 1.32, bz + 3.9), Vector3(0.9, 0.28, 0.5), "E3A93A", false, Vector3(0, 0, 0))
		B.ball(Vector3(bx - 3.6 + k * 1.44, py + 1.55, bz + 3.9), 0.2, "C98F4F", Vector3(1.4, 0.8, 1.0))
	for k in 3:
		B.box(Vector3(bx - 3.6 + k * 3.6, py + 2.2, bz + 2.23), Vector3(1.6, 1.4, 0.08), "", false, Vector3.ZERO, 0.0, "window")
		B.box(Vector3(bx - 3.6 + k * 3.6, py + 2.2, bz + 2.2), Vector3(2.0, 1.8, 0.05), WHITE, false)
	B.box(Vector3(bx, py + 4.1, bz + 2.3), Vector3(4.0, 0.7, 0.12), CORAL, false)
	# cafe tables, benches, lamps, planters
	for tp in [Vector2(-8.0, -75.6), Vector2(9.5, -75.6), Vector2(-2.5, -74.4)]:
		w.table(tp.x, tp.y, 0.0, py)
		w.chair(tp.x - 0.9, tp.y, 90, py)
		w.chair(tp.x + 0.9, tp.y, 270, py)
	w.patio_umbrella(-8.0, -75.6, CORAL, py)
	w.patio_umbrella(9.5, -75.6, FADED_BLUE, py)
	w.bench(-5.5, plaza_cz + 0.5, 90, py)
	w.bench(5.5, plaza_cz + 0.5, 270, py)
	w.bench(0.0, plaza_cz + 4.2, 180, py)
	w.bench(12.0, plaza_cz + 3.0, 270, py)
	for lp in [Vector2(-13.5, -73.5), Vector2(13.5, -73.5), Vector2(-4.0, -84.5), Vector2(14.0, -84.5)]:
		w.lamp(lp.x, lp.y, py, 3.6)
	for pp in [Vector2(-14.0, -82.0), Vector2(14.5, -79.0), Vector2(3.0, -73.3), Vector2(-3.0, -73.3)]:
		w.planter(pp.x, pp.y, py)
	# the flower stall
	B.box(Vector3(-5.2, py + 0.5, -85.0), Vector3(3.6, 1.0, 1.0), WOOD, true)
	B.box(Vector3(-5.2, py + 1.5, -85.9), Vector3(3.6, 3.0, 0.1), CHALK, true)
	for k in 4:
		B.box(Vector3(-6.7 + k * 1.0, py + 3.1, -85.3), Vector3(1.0, 0.1, 1.9), "F7C7D4" if k % 2 == 0 else WHITE, true, Vector3(-10, 0, 0))
	for k in 6:
		B.ball(Vector3(-6.4 + k * 0.5, py + 1.15, -85.0), 0.14, ["E85745", "F1C94B", "F7C7D4", "FFFFFF", "A98FB8", "E85745"][k])
	# a few fountain-side flowers
	for k in 10:
		var a = k * TAU / 10.0
		B.ball(Vector3(fx + cos(a) * 3.1, py + 0.18, fz + sin(a) * 3.1), 0.14, ["E85745", "F1C94B", "F7C7D4", "FFFFFF"][k % 4])

func _farm():
	var wx = 86.0
	var wz = -80.0
	var wy = w.gh(wx, wz)
	farm_y = wy
	# the windmill
	B.cyl(Vector3(wx, wy + 4.6, wz), 3.5, 9.2, CHALK, true, 2.5)
	B.cone(Vector3(wx, wy + 10.9, wz), 3.4, 3.0, CORAL, true)
	B.box(Vector3(wx, wy + 1.0, wz + 3.2), Vector3(1.3, 2.0, 0.14), DARKWOOD, false)
	for k in 2:
		B.box(Vector3(wx + (k * 2 - 1) * 1.5, wy + 5.0, wz + 2.9), Vector3(0.7, 1.0, 0.1), "2B3A44", false)
	var hub = Vector3(wx, wy + 8.8, wz + 3.7)
	B.box(hub - Vector3(0, 0, 0.8), Vector3(1.6, 1.6, 1.6), SLATE, true)
	var rotor = AnimatableBody3D.new()
	rotor.set_script(ANIM_SCRIPT)
	rotor.collision_layer = 1
	rotor.collision_mask = 0
	rotor.axis = Vector3(0, 0, 1)
	rotor.rate = 0.42
	rotor.position = hub
	w.map.add_child(rotor)
	w._mesh_box(rotor, Vector3.ZERO, Vector3(1.0, 1.0, 0.7), SLATE, 0.0)
	for i in 4:
		var a = i * TAU / 4.0 + 0.5
		var c = Vector3(-sin(a) * 4.9, cos(a) * 4.9, 0.0)
		w._mesh_box(rotor, c, Vector3(0.18, 9.6, 0.16), "8B6A4D", rad_to_deg(a))
		w._coll_box(rotor, c, Vector3(0.18, 9.6, 0.16), rad_to_deg(a))
		var c2 = Vector3(-sin(a) * 5.5 + cos(a) * 0.55, cos(a) * 5.5 + sin(a) * 0.55, 0.0)
		w._mesh_box(rotor, c2, Vector3(1.0, 6.4, 0.08), "F4F1E8", rad_to_deg(a))
		w._coll_box(rotor, c2, Vector3(1.0, 6.4, 0.08), rad_to_deg(a))
	w.anchors["windmill"] = Vector3(wx + 5.4, wy + 13.5, wz + 2.0)
	# the barn, the silo and a tractor
	var bx = 102.0
	var bz = -66.0
	var by = w.gh(bx, bz)
	B.box(Vector3(bx, by + 3.2, bz), Vector3(10.0, 6.4, 14.0), "A8382C", true)
	B.prism(Vector3(bx, by + 8.2, bz), Vector3(14.8, 3.6, 11.0), "6F7C84", true, Vector3(0, 90, 0))
	B.box(Vector3(bx - 5.05, by + 2.2, bz), Vector3(0.1, 4.4, 4.4), "F4F1E8", false)
	B.box(Vector3(bx - 5.12, by + 2.2, bz), Vector3(0.06, 4.4, 0.25), "A8382C", false, Vector3(0, 0, 0))
	for k in 5:
		var hz = bz - 4.5 + k * 2.2
		w.B.cyl(Vector3(bx - 7.0, by + 0.5, hz), 0.55, 1.0, "D9B25F", true, -1.0, 0.0, Vector3(0, 0, 90))
	B.cyl(Vector3(bx - 9.5, by + 5.0, bz + 6.0), 1.9, 10.0, "B8BEC4", true)
	B.cone(Vector3(bx - 9.5, by + 11.6, bz + 6.0), 2.0, 2.2, "8E96A0", true)
	w.anchors["barn"] = Vector3(bx, by + 11.0, bz)
	var tr = Vector3(bx - 12.0, by, bz - 3.0)
	B.box(tr + Vector3(0, 0.9, 0), Vector3(1.6, 1.0, 2.6), "C8372D", true)
	B.box(tr + Vector3(0, 1.8, -0.5), Vector3(1.4, 1.1, 1.2), "C8372D", true)
	B.box(tr + Vector3(0, 2.5, -0.5), Vector3(1.5, 0.12, 1.4), "30343A", false)
	for sx in [-0.9, 0.9]:
		B.cyl(tr + Vector3(sx, 0.7, -0.7), 0.7, 0.4, "30343A", true, -1.0, 0.0, Vector3(0, 0, 90))
		B.cyl(tr + Vector3(sx * 0.9, 0.45, 0.9), 0.45, 0.3, "30343A", true, -1.0, 0.0, Vector3(0, 0, 90))
	# fields: little rows of crops
	for r in 10:
		var zz = -90.0 + r * 3.0
		for seg in 8:
			var xx = 62.0 + seg * 5.0 + 2.5
			var gy = w.gh(xx, zz)
			B.box(Vector3(xx, gy + 0.2, zz), Vector3(4.2, 0.4, 0.7), "5E8C3A" if r % 2 == 0 else "7BA043", false)
	# a fence along the meadow's south edge
	for k in 14:
		var fx = 64.0 + k * 3.2
		var fy = w.gh(fx, -57.0)
		B.box(Vector3(fx, fy + 0.5, -57.0), Vector3(0.1, 1.0, 0.1), WOOD, false)
	B.box(Vector3(86.4, w.gh(86.4, -57.0) + 0.85, -57.0), Vector3(44.8, 0.07, 0.07), WOOD, false)
	B.box(Vector3(86.4, w.gh(86.4, -57.0) + 0.5, -57.0), Vector3(44.8, 0.07, 0.07), WOOD, false)
	# the scarecrow (its hat can be stolen)
	var sx0 = 74.0
	var sz0 = -72.0
	var sy0 = w.gh(sx0, sz0)
	B.cyl(Vector3(sx0, sy0 + 1.1, sz0), 0.05, 2.2, WOOD, false)
	B.box(Vector3(sx0, sy0 + 1.65, sz0), Vector3(1.7, 0.08, 0.08), WOOD, false)
	B.box(Vector3(sx0, sy0 + 1.35, sz0), Vector3(0.5, 0.75, 0.22), CORAL, true)
	B.ball(Vector3(sx0, sy0 + 2.05, sz0), 0.2, "E8D8A8")
	for sx in [-1.0, 1.0]:
		B.box(Vector3(sx0 + sx * 0.85, sy0 + 1.4, sz0), Vector3(0.3, 0.5, 0.1), "7A6A52", false)
	B.cyl(Vector3(sx0, sy0 + 2.22, sz0), 0.4, 0.03, "E8D8A0", false)
	B.cyl(Vector3(sx0, sy0 + 2.3, sz0), 0.2, 0.14, "E8D8A0", false)
	# a hay maze of bales near the barn gives gulls somewhere to land
	for k in 3:
		B.cyl(Vector3(bx - 4.0 + k * 1.2, by + 0.5, bz + 8.6), 0.55, 1.0, "D9B25F", true, -1.0, 0.0, Vector3(0, 0, 90))

func _small_props():
	# ferris wheel ticket booth (pier)
	B.box(Vector3(-9.6, 1.6, 50.6), Vector3(1.8, 2.4, 1.8), CORAL, true)
	B.box(Vector3(-9.6, 2.9, 50.6), Vector3(2.2, 0.2, 2.2), WHITE, false)
	B.box(Vector3(-8.65, 1.5, 50.6), Vector3(0.1, 0.8, 1.2), "", false, Vector3.ZERO, 0.0, "window")
	# harbour: a forklift and pallets
	var fx = 84.0
	var fz = -6.0
	B.box(Vector3(fx, 0.7, fz), Vector3(1.4, 0.9, 2.2), "E8A23A", true)
	B.box(Vector3(fx, 1.6, fz - 0.3), Vector3(1.3, 1.0, 1.0), "E8A23A", false)
	B.box(Vector3(fx, 2.2, fz - 0.3), Vector3(1.4, 0.1, 1.2), "30343A", false)
	B.box(Vector3(fx, 1.5, fz + 1.4), Vector3(0.12, 2.4, 0.12), "30343A", false)
	B.box(Vector3(fx - 0.4, 0.2, fz + 1.9), Vector3(0.1, 0.1, 1.2), "30343A", false)
	B.box(Vector3(fx + 0.4, 0.2, fz + 1.9), Vector3(0.1, 0.1, 1.2), "30343A", false)
	for p in [Vector2(80.0, -3.0), Vector2(90.0, -8.0), Vector2(94.0, -2.0)]:
		w.crate(p.x, p.y, 0.9)
		w.crate(p.x + 1.0, p.y + 0.2, 0.7)
	# a second crane hook to hang a star fry on
	w.anchors["crane_hook2"] = Vector3(100.0, 11.4, 4.0)
	# marina: a bait-shop sign
	B.box(Vector3(-36.0, 3.6, 25.2), Vector3(3.0, 0.7, 0.12), FADED_BLUE, false)

# ====================================================================== the two new fry owners
func owner_defs():
	var defs = []
	var y = py
	defs.append({"id": "SPECIAL_ORANGE", "type": "pink", "arch": "vendor", "carrier": "hand", "behavior": "patrol",
		"pos": Vector3(3.5, y, -81.7), "face": Vector3(0, 0, 1), "speed": 0.9,
		"path": [Vector3(3.5, y, -81.7), Vector3(10.5, y, -81.7)],
		"alts": [{"pos": Vector3(-9.0, y, -76.5), "face": Vector3(1, 0, 0)}, {"pos": Vector3(11.0, y, -74.0), "face": Vector3(-1, 0, 0)}],
		"style": {"shirt": "F4F1E8", "hair": "6B4A2B", "hair_style": "cap", "hat": "F4F1E8", "apron": true, "item_r": "tray", "pants": "4B5566", "fat": 1.2}})
	var ky = w.gh(-92.5, 44.0)
	defs.append({"id": "SPECIAL_SILVER", "type": "cyan", "arch": "elder", "carrier": "plate", "behavior": "sit_eat",
		"pos": Vector3(-92.5, ky, 44.0), "face": Vector3(-1, 0, 0), "tdist": 1.0, "seated": true,
		"alts": [{"pos": Vector3(-100.0, ky, 57.0), "face": Vector3(0, 0, -1), "table": Vector3(-100.0, ky, 56.0)}],
		"style": {"shirt": "3E4F6B", "hair": "D8D8D8", "hair_style": "beanie", "hat": "30343A", "glasses": true, "item_r": "cup", "pants": "2F4A5E"}})
	return defs

# ====================================================================== people and animals
func _g(x, z):
	return Vector3(x, w.gh(x, z), z)

func _amb(mode, pos, face, extra = {}, path = [], speed = 1.1):
	return w._amb(mode, pos, face, extra, path, speed)

func build_life():
	var py_ = py
	# --- summit plaza
	_amb("play", Vector3(-3.5, py_, -77.5), Vector3(0, 0, 1), {"item_l": "guitar", "hair_style": "beanie"})
	_amb("chat", Vector3(-8.9, py_, -75.6), Vector3(1, 0, 0), {"seated": true, "item_r": "cup"})
	_amb("chat", Vector3(-7.1, py_, -75.6), Vector3(-1, 0, 0), {"seated": true, "hair_style": "bun"})
	_amb("eat", Vector3(10.4, py_, -75.6), Vector3(-1, 0, 0), {"seated": true, "item_r": "cup", "hair_style": "long"})
	_amb("stand", Vector3(-5.2, py_, -86.2), Vector3(0, 0, 1), {"apron": true, "hair_style": "bun", "grumpy": true})
	_amb("play", Vector3(4.5, py_, -76.5), Vector3(-1, 0, 0), {"scale": 0.7, "chaser": true})
	_amb("play", Vector3(-1.0, py_, -73.8), Vector3(0, 0, -1), {"scale": 0.72, "chaser": true})
	_amb("paint", Vector3(13.0, py_, -80.5), Vector3(-1, 0, 0), {"item_r": "brush", "hair_style": "beanie", "mischief": "beret"})
	_amb("stroll", Vector3(-12.0, py_, -77.0), Vector3(1, 0, 0), {}, [Vector3(-12.0, py_, -77.0), Vector3(12.0, py_, -77.0)], 0.9)
	_amb("stroll", Vector3(10.0, py_, -73.2), Vector3(-1, 0, 0), {"item_r": "paper"}, [Vector3(10.0, py_, -73.2), Vector3(-10.0, py_, -73.2)], 0.8)
	# --- farm
	var fy = farm_y
	_amb("stand", _g(94.0, -58.5), Vector3(0, 0, -1), {"item_r": "broom", "hair_style": "sunhat", "hat": "E8D8A0", "grumpy": true, "shirt": "5E8F6B"})
	_amb("play", _g(88.0, -66.0), Vector3(0, 0, 1), {"scale": 0.7, "chaser": true})
	_amb("paint", _g(70.0, -62.0), Vector3(1, 0, 0), {"item_r": "brush", "hair_style": "bun"})
	_amb("stroll", _g(66.0, -86.0), Vector3(1, 0, 0), {"backpack": true}, [_g(66.0, -86.0), _g(98.0, -86.0)], 0.8)
	_dog(_g(96.5, -60.0), 3.1, "7A5A3A")
	# --- doorsteps of the hill houses: somebody lives here
	var doors = w.hill_doors
	var made = 0
	for i in doors.size():
		if i % 3 != 1 or made >= 14:
			continue
		var d = doors[i]
		var modes = ["stand", "wave", "chat", "stand", "stand"]
		var m = modes[made % modes.size()]
		var ex = {"hair_style": ["short", "long", "bun", "cap", "beanie"][made % 5]}
		if m == "chat" or (made % 4 == 0):
			ex["item_r"] = "cup"
		if made % 5 == 2:
			ex["grumpy"] = true
		_amb(m, d, Vector3(0.0, 0, 1.0), ex)
		made += 1
	# --- church steps: a priest, a wedding party (the groom's bow tie is for the taking)
	var cy = w.gh(-26.0, -62.0) + 1.0
	_amb("stand", Vector3(-26.0, cy, -52.4), Vector3(0, 0, 1), {"hair_style": "bald", "shirt": "2B2F36", "pants": "2B2F36"})
	_amb("chat", Vector3(-22.4, cy, -52.4), Vector3(0.5, 0, 0.9), {"mischief": "bowtie", "shirt": "2B2F36", "pants": "2B2F36"})
	_amb("chat", Vector3(-21.4, cy, -52.4), Vector3(-0.5, 0, 0.9), {"shirt": "F4F1E8", "hair_style": "long"})
	_amb("stand", Vector3(-29.5, cy, -52.4), Vector3(0, 0, 1), {"hair_style": "bun", "shirt": "7A5A8B", "item_r": "paper"})
	# --- beach huts
	_amb("stand", _g(22.0, 8.6), Vector3(0, 0, 1), {"vest": true, "vest_color": "E8573A", "hair_style": "cap"})
	_amb("stand", _g(31.0, 8.6), Vector3(0, 0, 1), {"apron": true, "item_r": "icecream"})
	w.towel(40.0, 10.4, 0.0, "FF8A3C")
	_amb("lie", _g(40.0, 10.4) + Vector3(0, 0.04, 0), Vector3(0, 0, 1), {"hair_style": "short"})
	_amb("play", _g(48.5, 9.5), Vector3(0, 0, 1), {"scale": 0.7, "chaser": true})
	_amb("play", _g(58.0, 9.2), Vector3(0, 0, 1), {"item_l": "guitar", "hair_style": "beanie"})
	# --- harbour: dock workers, lunch break, stall vendors who hate gulls
	_amb("stroll", _g(60.0, -4.0), Vector3(1, 0, 0), {"vest": true, "vest_color": "E8A23A", "hair_style": "cap", "item_r": "tray"}, [_g(60.0, -4.0), _g(104.0, -4.0)], 1.0)
	_amb("stroll", _g(104.0, -9.0), Vector3(-1, 0, 0), {"vest": true, "vest_color": "E8A23A", "item_r": "tray"}, [_g(104.0, -9.0), _g(62.0, -9.0)], 0.95)
	_amb("sit", _g(66.0, -6.5), Vector3(1, 0, 0), {"seated": true, "item_r": "cup", "vest": true, "vest_color": "E8A23A"})
	_amb("sit", _g(67.6, -6.5), Vector3(-1, 0, 0), {"seated": true, "vest": true, "vest_color": "E8A23A"})
	_amb("stand", _g(88.0, -22.0), Vector3(0, 0, 1), {"vest": true, "vest_color": "E8573A", "hair_style": "cap"})
	for sx in [60.0, 68.0, 76.0]:
		_amb("stand", _g(sx, 6.5), Vector3(0, 0, -1), {"apron": true, "grumpy": true, "hair_style": "cap"})
	_dog(_g(80.0, -8.0), 1.2, "B58A4B")
	# --- marina office and the pier's ferris wheel
	_amb("stand", _g(-36.0, 26.6), Vector3(0, 0, 1), {"hair_style": "cap", "hat": "2B3A44", "vest": true, "vest_color": "3E6F8E"})
	_amb("fish", Vector3(-20.0, 0.34, 31.0), Vector3(0, 0, 1), {"item_r": "rod", "hair_style": "beanie"})
	_amb("stand", Vector3(-8.0, 0.4, 50.6), Vector3(-1, 0, 0), {"hair_style": "cap", "hat": "D96D5F"})
	_amb("stand", Vector3(-6.3, 0.4, 51.4), Vector3(0, 0, 1), {"scale": 0.7})
	_amb("stand", Vector3(-5.4, 0.4, 51.6), Vector3(0, 0, 1), {"item_r": "icecream"})
	# --- the lighthouse (the keeper's company), the park (a bench with an old man and a pipe), the market (a necklace), the islet
	_amb("paint", _g(-84.0, 42.0), Vector3(0, 0, 1), {"item_r": "brush", "hair_style": "bun"})
	_amb("sit", _g(-50.0, -6.0), Vector3(-1, 0, 0), {"seated": true, "mischief": "pipe", "hair_style": "bald", "item_r": "paper"})
	_amb("stand", _g(-46.0, 20.6), Vector3(0, 0, -1), {"apron": true, "mischief": "necklace", "hair_style": "long", "grumpy": true})
	_amb("fish", _g(-1.0, 124.0), Vector3(0, 0, 1), {"item_r": "rod", "hair_style": "beanie"})
	_dog(_g(2.0, 123.0), 0.8, "F1E6D2")
	# --- more dogs and a grumpy bench in the old town
	_dog(_g(-44.0, 17.4), 0.4, "8A6A4A")
	_dog(_g(-52.0, 2.0), 2.2, "3A2A20")
	_dog(_g(44.0, 31.0), 1.7, "C9A66A")
	_dog(Vector3(-3.2, py_, -75.2), 0.2, "6B4A2B")
	# --- the volleyball match
	_volleyball()

func _dog(pos, yaw, coat):
	var d = Node3D.new()
	d.set_script(DOG_SCRIPT)
	w.root.add_child(d)
	d.setup(w.player, pos, yaw, coat, null)

func _volleyball():
	var nx = 52.0
	var ppl = []
	for spec in [[47.0, 16.0, 1.0], [47.0, 21.0, 1.0], [57.0, 16.0, -1.0], [57.0, 21.0, -1.0]]:
		var n = _amb("play", _g(spec[0], spec[1]), Vector3(spec[2], 0, 0), {"hair_style": ["short", "bun", "cap", "long"][ppl.size()]})
		ppl.append(n)
	_amb("stand", _g(nx, 12.3), Vector3(0, 0, 1), {"vest": true, "vest_color": "E8573A"})
	w.towel(nx + 4.5, 26.0, 0.0, "3D8CD9")
	_amb("lie", _g(nx + 4.5, 26.0) + Vector3(0, 0.04, 0), Vector3(0, 0, 1), {})
	var v = Node3D.new()
	v.set_script(VOLLEY)
	v.setup(w.player, ppl, nx)
	w.root.add_child(v)
	v.position = _g(nx, 18.5)
	w.volley = v

func build_fish_spots():
	var spots = []
	# the water that a leaping fish must never touch: the pier with its wheel, the marina, the harbour boats, the sailing boats out at sea
	FISH_SPOT.live = 0
	FISH_SPOT.avoid_rects = [[-12.0, 16.0, 20.0, 78.0], [-36.0, -6.0, 24.0, 46.0], [108.0, 120.0, -30.0, -4.0], [92.0, 112.0, 14.0, 26.0]]
	FISH_SPOT.avoid_discs = [[Vector3(16.0, 0.0, 74.0), 3.5]]
	for sb in w.sea_boats:
		FISH_SPOT.avoid_discs.append([sb["deck"], 7.5])
	# open water on every side of the town: both sides of the pier, the marina's mouth, the bay, the harbour, the open sea (round 7: many more of them)
	for sp in [[-22.0, 60.0, 7.0], [26.0, 62.0, 8.0], [-24.0, 74.0, 8.0], [-34.0, 70.0, 9.0], [28.0, 50.0, 7.0], [42.0, 66.0, 10.0], [-54.0, 62.0, 10.0],
			[58.0, 52.0, 9.0], [82.0, 42.0, 10.0], [124.0, -16.0, 6.0], [8.0, 92.0, 11.0], [-30.0, 98.0, 10.0], [30.0, 102.0, 10.0], [-4.0, 136.0, 9.0],
			[64.0, 84.0, 10.0], [-70.0, 86.0, 10.0], [100.0, 60.0, 10.0], [-120.0, 90.0, 10.0]]:
		var f = Node3D.new()
		f.set_script(FISH_SPOT)
		w.root.add_child(f)
		f.setup(w.player, Vector3(sp[0], 0, sp[1]), -0.75, sp[2])
		spots.append(f)
	return spots
