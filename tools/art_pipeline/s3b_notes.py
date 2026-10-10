"""Final S3b handoff, generated only after the one full regression has ended."""
from pathlib import Path
import json,re,hashlib,shutil
import numpy as np
from PIL import Image
R=Path(__file__).resolve().parents[2];S=R/'art_src/s3b'
a=json.loads((S/'final_review/audit.json').read_text());m=json.loads((S/'final_review/colour_measurements.json').read_text())['regions']
scope=json.loads((S/'source_scope.json').read_text());contract=json.loads((S/'contract.json').read_text())
log=(S/'final_Autotest.log').read_text(encoding='utf-8-sig')
assert 'ended=true phase=3' in log,'Regression has not reached the ordinary-fry ending'
assert 'total=24/24' in log,'24/24 not verified'
end=next(x for x in log.splitlines() if 'ended=true phase=3' in x)
white={}
for tm in ['noon','golden','dusk']:
    white[tm]={}
    for phase in ['baseline','final']:
        ar=np.asarray(Image.open(S/phase/f'gull_{tm}.png').convert('RGB').crop((475,155,550,188)),dtype=float)/255
        mx=ar.max(2);mn=ar.min(2)
        white[tm][phase]={'median_rgb_255':np.median(ar.reshape(-1,3),axis=0).tolist(),'saturation_mean':float(((mx-mn)/np.maximum(mx,1e-8)).mean()),'luma_median_255':float(np.median(ar@np.array([.2126,.7152,.0722]))*255)}
        white[tm][phase]['median_rgb_255']=[round(v*255,1) for v in white[tm][phase]['median_rgb_255']]
(S/'gull_white_guard.json').write_text(json.dumps({'roi':[475,155,550,188],'method':'Fixed forehead rectangle, all pixels, no threshold or mask','times':white},indent=2))
ct='| Fixed visible-surface ROI | Mean S: S3 → S3b / cover | Luma std: S3 → S3b / cover | S / std error vs cover |\n|---|---:|---:|---:|\n'
for k,v in m.items():
    b,c,r=v['before'],v['after'],v['cover'];e=v['relative_error_after']
    ct+=f"| {k} | {b['saturation_mean']:.3f} → {c['saturation_mean']:.3f} / {r['saturation_mean']:.3f} | {b['luma_std']:.3f} → {c['luma_std']:.3f} / {r['luma_std']:.3f} | {e['saturation_mean']:+.1%} / {e['luma_std']:+.1%} |\n"
pt='| View / time / governor | Draws S3 → S3b | Rendered tris S3 → S3b | Render CPU ms S3 → S3b | Render GPU ms S3 → S3b |\n|---|---:|---:|---:|---:|\n'
for p in a['pairs']:
    b,c=p['s3'],p['after']
    pt+=f"| {p['view']} / {p['time']} / {p['governor']} | {b['draw_calls']:,.0f} → {c['draw_calls']:,.0f} | {b['triangles']:,.0f} → {c['triangles']:,.0f} | {b['render_cpu_ms']:.3f} → {c['render_cpu_ms']:.3f} | {b['render_gpu_ms']:.3f} → {c['render_gpu_ms']:.3f} |\n"
intro='''# S3b richness pass — second S3 review submission; STOP

2026-10-11. Review 11 addressed in order, **round 2 of maximum 3 for S3**. Three internal tuning passes in this session (`pass1`, `pass2`, `final`), now stopped. **Not art-approved; the full cover-matching gate remains open.** Reference viewed first: `art_src/reference/cover.jpg`, then the S3 summary. All comparison sheets use the original S3 cover crops and actual fixed-camera game captures, without retouching.

## Changes against Review 11

1. **Palette and light:** stronger shared pigment response, deeper blue-violet shadow fill, less middle-distance fog. Grass/foliage move toward olive; paving becomes warm grey-beige; wood gains a golden brown lit face. The gull material retains its separate white response. Sky, progress clock, sun target, saturation/ending/Gull Sense overrides are unchanged. No extra lights or texture samplers.
2. **Headland:** replace nine attached S3 crags (1,224 source tris) with a **144-triangle** continuous, flat-faceted warm brown-grey rock skirt, cool shaded facets, irregular strata and a grass edge. This is non-solid visual dressing over the original height field. The terrain shader hides only the covered slope when the kit-backed skirt is present; it defaults to the complete original ground if the kit is absent. Original terrain vertices, normals, colours, collision and plateau positions remain identical. Three red lighthouse bands now extend outside the white core (two old bands were hidden inside it). Existing small house repainted cream/red, pine palette darkened. **Three existing gameplay turbines remain:** removing/scaling them to the cover's two small turbines would mismatch existing solids/anchors. The distant decorative island still has its original two turbines.
3. **Houses:** repaint only `COLOR_0` in **22 existing GLBs**: terracotta/coral roofs, cream/peach/butter/sage walls. `s3b_palette.py` preserves all other bytes, including positions, normals, indices, UVs and dimensions; no new house family or fantasy-town import. Shared golden-hour/dusk window emission is stronger.
4. **Cafe:** two extra non-solid striped canopies over existing tables, twelve extra festoon bulbs and three round railing globes. Existing planters, menu, tableware, people and fry targets stay at their original positions. Existing window material warms the shopfront. Everything joins the existing district/light batches; no per-object process or OmniLight.
5. **Water:** deeper blue-teal base, warmer orange glitter and gentler filtered ripple contrast. S3's analytic shore/post foam remains soft; no reflection pass, SSR, scene textures or geometry increase. Glitter still turns off with governor ≥2. Fixed pier camera faces away from the sun, so it cannot show the cover's sun-facing reflection path; this mismatch is reported, not hidden by changing the camera/light.

## Measurements against the cover

`final_review/material_crops.png` and `colour_measurements.json` contain all numbers and exact rectangles. HSV mean saturation and standard deviation of display-referred Rec.709 luma, both on 0–1 RGB. Rectangles are frozen across all passes; no per-result masks, grading or selected-pixel thresholds. They exclude the sky but include both lit surfaces and shadows/props. **These are screen-region proxies, not matched geometry or an isolated N·L lit-pixel test.** Composition differs; the town cover crop includes part of a wing, and the water cover crop includes strong glitter. Therefore a ±15% region result is not proof of matching individual materials or lighting.

'''
tail='''
Town and cafe ROIs meet both approximate ±15% comparisons; cafe saturation is near the lower boundary. Wood, paving and headland contrast still fail; water also fails saturation. No blanket colour/contrast pass is claimed. The forehead guard stays near-white at noon/golden/dusk (see `gull_white_guard.json`); the same white feather/head pixels remain visually clean, with pale cool wings. The head/wing lighting is still much flatter than the cover's rim light.

## Performance and contracts

Native Godot **4.7.1**, Compatibility, 960×540, 30 samples per view, 30-fps cap. Same S3 coordinates/FOV and golden/dusk keys, cafe 3/15/60 m, beach/headland, governor 0 and forced 2. Fresh pre-edit capture reproduces S3 draw/triangle counts. All **17/17** final rows have lower draws and rendered tris than both S3 and the fresh baseline. The monitor counts render passes, not unique asset triangles.

'''
build=a['build_ms'];auto_build=int(re.search(r'island was built in (\d+) ms',log)[1])
finish=f'''
Matched build: **S3 {build['s3']} ms → S3b {build['after']} ms**; fresh S3b pre-edit run {build['before']} ms, pass 1 1057 ms, pass 2 946 ms. Separate autotest startup {auto_build} ms. This is measured evidence, not a universal startup or browser speed guarantee. Frame caps hide throughput; absolute CPU/GPU samples above still vary.

Cost savings: six-segment/three-ring sphere bulbs within the existing lamp batch; non-shadow-casting emissive lamp/window meshes (zero illumination contribution from their old shadow passes); fewer headland triangles. Exact static terrain arrays are cached in `game/assets/models/terrain_s3b.res` (**193,536 bytes**) to avoid rebuilding them at startup. `Terrain.build_mesh()` retains its entire procedural fallback. Cache regeneration must accompany future H/grid/colour changes; the cache is not self-invalidating. `s3b_bake_terrain.gd` rebuilds this delivery from the immutable S3b source snapshot.

Final focused contract: **all 15 CC0 assets pass**, one shared surface/material, budget/normal/size checks, missing/disabled kit checks, canopy 48 triangles; cached vs procedural terrain vertex/colour/normal arrays equal. Fixed-camera physics hash: **1498 → 1498**, all recorded shape data/local transforms equal; all anchors equal. Source audit confirms only the non-solid lighthouse paint rings changed in `world_builder.gd`; all other world-building functions and gameplay/player/NPC/fry/story/audio/save/project files are identical. House non-colour bytes are identical. See `source_scope.json` and `source_diff.patch`. These are not a human collision/playfeel review of the decorative cliff face, which approximates the unchanged solid slope.

One full `--autotest`, on final art: **24/24**, rainbow obtained, ordinary-fry ending. Exact endpoint:

`{end}`

The first SPECIAL_ORANGE attempt locked MISCHIEF and reported missed after a long approach; the second attempt succeeded. This was not a timeout. The entire run took about 260 game seconds. No gameplay adjustment was used to make it pass. Native shutdown resource/RID leak warnings and nonzero capture wrapper exits remain inherited; **not a clean-shutdown claim**. Final camera/contract logs have no script/shader runtime errors. Test windows assert NO_FOCUS and uncaptured mouse; no desktop input was automated. Runtime APPDATA/LOCALAPPDATA/TEMP stay inside `art_src/s3b/runtime`, Dummy audio, one game run at a time.

## Visual review and remaining defects

Viewed every capture through the labelled source pages, all comparison sheets, and the full-size cafe/headland/roof/gull key shots. The warm red roof/cream wall separation now survives distance, paving no longer reads pink-lilac, cafe umbrellas/light strings read as a place, and the headland shows red/white stripes and shaded rock facets. The white gull remains separate from the richer background.

**Still below the cover:** the headland is a conspicuous broad polygonal truncated mound with large facets and some regular tiering, rather than naturally broken cliffs; its symmetric layout and oversized turbines remain. Water has repetitive wave bands, weak reflected detail and no scene/boat reflections; the fixed pier view lacks the cover's bright sun path. Window glow is visible but does not cast local light on the plaza; wall/back facades and cafe furniture are still plain. Vegetation remains toy-like with some overly bright greens; broad hard shadows and sparse harbour detail remain. Paving/wood contrast is under target. The covered rock face is visual-only and has not been manually flown against at every point.

Review entry: `art_src/s3b/review/summary_before_after_cover.png`; dedicated roof/pier/town/flight, cafe distance, ground and gull sheets alongside `material_crops.png`. Raw final images: `art_src/s3b/final/`. First-pass brown banded "cake" and pass-2 too-grey facets are retained, not silently overwritten. `viewed_images.json` records reviewed image hashes. No downloads, MCP, desktop automation, web export, build publishing, gameplay tuning, or Git commit (workspace has no Git repository). **STOP S3b; await the next art review, do not start S4 or another tuning pass.**

Reproduce captures: `powershell -NoProfile -File tools/art_pipeline/run_s3b.ps1 -Label <new-label> -Mode Cams`. Contract: same runner `-Mode Contract`. Repaint: `python -I tools/art_pipeline/s3b_palette.py`, then runner `-Mode Import`. Terrain bake uses the runner's isolated environment with `--headless --script res://scripts/art/s3b_bake_terrain.gd -- --art-s3b`. Measurement/sheets: `python -I tools/art_pipeline/s3b_evidence.py <label>`. One full regression only per final phase; do not loop it for art tuning.

<!-- END S3B HANDOFF -->

---

'''
def prepend(path,text):
    p=R/path;old=p.read_text(encoding='utf-8')
    if old.startswith('# S3b'):
        old=old.split('<!-- END S3B HANDOFF -->',1)[1].lstrip().removeprefix('---').lstrip()
    p.write_text(text+old,encoding='utf-8')
prepend('docs/36_ROUND14_CHANGES.md',intro+ct+tail+pt+finish)
manifest=f'''# S3b art manifest — round 2/3, STOP for review

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

Cafe 3/15/60 m draw calls **1539 → 1535 / 1917 → 1914 / 2497 → 2493**. All 17 final rows reduce draws/tris. S3 build **978 → 846 ms** (fresh pre-edit 1063 ms; separate final autotest {auto_build} ms). Native capped timing is not browser throughput proof; existing shutdown leak warnings persist.

Colour ROI means/stds: town **S .240 → .463 (cover .426), std .138 → .165 (.177)**; cafe **S .301 → .400 (.469), std .182 → .177 (.195)**. These two mixed lit/shadow screen crops lie within approximately 15%; wood, paving, headland and water do not all pass. Fixed crop definitions and every result, including failures, are in `colour_measurements.json`. Gull forehead remains near-white at all three times.

Honest defects: large regular cliff facets and symmetrical mound, three tall original turbines, repetitive water bands/no scene reflections, weak pier-view glitter because camera faces away from sun, simple unlit wall backs/furniture, hard shadows, mixed overly green foliage. Cafe lights are emissive visual accents, not plaza illumination. The colour comparison is a screen-region proxy rather than isolated, geometrically matched lit pixels. **STOP; no S4.**

<!-- END S3B HANDOFF -->

---

'''
prepend('docs/ART_MANIFEST.md',manifest)
third=R/'art_src/third_party/ASSET_MANIFEST.md';t=third.read_text(encoding='utf-8')
if 'S3b reuse note' not in t:
    t='''# S3b reuse note (2026-10-11)

No additional third-party files imported or downloaded. All 15 derived S3 kit GLBs and their source licences/hashes remain unchanged. S3b replaces the nine visible `crag.glb` placements with a project-authored 144-triangle decorative rock skirt; `crag.glb` is retained as an unused catalogue asset. Existing houses are project-authored assets with COLOR_0 repaint only, not fantasy-town-kit derivatives. The table below describes the historical S3 placements; only the crag placement count changes to zero in S3b.

---

'''+t
    third.write_text(t,encoding='utf-8')
state=R/'docs/ART_STATE.md';t=state.read_text(encoding='utf-8')
entry='- 2026-10-11 S3b submitted and STOPPED (second S3 review round, three internal passes). Final `art_src/s3b/final/`, sheets `art_src/s3b/review/`; 17/17 draws/tris lower, S3 build 978 -> 846 ms, 1498 shape hashes/anchors identical, exact terrain cache + fallback, 22 colour-only house GLBs, one final 24/24-to-ending run. NOT art-approved: town/cafe screen metrics near cover, other contrast/water targets and natural cliff shape remain open. No S4/export. See top of ART_MANIFEST and 36_ROUND14_CHANGES.\n'
if entry not in t:state.write_text(t.rstrip()+'\n'+entry,encoding='utf-8')
shutil.copytree(S/'final_review',S/'review',dirs_exist_ok=True)
print('Wrote S3b handoff; full regression endpoint verified')
