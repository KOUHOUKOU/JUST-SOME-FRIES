> ⚠️ **被设计 v2 部分取代。** 现行规则以 `docs/18_DESIGN_V2_AUTHORITATIVE.md` 与 `docs/19_IMPLEMENTATION_PLAN_V2.md` 为准;本文件中与之冲突的条款(飞行/体力/巢相关、时长、结构细节以 v2 为准;主题与"普通薯条"核心不变)**作废**,其余内容仍可参考。

# 00 — MASTER SPECIFICATION

## Title

**JUST SOME FRIES**

## High concept

A short 3D game about being a gull who only wanted a few fries. The player begins with a tiny, understandable appetite, then becomes trained by the game's own reward language to chase increasingly bright and useful fries. Every special fry genuinely improves the gull. At maximum progression the gull is more capable than ever — and is still hungry.

The true ending is caused by eating an utterly ordinary fry that has been beside the first tutorial encounter since the beginning.

The point is never explained in dialogue. The player should understand it through reinterpreting their own prior behavior.

## Design pillars

1. **Being a gull is fun.** Flying, diving and yelling must have intrinsic pleasure.
2. **Stealing has readable skill.** Failure comes from speed, angle, timing and escape, not arbitrary RNG.
3. **Upgrades are honest.** Every upgrade really improves the player.
4. **The game trains attention.** Color, glow, objectives and progression make spectacle easier to see and the ordinary harder to notice.
5. **The ending removes systems instead of adding explanation.**

## Expected length

- Skilled/returning player: 5–10 min.
- Typical first run: 12–20 min.
- Explorer / Prism grinder: 20–30+ min.
- Early Bird route: under 1 min is possible.

## Emotional arc

**amusement → competence → greed → power → confusion → observation → quiet satisfaction**

## Structure

### Act I — JUST THREE FRIES

Objective begins:

`JUST THREE FRIES.`

`0 / 3`

Three increasingly complete tutorial thefts unlock:

`GULL SENSE 1 / 3`

`GULL SENSE 2 / 3`

`GULL SENSE 3 / 3`

After the third:

`GULL SENSE COMPLETE`

The four special fries reveal themselves across the map.

Counter becomes:

`3 / 7`

### Act II — Four special fries

Order is free.

- Red — Tailwind Fry — speed/acceleration.
- Blue — Deep Breath Fry — stamina maximum.
- Yellow — Second Wind Fry — stamina recovery.
- Green — Steady Beak Fry — snatch timing window.

When all are collected:

`7 / 7`

Hold ~1.8 s.

Then:

`STILL HUNGRY.`

The objective counter disappears.

### Act III — Prism phase

Prism Fries begin appearing at existing food locations. They have no total and are not required collectibles.

Each gives a small all-stat increase up to a soft cap.

At thresholds of 3/6/9/12 Prism Fries, the Ordinary Fry becomes increasingly perceptible, but never receives an arrow or map marker.

### Act IV — FRY

The player eventually notices the Ordinary Fry near the first café table.

On eating it:

`FRY`

*Tastes good.*

No stat effect. No triumph sting. HUD fades. Music fades. Ambient sea remains. Control remains available.

## Early ending

The Ordinary Fry is edible from second zero. If the player notices it before Gull Sense 3/3, the same ending happens immediately and hidden achievement `EARLY BIRD` may be awarded.

## Forbidden interpretations

Do not add text such as:

- "True happiness is in simple things."
- "Greed is bad."
- "You had enough all along."
- "Good ending."

Do not make special upgrades fake or harmful. The deeper tension is that everything the player gained was useful — but useful mainly for gaining more.
