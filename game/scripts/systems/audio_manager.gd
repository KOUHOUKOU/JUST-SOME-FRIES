extends Node
# The sound of the game (round 7). Everything is rendered offline by tools/audio (numpy): ~100 sound effects made of feathers, air, taps, wood and water,
# and nine pieces of music (arrangements in the spirit of famous public-domain works: Satie, Pachelbel, Bach, Debussy, Grieg, Rossini...).
# At run time the game only LOADS .ogg files (no synthesis at start-up: the browser version used to freeze for seconds). If a file is missing the old
# procedural generator (below, "generation") fills in, so the game never goes silent.
#   music: one piece per part of the island, cross-faded when the gull flies from one to the next (zones are decided in main.gd);
#          STARLIGHT has its own piece; the title and the ending have theirs.

const Names = preload("res://scripts/systems/audio_names.gd")
const RATE = 22050
const MRATE = 11025
# the pitch ladder of a streak of good presses (a major pentatonic climb)
const PENTA = [1.0, 1.1225, 1.2599, 1.4983, 1.6818, 2.0, 2.2449, 2.5198]
# how loud each piece plays (dB): they are all normalised to the same loudness, so this is only taste
const MUSIC_DB = {"title": -7.0, "boardwalk": -9.5, "beach": -10.0, "hill": -9.0, "sea": -9.0, "summit": -9.5, "sky": -10.0, "star": -9.5, "ending": -7.0, "ending_mem": -9.0,
	"cine_joy": -9.0, "cine_wish": -8.0, "cine_home": -8.0, "cine_sun": -8.0}
const ALT = {"flap": ["flap", "flap2"]}

var sounds = {}
var pool = []
var pool_i = 0
var wind
var waves
var murmur
var music = []                 # (legacy name) the two cross-fading players
var music_streams = {}
var thread = null
var ready_ok = false
var music_master = 1.0
var lowpass
var gull_timer = 6.0
var growl_timer = -1.0
var calm = 0.0
var music_wanted = false
var music_level = 0
var music_fade = 1.0
var ending = false
var muffle_tw = null
var theme_player
var theme_player2
var theme_want = ""
var theme_loop = false
var themes = {}
var zone = ""                  # the piece that is playing in the world right now
var world_zone = "boardwalk"
var star_on = false
var cur = 0
var zone_tw = []
var hush = false
var hush_db = 0.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 18:
		var p = AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	wind = _loop_player(-80.0)
	waves = _loop_player(-80.0)
	murmur = _loop_player(-80.0)
	for i in 2:
		music.append(_loop_player(-80.0))
		zone_tw.append(null)
	theme_player = _loop_player(-80.0)
	theme_player2 = _loop_player(-80.0)
	lowpass = AudioEffectLowPassFilter.new()
	lowpass.cutoff_hz = 20500.0
	AudioServer.add_bus_effect(0, lowpass)
	if _load_assets():
		_finish_loading()
	else:
		# something is missing: the old generator makes up for it (on a thread; the browser build has no threads and then simply runs without)
		thread = Thread.new()
		thread.start(_generate_all)

func _load_assets():
	var ok = true
	for n in Names.SFX:
		var path = "res://assets/audio/sfx/%s.wav" % n
		if ResourceLoader.exists(path):
			sounds[n] = load(path)
		else:
			ok = false
	for n in Names.MUSIC:
		var path = "res://assets/audio/music/%s.ogg" % n
		if ResourceLoader.exists(path):
			var st = load(path)
			if st != null and "loop" in st:
				st.loop = n != "ending"
			music_streams[n] = st
		else:
			ok = false
	for n in ["wind", "waves", "murmur"]:
		if sounds.has(n) and sounds[n] is AudioStreamWAV:
			sounds[n].loop_mode = AudioStreamWAV.LOOP_FORWARD
			sounds[n].loop_begin = 0
			sounds[n].loop_end = sounds[n].data.size() / 2
	return ok and sounds.has("wind") and music_streams.has("title")

func _finish_loading():
	wind.stream = sounds.get("wind")
	waves.stream = sounds.get("waves")
	murmur.stream = sounds.get("murmur")
	waves.volume_db = -14.0
	wind.volume_db = -40.0
	murmur.volume_db = -30.0
	waves.play()
	wind.play()
	murmur.play()
	ready_ok = true
	if theme_want != "":
		play_theme(theme_want, theme_loop)
	if music_wanted:
		_zone_changed(true)

func _loop_player(db):
	var p = AudioStreamPlayer.new()
	p.volume_db = db
	add_child(p)
	return p

func _process(delta):
	if thread != null and not thread.is_alive():
		var r = thread.wait_to_finish()
		thread = null
		if r != null:
			sounds = r["sounds"]
			wind.stream = r["wind"]
			waves.stream = r["waves"]
			murmur.stream = r["murmur"]
			themes = r["themes"]
			for n in Names.MUSIC:
				if not music_streams.has(n):
					music_streams[n] = r["music"][0] if r["music"].size() > 0 else null
			waves.volume_db = -14.0
			wind.volume_db = -40.0
			murmur.volume_db = -30.0
			waves.play()
			wind.play()
			murmur.play()
			ready_ok = true
			if theme_want != "":
				play_theme(theme_want, theme_loop)
			if music_wanted:
				_zone_changed(true)
	if not ready_ok:
		return
	hush_db = move_toward(hush_db, -26.0 if hush else 0.0, 30.0 * delta)
	# distant gulls
	gull_timer -= delta
	if gull_timer <= 0.0:
		gull_timer = randf_range(9.0, 22.0)
		if not ending and not hush:          # round 12: never a stray call in the quiet of the ending or under a film moment
			play("gull_far", randf_range(-28.0, -22.0), randf_range(0.85, 1.15))
	# tummy growl scheduler
	if growl_timer > 0.0:
		growl_timer -= delta
		if growl_timer <= 0.0:
			play("growl", -22.0 + 2.0 * min(GS.fries_eaten, 8))
			growl_timer = -1.0
	murmur.volume_db = lerp(murmur.volume_db, -30.0 + 6.0 * calm, 1.0 - exp(-2.0 * delta))
	waves.volume_db = lerp(waves.volume_db, -14.0 + 3.0 * calm, 1.0 - exp(-2.0 * delta))
	# the music follows the hush and the fade-out of the ending
	var active = music[cur]
	if active.playing:
		var target = MUSIC_DB.get(zone, -10.0) + hush_db
		if music_fade < 1.0:
			target = lerp(-80.0, target, music_fade)
		if zone_tw[cur] == null or not zone_tw[cur].is_running():
			active.volume_db = move_toward(active.volume_db, target, 24.0 * delta)

func play(sound_name, vol_db = 0.0, pitch = 1.0):
	if ALT.has(sound_name):
		sound_name = ALT[sound_name][randi() % ALT[sound_name].size()]
	if not sounds.has(sound_name):
		return
	var p = pool[pool_i]
	pool_i = (pool_i + 1) % pool.size()
	p.stream = sounds[sound_name]
	p.volume_db = vol_db
	p.pitch_scale = pitch
	p.play()

func set_wind(n, boosting = false):
	if not ready_ok:
		return
	var tgt = lerp(-38.0, -14.0, clamp(n, 0.0, 1.4))
	if ending:
		tgt = -60.0
	if boosting:
		tgt += 3.0
	wind.volume_db = lerp(wind.volume_db, tgt, 0.12)
	wind.pitch_scale = lerp(0.75, 1.25, clamp(n, 0.0, 1.4))

func set_calm(c):
	calm = c

func muffle(on, sec = 0.2, cutoff = 1100.0):
	if muffle_tw != null:
		muffle_tw.kill()
	muffle_tw = create_tween().set_ignore_time_scale(true)
	muffle_tw.tween_property(lowpass, "cutoff_hz", cutoff if on else 20500.0, sec)

# ---------------------------------------------------------------- the music
func start_music():
	ending = false
	music_wanted = true
	music_fade = 1.0
	if ready_ok:
		_zone_changed(true)

func set_music_level(level):
	music_level = level         # (legacy: the music now follows the place, not the progress)

# main.gd tells where the gull is (a piece of the island); STARLIGHT overrides it
func set_world_zone(z):
	if z == world_zone:
		return
	world_zone = z
	if music_wanted and not star_on:
		_zone_changed(false)

func set_star(on):
	if on == star_on:
		return
	star_on = on
	if music_wanted:
		_zone_changed(false)

func _zone_changed(first):
	var want = "star" if star_on else world_zone
	if not music_streams.has(want) or music_streams[want] == null:
		return
	if want == zone and music[cur].playing and not first:
		return
	zone = want
	var old = music[cur]
	cur = 1 - cur
	var nw = music[cur]
	nw.stream = music_streams[want]
	nw.volume_db = -60.0
	nw.play()
	var target = MUSIC_DB.get(want, -10.0) + hush_db
	var sec = 2.4 if want == "star" else 3.8
	if zone_tw[cur] != null:
		zone_tw[cur].kill()
	zone_tw[cur] = create_tween().set_ignore_time_scale(true)
	zone_tw[cur].tween_property(nw, "volume_db", target, sec)
	var other = 1 - cur
	if zone_tw[other] != null:
		zone_tw[other].kill()
	zone_tw[other] = create_tween().set_ignore_time_scale(true)
	zone_tw[other].tween_property(old, "volume_db", -60.0, sec)
	zone_tw[other].tween_callback(old.stop)

# the title theme (loops) and the ending theme (plays once). Separate from the zone music.
func play_theme(theme_name, loop = true, vol = -7.0):
	theme_want = theme_name
	theme_loop = loop
	if not ready_ok:
		return
	var key = {"theme_open": "title", "theme_end": "ending", "theme_mem": "ending_mem"}.get(theme_name, theme_name)
	if not music_streams.has(key) or music_streams[key] == null:
		return
	var st = music_streams[key]
	if "loop" in st:
		st.loop = loop
	theme_player.stream = st
	theme_player.volume_db = vol
	theme_player.play()

# round 9: one theme melts into the next (the memories of the ending turn into the Largo when the big brother lands)
func crossfade_theme(theme_name, loop = false, vol = -9.0, sec = 2.5):
	theme_want = theme_name
	theme_loop = loop
	if not ready_ok:
		return
	var key = {"theme_open": "title", "theme_end": "ending", "theme_mem": "ending_mem"}.get(theme_name, theme_name)
	if not music_streams.has(key) or music_streams[key] == null:
		return
	var old = theme_player
	var nw = theme_player2
	theme_player2 = old
	theme_player = nw
	var st = music_streams[key]
	if "loop" in st:
		st.loop = loop
	nw.stream = st
	nw.volume_db = -60.0
	nw.play()
	var tw = create_tween().set_ignore_time_scale(true)
	tw.tween_property(nw, "volume_db", vol, sec)
	tw.parallel().tween_property(old, "volume_db", -60.0, sec)
	tw.tween_callback(old.stop)

func stop_theme(sec = 1.5):
	theme_want = ""
	if theme_player == null or not theme_player.playing:
		return
	var tw = create_tween().set_ignore_time_scale(true)
	tw.tween_property(theme_player, "volume_db", -60.0, sec)
	tw.tween_callback(theme_player.stop)

# a short piece for a cinematic moment (round 8): the world's music ducks under it and comes back when it is over
func cine_music(piece, vol = -9.0):
	hush = true
	play_theme(piece, false, vol)

func cine_music_end(sec = 2.0):
	hush = false
	stop_theme(sec)

# a hush: the music drops far down for a moment (the silence before JUST) and comes back
func hush_music(on):
	hush = on
	var tw = create_tween().set_ignore_time_scale(true)
	tw.tween_property(theme_player, "volume_db", -34.0 if on else -7.0, 0.8 if on else 1.4)

func fade_music(sec):
	var tw = create_tween().set_ignore_time_scale(true)
	tw.tween_property(self, "music_fade", 0.0, sec)
	tw.parallel().tween_property(wind, "volume_db", -60.0, sec)

func schedule_growl(delay = 4.0):
	growl_timer = delay

func stop_growl():
	growl_timer = -1.0

# ====================================================================== generation
func _generate_all():
	var s = {}
	_build_sfx(s)
	return {"sounds": s, "wind": _gen_wind(), "waves": _gen_waves(), "murmur": _gen_murmur(),
		"music": [_gen_music(0), _gen_music(1), _gen_music(2)], "themes": {"theme_open": _gen_theme(0), "theme_end": _gen_theme(1)}}

func _wav(samples, loop = false, rate = RATE):
	var w = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	var bytes = PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clamp(samples[i], -1.0, 1.0) * 30000.0))
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w

func _buf(dur, rate = RATE):
	var b = PackedFloat32Array()
	b.resize(int(rate * dur))
	return b

func _lp(b, a):
	var y = 0.0
	for i in b.size():
		y += (b[i] - y) * a
		b[i] = y
	return b

func _mix(a, bb, offset_sec = 0.0, gain = 1.0, rate = RATE):
	var off = int(offset_sec * rate)
	var need = off + bb.size()
	if a.size() < need:
		a.resize(need)
	for i in bb.size():
		a[off + i] += bb[i] * gain
	return a

func _gain(b, g):
	for i in b.size():
		b[i] *= g
	return b

func _noise(dur, vol, decay, lp = 0.2, attack = 0.01):
	var b = _buf(dur)
	var y = 0.0
	for i in b.size():
		var t = float(i) / RATE
		y += (randf_range(-1.0, 1.0) - y) * lp
		b[i] = y * vol * exp(-t * decay) * min(t / attack, 1.0)
	return b

# soft bell-like note: sine + faint upper partials, smooth attack
func _note(f, dur, vol, decay = 4.0, attack = 0.012, bright = 0.2):
	var b = _buf(dur)
	for i in b.size():
		var t = float(i) / RATE
		var e = exp(-t * decay) * min(t / attack, 1.0)
		b[i] = (sin(TAU * f * t) + bright * sin(TAU * f * 2.0 * t) + bright * 0.25 * sin(TAU * f * 3.01 * t)) * vol * e
	return b

# rounded gull-like call (soft, mid frequency, never shrill)
func _call(f0, f1, dur, vol, vib_hz = 7.0, vib = 22.0, breath = 0.05):
	var b = _buf(dur)
	var ph = 0.0
	for i in b.size():
		var t = float(i) / RATE
		var u = t / dur
		var f = lerp(f0, f1, u) + sin(t * TAU * vib_hz) * vib * sin(PI * u)
		ph += TAU * f / RATE
		var env = pow(max(sin(PI * u), 0.0), 0.7)
		b[i] = (sin(ph) + 0.2 * sin(ph * 2.0) + 0.05 * sin(ph * 3.0) + breath * randf_range(-1.0, 1.0)) * vol * env
	return _lp(b, 0.4)

func _sweep(dur, f0, f1, vol, shape = 1.0):
	var b = _buf(dur)
	var ph = 0.0
	for i in b.size():
		var t = float(i) / RATE
		var u = pow(t / dur, shape)
		ph += TAU * lerp(f0, f1, u) / RATE
		b[i] = sin(ph) * vol * sin(PI * t / dur)
	return b

func _hz(m):
	return 440.0 * pow(2.0, (m - 69) / 12.0)

func _build_sfx(s):
	var rng = RandomNumberGenerator.new()
	rng.seed = 7
	# --- gull voices
	var c = _call(820.0, 640.0, 0.34, 0.5)
	c = _mix(c, _call(780.0, 600.0, 0.3, 0.45), 0.36)
	s["chirp"] = _wav(c)
	s["happy"] = _wav(_mix(_call(640.0, 820.0, 0.2, 0.4, 5.0, 10.0), _call(720.0, 900.0, 0.24, 0.35, 5.0, 10.0), 0.24))
	s["cry"] = _wav(_mix(_call(900.0, 520.0, 0.45, 0.55, 9.0, 40.0), _noise(0.3, 0.05, 6.0, 0.15), 0.0))
	s["proud"] = _wav(_mix(_call(700.0, 980.0, 0.32, 0.5, 6.0, 14.0), _call(860.0, 1100.0, 0.4, 0.5, 6.0, 14.0), 0.34))
	s["lure"] = _wav(_mix(_call(880.0, 560.0, 0.5, 0.6, 8.0, 30.0), _call(840.0, 540.0, 0.5, 0.55, 8.0, 30.0), 0.52))
	s["gull_far"] = _wav(_gain(_mix(_call(760.0, 600.0, 0.4, 0.5), _call(700.0, 560.0, 0.4, 0.45), 0.5), 0.6))
	# --- movement
	s["flap"] = _wav(_lp(_noise(0.3, 0.55, 8.0, 0.1, 0.05), 0.5))
	var boost = _lp(_noise(0.9, 0.5, 2.2, 0.08, 0.2), 0.5)
	boost = _mix(boost, _sweep(0.8, 160.0, 320.0, 0.14, 1.5))
	s["boost"] = _wav(boost)
	s["roll"] = _wav(_lp(_noise(0.45, 0.6, 5.0, 0.1, 0.06), 0.55))
	s["whoosh"] = _wav(_lp(_noise(0.5, 0.5, 4.0, 0.12, 0.1), 0.5))
	s["splash"] = _wav(_lp(_noise(0.7, 0.9, 5.0, 0.3, 0.004), 0.6))
	s["shake"] = _wav(_lp(_noise(0.5, 0.5, 4.0, 0.5, 0.01), 0.7))
	s["tumble"] = _wav(_mix(_sweep(0.5, 260.0, 90.0, 0.3), _lp(_noise(0.4, 0.5, 6.0, 0.2), 0.5)))
	s["thud"] = _wav(_mix(_sweep(0.22, 130.0, 55.0, 0.8), _lp(_noise(0.15, 0.4, 20.0, 0.3), 0.4)))
	s["land"] = _wav(_mix(_sweep(0.15, 150.0, 80.0, 0.4), _lp(_noise(0.12, 0.3, 24.0, 0.3), 0.4)))
	# --- snatching
	s["snatch"] = _wav(_mix(_lp(_noise(0.2, 0.7, 14.0, 0.25), 0.5), _sweep(0.12, 300.0, 140.0, 0.4)))
	var crunch = _noise(0.07, 0.9, 30.0, 0.35)
	crunch = _mix(crunch, _noise(0.07, 0.8, 30.0, 0.3), 0.08)
	crunch = _mix(crunch, _noise(0.1, 0.7, 24.0, 0.25), 0.17)
	s["crunch"] = _wav(_lp(crunch, 0.7))
	s["miss"] = _wav(_mix(_sweep(0.22, 330.0, 220.0, 0.3), _lp(_noise(0.1, 0.4, 20.0, 0.3), 0.5)))
	s["clack"] = _wav(_mix(_note(300.0, 0.08, 0.7, 40.0, 0.001), _lp(_noise(0.05, 0.6, 40.0, 0.4), 0.6)))
	s["oh"] = _wav(_formant_oh())
	s["alert"] = _wav(_note(660.0, 0.18, 0.28, 14.0, 0.005))
	s["tooslow"] = _wav(_note(196.0, 0.16, 0.4, 14.0, 0.006))
	s["bark"] = _wav(_mix(_lp(_noise(0.12, 0.8, 18.0, 0.3), 0.55), _sweep(0.12, 360.0, 200.0, 0.5)))
	s["squirt"] = _wav(_lp(_noise(0.4, 0.5, 3.0, 0.5, 0.03), 0.8))
	s["broom"] = _wav(_lp(_noise(0.3, 0.6, 7.0, 0.15, 0.08), 0.5))
	s["heartbeat"] = _wav(_mix(_sweep(0.16, 90.0, 55.0, 0.8), _sweep(0.16, 90.0, 55.0, 0.6), 0.22))
	# --- body
	var g = _sweep(0.8, 78.0, 48.0, 0.9)
	var trem = _buf(0.8)
	for i in trem.size():
		var t = float(i) / RATE
		trem[i] = g[i] * (0.65 + 0.35 * sin(TAU * 11.0 * t))
	trem = _mix(trem, _lp(_noise(0.7, 0.18, 2.0, 0.1, 0.1), 0.2))
	s["growl"] = _wav(trem)
	# --- rewards (warm, major, soft attack)
	var ok = _note(_hz(72), 0.35, 0.4, 7.0)
	ok = _mix(ok, _note(_hz(79), 0.5, 0.4, 5.5), 0.1)
	s["success"] = _wav(ok)
	s["perfect"] = _wav(_mix(_note(_hz(91), 0.8, 0.28, 4.0, 0.004, 0.1), _note(_hz(96), 0.9, 0.2, 3.5, 0.004, 0.1), 0.05))
	var up = {"red": [60, 67, 72, 76, 79], "blue": [62, 69, 74, 78, 81], "purple": [65, 72, 77, 81, 84], "green": [64, 71, 76, 79, 83], "pink": [66, 73, 78, 82, 85],
		"orange": [59, 66, 71, 75, 78], "cyan": [67, 74, 79, 83, 86]}
	# Gull Sight: a soft breath in / breath out, and the little comic-panel pop
	s["vision_on"] = _wav(_mix(_sweep(0.55, 140.0, 330.0, 0.22, 1.4), _lp(_noise(0.5, 0.18, 3.0, 0.08, 0.2), 0.4)))
	s["vision_off"] = _wav(_mix(_sweep(0.4, 320.0, 150.0, 0.18, 0.8), _lp(_noise(0.35, 0.12, 5.0, 0.1, 0.05), 0.4)))
	s["pop"] = _wav(_mix(_sweep(0.12, 260.0, 620.0, 0.35, 0.7), _note(_hz(84), 0.2, 0.12, 14.0, 0.002)))
	for k in up:
		var sp = _buf(0.1)
		for j in 5:
			sp = _mix(sp, _note(_hz(up[k][j]), 1.0, 0.26, 3.0, 0.015, 0.25), j * 0.1)
		sp = _mix(sp, _note(_hz(up[k][0] - 12), 1.6, 0.3, 2.0, 0.02, 0.1))
		s["special_" + k] = _wav(sp)
	s["gs_tick"] = _wav(_note(_hz(84), 0.5, 0.25, 6.0))
	s["gs_complete"] = _wav(_mix(_mix(_note(_hz(72), 1.2, 0.3, 2.4), _note(_hz(76), 1.2, 0.3, 2.4), 0.12), _note(_hz(79), 1.4, 0.3, 2.2), 0.24))
	var kinds = [[84, 88, 91], [86, 90, 93], [81, 85, 88], [83, 86, 91], [88, 91, 95], [79, 83, 86], [85, 89, 92]]
	for k in kinds.size():
		var pr = _buf(0.1)
		for j in 3:
			pr = _mix(pr, _note(_hz(kinds[k][j]), 0.7, 0.22, 5.0, 0.01, 0.3), j * 0.07)
		s["prism_%d" % k] = _wav(pr)
	var ch = _note(_hz(81), 1.8, 0.22, 1.8)
	ch = _mix(ch, _note(_hz(88), 1.8, 0.1, 2.0))
	s["chime"] = _wav(ch)
	# --- round 4: a reward for every rarity (rare < epic < legendary), kept soft: bells, never fanfare
	var r1 = _buf(0.1)
	for j in 3:
		r1 = _mix(r1, _note(_hz([72, 76, 79][j]), 0.9, 0.2, 4.5, 0.01, 0.2), j * 0.09)
	s["reward_1"] = _wav(r1)
	var r2 = _buf(0.1)
	for j in 4:
		r2 = _mix(r2, _note(_hz([72, 76, 79, 84][j]), 1.2, 0.2, 3.5, 0.01, 0.25), j * 0.1)
	r2 = _mix(r2, _note(_hz(60), 1.8, 0.2, 1.8, 0.03, 0.1), 0.0)
	s["reward_2"] = _wav(r2)
	var r3 = _buf(0.1)
	for j in 5:
		r3 = _mix(r3, _note(_hz([72, 76, 79, 84, 88][j]), 1.6, 0.19, 2.8, 0.01, 0.3), j * 0.11)
	r3 = _mix(r3, _note(_hz(60), 2.6, 0.22, 1.3, 0.04, 0.1), 0.0)
	r3 = _mix(r3, _note(_hz(67), 2.6, 0.16, 1.3, 0.05, 0.1), 0.2)
	for j in 4:
		r3 = _mix(r3, _note(_hz(96 + (j % 2) * 4), 0.9, 0.06, 4.0, 0.005, 0.1), 0.7 + j * 0.16)
	s["reward_3"] = _wav(r3)
	# --- small world sounds
	var bb = _mix(_sweep(0.09, 480.0, 900.0, 0.3, 0.8), _lp(_noise(0.04, 0.1, 40.0, 0.3), 0.5))
	bb = _mix(bb, _sweep(0.07, 560.0, 1000.0, 0.22, 0.8), 0.13)
	s["bubble"] = _wav(bb)
	var eq = _buf(0.1)
	for j in 3:
		eq = _mix(eq, _note(_hz([84, 88, 91][j]), 0.5, 0.22, 7.0, 0.004, 0.2), j * 0.07)
	s["equip"] = _wav(eq)
	s["bop"] = _wav(_mix(_sweep(0.14, 230.0, 90.0, 0.8), _lp(_noise(0.08, 0.35, 24.0, 0.3), 0.4)))
	s["boo"] = _wav(_mix(_call(480.0, 760.0, 0.26, 0.5, 9.0, 40.0), _call(520.0, 800.0, 0.22, 0.4, 9.0, 40.0), 0.0))
	s["rival_call"] = _wav(_mix(_call(700.0, 500.0, 0.34, 0.5, 11.0, 50.0, 0.12), _call(660.0, 470.0, 0.3, 0.45, 11.0, 50.0, 0.12), 0.32))
	# round 5: one soft low note for every danger, a sip for the drinks, a little heart for a friend
	s["warn"] = _wav(_mix(_note(_hz(52), 0.4, 0.3, 6.0, 0.004, 0.1), _note(_hz(47), 0.45, 0.26, 6.0, 0.004, 0.1), 0.11))
	s["sip"] = _wav(_mix(_sweep(0.2, 300.0, 540.0, 0.28, 0.8), _lp(_noise(0.28, 0.1, 6.0, 0.15, 0.04), 0.5)))
	s["heart"] = _wav(_mix(_note(_hz(88), 0.5, 0.16, 6.0, 0.004, 0.2), _note(_hz(95), 0.55, 0.13, 6.0, 0.004, 0.2), 0.08))
	s["feed"] = _wav(_mix(_note(_hz(79), 0.5, 0.2, 5.0, 0.004, 0.2), _note(_hz(84), 0.6, 0.18, 4.5, 0.004, 0.2), 0.1))
	# round 6: the rhythm. A green press = a soft marimba note, a gold press = a bell with a sparkle on top, a miss = a muted little "tock".
	var ro = _mix(_note(_hz(72), 0.42, 0.34, 9.0, 0.003, 0.35), _lp(_noise(0.03, 0.12, 60.0, 0.4), 0.5))
	ro = _mix(ro, _note(_hz(84), 0.3, 0.08, 12.0, 0.003, 0.1), 0.0)
	s["ring_ok"] = _wav(ro)
	var rg = _note(_hz(76), 0.7, 0.3, 5.5, 0.003, 0.3)
	rg = _mix(rg, _note(_hz(83), 0.8, 0.26, 5.0, 0.003, 0.3), 0.045)
	rg = _mix(rg, _note(_hz(91), 0.6, 0.12, 7.0, 0.003, 0.1), 0.09)
	s["ring_gold"] = _wav(rg)
	s["ring_miss"] = _wav(_mix(_note(176.0, 0.14, 0.45, 26.0, 0.002, 0.2), _lp(_noise(0.06, 0.25, 40.0, 0.25), 0.4)))
	# the buffs: coffee a bright rising swirl, cocktail a warm sliding bubble, ice cream a sparkle run; one shared "wears off"
	var bc = _mix(_sweep(0.5, 220.0, 740.0, 0.22, 1.3), _note(_hz(79), 0.7, 0.18, 4.0, 0.01, 0.3), 0.18)
	bc = _mix(bc, _note(_hz(86), 0.8, 0.14, 4.0, 0.01, 0.3), 0.26)
	s["buff_coffee"] = _wav(bc)
	var ba = _mix(_sweep(0.6, 520.0, 260.0, 0.2, 0.9), _note(_hz(67), 0.9, 0.2, 3.0, 0.02, 0.2), 0.0)
	ba = _mix(ba, _note(_hz(74), 0.9, 0.16, 3.0, 0.02, 0.2), 0.16)
	for j in 3:
		ba = _mix(ba, _sweep(0.12, 300.0 + j * 120.0, 560.0 + j * 120.0, 0.14, 0.7), 0.12 + j * 0.12)
	s["buff_alcohol"] = _wav(ba)
	var bi = _buf(0.1)
	for j in 6:
		bi = _mix(bi, _note(_hz([84, 88, 91, 96, 100, 103][j]), 0.6, 0.16, 6.0, 0.004, 0.2), j * 0.07)
	s["buff_ice"] = _wav(bi)
	s["buff_end"] = _wav(_mix(_note(_hz(76), 0.5, 0.22, 6.0, 0.01, 0.2), _note(_hz(69), 0.7, 0.2, 5.0, 0.01, 0.2), 0.14))
	s["boing"] = _wav(_mix(_sweep(0.25, 180.0, 520.0, 0.35, 0.6), _note(_hz(88), 0.3, 0.12, 9.0, 0.003, 0.2), 0.04))
	# the "you got a fry" glide: a short rising shimmer under the reward chord
	var fg = _mix(_sweep(0.55, 360.0, 1100.0, 0.12, 1.4), _lp(_noise(0.5, 0.06, 3.0, 0.1, 0.2), 0.5))
	s["fry_fly"] = _wav(fg)
	# the one resolving tone: tonic (C) — only used at the ending
	s["tonic"] = _wav(_mix(_note(_hz(72), 3.5, 0.3, 1.1, 0.03, 0.1), _note(_hz(60), 3.5, 0.25, 0.9, 0.05, 0.05)))

# soft music-box themes. 0 = the title: warm and unresolved (a hungry gull); 1 = the ending: it finally comes home to C.
func _pluck(b, t0, midi, vel, decay = 3.2, rate = MRATE):
	var f = _hz(midi)
	var i0 = int(t0 * rate)
	var len_ = int(2.2 * rate)
	for i in len_:
		if i0 + i >= b.size():
			break
		var t = float(i) / rate
		var e = exp(-t * decay) * min(t / 0.006, 1.0)
		b[i0 + i] += (sin(TAU * f * t) + 0.35 * sin(TAU * f * 2.0 * t) + 0.12 * sin(TAU * f * 4.01 * t)) * vel * e

func _pad(b, t0, dur, midis, vel, rate = MRATE):
	var i0 = int(t0 * rate)
	var len_ = int(dur * rate)
	for m in midis:
		var f = _hz(m)
		for i in len_:
			if i0 + i >= b.size():
				break
			var t = float(i) / rate
			var e = sin(PI * clamp(t / dur, 0.0, 1.0))
			e = e * e
			b[i0 + i] += (sin(TAU * f * t) + 0.5 * sin(TAU * f * 1.004 * t)) * vel * e

func _gen_theme(kind):
	var bpm = 72.0 if kind == 0 else 64.0
	var beat = 60.0 / bpm
	var bars = 8 if kind == 0 else 10
	var n = int(MRATE * (beat * 4.0 * bars + (0.0 if kind == 0 else 4.0)))
	var b = PackedFloat32Array()
	b.resize(n)
	var rng = RandomNumberGenerator.new()
	rng.seed = 21 + kind
	if kind == 0:
		var chords = [[53, 57, 60, 64], [57, 60, 64, 67], [50, 53, 57, 62], [55, 59, 62, 65]]
		var scale = [72, 74, 76, 79, 81, 84]
		for bar in bars:
			var ch = chords[bar % 4]
			_pad(b, bar * beat * 4.0, beat * 4.4, ch, 0.026)
			for st in 8:
				if rng.randf() < 0.3:
					continue
				var tone = ch[(st * 2 + bar) % 4] + 24
				_pluck(b, bar * beat * 4.0 + st * beat * 0.5, tone, 0.05 if st % 2 == 0 else 0.032)
			var mel = scale[(bar * 2 + rng.randi() % 3) % scale.size()]
			_pluck(b, bar * beat * 4.0 + beat * (0.0 if bar % 2 == 0 else 1.0), mel, 0.09, 2.2)
			if bar % 2 == 1:
				_pluck(b, bar * beat * 4.0 + beat * 2.5, scale[(bar + 3) % scale.size()], 0.07, 2.2)
	else:
		# I - V - vi - IV, twice, then a long C major: the one fry, finally
		var prog = [[48, 55, 60, 64], [43, 50, 59, 62], [45, 52, 60, 64], [41, 48, 57, 60], [48, 55, 60, 64], [43, 50, 59, 62], [45, 52, 60, 64], [41, 48, 57, 60], [43, 50, 59, 62], [48, 55, 60, 64, 67, 72]]
		var mel2 = [76, 79, 81, 79, 76, 74, 72, 74, 76, 79, 81, 84, 81, 79, 77, 76, 74, 72, 74, 72, 71, 72, 74, 72, 79, 76, 74, 72, 74, 71, 74, 79, 76, 74, 72]
		var mi = 0
		for bar in bars:
			var ch2 = prog[bar]
			_pad(b, bar * beat * 4.0, beat * (4.4 if bar < 9 else 8.0), ch2, 0.03)
			for st in 4:
				_pluck(b, bar * beat * 4.0 + st * beat, ch2[st % 4] + 12, 0.045, 3.0)
			if bar < 9:
				for st2 in [0, 2]:
					if mi < mel2.size():
						_pluck(b, bar * beat * 4.0 + st2 * beat + (0.5 * beat if st2 == 2 else 0.0), mel2[mi], 0.09, 2.0)
						mi += 1
			else:
				_pluck(b, bar * beat * 4.0, 72, 0.12, 0.9)
				_pluck(b, bar * beat * 4.0 + beat * 1.5, 79, 0.09, 0.9)
				_pluck(b, bar * beat * 4.0 + beat * 3.0, 84, 0.07, 0.8)
	return _wav(_lp(b, 0.55), kind == 0, MRATE)

func _formant_oh():
	var dur = 0.22
	var b = _buf(dur)
	for i in b.size():
		var t = float(i) / RATE
		var u = t / dur
		var f = 200.0 + 40.0 * sin(PI * u)
		var v = sin(TAU * f * t) * 0.3 + sin(TAU * 500.0 * t) * 0.18 + sin(TAU * 850.0 * t) * 0.08
		b[i] = v * sin(PI * u)
	return _lp(b, 0.3)

func _gen_wind():
	var b = _buf(3.0)
	var y = 0.0
	var y2 = 0.0
	for i in b.size():
		y += (randf_range(-1.0, 1.0) - y) * 0.05
		y2 += (y - y2) * 0.25
		var t = float(i) / RATE
		b[i] = y2 * (1.4 + 0.5 * sin(TAU * t / 3.0))
	return _wav(b, true)

func _gen_waves():
	var b = _buf(8.0)
	var y = 0.0
	for i in b.size():
		var t = float(i) / RATE
		var swell = 0.3 + 0.7 * (0.5 + 0.5 * sin(TAU * t / 8.0 - 1.2))
		y += (randf_range(-1.0, 1.0) - y) * 0.04
		b[i] = y * swell * 2.2
	return _wav(b, true)

func _gen_murmur():
	var b = _buf(6.0)
	var y = 0.0
	var y2 = 0.0
	for i in b.size():
		var t = float(i) / RATE
		y += (randf_range(-1.0, 1.0) - y) * 0.09
		y2 += (y - y2) * 0.4
		var am = 0.5 + 0.5 * sin(TAU * t * 0.7) * sin(TAU * t * 1.9 + 1.0)
		b[i] = y2 * am * 1.5
	return _wav(b, true)

# warm seaside loop: IV - vi - ii - V(sus). Never plays the tonic chord.
func _gen_music(layer):
	var bpm = 84.0
	var beat = 60.0 / bpm
	var bars = 8
	var dur = beat * 4.0 * bars
	var n = int(MRATE * dur)
	var b = PackedFloat32Array()
	b.resize(n)
	# chords: [bass midi, tones...]
	var chords = [[41, 53, 57, 60, 64], [45, 57, 60, 64, 67], [38, 53, 57, 60, 62], [43, 55, 60, 62, 65]]
	var rng = RandomNumberGenerator.new()
	rng.seed = 11 + layer
	if layer == 0:
		for bar in bars:
			var ch = chords[bar % 4]
			var t0 = bar * beat * 4.0
			for k in range(1, 5):
				var f = _hz(ch[k])
				var i0 = int(t0 * MRATE)
				var len_ = int(beat * 4.0 * MRATE)
				for i in len_:
					var t = float(i) / MRATE
					var e = sin(PI * t / (beat * 4.0))
					e *= e
					b[(i0 + i) % n] += (sin(TAU * f * t) + 0.6 * sin(TAU * f * 1.003 * t)) * 0.035 * e
		# gentle plucked arpeggio, eighth notes
		for bar in bars:
			var ch = chords[bar % 4]
			for st in 8:
				if rng.randf() < 0.18:
					continue
				var tone = ch[1 + (st * 3 + bar) % 4] + (12 if st % 4 == 2 else 0)
				var t0 = bar * beat * 4.0 + st * beat * 0.5
				var f = _hz(tone + 12)
				var i0 = int(t0 * MRATE)
				var len_ = int(0.9 * MRATE)
				var vel = 0.06 if st % 2 == 0 else 0.04
				for i in len_:
					var t = float(i) / MRATE
					var e = exp(-t * 4.5) * min(t / 0.01, 1.0)
					b[(i0 + i) % n] += (sin(TAU * f * t) + 0.3 * sin(TAU * f * 2.0 * t)) * vel * e
	elif layer == 1:
		for bar in bars:
			var ch = chords[bar % 4]
			for bt in 4:
				var t0 = bar * beat * 4.0 + bt * beat
				var f = _hz(ch[0] + (12 if bt == 2 else 0))
				var i0 = int(t0 * MRATE)
				var len_ = int(0.7 * MRATE)
				for i in len_:
					var t = float(i) / MRATE
					var e = exp(-t * 5.0) * min(t / 0.015, 1.0)
					b[(i0 + i) % n] += sin(TAU * f * t) * 0.16 * e * (1.0 if bt % 2 == 0 else 0.5)
			# soft shaker on off-beats
			for st in 8:
				if st % 2 == 1:
					var t0 = bar * beat * 4.0 + st * beat * 0.5
					var i0 = int(t0 * MRATE)
					var y = 0.0
					for i in int(0.08 * MRATE):
						var t = float(i) / MRATE
						y += (rng.randf_range(-1.0, 1.0) - y) * 0.35
						b[(i0 + i) % n] += y * 0.05 * exp(-t * 40.0)
	else:
		for bar in bars:
			var ch = chords[bar % 4]
			for st in [0, 5]:
				var tone = ch[1 + (bar + st) % 4] + 24
				var t0 = bar * beat * 4.0 + st * beat * 0.5
				var f = _hz(tone)
				var i0 = int(t0 * MRATE)
				var len_ = int(1.6 * MRATE)
				for i in len_:
					var t = float(i) / MRATE
					var e = exp(-t * 2.2) * min(t / 0.006, 1.0)
					b[(i0 + i) % n] += (sin(TAU * f * t) + 0.15 * sin(TAU * f * 2.76 * t)) * 0.07 * e
	return _wav(b, true, MRATE)
