# 44 — Final art delivery (S4)

2026-10-11. S7 was approved in **ART_REVIEW Review 15**. This delivery packages that state; it does not open another art iteration. Everything is local to this project. No download, desktop input automation, Git push, release upload or publication was performed.

## Delivered files

- **ORIGINAL / FINAL / COVER:** [sheet 1](../art_src/final/original_vs_final_01.jpg), [sheet 2](../art_src/final/original_vs_final_02.jpg), [sheet 3](../art_src/final/original_vs_final_03.jpg), [sheet 4](../art_src/final/original_vs_final_04.jpg). Each is 1920 pixels wide. There are **15 matched views per version**, including the requested roof, cafe 3 m / 15 m, market, beach, marina, cranes, stairs, headland, sea flight, gull with fry, VN portrait and table fry, plus farm and pier.
- **Real game video:** [film/art_remaster_preview.mp4](../film/art_remaster_preview.mp4) — **40.000 s, 1280×720, 30 fps, H.264 + AAC stereo**, 27.41 MB. [Eight extracted PNG frames](../art_src/final/frames/) and [frame sheet](../art_src/final/preview_frames.jpg).
- **Windows:** [build/JustSomeFries.exe](../build/JustSomeFries.exe) and [build/JustSomeFries.pck](../build/JustSomeFries.pck). Keep both together; double-click the EXE.
- **Web:** [web/index.html](../web/index.html), with its neighboring PCK, WASM, JS, worklets and images. This is a local export, **not a published site**; serve the entire directory over HTTP to play.
- Evidence, measurements, reconstruction and local test data: [art_src/final/](../art_src/final/). Safe original review copy: [art_src/_orig_build/](../art_src/_orig_build/).

## What changed across the art round

| Area | Delivered result |
|---|---|
| Gull | Faceted, larger round white head/body, black dot eyes, chunky orange beak, pale wings with dark tips and yellow feet. Authored parts attach beneath the original animation pivots; wearables were refitted. Procedural fallback remains. |
| Lighting | Warm golden sky, cooler shadows, stronger color separation, layered distant ridges, lamp/string-light glow and a restrained sun-glitter path. Compatibility renderer and existing quality governor retained. |
| Ground / town | Brown dirt-like beach replaced by pale sand; warmer cafe paving, golden timber, richer house walls and terracotta roofs, warm windows, striped umbrellas and plants. |
| Kits | Existing cafe tables/chairs/planters, pier crates/barrels/planks, palms, rocks and small boats use adapted local Kenney assets, sharing vertex-color materials and district batches. |
| People | Flat-faceted round heads, dot eyes, thicker limbs and mitten hands. Existing style colors, motions, held-item pivots and all 171 style variants remain. |
| Island fixes | Marina supports, warehouse/barn/church trim, warmer terrace masonry, ivy and crops, less regular distant ridges. Lighthouse headland is now lower and wider, with layered rock, a rubble skirt and shoreline foam. |
| Startup | Exact pre-baked person variants and ground-noise caches avoid repeated synchronous generation. Version/source checks preserve runtime generation fallbacks. |

**Scope distinction:** S4 changed only optional review/movie bot code and delivery tooling/docs. It did not change gameplay, tuning, story text, audio assets/logic or save behavior. The earlier S7 headland exception already changed the local terrain height **24 → 12 m**, with 68 collider origins, five NPC origins and two anchors following their ground; the final game retains that approved state. It would be inaccurate to describe the entire art round as having unchanged world coordinates. See [Round 14 changes](36_ROUND14_CHANGES.md) for this exception and the earlier concurrent audio-manager edit, which S4 did not make or revert.

## Comparison method and what the sheets show

The ORIGINAL copy combines **current assets** with the original `scripts/`, `shaders/`, `scenes/` and `project.godot` from `backup/pre_art_round14`. Original builders do not use the new model pipeline. Its only source instrumentation is a review dispatcher and the no-focus/no-mouse-capture protection missing from the old main script. [Provenance and original hashes](../art_src/final/original_provenance.json) record this. This is a reconstructed comparison, not a claim that every original asset byte was archived before the round.

Both versions use the same [fixed camera coordinates](../art_src/final/cameras.json), `day.t = 0.72`, governor 0, 960×540 native captures, frozen world simulation and matched character-pose setup. The renderer is **Godot 4.7.1 Compatibility**, the only installed version; this is not 4.6.3 certification. Screenshots are unretouched; the sheets resize, letterbox and label only. Cover crops are explicitly reference artwork, not game output or a matched physical camera. The gull holding a fry and VN dialogue box are staged review fixtures using each version's real meshes and production portrait viewport.

All 30 source screenshots were inspected through the comparison sheets, and the corrected detail sheet was inspected again. Initial off-target table framing, cropped wings and a VN backdrop leaking into the main camera were retained in `art_src/final/camera_setup/`; only those three details per version were recaptured. Final table framing shows the actual first tutorial fry. A new umbrella partly crosses the top of that view; it was left visible rather than hidden for a cleaner result.

The sand, richer roofs, cafe furniture, larger gull and low headland are clear differences. The close cafe view also exposes rigid body joints. The marina/harbor and sea views retain simple boats, large empty surfaces and weak reflections. No cover-quality equivalence is claimed.

## Geometry, draws and build time

Source mesh counts are distinct from rendered triangles, which include the whole view and shadow submissions.

| Asset | Delivered triangles / submission detail |
|---|---:|
| Hero gull | **734**, 11 parts, one shared material |
| Person | **665 bare / 1,271 worst active body combination**, eight visible body parts; at most ten with two held props (S5 contract) |
| Example house `house_00.glb` | **612** |
| Example broadleaf `tree_leaf_0.glb` | **500** |
| Kenney palm | **482** |
| Local S7 headland | **480**, one surface / existing shared material |
| S3 kit catalog | **1,898** unique source triangles across 15 files; includes the retained unused crag |
| S6 wheat / leaf crop / ivy | **112 / 82 / 52** |

The gull, example house/tree and headland counts were reread from delivered GLB index accessors in S4. Person combination limits and kit counts come from the retained phase contracts/manifests. No model was regenerated in S4.

Matched S4 world views: **14/14 have fewer draws and rendered triangles**. The fifteenth view is the portrait UI fixture and is not used for world-performance comparison. Selected samples:

| Camera | Draw calls ORIGINAL → FINAL | Rendered triangles ORIGINAL → FINAL |
|---|---:|---:|
| Opening roof | 2,482 → **1,132** | 1,731,966 → **428,909** |
| Cafe 3 m | 2,811 → **1,177** | 1,934,570 → **480,009** |
| Cafe 15 m | 3,524 → **1,506** | 2,188,724 → **634,476** |
| Boardwalk / market | 4,928 → **2,272** | 2,816,418 → **688,429** |
| Harbor cranes | 3,306 → **1,633** | 1,761,170 → **584,452** |
| Headland | 1,146 → **532** | 1,083,778 → **303,115** |
| Table fry | 2,448 → **1,019** | 1,755,838 → **465,451** |

Full measurements: [ORIGINAL](../art_src/final/original/metrics.json), [FINAL](../art_src/final/final/metrics.json). These are native fixed-camera submission counts, **not browser FPS**.

Island builder time in the latest matched S4 detail-capture processes: **635 → 410 ms**. This is one native sample per version, not a median. The packaged Windows smoke run built the island in **469 ms**. Separately, the retained S7 five-process benchmark was **1,022 → 600 ms median** from S6 to S7; its original pre-S6 target was 916 ms. These are different baselines and must not be merged. S7 first actual 3D review-frame submissions were 1,298 → 1,198 draws. [S7 raw audit](../art_src/s7/audit.json) documents OS/driver caches not being flushed, mixed GPU timing and two tiny triangle increases in that phase. No new full performance loop was run for S4.

## Clip and validation

Exactly **one** 720p Movie Maker capture was run with `--write-movie --fixed-fps 30 -- --film --seg=6 --movie-fps=30`. The raw [52.03-second AVI](../film/art_remaster_raw.avi) is retained. The MP4 uses raw seconds **1–41** at original speed: roof takeoff, pier/Ferris wheel, dive, actual rhythm-ring grab, successful escape, fast town flight and the sea approach to the lighthouse. The unused raw ending stays near the lighthouse; it is not looped into the delivered preview.

The bot uses the real flight controller and existing `film_steal`/timing input path. It has visible setup cuts before the dive/snatch approach, town and sea legs; those placements reset stamina as the existing bot does. Golden hour is held for filming. **This is a staged real-game preview, not an uninterrupted manual playthrough.** There are no speed/timing-rule edits, custom render mock-ups, narration or substitute music. The actual log records `TUTORIAL_01`, `ok=true`, `perfect=true`, two notes and `tutorial_done=true`. [Event timeline](../art_src/final/film_events.json), [capture log](../art_src/final/Film.log).

Movie Maker captured PCM game audio, encoded to AAC; the final track is non-silent (mean **−32.0 dB**, peak **−8.4 dB**, measured by ffmpeg). This verifies captured signal, not a listening-quality review. The raw footage was visually sampled at two-second intervals, and all eight full delivery frames were inspected via the frame sheet. The ring frame and successful verdict are visible. Brief Ferris-wheel/cabin occlusion and the tight snatch camera remain in the real footage.

S4 checks: Windows `BUILD.bat`, Web release export, page patch, packaged Windows headless start/quit (exit **0**, no warnings/errors in `Smoke.log`), matching Windows/Web PCK SHA256, valid WASM header, required loader patch, 720p/30 fps/40 s video with audio and exactly eight extracted frames. [Check results](../art_src/final/delivery_checks.json). The packaged smoke run used the EXE and neighboring PCK in `build/`, not the source project. The existing S7 full regression remains **24/24 → rainbow → ended=true phase=3**; S4 did not repeat that full suite. Web was exported and statically checked, **not replayed in a browser** in this session.

## Build sizes

**Decimal MB (1 MB = 1,000,000 bytes), uncompressed local files:**

| Output | Final MB | Increase versus reconstructed pre-art content |
|---|---:|---:|
| Windows EXE | **179.00** | **0.00 MB** (same runtime hash) |
| Windows PCK | **32.26** | **+4.55 MB** |
| Windows EXE + PCK | **211.26** | **+4.55 MB** |
| Web folder total | **72.27** | **+4.55 MB** on the same runtime/wrapper basis |

`BUILD.bat` deliberately delivers the installed Godot runtime plus PCK, not a slim Windows export template. Installed `4.7.1.stable/web_nothreads_release.zip` was used for Web; no template was downloaded. The release was followed by the exact Round 13 command `python tools/web/patch_index.py web/index.html film/poster_new.jpg`.

Baseline honesty: the old on-disk PCK was **27.764012 MB**, but inspection found P0 pipeline assets (`p0_rounded_cube`, palette card, soft-toon and review scripts). It is not a pristine pre-art binary. Against that actual previous delivery, the PCK grows **4.496984 MB**, and Web grows **4.497615 MB**. Its hashes and PCK are retained in `art_src/final/pre_delivery_sizes.json` and `pre_delivery_build/`.

For the requested pre-art comparison, [original_reference.pck](../art_src/final/original_reference.pck) was rebuilt from the **exact backed-up original source**, excluding new `assets/art`, `assets/models` and review-script resources. It is **27.712396 MB**. It uses current non-art assets, so this is a **reconstructed baseline**, not proof of an unavailable historical binary size. The Web reference is the same runtime/wrapper plus this baseline PCK (**67.716502 MB**); it is not a second historical Web export. [Size accounting](../art_src/final/build_sizes.json), [baseline export provenance](../art_src/final/original_size_reference.json).

## Third-party assets and licenses

All used third-party model packs are **Kenney CC0 1.0**. The original local license texts were read again in S4; no online acquisition was needed. Official pages and shipped derivatives:

| Official pack | Used derivatives |
|---|---|
| [Nature Kit](https://kenney.nl/assets/nature-kit) | Cliff faces, rocks (including the S7 rubble skirt), bushes/flowers; wheat, leaf crops and ivy |
| [Pirate Kit](https://kenney.nl/assets/pirate-kit) | Rowboats, barrels, crates, planks and bent palms |
| [Furniture Kit](https://kenney.nl/assets/furniture-kit) | Round tables, chairs and potted plants |
| [Food Kit](https://kenney.nl/assets/food-kit) | Decorative plates and soda cups |

License originals: `art_src/third_party/_quarantine/<pack>/x/License.txt`. Per-file source names, conversion details and hashes: [ASSET_MANIFEST](../art_src/third_party/ASSET_MANIFEST.md), `art_src/s3/kit_catalog.json`, `art_src/s6/assets.json`. Vertex colors/AO and scale were adapted locally. The S3 tall crag remains in the catalog but is unused; S7 now places the existing rock derivative. Fantasy-town-kit, city-kit-suburban and blocky-characters were **not used**. The gull, people, houses, interactive fries and headland geometry are project-authored; the original procedural sailboats remain.

## Remaining defects / limits

- Lighting and sea reflections remain flatter and less rich than the cover. The water lacks convincing reflected buildings, boats and sunset color; broad streaks can be seen.
- Headland rock bands are still mechanically regular, with large planar facets and fine diagonal shading patterns. The decorative skirt is non-solid and can be flown through. The white house is partly hidden, and **three original gameplay turbines remain**, versus two in the cover.
- People have rigid shoulders/legs and stiff poses at 3 m; the table view can make their body parts overlap awkwardly with furniture. Distant figures lose facial detail.
- Boats, cranes/containers, playground and some large facade/ground areas remain primitive or sparse. Some plaster colors are stronger/yellower than the cover, while long views still look relatively flat.
- Gull wing joints/folds remain angular. The filmed snatch close-up is tight and briefly crops the gull/fry; the flight camera briefly meets Ferris-wheel geometry. These were not hidden with art edits or another capture.
- The clip includes bot setup cuts and does not prove manual flight feel. Audio presence is measured; listening quality, a full Windows human playthrough and Web browser performance remain unreviewed here.
- The pre-art size baseline is reconstructed. Native capped captures and older phase contracts do not establish 60 fps on the web or on weaker machines.

## Re-run locally

Run from this project root. The runner redirects APPDATA, LOCALAPPDATA, TEMP and TMP inside `art_src/final/runtime/`; review windows report NO_FOCUS and an uncaptured mouse. It uses in-engine bot input only.

```powershell
# The original copy is already prepared; s4_setup.py refuses to overwrite it.
powershell -NoProfile -ExecutionPolicy Bypass -File tools/art_pipeline/run_s4.ps1 -Mode OriginalCams
powershell -NoProfile -ExecutionPolicy Bypass -File tools/art_pipeline/run_s4.ps1 -Mode FinalCams
python tools/art_pipeline/s4_sheets.py

# Only when a new capture is explicitly wanted (one 720p run):
powershell -NoProfile -ExecutionPolicy Bypass -File tools/art_pipeline/run_s4.ps1 -Mode Film
python tools/film/finish_art_preview.py

powershell -NoProfile -ExecutionPolicy Bypass -File tools/art_pipeline/run_s4.ps1 -Mode Build
powershell -NoProfile -ExecutionPolicy Bypass -File tools/art_pipeline/run_s4.ps1 -Mode Web
python tools/web/patch_index.py web/index.html film/poster_new.jpg
powershell -NoProfile -ExecutionPolicy Bypass -File tools/art_pipeline/run_s4.ps1 -Mode Smoke
```

Camera source: `tools/art_pipeline/s4_review.gd`, copied identically to both review projects. Production optional dispatcher: `autotest.gd --cams --art-s4`. Film source: `game/scripts/art/s4_film.gd`, retained tooling copy `tools/film/art_remaster_segment.gd`. The ffmpeg/ffprobe executables are the existing PATH tools also used by `tools/film/make_promo.py`; encoding is limited to two threads. Re-running rewrites the named S4 output files, so retain this delivery first if another comparison is desired.

## Rollback

For a functional source rollback, copy `backup/pre_art_round14/scripts/`, `shaders/`, `scenes/` and `project.godot` over the corresponding paths in `game/`, then reimport and rebuild Windows/Web. Keep a copy of the final source before doing that. The new model files can remain on disk: original builders use their procedural visuals. This also restores the older 24 m headland and all behavior present in that backup; it is not an art-toggle within the final build. The old backup predates the no-focus test protection: preserve that protection for any future dev runs, or use the already-safe `art_src/_orig_build` for comparisons. This delivery did **not** execute a rollback.

**S4 complete. Stop; no publication or further art work scheduled.**
