# 37 - P1a: the hero gull (art director spec)

The gull is on screen 100 % of the time. It must be the most charming object in the game. Think: a plump, slightly cheeky clay toy gull, lit by golden light.

## Design
**Body:** egg-shaped, chubby, big soft chest, slightly raised tail end. Smooth shading, bevelled, no facets.
**Head:** a little large for the body; soft round skull, brow ridge hint; a **big dark glossy eye** with a tiny cream highlight dot (separate tiny vertex-coloured sphere or colour patch) and a soft lid line that gives a mildly mischievous look. Subtle cheek shape.
**Beak:** sturdy, slightly hooked, butter-yellow (F5B53A), with a **red-coral dot** (E2503A) near the lower tip; bevelled, with a visible nostril groove; two parts (upper/lower) only if the existing beak_socket/head_lunge animation needs it.
**Wings (the hero of flight shots):** three segments per wing matching the existing shoulder/elbow pivots: upper arm (soft covert mass), forearm, hand with **layered primary feathers**: 5-6 rounded feather plates fanned slightly, charcoal tips (3A3D48) fading to lilac-grey (B7B2C9) and then to the cream body colour. Upper surface mantle soft grey-blue (B9C3D1); underside cream with lilac AO. Wings have visible thickness (bevelled), and a readable curved silhouette at 60 m.
**Tail:** fan of 5 rounded feathers, charcoal tip band.
**Legs/feet:** slim coral-orange (F28A52), small webbed feet, soft toes; they already tuck in flight via `legs`.
**Palette:** body cream F7F1E6; belly/underside lilac shadow D8CFE6 baked into vertex colour; back/wings grey-blue B9C3D1; tips charcoal 3A3D48; beak F5B53A + dot E2503A; legs F28A52. Keep it clear against sky (blue/orange) and ground (peach/green): the **underside lilac + charcoal wing tips + slight rim** must separate it.

## Technical
- <= 4,000 tris for the whole gull, <= 12 mesh parts (one per pivot / feather group), ONE shared soft-toon material with vertex colour. Draw calls per gull must be <= the current procedural gull (count it).
- Keep every existing pivot/animation in `gull_visual.gd` (shoulder, elbow, head, beak_socket, legs, tail, wear slots, comet trail, plain/bro_style variants). Add an `_build_authored()` path that attaches the authored part meshes under the existing pivots, falls back to the procedural gull if the GLB(s) are missing or invalid. The same mesh is used for player, rival/friend gulls and the 2.3x big brother (colours may be tinted through existing material params; keep accessories attached).
- Modelling in Blender: build from rounded primitives + subdivision + bevel + (optional) skin/metaball for the body; bake AO + gradient to vertex colour; export parts as separate GLBs or one GLB with named nodes; follow `docs/ART_MANIFEST.md` pivot contract. Generator script `tools/blender/hero_gull.py` (seedless, reproducible).
- Origins: each part's origin at its pivot so the code can attach it with zero offset where possible.

## Review you must do (look at every image)
1. Blender turntable (5 views) + a "pose sheet": wings up, wings level, wings down/flare, perched with legs out. Check silhouette at 128 px as well.
2. In game (use `--cams`): soaring side view, 3/4 rear view (the usual chase camera), landing flare, perched on the roof, the snatch close-up with a fry in the beak, and the visual-novel portrait. In **noon, golden-hour and dusk** lighting. At 3 m, 15 m, 60 m.
3. Compare with the same shots from `shots/` (before). Make a `art_src/p1a/before_after.png` sheet.
4. List defects honestly (lumpy form, muddy colour, weak silhouette, z-fighting, flipped normals, floating parts, shader washing out). Fix them before you report; at most 4 internal iterations. Do not report "looks great".

Do not start the tree/house/person: that is P1b.
