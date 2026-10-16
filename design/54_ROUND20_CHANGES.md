# Round 20 - no more "bling": silence instead of ringing sounds, and WATCH STORY

## The sound (corrected after the user's reply)
First pass muted ~55 sounds; the user said that was wrong: the fry / coffee / drink / reward sounds are good and full of spirit. Only two things were bad:
the **marimba "typing voice"** (one note per typed letter, in the story boxes, the comic and the hold-E ring) and the **F call** (`lure`: a nasal sawtooth squawk).
Everything else is back (`MUTED` / `MUTED_INSTS` in `audio_manager.gd` are now empty lists, kept as a switch).

* Typing voices: gone (`story.gd` `_voice_note` and the hold-E ticks, `yonkoma.gd`); words appear silently over the real music.
* F call: new `lure.wav` (`tools/audio/r20_audio.py`): a warm two-note coo, formants 450 / 900 / 2200 Hz, soft harmonic roll-off, nothing above ~3 kHz (old: centroid 893 Hz, nasal 1.5-2.9 kHz formants).
  A roof flock arrives answering with the same call, softer and a little higher; the old shrill `rival_call` / `gull_far` cries at the flock and at the gift friend are gone. Barks are as before.
* New sounds: `page` (paper slide + a muffled tap; on every memory polaroid and every comic panel), `surf_soft` (20 s seamless calm sea, stereo, fades in under the last quiet roof scene of the ending
  and out before the comic).
* New `SFX` bus (`audio_manager._make_sfx_bus`): a very light room (wet 0.07) and a hard limiter at -1.5 dB; every sound effect and judgement note goes through it, the music does not.
  Sounds sit in one space and a busy moment cannot pile up into harshness or clipping.
* Audit (`peak / loudest 100 ms / click at start and end`) of all ~100 WAVs: peaks -2..-9 dB, no clicks, nothing to rework; the existing sounds were left alone on purpose.
* Old F call kept in `tools/audio/old_sfx_r20/lure.wav`.

## WATCH STORY (menu)
* Cover menu: START / CONTINUE / ACHIEVEMENTS / **WATCH STORY** / QUIT. Greyed (with a small line of explanation) until a finished save exists
  (`GS.finished_slot()` = first slot whose run is marked "free", i.e. the ending was seen).
* It opens a card: THE OPENING / THE ENDING / BACK.
  * Opening: `scenes.opening()` exactly as at the start of a run; at HOLD E the game goes back to the menu.
  * Ending: the first finished save is restored (its memories, the things it wore), then the real ending plays (`scenes.ending`); credits, then back to the menu.
  * `GS.replay` ("opening"/"ending") blocks every save while it plays; `_reload` clears it.
* i18n: `tools/i18n/tr_zz_r20.py` (zh_CN, zh_TW, ja), rebuilt with `python tools/i18n/build.py`.
* Dev mode: `godot --path game --write-movie <abs path>.avi --fixed-fps 30 -- --r20ending` (or `--r20opening`) records the replay with the real audio mix
  (needs `dev_savegame2.json` = a finished save in user://; quits 25 s into the credits).
