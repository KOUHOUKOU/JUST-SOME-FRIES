> ⚠️ **被设计 v2 部分取代。** 现行规则以 `docs/18_DESIGN_V2_AUTHORITATIVE.md` 与 `docs/19_IMPLEMENTATION_PLAN_V2.md` 为准;本文件中与之冲突的条款(巢穴节点、飞行伪代码、Snatch 与 NPC 结构(v2 新增载体/WARY/警惕/注意力节奏);普通薯条收敛光晕阈值仍有效)**作废**,其余内容仍可参考。

# 07 — TECHNICAL ARCHITECTURE

## Engine

Godot 4.6.3 stable.

GDScript.

Primary target: Windows desktop.

## Suggested repository structure

```text
game/
  project.godot
  scenes/
    main.tscn
    player/
      player_gull.tscn
    npc/
      npc_base.tscn
    fries/
      fry_base.tscn
    world/
      world.tscn
    ui/
      hud.tscn
      gull_sense.tscn
  scripts/
    player/
      gull_controller.gd
      gull_camera.gd
      stamina.gd
    interaction/
      snatch_controller.gd
      carryable.gd
    npc/
      npc_controller.gd
      npc_reaction.gd
    fries/
      fry_base.gd
      special_fry.gd
      ordinary_fry.gd
      fry_manager.gd
    systems/
      game_state.gd
      progression_manager.gd
      audio_manager.gd
      achievement_manager.gd
    ui/
      hud.gd
      snatch_ui.gd
      gull_sense_ui.gd
  assets/
    models/
      hero_gull.glb   # optional; fallback required
    audio/
      music/
      ambience/
      sfx/
    materials/
  shaders/
```

Do not create architecture layers that are not needed by this project.

## Main scene

Recommended tree:

```text
Main
├── World
│   ├── Environment
│   ├── MapGeometry
│   ├── EncounterRoot
│   ├── NPCs
│   ├── Fries
│   └── Nest
├── PlayerGull
│   ├── Collision
│   ├── VisualRoot
│   ├── BeakSocket
│   ├── CameraRig
│   │   └── SpringArm3D
│   │       └── Camera3D
│   └── Audio
├── GameSystems
│   ├── ProgressionManager
│   ├── FryManager
│   ├── AchievementManager (P1)
│   └── AudioManager
└── UI
    ├── HUD
    ├── SnatchUI
    ├── GullSenseScreen
    ├── ToastLayer
    └── PauseMenu
```

## Global progression state

Use an Autoload or clearly centralized manager.

Enum/state concept:

```text
TUTORIAL
SPECIAL_HUNT
STILL_HUNGRY
ENDED
```

Core variables:

```text
gull_sense_count: int
special_fries_collected: int
prism_count: int
ordinary_fry_eaten: bool
has_red: bool
has_blue: bool
has_yellow: bool
has_green: bool
global_prism_multiplier: float
```

Prefer signals to UI polling.

Examples:
- `gull_sense_changed(count)`
- `special_fry_collected(type)`
- `progress_changed(current, target)`
- `still_hungry_started()`
- `prism_count_changed(count)`
- `ordinary_fry_eaten()`
- `stamina_changed(value, max_value)`
- `dash_cooldown_changed(ratio)`

## Player controller

Recommended root:
- `CharacterBody3D`.

Separate:
- physics movement
- visual banking/wing animation
- camera feedback.

Do not rotate the collision body with every visual bank if that produces unstable physics. Visual root may roll independently.

## Flight movement approach

Use smoothed desired velocity rather than rigidbody aerodynamic simulation.

Pseudo-process:

1. Read camera/mouse steering target.
2. Determine desired forward vector.
3. Apply acceleration toward target forward speed.
4. Add flap vertical impulse when allowed.
5. Apply dive/downward contribution from pitch.
6. Apply dash impulse/burst if allowed.
7. Run `move_and_slide()`.
8. Smooth visual orientation/bank separately.

No stall, lift equations, or advanced aerodynamics.

## Camera

SpringArm3D for collision.

Smooth FOV/distance based on normalized speed and dash state.

Use Tween or lerp rather than spawning many Tweens every frame.

## Snatch architecture

Player-owned `SnatchController` finds eligible target via:
- area/cone query and/or raycast
- distance
- forward dot
- speed threshold.

Encounter-owned fry exposes:
- availability
- owner NPC
- snatch difficulty
- on_grab / on_drop / on_consumed.

Timing UI should be driven by encounter state, not own game logic.

## NPC awareness

No NavMesh needed.

Each NPC has:
- facing forward vector
- view distance
- view dot threshold
- awareness growth/decay
- reaction profile.

For stationary NPCs this is enough.

If P1 moving NPCs exist, use Path3D or deterministic point-to-point interpolation.

## Swat

Use an `Area3D` enabled only for the active strike interval.

Telegraph by rotating arm first.

The area should be forgiving and visibly match the arm motion.

## Fry system

Use one base class/data model.

Types:
- tutorial
- red
- blue
- yellow
- green
- prism
- ordinary.

Special visual treatment can be data-driven.

Avoid seven bespoke scripts.

## Ordinary Fry convergence

Visibility state depends on `prism_count` and player distance.

Thresholds:
- 0–2: no halo
- 3+: faint halo ≤10 m
- 6+: stronger ≤18 m + slow pulse
- 9+: warm outline/glint ≤25 m
- 12+: same plus directional chime condition ≤35 m, ~25° facing, cooldown ~15 s.

Do not implement a map marker.

## NPC animation

Prefer AnimationPlayer for reusable pose clips or Tween for simple reactions.

No skeletal dependency.

## Highlight implementation

Avoid sophisticated mesh outline post-processing.

Special Fries:
- emissive material + billboard/halo + optional GPUParticles3D.

Ordinary Fry:
- subtle warm halo whose alpha/range changes by convergence level.

## TAB slow time

If implemented:
- avoid breaking UI input by relying blindly on global timescale.
- set UI to process while paused/slow as appropriate.
- target effective world speed ~0.12.

Simpler fallback: pause movement and animate a subtle background shader. Function over flourish.

## Save system

None required.

No run persistence.

Achievements may be session-only.

## Performance

Target 60 FPS on normal modern laptop.

Avoid:
- many dynamic lights
- high-poly crowds
- expensive transparent overdraw
- huge texture sets
- realtime GI dependency.

One directional sun + simple environment.
