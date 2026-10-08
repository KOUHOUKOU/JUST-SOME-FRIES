# Build & tuning notes (v2)

## Run / build / test
- Play from source: `PLAY.bat` (needs `D:\Tools\Godot\4.7.1`). Standalone: `BUILD.bat` → `build\JustSomeFries.exe` (+ `.pck` next to it).
  The exe is the Godot 4.7.1 runtime renamed (no export templates are installed on this machine); the `.pck` is auto-loaded.
  A "real" slim export + Web build needs the official export templates (~1 GB download) — not downloaded.
- Dev test modes (from `game/`): `godot --path . -- <mode>` where mode is one of
  `--autotest` (bot plays the whole game and prints `[AUTOTEST]` metrics), `--tour` (art screenshots), `--intro`, `--cam`,
  `--ui`, `--wary`, `--systems`, `--audio` (writes WAV previews to `assets/audio/preview/`), `--cone`, `--restart`.
  Screenshots land in `shots/`.

## Deviations from docs
- Engine is Godot 4.7.1 (only version installed); project feature tag 4.6; GL Compatibility renderer.
- All meshes/audio are procedural. `assets/models/hero_gull.glb` (optional) replaces the fallback gull.
- Swat hits are distance/segment checks, not Area3D. Input actions are registered in `game_state.gd`.
- Ring is time-to-contact driven (speed independent), verdict decided at the E press; slow-mo close-up only reveals it.
- Nest removed; perching on any flat surface restores stamina (18/s, 26/s when ≥4 m high; ×1.8 with Second Wind).

## Key numbers (all in `game_state.gd` / `gull_player.gd` / `npc_controller.gd`)
- Speeds: glide 5 · throttle 11 (13.5 red) · boost 19 (24 red) · dive cap 16 · snatch needs ≥10.45.
- Stamina: 100 (160 blue) · throttle 2.5/s · boost 16/s (locks until 15) · flap 6 · roll 10 · glide regen 2/s (6 yellow).
- Camera: FOV 66→74→92, distance 4.0→5.2→7.5 across glide/throttle/boost.
- Collisions: wall impact >9 m/s tumbles (1.2 s, −12 stamina). Water: soaked 15 s (speed ×0.85, regen ×0.5).
- Swat hit: tumble 1.2 s, −30 stamina, fry dropped. Wary 3 → owner leaves (tutorial owners just reset), returns after 40 s.
- Town wariness ("heat") decays 1 per 30 s; scales NPC view/gain and shrinks ring windows.
- Prism reward habituation: 1.0 → 0.6 (2–4) → 0.3 (5–8) → 0.1 (9+).

## Playtest round 2 (2026-10-06)
- **Freeze / system lag**: no leak found (260 s soak + full playthrough: objects/nodes/RAM/VRAM flat, `--soak`, `--census`).
  Likely cause: uncapped 240 fps render of ~2000 draw calls (shadow pass included) saturating a laptop GPU/CPU.
  Fixes: `Engine.max_fps = 60` (30 in menus/pause, `game_state.gd`/`menus.gd`), `GS.cull_tree()` hides ambient NPC meshes beyond 110 m
  and ambient gulls beyond 140 m (and stops gull shadows). `main.gd` prints a `[PERF]` line every 10 s into
  `%APPDATA%\Godot\app_userdata\JUST SOME FRIES\logs\godot.log` - send it if a freeze ever happens again.
- **FOCUS (bullet time) replaces the old centre ring** (`snatch_controller.gd`): dashing at a fry in the aim cone starts a lock at
  TTC <= ring_time x 1.25. `Engine.time_scale` eases 0.5 -> 0.26 while the lock lasts (x0.8 for the tutorial fry), heartbeat + soft
  low-pass, vignette, zoom (-14 FOV, `player.focus`), turn rate x2.8, aim pulled onto the fry (2.2/s, 4.0/s with Steady Beak).
  The ring is drawn AROUND THE FRY on screen (`hud.gd Reticle._ring`): white ring shrinks to the green band; E when it is inside.
  E also needs the beak within ~17 deg of the fry (`ALIGN_COS`), else "OFF TARGET". Verdict is still decided at the press.
- **First fry**: starts facing the café table (`_face_first_fry`), gold marker / edge arrow (`hud.guide_pos`), one persistent
  instruction at a time (`_tutorial_director`), +50 % green band and slower bullet time for TUTORIAL_01 until it is taken.
- **Item-get showcase** (`ui/fry_showcase.gd`): every named fry (3 tutorial, 4 special, first prism) pauses the game, wipes a band in from the
  left, slides the real fry model out of the left edge, shows NEW!, name, source ("STOLEN FROM ..."), description and ability numbers.
  New prism varieties get a small banner instead. The ordinary fry gets the last card: "FRY - A GIFT FROM THE OLD MAN - ABILITY: NONE".
- Dev modes added: `--soak [--secs=N]`, `--census`, `--showcase`, `--focus`.

## Playtest round 3 (2026-10-06) - see docs/21_ROUND3_CHANGES.md
- **Two simple checks instead of one hard one** (`snatch_controller.gd`): GRAB (white ring -> GREEN band, GOLD band inside = perfect) then, after a green
  grab + close-up, the ESCAPE CHECK (the owner winds up a swing, the ring runs on that wind-up; green or gold = slip away, else shot down: the fry falls,
  vanishes and the owner "reorders" it 16 s later (8 s for tutorial fries); the player is swatted: tumble, -30 stamina, comic panel). Gold grab = no escape check.
  Bands are x1.3 fatter than before (`WINDOW_BOOST`), gold = 30 % of green (`GOLD_FRAC`). First fry: x1.5 and immune to crowd thinning.
- **Only one fry is ever judged**: highest dot with the view centre (distance ignored), needs a clear line of sight (`_los`), brackets sit ON that fry,
  mischief props wait until the 3 tutorial fries are done. Early green presses dash the gull the rest of the way during the close-up.
- **Speed gauge** (right edge): number = m/s x 4 (`GS.SPEED_UNIT`), GRAB line at 40 (`GS.GRAB_SPEED` = 10 m/s), target marker + chevrons for accelerating/braking.
  Top speeds never change (cruise 11 / boost 19 / dive cap 16). **TAILWIND only changes acceleration**: x0.5 / 0.9 / 1.5 / 2.3 -> 5->10 m/s in 1.9 / 1.2 / 0.7 / 0.45 s.
- **Crowd WATCH** (`GS.watch` 0..4 = heat memory + owners who are looking (+1.2 alert / +0.5 suspicious, scaled by distance) + awake dogs + up to +0.7 for a crowd
  within 14 m, smoothed). Window multiplier `max(1 - 0.1 * watch, 0.55)`. Meter under the stamina bar. A failure while watch >= 2 prints a faint line.
  Every successful theft adds +0.3 heat, a failed grab +0.5, a swat +1.0 (heat decays 1 / 30 s).
- **Gull Sight = hold TAB** (slow motion x0.3, dark screen, every non-plain fry glows through walls in its rarity colour, edge arrows when off-screen). Costs
  9 stamina / real second (x1.0 / 0.6 / 0.3 / 0 with Farsight tiers 0-3). Needs the 3 tutorial fries. Out of stamina -> closes, "out of breath". The plain fry never glows.
  **Fry Codex = C** (map, stat bars, fry list with tier pips; HUD hidden).
- **Fry types x3 tiers** (`game_state.gd`): red Tailwind, blue Deep Breath, yellow Second Wind, green Steady Beak (grab window x1/1.2/1.45/1.75 + aim cone 33/40/46/52 deg),
  rose Farsight (NEW, the Birdwatcher in the park fountain area). Tier 1 RARE (blue backdrop) = the 5 owner fries; tier 2 EPIC (purple) and tier 3 LEGENDARY (gold, maxed)
  = 10 "star" fries that appear at the 13 hard-to-reach anchors after the 5 tier-1 fries (max 3 at once, tier 3 only after tier 2 of its kind). Progress is now n / 8.
- **"Where is the plain fry?"**: `hunger_t` runs while STILL HUNGRY (x3 once every star fry is collected): whispers at 45 / 110 / 190 / 270 s, at 330 s a faint
  "THE CORNER TABLE?" pointer + the old man waves. Gull Sight shows "nothing ordinary glows." after 100 s. The plain fry's halo uses `GS.longing()` (stars x1.2 + hunger/40).
- **Opening** (`ui/title_cards.gd`): "This is an age of magic..." title cards (any key skips). **Credits** after the ending: a joke cast list + your run's numbers.
- **Comic panel** (`ui/comic_pop.gd`): lower-left; pictures from `assets/ui/comics/<id>.png` (docs/20_COMIC_PROMPTS.md) or drawn placeholders.
- Dev modes added: `--flee`, `--vision`, `--gauge`, `--comics`, `--title`, `--credits`, `--menu` (real START path), `--one --id=SPECIAL_ROSE`, `--star` (all 13 star anchors).
  `GS.no_focus_pause` keeps a minimised test window from pausing the bot.
## Round 4 (2026-10-06) - the "finished game" pass, see docs/22_ROUND4_CHANGES.md
- **Grab speed by rarity** (`GS.need_speed`, gauge = m/s x 4): TUT_NEED 8 / 9 / 10 (32 / 36 / 40), TIER_NEED rare 10.5 (42), epic 14 (56), legendary 17 (68), decorative steals 13-14.5, fish 14.5.
  The lock needs `closing >= max(7, need - 3)`; the gauge GRAB line follows `snatch.need_speed` (colour = rarity); brackets say "NEED n".
- **Rings** (`snatch_controller.gd`): ONE green ring + ONE gold ring, drawn exactly as thick as the window. Owner fries: green = the owner's timing x `WINDOW_SCALE` 0.55
  (tutorial 1 x1.4, tutorial 2 x1.2); epic `STAR_WINDOW` .13, legendary .085, fish .07; gold = `GOLD_FRAC_TAB` [.34 .30 .27 .24], fish .22 (min .016); Steady Beak still scales every window
  (x1 / 1.2 / 1.45 / 1.75) and now also slows the ring (`RING_TAB` 1 / 1.06 / 1.12 / 1.2). Ring time: owner's own, epic 0.62 s, legendary 0.5 s, fish 0.42 s (x1.25 focus time).
  The ring never runs backwards, has no lag, and past the green (+`LATE_GRACE` .012) the grab fails immediately. Escape check: window = owner timing x .6 (x1.35 for the tutorials);
  the gull is pinned to the owner's swing centre until the verdict (`_pin_to_swing`), a fail brings the swing down at once (`_flee_fail`).
  **E is time-stamped** in `_input` and judged at the instant of the press (`ring_rate` rewind); the HUD ring is extrapolated between physics ticks (`ring_p_now`).
  Epic / legendary miss: -8 / -14 stamina, fry spooked 1.8 / 2.7 s.
- **Fry types** (`game_state.gd`): 7 types x 3 tiers (new orange FLUFF: `HURT_TAB` 1 / .7 / .45 / .2 and `STUN_TAB` 1 / .85 / .7 / .5; new silver HUSH: `NOTICE_TAB` 1 / .8 / .6 / .4 on NPC awareness gain).
  Progress n / 10, star fries n / 14 (17 anchors). Day cycle: sense .06, specials .052, stars .032 each.
- **Save** (`GS.write_save / apply_save`, `main._restore_run`): `user://savegame.json`, autosaved from `main._autosave_tick` whenever the progress signature changes while idle; deleted at the ending.
- **Hunger**: `HUNGER_STEPS` (clock) + `HUNGER_COUNT_STEPS` (1 / 3 / 5 / 7 / 9 / 11 / 13 star fries). Plain-fry steam = `GS.longing() / 14` (stars x1.2 + hunger_t / 40). Pointer + waving old man at 330 s or 12 star fries.
- **Hazards**: volleyball (`world/volleyball.gd`, hit radius 1.2 m, 4 s cooldown), grumpy people (`ambient_npc._grump`: reach 2.9 m, 0.6 s wind-up, 8 s cooldown), kids (`_chase`: landed gull within 20 m, 3.7 m/s, BOO = `player.startle` -6 stamina),
  dogs (also chase a landed gull within 8.5 m), rival gulls (`world/rival_gulls.gd`: 60-100 s apart, 21 m/s dive, bump = -4 stamina), fish spots (`world/fish_spot.gd`: idle 5-34 s, bubbles 3.2 s, leap 2.3 s).
- Dev modes added: `--world --hud --tiers --fish --rival --volley --wear --save --hunger --ending --hazards`. Run them with `Start-Process` (see round 3 notes).
## Round 5 (2026-10-07) - expert playtest, see docs/23_ROUND5_CHANGES.md
- **Units**: gauge = m/s x 6 (`GS.SPEED_UNIT`). Glide 5 (30), cruise 11 (66), boost 19 (114) at the start. Fries only change the TOP speed (SONIC red: 19 / 21 / 23 / 25 m/s = 114 / 126 / 138 / 150, +0.15 m/s per rainbow fry) and the ACCELERATION (TAILWIND orange x1 / 1.4 / 2 / 3, +0.04 each). Boost accel base 8, throttle 4, glide 3 (all x accel_mult); landing (Ctrl) brakes at 18 m/s^2 and sinks at 9 m/s.
- **Need speed** (`GS.NEED_GAUGE` [silver, gold, diamond]): red 72/102/126, orange 72/96/132, green 66/90/138, cyan 72/108/126, blue 72/102/144, purple 66/96/132, pink 72/114/150; tutorial 48/54/60; rainbow 90; mischief 72-87 (drinks 72, clothes 75, hats 81-87), fish 96. The lock needs speed >= need and `closing >= max(7, need-3)`, beak within `lock_cos` (0.95 / .94 / .93 / .92 by STEADY level; decorations +0.03), and a distance <= closing x 1.05 (3.5..26 m).
- **Rhythm** (`snatch_controller.gd`, real seconds): `SEQ_TIER` n / lead / gap / gold width / green width: silver 1 / .85 / - / .085 / .17; gold 3 / .85 / .42 / .07 / .14; diamond 5 / .80 / .30 / .055 / .115; rainbow 1 / .8 / - / .09 / .18; fish 1 / .75 / - / .045 / .09; decorations 1 / .95 / - / .11 / .24; tutorial 1-3 get fat bands. Multipliers: STEADY bands x1 / 1.25 / 1.5 / 1.8 and rings x1 / 1.12 / 1.25 / 1.45 slower, crowd 1.0..0.65, owner archetype 1.0 (elder) .92 (adult, vendor) .8 (child), escape check x.95. Gold: gold band ends at the ring, green band is the share before it; a gold press may be 20 ms late, a ring is a miss 30 ms after its gold. One miss allowed with 3 or 5 rings; PERFECT = no miss and gold on >= ceil(0.8 n) rings. Presses in the first 0.14 s are ignored. The world slows to `seq_ts` = distance / (rhythm length x speed), clamped .2..0.8; the gull is carried along a straight line to 1.7 m from the fry (no collisions while guided: `gull_player._fly` returns early). Escape check: `FLEE_TS` 0.33, the owner's `scripted_tele` = rhythm length x .33 + .12.
- **Stamina**: 60 / 90 / 130 / 190 (+4 per rainbow); cruise 3/s, boost 18/s, flap 6, roll 10; regen glide 1.5 / 2.2 / 3.2 / 4.5 per s, perched 9/s (14/s above 4 m) x 1 / 1.5 / 2.2 / 3 (purple).
- **Gull Sight**: radius 40 / 80 / 160 / 320 m (+4 per rainbow), free when not flying, 9 / 5.4 / 2.7 / 0 stamina per real second in the air. World speed x0.3.
- **Drinks** (`GS.set_drink`, 15 s): coffee: cruise x1.22, boost +2.5 m/s, acceleration x2.6, small tremble; alcohol: speeds x0.58, boost x0.55, acceleration x0.4, a slow sway (aim yaw += sin 1.1t * .5 + sin 2.3t * .28 per s). 3 s on the ground clears it. Drinks respawn 55 s after being taken (when the player is > 14 m away).
- **Rainbow** (`GS.add_rainbow`, max 8 per colour): re-ordered by the owner of a finished colour every 70 s (player > 20 m away, `main._rainbow_tick`) and fed by kids (90 s cooldown). Never counts for the mission.
- **Missions** 3 / 6 / 10 / 24 (`GS.MISSIONS`, `GS.fry_total()`); the plain-fry hint ladder follows `fry_total` (10 / 13 / 16 / 19 / 21 / 23 / 24); the pointer and the waving old man start at 20 fries or 330 s.
- **Rest events** (`world/rest_events.gd`): after 4.5 s of sitting still (not before 3 fries): friendly gull 40 % (+14 stamina), kid 40 % (needs 4 fries and a 90 s kid cooldown) , stray dog 20 %; 12 s after the start, then 14-22 s between events; high crowd attention allows only the gull.
- **Hazard warnings** (`world/warn.gd`): volleyball smash every 11-16 s once the gull has hung within 22 m of the court for 2.5 s (wind-up 1.1 s, aim follows 0.75 s, ball 18 m/s); dog crouch 0.72 s; water gun / grumpy wind-ups with a "!"; the sound "warn".
- **Dev modes added**: `--rhythm` (silver / gold / diamond, misses), `--land` (Ctrl landing, TAB cost), `--rest` (the three rest events), `--codex`, `--places`, `--topdown`, `--rainbow`, `--star --only=a,b`, `--one --id=...`, `--menu` (the real START path with shots). `--autotest` plays the whole game (tutorial, 7 silvers, 14 gold/diamond with `GS.test_boost_bonus` 8, a rainbow re-order, the plain fry).
## Walkthrough video + delivery (2026-10-07)
- **`--film`** (`autotest.film`): the real menu -> opening -> big brother, then the bot flies: free flight, 3 tutorial fries (one shot down on the escape, one PERFECT), Gull Sight, 3 silvers, a hat, the codex, a volleyball smash, a gold (3 rings) and a diamond (5 rings) fry, then the real ending cinematic, cards and credits (~3 min).
  Record: `godot --path game --write-movie out.avi --fixed-fps 30 -- --film --movie-fps=30`, then `ffmpeg -i out.avi -c:v libx264 -crf 25 -c:a aac -b:a 128k -af loudnorm -movflags +faststart walkthrough.mp4`.
- **Game clock** `GS.usec()` / `GS.msec()`: every timed thing (rhythm rings, presses, dialogue, title cards, HUD pulses) reads it instead of `Time.get_ticks_*`. Wall clock normally; under Movie Maker it counts drawn frames / `--movie-fps` (the engine does not pass `--fixed-fps` to scripts), because the movie renders faster or slower than real time and the rhythm would drift.
- **Links (submitted to Tripothon)**: repo `https://github.com/KOUHOUKOU/JUST-SOME-FRIES` (also the video field), web demo `https://kouhoukou.github.io/JUST-SOME-FRIES/` (= `docs/` on main), video page `.../walkthrough.html`, download `.../releases` (zip uploaded by hand: no `gh` on this machine).
## Round 6 (2026-10-07) - see docs/24_ROUND6_CHANGES.md
- **Flight**: boost top speed 15 / 17.5 / 20.5 / 24 m/s (gauge 90 / 105 / 123 / 144); acceleration glide 2.4, throttle 3.0, boost 3.6 m/s^2 x `accel_mult` (TAILWIND x1 / 1.5 / 2.2 / 3.2; coffee x2.2); dive cap 14 m/s. Need speeds (`NEED_GAUGE`): silver 72-84, gold 96-114, diamond 126-144; tutorial 45 / 51 / 57; rainbow 84; fish 14 m/s; cloud 96, sun 114.
- **Rhythm** (`snatch_controller.gd`): `SEQ_TIER` circles x waves, lead, gap, gold width, green width (s): things 1x1 .85 / - / .07 / .13; silver 2x2 .85 / .36 / .05 / .095; gold 3x2 .85 / .33 / .045 / .085; diamond 5x2 .85 / .29 / .04 / .075; rainbow 1x2 .42 / .06 / .11; fish 1x1 .04 / .07; cloud / sun .035 / .06; tutorial 1x2 with fat bands (.09/.2, .075/.16, .065/.13). A wave shrinks onto its circle in 0.56 s (x STEADY ring slowdown). Multipliers: STEADY bands x1 / 1.25 / 1.5 / 1.8, crowd .65-1, owner archetype .85-1, coffee x1.3, cocktail x.88. Points: green 1, gold 2, need = number of waves; the rhythm ends as soon as the points are there or cannot be reached any more. Perfect = no miss and >= 70 % golds. `seq_ts` x `GS.slowmo_mult()` (coffee .55, cocktail 1.7).
- **Buffs** (`game_state.gd`): `BUFF_SEC` 20; `buffs_die()` on landing (all three) and on a hit (coffee, cocktail); a dying buff burns 9x faster. Top speed +2.4 / +3.4 / +2.0 m/s (coffee / cocktail / ice cream). Cocktail: flight, flap, roll and Gull Sight cost nothing. Ice cream: `player.shield_hit()` in `get_swatted`, `startle`, wall crashes and rival bumps.
- **Terrain**: STEP 2 m; three terraces (banks at z -26..-31, -47..-52, -68..-73 to 5.5 / 11 / 16.5 m), east of x 48-60 it melts into the old rolling hill. Ground kinds in the vertex alpha.
- **World census** (`--census2`): every wearable x1, ball x1, coffee 4, cocktail 3, ice cream ~6.
- **Dev modes added**: `--sky` (catch the cloud and the sun), `--stand` (feet on ground / roof), `--census2`; `--flee` now only grabs the tutorial fries; `--rhythm` tests points (all green / skip one / all gold); `--drink` tests the buffs.
## Round 7 (2026-10-08) - see docs/26_ROUND7_CHANGES.md
- **Top speed ladder** (`BOOST_TAB` m/s): 15 / 20 / 25 / 28.5 (gauge 90 / 120 / 150 / 171). Silver SONIC covers every gold need (max 114), gold SONIC every diamond need (max 144). Drinks: coffee +4.2, cocktail +5.0, ice cream +3.0 m/s (`BUFF_TOP`), they add up. Fish need `FISH_NEED` 96 / 120 / 144. Wearables higher than 5 m: +0..1.8 m/s (`mischief._process`).
- **Buffs**: `add_buff` adds `BUFF_SEC` 20 s (cap `BUFF_CAP` 300), refills stamina (`buff_added`), nothing burns them away (`buffs_die` is a no-op). All three at once -> `start_star` (`STAR_SEC` 30): `free_flight()`, `invincible()`, boost +9 m/s (`STAR_TOP`), cruise +7, glide +4, accel x2, windows x1.5, slow-motion x0.5, turn rate +45 %, camera +9 FOV / +1.6 m back / roll x0.7 / follow rate 6.5.
- **Rhythm circles** (`hud.gd Reticle._rhythm`, px at 720p, wave start / target / spacing): 1 circle 172 / 52 / -, 2: 120 / 40 / 262, 3: 100 / 35 / 208, 5: 106 / 37 / 228. Fish: tier 5 (common) 1x2, tier 7 (rare) 3x1, tier 8 (legendary) 5x1 (`SEQ_TIER`).
- **Fish** (`world/fish_spot.gd`): idle 3-10 s, forecast 5 s (real time, Gull Sight only), bubbles 2.4 s, leap 2.6 / 3.0 / 3.6 s, cooldown 6-14 s (20 s after a catch), at most 4 live at once, 18 areas, 16 tries to find a free arc (`_path_free`: avoid rects / discs + 5 sphere queries at 5 heights). Species table `GS.FISH_SPECIES` (name, rarity, cm min/max, kg min/max, colours); length = lerp(min, max, u^1.7), weight grows with u^2.2.
- **Quests**: `GS.QUESTS` (10), `BIG_QUESTS` fishbook / cloud / sun, `QUEST_SHOWN` 4 lines.
- **Rainbow**: `main._rainbow_tick`: target holders = min(2 + 2 x finished colours, 14), holders must be >= 62 m from the start (weight grows with distance), a new one 14-30 s after the last; kind children (`ambient_npc._kind`): run at 3.6 m/s when the gull sits within 22 m, cooldown 150 s; friend gulls (`rest_events`): gift chance 30 % (55 % on roofs / trees / hovering), cooldown 60 s.
- **Audio**: `tools/audio` (numpy/scipy/ffmpeg). Music 32 kHz stereo OGG q4, -23 dBFS RMS, seamless loops (the reverb tail is folded onto the start); SFX 32 kHz mono WAV. Zones in `main._zone_of` (sky above 40 m, summit, hill, sea, beach, boardwalk), 2.4 s of stubbornness, 3.8 s cross-fade, STARLIGHT 1.2 s.
- **Web / perf**: `GS.web`, `systems/perf_governor.gd` (levels: 3D scale 1 / .85 / .72 / .6, shadow distance 140 / 90 / 60 / 40, no shadows at level 3; down after 4 s under 26 fps, up after 15 s over 56 fps; the web build starts at level 1).
- **Dev modes added**: `--r7`, `--r7b`, `--cams` (reads `shots/cams.json`), `--menu` now drives the real cover + opening (`--fastkeys` presses a key every second), `--ending` plays the whole ending.
## Round 8 (2026-10-08) - see docs/28_ROUND8_CHANGES.md
- **Rhythm tiers** (`SEQ_TIER`): 9 = rainbow fry (5 circles x 1 wave, gap .31, gold .038, green .075), 10 = shooting star (5 x 1, lead .80, gap .29, gold .034, green .068; x1.5 in STARLIGHT). `GS.RAINBOW_NEED` 150, `GS.METEOR_NEED` 190 (gauge; = 25 / 31.7 m/s). STARLIGHT top speed = 15 + 12.2 (three drinks) + 9 = 36.2 m/s = 217 gauge.
- **Shooting stars** (`world/meteors.gd`): speed 21 m/s, 6 s before the closest approach, 17 s of flight, forecast 5 s, orbit at 62-120 m (raised 22 m at a time over terrain + 14 m), real star every 110-200 s and 2.5 s after STARLIGHT starts; decorations every 30-60 s (12-26 s at night) 260-420 m away at 150 m/s. Catch: breath refill, +10 s STARLIGHT (cap 60), quest "meteor", wearable "meteor" (slot comet).
- **Sky steering** (`gull_player._fly`): pitch limits -70 / +78 degrees (were -60 / +45); above 38 m the turn rate grows up to x2.25 (full at 83 m) and the pitch rate by +.25.
- **Cinematic moments** (`story_scenes.gd cinema`, queued by `main.queue_cine` and shown by `main._cine_tick` once the gull is free; each once per run, saved in `GS.cine_seen`): drink_coffee / drink_alcohol / drink_ice, drinks3, fish, meteor, all24; plus the big brother's talks chat1 / chat2 / chat3 (3 / 10 / 18 fries, only when the gull sits within 7 m for 1 s). Film mode = `story.gd bars_in / narrate / set_tag`, time scale 0.22, buff timers paused.
- **Visual novel box** (`story.gd say_vn`): 320 x 320 SubViewport portrait (shares the 3D world, camera 1.0 x the gull's scale away, fov 30-34), backdrop quad on render layer 20 (main cameras mask it out in `story.begin`), the camera avoids the other speaker (`look["avoid"]`).
- **Memories** (`GS.memories`, `GS.remember`, `AWARD_MEM`): coffee / alcohol / ice / starlight / fish (+ its species) / cloud / sun / meteor / friend / gift / kid / rainbow / thermal / skim / wall / armed / all24, plus fry1 from the first starter fry; the ending shows at most 8 (priority order, then chronological) + "a fry on the floor".
- **Audio**: `tools/audio/synth_extra.py` (tuned Karplus-Strong `pluck`, guitar2, pizz, harp2, clarinet, accordion, celesta, glock, brush, tamb, swell), `music8.py` (title, ending, star, cine_joy / cine_wish / cine_home), new SFX friend_come, friend_gift, meteor_pass, meteor_get, cine_in, cine_out, vn_next, vn_pop, star_riser, drop_tick. `Sfx.cine_music(piece)` ducks the world music under a cinematic piece.
- **Gulls**: `gull_visual.PALE` (butter, blush, sky, mint, lilac, peach), `tint_pale`; `comet_k` grows the star's tail with the speed.
- **Dev modes added**: `--r8` (checks), `--r8t`, `--r8b`, `--r8c`, `--r8e`, `--r8m`. `--film` was rewritten for the 2-minute promotional video (see "Promo video").
## Round 9 (2026-10-08) - see docs/30_ROUND9_CHANGES.md
- **Sky needs** (`game_state.gd`): `CLOUD_NEED` 255, `METEOR_NEED` 262, `SKYBOW_NEED` 266, `SUN_NEED` 272 (gauge). Ceiling with all drinks + STARLIGHT: silver SONIC 247, gold 277, diamond 298 (`--r9speed`). Tach scale `vmax` 160 -> 310 when `boost_speed` > 155.
- **Rhythm tiers** (`SEQ_TIER`, every circle 2 waves): 0 things 1x2 (gap .40, gold .06, green .115); 5 fish common 1x2; 7 rare 3x2 (.36); 8 legendary 5x2 (.30); 9 rainbow fry 5x2 (.30, .04/.075); 6 cloud / sun and 10 star 5x2 (gap .29, .03/.06); 11 the rainbow in the sky 7x2 (gap .28, .03/.06; layout `LAYOUTS[7]` an arch). HUD geometry for 7 circles: start 76 px / gold end 28 px / spacing 148 px. `FISH_JUDGE` 2 / 6 / 10.
- **Camera director** (`ui/cine_cam.gd`): `dist_for(width, frac, fov)`; sizes wide .10 / medium .30 / tight .45 / insert .22 of the picture width; gull width 2.7 m x scale flying, 1.5 m perched; candidate azimuths every 12 degrees within `spread`, score = backdrop (3 rays through the subject: wall < 5 m -3, < 14 m -.8, scenery +2, sea +.15, sky +.7) x 3 - |offset| x .9, blocked / below ground -200; `clear()` also rejects people, dogs and fries within 1 m of the line of sight or 2.2 m of the lens; options `side` (force the third), `lift` (carry the subject up above a dialogue box), `push` (slow dolly, <= .1).
- **Cinematics** (`story_scenes.gd`): drinks3 17 s, meteor 16 s, sun 12 s, skybow 13 s, all24 19 s; `hud.quiet_moment` (bars .34, 4 lines max, 1.3-2.5 s per line); 4 s between two moments (`cine_done_at`).
- **Gull Sight pillars** (`vision_overlay._beam`): heights 70 / 130 / 220 / 350 m, 10 segments, width 8-32 px, polygons with vertex alpha on the additive layer.
- **Weather** (`world/sky.gd`, `cloud_drift.gd`, `rainbow_pair.gd`): 15 white / 6 grey / 5 rain clouds; rain = 380 CPU particles (130 on the web), switched by `over_sea(x, z, 22)` every .4 s; the pair sits at (-160, 82, 215), drifts 1.1 m/s, half span 55 m, arch 42 m, seven tubes (1.7 m apart, 0.95 m radius), visible while it rains and not taken (hidden for 150 s after a catch).
- **Star trail** (`gull_visual` "meteor"): 60 stars, 3.2 s, world space, alpha-blended gold, `speed_scale` .55 + 2.2 x speed share, distance fade 0.8-3.5 m.
- **Music** (`tools/audio/music9.py`, `music9_end.py`, `sf_render.py`, `midi_util.py`): FluidSynth + GeneralUser GS, 32 kHz, reverb in the synth, -23 dBFS RMS, OGG q5. Title 63 s loop (80 bpm, 6/8), ending_mem 48 s loop (60 bpm, 6/8), ending 62 s once (62 bpm, Largo notes from `ref/largo.mid`). `Sfx.crossfade_theme("theme_end", false, -8, 3)` when the big brother lands.
- **Dev modes added**: `--r9speed --r9cine --r9quiet --r9tab --r9trail --r9sky --shotcheck`.
