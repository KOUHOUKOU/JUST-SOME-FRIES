extends RefCounted
# Round 20: everything the big brother says on his roof (character notes: docs/55_BIG_BRO.md).
# A TALK is one short conversation (3-6 lines). Every visit gives ONE talk: the first one that the gull has earned and has not heard yet (a key talk: it happens once per save,
# GS.cine_seen remembers it), and when nothing new is left, E gives a small talk that fits how far the gull has come (never the same one twice in a row).
# Lines are plain English (they go through Loc.t); a line that starts with "Y|" is the little gull's, every other line is his.

const KEY = {
	# --- the ladder (by the number of fries): he starts short and cool, then warms up, and the gull starts to look like him
	"chat1": ["Saw you land. Clean. Not bad, kid.",
		"Fast beats strong. Strong beats loud.",
		"Go make the sky nervous. I'll be here. Looking expensive."],
	"chat2": ["Ten fries. You fly like you're late for something.",
		"I was fast like that once. Then I found accessories.",
		"...Hats are heavy. So is wanting things."],
	"chat3": ["Eighteen. Where do you think we're headed, kid?",
		"...Nineteen, I suppose. That's not a direction. That's arithmetic.",
		"Funny thing about having everything: it takes up room. In here.",
		"You've got the squint now. ...You're starting to look like me.",
		"Not sure that's a compliment. To either of us.",
		"Still hungry? ...Yeah. Me too."],
	"chat4": ["All twenty-four. The whole spectrum.",
		"I had them all, once. I could name every one in my sleep.",
		"Years of chasing magic fries. The fast ones. The shiny ones. The ones that sing.",
		"And somewhere in all that, I lost track of the first one. Where it was. What it tasted like.",
		"Y|...still hungry?",
		"Always. That's the trick of it.",
		"It never was the kind you can see on a plate."],
	# --- what the gull has done (each one once, in this order)
	"bro_hat": ["That hat. ...Where'd you find it?",
		"No. Don't tell me. A hat should keep its own story.",
		"Wear it low. The sun is rude up here."],
	"bro_drinks": ["You smell like a cafe, a bar and a freezer.",
		"...Respect.",
		"I never trusted a gull who couldn't hold a cocktail and a grudge at the same time."],
	"bro_fish": ["I smelled the sea on you.",
		"So it gave you something. It never gave me anything.",
		"...I never asked politely.",
		"Say thank you on your way out, kid. The water remembers manners."],
	"bro_starlight": ["That streak across the sky the other day. Every colour. Very loud.",
		"I used to leave one of those.",
		"People on the pier thought it was a plane.",
		"...It was me. Mostly."],
	"bro_friend": ["I saw a gull land next to you. Just to say hello.",
		"Do they do that now?",
		"In my day we ignored each other. Out of respect. And pride.",
		"And fear of the hat."],
	"bro_sky_cloud": ["You wore a cloud. ...How was it?",
		"Y|...soft.",
		"Soft. Yes. That's what I'd forgotten about the sky.",
		"Everybody looks up and sees height. Nobody mentions the cushions."],
	"bro_sky_raincloud": ["A rain cloud. Your own private weather.",
		"I had one of those, years ago. It only ever rained on my hat.",
		"...That's why the hat is waterproof. Mostly."],
	"bro_sky_star": ["A falling star. In your beak, no less.",
		"Did you wish?",
		"Y|...beak was full.",
		"Ha. Good. Wishes are for gulls with nothing in their beaks.",
		"I wished once. For a hat. ...Look how that went."],
	"bro_sky_moon": ["You caught the moon. I tried once. It laughed.",
		"I flew at it all night.",
		"By morning I was at the far end of the island and it was still up there. Calm as a plate.",
		"...Then it went and sat in your beak. Typical."],
	"bro_sky_sun": ["The sun. In a beak.",
		"Warm?",
		"Y|...warm.",
		"I held it for one second, once. It left a mark.",
		"...You think these shades are for show?"],
	"bro_sky_rainbow": ["Straight through a rainbow. Every colour there is, and none of them has a taste.",
		"Strange. You'd think they would.",
		"Y|...it tastes like a rainbow.",
		"...Fair."],
	"chat_sky": ["Cloud, star, sun, moon, rainbow. The whole sky.",
		"Nobody gets the whole sky. It's not that kind of thing.",
		"And you came back down to a roof.",
		"...Interesting."],
	# --- after the end
	"free_intro": ["...You're back. The fry is gone, and you're back.",
		"Good. The sky didn't get any smaller.",
		"Press E when you want company.",
		"I'll be here. Without the chain. ...Still looking expensive."],
}

# the order in which the key talks after the ladder are offered
const ORDER = ["bro_hat", "bro_drinks", "bro_fish", "bro_starlight", "bro_friend", "bro_sky_cloud", "bro_sky_raincloud", "bro_sky_star", "bro_sky_moon", "bro_sky_sun", "bro_sky_rainbow", "chat_sky"]
const SKY_TALKS = ["bro_sky_cloud", "bro_sky_raincloud", "bro_sky_star", "bro_sky_moon", "bro_sky_sun", "bro_sky_rainbow"]

# small talks: [fries 0-9, fries 10-17, fries 18+, after the end]
const SMALL = [
	[["Wind's good today.", "Don't waste it."],
	["Mind the old man's table.", "Not that he'd notice. ...Still."],
	["Start small. Work up.", "Everybody does. Even me."],
	["The sea looks flat from up here.", "...It isn't."],
	["Chin up, kid. Wings out.", "The rest is details."],
	["I don't give advice.", "...Land softer."]],
	[["Silver, gold, diamond. The shinier it is, the faster it runs.", "...Same as most things."],
	["The rings shrink when you're nervous.", "That's not a rule. I just noticed."],
	["Roofs are better for resting than trees.", "Roofs hold still. Trees gossip."],
	["Notice how a crowd watches your feet, not your face?", "Gulls and thieves, same rule: look innocent from the knees down."],
	["I had a rule once: never fly with a full beak and an empty head.", "...Broke it daily."],
	["The sky isn't empty.", "It's just quiet in places."]],
	[["You squint like me now. Did you notice?", "I'm not sure either of us should be proud."],
	["Late in the afternoon the whole pier goes the colour of a fry.", "...I didn't say that. Forget it."],
	["I knew a gull who only ever ate what fell. Never took a thing.", "I thought he was a fool.", "...He always looked fed."],
	["Everything I own, I wear.", "Funny. It's never the outside that feels heavy."],
	["I keep a list of everything I have.", "It's very long. There's a gap near the bottom where something used to be."],
	["Do you remember what the first one tasted like?", "Y|...warm.", "Warm. Yes.", "...That's how it starts."]],
	[["I went down to the cafe at dawn. Before the shutters.", "Stood where you stood. The stone is cold in the morning.", "...I'd forgotten that."],
	["That old man. Still drops them?", "Y|...every morning.", "Good."],
	["Salt. That's what I remember best now.", "Salt, and a small sound. tk."],
	["Funny. The hat is lighter.", "Same hat."],
	["Show me the squint properly.", "Y|...like this.", "Like this?", "Y|...no.", "...I'll practise."],
	["It was still warm when it got up here.", "...I think about that."],
	["Sit. The view's the same.", "The company isn't."]],
]

static var last_small = -1

# does the gull deserve this key talk?
static func eligible(id):
	var m = GS.memories
	match id:
		"bro_hat":
			return GS.worn.size() >= 1
		"bro_drinks":
			return m.has("coffee") or m.has("alcohol") or m.has("ice")
		"bro_fish":
			return m.has("fish") or not GS.fish_book.is_empty()
		"bro_starlight":
			return m.has("starlight")
		"bro_friend":
			return m.has("friend") or m.has("gift") or m.has("kid")
		"bro_sky_cloud":
			return m.has("sky_cloud") or m.has("cloud")
		"bro_sky_raincloud":
			return m.has("sky_raincloud") or m.has("raincloud")
		"bro_sky_star":
			return m.has("sky_star") or m.has("meteor")
		"bro_sky_moon":
			return m.has("sky_moon") or m.has("moon")
		"bro_sky_sun":
			return m.has("sky_sun") or m.has("sun")
		"bro_sky_rainbow":
			return m.has("sky_rainbow") or m.has("skybow")
		"chat_sky":
			if GS.sky_got.size() < 5:
				return false
			for s in SKY_TALKS:
				if eligible(s) and not GS.cine_seen.has(s):
					return false
			return true
	return false

# the talk for NOW ("" = nothing new): the ladder first (by the number of fries), then what the gull has done
static func next_talk(bro):
	if GS.free_play:
		return "" if GS.cine_seen.has("free_intro") else "free_intro"
	var c = bro._next_chat()
	if c != "":
		return c
	for id in ORDER:
		if not GS.cine_seen.has(id) and eligible(id):
			return id
	return ""

# a small talk that fits the gull's stage (never the same one twice in a row)
static func small_talk():
	var stage = 3 if GS.free_play else (0 if GS.fry_total() < 10 else (1 if GS.fry_total() < 18 else 2))
	var pool = SMALL[stage].duplicate()
	if stage == 3:
		pool.append_array(tips())
	var i = randi() % pool.size()
	if i == last_small:
		i = (i + 1) % pool.size()
	last_small = i
	return pool[i]

# the practical things he knows (after the end): what is still left to find, said his way
static func tips():
	var out = []
	var missing = GS.FRY_CAP - GS.fry_total()
	if missing > 0:
		out.append(["%d fries are still out there. I counted. I was bored." % missing, "Golds hide on roofs. Diamonds hide where you'd need a ladder, if you had one."])
	else:
		out.append(["All twenty-four. Show-off.", "Try the rainbow ones. They keep coming. Like regrets."])
	var nf = GS.fish_book.size()
	if nf < GS.FISH_ORDER.size():
		out.append(["%d kinds of fish so far. Nine exist." % nf, "Catch one and the sea wakes up. Then you can ride it. Space on the water, kid."])
	else:
		out.append(["All nine fish. The sea has stopped returning your calls.", "Five in one OCEAN TIME? Go on. I'll pretend not to watch."])
	if not GS.sky_got.has("sun") or not GS.sky_got.has("moon"):
		out.append(["Nine suns, they say. One of them is real.", "Nine rings per sun. Nine per moon. The sky is a strict teacher."])
	out.append(["%d of %d achievements." % [GS.ach_count(), GS.ACH.size()], "The rest are mostly things you do by accident. Or on purpose, if you're me."])
	out.append(["Squawk on a roof. F. They come. Don't ask me why.", "Squawk at a crowd that doesn't like you. ...Don't."])
	return out

static func lines(id):
	return KEY.get(id, [])
