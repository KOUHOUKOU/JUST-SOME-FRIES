> ⚠️ **被设计 v2 部分取代。** 现行规则以 `docs/18_DESIGN_V2_AUTHORITATIVE.md` 与 `docs/19_IMPLEMENTATION_PLAN_V2.md` 为准;本文件中与之冲突的条款(RED 遭遇坐标(迁至 1.5,0.4,58)、巢穴锚点、Prism 锚点(改为技巧点)、NPC 档案、nest 碰撞/分组;翻滚为 A/D 双击,无需新 action)**作废**,其余内容仍可参考。

# 16 — CONSTRUCTION COORDINATES, INPUTMAP, COLLISION, IDS

This file removes low-value implementation guesswork. Use these values for the first complete build. Small tuning changes are allowed only after the full graybox game runs.

## Coordinate convention

- Godot +Y = up.
- +Z points toward the open sea.
- -Z points inland.
- +X points toward the beach / east side.
- -X points toward the kiosk / west side.
- Ground reference height = Y 0.
- Sea surface = Y -0.75.

Core town footprint: X -40..40, Z -25..35.
Pier may extend to Z 52. Background sea may extend far beyond this.

## Fixed landmark anchors

Use these as scene-parent origins; individual meshes can be arranged locally around them.

| ID | Position (x,y,z) | Notes |
|---|---:|---|
| `LM_CAFE` | `(-6,0,2)` | tutorial origin / ending return |
| `LM_NEST` | `(0,8,-6)` | central rooftop nest |
| `LM_KIOSK` | `(-18,0,15)` | fast-food kiosk |
| `LM_BOARDWALK` | `(0,0,11)` | connective promenade |
| `LM_BEACH` | `(22,0,16)` | sand/family area |
| `LM_PLAY_AREA` | `(28,0,14)` | child encounter |
| `LM_PIER_ROOT` | `(0,0.25,26)` | pier begins here |
| `LM_PIER_END` | `(0,0.25,50)` | far pier end |
| `LM_HOUSES` | `(4,0,-15)` | 3–5 low houses |

Recommended nest spawn position: `(0,9.0,-5.5)` facing roughly toward +Z.

## Required encounter IDs and anchors

IDs are stable and should be used in scene metadata/data resources so progression never relies on node names.

| Encounter ID | Type | NPC | Position | Facing suggestion |
|---|---|---|---:|---|
| `TUTORIAL_01` | tutorial | elder_m | `(-8,0,3)` | `(0,0,1)` |
| `TUTORIAL_02` | tutorial | elder_f | `(-2.5,0,5.5)` | `(-1,0,0)` |
| `TUTORIAL_03` | tutorial | adult | `(-16.5,0,15)` | `(0,0,-1)` |
| `SPECIAL_RED` | red | adult | `(1.5,0.4,35)` | `(0,0,-1)` |
| `SPECIAL_BLUE` | blue | adult | `(20,0,19)` | `(-0.6,0,-0.8)` |
| `SPECIAL_YELLOW` | yellow | adult | `(-11,0,11.5)` | `(0.8,0,0.2)` |
| `SPECIAL_GREEN` | green | child | `(27,0,14.5)` | `(-1,0,0)` |

These positions are starting anchors. Move by at most a few meters if collision/approach lanes require it; preserve zone and difficulty intent.

## Ordinary Fry exact first-build location

Encounter relation: same café table as `TUTORIAL_01`.

Initial world position:

`(-8.65, 0.10, 3.65)`

The tutorial fry should be visibly on the table around Y 0.9–1.0.
The Ordinary Fry is on the ground beside/under the table edge, not behind an opaque wall.

It must exist in the scene at startup and remain edible in every progression state.

## Prism spawn anchors

Use a fixed pool rather than procedural spatial generation. Randomly choose inactive anchors after `STILL_HUNGRY` begins.

Suggested anchors:

- `PRISM_01 (-14,1.0,14)` kiosk table
- `PRISM_02 (-4,1.0,7)` café/boardwalk table
- `PRISM_03 (14,0.8,16)` beach chair
- `PRISM_04 (25,0.6,11)` beach towel / picnic point
- `PRISM_05 (4,1.0,30)` pier bench
- `PRISM_06 (-3,1.0,42)` pier edge table/prop point
- `PRISM_07 (7,0.8,-8)` house-side bench
- `PRISM_08 (-20,0.8,10)` kiosk outer seat

Never spawn Prism Fries inside the café floor location used by the Ordinary Fry.

## InputMap action names

Create these exact Godot actions:

| Action | Default binding |
|---|---|
| `move_forward` | W |
| `move_back` | S |
| `bank_left` | A |
| `bank_right` | D |
| `flap` | Space |
| `dash` | Left Shift |
| `interact` | E |
| `squawk` | F |
| `gull_sense` | Tab |
| `pause_game` | Esc |

Mouse motion is handled directly for pitch/yaw.

Recommended initial mouse sensitivity scalar: `0.0022` radians/pixel, exposed in settings later if easy.

## Collision layers

Use exact layer assignments unless an existing implementation has a strong technical reason to differ.

1. `WORLD_STATIC`
2. `PLAYER`
3. `NPC_BODY`
4. `INTERACTABLE`
5. `NPC_SWAT`
6. `TRIGGER`
7. `CARRYABLE`
8. `RESERVED`

### Suggested masks

Player body:
- collide with 1 WORLD_STATIC
- optionally 3 NPC_BODY if physical body collisions feel good; otherwise NPC bodies may be trigger-only.

Player snatch/query Area3D:
- detect 4 INTERACTABLE and 7 CARRYABLE.

NPC awareness raycast:
- test 1 WORLD_STATIC and identify 2 PLAYER as target through explicit query logic.

NPC swat Area3D:
- layer 5, mask 2 PLAYER.

Nest trigger:
- layer 6, mask 2 PLAYER and optionally 7 CARRYABLE.

Fry:
- layer 4.

Carryable props:
- layer 7.

## Node groups

Use groups for cheap discovery:

- `player`
- `npcs`
- `fries`
- `special_fries`
- `prism_fries`
- `carryables`
- `nest`

Do not use groups as the only source of progression identity; encounter IDs remain explicit.

## NPC baseline data profiles

Use data/resource dictionaries, not three separate code paths.

### Elder
- view distance: 8 m
- forward view angle: ~80° total
- awareness gain: 0.45 / sec head-on
- awareness decay: 0.8 / sec
- timing success fraction: ~0.42 of ring cycle
- swat telegraph: 0.65 sec
- swat active: 0.25 sec

### Adult
- view distance: 11 m
- view angle: ~105° total
- awareness gain: 0.75 / sec
- awareness decay: 0.65 / sec
- timing success fraction: ~0.30
- swat telegraph: 0.42 sec
- swat active: 0.22 sec

### Child
- view distance: 12 m
- view angle: ~125° total
- awareness gain: 1.0 / sec
- awareness decay: 0.55 / sec
- timing success fraction: ~0.22
- swat telegraph: 0.28 sec
- swat active: 0.20 sec

Approach from behind should multiply awareness gain by roughly 0.3.
Green upgrade multiplies timing success width by 1.45, clamped to a sensible maximum.

## UI anchors

Use normal 16:9 reference layout and Godot anchors so it scales.

- Objective: top center, Y margin ~32 px.
- Gull status/stamina: top right, X margin ~32 px, Y ~28 px.
- Four special-fry slots: immediately left of gull status.
- Center reticle: exact viewport center.
- Reward card: center, slightly above true center.
- Achievement toast: lower-right, compact.

Do not create a persistent minimap in normal flight.

## World first-build material colors

Approximate starting hex colors; tune lighting rather than inventing a new palette.

- chalk wall: `#E8E2D2`
- sage: `#879B82`
- coral: `#D96D5F`
- faded blue: `#7396A8`
- sand: `#D9C79F`
- wood: `#8B6A4D`
- terracotta: `#B96F50`
- slate: `#586169`
- sea: `#477F8A`
- ordinary fry gold: `#DCA847`
- red fry: `#E85745`
- blue fry: `#3D8CD9`
- yellow fry: `#F1C94B`
- green fry: `#4FB56D`
- prism base: `#9A5DE8`

## Rule if these constants conflict with feel

Do not ask for redesign. Keep the game loop and spatial relationships, make the smallest tuning change, and document it in `TUNING_NOTES.md`.
