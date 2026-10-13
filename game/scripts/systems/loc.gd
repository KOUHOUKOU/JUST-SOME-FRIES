class_name Loc
extends RefCounted
# Languages (round 17): English, Simplified Chinese, Traditional Chinese, Japanese.
# English stays the source text everywhere in the code. Every string that reaches the screen is looked up by its English text in
# res://assets/i18n/strings.json ({"english": {"zh_CN": .., "zh_TW": .., "ja": ..}}).
#   - Labels / Buttons / Label3D: through LocTr, a Translation the engine asks for every Control text (auto-translation).
#   - drawn text (draw_string and friends): the call sites pass the text through Loc.t().
# Lines with numbers or names in them are templates: the key is the format string of the code ("SLOT %d"), the translation
# uses {0} {1} .. for the values in order ("存档 {0}"); %s values are translated themselves (fry names, colours ...).
# Unknown text is shown as it is (English), so a missed line never breaks anything.

const LANGS = ["en", "zh_CN", "zh_TW", "ja"]
const NAMES = {"en": "English", "zh_CN": "简体中文", "zh_TW": "繁體中文", "ja": "日本語"}
const DATA = "res://assets/i18n/strings.json"
const CFG = "user://language.cfg"

static var lang = "en"
static var cjk = false
static var table = {}            # english -> current language
static var folded = {}           # english.to_lower() -> current language (for names shown in lower case, etc.)
static var templates = []        # [RegEx, translation, kinds]
static var cache = {}
static var raw = {}
static var loaded = false
static var tr_res = null
static var record = false        # dev: --loc-log writes every looked-up string that has no translation
static var misses = {}
static var fonts = {}

class LocTr extends Translation:
	func _get_message(src_message, _context = &""):
		var s = String(src_message)
		var r = Loc.t(s)
		return StringName(r) if r != s else &""

static func _load():
	if loaded:
		return
	loaded = true
	var f = FileAccess.open(DATA, FileAccess.READ)
	if f == null:
		push_warning("Loc: no " + DATA)
		return
	var j = JSON.parse_string(f.get_as_text())
	if j is Dictionary:
		raw = j

static func saved_lang():
	var c = ConfigFile.new()
	if c.load(CFG) == OK:
		var l = String(c.get_value("ui", "lang", ""))
		if l in LANGS:
			return l
	return ""

static func has_saved():
	return saved_lang() != ""

static func save_lang():
	var c = ConfigFile.new()
	c.set_value("ui", "lang", lang)
	c.save(CFG)

# the language the player had last time, else the system language (or English)
static func guess():
	var s = saved_lang()
	if s != "":
		return s
	var os = OS.get_locale()
	if os.begins_with("ja"):
		return "ja"
	if os.begins_with("zh"):
		return "zh_TW" if (os.contains("TW") or os.contains("HK") or os.contains("MO") or os.contains("Hant")) else "zh_CN"
	return "en"

static func set_lang(l):
	_load()
	if not (l in LANGS) and not (l == "xx" and record):
		l = "en"
	lang = l
	cjk = l != "en"           # "xx" (dev, with --loc-log): no table at all, every shown string is written down
	table = {}
	folded = {}
	templates = []
	cache = {}
	var spec = RegEx.create_from_string("%(-?0?\\d*)(\\.\\d+)?([dfis%])")
	if cjk:
		var tl = []
		for k in raw.keys():
			var v = raw[k]
			if not (v is Dictionary) or not v.has(l) or String(v[l]) == "":
				continue
			var val = String(v[l])
			if spec.search(k) != null and k.find("%") >= 0 and _is_template(k):
				tl.append([k, val])
			else:
				table[k] = val
				folded[k.to_lower()] = val
		# longer templates (more fixed text) first
		tl.sort_custom(func(a, b): return _fixed_len(a[0]) > _fixed_len(b[0]))
		for p in tl:
			var c = _compile(p[0])
			if c != null:
				templates.append([c[0], p[1], c[1]])
	_apply_fonts()
	if tr_res == null:
		tr_res = LocTr.new()
		TranslationServer.add_translation(tr_res)
	tr_res.locale = l if cjk else "zz"
	TranslationServer.set_locale(l if cjk else "en")

static func _is_template(k):
	var r = RegEx.create_from_string("%(-?0?\\d*)(\\.\\d+)?([dfis])")
	return r.search(k) != null

static func _fixed_len(k):
	var r = RegEx.create_from_string("%(-?0?\\d*)(\\.\\d+)?([dfis%])")
	return r.sub(k, "", true).length()

static func _compile(k):
	var spec = RegEx.create_from_string("%(-?0?\\d*)(\\.\\d+)?([dfis%])")
	var pat = "^"
	var kinds = []
	var pos = 0
	for m in spec.search_all(k):
		pat += _esc(k.substr(pos, m.get_start() - pos))
		var c = m.get_string(3)
		if c == "%":
			pat += "%"
		elif c == "d" or c == "i":
			pat += "\\s*(-?\\d+)"
			kinds.append("n")
		elif c == "f":
			pat += "\\s*(-?\\d+(?:\\.\\d+)?)"
			kinds.append("n")
		else:
			pat += "(.+?)"
			kinds.append("s")
		pos = m.get_end()
	pat += _esc(k.substr(pos)) + "$"
	var re = RegEx.new()
	if re.compile(pat) != OK:
		return null
	return [re, kinds]

static func _esc(s):
	var o = ""
	for ch in s:
		if "\\^$.|?*+()[]{}/".contains(ch):
			o += "\\" + ch
		elif ch == "\n":
			o += "\\n"
		else:
			o += ch
	return o

# the text in the current language (English when there is none)
static func t(s):
	if not cjk:
		return s
	if not (s is String):
		if s is StringName:
			s = String(s)
		else:
			return s
	if s == "":
		return s
	if cache.has(s):
		return cache[s]
	var r = _lookup(s, 0)
	if cache.size() > 6000:
		cache.clear()
	cache[s] = r
	return r

static func _lookup(s, depth):
	if table.has(s):
		return table[s]
	if depth > 3 or not _has_latin(s):
		return s
	# keep surrounding spaces / dots the code adds
	var core = s.strip_edges()
	if core != s and core != "":
		var r0 = _lookup(core, depth + 1)
		if r0 != core:
			var lead = s.substr(0, s.find(core))
			return lead + r0 + s.substr(lead.length() + core.length())
	for tp in templates:
		var m = tp[0].search(s)
		if m != null:
			var args = []
			for i in tp[2].size():
				var g = m.get_string(i + 1)
				args.append(_lookup(g, depth + 1) if tp[2][i] == "s" else g)
			return String(tp[1]).format(args)
	if s.contains("\n"):
		var parts = s.split("\n")
		var outp = []
		var any = false
		for p in parts:
			var tpp = _lookup(p, depth + 1)
			any = any or tpp != p
			outp.append(tpp)
		if any:
			return "\n".join(outp)
	if s.contains("|"):
		var parts2 = s.split("|")
		var out2 = []
		var any2 = false
		for p in parts2:
			var tp2 = _lookup(p, depth + 1)
			any2 = any2 or tp2 != p
			out2.append(tp2)
		if any2:
			return "|".join(out2)
	var low = s.to_lower()
	if folded.has(low):
		return folded[low]
	if record:
		misses[s] = true
	return s

static func _has_latin(s):
	for ch in s:
		var c = ch.unicode_at(0)
		if (c >= 65 and c <= 90) or (c >= 97 and c <= 122):
			return true
	return false

# a list of lines in the current language
static func ta(arr):
	if not cjk:
		return arr
	var o = []
	for x in arr:
		o.append(t(x))
	return o

# how long a line "feels" for reading-speed timers: a Chinese / Japanese character is about two and a half English letters
static func read_len(s):
	return int(String(s).length() * (2.6 if cjk else 1.0))

# typing speed in characters per second for the typewriter
static func cps(c):
	return c * 0.42 if cjk else c

# ---- word wrap that also breaks Chinese / Japanese between characters (never before a closing mark)
const NO_START = "，。、！？：；）」』】〉》…ー・,.!?:;)]}~～ぁぃぅぇぉっゃゅょァィゥェォッャュョ"

static func _is_wide(ch):
	var c = ch.unicode_at(0)
	return (c >= 0x2E80 and c <= 0x9FFF) or (c >= 0xF900 and c <= 0xFAFF) or (c >= 0xFF00 and c <= 0xFFEF) or (c >= 0x3000 and c <= 0x30FF)

# splits a paragraph into pieces that can be put on a line; returns [[piece, needs_space_before]]
static func _tokens(para):
	var out = []
	var cur = ""
	var space = false
	for ch in para:
		if ch == " ":
			if cur != "":
				out.append([cur, space])
				cur = ""
			space = true
			continue
		if _is_wide(ch):
			if NO_START.contains(ch) and (cur != "" or not out.is_empty()):
				if cur != "":
					cur += ch
				else:
					out[out.size() - 1][0] += ch
				continue
			if cur != "":
				out.append([cur, space])
				space = false
			cur = ch
			out.append([cur, space])
			cur = ""
			space = false
		else:
			if cur != "" and _is_wide(cur[cur.length() - 1]):
				out.append([cur, space])
				space = false
				cur = ""
			cur += ch
	if cur != "":
		out.append([cur, space])
	return out

static func wrap(text, f, fs, maxw):
	var out = []
	for para in String(text).split("\n"):
		var cur = ""
		for tk in _tokens(para):
			var w = tk[0]
			var test = w if cur == "" else (cur + (" " if tk[1] else "") + w)
			if cur != "" and f.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > maxw:
				out.append(cur)
				cur = w
			else:
				cur = test
		out.append(cur)
	return out

# ---- fonts: the engine font has no Chinese / Japanese letters, so two small subset fonts (Noto Sans SC / JP, SIL OFL) are added
# as fallbacks; the order picks the right letter shapes for Japanese.
static func _font(name):
	if not fonts.has(name):
		var p = "res://assets/fonts/%s.ttf" % name
		fonts[name] = load(p) if ResourceLoader.exists(p) else null
	return fonts[name]

static func _apply_fonts():
	var base = ThemeDB.fallback_font
	if base == null:
		return
	var sc = _font("jsf_sc")
	var jp = _font("jsf_jp")
	var fb = []
	for f in ([jp, sc] if lang == "ja" else [sc, jp]):
		if f != null:
			fb.append(f)
	base.fallbacks = fb

static func dump_misses(path):
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	var ks = misses.keys()
	ks.sort()
	for k in ks:
		f.store_line(JSON.stringify(k))
