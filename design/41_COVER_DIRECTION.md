# 41 - Direction v2: "make the game look like its cover" (supersedes the soft-clay direction of docs/35 for LOOK; budgets/pipeline rules of docs/35 still hold)

The user rejected the round-14 result so far: the new gull lost its goofy charm, the people look like crude modelling, and the changes were not a real upgrade. Reason: we drifted from the user's own cover and judged assets against the old game instead of the target. THE TARGET IS `art_src/reference/cover.jpg`. Full user brief: `art_src/reference/art_remaster_master_brief.md` (read it).

## What the cover actually is (analysis)
1. **Faceted, flat-shaded low-poly** forms with soft cinematic lighting. Not smooth clay, not feathers. Chunky houses are simple boxes with gable roofs; the charm is composition and light, not model detail.
2. **The gull**: a big round faceted white head (head about as big as half the body), **two tiny round black dot eyes** (wide set, no lids, no brows: this is the goofy charm), a chunky orange-yellow beak, plump faceted white body, broad angular wings with pale-grey facets, yellow flat-shaded webbed feet. Silly, innocent, greedy.
3. **Light and atmosphere carry the image**: purple-to-orange dusk sky with clouds; low golden sun with a sun-glitter path on the water; warm glowing windows; lamp posts with round glowing bulbs along the pier; string lights; cool shadows against warm lit sides; atmospheric haze making distant hills and islands lighter and bluer; mild bloom; teal-blue water with soft waves; terracotta/coral roofs, cream walls, olive/sage trees, wooden pier, sails, a red-and-white lighthouse on a rocky island with wind turbines, a Ferris wheel with lights.
4. People are tiny and simple. Detail density is moderate: a balance of big shapes and small life details (umbrellas, tables, lanterns, boats, bunting).

## Rules for this round
- Judge every result by a SIDE-BY-SIDE with the cover (same mood), not by "better than before".
- Prefer high-quality ready CC0 kits (downloaded and licence-verified in `art_src/third_party/_quarantine/`: Kenney pirate-kit, food-kit, furniture-kit, nature-kit, fantasy-town-kit, city-kit-suburban, blocky-characters; all CC0) over scripted primitives, unified by a common palette and the cover lighting. Record every third-party asset in `art_src/third_party/ASSET_MANIFEST.md` (name, source URL, licence, files used).
- Custom-model only what must be unique: the gull (and later the fry shack sign, Ferris wheel etc.).
- Keep what already works if it still fits the cover: tree/house loaders, fry carton, wardrobe loaders, fallbacks, the pipeline. Remove what contradicts the cover (smooth/feathery gull, judgy lidded eyes).

## Sequence
S1 gull rebuild to the cover (spec below) -> S2 cover lighting and atmosphere in real Godot -> S3 kit integration for the cafe + pier slice (palette-remapped Kenney assets) -> S4 same-camera before/after + 30-60 s gameplay clip -> then roll out to the rest of the island.

## S1 - the gull, to the cover and the user's five reference views
References: `art_src/hero_gull/gull_{left,right,front,back,top}.png` (the user's own design) and the gull on the cover.
- **Faceted flat shading** (export with sharp/split normals so the shader shows facets). About 500-900 tris total. No feather cards, no bevel mush, no smooth shading on the body.
- **Head**: big round faceted sphere merged into a plump body, no neck definition to speak of. **Eyes: two small black round dots (slightly raised discs or low-poly spheres, about 7-8 % of head width), wide-set on the sides of the face, no eyelids, no highlight card, no brow, no blush.** The look is innocent and dumb.
- **Beak**: chunky, short, thick trapezoid/box-like prism, orange-yellow (F7B21A-ish) with a slightly redder tip as in the reference.
- **Body**: plump egg, white (F5F5F7); pale cool-grey facets on belly and undersides come from lighting plus a few vertex-colour facet tints (E2E4EA); wings broad, angular, pointed, mid-grey top facets and darker grey tips as in the reference; short wedge tail; yellow-orange thin legs with flat triangular webbed feet.
- **Objective check**: render orthographic silhouettes (front, left, top) of the model and compare with the reference images by silhouette IoU; target IoU >= 0.85 per view (report the numbers) plus your own visual check. A 3/4 rear view (the gameplay camera angle) must read as a plump goofy white gull with a big head.
- **Integration**: keep the existing authored-gull path, pivots and animation contract in `gull_visual.gd` and docs/ART_MANIFEST.md (shoulder, elbow, head, beak_socket, legs, tail, wear slots, comet trails, variants incl. the 2.3x big brother). Replace the part meshes only. The wardrobe items attach to slots: refit hat/glasses/shades etc. to the new head (they must sit properly on a big round head with dot eyes). Keep the procedural fallback.
- Colours must stay white seagull in noon, golden hour and dusk.
- Review shots: Blender 5-view turntable plus silhouettes vs references; in game: flight (rear 3/4, side), perch, snatch close-up with a fry in the beak, VN portrait, wearing top hat + shades, at 3 / 15 / 60 m; before (current) vs after vs the cover gull side by side.
