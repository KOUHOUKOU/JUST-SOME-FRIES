# 38 - P1b: tree, house, person (art director spec)

Same look as the approved hero gull (docs/37, ART_REVIEW Review 3): soft pebble forms, bevels, baked AO + vertical gradient in vertex colour, warm light, warm-violet shadow, ONE shared soft-toon material. These three are the bulk of what the player sees.

## Tree (deciduous + pine)
- Deciduous: trunk tapered with a gentle lean and root flare; crown = 3-5 overlapping soft rounded lobes (subdivided blobs with gentle bumps, NOT faceted); colour gradient dark sage (underside, inside) -> mid green -> warm yellow-green highlight on top; AO between lobes and under the crown. 3 seeded variants (round, tall, wide). <= 500 tris each.
- Pine: 4-5 stacked rounded tiers with soft scalloped lower edges, darker teal-green, snow-free; trunk stub visible. 2 variants. <= 450 tris.
- ONE merged mesh per variant (trunk + crown) so it can be used in the existing MultiMesh batching (read game/scripts/world/world_flora.gd and batcher.gd; keep per-instance transforms/scales/tints working). Keep collision/trigger logic untouched.
- **Wind weight:** store sway weight in vertex colour ALPHA (0 at trunk base -> 1 at crown top). The soft-toon shader must ignore alpha for albedo. (P4 will use it; do the data now, not the shader.)

## House (town and homes)
- Read world_town.gd / world_homes.gd for the existing footprint sizes; keep the SAME footprints, heights, door positions and colliders, so nothing in gameplay moves.
- Chunky, friendly: bevelled walls with a very slight taper, thick overhanging roof with a soft eave and ridge cap, chimney, arched door with a step, shuttered windows (flower box on some), darker plinth at the base, AO under the eaves and around openings. Roof shapes: gable and hip. Wall colours (vertex colour, generated per variant): cream, peach, butter, sage-blue, rose; roofs: terracotta, salmon, teal. 6-8 combos from a seeded generator. <= 1,200 tris.
- Used through a loader in the world builders with the existing primitive houses as fallback.

## Person (NPC)
- Toy proportions about 3 heads tall: large round head, tiny simple face (two dark dot eyes with a highlight, small blush, tiny mouth), hair as one sculpted mass (variants: short, bun, long, cap-hair, bald), soft clothes with a couple of folds, rounded hands, shoes. <= 1,800 tris.
- Respect the pivot contract in docs/ART_MANIFEST.md (human_rig.gd): parts under `upper`, `torso`, `head`, `arm_l/r`, `hand_l/r`, `leg_l/r`, `hand_anchor`. Keep every animation mode working (idle walk jog eat chat fish paint sit lie wave alarm play) with no gaps or intersections at the extremes.
- **Recolouring:** the existing NPCs differ by style keys (skin, shirt, pants, hair, apron, vest, backpack, fat, scale...). Keep that variety working. You decide the mechanism (separate parts with tinted material variants cached like the existing `mat()` cache, or instance shader params on the one shared shader), but draw calls per person must be <= the current procedural person and the shader must stay cheap.
- Faces must read at 15 m as a face and at 60 m as a clean coloured figure; skin tones keep warm and varied.

## Review you must do (look at every image)
1. Blender turntable for each asset + a cast sheet: 8 different NPC styles side by side, 5 tree variants, 6 house combos.
2. In game with `--cams`: a street/square shot (houses + trees + people) at 3 m, 15 m, 60 m, in noon / golden hour / dusk; the cafe table close-up; a visual-novel portrait of an NPC if one exists; before/after sheet for each.
3. Numbers: tris, parts, draw calls vs the replaced procedural versions, per-person draw calls; a same-session frame-time A/B on a crowded town view (only report; do not stop for < 5 %).
4. Honest defect list. At most 3 internal iterations before reporting.

Gameplay, numbers, text, audio, saves untouched. No web export. Do not start P2.
