# S6 local nature-kit derivatives (2026-10-11)

No downloads. Read the existing `art_src/third_party/_quarantine/nature-kit/x/License.txt`: **Creative Commons Zero (CC0)**, Kenney Nature Kit 2.1. Licence original is retained. Official source: [Kenney nature-kit](https://kenney.nl/assets/nature-kit). Conversion uses `tools/blender/s6_world.py` through existing `import_kenney.convert`: palette/AO bake, flat vertex-colour output, metre dimensions, single surface, no texture. Complete per-source/per-output hashes, palettes and original triangle counts: `art_src/s6/assets.json`.

| Source within nature-kit | Derived output | Final tris | Use |
|---|---|---:|---|
| `Models/GLTF format/crops_wheatStageB.glb` | `game/assets/models/s6/wheat.glb` | 112 | 40 wheat rows at existing field centres |
| `Models/GLTF format/crops_leafsStageB.glb` | `game/assets/models/s6/leaves.glb` | 82 | 80 leaf clumps replacing 40 original rows |
| `Models/GLTF format/hanging_moss.glb` | `game/assets/models/s6/ivy.glb` | 52 | Existing town terrace edges |

All three use the existing shared material with procedural fallbacks. The S6 `headland.glb` (240 tris) is project-authored, not third-party. All prior S3 derived files and local source packs are unchanged. Four bounded review iterations, including rejected overly simplified crop shapes, remain under `art_src/s6/iteration_1..4/`. Final render/capture entry: `art_src/s6/review/README.md`. No additional packs used.

---

# S3b reuse note (2026-10-11)

No additional third-party files imported or downloaded. All 15 derived S3 kit GLBs and their source licences/hashes remain unchanged. S3b replaces the nine visible `crag.glb` placements with a project-authored 144-triangle decorative rock skirt; `crag.glb` is retained as an unused catalogue asset. Existing houses are project-authored assets with COLOR_0 repaint only, not fantasy-town-kit derivatives. The table below describes the historical S3 placements; only the crag placement count changes to zero in S3b.

---

# S3 third-party asset manifest

All source packs were already downloaded by the user. Read local `License.txt` before use; licence originals remain unchanged under `_quarantine/<pack>/x/License.txt`. No downloads or additional licences in S3.

Sources were inspected through their own supplied previews and actual Blender renders. `tools/blender/import_kenney.py` samples face-centre UV colours (or material factors when untextured), remaps the palette, bakes light AO/gradient, fits metre dimensions, creates genuinely split flat triangles and exports one vertex-colour surface without textures/cameras/lights. Full source/output SHA256, colour mappings, AO statistics and dimensions: `art_src/s3/kit_catalog.json`. Runtime shared material: `Art.material()`.

| Asset | Pack / official source | Licence | Source file within pack | Derived file | Tris | Used at / status |
|---|---|---|---|---|---:|---|
| cliff | [nature-kit](https://kenney.nl/assets/nature-kit) | CC0 1.0 | `Models/GLTF format/cliff_rock.glb` | `game/assets/art/kenney/cliff.glb` | 32 | Town terrace banks, 30 decorative faces |
| crag | [nature-kit](https://kenney.nl/assets/nature-kit) | CC0 1.0 | `Models/GLTF format/rock_tallA.glb` | `game/assets/art/kenney/crag.glb` | 136 | Headland edge, 9 inset crags |
| rock | [nature-kit](https://kenney.nl/assets/nature-kit) | CC0 1.0 | `Models/GLTF format/rock_largeC.glb` | `game/assets/art/kenney/rock.glb` | 72 | Pipeline prototype; loaded as availability guard only, not placed in final scene |
| bush | [nature-kit](https://kenney.nl/assets/nature-kit) | CC0 1.0 | `Models/GLTF format/plant_bush.glb` | `game/assets/art/kenney/bush.glb` | 32 | 6 headland / hill plants |
| flower | [nature-kit](https://kenney.nl/assets/nature-kit) | CC0 1.0 | `Models/GLTF format/flower_redA.glb` | `game/assets/art/kenney/flower.glb` | 73 | 6 flowers beside the plants |
| rowboat | [pirate-kit](https://kenney.nl/assets/pirate-kit) | CC0 1.0 | `Models/GLB format/boat-row-large.glb` | `game/assets/art/kenney/rowboat.glb` | 171 | 2 moored non-solid rowboats beside existing marina |
| barrel | [pirate-kit](https://kenney.nl/assets/pirate-kit) | CC0 1.0 | `Models/GLB format/barrel.glb` | `game/assets/art/kenney/barrel.glb` | 148 | 4 pier / marina supply barrels |
| crate | [pirate-kit](https://kenney.nl/assets/pirate-kit) | CC0 1.0 | `Models/GLB format/crate.glb` | `game/assets/art/kenney/crate.glb` | 76 | 19 existing crate positions, original collision/RNG retained |
| planks | [pirate-kit](https://kenney.nl/assets/pirate-kit) | CC0 1.0 | `Models/GLB format/platform-planks.glb` | `game/assets/art/kenney/planks.glb` | 48 | 2 stacked pier supplies; main decking uses a shader |
| palm | [pirate-kit](https://kenney.nl/assets/pirate-kit) | CC0 1.0 | `Models/GLB format/palm-detailed-bend.glb` | `game/assets/art/kenney/palm.glb` | 482 | Existing kind-2 palm locations via scenery loader; original collision/perch calls retained |
| table | [furniture-kit](https://kenney.nl/assets/furniture-kit) | CC0 1.0 | `Models/GLTF format/tableRound.glb` | `game/assets/art/kenney/table.glb` | 78 | 32 existing table positions, original table-top height retained |
| chair | [furniture-kit](https://kenney.nl/assets/furniture-kit) | CC0 1.0 | `Models/GLTF format/chair.glb` | `game/assets/art/kenney/chair.glb` | 162 | 57 existing chair positions |
| plant | [furniture-kit](https://kenney.nl/assets/furniture-kit) | CC0 1.0 | `Models/GLTF format/pottedPlant.glb` | `game/assets/art/kenney/plant.glb` | 60 | Existing planters plus 3 small cafe pots (36 total kit placements) |
| plate | [food-kit](https://kenney.nl/assets/food-kit) | CC0 1.0 | `Models/GLB format/plate.glb` | `game/assets/art/kenney/plate.glb` | 140 | 3 decorative cafe table plates; no gameplay targets |
| drink | [food-kit](https://kenney.nl/assets/food-kit) | CC0 1.0 | `Models/GLB format/soda.glb` | `game/assets/art/kenney/drink.glb` | 188 | 3 decorative cafe drinks; no triggers or collectible logic |

Rejected trials (NOT shipped): `pirate-kit/Models/GLB format/ship-small.glb`, CC0, official source https://kenney.nl/assets/pirate-kit . Whole ship was too ornate and its extracted `sail-a` did not meet the adaptation/shape gate. Derived trial files are retained in `art_src/s3/rejected/`; existing procedural sailboats remain. No new sailboat collision or bobbing logic was introduced. The original boats are statically batched; the spec's “bobbing as before” does not describe these existing source boats.

Not used: fantasy-town-kit, city-kit-suburban, blocky-characters. Existing authored houses, fries, gull and characters were retained. The previewed furniture `loungeChairRelax` was rejected as an indoor sofa. Food-kit fries previewed only; all interactive fries remain the existing game assets.
