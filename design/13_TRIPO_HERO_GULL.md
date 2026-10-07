# 13 — TRIPO HERO GULL HANDOFF

This is the only 3D asset worth generating externally before core completion.

## Desired look

A charming stylized low-poly gull, readable at third-person gameplay distance.

Not photorealistic.

Avoid individual feather geometry.

The silhouette matters more than surface detail.

## Primary prompt

> Stylized low-poly herring gull game character, clean faceted geometry, white body and head, cool gray wings with dark wing tips, yellow beak and legs, clear readable silhouette, slightly charming proportions, wings spread in neutral glide pose, symmetric, game-ready, no environment, no accessories, simple clean materials.

## What to reject

Reject generations with:
- deformed asymmetric wings
- merged wing/body silhouette
- strange extra legs
- unreadable beak
- excessively realistic feathers
- highly dense detail that will not be visible in play
- complex background geometry fused to model.

## Rig path

Tripo's current official animation rig documentation supports non-humanoid `avian` rig type and GLB output.

Recommended:
1. use Rig Check first
2. only pay/use auto-rig if compatibility is good
3. use `avian`
4. output GLB.

## Critical fallback rule

If rigging does not work quickly, stop.

Do NOT spend the jam repairing weights/bones.

Import the static GLB as the body and animate separate procedural wing meshes, or use the entirely procedural fallback gull.

The game is designed to survive this.

## Orientation target

Preferred local convention after import:
- forward = -Z if practical in Godot convention
- up = +Y
- center/pivot near body center.

If model orientation differs, fix with a wrapper `VisualRoot` transform before opening Blender.
