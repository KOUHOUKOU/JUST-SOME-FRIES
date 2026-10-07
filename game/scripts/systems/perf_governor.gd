extends Node
# Keeps the game playable on a weak machine and in the browser (round 7).
# The browser build is single-threaded WebAssembly: the same scene costs several times what it costs on the desktop, and the first version of the demo
# could run slower and slower until the tab gave up. So:
#   * the web build starts lighter (no MSAA, a small shadow atlas, 3D drawn at 85 %, people and grass far away are not drawn or simulated)
#   * on every platform a little governor watches the frame rate and, if it stays low for a few seconds, lowers the 3D resolution, the shadow distance and
#     finally the shadows themselves; if the machine copes again it raises them back. The 2D interface is never touched.
# [PERF] lines in the log / browser console say what the governor is doing.

var main
var level = 0
var base = 0
var low = 0
var high = 0
var t = 0.0
const SCALE = [1.0, 0.85, 0.72, 0.6]
const SHADOW_DIST = [140.0, 90.0, 60.0, 40.0]

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	if GS.web:
		RenderingServer.directional_shadow_atlas_set_size(1024, false)
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		base = 1
		level = 1
	_apply()

func _apply():
	get_viewport().scaling_3d_scale = SCALE[level]
	var sun = main.world.get("sun") if main != null and main.world != null else null
	if sun != null:
		sun.shadow_enabled = level < 3
		sun.directional_shadow_max_distance = SHADOW_DIST[level]
		if GS.web:
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	print("[PERF] quality level %d (3D scale %.2f, shadows %s)" % [level, SCALE[level], str(level < 3)])

func _process(delta):
	t += delta
	if t < 1.0:
		return
	t = 0.0
	if get_tree().paused or Engine.max_fps <= 30 or GS.showcase_active:
		low = 0
		high = 0
		return
	var fps = Engine.get_frames_per_second()
	if fps < 26:
		low += 1
		high = 0
	elif fps > 56:
		high += 1
		low = 0
	else:
		low = max(low - 1, 0)
		high = max(high - 1, 0)
	if low >= 4 and level < 3:
		level += 1
		low = 0
		_apply()
	elif high >= 15 and level > base:
		level -= 1
		high = 0
		_apply()
