> ⚠️ **被设计 v2 部分取代。** 现行规则以 `docs/18_DESIGN_V2_AUTHORITATIVE.md` 与 `docs/19_IMPLEMENTATION_PLAN_V2.md` 为准;本文件中与之冲突的条款(整份被 19 号取代)**作废**,其余内容仍可参考。

# 08 — IMPLEMENTATION PLAN, MILESTONES, AND CUT ORDER

The coding agent should execute this file sequentially.

## Milestone 0 — Bootstrap

### Required reading
- `AGENTS.md`
- `docs/07_TECH_ARCHITECTURE.md`
- `docs/16_CONSTRUCTION_COORDINATES_INPUT_COLLISION.md`

### Work
- Create Godot 4.6.3 project under `game/`.
- Configure input actions.
- Create baseline directories/scenes.
- Create `Main` scene.
- Add a simple gray floor/sea/horizon setup.
- Ensure project runs with no external assets.

### Acceptance
- Project opens and runs without errors.
- A placeholder PlayerGull node exists.

---

# Milestone 1 — THE BIRD MOVES

### Required reading
- `docs/01_GAMEPLAY_AND_NUMBERS.md`
- `docs/04_UI_UX_CAMERA_FEEDBACK.md`
- player/camera portions of `docs/07_TECH_ARCHITECTURE.md`
- `docs/16_CONSTRUCTION_COORDINATES_INPUT_COLLISION.md`

### Work
Implement:
- flight
- mouse steering
- W acceleration / S brake
- A/D banking
- flap
- dash
- stamina
- landing / ground mode
- nest instant refill volume
- chase camera
- FOV and distance speed feedback
- fallback gull visual with wings if hero model absent.

### Acceptance test
Spend at least 60 seconds flying an empty gray space.

Must be:
- controllable
- forgiving
- no accidental death
- no severe camera nausea
- acceleration perceptible
- dash satisfying
- landing/takeoff possible.

Do not proceed if basic flight feels broken.

---

# Milestone 2 — ONE FRY IS FUN

### Required reading
- `docs/01_GAMEPLAY_AND_NUMBERS.md`
- snatch/NPC sections of `docs/07_TECH_ARCHITECTURE.md`
- `docs/16_CONSTRUCTION_COORDINATES_INPUT_COLLISION.md`

### Work
Create:
- one gray table
- one Elder NPC
- one tutorial fry
- awareness
- valid-speed detection
- timing ring
- successful grab
- BeakSocket attachment
- telegraphed swat
- dodge
- hit/drop/retry
- minimal sound hooks.

### Acceptance
Steal the same fry successfully and unsuccessfully several times.

The player must clearly understand:
- why an attempt was too slow
- when to press E
- whether the NPC noticed them
- why they were hit
- how to try again.

No random failure.

---

# Milestone 3 — COMPLETE GRAYBOX GAME

### Required reading
- `docs/00_MASTER_SPEC.md`
- `docs/02_PROGRESSION_ENDING_COPY.md`
- `docs/03_MAP_WORLD_LAYOUT.md`
- `docs/01_GAMEPLAY_AND_NUMBERS.md`
- `docs/16_CONSTRUCTION_COORDINATES_INPUT_COLLISION.md`

### Work
Build simple graybox version of full 80×60 world.

Add:
- Tutorial encounters 1–3
- Gull Sense 1/3 → 3/3
- colored reveal
- Red/Blue/Yellow/Green encounters
- upgrade effects
- 3/7 → 7/7 progression
- Still Hungry transition
- Prism Fries and soft cap
- Ordinary Fry present from startup
- early ending
- Prism convergence halo thresholds
- normal ending.

### Acceptance
A fresh player can go from launch to ending with only gray geometry.

Also test:
- eat Ordinary Fry immediately → ending works
- collect 7/7 → Still Hungry works
- Prism thresholds make Ordinary Fry progressively more visible
- game does not require Prism Fries to end.

This is the first **submission-safe gameplay build**.

DO NOT start major art polish before this passes.

---

# Milestone 4 — HUD AND UX

### Required reading
- `docs/04_UI_UX_CAMERA_FEEDBACK.md`
- `docs/02_PROGRESSION_ENDING_COPY.md`

### Work
Add:
- objective top-center
- stamina bar
- dash cooldown
- 4 special fry slots
- central reticle
- timing ring polish
- reward cards
- Still Hungry presentation
- ending presentation
- main menu
- pause menu
- controls page.

P1 if time:
- full TAB Gull Sense screen.

### Acceptance
A first-time player can understand controls/progression without developer explanation.

---

# Milestone 5 — WORLD ART PASS

### Required reading
- `docs/03_MAP_WORLD_LAYOUT.md`
- `docs/05_ART_ASSET_PIPELINE.md`

### Work
Replace gray blocks with coherent low-poly world:
- café
- boardwalk
- kiosk
- beach
- pier
- houses
- nest
- water
- golden-hour light
- final simple materials.

Integrate hero gull if available.

Create modular NPC visual variants.

### Acceptance
Screenshots should clearly read as one intentional seaside game rather than a test map.

---

# Milestone 6 — AUDIO AND JUICE

### Required reading
- `docs/06_AUDIO_MUSIC.md`
- reward sections of `docs/04_UI_UX_CAMERA_FEEDBACK.md`

### Work
Wire final or placeholder:
- waves
- wind
- gull sounds
- NPC reactions
- snatch sounds
- reward stings
- music state changes
- FOV pulse
- particles
- Gull Sense reveal
- Ordinary Fry contrast.

### Acceptance
Special Fry pickup feels noticeably gratifying.

Ordinary Fry ending feels noticeably quieter than every upgrade.

---

# Milestone 7 — P1 POLISH

Only if all P0 tests pass.

Possible order:
1. TAB full detail/map screen
2. carryable objects + nest junk
3. achievements
4. deep-sea easter egg
5. extra NPC movement
6. decorative props.

---

# Final milestone — EXPORT AND QA

### Required reading
- `docs/09_QA_ACCEPTANCE.md`
- `docs/10_DELIVERY_SUBMISSION.md`

### Work
- test from clean launch
- fix errors
- Windows export
- verify executable starts independently
- capture required screenshots/video only after final build is stable.

---

# CUT ORDER IF SCHEDULE IS IN DANGER

Remove in exactly this order:

1. deep-sea easter egg
2. achievements
3. carryable objects
4. moving NPC paths
5. additional decorative props
6. full TAB schematic map (keep a simple stats overlay if desired)
7. secondary particle flourishes.

Never cut:
- enjoyable flight
- snatch speed requirement
- timing ring
- swat/escape
- 3 tutorial fries
- 4 upgrades
- Still Hungry
- Prism phase
- Ordinary Fry
- quiet ending
- basic sound feedback.
