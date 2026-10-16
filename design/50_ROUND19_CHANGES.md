# Round 19 - the rings, the beat, the TAB bug (2026-10-16)

User's playtest points and what was done:

1. **White wave too thick** - `ui/hud.gd _rhythm`: the wave is now a thin crisp line (3.4 px next / 2 px faint, 4.4 gold zone) with a thin dark rim; only the NEXT wave is bright
   (the others are faint), the wide glows are gone, the band under-glows are narrower.
2. **Ring size uneven (tiny at 7/9, huge at 1)** - one comfortable size for all counts (`geo` table: 1:132, 2:114, 3:92, 5:112, 7:88, 9:84 at 720p) and `DP.ring` = 1.0 (was 0.68 / 0.62).
3. **Same speed for every wave, longer approach** - `DP.appr` / `DP.beat` (EASY 0.95 s / 0.62 s, HARD 0.8 s / 0.5 s; classic keeps the old tier table with 0). The faster-later-tiers ladder is
   nearly flat (0.97 / 0.94 / 0.92 of the beat for silver / gold / diamond); no slow first wave, no quicker second wave. Sky (sun, moon, ...) 1.1 x. `snatch_controller.gd _seq_params`.
4. **Even spacing** - the beat is the same for every tier (about 87 bpm in EASY at the default 1.12 timing factor); the count-in ticks are on the same beat.
5. **Two judgements per circle again in EASY** (`w_fry` 1 -> 2; the very first fry TUTORIAL_01 keeps one). HARD keeps three per fry circle.
6. **Sound = beat** - note i of the tune belongs to wave i, played on its beat (an early press waits for the middle of the gold band, at most 0.14 s: `_on_beat`); a gold press is the same note
   with sparkle and a run of bells (no second note squeezed in 70 ms later). A miss is a hole on its beat. `tunes.gd gold()`.
7. **TAB in cut scenes** - `main.gd`: Gull Sight cannot open while `GS.cutscene`, `scenes.cine_busy` or `scenes.beat_busy`, is closed if a cut scene starts, and `_close_sense` leaves the
   cut scene's own slow time alone.

Tests: `--r18a` (4 checks rewritten for the new rules), `--r18h` (easy gold test: two presses), `--r18n` (EASY novice bot; flaky once: TUTORIAL_02 timeout, passed twice after).
New dev picture: `shots/run_r18.ps1 -Mode rhythm -Extra "--ringview" [--hard]` writes `shots/rv_1/2/3/5/7/9.png` (still pictures of the circle layouts).
