# Round 16 - the last polish (2026-10-12)

The director's 12 points + the four-panel idea. Tests: `--r16a` (logic: breath, nine suns, quest board, FISH/RAINBOW priority, clocks, crowd, saves, reel), `--r16b` (sea: surf, launch, three fish rarities in the air, F on a roof / on the ground, rainbow rings), `--r16c` (the ending with reels + strip), `--r16d` (the opening strip), `--r16e` (the nine circles filmed), `--r16f` (KEEP PLAYING + the big brother), `--r16s` (the screenshots the strip was drawn from). Regression `--r7 --r12 --r15a --r15b --r15n --r15u --save` all pass. Test runs use `dev_savegame*.json` / `dev_mem`, never a player's files.

## 1  Every fry gives the whole breath back
`main._on_escaped` -> `player.refill()`. The first look through Gull Sight costs nothing (`GS.vision_cost()` is 0 until the TAB lesson is done), so TAB can never fail on an empty bar.

## 2  Nine suns, the moon, the rain cloud
* `snatch_controller`: tier 12 = SUN, 13 = MOON (nine circles x 2 waves = 18 judgements, a 3 x 3 square), RAIN CLOUD = tier 6 like the white cloud (it used to be a single circle). `hud.gd`: the sun's outer band is ORANGE, the moon's BLUE (gold inside, as always), the pips and shock rings follow.
* Bug found on the way (round 15): catching the cloud / sun / moon never ticked the SKY quest (`GS.sky_catch` was only called by shooting stars). `mischief.stolen` now calls it.
* Each sky thing has its own little show (`main._sky_show`, no camera games): sun = nine small golden rings one after the other; moon = a wide silver ring, falling moon-dust, a lullaby of chimes, a blue wash; rain cloud = a drizzle that follows the gull, a rumble, a flash; cloud = puffs; rainbow = seven rings.

## 3-4  FISH TIME (the sea)
* `GS`: every fish gives the whole breath and starts / tops up FISH TIME (22 s + 10 / 15 / 24 s per fish, cap 90, streak window 14 s). The fish book is no longer a quest.
* RAINBOW TIME vs FISH TIME: `GS.fish_mode()` = FISH TIME running AND the gull over the sea, less than 9 m above it (`sea_zone`, set by the player every frame, with hysteresis). In the sea the fish rules count, anywhere else the rainbow does; `star_active()` follows. Both clocks keep running.
* In the sea, in FISH TIME: flying costs nothing, +3 m/s top speed, x1.5 acceleration, wider bands, deep-ocean-blue stamina bar, blue bubbles and glow, its own music (`fish.ogg`). Touching the water is a SURF, not a crash: W builds speed (15 m/s, Shift 22), A/D steer; **Space = LAUNCH** (a 2-second burst, acceleration x7, the top speed stays the gull's own) at the fish.
* Frenzy (`fish_spot.gd`): spots within 150 m wake up (forecast 1 s, bubbles 1.1 s, a leap again 1-2 s after the last), up to 6 at once, and the director always asks for the rarity that is missing, so three rarities are in the air together. `FISH x3` pops up, a comic every third.
* Water ripples (`gull_player._ripple`): a pool of 26 flat rings. Paddling kicks a ring from each foot, the floating gull breathes a wide slow one, a surfing gull cuts a wake, landing / launching throw rings and spray.
* Music: `tools/audio/music16.py` renders "Row, Row, Row Your Boat" (public domain) as a sea-shanty jig round (tin whistle, fiddle, accordion, banjo enter two bars apart; keys C > D > E > D > C); 53 s loop. I cannot hear it: the user judges by ear.

## 5  F
`main._squawk_effects`. On a roof: `rest_events.call_flock` (4-5 gulls fly in, land or hover, hearts, leave after ~9 s; a little breath back; achievement). On the ground: every person within 16 m (max 3) answers (`ambient_npc.answer_call`): crowd watch < 1.6 = a hello with a heart (+1), >= 1.6 = a chase with a shout and the old grump swing (-1), who walks home afterwards. In the air: the old yell.

## 6  The worn rainbow
No arch on the body any more. `aura_fx`: while the gull flies, a small rainbow-coloured ring appears behind it every 2-3.6 s, grows a little, drifts after the gull and fades (fades out near the lens).

## 7  The crowd forgets
`GS.mark_steal()` on every theft. After 8 s without one the watching crowd's share fades to zero over 4 s and the memory of the thief melts at 14x; the watch stays down until the next theft (so nothing hostile, which needs watch >= 1.6, happens early).

## 8-9  Pictures (Codex image generation, hand-inked, the SAME faceted gull as the game)
First attempt (a round doodle gull) was thrown away: the gull must be the game's gull. `art_src/r16/model_sheet.png` is drawn from the cover + three in-game screenshots (angular low-poly white gull, slate wing tops, golden beak, dot eyes) in flat hand-inked comic style; every later sheet takes it as the anchor. Cut by `tools/cut_r16.py` (+ `cut_r16_icons.py`): 27 old comic panels redrawn + 9 new (fish time, fish combo, F on a roof / hello / shoo, TAB lesson, roof rest, big-bro talk, free play); game icon (`game/icon.png`, window icon at run time, web favicon); a plain fry + seven coloured fry cartons (`assets/ui/art/`, not used in the UI yet); 30 achievement icons redrawn (29 achievements + a lock). Prompts: `art_src/r16/make_prompts.py`, `sheet_f.txt`, `sheet_g.txt`.

## 10  The ending's memories are real
`systems/memory_reel.gd`: the first time a memory happens (coffee, fish, the moon...) the game keeps 6 small square frames of the picture (per slot, `user://mem/slotN/`). The ending's polaroids play those frames as little films (film-strip holes on the sides); old saves without frames keep the drawn icons. The gull is centred in every memory shot (`side: 0`), the cards sit left and right.

## 11  Clocks
`GS._process` drains drinks / RAINBOW TIME / FISH TIME by GAME time (TAB's slow motion and the grab's bullet time slow them) and not at all while `GS.cutscene` (film moments, the story, the ending, the opening).

## 12  After the end
Two save slots (`GS.slot`, files `savegame.json` = slot 1, `savegame2.json`). START and CONTINUE open a slot screen (cards with fries / time / fish kinds / "THE END, AND KEEP PLAYING"); a filled slot asks twice before it is erased. The ending writes the run as a "free" save (`write_end_save`); at the credits HOLD E = KEEP PLAYING (reload straight into the slot, web via sessionStorage), ESC = menu. In free play the plain fry stays eaten, the gull wakes on the big brother's roof, he says hello, and E next to him gives a short talk that depends on what is left (fries, fish, the nine suns, achievements, the F trick). 5 new achievements (fish streak of 5, the flock, hello, indoor voice, one more lap).

## 13  The four-panel strip = False Knees #319, "What Fries Ahead" (a tribute)
Joshua Barkman's web comic *False Knees* #319 (2018): a young gull asks the old, richly dressed gull where he is headed; "I was going to get some fries, down at the pier"; "No. Big picture. I've got the chain, the hat, the coat, everything. So where does it end?"; "...Same." "It did. It had something to do with the fries." The game IS that question: the player chases collections and forgets the first, plain wish. The credits thank the comic by name.
* `ui/yonkoma.gd` + `assets/ui/yonkoma/` (`p1..p4` ending strip, `o1..o4` opening page; Codex redrew the panels with the game's own gulls, same camera angles).
* OPENING (about 8 s): the game picture on the big brother's roof shrinks onto a paper 2x2 page, the four panels ink in with typed speech bubbles (WHERE DO YOU THINK WE'RE HEADED? / I WAS GOING TO GO GET SOME FRIES. DOWN AT THE PIER. / NO. BIG PICTURE... SO WHERE DOES IT END?), the page opens back into the game. The player is the little gull who forgot the fries.
* ENDING: after the bro talk ("nothing shiny. nothing fast.", "just a fry, and somebody to eat it with.") the last picture of the game shrinks into slot 4 of the same page, panels 1-3 are inked (echo of the opening), panel 4 is inked OVER the live picture (the game turns into the comic) with the answer bubbles "...SAME." / "IT DID. IT HAD SOMETHING TO DO WITH THE FRIES.", zooms to full, black, credits.
* In between, never preached: the hunger whispers (HUD / main HUNGER arrays), big-bro lines at 18 and 24 fries, the 24/24 film ("so where does the path end?", "i think it has something to do with the fries.") only ask the question.
* Dev runs skip the comic (`autotest`), `--r16c` plays the ending page, `--r16d` the opening.

## 14  Round 16, second pass (the director's five points)
1. **Stuck in the water**: under piers / marina decks / overhanging cliffs the gull could not take off (the take-off crashed into the roof). `_pop_to_open_water()` slips it to the nearest open water (rays up and sideways), `water_grace` 1.8 s makes the take-off unhurtable, plus vert_boost 9, FOV kick, a splash column and ripples (the "launch" look). Tested on a grid: `--r16g` 163 shore points, 0 stuck. Floating restores breath; in FISH TIME surfing keeps breath full, and Space launches straight to `max(boost_speed, speed+7)`, also during TAB slow motion.
2. **Melodies**: `snatch_controller.TUNES`: 5-circle fries 10 notes, rainbow 14, sun / moon 18 (judged by ear; a gold judgement plays two notes).
3. **Sky catches have their words and white space again**: `SKY_FLOW` + `_cine_sky` (cloud, raincloud, moon, sun, rainbow, star): a big comic word, a typed thought of 4 lines on a thin band, a prop that flies in, calm music; the central "BELOW" picture of the 24/24 film is gone (words only; `_cine_all24`). Layout fix this pass: word higher (y 0.18, smaller), thought band at 0.43. Once per run for each thing; the gull keeps flying afterwards.
4. **The pillar and the bite scene**: `cine_cam.POSTS` lists posts without collision (cafe porch columns, umbrella poles); `clear()` tests them first. The bite is lettered in comic words: CHOMP! / NOM NOM! / MMMMF.
5. Tribute and the existential thread: section 13.

Tests: `--r16a b c d e f g`, `--r9cine --only=cloud,raincloud,moon,sun,skybow,meteor,all24`, `--r7 --r12 --save --r15a b n u --r9sky` all PASS.
Test runs now put the Godot window far off screen (`--position -30000,-30000`, minimised, below normal priority) so they never cover another game.

## Numbers
FISH_FIRST_SEC 22, FISH_ADD 10 / 15 / 24, FISH_CAP 90, FISH_TOP 3, SEA_ZONE_H 9, SURF 15 / 22 m/s, launch 2 s x7, IDLE_CALM 8 s, SUN_CIRCLES 9, MOON_NEED = SUN_NEED = 244.

## 15  The new walkthrough (3 min 18 s)
`--film --seg=N` segments (autotest.gd `film_seg*`): 1 cover + comic opening, 2 first fry + Gull Sight, 3 RAINBOW TIME + falling star, 11 FISH TIME (catch, surf, launch), 12 moon / sun / rainbow fry, 13 the dressed-up gull on the roof (flock, 24/24), 14 the ending (memory reels, comic page, credits). Record with `python -I tools/film/record_all.py --only=11,12 --no-promo` (the window is placed far off screen, below-normal priority), cut with `python tools/film/make_promo16.py` (edge-tts voice Andrew, burned-in subtitles, end card with the False Knees credit). Outputs: film/promo.mp4 -> submission/JustSomeFries_walkthrough.mp4 and docs/walkthrough.mp4 (41 MB), the 8.8 MB form version, the .srt.
