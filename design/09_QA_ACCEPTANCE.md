> ⚠️ **被设计 v2 部分取代。** 现行规则以 `docs/18_DESIGN_V2_AUTHORITATIVE.md` 与 `docs/19_IMPLEMENTATION_PLAN_V2.md` 为准;本文件中与之冲突的条款(凡涉及巢穴、旧速度、无失败惩罚的验收项;新验收见 18 号 §15 与 19 号各里程碑)**作废**,其余内容仍可参考。

# 09 — QA AND ACCEPTANCE TESTS

Run these before declaring the build complete.

## A. Boot and menu

- Game launches without editor-only dependencies.
- Main menu appears.
- PLAY starts a clean run.
- HOW TO FLY is readable.
- Esc pause works.
- Restart Run resets progression and Ordinary Fry state.

## B. Flight

- Mouse steering works at low and high speed.
- W accelerates smoothly rather than instantly snapping to max speed.
- S noticeably brakes.
- A/D bank without losing control.
- Space flap consumes stamina and adds height.
- Shift dash consumes stamina and has cooldown.
- At <20 stamina, flap/dash disable but normal movement remains usable.
- Nest instantly restores full stamina.
- Collision does not kill or permanently trap gull.
- Landing and takeoff are possible.
- Camera does not pass through major walls in ordinary play.

## C. Snatch loop

For each NPC difficulty:
- below-speed approach cannot steal
- valid-speed approach triggers timing opportunity
- good E timing grabs fry
- bad timing fails visibly
- low-awareness approach rewards stealth/angle
- high-awareness successful grab can trigger swat
- player can physically evade
- hit drops fry and costs stamina
- encounter becomes retryable.

## D. Tutorial progression

- Tutorial 1 increments Gull Sense to 1/3.
- Tutorial 2 increments to 2/3.
- Tutorial 3 increments to 3/3.
- At 3/3, four special fries become visible/readable.
- Objective becomes 3/7.

## E. Upgrades

- Red produces perceivable acceleration/speed improvement.
- Blue increases max stamina to intended value.
- Yellow improves recovery.
- Green clearly enlarges timing success window.
- Each special pickup triggers correct card/slot and only once.
- Any collection order works.

## F. 7/7 transition

- 7/7 displays.
- ~1.8 s hold feels intentional.
- Still Hungry appears.
- objective counter disappears.
- Prism Fries begin.
- music changes correctly.

## G. Prism

- first Prism gives large explanation.
- later Prism gives smaller feedback.
- multiplier increases until cap.
- after cap, game remains stable.
- no required collectible count appears.

## H. Ordinary Fry

### Immediate route
- present from game start
- can be eaten before tutorial fry 1
- triggers ending correctly.

### Midgame route
- can be eaten before 7/7
- triggers ending correctly.

### Prism convergence
- 0–2 Prism: no halo
- 3: faint near halo
- 6: stronger/pulsing
- 9: more noticeable
- 12: directional chime behavior works without becoming a quest arrow.

### Ending
- only crunch + restrained response
- FRY / Tastes good text
- system HUD fades
- music fades
- ambience remains
- player control remains.

## I. Visual logic

- Ordinary Fry visually resembles ordinary background food.
- Special Fries are clearly color-coded.
- Prism Fries read differently from special fries.
- first café table and Ordinary Fry are physically readable.
- nest is easy to relocate.
- all major zones visually distinct.

## J. Audio

- no missing-audio errors crash game
- wind responds to speed
- F yell works with cooldown
- NPC reaction sounds are not painfully repetitive
- special pickup sting is stronger than tutorial pickup
- Ordinary Fry ending has no triumphant sting.

## K. Performance

- stable playable framerate on target machine
- no obvious memory runaway after repeated retries / Prism spawns
- particles are bounded
- NPCs do not create unnecessary heavy processing.

## L. Softlock tests

Try intentionally:
- hit a wall repeatedly
- run stamina to zero-ish offshore
- fail same fry 10 times
- grab then collide
- restart during an encounter
- open/close TAB repeatedly
- eat Ordinary Fry while UI animation is playing
- collect final colored fry while moving very fast.

No permanent stuck state is acceptable.
