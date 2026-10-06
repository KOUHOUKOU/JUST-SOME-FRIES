> ⚠️ **被设计 v2 部分取代。** 现行规则以 `docs/18_DESIGN_V2_AUTHORITATIVE.md` 与 `docs/19_IMPLEMENTATION_PLAN_V2.md` 为准;本文件中与之冲突的条款(飞行数值、体力、冲刺、扇翅、时机环、NPC 档案、升级数值、遭遇列表、无失败惩罚的规定)**作废**,其余内容仍可参考。

# 01 — GAMEPLAY, CONTROLS, AND NUMBERS

## Core theft loop

Every fry encounter uses exactly:

**DIVE → LOCK → SNATCH → BREAK**

There are no unrelated popup minigames.

## Controls

| Input | Action |
|---|---|
| Mouse | steer / pitch / yaw |
| W | accelerate toward cruise speed |
| S | air brake / slow glide |
| A / D | bank + strengthen turn |
| Space | flap / upward impulse |
| Left Shift | dash |
| E | snatch / interact / eat |
| F | squawk |
| TAB | Gull Sense screen |
| Esc | pause |

Grounded movement uses WASD. Space takes off.

## Flight target

Accessible arcade flight, not simulation. The gull should feel closer to a forgiving small aircraft with bird-like gestures.

### Starting tuning values

- passive forward speed: 6.5 m/s
- W cruise target: 10.5 m/s
- normal dive cap: 14 m/s
- minimum speed to initiate snatch: 10.5 m/s
- dash peak: ~17 m/s
- forward acceleration: ~6.5 m/s²
- pitch limit up: ~+35°
- pitch limit down: ~−60°
- visual bank: clamp roughly ±45°

These values may be adjusted after direct playtesting. Preserve the relationships and feel, not the exact decimals.

## Flap

- input: Space
- cost: 10 stamina
- cooldown: ~0.25 s
- effect: short upward impulse + slight speed support
- unavailable below 20 stamina
- must visibly flap wings or fallback wing nodes

## Dash

- input: Left Shift
- cost: 18 stamina
- cooldown: ~1.8 s
- immediate forward acceleration
- short wind streaks
- FOV punch
- stronger wing tuck
- unavailable below 20 stamina

Dash is useful but not mandatory for every theft.

## Stamina

Base max: 100.

Blue upgrade max: 140.

Airborne recovery after ~1.5 s without flap/dash:
- base: 1/s
- yellow upgrade: 2.5/s

Ground recovery:
- base: 10/s
- yellow upgrade: 16/s

Nest:
- instant full restoration.

Below 20%:
- flap unavailable
- dash unavailable
- stamina HUD pulses gently
- basic flight speed is NOT reduced
- no HP loss
- no death

## Landing

If speed is low and a valid floor is nearby, allow entering `GROUNDED`.

Ground speed: ~2.2 m/s.

No complex walk animation required. A body bob is acceptable.

Ordinary Fry should be easiest to notice while slow or grounded.

## DIVE stage

Target may become interactable only if:

- it lies in a forward interaction cone,
- distance is approximately ≤2.2 m,
- current speed ≥10.5 m/s.

Below speed, reticle may show gray readiness and tiny `TOO SLOW` feedback.

Approaching from behind/side should reduce NPC awareness accumulation.

## LOCK stage

Once fast and in range, show a compact circular timing ring around the central reticle.

Nominal duration: ~0.7 s.

A moving indicator crosses a green success region.

Press E inside green: grab succeeds.

Outside green: encounter misses; NPC protects food; ~1 sec reset.

The game world should continue moving. Do not pause for this challenge.

## BREAK stage

After successful grab, the fry attaches to `BeakSocket`.

If NPC awareness was low, clean escape.

If awareness was high, NPC performs a telegraphed swat with an Area3D hit volume.

Player physically steers out of it.

If hit:
- fry drops / returns to encounter after ~2–3 s
- −25 stamina
- short gull spin/rebound
- comic vocal reaction
- no death

## NPC difficulty archetypes

| Archetype | Awareness | Vision | Timing window | Swat | Use |
|---|---|---|---|---|---|
| Elder | slow | narrow | generous | slow | tutorials |
| Adult | normal | normal | medium | medium | standard |
| Child | fast | wide | small | fast | hardest special |

Keep difficulty deterministic and readable, not random failure percentages.

## NPC awareness model

Recommended implementation:

- distance check
- facing dot product
- optional raycast for line of sight
- awareness value 0..1

States:

`IDLE → SUSPICIOUS → ALERT → SWAT`

Medium awareness:
- head turns toward gull.

High awareness:
- small `!` feedback.

Do not show a numeric meter.

## Seven required fry encounters

### Tutorial 1
- Café terrace.
- Elderly man.
- Very easy.
- Teaches speed + E timing.
- Ordinary Fry lies below/near the same table.

### Tutorial 2
- Bench / café edge.
- Elderly woman.
- Teaches approach angle / behind awareness.

### Tutorial 3
- Fast-food seating.
- Adult.
- Teaches full grab + evade.
- Completing it unlocks Gull Sense 3/3.

### Red — Tailwind Fry
- Pier/marina.
- Adult with takeaway fries.
- Open high-speed approach.

### Blue — Deep Breath Fry
- Beach family area.
- Adult near umbrella/chair.
- Obstacles encourage route planning.

### Yellow — Second Wind Fry
- Busy boardwalk/kiosk.
- Adult surrounded by visual distractions.

### Green — Steady Beak Fry
- Beach play area.
- Child.
- Highest standard difficulty.

## Upgrade values

### Red / Tailwind
- forward acceleration ×1.20
- dive acceleration ×1.20
- max normal flight speed +2 m/s

### Blue / Deep Breath
- stamina max 100 → 140

### Yellow / Second Wind
- airborne recovery 1 → 2.5/s
- grounded recovery 10 → 16/s

### Green / Steady Beak
- timing success region ×1.45

## Prism Fries

Start after 7/7.

Each:

`global_prism_multiplier += 0.03`

Soft cap: 1.30.

Apply softly to speed, acceleration, stamina, recovery and timing window.

After cap, Prism Fries can still be eaten but do not further change mechanics.

Do not show the cap.
