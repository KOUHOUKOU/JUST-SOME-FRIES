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
