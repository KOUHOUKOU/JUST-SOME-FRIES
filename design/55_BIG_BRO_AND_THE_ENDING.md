# Round 20b - the big brother, the ending, hold E, the launch camera

## 1. Hold E fast-forwards (instead of keys that skip)
* Credits roll and the ending cards (`ui/title_cards.gd`): HOLD E = 4x speed, let go = normal; no key skips them any more (Enter and every other key are swallowed). At the end of the roll
  "HOLD E - KEEP PLAYING / ESC - menu" is as before; a key that is still down from the fast-forward does not count as "keep playing".
* The talk of the ending (`ui/story.gd`, `ff_ok` set by `scenes.ending`): HOLD E = typing, reading time and waits run 4x. (It is off in the opening and in the roof talks.)

## 2. The ocean launch jitter (TAB lock + Space, world at x0.3)
Measured with `--r20j` (camera step per rendered frame, sampled at `frame_pre_draw`): the gull and the camera rig were smooth; the **spring arm** was not. SpringArm3D tests collisions once per
*physics* tick, which in the slow motion of TAB is only ~18 times a second, while the rig moves every frame; right after a launch (camera low behind the gull, the camera-only floor just above
the sea) the arm length jumped between 2 and 6 m. Fixes (`player/gull_player.gd update_camera`): the camera sits at a smoothed arm length in real time (a wall pulls it in fast, it
comes back out gently), `fov_kick` and `shake` die away in real time (they used to last 3x longer in slow motion). Result: camera 2nd-difference mean 0.044 -> 0.014, worst jump 1.8 -> 0.5 m.

## 3. The big brother
Notes (the character that the lines are written from):
* **BIG BRO.** Twice a gull's size, top hat, shades, gold chain, an unlit pipe, a long coat with a pocket he has never used. Once the fastest gull on the pier. Then he started collecting:
  everything on him is something he took or that took him (the hat blew in "like an invitation"; the shades because "the sun got polite"). He has everything and is hungry anyway.
* **Voice.** Short sentences, dry, understatement, never says "I miss" or "I'm lonely": feelings come out as objects (weight, room, a gap on a list, a hat). Cool at first, not cold;
  he calls the gull "kid"; as the gull gets further he talks more, jokes more, and starts to notice that it looks like him (the squint); late he is confiding.
* **What he lost** is not the fry but the *first* fry: where it was, what it tasted like. He still remembers its colour, its warmth, and the small sound it made on the stone (tk). He never says so
  outright before the end: "I lost track of the first one" is as close as he gets.
* **Motifs** that come back: *warm*, *salt*, *tk*, the hat, "same", "looking expensive", the old man at the cafe.

Talks (`ui/bro_talks.gd`, text lives there): every visit gives ONE talk. Next to him (or by pressing E next to him, any time after the three first fries) the game plays the first **key talk** the gull
has earned and not heard (saved in `GS.cine_seen`), otherwise a **small talk** for its stage (0-9 fries, 10-17, 18+, after the end; never the same twice in a row).
An automatic talk needs a new visit (the gull must have gone >14 m away since the last one); E can always ask. No floating line over a talk.

| order | talk | when |
|---|---|---|
| 1-4 | chat1..chat4 | 3 / 10 / 18 / 24 fries (a late gull hears the newest, the older count as heard). chat3: "you're starting to look like me". chat4: the first fry lost, nothing like "go look at the table" |
| 5 | bro_hat | first accessory |
| 6 | bro_drinks | coffee / cocktail / ice cream |
| 7 | bro_fish | first fish |
| 8 | bro_starlight | RAINBOW TIME |
| 9 | bro_friend | a gull landed next to you / a gift / a kind child |
| 10-15 | bro_sky_cloud / raincloud / star / moon / sun / rainbow | one talk for each thing of the sky the gull has caught (praise, a joke, a memory) |
| 16 | chat_sky | all five, after their own talks |
| after the end | free_intro, then small talks (warm, with memories; plus his practical tips) | |

After the end he sits without the shades and without the chain (`main._free_play_start`); the hat stays.

## 4. The ending (the roof) - rewritten (`ui/story_scenes.gd ending`)
Beat sheet; the idea is that he is moved by something small and never says so, and that "same" (his answer to the question he asked in the opening) lands where the comic expects it.
1. The little gull lands, still dressed. *"...That's a lot of hats, kid." / "I'd know."*
2. It puts the fry between them. *"...What's that." - "...it's just a fry." - "It doesn't glow. It doesn't make you fast. ...It doesn't do anything." - "...just some fries."*
3. Everything it wore falls away. His answer: *"...same."* Then, looking at his own coat: *"Mine took years to put on. I never tried the other direction."*
4. The shades come off (his eyes, first time). *"...It's the colour I remembered." "You carried it all the way up here." "...It's still warm."* (the gratitude, as a fact about temperature)
5. He eats it. *"...Oh." "Salt." "I'd forgotten it was this small."* - *"...yeah."*
6. They sit facing the sea (calm surf under it). He takes off the chain; nobody asked him to. *"I'm keeping the hat." - "...good hat." - "...It is a good hat."*
7. *"That old man. Does he still drop them?" - "...every morning." (tk, far below) - "...Good."* Captions, then the last comic panel and the credits as before.

All new lines: `tools/i18n/gen_r20b.py` (zh_CN, ja by hand; zh_TW from a vetted character table) -> `tr_zz_r20b.py` -> `build.py`. Tests: `--r20t` (which talk when, translations), `--r20s` (screenshots of a talk), `--r20j` (the launch).
