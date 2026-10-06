> ⚠️ **被设计 v2 部分取代。** 现行规则以 `docs/18_DESIGN_V2_AUTHORITATIVE.md` 与 `docs/19_IMPLEMENTATION_PLAN_V2.md` 为准;本文件中与之冲突的条款(80×60 的地图尺寸、巢穴、分区内容(v2 为 260×220,九个分区))**作废**,其余内容仍可参考。

# 03 — MAP AND WORLD LAYOUT

## World size

Core playable coast/town footprint: approximately **80 m × 60 m**.

This is deliberately compact. The sea horizon and background structures create scale; travel time stays short.

Normal flight from nest to the farthest meaningful encounter:
- before upgrades: ~12–15 s
- after upgrades: ~6–9 s

## Spatial principle

The nest is central and elevated. From the nest, a player should understand the major geography without a minimap.

The café/tutorial origin must be visible or easy to relocate later so the final return feels natural.

## Conceptual plan

```text
                         OPEN SEA

              ~~~~~~~~~~~~~~~~~~~~~~~~~

                         PIER
                          |
                     small marina
                          |
            FAST FOOD ----+---- BEACH
                 \        |        \
                  \   BOARDWALK   PLAY AREA
                   \      |
                      CAFE
                       |
                 [ROOFTOP NEST]
                       |
              LOW SEASIDE HOUSES

                     INLAND
```

## Zone A — Café Terrace

Narrative origin and ending location.

Required geometry:
- low one/two-story café shell
- awning
- 4–5 tables
- chairs
- 2–3 planters
- low fence/edge
- first two tutorial encounters
- Ordinary Fry at the first table.

Palette:
- warm off-white walls
- muted sage awning
- medium warm wood furniture
- terracotta planters.

Ordinary Fry placement:
- on ground under or immediately beside first tutorial table
- partially near a chair/table leg
- not occluded by an opaque object from all natural viewing angles
- no glow until Prism convergence starts.

## Zone B — Boardwalk

The connective spine.

Geometry:
- simple wide promenade
- benches
- bins
- lamp posts
- railings
- planters.

Purpose:
- readable travel route
- low-altitude flight lane
- yellow encounter
- visual connection between café, kiosk, beach, pier.

Materials:
- pale warm stone and/or faded wood.

## Zone C — Fast-Food Kiosk

Brightest human-made landmark.

Geometry:
- small rectangular kiosk
- service hatch
- cream canopy
- coral/red accent panel
- takeaway fry cartons
- 2 tables.

No logos or readable brand names.

Purpose:
- visually communicates "food"
- tutorial 3.

## Zone D — Beach

Largest open ground region.

Geometry:
- pale sand plane
- 3–4 umbrellas
- 4–6 chairs
- simple sandcastle
- ball
- beach towels as flat colored meshes
- family/child NPCs.

Purpose:
- blue encounter
- green encounter
- hardest crowd pressure
- strong visual contrast with boardwalk.

## Zone E — Pier / Marina

Long narrow platform into sea.

Geometry:
- wooden boxes/planks
- railings
- 1–2 simple boats
- posts
- ropes represented as simple cylinders/curves if cheap
- lifebuoy
- bench.

Purpose:
- red encounter
- best high-speed dive lane
- late-game Prism spawn area.

## Zone F — Low Seaside Houses

3–5 simple buildings, maximum two floors.

No interiors.

Purpose:
- establish "small coastal town" rather than isolated arena
- provide roofs/obstacles/perches
- house the central nest on one accessible roof.

Palette distribution:
- chalk white
- faded blue
- faded coral
- sage
- one terracotta roof
- one slate/dark-gray roof.

## Nest

Location:
- central roof ~7–9 m above ground.

Required:
- twig/stick nest shape
- a few scraps / shiny junk props
- Area3D that instantly fills stamina
- subtle rustle feedback.

Do not require an animation to rest.

## Sea boundary

P1 only.

No visible wall.

Past intended boundary, increasing headwind opposes outward movement.

A fully upgraded/full-stamina gull may cross the strongest section.

Far threshold:
- music fades
- wind/sea only
- after several seconds, soft white fade
- teleport to nest
- optional blue bottle cap appears in nest
- optional hidden `SOMEWHERE ELSE` achievement.

If this threatens schedule, omit it and use a soft invisible return volume far offshore.

## Background dressing

Use cheap silhouettes:
- distant low-poly coastline
- 3–6 blocky far buildings
- tiny static boats
- distant lighthouse-like vertical shape if desired.

These are visual only and should have no expensive collision.
