# Round 20 - the new 2-minute trailer

Replaces `walkthrough.mp4` on the Pages video page and in the release (`JustSomeFries_walkthrough.mp4`, +`_10MB.mp4`, `.srt`, poster). 1280x720, 30 fps, 119.8 s, 54 MB (10 MB version for the form).

**Shape.** A story open (one fry falls: *tk.*, an age of magic, a hungry gull, the four-panel comic) - the first fry (take-off, dive, lock-on, the beak with the fry) - Gull Sight and three drinks -
RAINBOW TIME (the drop of the music on the lettering, 17 s of flat-out flight over the island) - a fish, a rainbow, a falling star, the moon - the roof (bite, memories, "...That's a lot of hats, kid.", "It's just a fry.",
the finery falls away, "...same.", the shades, "It's still warm.", "Salt.", the chain, "...Good.", the last comic panel, "IT WAS ENOUGH.") - the cover.

**Music** (`tools/film/score_r20.py`, real public-domain recordings from `tools/audio/src`, edited, not rendered): Debussy *Clair de lune* (the story) -> Grieg *Morning Mood* (its swell lands on the steal) ->
Mendelssohn *Italian* symphony, first movement (its drop at src 35.47 s lands on "RAINBOW TIME"; the sections C and D are cut in whole pulses of its beat, 0.824 s, found with `fit_grid.py`) ->
Dvorak *Largo* (the long build under the memories and the dialogue; its climax at src 490 s lands on "...same."), plus a synthesised riser into the drop and two low hits (the drop, the title). Anchors: `film/anchors_r20.json`.
**Voice** (`make_trailer_r20.py`): edge-tts `en-US-AndrewNeural`, rate -8 %, pitch -3 Hz, warmed and put in a little room; the score ducks under it. Ten short lines; the game's own words carry the roof.
(edge-tts 7.2.8 was refused by the service with a 403; `pip install -U edge-tts` (7.3.1) fixed it.)

**Footage** (all recorded with this version of the game, Movie Maker, 1280x720): `tools/film/record_all.py --only=1,30,31,22,11,12,40,41 --no-promo` and `film/seg_end.avi` =
`godot --path game --write-movie <abs path>.avi --fixed-fps 30 -- --r20ending --nomusic` (the replay of the ending from a finished save: see docs/54). New film segments in `game/scripts/autotest_r20.gd`:
`--film --seg=40` (the rainbow: approach, 14 judgements, the film moment) and `--seg=41` (the falling star in RAINBOW TIME). The judgement scenes are cut with speed ramps (1.5-4x), as the brief allowed.
**Look**: a little contrast and saturation, vignette, fine grain, flashes on the steal / the drop / the rainbow / the star, type slams (FLY. DIVE. STEAL. A FISH. A RAINBOW. A FALLING STAR.), the end card on the cover art.
Tools: `timesheet.py` (contact sheets with the time burned in, to pick in/out points), `music_probe.py`, `fit_grid.py`, `tts_probe.py`.
