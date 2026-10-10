# S4 — final local delivery, COMPLETE / STOP

2026-10-11. S7 was approved by Review 15. Delivered `docs/44_FINAL_ART_REPORT.md`, four 1920px original/final/cover sheets, 15 matched camera views per version, `film/art_remaster_preview.mp4` (40.000s, 1280x720 at30fps, original game audio), eight frames and rebuilt Windows/Web. Exactly one Movie Maker capture; raw52.03s retained, final uses seconds1–41. Real bot snatch succeeded with PERFECT; no gameplay/timing edits. Review-camera setup failures retained and three details per version corrected. Every generated view inspected through its contact sheets.

`BUILD.bat` passed; installed Web no-threads release template used, then Round13 `patch_index.py`. Packaged Windows headless start/quit exits0, no warnings/errors. Final decimal sizes EXE178.997256MB / PCK32.260996MB / Windows total211.258252MB / Web total72.265102MB. Original-source reconstructed pre-art PCK27.712396MB: content increase4.548600MB; old retained P0 package was27.764012MB, so it is explicitly not called pristine pre-art. Raw evidence/provenance at `art_src/final/`.

14/14 matched world-camera draw/tris rows lower, e.g. roof2482→1132 draws /1731966→428909 tris; cafe3m2811→1177 /1934570→480009. Latest native original/final review builder sample635→410ms (single pair), packaged469ms; historical S7 five-process median1022→600ms remains separate. No new full autotest/browser playthrough; prior S7 24/24-to-ending retained. No downloads, external writes, desktop automation, publishing or new art phase. [Full report, licenses, defects and rerun/rollback](44_FINAL_ART_REPORT.md). **STOP.**

---

# S7 — low headland and startup budget; four iterations, STOP

2026-10-11, Review 14. **Submitted, not art-approved. Native five-process build median passes the <=916 ms gate.** Cover viewed first. No S4, web export, download, MCP, publishing, desktop mouse/keyboard automation or writes outside the project. No Git repository was available. Final visual evidence: [three cameras before / after / cover](../art_src/s7/review/iteration_4_verified_before_after_cover.jpg), [six full-frame contacts](../art_src/s7/review/iteration_4_verified_contact.jpg), [review index](../art_src/s7/review/README.md). Captures are unretouched; sheets only resize and label them.

## Headland: overlay first, then the explicitly authorised height fallback

Iteration 1 kept the 24 m gameplay plateau and tried a broad, 480-triangle layered skin. The actual sea/east/west captures show an unacceptably regular tiered mound. Widening the foot did not resolve the plateau/tower height ratio, and a wider foot crowded the marina side. This rejected candidate remains in `iteration_1/`; it is the evidence for using the user's terrain-profile exception.

Iteration 2 lowered only the headland term of `Terrain.H` from 24 to **12 m**; its radius-24 m level cap and radius-40 m influence footprint stay fixed. Everything outside that radius remains exactly equal. The full terrain cache was regenerated. Local objects that already use `gh/H` follow the new ground. The three existing `>20 m` decoration predicates were scaled to `HEADLAND_HEIGHT * 20/24` so their selection and gameplay RNG remain identical. Iterations 3–4 adjusted the rock shoulders, staggered thin overhangs and added a tidal skirt. **No fifth art iteration:** `iteration_4_verified` is the fourth candidate with final shadow-submission and fallback/budget verification corrections.

Final skin: **480 tris, one surface, existing shared material, 55,892 bytes**; ten coloured strata intervals with asymmetric radii, stronger horizontal ledges, a small grass lip and 12 existing Kenney CC0 rocks (72 tris each), merged into the same headland district. Foam is an analytic narrow broken line in the existing opaque sea shader: no texture or reflection pass. White house, striped lighthouse, dark pines and the original moving turbines remain. The S6 distant decorative island deliberately continues to use its original asset; it is not lowered or left floating by the new local profile.

The contract checks **1,498 colliders**, **68 origins translated down with their original local ground**, one changed terrain shape, and no other shape/basis changes. The two affected anchors (`lighthouse`, `turbine`) move down exactly 12 m with their structures; all other anchors and all nine thermal zones are exact. Ground, lighthouse perch and keeper-table raycasts pass. 171 NPC styles are identical; five local NPC origins move down 12 m. One boundary tree's canopy collider centre lies just outside the 40 m circle: the test checks its exact ground-derived displacement against the tree's base, rather than incorrectly treating canopy-centre radius as its terrain footprint. This is **not** an unchanged-global-collision-hash claim.

## Startup cause, profiling and correction

The expensive startup work was still runtime person-colour generation and mesh upload, repeated for **171 distinct styles**. Native profile medians before: **351.708 ms** tint/merge/upload, **51.779 ms** GLB loading, **85.121 ms** district append, **25.446 ms** batch commit/upload, **22.592 ms** ground-noise/material creation, **11.828 ms** primitive colour-cache creation, **4.071 ms** GLB instantiation/validation and **0.334 ms** tree MultiMesh setup. These are named instrumented regions, not additive disjoint wall-time accounting. Source inspection confirms scenery AO is already baked into GLB colours; no runtime AO bake was found.

S6 added synchronous crop/ivy/cliff/decor generation in the existing builders, but the historical **916→1115 ms** three-run medians do **not** isolate 199 ms of S6-only work: the saved pre-S6 runs span 603–1135 ms; this session's unchanged S6 baseline spans 569–1046 ms. The inherited warm-resource comparison was only +24 ms. A precise S6-only 199 ms causal attribution remains unsupported. The actual large, removable blocker was identified and removed instead of ascribing the whole spread to GLB IO or MultiMesh setup.

`s7_bake.gd` saves exact final person arrays in one compressed **2,395,888-byte** resource and the two identical ground-noise images. The runtime validates the imported person source-array fingerprint plus cache version, shares the existing material and falls back to generation for missing/stale caches or unknown styles. Final medians: **67.000 ms** person-cache load (including verification), **4.324 ms** noise/material, **56.083 ms** GLB load, **77.560 ms** district append, **22.672 ms** commit/upload, **10.610 ms** primitive paint cache, **3.967 ms** GLB instantiation/validation, **0.281 ms** tree MultiMesh. GLB loading itself did not improve. Contract compares **every array of every part of all 171 styles byte-for-byte**, and both noise images pixel-for-pixel, against runtime generation. No styles, colours or poses were removed to get the gain.

Further submission savings: turbine rotor visuals merge under their original moving body, keeping all collider children; dot-eye visible/emote meshes remain but stop submitting redundant tiny shadows inside the head silhouette. The three cafe views were re-inspected, with faces/eyes intact. A separate render-only terrain resource omits **1,071 triangles already fully discarded by the existing headland shader**, including an edge-distance test; physics always uses the complete regenerated mesh. If the optional rock kit/headland is missing, the complete terrain and procedural shell remain available. No per-frame scripts/materials were added.

Five independent native processes, same 960×540/30-fps arguments and instrumentation:

| Series | Builds in ms | Median |
|---|---|---:|
| Fresh S6 baseline | 1031, 1022, 569, 904, 1046 | **1022** |
| Final S7 | 417, 600, 791, 825, 515 | **600** |
| Historical pre-S6 target | 1135, 603, 916 | **916** |

Final median is **41.3% below the fresh S6 baseline**, **34.5% below the requested pre-S6 target**; all five final runs are below 916 ms. “Cold” means a fresh process with empty script/style caches; the OS disk cache and driver shader cache were **not** flushed. Raw runs and non-overlapping/overlapping profile labels are in [audit.json](../art_src/s7/audit.json). The five failed initial instrumentation runs are retained but excluded; a misplaced timer initially caused a parse error and the runner now stops a batch on script errors. No failed sample was silently treated as a timing result.

## Draws, first frame and governor

Godot **4.7.1** is the only installed engine (Compatibility, RTX 5070 Ti Laptop GPU). There is no 4.6.3 or browser certification. Same frozen six cameras, three headland views and cafe at 3/15/60 m, plus four governor-2 samples. All **10/10 draw counts lower**. Eight triangle counts lower; headland-west +26 and cafe-3m/governor-2 +49 rendered triangles remain (under 0.011%); no blanket every-metric non-regression pass is claimed. Model/material budgets remain respected. CPU/GPU samples are mixed and the 30-fps cap does not establish browser throughput.

| View / governor | Draws before → final | Rendered tris before → final | CPU render ms | GPU render ms |
|---|---:|---:|---:|---:|
| headland_east / 0 | 609 → 532 | 303606 → 303115 | 3.132 → 3.258 | 0.743 → 0.747 |
| headland_sea / 0 | 684 → 654 | 341570 → 341516 | 4.156 → 4.374 | 0.757 → 0.759 |
| headland_west / 0 | 630 → 608 | 313702 → 313728 | 4.491 → 4.308 | 0.725 → 0.728 |
| cafe_3m / 0 | 1410 → 1179 | 537682 → 535009 | 4.758 → 4.312 | 0.754 → 0.722 |
| cafe_15m / 0 | 1754 → 1507 | 647309 → 644476 | 5.632 → 5.354 | 0.670 → 0.770 |
| cafe_60m / 0 | 2292 → 2055 | 677164 → 674431 | 7.376 → 6.852 | 0.619 → 0.655 |
| headland_east / 2 | 341 → 308 | 216823 → 216370 | 2.921 → 2.755 | 0.705 → 0.748 |
| cafe_3m / 2 | 896 → 786 | 471585 → 471634 | 3.494 → 3.274 | 0.588 → 0.717 |
| cafe_15m / 2 | 1156 → 1032 | 522071 → 520694 | 4.283 → 4.345 | 0.579 → 0.632 |
| cafe_60m / 2 | 1519 → 1420 | 518218 → 516775 | 6.134 → 6.046 | 0.602 → 0.715 |

First actual 3D review-frame submission: **1298→1198 draws**, **430632→426419 tris**. The first frame in the short title-startup runs is just the menu (**119 draws / 7102 tris**, unchanged), so it is not reported as the island's render cost. Process-start-to-that-menu-frame medians are **3355→3283 ms**, far less improvement than the isolated builder time: startup and build time are different quantities.

Governor forced 2/3 and native `GS.web=true` policy checks pass: resolution/shadow distances apply, glow/halos/glitter/heavy horizon layers switch off, level 3 shadows off. Existing automatic adjustment intentionally resets its counters while paused or capped at <=30 fps, so these gentle runs do **not** exercise the live 4-low/15-high-second adaptation loop. `perf_governor.gd` itself is unchanged.

## Regression, reproduction, remaining defects

Final `--autotest` completed **24/24**, collected a rainbow fry and reached **`ended=true phase=3`**. Full log: `art_src/s7/final_Autotest.log`; actual screenshots in `art_src/s7/autotest/`. The inherited SPECIAL_ORANGE first approach again targeted MISCHIEF and passed on retry 2; no snatch/controller/tuning edit was made. Contract also passes nine styles × 13 modes × three modifier sets × 45 frames, pivots, anchors, emotes and missing/invalid visual fallbacks. Native inherited shutdown resource/leak messages must not be read as a warning-free export. Early ordinary ending was not separately rerun.

Reproduce only when explicitly needed: `tools/art_pipeline/run_s7.ps1 -Label <new-label> -Mode Cams|Cold|Contract|Autotest`; `-Mode Bake` regenerates person/noise/full-terrain/render-terrain resources, then `-Mode Import` as needed for a regenerated GLB. Blender: `--background --threads 4 --python tools/blender/s7_headland.py`. `s7_setup.py` is a one-time baseline capture and refuses overwrite. `s7_audit.py` writes scope/hash/measurement evidence. `source_diff.patch` records every changed baseline source; all pre-existing GLBs are untouched. Test user data/log/temp paths are isolated in `art_src/s7/runtime/`; every sampled test window reports uncaptured mouse and NO_FOCUS.

**What the pictures show:** sea/west views now read as a low broad island rather than a high cone; rock ledges, pale/cool/warm strata, dark pines and the foam skirt are visible. East close-up still has large planar, mechanically repeated rock bands and visible fine diagonal material/shadow pattern. The small white house is partly hidden behind lighthouse/pines, the inherited **three** tall gameplay turbines remain (**the cover's requested two-turbine composition is not achieved**), the broad non-solid rock apron can be flown through, and the cover's reflected sunset/bounced warmth are still absent. Foam is a simple line, not surf simulation. This is a substantial proportion change and a measured build-time fix, **not a cover-quality approval**. Four art iterations used; **STOP S7**.

---

# S6 whole-island audit and fixes — four iterations; STOP

2026-10-11. Review 13 task. **Submitted for review, not art-approved. Draw/triangle regression checks pass; island build-time non-regression is NOT established.** Four internal art iterations have been used. No S4, web export, download, MCP, publishing or desktop input. All writes and isolated runtime directories are inside this project. No Git repository was available.

Start with [rank 1–5](../art_src/s6/review/ranking_1.jpg), [rank 6–10](../art_src/s6/review/ranking_2.jpg), [before / final / cover summary](../art_src/s6/review/summary_before_after_cover.jpg), and the [full review index](../art_src/s6/review/README.md). Source screenshots are unretouched. The cover was viewed before implementation, alongside docs/41 and the S3/S3b/S5 review sheets.

## Audit and visible changes

22 fixed golden-hour world cameras plus the actual title UI cover opening roof/close-up, cafe, market, beach, playground, marina, harbor/cranes, church, stairs, villas, garden, farm, windmill, summit, headland, horizon, low/high sea flight, fast-flight pose, ending floor and pier. Cameras are frozen in `art_src/s6/cams.json`. Baseline camera framing was corrected before art edits; discarded setup captures remain in `camera_setup/`. Every baseline/final view is included in the four comparison pages. Garden coverage is partly blocked by a pine; this is an honest limitation, not a hidden clean view.

| Rank | Worst baseline spot | S6 change / observed result |
|---|---|---|
| 1 | Headland: giant brown cone with broad empty facets | Authored 240-triangle irregular cliff skirt and grass lip. More broken silhouette/facets, but still tall and regular. Original playable plateau and three turbines stay fixed. |
| 2 | Farm/windmill: rectangular green crop bars, blank barn | Local Kenney wheat and leaf crops, furrow colour, warm barn roof, cornerboards/door trim. Reads as a field now; wheat remains chunky and planting sparse. |
| 3 | Marina: office appears unsupported over water | Non-solid foundation/piles/braces and window frames. Office reads supported; simple boats and facade remain. |
| 4 | Town stairs/banks: continuous grey strips and repeated cliff faces | Warm masonry, varied rock scale/yaw and ivy along existing edges. Warmer, but masonry is visibly repetitive. |
| 5 | Harbor: grey warehouse, bare yard and block containers | Terracotta roof, frontage/door trim, loading doors and painted yard strips. Roof improves long-view separation; container blocks remain plain. |
| 6 | Church/summit: grey roofs and blank tower | Terracotta church/clock roofs, tower edge trim and side bell openings. Warmer landmarks; plinth and distant shading remain simple. |
| 7 | Horizon: repeated domes, lighthouse on a grey lump | Lower uneven ridge meshes, small distant rock skirt and grass cap. Less dome-like; tops still too flat/regular under haze. |
| 8 | Playground: box hut, blue slab slide, empty ground | Small gable, slide side edges and rail, subtle warmer ground patch. Limited improvement; still sparse and primitive at close range. |
| 9 | Opening: large plain roof and flat illumination | Audited, no direct roof/lighting rebuild. Carries forward. |
| 10 | Sea: streaky bands and weak scene reflections | Audited, existing water retained. Carries forward. |

The eight selected locations were addressed in this priority order within one implementation, then reviewed in four bounded art passes. Iteration 1 exposed reversed cliff wall winding (visible missing wall); iteration 2 corrected winding and adjusted crops; iteration 3 broke up the cliff rings but overly reduced crop geometry; iteration 4 restored fuller crops within the render budget. All candidate renders/captures and failure logs are retained. No fifth art iteration.

## Implementation / preserved contracts

`s6_world.py` uses the existing `import_kenney.py` conversion path and already-local nature-kit CC0 sources. Three derived GLBs plus one project-authored cliff live in `game/assets/models/s6/`: wheat **112**, leaves **82**, ivy **52**, cliff **240** tris; **486 unique source tris**, four single surfaces, existing shared soft-toon material. Source/output hashes and palette records: `art_src/s6/assets.json`; licence: `art_src/third_party/ASSET_MANIFEST.md`. Importer optional output/review directories preserve its previous defaults.

`s6_parts.gd` retains the old crop boxes and procedural cliff when assets are unavailable. The 80 original crop-row centres are retained; 40 wheat meshes and 80 small leaf clumps replace them visually. Separate district crop meshes cast no shadows. Decorative supports/trim/ivy have no collisions. World anchors, gameplay ground and triggers are unchanged.

Budget offsets: small static visual spheres use 8 segments/4 rings; centimetre-scale flower/pebble instance meshes become 8-triangle faceted forms with identical placement/RNG/colour/visibility; nine windmill rotor visual boxes become one coloured mesh, with their original collider children preserved. `person_parts.gd` avoids an unnecessary SurfaceTool upload for singleton limbs/eyes, retaining identical faces, tint, rig and fallbacks. No new per-frame work, material, texture sampler or rendering pass. Ground furrows/masonry are arithmetic in the existing shader. No gameplay, text, audio or save edits.

`s6_audit.py` confirms **1,498 identical global collider transforms/shape hashes**, identical anchors, all **171** NPC positions/styles unchanged, and all pre-existing GLBs/terrain cache unchanged. The baseline file hash check covers its captured source set; it is not a claim about unrelated files outside that set. Full source diff: `art_src/s6/source_diff.patch`.

## Measured budgets and open timing gate

Native Godot **4.7.1**, Compatibility, RTX 5070 Ti Laptop GPU, 960×540, capped 30 fps. **Not certified on the requested 4.6.3 or web.** 22 matched governor-0 rows plus cafe/rush/pier governor-2 rows: **25/25 draw calls and rendered triangle counts no worse**. Draw changes **−16 to 0**; tris **−153,892 to −5,712** (−5.1% to −40.6%). Rendered tris include passes, not just unique asset geometry.

| Fixed view | Draw calls before → after | Rendered tris before → after |
|---|---:|---:|
| Cafe | 2,540 → 2,540 | 888,627 → 745,891 |
| Harbor/cranes | 1,765 → 1,750 | 652,436 → 586,140 |
| Town stairs | 2,095 → 2,087 | 766,115 → 631,555 |
| Windmill | 360 → 345 | 198,069 → 187,985 |
| Headland | 609 → 609 | 360,246 → 303,606 |
| Rush | 2,987 → 2,972 | 925,592 → 786,136 |
| Pier, governor 2 | 1,298 → 1,297 | 577,259 → 461,364 |

**Do not claim a startup gain or a passed build-time gate.** Matched capture run reports **641 → 551 ms**, but alternating native cold-start samples were before **[1135, 603, 916]**, after **[1115, 866, 1136] ms**: medians **916 → 1115 ms (+21.7%)**. A separate alternating warm-resource builder benchmark reports medians **992.6 → 1016.6 ms (+2.4%)**. The series disagree and are noisy; the user's strict “no worse” requirement remains unproven. Earlier iteration build samples (701/977/1024 ms) are retained, not discarded. No further runs/art changes after the four-pass cap.

Across matched rows, render CPU delta is **−0.608 to +1.112 ms** and GPU delta **−0.273 to +0.184 ms**. Capped frame timings are not a throughput or browser performance claim. Absolute render cost is mixed despite fewer tris. Raw samples, both timing series and hardware are in `art_src/s6/audit.json`. The first headless benchmark freed its owner before deferred flora ran: that harness failure is retained as `bench_teardown_failure.*`; final bench waits for deferred work outside the timed builder section and completes cleanly.

## Validation / what was actually seen

One full final `--autotest` reached **24/24**, took a rainbow fry and finished **`ended=true phase=3`**. Actual captured ending: `art_src/s6/autotest/a08_ending.png`. This run does not separately prove an early-before-tutorial ending. Incidental bot stats differ (perfect 3, walls 2, drinks 1); gameplay code was not changed to obtain the result. Complete log: `art_src/s6/final_Autotest.log`; console preserves inherited GLES/ObjectDB shutdown leak diagnostics and shell exit 1. Runtime completion markers pass; do not describe the process as a warning-free exit.

Final contract passes all asset budgets, flat normals, nondegenerate triangles, outward walls, missing/disabled asset fallback, and old/new person geometry equality, plus **9 styles × 13 modes × 3 modifier sets × 45 frames** (anchors, tint, emotes, cache). The initial cliff normal assertion incorrectly treated its upward grass rim as a vertical wall; the failed log is retained, and the corrected test permits the upward rim. Contract: `art_src/s6/contract.json`.

All generated renders/screenshots were inspected through full contact pages; key cliff/farm/marina and ending captures were also opened directly. The indexed hash record is `art_src/s6/viewed_images.json`. This is builder visual QA, not art-director acceptance. The actual title UI is unchanged cover artwork. The fast-flight review is a **24 m/s boost-pose/FOV fixture, not video or a motion-performance test**; the fixed cafe-floor view is a staged golden-hour composition, separate from the real ending run. Test runs assert mouse uncaptured and NO_FOCUS; no desktop input automation. Blender used low-sample small renders; runtime data is isolated under `art_src/s6/runtime/`.

Still visible: large/tall headland and its non-solid decorative skirt, regular ridge tops/masonry, tiny chunky crops, sparse playground/beach, bare container blocks, simple boats, stiff S5 people, garden occlusion, weak water reflections, hard/flat light and little cover-like bounced warmth. The cover remains substantially richer. **STOP S6 for review; no S4/video/export.**

---

# S5 cover people + Review 12 polish — submitted; STOP

2026-10-11. **Three internal art iterations, then STOP for review. Not art-approved.** Target viewed first: `art_src/reference/cover.jpg`, including enlarged cafe/pier people, followed by the S3b comparison. Final source is `tools/blender/person.py`; the previous smooth generator is retained in `tools/blender/archive/person_smooth_pre_s5.py` (only its helper import path was adjusted for the move). No S4, web export, download or publish.

## What changed

- Rebuilt all 19 reusable person components as flat-shaded, split-normal low-poly geometry. Round head diameter .66 m, approximately **32.4%** of the 2.04 m bare figure; two tiny black dot eyes; no nose, blush, highlight, eyebrows or visible mouth. Broad faceted hair/hat masses, chamfered box torso, thick sleeves/legs, mitten palms/thumbs and chunky shoes. Existing seven hair choices (including bald) remain.
- Kept the original nine-part loader contract, every rig pivot, all 13 animation modes, the external upright fry anchor and procedural fallback. The `Mouth` part is a buried one-triangle compatibility placeholder; `human_rig` hides that mesh while retaining its emote scale interface. Thus there are **8 visible body surfaces**, or at most **10 with two existing merged held props**, instead of 9 / 11. Optional apron/backpack/vest merge into Torso; hair/glasses merge into Head as before.
- Preserved UV.x tint region IDs and all existing style keys. Cached per-region colour factors replace repeated per-vertex hex decoding in `person_parts.gd`; recolouring remains event/build-time, with no new process/material/pass. `fat` still affects torso/clothes X/Z and inverse-transformed normals, and `scale` still acts through the existing root. Optional glasses retain their key, now as simple frames around the dots.
- Iteration 1 exposed a rectangular apron and vest overlap. Iterations 2–3 changed the apron to a tapered bib/flared skirt and thin wraparound tie, and fitted the vest upper/lower shell. Combination garments remain more angular than the cover, with tiny contrasting shirt slivers near vest shoulders.
- **Gull:** only upper/forewing vertex paint changed to near-white/pale lilac-grey, with charcoal tips retained. Source audit confirms every non-colour accessor, index and normal is byte-identical to the previous 734-triangle gull. Original rig, sockets and wardrobe untouched.
- **Cafe:** a local warm sandy/terracotta blend and restrained per-tile variation in the existing paving shader; warmer golden decking, stronger plank variation/joints. No added texture sampler, pass, model or collision.
- **Headland:** asymmetrical broader rock foot, lower outer shoulder and gentler slope; narrowed back on the east side to avoid spreading into the town. Remains 144 source triangles. The inner grass cap at radius 24.25 m / height 24.02 m and all gameplay solids stay fixed. **This is a partial shape correction: the locked high plateau means it is still taller and more mound-like than the cover.** The added rocky skirt is non-solid dressing, not new walkable terrain.
- **VN:** fixed the pre-existing authored-gull framing test to require the `worn` field, so authored humans are not treated as gulls. Existing human camera settings and the gull fit formula remain unchanged. Three real production VN boxes/live 320×320 viewports show elder, child and sunhat fixtures with complete heads/hats. The review camera excludes portrait-backdrop layer 20; early review images with the yellow panel behind the whole actor are retained. No story text/timing/UI layout change.

## Asset and rendering numbers

| Person body library | Previous smooth | S5 final |
|---|---:|---:|
| Bare tris, including hidden compatibility part | 1,168 | **665** |
| Worst combination: hair + glasses + apron + vest + pack | 1,790 | **1,271** |
| Visible body main-pass surfaces | 9 | **8** |
| With two existing merged held props | <=11 | **<=10** |
| Shared render material | 1 | **1** |
| GLB bytes | 102,444 | **211,816** |

The GLB is larger despite fewer triangles because flat normals split vertices. Held props are unchanged and their triangles are additional to the body budget. Runtime contract confirms all 9 sampled styles remain under the 1,800-triangle body ceiling and all imported triangle normals are flat.

Same-session project baseline vs final, native **Godot 4.7.1 Compatibility**, 960×540, 30-frame medians, 30-fps cap. These are full-view render-pass counts, not unique mesh triangles. No browser performance claim. All **11/11** matched rows have fewer draws and rendered tris. Selected rows:

| Camera / governor | Draws previous → S5 | Rendered tris previous → S5 | Render CPU ms previous → S5 |
|---|---:|---:|---:|
| Cafe people, 3 m / 0 | 2,721 → **2,504** | 1,010,521 → **882,844** | 4.883 → 4.612 |
| Cafe people, 15 m / 0 | 2,804 → **2,581** | 995,952 → **864,793** | 5.208 → 5.092 |
| Pier crowd, 15 m / 0 | 1,548 → **1,427** | 749,706 → **679,412** | 3.863 → 3.685 |
| Pier crowd, 60 m / 0 | 1,788 → **1,664** | 765,138 → **691,694** | 4.255 → 4.527 |
| Pier crowd, 60 m / 2 | 1,194 → **1,118** | 542,956 → **496,538** | 3.544 → 3.518 |
| Headland / 0 | 656 → **609** | 387,462 → **360,246** | 2.192 → 2.156 |

Full table with GPU and capped-frame times: `art_src/s5/comparison_metrics.json`. Capped frame medians vary by less than 2.2%; no uncapped throughput improvement claim. The 60 m pier CPU sample is **0.272 ms higher**, not concealed by the geometry saving. Island build times: fresh baseline **597 ms**, iteration 1 **1,397 ms**, iteration 2 **596 ms**, final **746 ms**, separate full-autotest startup **842 ms**. Per-region tint caching was added after iteration 1. Build timing varies substantially; **startup non-regression is not established**. These native figures do not certify browser startup.

## Validation and evidence

- Focused contract: **9 styles × 13 modes × 3 modifier sets × 45 frames**. Original root/upper/torso/head/arms/hands/legs and upright held-fry anchor transforms match the procedural path at every sample. Emote scale interface, child scale, `fat`, holding, seated and arm overrides pass. Missing and invalid assets still build the procedural person.
- Tint test covers the style-controlled skin/shirt/pants/hair/shoes/hat/pack/vest regions. An initial strict colour assertion failed because it ignored the GLB/ArrayMesh UNORM8 quantization; the revised check allows exactly the two quantization steps amplified by the tint ratio. The failure/diagnostic logs remain under `art_src/s5/`; this was a test correction, not another art iteration.
- **1,498 → 1,498** collision shapes with identical sorted shape/local-transform hash; anchors identical. All **171** original people have identical positions and style dictionaries in the comparison. Terrain source/cache, gameplay controllers, player logic, audio, saves and project settings are unchanged. `source_audit.json` and `source_diff.patch` list every modified pre-existing source. New files are review tooling only.
- One full final-art `--autotest` completed **24/24**, obtained a rainbow fry and reached **`ended=true phase=3`**. SPECIAL_ORANGE required the inherited second approach after the first targeted MISCHIEF. About 300 game seconds; no gameplay edits were made to obtain the result. Bot incidental stats differ from S3b (perfect 2, walls 5, drinks 0). Final log: `art_src/s5/final_Autotest.log`.
- Available engines were Blender **5.2.1 LTS** and Godot **4.7.1**; Godot 4.6.3 was not installed/tested. Existing shutdown RID/resource leak warnings remain; no clean-shutdown claim. No desktop input automation. Test windows assert `NO_FOCUS` and uncaptured mouse. Runtime APPDATA/LOCALAPPDATA/TEMP and all evidence remain inside `art_src/s5/`. Blender used 4 threads, 8 EEVEE samples and 320 px views. Game captures are at most 960×540; one game render run at a time.

Review entry: `art_src/s5/review/people_cover.png`; same-camera cafe 3/15 m, pier 15/60 m, paving, headland and gull comparisons beside it. `portraits.png` compares old/new live portraits. `pier_60m_pixels.png` uses the exact same source rectangle enlarged with nearest-neighbour: it does not invent detail. Final raw game/Blender views: `art_src/s5/iteration_3/`. The closer cast loads the saved old GLB in memory and switches old/new fixtures under the same final lighting. Other A/B views compare the retained pre-edit baseline to final art with identical camera coordinates/FOV. Gallery pages cover every intermediate source capture, including failed first-pass garment combinations; key views were additionally opened at full size. `viewed_images.json` records image hashes and the review method. Initial iteration-1 Blender camera bounds were stale and clipped heads; those render-only frames were regenerated with an explicit view-layer update before the corrected turntable was accepted.

## What I actually see / remaining defects

At 3 m the face is a round faceted head with two uncomplicated dots, and the hands/shoes have clearer mass. The eight-style cast now shares the gull's facet language. At 15 m, heads, clothing blocks and seated/fishing poses read distinctly. At 60 m, the people remain recognizable coloured figures, **not identifiable faces**; the native-pixel crop makes that limit explicit. The inherited cafe 3 m sightline includes a large foreground person and an umbrella pole across the central figure; the cast and VN frames provide unobstructed face evidence.

The people still have straight, stiff lower legs and rather squared shoulder transitions; dark hair loses some facet detail at dusk, and raised arms can crowd the large head. Vest shoulder edges retain tiny shirt-coloured slivers, and the combined apron/vest/fat fixture is bulky. No new animation was introduced to hide this. New pale wings still receive relatively flat game lighting, with a strong dark tip area. Paving and wood are warmer but do not have the cover's luminous local bounce light. The headland remains too tall/regular, with oversized existing turbines. **Weak sea reflections and repetitive rock-wall geometry from Review 12 item 5 remain open.** These are explicit review limits, not an assertion that cover quality or human taste approval has been achieved.

Reproduce: `powershell -NoProfile -File tools/art_pipeline/run_s5.ps1 -Label <fresh-label> -Mode Cams`; `-Mode Import`, `Contract`, or `Autotest` for the corresponding step. Person: Blender `--background --threads 4 --python tools/blender/person.py -- --iteration 3`. Gull colour export: `hero_gull.py -- --s5 --no-render`. `python tools/art_pipeline/s5_audit.py` checks the recorded A/B/source evidence. No Git repository exists here, so no checkpoint commit. **STOP S5; await art review.**

---

# S3b richness pass — second S3 review submission; STOP

2026-10-11. Review 11 addressed in order, **round 2 of maximum 3 for S3**. Three internal tuning passes in this session (`pass1`, `pass2`, `final`), now stopped. **Not art-approved; the full cover-matching gate remains open.** Reference viewed first: `art_src/reference/cover.jpg`, then the S3 summary. All comparison sheets use the original S3 cover crops and actual fixed-camera game captures, without retouching.

## Changes against Review 11

1. **Palette and light:** stronger shared pigment response, deeper blue-violet shadow fill, less middle-distance fog. Grass/foliage move toward olive; paving becomes warm grey-beige; wood gains a golden brown lit face. The gull material retains its separate white response. Sky, progress clock, sun target, saturation/ending/Gull Sense overrides are unchanged. No extra lights or texture samplers.
2. **Headland:** replace nine attached S3 crags (1,224 source tris) with a **144-triangle** continuous, flat-faceted warm brown-grey rock skirt, cool shaded facets, irregular strata and a grass edge. This is non-solid visual dressing over the original height field. The terrain shader hides only the covered slope when the kit-backed skirt is present; it defaults to the complete original ground if the kit is absent. Original terrain vertices, normals, colours, collision and plateau positions remain identical. Three red lighthouse bands now extend outside the white core (two old bands were hidden inside it). Existing small house repainted cream/red, pine palette darkened. **Three existing gameplay turbines remain:** removing/scaling them to the cover's two small turbines would mismatch existing solids/anchors. The distant decorative island still has its original two turbines.
3. **Houses:** repaint only `COLOR_0` in **22 existing GLBs**: terracotta/coral roofs, cream/peach/butter/sage walls. `s3b_palette.py` preserves all other bytes, including positions, normals, indices, UVs and dimensions; no new house family or fantasy-town import. Shared golden-hour/dusk window emission is stronger.
4. **Cafe:** two extra non-solid striped canopies over existing tables, twelve extra festoon bulbs and three round railing globes. Existing planters, menu, tableware, people and fry targets stay at their original positions. Existing window material warms the shopfront. Everything joins the existing district/light batches; no per-object process or OmniLight.
5. **Water:** deeper blue-teal base, warmer orange glitter and gentler filtered ripple contrast. S3's analytic shore/post foam remains soft; no reflection pass, SSR, scene textures or geometry increase. Glitter still turns off with governor ≥2. Fixed pier camera faces away from the sun, so it cannot show the cover's sun-facing reflection path; this mismatch is reported, not hidden by changing the camera/light.

## Measurements against the cover

`final_review/material_crops.png` and `colour_measurements.json` contain all numbers and exact rectangles. HSV mean saturation and standard deviation of display-referred Rec.709 luma, both on 0–1 RGB. Rectangles are frozen across all passes; no per-result masks, grading or selected-pixel thresholds. They exclude the sky but include both lit surfaces and shadows/props. **These are screen-region proxies, not matched geometry or an isolated N·L lit-pixel test.** Composition differs; the town cover crop includes part of a wing, and the water cover crop includes strong glitter. Therefore a ±15% region result is not proof of matching individual materials or lighting.

| Fixed visible-surface ROI | Mean S: S3 → S3b / cover | Luma std: S3 → S3b / cover | S / std error vs cover |
|---|---:|---:|---:|
| town | 0.240 → 0.463 / 0.426 | 0.138 → 0.165 / 0.177 | +8.5% / -7.0% |
| cafe | 0.301 → 0.400 / 0.469 | 0.182 → 0.177 / 0.195 | -14.7% / -9.2% |
| wood | 0.268 → 0.352 / 0.445 | 0.161 → 0.143 / 0.194 | -21.0% / -26.3% |
| water | 0.581 → 0.632 / 0.305 | 0.069 → 0.069 / 0.160 | +106.9% / -56.8% |
| headland | 0.181 → 0.368 / 0.368 | 0.075 → 0.093 / 0.147 | +0.1% / -36.4% |
| paving | 0.297 → 0.388 / 0.440 | 0.136 → 0.116 / 0.165 | -11.7% / -30.1% |

Town and cafe ROIs meet both approximate ±15% comparisons; cafe saturation is near the lower boundary. Wood, paving and headland contrast still fail; water also fails saturation. No blanket colour/contrast pass is claimed. The forehead guard stays near-white at noon/golden/dusk (see `gull_white_guard.json`); the same white feather/head pixels remain visually clean, with pale cool wings. The head/wing lighting is still much flatter than the cover's rim light.

## Performance and contracts

Native Godot **4.7.1**, Compatibility, 960×540, 30 samples per view, 30-fps cap. Same S3 coordinates/FOV and golden/dusk keys, cafe 3/15/60 m, beach/headland, governor 0 and forced 2. Fresh pre-edit capture reproduces S3 draw/triangle counts. All **17/17** final rows have lower draws and rendered tris than both S3 and the fresh baseline. The monitor counts render passes, not unique asset triangles.

| View / time / governor | Draws S3 → S3b | Rendered tris S3 → S3b | Render CPU ms S3 → S3b | Render GPU ms S3 → S3b |
|---|---:|---:|---:|---:|
| roof / golden / 0 | 1,330 → 1,328 | 657,496 → 631,732 | 3.868 → 3.745 | 0.538 → 0.504 |
| pier / golden / 0 | 2,289 → 2,285 | 918,946 → 887,416 | 5.678 → 6.242 | 0.851 → 1.119 |
| town / golden / 0 | 2,425 → 2,421 | 912,743 → 881,453 | 5.179 → 4.891 | 0.583 → 0.435 |
| flight / golden / 0 | 135 → 131 | 225,852 → 194,802 | 1.591 → 1.197 | 0.546 → 0.351 |
| roof / dusk / 0 | 1,529 → 1,527 | 684,844 → 659,080 | 3.635 → 3.658 | 0.517 → 0.485 |
| pier / dusk / 0 | 2,463 → 2,459 | 950,576 → 919,046 | 6.133 → 5.782 | 0.614 → 0.480 |
| town / dusk / 0 | 2,389 → 2,385 | 906,842 → 875,824 | 4.646 → 5.121 | 0.499 → 0.596 |
| flight / dusk / 0 | 135 → 131 | 225,852 → 194,802 | 1.686 → 1.627 | 0.540 → 0.489 |
| cafe_3m / golden / 0 | 1,539 → 1,535 | 764,611 → 734,713 | 3.315 → 3.304 | 0.553 → 0.418 |
| cafe_15m / golden / 0 | 1,917 → 1,914 | 906,738 → 878,375 | 4.458 → 4.058 | 0.532 → 0.446 |
| cafe_60m / golden / 0 | 2,497 → 2,493 | 967,422 → 936,580 | 5.836 → 5.355 | 0.611 → 0.674 |
| beach / golden / 0 | 2,757 → 2,753 | 929,330 → 898,344 | 5.920 → 6.190 | 0.541 → 0.604 |
| headland / golden / 0 | 659 → 656 | 417,897 → 387,462 | 2.411 → 2.391 | 0.606 → 0.419 |
| pier / golden / 2 | 1,397 → 1,393 | 658,806 → 628,326 | 4.342 → 4.759 | 0.501 → 0.443 |
| cafe_3m / golden / 2 | 971 → 968 | 659,823 → 631,950 | 2.722 → 2.851 | 0.517 → 0.615 |
| cafe_15m / golden / 2 | 1,247 → 1,245 | 724,507 → 698,025 | 3.526 → 3.403 | 0.513 → 0.508 |
| cafe_60m / golden / 2 | 1,648 → 1,645 | 742,535 → 713,718 | 4.665 → 4.913 | 0.521 → 0.484 |

Matched build: **S3 978 ms → S3b 846 ms**; fresh S3b pre-edit run 1063 ms, pass 1 1057 ms, pass 2 946 ms. Separate autotest startup 857 ms. This is measured evidence, not a universal startup or browser speed guarantee. Frame caps hide throughput; absolute CPU/GPU samples above still vary.

Cost savings: six-segment/three-ring sphere bulbs within the existing lamp batch; non-shadow-casting emissive lamp/window meshes (zero illumination contribution from their old shadow passes); fewer headland triangles. Exact static terrain arrays are cached in `game/assets/models/terrain_s3b.res` (**193,536 bytes**) to avoid rebuilding them at startup. `Terrain.build_mesh()` retains its entire procedural fallback. Cache regeneration must accompany future H/grid/colour changes; the cache is not self-invalidating. `s3b_bake_terrain.gd` rebuilds this delivery from the immutable S3b source snapshot.

Final focused contract: **all 15 CC0 assets pass**, one shared surface/material, budget/normal/size checks, missing/disabled kit checks, canopy 48 triangles; cached vs procedural terrain vertex/colour/normal arrays equal. Fixed-camera physics hash: **1498 → 1498**, all recorded shape data/local transforms equal; all anchors equal. Source audit confirms only the non-solid lighthouse paint rings changed in `world_builder.gd`; all other world-building functions and gameplay/player/NPC/fry/story/audio/save/project files are identical. House non-colour bytes are identical. See `source_scope.json` and `source_diff.patch`. These are not a human collision/playfeel review of the decorative cliff face, which approximates the unchanged solid slope.

One full `--autotest`, on final art: **24/24**, rainbow obtained, ordinary-fry ending. Exact endpoint:

`[AUTOTEST] ended=true phase=3 stats={ "stolen": 25, "perfect": 3, "shot": 0, "slipped": 0, "walls": 3, "missed": 0, "swats": 0, "vision_s": 0.0, "fish": 0, "rivals": 0, "bops": 0, "scares": 1, "drinks": 1, "fed": 0, "friends": 0, "rainbow": 1, "star": 0, "gifts": 0, "meteors": 0 }`

The first SPECIAL_ORANGE attempt locked MISCHIEF and reported missed after a long approach; the second attempt succeeded. This was not a timeout. The entire run took about 260 game seconds. No gameplay adjustment was used to make it pass. Native shutdown resource/RID leak warnings and nonzero capture wrapper exits remain inherited; **not a clean-shutdown claim**. Final camera/contract logs have no script/shader runtime errors. Test windows assert NO_FOCUS and uncaptured mouse; no desktop input was automated. Runtime APPDATA/LOCALAPPDATA/TEMP stay inside `art_src/s3b/runtime`, Dummy audio, one game run at a time.

## Visual review and remaining defects

Viewed every capture through the labelled source pages, all comparison sheets, and the full-size cafe/headland/roof/gull key shots. The warm red roof/cream wall separation now survives distance, paving no longer reads pink-lilac, cafe umbrellas/light strings read as a place, and the headland shows red/white stripes and shaded rock facets. The white gull remains separate from the richer background.

**Still below the cover:** the headland is a conspicuous broad polygonal truncated mound with large facets and some regular tiering, rather than naturally broken cliffs; its symmetric layout and oversized turbines remain. Water has repetitive wave bands, weak reflected detail and no scene/boat reflections; the fixed pier view lacks the cover's bright sun path. Window glow is visible but does not cast local light on the plaza; wall/back facades and cafe furniture are still plain. Vegetation remains toy-like with some overly bright greens; broad hard shadows and sparse harbour detail remain. Paving/wood contrast is under target. The covered rock face is visual-only and has not been manually flown against at every point.

Review entry: `art_src/s3b/review/summary_before_after_cover.png`; dedicated roof/pier/town/flight, cafe distance, ground and gull sheets alongside `material_crops.png`. Raw final images: `art_src/s3b/final/`. First-pass brown banded "cake" and pass-2 too-grey facets are retained, not silently overwritten. `viewed_images.json` records reviewed image hashes. No downloads, MCP, desktop automation, web export, build publishing, gameplay tuning, or Git commit (workspace has no Git repository). **STOP S3b; await the next art review, do not start S4 or another tuning pass.**

Reproduce captures: `powershell -NoProfile -File tools/art_pipeline/run_s3b.ps1 -Label <new-label> -Mode Cams`. Contract: same runner `-Mode Contract`. Repaint: `python -I tools/art_pipeline/s3b_palette.py`, then runner `-Mode Import`. Terrain bake uses the runner's isolated environment with `--headless --script res://scripts/art/s3b_bake_terrain.gd -- --art-s3b`. Measurement/sheets: `python -I tools/art_pipeline/s3b_evidence.py <label>`. One full regression only per final phase; do not loop it for art tuning.

<!-- END S3B HANDOFF -->

---

# S3 kit integration and ground — four art iterations; STOP for review

2026-10-11. Built against `docs/41` / `docs/43` and the user's cover. **Submitted, not art-approved; the cover-quality gate is NOT claimed complete.** Four art tuning iterations used. Final validation within iteration 4 corrected two implementation defects (imported normals and unindexed canopy batching); the failed captures remain as evidence. No S4, web export, downloads, desktop input automation, Git repository, or release.

## Delivered

- Reusable `tools/blender/import_kenney.py`: local licensed GLB import, face-centre UV colormap sampling / untextured material factors, semantic palette remap, 8-ray light AO and height gradient, metre fitting / base origin, merged single surface, split flat triangles, no output textures/cameras/lights. Fifteen exports total **1,898 tris**; props ≤188, palm 482; one shared existing soft-toon material. One rock prototype is retained but not visibly placed. Every used source, official URL, licence and derived path is in `art_src/third_party/ASSET_MANIFEST.md`; hashes, UV palette samples and AO data are in `kit_catalog.json`.
- Ground: removed Compatibility's extra colour darkening and noisy/gritty modulation, using cream sand, sage grass, warm grey paving and restrained rock strata. Height field, all terrain vertices, vertex colours, normals and collision geometry remain bit-identical. Height samples are cached once in `build_mesh()` to offset import/build cost; `H()` and gameplay use of it are unchanged. Headland and terrace edges gain non-solid nature-kit rocks/cliffs, bushes and flowers.
- Sea/pier: blue-teal/shallow palette, gentler ripple contrast and foam localized around original pier-post coordinates; S2 glitter retained. Flat water silhouette now uses 18 triangles instead of 65,522; wave shading remains in the existing opaque shader without a reflection pass. Original landing decks gain golden plank shading, plus barrels, stacked kit planks, crates, bollards, low-poly rope coils and two decorative CC0 rowboats. Lamp positions, glowing bulbs, rails, string lights and Ferris mechanism retained. Existing sailboats remain: full pirate ship and extracted sail experiments were rejected; no new sailing/fishing-boat family is claimed. These original boats are statically batched, so there was no existing bobbing to preserve or change.
- Cafe: kit octagonal round tables, chairs, planters, plates/drinks, striped umbrellas and cafe awning, small counter frontage. Existing menu boards, interactive fry cartons, triggers and NPC placements retained. Table surface height stays .81 m; original procedural builders still execute their collision and RNG calls. Beach: same umbrella locations with striped canopies and faceted palms at existing kind-2 tree bases; existing loungers, towels and tiki bar retained. Houses, stairs, warm windows and shops use the existing S2/P1 assets; no fantasy-town housing rollout.
- Static non-emissive primitives now join the shared vertex-colour batches by 50 m district, alongside imported props. This is a visual/material route only; special window/lamp/emissive materials keep their original path. Repeated palms use the existing scenery MultiMesh route. Missing/invalid kit meshes fall back to the original builders. No per-prop process, new light, collider or gameplay system.

## Real-game A/B measurements

Fresh S2-end-state baseline and final `iteration_4_verified/`, identical S2 coordinates/FOV, golden+dusk for roof/pier/town/flight; cafe 3/15/60 m, beach/headland and forced governor 2. Native Godot **4.7.1**, Compatibility, RTX 5070 Ti Laptop; 960×540, 30 samples, 30-fps cap. Governor 0 and forced governor 2 are measured separately; this is not an adaptive-governor or browser throughput test. `triangles` are Godot's rendered primitive monitor, including passes, not unique scene triangles.

| View / time / governor | Draw calls before → after | Rendered tris before → after | Render CPU ms before → after | Render GPU ms before → after |
|---|---:|---:|---:|---:|
| roof / golden / 0 | 1,447 → 1,330 | 943,060 → 657,496 | 5.256 → 3.868 | 0.539 → 0.538 |
| pier / golden / 0 | 2,451 → 2,289 | 1,081,898 → 918,946 | 7.375 → 5.678 | 0.556 → 0.851 |
| town / golden / 0 | 2,610 → 2,425 | 1,166,292 → 912,743 | 6.231 → 5.179 | 0.667 → 0.583 |
| flight / golden / 0 | 179 → 135 | 425,494 → 225,852 | 1.851 → 1.591 | 0.358 → 0.546 |
| roof / dusk / 0 | 1,646 → 1,529 | 979,692 → 684,844 | 5.777 → 3.635 | 0.764 → 0.517 |
| pier / dusk / 0 | 2,632 → 2,463 | 1,113,614 → 950,576 | 5.908 → 6.133 | 0.479 → 0.614 |
| town / dusk / 0 | 2,577 → 2,389 | 1,161,864 → 906,842 | 5.226 → 4.646 | 0.443 → 0.499 |
| flight / dusk / 0 | 174 → 135 | 424,478 → 225,852 | 2.169 → 1.686 | 0.705 → 0.540 |
| cafe_3m / golden / 0 | 1,693 → 1,539 | 1,014,354 → 764,611 | 4.178 → 3.315 | 0.587 → 0.553 |
| cafe_15m / golden / 0 | 2,079 → 1,917 | 1,079,416 → 906,738 | 5.124 → 4.458 | 0.446 → 0.532 |
| cafe_60m / golden / 0 | 2,661 → 2,497 | 1,115,766 → 967,422 | 6.035 → 5.836 | 0.499 → 0.611 |
| beach / golden / 0 | 2,952 → 2,757 | 1,068,484 → 929,330 | 7.943 → 5.920 | 2.265 → 0.541 |
| headland / golden / 0 | 756 → 659 | 666,256 → 417,897 | 3.636 → 2.411 | 0.654 → 0.606 |
| pier / golden / 2 | 1,528 → 1,397 | 894,740 → 658,806 | 6.508 → 4.342 | 0.597 → 0.501 |
| cafe_3m / golden / 2 | 1,110 → 971 | 902,610 → 659,823 | 3.578 → 2.722 | 0.503 → 0.517 |
| cafe_15m / golden / 2 | 1,393 → 1,247 | 950,634 → 724,507 | 4.831 → 3.526 | 0.497 → 0.513 |
| cafe_60m / golden / 2 | 1,787 → 1,648 | 958,182 → 742,535 | 6.941 → 4.665 | 0.607 → 0.521 |

All **17/17** matched rows have fewer draw calls and rendered triangles. Matched-camera build log: **1104 → 978 ms**. This is one pair, not a controlled startup distribution: the separate full-autotest launch was **1521 ms**, and final-stage capture launches ranged 721–978 ms. Do not claim a universal startup speed-up or certified browser budget. Absolute render timings still fluctuate: worst CPU delta +0.225 ms (pier dusk), worst GPU delta +0.295 ms (pier golden). Lower draws/tris do not establish a universal GPU-time win; the capped frame intervals are not throughput proof.

## Verification and provenance

- Final `s3_contract.gd`: all fifteen imported meshes have expected metre bounds, flat nondegenerate triangles, COLOR_0, one surface, shared material and per-asset budgets. Missing/disabled asset checks pass; old vs new terrain vertex/colour/normal arrays are exactly equal. All original 1498 collider shapes/local transforms hash identically, and all anchor values match. Five wrapped procedural bodies compare byte-identically; source scope details are in `source_scope.json`.
- One full `--autotest`: **24/24**, rainbow obtained, ordinary-fry ending; `[AUTOTEST] ended=true phase=3 stats={ "stolen": 25, "perfect": 3, "shot": 0, "slipped": 0, "walls": 1, "missed": 1, "swats": 1, "vision_s": 0.0, "fish": 0, "rivals": 0, "bops": 0, "scares": 1, "drinks": 1, "fed": 0, "friends": 0, "rainbow": 1, "star": 0, "gifts": 0, "meteors": 0 }`. This verifies the endpoint, not deterministic agreement of all wall/perfect/miss counts or a human playtest. It ran after the final GLB normal fix but before the final canopy index fix; the canopy fix got its 48-triangle contract, final same-camera/physics/anchor verification, and no second full suite.
- Final capture logs contain no script/shader runtime errors. Existing native shutdown RID/resource leak errors remain (including nonzero wrapper status on the full autotest); **not a clean-exit claim**. Final focused contract exits 0. Captures assert NO_FOCUS and uncaptured mouse. Runtime saves/temp/audio driver are isolated to `art_src/s3/runtime`, with Dummy audio.
- **Concurrent edit, not made by S3:** `game/scripts/systems/audio_manager.gd` changed during this session from WAV data-size loop length to duration × mix rate. It was preserved, not reverted or credited to this art task. Exact diff is recorded in `source_scope.json`; audio correctness was not tested. All other non-art/gameplay source/config changes are enumerated in `audit.json`; project settings, controller, story, saves, encounter definitions, numbers and text were not edited by S3.

## What was actually seen against the cover

Sand now reads as warm sand, and the ground no longer dominates as dirty brown noise. Pier boards, striped umbrellas, round tables, chairs and small plants are readable in the real cameras. Normals are now visibly faceted on barrel bands, cup and planks. Roof golden-hour composition retains S2's useful warm mood.

**Still below target:** the headland is still a large smooth mound with a sparse applied-rock treatment, not the cover's convincing layered cliff silhouette; terrace strips remain regular. Water has shallow colour and glitter but lacks boat/building reflections and the cover's crisp sparkling depth. Buildings/people/paving remain paler and flatter than the cover, shadows are hard, generic house backs and lit-window warmth remain weak. Palms have angular ribbon leaves; furniture is still plain; table close-up is partially occluded by original NPCs. The two added rowboats are modest detail, not a rebuilt fleet; retained menu boards, loungers/towels/tiki bar and houses are not upgraded kit families. No full cover-quality or complete spec-content acceptance is claimed.

Rejected records: iteration 1 studded-rock ring and overly regular water; iteration 2 block-wall rings, thick palms and unusable sail adaptation; iteration 3 tall repetitive rock pillars; iteration 4 custom-normal reset failed, then fresh split-mesh export passed; unindexed canopies were absent until the indexed-batch correction. No fifth art tuning pass was started. The final evidence folder is **`iteration_4_verified/`**, not `iteration_4/` or `iteration_4_final/`.

Review: `art_src/s3/review/summary_before_after_cover.png`, four fixed-camera sheets, cafe distance sheet, ground/beach sheet; all source captures and failed iterations retained. `viewed_images.json` inventories inspected images. Reproduction: `run_s3.ps1 -Label <new-label> -Mode Cams`, `-Mode Contract`, importer command in its docstring, then `s3_delivery.py` / `s3_scope.py` / `s3_notes.py` for the current fixed handoff. **STOP S3; awaiting art-director review.**

---

# S2 cover atmosphere — four internal art iterations; STOP for review

2026-10-10. **S2 only**, after S1 approval in ART_REVIEW Review 9. The real Godot island now has a four-key colour script, warm/cool lighting, dusk lights, calmer teal water, sun glitter, layered distant land and lighter gull wings. This is an implementation/review submission, **not a claim of matching the cover or art-director approval**. No S3, export or release.

## What changed

- `day_cycle.gd`, `cover_sky.gdshader`, `_environment`: morning / afternoon / golden / dusk keys at t=0/.35/.72/1; lavender-blue ambient/shadows and warm direct light; purple/pink/peach sky with a sun-facing warm horizon. Existing progress clock, movement of t and catchable sun position are unchanged.
- `cover_atmosphere.gd`: existing shared window/lamp materials, thin batched overlays at authored houses' real window coordinates, 36 cafe/pier string bulbs and 24 Ferris bulbs. **204 halo instances in two MultiMeshes**, two new shared spatial materials (halo/haze), one sky material, **zero added OmniLights**, zero per-object processes or textures. The full scene still has one pre-existing OmniLight.
- Native glow is enabled at governor 0–1, with restrained local additive halos. **Correction:** the first RGBA `ImageChops.getbbox()` check returned None because alpha difference was zero, incorrectly suggesting no native bloom. RGB comparisons show it works, consistent with the [official Compatibility glow documentation](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html#glow). Final on/off mean RGB difference is **0.4658/255**. The incorrect disabled-glow captures/composites are retained in `iteration_4_glow_disabled/` and `review_glow_disabled/`; final evidence is `iteration_4/` and `review/`. The fourth iteration included this technical validation correction; there was no fifth art tuning pass.
- `sea.gdshader`: opaque teal/blue palette, analytic coast depth/foam from existing shoreline boundaries, pier foam, pink/lavender horizon reflection and broken directional gold glitter. No screen/depth sampler, SSR or extra water pass. `ground.gdshader` only dims the overbright wet-sand strip. Water collisions/height remain unchanged.
- Giant decorative cone mountains replaced by three merged rounded hill layers with manual atmospheric colour, plus one merged non-solid distant lighthouse/turbine island. Original playable lighthouse, wind turbines, terrain and colliders remain. Clouds use smoother normals on the same cheap geometry and pink/lilac dusk paint; drift/rain/quest placement is unchanged.
- `soft_toon.gdshader`: cool shadow fill, bounded warm directional tint/rim; neutral gull wing paint becomes pale grey-lilac while dark tips/cosmetic colour regions remain. No GLB or pivot changes. Saturation now plateaus at **1.08** (old full-special 1.56); glow cap **.42**, tested full-special **0.404** (old .75). Gull Sense .35 and ending .96/.30 overrides remain.

## Real-game evidence and performance

Four fixed cameras (opening cafe roof to pier, pier/marina, hillside stairs, flight to the sun) × four time keys, **960×540**, same coordinates/FOV before/after. The baseline is the actual current S1 build captured before S2, not a mixed historical render. Contact sheets include cover crops. Additional rear flight, close gull colour keys, late progress, ending, Gull Sense, native glow A/B and governor 2/3/web-lite branch captures were inspected. All produced images, including rejected/diagnostic ones, are indexed in `viewed_images.json`.

Desktop Godot **4.7.1**, GL Compatibility, RTX 5070 Ti Laptop; **30 samples per row, 30-fps cap, governor 0, 3D scale 1**. Four dusk rows below; all 16 pairs are in `audit.json`.

| Camera / dusk | Draws before → after | Frame interval ms | Render CPU ms | Render GPU ms |
|---|---:|---:|---:|---:|
| roof | 1648 → 1646 | 33.338 → 33.131 | 4.179 → 3.996 | 0.524 → 0.508 |
| pier | 2636 → 2632 | 33.259 → 32.987 | 5.795 → 5.798 | 0.500 → 0.585 |
| town | 2584 → 2577 | 33.398 → 33.255 | 4.731 → 4.966 | 0.459 → 0.473 |
| flight | 181 → 174 | 33.319 → 33.326 | 1.366 → 1.432 | 0.461 → 0.464 |

Across all 16 pairs, largest median frame-interval change: **+0.09%**, draw changes **-9 to -2**. **The required +10% performance gate remains unverified:** the 30-fps cap hides available throughput. Render CPU rose **5.045 → 7.297 ms (+44.64%)** in the afternoon pier view; GPU rose **0.583 → 1.269 ms (+117.67%)** in the afternoon town view. These are unresolved timing regressions; laptop scheduling is a possible confound, not an established explanation. Lower capped intervals are not a speedup claim. No fifth art iteration or extra benchmark was started. Synchronous build **1824 → 1048 ms**, separate runs, not a controlled startup benchmark. Governor 2/3 and native `GS.web` branch assertions confirm glow, halos, glitter and extra horizon/sun-corona layers off; core colour, sea, light cores and one hill layer remain. Browser itself was **not exported or run**.

## Validation and remaining defects

- Source audit: **69/78** pre-existing script/shader/scene files byte-identical; the nine changed files are enumerated in `audit.json`. All gameplay world functions outside the seven visual/build hooks are identical; `main.gd` differs only by one atmosphere reference. Progress computation, sun quest placement, project settings, gull GLB, model loaders/fallbacks, controllers, audio, story, save code and numbers are unchanged. Scene collider count **1498 → 1498** (count plus source-scope check, not an exhaustive physics replay).
- **One full --autotest:** 24/24, rainbow obtained, ordinary fry and `ended=true phase=3`; ten regression images inspected. It ran immediately before the final native-glow switch correction; that correction received the final camera/governor checks, not a second full suite. Known shutdown RID/resource warnings remain. Final logs contain no GDScript/shader runtime errors. Test capture asserts **NO_FOCUS=true and mouse not captured**; no desktop input automation.
- Seen against the cover: the blue-green sea and small gold reflection marks replace cyan/white glare; warm dusk lamps/windows and pale wings are clearer; giant pyramids are gone. **Still flatter than the cover:** sunlight/rim is weaker, trees/buildings have pale toy colours, shadow edges/roof moire remain, hills are simple smooth silhouettes, cloud masses are sparse and bubble-like, water sparkles remain procedural and there are no full boat/lamp reflections. The existing bright vertical gameplay-effect columns remain visible. The distant island's turbines are static decor.
- The catchable sun is deliberately still 90–125 m high, so it cannot reproduce the cover's low horizon sun without changing the gameplay target. The fixed map/camera composition also differs from the cover's stacked town; no S3 layout/asset work was attempted. Light-core emission/halos are visual accents, not local illumination or bounced light.

Reproduce only when requested: `powershell -NoProfile -File tools/art_pipeline/run_s2.ps1 -Label iteration_4 -Mode Cams`; then `s2_sheets.py iteration_4`, `s2_audit.py iteration_4`, `s2_delivery.py`. Launcher isolates APPDATA/LOCALAPPDATA/TEMP/TMP under `art_src/s2/runtime`, uses Dummy audio and 30 fps. No downloads of assets/dependencies, no new MCP server, no external writes, no web export, no Git repository available. **STOP S2.**

---

# Round 14 changes - S1 round 2 / Review 8 / STOP

2026-10-10. **Round 2 of at most 3 for S1.** Addressed Review 8 in order and stopped for review. Numerical silhouette gates pass; no artistic approval is claimed. No S2, web export or changes to gameplay numbers, text, audio or saves.

| Orthographic silhouette IoU | Before | After |
|---|---:|---:|
| Front | .862900 | **.864363** |
| Left | .455244 | **.751080** |
| Top | .722123 | **.872098** |
| Right | .453788 | **.751077** |
| Back | .859254 | **.870008** |

Review 8 targets front/top >=.85 and left >=.75 are met. Actual Blender alpha, same reference-mask/bbox-normalization method as round 1; no anisotropic scaling. **Camera/wing poses were registered to the illustrated references**, including asymmetric side upstroke and spread top view. All parameters are saved. These scores include pose correction and do not isolate geometry quality; the left/right result is marginal and the far wing still differs visibly.

Review items and measurements:

1. **White:** F7F7FA paint, approximately +/-1% facet luminance, tiny cool underside bias; removed strong painted stripes. Gull-only `plumage_fill` preserves near-white with light cool shadows. Actual noon/golden/dusk median body luma **197→236 / 196→233 / 183→222**. Brightest 20% RGB after **241/241/245, 240/238/242, 229/226/231**. Scenery's shader parameter remains zero and scene lighting is untouched. See the cover/three-light comparison and exact mask method in the manifest.
2. **Silhouettes:** five-view measurement above, complete overlays and reference registration JSON retained. Model remains a plump, faceted gull with original head/body/leg anchors.
3. **Beak:** shortened **18.8%** (.181→.147 m), slightly narrower, horizontal lower edge, thick tip with a short red-orange end. Existing socket unchanged.
4. **Eyes:** dots **20% larger**, .023 m lower / .011 m forward; glasses and shades refitted locally. Dots only barely resolve at 15 m and do not resolve at 60 m.
5. **Wings:** extended the upper/fore shells across the real joints; discarded button-like cap attempt. Mesh-local fold fitting reduces folded wing vertical extent **.495→.198 m**, making perch wings lie along the body. Shoulder/elbow animation, fold weight and timing stay unchanged. **Remaining:** hard overlap edges at extreme poses; the full-range invisibility requirement is not unconditionally certified.
6. **VN / necklace:** actual YOU, hatted YOU and Big Bro portrait captures include whole heads/hats; top margins approximately **74 / 58 / 41 px** on 320px portraits. Big Bro necklace median forward coat clearance **.197→.0098 m** (unscaled coordinates), no floating front plane. Story changes are limited to the portrait camera helper.
7. **Cover pose:** actual café-roof dusk captures with wings raised and an ordinary fry at the retained socket; cover crop comparison plus rear three-quarter image. Ground-only stale-ray and partly buried-feet drafts are retained as failures; final fixture uses the real roof height and transformed foot minimum.

Final hero: **734 tris / 11 parts / 1 shared gull material / 85,224 bytes**, versus 714 / 11 / 1 / 83,340 before. Five existing wearables regenerated with unchanged triangle/surface counts. Pivots, body scale compensation, variants, 2.3x Big Bro, beak socket, trails and procedural fallback retained. `gull_visual.gd` changes only authored mesh-fold target fitting; `story.gd` changes only camera framing. Both files are byte-identical outside those visual helpers. Overall source audit: **72/77** baseline source/config files unchanged.

Final same-session A/B: **2,286→2,286 draws**, **33.322→33.240 ms** median frame interval, 30 fps cap / governor 0 / 512x288. CPU 6.444→6.317 ms; GPU 3.411→.581 ms is variable sampling, not a speed-up claim. No web-performance claim. Contract PASS: 128 paired animation-pivot samples, 23 wearables, all 734 triangles flat, tint/reset/socket/trails and missing/invalid fallbacks.

**One full autotest**, exit 0: **24/24**, rainbow obtained, **ended=true phase=3**. Final stats stolen 25, perfect 4, walls 3, missed 0; existing SPECIAL_ORANGE retry occurred. The final joint-cap removal came after that run and received focused import/contract/capture checks, not a second full suite. All ten regression images were viewed. Existing shutdown leaks remain; no script/shader errors. Existing Godot 4.7.1 and Blender 5.2.1, isolated in-project saves/temp, no downloads or Git checkout.

Evidence: `art_src/s1/round_2/review/{cover_comparison,five_views,silhouettes,white_before_after,portrait_and_fold}.png`; final raw game images in `game/`; measurements in `silhouette_iou.json`, `colour_measurements.json`, `dimensions.json`, `game/metrics.json`, `contract.json`, `source_audit.json`, `visual_scope_check.json`. Every produced image was inspected, including discarded attempts; `viewed_images.json` records their hashes. The final part generator and pose JSON reproduce the delivered model; `run_s1_r2.ps1` and `s1_r2_delivery.py` reproduce checks/capture composition.

**What I saw:** cleaner white, clearer dot eyes, compact beak, wearable fit and uncropped portraits; folded wings no longer stand up as large plates. Against the cover, far-wing foreshortening, stacked torso facets, overbright Blender top faces and angular joint overlaps remain; dusk light remains flatter because S2 is outside this round. **STOP here. Review 8's visual follow-up is still needed; no round 3 or S2 started.**

---

# Historical: S1 faceted cover gull round 1 / not art-approved

2026-10-10. User's docs/41 direction applied, **S1 only, four internal geometry iterations**. Replaced the rejected smooth/feathery GLB with a flat-shaded gull: enlarged round head, two black dots without lids/highlights, short orange-yellow prism beak with a red-orange tip, plump white body, solid angular grey wings/dark tips, short tail wedge, yellow webbed feet. Retired generator moved to `tools/blender/archive/hero_gull_smooth_round14.py`; matching old GLB retained only in `art_src/s1/before/` for comparisons.

**This submission fails the complete silhouette gate.** Final IoU against front / left / top references is **0.862900 / 0.455244 / 0.722123**, target >= .85 for each. Front passes; left and top do not. The method, exact camera/pose assumptions, masks and intermediate results are documented in the S1 section of `ART_MANIFEST.md` and `art_src/s1/README.md`. Uniform bbox normalization only; no nonuniform warp. References are not calibrated orthographic views, but the visible shape mismatch is real and cannot be dismissed as only camera error. The final top camera's inverted roll was corrected and invalid evidence retained; no fifth model iteration.

| Bare hero | Before (rejected authored gull) | S1 |
|---|---:|---:|
| Triangles | 3,804 | **714** |
| Mesh parts / shared materials | 11 / 1 | **11 / 1** |
| GLB bytes | 118,928 | **83,340** |
| Visible main-pass surfaces, flying / feet out | 10 / 11 | **10 / 11** |

Wardrobe: mesh-local refit of 17 head/face/neck/body items, including brother variants; all 23 existing assets regenerated, same 3,878 total tris and same per-item surfaces. Hats sit over the new head, glasses/shades surround the new dot-eye positions, shirts/coats surround the fuller body. Necklace positioning and VN crop remain defective. Existing slot roots, names, effects and animation are unchanged. Procedural gulls now keep their procedural garments via one loader guard, avoiding the new large hats on the old small fallback head.

**Production scope audit:** 146/148 pre-existing source/config files byte-identical. Only `game/scripts/art/p2_parts.gd` (two-line fallback guard plus comment) and `game/scripts/autotest.gd` (opt-in review routes) differ. `gull_visual.gd`, both gull builders, all pivots, animation/fold formulas, growth/tints, beak socket, comet trails, 2.3x brother scale, controller, gameplay numbers, story, cameras, audio, shader, world light and saves are untouched. New code is review tooling: `s1_review.gd`, `s1_contract.gd`, `run_s1.ps1`, `s1_measure.py`, `s1_delivery.py`. Exact audit and asset hashes: `art_src/s1/{source_audit,assets}.json`.

**Validation:** all 714 imported triangles have flat normals; 11 one-surface parts share one material. Contract PASS: 128 paired pose samples, 23 wearable cases, original socket/trails, recolouring/reset and missing/invalid-resource fallbacks. One complete autotest reaches **24/24**, rainbow grab, **ended=true phase=3**. SPECIAL_ORANGE required a retry after a MISCHIEF target; no exact incidental-stat equality claim. Used installed Godot 4.7.1, not 4.6.3; existing shutdown leaks remain. Saves/config/temp isolated inside `art_src/s1/runtime`. No Git checkout present. No web export.

**Measured A/B:** sequential hero-only swap on the same paused dusk island, 512x288, governor 0, 30-frame medians, 30-fps cap. Flight draws **2,282 -> 2,282**, frame **31.542 -> 31.261 ms**; real roof-perch draws **906 -> 906**, frame **30.898 -> 31.215 ms**. Geometry cost falls, draw count holds, frame differences are noise. GPU samples are variable, including an increase for perch (.700 -> 1.204 ms), so no GPU speed claim. World build 1,418 ms / first-review frame 6,082 ms are current observations, not startup non-regression proof. Final authority: `iteration_4/game/corrected/metrics.json`; earlier timing overlapped a short Blender camera repair and is excluded.

**Viewed evidence:** all **67 PNGs**, including unsuccessful iterations and ten regression shots. Four raw game shots at 960x540; other raw captures <=512, Blender 8 samples / four threads. Review entry: `art_src/s1/review/cover_before_after.png`, `five_views.png`, `wardrobe_and_vn.png`; silhouette overlay: `iteration_4/silhouette_comparison.png`. Capture repairs are transparent: early ground pose was suspended over water; `game/corrected/perch_dusk_*` show an actual roof; uncropped upstroke replaces the clipped first shot. Actual VN viewport crops were preserved as failures, not reframed only for review.

**Critical comparison:** the plain dot eyes and much larger head restore the intended innocent expression, and white/grey/yellow read in noon, golden hour and dusk. The cover still has a more coherent head/body mass, better wing shape and warmer lighting. Current folded wings look like angular plates; extreme downstroke has hinge seams; side/top silhouettes fail; head/chest facets feel stacked; necklace floats; the default portrait camera crops the hero's head and brother's top hat. At 60 m only the light silhouette remains. **S1 submitted, visual gate NOT passed. STOP at the four-iteration limit; no S2 work.**

---

# Historical: P2 delivery / STOP for review

2026-10-10. **P2 only, three internal iterations maximum. Awaiting Claude's review; not approved. No P3 or web export.** Work order: fries, wardrobe, dog/fish, special cast/VN. P1a/P1b models and the approved shared shader are unchanged.

- **Fries:** six authored GLBs with bevelled golden sticks, carton/cream label, cone/twist, plate/dip and special colour ribbon. Ordinary stays unlisted/non-glowing and keeps its original rules. Carrier/lock-on/halo/reveal logic is untouched. Hand scale lives on mesh children so restocking retains it.
- **Wardrobe:** all 19 kinds plus four Big Bro variants. Existing slots, removable roots and animated scarf/balloon/meteor nodes remain. Alpha, glow overlays and particle logic remain. Three complete outfits captured perched and flying, every item fitted in Blender front/side views.
- **Creatures:** round floppy-eared dog on its old seven animation parts; nine rounded fish on Body/Tail pivots. Species/rarity/size/weight/catch/swim behavior unchanged.
- **People/VN:** approved P1b body reused for vendors, old man, child, backpack and vest. Existing held meshes merge under their original hand roots, keeping an equipped character within 9-11 surfaces. Actual YOU/BIG BRO portraits and a labelled FRIEND review fixture captured; no new dialogue or characters.

| Asset | Old tris / surfaces | P2 tris / surfaces |
|---|---|---|
| Box / plate fry set | 348 / 29; 5,184 / 51 | **596 / 2; 548 / 2** |
| Hand / cone / special / ordinary | See manifest for kind-dependent old geometry | **504 / 2; 504 / 2; 420 / 2; 60 / 1** |
| Wardrobe, 23 assets total | 66,450 tris | **3,878 tris; 40-244 per item**, no item draw increase |
| Dog | 156 / 13 | **1,192 / 7** |
| Nine fish | 10,328 total; 6-15 surfaces each | **5,472 total; 580-676 / 2** each |
| Person body / equipped | P1b body 9 surfaces | **Same body**, <=11 with both hand props |

Asset surface counts exclude existing fry halos/rims and particles. Wardrobe's animated pieces/effect overlays retain their separate surfaces; see exact counts/contracts in `ART_MANIFEST.md`. Person 1,800-triangle budget refers to the body; unchanged props add triangles (final vendor with ice cream 1,964 / 10).

Files: `tools/blender/{fries,wardrobe,creatures}.py`; **39 GLBs / 454,972 bytes** in `game/assets/models/`; loader `game/scripts/art/p2_parts.gd`; emission-only soft-toon variant `game/shaders/fry_clay.gdshader`. Five production visual hooks in fry/gull_visual/dog/fish_spot/human_rig. Review/check tools: `p2_review.gd`, `p2_contract.gd`, `run_p2.ps1`, `p2_delivery.py`, plus opt-in autotest routing. Original gameplay functions are byte-equivalent after removing those hook lines; 62 other existing scripts/shaders are unchanged (`art_src/p2/source_audit.json`).

Evidence entry point: **`art_src/p2/review/`**, twelve before/after, outfit, wardrobe and portrait sheets. Final raw assets/captures: `art_src/p2/iteration_3/`. Final person/held-item evidence superseding older counts: `iteration_3/game/details_held_final/`. All **237 PNGs opened**, including intermediate failures; hashes/dimensions in `art_src/p2/viewed_images.json`. Exactly four 960x540 images, others <=512; EEVEE 8 samples / four threads. Initial floating dog pieces and wearable placement were repaired. Canonical GLB node-name suffixes caused fallback on later assets in iteration 2; iteration 3 contract proves authored nodes loaded. Old failures are retained and labelled, not passed off as final renders.

Validation: one full `--autotest` reached **24/24**, rainbow grab and **ended=true phase=3**. The final held-prop merge and meteor billboard material fix occurred afterward and received focused checks/captures. Final contract covers **136 fry cases, 23 wearables, 9 fish, dog pivots and 18 types of dual-hand props**, with plain rules, RNG, aim/vision, required meshes, budgets and missing-part fallback checks. See `art_src/p2/contract.json` and `autotest_i1.log`. Isolated APPDATA/LOCALAPPDATA; production saves untouched. Validation used existing **Godot 4.7.1**, not separately tested 4.6.3. Existing shutdown-leak warnings remain.

Same-session **fry-only** cafe A/B: draws **1,935 -> 1,673 (-13.54%)**, frame **33.182 -> 33.370 ms**, CPU **5.932 -> 5.659 ms**, GPU **.581 -> .718 ms**, governor **0**. Desktop 512x288, 30-fps cap, 30-frame medians; .57% frame difference is noise, GPU increase reported honestly. Both halves precede the final held-prop merge. Final world-build observations 1,129 / 933 ms and first-review-frame 3,987 / 3,611 ms are separate runs, not controlled startup A/B. No uncapped speed, first-frame non-regression or web-performance claim.

Seen: golden sticks read softer and appetising close up; paper/dish separate clearly; dog has connected paws/tail and floppy ears; hats/glasses/coats and fish have rounded silhouettes. **Remaining defects:** 60m cafe glint is weak/awning-occluded; box rim angular and salt faint; special sticks stay gold with colour identity on the ribbon/effects (literal per-kind stick tint not implemented); simplified wardrobe patterns and Big Bro coat details; occasional accessory occlusion; fish matte with similar common-species silhouettes/weak markings; tall Big Bro hat cropped in existing VN framing. P1a defects and roof/sea banding remain. These limits are open for art review, not claimed passes. **STOP P2.**

---

# Historical: Review 4 P1b revision / STOP

2026-10-10. **P1b review round 2 only, two internal asset iterations. Six open items addressed; stopped for art-director review. No P2 or web export.** P1a models and carried defects are unchanged.

- Trees: deeper saturated green per-lobe paint, restrained yellow-green caps, darker teal pines; four distinct lobes with round/oval/umbrella silhouettes and exposed branch forks. Wind alpha 0..1 retained.
- People: curved closed apron bib plus waistband and shoulder straps; volumetric backpack and fitting vest; thicker tapered upper arms/thighs, cuffs, neck and larger shoes. Garments scale with torso fatness. Faces' positions/normals/colours are verified identical. The common Blender helper now unifies tint UV layer names before joining, fixing metadata loss on mixed custom meshes and Blender primitives (including hands/buns).
- Houses: six richer wall palettes with deeper terracotta/salmon/teal roofs; all footprints, door positions, roof geometry and colliders unchanged.
- Shared shader: shadow floor .68 -> .43 and rim .025 -> .008. Lit palette, mild violet shadow hue and single cheap pass retained; light, fog and gameplay values unchanged. Gull still reads white: lit-body S 0.47% noon / 3.70% golden (<12%). Golden sample is only 14 eroded pixels at 512x288; quantitative precision is limited.

| Asset | Original procedural | Current P1b |
|---|---|---|
| Deciduous / pine | 540 / 560 tris; 4 / 5 primitives, two material groups | 500 / 450 tris; one surface each; five MultiMeshes total |
| House | 140-1,076 tris; 12-47 primitives / 7-15 groups | 520-1,192 tris; one surface each; eight district batches |
| Person, eight cast styles | 4,584-8,952 tris; 15-17 surfaces | 1,340-1,522 tris; nine surfaces |
| Person, every option | up to 21 surfaces excluding held items | 1,790 tris / 1,800 budget; still nine surfaces |

Same-session matched crowded town: **2,070 -> 1,429 draws**, frame **33.520 -> 33.195 ms**, render CPU **5.551 -> 4.736 ms**, GPU **1.616 -> .696 ms**. Desktop Compatibility 512x288, 30 fps cap, 30-frame medians, 171 rigs and matched props; frame difference is noise, not an uncapped speed claim.

| Same 960x540 street view | Foliage mean S old -> new | S ratio >=.90 | Full-frame luma std ratio >=.95 |
|---|---:|---:|---:|
| noon / 15m | 52.91% -> 54.10% | 1.023 | 0.978 |
| noon / 60m | 42.23% -> 46.50% | 1.101 | 0.966 |
| golden / 15m | 44.40% -> 46.79% | 1.054 | 1.009 |
| golden / 60m | 46.27% -> 45.25% | 0.978 | 0.987 |

All four pass. Geometry-based masks include crowns and unchanged same-material hedges; no colour-threshold selection on the beauty image. Grass/palms/trunks/background are excluded, one-pixel erosion. Contrast is full-frame display-sRGB Rec709 luma standard deviation. Invisible transparent effects are hidden only during the mask diagnostic. Final numeric authority: `art_src/p1b_review2/iteration_2/game/colour_measurements.json`; four side-by-side sheets at `iteration_2/before_after_{noon,golden}_{15m,60m}.png`.

Files: `tools/blender/{trees,houses,person,p1b_common}.py`; updated corresponding GLBs under `game/assets/models/`; `game/scripts/art/person_parts.gd`; `game/shaders/soft_toon.gdshader`. New opt-in review/measurement/audit tools are `p1b_r2_review.gd`, `run_p1b_r2.ps1`, `p1b_r2_measure.py`, `p1b_r2_audit.py`, with isolated routing in existing review/contract/autotest scripts. `ART_MANIFEST.md` contains exact unchanged person/gull pivot contracts and full evidence paths. Final source provenance is trees/person iteration 2, houses iteration 1.

Validation: 9 styles x 13 modes x 3 modifiers x 45 frames pass, with cache/fallback/alpha/mesh budgets and unchanged held anchors. All 1,454 world colliders and full generation records match. Source audit verifies face geometry/paint, tint UV regions and unchanged gameplay, human animation, world builders, gull and save code. No full gameplay-suite repeat this revision; the prior P1b 24/24 is historical. All **113 PNGs** were opened, including invalid diagnostics; inventory in `art_src/p1b_review2/viewed_images.json`. Early clothing clipping was fixed; mask-only harness repairs are retained with `_invalid` suffixes and excluded from acceptance. No third asset iteration.

Seen: lush green crowns, darker pines, clearer roof/wall separation, wrapped garments and sturdier people. Honest remaining defects: low-poly tree outline steps and similar pine variants, partly hidden round/oval forks; noon frame contrast is still 2.2-3.4% below old (within the review threshold), sparse house backs/shallow hips, occasional raised-hand/hair overlap, and existing roof shadow banding. No zero-intersection or art-approval claim. STOP.

---

## Historical P1b round 1 delivery (superseded by Review 4 revision above)

# Round 14 changes - P1b complete, stopped for review

2026-10-10. P1a is approved by `ART_REVIEW.md` Review 3. This delivery is **P1b only**. The gull, shared shader and carried gull defects are unchanged. No P2 or web export.

Blender generators `tools/blender/trees.py`, `houses.py`, `person.py` use `p1b_common.py` and the existing pipeline. They produce five tree GLBs, 22 houses fitted to the real seed-42 footprints (six colour combinations), and `person_parts.glb` in `game/assets/models/`. Runtime loaders are `game/scripts/art/scenery_parts.gd` and `person_parts.gd`; integration is in `world_builder.gd`, `batcher.gd`, `human_rig.gd`, with the original procedural builders retained. Trees have 0-1 wind weight in vertex alpha and five MultiMesh batches; houses merge into eight district batches. People cache recoloured meshes, merge hair/clothes, retain all animation pivots and held items, and use nine surfaces with the same shared opaque material as the gull.

| Asset | Old procedural | P1b |
|---|---|---|
| Deciduous tree | 540 tris, 4 primitives / 2 material groups | 496 tris, 1 surface, 3 variants |
| Pine | 560 tris, 5 primitives / 2 groups | 432 tris, 1 surface, 2 variants |
| Fitted house | 140-1,076 tris, 12-47 primitives / 7-15 groups | 520-1,192 tris, 1 surface each |
| Person (8 cast styles) | 4,584-8,952 tris / 15-17 surfaces | 1,378-1,470 tris / 9 surfaces |
| Person library maximum, all optional garments | old bare 14 surfaces, up to 21 with options | 1,754 tris / 9 surfaces; props remain extra |

Final matched crowded-town A/B: **2,070 -> 1,429 draw calls**, median frame **33.636 -> 33.125 ms**, render CPU **5.887 -> 4.538 ms**, GPU **1.698 -> .722 ms**. Same frozen island/session, 171 people, identical controller-added props, Compatibility 512x288, cap 30, 30 frames/state. Frame-interval difference is noise. `art_src/p1b/iteration_3/game/matched_metrics.json` supersedes the earlier pairs, whose old fixtures omitted post-build props. This is desktop evidence, not web certification.

Validation: original 1,454 colliders and complete house/tree generation records match; original human procedural and animation function bodies match. Nine styles x 13 modes x three modifier sets x 45 frames preserve pivots, hand anchors and emotes. Missing/invalid assets fall back; wind alpha and all budgets pass. **One full autotest reached 24/24, rainbow grab OK and `ended=true phase=3`**, with no script/shader errors. Normal world build was 798 ms in this run. Known shutdown resource warnings remain and affect PowerShell's wrapper status; completed test markers are in `art_src/p1b/autotest_i3.log`. Isolated project-local save/config directories; no user saves changed.

Looked at all **190 PNGs**, <=512 px, including superseded captures; hashes in `art_src/p1b/viewed_images.json`. Final Blender turntables/casts are in `iteration_3/{trees,houses,person}`. Corrected street views are `iteration_3/game/street_clear_*`; cafe, face, eight-style casts and all 13 pose modes are alongside them. There is no existing NPC VN portrait, so an in-engine face fixture is supplied. Family comparison sheets: `art_src/p1b/tree_before_after.png`, `house_before_after.png`, `person_before_after.png`.

Observed: warmer consistent pastels, clear cream/rose houses and muted sage trees, rounder people with distinct skin/clothing, readable figures at distance. Remaining defects: polygon steps in close tree silhouettes; exact foot contact on every crown variant not visually verified; pale olive foliage; subtle house bevels and shallow hip ends; sparse house backs; scalloped long-hair fringe and planar thick vest edges; a raised hand can overlap the hair silhouette at extremes. The third internal asset batch is final for this delivery. No zero-intersection or art-approval claim. Full file list, exact pivot contract and limitations are in `ART_MANIFEST.md`.

Review tools: `tools/blender/run_p1b.ps1` (`Import`, `Contract`, `Cams`, `Framing`, `Perf`, `Numbers`, `Autotest`), `p1b_sheets.py`; opt-in `game/scripts/art/p1b_review.gd`, `p1b_contract.gd`, `p1b_numbers.gd`. Checks and counts: `art_src/p1b/{validation,contract,numbers}.json`.

---

## Historical P1a/P0 changes (approval superseded by Review 3)

# Round 14 changes - Review 2 hero gull revision / STOP

2026-10-10. The user and `ART_REVIEW.md` Review 1 approve P0 as a pipeline; its old noise-level timing gate below is superseded. **P1a only is implemented. STOP for Claude's art review. No tree/house/person, P1b or P2 work.**

## Review 2 revision - historical result, 2026-10-10

Three internal asset iterations completed; STOP for art review. Only the hero gull and its shared shader were revised. No tree/house/person, gameplay values, text, audio, saves or web export.

Files: `tools/blender/hero_gull.py` -> `game/assets/models/hero_gull_parts.glb`; `game/shaders/soft_toon.gdshader`; `game/scripts/player/gull_visual.gd`. Review support: `game/scripts/art/p1a_r2_review.gd`, opt-in `autotest.gd` dispatch, `tools/blender/run_p1a_r2.ps1`, `tools/blender/p1a_r2_sheets.py`. Manifest updated alongside this report.

1. Colour first: neutralised lit shader tint; mild violet restricted to shadow illumination and lower-belly paint; reduced AO and height darkening. Kept cream F7F1E6, blue-grey B9C3D1 and charcoal 3A3D48; retained .35 / 1.25 shadow bias. Viewed both required colour shots plus noon/golden/dusk cards. Final mean RGB / HSV S: noon 3 m **229.5,229.4,230.3 / 0.38%** (4,675 pixels); golden 15 m **244.2,240.3,235.3 / 3.63%** (104 pixels). Mean individual-pixel S is 1.97% / 3.58%. Mask uses body/chest/head UV regions facing the sun (N.L>.5), eroded 1 pixel; includes blue-grey back paint and possible self-shadow. Noon is near-neutral, golden warm. Both <12%; no whole-bird lilac cast seen.
2. Replaced sausage segments with longer thin blade wings, curved leading edges, tapered fore/hand, five layered primaries and a full charcoal band over the last 30% of each hand feather. Added shoulder/elbow covert coverage. Same-pose level span **1.915 -> 2.285 m (+19.3%)**, up **1.632 -> 1.966 m (+20.5%)**. At native 128 px, black silhouette widths **92 -> 109** level and **80 -> 93** up; black area **833 -> 895** and **769 -> 819** pixels. New silhouette has a longer taper, legible feather steps and softer leading edge; the old silhouette is shorter and rectangular.
3. Perch: more horizontal egg, blended neck, longer exposed shins with unchanged sole height, tail visible behind. Authored-only mesh children tuck back onto the body. Praised face geometry is preserved exactly: 642 head POSITION vertices match the previous GLB; eye/beak shape and socket remain.
4. Joint correction: the first long-wing pass crossed at extreme downstroke. Final mesh-child counter-rotation limits the effective fore/hand roll to +/-1.35 rad while all original animated pivots retain their exact transforms. This is an art adaptation, not a controller or animation-number change. The ground tuck changes only authored wing mesh children. Original fallback build is byte-identical; original pose calculations are identical except for the final art helper call. 128 sampled pivot comparisons and the existing contract pass; final up/down/flare/dive/mid-fold images show no open hinge gap or blade crossing. There is still a visible low-poly covert seam at close range.
5. Evidence: `art_src/p1a_review2/before_after.png` (includes old/new black silhouettes), `colour_check.png`, `joints.png`; final source frames/metrics in `iteration_3/`, Blender poses in `iteration_3/blender/`. All **67 PNGs** were opened, including rejected or invalid captures; inventory/hashes in `viewed_images.json`.

| Base gull | Old procedural | Review 2 authored |
|---|---:|---:|
| Triangles | 1,464 | 3,804 / 4,000 |
| Mesh parts / surfaces | 22 | 11 / 12 |
| Materials | 16 | 1 |
| Visible main-pass parts, flight / feet out | 18 / 22 | 10 / 11 |
| Imported vertices / GLB bytes | n/a | 1,990 / 118,928 |

Same-session controlled player replacement, frozen full island, 960x540, Compatibility, governor 0, 3D scale 1, 30 samples/state, cap 30 fps. All other authored gulls stay identical in each pair.

| View | Draw calls old -> new | Median frame ms | Render CPU ms | Render GPU ms |
|---|---:|---:|---:|---:|
| Flight | 1,039 -> 1,023 | 33.385 -> 33.202 | 3.251 -> 3.650 | 2.416 -> 2.458 |
| Perch | 1,216 -> 1,194 | 33.329 -> 33.285 | 3.726 -> 4.348 | 2.968 -> 2.983 |

Draw calls fall by 16/22. GPU medians rise 1.7% / 0.5%; capped frame medians change <1%. Render CPU readings rise **0.399 ms / 12.3%** and **0.622 ms / 16.7%**; disclosed as a limitation of this small paired sample, not evidence of an uncapped speed improvement. No repeat performance loop. The requested gate is tris/parts/draw calls/cheap shader; shader still has no new pass, sampling or loop. No browser-performance claim. Island build 679 ms, flora finished at 10.6 s. Engine: Godot 4.7.1 stable (existing deviation), Blender 5.2.1 LTS, RTX 5070 Ti Laptop.

Validation/provenance: iteration 1 was colour-only; iteration 2 built wings/perch and exposed crossing; iteration 3 fixed extremes/tuck and produced final evidence. An iteration-2 capture-helper integer/float error left invalid joint and silhouette poses; those PNGs/logs remain. The corrected harness-only subset is in `iteration_2/joints_valid/`; use iteration 3 for the result. A Blender world-node localisation lookup failed before rendering and was fixed; final export/render completed. Blender deprecation warnings can make PowerShell report exit 1 despite completed renders; logs and asset validation distinguish this from the actual earlier exception. No fourth asset iteration.

Import and the targeted `p1a_contract.gd` passed. No full gameplay suite was rerun; previous P1a 24/24 is historical. Existing shutdown resource warnings are ignored per Review 1. Isolated APPDATA/LOCALAPPDATA are inside the project. Source audit: only existing `autotest.gd`, `gull_visual.gd`, `soft_toon.gdshader` changed; 61 other snapshotted source/config files are unchanged. Praised head and procedural fallback are byte/geometry verified. Final art remains subject to the director's approval.

Remaining defects: elbow coverts still look like overlapping low-poly plates close up, primary ends are fairly straight, webbed feet have simplified toes, and dusk remains relatively bright. No further render iteration or next asset phase started.

---

## Initial P1a delivery (historical)

## What changed

- Review 1 item 1: `game/shaders/soft_toon.gdshader` now bounds directional light colour/energy, disables sky ambient bleaching, uses warm-violet shadow fill / warm lit bands, vertex-painted albedo and a small rim. Seven-colour card is visible under noon, golden and dusk. Sun direction, real attenuation, fog and governor shadow control still operate. No emission, outline, texture access, loop, metallic/specular or added pass. It deliberately responds less strongly than StandardMaterial3D to sky colours.
- Review 1 item 2: `world_builder.gd` visual shadow bias `.1 -> .35`, normal bias `2 -> 1.25`. Cube bevels are clean in `iteration_4/bevel_golden_close.png`, replacing the P0 saw-tooth top edge. The old broad roof still shows fine contour/moire patterns; this is not a claim that every world shadow defect is fixed. No light energy/colour or sky changes.
- `tools/blender/hero_gull.py` -> `game/assets/models/hero_gull_parts.glb`: round egg body/chest, oversized soft head, dark eyes with cream catchlights and brows, cheek mass, butter hooked beak/coral dot/nostrils, three wing groups per side, five rounded primary feathers per hand, five tail feathers, coral legs and webbed feet. Static-group AO and vertical/lilac gradient are baked into RGB.
- `_build_authored()` in `gull_visual.gd`, supported by `game/scripts/art/gull_parts.gd`, binds named meshes at zero offsets under the existing pivots. Invalid/missing assets use the original procedural code. Player, friends/rivals and 2.3x brother share the asset. UV.x carries a CPU-only tint-region number; existing material colour properties still drive growth/pale tints. Variants are cached, no per-frame mesh update. The original pose/comet/wardrobe/trail functions and procedural build body are byte-identical to the snapshot. Body growth scale and the actual BeakSocket are retained. Base asset has one material; unchanged accessories/particles retain their old materials.
- Supporting tools: `palette_card.py`, `p1a_sheets.py`, `run_p1a.ps1`; dev-only `p1a_review.gd`, `p1a_contract.gd`, and small opt-in dispatch/output routing in `autotest.gd`. `common.py` gains optional UV export and review framing. Existing production files changed only: gull visual, shader, visual sun bias; the fourth existing changed file is the opt-in test harness. `source_audit.json` records this. `gull_player.gd`, people, gameplay, tuning, text, audio, project settings and saves code are unchanged.

## Numbers

| Base gull, excluding old accessories/particles | Procedural | Authored |
|---|---:|---:|
| Triangles, all parts | 1,464 | 3,884 / 4,000 limit |
| Mesh parts / surfaces | 22 | 11 / 12 limit |
| Used materials | 16 | 1 |
| Visible main-pass parts, flight / feet out | 18 / 22 | 10 / 11 |
| GLB | none | 119,104 bytes; 2,032 imported vertices |

Full frozen island, same-session same-pose camera pairs after the four flora MultiMeshes exist; 30 samples per state, desktop Compatibility, 512x288, capped 30 fps, governor **0**, 3D scale **1**. All other gulls already use the new asset in both halves, so this isolates replacement of the player base gull. Draw totals include island/shadows and the unchanged fry in the snatch view.

| View at 3 m | Draws before -> after | Median frame ms | Render CPU ms | Render GPU ms |
|---|---:|---:|---:|---:|
| side | 956 -> 940 | 33.158 -> 33.218 | 3.212 -> 3.344 | 0.981 -> 1.009 |
| chase | 1216 -> 1200 | 33.289 -> 33.236 | 3.757 -> 3.648 | 1.244 -> 1.252 |
| flare | 993 -> 971 | 33.346 -> 33.212 | 3.196 -> 3.215 | 0.839 -> 0.876 |
| perch | 1303 -> 1281 | 33.424 -> 33.439 | 4.106 -> 4.290 | 1.761 -> 1.784 |
| snatch | 1055 -> 1039 | 33.348 -> 33.205 | 3.254 -> 3.509 | 0.977 -> 1.009 |
| portrait | 1589 -> 1567 | 33.237 -> 33.102 | 4.742 -> 4.651 | 1.927 -> 1.963 |

Every paired view removes 16 or 22 draws; no added pass/texture or expensive shader loop. Median capped frame intervals remain approximately 33.2 ms. GPU changes are +0.008 to +0.037 ms (0.6-4.4%). CPU samples vary: the snatch row is +0.255 ms / 7.8%, the largest increase; other rows range from improvements to +4.5%. This small one-session sample does not prove an uncapped speed improvement or explain that CPU outlier. It is disclosed, not used to override the user's draw/triangle/shader-cost gate. No repeated performance loop or web export.

Capture run: island synchronous build **704 ms**, first review callback **2,902 ms since engine start**, flora complete **11.3 s**. Full regression build **673 ms**. These are not browser first-frame results. Engine **Godot 4.7.1 stable** (documented project deviation from old AGENTS 4.6.3), Blender **5.2.1 LTS**, NVIDIA RTX 5070 Ti Laptop.

## What was seen / limits

Every generated PNG was opened: **141**, all <=512 px; inventory and hashes in `art_src/p1a/viewed_images.json`. Blender uses 384 px, EEVEE 8 samples, four threads. Review sheets are compositions of existing PNGs. Main handoff: `art_src/p1a/before_after.png`; palette, three mood sheets, pose sheet, 128 px silhouettes, distances, actual VN portraits and historical-camera comparison are beside it.

Four internal art iterations were used. Initial palette card was obstructed and low bias exposed roof stripes; iteration 2 corrected the card/bias and built the first gull. The first gull had disconnected-looking wing pebbles, a hidden beak dot and feather ends below its feet in the old ground pose. Iterations 3/4 corrected placement, rounded caps and silhouette sampling without changing animation angles. Blender's opaque exporter discarded alpha-based tint labels; final metadata uses exported UVs, validated before runtime attachment. No fifth modelling/render iteration.

Capture harness failures were repaired without changing the asset: the fry collection is a Dictionary (setup failure retained in `cams_i4_setup_error.log`); a frozen VN camera needed interpolation reset (`vn_noon.png` is the bad frame, `vn_noon_fixed.png` is the corrected one). Initial 60 m roof cameras hit intervening buildings; six `*_60m_clear.png` supplements use higher clear sightlines at the same distance. These are preserved alongside the original frames. Historical `shots/cam_b1a.png` has its original comic UI and pose; `historical_comparison.png` matches camera and spawn but is not a controlled performance pair.

Observed remaining defects:

- Shoulder and forearm masses still look like joined soft plates; the untouched ground fold makes a low cupped wing shape. The charcoal feather tips and curved outline read in flight; the 128 px silhouette has clear up/level/flare/perched poses.
- The breast's violet shadow is strong, and the gull stays relatively bright at dusk. Palette stability is improved, but final shadow saturation is a taste decision still open to the director.
- The close VN portrait reveals polygon edges on cheek/brow shapes; eyes use painted cream catchlights, not an additional glossy material. Existing glasses/hat/coat remain attached but are not newly tailored.
- At 15 m the bird reads; at 60 m / 512 px it is only a few pixels and separate feathers disappear. Grounded silhouettes are especially weak against the roof. Distant art readability is **limited, not approved**.
- Fine moire on old broad roof planes remains. Existing snatch cinematic framing crops the very large fry/gull (`autotest/a_cine.png`); no camera/gameplay reframing was attempted.

## Validation / reproduction

One full `--autotest` run, exit 0: tutorials, seven silver specials, **24/24**, rainbow grab, ordinary fry and **`ended=true phase=3`**. Final stats stolen 25, perfect 4, walls 0, missed 0, rainbow 1. Endpoints agree with baseline; incidental bot counts are not identical. All 10 regression PNGs were opened. No second full suite. Existing shutdown RID/resource warnings remain; final camera/contract/regression logs have no script or shader errors.

The small contract probe confirms GLB names/UV/colour, missing and invalid fallback, tint/reset, shared material and identical animated shoulder/elbow/head/socket transforms. Runtime captures also exercise growth colour channels, pale tint, accessories and brother. The base asset stays within budgets. Visual approval remains with Claude; no P1b work begins.

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --threads 4 --python tools/blender/hero_gull.py -- --iteration 4
powershell -NoProfile -File tools/blender/run_p1a.ps1 -Mode Import -Iteration 4
powershell -NoProfile -File tools/blender/run_p1a.ps1 -Mode Contract -Iteration 4
powershell -NoProfile -File tools/blender/run_p1a.ps1 -Mode Cams -Iteration 4
# Targeted capture-only fixes / historical view, no asset changes:
powershell -NoProfile -File tools/blender/run_p1a.ps1 -Mode Details -Iteration 4
python tools/blender/p1a_sheets.py
# Already completed ONCE; not needed for further image inspection:
# powershell -NoProfile -File tools/blender/run_p1a.ps1 -Mode Autotest -Iteration 4
```

Launcher redirects APPDATA/LOCALAPPDATA to `art_src/p1a/runtime` before engine start, restores them on exit, caps native runs at 30 fps and uses Dummy audio. No real save access, downloads, dependency installs, web export, or work outside the authorised project directories. No Git repository/checkpoint available.

---

## Historical P0 delivery (approval status superseded above)


**P0 only. STOP; no P1 authoring or production visual replacement.** Pipeline proof is delivered; the look and strict performance non-regression gate are not approved. See `ART_MANIFEST.md` for exact gull/human pivots and all attachment/recolouring contracts.

## Built

`tools/blender/common.py`, `p0_cube.py`: clean scene, applied bevel/smooth weighted normals, finite-distance cosine-hemisphere BVH AO into vertex colour, vertical gradient, selected +Y-up GLB export, EEVEE 4-angle + top review and contact sheet. No Cycles bake, textures, external package install, MCP bridge or asset download. One scene generator succeeded after a pre-render fix: this Blender install localizes the default BSDF node name, so the helper now creates/type-selects shader nodes explicitly. The failed run produced no renders; both logs are retained.

`game/scripts/art/art_loader.gd`, `game/shaders/soft_toon.gdshader`: optional GLB loading, colour presence checks, `null` fallback, one shared opaque material, four soft bands, violet/gold tint terms and subtle rim without another draw pass. No frame callback and no outline. Only the opt-in `--cams --art-p0 --art-review` path uses the test GLB. `hero_gull.glb` has not been created; no actor or world builder was replaced.

`p0_review.gd`, `art_src/p0/cams.json`, `run_p0.ps1`, `review_sheets.py`: isolated captures/metrics at 3, 15, 60 m; paired primitive-flat / GLB-toon shots; same-mesh white-vertex ablation; governor level 3 check; in-project logs and disposable user data. `autotest.gd` changed only to route opt-in review outputs, constrain capture size and dispatch this camera check. All other existing game source files are byte-identical to the pre-work hashes in `art_src/p0/source_hashes_before.json`; verification is in `art_src/p0/verification.json`. Gameplay/tuning/text/audio/save code is unchanged.

## Run it

From the project root, using existing installations:

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --threads 4 --python-exit-code 1 --python tools/blender/p0_cube.py
powershell -NoProfile -ExecutionPolicy Bypass -File tools/blender/run_p0.ps1 Import
powershell -NoProfile -ExecutionPolicy Bypass -File tools/blender/run_p0.ps1 Cams
python tools/blender/review_sheets.py
# Full regression was requested and run once; do not repeat for art tweaking:
powershell -NoProfile -ExecutionPolicy Bypass -File tools/blender/run_p0.ps1 Autotest
```

Launcher modes are explicit; there is no automatic batch of repeated renders/tests. Blender writes five 384 px / 8-sample EEVEE views, one 510×340 sheet, using four CPU threads. Godot captures are 512×288, capped at 30 fps, Dummy audio. The composite sheets are no larger than 512 px. APPDATA and LOCALAPPDATA are redirected before Godot starts to `art_src/p0/runtime/` and restored when it exits. No real user save is read/written. There was no Git repository, so no checkpoint commit was possible. No web export was performed.

## Measured evidence

Installed Blender **5.2.1 LTS** successfully ran the user's exact version command first. Existing Godot is **4.7.1 stable**, Compatibility/OpenGL 3.3, NVIDIA RTX 5070 Ti Laptop; this matches the current project's documented engine deviation, not the older 4.6.3 instruction. Browser runtime was not tested.

GLB: **188 triangles**, **96 imported vertices**, **46 distinct imported colours**, **1 mesh / 1 surface / 1 used shared material**, **5,660 bytes**, **1×1×1 m**, base-centre pivot. Blender bake: 32 deterministic hemisphere samples/corner, radius .4 m, measured occlusion range 0–1 (mean .30859), 384 colour corners before GLB vertex deduplication. Exported GLB contains `COLOR_0`; there are no image textures/cameras/lights/animation/collision. The same imported mesh becomes visibly white when its vertex colours are replaced with white; the unchanged shader/geometry makes this a useful colour-path ablation.

Final same-process comparisons, after all four existing flora MultiMeshes finish, frozen island, identical camera/light/object location per pair; **30 samples per row**, 30 fps cap, native window 512×288, governor **0**, 3D scale **1**. Draw calls include the existing island and its shadows, not just the cube.

| Camera | Draw calls before → after | Median frame interval ms before → after | Render CPU ms before → after | Render GPU ms before → after |
|---|---:|---:|---:|---:|
| 3 m | 1,082 → 1,082 | 33.373 → 33.323 | 2.128 → 2.071 | .392 → .394 |
| 15 m | 1,729 → 1,729 | 33.284 → 33.349 | 3.032 → 3.197 | .426 → .427 |
| 60 m | 3,518 → 3,518 | 33.602 → 33.212 | 10.220 → 11.083 | 2.985 → 3.172 |

At governor **3**, scale **.6**, shadows off: 365 draw calls, median interval 33.289 ms, render CPU 3.139 ms, GPU .679 ms (close view). The shader still renders with vertex colours. This is the actual existing governor, not a separate simulated shader switch.

Island synchronous build: **700 ms** in the final camera run; first review frame observed at **3,065 ms since engine start** (includes engine initialization/build, not a clean GPU first-frame measurement). Flora finished at **6.9 s**. The first, discarded camera run built in 691 ms, and flora did not finish until 10.1 s; its 15 m draw count changed during sampling. That invalid comparison is preserved under `game_initial/`, `cams_initial.log`. The corrected run waited on the actual four MultiMeshes and used exact camera distances. No further camera rerender loop was run.

**Performance gate remains open.** Draw counts are equal, but some measured CPU/GPU timings are higher, notably the 60 m row. Thirty capped frames cannot establish the cause or a strict non-regression result. Do not present these as a speed improvement or browser validation. The opt-in fixture/loader/shader remain absent from the normal game path, so there is no production visual change to roll back; under the brief's rule, do not proceed to P1 on this evidence. The ordinary start/ending close-up viewports were not changed and do not load this fixture.

## What was actually seen

Opened every Blender review PNG, both sets of P0 game captures, and all three final composite sheets. Also opened existing `shots/cl_t19_gull.png` for context. The fixture has a rounded outline and visible peach/sage shading; the normal scene remains procedural. Blender's side shading is muddy, bevel shading slightly uneven and ground shadows noisy at eight samples. In Godot, the warm colours wash toward white/cyan under the existing noon sky; shadow tint is weaker than the brief's intended warm-violet look. Small saw-tooth self-shadow artifacts remain on the top bevel (similar artifacts exist in the original roof/gull reference). At 15 m it remains a small block; at 60 m only its presence is legible. The governor-3 image is blurrier but has no missing material. This does **not** approve silhouettes, character joints, grain, animation or distant art readability for later assets.

Review PNGs:

- `art_src/p0/review/contact_sheet.png` (individual views in the same directory).
- `art_src/p0/game/before_after.png`; full detail `close_before.png`, `close_after.png`.
- `art_src/p0/game/distance_sheet.png` (all three distances).
- `art_src/p0/game/diagnostics.png` (vertex-colour ablation + governor 3).

## Validation status / existing warnings

- Blender export and Godot import succeed. Runtime assertions confirm colour variation survived, imported AABB/pivot/scale are correct, two instances share a material, missing asset returns `null`, and the governor-3 scene renders.
- There were **no shader compile or GDScript runtime errors during P0 capture**. Godot prints resource/RID leaks at shutdown (CanvasItem, materials, textures, shaders, PagedAllocator and ObjectDB). Comparable warnings exist in the untouched `shots/reg_world.err.txt` and prior `reg_autotest` logs. This is evidence of pre-existing warnings, not proof that every current leak is identical or harmless; not repaired in an art-only phase.
- Full `--autotest`: **one run completed**, exit 0, roughly 4.5 minutes at 30 fps. All three tutorial fries, all seven silver specials, **24/24**, rainbow grab, plain fry (`hud_state=eat`) and **`ended=true phase=3`** were observed. `SPECIAL_ORANGE` required the bot's existing second attempt after grabbing MISCHIEF on its first route; no test action or gameplay tuning was altered to force a pass. Final stats: stolen 25, perfect 2, walls 4, missed 0, rainbow 1. Prior `shots/reg_autotest.txt` also reaches 24/24 and `ended=true`, but perfect/wall/side-event counts differ; this is endpoint agreement, **not identical deterministic gameplay results**. The console's old `want ~19` boost label still prints although current round-3 base boost is 15; actual boost in this run was 15.0. No broad test rerun was performed.
- Opened all **10 regression PNGs** in `art_src/p0/autotest/`. They show the procedural gull, Gull Sight unlock, 24/24 HUD, rainbow result and the `FRY / Tastes good.` ending card. At the imposed 512 px review size, small HUD text is difficult to read; the existing snatch close-up crops parts of the gull/fry and the sunset is very saturated. Those pictures validate that captures/flow exist, not final human experience or art quality. The P0 cube does not appear in this normal-flow run. All 35 PNG artifacts from this session are <=512 px on both axes and were opened; `art_src/p0/viewed_images.json` inventories their hashes.
- Shader API references consulted (no downloaded assets/dependencies): [Godot spatial shader reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html), [Godot glTF importer](https://github.com/godotengine/godot/blob/master/modules/gltf/gltf_document.cpp), [Compatibility shader source](https://github.com/godotengine/godot/blob/master/drivers/gles3/shaders/scene.glsl). Actual installed-engine compilation and captures are the runtime evidence; `master` source is supporting context only.

P0 review STOP is in effect. P1/P2 have not started. Do not interpret a successful import or `ART_P0 PASS` line as art-director approval or a passed performance gate.
