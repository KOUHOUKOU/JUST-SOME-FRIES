extends Node
# ROUND 16, the memory reel. The first time the gull does something that it will remember (the first coffee, the first fish, the moon...), a few frames of
# the picture on screen are kept: square, small, over about a second. They are written into the user folder (per save slot) so that they survive a save / load,
# and the ending plays them back, as little moving polaroids, while the gull remembers.
#
# Nothing here slows the game: 6 captures over a second, a small crop, a JPEG. Test runs and the browser's lite mode record fewer frames or none.

const FRAMES = 6
const GAP = 0.13            # real seconds between two captures
const SIZE = 176
const IDS = ["fry1", "coffee", "alcohol", "ice", "starlight", "fish", "cloud", "raincloud", "sun", "moon", "skybow", "meteor", "friend", "gift", "kid", "rainbow", "thermal", "skim",
	"wall", "armed", "all24", "fishtime", "sky_cloud", "sky_raincloud", "sky_sun", "sky_moon", "sky_rainbow", "sky_star"]
const ALIAS = {"sky_cloud": "cloud", "sky_raincloud": "raincloud", "sky_sun": "sun", "sky_moon": "moon", "sky_rainbow": "skybow", "sky_star": "meteor"}

var busy = {}
var cache = {}              # id -> [Texture2D]

func _dir():
	return ("user://dev_mem/slot%d" if OS.get_cmdline_user_args().size() > 0 else "user://mem/slot%d") % GS.slot

func record(id):
	id = ALIAS.get(id, id)
	if not (id in IDS) or busy.has(id) or has_reel(id):
		return
	busy[id] = true
	DirAccess.make_dir_recursive_absolute(_dir())
	var frames = []
	for i in FRAMES:
		await get_tree().create_timer(GAP if i > 0 else 0.05, true, false, true).timeout
		await RenderingServer.frame_post_draw
		var vp = get_viewport()
		if vp == null or get_tree() == null:
			break
		var img = vp.get_texture().get_image()
		if img == null or img.is_empty():
			continue
		var w = img.get_width()
		var h = img.get_height()
		var s = int(min(w, h) * 0.86)         # the middle of the picture, a little closer than the whole height
		img = img.get_region(Rect2i((w - s) / 2, int((h - s) * 0.42), s, s))
		img.resize(SIZE, SIZE, Image.INTERPOLATE_BILINEAR)
		img.convert(Image.FORMAT_RGB8)
		img.save_jpg("%s/%s_%d.jpg" % [_dir(), id, i], 0.82)
		frames.append(ImageTexture.create_from_image(img))
	if frames.size() >= 3:
		cache[id] = frames
	busy.erase(id)

func has_reel(id):
	id = ALIAS.get(id, id)
	if cache.has(id):
		return true
	return FileAccess.file_exists("%s/%s_%d.jpg" % [_dir(), id, 2])

# the frames of one memory (loaded from the slot's folder when they are not in memory yet), or an empty array
func reel(id):
	id = ALIAS.get(id, id)
	if cache.has(id):
		return cache[id]
	var out = []
	for i in FRAMES:
		var p = "%s/%s_%d.jpg" % [_dir(), id, i]
		if not FileAccess.file_exists(p):
			break
		var img = Image.load_from_file(p)
		if img == null or img.is_empty():
			break
		out.append(ImageTexture.create_from_image(img))
	if out.size() >= 3:
		cache[id] = out
		return out
	return []

# a new run in this slot: the old reels are gone
func clear_slot():
	cache.clear()
	var d = DirAccess.open(_dir())
	if d == null:
		return
	for f in d.get_files():
		d.remove(f)
