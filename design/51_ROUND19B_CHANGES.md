# Round 19b - feedback after the first play of round 19 (2026-10-16)

1. **Screen feedback on a good judgement** - `hud.gd Vignette._hit_glow`: the four corners of the screen light for 0.5 s, a pale glow in the band colour for green (orange for the sun, blue for
   the moon), a warmer and stronger one (and a bit bigger) for gold. The snatch controller stores `hit_fx_res / hit_fx_t / hit_fx_tier` in `_note_result`.
2. **Gold sounds exactly like green** - `tunes.gd gold()` is now just `play()` (no sparkle, no run of bells, no second note); the HARD `hit()` lost its extra glockenspiel; the little bell on top of
   every note is 4 dB quieter. The difference between green and gold is only on the screen and in the points.
3. **Wall sounds** - `gull_player.gd`: brushing a wall below the crash speed (`worst <= 9`) no longer plays "land" or shakes the picture (inside a box the flap kept hitting the ceiling and buzzed);
   `soft_bump` plays at most once per 0.9 s.
4. **Sky order** - the item's own moment (cine queue) comes first; the goal board and the film of the whole sky wait for it (`hud.gd _when_scenes_free`, `_big_quest_film`).
5. **Goal finished = the board comes up by itself** - `GS.quest_pop(id)` / `quest_pops`, drawn in `hud.gd` (board section): a folded board slides in, the count runs 0 -> max in 0.9 s, the line
   flashes twice, a stroke is drawn through it, then the board slides away again (4.6 s in all). Replaces the old "TASK DONE" toast; the sky quest does the same, then its film.
6. **Gold / diamond speed** - `GS.NEED_GAUGE`: silver unchanged (72-84), gold 86-98, diamond 102-110 (they were 96-114 and 126-144). The rainbow fry (150) is the hard one.
7. **The "gling gling"** - the typed voice of the story (`story.gd _voice_note`) is now a soft marimba walking up and down the pentatonic scale (it was a sharp blip at a random pitch); the hold-E
   ticks climb the scale. I cannot listen: **judge it by ear** (if the intro/ending "gling" is something else, tell me which moment).
8. **Words** - `tools/i18n/tr_zz_r19.py` (sorts last, wins): the sky captions and thoughts are rewritten (longer, warmer, funny, no dots) in zh_CN / zh_TW / ja, and every "......" of the
   earlier tables is gone. The game has Chinese (simplified, traditional) and Japanese, no Korean.
9. **Few dots** - see 8; the English source of the sky lines lost its dots too.

Tests: `--r18a` (31), `--r18h`, `--r15a` pass; `--rhythm --questpop` writes `shots/qp_*.png` (board slides in while folded, the count, the flash, the stroke).
