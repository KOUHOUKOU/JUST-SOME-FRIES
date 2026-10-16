# Round 20 - no more "bling": silence instead of ringing sounds, and WATCH STORY

## The sound
The user found every isolated ringing sound unbearable (the typing "voice" in the story boxes and the comic, the F call, flocks and dogs arriving, the title and the reward jingles).
Rule from now on: **a lone bell is worse than nothing**.

* `audio_manager.gd`: `MUTED` (sound names that `play()` now ignores) and `MUTED_INSTS` (`tinkle`, `glock`, `xylo`: the bell voices that sat on top of the judgement tunes).
  Muted: chime, ready_chime, perfect, vn_next, vn_pop, tick_ui, ui_go, count_tick, gs_tick, gs_complete, success, blip, drop_tick, equip, heart, hello, feed, star_on/off/riser,
  friend_come/gift/welcome, meteor_get/pass, ring_ok/gold, prism_0..6, special_*, buff_*, tonic, reward_1..3 (the harp flourishes), lure (the F call), cine_in/out.
  They were chosen by measurement (spectral flatness ~ 0 = a pure ringing tone) and by where the user heard them.
* The typing voices are gone (`story.gd` `_voice_note`, the hold-E ticks, `yonkoma.gd`): words appear silently, the music carries the scene.
* F (squawk): no sound at all (the visual kick stays); a roof flock arrives without a cry; the gift friend does not cry out either; dog barks lowered and un-pitched.
* Still sounding: wings, steps, landings, wind, water, crunch, thuds, people's "oh", dogs, the real orchestral music, and the main instrument of the judgement tunes
  (kalimba / music box / harp / celesta / marimba) - the tune itself, without the bell on top.
* `tools/audio` is untouched (the WAVs are still in the project, just not played): to bring one back, remove it from `MUTED`.

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
