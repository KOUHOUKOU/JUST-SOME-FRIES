# S4 final delivery — COMPLETE (2026-10-11)

The S7 art state below was subsequently **approved in ART_REVIEW Review 15** and is now packaged. [Final report and artifacts](44_FINAL_ART_REPORT.md): four ORIGINAL/FINAL/COVER sheets, a 40-second real 720p30 game clip with audio, eight stills, local Windows/Web builds. S4 introduces only optional review/movie harnesses and delivery tooling; no model/material/gameplay/audio/save changes. All 14 measured ORIGINAL/FINAL world-camera rows have fewer draws/tris. Windows smoke exits0 cleanly; Web export/patch statically checked, browser play not rerun. Known art defects remain listed in the final report. **STOP.**

---

# S7 current headland / startup delivery — STOP after four iterations

2026-10-11. Review 14. Submitted, not art-approved. Native five-process median **1022→600 ms**, below the historical pre-S6 **916 ms** target. Full measurements, fallback rationale and remaining defects are at the top of [36_ROUND14_CHANGES.md](36_ROUND14_CHANGES.md). Review [three-camera before / final / cover](../art_src/s7/review/iteration_4_verified_before_after_cover.jpg).

| Asset/system | Source / runtime | Delivered cost / contract |
|---|---|---|
| Low layered local headland | `tools/blender/s7_headland.py`; `kenney_parts.gd` / scenery loader | `game/assets/models/s7/headland.glb`; **480 tris, 1 surface, 55,892 bytes**, existing material. 12 reused 72-tri Kenney CC0 rocks in same district. No new material or texture. |
| Local height fallback | `terrain.gd:HEADLAND_HEIGHT`, `world_builder.gd` | Headland 24→12 m, cap radius24 / influence radius40 unchanged. Full regenerated `s7/terrain.res` **193,446 bytes**. 1498 colliders; 68 origins follow ground; two anchors down12; all other anchors and nine thermals exact. Five NPCs down12; all 171 styles exact. |
| Visible terrain cache | `s7_bake.gd`, `terrain.gd:visual_mesh` | `s7/terrain_visible.res` **266,402 bytes**; 1071 already-discarded triangles omitted from rendering only. Complete collision preserved; complete mesh used if optional art missing. |
| Exact 171-style person cache | `s7_bake.gd`, `person_parts.gd` | `s7/person_variants.res` **2,395,888 bytes**; all final arrays identical, source fingerprint/version check, shared material, generation fallback. Dot-eye meshes/animation remain, redundant eye shadow submissions off. |
| Exact ground noise images | Same bake; `terrain.gd` | `s7/ground_coarse.res` **62,918**, `s7/ground_fine.res` **61,548 bytes**, exact procedural pixels, old generation fallback. |
| Tidal foam / rotor batches | `sea.gdshader`; `world_builder._turbine` | Existing sea pass; no extra material/sampler/process. Three original rotor visuals merged individually, original collider children/rotation retained. |
| Audit / reproducibility | `run_s7.ps1`, `s7_audit.py`, `s7_contract.gd`, `s7_profile.gd` | Raw five-process logs, 10 fixed camera/quality pairs, all171 cached styles exact, landing rays and local collider comparison, final24/24→rainbow→ending. No web export/download/desktop input. |

All **10/10 camera draw counts lower**, close cafe 3/15/60 m **1410→1179 / 1754→1507 / 2292→2055** at governor0. First actual review-frame draws1298→1198; short startup first menu frame119 unchanged. Two tiny triangle-count increases (+26 / +49) and mixed GPU timing remain; no universal all-metric or web speed claim. Final measured resources add about **3.04 MB** total on-disk resource-file size (sum of internally compressed files), trading download/storage for avoided synchronous build work; actual PCK/network compression is unmeasured.

Existing S6 headland remains for the far decorative island and historical assets; all pre-existing GLBs are unchanged. CC0 rock provenance is the existing `assets/art/kenney/rock.glb` entry in `art_src/third_party/ASSET_MANIFEST.md`. New headland is project-authored; no external asset acquisition. Old source/candidate evidence is retained under `art_src/s7/baseline/` and `iteration_1..4/`.

Honest defects: still mechanically layered large rock facets, fine diagonal shading pattern, weak water reflections/lighting, partly obscured white house; **three original solid gameplay turbines, not the requested cover pair**. Skirt/foam are non-solid decoration. Absolute lighthouse/turbine heights changed with the explicitly authorised local profile fallback; they are not unchanged anchors. 4.7.1 native only; capped tests force/check governor policies but do not exercise live automatic degradation. No taste approval claimed. **STOP S7; S4 not started.**

---

# S6 current whole-island pass (2026-10-11)

**Four internal art iterations; submitted and STOPPED, not art-approved.** Draw/triangle comparison passes; build-time non-regression remains **UNPROVEN**. This section supersedes the headland/crop/horizon visuals described below; S5 people, gull, houses and their authored GLBs are retained. Full numbers/limits: top of `36_ROUND14_CHANGES.md`. Entry: [review index](../art_src/s6/review/README.md), [before / after / cover](../art_src/s6/review/summary_before_after_cover.jpg).

| Asset/system | Source / output / integration | Budget / contract |
|---|---|---|
| Wheat | Local Kenney nature-kit `crops_wheatStageB`; `tools/blender/s6_world.py` through `import_kenney.py`; `game/assets/models/s6/wheat.glb` | 112 tris, 1 surface; 40 placements at original row centres |
| Leaf crop | Same pipeline, `crops_leafsStageB`; `game/assets/models/s6/leaves.glb` | 82 tris, 1 surface; 80 small clumps replacing 40 box rows; original centres/terrain retained |
| Ivy | Same pipeline, `hanging_moss`; `game/assets/models/s6/ivy.glb` | 52 tris, 1 surface; non-solid terrace dressing |
| Irregular headland skirt | Project-authored in `s6_world.py`; `game/assets/models/s6/headland.glb` | 240 tris, 1 surface; no collider, original plateau/landmarks fixed; decorative distant island reuses it |
| Runtime loader / fallback | `game/scripts/art/s6_parts.gd`; `kenney_parts.gd`, world builder/extra | Existing `Art.material`; 486 unique GLB tris total. Missing/invalid/disabled assets use existing procedural fallback. Crop district meshes cast no shadows. |
| Building dressing | `s6_parts.gd` | Marina supports/windows, barn/warehouse/church trim, playground gable/slide edges; all non-solid, shared static batches |
| Colour / ground | `world_builder.gd`, `world_extra.gd`, `ground.gdshader` | Terracotta roofs, warm masonry/furrows/playground ground; no new sampler/pass |
| Horizon | `cover_atmosphere.gd` | 60-triangle uneven ridge forms replace decorative domes; same haze batches/materials and landmark positions |
| Geometry offsets | `batcher.gd`, `world_flora.gd`, `s6_parts.gd` | Small visual spheres 8×4, tiny flower/pebble shapes 8 tris, merged windmill rotor; original RNG/positions/colliders retained |
| Person cache build | `person_parts.gd` | Singleton parts avoid SurfaceTool reconstruction; existing GLB/tint/rig/face geometry unchanged and contract-tested |

Third-party licence/source/output SHA256 and palette records: `art_src/s6/assets.json`, `art_src/third_party/ASSET_MANIFEST.md`. All source kits already existed locally; no download. Original assets remain byte-identical; `art_src/s6/baseline/` stores pre-edit hashes/source. No gameplay/text/audio/save change. 1,498 collider transforms/shapes, all anchors and 171 NPC positions/styles match exactly.

Evidence: **22 fixed golden-hour world cameras + title**, all source captures <=960×540, in `baseline/game/` and `iteration_4/game/`; all four candidate rounds retained. 25/25 matched native governor-0/2 samples no worse draws/tris: draws −16..0; rendered tris −153,892..−5,712. Rush **2987→2972 draws / 925592→786136 tris**. Native Compatibility Godot **4.7.1**, not requested 4.6.3/web certification. Capped timings are not throughput evidence.

Timing is unresolved: matched build **641→551 ms**, alternating native medians **916→1115 ms (+21.7%)**, warm-resource builder medians **992.6→1016.6 ms (+2.4%)**. The strict no-worse build-time gate is not passed. Render CPU/GPU samples are mixed. Raw samples/failure logs remain in `art_src/s6/`; see full change log before accepting budgets.

Final regression **24/24 → rainbow → ended=true phase=3**; final asset/fallback/person contract passes. Shutdown retains inherited GLES/ObjectDB leak errors and shell exit 1, despite successful completion markers. Every generated screenshot/render inspected, indexed in `viewed_images.json`. The rush view is a fixed 24 m/s pose, not a clip; cafe-floor review is staged, while `autotest/a08_ending.png` shows the actual ending.

Remaining: cliff still too tall/regular, shadowless chunky crop clumps, repetitive masonry, sparse playground, simple harbor/boats, garden camera partly blocked by pine, stiff S5 people, weak sea reflections and flat lighting relative to cover. All test runs use isolated paths and uncaptured mouse/NO_FOCUS. **STOP S6; no S4, web export or publishing.**

---

# S5 current person / Review 12 polish (2026-10-11)

**Submitted after three internal art iterations; STOPPED, not art-approved.** This section supersedes the old smooth-person appearance and budgets below. Review entry: `art_src/s5/review/people_cover.png`; final game/Blender captures: `art_src/s5/iteration_3/`. Full measurements/limitations are at the top of `36_ROUND14_CHANGES.md`.

| Asset | Generator / integration | Delivered GLB | Source tris / surfaces | Status |
|---|---|---|---|---|
| Flat-faceted cover person, 7 hair choices incl. bald | `tools/blender/person.py`; `person_parts.gd`; `human_rig.gd` | `game/assets/models/person_parts.glb` | **665 bare, 1,271 worst body combination**; 9 named interface parts, **8 visible body draws**, <=10 with two merged held items; 1 shared material; **211,816 bytes** | Submitted; rigid shoulders/legs and tiny vest-edge slivers remain |
| Gull wing paint | `tools/blender/hero_gull.py` (`--s5 --no-render`) | `game/assets/models/hero_gull_parts.glb` | **734 / 11 / 1**, unchanged geometry | Upper/forewing paint near-white/pale lilac; dark tips retained |
| Headland rock skirt | `kenney_parts.gd:headland` | Existing runtime scenery batch | **144**, unchanged | Broader asymmetric foot; unchanged playable cap/collisions; still too tall vs cover |
| Cafe paving / decking | `ground.gdshader`, `decking.gdshader` | Existing ground/deck geometry | No new draws/materials/samplers | Warmer, more plank/tile contrast; local bounce remains absent |

Old person generator: `tools/blender/archive/person_smooth_pre_s5.py`. Original asset and sources retained in `art_src/s5/baseline/`. New source is deterministic, entirely flat-shaded and untextured; no bone, imported animation, external dependency or sophisticated rig.

## S5 person contract (same pivots)

The exact hierarchy in the historical **Exact person pivot contract** section remains authoritative. `root/upper/torso/head/arm_l/r/hand_l/r/leg_l/r/hand_anchor` positions, rotations and ownership do not change. Face remains +Z; source parts are pivot-local. Original eye transforms are retained, with the new face offsets baked into the eye meshes. Original `Mouth` transform/reference remains emote-scalable but its tiny internal compatibility mesh is hidden: cover people have no drawn mouth. The complete procedural fallback still has its old face and is untouched.

All 13 modes retained: idle, walk, jog, eat, chat, fish, paint, sit, lie, wave, alarm, play, recline. `hand_anchor` remains outside the scaled root and follows the existing left hand plus world Y .02, with upright yaw. No controller, hitbox, fry placement or snatch timing change.

Recolour IDs remain **UV.x = region / 15**: 0 fixed, 1 skin, 2 shirt, 3 pants, 4 hair, 5 shoes, 6 hat, 7 pack colour, 8 vest colour, 9 inherited blush channel (unused in S5), 10 cream apron. RGB holds linear pigment with <=1.6% facet variation, alpha stays opaque. `person_parts.gd` builds the same cached style variants, merges head/hair/glasses and torso/clothes, and computes inverse-transformed normals for `fat`. Tint factors are now decoded once per region, not once per vertex. Existing `scale`, `fat`, `glasses`, `apron`, `vest`, `vest_color`, `backpack`, `pack_color`, hair styles and original held-item/balloon paths remain.

VN's gull-only fit branch now checks `worn != null` as well as `authored`, preventing a human from accessing gull-only fields. No changes to the portrait camera formula, live viewport size, story content, timing or UI layout. Elder/child/sunhat production VN box fixtures are shown in the final evidence; complete heads/hats fit. They are review fixtures, not newly added story speakers.

## S5 checks and honest limits

`art_src/s5/contract.json`: 9 styles × 13 modes × 3 modifier sets × 45 frames, including held anchors, emotes, child scale, arm overrides, source flat normals, tint regions, shared material, cache and missing/invalid fallback. `comparison_metrics.json`: all **11/11** matched frames lower draws/tris; 171 identical NPC positions/styles; 1,498 identical collider shapes and unchanged anchors. Cafe 3 m **2,721→2,504 draws / 1,010,521→882,844 rendered tris**; pier 60 m **1,788→1,664 / 765,138→691,694**. One native material, no extra rendering pass. The body triangle budget excludes unchanged held props.

One full final-art `--autotest` completed **24/24**, obtained a rainbow fry and reached **`ended=true phase=3`**. SPECIAL_ORANGE required the inherited second approach after the first targeted MISCHIEF. About 300 game seconds; no gameplay edits were made to obtain the result. Bot incidental stats differ from S3b (perfect 2, walls 5, drinks 0). Final log: `art_src/s5/final_Autotest.log`.

Native Godot 4.7.1, not separately certified on 4.6.3 or web. Build samples **597→746 ms** (other iteration sample 596 ms; full-autotest 842 ms): **startup non-regression unproven**, no speed claim. The flat-normal GLB is larger than the old 102,444-byte smooth file despite fewer tris. GPU/capped-frame variability and inherited shutdown leaks are reported in the full change log.

Seen: simpler dot faces and larger head silhouettes; clothing/poses readable at 15 m; small coloured figure silhouettes at 60 m, face detail unavailable. Remaining: stiff legs/shoulders, dark hair under dusk, raised-hand crowding, bulky optional-clothes stack and tiny shirt slivers at vest shoulders. Pale wings remain flatter-lit than the cover. Headland is still a tall faceted mound because its gameplay plateau remains fixed; broad visual skirt is non-solid. Sea reflection and regular rock-wall defects remain open. No artwork approval is claimed.

All review runs assert uncaptured mouse and NO_FOCUS; no desktop mouse/keyboard automation. EEVEE 8 samples / 4 threads, Blender 320 px, game <=960×540, isolated runtime inside `art_src/s5`. No download, MCP server, web export or publishing. `s5_audit.py` confirms gull geometry unchanged and scope hashes; `s5_sheets.py` composes unretouched evidence. **STOP S5; no S4 started.**

---

# S3b art manifest — round 2/3, STOP for review

2026-10-11. Final art is in `art_src/s3b/final/`; review sheets in `art_src/s3b/review/`. Three bounded internal passes; **not art-approved, full cover metrics not passed**. Full numbers and defects: top of `36_ROUND14_CHANGES.md`.

| Asset/system | Reproduction/runtime | Change / budget / contract |
|---|---|---|
| 22 existing houses | `tools/art_pipeline/s3b_palette.py`; `game/assets/models/house_00..21.glb` | COLOR_0 repaint only, roof terracotta/coral; wall cream/peach/butter/sage. All other bytes identical; same tris/material/footprints. Hashes: `art_src/s3b/house_palette.json`. |
| Shared palette | `soft_toon.gdshader`, `day_cycle.gd`, `ground.gdshader`, `decking.gdshader` | Richer pigment, deeper cool shadow, warm paving/wood, reduced fog, stronger window/lamp emission. Gull's separate white response retained; no new material or light. |
| Headland rock skirt | `kenney_parts.headland()` | 144 tris in existing district batch, replacing 9 × 136-tri crags. Non-solid; original terrain/colliders/anchors retained. Original ground shader path used if kit unavailable. Large regular facets remain a defect. |
| Lighthouse | `world_builder._headland()` | Three painted non-solid red bands made visible outside original cylinder. No collider or anchor change. Existing 3 gameplay turbines, small house and pines retained. |
| Cafe dressing | `kenney_parts.cafe()`, `cover_atmosphere.finish()` | 2 striped canopies, 12 festoon bulbs, 3 railing globes; existing shared batches. Planters/people/food/colliders unchanged. No local point lights. |
| Lamp/window batching | `batcher.gd` | Bulbs use 6 segments/3 rings; emissive lamp/window batches cast no shadows. Shared materials retained. |
| Water | `sea.gdshader` | Blue-teal depth, orange sun glitter, filtered ripples, S3 soft shore/post foam. Same opaque 18-triangle plane, no reflections. Governor ≥2 disables glitter. |
| Exact terrain cache | `game/assets/models/terrain_s3b.res`, `s3b_bake_terrain.gd` | 193,536-byte compressed resource. Same vertices/normals/colours; procedural fallback still in `terrain.gd`. Rebuild cache if terrain source changes. |
| CC0 kits | Original S3 15 GLBs / 1,898 tris | No new third-party import/download. `crag.glb` now retained but not placed; other provenance remains in third-party manifest. |
| Evidence | `run_s3b.ps1`, `s3b_evidence.py`, `s3b_scope.py`; S3 test harness opt-in | 17 matched rows, missing-kit and terrain-array contract, 1498 shape hashes/anchors identical, final 24/24-to-ending run. No desktop input or web export. |

Cafe 3/15/60 m draw calls **1539 → 1535 / 1917 → 1914 / 2497 → 2493**. All 17 final rows reduce draws/tris. S3 build **978 → 846 ms** (fresh pre-edit 1063 ms; separate final autotest 857 ms). Native capped timing is not browser throughput proof; existing shutdown leak warnings persist.

Colour ROI means/stds: town **S .240 → .463 (cover .426), std .138 → .165 (.177)**; cafe **S .301 → .400 (.469), std .182 → .177 (.195)**. These two mixed lit/shadow screen crops lie within approximately 15%; wood, paving, headland and water do not all pass. Fixed crop definitions and every result, including failures, are in `colour_measurements.json`. Gull forehead remains near-white at all three times.

Honest defects: large regular cliff facets and symmetrical mound, three tall original turbines, repetitive water bands/no scene reflections, weak pier-view glitter because camera faces away from sun, simple unlit wall backs/furniture, hard shadows, mixed overly green foliage. Cafe lights are emissive visual accents, not plaza illumination. The colour comparison is a screen-region proxy rather than isolated, geometrically matched lit pixels. **STOP; no S4.**

<!-- END S3B HANDOFF -->

---

# S3 CC0 kit and scenery manifest — STOP for review

2026-10-11. Current final evidence: `art_src/s3/iteration_4_verified/`. Four art tuning iterations plus technical verification corrections in iteration 4. Submitted, **not art-approved**; no S4 or web export. Target is the cover, and the cliff/water/building weaknesses below remain open.

| Asset / system | Source / runtime | Budget / status |
|---|---|---|
| CC0 kit pipeline | `tools/blender/import_kenney.py`; `game/scripts/art/kenney_parts.gd`; `assets/art/kenney/*.glb` | 15 exports, 1,898 total tris, all flat / COLOR_0 / one surface; one shared `Art.material()`. Source licences and per-file records in `art_src/third_party/ASSET_MANIFEST.md`. |
| Ground / water / decking | `ground.gdshader`, `sea.gdshader`, `decking.gdshader` | Clean sand/grass/stone; 18-triangle opaque water plane, fragment waves/glitter; one new deck shader. Height/collision unchanged. |
| Kit placement / batching | `kenney_parts.gd`, `world_builder.gd`, `batcher.gd` | Original builder collision and RNG calls retained, static district merge, palm MultiMeshes, procedural fallbacks. Windows/lamps/emission keep their existing materials. |
| Terrain build cache | `terrain.gd:build_mesh` | Cache identical H samples; old/new vertices, colours, normals and shape hash equal. |
| Striped canopies | `kenney_parts.umbrella` | 48 indexed triangles per canopy, matching original positions/envelope; existing collider calls retained. Final index fix validated in real game and contract. |
| Tests / evidence | `s3_review.gd`, `s3_contract.gd`, `tools/art_pipeline/run_s3.ps1`, `s3_delivery.py`, `s3_scope.py` | 17 matched measurement rows, 1498 identical collider shapes, unchanged anchors, one full 24/24-to-ending run. |

| Export | Tris | Metre bounds (x,y,z) |
|---|---:|---|
| `cliff.glb` | 32 | [5, 4, 1.2] |
| `crag.glb` | 136 | [9, 20, 8] |
| `rock.glb` | 72 | [3.8, 1.4, 3] |
| `bush.glb` | 32 | [1.1, 0.85, 0.95] |
| `flower.glb` | 73 | [0.25, 0.55, 0.25] |
| `rowboat.glb` | 171 | [2, 0.85, 5.2] |
| `barrel.glb` | 148 | [0.68, 0.9, 0.68] |
| `crate.glb` | 76 | [0.85, 0.85, 0.85] |
| `planks.glb` | 48 | [1, 0.12, 1] |
| `palm.glb` | 482 | [3.8, 7.8, 4.8] |
| `table.glb` | 78 | [1, 0.81, 0.8] |
| `chair.glb` | 162 | [0.46, 0.97, 0.46] |
| `plant.glb` | 60 | [0.7, 1.28, 0.7] |
| `plate.glb` | 140 | [0.27, 0.025, 0.27] |
| `drink.glb` | 188 | [0.14, 0.28, 0.14] |

Cafe 3/15/60 m draw calls **1693→1539 / 2079→1917 / 2661→2497**; all 17 rows reduce draws/tris. Matching-camera build **1104→978 ms**; separate autotest startup 1521 ms, so no universal startup/performance claim. Full absolute CPU/GPU and governor 2 table: top of `36_ROUND14_CHANGES.md` and `art_src/s3/audit.json`.

Review entrypoints: `art_src/s3/review/summary_before_after_cover.png`, `cafe_before_after_cover.png`, `ground_before_after_cover.png`, and four named camera sheets. Final Blender models: `kit_review_final_flat/`. Failed variants, including too-ornate `ship-small` and unusable extracted sail, are preserved outside the shipping GLB folder. Existing sailboats, fishing boat, house family, menu boards, loungers, towels, tiki bar and S2 lamp/window system remain; they are not newly authored S3 families. `rock.glb` is a retained pipeline prototype/availability guard, not final visible placements.

Open quality defects: headland is still a smooth mound with attached rock accents; water has no scene reflections; pale building/paving values, hard shadows, sparse cafe decoration, angular palm leaves and plain house backs remain below the cover. Source/geometry checks do not certify artistic acceptance or human experience. The full autotest preceded the last canopy indexing correction; final focused camera/physics/contract checks followed it. Native shutdown leak warnings remain.

One unrelated audio-manager loop-length edit appeared concurrently and was preserved without modification; exact diff is in `art_src/s3/source_scope.json`. S3 made no gameplay/number/text/audio/save edits. No downloads, no desktop input, no export. **STOP for director review.**

---

# S2 cover atmosphere manifest — STOP for review

2026-10-10. S1 is approved by ART_REVIEW Review 9. This top entry describes the **S2-only** visual delivery; historical S1/P entries below remain provenance. Four internal art iterations, with the native-glow diagnostic corrected during final validation. No S3 or web export. Detailed A/B table and limits: top of `36_ROUND14_CHANGES.md`.

| Visual asset / system | Runtime files | Geometry/material cost and contract |
|---|---|---|
| Four-time colour script / sky | `world/day_cycle.gd`, `shaders/cover_sky.gdshader`, `world_builder._environment` | One sky material; existing directional light/environment. Clock, progress and catchable sun coordinates unchanged. |
| House/shop windows and street lamps | `world/cover_atmosphere.gd`, existing `window`/`lamp` batch materials | Glass overlays use recorded original house window centres; all decorative additions non-solid. Two existing shared materials, no per-window process. Procedural house path remains. |
| Cafe/pier festoons / Ferris lights | `cover_atmosphere.finish/wheel_lights`, `cover_halo.gdshader` | 36 string cores in existing static lamp batch; 24 six-sided wheel bulbs in one moving-parent MultiMesh. 180 scene + 24 wheel halo quads in two MultiMeshes. Zero new OmniLights. |
| Teal water / shore foam / sun glitter | `shaders/sea.gdshader`, small wet-sand adjustment in `ground.gdshader` | Existing sea geometry and one material/pass; opaque, no screen/depth texture/SSR. Analytic coast boundaries, not physics changes. Glitter off at governor >=2 and GS.web. |
| Distant hill layers / decorative lighthouse island | `cover_atmosphere.distant/_horizon_island`, `cover_haze.gdshader` | Three merged hill meshes plus one merged non-solid island/tower/turbines, one shared haze material, no shadows. Independent fixed RNG; original gameplay RNG unchanged. Two extra hill layers and island off in lite mode. |
| Cloud colour / softness | `world/sky.gd`, `day_cycle.gd` | Existing cloud materials/geometry layout; smooth sphere normals and dusk colour, no new cloud scripts. Rain, cloud movement/targets and rainbow unchanged. |
| Gull/people warm rim, pale wings | `shaders/soft_toon.gdshader` | Same opaque shared materials/pass; neutral gull wing regions only, dark tips preserved. Hero GLB remains **734 tris / 11 parts / 85,224 bytes**. All sockets, pivots, tint/reset and procedural model fallbacks retained. |

**Quality control:** native Compatibility bloom is supported and enabled at quality 0–1, supplemented by two local halo batches. The initial RGBA difference test was invalid (zero alpha difference hid RGB difference); corrected RGB on/off evidence is in `image_measurements.json`. See [Godot's glow implementation notes](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html#glow). Native bloom, halo batches, glitter and extra far/sun-corona layers turn off at levels 2–3 and all GS.web runs (a conservative web policy). Lower levels retain emissive cores and the colour script. No browser execution/export is claimed.

**Caps and budgets:** saturation <=1.08, glow <=.42 (full-special observed 0.404); ending .96/.30 and Gull Sense .35 preserved. Two new shared spatial materials and one sky shader, zero textures, zero per-light scripts, zero added local lights. All 16 fixed-camera draw totals fall below the current S1 baseline (-9 to -2); largest median capped frame change +0.09%. **The +10% performance gate remains unverified:** the cap hides throughput, and afternoon samples show unresolved render CPU +44.64% and GPU +117.67% regressions in different views. See the change log and all pairs in `audit.json`; neither uncapped nor web performance is certified. No gull/person/house/tree GLB regenerated.

**Review entrypoints:** `art_src/s2/review/summary_before_after_cover.png`; four `{roof,pier,town,flight}_before_after_cover.png` sheets; `gull_palette_cover.png`; full captures and metrics in `iteration_4/`. `baseline/` holds pre-S2 source/shader/scene copies plus real four-time captures. `iteration_1..3/`, `iteration_4_glow_disabled/`, and `review_glow_disabled/` are retained diagnostic history. Every generated PNG is inspected and hashed in `viewed_images.json`; sheets only resize/label source screenshots, never retouch them.

**Checks:** source-scope audit, unchanged day progression/sun placement, 1498 collider count before/after, governor/lite effect assertions, uncaptured mouse/NO_FOCUS assertions; one 24/24-to-ending regression. The full regression predates the final native-glow enable correction, which received focused final capture validation. Existing shutdown leak warnings remain; no final script/shader errors. APPDATA/LOCALAPPDATA/TEMP isolated inside this project; no external writes/downloaded art/export.

**Honest open defects:** weaker golden key/rim than cover, pale materials and hard shadows/roof moire, simple hill silhouettes, sparse cloud heaps, procedural water pattern without full reflected scenery; old gameplay-effect columns remain. The original high catchable sun and island layout differ from the cover. Distant turbines are static decorative silhouettes. Four art iterations used; **STOP, awaiting director review**.

---

# Round 14 art manifest - S1 round 2 / STOP for Review 8 follow-up

2026-10-10. **Second S1 review submission of maximum three.** Review 8's numbered items were addressed in order. Its numerical silhouette gates pass; this is **not art-director approval**. Joint overlap edges and reference-pose differences remain visible. No S2, web export, downloads or external writes. The previous submission below is historical.

## Round 2 asset and contract

`tools/blender/hero_gull.py -- --round2` produces `game/assets/models/hero_gull_parts.glb`: **734 triangles / 11 parts / 1 shared gull material / 85,224 bytes**. Body 144, Chest 80, Head 296, UpperL/R 26 each, ForeL/R 36 each, HandL/R 16 each, Tail 10, Legs 48. All imported triangles remain flat shaded. The final joint shell adds 20 triangles to round 1's 714. Rejected raised joint caps (794 tris) are retained under `art_src/s1/round_2/draft_joint_caps/`; they are not the live asset.

The original hierarchy below remains authoritative: shoulder/elbow/head/tail/legs, beak socket, body growth scale, wear roots, comet trails, 2.3x Big Bro and procedural fallbacks are retained. `pose()` and all pivot formulas are byte-identical. **Explicit visual-only exception:** `_pose_authored_fold()` now fits mesh-child folded targets to the faceted wing: upper/fore Y scales .60/.32 and lateral positions .24/.285. Fold weight, interpolation, wrist compensation, animation timing and gameplay values are unchanged. This supersedes round 1's claim that the entire gull source is untouched.

Gulls share one cached `GullParts.material()` using the existing shader with `plumage_fill=1`. Scenery keeps `Art.material()` and its default `plumage_fill=0`; no scene light/sky changes, extra passes, textures or loops. UV recolouring regions and tint/reset remain valid. `wardrobe.py -- 2 --s1 --round2` regenerates only glasses, shades, bro_shades, necklace and bro_necklace, preserving their part/triangle counts and roots; hats retain their existing fit.

## Review 8 measurements, in order

1. **White / banding:** base F7F7FA; vertex luminance variation approximately +/-1%, with only a tiny cool underside bias. Removed strong E2E4EA stripe selections. White plumage receives a continuous light response and a light cool shadow, while grey wings retain their normal shader response. Final same-camera noon/golden/dusk body median display luma, 0–255: **196.8→235.6 / 196.4→233.0 / 183.2→221.7**. Brightest 20% RGB after: **241/241/245, 240/238/242, 229/226/231**; darkest 25%: **229/229/234, 231/228/233, 218/215/220**. Lit saturation 1.63/1.77/1.86%. These percentiles are image proxies, not geometric N.L labels. Masks retain wing occlusion, are eroded two pixels, and exclude coloured beak/black eyes; 24,151/24,560 neutral pixels before/after. See `colour_measurements.json` and `review/white_before_after.png`, which includes the cover crop.

2. **Pose and silhouettes:** alpha >127, reference min RGB <243, largest component + enclosed-hole fill; uniform longest-bbox-edge normalization to 460 pixels on 512, no nonuniform warp. Scores below are from **actual Blender renders**, not CPU approximations.

| View | Round 1 | Round 2 | Review 8 threshold |
|---|---:|---:|---:|
| Front | .862900 | **.864363** | .85 |
| Left | .455244 | **.751080** | .75 |
| Top | .722123 | **.872098** | .85 |
| Right | .453788 | **.751077** | checked; .75 comparison |
| Back | .859254 | **.870008** | checked; .85 comparison |

   These are **pose-conditioned** scores. Bounded CPU registration adjusted camera and existing shoulder/elbow/sweep DOFs; front camera elevation is slightly corrected, side wings use asymmetric raised poses and top wings spread. `reference_poses.json` records all parameters, including the small side camera roll. Round-1 scores use its original poses. Much of the gain is corrected projection, not changed body geometry. Left/right only narrowly cross .75; far-wing foreshortening, body slope and leg projection still differ from the illustrated reference. Do not promote IoU into visual approval.

3. **Beak:** orange shell length **.181→.147 m (-18.8%)**, width **.190→.174 m**. Its old .190 m vertical extent included the droop; new .117 m extent has an almost level .155–.157 m lower edge and thick .097 m tip. Red-orange tip length .018 m. The existing beak socket did not move.

4. **Eyes:** dot diameters increased **20%** in all axes; centres moved **.023 m lower and .011 m forward**, preserving wide spacing. No lids/brows/highlight cards. Glasses/shades follow the new position. At 15 m / 960x540 the dots are about two pixels across and remain just legible; at 60 m there is no facial-detail claim.

5. **Fold / joints:** upper shell now starts within the body; fore shell extends into the elbow rather than using a raised button-shaped cap. Existing mesh-fold targets tuck the wings along the flanks. On the final mesh, folded wing vertical extent falls **.495→.198 m** from the old visual target to the revised one. Actual perch, glide, up/down extremes and dive were inspected. The conspicuous upright perch slabs are gone. **Carried defect:** angular overlap edges still show at the elbow, especially in dive/downstroke; no exhaustive continuous triangle-intersection proof is claimed. The 128-sample contract checks pivot behavior, not seam invisibility.

6. **VN / necklace:** `_portrait_tick()` changes only authored-gull framing; wider caller compositions and procedural framing remain. The real 320x320 portraits contain the full head/hat with margin (exact projected bounds in `game/metrics.json`; top margins approximately 74 px bare YOU, 58 px hatted YOU, 41 px Big Bro). Big Bro necklace wraps the coat: median forward clearance to its front ellipsoid **.197→.0098 m**, final vertex range **.0027–.0195 m**, in unscaled gull coordinates. His runtime scale remains 2.3. This is a measured surface approximation plus visual inspection, not cloth simulation.

7. **Cover comparison:** `review/cover_comparison.png` places the cover gull crop beside the actual dusk café-roof pose with raised wings and a fry at the original beak socket. `game/cover_rear.png` supplies the rear three-quarter view. Pose/fry attachment is an explicit review fixture, not a newly scripted theft. Feet are placed using their actual transformed mesh minimum on the existing roof at y=4.8. Earlier stale-ray ground captures and foot-penetrating drafts are retained and superseded.

## Round 2 validation, evidence and stop

Authority: **`art_src/s1/round_2/`**. Start with `review/cover_comparison.png`, `five_views.png`, `silhouettes.png`, `white_before_after.png`, `portrait_and_fold.png`; `frames_1..3.png` cover every final raw frame including masks. Every generated image, including discarded drafts and all ten regression shots, was inspected directly or on its contact sheet; hashes/dimensions are recorded in `viewed_images.json`.

- Final import/contract PASS: **734 flat triangles, 11 surfaces, one shared gull material, 128 paired pivot samples, 23 wearable cases, missing/invalid gull and missing garment fallback, tint/reset, socket/trails**.
- One complete `--autotest`, exit 0: **24/24, rainbow grab, ended=true phase=3**; stolen 25, perfect 4, walls 3, missed 0. SPECIAL_ORANGE used its existing second attempt. Endpoint agreement, not identical incidental statistics. This full run preceded the final cap-to-wing-shell mesh replacement; that pure GLB correction received a fresh import, contract and camera pass. No repeated full suite.
- Final sequential same-session flight A/B, 512x288 / 30 fps cap / 30-frame medians / governor 0: **2,286→2,286 draw calls; 33.322→33.240 ms** frame interval; CPU **6.444→6.317 ms**, GPU **3.411→.581 ms**. Variable GPU samples are not a speed claim. Bare gull remains 10 main-pass surfaces flying / 11 feet visible. Build/first-frame observations are in the final log/metrics, not controlled startup proof.
- Source audit: **72/77 baseline source/config files byte-identical**. Changes: visual shader, gull material selection, mesh-only fold target, portrait camera fit, opt-in autotest route. Outside the respective visual helper functions, gull and story files are byte-identical to the baseline. No gameplay, progression, controller, text, audio, save or world-light changes.
- Existing Blender 5.2.1 / Godot 4.7.1 Compatibility; 4.6.3 was not separately tested. Blender 512px / 8 samples / four threads; game captures <=960x540, 30 fps, Dummy audio. APPDATA/LOCALAPPDATA/TEMP stay in the project. Existing shutdown resource warnings remain; no script/shader errors. No Git repository exists for a checkpoint.

Reproduction: `run_s1_r2.ps1 -Mode Import|Contract|Color|Review`; `s1_r2_delivery.py` recomputes measurements/sheets from existing captures. `s1_r2_pose.py --fit` is optional pose-registration work, not needed to regenerate from the delivered pose JSON. `Autotest` is a separate long mode and was run once.

**Seen against the cover:** the dull grey cast and VN clipping are corrected, short beak and larger dots read more clearly, the chain sits on the coat, and folded wings sit lower. The cover still has more natural wing planes and much richer warm/cool light; our torso can look stacked, far wing is too foreshortened, Blender top facets are overbright, and close joint edges remain angular. **STOP after S1 round 2. Do not start round 3 or S2 without the next instruction.**

---

# Historical: S1 round 1 - visual gate FAILED

2026-10-10. **S1 only under docs/41. Four internal geometry iterations exhausted. Submitted with explicit defects, NOT approved; no S2, web export or publishing.** This entry supersedes the smooth-gull descriptions below. The old procedural fallback remains; the rejected authored smooth gull is no longer the live asset.

## S1 files and measured budgets

| Asset | Current source / output | Measured result |
|---|---|---|
| Faceted hero gull | `tools/blender/hero_gull.py` -> `game/assets/models/hero_gull_parts.glb` | **714 tris, 11 parts/surfaces, 1 shared material, 1,540 imported vertices, 83,340 bytes** |
| Rejected smooth gull, reference only | `tools/blender/archive/hero_gull_smooth_round14.py`; matching GLB in `art_src/s1/before/` | Historical **3,804 tris / 11 parts / 1 material**; not loaded in normal play |
| Wardrobe, all 19 kinds + 4 brother variants | `tools/blender/wardrobe.py` -> existing `wear_*.glb` paths | Same **3,878 total tris**, same **40-244 per item**, same part/draw counts |

Bare gull parts: Body 144; Chest 80; Head (skull, two eyes, closed beak and red-orange tip) 296; UpperL/R 26 each; ForeL/R 26 each; HandL/R 16 each; Tail 10; Legs 48. All 714 imported triangles have constant face normals, checked in Godot. No feathers, brows, eyelids, eye highlights, blush, textures, bones or extra shader passes. Body paint F5F5F7 with a few E2E4EA facets; orange-yellow prism beak and triangular yellow webs. Existing growth/tint colours are still applied by the loader. Shared shader and world light are unchanged.

Wardrobe tailoring is mesh-local: wider, raised hats around the new head centre; glasses/shades widened and brought onto the dot eyes; pipe/bowtie/necklace/scarf moved to the new face/chest; shirts/coats widened to the body. Seventeen models were refitted; six effect/tail items retain their geometry. All 23 were regenerated. Wardrobe source/output provenance is S1 iteration 3; final gull is iteration 4. The generator defaults to S1; `--legacy-fit` is historical P2 only. **Fit is not universally accepted: necklaces float too far forward and default VN crops are unresolved.**

## S1 pivot / animation / fallback contract

The **Exact original gull hierarchy** table later in this manifest remains authoritative and unchanged. `gull_visual.gd`, `_build_authored()`, `_build_procedural()`, animation/fold code, body growth scale, `gull_player.gd`, head `(0,.1,-.36)`, BeakSocket `(0,-.03,-.3)`, shoulders, elbows, tail, legs, trails, wear-root transforms and 2.3x brother scale were not edited. The 11 canonical GLB part names and UV.x regions 0..7/7 remain. Body mesh coordinates still compensate for the original `(1,.9,1.9)` body scale. Large-head geometry is offset inside Head, not by moving its pivot.

One production loader change: `p2_parts.gd::wear` returns to the original garment builder when the gull itself is procedural. This prevents new big-head garments from being attached to the small fallback head. Missing/invalid gull and missing wardrobe assets keep complete procedural visuals; particles and animated accessory names remain. No `hero_gull.glb` was created, so the unsafe legacy whole-model shortcut is still inactive.

Contract evidence: `art_src/s1/contract.json` / `contract_i4.log`: **128 paired animation samples**, **23 wearable cases**, constant flat normals, one shared material, tint/reset, original trails/socket, missing/invalid gull and missing wearable fallback PASS. Exact source SHA audit: **146 of 148 pre-existing script/shader/scene/config files unchanged**; only `autotest.gd` (opt-in S1 capture routing) and `art/p2_parts.gd` (fallback fit guard) differ. New review-only scripts are `art/s1_review.gd` and `art/s1_contract.gd`. Gameplay, tuning, story text, audio, saves and production cameras are untouched.

## S1 silhouette measurement — gate FAIL

| Orthographic render vs reference | IoU | >= 0.85 |
|---|---:|---|
| Front | **0.862900** | PASS |
| Left oblique | **0.455244** | FAIL |
| Top | **0.722123** | FAIL |

Authority: `art_src/s1/iteration_4/silhouette_iou.json` and `silhouette_comparison.png`; reproducible with `tools/blender/s1_measure.py 4`. Model alpha > .5; reference minimum RGB < 243, largest connected component and enclosed-hole fill. Both masks use uniform longest-bbox-side normalization to 460 px and bbox centring on a 512 px canvas; no non-uniform scaling, deformation or automatic camera optimization. Exact bounds/scales/intersection/union are recorded. Camera vectors and wing pose are in `blender/asset_stats.json` and the generator; top camera roll is explicitly 180 degrees, beak down. Left/right references are artistic oblique views, so camera/pose discrepancy contributes, **but mesh mismatch remains and the target is not passed**. Do not advertise these as calibrated pose-independent shape scores.

All four iteration results are retained. The initial fourth-iteration top image had a 180-degree camera-roll error; its image/results remain labelled `_invalid_camera_roll`. Only that capture was repaired after geometry iteration 4; no fifth geometry iteration.

## S1 review / performance / regression

Start with `art_src/s1/review/cover_before_after.png`, `five_views.png`, `wardrobe_and_vn.png`, and the silhouette sheet. **All 67 generated PNGs were opened**; dimensions/hashes are in `art_src/s1/viewed_images.json`. Blender: 512-square, 8 EEVEE samples, four threads. Four raw game captures are 960x540; other raw captures are <=512; composed sheets <=960x540.

Final game evidence: `art_src/s1/iteration_4/game/`, including rear/side flight, fry attached at the unchanged snatch socket, noon/golden/dusk, 3/15/60 m, actual YOU/BIG BRO VN viewports, four outfits, brother, up/down/dive extremes. `game/corrected/` supersedes the early airborne ground-pose pictures with a real roof perch at raycast surface `(-11.6,4.800002,-.8)`, and supplies the uncropped upstroke. Initial ground-pose images are not foot-contact proof. The snatch image is a socket fixture, not a newly scripted live theft.

Sequential same-session **hero-only** A/B, existing dusk island, Compatibility, 512x288, governor 0, capped 30 fps, 30-frame medians:

| View | Draw calls before -> after | Frame ms before -> after |
|---|---:|---:|
| Rear flight | **2,282 -> 2,282** | 31.542 -> 31.261 |
| Roof perch | **906 -> 906** | 30.898 -> 31.215 |

Bare asset main-pass surfaces remain 10 flying / 11 legs visible. Timing differences are noise, not a speed claim. Full CPU/GPU samples in `corrected/metrics.json` include variable GPU timings (flight 4.524 -> .948 ms; perch .700 -> 1.204 ms); no GPU improvement claim. World build 1,418 ms, first review frame 6,082 ms are observations, not controlled startup comparisons. The first review timing overlapped a short Blender camera repair and is excluded. No web-performance or all-three-live-snatch-camera certification.

One full `--autotest`: **24/24**, rainbow obtained, **ended=true phase=3** (`art_src/s1/autotest_i4.log`). It retried SPECIAL_ORANGE after first targeting MISCHIEF; endpoint passes, incidental bot statistics differ. Godot **4.7.1** was the available installed engine; 4.6.3 was not tested. Existing shutdown resource-leak messages remain; no script/shader errors. APPDATA/LOCALAPPDATA/TEMP isolated under `art_src/s1/runtime`; no real save used. No Git repository was present, so no checkpoint commit.

**What I saw against the cover:** bigger round head, tiny un-lidded dots, chunky closed beak, plump white body and broad solid facets restore the intended simple facial language. White remains readable in all three light states. However, the cover has a better integrated head/chest, more natural wing planes and much stronger warm/cool lighting. Our side/top shapes still diverge; folded wings read as plates, extreme downstroke exposes hinge seams, the head/chest retains stacked faceted forms, necklaces float forward, and default VN crops cut the hero head and brother hat. At 60 m it is a small white mark without facial detail. These are open defects, not acceptance. **STOP S1; do not start S2 without the next instruction.**

---

# Historical: P2 delivery / STOP for review

2026-10-10. **P2 only, following docs/39. Three internal iterations maximum; submitted for Claude's review, NOT art-approved. No P3 or web export.** P1a/P1b geometry and the approved shared shader remain unchanged. The earlier P1b entry below is historical.

## P2 assets, files and measured budgets

Counts below are triangles / visible mesh surfaces for the asset, excluding existing fry halos/rims and particles. Scene draw calls are measured separately. All new GLBs together: **39 files, 454,972 bytes**, SHA256 inventory at `art_src/p2/assets.json`.

| Asset | Generator / GLB under `game/assets/models/` | Original -> P2 tris / surfaces |
|---|---|---|
| Red/cream carton + six golden sticks | `tools/blender/fries.py` / `fry_box.glb` | 348 / 29 -> **596 / 2** |
| Plate, dip and sticks | same / `fry_plate.glb` | 5,184 / 51 -> **548 / 2** |
| Hand bundle / paper cone | same / `fry_hand.glb`, `fry_cone.glb` | 348 / 29 -> **504 / 2** each; old cone used box fallback |
| Special bundle and colour ribbon | same / `fry_star.glb` | Tested old kind 2: 144 / 12 -> **420 / 2**; old kinds have different shapes |
| Ordinary single fry | same / `fry_ordinary.glb` | 60 / 5 -> **60 / 1**, no emission |
| All 19 wearable kinds + 4 Big Bro variants | `tools/blender/wardrobe.py` / `wear_*.glb` | Authored total **3,878** tris versus 66,450 old; **40-244** tris/item, no per-item draw increase |
| Clay dog | `tools/blender/creatures.py` / `dog_parts.glb` | 156 / 13 -> **1,192 / 7** |
| Sardine, mackerel, herring, mullet, bass, opah | same / `fish_<species>.glb` | Old 784-2,328 / 6-15 -> **580 / 2** each |
| Flyer / marlin / tuna | same / matching `fish_*.glb` | Old 800 / 8, 1,496 / 8, 824 / 11 -> **676 / 2, 676 / 2, 640 / 2** |
| Special people and existing held props | Existing P1b `person_parts.glb`; no new person GLB | Body remains **1,168-1,790 / 9**; up to **11** surfaces with two held props |

All nine fish total 5,472 tris versus 10,328 old. Person body budget excludes held props: the final vendor including its unchanged ice cream is 1,964 tris / 10 surfaces, child 1,828 / 10. Held-item geometry is merged, not reduced; do not interpret the body budget as the whole equipped character's total.

Wardrobe exact tris: hat 196, sailor 176, topper 152, beret 116, glasses 156, shades 132, necklace 208, bowtie 120, scarf 164, pipe 128, hawaii 192, stripes 192, coat 244, balloon 152, socks 100, cloud 240, sun 176, skybow 210, meteor 40; bro_topper 176, bro_shades 132, bro_necklace 232, bro_coat 244. Most use one surface; scarf and balloon retain two animated parts. Sun and meteor also retain their original glow overlay (runtime 178 / 2 and 42 / 2 respectively), plus unchanged particle systems where present. Authored geometry uses one material per item; retained effect overlays are separate existing materials.

## P2 integration and pivot contracts

`game/scripts/art/p2_parts.gd` reuses `art_loader.gd`, caches imported parts/tints/held meshes and substitutes visual mesh children after the original builders run. Missing required meshes return to the procedural visual. No new `_process`/physics callback, controller, collider, progression, text, audio or save logic. There are five production hook sites: `fries/fry.gd`, `player/gull_visual.gd`, `npc/dog.gd`, `world/fish_spot.gd`, `npc/human_rig.gd`. `autotest.gd` adds opt-in P2 review routing only.

- **Fries:** GLBs contain canonical `Sticks` and `Carrier` nodes; Ordinary has `Sticks` only. The original `visual` root, scale resets, aim point, snatchable state, RNG, reveal state, Gull Sight emblem, halo/rim and all gameplay remain owned by `fry.gd`. The hand bundle's .8 scale is mesh-local so restocking cannot erase it. Type colour is applied to the carrier/ribbon; sticks stay golden. Special kinds currently share one bundle geometry, rather than retaining every old decorative silhouette. The cone is supported but no new cone placement was invented.
- **Fry material:** ordinary uses the exact shared `Art.material()` with no emission. Other fries use cached `fry_clay.gdshader`, the approved soft-toon shader plus one emission term. Existing emission strengths are retained (.25/.7/.9 sticks; .15/1/1.3 carrier). No extra pass, loop, texture or changes to `soft_toon.gdshader`.
- **Wear:** keep every `_build_item` / `_build_bro_item` root transform and existing slot: head hats; eyes glasses/shades; neck necklace/bowtie/scarf; mouth pipe; body shirts/coats; float balloon; tail socks; cloud/cloud, halo/sun, comet/meteor, halo2/skybow. GLB `Item` is local to that root. `ScarfTail`, `Balloon` and `Spin` retain their animation names; meteor `Sparks` and glow survive. Cloud alpha .6, skybow alpha .3 and existing depth policy are retained; meteor Spin keeps its billboard/unshaded policy. Wear/ownership/shedding/save functions are unchanged. Big Bro reuses the existing 2.3 scale and four authored variants.
- **Dog:** `body` at origin; `head` at (0,.62,.52); `tail` at (0,.6,-.45); four leg roots at (+/-.14,.13,+/-.3). Existing live node references and transforms survive; GLB `Body`, `Head`, `Tail`, `Leg` meshes replace only their visuals. Leg mesh is reused four times. Coat tint uses UV region 1. Bark/lunge/sleep/wag timing is unchanged.
- **Fish:** canonical `Body` and `Tail`, preserving the old species-specific tail translation and X rotation; vertices are authored in that pivot's local frame. Existing `visual` scale, swimming/held/caught transforms, species/rarity/length/weight/speed data remain unchanged. Tint is baked vertex RGB, no per-frame work.
- **People:** P1b nine-part body/pivots below are unchanged. Existing multi-mesh hand props merge once under the original removable `item_node_l/r`; single-mesh props remain untouched. The existing `_make_item` implementation is byte-equivalent. No production chef/moustache style keys were found, so no new character/style was invented. Actual vendor, old man, child, backpack and vest styles are captured. Production VN speakers are YOU and BIG BRO; the third FRIEND portrait/box is explicitly a review fixture, not added dialogue.

GLB positions follow the existing Blender-to-Godot conversion, +Y up at runtime. Vertex RGB stores paint/AO; UV.x stores existing tint-region metadata. No textures, bones, imported animation, lights or cameras. All repeated Blender exports force canonical node names: Blender's `.001` suffix caused real fallback failures during iteration 2 and was corrected in iteration 3.

## P2 evidence and reproducibility

Start with `art_src/p2/review/`: `fries_noon.png`, `fries_golden.png`, `fries_dusk.png` (3/15/60m old/new), `fries_close.png`, `dog.png`, `fish.png`, `outfits.png`, `portraits.png`, `wardrobe_1.png` through `_4.png`. These are small review sheets, not new high-resolution renders.

Final source/renders: `art_src/p2/iteration_3/`. Blender fry/dog/fish turntables are under `fries/turntable/` and `creatures/{dog,fish}/`; every wearable has a front/side fitting sheet in `wardrobe/`. Wings are intentionally hidden in those Blender fitting sheets to expose clothing; full wings are present in the three in-game outfits, both perch and flight. Do not claim exhaustive dynamic clipping coverage for all 23 items.

Game captures: `iteration_3/game/` has the fry cast, matched lighting/distance shots, `snatch_cine_before_contact.png`, `fish_catch_socket.png`, outfits, dog, nine fish, VN boxes/portraits. Cinematic and held-fish shots use the existing camera/attachment transforms in a frozen review fixture, not a recording of manual play. `game/details/` contains the four 960x540 close shots, meteor/restock diagnostics and intermediate people shots. **Final held-prop/person evidence is `game/details_held_final/`**; it supersedes the older people's mesh counts. `game/metrics.json` is authoritative for fry A/B, `game/details_held_final/metrics.json` for equipped people, `art_src/p2/contract.json` for final asset budgets/contracts.

All **237 PNGs were opened and visually inspected**, including failed/intermediate captures. `art_src/p2/viewed_images.json` records dimensions and hashes. Exactly four are 960x540; all others have longest side <=512. Blender EEVEE used 8 samples and four threads. At most three asset iterations: wardrobe/creatures 1-3; fries 1 and 3. Iteration 2 fish used procedural fallbacks and are labelled as the old side in `review/fish.png`, not as authored success. Early floating dog parts, glasses/necklace fit, capture occlusion, invisible VN box and a review cleanup crash were corrected; old files/logs remain for provenance.

Reproduce from project root, only when another review is requested:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --threads 4 --python tools/blender/fries.py -- 3
# Same entry point for wardrobe.py or creatures.py; generates GLBs plus low-sample review images.
powershell -File tools/blender/run_p2.ps1 -Mode Import -Iteration 3
powershell -File tools/blender/run_p2.ps1 -Mode Contract -Iteration 3
powershell -File tools/blender/run_p2.ps1 -Mode Cams -Iteration 3
# Optional focused captures: -Mode Details / -Mode People. Full run: -Mode Autotest.
python tools/blender/p2_delivery.py
```

`run_p2.ps1` isolates APPDATA/LOCALAPPDATA under `art_src/p2/runtime`; normal user saves are not used. Current validation used the existing **Godot 4.7.1** installation and Blender **5.2.1**, not a new engine install; 4.6.3 compatibility is not separately validated. No build/export/download. There is no Git repository for a checkpoint commit.

## P2 checks, performance and open defects

- One full `--autotest`: **24/24**, rainbow grab OK, **ended=true phase=3** (`art_src/p2/autotest_i1.log`, ten inspected captures). This ran after final geometry and the hand-restock fix, before the final held-prop merge and meteor billboard material fix. Those last visual changes received focused final contract/capture checks, not another full suite. The terminal progression matches the prior run; incidental gameplay statistics are not asserted identical.
- Final contract PASS: **136 fry combinations, 23 wearable assets, 9 fish, dog pivots and 18 held-item types with both hands occupied**. Checks include budgets, required authored nodes, ordinary no-emission/hidden vision entry, aim/vision/snatchable/RNG equivalence, fish data/tail transforms, held-prop triangle equality and <=11 surfaces. Loader missing-part fallback is checked. This is not proof of every animation's appearance.
- `art_src/p2/source_audit.json`: **62 existing scripts/shaders byte-unchanged**; the five production files become byte-equivalent after removing only their inserted visual hook lines. Sixth changed existing file is opt-in `autotest.gd`. Baseline hashes and source copies are under `art_src/p2/baseline/`. Approved shared shader remains unchanged.
- Same-session fry-only A/B, frozen cafe, Compatibility 512x288, 30-fps cap, 30-frame medians: **1,935 -> 1,673 draws (-13.54%)**; frame **33.182 -> 33.370 ms**; render CPU **5.932 -> 5.659 ms**; render GPU **.581 -> .718 ms**; governor **0**. Frame difference is .57%, within Review 1's noise threshold. The GPU increase is recorded, not hidden. These numbers predate the final held-prop merge; both A/B halves had the same people. They are not a whole-phase or web benchmark.
- Observed world build: final main capture **1,129 ms**, final people capture **933 ms**; first review frame **3,987 / 3,611 ms** respectively. Earlier iteration 2 build was 786 ms. These are different runs, not a controlled first-frame A/B; no startup non-regression claim. Deferred flora completed at 12.5 / 12.1 s. Existing shutdown resource-leak warnings remain; no final script/shader errors.

Seen: softer golden sticks, red carton/cream label, softer paper and dish, rounded floppy-eared dog, rounded fish with eyes, fitted glasses/hats/coats and readable Big Bro identity. Honest open defects / acceptance limits:

1. At 60m the cafe fries are a tiny glint, often obscured by its awning; universal 60m readability is **not established**. The unchanged giant shop sign competes for attention. Box back/rim still looks angular; salt dots are subpixel. Special colour identity is on ribbon/carrier/effects while sticks stay gold; the literal per-kind stick tint and distinct old special shapes are not preserved.
2. Clothing patterns are broad/soft vertex paint: abstract flowers, weak jersey stripes, a band suggesting woven straw. Top hats/clouds are visibly faceted. Big Bro coat is simplified, without the old fur/epaulette detail. Bowtie, fringe, necklace and tail socks can be occluded by head/body/wings. Three outfit poses do not close every clipping case.
3. Fish remain **matte**, not the specified glossy finish; several common species have similar silhouettes, weak mackerel stripes/opah spots and lobed tails. Dog is connected after repair but still low-poly at ear/paw joins.
4. Big Bro's tall hat is cropped in the unchanged 320px VN camera. Faces retain P1b's faceted nose/hair highlights. FRIEND is a test fixture, not evidence of a third production VN speaker.
5. Existing roof/sea banding and P1a carried wing/beak defects remain. Low-sample Blender highlights are noisy. No art-approval, all-style animation, uncapped performance or web-validation claim.

**STOP P2. Claude reviews these residuals; no P3 work has begun.**

---

# Historical: P1b Review 4 revision / STOP

Date: 2026-10-10. **Review 4 six-item revision, P1b round 2. Two internal asset iterations; STOPPED for art-director review. No P2. P1a geometry/carried defects are unchanged; the shared shader shadow floor/rim are revised and the white gull is rechecked.**

## P1b assets and integration

| Asset | Reproducible script | Game GLB | Tris / visible parts | Material and batching |
|---|---|---|---|---|
| 3 deciduous variants: round / tall / wide | `tools/blender/trees.py` | `game/assets/models/tree_leaf_0.glb` through `_2.glb` | 500 / 1 each (old 540 / 4 primitives, 2 material groups) | One merged surface; 3 MultiMeshes for all 57 instances |
| 2 pine variants, four rounded tiers | `tools/blender/trees.py` | `game/assets/models/tree_pine_0.glb`, `_1.glb` | 450 / 1 each (old 560 / 5 primitives, 2 material groups) | 2 MultiMeshes for all 36 instances; palms unchanged |
| 22 fitted houses, 6 seeded wall/roof combinations | `tools/blender/houses.py` | `game/assets/models/house_00.glb` through `_21.glb`, `house_catalog.json` | 520-1,192 / 1 each; total 16,820 (old 140-1,076 / 12-47 primitives; total 8,908) | Shared surface merged into 8 district batches; old houses used 43 colour/special-material keys, shared with other scenery |
| Person with 7 existing hair/hat choices including bald | `tools/blender/person.py` | `game/assets/models/person_parts.glb` | 1,168 bare / up to 1,790 with every optional garment; 9 visible parts | Source GLB has 19 reusable components; head/hair/glasses and torso/clothes merge at load time into the same 9 runtime parts. No per-frame mesh work |

Every final visible mesh uses the **same `Art.material()` object** as the approved gull. `game/shaders/soft_toon.gdshader` keeps the approved lit paint and 30% mild violet shadow hue; shadow illumination floor is .43 instead of .68 and rim strength .008 instead of .025. It remains opaque with no new passes, texture reads or shader loops. Sun bias, energy, sky, fog and gameplay values are unchanged. Baked AO and height gradients remain in RGB. Tree wind ALPHA survives GLB and Godot import as **0.0 to 1.0**, independent of tint; the shader ignores ALPHA. No wind animation was added.

Source helper: `tools/blender/p1b_common.py`, using the existing `common.py`. Loaders: `game/scripts/art/scenery_parts.gd`, `person_parts.gd`. Hooks: `world/world_builder.gd`, `world/batcher.gd`, `npc/human_rig.gd`. All missing/unusable assets fall back to the original procedural builders. The house index checks captured position/dimensions/roof kind, so a mismatched footprint falls back. Normal tree tint/scale and all collider/RNG generation still execute exactly as before. 93 authored trees / 14 untouched palms / 22 houses; houses keep original door centres, wall/roof heights and all landing/collision nodes. Gable / short-hip / existing flat terrace counts are 7 / 5 / 10. Hip ridge ends are inset only .40 m, inside the existing .45 m eave overhang, to avoid moving the original roof landing geometry. Open-front shops and all other P2/P3 props are outside this phase.

GLB file sizes: five trees **71,472 bytes** total; 22 houses **730,044 bytes** total; person component library **102,444 bytes**. No textures, armatures, imported animation, lights or cameras.

### Exact person pivot contract (retained)

`human_rig.gd` owns these fields; attachment changes only mesh children:

```text
HumanRig (self; world position/yaw owned by existing controller)
  root / HumanRoot                     scale = style.scale
    upper / Upper                      (0, .85, 0)
      torso / Torso                    (0, 0, 0) -> merged Torso mesh
      head / Head                      (0, .77, 0) -> merged Head + hair/glasses
        eye_l / EyeL                   (-.09, .20, .16), independently scaled by emote
        eye_r / EyeR                   ( .09, .20, .16), independently scaled by emote
        mouth / Mouth                  (0, .045, .17), independently scaled by emote
      arm_l / ArmL                     (-.35, .55, 0) -> merged sleeve/hand mesh
        hand_l / Hand                  (0, -.60, .04) -> original held item nodes
      arm_r / ArmR                     ( .35, .55, 0) -> merged sleeve/hand mesh
        hand_r / Hand                  (0, -.60, .04) -> original held item nodes
    leg_l / LegL                       (-.11, .85, 0) -> merged trouser/shoe
    leg_r / LegR                       ( .11, .85, 0) -> merged trouser/shoe
  hand_anchor / HandAnchor             outside root; follows hand_l.global_position + (0,.02,0), rig world yaw
```

The major pivot transforms, `_process`, `_make_arm`, `_make_item`, `_build_hair`, `emote` and the complete procedural build body are unchanged. Eye/mouth mesh-local placements differ for the larger authored face; their animation scale interface is retained. Idle, walk, jog, eat, chat, fish, paint, sit, lie, wave, alarm, play **and recline** are checked, including `holding`, `seated`, arm overrides and child scale. Skin/shirt/pants/hair/shoes/hat/pack/vest colours are baked once into cached mesh variants; apron, glasses, fat and scale still work. Source tint regions occupy UV.x, not material slots. The pre-existing gull pivot hierarchy is preserved in the historical section below and its source hash is unchanged.

### Review 4 changes, in priority order

1. Repainted each crown lobe independently: deep teal-green underside, saturated green midrange, narrow warm yellow-green top. Final authored linear-converted stops are `296D49 / 47A64C / A3CD58`; the first trial was still too pale in game. Pines use deeper `245846 / 398653 / 70AC67`. Original per-instance tints remain. Measurements below use actual rendered colour, not the source swatches.
2. Each deciduous tree now has four distinct overlapping lobes: round, tall oval, wide umbrella. Crown bases reveal a longer tapered trunk and two branch forks. The round/tall fork is partly hidden from the front, visible in the turntable; umbrella forks read most clearly. One surface at 500 tris; pine four-tier silhouette is 450 tris. Tree top/bottom wind ALPHA remains 0..1.
3. Apron is a closed curved/bevelled bib, wrapped waistband and two shoulder straps, cream with AO, merged into Torso. Backpack is an oval volume with wraparound straps; vest is a body-fitting open-front shell with folded edges. First-pass clothing intersections were fixed in the second asset pass. `person_parts.gd` scales all garments in X/Z with `fat`, matching the torso, rather than merely offsetting their front/back cards.
4. Tapered upper arms and thighs, painted sleeve cuffs, visible neck/shoulder connection and wider rounded shoes. Source Head/EyeL/EyeR/Mouth positions, normals and vertex colours match the previous GLB exactly (204/30/30/14 imported vertices). All animation pivots and functions are untouched. Bare 1,168 tris; eight cast styles 1,340-1,522; maximum with every option 1,790. All remain nine runtime draw surfaces.
5. Six wall/roof combinations now use richer pastel walls and deeper terracotta, salmon and blue-teal roofs. House geometry, door positions, roofs/footprints and colliders are unchanged from P1b round 1. Rooftops separate from their walls and foliage in the 60 m noon/golden pairs.
6. Reduced shader shadow floor/rim to give the lobes and architecture stronger shading while retaining near-neutral lit paint. Shared material identity, pass count and shader complexity are unchanged. White-gull recheck below; approved gull geometry and carried defects remain untouched.

UV metadata correction: `p1b_common.py` gives every object's tint UV layer the same `TintRegion` name before joining. Blender-generated `UVMap` and custom-mesh UV layers previously split into two export channels; this could lose hand/bun recolouring and diagnostic crown IDs. The revised person/tree GLBs have the expected regions in `TEXCOORD_0`, verified independently of the image tests. This metadata is CPU-side only; no new texture reads or material slots.

### Final evidence and numeric gates

Final Blender assets: `art_src/p1b_review2/iteration_2/{trees,person}/`; houses were finished in `iteration_1/houses/` and not rerendered in iteration 2. Casts and five-angle turntables were all opened. Final game captures and measurements: `iteration_2/game/`. Four review sheets: `iteration_2/before_after_{noon,golden}_{15m,60m}.png`. The old half is the original procedural world and NPCs, including the same controller-added props; the new half is the current authored world. All are frozen same-camera comparisons.

| Street | Foliage mean HSV S, old -> new | S new/old (gate >=.90) | Full-frame luma std, old -> new | Contrast new/old (gate >=.95) |
|---|---:|---:|---:|---:|
| noon / 15m | 52.91% -> 54.10% | 1.023 | 0.21038 -> 0.20577 | 0.978 |
| noon / 60m | 42.23% -> 46.50% | 1.101 | 0.22266 -> 0.21507 | 0.966 |
| golden / 15m | 44.40% -> 46.79% | 1.054 | 0.20744 -> 0.20939 | 1.009 |
| golden / 60m | 46.27% -> 45.25% | 0.978 | 0.22334 -> 0.22045 | 0.987 |

All four pass. Method: 960x540 native captures; geometry/UV masks include visible tree crowns and unchanged hedges using the same foliage batch colours; exclude grass, palms, trunks, sky, roofs. Masks are eroded one pixel. Mean of per-pixel HSV saturation; contrast is the population standard deviation of display-sRGB luma `0.2126 R + 0.7152 G + 0.0722 B`, normalized 0..1. No beauty-pixel recolouring or saturation-based selection. Sample sizes: 15 m old/new 165,932 / 152,796 pixels; 60 m 107,158 / 94,962. Mask-only capture hides transparent/additive overlay volumes so invisible thermals cannot become opaque black occluders. Separate masks are needed because the crowns have different shapes. Full-frame contrast includes unchanged sky/ground; it is not a tree-only contrast metric.

Gull recheck with the revised shader: noon 3 m mean RGB **223.1/223.2/224.1**, HSV S **0.47%**; golden 15 m **239.6/235.8/230.7**, S **3.70%** (both <12%). Body/chest/head UV regions with N.L>.5, excluding eyes/beak/wings, eroded one pixel. At 512x288 the sample has 1,145 / only 14 pixels respectively; the golden quantitative result is sparse. These four PNGs were opened: the gull still reads white with blue-grey wings and dark tips. No claim of exact source-swatch RGB.

| Same-session crowded town, 171 rigs, matched props; 512x288 / 30 fps cap / 30-frame medians | Old procedural | Revised authored |
|---|---:|---:|
| Draw calls including shadows | 2,070 | 1,429 (-31.0%) |
| Frame interval ms | 33.520 | 33.195 |
| Render CPU ms | 5.551 | 4.736 |
| Render GPU ms | 1.616 | .696 |

`iteration_2/game/metrics.json` is the final A/B. Frame interval is effectively unchanged under the cap; this is desktop Compatibility evidence, not web certification. Five tree MultiMeshes and eight house district batches remain unchanged; each person has nine draws versus old 15-17 for these cast styles (held props extra). No added shader pass/loop/texture lookup. Godot 4.7.1 stable and Blender 5.2.1 LTS, as specified in the art brief/TUNING_NOTES; EEVEE eight samples and four threads.

Validation: `art_src/p1b_review2/contract.json` passes 9 styles x 13 modes x 3 modifiers x 45 frames (15,795 paired pose samples), shared material/cache, held anchors, emotes, missing/invalid fallback, triangle budgets and imported wind alpha. All 1,454 static colliders and the complete original house/tree generation command streams match the immutable baseline. `source_audit.json` verifies the praised face data, tint-region metadata and source hashes. Only existing production `person_parts.gd` and `soft_toon.gdshader` changed; the other three changed existing scripts are opt-in review/test routing. `human_rig.gd`, gull model/source, world generation, controllers, gameplay/saves/audio/text code remain unchanged. No new full gameplay-suite run this review revision; P1b round 1's 24/24 remains historical evidence. Isolated APPDATA/LOCALAPPDATA under `art_src/p1b_review2/runtime/`; no real saves or web export touched.

Review tools: `tools/blender/run_p1b_r2.ps1` (`Import`, `Cams`, `Masks`, `Contract`), `p1b_r2_measure.py`, `p1b_r2_audit.py`; `game/scripts/art/p1b_r2_review.gd`. All **113 PNGs** opened, including superseded/invalid diagnostic images; hashes in `viewed_images.json`. Two asset iterations, not three. Instrumentation-only masks were corrected separately (UV layer naming, auto-renamed MultiMesh nodes, transparent volumes); `*_invalid.png` and `*_diagnostic_invalid.png` are explicitly superseded and not acceptance evidence. Final masks/measurements have no `_invalid` suffix. Eight 960x540 street beauty images per iteration; other game views 512x288; Blender <=512.

### What was seen / honest remaining limits

Foliage now reads green rather than khaki, with a dark teal pine family and distinct lower lobe shadows. The umbrella is broader and the oval narrower than the round tree; forks are visible under the crowns. Roofs are stronger coloured shapes against cream/peach/rose walls. Apron/vest/backpack now wrap the body; no floating torso card or clothing holes were seen in the final front/back and wave/sit/jog/recline views. Faces retain their expressions; figures are sturdier and hands retain their skin colour.

Close tree outlines still reveal polygon steps, especially pine tier shoulders; the pine variants are intentionally similar. The round/tall forks partly disappear behind front lobes. At noon the full-frame contrast is still 2.2-3.4% below the old scene, although it passes the stated 5% tolerance; not every view has greater contrast. House backs remain sparse and hips shallow. Raised hands can overlap hair in extreme animation; tested pivot equality is not a proof of zero continuous mesh contact. Existing roof shadow banding and unchanged background props remain. Eight-sample Blender shadow grain remains. Gull Review 3 carried defects were not worked on. STOP for review; no P2.

---

## Historical P1a/P0 record (P1a now approved by Review 3)


# Round 14 art manifest - P1a hero gull / Review 2 revision

Date: 2026-10-10. **Review 2 fixes implemented; STOPPED for the next art-director review. P0 pipeline remains approved.** No tree, house or person work. Current P1a evidence and remaining defects are below; the P0 section is retained as historical evidence, not the current approval gate.

| Asset | Reproducible script | GLB | Triangles | Status | Notes |
|---|---|---|---:|---|---|
| Hero gull, 5 primaries/wing + 5 tail feathers | `tools/blender/hero_gull.py` | `game/assets/models/hero_gull_parts.glb` | 3,804 | Approved in Review 3; carried defects untouched | 11 parts/surfaces, 1 shared soft-toon material, 118,928 bytes. Player, rival/friend and big brother use the same source meshes. Missing/invalid GLB falls back. |
| Seven-colour calibration card (review only) | `tools/blender/palette_card.py` | `game/assets/models/p1a_palette_card.glb` | 1,316 | Three skies inspected | Cream / peach / sage / coral / butter / charcoal / lilac; loaded only by review harness. |
| 1 m rounded colour cube | `tools/blender/p0_cube.py` | `game/assets/models/p0_rounded_cube.glb` | 188 | P0 pipeline approved; calibration refined in P1a | 96 imported vertices, 46 distinct imported colours, 1 mesh / surface / shared material, 5,660 bytes. Base-centre pivot, AABB `(-.5,0,-.5)` to `(.5,1,.5)` in Godot. No textures, lights, cameras, animations or collision in GLB. |

## Review 2 revision (historical; approved in Review 3)

Three internal asset iterations, then STOP. Review 2 items were addressed in their stated order: colour, blade wings, perch silhouette, animated joints, readable evidence. No tree/house/person or web export.

- **Colour:** `game/shaders/soft_toon.gdshader` reduces sun hue mixing from .12 to .03 and removes the yellow/blue imbalance in the lit multiplier. Shadow illumination uses a 30% mild violet tint; sky ambient stays disabled. In `tools/blender/hero_gull.py`, lilac paint is limited to the lower belly (maximum .22 blend); static-contact AO strength is .12 instead of .25 and height darkening .03 instead of .065. White is still authored F7F1E6, back/upper wing B9C3D1, tips 3A3D48. Visual sun bias remains .35 / 1.25. Noon/golden/dusk palette cards were rechecked; no saw-tooth edge was observed on the reviewed gull wings.
- **Wings:** replaced inflated upper/forearm eggs with thin cambered blade sections, curved leading edges, pinched trailing edges, root/elbow covert coverage and five separate primary plates merged per hand. Charcoal reaches full strength at 70% of hand-feather length. Rest span is 2.32 m versus 1.93 m procedural. Level/up world-X spans are 2.285/1.966 m versus 1.915/1.632 m (+19.3%/+20.5%). Native 128 px black-on-sky widths are 109/93 px versus 92/80 px. Same camera, same pose and scale, no outline dilation.
- **Perch:** a slightly horizontal, raised egg body, blended neck, longer visible shins and tail extending to .77 m. Feet keep their original sole height near -.4 m. `_pose_authored_fold()` tucks only authored wing mesh children back along the body; they do not hang below the feet. The source head/eyes/beak POSITION data is identical to the previous GLB (642 imported head vertices).
- **Joints:** root/elbow covert geometry covers hinges. Long fore/hand mesh children counter-rotate only at extreme flap angles to keep the two blades from crossing, and interpolate into the authored perch tuck. The existing shoulder/elbow rotations, pose calculations, trail parents, head lunge, socket, growth and procedural fallback stay intact. The original `pose()` gains only the art-child helper call. This supersedes the previous claim that the entire pose function was byte-identical. A 128-sample sweep compares old/new animated pivots; extreme up/down, flare, dive and mid-fold images were inspected. This is visual evidence plus pivot checks, not an exhaustive mesh intersection proof.
- **Evidence:** `art_src/p1a_review2/before_after.png` includes procedural/authored flight and perch plus both native 128 px silhouette pairs. `colour_check.png`, `joints.png`; final individual images and JSON in `iteration_3/`, Blender details in `iteration_3/blender/`. All **67 generated PNGs** were opened, including failed harness images; hashes are in `viewed_images.json`. Close game frames are <=960x540, Blender poses <=768, 8 EEVEE samples / 4 threads, game capped at 30 fps. Only three asset iterations; a type-correction recapture inside iteration 2 changed the harness only.

| Lit body measurement | Mean RGB (0-255) | HSV saturation of mean | Mean pixel saturation | Pixels |
|---|---:|---:|---:|---:|
| Noon, 3 m over blue sea | 229.5 / 229.4 / 230.3 | 0.38% | 1.97% | 4,675 |
| Golden hour, 15 m over peach roof | 244.2 / 240.3 / 235.3 | 3.63% | 3.58% | 104 |

Mask: visible body/chest/head UV regions with geometric N.L > .5; eroded by one pixel; eyes/beak/wings excluded. Includes the blue-grey mantle on the body and may include self-shadow. Noon is effectively neutral (blue +0.8/255), golden is warm; both are below S <12%. These are rendered values, not a claim of exact on-screen F7F1E6. The 15 m sample is small. I see a white gull against blue sea, with blue-grey upper wings and clear dark tips; no whole-bird lilac cast.

Current asset: **3,804 tris / 11 mesh parts / 1 shared material / 1,990 imported vertices / 118,928 bytes**. Procedural: 1,464 tris / 22 parts / 16 materials. Visible main-pass parts: flight 18 -> 10; feet out 22 -> 11. Same-session full-island draws at 960x540: flight **1,039 -> 1,023**, perch **1,216 -> 1,194**. Median capped frame times remain ~33.2 ms. Shader adds no pass, loop or texture read. Full timings and limitations are in `36_ROUND14_CHANGES.md`.

Validation: import and `p1a_contract.gd` pass; 128 sampled original pivot transforms match the fallback. `source_audit.json` confirms only three existing game sources changed this round (shader, gull visual, opt-in autotest dispatcher); 61 other tracked source/config files are unchanged, including gameplay, saves and project settings. New review-only script: `game/scripts/art/p1a_r2_review.gd`; launcher/composition: `tools/blender/run_p1a_r2.ps1`, `p1a_r2_sheets.py`. APPDATA/LOCALAPPDATA remain isolated inside `art_src/p1a_review2/runtime`. No repeated full suite; prior P1a 24/24 result is historical, not a new test result.

Honest remaining defects: at close range the low-poly elbow covert still reads as an overlapping plate with a hard seam; primary ends remain rather straight/squared; the simplified webbed feet have less toe detail. Dusk is deliberately palette-stable and relatively bright. The body stays chubby, though the side perch now has a visible neck, legs and tail. I saw no open hinge gap or blade crossing in the final reviewed extremes; art approval remains with the director.

## Initial P1a delivery and evidence (historical, superseded by Review 2 above)

- Source/generation: `tools/blender/hero_gull.py`; shared helpers in `common.py` now allow optional exported UV metadata and tighter review framing. Seedless, 4 threads, 16-ray deterministic static-contact AO per moving group, baked height/lilac gradient; EEVEE review at 384 px / 8 samples. Applied mesh coordinates, smooth normals, rounded feather caps. No texture, extra material, animation, skeleton, camera, light or collision is exported.
- `game/scripts/art/gull_parts.gd`: validates all 11 named one-surface parts, colour and UV data, and triangle budget before attaching anything. `COLOR_0` is opaque painted RGB. `TEXCOORD_0.x = region / 7` identifies fixed, white, chest, wing, tip, tail, beak, eye regions; it is CPU recolour metadata, never a texture lookup. Recolour happens on the existing growth/tint/reset events, caches mesh variants and retains ONE shared render material for the base gull; unchanged accessories/particles retain their old materials. Existing StandardMaterial3D values remain cosmetic state channels only.
- `gull_visual.gd`: `_build_authored()` precedes the byte-identical procedural build body. The pose, comet, wear, wardrobe and trail methods are unchanged. Only three cosmetic event methods gain a colour-sync call. Existing body growth scale is preserved through an unscaled authored body mesh under `body_mi` with the original `(fluff,.9*fluff,1.9)` scale.
- `soft_toon.gdshader`: bounded sun tint, four soft illumination levels, violet shadow fill, warm lit tone and subtle rim. Sky irradiance is excluded to avoid palette bleaching; the real sun direction, attenuation, fog and sun-energy response remain. No emission, specular, atlas, outline, sampling or extra pass. `world_builder.gd` sets visual shadow bias `.35` / normal bias `1.25`; sun colour, energy, sky and gameplay values are unchanged. Colour card remains distinguishable in noon/golden/dusk. The P0 cube's top bevel no longer has the saw-tooth edge in the golden close-up. Broad old roof surfaces still show fine moire/contour lines.
- Review entry: `art_src/p1a/before_after.png`. Also `palette.png`, `pose_sheet.png`, `silhouette_128.png`, `views_{noon,golden,dusk}.png`, `distances.png`, `portraits.png`, `historical_comparison.png`. Individual final captures: `art_src/p1a/iteration_4/`; stats: `iteration_4/metrics.json`, `iteration_4/blender/asset_stats.json`. Historical comparison uses `shots/cam_b1a.png`'s camera and spawn; its original comic overlay/pose differ, so performance uses the controlled same-session A/B pairs instead.
- All **141 generated PNGs** were opened, including earlier failures, the 10 full-regression captures, and composed sheets; all are <=512 px. Hash inventory: `art_src/p1a/viewed_images.json`. There were four internal art iterations: palette first pass; clean card + first gull; fold/eye correction; final rounded feather ends / silhouette and valid tint metadata. No fifth asset iteration. Targeted capture-harness repairs in the fourth iteration are preserved, not hidden: missing dictionary key before gull capture, initial stale VN camera interpolation, and obstructed 60 m roof sightlines. Use `vn_noon_fixed.png` and `*_60m_clear.png`; original failed/occluded frames remain.
- Validation: `p1a_contract.gd` confirms authored path, missing/invalid fallback, material sharing, tint/reset and unchanged animated pivot transforms. `--cams --art-p1a` captures six views x three skies x 3/15/60 m, the real 320 px VN viewport, growth colours, pale tint/accessories and 2.3x big brother. One full `--autotest` reaches 24/24, rainbow and `ended=true phase=3`. APPDATA/LOCALAPPDATA are redirected into `art_src/p1a/runtime`; real saves are untouched. No web export. See `docs/36_ROUND14_CHANGES.md` for timings and honest limits.

### Authored gull attachment hierarchy

The exact original pivot contract below remains authoritative. New mesh children use stable names; pivot variables and their positions/rotations are unchanged:

```text
gull / self
|-- body_mi [Node3D, original growth scale (1,.9,1.9)] -> Body
|-- Chest [MeshInstance3D, authored vertices already in gull-local coordinates]
|-- head (0,.1,-.36) -> Head [skull, eyes, brows, cheeks, beak/dot/nostrils merged]
|   `-- BeakSocket (0,-.03,-.3) [same marker; same head_lunge]
|-- tail (0,0,.38) -> Tail [5 merged feathers]
|-- shoulder[-1/+1] (+/-.14,.07,-.06) -> UpperL/UpperR
|   `-- elbow[-1/+1] (+/-.32,0,0) -> ForeL/ForeR + HandL/HandR
|       `-- trail_l/trail_r (+/-.5,0,.1) [unchanged]
`-- legs (0,0,0), existing visibility rule -> Legs [both legs/webbed feet/toes]
```

Authored flight mesh child offsets are zero in ordinary glide. Review 2 adds mesh-child-only wrist compensation at extreme flap angles and a ground tuck; the original pivot hierarchy below is unchanged. Body geometry is pre-divided by the original body scale. Head includes beak/eyes but the live socket stays a separate sibling under `head`. Accessories remain under their original parents in the table below. The GLB is named `hero_gull_parts.glb` deliberately: it does not activate the old `gull_player._try_load_hero()` whole-model shortcut. No `gull_player.gd` change.

Remaining art defects: violet fill is strong on the breast; shoulder/forearm masses still read as separate rounded plates; the unchanged ground fold makes a low cupped silhouette. Cheek/brow polygon edges remain visible in the 320 px portrait; pupil gloss is a painted cream dot, not another specular material. At 60 m and 512 px the flying outline is only several pixels wide, and separate feathers disappear; distant readability is limited, not approved. Existing clothes remain attached but were not re-tailored. The old cinematic snatch framing still crops the oversized fry/gull in the regression capture. These are review notes, not a reason to start P1b.

## P0 files and evidence (historical)

- `tools/blender/common.py`: scene cleanup, applied 2–3 segment bevels, smooth weighted normals, deterministic finite-radius hemisphere AO bake into `Col`, +Y-up GLB export, bounded 4-angle + top EEVEE renderer and Blender-native contact sheet. Palette inputs are linear RGB; `linear_rgb()` converts hex swatches. Bake **after** modifiers. Alpha stays opaque. Ground is an explicit bake occluder and is not exported.
- `game/scripts/art/art_loader.gd`: optional loader returning `null` for missing/non-scene/no-colour assets; caller retains primitive fallback. Meshes share one shader material. No `_process`, no extra pass. Future static scenery must feed batching/MultiMesh, not call `attach()` once per bush. Do not use this whole-scene helper to overwrite animated pivots.
- `game/shaders/soft_toon.gdshader`: four smooth light bands, violet/gold tint terms, light-dependent subtle rim, `COLOR` albedo with Compatibility colour-space conversion in the vertex stage, roughness .92, no metal/specular/emission/outline/screen reads. Sky, fog and real shadow attenuation remain enabled; governor 3 tested. See the known appearance defects below.
- `game/scripts/art/p0_review.gd`, `art_src/p0/cams.json`: dev-only `--cams --art-p0 --art-review`, same-pose comparisons at exactly 3 / 15 / 60 m, white-vertex ablation, governor 3, measured stats. Waits for all four existing flora MultiMeshes before comparing. Test fixture has no collision and exists only in this dev run.
- `game/scripts/autotest.gd`: small opt-in review output/512 px capture routing and P0 camera dispatch. Existing test actions and gameplay assertions are unchanged. Normal output paths are unchanged.
- `tools/blender/run_p0.ps1`: local Godot launcher with APPDATA/LOCALAPPDATA redirected to `art_src/p0/runtime/`; logs, test saves and caches stay inside this project. Does not touch a real save. `tools/blender/review_sheets.py` only combines existing PNGs, using already installed Pillow.
- Opened/viewed: all five `art_src/p0/review/*.png` views plus `contact_sheet.png`; all P0 game screenshots and their composed sheets. First measurement is retained under `art_src/p0/game_initial/` and `cams_initial.log` because flora was still arriving. Final evidence lives under `art_src/p0/game/`.
- Also opened all 10 regression captures under `art_src/p0/autotest/`. One full autotest reached 24/24, rainbow and `ended=true phase=3`; endpoint agrees with the prior regression, but bot incidental stats differ. No second full test was run. All 35 generated PNGs are <=512 px and listed in `art_src/p0/viewed_images.json`.
- Main review entry: `art_src/p0/game/before_after.png`; full detail: `close_before.png` and `close_after.png`. Distance and diagnostic sheets: `distance_sheet.png`, `diagnostics.png`. Numeric evidence: `asset_stats.json`, `game/metrics.json`. Full change/test report: `docs/36_ROUND14_CHANGES.md`.

## Exact original gull hierarchy - retained procedural fallback

Source: `game/scripts/player/gull_visual.gd:63–129`, `gull_player.gd:126–137`, `gull_visual.gd:305–317,453–739`. Coordinates below are **local Godot metres**, +Y up; gull faces **-Z**. Names in backticks are GDScript variables unless explicitly stated to be node names. Most pivot nodes have **no assigned name**: their generated `@Node3D@...` names are not stable paths. There is no named `Body` pivot or generic `WearSlots` node.

```text
PlayerGull (CharacterBody3D: gameplay and collision)
└─ VisualRoot (explicit node name; base uniform scale 1.3)
   └─ gull / self (Node3D + gull_visual.gd; growth also scales this node)
      ├─ body_mi [MeshInstance3D] pos (0,0,0), sphere r .2, scale (1,.9,1.9)
      ├─ chest [MeshInstance3D] pos (0,-.04,-.2), sphere r .12, scale (1.1,1,1)
      ├─ head [Node3D] pos (0,.1,-.36)
      │  ├─ head sphere at (0,0,0), r .115
      │  ├─ beak box at (0,-.03,-.16), size (.05,.045,.2)
      │  ├─ red beak dot box at (0,-.055,-.22), size (.052,.02,.05)
      │  ├─ eyes at (±.06,.03,-.065), r .02
      │  └─ BeakSocket [Marker3D, explicit name] pos (0,-.03,-.3)
      ├─ tail [Node3D] pos (0,0,.38)
      │  └─ 3 feather boxes: ((k-1)*.06,0,.1), rotation.y=(k-1)*.16
      ├─ shoulder[side] [Node3D], side ∈ {-1.0,+1.0}, pos (.14*side,.07,-.06)
      │  ├─ inner wing box pos (.16*side,0,.04), size (.32,.035,.34)
      │  └─ elbow[side] [Node3D] pos (.32*side,0,0)
      │     ├─ outer wing box pos (.17*side,0,.06), size (.34,.03,.28)
      │     ├─ dark tip box pos (.42*side,0,.1), size (.17,.032,.2)
      │     ├─ white tip box pos (.38*side,0,.03), size (.05,.034,.05)
      │     └─ trail_l / trail_r [CPUParticles3D] pos (±.5,0,.1)
      └─ legs [Node3D] pos (0,0,0), initially hidden
         ├─ 2 shins: (±.07,-.28,.02), size (.025,.2,.025)
         └─ 2 feet: (±.07,-.39,-.03), size (.08,.015,.13)
```

Animation contract: shoulder rotation `(0,-cur.s*side,cur.a*side)`; elbow Z `-cur.e*side`; legs visibility `cur.legs>.3`; tail X `-.1*cur.legs`; head Z `-.36-head_lunge`. `body_mi.scale`, chest/wing/tip/beak/eye materials, `apply_growth()` and `tint_pale()` are also live contracts. Preserve these references/recolourable regions when parts are later authored.

Wearable attachment roots are stored in the **`worn[kind]` dictionary**. There are no persistent empty socket nodes for hats/shades/scarf:

| Parent | `kind` → local root position (rotation when set) |
|---|---|
| `head` | `hat`, `sailor`, `topper`: `(0,.1,0)`; `beret`: `(.02,.105,0)`; `glasses`, `shades`, `pipe`: `(0,0,0)`; `bowtie`: `(0,-.075,-.07)` |
| gull/self | `necklace`: `(0,-.015,-.27)`; `scarf`: `(0,-.015,-.25)` (child explicitly named `ScarfTail`); `hawaii`, `stripes`, `coat`, `balloon`: `(0,0,0)` (balloon mesh named `Balloon`); `cloud`: `(0,.66,.1)` root named `CloudBuddy`; `sun`: `(0,.14,.3)`; `skybow`: `(0,.2,-.12)` root named `RainbowHalo`; `meteor`: `(0,.02,.36)` children named `Spin`, `Sparks`; unknown kind defaults to self at zero |
| `tail` | `socks`: `(0,0,0)` |
| big-brother overrides | `coat`: self at zero; `topper`: head `(0,.1,0)`, rotation `(0,0,-.1)`; `shades`: head at zero; `necklace`: self `(0,-.015,-.27)` |

**Legacy integration hazard (avoided in P1a):** `gull_player._try_load_hero()` currently loads a complete `hero_gull.glb` under `VisualRoot`, hides `gull`, and adds a replacement marker at `(0,0,-.6)`. It does **not** connect imported parts to the shoulder/elbow/head pivots. P0 does not create that filename or alter this path. P1 must integrate meshes under the existing pivots instead of activating this legacy whole-model shortcut.

## Exact existing human hierarchy — inspected, not changed

Source: `game/scripts/npc/human_rig.gd:84–171`, `_process()` at 325–432. Person faces **+Z**, unlike the gull. `root`, `upper`, `torso`, `head`, arms, legs and `hand_anchor` are variable references, **not assigned node names**. Only the two `Hand` nodes have explicit names.

```text
human_rig / self [Node3D]
├─ root [Node3D], scale = Vector3.ONE * style.scale (default 1)
│  ├─ upper [Node3D] pos (0,.85,0)
│  │  ├─ torso [Node3D] pos (0,0,0)
│  │  │  ├─ body capsule pos (0,.32,0), r .27, height .82,
│  │  │  │  scale (fat,1,fat*.9), shirt material
│  │  │  ├─ optional apron at (0,.15,.22)
│  │  │  ├─ optional backpack at (0,.35,-.27)
│  │  │  └─ optional vest at (0,.32,0), width/depth multiplied by fat
│  │  ├─ arm_l [Node3D] pos (-.35,.55,0)
│  │  │  ├─ sleeve box at (0,-.28,0), size (.1,.56,.1)
│  │  │  ├─ hand sphere at (0,-.58,0), r .065
│  │  │  └─ Hand [Node3D] pos (0,-.6,.04), referenced as hand_l
│  │  │     └─ optional item_node_l [Node3D] at zero
│  │  ├─ arm_r [Node3D] pos (.35,.55,0), same children
│  │  │  └─ Hand [Node3D] pos (0,-.6,.04), referenced as hand_r
│  │  │     └─ optional item_node_r [Node3D] at zero
│  │  └─ head [Node3D] pos (0,.77,0)
│  │     ├─ head sphere (0,.16,0), r .165, scale (1,1.06,1)
│  │     ├─ eye_l/r (±.06,.2,.15), r .022
│  │     ├─ nose (0,.15,.165), r .028
│  │     ├─ mouth (0,.08,.16), size (.07,.016,.02)
│  │     └─ optional glasses and hair/hat meshes (all directly under head)
│  ├─ leg_l [Node3D] pos (-.11,.85,0)
│  │  ├─ pants box (0,-.38,0), size (.16,.76,.19)
│  │  └─ shoe box (0,-.8,.04), size (.17,.08,.28)
│  └─ leg_r [Node3D] pos (.11,.85,0), same children
└─ hand_anchor [Node3D], outside scaled root; starts at zero
```

`hand_anchor` follows `hand_l.global_position + (0,.02,0)` every frame with only the rig's global yaw: the held fry stays upright. Do not parent it under the authored hand or scale it twice. Root bob/seat/recline/lie transforms, upper lean, head pitch, arm X/Z overrides and leg swing remain procedural. Bare head top is ~1.955 m at scale 1 (not exactly 1.8 m); shoe bottom is .01 m. Hats/hair add height. `fat` changes only body X/Z and vest size, not pivot spacing.

Preserve style keys `skin`, `shirt`, `pants`, `shoes`, `hair`, `hair_style` (`bald`, `long`, `bun`, `cap`, `sunhat`, `beanie`, default short), `hat`, `glasses`, `apron`, `backpack`, `pack_color`, `vest`, `vest_color`, `scale`, `fat`, `item_l/r`, `balloon`. Eye/mouth meshes must remain separately emote-scalable. Future material sharing must preserve colour regions; P0's already-coloured cube does not solve the P1/P2 recolouring contract.

## Honest visual status / review gate

Blender: the five opened views show rounded edges, peach/sage colour separation and darker contact/bottom regions; no detached part or visible hole. Side faces are a little muddy, the top bevel has slight uneven shading, and the 8-sample ground shadow is noisy. This is not a clay/grain finish approval.

Godot: close comparison shows a bevelled silhouette and visible vertex colour against the original hard-edged box. The white-vertex ablation proves the colours reach the renderer. Existing noon sky/light pushes the top toward white and the sage side toward blue; the violet shadow term is not yet a convincing warm-violet appearance. Thin self-shadow serrations remain at the upper bevel. At 15 m it reads as a small coloured block; at 60 m it is only a few pixels and its finish cannot be judged. Governor 3 preserves the shape/colour but visibly softens the image and removes cast shadows as expected. Compared with `shots/cl_t19_gull.png`, the surrounding primitive world and its existing shadow artifacts remain visible.

**One next art change for review:** reduce the cold noon-light wash while retaining peach/sage separation and no fry-like glow. No character/environment modelling, grain atlas, wind or P1 asset was started. P0 pipeline evidence is ready for the director; visual approval and a strict performance non-regression claim remain open.
