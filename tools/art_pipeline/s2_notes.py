"""Prepend final S2 evidence to the two requested project documents."""
from pathlib import Path
import json,re
root=Path.cwd();data=root/'art_src/s2'
a=json.loads((data/'audit.json').read_text());m=json.loads((data/'iteration_4/metrics.json').read_text())
images=json.loads((data/'image_measurements.json').read_text());run=(data/'final_Autotest.log').read_text(encoding='utf8')
assert 'ended=true phase=3' in run and '24/24' in run
def elapsed(label):
    text=(data/(label+'_Cams.log')).read_text(encoding='utf8')
    return re.search(r'the island was built in (\d+) ms',text)[1]
rows=[]
for p in a['pairs']:
    if p['time']!='dusk':continue
    x=p['before'];y=p['after']
    rows.append(f"| {p['view']} | {x['draw_calls']:.0f} → {y['draw_calls']:.0f} | {x['frame_ms']:.3f} → {y['frame_ms']:.3f} | {x['render_cpu_ms']:.3f} → {y['render_cpu_ms']:.3f} | {x['render_gpu_ms']:.3f} → {y['render_gpu_ms']:.3f} |")
table='\n'.join(rows)
notes=f'''# S2 cover atmosphere — four internal art iterations; STOP for review

2026-10-10. **S2 only**, after S1 approval in ART_REVIEW Review 9. The real Godot island now has a four-key colour script, warm/cool lighting, dusk lights, calmer teal water, sun glitter, layered distant land and lighter gull wings. This is an implementation/review submission, **not a claim of matching the cover or art-director approval**. No S3, export or release.

## What changed

- `day_cycle.gd`, `cover_sky.gdshader`, `_environment`: morning / afternoon / golden / dusk keys at t=0/.35/.72/1; lavender-blue ambient/shadows and warm direct light; purple/pink/peach sky with a sun-facing warm horizon. Existing progress clock, movement of t and catchable sun position are unchanged.
- `cover_atmosphere.gd`: existing shared window/lamp materials, thin batched overlays at authored houses' real window coordinates, 36 cafe/pier string bulbs and 24 Ferris bulbs. **204 halo instances in two MultiMeshes**, two new shared spatial materials (halo/haze), one sky material, **zero added OmniLights**, zero per-object processes or textures. The full scene still has one pre-existing OmniLight.
- Native glow is enabled at governor 0–1, with restrained local additive halos. **Correction:** the first RGBA `ImageChops.getbbox()` check returned None because alpha difference was zero, incorrectly suggesting no native bloom. RGB comparisons show it works, consistent with the [official Compatibility glow documentation](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html#glow). Final on/off mean RGB difference is **{images['native_bloom_ab']['iteration_4']['mean_abs_rgb_255']:.4f}/255**. The incorrect disabled-glow captures/composites are retained in `iteration_4_glow_disabled/` and `review_glow_disabled/`; final evidence is `iteration_4/` and `review/`. The fourth iteration included this technical validation correction; there was no fifth art tuning pass.
- `sea.gdshader`: opaque teal/blue palette, analytic coast depth/foam from existing shoreline boundaries, pier foam, pink/lavender horizon reflection and broken directional gold glitter. No screen/depth sampler, SSR or extra water pass. `ground.gdshader` only dims the overbright wet-sand strip. Water collisions/height remain unchanged.
- Giant decorative cone mountains replaced by three merged rounded hill layers with manual atmospheric colour, plus one merged non-solid distant lighthouse/turbine island. Original playable lighthouse, wind turbines, terrain and colliders remain. Clouds use smoother normals on the same cheap geometry and pink/lilac dusk paint; drift/rain/quest placement is unchanged.
- `soft_toon.gdshader`: cool shadow fill, bounded warm directional tint/rim; neutral gull wing paint becomes pale grey-lilac while dark tips/cosmetic colour regions remain. No GLB or pivot changes. Saturation now plateaus at **1.08** (old full-special 1.56); glow cap **.42**, tested full-special **{m['late_glow']:.3f}** (old .75). Gull Sense .35 and ending .96/.30 overrides remain.

## Real-game evidence and performance

Four fixed cameras (opening cafe roof to pier, pier/marina, hillside stairs, flight to the sun) × four time keys, **960×540**, same coordinates/FOV before/after. The baseline is the actual current S1 build captured before S2, not a mixed historical render. Contact sheets include cover crops. Additional rear flight, close gull colour keys, late progress, ending, Gull Sense, native glow A/B and governor 2/3/web-lite branch captures were inspected. All produced images, including rejected/diagnostic ones, are indexed in `viewed_images.json`.

Desktop Godot **4.7.1**, GL Compatibility, RTX 5070 Ti Laptop; **30 samples per row, 30-fps cap, governor 0, 3D scale 1**. Four dusk rows below; all 16 pairs are in `audit.json`.

| Camera / dusk | Draws before → after | Frame interval ms | Render CPU ms | Render GPU ms |
|---|---:|---:|---:|---:|
{table}

Across all 16 pairs, largest median frame-interval change: **+0.09%**, draw changes **-9 to -2**. **The required +10% performance gate remains unverified:** the 30-fps cap hides available throughput. Render CPU rose **5.045 → 7.297 ms (+44.64%)** in the afternoon pier view; GPU rose **0.583 → 1.269 ms (+117.67%)** in the afternoon town view. These are unresolved timing regressions; laptop scheduling is a possible confound, not an established explanation. Lower capped intervals are not a speedup claim. No fifth art iteration or extra benchmark was started. Synchronous build **1824 → 1048 ms**, separate runs, not a controlled startup benchmark. Governor 2/3 and native `GS.web` branch assertions confirm glow, halos, glitter and extra horizon/sun-corona layers off; core colour, sea, light cores and one hill layer remain. Browser itself was **not exported or run**.

## Validation and remaining defects

- Source audit: **69/78** pre-existing script/shader/scene files byte-identical; the nine changed files are enumerated in `audit.json`. All gameplay world functions outside the seven visual/build hooks are identical; `main.gd` differs only by one atmosphere reference. Progress computation, sun quest placement, project settings, gull GLB, model loaders/fallbacks, controllers, audio, story, save code and numbers are unchanged. Scene collider count **1498 → 1498** (count plus source-scope check, not an exhaustive physics replay).
- **One full --autotest:** 24/24, rainbow obtained, ordinary fry and `ended=true phase=3`; ten regression images inspected. It ran immediately before the final native-glow switch correction; that correction received the final camera/governor checks, not a second full suite. Known shutdown RID/resource warnings remain. Final logs contain no GDScript/shader runtime errors. Test capture asserts **NO_FOCUS=true and mouse not captured**; no desktop input automation.
- Seen against the cover: the blue-green sea and small gold reflection marks replace cyan/white glare; warm dusk lamps/windows and pale wings are clearer; giant pyramids are gone. **Still flatter than the cover:** sunlight/rim is weaker, trees/buildings have pale toy colours, shadow edges/roof moire remain, hills are simple smooth silhouettes, cloud masses are sparse and bubble-like, water sparkles remain procedural and there are no full boat/lamp reflections. The existing bright vertical gameplay-effect columns remain visible. The distant island's turbines are static decor.
- The catchable sun is deliberately still 90–125 m high, so it cannot reproduce the cover's low horizon sun without changing the gameplay target. The fixed map/camera composition also differs from the cover's stacked town; no S3 layout/asset work was attempted. Light-core emission/halos are visual accents, not local illumination or bounced light.

Reproduce only when requested: `powershell -NoProfile -File tools/art_pipeline/run_s2.ps1 -Label iteration_4 -Mode Cams`; then `s2_sheets.py iteration_4`, `s2_audit.py iteration_4`, `s2_delivery.py`. Launcher isolates APPDATA/LOCALAPPDATA/TEMP/TMP under `art_src/s2/runtime`, uses Dummy audio and 30 fps. No downloads of assets/dependencies, no new MCP server, no external writes, no web export, no Git repository available. **STOP S2.**

---

'''
manifest=f'''# S2 cover atmosphere manifest — STOP for review

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

**Review entrypoints:** `art_src/s2/review/summary_before_after_cover.png`; four `{{roof,pier,town,flight}}_before_after_cover.png` sheets; `gull_palette_cover.png`; full captures and metrics in `iteration_4/`. `baseline/` holds pre-S2 source/shader/scene copies plus real four-time captures. `iteration_1..3/`, `iteration_4_glow_disabled/`, and `review_glow_disabled/` are retained diagnostic history. Every generated PNG is inspected and hashed in `viewed_images.json`; sheets only resize/label source screenshots, never retouch them.

**Checks:** source-scope audit, unchanged day progression/sun placement, 1498 collider count before/after, governor/lite effect assertions, uncaptured mouse/NO_FOCUS assertions; one 24/24-to-ending regression. The full regression predates the final native-glow enable correction, which received focused final capture validation. Existing shutdown leak warnings remain; no final script/shader errors. APPDATA/LOCALAPPDATA/TEMP isolated inside this project; no external writes/downloaded art/export.

**Honest open defects:** weaker golden key/rim than cover, pale materials and hard shadows/roof moire, simple hill silhouettes, sparse cloud heaps, procedural water pattern without full reflected scenery; old gameplay-effect columns remain. The original high catchable sun and island layout differ from the cover. Distant turbines are static decorative silhouettes. Four art iterations used; **STOP, awaiting director review**.

---

'''
for file,text in [('docs/36_ROUND14_CHANGES.md',notes),('docs/ART_MANIFEST.md',manifest)]:
    p=root/file;old=p.read_text(encoding='utf8')
    if old.startswith('# S2 cover atmosphere'):
        old=old.split('\n---\n\n',1)[1]
    p.write_text(text+old,encoding='utf8')
print('Updated the two requested documents')
