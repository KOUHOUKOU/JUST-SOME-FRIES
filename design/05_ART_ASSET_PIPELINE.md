> ⚠️ **被设计 v2 部分取代。** 现行规则以 `docs/18_DESIGN_V2_AUTHORITATIVE.md` 与 `docs/19_IMPLEMENTATION_PLAN_V2.md` 为准;本文件中与之冲突的条款(薯条模型规格、场景建模规格(v2 要求更高))**作废**,其余内容仍可参考。

# 05 — ART AND ASSET PIPELINE

## Core strategy

Do not build this game around a large external asset pipeline.

### Environment
Build primarily from Godot primitives and simple materials.

### NPCs
Build from modular primitive body pieces or extremely simple local meshes.

### Hero gull
Use one external Tripo GLB if available; otherwise use the procedural fallback gull.

This is intentional. Completion and visual coherence matter more than mesh complexity.

## Why there are no generated 2D art files in this workspace

The frozen visual design does not require raster concept art, painted textures, or illustrated UI to begin production. UI should use simple vector/procedural shapes, and the world is deliberately low-poly. Generating images now would create asset dependencies without improving the critical path.

If a later key-art/submission-image is needed, generate it only after the playable game is finished.

## Visual style

Stylized low-poly coastal miniature.

Characteristics:
- clear silhouettes
- faceted geometry
- warm late-afternoon light
- limited palette
- minimal texture dependence
- readable color-coded fries.

Avoid:
- photorealism
- dense PBR texture workflow
- complex decals
- large material libraries.

## World palette

- sea: muted teal-blue
- sky: pale blue → warm peach horizon
- sand: warm cream
- wood: faded warm brown
- primary walls: chalk/off-white
- house accents: faded blue, faded coral, sage
- roofs: terracotta / slate gray
- café awning: muted sage
- kiosk accent: coral-red.

Special Fry colors:
- Red: saturated coral/red-orange
- Blue: clean ocean blue
- Yellow: warm gold
- Green: fresh medium green
- Prism: violet + rainbow shimmer/emission
- Ordinary: normal fried-potato gold, matching background fries.

## Lighting

One DirectionalLight3D.

Fixed golden-hour time.

Warm direct light, cooler ambient fill.

Use modest shadows.

WorldEnvironment:
- reasonable tone mapping
- subtle ambient fill
- optional very light distance fog.

Do not build:
- day/night cycle
- volumetric weather
- expensive realtime GI dependency.

## Water

P0:
- one large plane
- appealing blue/teal material.

Optional:
- simple low-frequency vertex displacement or scrolling normal.

Do not spend meaningful schedule on realistic water.

## Hero seagull

Expected final file:

`game/assets/models/hero_gull.glb`

### Recommended Tripo prompt

> Stylized low-poly herring gull game character, clean faceted geometry, white body and head, cool gray wings with dark wing tips, yellow beak and legs, clear readable silhouette, slightly charming proportions, wings spread in neutral glide pose, symmetric, game-ready, no environment, no accessories, simple clean materials.

### Manual workflow

1. Generate several previews only if cheap.
2. Select one with the cleanest gull silhouette.
3. Prefer sane topology over detail.
4. Run Tripo Rig Check first if using rigging.
5. If compatible, attempt `avian` auto rig.
6. Export GLB.
7. Put at the exact path above.
8. Only use Blender for scale/orientation or small repair.

Current Tripo documentation supports non-humanoid `avian` auto rigging and GLB output, but the project must never depend on it succeeding.

## Procedural fallback gull

Required even if hero GLB is expected.

Create under `PlayerGull/VisualRoot` from simple low-poly pieces:
- ellipsoid/body
- sphere/low-poly head
- cone beak
- left wing
- right wing
- tail wedge
- optional simple legs.

Visual states:

### GLIDE
Wings extended.

### FLAP
Wing rotations animate through one down/up beat.

### DIVE
Wings tuck partially backward.

### DASH
Wings tuck further.

### GROUND
Wings fold close to body.

### HIT
Whole visual root rolls/spins briefly.

Use Tween/AnimationPlayer.

Movement collider remains independent.

## Modular NPC construction

Base body parts:
- head primitive
- torso
- upper arms
- optional forearms
- legs
- simple hair/hat block.

Required visual variants:
- elder male
- elder female
- adult male
- adult female
- child.

Reuse same meshes with:
- scale changes
- torso proportions
- clothing colors
- hair block changes
- hat/accessory.

No facial animation.

Actions created by transform animation:
- idle sway
- head turn
- torso lean
- arm protect
- arm swat
- child hop.

## Environment asset manifest

Build in Godot primitives unless noted.

### Café
- wall blocks
- roof/awning
- 5 tables
- ~12 chairs
- planters
- low fence.

### Kiosk
- shell
- canopy
- service opening
- fry cartons
- tables.

### Beach
- sand plane
- umbrellas
- chairs
- towels
- ball
- sandcastle.

### Pier
- deck
- rails/posts
- ropes if cheap
- lifebuoy
- bench
- 1–2 blocky boats.

### Town
- 3–5 simple house shells
- roof wedges
- a few chimneys/vents
- lamp posts
- bins
- benches.

### Nest
- circular bundle of cylinders/sticks
- cloth scraps / shiny junk.

## Fries

Use very simple meshes.

A fry can be:
- elongated beveled box
- yellow/golden material.

Special version:
- same mesh
- color/emissive halo/particles.

Do not make seven unique high-detail fry models.

## Carryable P1 props

If implemented:
- phone
- keys
- blue bottle cap
- pen
- toy shovel
- sunglasses.

Simple geometry only. No collection UI.
