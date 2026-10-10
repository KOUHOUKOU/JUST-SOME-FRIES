# 43 - S3: ready-made CC0 kits + cover-quality ground, for the cafe + pier + beach slice (art director spec)

Target: `art_src/reference/cover.jpg`; direction `docs/41_COVER_DIRECTION.md`; lighting already improved in S2 (see `art_src/s2/review/summary_before_after_cover.png`; the roof view at golden hour is the right mood). What is still far from the cover in the S2 captures: **the ground and cliffs look like brown dirt / one big brown block** (headland plateau, beach), the **water is a flat teal**, the **pier/cafe props are sparse and plain**, boats/umbrellas/tables are crude, the houses lack warm lit windows.

## Third-party assets (user approved CC0 downloads; already downloaded and licence-checked)
`art_src/third_party/_quarantine/<pack>/x/` (each has `License.txt` = CC0; models in `Models/` as GLB/OBJ/FBX with a shared `colormap.png`/textures):
- `pirate-kit`: ships, small boats, docks/planks/posts, barrels, crates, palm trees, rocks, islands, flags.
- `nature-kit`: trees, pines, bushes, rocks, cliffs, stones, grass, flowers, logs, fences, tents.
- `food-kit`: fries, burgers, drinks, plates, cartons, ice cream, etc.
- `furniture-kit`: tables, chairs, benches, lamps, plants, shelves (indoor-leaning, many usable outdoors).
- `fantasy-town-kit`: modular walls, roofs, stairs, bridges, stalls, market carts, windmill, fences, wells.
- `city-kit-suburban`, `blocky-characters`: probably NOT needed (style mismatch) unless a piece is clearly useful.
Rules: only use them after you have viewed the actual model; keep the licence file with the pack; record every asset actually used in `art_src/third_party/ASSET_MANIFEST.md` (pack, source URL = the official Kenney page, licence CC0, file names, where used). No other downloads; ask if something else is needed.

## Pipeline for third-party kits (build once, reuse)
`tools/blender/import_kenney.py` (headless): import a GLB, convert its colormap/texture colours to VERTEX COLOURS per face (sample the colormap at the face UV; the kits are flat-colour palettes), remap colours into OUR palette (warm cream walls, terracotta/coral roofs, olive/sage greens, teal-blue water, golden wood planks, white sails with soft lavender shade; keep the cover mood), flat shading, bake light AO/gradient into vertex colour, fix scale/origin to our world units, merge parts that always go together, export to `game/assets/art/kenney/*.glb` using the existing shared soft-toon material path. Each exported asset must look consistent with the cover: faceted/flat, warm, clean. Use MultiMesh/batching for repeats; keep fallbacks.

## What to do (priority order, always keeping positions/colliders/triggers/gameplay intact)
1. **Ground, beach and cliffs** (biggest visible flaw): beach sand a warm cream-yellow (not brown gravel), grass lush olive/sage, paving warm grey stones, wooden decking golden brown; the headland/hill: grass cap, rocky layered sides from nature-kit rocks/cliffs placed along the edges (decor only, collision untouched), small bushes and flowers; fix ground.gdshader palette and noise so it reads as stylised and clean. The water: richer blue-teal depth gradient, lighter near shore, warm glitter, soft foam line along shore and pier posts.
2. **Pier and marina**: planks/posts/rails/bollards/lamp posts with glowing round bulbs (cover style), barrels, crates, rope, life rings; boats from pirate-kit (small sail boats and rowboats: white/cream hulls with coloured stripes, white-lavender sails, a few tiny fishing boats), bobbing as before.
3. **Cafe square**: round tables, chairs, big striped umbrellas, planters, string lights, menu boards, food on tables (fries cartons from food-kit/our fry assets), potted plants, a counter; make the area feel lived-in but ordered, like the cover.
4. **Beach**: palm trees, sun umbrellas, loungers, towels, a tiki bar.
5. **Houses and shops** on the hill and by the cafe: warm cream/peach walls, strong terracotta/coral roofs, shutters, balconies, awnings, window glow at dusk (cheap emissive), using fantasy-town modular pieces and/or our existing house assets; stairs to the hill.
Do the first three completely before the rest; if budget or quality is short, ship fewer, better pieces.

## Performance rules
Draw calls, tris and island build time must not get worse than the current S2 numbers (the web build is the constraint; see docs/34_ROUND13_CHANGES.md): batch/instance, merge static pieces per district, share the single material. Report A/B draw calls at 3/15/60 m and the island build time.

## Review you must do
Same four fixed cameras as S2 (roof toward pier at golden hour and dusk; pier/marina; town hill; sea flight) plus the cafe table close-up, each BEFORE (S2 end state) vs AFTER vs cover crop side by side; be critical and list what is still plainer than the cover. Up to 960x540 for key shots. At most 4 internal iterations.
Constraints: no gameplay/number/text/audio/save changes; no mouse/keyboard desktop automation; gentle runs; no web export; write only inside this project. Update docs/36_ROUND14_CHANGES.md and docs/ART_MANIFEST.md. Report briefly with before/after/cover sheets, numbers and honest remaining defects. Then STOP.
