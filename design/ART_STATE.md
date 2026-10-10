# ART_STATE - autonomous art round (read this first in any new session)

## Final delivery — S4 COMPLETE, STOP (2026-10-11)

S7 approval is Review 15. Final entry: [44_FINAL_ART_REPORT.md](44_FINAL_ART_REPORT.md). Four 1920px ORIGINAL/FINAL/COVER sheets and 30 captures in `art_src/final/`; one real capture produced `film/art_remaster_preview.mp4` (40s, 720p30, game audio) and eight frames. Local Windows + patched Web rebuilt; packaged headless smoke exit0, no warnings/errors. EXE179.00 MB, PCK32.26 MB, Web72.27 MB; content +4.55 MB versus an explicitly reconstructed pre-art baseline. Weak reflections, regular rock strata, rigid people, simple boats/props and occasional camera occlusion remain. No new art/gameplay/audio/save edits; no download/push/upload/publish. **Do not launch another phase.**

Owner while the user is away: Claude (art director + gatekeeper). Builder: Codex via `tools/codex/run_codex.ps1`.
User authorised (2026-10-10): unattended iteration; scoped command allowlist in `.claude/settings.local.json`; deliver a local build + before/after sheets; NO git push, NO release upload, NO web publish.

## Rules of the loop
1. Claude launches Codex for one phase (prompt file in `art_src/_codex/prompt_<phase>.txt`, Codex model `gpt-6-astra` xhigh for design-heavy phases, `gpt-6.1-sol` high for rollout).
2. When Codex finishes, Claude reads `art_src/_codex/latest.md`, opens every review PNG, writes honest notes to `docs/ART_REVIEW.md`, then either (a) resumes Codex with the notes, or (b) approves the phase.
3. Max 4 review rounds per phase. After round 4 Claude either accepts with a "known defects" note or cuts scope. No endless loops.
4. Claude is the gatekeeper for every STOP gate in docs/35 (the user reviews only the final delivery).
5. Backup of the pre-art code: `backup/pre_art_round14/` (scripts, shaders, scenes, project.godot, AGENTS.md). To roll back, copy it over `game/`.
6. Gentle machine: low render samples, no loops, no full test suites per iteration.

## Quality bar for approval (all must hold)
- Silhouette readable at 60 m; gull never blends into sky or ground.
- Fries are the hottest, most saturated gold in every shot.
- Shadows warm-violet; no grey/black dead areas; no z-fighting, flipped normals, floating parts.
- Budgets in docs/35 section 3 respected; draw calls and first-frame time not worse than before.
- `--autotest` result identical; procedural fallbacks intact.

## Progress log
- 2026-10-11 S7 submitted and STOPPED after four art iterations. Review14 headland lowered24→12m only after rejected decorative overlay; layered skirt/foam. Native cold-process median1022→600ms (target916), all10 draw pairs lower, exact171-style/noise bake caches,1498 colliders/68 grounded translations/two anchors down12/thermals exact; final24/24→rainbow→ended=true phase=3. Still regular bands, three original turbines, weak reflections. Review `art_src/s7/review/README.md`; details at top of36/ART_MANIFEST. NOT art-approved; no S4/export.
- 2026-10-11 S6 submitted and STOPPED after four internal art iterations. Review13 whole-island audit: 22 golden-hour world cameras + actual title, worst10 ranked with images, first8 addressed. Start at `art_src/s6/review/README.md`, `ranking_1/2.jpg`, `summary_before_after_cover.jpg`; final captures `iteration_4/game/`. 25/25 matched draws/tris no worse, 1498 identical global colliders/anchors and 171 NPC layouts/styles, contract PASS, one full 24/24→rainbow→ended=true phase=3 run. **NOT art-approved; strict build-time gate UNPROVEN**: matched641→551ms, repeated native medians916→1115ms, warm-resource medians992.6→1016.6ms. Tall headland/flat light/weak reflections/simple props remain. All evidence/failures retained; no S4, web export, download or publish. Details at top of ART_MANIFEST and 36_ROUND14_CHANGES. No automatic next phase.
- 2026-10-10 19:28 Codex P0 (pipeline) launched (gpt-6-astra xhigh, danger-full-access). Status: running.
- 2026-10-10 P0 DONE: pipeline approved (see ART_REVIEW.md Review 1); look/shader calibration open. Perf gate redefined (draw calls/tris/shader cost; ignore noise).
- 2026-10-10 P1a (hero gull + shader calibration) launched via `resume --last` (gpt-6-astra xhigh). Prompt: art_src/_codex/prompt_P1a.txt, spec: docs/37_P1A_GULL_SPEC.md. Next: P1b (tree, house, person) -> P2 people/wearables -> P3 world kit -> P4 life -> final build + before/after sheets.
- P1a review round 1 done: gull too pink/lilac, wings weak, perch ball-like -> round 2 launched (prompt_P1a_r2.txt, ART_REVIEW Review 2). Max 4 rounds.
- P1a APPROVED (Review 3). P1b (tree, house, person) launched; spec docs/38; prompt art_src/_codex/prompt_P1b.txt.
- P1b round 1 reviewed (Review 4): trees sickly/pale, scene flat, apron floating, limbs thin, roof contrast -> round 2 launched.
- P1b APPROVED (Review 5). Next P2: fries + gull wearables + dog + special NPCs.
- P2 (fries, wardrobe, dog/fish, special people) launched; spec docs/39.
- P2 resume FAILED (session context 1.3M tokens -> stream disconnect). Rule: from now on every phase uses a FRESH Codex session (no -Resume); state lives in docs. P2 relaunched fresh.
- 2026-10-10 P2 delivered by fresh Codex session; **STOPPED for Claude review, NOT approved**. Three internal iterations maximum. 39 GLBs, visual-only hooks, 24/24 ending run and final asset/pivot contract checks; 237 viewed PNGs. Start at `art_src/p2/review/` and the new top sections of `ART_MANIFEST.md` / `36_ROUND14_CHANGES.md`. Final held-person captures: `art_src/p2/iteration_3/game/details_held_final/`. Open limits include 60m fry visibility, matte fish/weak markings, wardrobe detail/occlusion and cropped Big Bro VN hat. No P3 or web export.
- P2 reviewed (Review 6): mostly good; fish ghost rectangles, VN evidence missing, special fry tint -> P2 r2 launched (fresh session).
- P3 spec written (docs/40) + prompt_P3.txt; launch after P2 r2 is reviewed.
- 2026-10-10 USER PAUSED the autonomous loop: results judged not a substantive upgrade (gull lost its cute/dumb charm, people ugly). New brief from user: C:/Users/ROG/Downloads/writing-block.md (Art Remaster Master Brief): reuse open-source assets, cover.jpg is the target look. P2 r2 Codex run stopped. Await direction.
- 2026-10-10 Direction v2 (docs/41): target = cover.jpg. Kenney CC0 kits (7 packs, ~31 MB, licences verified CC0) are in art_src/third_party/_quarantine. Review 7 retracts gull/people approvals. S1 gull rebuild launched (art_src/_codex/prompt_S1_gull.txt). Plan: S1 gull -> S2 cover lighting/atmosphere -> S3 Kenney kits for cafe+pier -> S4 before/after + clip.
- 2026-10-10 S1 submitted and STOPPED after four internal geometry iterations; **NOT approved / silhouette gate FAIL**. Faceted gull 714 tris / 11 parts / 1 material; wardrobe mesh-local refit; original pivots and procedural fallback retained. IoU front .862900, left .455244, top .722123. Contract and full 24/24-to-ending regression pass; visual defects remain (side/top shape, wing seams/fold, VN crop, floating necklace). Start at `art_src/s1/review/`, with final status at the top of `ART_MANIFEST.md` and `36_ROUND14_CHANGES.md`. No S2 or web export.
- 2026-10-10 CLEANUP at user request: old phase plan (P2 r2, P3 world-kit prompts/specs) cancelled and moved to _cancelled/ folders. Only docs/41_COVER_DIRECTION.md + sequence S1..S4 are active. NOTE: P2 r2 Codex run was killed mid-way; verify state during S1 regression (fish/VN/fry files may be half-edited).
- S1 round 1 reviewed (Review 8): charm back, but dirty banding/grey, side IoU 0.455, beak big, VN crop. Round 2 launched.
- 2026-10-10 USER COMPLAINT: test windows captured the real mouse. FIXED in main.gd/menus.gd: runs with user args never capture the mouse, window gets NO_FOCUS. Verified headless parse OK.
- S1 APPROVED (Review 9). S2 cover lighting/atmosphere launched (docs/42, prompt_S2.txt). Next S3 Kenney kits for cafe+pier, S4 before/after + clip.
- S2 APPROVED as lighting base (Review 10). S3 kits + ground/cliff/water/pier/cafe launched (docs/43, prompt_S3.txt).
- DASHBOARD: user cannot see live progress. A progress page is published (https://claude.ai/artifact/9FAyvm2QYEwjY8MCLZ5nRQ); source tools/dashboard (progress.json + build.py + template.html). RULE: after every Codex completion/launch and every review, edit progress.json, run python -I tools/dashboard/build.py, republish tools/dashboard/dashboard.html (same path => same URL).
- 2026-10-11 S3 submitted and STOPPED after four art tuning iterations (final normal/index correctness fixes verified within iteration 4). NOT art-approved. Final evidence `art_src/s3/iteration_4_verified/`, sheets `art_src/s3/review/`; 15 CC0 exports / 1898 tris, all 17 A/B draw/triangle rows lower, matched build 1104 -> 978 ms (separate autotest startup 1521 ms). 1498 identical collider shapes/anchors; one 24/24-to-ending run. Cover gaps remain: smooth headland, flat reflections, pale buildings, sparse fleet/props. Existing sailboats/houses retained; no S4/export. Concurrent audio-manager edit recorded, not made or reverted by S3. See top of ART_MANIFEST and 36_ROUND14_CHANGES.
- S3 reviewed (Review 11): sand/furniture better, but pale/lilac, headland dome, low contrast. S3b richness pass launched (prompt_S3b.txt).
- 2026-10-11 S3b submitted and STOPPED (second S3 review round, three internal passes). Final `art_src/s3b/final/`, sheets `art_src/s3b/review/`; 17/17 draws/tris lower, S3 build 978 -> 846 ms, 1498 shape hashes/anchors identical, exact terrain cache + fallback, 22 colour-only house GLBs, one final 24/24-to-ending run. NOT art-approved: town/cafe screen metrics near cover, other contrast/water targets and natural cliff shape remain open. No S4/export. See top of ART_MANIFEST and 36_ROUND14_CHANGES.
- S3b APPROVED as island look base (Review 12). S5 people (cover style) + polish launched (prompt_S5_people.txt). S4 (before/after + video) moves to the END so it shows the final state.

- 2026-10-11 S5 submitted and STOPPED after three internal art iterations; NOT art-approved. Cover people 665-1271 tris / 8 visible body draws (<=10 with two held props), old generator archived. Wings lighter, paving/deck warmer, headland broader but still high. All 11 matched draw/triangle rows lower; 1498 collider shapes and 171 people positions/styles unchanged; final 24/24-to-ending run. Startup non-regression unproven (597 -> 746 ms). Review `art_src/s5/review/people_cover.png` and new top sections of ART_MANIFEST / 36_ROUND14_CHANGES. No S4/export.
- S5 APPROVED (Review 13). S6 whole-island audit + fix of worst 6-8 spots launched (prompt_S6_island.txt). Then S4 final before/after + video.
- S6 reviewed (Review 14): island coherent; blockers headland cone + build-time regression -> S7 launched (prompt_S7.txt). Then S4 final deliverables.
- S7 APPROVED (Review 15). S4 final delivery launched (prompt_S4_final.txt): original-vs-final sheets, clip film/art_remaster_preview.mp4, local builds, docs/44 report. No push/upload.
