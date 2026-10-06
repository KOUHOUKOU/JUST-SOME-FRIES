> ⚠️ **被设计 v2 部分取代。** 现行规则以 `docs/18_DESIGN_V2_AUTHORITATIVE.md` 与 `docs/19_IMPLEMENTATION_PLAN_V2.md` 为准;本文件中与之冲突的条款(镜头距离/FOV 档位、Gull Sense 行为、抢夺奖励流程(新增特写慢镜头))**作废**,其余内容仍可参考。

# 04 — UI, UX, CAMERA, AND GAME FEEL

## HUD philosophy

The screen should remain visually clean. Information comes from the gull, world and sound whenever possible.

## Top center

Act I:

`JUST THREE FRIES.`

`0 / 3` → `3 / 3`

Act II:

`3 / 7` → `7 / 7`

At completion:

`7 / 7`

hold ~1.8 s → `STILL HUNGRY.` → fade away.

No permanent objective after this.

## Top right — Gull status

Small gull-head silhouette/icon.

Below or beside:
- horizontal stamina bar
- radial dash cooldown.

No numeric stamina percentage by default.

Low stamina:
- gentle pulse
- no giant warning banner.

## Special Fry slots

To the left of gull status.

Hidden until Gull Sense completes.

Then show four slots initially as `???` or muted fry silhouettes.

Upon collection:
- red icon
- blue icon
- yellow icon
- green icon.

Ordinary Fry never occupies one of these slots.

## Central reticle

Default:
- tiny dot or four minimal brackets.

Stealable fry in forward cone:
- brackets appear.

Too slow:
- gray.

Speed valid:
- warm/gold.

Snatch range:
- circular timing UI overlays reticle.

Clear immediately after encounter.

## Timing ring

Keep screen-space size small enough that player still sees flight path.

Ring animation:
- outer/moving element converges or rotates
- clearly marked green success region
- success/fail color flash under 0.2 s.

Do not pause the game.

## Gull Sense screen — TAB

P0 can be a simple overlay; polish is P1.

Preferred behavior:
- set game time scale ~0.12
- world still visibly moves
- translucent dark overlay
- music lower / optional low-pass.

### Left panel — schematic map

Hand-authored simple 2D diagram, not a realtime rendered minimap.

Labels/icons:
- Café
- Boardwalk
- Kiosk
- Beach
- Pier
- Nest.

Player icon position is derived from normalized world X/Z.

After Gull Sense 3/3:
- uncollected special fries appear as colored pulses.

Never show:
- Ordinary Fry
- Prism Fries.

### Right panel — status

Four bars:
- SPEED
- STAMINA
- RECOVERY
- FOCUS.

Special Fry cards:
- unobtained: `???`
- obtained: name, effect, flavor line.

After ending only, below the system rather than inside it:

`FRY`

`No effect.`

`Tastes good.`

## Camera

Use `SpringArm3D` or equivalent collision-safe third-person rig.

Base distance: ~4.2 m.

High speed: ~5.2 m.

Base FOV: ~68°.

High cruise: ~77°.

Dash peak: ~84°.

Smooth interpolation ~0.15–0.25 s.

Visual camera roll: 20–30% of bird visual roll.

No constant shake.

Micro-shake only on:
- successful snatch
- swat hit
- hard collision.

No strong motion blur.

## Speed feedback

Do not create a large speedometer.

Communicate speed through:
- FOV
- camera pullback
- wind loop volume/pitch
- subtle screen-edge streaks
- wing posture
- target readiness.

## Reward "juice" — tutorial fry

On successful escape:
- small white/gold burst
- short positive sound
- `GULL SENSE N / 3`
- brief icon pulse.

Third tutorial success:
- stronger pulse
- four colored signals fade into the world over ~1 s.

## Reward "juice" — Special Fry

Sequence target duration: ~1.0–1.3 s.

1. escape success confirmed
2. ~0.05–0.08 s micro-freeze / very brief slow-time impression
3. colored particle burst
4. FOV pulse outward
5. short upgrade sting
6. triumphant gull call
7. card appears with name/effect
8. relevant stat bar visibly extends
9. card shrinks/flies toward HUD slot.

Do not lock player control for long.

## Prism feedback

First:
- `PRISM FRY`
- `EVERYTHING ↑`
- rainbow pulse/chime.

Further:
- small rainbow ring + `ALL ↑`
- no large card interruption.

## Ordinary Fry contrast

On Ordinary Fry:

DO NOT use:
- freeze-frame
- particle burst
- FOV pulse
- upgrade sting
- stat bars
- rarity effect.

Use only:
- crisp crunch
- tiny satisfied gull vocal
- `FRY`
- `Tastes good.`

Then fade game-system UI and music.
