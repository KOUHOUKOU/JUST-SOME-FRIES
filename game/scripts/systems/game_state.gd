extends Node
# Global progression state, stat formulas, crowd "watch", achievements.
#
# ROUND 5. Fry TYPES (rainbow order). Each has three tiers: 1 SILVER, 2 GOLD, 3 DIAMOND (then every further fry of that colour is a
# RAINBOW fry: a tiny extra bit of the same stat). The cruise / glide speeds never change, only the TOP speed and how fast you get there.
#   red    SONIC      top (boost) speed        19 -> 21 -> 23 -> 25 m/s   (gauge = m/s x 6: 114 -> 150)
#   orange TAILWIND   acceleration             x1 -> x1.4 -> x2 -> x3
#   green  STEADY     judgement: wider bands + slower rings
#   cyan   FARSIGHT   Gull Sight radius 40 -> 80 -> 160 -> 320 m, in the air cheaper (diamond: free)
#   blue   DEEP       stamina 60 -> 90 -> 130 -> 190
#   purple SECOND     resting + roll cooldown
#   pink   FLUFF      swats hurt less, stun shorter

signal gull_sense_changed(count)
signal gull_sense_complete
signal special_collected(type)
signal progress_changed(current, target)
signal still_hungry_started
signal ordinary_fry_eaten
signal stamina_changed(value, max_value)
signal dash_cooldown_changed(ratio)
signal achievement(title)
signal player_hurt(kind, lost_fry)   # kind: swat_punch|swat_poke|swat_sweep|swat_squirt|swat_lunge|crash
signal comic(id, caption, extra)      # the lower-left comic panel (see ui/comic_pop.gd); extra = {"tier": 0..3, "col": Color, "type": "red"...}
signal fry_got(type, tier)            # a (non-plain) fry was taken: the light "got it" moment in the HUD
signal drink_changed(kind)

enum Phase { TUTORIAL, SPECIAL_HUNT, STILL_HUNGRY, ENDED }

const FRY_TYPES = ["red", "orange", "green", "cyan", "blue", "purple", "pink"]
const TOTAL_BASE = 10                 # 3 tutorial fries + 7 silver fries = the end of the first part
const FRY_CAP = 24                    # 3 + 7 x (silver, gold, diamond)
const MISSIONS = [3, 6, 10, 24]
const STAR_TOTAL = 14                 # gold + diamond of every type
const RAINBOW_MAX = 8
const SAVE_PATH = "user://savegame.json"
const WEARABLES = ["hat", "sailor", "topper", "beret", "glasses", "shades", "necklace", "bowtie", "scarf", "pipe", "hawaii", "stripes", "coat", "balloon"]
const WEAR_NAMES = {"hat": "STRAW HAT", "sailor": "SAILOR CAP", "topper": "TOP HAT", "beret": "RED BERET", "glasses": "READING GLASSES", "shades": "SUNGLASSES", "necklace": "GOLD CHAIN",
	"bowtie": "BOW TIE", "scarf": "RED SCARF", "pipe": "PIPE", "hawaii": "FLOWER SHIRT", "stripes": "STRIPED SHIRT", "coat": "LONG COAT", "balloon": "BALLOON"}
const TUT_NEED = {"TUTORIAL_01": 8.0, "TUTORIAL_02": 9.0, "TUTORIAL_03": 10.0}   # m/s: the first three fries, a gentle ramp (gauge 48 / 54 / 60)
# gauge speed needed to lock a fry of this type: [silver, gold, diamond]. Diamond ones need a faster gull than the base boost (114):
# 126 needs SONIC silver (126), 132 / 138 need SONIC gold (138), 144 / 150 need SONIC diamond (150).
const NEED_GAUGE = {"red": [72, 102, 126], "orange": [72, 96, 132], "green": [66, 90, 138], "cyan": [72, 108, 126],
	"blue": [72, 102, 144], "purple": [66, 96, 132], "pink": [72, 114, 150]}
const RAINBOW_NEED = 90.0
const DECOR_NEED = 11.0               # m/s for borrowed hats, balloons... (mischief objects set their own)
const SPEED_UNIT = 6.0                # gauge number = m/s * SPEED_UNIT
const RARITY_NAMES = ["COMMON", "SILVER", "GOLD", "DIAMOND", "RAINBOW"]
const RARITY_COLORS = [Color("E8E4D4"), Color("C3CCD8"), Color("FFC83A"), Color("DDF4FF"), Color("FF8AD8")]
const TYPE_COLORS = {"red": Color("E8453C"), "orange": Color("F28A2E"), "green": Color("4FBF5A"), "cyan": Color("33CFD6"),
	"blue": Color("3D6FE0"), "purple": Color("9B5DE0"), "pink": Color("F277B5")}
const BOOST_TAB = [19.0, 21.0, 23.0, 25.0]
const ACCEL_TAB = [1.0, 1.4, 2.0, 3.0]
const STAM_TAB = [60.0, 90.0, 130.0, 190.0]
const REGEN_GLIDE_TAB = [1.5, 2.2, 3.2, 4.5]
const REGEN_PERCH_TAB = [1.0, 1.5, 2.2, 3.0]
const ROLL_CD_TAB = [1.0, 0.85, 0.7, 0.5]
const WINDOW_TAB = [1.0, 1.25, 1.5, 1.8]     # judgement bands are this much wider
const CONE_TAB = [33.0, 40.0, 46.0, 52.0]
const RING_TAB = [1.0, 1.12, 1.25, 1.45]     # the rings take this much longer to arrive (slower)
const SIGHT_R_TAB = [40.0, 80.0, 160.0, 320.0]
const VISION_TAB = [1.0, 0.6, 0.3, 0.0]
const HURT_TAB = [1.0, 0.7, 0.45, 0.2]       # share of the swat damage that still lands
const STUN_TAB = [1.0, 0.85, 0.7, 0.5]       # share of the tumble time that is left
const VISION_BASE_COST = 9.0          # stamina per real second while Gull Sight is held in the AIR (free on the ground)
const NAMES = {
	"red": ["ROCKET FRY", "JET FRY", "SONIC FRY"],
	"orange": ["TAILWIND FRY", "GALE FRY", "HURRICANE FRY"],
	"green": ["STEADY BEAK FRY", "STEADIER BEAK FRY", "UNSHAKEABLE BEAK FRY"],
	"cyan": ["FARSIGHT FRY", "EAGLE-EYED FRY", "ALL-SEEING FRY"],
	"blue": ["DEEP BREATH FRY", "BIG LUNGS FRY", "BOTTOMLESS FRY"],
	"purple": ["SECOND WIND FRY", "THIRD WIND FRY", "ENDLESS WIND FRY"],
	"pink": ["FLUFF FRY", "FLUFFIER FRY", "MAXIMUM FLUFF FRY"],
}
const STAT_NAMES = {"red": "TOP SPEED", "orange": "ACCELERATION", "green": "STEADY TIMING", "cyan": "GULL SIGHT", "blue": "STAMINA", "purple": "RECOVERY", "pink": "SWAT DAMAGE"}
const DESCS = {
	"red": ["Faster at the very top.\nCruising stays exactly the same.", "The top of the dial moves up again.", "The dial runs out of numbers."],
	"orange": ["Speeds up sooner.\nThe top speed is still yours alone.", "Less runway. More gull.", "The runway is now a rumour."],
	"green": ["Wider bands, slower rings.\nLess thinking, better grabbing.", "Even less thinking.", "Your beak no longer shakes. Neither does the fry."],
	"cyan": ["Squinting, but with magic.\nGull Sight reaches twice as far.", "Everything far away glows.", "Look all you like. It costs nothing."],
	"blue": ["More sky before you need a rest.", "Lungs the size of a pier.", "You are mostly lungs now."],
	"purple": ["Apparently breathing is useful.", "Resting is now a competitive sport.", "Naps are optional. Recovery is not."],
	"pink": ["Softer landings.\nSwats hurt less.", "Fluffier. Harder to hurt.", "A cloud with a beak."],
}

var phase = Phase.TUTORIAL
var gull_sense_count = 0
var tutorial_done = {}
var lv = {"red": 0, "orange": 0, "green": 0, "cyan": 0, "blue": 0, "purple": 0, "pink": 0}
var has = {"red": false, "orange": false, "green": false, "cyan": false, "blue": false, "purple": false, "pink": false}   # lv >= 1 (kept for old call sites)
var rainbow = {"red": 0, "orange": 0, "green": 0, "cyan": 0, "blue": 0, "purple": 0, "pink": 0}   # extra fries beyond diamond (tiny boosts)
var rb_seen = 0                       # rainbow fries taken in total (for the story)
var worn = {}                         # every wearable stolen so far: "pipe" -> true (what the gull OWNS)
var equipped = {}                     # ...and which of them it is wearing right now
var load_pending = false              # the menu's CONTINUE asked for the saved run
var saved_pos = null                  # where the saved run was (applied by main.gd)
var star_got = {}                     # "red_2" -> true
var ordinary_eaten = false
var skip_menu = false
var skip_intro = false
var mouse_sens_mult = 1.0
var heat = 0.0                        # the town's memory of a thieving gull (decays)
var watch = 0.0                       # crowd alertness around the player right now: heat + people who are looking (0..4)
var sense_active = false              # Gull Sight held (slow motion + dark screen)
var vision_tired = false
var codex_open = false
var no_focus_pause = false            # dev test modes: a minimised window must not pause the bot
var showcase_active = false
var achievements_done = {}
var fries_eaten = 0
var mischief_counts = {}
var invert_y = false
var run_time = 0.0
var end_time = -1.0
var hunger_t = 0.0                    # seconds spent STILL HUNGRY (drives the "where is it?" hints)
var stats = {}
var drink = ""                        # "" | "coffee" | "alcohol": a drink the gull has had (see drink_t)
var drink_t = 0.0
var menu_seen = {}                    # codex items already seen (the NEW dots)
var test_boost_bonus = 0.0            # dev tests only: extra top speed so the bot can reach diamond fries

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 240 Hz uncapped rendering of a ~2000-draw-call scene saturated a laptop GPU/CPU (system-wide lag after a while).
	# 60 fps is plenty: physics already runs at 60 Hz.
	Engine.max_fps = 60
	_init_clock()
	var keys = {"move_forward": KEY_W, "move_back": KEY_S, "bank_left": KEY_A, "bank_right": KEY_D,
		"flap": KEY_SPACE, "dash": KEY_SHIFT, "land": KEY_CTRL, "interact": KEY_E, "squawk": KEY_F,
		"gull_sense": KEY_TAB, "codex": KEY_C, "pause_game": KEY_ESCAPE}
	for a in keys:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
		var ev = InputEventKey.new()
		ev.physical_keycode = keys[a]
		InputMap.action_add_event(a, ev)
	reset_stats()

# The clock every timed thing in the game reads (rhythm rings, dialogue, cards). Normally the wall clock; under Movie Maker
# (--write-movie, the walkthrough video) frames render slower than real time, so there it counts movie frames instead.
var movie_fps = 0.0

func _init_clock():
	var args = OS.get_cmdline_args()
	if not (OS.has_feature("movie") or "--write-movie" in args):
		return
	# the engine keeps --fixed-fps to itself: the movie rate comes in as a user arg (`-- --movie-fps=30`), default 60 like Movie Maker
	movie_fps = 60.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--movie-fps="):
			movie_fps = float(a.substr(12))

func usec():
	if movie_fps > 0.0:
		return int(Engine.get_frames_drawn() * 1000000.0 / movie_fps)     # one movie frame per drawn frame
	return Time.get_ticks_usec()

func msec():
	return usec() / 1000

# Perf: hide far-away decoration (every hidden mesh also skips the shadow pass) and optionally stop it casting shadows.
func cull_tree(root, end_m, no_shadow = false):
	var stack = [root]
	while not stack.is_empty():
		var n = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is GeometryInstance3D:
			n.visibility_range_end = end_m
			if no_shadow:
				n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _process(delta):
	if heat > 0.0:
		heat = max(heat - delta / 30.0, 0.0)
	if drink != "":
		drink_t -= delta / max(Engine.time_scale, 0.1)
		if drink_t <= 0.0:
			set_drink("")

func reset_stats():
	stats = {"stolen": 0, "perfect": 0, "shot": 0, "slipped": 0, "walls": 0, "missed": 0, "swats": 0, "vision_s": 0.0, "fish": 0, "rivals": 0, "bops": 0, "scares": 0,
		"drinks": 0, "fed": 0, "friends": 0, "rainbow": 0}

func reset():
	phase = Phase.TUTORIAL
	gull_sense_count = 0
	tutorial_done = {}
	for k in lv:
		lv[k] = 0
		has[k] = false
		rainbow[k] = 0
	rb_seen = 0
	star_got = {}
	worn = {}
	equipped = {}
	ordinary_eaten = false
	heat = 0.0
	watch = 0.0
	sense_active = false
	vision_tired = false
	codex_open = false
	showcase_active = false
	achievements_done = {}
	fries_eaten = 0
	mischief_counts = {}
	run_time = 0.0
	end_time = -1.0
	hunger_t = 0.0
	drink = ""
	drink_t = 0.0
	menu_seen = {}
	reset_stats()

func set_level(type, level):
	lv[type] = clamp(level, 0, 3)
	has[type] = lv[type] >= 1

func add_rainbow(type):
	rainbow[type] = min(rainbow[type] + 1, RAINBOW_MAX)
	rb_seen += 1
	stats["rainbow"] += 1

func add_heat(a):
	heat = clamp(heat + a, 0.0, 4.0)

func watch_label():
	if watch < 1.0:
		return "CALM"
	if watch < 2.0:
		return "WARY"
	if watch < 3.0:
		return "ALERT"
	return "ALL EYES"

func watch_high():
	return watch >= 2.0

func award(title):
	if achievements_done.has(title):
		return
	achievements_done[title] = true
	achievement.emit(title)

func special_count():
	var n = 0
	for k in lv:
		if lv[k] >= 1:
			n += 1
	return n

func level_sum():
	var n = 0
	for k in lv:
		n += lv[k]
	return n

func star_count():
	return star_got.size()

# every counted fry (rainbow ones are extras and never count): the three starters + silver / gold / diamond of every colour
func fry_total():
	return min(gull_sense_count, 3) + level_sum()

func progress_value():
	return 3 + special_count()

func type_complete(t):
	return lv[t] >= 3

func vision_unlocked():
	return gull_sense_count >= 3

# the mission board: the next target that has not been reached yet (-1 when every fry is in)
func mission_target():
	var n = fry_total()
	for m in MISSIONS:
		if n < m:
			return m
	return -1

# how strongly the player misses the plain fry: 0..12 (fries + time spent hungry); drives its faint halo
func longing():
	return max(fry_total() - 10, 0) * 0.9 + hunger_t / 40.0

# ---- drinks (coffee = fast and twitchy, alcohol = slow and wobbly) ----
func set_drink(kind, sec = 15.0):
	if drink == kind and kind != "":
		drink_t = sec
		return
	drink = kind
	drink_t = sec if kind != "" else 0.0
	drink_changed.emit(kind)

func drink_speed_mult():
	return 1.22 if drink == "coffee" else (0.58 if drink == "alcohol" else 1.0)

func drink_accel_mult():
	return 2.6 if drink == "coffee" else (0.4 if drink == "alcohol" else 1.0)

# ---- stat formulas (every number a player can feel lives here) ----
func glide_speed():
	return 5.0 * drink_speed_mult()

func cruise_speed():
	return 11.0 * drink_speed_mult()      # fries never change this

# the TOP speed: boost. Sonic fries lift it; coffee lifts it a bit more, alcohol cuts it
func boost_speed():
	var b = BOOST_TAB[lv["red"]] + 0.15 * rainbow["red"] + test_boost_bonus
	if drink == "coffee":
		return b + 2.5
	if drink == "alcohol":
		return b * 0.55
	return b

func accel_mult():
	return (ACCEL_TAB[lv["orange"]] + 0.04 * rainbow["orange"]) * drink_accel_mult()

func stamina_max():
	return STAM_TAB[lv["blue"]] + 4.0 * rainbow["blue"]

func regen_glide():
	return REGEN_GLIDE_TAB[lv["purple"]] * (1.0 + 0.03 * rainbow["purple"])

func regen_perch(high):
	var base = 14.0 if high else 9.0
	return base * (REGEN_PERCH_TAB[lv["purple"]] + 0.04 * rainbow["purple"])

func roll_cooldown():
	return ROLL_CD_TAB[lv["purple"]]

# the judgement bands are this much wider
func timing_mult():
	return WINDOW_TAB[lv["green"]] * (1.0 + 0.02 * rainbow["green"])

# the rings take this much longer to arrive (a slower rhythm)
func ring_speed_mult():
	return RING_TAB[lv["green"]] * (1.0 + 0.015 * rainbow["green"])

func assist_cone_cos():
	return cos(deg_to_rad(CONE_TAB[lv["green"]]))

func sight_radius():
	return SIGHT_R_TAB[lv["cyan"]] + 4.0 * rainbow["cyan"]

func vision_cost():
	return VISION_BASE_COST * VISION_TAB[lv["cyan"]]

func hurt_mult():
	return max(HURT_TAB[lv["pink"]] - 0.01 * rainbow["pink"], 0.08)

func stun_mult():
	return STUN_TAB[lv["pink"]]

func notice_mult():
	return 1.0

# gauge (x6) speed the gull must have to lock this fry. Harder fries ask for a longer dive / a boost / a faster boost.
func need_speed(f):
	if f == null or not is_instance_valid(f):
		return 11.0
	match f.ftype:
		"tutorial":
			return TUT_NEED.get(f.id, 10.0)
		"fish":
			return f.min_speed
		"mischief":
			return f.min_speed
		"ordinary":
			return 0.0
	if f.tier >= 4:
		return RAINBOW_NEED / SPEED_UNIT
	if f.utype != "" and NEED_GAUGE.has(f.utype):
		return NEED_GAUGE[f.utype][clamp(f.tier, 1, 3) - 1] / SPEED_UNIT
	return 11.0

# crowd watch effects: more eyes = a thinner window (and sharper NPCs via heat)
func heat_view_mult():
	return 1.0 + 0.12 * heat

func heat_gain_mult():
	return (1.0 + 0.15 * heat) * notice_mult()

func heat_window_mult():
	return max(1.0 - 0.1 * watch, 0.65)

# ---- text for cards / codex ----
func fry_name(type, tier):
	if tier >= 4:
		return "RAINBOW %s FRY" % NAMES[type][0].replace(" FRY", "").split(" ")[0]
	return NAMES[type][clamp(tier - 1, 0, 2)]

# value text for the "ability" line (the stat's name is shown separately, see STAT_NAMES)
func ability_text(type, level):
	match type:
		"red":
			return "TOP %d   >   %d" % [int(round(BOOST_TAB[level - 1] * SPEED_UNIT)), int(round(BOOST_TAB[level] * SPEED_UNIT))]
		"orange":
			return "x%.1f   >   x%.1f   -   TOP SPEED UNCHANGED" % [ACCEL_TAB[level - 1], ACCEL_TAB[level]]
		"green":
			return "BANDS x%.2f   -   RINGS %d %% SLOWER" % [WINDOW_TAB[level], int(round((1.0 - 1.0 / RING_TAB[level]) * 100.0))]
		"cyan":
			return "RANGE %d m   -   %s IN THE AIR" % [int(SIGHT_R_TAB[level]), "FREE" if level >= 3 else "-%d %%" % int(round((1.0 - VISION_TAB[level]) * 100.0))]
		"blue":
			return "%d   >   %d" % [int(STAM_TAB[level - 1]), int(STAM_TAB[level])]
		"purple":
			return "RESTING x%.1f   -   ROLL %.2f s" % [REGEN_PERCH_TAB[level], ROLL_CD_TAB[level]]
		"pink":
			return "HITS -%d %%   -   STUN -%d %%" % [int(round((1.0 - HURT_TAB[level]) * 100.0)), int(round((1.0 - STUN_TAB[level]) * 100.0))]
	return ""

# one short line for the tiny rainbow bonus
func rainbow_text(type):
	match type:
		"red":
			return "+0.9 TOP SPEED"
		"orange":
			return "+4 % ACCELERATION"
		"green":
			return "+2 % BANDS"
		"cyan":
			return "+4 m SIGHT"
		"blue":
			return "+4 STAMINA"
		"purple":
			return "+3 % RESTING"
		"pink":
			return "-1 % DAMAGE"
	return ""

# ---- save game (a plain JSON file in the user folder): the run so far, the gull's stuff and where it was ----
func has_save():
	return FileAccess.file_exists(SAVE_PATH)

func delete_save():
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

func write_save(pos, yaw):
	if ordinary_eaten:
		return false
	var d = {"v": 1, "sense": gull_sense_count, "tut": tutorial_done.keys(), "lv": lv.duplicate(), "rb": rainbow.duplicate(), "stars": star_got.keys(),
		"worn": worn.keys(), "eq": equipped.keys(), "mis": mischief_counts.duplicate(), "ach": achievements_done.keys(), "eaten": fries_eaten,
		"hunger": hunger_t, "run": run_time, "stats": stats.duplicate(), "phase": int(phase), "pos": [pos.x, pos.y, pos.z], "yaw": yaw,
		"seen": menu_seen.keys()}
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(d))
	f.close()
	return true

func read_save():
	if not has_save():
		return null
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return null
	var txt = f.get_as_text()
	f.close()
	var data = JSON.parse_string(txt)
	if typeof(data) != TYPE_DICTIONARY or int(data.get("v", 0)) != 1 or not data.has("rb"):
		return null          # a save from an older version of the game: start fresh
	return data

# put a loaded save into the state (the world is rebuilt from it by main.gd)
func apply_save(d):
	reset()
	gull_sense_count = int(d.get("sense", 0))
	for id in d.get("tut", []):
		tutorial_done[id] = true
	var l = d.get("lv", {})
	for k in lv:
		set_level(k, int(l.get(k, 0)))
	var r = d.get("rb", {})
	for k in rainbow:
		rainbow[k] = int(r.get(k, 0))
	for k in d.get("stars", []):
		star_got[k] = true
	for k in d.get("worn", []):
		worn[k] = true
	for k in d.get("eq", []):
		equipped[k] = true
	for k in d.get("seen", []):
		menu_seen[k] = true
	var m = d.get("mis", {})
	for k in m:
		mischief_counts[k] = int(m[k])
	for k in d.get("ach", []):
		achievements_done[k] = true
	fries_eaten = int(d.get("eaten", 0))
	hunger_t = float(d.get("hunger", 0.0))
	run_time = float(d.get("run", 0.0))
	var st = d.get("stats", {})
	for k in st:
		stats[k] = st[k]
	phase = int(d.get("phase", 0))
	var p = d.get("pos", [-9.5, 6.0, -0.8])
	saved_pos = {"pos": Vector3(p[0], p[1], p[2]), "yaw": float(d.get("yaw", PI))}
