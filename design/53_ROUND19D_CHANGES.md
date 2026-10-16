# Round 19d (2026-10-16, fourth feedback)

1. + 6. **THE SEA FREEZE (found, reproduced, fixed).** In OCEAN TIME a fish that leaves the water frees its node while the rhythm on it is still running. A freed object reads as `null` in
   GDScript, so `snatch_controller._scan` (`if lock_fry != null: _update_lock`) never ran again, nothing released the gull: the rhythm stayed on (`seq != null`), `input_locked` stayed true,
   the gull fell back on the water in "surf" mode and could neither move nor take off (mouse input is zeroed while locked: the camera "twitched"). Coming back to the start did not help because the
   state lives in the snatch controller, not in the position. Reproduced with the new soak test `--r18s` (it froze after 5-6 launch cycles in two of three runs; the state dump showed
   `seq true, lock_fry null, input_locked true`). Fix: `step()` lets go of a rhythm whose fry is no longer valid (`seq != null and not is_instance_valid(lock_fry)` -> `_unlock()`).
   After the fix the soak runs clean for 9+ cycles. Test: `shots/run_r18.ps1 -Mode r18s -Extra "--cycles=16" -Limit 300`.
2. **UNSTICK button** in the pause (ESC) menu: "脱离卡死：回到出发点上空". `main.gd _unstick()`: puts the gull in the AIR 11 m above the start (the roof is not touched, so the big brother's talk does not
   start), clears the snatch state, input lock, slow motion, Gull Sight, cut-scene flags, every drink / STARLIGHT / OCEAN TIME; collection, fish book, quests are untouched.
3. **The "gling"**: `audio_manager.gd` - the `reward_1/2/3` jingles (spray of bells) are replaced by a tiny soft harp motif (two to four notes of the C triad); the two `reward_3` calls of the ending cards
   are deleted; the four-panel strip's random-pitch blip is a soft marimba on the pentatonic scale (as the story typing voice already was). The achievement sound, the keep-playing start and the
   sky rewards all use the motif now. I cannot listen: **judge it by ear**.
4. **Tunes**: `tunes.gd` - five more songs everybody knows (Mary Had a Little Lamb, Für Elise, When the Saints, Oh Susanna, Jingle Bells chorus), every catch plays the BEGINNING of a song (it
   used to start at a random phrase) and the song is chosen for the best fit to the number of judgements (a catch of 6 gets a song whose first phrases are 6 notes, 10 -> Für Elise / Auld Lang Syne /
   Amazing Grace, 18 -> Für Elise / Canon ...).
5. **Three save slots** (`GS.SLOTS = 3`); the difficulty is chosen once with a new run and the pause menu only shows it (disabled button, "SET FOR THIS SAVE"); every slot card has a green (EASY) or
   red (HARD) frame (`menus.gd _slot_border`).

Tests: `--r18s` (sea soak + UNSTICK check), r18a, r18h.
