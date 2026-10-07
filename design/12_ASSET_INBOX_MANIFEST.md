# 12 — ASSET INBOX MANIFEST

The game must run even when all optional external assets are missing.

## Hero 3D model

Preferred path:

`game/assets/models/hero_gull.glb`

If absent:
- use procedural fallback gull.

If present:
- import under `VisualRoot`
- normalize orientation/scale locally
- never make player collision/movement depend on its skeleton.

## Optional audio paths

Suggested convention:

```text
game/assets/audio/music/main_loop.ogg
game/assets/audio/ambience/ocean_loop.ogg
game/assets/audio/ambience/wind_loop.ogg
game/assets/audio/sfx/gull_call_01.ogg
game/assets/audio/sfx/gull_call_02.ogg
game/assets/audio/sfx/gull_call_03.ogg
game/assets/audio/sfx/gull_hit.ogg
game/assets/audio/sfx/gull_triumph.ogg
game/assets/audio/sfx/flap.ogg
game/assets/audio/sfx/dash.ogg
game/assets/audio/sfx/snatch.ogg
game/assets/audio/sfx/timing_success.ogg
game/assets/audio/sfx/timing_fail.ogg
game/assets/audio/sfx/fry_crunch.ogg
game/assets/audio/sfx/npc_elder.ogg
game/assets/audio/sfx/npc_adult.ogg
game/assets/audio/sfx/npc_child.ogg
game/assets/audio/sfx/upgrade_sting.ogg
game/assets/audio/sfx/prism_chime.ogg
```

Agent behavior if absent:
- no crashes
- use optional preload/load checks or placeholders
- continue building.

## No required texture pack

Environment should not require externally supplied textures.

Use flat materials and primitive geometry.

## No required 2D illustration pack

HUD can be constructed from:
- Control nodes
- Label
- ColorRect
- TextureRect only if a simple generated/vector icon is locally available
- procedural circles/bars.

Fry/gull icons can initially be simple colored shapes or text glyphs.

Do not stop implementation waiting for final icon art.
