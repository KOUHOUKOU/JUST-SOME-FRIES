# 35 - Art Upgrade Brief (Round 14: "Warm Clay Storybook")

Authoritative brief for the final visual upgrade. Read this whole file, then `AGENTS.md` section 11, then `TUNING_NOTES.md` (performance + web sections) before touching anything.

## 0. Why, and what is in / out of scope

Today every object in the game (gull, people, trees, houses, props) is assembled in GDScript from Box / Sphere / Capsule / Cylinder meshes with one flat colour each. `game/assets/models/` is empty. The sky, light, rainbow, clouds and UI are good. The objects look crude and do not feel like they live in that light.

**In scope:** authored 3D models (Blender -> GLB), baked vertex colour / AO, a soft-toon material shader, wind and "life" shaders, and replacing primitive-built visuals with the authored ones.
**Out of scope (frozen):** gameplay, numbers, flight, snatch loop, quests, story text, audio, UI layout, save format. Do not change any tuning value. If a visual swap forces a gameplay change, stop and report.

This round relaxes two old AGENTS.md rules only for art work: "prefer Godot primitives" (GLB is now wanted) and "do not look at references / art polish later" (the art round is now). Everything else in AGENTS.md still holds.

## 1. Tooling (verified on this machine, 2026-10-10)

* Blender: `C:\Program Files\Blender Foundation\Blender 5.2\blender.exe` (5.2.1 LTS).
* Headless works. A smoke test (sphere + bevel + EEVEE render 320x240 + GLB export) ran in 3.5 s. Use:
  `"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" --background --python tools/blender/<script>.py -- <args>`
* **No Blender MCP server is needed or wanted.** Work with plain `bpy` scripts, so every asset is reproducible from a script in the repo. Do not use a live GUI bridge.
* Godot: see `TUNING_NOTES.md` (editor `D:\Tools\Godot\4.7.1`, console exe, dev test modes, `--cams` reads `shots/cams.json`).
* Python for tools: the Windows Python already used by `tools/`. Do not install packages. Ask before downloading anything.

Layout:
```
tools/blender/common.py      shared helpers (you write it): clean scene, bevel, smooth, AO bake to vertex colour, export, turntable render, contact sheet
tools/blender/<asset>.py     one generator script per asset (parametric, seedable for variants)
art_src/<asset>/             references (input), review renders (output), optional .blend
game/assets/models/<asset>.glb   what the game loads
docs/ART_MANIFEST.md         table: asset | script | glb | tris | status | notes   (you keep it current)
```

## 2. The look: "Warm Clay Storybook"

Think handmade clay toys in golden late-afternoon light, with a gouache grain. NOT realistic, NOT hard faceted low-poly.

**Shape language - "soft pebble"**
* Everything is a little chubby and rounded. Every hard edge gets a bevel (Blender Bevel modifier, 2-3 segments, width relative to part size) so edges catch light. Smooth shading everywhere except deliberate crisp features (roof edges, planks).
* Strong, readable silhouettes at 30 m. Big shapes first; at most two or three secondary details per asset.
* Consistent proportions across the cast: people about 3 heads tall, big round head, small eyes, blush dots, hair as one sculpted mass, clothing with a few soft folds.

**Colour script**
* The world is pastel and slightly desaturated: cream, peach, salmon-coral, dusty teal sea, sage green, butter yellow roofs.
* Shadows are tinted warm-violet, never grey or black. Highlights lean warm gold.
* **Fries are the only hot, saturated, glowing gold in the world** (they already glow; keep that the brightest accent). Nothing else may compete with them.
* The player gull must pop from sky and ground: cream-white body, lilac underside shadow, coral-orange beak and feet with the red beak dot, dark charcoal wing tips, a thin rim light. Keep the existing silhouette idea (big wings, plump chest). References for the gull pose and colours: `art_src/hero_gull/*.png` (the faceted look in them is too hard: keep the shapes, soften the surface with bevel + smooth shading).

**Surface**
* No image textures except one small shared grain/gradient atlas (<= 512x512). Colour comes from vertex colours + that atlas.
* Bake ambient occlusion into vertex colour (darker at contact seams, under eaves, tree crown undersides) plus a vertical gradient (darker low, lighter high). This is what makes simple shapes look finished.
* Roughness high (0.8-1.0), no metallic except tiny accents.

**Godot material / shader** (`game/shaders/`)
* One soft-toon shader: 3-4 soft light bands (no hard cutoffs), warm-violet shadow tint, subtle rim light, vertex colour as albedo. Must work with the existing directional light, sky, fog and the `perf_governor`.
* Optional thin outline (inverted hull or shader) for the player gull and NPCs only. Keep it off at governor level >= 2.
* Wind shader (vertex-only, cheap) for tree crowns, grass tufts, flags, bunting. Cloud shadow drift on the ground is a nice-to-have.

## 3. Hard budgets (the web build is the constraint)

From Round 13: the island has about 17,000 objects, 2,000-2,800 draw calls, the web build is one thread, and the first frame already freezes browsers. **Art must not make this worse. Prefer it to get better.**
* Hero gull <= 4,000 tris. Person <= 1,800 tris. House <= 1,200 tris. Tree <= 500 tris. Small prop <= 200 tris.
* Static scenery: merge per-district, or use `MultiMeshInstance3D` (see `game/scripts/world/batcher.gd`). Never one `MeshInstance3D` per bush.
* Share materials: target <= 6 distinct materials for all scenery. One shared soft-toon material with vertex colour is the default.
* No per-object `_process`. Wind and life effects live in shaders.
* Do not add draw calls to the three close-up cameras in catch moments.
* After each phase record: draw calls, frame time, `perf_governor` level, first-frame build time (use existing dev modes / log lines). If any number is worse than before the phase, fix or revert before moving on.

## 4. Integration contracts (do not break gameplay)

Gameplay never depends on the visuals; keep it that way.

**Gull** (`game/scripts/player/gull_visual.gd`, `gull_player.gd:208`): it animates pivot nodes (shoulder/elbow per wing, head, beak socket, legs, tail, body, wear slots). Export the authored gull as separate parts (wing segments, head, beak, tail, legs, body) so each can sit under the existing pivot. Read the build code in `gull_visual.gd` first and document the exact pivot hierarchy in `docs/ART_MANIFEST.md` before modelling. Replace the mesh inside each pivot; do not rewrite the animation code. Accessories (hats, shades, scarf) keep their sockets. Keep the procedural gull as a fallback if the GLB is missing.
**People** (`game/scripts/npc/human_rig.gd`): same idea. Keep the nodes `upper`, `torso`, `head`, `arm_l/r`, `hand_l/r`, `leg_l/r`, `hand_anchor`; keep `style` colours working (skin, shirt, pants, hair, apron, vest, backpack...) by using vertex-colour channels or separate recolourable parts, so existing NPC variety survives. Scale variants (`fat`, `scale`) must still look right.
**Scenery**: GLBs are loaded by the world builders (`world_builder.gd`, `world_town.gd`, `world_homes.gd`, `world_flora.gd`, `world_extra.gd`). Replace builders' primitive code with a loader call, keep positions/colliders/gameplay triggers exactly as they are, keep the primitive path as a fallback if a GLB is missing.
**GLB export settings:** +Y up, apply modifiers, include vertex colours, no cameras or lights, origin at the sensible pivot (feet for people, base centre for buildings), 1 Blender unit = 1 metre = current world scale (a person is about 1.8 m, check `human_rig` scale). After import verify in Godot that vertex colours actually show (material must use vertex colour as albedo).

## 5. Phases (each ends with a STOP gate)

**P0 - Pipeline (small).** `tools/blender/common.py` + a turntable/contact-sheet renderer (EEVEE, 4 angles + top, 512px each, warm key light, soft sky fill) writing PNGs to `art_src/<asset>/review/`. A Godot-side loader helper and the soft-toon shader. Prove it on a rounded cube end to end (Blender -> GLB -> in game). *Gate: you looked at the render and the in-game screenshot.*

**P1 - Vertical slice.** One hero gull, one tree (3 crown variants via seed), one house (2 variants), one person. In the game, with the new shader, in the same camera as an existing "before" screenshot. Produce `art_src/slice/before_after.png`. **STOP here and report.** The art director (Claude) approves or rejects the look using the quality bar in `docs/ART_STATE.md`, and starts P2 by sending you a new prompt. Do not start P2 on your own.

**P2 - People and wearables.** All NPC types in `human_rig` styles, dog, the big brother, gull accessories, children, vendors. Face/portrait views used by the visual-novel box must still look right (`ui/story.gd say_vn`).

**P3 - World kit.** Houses, shops, boats, pier, Ferris wheel, windmill, lighthouse, street furniture, benches, umbrellas, stalls, rocks, hedges, lamp posts, signs. 3-4 variants per family so streets are not repetitive.

**P4 - Life.** Wind, cloud shadows, shore foam line, boat bobbing, chimney smoke, window glow at dusk, aerial-perspective tint by distance. All shader-side, all cheap.

After each phase: update `docs/ART_MANIFEST.md`, add `docs/36_ROUND14_CHANGES.md` notes (what changed, numbers, known defects), run the regression modes, and stop for review.

## 6. Review protocol (how "good" is decided)

You are building art, so you must SEE it:
1. After every asset, render the contact sheet and **open the PNG and look at it**. Describe what you see in two or three honest sentences, including defects (lumpy form, muddy colour, weak silhouette, z-fighting, bad normals, floating parts). If your environment cannot show you images, say so immediately and stop; do not guess.
2. Then take an in-game screenshot of that asset at three distances (close, 15 m, 60 m) with `--cams`, build a contact sheet, and look again. Art that is good in Blender but mush at 60 m fails.
3. Compare against the "before" screenshots in `shots/` and the colour script above. Report one thing you would still change.
4. Never write "looks great". Write what you checked and what is still wrong. The art director decides taste against `docs/ART_STATE.md`.
5. Reviewer notes will appear as `docs/ART_REVIEW.md`. Read it at the start of every session and fix every open item first.

## 7. Regression and machine etiquette

* Re-run the existing checks after each phase (`--autotest` and the dev modes the phase touches; see `TUNING_NOTES.md`). Gameplay results must be identical.
* The machine's fans run hard on long jobs. Gentle runs only: Blender EEVEE low samples (<= 16), `--threads 4`, render <= 512px for review, no looping renders, no repeated full test suites, no web re-export unless asked. If you need the web build re-exported, use `BUILD.bat` and `tools/web/patch_index.py` exactly as `docs/34_ROUND13_CHANGES.md` says.
* Write all temp files to `art_src/` or the system temp dir, never into `game/` unless it is a deliverable.
* Windows paths and CRLF: write GDScript with tabs like the surrounding code; do not reformat files you are not changing.

## 8. Do not

* Do not change gameplay, numbers, text, audio, saves.
* Do not add dependencies, plug-ins or MCP servers. Do not download assets, textures or models from the internet (ask first).
* Do not build one giant mesh for the whole island, or any asset above the budgets.
* Do not remove the procedural fallbacks.
* Do not touch the plain fry's rules (hidden, unlisted, never glowing) or the Gull Sight emblems.
* Do not skip a STOP gate.
