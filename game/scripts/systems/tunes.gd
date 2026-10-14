extends RefCounted
# ROUND 18: THE TUNES OF THE JUDGEMENTS.
# Every good press in a catch plays the next note of a little tune, so a catch is a melody the player plays with E. Each kind of catch has its own family of tunes and its own
# instrument; the tune is picked at random every time (a different SEGMENT of a different song: where in the song it starts is random too, always at the start of a phrase),
# so no two catches of a fry sound alike. The songs are gentle, not fast and all in the public domain (traditional or composed before 1900); they are written as phrases of
# MIDI notes in C major / A minor, and a segment is a run of whole phrases cut to the number of judgements and resolved onto a note of the tonic chord.
#   things, drinks, the three starter fries   kalimba      Frere Jacques, Twinkle, Row Your Boat
#   silver fries                              music box    Brahms' Lullaby, Twinkle, Frere Jacques
#   gold fries                                harp         Greensleeves, Amazing Grace, Auld Lang Syne, Sakura, the Lullaby
#   diamond fries                             celesta      Pachelbel's Canon, Greensleeves, Morning Mood, Auld Lang Syne
#   rainbow fries                             glockenspiel a harp-like climb of thirds up the C major scale: seven circles = the seven colours
#   fish                                      marimba      Row Your Boat, Frere Jacques, Sakura
#   the sky                                   harp + pad   cloud: Canon / Amazing Grace; rain cloud: Greensleeves; sun: Morning Mood; moon: the Lullaby; star: Twinkle; rainbow: the climb
# ROUND 18b: brighter and more playful. Every note has a 'ting' of tinkle bells an octave up on top of it, the families of the small fries (things, silver, fish) sing an octave higher,
# a gold press (two points) is two notes a skip apart followed by a little upward run of bells, and in HARD (`single`) the tune plays by itself on the beats (`beat`, quiet) while a
# hit adds a bright voice on top of its beat (`hit`, louder and brighter the longer the streak).
# (the samples: tools/audio/r18_audio.py, played by audio_manager.gd play_note)

const SCALE = [60, 62, 64, 65, 67, 69, 71, 72, 74, 76, 77, 79, 81, 83, 84]
const STABLE = [60, 64, 67, 72, 76, 79, 84, 57, 69]      # the notes of the tonic chords (C, E, G and A): a tune ends on one of them

# the phrases of every song
const SONGS = {
	"twinkle": [[60, 60, 67, 67, 69, 69, 67], [65, 65, 64, 64, 62, 62, 60], [67, 67, 65, 65, 64, 64, 62], [67, 67, 65, 65, 64, 64, 62], [60, 60, 67, 67, 69, 69, 67], [65, 65, 64, 64, 62, 62, 60]],
	"ode": [[64, 64, 65, 67], [67, 65, 64, 62], [60, 60, 62, 64], [64, 62, 62], [64, 64, 65, 67], [67, 65, 64, 62], [60, 60, 62, 64], [62, 60, 60]],
	"lullaby": [[64, 64, 67], [64, 64, 67], [64, 67, 72, 71, 69, 69, 67], [62, 64, 65, 62, 62, 64, 65], [62, 65, 71, 69, 67, 71, 72]],
	"jacques": [[60, 62, 64, 60], [60, 62, 64, 60], [64, 65, 67], [64, 65, 67], [67, 69, 67, 65, 64, 60], [67, 69, 67, 65, 64, 60], [60, 55, 60], [60, 55, 60]],
	"row": [[60, 60, 60, 62, 64], [64, 62, 64, 65, 67], [72, 72, 72, 67, 67, 67, 64, 64, 64, 60, 60, 60], [67, 65, 64, 62, 60]],
	"greensleeves": [[69, 72, 74], [76, 77, 76], [74, 71, 67], [69, 71, 72], [69, 69, 68, 69], [71, 68, 64], [69, 72, 74], [76, 77, 76], [74, 71, 67], [69, 71, 72], [71, 69, 68, 66], [68, 69]],
	"amazing": [[67, 72, 76, 72, 76, 74, 72, 69, 67], [67, 72, 76, 72, 76, 74, 79], [79, 76, 79, 76, 72, 74, 72, 69, 67], [67, 72, 76, 72, 76, 74, 72]],
	"auld": [[67, 72, 72, 72, 76], [74, 72, 74, 76], [72, 72, 76, 79], [81], [79, 76, 76, 72, 74, 72, 74, 76, 72, 69, 69, 67]],
	"sakura": [[69, 69, 71], [69, 69, 71], [69, 71, 72, 71, 69, 71, 69, 65, 64], [69, 69, 71], [69, 69, 71], [69, 71, 72, 71, 69, 71, 69, 65, 64]],
	"canon": [[76, 74, 72, 71, 69, 67, 69, 71], [72, 71, 69, 67, 65, 64, 65, 67], [64, 67, 69, 71, 72, 76, 74, 72], [71, 69, 71, 72, 69, 67, 65, 64]],
	"morning": [[67, 64, 62, 64, 67, 64, 62, 64], [67, 64, 62, 64, 67, 69, 67, 64], [62, 64, 67, 69, 72, 69, 67, 64], [62, 64, 67, 64, 62, 60, 62, 64]],
}

# what each family may pick: song names, the instrument, whether a soft pad swells under every fourth note
const FAMILIES = {
	"things": {"songs": ["jacques", "twinkle", "row"], "inst": "kalimba", "pad": false},
	"silver": {"songs": ["lullaby", "twinkle", "jacques"], "inst": "musicbox", "pad": false},
	"gold": {"songs": ["greensleeves", "amazing", "auld", "sakura", "lullaby"], "inst": "harp", "pad": false},
	"diamond": {"songs": ["canon", "greensleeves", "morning", "auld"], "inst": "celesta", "pad": true},
	"rb": {"songs": [], "inst": "glock", "pad": false},
	"fish": {"songs": ["row", "jacques", "sakura"], "inst": "marimba", "pad": false},
	"cloud": {"songs": ["canon", "amazing"], "inst": "harp", "pad": true},
	"raincloud": {"songs": ["greensleeves"], "inst": "harp", "pad": true},
	"sun": {"songs": ["morning"], "inst": "harp", "pad": true},
	"moon": {"songs": ["lullaby"], "inst": "celesta", "pad": true},
	"star": {"songs": ["twinkle"], "inst": "celesta", "pad": true},
	"skybow": {"songs": [], "inst": "harp", "pad": true},
}

const LIFT = {"things": 12, "silver": 12, "fish": 12}      # these families sing an octave higher (the small fries are the cheerful ones)
const PENT = [0, 2, 4, 7, 9]                               # the C major / A minor pentatonic: every bell run is built on it and always agrees with the songs
static var last_song = ""

static func family_of(tier, cls, key):
	if cls == "sky":
		match key:
			"cloud", "raincloud", "sun", "moon", "skybow":
				return key
			"meteor":
				return "star"
		return "cloud"
	if cls == "fish":
		return "fish"
	if cls == "rb":
		return "rb"
	match tier:
		1:
			return "silver"
		2:
			return "gold"
		3:
			return "diamond"
	return "things"

# a rising run of broken chords up the scale: the rainbow. `w` notes for every colour (2 = a third, 3 = a whole triad)
static func rainbow(circles, w):
	var out = []
	for k in circles:
		for j in w:
			out.append(SCALE[k + 2 * j])
	return out

# a segment of a song: whole phrases from a random phrase on, cut to n notes
static func segment(song, n):
	var ph = SONGS[song]
	var start = randi() % max(ph.size() - 1, 1)
	var out = []
	var i = start
	var guard = 0
	while out.size() < n and guard < 80:
		out.append_array(ph[i % ph.size()])
		i += 1
		guard += 1
		if i % ph.size() == 0 and out.size() < n:
			# the song has been sung to the end: sing the last phrases again an octave higher
			for q in ph.size():
				for m in ph[q]:
					out.append(m + 12 if m + 12 <= 88 else m)
				if out.size() >= n:
					break
	out = out.slice(0, n)
	return out

static func resolve(notes):
	if notes.is_empty():
		return notes
	var last = notes[notes.size() - 1]
	var best = last
	var bd = 99
	for s in STABLE:
		var d = abs(s - last)
		if d < bd:
			bd = d
			best = s
	notes[notes.size() - 1] = best
	return notes

# the tune of one catch: {"name", "inst", "pad", "notes": [n midi notes]}
static func pick(tier, n, cls, key = ""):
	var fam = family_of(tier, cls, key)
	var f = FAMILIES[fam]
	var notes = []
	var name = "climb"
	if f["songs"].is_empty():
		var w = max(int(round(float(n) / 7.0)), 1)
		var circles = max(int(round(float(n) / w)), 1)
		notes = rainbow(min(circles, 8), w)
		while notes.size() < n:
			notes.append(notes[notes.size() - 1])
		notes = notes.slice(0, n)
	else:
		var songs = f["songs"].duplicate()
		if songs.size() > 1 and songs.has(last_song):
			songs.erase(last_song)
		name = songs[randi() % songs.size()]
		last_song = name
		notes = segment(name, n)
	notes = resolve(notes)
	return {"name": name, "inst": f["inst"], "pad": f["pad"], "notes": notes, "n": n, "lift": LIFT.get(fam, 0)}

# the pitch of note i (lifted for the cheerful families, never above the top of the bank)
static func note_of(tune, i):
	var notes = tune["notes"]
	var m = notes[clamp(i, 0, notes.size() - 1)] + int(tune.get("lift", 0))
	while m > 96:
		m -= 12
	return m

# `k` steps up the pentatonic scale from m
static func up_pent(m, k):
	var cur = m
	var left = k
	while left > 0 and cur < 110:
		cur += 1
		if (cur % 12) in PENT:
			left -= 1
	return cur

static func _bank_top(m):
	return m if m <= 100 else m - 12

# play note i: the voice of the family with a bright 'ting' on top (a gold press: with a glockenspiel sparkle as well)
static func play(tune, i, gold = false, extra_db = 0.0):
	if tune == null or tune["notes"].is_empty():
		return
	var m = note_of(tune, i)
	Sfx.play_note(tune["inst"], m, -2.0 + extra_db)
	Sfx.play_note("tinkle", _bank_top(m + 12), -11.0 + extra_db)
	if gold:
		Sfx.play_note("glock", _bank_top(m + 12), -8.0 + extra_db)
	if tune["pad"] and i % 4 == 0:
		Sfx.play_note("pad", m, -19.0 + extra_db)

# a gold press (EASY): two notes of the tune a skip apart, then a little upward run of bells that dies away: the 'yes!' of the game
static func gold(tune, i0):
	if tune == null or tune["notes"].is_empty():
		return
	play(tune, i0, true)
	var tree = Engine.get_main_loop()
	if tree == null:
		return
	tree.create_timer(0.07, true, false, true).timeout.connect(func(): play(tune, i0 + 1, false, 0.5))
	var top = _bank_top(note_of(tune, i0 + 1) + 12)
	for k in 3:
		tree.create_timer(0.13 + 0.055 * k, true, false, true).timeout.connect(func(): Sfx.play_note("tinkle", _bank_top(up_pent(top, 1 + k)), -12.0 - 1.5 * k))

# HARD: the music plays by itself. Beat i of the tune, quietly (a missed beat still sounds, it just does not shine)
static func beat(tune, i):
	if tune == null or tune["notes"].is_empty():
		return
	var m = note_of(tune, i)
	Sfx.play_note(tune["inst"], m, -8.0)
	if tune["pad"] and i % 4 == 0:
		Sfx.play_note("pad", m, -21.0)

# HARD: a hit on beat i. A bright voice on top of the beat, louder and shinier with the streak
static func hit(tune, i, combo = 1):
	if tune == null or tune["notes"].is_empty():
		return
	var m = note_of(tune, i)
	var up = 0.35 * min(combo, 8)
	Sfx.play_note("xylo", _bank_top(m + 12), -7.0 + up)
	Sfx.play_note("tinkle", _bank_top(m + 12), -9.0 + up)
	Sfx.play_note(tune["inst"], m, -3.0 + up)
	if combo >= 3 and combo % 2 == 1:
		Sfx.play_note("glock", _bank_top(up_pent(m + 12, 2)), -10.0 + up)
