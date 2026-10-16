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
signal buff_started(kind)             # coffee | alcohol | ice
signal buff_ended(kind)
signal quest_done(id)                 # a side quest of the mission board was finished (the HUD goes quiet for a moment)
signal buff_added(kind, stacked)      # a drink was taken (even a second one of the same kind): breath back, a little show
signal star_started                   # all three drinks at once: STARLIGHT, 30 seconds of the best flying there is
signal star_ended
signal fish_caught(info)              # {"sp": id, "len": cm, "kg": x, "new": bool, "rec_len": bool, "rec_kg": bool}
signal meteor_caught                  # a shooting star was caught (round 8)
signal sky_caught(kind, count)        # round 15: cloud | raincloud | star | moon | sun | rainbow; count = how many of the five are in
signal achievement_unlocked(id)       # round 15: a gallery achievement (icon, name, date)
signal fish_started                   # round 16: the first fish of a streak: OCEAN TIME begins
signal fish_added(streak, rarity)     # ...and every fish after it (the streak climbs, the time grows)
signal fish_ended
signal memory_added(id)               # round 16: a first-time moment worth a little film (main.gd records a few frames of it)

enum Phase { TUTORIAL, SPECIAL_HUNT, STILL_HUNGRY, ENDED }

# ---- ROUND 18: DIFFICULTY ---------------------------------------------------------------------------------------------------------------------------------------------
# The first outside players found the game hard to enter: nobody knew how to get a fry, the breath ran out, TAB cost breath, the rings arrived before anyone saw them and the
# town hit back for nothing. So there are two ways to play:
#   EASY  = the way in. Lots of breath that comes back quickly, TAB is nearly free, the rings are clear (round 18b: smaller again) and the waves go at the normal speed from the very first one (a count-in of soft ticks), every
#           ordinary fry (the 24) asks for ONE judgement per circle with fat bands; the waves of the families speed up (`ladder`: starter 1.0 .. diamond 0.76 of the time) and the fat bands
#           get thinner (`band_lad`), so the music of a diamond fry is quicker than the music of a plain one, the town is friendly unless the crowd is on FULL alert, a wall is a bump.
#           Its challenge lives elsewhere: the rainbow fries, the fish and the things of the sky (clouds, the moon, the sun, a rainbow, a star).
#   HARD  = the race, and a real rhythm game (round 18b, `single`): ONE band only (gold, as wide as the old green one), THREE waves per circle, the tune plays by itself on the
#           beats and an E counts only when the white wave is in the gold band (a hit = 1 point, a quarter of the waves may be missed). Higher speeds, breath that runs out,
#           a TAB that costs, a town that is wary and a clock (the fastest time to the 24 fries is kept).
#   classic = the numbers of round 17 (dev / test runs only: the bots were written for them).
# `GS.dp(key)` reads the table for the current difficulty. Waves per circle: 0 = keep the number of the tier table.
const DP = {
	"easy": {"stam": 1.7, "drain": 0.5, "regen_air": 2.4, "regen_perch": 2.4, "free_early": true, "sight": 0.25, "sight_game": true, "need": 0.88, "band": 1.5, "band_x": 1.0,
		"ring": 1.0, "first_slow": 1.0, "first_lead": 0.3, "ticks": 2, "gap": 1.0, "appr": 0.74, "beat": 0.62, "sky_slow": 1.1, "single": false, "ladder": [1.0, 0.97, 0.94, 0.92], "band_lad": [1.0, 0.92, 0.84, 0.78], "w_fry": 2, "w_rb": 2, "w_fish": 2, "w_sky": 2, "sky_need": 0.6,
		"hostile": 3.0, "friend": 1.4, "hits": false, "star_sec": 45.0, "label": "EASY"},
	"hard": {"stam": 1.0, "drain": 1.0, "regen_air": 1.0, "regen_perch": 1.0, "free_early": false, "sight": 1.0, "sight_game": false, "need": 1.1, "band": 0.85, "band_x": 0.8,
		"ring": 1.0, "first_slow": 1.0, "first_lead": 0.1, "ticks": 1, "gap": 0.88, "appr": 0.66, "beat": 0.5, "sky_slow": 1.0, "single": true, "ladder": [1.0, 0.97, 0.94, 0.92], "band_lad": [1.0, 1.0, 1.0, 1.0], "w_fry": 3, "w_rb": 3, "w_fish": 3, "w_sky": 2, "sky_need": 1.0,
		"hostile": 1.6, "friend": 0.5, "hits": true, "star_sec": 30.0, "label": "HARD"},
	"classic": {"stam": 1.0, "drain": 1.0, "regen_air": 1.0, "regen_perch": 1.0, "free_early": false, "sight": 1.0, "sight_game": false, "need": 1.0, "band": 1.0, "band_x": 1.0,
		"ring": 1.0, "first_slow": 1.0, "first_lead": 0.0, "ticks": 0, "gap": 1.0, "appr": 0.0, "beat": 0.0, "sky_slow": 1.0, "single": false, "ladder": [1.0, 1.0, 1.0, 1.0], "band_lad": [1.0, 1.0, 1.0, 1.0], "w_fry": 0, "w_rb": 0, "w_fish": 0, "w_sky": 0, "sky_need": 1.0,
		"hostile": 1.6, "friend": 1.0, "hits": true, "star_sec": 30.0, "label": "CLASSIC"},
}
var diff = "easy"                    # "easy" | "hard" | "classic"
var diff_changed = false              # the player switched difficulty in the middle of this run (a hard record needs a run that was hard from the start)
var hard_clock = 0.0                  # seconds of play (cut scenes, cards and the codex do not count) for the HARD race
var hard_best = -1.0                  # the fastest time to the 24 fries in HARD (kept in user://records.json)
var hard_last = -1.0                  # the time of this run's 24th fry (-1 until then)
const RECORDS_PATH = "user://records.json"
const SETTINGS_PATH = "user://settings.cfg"
var input_offset_ms = 0.0             # round 18: rhythm timing offset (+ = a press counts as earlier: for a laggy screen or speakers; the browser build starts with a little)
var tab_toggle = false                # round 18: TAB toggles Gull Sight instead of being held (for hands that tire)
var board_open = true                 # round 18b: the goals board (top left); Q folds it away and brings it back

func load_settings():
	var c = ConfigFile.new()
	if c.load(SETTINGS_PATH) == OK:
		input_offset_ms = float(c.get_value("play", "offset_ms", 0.0))
		tab_toggle = bool(c.get_value("play", "tab_toggle", false))
		board_open = bool(c.get_value("play", "board_open", true))
	elif OS.has_feature("web"):
		input_offset_ms = 40.0

func save_settings():
	if OS.get_cmdline_user_args().size() > 0:
		return
	var c = ConfigFile.new()
	c.set_value("play", "offset_ms", input_offset_ms)
	c.set_value("play", "tab_toggle", tab_toggle)
	c.set_value("play", "board_open", board_open)
	c.save(SETTINGS_PATH)

func dp(k):
	return DP[diff][k]

func is_easy():
	return diff == "easy"

func is_hard():
	return diff == "hard"

func diff_label():
	return DP[diff]["label"]

func set_diff(d, mid_run = false):
	if not DP.has(d):
		return
	if mid_run and d != diff:
		diff_changed = true
	diff = d

# the town only turns on the gull when the crowd's attention is on its highest (EASY: "ALL EYES"); every pink CHARM fry raises the line a little (HARD)
func hostile_line():
	return dp("hostile") + (0.35 * charm() if diff == "hard" else 0.0)

func hostile():
	return watch >= hostile_line()

# kindness of the town: how often a friend turns up (CHARM fries add to it)
func friend_mult():
	return dp("friend") * (1.0 + 0.3 * charm())

# the pink fry is a CHARM fry since round 18: 0..3 (+ a little for every rainbow one)
func charm():
	return float(lv["pink"]) + 0.05 * rainbow["pink"]

func star_sec():
	return dp("star_sec")

func load_records():
	var f = FileAccess.open(RECORDS_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(d) == TYPE_DICTIONARY:
		hard_best = float(d.get("hard_best", -1.0))

func save_records():
	if OS.get_cmdline_user_args().size() > 0:
		return                       # the dev / test runs never touch a player's records
	var f = FileAccess.open(RECORDS_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"hard_best": hard_best}))
		f.close()

func time_text(secs):
	var s = int(max(secs, 0.0))
	return "%d:%02d" % [s / 60, s % 60]

const FRY_TYPES = ["red", "orange", "green", "cyan", "blue", "purple", "pink"]
const TOTAL_BASE = 10                 # 3 tutorial fries + 7 silver fries = the end of the first part
const FRY_CAP = 24                    # 3 + 7 x (silver, gold, diamond)
const MISSIONS = [3, 6, 10, 24]
const STAR_TOTAL = 14                 # gold + diamond of every type
const RAINBOW_MAX = 8
const SAVE_PATH = "user://savegame.json"
# every kind exists ONCE in the world and can be taken ONCE (only fries, rainbow fries and the drinks come back)
const WEARABLES = ["hat", "sailor", "topper", "beret", "glasses", "shades", "necklace", "bowtie", "scarf", "pipe", "hawaii", "stripes", "coat", "socks", "balloon", "cloud", "raincloud", "sun", "moon", "meteor", "skybow"]
const WEAR_NAMES = {"hat": "STRAW HAT", "sailor": "SAILOR CAP", "topper": "TOP HAT", "beret": "RED BERET", "glasses": "READING GLASSES", "shades": "SUNGLASSES", "necklace": "GOLD CHAIN",
	"bowtie": "BOW TIE", "scarf": "RED SCARF", "pipe": "PIPE", "hawaii": "FLOWER SHIRT", "stripes": "STRIPED SHIRT", "coat": "LONG COAT", "socks": "STRIPED SOCK", "balloon": "BALLOON",
	"cloud": "A WHOLE CLOUD", "raincloud": "A RAIN CLOUD", "moon": "A WHOLE MOON", "sun": "A LITTLE SUN", "meteor": "A SHOOTING STAR", "skybow": "A WHOLE RAINBOW"}
const TUT_NEED = {"TUTORIAL_01": 7.5, "TUTORIAL_02": 8.5, "TUTORIAL_03": 9.5}   # m/s: the first three fries, a gentle ramp (gauge 45 / 51 / 57)
# gauge speed needed to lock a fry of this type: [silver, gold, diamond]. The gull starts with a top speed of 90:
# silvers need 78-84 (a boost run-up), golds need SONIC (96-114 - a silver SONIC fry gives 105, a gold one 123), diamonds need 120-138 (SONIC gold 123 / diamond 144).
const NEED_GAUGE = {"red": [78, 90, 102], "orange": [78, 90, 106], "green": [72, 86, 102], "cyan": [78, 92, 104],
	"blue": [78, 90, 104], "purple": [72, 88, 102], "pink": [84, 98, 110]}       # round 19: gold and diamond only ask for a LITTLE more speed (they asked up to 144); the rainbow fry (150) is where it gets hard
# ROUND 7: the ladder of top speeds. The first SONIC fry (silver) covers EVERY silver and gold fry (the hardest gold needs 114), the second one (gold) covers every diamond
# fry (the hardest needs 144), and one drink on top of the first one reaches a diamond fry too.
const RAINBOW_NEED = 150.0           # round 8: a rainbow fry is five judgements and asks for a gold-SONIC gull or a drink or two on top of a silver one
# ROUND 10: the sky asks for the gull in its full-drink state, nothing more. Gauge = m/s x 6. A SILVER sonic fry (20) + all three drinks (+12.2) + STARLIGHT (+9)
# reaches 247, so every wonder of the sky (cloud, star, rainbow, sun) is within reach of a silver gull the moment it has all three cups running (gold: 277, diamond: 298
# - plenty of slack). The hard ones are the fish now (FISH_NEED).
const METEOR_NEED = 232.0            # a shooting star
const CLOUD_NEED = 225.0             # a whole cloud
const SKYBOW_NEED = 238.0            # the rainbow in the sky
const SUN_NEED = 244.0               # the sun (the moon asks for exactly the same)
const SUN_CIRCLES = 9                # round 16: nine suns (the old tale): the sun and the moon are 9 circles x 2 judgements
const MOON_NEED = 244.0
const RAINCLOUD_NEED = 225.0         # the grey cloud, as hard as the white one
const DECOR_NEED = 11.0               # m/s for borrowed hats, balloons... (mischief objects set their own)
const SPEED_UNIT = 6.0                # gauge number = m/s * SPEED_UNIT
const RARITY_NAMES = ["COMMON", "SILVER", "GOLD", "DIAMOND", "RAINBOW"]
const RARITY_COLORS = [Color("E8E4D4"), Color("C3CCD8"), Color("FFC83A"), Color("DDF4FF"), Color("FF8AD8")]
const TYPE_COLORS = {"red": Color("E8453C"), "orange": Color("F28A2E"), "green": Color("4FBF5A"), "cyan": Color("33CFD6"),
	"blue": Color("3D6FE0"), "purple": Color("9B5DE0"), "pink": Color("F277B5")}
const BOOST_TAB = [15.0, 20.0, 25.0, 28.5]   # gauge 90 -> 120 -> 150 -> 171
const ACCEL_TAB = [1.0, 1.5, 2.2, 3.2]
const STAM_TAB = [60.0, 90.0, 130.0, 190.0]
# the three time buffs (20 s each). They burn on the stamina bar and fade quickly once the gull lands or is hit.
const BUFF_SEC = 30.0                 # round 18: every cup lasts 30 s (it used to be 20: the players felt the drinks ended before they could use them)
const BUFF_CAP = 300.0                # drinks stack their time (and their states): a gull can keep the party going for as long as it keeps finding cups
const BUFF_TOP = {"coffee": 4.2, "alcohol": 5.0, "ice": 3.0}      # m/s of extra top speed (x6 for the gauge)
const STAR_SEC = 30.0
const STAR_TOP = 9.0                  # STARLIGHT: top speed on top of everything else
const BUFF_COL = {"coffee": Color("B9783C"), "alcohol": Color("FFD23A"), "ice": Color("8FE3F2")}
const BUFF_NAME = {"coffee": "COFFEE", "alcohol": "COCKTAIL", "ice": "ICE CREAM"}
# the side quests on the mission board: id -> [fries needed before it shows up, text on the board, "still hungry" line shown afterwards (big quests only), name of the REWARD (round 18), what it does]
# BIG quests (fish book, cloud, sun) end with the quiet moment; the small ones just tick off with a chime.
const QUESTS = {
	"star": [3, "RAINBOW TIME: ALL THREE DRINKS AT ONCE", "", "RAINBOW TIME", "FLY FREE, NOTHING CAN HURT YOU, SPEED SOARS"],
	"fish": [3, "CATCH A FISH", "", "OCEAN TIME", "THE SEA IS YOURS: SURF IT, LAUNCH AT THE FISH"],
	"drink": [3, "GET A DRINK", "", "A BOOST", "ALL YOUR BREATH BACK AND MORE SPEED"],
	"wear": [3, "GET AN ACCESSORY", "", "A NEW LOOK", "WEAR IT FROM THE CODEX (C)"],
	"rainbow": [6, "GET A RAINBOW FRY", "", "A BETTER GULL", "IT ADDS A LITTLE TO ITS COLOUR FOR EVER"],
	"sky": [10, "SKY HIGH! CLOUD, STAR, MOON, SUN, RAINBOW", "the whole sky, in one beak.|it was softer, warmer and louder than i expected.|and somehow i'm still hungry.", "WEAR THE SKY", "WHAT YOU CATCH UP THERE STAYS WITH YOU"],
}
const BIG_QUESTS = ["sky"]
const SKY_THINGS = ["cloud", "raincloud", "moon", "sun", "skybow", "meteor"]      # the things of the sky keep their speeds in every difficulty (their challenge is the challenge of EASY)
const SKY_KINDS = ["cloud", "star", "moon", "sun", "rainbow"]      # the five things of the sky quest (a rain cloud counts as the cloud; catching both is an achievement of its own)
const QUEST_SHOWN = 5                 # lines on the board at once

# ---- the fish book: nine kinds in three rarities (2 / 3 / 5 judgements, faster gull needed). Length in cm, weight in kg (rolled per fish) ----
# [name, rarity, len_min, len_max, kg_min, kg_max, body colour, belly colour]
const FISH_SPECIES = {
	"sardine": ["SILVER SARDINE", 0, 12, 22, 0.03, 0.12, "9FB8C6", "F4F8FA"],
	"mackerel": ["STRIPY MACKEREL", 0, 26, 44, 0.25, 0.9, "4F8FA3", "F2EFE0"],
	"herring": ["GREEDY HERRING", 0, 20, 36, 0.12, 0.5, "7C9BB0", "F6F1E6"],
	"mullet": ["RED MULLET", 1, 18, 38, 0.1, 0.6, "E27058", "F8D9C8"],
	"flyer": ["FLYING FISH", 1, 24, 40, 0.2, 0.9, "3E7BD0", "DCEBFA"],
	"bass": ["SEA BASS", 1, 40, 90, 0.8, 7.0, "6B7E6A", "E6E4D0"],
	"tuna": ["GOLDEN TUNA", 2, 80, 210, 8.0, 95.0, "E2B33A", "FFF1B8"],
	"opah": ["MOONFISH", 2, 60, 150, 18.0, 90.0, "C7556B", "F6B6C2"],
	"marlin": ["RAINBOW MARLIN", 2, 150, 330, 40.0, 220.0, "37B7D9", "D9F6FF"],
}
const FISH_ORDER = ["sardine", "mackerel", "herring", "mullet", "flyer", "bass", "tuna", "opah", "marlin"]
const FISH_RARITY_NAMES = ["COMMON", "RARE", "LEGENDARY"]
const FISH_RARITY_COLORS = [Color("BFD7E4"), Color("B58CF0"), Color("FFC83A")]
const FISH_NEED = [96.0, 132.0, 186.0]     # gauge speed to catch a fish of this rarity (round 10: rare 120 -> 132, legendary 144 -> 186: gold SONIC plus a drink or two)
const FISH_JUDGE = [2, 6, 10]       # judgements (every circle is judged twice)
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
	"pink": ["CHARM FRY", "CHARMING FRY", "IRRESISTIBLE FRY"],        # round 18: the pink fry is the CHARM fry (it was the FLUFF fry: nobody hits a gull any more unless the crowd is on full alert)
}
const STAT_NAMES = {"red": "TOP SPEED", "orange": "ACCELERATION", "green": "STEADY TIMING", "cyan": "GULL SIGHT", "blue": "STAMINA", "purple": "RECOVERY", "pink": "CHARM"}
const CHARM_LINES = ["", "STRANGERS SMILE FIRST", "GULLS COME TO SAY HELLO", "EVEN THE DOGS ARE FRIENDS"]
const DESCS = {
	"red": ["Faster at the very top.\nCruising stays exactly the same.", "The top of the dial moves up again.", "The dial runs out of numbers."],
	"orange": ["Speeds up sooner.\nThe top speed is still yours alone.", "Less runway. More gull.", "The runway is now a rumour."],
	"green": ["Wider bands, slower rings.\nLess thinking, better grabbing.", "Even less thinking.", "Your beak no longer shakes. Neither does the fry."],
	"cyan": ["Squinting, but with magic.\nGull Sight reaches twice as far.", "Everything far away glows.", "Look all you like. It costs nothing."],
	"blue": ["More sky before you need a rest.", "Lungs the size of a pier.", "You are mostly lungs now."],
	"purple": ["Apparently breathing is useful.", "Resting is now a competitive sport.", "Naps are optional. Recovery is not."],
	"pink": ["People smile at you first.\nHits hurt a little less, too.", "Kids and other gulls come to say hello.\nFluffier. Harder to hurt.", "Even the dogs want to be friends.\nA cloud with a beak."],
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
var heat_decay_mult = 1.0             # round 12: far from the crowd and high in the sky the town forgets in seconds (main._update_watch sets it)
var watch = 0.0                       # crowd alertness around the player right now: heat + people who are looking (0..4)
var sense_active = false              # Gull Sight held (slow motion + dark screen)
var vision_tired = false
var codex_open = false
var no_focus_pause = false            # dev test modes: a minimised window must not pause the bot
var showcase_active = false
var film_flow = false                # a flow film moment is running: the gull keeps flying, but nothing new may lock or open Gull Sight
var achievements_done = {}
var fries_eaten = 0
var mischief_counts = {}
var invert_y = false
var run_time = 0.0
var end_time = -1.0
var hunger_t = 0.0                    # seconds spent STILL HUNGRY (drives the "where is it?" hints)
var stats = {}
var drink = ""                        # the latest buff the gull has had ("" when none is running): "coffee" | "alcohol" | "ice"
var drink_t = 0.0                     # seconds left of that latest buff
var buff = {"coffee": 0.0, "alcohol": 0.0, "ice": 0.0}          # seconds left of every buff (real seconds)
var buff_dying = {"coffee": false, "alcohol": false, "ice": false}   # landed / hit: the bar now burns away fast
var buff_msg = ""                     # the lower-left line ("senses sharpened...") and when it appeared
var buff_msg_t = -9.0
var quests = {}                       # id -> "active" | "done"
var quest_flash = ""                  # a quest that was finished a moment ago (the HUD fades out, a line fades in)
var menu_seen = {}                    # codex items already seen (the NEW dots)
var lite_flags = 0                    # dev (web only): see `?lite=N` in `_ready`
var web = OS.has_feature("web")       # the browser build: a lighter world (fewer people, no grass blades far away, no MSAA, smaller shadows...)
var test_boost_bonus = 0.0            # dev tests only: extra top speed so the bot can reach diamond fries
var star_t = 0.0                      # seconds of STARLIGHT left (all three drinks at once)
var star_total = 0                    # how many times the gull has been in it
var fish_book = {}                    # species id -> {"n": caught, "kg": heaviest, "cm": longest}
const QUEST_POP_SEC = 4.6             # round 19: how long a finished goal holds the board on the screen
var quest_pops = []                   # round 19: {id, t0} the finished goals that still have to be shown on the board
func quest_pop(id):
	var now = msec() / 1000.0
	var t0 = now
	if quest_pops.size() > 0:
		t0 = max(now, quest_pops[quest_pops.size() - 1]["t0"] + QUEST_POP_SEC)
	quest_done_at[id] = t0
	quest_pops.append({"id": id, "t0": t0})
var quest_done_at = {}             # quest id -> game seconds when it was ticked off (the board drops it a little later)
var cine_hold = null                  # a caught thing (a fish, a star) that the cinematic moment keeps alive until it is over
var sky_got = {}                      # round 15: the five sky things caught this run: cloud | star | moon | sun | rainbow
var clouds_got = {}                   # ...which clouds: cloud | raincloud
var sight_time = 0.0                  # seconds Gull Sight has been held in total (the TAB lesson ends after a few)
var tab_lesson = 0                    # 0 = not shown yet, 1 = prompt on screen, 2 = done
var cine_seen = {}                    # the cinematic moments that have been shown already (each plays once per run): drinks3, fish, meteor, all24
var coach_done = {}                   # round 18: the steps of the first-fry coach the player has already done (climb / tab / dive / press), see main._coach_tick

# ---- ROUND 16: OCEAN TIME. A fish gives the breath back and starts (or tops up) a state of the sea: on the water the gull surfs at no cost, Space on the water is a
# LAUNCH (a big, short burst of acceleration to catch the fish that jump), and every other fish starts leaping so that a streak is easy to keep going.
# When RAINBOW TIME and OCEAN TIME run together, the SEA (the water and the air just above it) belongs to OCEAN TIME and the air to RAINBOW TIME (see `fish_mode`).
const FISH_FIRST_SEC = 22.0
const FISH_ADD = [10.0, 15.0, 24.0]    # seconds per fish: common, rare, legendary
const FISH_CAP = 90.0
const FISH_TOP = 3.0                   # m/s of extra top speed in the sea while OCEAN TIME runs (the fish ask for a lot)
const FISH_STREAK_SEC = 14.0           # a fish within this many seconds of the last one keeps the streak going
const SEA_ZONE_H = 9.0                 # the "sea" reaches this high above the water (a leaping fish tops out at ~4.4 m)
var fish_t = 0.0                       # seconds of OCEAN TIME left
var fish_streak = 0
var fish_streak_t = 0.0
var fish_best_streak = 0
var sea_zone = false                   # the gull is over the sea and low: the player script sets this every frame
var cutscene = false                   # a film moment / the story is on screen: the drinks and OCEAN TIME wait (main / story_scenes set it)
var replay = ""                      # round 20: "opening" / "ending" while WATCH STORY is playing (nothing is saved meanwhile)
var free_play = false                  # round 16: the ending is over and the player kept playing (every colour, every fish, every achievement still to get)
var slot = 1                           # which of the save slots this run lives in
var autoload_slot = 0                  # a reload that must continue a slot at once (KEEP PLAYING after the credits)

func fish_active():
	return fish_t > 0.0

# the sea belongs to OCEAN TIME while it runs; everywhere else RAINBOW TIME (if it runs) is in charge
func fish_mode():
	return fish_t > 0.0 and sea_zone

func add_fish_time(rarity):
	var was = fish_t > 0.0
	remember("fishtime")
	if fish_streak_t <= 0.0:
		fish_streak = 0
	fish_streak += 1
	fish_best_streak = max(fish_best_streak, fish_streak)
	fish_streak_t = FISH_STREAK_SEC
	fish_t = min(fish_t + FISH_ADD[clamp(rarity, 0, 2)] + (0.0 if was else FISH_FIRST_SEC), FISH_CAP)
	if not was:
		fish_started.emit()
	fish_added.emit(fish_streak, rarity)
	if fish_streak >= 5:
		ach_unlock("fishstreak")

func end_fish():
	if fish_t > 0.0:
		fish_t = 0.0
		fish_streak = 0
		fish_ended.emit()

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 240 Hz uncapped rendering of a ~2000-draw-call scene saturated a laptop GPU/CPU (system-wide lag after a while).
	# 60 fps is plenty: physics already runs at 60 Hz.
	Engine.max_fps = 60
	_init_clock()
	ach_load()
	load_records()
	load_settings()
	# round 18: the dev / test runs keep the numbers of round 17 ("classic") unless they ask for --easy / --hard; a player's run starts EASY (the menu asks, the save remembers)
	var ua = OS.get_cmdline_user_args()
	if ua.size() > 0:
		diff = "classic"
		if "--easy" in ua:
			diff = "easy"
		elif "--hard" in ua:
			diff = "hard"
	var keys = {"move_forward": KEY_W, "move_back": KEY_S, "bank_left": KEY_A, "bank_right": KEY_D,
		"flap": KEY_SPACE, "dash": KEY_SHIFT, "land": KEY_CTRL, "interact": KEY_E, "squawk": KEY_F,
		"gull_sense": KEY_TAB, "codex": KEY_C, "pause_game": KEY_ESCAPE, "turn_back": KEY_R, "board_toggle": KEY_Q}
	for a in keys:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
		var ev = InputEventKey.new()
		ev.physical_keycode = keys[a]
		InputMap.action_add_event(a, ev)
	reset_stats()
	# round 17: the language. The player picks it on the card before the cover (ui/menus.gd); it is remembered in user://language.cfg.
	# Dev / test runs stay in English unless they pass --lang=zh_CN / zh_TW / ja; --loc-log writes every shown line that has no translation.
	var uargs = OS.get_cmdline_user_args()
	var la = ""
	for a in uargs:
		if a.begins_with("--lang="):
			la = a.substr(7)
	if "--loc-log" in uargs:
		Loc.record = true
	if la == "":
		la = "en" if uargs.size() > 0 else Loc.guess()
	Loc.set_lang(la)
	if web:
		# the browser build restarts by reloading the page (main.gd `_reload`): the choice (straight into a new run, or the menu) comes through the tab's session storage
		var v = JavaScriptBridge.eval("(function(){ try { var v = sessionStorage.getItem('jsf_skip_menu'); sessionStorage.removeItem('jsf_skip_menu'); return v; } catch (e) { return null; } })()")
		skip_menu = str(v) == "1"
		web_reloaded = v != null                  # a reload from inside the game (restart / back to the menu): the language card is not shown again
		var vd = JavaScriptBridge.eval("(function(){ try { var v = sessionStorage.getItem('jsf_diff'); sessionStorage.removeItem('jsf_diff'); return v; } catch (e) { return null; } })()")
		if vd != null and DP.has(str(vd)):
			diff = str(vd)                      # round 18: a restart keeps the difficulty of the run
		var vs = JavaScriptBridge.eval("(function(){ try { var v = sessionStorage.getItem('jsf_slot'); sessionStorage.removeItem('jsf_slot'); return v; } catch (e) { return null; } })()")
		autoload_slot = int(str(vs)) if (vs != null and str(vs).is_valid_int()) else 0
		# dev: `?lite=N` in the page address switches parts of the film moments off to find out what costs the most in the browser (1 = no close-ups, 2 = no blur, 4 = no letterbox bars + words)
		var lv = JavaScriptBridge.eval("(function(){ try { return new URLSearchParams(location.search).get('lite'); } catch (e) { return null; } })()")
		if lv != null:
			lite_flags = int(str(lv))

# The clock every timed thing in the game reads (rhythm rings, dialogue, cards). Normally the wall clock; under Movie Maker
# (--write-movie, the walkthrough video) frames render slower than real time, so there it counts movie frames instead.
var web_reloaded = false

func _exit_tree():
	if Loc.record:
		Loc.dump_misses(ProjectSettings.globalize_path("res://").path_join("../shots/loc_miss_%d.txt" % Time.get_ticks_usec()))
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
	if web:
		end_m *= 0.55
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
		heat = max(heat - delta / 30.0 * heat_decay_mult, 0.0)
	# round 16: the drinks and OCEAN TIME run on GAME time (Gull Sight and the grab slow-motion slow them too, so a player who taps TAB keeps them longer) and wait
	# while a film moment, the story or the credits are on screen
	if not get_tree().paused and not codex_open and not showcase_active and not cutscene and not film_flow:
		_buff_tick(delta)

func reset_stats():
	stats = {"stolen": 0, "perfect": 0, "shot": 0, "slipped": 0, "walls": 0, "missed": 0, "swats": 0, "vision_s": 0.0, "fish": 0, "rivals": 0, "bops": 0, "scares": 0,
		"drinks": 0, "fed": 0, "friends": 0, "rainbow": 0, "star": 0, "gifts": 0, "meteors": 0}

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
	for k in buff:
		buff[k] = 0.0
		buff_dying[k] = false
	buff_msg = ""
	quests = {}
	quest_flash = ""
	menu_seen = {}
	star_t = 0.0
	star_total = 0
	cine_seen = {}
	sky_got = {}
	clouds_got = {}
	sight_time = 0.0
	tab_lesson = 0
	memories = {}
	cine_hold = null
	fish_book = {}
	quest_done_at = {}
	quest_pops = []
	fish_t = 0.0
	fish_streak = 0
	fish_streak_t = 0.0
	fish_best_streak = 0
	last_steal_t = -999.0
	sea_zone = false
	cutscene = false
	free_play = false
	hard_clock = 0.0
	hard_last = -1.0
	diff_changed = false
	coach_done = {}
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

# round 16: the crowd only stays wary of a gull that keeps stealing. A gull that has taken nothing for IDLE_CALM seconds is forgotten quickly (heat and the watching crowd
# fade to zero in a few seconds) and stays forgotten until its next theft.
const IDLE_CALM = 8.0
var last_steal_t = -999.0             # game clock (seconds) of the last successful theft
func mark_steal():
	last_steal_t = msec() / 1000.0

func idle_steal_s():
	return msec() / 1000.0 - last_steal_t

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
	if AWARD_MEM.has(title):
		remember(AWARD_MEM[title])
	if AWARD_ID.has(title):
		ach_unlock(AWARD_ID[title])
		return
	achievement.emit(title)

# ---- ROUND 15: the achievements (a gallery that lives in the player's profile, not in one run): id -> [name, what to do, the game's comment]
const ACH = {
	"first_fry": ["FIRST BITE", "Steal your very first fry.", "It was warm, it was salty, and it was somebody else's."],
	"plain_first": ["THE FIRST ONE IS THE LAST ONE", "Eat the plain fry before you take a single magic one.", "A very short game. A very full gull."],
	"enough": ["JUST SOME FRIES", "Eat the plain fry at the very end.", "Everything you needed was on the table. It usually is."],
	"all24": ["ALL 24", "Own every fry: silver, gold and diamond of all seven colours.", "A complete set. The pier is nervous."],
	"seven": ["SEVEN COLOURS", "Get a fry of every colour.", "A taste for the whole spectrum. Mostly salt, though."],
	"rainbowfry": ["TASTE THE RAINBOW", "Get your first rainbow fry.", "It is, regrettably, not fruit flavoured."],
	"rainbowtime": ["RAINBOW TIME", "Run coffee, cocktail and ice cream at the same time.", "The sky made room. So did the laws of physics."],
	"happyhour": ["HAPPY HOUR", "Taste coffee, a cocktail and ice cream.", "Three drinks, zero regrets, one very busy beak."],
	"skyall": ["SKY HIGH!", "Catch a cloud, a star, the moon, the sun and a rainbow.", "You own the sky now. Please do not tell the airlines."],
	"clouds2": ["FAIR WEATHER, FOUL WEATHER", "Catch the white cloud and the rain cloud.", "A gull for every season. And every umbrella."],
	"moon": ["OVER THE MOON", "Catch the moon.", "Cheese was never confirmed."],
	"sun": ["TOO HOT TO HANDLE", "Catch the sun.", "Warm, brilliant, and a little hard on the beak."],
	"star": ["WISHFUL THINKING", "Catch a shooting star.", "Wish granted: more speed. Wish pending: more fries."],
	"fishall": ["THE WHOLE SEA", "Catch every kind of fish.", "Nine species. One extremely smug gull."],
	"bigfish": ["BIG FISH ENERGY", "Catch a legendary fish.", "The pier saw it. The pier will exaggerate."],
	"wearall": ["FASHION WEEK", "Wear every kind of clothing on the island.", "More hats than a gull has heads. Mathematically concerning."],
	"brolook": ["SAME BIG BRO ENERGY", "Wear a top hat, shades, a chain, a pipe and a long coat at once.", "Spot the difference. Hint: it is the squint."],
	"friend": ["NEW FRIEND", "Let another gull sit down next to you.", "Hearts were exchanged. No fries were shared."],
	"kind": ["A KIND WORLD", "Be given a gift by a stranger or a child.", "Turns out the town was never against you. Just busy."],
	"puppy": ["GOOD BOY", "Be circled by a happy puppy.", "He is not guarding anything. He just likes you."],
	"thermal": ["THERMAL RIDER", "Soar up on a column of warm air.", "Free altitude. Freer than free."],
	"skim": ["SKIMMER", "Skim the sea at speed.", "Wet feet, dry wit."],
	"wall": ["WALL KISS", "Fly into a wall at full speed.", "The wall is fine. The wall is always fine."],
	"fishstreak": ["SCHOOL'S IN", "Catch five fish in one OCEAN TIME.", "The sea ran out of excuses before you ran out of beak."],
	"callgulls": ["BIRDS OF A FEATHER", "Call a flock of gulls to a rooftop with F.", "You did not ask them to come. They came anyway. Hearts."],
	"callkind": ["WELL, HELLO", "Squawk at a calm crowd and be waved at.", "Turns out a good squawk is just a loud hello."],
	"callshoo": ["INDOOR VOICE", "Squawk at a wary crowd and be chased off.", "They did not want your hello. They wanted a quiet pier."],
	"freeplay": ["ONE MORE LAP", "Keep playing after the end.", "The fry is eaten. The sky is not."],
	"innocent": ["INNOCENT AS A SEAGULL", "Calm a crowd that was on full alert, until nobody is watching you.", "Whistle. Look at the clouds. Works every time."],
}
const AWARD_ID = {"EARLY BIRD": "plain_first", "ENOUGH": "enough", "ALL 24": "all24", "RAINBOW": "rainbowfry", "BIG FISH ENERGY": "bigfish", "NEW FRIEND": "friend",
	"A FRIEND WHO SHARES": "kind", "A KIND CHILD": "kind", "THERMAL RIDER": "thermal", "SKIMMER": "skim", "WALL KISS": "wall", "WISHFUL THINKING": "star", "TOO HOT TO HANDLE": "sun"}
const ACH_PATH = "user://achievements.json"
var ach_profile = {}                  # id -> {"date": "2026-10-11"}
var ach_persist = true

func ach_load():
	ach_persist = OS.get_cmdline_user_args().size() == 0           # the dev / test runs never touch the real profile
	if not ach_persist or not FileAccess.file_exists(ACH_PATH):
		return
	var f = FileAccess.open(ACH_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(d) == TYPE_DICTIONARY:
		for k in d:
			if ACH.has(k) and typeof(d[k]) == TYPE_DICTIONARY:
				ach_profile[k] = d[k]

func ach_save():
	if not ach_persist:
		return
	var f = FileAccess.open(ACH_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(ach_profile))
		f.close()

func ach_has(id):
	return ach_profile.has(id)

func ach_date(id):
	return str(ach_profile.get(id, {}).get("date", ""))

func ach_count():
	return ach_profile.size()

func ach_unlock(id):
	if not ACH.has(id) or ach_profile.has(id):
		return false
	var d = Time.get_date_dict_from_system()
	ach_profile[id] = {"date": "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]}
	ach_save()
	achievement_unlocked.emit(id)
	return true

# the achievements that are a state of the run, not an event: looked at every second or so
const BRO_LOOK = ["topper", "shades", "necklace", "pipe", "coat"]
func ach_tick():
	if special_count() >= FRY_TYPES.size():
		ach_unlock("seven")
	if mischief_counts.get("coffee", 0) > 0 and mischief_counts.get("alcohol", 0) > 0 and mischief_counts.get("icecream", 0) > 0:
		ach_unlock("happyhour")
	var n = 0
	for k in WEARABLES:
		if not (k in ["cloud", "raincloud", "sun", "moon", "meteor", "skybow"]) and worn.has(k):
			n += 1
	if n >= WEARABLES.size() - 6:
		ach_unlock("wearall")
	var all_on = true
	for k in BRO_LOOK:
		if not equipped.has(k):
			all_on = false
	if all_on:
		ach_unlock("brolook")
	if fish_book.size() >= FISH_ORDER.size():
		ach_unlock("fishall")

# ---- the gull's memories (round 8): the things it really did, in the order it did them. The ending plays them back while the plain fry is being chewed.
const AWARD_MEM = {"OVER THE MOON": "moon", "RAIN ON MY PARADE": "raincloud", "ESPRESSO": "coffee", "LAST ORDERS": "alcohol", "SWEET TOOTH": "ice", "GONE FISHING": "fish", "BIG FISH ENERGY": "bigfish", "HEAD IN THE CLOUDS": "cloud",
	"TOO HOT TO HANDLE": "sun", "OVER THE RAINBOW": "skybow", "WISHFUL THINKING": "meteor", "NEW FRIEND": "friend", "A FRIEND WHO SHARES": "gift", "A KIND CHILD": "kid", "RAINBOW": "rainbow",
	"THERMAL RIDER": "thermal", "SKIMMER": "skim", "WALL KISS": "wall", "FULLY ARMED": "armed", "ALL 24": "all24"}
var memories = {}                     # id -> {"t": seconds of the run when it happened, ...}

func remember(id, data = {}):
	if memories.has(id):
		if not data.is_empty():
			memories[id].merge(data, true)
		return
	var d = data.duplicate()
	d["t"] = run_time
	memories[id] = d
	memory_added.emit(id)

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

# ---- the three buffs (20 s per cup, and every cup ADDS its time; the three kinds stack with each other) ----
#   COFFEE     snappier acceleration, a higher top speed, and the world slows much more while you grab (senses sharpened: the rings are easier)
#   COCKTAIL   a higher top speed and NO stamina cost, but the grab slow-motion is much milder (a duller gull: harder rings)
#   ICE CREAM  nothing can hurt you (dogs, kids, walls...) and a higher top speed
# Every cup refills the gull's breath on the spot, so a drink never leaves the gull stuck on the ground. Nothing burns a buff away any more:
# it runs its time out, whatever the gull does. All three at once = STARLIGHT (30 s).
func has_buff(kind):
	return buff[kind] > 0.0

func add_buff(kind, sec = BUFF_SEC):
	var was = buff[kind] > 0.0
	remember({"coffee": "coffee", "alcohol": "alcohol", "ice": "ice"}.get(kind, kind))
	buff[kind] = min(buff[kind] + sec, BUFF_CAP)
	buff_dying[kind] = false
	drink = kind
	drink_t = buff[kind]
	if not was:
		buff_started.emit(kind)
	buff_added.emit(kind, was)
	drink_changed.emit(kind)
	if star_t <= 0.0 and buff["coffee"] > 0.0 and buff["alcohol"] > 0.0 and buff["ice"] > 0.0:
		start_star()

func set_drink(kind, sec = BUFF_SEC):      # kept for old call sites ("" clears everything)
	if kind == "":
		for k in buff:
			if buff[k] > 0.0:
				buff[k] = 0.0
				buff_ended.emit(k)
		drink = ""
		drink_t = 0.0
		drink_changed.emit("")
		return
	add_buff(kind, sec)

# kept for old call sites: nothing burns a drink away any more
func buffs_die(_include_ice = true):
	pass

func start_star():
	remember("starlight")
	ach_unlock("rainbowtime")
	star_t = star_sec()
	star_total += 1
	stats["star"] = stats.get("star", 0) + 1
	star_started.emit()

# RAINBOW TIME as the gull feels it right now: in the sea OCEAN TIME is in charge, so the rainbow stays quiet there
func star_active():
	return star_t > 0.0 and not fish_mode()

func end_star():
	if star_t > 0.0:
		star_t = 0.0
		star_ended.emit()

func _buff_tick(rdt):
	var latest = ""
	var latest_t = 0.0
	for k in buff:
		if buff[k] <= 0.0:
			continue
		buff[k] = max(buff[k] - rdt, 0.0)
		if buff[k] <= 0.0:
			buff_ended.emit(k)
		elif buff[k] >= latest_t or latest == "":
			latest = k
			latest_t = buff[k]
	if latest != drink:
		drink = latest
		drink_changed.emit(latest)
	drink_t = buff[latest] if latest != "" else 0.0
	if star_t > 0.0:
		star_t = max(star_t - rdt, 0.0)
		if star_t <= 0.0:
			star_ended.emit()
	if fish_streak_t > 0.0:
		fish_streak_t = max(fish_streak_t - rdt, 0.0)
	if fish_t > 0.0:
		fish_t = max(fish_t - rdt, 0.0)
		if fish_t <= 0.0:
			fish_streak = 0
			fish_ended.emit()

# the lower-left one-liner ("senses sharpened...")
func say_buff(text):
	buff_msg = text
	buff_msg_t = msec() / 1000.0

func invincible():
	return buff["ice"] > 0.0 or star_active()

func drink_speed_mult():
	return 1.0

func drink_accel_mult():
	var m = 2.2 if buff["coffee"] > 0.0 else 1.0
	if star_active():
		m *= 2.0
	if fish_mode():
		m *= 1.5
	return m

# how much the grab slow-motion slows the world: coffee deeper, cocktail milder, STARLIGHT deepest of all
func slowmo_mult():
	var m = 1.0
	if buff["coffee"] > 0.0:
		m *= 0.55
	if buff["alcohol"] > 0.0:
		m *= 1.7
	if star_active():
		m = min(m, 0.5)
	return m

# the judgement bands: coffee widens them a little (clear senses), the cocktail narrows them (a dull gull), STARLIGHT sharpens everything
func buff_window_mult():
	var m = 1.0
	if buff["coffee"] > 0.0:
		m *= 1.3
	if buff["alcohol"] > 0.0:
		m *= 0.88
	if star_active():
		m = max(m, 1.0) * 1.5
	if fish_mode():
		m *= 1.25
	return m

# nothing costs stamina: the cocktail and STARLIGHT
func free_flight():
	return buff["alcohol"] > 0.0 or star_active() or fish_mode() or (dp("free_early") and gull_sense_count < 3)      # round 18: EASY never runs out of breath while learning

# ---- "where to fly next": the nearest fry that the gull's top speed can really lock (E in free flight, and the arrow of Gull Sight) ----
var sniff_node = null
var sniff_until = 0.0

func reachable(f):
	return need_speed(f) <= boost_speed() + 0.02

func nearest_fry(from_pos, reachable_only = true):
	var best = null
	var bd = 1e9
	for f in get_tree().get_nodes_in_group("fries"):
		if not is_instance_valid(f) or f.ftype == "ordinary":
			continue
		if f.vision_info() == null or not f.is_snatchable():
			continue
		if reachable_only and not reachable(f):
			continue
		var d = from_pos.distance_to(f.global_position)
		if d < bd:
			bd = d
			best = f
	return best

# ---- stat formulas (every number a player can feel lives here) ----
func glide_speed():
	return 5.0 * drink_speed_mult() + (4.0 if star_active() else 0.0)

func cruise_speed():
	return 11.0 * drink_speed_mult() + (7.0 if star_active() else 0.0)      # fries never change this

# the TOP speed: boost. Sonic fries lift it; every buff lifts it a bit more
func boost_speed():
	var b = BOOST_TAB[lv["red"]] + 0.15 * rainbow["red"] + test_boost_bonus
	for k in BUFF_TOP:
		if buff[k] > 0.0:
			b += BUFF_TOP[k]
	if star_active():
		b += STAR_TOP
	if fish_mode():
		b += FISH_TOP
	return b

func accel_mult():
	return (ACCEL_TAB[lv["orange"]] + 0.04 * rainbow["orange"]) * drink_accel_mult()

func stamina_max():
	return (STAM_TAB[lv["blue"]] + 4.0 * rainbow["blue"]) * dp("stam")

func regen_glide():
	return REGEN_GLIDE_TAB[lv["purple"]] * (1.0 + 0.03 * rainbow["purple"]) * dp("regen_air")

func regen_perch(high):
	var base = 14.0 if high else 9.0
	return base * (REGEN_PERCH_TAB[lv["purple"]] + 0.04 * rainbow["purple"]) * dp("regen_perch")

# round 18: how much a point of flight costs (EASY: half)
func drain_mult():
	return dp("drain")

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
	if tab_lesson < 2:
		return 0.0                # round 16: the first look through Gull Sight is free: the lesson must never fail on an empty bar
	return VISION_BASE_COST * VISION_TAB[lv["cyan"]] * dp("sight")      # round 18: EASY a quarter of it AND per second of game time (the slow world makes it a trickle)

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
	var k = dp("need")
	match f.ftype:
		"tutorial":
			return TUT_NEED.get(f.id, 10.0) * k
		"fish":
			return f.min_speed
		"mischief":
			return f.min_speed * (1.0 if f.kind in SKY_THINGS else k)
		"ordinary":
			return 0.0
	if f.tier >= 4:
		return RAINBOW_NEED / SPEED_UNIT
	if f.utype != "" and NEED_GAUGE.has(f.utype):
		return NEED_GAUGE[f.utype][clamp(f.tier, 1, 3) - 1] / SPEED_UNIT * k
	return 11.0 * k

# ---- the side quests on the mission board (fish / cloud / sun): they appear after enough fries, finishing one is a quiet moment ----
func quest_state(id):
	return quests.get(id, "")

func quests_refresh():
	for id in QUESTS:
		if quests.get(id, "") == "" and gull_sense_count >= 3 and fry_total() >= QUESTS[id][0]:
			quests[id] = "active"
	quests_check()

func quest_finish(id):
	if quests.get(id, "") == "done":
		return
	quests[id] = "done"
	quest_done_at[id] = msec() / 1000.0
	if id in BIG_QUESTS:
		quest_flash = id
	quest_done.emit(id)

# [now, total] of a quest that counts (m / n on the board), or [] when it does not count
func quest_progress(id):
	match id:
		"sky":
			return [sky_got.size(), SKY_KINDS.size()]
	return []

func quest_label(id):
	var t = QUESTS[id][1]
	var pr = quest_progress(id)
	if pr.size() == 2:
		t += "   %d / %d" % [pr[0], pr[1]]
	return t

func _quest_ok(id):
	match id:
		"drink":
			return stats.get("drinks", 0) >= 1
		"sky":
			var pr = quest_progress(id)
			return pr[0] >= pr[1]
		"star":
			return star_total >= 1
		"wear":
			return worn.size() >= 1
		"rainbow":
			return rb_seen >= 1
		"fish":
			return not fish_book.is_empty()
	return false

# round 15: one of the five things of the sky was caught. `kind` = cloud | raincloud | star | moon | sun | rainbow
func sky_catch(kind):
	var key = "cloud" if kind == "raincloud" else kind
	var fresh = not sky_got.has(key)
	sky_got[key] = true
	if kind == "cloud" or kind == "raincloud":
		clouds_got[kind] = true
	remember("sky_" + kind)
	sky_caught.emit(kind, sky_got.size())
	if clouds_got.size() >= 2:
		ach_unlock("clouds2")
	match kind:
		"moon":
			ach_unlock("moon")
		"sun":
			ach_unlock("sun")
		"star":
			ach_unlock("star")
	quests_check()
	if sky_got.size() >= SKY_KINDS.size():
		ach_unlock("skyall")
	return fresh

# tick off every quest whose condition is met (the sky quests are ticked off by the cloud and the sun themselves)
func quests_check():
	for id in QUESTS:
		if quests.get(id, "") == "active" and _quest_ok(id):
			quest_finish(id)

# the lines of the board: the unfinished quests in order (at most QUEST_SHOWN), and the ones ticked off in the last 12 seconds
func quests_shown():
	var out = []
	var now = msec() / 1000.0
	var n_active = 0
	for id in QUESTS:
		var st = quests.get(id, "")
		if st == "active" and n_active < QUEST_SHOWN:
			out.append(id)
			n_active += 1
		elif st == "done" and now - quest_done_at.get(id, -99.0) < 12.0:
			out.append(id)
	return out

# ---- the fish book ----
func fish_pick_species(force_rar = -1):
	var r = randf()
	var rar = 0 if r < 0.58 else (1 if r < 0.88 else 2)
	if force_rar >= 0:
		rar = force_rar
	var pool = []
	for k in FISH_ORDER:
		if FISH_SPECIES[k][1] == rar:
			pool.append(k)
	return pool[randi() % pool.size()]

func fish_roll(sp):
	var d = FISH_SPECIES[sp]
	var u = pow(randf(), 1.7)            # most fish are smallish, now and then a monster
	var len_cm = lerp(float(d[2]), float(d[3]), u)
	var kg = lerp(float(d[4]), float(d[5]), pow(u, 2.2) * randf_range(0.85, 1.12))
	return {"sp": sp, "len": len_cm, "kg": clamp(kg, float(d[4]), float(d[5]) * 1.1)}

func fish_record(f):
	var sp = f["sp"]
	var e = fish_book.get(sp, null)
	var info = {"sp": sp, "len": f["len"], "kg": f["kg"], "new": e == null, "rec_len": false, "rec_kg": false}
	remember("fish", {"sp": sp, "len": f["len"], "kg": f["kg"]})
	if e == null:
		e = {"n": 0, "kg": 0.0, "cm": 0.0}
	else:
		info["rec_len"] = f["len"] > e["cm"] + 0.05
		info["rec_kg"] = f["kg"] > e["kg"] + 0.0005
	e["n"] += 1
	e["kg"] = max(e["kg"], f["kg"])
	e["cm"] = max(e["cm"], f["len"])
	fish_book[sp] = e
	fish_caught.emit(info)
	return info

func fish_kg_text(kg):
	if kg < 1.0:
		return "%d g" % int(round(kg * 1000.0))
	return "%.1f kg" % kg

func fish_cm_text(cm):
	if cm >= 100.0:
		return "%.2f m" % (cm / 100.0)
	return "%d cm" % int(round(cm))

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
			return "%s   -   HITS -%d %%" % [CHARM_LINES[clamp(level, 0, 3)], int(round((1.0 - HURT_TAB[level]) * 100.0))]
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
			return "+1 % CHARM"
	return ""

# ---- save game (a plain JSON file in the user folder): the run so far, the gull's stuff and where it was ----
# round 16: two save slots. Slot 1 keeps the old file name (an older save simply is slot 1).
const SLOTS = 3         # round 19: three slots (it was two)
func save_path(sl = 0):
	var n = slot if sl <= 0 else sl
	if OS.get_cmdline_user_args().size() > 0:
		return "user://dev_savegame%d.json" % n        # the test bots never touch a real player's saves
	return SAVE_PATH if n == 1 else "user://savegame%d.json" % n

func has_save(sl = 0):
	return FileAccess.file_exists(save_path(sl))

# round 20: the first slot whose run has been finished (0 = none): WATCH STORY needs one (the ending is replayed from its memories)
func finished_slot():
	for i in range(1, SLOTS + 1):
		var info = slot_info(i)
		if not info.is_empty() and info.get("free", false):
			return i
	return 0

func has_any_save():
	for i in range(1, SLOTS + 1):
		if has_save(i):
			return true
	return false

func delete_save(sl = 0):
	if has_save(sl):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path(sl)))

# what a slot card shows: {} when the slot is empty
func slot_info(sl):
	var d = read_save(sl)
	if d == null:
		return {}
	var l = d.get("lv", {})
	var n = int(d.get("sense", 0)) if int(d.get("sense", 0)) < 3 else 3
	for k in l:
		n += int(l[k])
	var secs = int(float(d.get("run", 0.0)))
	return {"fries": n, "time": "%02d:%02d" % [secs / 60, secs % 60], "free": bool(d.get("free", false)), "fish": d.get("fish", {}).size(), "diff": str(d.get("diff", "easy"))}

# the end of a run: the gull is on the roof next to its big brother and may keep playing from there (the save is marked "free")
func write_end_save(pos, yaw):
	return write_save(pos, yaw, true)

func write_save(pos, yaw, ended = false):
	if replay != "":
		return false                  # round 20: watching the story again never touches a save
	if ordinary_eaten and not ended:
		return false
	var d = {"v": 1, "sense": gull_sense_count, "tut": tutorial_done.keys(), "lv": lv.duplicate(), "rb": rainbow.duplicate(), "stars": star_got.keys(),
		"worn": worn.keys(), "eq": equipped.keys(), "mis": mischief_counts.duplicate(), "ach": achievements_done.keys(), "eaten": fries_eaten,
		"hunger": hunger_t, "run": run_time, "stats": stats.duplicate(), "phase": int(phase), "pos": [pos.x, pos.y, pos.z], "yaw": yaw,
		"seen": menu_seen.keys(), "quests": quests.duplicate(), "fish": fish_book.duplicate(true), "starn": star_total, "cine": cine_seen.keys(), "mem": memories.duplicate(true), "sky": sky_got.keys(), "clouds": clouds_got.keys(), "sight": sight_time, "tabl": tab_lesson,
		"free": free_play or ended, "diff": diff, "dchg": diff_changed, "hclock": hard_clock, "hlast": hard_last, "coach": coach_done.keys()}
	if ended:
		d["phase"] = int(Phase.STILL_HUNGRY) if special_count() >= FRY_TYPES.size() else (int(Phase.SPECIAL_HUNT) if gull_sense_count >= 3 else int(Phase.TUTORIAL))
	var f = FileAccess.open(save_path(), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(d))
	f.close()
	return true

func read_save(sl = 0):
	if not has_save(sl):
		return null
	var f = FileAccess.open(save_path(sl), FileAccess.READ)
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
	free_play = bool(d.get("free", false))
	if d.has("diff") and DP.has(str(d["diff"])):
		diff = str(d["diff"])
	elif OS.get_cmdline_user_args().size() == 0:
		diff = "easy"                    # a save from before the difficulties
	diff_changed = bool(d.get("dchg", false))
	hard_clock = float(d.get("hclock", 0.0))
	hard_last = float(d.get("hlast", -1.0))
	for k in d.get("coach", []):
		coach_done[k] = true
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
	var fb = d.get("fish", {})
	for k in fb:
		if FISH_SPECIES.has(k):
			fish_book[k] = {"n": int(fb[k].get("n", 1)), "kg": float(fb[k].get("kg", 0.0)), "cm": float(fb[k].get("cm", 0.0))}
	star_total = int(d.get("starn", 0))
	for k in d.get("sky", []):
		sky_got[k] = true
	for k in d.get("clouds", []):
		clouds_got[k] = true
	sight_time = float(d.get("sight", 0.0))
	tab_lesson = int(d.get("tabl", 0))
	for k in d.get("cine", []):
		cine_seen[k] = true
	var mm = d.get("mem", {})
	for k in mm:
		memories[k] = mm[k]
	if star_total > 0:
		cine_seen["drinks3"] = true            # a save from before the cinematic moments: do not replay what the player has long since lived
	if not fish_book.is_empty():
		cine_seen["fish"] = true
	var qs = d.get("quests", {})
	for k in qs:
		quests[k] = str(qs[k])
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
	if int(st.get("meteors", 0)) > 0:
		cine_seen["meteor"] = true
	if fry_total() >= FRY_CAP:
		cine_seen["all24"] = true
	for k in sky_got:                   # what the sky already gave has had its moment
		cine_seen[{"rainbow": "skybow", "star": "meteor"}.get(k, k)] = true
	for k in clouds_got:
		cine_seen[k] = true

	var p = d.get("pos", [-9.5, 6.0, -0.8])
	saved_pos = {"pos": Vector3(p[0], p[1], p[2]), "yaw": float(d.get("yaw", PI))}
