"""Write the S3 handoff from measured final evidence; preserve previous phase notes."""
from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[2];S=ROOT/'art_src/s3'
a=json.loads((S/'audit.json').read_text(encoding='utf-8'));cat=json.loads((S/'kit_catalog.json').read_text(encoding='utf-8'))
log=(S/'final_Autotest.log').read_text(encoding='utf-8-sig')
assert 'total=24/24' in log and 'ended=true phase=3' in log
assert a['all_draws_nonincreasing'] and a['all_tris_nonincreasing'] and a['physics_shapes_identical'] and not a['contract']['failures']
def n(v):return f'{v:,.0f}'
rows=[]
for p in a['pairs']:
    b=p['before'];c=p['after']
    rows.append(f"| {p['view']} / {p['time']} / {p['governor']} | {n(b['draw_calls'])} → {n(c['draw_calls'])} | {n(b['triangles'])} → {n(c['triangles'])} | {b['render_cpu_ms']:.3f} → {c['render_cpu_ms']:.3f} | {b['render_gpu_ms']:.3f} → {c['render_gpu_ms']:.3f} |")
stats=re.search(r'\[AUTOTEST\] ended=true[^\n]+',log)[0]
entry='''# S3 kit integration and ground — four art iterations; STOP for review

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
'''+ '\n'.join(rows)+f'''

All **17/17** matched rows have fewer draw calls and rendered triangles. Matched-camera build log: **{a['build_ms'][0]} → {a['build_ms'][1]} ms**. This is one pair, not a controlled startup distribution: the separate full-autotest launch was **1521 ms**, and final-stage capture launches ranged 721–978 ms. Do not claim a universal startup speed-up or certified browser budget. Absolute render timings still fluctuate: worst CPU delta +0.225 ms (pier dusk), worst GPU delta +0.295 ms (pier golden). Lower draws/tris do not establish a universal GPU-time win; the capped frame intervals are not throughput proof.

## Verification and provenance

- Final `s3_contract.gd`: all fifteen imported meshes have expected metre bounds, flat nondegenerate triangles, COLOR_0, one surface, shared material and per-asset budgets. Missing/disabled asset checks pass; old vs new terrain vertex/colour/normal arrays are exactly equal. All original 1498 collider shapes/local transforms hash identically, and all anchor values match. Five wrapped procedural bodies compare byte-identically; source scope details are in `source_scope.json`.
- One full `--autotest`: **24/24**, rainbow obtained, ordinary-fry ending; `{stats}`. This verifies the endpoint, not deterministic agreement of all wall/perfect/miss counts or a human playtest. It ran after the final GLB normal fix but before the final canopy index fix; the canopy fix got its 48-triangle contract, final same-camera/physics/anchor verification, and no second full suite.
- Final capture logs contain no script/shader runtime errors. Existing native shutdown RID/resource leak errors remain (including nonzero wrapper status on the full autotest); **not a clean-exit claim**. Final focused contract exits 0. Captures assert NO_FOCUS and uncaptured mouse. Runtime saves/temp/audio driver are isolated to `art_src/s3/runtime`, with Dummy audio.
- **Concurrent edit, not made by S3:** `game/scripts/systems/audio_manager.gd` changed during this session from WAV data-size loop length to duration × mix rate. It was preserved, not reverted or credited to this art task. Exact diff is recorded in `source_scope.json`; audio correctness was not tested. All other non-art/gameplay source/config changes are enumerated in `audit.json`; project settings, controller, story, saves, encounter definitions, numbers and text were not edited by S3.

## What was actually seen against the cover

Sand now reads as warm sand, and the ground no longer dominates as dirty brown noise. Pier boards, striped umbrellas, round tables, chairs and small plants are readable in the real cameras. Normals are now visibly faceted on barrel bands, cup and planks. Roof golden-hour composition retains S2's useful warm mood.

**Still below target:** the headland is still a large smooth mound with a sparse applied-rock treatment, not the cover's convincing layered cliff silhouette; terrace strips remain regular. Water has shallow colour and glitter but lacks boat/building reflections and the cover's crisp sparkling depth. Buildings/people/paving remain paler and flatter than the cover, shadows are hard, generic house backs and lit-window warmth remain weak. Palms have angular ribbon leaves; furniture is still plain; table close-up is partially occluded by original NPCs. The two added rowboats are modest detail, not a rebuilt fleet; retained menu boards, loungers/towels/tiki bar and houses are not upgraded kit families. No full cover-quality or complete spec-content acceptance is claimed.

Rejected records: iteration 1 studded-rock ring and overly regular water; iteration 2 block-wall rings, thick palms and unusable sail adaptation; iteration 3 tall repetitive rock pillars; iteration 4 custom-normal reset failed, then fresh split-mesh export passed; unindexed canopies were absent until the indexed-batch correction. No fifth art tuning pass was started. The final evidence folder is **`iteration_4_verified/`**, not `iteration_4/` or `iteration_4_final/`.

Review: `art_src/s3/review/summary_before_after_cover.png`, four fixed-camera sheets, cafe distance sheet, ground/beach sheet; all source captures and failed iterations retained. `viewed_images.json` inventories inspected images. Reproduction: `run_s3.ps1 -Label <new-label> -Mode Cams`, `-Mode Contract`, importer command in its docstring, then `s3_delivery.py` / `s3_scope.py` / `s3_notes.py` for the current fixed handoff. **STOP S3; awaiting art-director review.**

---

'''
manifest='''# S3 CC0 kit and scenery manifest — STOP for review

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
'''
for k,v in cat.items():manifest+=f"| `{k}.glb` | {v['tris']} | {v['size_m']} |\n"
manifest+=f'''
Cafe 3/15/60 m draw calls **1693→1539 / 2079→1917 / 2661→2497**; all 17 rows reduce draws/tris. Matching-camera build **{a['build_ms'][0]}→{a['build_ms'][1]} ms**; separate autotest startup 1521 ms, so no universal startup/performance claim. Full absolute CPU/GPU and governor 2 table: top of `36_ROUND14_CHANGES.md` and `art_src/s3/audit.json`.

Review entrypoints: `art_src/s3/review/summary_before_after_cover.png`, `cafe_before_after_cover.png`, `ground_before_after_cover.png`, and four named camera sheets. Final Blender models: `kit_review_final_flat/`. Failed variants, including too-ornate `ship-small` and unusable extracted sail, are preserved outside the shipping GLB folder. Existing sailboats, fishing boat, house family, menu boards, loungers, towels, tiki bar and S2 lamp/window system remain; they are not newly authored S3 families. `rock.glb` is a retained pipeline prototype/availability guard, not final visible placements.

Open quality defects: headland is still a smooth mound with attached rock accents; water has no scene reflections; pale building/paving values, hard shadows, sparse cafe decoration, angular palm leaves and plain house backs remain below the cover. Source/geometry checks do not certify artistic acceptance or human experience. The full autotest preceded the last canopy indexing correction; final focused camera/physics/contract checks followed it. Native shutdown leak warnings remain.

One unrelated audio-manager loop-length edit appeared concurrently and was preserved without modification; exact diff is in `art_src/s3/source_scope.json`. S3 made no gameplay/number/text/audio/save edits. No downloads, no desktop input, no export. **STOP for director review.**

---

'''
for path,text in [(ROOT/'docs/36_ROUND14_CHANGES.md',entry),(ROOT/'docs/ART_MANIFEST.md',manifest)]:
    old=path.read_text(encoding='utf-8')
    if old.startswith('# S3 '):old=old.split('\n---\n\n',1)[1]
    path.write_text(text+old,encoding='utf-8')
print('S3 docs written from final evidence')
