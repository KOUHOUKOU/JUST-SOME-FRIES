# Round 19c (2026-10-16, third feedback)

1. **Bigger target rings, faster waves** - `hud.gd` geo table (1 circle 158, 2: 136, 3: 92, 5: 128, 7: 90, 9: 86 at 720p) and `DP.appr` EASY 0.74 s (was 0.95), HARD 0.66 s. The bands are
   judged in seconds (unchanged), so a faster wave over a bigger ring makes the green / gold bands about 50 % thicker on the screen: thicker = easier, faster = harder, about even.
2. **Translation polish** - `tools/i18n/tr_zz_r19b.py` (wins over everything): opening and title cards, ending memories, a few big-brother lines, the rhythm instructions ("gold counts double"
   -> "金色算两次"), small items. (There is no Korean in the game; zh_CN, zh_TW and ja were all polished.)
3. **The whole piece is played** - `snatch_controller.gd _note_result`: the rhythm ends only when every note has been judged, then it counts (`points >= need`). Gold is still worth two points, so
   after golds one miss is forgiven; no early success, no early failure.
4. **Sea take-off see-through** - the camera swung under the (one-sided) sea plane and showed the sea bed. A camera-only plate (collision layer 16, `world_builder.gd cam_floor`) sits just above
   the water and the gull's camera arm (`collision_mask = 1 | 16`) cannot go below it.

Tests: r18a 31 PASS, r18h 12 PASS (its easy test now checks "two golds do not end it, the piece counts at its last note"), r18n (EASY novice) passes, `--rhythm` classic bot runs
(its "all gold" case is a 30 fps bot problem: a frame is longer than the gold window; it was hidden by the old early finish).
