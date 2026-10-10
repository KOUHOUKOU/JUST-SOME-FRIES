from pathlib import Path
import json,re
R=Path(__file__).resolve().parents[2];S=R/'art_src/s7';a=json.loads((S/'audit.json').read_text())
log=(S/'final_Autotest.log').read_text(encoding='utf8')
assert 'ended=true' in log and 'phase=3' in log,'Do not document a completed regression until it finishes'
print('\n'.join(l for l in log.splitlines() if '[AUTOTEST]' in l and any(t in l for t in ['24','ended=','rainbow','PASS','FAIL'])))
table='\n'.join(f"| {r['view']} / {r['governor']} | {int(r['before']['draw_calls'])} → {int(r['after']['draw_calls'])} | {int(r['before']['triangles'])} → {int(r['after']['triangles'])} | {r['before']['render_cpu_ms']:.3f} → {r['after']['render_cpu_ms']:.3f} | {r['before']['render_gpu_ms']:.3f} → {r['after']['render_gpu_ms']:.3f} |" for r in a['camera_rows'])
notes=f'''# S7 — low headland and startup budget; four iterations, STOP

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
{table}

First actual 3D review-frame submission: **1298→1198 draws**, **430632→426419 tris**. The first frame in the short title-startup runs is just the menu (**119 draws / 7102 tris**, unchanged), so it is not reported as the island's render cost. Process-start-to-that-menu-frame medians are **3355→3283 ms**, far less improvement than the isolated builder time: startup and build time are different quantities.

Governor forced 2/3 and native `GS.web=true` policy checks pass: resolution/shadow distances apply, glow/halos/glitter/heavy horizon layers switch off, level 3 shadows off. Existing automatic adjustment intentionally resets its counters while paused or capped at <=30 fps, so these gentle runs do **not** exercise the live 4-low/15-high-second adaptation loop. `perf_governor.gd` itself is unchanged.

## Regression, reproduction, remaining defects

Final `--autotest` completed **24/24**, collected a rainbow fry and reached **`ended=true phase=3`**. Full log: `art_src/s7/final_Autotest.log`; actual screenshots in `art_src/s7/autotest/`. The inherited SPECIAL_ORANGE first approach again targeted MISCHIEF and passed on retry 2; no snatch/controller/tuning edit was made. Contract also passes nine styles × 13 modes × three modifier sets × 45 frames, pivots, anchors, emotes and missing/invalid visual fallbacks. Native inherited shutdown resource/leak messages must not be read as a warning-free export. Early ordinary ending was not separately rerun.

Reproduce only when explicitly needed: `tools/art_pipeline/run_s7.ps1 -Label <new-label> -Mode Cams|Cold|Contract|Autotest`; `-Mode Bake` regenerates person/noise/full-terrain/render-terrain resources, then `-Mode Import` as needed for a regenerated GLB. Blender: `--background --threads 4 --python tools/blender/s7_headland.py`. `s7_setup.py` is a one-time baseline capture and refuses overwrite. `s7_audit.py` writes scope/hash/measurement evidence. `source_diff.patch` records every changed baseline source; all pre-existing GLBs are untouched. Test user data/log/temp paths are isolated in `art_src/s7/runtime/`; every sampled test window reports uncaptured mouse and NO_FOCUS.

**What the pictures show:** sea/west views now read as a low broad island rather than a high cone; rock ledges, pale/cool/warm strata, dark pines and the foam skirt are visible. East close-up still has large planar, mechanically repeated rock bands and visible fine diagonal material/shadow pattern. The small white house is partly hidden behind lighthouse/pines, the inherited **three** tall gameplay turbines remain (**the cover's requested two-turbine composition is not achieved**), the broad non-solid rock apron can be flown through, and the cover's reflected sunset/bounced warmth are still absent. Foam is a simple line, not surf simulation. This is a substantial proportion change and a measured build-time fix, **not a cover-quality approval**. Four art iterations used; **STOP S7**.

---

'''
manifest='''# S7 current headland / startup delivery — STOP after four iterations

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

'''
for path,content in [('docs/36_ROUND14_CHANGES.md',notes),('docs/ART_MANIFEST.md',manifest)]:
 p=R/path;s=p.read_text(encoding='utf8');assert not s.startswith('# S7'), 'Already published S7 notes';p.write_text(content+s,encoding='utf8')
(S/'review/README.md').write_text('''# S7 review — STOP, four art iterations

Start with [three-camera before / final / cover](iteration_4_verified_before_after_cover.jpg) and [all six final images](iteration_4_verified_contact.jpg). Full 960×540 originals: `../iteration_4_verified/game/`. These are real in-game captures, unretouched.

- [Baseline](baseline_contact.jpg), [failed 24m overlay](iteration_1_before_after_cover.jpg), [lowered profile](iteration_2_before_after_cover.jpg), [strata/foam](iteration_3_before_after_cover.jpg), [iteration4](iteration_4_before_after_cover.jpg).
- [Raw measured audit](../audit.json), [contract](../contract.json), [source diff](../source_diff.patch), [final complete autoplay](../final_Autotest.log), [actual ending](../autotest/a08_ending.png).
- Five cold-process median **1022→600 ms**, target<=916 passed. All10 camera draw pairs lower. Two tiny triangle-count increases remain. Native capped4.7.1, not web/4.6.3 verification.
- Full docs: [change log](../../../docs/36_ROUND14_CHANGES.md), [manifest](../../../docs/ART_MANIFEST.md).

The first overlay was rejected by the builder: still a tall regular cake. The user-authorised fallback lowers the headland24→12m; 1498 colliders retained, 68 follow ground, 2 anchors down12, thermals exact. Final24/24/rainbow/ending pass. Geometry still has regular strata; three original solid gameplay turbines remain rather than the cover pair. House partly hidden, sea reflections and warm bounced lighting still weak. Builder review is not director approval. No fifth art iteration, S4, export, download or scheduled work.
''',encoding='utf8')
p=R/'docs/ART_STATE.md';s=p.read_text(encoding='utf8');s=s.replace('## Progress log\n','## Progress log\n- 2026-10-11 S7 submitted and STOPPED after four art iterations. Review14 headland lowered24→12m only after rejected decorative overlay; layered skirt/foam. Native cold-process median1022→600ms (target916), all10 draw pairs lower, exact171-style/noise bake caches,1498 colliders/68 grounded translations/two anchors down12/thermals exact; final24/24→rainbow→ended=true phase=3. Still regular bands, three original turbines, weak reflections. Review `art_src/s7/review/README.md`; details at top of36/ART_MANIFEST. NOT art-approved; no S4/export.\n',1);p.write_text(s,encoding='utf8')
p=R/'TUNING_NOTES.md';s=p.read_text(encoding='utf8');s+='''\n## S7 local headland / build cache (2026-10-11)\n- User-authorised fallback after failed overlay: `Terrain.HEADLAND_HEIGHT=12` (was24), original cap/influence radii and every non-headland H sample retained. Structures,68 collider origins,keeper/fiveNPCs and two anchors follow ground; thermals unchanged. Three original gameplay turbines retained rather than creating invisible solid remnants.\n- Regenerate `game/assets/models/s7/*.res` with `run_s7.ps1 -Mode Bake` after terrain/person-source changes. Person cache verifies source arrays/version; unknown styles/missing resources use the original generator. Cached noise pixels and171 person styles are exact. Terrain render trim is valid only with the optional headland shell; collision uses full terrain.\n- Five native fresh-process build median600ms vs freshS6 1022ms/preS6 target916ms. This is not disk-cold, total-load-time or browser throughput evidence. No web export. S7 STOP after four art iterations; remaining defects and all evidence in docs/36.\n''';p.write_text(s,encoding='utf8')
print('S7 notes, manifest, state, tuning and review index written')
