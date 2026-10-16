extends Node3D
# Main: assembles world + player + UI and orchestrates progression, the opening title + shot, Gull Sight (hold TAB),
# the Fry Codex (C), rarity tiers + star fries, the "where is the plain fry?" hints, the ending and the credits (docs/18, docs/20).

const WB = preload("res://scripts/world/world_builder.gd")
const PLAYER_SCRIPT = preload("res://scripts/player/gull_player.gd")
const HUD_SCRIPT = preload("res://scripts/ui/hud.gd")
const MENU_SCRIPT = preload("res://scripts/ui/menus.gd")
const SENSE_SCRIPT = preload("res://scripts/ui/gull_sense_ui.gd")
const FRY_SCRIPT = preload("res://scripts/fries/fry.gd")
const DAY_SCRIPT = preload("res://scripts/world/day_cycle.gd")
const SHOWCASE_SCRIPT = preload("res://scripts/ui/fry_showcase.gd")
const TITLE_SCRIPT = preload("res://scripts/ui/title_cards.gd")
const RIVAL_SCRIPT = preload("res://scripts/world/rival_gulls.gd")
const MENU_CAM_SCRIPT = preload("res://scripts/ui/menu_cam.gd")
const STORY_SCRIPT = preload("res://scripts/ui/story.gd")
const SCENES_SCRIPT = preload("res://scripts/ui/story_scenes.gd")

const VISION_TS = 0.3          # world speed while Gull Sight is held

# Item-get cards. Every NAMED fry gets one (with a NEW! tag the first time) so that the plain fry at the end
# reads as the odd one out: the only one that was given, and the only one with no ability.
const SHOW_TUTORIAL = [
	{"name": "CORNER TABLE FRY", "category": "COMMON FRY  -  FIRST", "carrier": "box", "source": "STOLEN FROM: THE OLD MAN",
		"desc": "Crisp, salty and slightly illegal.\nA strong start.", "ability_title": "UNLOCKING", "ability": "GULL SIGHT   1 / 3"},
	{"name": "SEASIDE PLATE FRY", "category": "COMMON FRY  -  SECOND", "carrier": "plate", "source": "STOLEN FROM: THE UMBRELLA LADY",
		"desc": "She only looks up when you think she won't.\nNoted.", "ability_title": "UNLOCKING", "ability": "GULL SIGHT   2 / 3"},
	{"name": "HOT HANDHELD FRY", "category": "COMMON FRY  -  THIRD", "carrier": "hand", "source": "STOLEN FROM: A MAN WITH A CARTON",
		"desc": "Still moving, still warm.\nSo are you.", "ability_title": "UNLOCKED", "ability": "GULL SIGHT   -   HOLD TAB"},
]
const TIER1_SOURCE = {"red": "STOLEN FROM: A BOARDWALK VENDOR", "blue": "STOLEN FROM: A PICNIC PARENT", "purple": "STOLEN FROM: A PIER WANDERER",
	"green": "STOLEN FROM: A VERY FAST KID", "pink": "STOLEN FROM: A BAKER", "orange": "STOLEN FROM: A BIRDWATCHER", "cyan": "STOLEN FROM: A LIGHTHOUSE KEEPER"}
const SPOT_NAMES = {"ferris": "THE FERRIS WHEEL", "lighthouse": "THE LIGHTHOUSE LAMP", "turbine": "A WIND TURBINE", "church": "THE CHURCH SPIRE",
	"crane_hook": "A CRANE HOOK", "containers": "A CONTAINER STACK", "buoy": "A LONELY BUOY", "islet": "THE ISLET", "lifeguard": "THE LIFEGUARD TOWER",
	"chimney": "A HILLTOP CHIMNEY", "mast": "A MARINA MAST", "kite": "A KITE (OF ALL THINGS)", "playground_top": "THE PLAYGROUND SLIDE",
	"windmill": "THE WINDMILL", "clock_tower": "THE CLOCK TOWER", "crane_hook2": "THE OTHER CRANE", "barn": "A BARN ROOF",
	"bar_shelf": "THE BAR SHELF", "cafe_table": "A CAFE TABLE", "market_stall": "THE SUPERMARKET STALL", "boat_deck": "A FISHING BOAT", "roof_laundry": "A LAUNDRY ROOF",
	"villa_bbq": "A BARBECUE", "villa_pool": "A SWIMMING POOL", "fry_sign": "THE FRY SHACK SIGN"}
const GOLD_SPOTS = ["lifeguard", "chimney", "playground_top", "barn", "containers", "buoy", "islet", "mast", "bar_shelf", "cafe_table", "market_stall", "boat_deck", "roof_laundry", "villa_bbq", "villa_pool", "fry_sign"]
const DIAMOND_SPOTS = ["ferris", "lighthouse", "turbine", "church", "crane_hook", "crane_hook2", "clock_tower", "kite", "windmill"]
# round 7: where the gold (tier 2) and diamond (tier 3) fry of every colour hangs. The more useful the colour, the nearer to the start (beach and boardwalk);
# the least useful ones sit at the edges of the map. The first free preferred spot wins, otherwise any spot of the right height.
const PREF_GOLD = {"red": ["lifeguard"], "orange": ["cafe_table", "market_stall"], "green": ["bar_shelf", "fry_sign"], "blue": ["playground_top", "boat_deck"],
	"cyan": ["roof_laundry", "villa_bbq", "villa_pool"], "purple": ["chimney", "mast", "containers"], "pink": ["barn", "islet", "buoy"]}
const PREF_DIAMOND = {"red": ["ferris"], "orange": ["clock_tower", "church"], "green": ["crane_hook", "kite"], "blue": ["crane_hook2", "lighthouse"],
	"cyan": ["turbine"], "purple": ["windmill"], "pink": ["lighthouse", "turbine"]}
# ROUND 10: the way to the plain fry is no longer spelled out. Two faint whispers by the clock and one by the count, none of them pointing anywhere;
# the rest (a thread of steam when you pass near, a dim glow at a few metres) is for the player to notice and understand alone.
const HUNGER_STEPS = [
	[180.0, "something is still missing."],
	[420.0, "...what was it, again?"],
	[780.0, "i was going to get some fries. wasn't i."],
]
const HUNGER_COUNT_STEPS = [
	[18, "stronger. faster. still hungry."],
	[22, "where does this path end?"],
]

var player
var hud
var menus
var sense
var showcase
var title
var world
var day
var ordinary
var elder
var star_queue = []
var star_active = []
var star_timer = 0.0
var first_star = true
var codex_open = false
var codex_yaw = 0.0
var codex_pitch = 0.3
var intro_active = false
var intro_t = 0.0
var intro_clock = 0.0
var intro_phase = "bro"
var dialogue
var story
var scenes
var bro
var intro_dropped = false
var autotest = false
var last_yell = -9.0
var play_t = 0.0
var used_w = false
var tab_hint_t = -1.0
var perf_last = 0
var hunger_step = 0
var hunger_cstep = 0
var watch_t = 0.0
var elder_waving = false
var rivals
var rest
var loaded_run = false
var save_sig = ""
var save_t = 0.0
var steam_t = 0.0
var ending_started = false
var rb_t = 0.0
var rb_last = {}
var rb_n = 0
var rb_holders = []
var meteors
var cine_queue = []
var cine_wait = 0.0
var bro_prompt = ""             # round 16: "E - TALK" next to the big brother in free play
var yk = null                    # round 16: the four-panel strip layer (ui/yonkoma.gd)
var reel = null                  # round 16: records a few frames of every first-time moment (the ending plays them back)

func _ready():
	GS.reset()
	Engine.time_scale = 1.0
	if not GS.web:
		var ico = load("res://icon.png")            # round 16: the game's own icon (the gull with a fry) on the window and the task bar
		if ico != null:
			DisplayServer.set_icon(ico.get_image())
	get_tree().paused = false
	player = CharacterBody3D.new()
	player.set_script(PLAYER_SCRIPT)
	player.name = "PlayerGull"
	player.position = WB.SPAWN_POS
	add_child(player)
	player.mode = 1
	var wb = WB.new()
	var t_build = Time.get_ticks_msec()
	world = wb.build(self, player)
	print("[PERF] the island was built in %d ms" % (Time.get_ticks_msec() - t_build))     # (the browser build builds it in one go: the first frame can take a long time there)
	wb.tick_report()
	preload("res://scripts/art/s7_profile.gd").report()
	if "--s7-profile" in OS.get_cmdline_user_args():RenderingServer.frame_post_draw.connect(_s7_first_frame,CONNECT_ONE_SHOT)
	player.ground_h = world["ground_h"]
	player.trees = world.get("trees", [])
	player.air_zones = world["air_zones"]
	player.respawn_point = WB.SPAWN_POS + Vector3(0, 6, 0)
	ordinary = world["ordinary"]
	elder = world["npcs"][0]
	day = Node.new()
	day.set_script(DAY_SCRIPT)
	day.sun = world["sun"]
	day.env = world["env"]
	day.sky = world["sky_mat"]
	day.win_mat = world["window_mat"]
	day.lamp_mat = world["lamp_mat"]
	day.beam_mat = world.get("beam_mat")
	day.cloud_mat = world.get("cloud_mat")
	day.storm_mat = world.get("storm_mat")
	day.sun_disc = world.get("sun_disc")
	day.moon_disc = world.get("moon_disc")
	day.player = player
	day.atmosphere = world.get("cover_atmosphere")
	add_child(day)
	hud = CanvasLayer.new()
	hud.set_script(HUD_SCRIPT)
	hud.player = player
	add_child(hud)
	hud.visible = false
	sense = CanvasLayer.new()
	sense.set_script(SENSE_SCRIPT)
	sense.player = player
	add_child(sense)
	showcase = CanvasLayer.new()
	showcase.set_script(SHOWCASE_SCRIPT)
	add_child(showcase)
	title = CanvasLayer.new()
	title.set_script(TITLE_SCRIPT)
	add_child(title)
	dialogue = CanvasLayer.new()
	dialogue.set_script(load("res://scripts/ui/dialogue_ui.gd"))
	add_child(dialogue)
	story = CanvasLayer.new()
	story.set_script(STORY_SCRIPT)
	add_child(story)
	yk = CanvasLayer.new()
	yk.set_script(load("res://scripts/ui/yonkoma.gd"))
	add_child(yk)
	scenes = Node.new()
	scenes.set_script(SCENES_SCRIPT)
	scenes.main = self
	add_child(scenes)
	bro = Node3D.new()
	bro.set_script(load("res://scripts/world/big_bro.gd"))
	add_child(bro)
	bro.main = self
	bro.setup(player, WB.BRO_POS, Vector3(WB.SPAWN_POS.x, 5.4, WB.SPAWN_POS.z))
	title.restart_requested.connect(func(): _reload(GS.replay == "", GS.slot if GS.replay == "" else 0))        # round 16: after the credits, HOLD E = keep playing (free flight in the same save); round 20: after WATCH STORY, back to the menu
	title.menu_requested.connect(func(): _reload(false))
	menus = CanvasLayer.new()
	menus.set_script(MENU_SCRIPT)
	add_child(menus)
	menus.start_pressed.connect(_on_start_pressed)
	menus.continue_pressed.connect(_on_continue_pressed)
	menus.story_pressed.connect(_on_story_pressed)
	menus.save_pressed.connect(func(): menus.note_saved(save_now()))
	rivals = Node.new()
	rivals.set_script(RIVAL_SCRIPT)
	rivals.player = player
	rivals.spots = world.get("fish_spots", [])
	add_child(rivals)
	var gov = Node.new()
	gov.set_script(load("res://scripts/systems/perf_governor.gd"))
	gov.main = self
	add_child(gov)
	rest = Node.new()
	rest.set_script(load("res://scripts/world/rest_events.gd"))
	rest.player = player
	add_child(rest)
	meteors = Node.new()
	meteors.set_script(load("res://scripts/world/meteors.gd"))
	meteors.player = player
	meteors.main = self
	meteors.day = day
	add_child(meteors)
	var mcam = Node.new()
	mcam.set_script(MENU_CAM_SCRIPT)
	mcam.player = player
	mcam.menus = menus
	add_child(mcam)
	menus.restart_pressed.connect(func(): _reload(true))
	menus.unstick_pressed.connect(_unstick)
	menus.quit_to_menu_pressed.connect(func(): _reload(false))
	menus.resume_pressed.connect(func():
		_close_sense()
		_close_codex())
	player.escaped.connect(_on_escaped)
	player.ate_ordinary.connect(_on_ate_ordinary)
	GS.gull_sense_complete.connect(_reveal_specials)
	GS.star_started.connect(func():
		if GS.cine_seen.has("drinks3"):
			Sfx.set_star(true)          # (the first time, the cinematic moment hands over to the STARLIGHT music itself)
			Sfx.play("star_riser", -9.0)
		queue_cine("drinks3"))
	GS.fish_caught.connect(func(info): queue_cine("fish", info))
	GS.buff_started.connect(func(kind): queue_cine("drink_" + kind))
	GS.sky_caught.connect(_sky_reward)
	GS.fish_started.connect(func(): GS.comic.emit("fishtime", "THE SEA GAVE YOU A RIDE. SPACE ON THE WATER = LAUNCH.", {"tier": 0}))
	GS.fish_added.connect(func(streak, _r):
		if streak >= 2:
			hud._show_center("FISH  x%d" % streak, 0.9, 38)
		if streak == 3:
			GS.comic.emit("fishcombo", "THREE IN A ROW. THE FISH ARE ORGANISING.", {"tier": 0}))
	GS.memory_added.connect(_on_memory_added)
	reel = Node.new()
	reel.set_script(load("res://scripts/systems/memory_reel.gd"))
	add_child(reel)
	GS.star_ended.connect(func(): Sfx.set_star(false))
	GS.still_hungry_started.connect(_begin_star_phase)
	player.update_camera(0.0, true)
	Sfx.set_music_level(0)
	var args = OS.get_cmdline_user_args()
	if args.size() > 0:                              # dev/test run: never steal the keyboard focus or the mouse from the person at the desk
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	for a in args:
		if a.begins_with("--shot="):
			var path = a.substr(7)
			get_tree().create_timer(2.5, true, false, true).timeout.connect(func():
				get_viewport().get_texture().get_image().save_png(path)
				get_tree().quit())
	var dev_modes = ["--autotest", "--tour", "--intro", "--wary", "--ui", "--cam", "--systems", "--cone", "--audio", "--prism", "--star", "--mischief",
		"--yellow", "--fuzz", "--early", "--restart", "--soak", "--census", "--showcase", "--focus", "--flee", "--vision", "--gauge", "--comics", "--title", "--credits", "--one",
		"--save", "--fish", "--rival", "--volley", "--wear", "--ending", "--hud", "--tiers", "--hunger", "--world", "--hazards", "--rhythm", "--land", "--rainbow", "--topdown", "--one", "--places", "--rest", "--codex", "--drink", "--smash", "--stand", "--sky", "--census2", "--reach", "--bank", "--cams", "--r7", "--r7b", "--r8", "--r8b", "--r8c", "--r8t", "--r8e", "--r8m", "--r9speed", "--shotcheck", "--r9tab", "--r9trail", "--r9sky", "--r9cine", "--r9open", "--r9end", "--r9rb", "--r9quiet", "--r10beats", "--r10npc", "--r10misc", "--r10look", "--r12", "--r12audio", "--r13reload", "--r15a", "--r15b", "--r15n", "--r15g", "--r15u", "--r16s", "--r16a", "--r16b", "--r16c", "--r16d", "--r16e", "--r16f", "--r16g", "--r16h", "--r18a", "--r18b", "--r18v", "--r18m", "--r18n", "--r18h", "--r18f", "--r18w", "--r18s"]
	var is_dev = false
	for m in dev_modes:
		if m in args:
			is_dev = true
	if is_dev:
		autotest = true
		autotest_no_cine = true          # the bots must not be frozen by the cinematic moments (the --r8 modes call them by hand)
		GS.no_focus_pause = true
		showcase.fast = true
		GS.skip_intro = not ("--intro" in args)
		if "--warm" in args:
			await _web_warm_up()                  # (dev: the browser's preparation of the graphics, before a bot flies)
		_start_game()
		var t = Node.new()
		t.set_script(load("res://scripts/autotest.gd"))
		t.main = self
		add_child(t)
	elif "--r20ending" in args or "--r20opening" in args:
		# dev (round 20): WATCH STORY straight from the start (record it with --write-movie; the run quits 25 s into the credits)
		autotest = false
		GS.no_focus_pause = true
		get_tree().paused = true
		Engine.max_fps = 30
		menus.show_main()
		await get_tree().create_timer(0.5, true, false, true).timeout
		title.finished.connect(func(): get_tree().create_timer(25.0, true, false, true).timeout.connect(func(): get_tree().quit()))
		if "--r20opening" in args:
			# the bot holds E at the "HOLD E TO FLY" prompt and the run quits when the opening is over (it would go back to the menu)
			get_tree().create_timer(0.1, true, false, true).timeout.connect(func():
				while true:
					await get_tree().process_frame
					if GS.replay == "":
						get_tree().quit()
						return
					if story.hold.get("on", false):
						Input.action_press("interact")
					else:
						Input.action_release("interact"))
		_on_story_pressed("ending" if "--r20ending" in args else "opening")
	elif "--film" in args:
		# dev: the walkthrough video (run with --write-movie): the real menu, opening and ending, the bot flies in between
		autotest = false
		GS.no_focus_pause = true
		get_tree().paused = true
		Engine.max_fps = 30
		menus.show_main()
		Sfx.play_theme("theme_open", true)
		var t3 = Node.new()
		t3.set_script(load("res://scripts/autotest.gd"))
		t3.main = self
		add_child(t3)
	elif "--menu" in args or "--r17" in args:
		# dev: the real START path (menu -> opening title cards -> cafe shot), driven by the bot
		autotest = false
		GS.no_focus_pause = true
		get_tree().paused = true
		Engine.max_fps = 30
		menus.show_main()
		Sfx.play_theme("theme_open", true)
		var t2 = Node.new()
		t2.set_script(load("res://scripts/autotest.gd"))
		t2.main = self
		add_child(t2)
	elif GS.skip_menu:
		GS.skip_menu = false
		GS.skip_intro = true
		if GS.autoload_slot > 0:
			GS.slot = GS.autoload_slot
			GS.autoload_slot = 0
			var d0 = GS.read_save()
			if d0 != null:
				_restore_run(d0)
		await _web_warm_up()
		_start_game()
	else:
		await _web_warm_up()
		get_tree().paused = true
		Engine.max_fps = 30
		menus.show_main()
		Sfx.play_theme("theme_open", true)

# The browser compiles a shader the first time it sees something and the whole page waits for it: 2-5 s every time the gull flew somewhere new, 20-30 s for the
# very first picture. So, behind the "preparing" card of the page, the camera is sent once over every part of the island (and a burst of sparks is shown) before the
# title appears: the waiting happens once, at the start, and is explained, instead of freezes in the middle of a flight. Only in the browser build.
const WARM_VIEWS = [
	[Vector3(-9.5, 8.0, -9.0), Vector3(-9.5, 3.0, 4.0), 70.0], [Vector3(20.0, 6.0, 40.0), Vector3(30.0, 1.0, 14.0), 70.0],
	[Vector3(2.0, 8.0, 98.0), Vector3(2.0, 12.0, 55.0), 65.0], [Vector3(-50.0, 30.0, 70.0), Vector3(-102.0, 20.0, 40.0), 65.0],
	[Vector3(0.0, 24.0, -6.0), Vector3(0.0, 10.0, -50.0), 70.0], [Vector3(-45.0, 14.0, 20.0), Vector3(-58.0, 0.0, -10.0), 70.0],
	[Vector3(55.0, 28.0, 12.0), Vector3(85.0, 5.0, -25.0), 70.0], [Vector3(10.0, 110.0, 150.0), Vector3(0.0, 0.0, 10.0), 70.0],
	[Vector3(-30.0, 5.0, 28.0), Vector3(-46.0, 1.0, 16.0), 70.0], [Vector3(0.0, 14.0, 96.0), Vector3(0.0, 4.0, 118.0), 70.0],
	[Vector3(-4.0, 40.0, 30.0), Vector3(-4.0, 75.0, -40.0), 70.0], [Vector3(40.0, 3.0, 95.0), Vector3(80.0, 2.0, 130.0), 70.0]]

func _web_warm_up():
	if not GS.web or loaded_run:
		return
	var was_locked = player.input_locked
	player.input_locked = true
	var n = WARM_VIEWS.size()
	var tw0 = Time.get_ticks_msec()
	var times = []
	for i in n:
		var tv0 = Time.get_ticks_msec()
		var v = WARM_VIEWS[i]
		JavaScriptBridge.eval("window.JSF && JSF.warm && JSF.warm(%d, %d)" % [i + 1, n])
		player.set_override(Transform3D(Basis.IDENTITY, v[0]).looking_at(v[1], Vector3.UP), v[2], 1.0, 200.0)
		if i == 1 or i == 7:
			_burst(v[1] + Vector3(0, 2.0, 0), Color(1.0, 0.9, 0.6), 30, 4.0)
		var props = []
		if i == 2 or i == 8:
			# the things the gull holds in its beak in the film moments (sun, cloud, falling star, rainbow): shown once, in front of the camera
			var ahead = v[0] + (v[1] - v[0]).normalized() * 2.5
			for k in ["sun", "cloud", "meteor", "skybow"]:
				var pr = scenes._make_prop(k)
				add_child(pr)
				pr.global_position = ahead + Vector3(0.0, 0.2 * props.size(), 0.0)
				props.append(pr)
		await get_tree().process_frame
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		for pr in props:
			pr.queue_free()
		times.append(Time.get_ticks_msec() - tv0)
	player.set_override(Transform3D.IDENTITY, 60.0, 0.0, 200.0)
	player.input_locked = was_locked
	print("[PERF] graphics prepared in %d ms (per view: %s)" % [Time.get_ticks_msec() - tw0, str(times)])
	JavaScriptBridge.eval("window.JSF && JSF.gameReady && JSF.gameReady()")

func _reload(skip, slot = 0):
	GS.replay = ""
	GS.skip_menu = skip
	GS.autoload_slot = slot
	Engine.time_scale = 1.0
	get_tree().paused = false
	Sfx.muffle(false, 0.01)
	# the browser build: a second island built on top of the first one fragments the wasm heap (which only ever grows): the classic way a long session ends in
	# a crash. A page reload gives a clean heap; the 0.8 s lets a save that was just written reach the browser's storage first.
	if GS.web and not autotest:
		var ok = JavaScriptBridge.eval("(function(){ try { sessionStorage.setItem('jsf_skip_menu', '%s'); sessionStorage.setItem('jsf_slot', '%d'); sessionStorage.setItem('jsf_diff', '%s'); setTimeout(function(){ location.reload(); }, 800); return 1; } catch (e) { return 0; } })()" % [("1" if skip else "0"), slot, GS.diff])
		if ok != null and float(ok) > 0.5:
			return
	get_tree().reload_current_scene()

# START button: the opening title cards first (only on a fresh launch), then the game
func _on_continue_pressed():
	var d = GS.read_save()
	if d == null:
		return
	_restore_run(d)
	_start_game()

# round 20: WATCH STORY. The opening plays exactly as it does at the start of a run. The ending plays from the memories of the first finished save (the same gull, the same
# things it wore and remembered); nothing is saved meanwhile, and the end of either goes back to the menu.
func _on_story_pressed(which):
	if which == "opening":
		GS.replay = "opening"
		get_tree().paused = false
		menus.begin_game()
		scenes.opening()
		return
	var sl = GS.finished_slot()
	var d = GS.read_save(sl) if sl > 0 else null
	if d == null:
		menus.show_main()
		return
	GS.slot = sl
	GS.replay = "ending"
	_restore_run(d)
	GS.cine_seen["free_intro"] = true     # (the big brother's talk after the end must not cut in)
	_start_game()
	await get_tree().create_timer(0.6, true, false, true).timeout
	GS.ordinary_eaten = true
	GS.phase = GS.Phase.ENDED
	Sfx.ending = true
	Sfx.fade_music(4.0)
	elder.look_at_pos(player.global_position, 8.0)
	elder.rig.set_mode("idle")
	var f = scenes._new_plain_fry(player.global_position + Vector3(0, 0.3, 0))
	f.attach(player.beak_socket)
	scenes.ending(f)

func _on_start_pressed():
	if GS.skip_intro:
		_start_game()
		return
	get_tree().paused = false
	menus.begin_game()
	scenes.opening()

# the last beat of the opening (HOLD E) is over: the page frame opens up and the gull is yours
func start_after_opening():
	if GS.replay == "opening":
		if OS.get_cmdline_user_args().size() > 0:
			GS.replay = ""                # (dev recording: the bot above quits the run)
			return
		_reload(false)                    # round 20: WATCH STORY: the opening is over, back to the menu (nothing was changed or saved)
		return
	GS.skip_intro = true
	story.cam = null
	story.frame_out(0.9)
	_start_game()
	get_tree().create_timer(1.0, true, false, true).timeout.connect(story.finish)

func _start_game():
	if not loaded_run and not autotest and reel != null:
		reel.clear_slot()                 # round 16: a new run in this slot: the old memories' pictures go
	get_tree().paused = false
	Engine.max_fps = 60
	menus.begin_game()
	player.active = true
	if OS.get_cmdline_user_args().size() == 0:       # dev/test runs (any user arg) never grab the real mouse
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Sfx.stop_theme(2.5)
	Sfx.world_zone = _zone_of(player.global_position)
	Sfx.start_music()
	if GS.skip_intro:
		_finish_intro()
	else:
		_begin_intro()

# ------------------------------------------------------------------ opening: the big brother, then the old man's table
func _begin_intro():
	intro_active = true
	intro_t = 0.0
	intro_clock = 0.0
	intro_phase = "bro"
	intro_dropped = false
	player.input_locked = true
	hud.visible = false
	ordinary.visible = false
	player.yaw = atan2(-1.0, 0.0)          # the gull looks at its big brother (east)
	player.aim_yaw = player.yaw
	player.mode = 1
	_bro_opening()

func _face_first_fry():
	# the first fry must be impossible to miss: start the run looking straight down at the café table
	var f = world["fries"]["TUTORIAL_01"]
	var v = (f.global_position + Vector3(0, 0.4, 0)) - player.global_position
	player.yaw = atan2(-v.x, -v.z)
	player.aim_yaw = player.yaw
	player.pitch = clamp(asin(clamp(v.normalized().y, -1.0, 1.0)), deg_to_rad(-40.0), deg_to_rad(25.0))
	player.aim_pitch = player.pitch
	player.cam_yaw = player.yaw
	player.update_camera(0.0, true)

func _finish_intro():
	intro_active = false
	dialogue.skipping = true
	dialogue.hide_all()
	if not loaded_run:
		_face_first_fry()
	# the plain fry has been lying on the table since the old man dropped it in the opening: no glow, no prompt, no reaction until the three starter fries are in
	ordinary.visible = not GS.free_play          # (round 16: in free play it has been eaten)
	ordinary.global_position = WB.ORDINARY_POS
	ordinary.rotation = Vector3.ZERO
	elder.rig.override_arm_r = null
	player.set_override(Transform3D.IDENTITY, 60.0, 0.0, 1.5)
	player.cine_cam.current = false
	player.cam.current = true
	player.input_locked = false
	hud.visible = true
	GS.skip_intro = false
	play_t = 0.0
	get_tree().create_timer(0.3).timeout.connect(func(): dialogue.skipping = false)

# the first scene of the game: the big brother tells the little gull he has everything and is still hungry
func _bro_opening():
	dialogue.skipping = false
	await get_tree().create_timer(1.1, true, false, true).timeout
	if not intro_active:
		return
	await dialogue.say("BIG BRO", "I got the chain.", 1.0)
	if not intro_active:
		return
	await dialogue.say("BIG BRO", "The shades. The hat. The coat.", 1.1)
	if not intro_active:
		return
	await dialogue.say("BIG BRO", "I got everything.", 1.3)
	if not intro_active:
		return
	await get_tree().create_timer(0.6, true, false, true).timeout
	await dialogue.say("BIG BRO", "...and I'm still hungry.", 1.6)
	if not intro_active:
		return
	await get_tree().create_timer(0.5, true, false, true).timeout
	await dialogue.say("BIG BRO", "So. What do YOU want?", 1.4)
	if not intro_active:
		return
	# the little gull has no answer: it looks away at the sea... and then at the cafe below
	var t0 = GS.msec()
	var y0 = player.yaw
	var y1 = atan2(0.2, -1.0)
	while (GS.msec() - t0) < 2800 and intro_active:
		var u = clamp((GS.msec() - t0) / 1800.0, 0.0, 1.0)
		player.yaw = lerp_angle(y0, y1, u * u * (3.0 - 2.0 * u))
		player.aim_yaw = player.yaw
		await get_tree().process_frame
	if not intro_active:
		return
	intro_phase = "cafe"
	intro_t = 0.0

func _intro_step(delta):
	intro_clock += delta
	if intro_phase == "bro":
		var u = clamp(intro_clock / 16.0, 0.0, 1.0)
		var cam_pos = Vector3(-10.4, 6.9, 5.4).lerp(Vector3(-9.2, 6.5, 4.4), u)
		var xf = Transform3D(Basis.IDENTITY, cam_pos).looking_at(Vector3(-7.9, 5.45, -1.1), Vector3.UP)
		player.set_override(xf, 38.0, 1.0, 4.0)
		return
	intro_t += delta
	var tgt = Vector3(-8.3, 1.25, 3.5)
	var cam_pos2 = Vector3(-5.4 + sin(intro_t * 0.2) * 0.3, 1.3, 7.2)
	var xf2 = Transform3D(Basis.IDENTITY, cam_pos2).looking_at(tgt, Vector3.UP)
	var goal = 1.0 if intro_t < 4.4 else 0.0
	player.set_override(xf2, 36.0, goal, 2.5 if goal > 0.5 else 0.7)
	if intro_t > 0.4 and intro_t < 2.2:
		elder.rig.override_arm_r = -2.1
		elder.rig.override_arm_r_z = -0.15
		ordinary.visible = true
		ordinary.global_position = elder.rig.hand_r.global_position + Vector3(0, 0.0, 0.05)
		ordinary.rotation = Vector3(0, 0.6, 0)
	elif intro_t >= 2.2 and not intro_dropped:
		intro_dropped = true
		elder.rig.override_arm_r = null
		ordinary.rotation = Vector3.ZERO
		var tw = create_tween()
		tw.tween_property(ordinary, "global_position", WB.ORDINARY_POS + Vector3(0, 0.04, 0), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(ordinary, "global_position", WB.ORDINARY_POS + Vector3(0, 0.0, 0), 0.12)
		elder.look_at_pos(elder.global_position + Vector3(0, 0, 8), 3.0)
		get_tree().create_timer(0.5).timeout.connect(func(): Sfx.play("land", -14.0, 1.6))
	if intro_t > 5.2:
		_finish_intro()

# ------------------------------------------------------------------ save / continue
func _sig():
	return "%d|%d|%d|%d|%d|%d|%d" % [GS.gull_sense_count, GS.level_sum(), GS.star_count(), GS.worn.size(), int(GS.phase), GS.stats["fish"], GS.stats.get("rainbow", 0)]

func save_now():
	if player == null or GS.ordinary_eaten or not player.active:
		return false
	var pos = player.global_position
	return GS.write_save(pos, player.yaw)

func _autosave_tick(rdt):
	save_t += rdt
	if save_t < 2.0:
		return
	save_t = 0.0
	var sg = _sig()
	if sg != save_sig and player.snatch.state == "idle" and not showcase.active and player.mode != 2:
		save_sig = sg
		save_now()

# put a saved run back into the (fresh) world
func _restore_run(d):
	loaded_run = true
	GS.apply_save(d)
	GS.skip_intro = true
	for m in get_tree().get_nodes_in_group("mischief"):
		if is_instance_valid(m) and m.has_method("is_wearable") and m.is_wearable() and (GS.worn.has(m.kind) or GS.mischief_counts.get(m.kind, 0) > 0):
			m.consumed = true
			m.taken = true
			m.queue_free()
	for id in GS.tutorial_done:
		var f = world["fries"].get(id, null)
		if f != null:
			f.consume()
			f.npc.rig.holding = false
	if GS.gull_sense_count >= 3:
		for k in world["fries"]:
			var sf = world["fries"][k]
			if is_instance_valid(sf) and sf.is_special():
				if GS.lv[sf.utype] >= 1:
					sf.consume()
					sf.npc.rig.holding = false
				else:
					sf.revealed = true
					sf.visible = true
					sf.halo_alpha = sf.halo_base
					sf._apply_halo()
		hud.slots_visible = true
		hud.objective_title.text = ""
		GS.phase = GS.Phase.SPECIAL_HUNT if GS.phase == GS.Phase.TUTORIAL else GS.phase
		Sfx.set_music_level(1)
		if GS.phase == GS.Phase.TUTORIAL:
			GS.phase = GS.Phase.SPECIAL_HUNT
	else:
		hud.objective_title.text = ""
	if GS.phase == GS.Phase.STILL_HUNGRY:
		_begin_star_phase()
		first_star = GS.star_count() == 0
		Sfx.set_music_level(2)
	player.gull.apply_growth()
	player.gull.restore_worn()
	player.stamina = GS.stamina_max()
	var sp = GS.saved_pos
	if sp != null:
		var pos = sp["pos"]
		if WB.Terrain.H(pos.x, pos.z) < -0.4:
			pos = WB.SPAWN_POS + Vector3(0, 6, 0)
		player.global_position = pos
		player.yaw = sp["yaw"]
		player.aim_yaw = player.yaw
		player.pitch = 0.0
		player.aim_pitch = 0.0
		player.cam_yaw = player.yaw
		player.mode = 0
		player.speed = 5.0
		player.velocity = Vector3.ZERO
		player.update_camera(0.0, true)
	if GS.tab_lesson == 0 and GS.fry_total() >= 10:
		GS.tab_lesson = 2
	day.t = day.compute_target()
	hud.hint_shown = {"e": true, "e2": true, "shift": true, "rest": true, "tab": true, "yell": true, "roll": true}
	tab_hint_t = 0.0
	hunger_step = 0
	while hunger_step < HUNGER_STEPS.size() and GS.hunger_t >= HUNGER_STEPS[hunger_step][0]:
		hunger_step += 1
	hunger_cstep = 0
	while hunger_cstep < HUNGER_COUNT_STEPS.size() and GS.fry_total() >= HUNGER_COUNT_STEPS[hunger_cstep][0]:
		hunger_cstep += 1
	GS.progress_changed.emit(GS.progress_value(), GS.TOTAL_BASE)
	save_sig = _sig()
	if GS.free_play:
		_free_play_start()

# round 19: UNSTICK (the pause menu). Whatever has gone wrong (a rhythm that never ended, locked input, a stuck slow motion, a gull wedged in a wall), this puts the gull in the AIR above
# the start (not on the roof: that would start the big brother's talk), clears every state and every buff, and keeps everything that was collected (fries, codex, fish book, quests).
func _unstick():
	var sn = player.snatch
	if sn.carry_fry != null and is_instance_valid(sn.carry_fry):
		sn.drop_carry()
	sn.carry_fry = null
	sn._unlock()
	sn.seq = null
	sn.lock_fry = null
	sn.state = "idle"
	sn.cine = {}
	sn.letterbox = 0.0
	sn.focus_owned = false
	sn.snatch_cd = 1.0
	sn.presses.clear()
	sn._clear_fish_lock()
	Engine.time_scale = 1.0
	Sfx.muffle(false, 0.2)
	player.input_locked = false
	player.scripted_move = false
	player.set_override(Transform3D.IDENTITY, 60.0, 0.0, 6.0)
	player.gull.head_lunge = 0.0
	_close_sense()
	_close_codex()
	GS.vision_tired = false
	GS.sense_active = false
	GS.set_drink("")
	GS.end_star()
	GS.fish_t = 0.0
	GS.fish_streak = 0
	GS.fish_streak_t = 0.0
	GS.cutscene = false
	cine_queue.clear()
	if scenes != null:
		scenes.cine_busy = false
		scenes.beat_busy = false
	hud.quiet_busy = false
	hud.quiet_bar = 0.0
	hud.ui_root.modulate.a = 1.0
	player.launch_t = 0.0
	player.on_water = false
	player.tumble_t = 0.0
	player.perch_high = false
	player.mode = 0
	player.knock = Vector3.ZERO
	player.vert_boost = 0.0
	player.velocity = Vector3.ZERO
	player.global_position = WB.SPAWN_POS + Vector3(0, 11, 0)
	player.yaw = atan2(-1.0, 0.0) + PI
	player.aim_yaw = player.yaw
	player.cam_yaw = player.yaw
	player.pitch = 0.05
	player.aim_pitch = 0.05
	player.speed = 9.0
	player.stamina = GS.stamina_max()
	player.update_camera(0.0, true)
	player.show_toast("BACK AT THE START", 1.4)
	Sfx.play("whoosh", -10.0, 0.9)

# round 16: the end of a run is not the end of the game. The plain fry has been eaten (it stays eaten); everything else is still out there: the fries that are missing, the
# fish, the nine suns, the achievements. The gull wakes up on the big brother's roof, and he has something to say about it.
func _free_play_start():
	ordinary.consumed = true
	ordinary.available = false
	ordinary.visible = false
	ordinary.remove_from_group("fries")
	GS.ach_unlock("freeplay")
	GS.comic.emit("free_play", "THE FRY IS GONE. THE SKY IS NOT.", {"tier": 0})
	var land = WB.BRO_POS + Vector3(-3.8, 0.0, 0.0)
	player.global_position = Vector3(land.x, WB.SPAWN_POS.y + 0.2, land.z)
	player.yaw = atan2(-1.0, 0.0)
	player.aim_yaw = player.yaw
	player.cam_yaw = player.yaw
	player.mode = 1
	player.perch_high = true
	player.velocity = Vector3.ZERO
	player.speed = 0.0
	player.update_camera(0.0, true)
	if not autotest:
		get_tree().create_timer(1.6, true, false, true).timeout.connect(func():
			if not GS.cine_seen.has("free_intro") and scenes != null and not scenes.cine_busy:
				GS.cine_seen["free_intro"] = true
				scenes.bro_chat("free_intro"))

# ------------------------------------------------------------------ the cinematic moments (story_scenes.gd `cinema`): queued, then shown when the gull is free
func queue_cine(id, extra = {}):
	if GS.cine_seen.has(id) or autotest_no_cine or ending_started or GS.ordinary_eaten:
		return
	for e in cine_queue:
		if e[0] == id:
			return
	cine_queue.append([id, extra])
	cine_wait = 0.9

func _cine_tick(rdt):
	if cine_queue.is_empty() or scenes.cine_busy or scenes.beat_busy:
		return
	var sn = player.snatch
	if sn.state != "idle" or sn.lock_fry != null or sn.carry_fry != null or showcase.active or codex_open or intro_active or player.mode == 2 or ending_started:
		return
	cine_wait -= rdt
	if cine_wait > 0.0:
		return
	if GS.msec() - scenes.cine_done_at < 4000:      # a breather between two moments
		return
	var e = cine_queue.pop_front()
	if GS.cine_seen.has(e[0]):
		return
	if e[0].begins_with("drink_"):
		# the very first sip of one kind: a small moment of its own, unless the third drink just made STARLIGHT (that one is bigger)
		var star_next = false
		for q in cine_queue:
			if q[0] == "drinks3":
				star_next = true
		if star_next or GS.star_t > 0.0:
			GS.cine_seen[e[0]] = true
			return
	GS.cine_seen[e[0]] = true
	if scenes.has_beat(e[0]):
		scenes.beat_moment(e[0], e[1])       # a beat: 4-7 s of comic, the gull keeps flying
		return
	scenes.cinema(e[0], e[1])

var autotest_no_cine = false

# the rainbow quest item sits on the arch at the point nearest to the gull (every frame: the gull is fast)
func _bow_tick():
	var it = quest_items.get("skybow", null)
	if it == null or not is_instance_valid(it) or it.taken:
		return
	var rp = get_tree().get_first_node_in_group("rainbow_pair")
	if rp == null:
		return
	it.global_position = rp.nearest(player.global_position)
	it.visible = rp.fade > 0.45 and not rp.taken

# where the camera of the rainbow cinematic stands: the whole arch from the side
func skybow_focus():
	var rp = get_tree().get_first_node_in_group("rainbow_pair")
	if rp == null:
		var gp = player.global_position
		return {"pos": gp + Vector3(0, 6.0, 30.0), "look": gp + Vector3(0, 6.0, 0.0)}
	return rp.wide_view(player.global_position)

# ------------------------------------------------------------------ per-frame
func _perf_log():
	# one line every 10 s into godot.log (user://logs) - makes "it froze after a while" reports diagnosable
	var now = GS.msec()
	if now - perf_last < 10000:
		return
	perf_last = now
	print("[PERF] t=%ds fps=%d proc=%.1fms phys=%.1fms obj=%d nodes=%d orphans=%d mem=%.0fMB vram=%.0fMB draws=%d ts=%.2f state=%s" % [
		now / 1000, Performance.get_monitor(Performance.TIME_FPS), Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, Performance.get_monitor(Performance.OBJECT_COUNT),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Engine.time_scale, player.snatch.state if player != null else "-"])

func _process(delta):
	_perf_log()
	GS.cutscene = intro_active or scenes.cine_busy or ending_started or story.active
	if intro_active:
		_intro_step(delta)
		return
	if codex_open:
		# the gull sits on the left half of the screen (the right half is the picture book)
		var c = player.global_position + Vector3(0, 0.45, 0)
		var dir = Vector3(sin(codex_yaw) * cos(codex_pitch), sin(codex_pitch), cos(codex_yaw) * cos(codex_pitch))
		var right = Vector3(dir.z, 0.0, -dir.x).normalized()
		var shift = right * 1.35
		var xf = Transform3D(Basis.IDENTITY, c + dir * 3.1 + shift + Vector3(0, -0.15, 0)).looking_at(c + shift + Vector3(0, -0.62, 0), Vector3.UP)
		player.set_override(xf, 46.0, 1.0, 3.0)
	if GS.sense_active:
		# Gull Sight lasts exactly as long as TAB is held (and the gull has the breath for it)
		var s = player.snatch
		if (not Input.is_action_pressed("gull_sense") and not GS.tab_toggle) or GS.vision_tired or player.mode == 2 or s.state != "idle" or s.lock_fry != null or GS.cutscene or scenes.beat_busy:
			if GS.vision_tired and (Input.is_action_pressed("gull_sense") or GS.tab_toggle):
				hud.whisper("out of breath. land somewhere and rest.", 3.0)
			_close_sense()
	elif GS.vision_tired and not Input.is_action_pressed("gull_sense"):
		GS.vision_tired = false
	if player.active and not get_tree().paused:
		var rdt = delta / max(Engine.time_scale, 0.05)
		play_t += rdt
		if not GS.ordinary_eaten and not intro_active:
			GS.run_time += rdt
		_hints()
		_zone_tick(rdt)
		_hunger_tick(rdt)
		_autosave_tick(rdt)
		_quest_tick(rdt)
		_tab_lesson_tick(rdt)
		_coach_tick(rdt)
		_clock_tick(rdt)
		_ach_tick(rdt)
		_bow_tick()
		_cine_tick(rdt)

# which piece of the island the gull is over decides which piece of music plays (they cross-fade, with a little stubbornness so that a quick dip
# across a border does not change the tune)
var zone_cand = ""
var zone_t = 0.0
var zone_check = 0.0

func _zone_of(p):
	if p.y > 40.0:
		return "sky"
	if p.z < -70.0 or (p.x > 60.0 and p.z < -44.0):
		return "summit"
	if p.z < -26.0 and p.x < 62.0:
		return "hill"
	if WB.Terrain.H(p.x, p.z) < -0.4 or (p.z > 24.0 and p.x > -12.0 and p.x < 16.0):
		return "sea"
	if p.x > 22.0 and p.z > -50.0:
		return "beach"
	return "boardwalk"

func _zone_tick(rdt):
	zone_check -= rdt
	if zone_check > 0.0:
		return
	zone_check = 0.4
	Sfx.set_fish(GS.fish_mode())          # round 16: the sea has its own music while OCEAN TIME runs
	var z = _zone_of(player.global_position)
	if z == Sfx.world_zone:
		zone_cand = ""
		zone_t = 0.0
		return
	if z != zone_cand:
		zone_cand = z
		zone_t = 0.0
	zone_t += 0.4
	if zone_t >= 2.4:
		Sfx.set_world_zone(z)

func _hints():
	if Input.is_action_pressed("move_forward"):
		used_w = true
	_tutorial_director()
	var post = GS.gull_sense_count >= 3
	if post and play_t > 25.0 and GS.fry_total() < 8 and player.mode == 0 and not hud.hint_shown.has("shift"):
		hud.hint("shift", "SHIFT - BOOST          CTRL - LAND", 4.0)

	if GS.diff != "classic" and play_t > 25.0 and GS.fry_total() < 3 and player.mode == 0 and not hud.hint_shown.has("turn"):
		hud.hint("turn", "R - TURN RIGHT ROUND", 4.0)
	if post and player.snatch.hud_state == "locked":
		hud.hint("e", "E - ON THE BEAT: WHEN A WHITE RING IS IN THE GOLD BAND." if GS.is_hard() else "E - WHEN A WHITE RING HITS THE GREEN.  GOLD COUNTS DOUBLE.", 3.5)
	if player.low_stamina and player.mode == 0:
		hud.hint("rest", "CTRL - LAND AND REST", 3.0)
	# round 15: the TAB lesson (see _tab_lesson_tick) replaces the old one-line hint; after it, the codex is mentioned once
	if GS.tab_lesson >= 2 and tab_hint_t < 0.0:
		tab_hint_t = play_t + 14.0
	if tab_hint_t > 0.0 and play_t > tab_hint_t:
		hud.hint("tab", "C - CODEX          F - SQUAWK (TRY IT ON A ROOF)", 4.0)
	if tab_hint_t > 0.0 and play_t > tab_hint_t + 12.0 and player.mode == 0:
		hud.hint("sniff", "E WHILE FLYING - POINTS TO THE NEAREST FRY YOU CAN CATCH", 4.5)

# Guides the first three (tutorial) fries: a marker you cannot lose + one persistent instruction at a time.
func _tutorial_director():
	hud.guide_pos = null
	var prompt = ""
	var n = GS.gull_sense_count
	if n < 3 and not GS.ordinary_eaten and not intro_active and not codex_open:
		var best = null
		var bd = 1e9
		for id in ["TUTORIAL_01", "TUTORIAL_02", "TUTORIAL_03"]:   # in order: 01 first, then the next one
			var f = world["fries"][id]
			if GS.tutorial_done.has(id) or not is_instance_valid(f) or f.consumed:
				continue
			best = f
			bd = f.global_position.distance_to(player.global_position)
			break
		var sn = player.snatch
		if best != null and sn.state != "cine":
			if sn.state == "idle" and sn.lock_fry == null and not best.vanished:
				hud.guide_pos = best.global_position + Vector3(0, 0.3, 0)
			if sn.state == "carry":
				prompt = ""
			elif best.vanished:
				prompt = "THE OLD MAN IS ORDERING A NEW ONE..."
			elif GS.diff != "classic":
				prompt = ""           # round 18: the coach card (hud.gd Coach) tells the steps, one line at a time
			elif sn.lock_fry != null:

				# round 10: the slow time is the most important skill of the game; the first fries name it, quietly
				if n == 0:
					prompt = "THE WORLD SLOWS DOWN: THIS IS GULL TIME.   PRESS  E  WHEN A WHITE RING HITS THE GREEN"
				elif n == 1:
					prompt = "GULL TIME AGAIN.   PRESS  E  WHEN A WHITE RING HITS THE GREEN   (GOLD COUNTS DOUBLE)"
				else:
					prompt = "PRESS  E  WHEN A WHITE RING HITS THE GREEN   (GOLD COUNTS DOUBLE)"
			elif n == 0:
				if player.mode == 1:
					prompt = "SPACE  -  TAKE OFF" if play_t > 1.0 else ""
				elif player.mode == 0:
					if bd > 24.0:
						prompt = "FLY TO THE GLOWING FRY  -  AIM WITH THE MOUSE, HOLD  W"
					elif player.speed < GS.need_speed(best):
						prompt = "HOLD  W  OR  SHIFT  -  REACH THE GRAB LINE  (%d)" % int(GS.need_speed(best) * GS.SPEED_UNIT)
					else:
						prompt = "KEEP AIMING AT THE FRY"
	if prompt == "" and bro_prompt != "":
		prompt = bro_prompt
	hud.set_prompt(prompt)

# crowd WATCH: global memory of the thieving gull + the people who are actually looking at it right now
func _update_watch(delta):
	watch_t -= delta
	if watch_t > 0.0:
		return
	watch_t = 0.2
	var local = 0.0
	var pp = player.global_position
	for n in world["npcs"]:
		if n.gone:
			continue
		var d = n.global_position.distance_to(pp)
		if d > 22.0:
			continue
		var near = 0.5 + 0.5 * (1.0 - d / 22.0)
		if n.awareness >= 0.7:
			local += 1.2 * near
		elif n.awareness >= 0.35:
			local += 0.5 * near
	for dg in get_tree().get_nodes_in_group("dogs"):
		if dg.state != "sleep" and dg.global_position.distance_to(pp) < 16.0:
			local += 0.4
	var crowd = 0
	for a in get_tree().get_nodes_in_group("ambient"):
		if a.visible and a.global_position.distance_to(pp) < 14.0:
			crowd += 1
	local += min(crowd * 0.12, 0.7)
	# round 12: up in the sky and away from the people, the crowd calms down fast (the memory of a thief fades in seconds, and what is left counts less);
	# a gull on the ground among quiet people is what the town is used to
	var nearest = 999.0
	for grp in ["ambient", "npcs"]:
		for a in get_tree().get_nodes_in_group(grp):
			if is_instance_valid(a) and not a.get("gone"):
				nearest = min(nearest, a.global_position.distance_to(pp))
	var away = player.mode == 0 and (pp.y > 20.0 or nearest > 45.0) and nearest > 14.0
	# round 15: a gull that sits still and bothers nobody is forgotten quickly, one that is high and far away even faster: down to zero
	var still = player.mode == 1 and player.still_t > 3.0 and player.carry_fry == null
	GS.heat_decay_mult = 9.0 if away else (5.0 if still else 1.0)
	_watch_target = clamp(GS.heat * (0.15 if away else (0.4 if still else 1.0)) + local * (0.55 if still else 1.0), 0.0, 4.0)
	# round 16: a gull that has stolen NOTHING for 8 seconds is forgotten fast (the target fades to zero over the next 4 s and the memory of the thief melts away),
	# and the watch stays down until the next theft
	var idle = GS.idle_steal_s()
	if idle > GS.IDLE_CALM:
		var calm_k = clamp(1.0 - (idle - GS.IDLE_CALM) / 4.0, 0.0, 1.0)
		_watch_target *= calm_k
		GS.heat_decay_mult = max(GS.heat_decay_mult, 14.0)

var _watch_target = 0.0

func _physics_process(delta):
	if player == null or not player.active:
		return
	if ordinary != null and not ordinary.consumed and not intro_active:
		ordinary.update_convergence(player.global_position, -player.global_transform.basis.z, delta)
	_update_watch(delta)
	GS.watch = lerp(GS.watch, _watch_target, 1.0 - exp(-3.0 * delta))
	_star_tick(delta)
	_rainbow_tick(delta / max(Engine.time_scale, 0.05))

func _input(event):
	if codex_open and event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		codex_yaw -= event.relative.x * 0.004
		codex_pitch = clamp(codex_pitch + event.relative.y * 0.004, -0.2, 1.2)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		var fs = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if intro_active and intro_clock > 0.8 and (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed():
		_finish_intro()
		return
	if player == null or not player.active or get_tree().paused or intro_active:
		return
	if event.is_action_pressed("gull_sense"):
		if GS.tab_toggle and GS.sense_active:
			GS.vision_tired = false
			_close_sense()
		else:
			_try_open_vision()
	elif event.is_action_released("gull_sense") and not GS.tab_toggle:
		GS.vision_tired = false
		_close_sense()
	if codex_open and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_LEFT, KEY_RIGHT]:
		sense.page = 1 - sense.page
		Sfx.play("equip", -12.0, 1.3)
	if event.is_action_pressed("board_toggle") and not event.is_echo() and not codex_open and not hud.film_clean:
		GS.board_open = not GS.board_open       # round 18b: Q folds the goals board away and brings it back
		GS.save_settings()
		Sfx.play("tick_ui", -8.0, 1.0 if GS.board_open else 0.8)
	if event.is_action_pressed("codex"):
		if codex_open:
			_close_codex()
		elif _can_open_codex():
			_open_codex()
	if event.is_action_pressed("squawk") and not player.input_locked and not codex_open:
		var now = GS.msec() / 1000.0
		if now - last_yell > 1.2:
			last_yell = now
			Sfx.play("lure", -2.0)
			player.fov_kick = 2.0
			_squawk_effects()

# round 16, the squawk has its own little world. ON A ROOF it calls the gulls of the neighbourhood (a flock lands around the gull, hearts, a short visit). ON THE GROUND
# a calm crowd (watch < 1.6) answers with hellos and waves; a wary one (watch >= 1.6) answers by chasing the noisy gull off. In the air it is the old yell.
func _squawk_effects():
	var pl = player
	var on_roof = pl.mode == 1 and not pl.on_water and pl.perch_high and pl.surface() == "roof"
	if on_roof:
		rest.call_flock()
		return
	rivals.scare(pl.global_position)
	for n in get_tree().get_nodes_in_group("npcs"):
		n.hear(pl.global_position)
	if pl.mode == 1 and not pl.on_water:
		var near = []
		for a in get_tree().get_nodes_in_group("ambient"):
			if is_instance_valid(a) and a.visible and a.has_method("answer_call") and a.global_position.distance_to(pl.global_position) < 16.0:
				near.append(a)
		near.sort_custom(func(x, y): return x.global_position.distance_squared_to(pl.global_position) < y.global_position.distance_squared_to(pl.global_position))
		var n_ans = 0
		var kind_n = 0
		var shoo_n = 0
		for a in near:
			if n_ans >= 3:
				break
			var r = a.answer_call()
			if r != 0:
				n_ans += 1
				if r > 0:
					kind_n += 1
				else:
					shoo_n += 1
		if kind_n > 0:
			GS.ach_unlock("callkind")
			GS.comic.emit("call_hello", "A STRANGER WAVED BACK. THE SQUAWK WORKS.", {"tier": 0})
		elif shoo_n > 0:
			GS.ach_unlock("callshoo")
			GS.comic.emit("call_shoo", "SQUAWKING AT A SUSPICIOUS CROWD: RUDE.", {"tier": 0})

# ---- Gull Sight: hold TAB. Slow motion, dark screen, every fry in range shines, everything else gets a number. Free on the ground. ----
func _try_open_vision():
	if codex_open or GS.sense_active or player.input_locked or GS.film_flow or GS.cutscene or scenes.cine_busy or scenes.beat_busy:       # round 19: never in a cut scene
		return
	if not GS.vision_unlocked():
		hud.whisper("gull sight is not open yet. three fries first.", 3.0)
		return
	var s = player.snatch
	if player.mode == 2 or s.state != "idle" or s.lock_fry != null:
		return
	if player.mode == 0 and player.stamina < 8.0 * GS.drain_mult() and GS.vision_cost() > 0.0:
		hud.whisper("too tired to squint. land and rest first.", 3.0)
		return
	_open_sense()

func _open_sense():
	GS.sense_active = true
	GS.vision_tired = false
	Engine.time_scale = VISION_TS
	Sfx.play("vision_on", -9.0)
	Sfx.muffle(true, 0.25, 3000.0)

func _close_sense():
	if not GS.sense_active:
		return
	GS.sense_active = false
	if not player.snatch.focus_owned and player.snatch.state != "cine" and not GS.cutscene:       # round 19: a cut scene keeps its own slow time
		Engine.time_scale = 1.0
	Sfx.play("vision_off", -12.0)
	Sfx.muffle(false, 0.3)

func _close_sense_if_open():
	_close_sense()
	_close_codex()

# ---- the side quests (fish / cloud / sun): they show up on the mission board once enough fries are in ----
var quest_items = {}
var quest_t = 0.0
const CLOUD_POS = Vector3(22.0, 92.0, 74.0)
const RAINCLOUD_POS = Vector3(-85.0, 86.0, 150.0)

func _quest_tick(rdt):
	quest_t -= rdt
	if quest_t > 0.0:
		return
	quest_t = 0.5
	var before = {}
	for id in GS.QUESTS:
		before[id] = GS.quest_state(id)
	GS.quests_refresh()
	var fresh = []
	for id in GS.QUESTS:
		if before[id] == "" and GS.quest_state(id) == "active":
			fresh.append(id)
	if fresh.size() > 3:
		hud.whisper("new tasks on the board. the gull is never idle.", 4.0)
		Sfx.play("chime", -14.0, 1.3)
	elif fresh.size() > 0:
		hud.whisper("new on the board: %s." % GS.QUESTS[fresh[0]][1].to_lower(), 4.0)
		Sfx.play("chime", -14.0, 1.3)
	# the five things of the sky (and the grey rain cloud) hang up there once the quest is on the board
	var sky_on = GS.quest_state("sky") != ""
	if sky_on:
		for spec in [["cloud", CLOUD_POS], ["raincloud", RAINCLOUD_POS]]:
			if not quest_items.has(spec[0]):
				var c = Node3D.new()
				c.set_script(load("res://scripts/fries/mischief.gd"))
				c.setup(spec[0], self, spec[1])
				quest_items[spec[0]] = c
		if not quest_items.has("moon"):
			var mo = Node3D.new()
			mo.set_script(load("res://scripts/fries/mischief.gd"))
			mo.setup("moon", self, DAY_SCRIPT.MOON_POS)
			quest_items["moon"] = mo
		if not quest_items.has("sun"):
			var s2 = Node3D.new()
			s2.set_script(load("res://scripts/fries/mischief.gd"))
			s2.setup("sun", self, day.sun_pos if day != null else Vector3(0, 110, 160))
			quest_items["sun"] = s2
		if not quest_items.has("skybow"):
			var rp0 = get_tree().get_first_node_in_group("rainbow_pair")
			if rp0 != null:
				var b0 = Node3D.new()
				b0.set_script(load("res://scripts/fries/mischief.gd"))
				b0.setup("skybow", self, rp0.apex())
				quest_items["skybow"] = b0
	# the sun item rides along with the sun in the sky; once it is caught the sky sun is gone (and the same for the moon)
	var sun_item = quest_items.get("sun", null)
	if sun_item != null and is_instance_valid(sun_item) and not sun_item.taken and day != null:
		sun_item.global_position = day.sun_pos
	var moon_item = quest_items.get("moon", null)
	if moon_item != null and is_instance_valid(moon_item) and not moon_item.taken and day != null:
		moon_item.global_position = DAY_SCRIPT.MOON_POS
	if day != null:
		day.sun_caught = GS.sky_got.has("sun")
		day.moon_caught = GS.sky_got.has("moon")

# ---- round 18: THE COACH. Nobody knew how to get a fry: that you climb first, put the fry in the middle of the screen, then dive at it with Shift, then press E on the green.
# So the first fries come with a card of those four steps (hud.gd Coach); the step that is lit follows what the gull is really doing, one line says what to do now. After the
# three starter fries it only comes back when a player has gone a long time without a fry, and then a pointer shows the nearest fry that can be caught.
var coach_idle = 0.0
var coach_total = -1
var coach_tgt = null

func _coach_target():
	if GS.gull_sense_count < 3:
		for id in ["TUTORIAL_01", "TUTORIAL_02", "TUTORIAL_03"]:
			var f = world["fries"][id]
			if not GS.tutorial_done.has(id) and is_instance_valid(f) and not f.consumed and not f.vanished:
				return f
		return null
	return GS.nearest_fry(player.global_position)

func _coach_tick(rdt):
	var tot = GS.fry_total()
	var sn = player.snatch
	if tot != coach_total:
		coach_total = tot
		coach_idle = 0.0
	if sn.state == "idle" and sn.lock_fry == null and player.mode != 2:
		coach_idle += rdt
	var busy = GS.ordinary_eaten or intro_active or ending_started or GS.free_play or codex_open or showcase.active or scenes.cine_busy or GS.film_flow or story.active
	var want = false
	if GS.diff != "classic" and not busy:
		if tot < 3:
			want = GS.is_easy() or tot == 0
		elif tot < 10:
			want = coach_idle > (45.0 if GS.is_easy() else 100.0)
	# a pointer to the nearest catchable fry for anybody who has been looking for one for a long time
	if GS.diff != "classic" and not busy and tot >= 3 and tot < GS.FRY_CAP and coach_idle > (80.0 if GS.is_easy() else 170.0) and player.mode == 0:
		var nf = GS.nearest_fry(player.global_position)
		if nf != null:
			GS.sniff_node = nf
			GS.sniff_until = GS.msec() / 1000.0 + 7.0
			hud.whisper("lost? the arrow points at the nearest fry you can catch.", 4.5)
			Sfx.play("chime", -14.0, 1.5)
			coach_idle = coach_idle - 45.0
	if not want:
		hud.coach = null
		return
	var tgt = _coach_target()
	if tgt == null:
		hud.coach = null
		return
	var p = player
	var tab = GS.vision_unlocked()
	var need = GS.need_speed(tgt)
	var to = tgt.global_position - p.global_position
	var step = 0
	var line = "CLIMB ABOVE THE FRY:  W AND LOOK UP,  OR TAP SPACE"
	if p.mode != 0:
		line = "PRESS SPACE TO TAKE OFF"
	elif sn.state == "carry" or sn.state == "cine":
		step = 4
		line = "GOT IT!"
	elif sn.lock_fry != null:
		step = 3
		line = "PRESS  E  ON THE BEAT:  WHEN A WHITE RING IS IN THE GOLD BAND" if GS.is_hard() else "PRESS  E  WHEN A WHITE RING HITS THE GREEN BAND  (GOLD COUNTS DOUBLE)"
	elif sn.near_target == tgt:
		step = 2
		line = "NOW DIVE:  HOLD SHIFT AND FLY STRAIGHT AT IT   (SPEED %d)" % int(round(need * GS.SPEED_UNIT))
	elif p.global_position.y >= tgt.global_position.y + 4.0 or to.length() < 10.0:
		step = 1
		line = ("HOLD TAB:  THE WORLD SLOWS DOWN.  PUT THE FRY IN THE MIDDLE OF THE SCREEN" if tab else "TURN SO THAT THE FRY IS IN THE MIDDLE OF THE SCREEN   (R - TURN AROUND)")
	hud.coach = {"show": true, "step": step, "line": line, "steps": [
		{"key": "SPACE", "label": "CLIMB"},
		{"key": "TAB" if tab else "MOUSE", "label": "SLOW + AIM" if tab else "AIM AT IT"},
		{"key": "SHIFT", "label": "DIVE"},
		{"key": "E", "label": "ON THE GOLD" if GS.is_hard() else "ON THE GREEN"}]}

# ---- round 18: the race clock of HARD (the fastest time to the 24 fries is kept)
func _clock_tick(rdt):
	if not GS.is_hard() or GS.ordinary_eaten or intro_active or GS.cutscene or showcase.active or codex_open or GS.hard_last > 0.0:
		return
	GS.hard_clock += rdt

func _hard_finish():
	if not GS.is_hard() or GS.hard_last > 0.0:
		return
	GS.hard_last = GS.hard_clock
	if GS.diff_changed:
		hud.whisper("24 fries in %s.  (a run that began easy is not a record.)" % GS.time_text(GS.hard_last), 6.0)
		return
	if GS.hard_best <= 0.0 or GS.hard_last < GS.hard_best:
		GS.hard_best = GS.hard_last
		GS.save_records()
		hud.whisper("24 fries in %s.  A NEW BEST TIME." % GS.time_text(GS.hard_last), 7.0)
		GS.comic.emit("record", "THE FASTEST GULL ON THE PIER. FOR NOW.", {"tier": 3, "col": GS.RARITY_COLORS[2]})
	else:
		hud.whisper("24 fries in %s.  (your best: %s)" % [GS.time_text(GS.hard_last), GS.time_text(GS.hard_best)], 6.0)

# ---- the TAB lesson (round 15). The most important key of the game gets a lesson of its own, by doing: a big keycap presses itself at the bottom of the screen
# ("HOLD TAB") from the moment the third fry has opened Gull Sight; once the player holds it, the lines change with the seconds of holding (what glows, what the number
# means), a ring closes, and after about three seconds the card thanks the player and goes. If the player ignores it, it shrinks, but it stays.
var lesson_wait = 0.0
func _tab_lesson_tick(rdt):
	if GS.tab_lesson >= 2 or GS.gull_sense_count < 3 or GS.ordinary_eaten or intro_active or ending_started:
		return
	if GS.sense_active:
		GS.sight_time += rdt
	if GS.tab_lesson == 0:
		var sn = player.snatch
		if showcase.active or sn.state != "idle" or sn.lock_fry != null or scenes.cine_busy or scenes.beat_busy or codex_open or player.input_locked:
			lesson_wait = 0.0
			return
		lesson_wait += rdt
		if lesson_wait > 3.0:
			GS.tab_lesson = 1
			Sfx.play("chime", -10.0, 1.5)
		return
	var t = GS.sight_time
	if t < 1.0:
		hud.lesson_line = "THE WORLD SLOWS DOWN"
	elif t < 2.2:
		hud.lesson_line = "EVERYTHING THAT GLOWS IS A FRY TO STEAL"
	else:
		hud.lesson_line = "THE NUMBER = THE SPEED YOU NEED"
	if not GS.sense_active and GS.sight_time >= 3.4:
		GS.tab_lesson = 2
		GS.comic.emit("tablesson", "SQUINT HARDER. SEE EVERYTHING.", {"tier": 0})
		hud.lesson_done_t = 3.6
		Sfx.play("reward_1", -8.0, 1.3)

var ach_t = 0.0
var calm_after_alarm = 0.0
var was_all_eyes = false
func _ach_tick(rdt):
	ach_t -= rdt
	if ach_t > 0.0:
		return
	ach_t = 1.0
	GS.ach_tick()
	# INNOCENT AS A SEAGULL: the crowd was on full alert, and now nobody is watching
	if GS.watch >= 3.0:
		was_all_eyes = true
	if was_all_eyes and GS.watch < 0.08:
		calm_after_alarm += 1.0
		if calm_after_alarm >= 2.0:
			if GS.ach_unlock("innocent"):
				GS.comic.emit("calm", "NOBODY IS WATCHING. SUSPICIOUSLY PERFECT.", {"tier": 0})
	else:
		calm_after_alarm = 0.0

# ---- a thing of the sky was caught (round 15): NO camera change and NO slow time. A ring of light leaves the gull, sparkles in the colour of the thing, a note that
# climbs with every new one, the little panel in the lower left, and a word + five pips at the top. The gull keeps flying and the player keeps looking where they were looking.
const SKY_COLS = {"cloud": Color("EAF2FF"), "raincloud": Color("B9C8E0"), "star": Color("FFE27A"), "moon": Color("9FD2FF"), "sun": Color("FFD66B"), "rainbow": Color("FF9AD0")}
const SKY_CAPS = {
	"cloud": ["A WHOLE CLOUD. SOFTER THAN IT LOOKED, AND A LITTLE DAMP.", "A CLOUD, CAUGHT. THE MORNING STAYS ON YOUR FEATHERS."],
	"raincloud": ["A RAIN CLOUD. IT FOLLOWS YOU HOME LIKE A SAD LITTLE DOG.", "RAIN, BUT YOURS. SOMEBODY HAD TO WEAR IT."],
	"star": ["A FALLING STAR. THE WISH WAS FRIES. OBVIOUSLY.", "THE STAR WAS FAST. YOU WERE FASTER. SORRY, STAR."],
	"moon": ["THE MOON. NO CHEESE, JUST A LOT OF QUIET.", "OVER THE MOON. IT TURNS OUT THAT IS A REAL PLACE."],
	"sun": ["THE SUN. WARM, BRIGHT AND NOT A BIT SORRY.", "YOU HELD THE SUN. YOUR BEAK IS FINE. YOUR HEART IS LIT."],
	"rainbow": ["A RAINBOW. SEVEN COLOURS, EVERY ONE OF THEM YOURS.", "THROUGH THE RAINBOW AND OUT INTO A BRAND NEW COLOUR."],
}
var _ring_tex_cache = null

func _ring_tex():
	if _ring_tex_cache == null:
		var S = 128
		var img = Image.create(S, S, false, Image.FORMAT_RGBA8)
		for y in S:
			for x in S:
				var r = Vector2(x - S * 0.5 + 0.5, y - S * 0.5 + 0.5).length() / (S * 0.5)
				var a = exp(-pow((r - 0.8) / 0.075, 2.0)) * clamp((1.0 - r) * 8.0 + 0.2, 0.0, 1.0)
				img.set_pixel(x, y, Color(1, 1, 1, clamp(a, 0.0, 1.0)))
		_ring_tex_cache = ImageTexture.create_from_image(img)
	return _ring_tex_cache

func _sky_ring(pos, col, size_to, secs, delay = 0.0):
	var mi = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = Vector2(1, 1)
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.albedo_texture = _ring_tex()
	m.albedo_color = Color(col.r, col.g, col.b, 0.0)
	m.no_depth_test = true
	q.material = m
	mi.mesh = q
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = pos
	mi.scale = Vector3.ONE * 0.8
	var tw = mi.create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(m, "albedo_color:a", 0.85, 0.08)
	tw.parallel().tween_property(mi, "scale", Vector3.ONE * size_to, secs).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(m, "albedo_color:a", 0.0, secs).set_delay(0.08)
	tw.tween_callback(mi.queue_free)

func _sky_reward(kind, n):
	var col = SKY_COLS.get(kind, Color.WHITE)
	var pos = player.global_position
	_sky_ring(pos, col, 11.0, 0.8)
	_sky_ring(pos, col.lightened(0.4), 17.0, 1.05, 0.14)
	_burst(pos, col, 54, 6.5)
	_burst(pos + Vector3(0, 0.5, 0), Color(1, 1, 1), 22, 4.0)
	player.fov_kick = 4.5
	player.refill()
	Sfx.play("prism_%d" % clamp(n - 1, 0, 6), -5.0)
	Sfx.play("reward_2", -8.0, 1.0 + 0.06 * n)
	_sky_show(kind, col)
	var caps = SKY_CAPS.get(kind, ["CAUGHT."])
	GS.comic.emit(kind, caps[randi() % caps.size()], {"tier": 0})
	# round 16: and the words and the white space (a film moment, once per run for each thing; the gull keeps flying)
	var cid = {"cloud": "cloud", "raincloud": "raincloud", "moon": "moon", "sun": "sun", "rainbow": "skybow", "star": "meteor"}.get(kind, "")
	if cid != "":
		queue_cine(cid)

# round 16: every thing of the sky is caught with a little show of its own (no camera games, the gull keeps flying)
func _sky_show(kind, col):
	var pl = player
	match kind:
		"sun":
			# nine suns: nine little golden rings leave the gull one after the other, round the circle
			for i in 9:
				var a = TAU * i / 9.0
				get_tree().create_timer(0.09 * i, true, false, true).timeout.connect(func():
					if is_instance_valid(pl):
						var off = Vector3(cos(a) * 2.4, sin(a) * 1.7, 0.0)
						_sky_ring(pl.global_position + off, Color(1.0, 0.62 + 0.04 * i, 0.15), 4.0, 0.7)
						_burst(pl.global_position + off, Color(1.0, 0.8, 0.3), 8, 2.5))
			pl.shake = max(pl.shake, 0.35)
			Sfx.play("meteor_get", -6.0, 0.8)
			hud.flash_screen(Color(1.0, 0.75, 0.25), 0.32, 0.9)
		"moon":
			# a slow, wide, silver-blue ring, falling moon-dust, the notes of a lullaby climbing down
			_sky_ring(pl.global_position, Color(0.7, 0.85, 1.0), 26.0, 1.8)
			for i in 5:
				get_tree().create_timer(0.35 * i, true, false, true).timeout.connect(func():
					Sfx.play("chime", -12.0, 1.6 - 0.12 * i))
			_dust_fall(pl, Color(0.75, 0.88, 1.0), 4.0)
			hud.flash_screen(Color(0.45, 0.62, 1.0), 0.3, 1.8)
		"raincloud":
			# its own weather: a drizzle that follows the gull for a few seconds, a grey-blue ring, a rumble
			_sky_ring(pl.global_position, Color(0.55, 0.62, 0.78), 14.0, 1.2)
			_rain_on(pl, 4.5)
			Sfx.play("thud", -9.0, 0.5)
			get_tree().create_timer(0.35, true, false, true).timeout.connect(func(): hud.flash_screen(Color(0.9, 0.95, 1.0), 0.28, 0.2))
			Sfx.play("squirt", -12.0, 0.7)
		"cloud":
			_burst(pl.global_position, Color(1, 1, 1), 40, 2.4)
			_dust_fall(pl, Color(1, 1, 1), 2.6)
		"rainbow":
			for i in 7:
				get_tree().create_timer(0.08 * i, true, false, true).timeout.connect(func():
					if is_instance_valid(pl):
						_sky_ring(pl.global_position, Color.from_hsv(float(i) / 7.0, 0.6, 1.0), 6.0 + 1.6 * i, 0.9))
		"star":
			_burst(pl.global_position, Color(1.0, 0.95, 0.5), 30, 5.0)

func _rain_on(pl, secs):
	var p = CPUParticles3D.new()
	p.amount = 90
	p.lifetime = 0.75
	p.local_coords = false
	p.direction = Vector3.DOWN
	p.spread = 6.0
	p.initial_velocity_min = 9.0
	p.initial_velocity_max = 12.0
	p.gravity = Vector3(0, -6, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(3.2, 0.1, 3.2)
	var q = QuadMesh.new()
	q.size = Vector2(0.035, 0.55)
	var mt = StandardMaterial3D.new()
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mt.albedo_color = Color(0.75, 0.86, 1.0, 0.8)
	q.material = mt
	p.mesh = q
	pl.add_child(p)
	p.position = Vector3(0, 3.0, 0)
	p.emitting = true
	get_tree().create_timer(secs, true, false, true).timeout.connect(func():
		p.emitting = false
		get_tree().create_timer(1.0, true, false, true).timeout.connect(p.queue_free))

func _dust_fall(pl, col, secs):
	var p = CPUParticles3D.new()
	p.amount = 60
	p.lifetime = 1.8
	p.local_coords = false
	p.direction = Vector3.DOWN
	p.spread = 25.0
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 1.2
	p.gravity = Vector3(0, -0.6, 0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 2.2
	var q = QuadMesh.new()
	q.size = Vector2(0.16, 0.16)
	var mt = StandardMaterial3D.new()
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mt.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mt.albedo_texture = preload("res://scripts/player/gull_visual.gd").star_tex()
	mt.albedo_color = Color(col.r, col.g, col.b, 0.9)
	q.material = mt
	p.mesh = q
	pl.add_child(p)
	p.position = Vector3(0, 1.0, 0)
	p.emitting = true
	get_tree().create_timer(secs, true, false, true).timeout.connect(func():
		p.emitting = false
		get_tree().create_timer(2.0, true, false, true).timeout.connect(p.queue_free))

# a first-time moment: the memory reel keeps a few frames of it for the ending
func _on_memory_added(id):
	if reel != null and not autotest:
		reel.record(id)

# ---- Fry Codex: key C (map + stats + fries with tiers) ----
func _can_open_codex():
	return player.mode != 2 and not GS.sense_active and player.snatch.state == "idle" and player.snatch.lock_fry == null and not player.input_locked and not GS.film_flow

func _open_codex():
	codex_open = true
	GS.codex_open = true
	codex_yaw = player.yaw + PI
	codex_pitch = 0.3
	player.input_locked = true
	Engine.time_scale = 0.12
	sense.visible = true
	hud.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.play("chime", -14.0, 0.6)

func _close_codex():
	if not codex_open:
		return
	codex_open = false
	GS.codex_open = false
	player.input_locked = false
	Engine.time_scale = 1.0
	sense.visible = false
	hud.visible = true
	if not autotest:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player.set_override(Transform3D.IDENTITY, 60.0, 0.0, 4.0)

# ------------------------------------------------------------------ cards
func _special_info(type, tier, source):
	var rc = GS.RARITY_COLORS[tier]
	var info = {"name": GS.fry_name(type, tier), "category": "%s FRY" % GS.RARITY_NAMES[tier], "ftype": type, "color": GS.TYPE_COLORS[type],
		"tier": tier, "rarity_col": rc, "source": source, "desc": GS.DESCS[type][tier - 1], "ability_title": GS.STAT_NAMES[type],
		"ability": GS.ability_text(type, tier), "carrier": "box"}
	return info

func _show_fry(key, n, done, extra = {}):
	var info = {}
	match key:
		"tutorial":
			info = SHOW_TUTORIAL[n - 1].duplicate()
			info["ftype"] = "tutorial"
			info["color"] = Color("F6C453")
			info["rarity_col"] = GS.RARITY_COLORS[0]
			info["tier"] = 0
			info["min_t"] = 1.0
		"ordinary":
			info = {"name": "FRY", "category": "ORDINARY FRY", "ftype": "ordinary", "color": Color("E3A93A"),
				"source": "A GIFT FROM: THE OLD MAN", "desc": "Just a fry.\nWarm and salty.",
				"ability_title": "ABILITY", "ability": "NONE.   IT'S JUST A FRY.", "min_t": 2.2, "auto_t": 14.0, "tier": 0}
		"star":
			var type = extra["type"]
			var tier = extra["tier"]
			info = _special_info(type, tier, "TAKEN FROM: " + extra["spot"])
			info["ftype"] = "star"
			info["kind"] = GS.FRY_TYPES.find(type)
			info["min_t"] = 1.4 if tier >= 3 else 1.0
		_:
			info = _special_info(key, 1, TIER1_SOURCE[key])
	showcase.open(info, done)

# ------------------------------------------------------------------ progression
func _on_escaped(f):
	GS.fries_eaten += 1
	player.refill()                 # round 16: every fry gives the whole breath back (the first TAB and every flight after a fry never starts on an empty bar)
	var kind = f.ftype
	match kind:
		"tutorial":
			if GS.tutorial_done.has(f.id):
				return
			GS.tutorial_done[f.id] = true
			GS.gull_sense_count += 1
			var n = GS.gull_sense_count
			if n == 1:
				GS.remember("fry1")
				GS.ach_unlock("first_fry")
			_burst(player.global_position, Color(1.0, 0.9, 0.55), 22 if n < 3 else 60, 4.0 if n < 3 else 7.0)
			Sfx.play("reward_1", -6.0, 1.0 + 0.12 * n)
			GS.fry_got.emit("tutorial", 0)
			get_tree().create_timer(0.5, true, false, true).timeout.connect(func():
				Sfx.schedule_growl(4.0)
				GS.gull_sense_changed.emit(n)
				if n == 3:
					player.fov_kick = 5.0
					GS.phase = GS.Phase.SPECIAL_HUNT
					ordinary.visible = true          # now it is there: it was on the table all along
					Sfx.set_music_level(1)
					Sfx.play("gs_complete", -6.0)
					get_tree().create_timer(1.4, true, false, true).timeout.connect(func():
						GS.gull_sense_complete.emit()))
		"red", "orange", "green", "cyan", "blue", "purple", "pink":
			if f.tier >= 4:
				_rainbow_collected(f)
				return
			if GS.lv[kind] >= 1:
				return
			var old_max = GS.stamina_max()
			GS.set_level(kind, 1)
			if kind == "blue":
				player.stamina += GS.stamina_max() - old_max
			_upgrade_juice(kind, 1)
			if kind == "red":
				_early_sonic()
			GS.fry_got.emit(kind, 1)
			Sfx.schedule_growl(4.5)
			hud.collect_special(kind)
			GS.special_collected.emit(kind)
			GS.progress_changed.emit(GS.progress_value(), GS.TOTAL_BASE)
			if GS.special_count() == GS.FRY_TYPES.size():
				get_tree().create_timer(1.8, true, false, true).timeout.connect(func():
					GS.phase = GS.Phase.STILL_HUNGRY
					GS.still_hungry_started.emit())
		"star":
			_star_collected(f)

# tier 1 / 2 / 3 reward juice: the higher the rarity, the bigger the moment (but it never stops the game)
func _upgrade_juice(kind, tier):
	var col = GS.RARITY_COLORS[clamp(tier, 0, 4)] if tier >= 2 else GS.TYPE_COLORS[kind]
	_burst(player.global_position, col, 40 + 25 * tier, 5.0 + tier)
	player.fov_kick = 5.0 + 2.5 * tier
	player.shake = 0.12 + 0.05 * tier
	Sfx.play("reward_%d" % clamp(tier, 1, 3), -4.0)

# a repeat fry of a finished colour: a tiny bit more of the same stat
func _rainbow_collected(f):
	var type = f.utype
	var old_max = GS.stamina_max()
	GS.add_rainbow(type)
	if type == "blue":
		player.stamina += GS.stamina_max() - old_max
	rb_last[f.get_meta("rb_id", f.id)] = GS.msec() / 1000.0
	_burst(player.global_position, GS.TYPE_COLORS[type].lerp(Color(1, 1, 1), 0.4), 24, 4.0)
	Sfx.play("reward_1", -8.0, 1.35)
	GS.fry_got.emit(type, 4)
	GS.award("RAINBOW")
	if GS.stats["rainbow"] == 6:
		hud.whisper("so many fries. still hungry.", 4.0)

func _burst(pos, col, amount, vel):
	var p = CPUParticles3D.new()
	p.amount = max(int(amount), 4)
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.9
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = vel * 0.5
	p.initial_velocity_max = vel
	p.gravity = Vector3(0, -3.0, 0)
	var sm = SphereMesh.new()
	sm.radius = 0.07
	sm.height = 0.14
	sm.radial_segments = 6
	sm.rings = 3
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	sm.material = m
	p.mesh = sm
	add_child(p)
	p.global_position = pos + Vector3(0, 0.2, 0)
	p.emitting = true
	get_tree().create_timer(2.0).timeout.connect(p.queue_free)

func _reveal_specials():
	Sfx.play("chime", -6.0, 1.2)
	for k in world["fries"]:
		var f = world["fries"][k]
		if is_instance_valid(f) and f.is_special():
			f.reveal()
	hud.reveal_specials()
	GS.progress_changed.emit(3, GS.TOTAL_BASE)

# ------------------------------------------------------------------ star fries (tier 2 epic + tier 3 legendary)
func _begin_star_phase():
	Sfx.set_music_level(2)
	star_queue = []
	for t in GS.FRY_TYPES:
		for tier in [2, 3]:
			if not GS.star_got.has("%s_%d" % [t, tier]):
				star_queue.append({"type": t, "tier": tier})
	star_timer = 0.5

func _star_tick(delta):
	if GS.phase != GS.Phase.STILL_HUNGRY:
		return
	star_active = star_active.filter(func(f): return is_instance_valid(f) and not f.consumed)
	star_timer -= delta
	if star_active.size() < 3 and star_timer <= 0.0:
		_spawn_star()
		star_timer = 2.5

func _spawn_star():
	var spots = world["prism_spots"]
	var used = []
	var taken = []
	for f in star_active:
		used.append(f.get_meta("spot"))
		taken.append("%s_%d" % [f.utype, f.tier])
	var free = []
	for s in spots:
		if not used.has(s["name"]):
			free.append(s)
	if free.is_empty():
		return
	var pool = []
	for e in star_queue:
		if taken.has("%s_%d" % [e["type"], e["tier"]]):
			continue
		if e["tier"] == 3 and GS.lv[e["type"]] < 2:
			continue      # the diamond one only appears once the gold one of its kind is yours
		pool.append(e)
	if pool.is_empty():
		return
	var e2 = pool[randi() % pool.size()]
	_place_star(e2["type"], e2["tier"], free)

# hang one star fry (type, tier) on a free anchor: the preferred ones of its colour first (round 7: the useful colours near the start)
func _place_star(type, tier, free):
	var allowed = GOLD_SPOTS if tier == 2 else DIAMOND_SPOTS
	var pref = (PREF_GOLD if tier == 2 else PREF_DIAMOND).get(type, [])
	var tier_free = free.filter(func(sp): return pref.has(sp["name"]))
	if tier_free.is_empty():
		tier_free = free.filter(func(sp): return allowed.has(sp["name"]))
	if tier_free.is_empty():
		tier_free = free
	if tier_free.is_empty():
		return null
	var s2 = tier_free[randi() % tier_free.size()]
	var e2 = {"type": type, "tier": tier}
	var f2 = Node3D.new()
	f2.set_script(FRY_SCRIPT)
	f2.position = s2["pos"]
	add_child(f2)
	f2.setup("STAR_%s_%d" % [e2["type"], e2["tier"]], "star", "none", GS.FRY_TYPES.find(e2["type"]), e2["tier"])
	f2.set_meta("spot", s2["name"])
	f2.home_parent = self
	f2.home_pos = s2["pos"]
	star_active.append(f2)
	return f2

# the SONIC (red) gold fry does not wait for STILL HUNGRY: the moment the silver one is yours, the gold one hangs over the beach (round 7: speed first)
func _early_sonic():
	if GS.lv["red"] != 1 or GS.star_got.has("red_2"):
		return
	for f in star_active:
		if is_instance_valid(f) and not f.consumed and f.utype == "red" and f.tier == 2:
			return
	var used = []
	for f in star_active:
		if is_instance_valid(f):
			used.append(f.get_meta("spot"))
	var free = []
	for s in world["prism_spots"]:
		if not used.has(s["name"]):
			free.append(s)
	_place_star("red", 2, free)

func _star_collected(f):
	var type = f.utype
	var tier = f.tier
	if GS.lv[type] >= tier:
		return
	var old_max = GS.stamina_max()
	GS.set_level(type, tier)
	GS.star_got["%s_%d" % [type, tier]] = true
	for i in star_queue.size():
		if star_queue[i]["type"] == type and star_queue[i]["tier"] == tier:
			star_queue.remove_at(i)
			break
	if type == "blue":
		player.stamina += GS.stamina_max() - old_max
	_upgrade_juice(type, tier)
	Sfx.schedule_growl(4.0)
	GS.fry_got.emit(type, tier)
	GS.special_collected.emit(type)
	hud.collect_special(type)
	if tier == 3 and GS.type_complete(type):
		hud.whisper("%s complete. the next ones are rainbow." % GS.STAT_NAMES[type].to_lower(), 4.0)
	if GS.fry_total() >= GS.FRY_CAP:
		GS.award("ALL 24")
		queue_cine("all24")
		_hard_finish()
	star_timer = 3.0

# RAINBOW FRIES (round 7). Once a colour is complete, a passer-by somewhere out at the edges of the map is holding a rainbow fry of that colour in one
# hand. More colours complete = more of them out there; a new one appears a while after one was taken. (Children with a heart and friendly gulls
# hand them out too: see ambient_npc.gd `_kind` and rest_events.gd.)
const RB_MODES = ["stand", "chat", "stroll", "play", "sit", "fish", "paint", "eat", "jog", "wave"]
var rb_wait = 0.0

func _rainbow_tick(rdt):
	if GS.ordinary_eaten or GS.gull_sense_count < 3:
		return
	rb_t -= rdt
	if rb_t > 0.0:
		return
	rb_t = 3.0
	rb_holders = rb_holders.filter(func(h): return is_instance_valid(h["fry"]) and not h["fry"].consumed and is_instance_valid(h["npc"]))
	var done = []
	for k in GS.FRY_TYPES:
		if GS.type_complete(k):
			done.append(k)
	if done.is_empty():
		return
	var target = min(2 + done.size() * 2, 14)
	if rb_holders.size() >= target:
		return
	rb_wait -= 3.0
	if rb_wait > 0.0:
		return
	var held = []
	for h in rb_holders:
		held.append(h["npc"])
	var pp = player.global_position
	var pick = null
	for tries in 40:
		var cands = get_tree().get_nodes_in_group("ambient")
		var a = cands[randi() % cands.size()]
		if not is_instance_valid(a) or held.has(a) or a.carried_fry != null or a.mischief_item != null or a.kind_kid or a.grumpy:
			continue
		if not (a.mode in RB_MODES) or a.rig == null or a.rig.hand_l == null or a.alarm_t > 0.0:
			continue
		var home = Vector2(a.home_pos.x, a.home_pos.z)
		var edge = home.distance_to(Vector2(-9.0, 0.0))
		if edge < 62.0 or a.global_position.distance_to(pp) < 45.0:
			continue
		# the further out, the likelier
		if randf() > clamp((edge - 62.0) / 70.0 + 0.12, 0.0, 1.0):
			continue
		pick = a
		break
	if pick == null:
		return
	var type = done[randi() % done.size()]
	var fry = Node3D.new()
	fry.set_script(FRY_SCRIPT)
	pick.rig.hand_l.add_child(fry)
	rb_n += 1
	fry.setup("RB_%s_%d" % [type, rb_n], type, "hand", 0, 4)
	fry.position = Vector3(0, 0.0, 0.05)
	fry.home_parent = pick.rig.hand_l
	fry.owner_amb = pick
	pick.carried_fry = fry
	rb_holders.append({"npc": pick, "fry": fry})
	rb_wait = randf_range(14.0, 30.0)
	Sfx.play("chime", -26.0, 1.7)

# ------------------------------------------------------------------ "where is it?": guidance towards the plain fry
func _hunger_tick(rdt):
	if GS.phase != GS.Phase.STILL_HUNGRY or GS.ordinary_eaten or GS.free_play:
		hud.hint_pos = null
		return
	if showcase.active:
		return
	var all_found = star_queue.is_empty() and star_active.is_empty()
	GS.hunger_t += rdt * (3.0 if all_found else 1.0)
	# the gull slowly remembers: by the clock...
	while hunger_step < HUNGER_STEPS.size() and GS.hunger_t >= HUNGER_STEPS[hunger_step][0]:
		hud.whisper(HUNGER_STEPS[hunger_step][1], 6.0)
		Sfx.schedule_growl(2.0)
		hunger_step += 1
	# ...and by every strong fry it has eaten without finding what it wanted
	while hunger_cstep < HUNGER_COUNT_STEPS.size() and GS.fry_total() >= HUNGER_COUNT_STEPS[hunger_cstep][0]:
		hud.whisper(HUNGER_COUNT_STEPS[hunger_cstep][1], 7.0)
		Sfx.schedule_growl(2.5)
		hunger_cstep += 1
	# a thin wisp of steam starts to rise from the plain fry: not a marker, just warmth you can see from far away
	steam_t -= rdt
	if steam_t <= 0.0:
		steam_t = 1.0
		# a wisp of warmth only for someone who is already close (nothing to see from the other end of the island)
		var dd = ordinary.global_position.distance_to(player.global_position)
		ordinary.set_steam(clamp(GS.longing() / 14.0, 0.0, 1.0) * clamp(1.0 - (dd - 10.0) / 28.0, 0.0, 1.0))

func _on_ate_ordinary(f):
	if GS.ordinary_eaten:
		return
	GS.ordinary_eaten = true
	GS.end_time = GS.run_time
	if GS.gull_sense_count < 3:
		GS.award("EARLY BIRD")
	elif GS.phase == GS.Phase.STILL_HUNGRY:
		GS.award("ENOUGH")
	GS.phase = GS.Phase.ENDED
	GS.write_end_save(Vector3(-8.9, 5.3, -1.3), atan2(-1.0, 0.0))       # round 16: the ending keeps the run: KEEP PLAYING after the credits goes on from the roof
	GS.ordinary_fry_eaten.emit()
	hud.hint_pos = null
	elder_waving = false
	Sfx.play("snatch", -2.0)
	Sfx.stop_growl()
	Sfx.ending = true
	Sfx.fade_music(5.0)
	for pf in get_tree().get_nodes_in_group("star_fries"):
		pf.consume()
	for sf in get_tree().get_nodes_in_group("fries"):
		if sf != ordinary:
			sf.go_plain()
	elder.look_at_pos(player.global_position, 8.0)
	elder.rig.set_mode("idle")
	_close_sense_if_open()
	# the plain fry goes into the gull's beak: it is not eaten yet
	if is_instance_valid(f):
		f.attach(player.beak_socket)
	if autotest:
		hud.ending_sequence()
	else:
		scenes.ending(f)

func _flight_cam(target, side):
	var p = target.global_position
	var xf = Transform3D(Basis.IDENTITY, p + side).looking_at(p + Vector3(0, 0.1, 0), Vector3.UP)
	player.set_override(xf, 46.0, 1.0, 6.0)

# THE ENDING. The gull picks up the plain fry and carries it to its big brother. He asks what it wants. In all its finery it says "JUST"...
# the finery falls away... "JUST WANT FRIES." Then the quiet part: the cafe corner again, the fry, the old man, the cards, the credits.
func _ending_cinematic(fry):
	if ending_started:
		return
	ending_started = true
	Sfx.play_theme("theme_end", false, -8.0)
	player.input_locked = true
	player.scripted_move = true
	hud.visible = false
	var from = player.global_position
	var land = Vector3(-8.15, 5.22, -1.2)
	var t0 = GS.msec()
	var dur = 3.4
	player.mode = 0
	player.speed = 6.0
	player.throttling = true
	bro.look_at_player = false
	bro._face(from, 1.0)
	var yaw_goal = atan2(-1.0, 0.0)
	while true:
		var t = (GS.msec() - t0) / 1000.0
		var u = clamp(t / dur, 0.0, 1.0)
		var e = u * u * (3.0 - 2.0 * u)
		var pos = from.lerp(land, e)
		pos.y += sin(e * PI) * 1.7
		var dirv = (land - from)
		player.global_position = pos
		player.yaw = lerp_angle(player.yaw, atan2(-dirv.x, -dirv.z), 0.08)
		player.rotation = Vector3(-0.15 * sin(e * PI), player.yaw, 0.0)
		var cam_pos = pos + Vector3(-3.4, 1.8, 3.8)
		var xf = Transform3D(Basis.IDENTITY, cam_pos).looking_at(pos + Vector3(0, 0.2, 0), Vector3.UP)
		player.set_override(xf, 44.0, 1.0, 6.0)
		if u >= 1.0:
			break
		await get_tree().process_frame
	# landed next to the big brother
	player.throttling = false
	player.mode = 1
	player.speed = 0.0
	player.global_position = land
	player.yaw = yaw_goal
	player.aim_yaw = yaw_goal
	player.rotation = Vector3(0, yaw_goal, 0)
	Sfx.play("land", -8.0)
	var two = Transform3D(Basis.IDENTITY, Vector3(-7.2, 6.15, 2.2)).looking_at(Vector3(-7.2, 5.7, -1.25), Vector3.UP)
	player.set_override(two, 36.0, 1.0, 3.0)
	await get_tree().create_timer(1.1).timeout
	dialogue.skipping = false
	await dialogue.say("BIG BRO", "What do you want?", 1.1)
	await get_tree().create_timer(0.5).timeout
	var dressed = not player.gull.worn.is_empty()
	await dialogue.shout("JUST", 1.0)
	await get_tree().create_timer(1.1).timeout
	if dressed:
		# everything falls away
		var fx = CPUParticles3D.new()
		fx.amount = 70
		fx.one_shot = true
		fx.explosiveness = 1.0
		fx.lifetime = 1.0
		fx.direction = Vector3.UP
		fx.spread = 180.0
		fx.initial_velocity_min = 1.5
		fx.initial_velocity_max = 4.0
		fx.gravity = Vector3(0, -2.0, 0)
		var q = QuadMesh.new()
		q.size = Vector2(0.14, 0.14)
		var m = StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_texture = preload("res://scripts/player/gull_visual.gd").soft_tex()
		m.vertex_color_use_as_albedo = true
		m.albedo_color = Color(1, 0.9, 0.6, 0.9)
		q.material = m
		fx.mesh = q
		add_child(fx)
		fx.global_position = player.global_position + Vector3(0, 0.3, 0)
		fx.emitting = true
		get_tree().create_timer(2.0).timeout.connect(fx.queue_free)
		player.gull.reset_plain()
		Sfx.play("equip", -4.0, 0.6)
		Sfx.play("whoosh", -8.0, 1.4)
		await get_tree().create_timer(0.9).timeout
	await dialogue.shout("JUST WANT FRIES.", 2.3, Color(1.0, 0.92, 0.6))
	await get_tree().create_timer(0.4).timeout
	# the big brother takes off his shades
	bro.gull.unwear("shades")
	bro.scripted_talk = true
	bro.speak("...same.", 2.4)
	await get_tree().create_timer(2.6).timeout
	player.scripted_move = false
	await _ending_cafe()

# the quiet part: the same corner of the same cafe, the same morning shot, but the gull is the one sitting there now, eating the one fry it wanted
func _ending_cafe():
	player.input_locked = true
	player.mode = 1
	player.velocity = Vector3.ZERO
	player.speed = 0.0
	var spot = WB.ORDINARY_POS + Vector3(0.5, 0.42, 0.2)
	player.global_position = spot
	var to_old = elder.global_position - spot
	player.yaw = atan2(-to_old.x, -to_old.z)
	player.aim_yaw = player.yaw
	player.update_camera(0.0, true)
	for grp in ["ambient", "npcs"]:
		for n in get_tree().get_nodes_in_group(grp):
			if n != elder and is_instance_valid(n) and n.global_position.distance_to(spot) < 9.0:
				n.visible = false
	for dg in get_tree().get_nodes_in_group("dogs"):
		if dg.global_position.distance_to(spot) < 9.0:
			dg.visible = false
	hud.visible = true
	hud.ending_sequence()
	elder.rig.set_mode("wave")
	var t0 = GS.msec()
	var gull_vis = player.gull
	var fry = ordinary
	if is_instance_valid(fry):
		fry.visible = true
	while true:
		var t = (GS.msec() - t0) / 1000.0
		if t > 14.0:
			break
		var u = clamp(t / 14.0, 0.0, 1.0)
		var tgt = spot + Vector3(0.0, 0.3, 0.0)
		var cam_pos = Vector3(-6.0, 1.5, 7.6).lerp(Vector3(-1.0, 3.6, 12.5), smoothstep(0.0, 1.0, u))
		var xf = Transform3D(Basis.IDENTITY, cam_pos).looking_at(tgt, Vector3.UP)
		player.set_override(xf, lerp(36.0, 46.0, u), 1.0, 3.0)
		gull_vis.head_lunge = max(sin(t * 5.0), 0.0) * 0.09 * (1.0 - smoothstep(0.55, 0.8, u))
		if t > 5.0:
			elder.rig.set_mode("idle")
		if t > 7.0 and is_instance_valid(fry) and not fry.consumed:
			fry.consume()
		await get_tree().process_frame
	gull_vis.head_lunge = 0.0
	story.finish()
	title.finished.connect(func(): title.play_credits(), CONNECT_ONE_SHOT)
	title.play_ending()

func _s7_first_frame():
	print("[S7_FIRST_FRAME] ",JSON.stringify({"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"tris":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"ticks_ms":Time.get_ticks_msec(),"no_focus":DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"mouse_captured":Input.mouse_mode==Input.MOUSE_MODE_CAPTURED}))
