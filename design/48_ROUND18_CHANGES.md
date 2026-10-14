# Round 18 - the first outside players (2026-10-14)

The first people who were not us played the game and were unhappy: nobody knew how to get a fry, the breath ran out, TAB cost breath, the white circle arrived before anyone saw it,
the town hit back for nothing, the board did not say what to do. We had been playing for so long that we had mistaken our own skill for a difficulty curve.
This round fixes the first ten minutes and adds two ways to play. Everything below is in the build.

Tests: `--r18a` (the numbers), `--r18b` (play: a bump, the U-turn, TAB locking a fry), `--r18v` (screens), `--r18m` (menus), `--r18n` (a clumsy bot must get the three starter fries).
`--easy` / `--hard` give any other dev mode that difficulty (dev runs are "classic" = the round 17 numbers, so every older bot keeps its meaning).

## The two modes (point 15)  -  `GS.DP` in `game_state.gd`, `GS.dp("key")`
A new run asks **EASY or HARD** after the slot card (`menus.gd`, the difficulty card); the pause menu switches (a run that was ever easy cannot set the HARD record). The choice is in the save.

| | EASY | HARD |
|---|---|---|
| breath | x1.7, flight costs half, regen x2.4 (a full breath on a perch in ~3 s), free until the 3 starter fries | as before |
| TAB (Gull Sight) | a quarter of the old cost, charged per second of game time = a trickle | 9 / s of real time |
| speed a fry needs | x0.88 (fries, drinks, things) | x1.10 |
| bands / rings | fries x1.5 wider, rings x1.35 | x0.85 (x0.8 for rainbow fries, fish, sky), rings x1.1, waves 12 % faster |
| waves per circle | ONE for every counted fry (tutorial fry 1: a single judgement); rainbow fries, fish, the sky keep two | THREE for fries, rainbow fries and fish; the sky two |
| the first wave | 1.9 x slower, windows grow with it, 2 count-in ticks | 1.25 x, 1 tick |
| the sky | asks for 60 % of the points, runs 1.5 x slower | 100 % |
| the town | hostile only when the crowd is on FULL alert (watch >= 3.0), hits are bumps, friends x1.4 | hostile at watch >= 1.6 (+0.35 per CHARM level), real swats, friends x0.5 |
| RAINBOW TIME | 45 s | 30 s |
| clock | - | the race clock of the run (top centre) and the best time to the 24 fries (`user://records.json`) |

The challenge of EASY lives in the rainbow fries, the fish and the things of the sky; the speeds of the sky are the same in every mode.

## The 15 points
1. **Nobody knew how to get a fry.** The COACH (`hud.gd Coach`, `main._coach_tick`): a card of four steps (CLIMB - AIM / TAB - DIVE - E ON THE GREEN) with the key of each; the lit step follows what the gull is really doing; one line says what to do now. It leads the three starter fries (EASY) and comes back after 45 s (EASY) / 100 s (HARD) without a fry; after 80 / 170 s without one an arrow points at the nearest fry that can be caught. **Q = turn right round** (a quick U-turn, `gull_player.gd`). The controls page and the start-of-run text say it too.
2. **The breath was too short.** See the table (and `GS.free_flight()`: nothing costs breath in EASY until Gull Sight opens).
3. **TAB cost breath.** EASY: a trickle. Every other thing that costs is scaled by `drain_mult`.
4. **TAB did not open the circles.** `snatch_controller._scan` no longer refuses a lock while Gull Sight is held. It reaches 1.4 x further in the slow world, EASY pulls the beak gently onto the fry in the middle of the view, and "TOO SLOW: NEED n - HOLD SHIFT" says why a circle did not open. The sight closes by itself when a fry is locked (the old rule).
5. **The first circle came too fast.** `_seq_params`: the first wave of every judgement takes `first_slow` x longer, its windows grow with it (what you see is what is judged), and two soft ticks (`count_tick.wav`) play on the beat of the waves that follow; "READY..." waits over the circle.
6. **Drinks last 30 s** (`BUFF_SEC`).
7. **Drink stations** (`mischief.gd STATIONS`): 14 drinks, one of each kind per station: start (espresso table, ice cream shop, supermarket cafe), beach (thermos, tiki bar, a table), the pier, the hill, the sea and the summit for explorers. The others became props.
8. **Fries are icons in a ring with a light going up.** Gull Sight draws every fry as a little carton of fries in its stat colour inside its rarity ring with the NAME of what it gives (TOP SPEED, STAMINA...) and the speed it needs; the starter fries have their pillar too. In the normal view every fry has a light pillar (`shaders/beacon.gdshader`, taller with the rarity).
9. **Nothing attacks without reason.** Grumpy people, shouting kids, hostile dogs, the volleyball spike and the owners' swat need the crowd on full alert (EASY) / watch >= 1.6 (HARD). A ball that crosses a calm gull just bounces off. In EASY even a real swing is a bump (`soft_bump`: a low round thump, a puff of feathers, nothing dropped, no breath lost); walls are bumps. The hit sounds are 8-11 dB softer everywhere and the shout (`cry`) is gone from the walls.
10. **The sky is slower and kinder, with songs that fit.** See the table. Cloud: Canon / Amazing Grace; rain cloud: Greensleeves; sun: Morning Mood; moon: Brahms' Lullaby; star: Twinkle; rainbow: a rising run of broken chords.
11. **The breath bar** is framed, three times bigger, has its number and its name, turns red and calls "LOW BREATH: CTRL - LAND AND REST"; the whole top-right corner now scales with the picture.
12. **The board.** THE GOAL: NO LONGER HUNGRY (a belly bar that fills with every fry but never quite to the top, with a "?"), NEXT: the fries on the way, BONUS GOALS each with its REWARD: RAINBOW TIME, **OCEAN TIME** (the new name of FISH TIME), A BOOST, A NEW LOOK, A BETTER GULL, WEAR THE SKY.
13. **Judgement music.** `systems/tunes.gd`: every good press plays the next note of a tune; the tune is a random segment of a random public-domain song of the family of the catch (kalimba for the starters, music box for silver, harp for gold, celesta for diamond, glockenspiel climb for rainbow fries, marimba for fish, harp + pad for the sky), cut at a phrase and resolved onto the tonic chord. The samples are 84 notes rendered with FluidSynth (`tools/audio/r18_audio.py`). **Rainbow fries are SEVEN circles** (the seven colours, laid out as an arch).
14. **The circles are clearer**: bigger (the geometry scales with `ring`), a dark scrim under them, thick white waves with a dark rim and a glow, bigger target bands.
15. See the two modes above.

## More
* The pink fry is the **CHARM** fry (`GS.charm()`): strangers smile first, more friends turn up (`friend_mult`), the dogs notice a landed gull from further away and want to be friends; in HARD it also raises the hostile line.
* Pause menu: DIFFICULTY switch, TAB switch mode (hold or toggle), rhythm timing offset (+-120 ms; the browser starts with +40). Saved in `user://settings.cfg`.
* New sounds: `soft_bump`, `soft_hit`, `count_tick`, `ready_chime`, `hello` (`tools/audio/r18_audio.py sfx`).
* Translations: `tools/i18n/tr_r18.py` (the new lines in all four languages; FISH TIME -> OCEAN TIME / 海洋时间 / 海洋時間 / オーシャンタイム everywhere).
