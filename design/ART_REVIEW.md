# ART_REVIEW - art director notes (newest first; fix open items first)

## Review 15 - S7 headland + build time (2026-10-11) - VERDICT: APPROVED
Headland now 12 m, wide layered rock base with rubble skirt and foam, grass cap with lighthouse and turbines: reads like the cover island from three cameras. 5-run cold island build median 1022 -> 600 ms, first 3D frame 1298 -> 1198 draw calls, 10/10 cameras fewer draws, 1,498 colliders and thermals fine, 24/24.
CARRIED: strata a bit regular, white house partly hidden, 3 turbines instead of 2 (kept for gameplay props), weak sea reflections.
Next: S4 final delivery (original-vs-final sheets, 40-60 s clip, local builds, report).

---

## Review 14 - S6 whole-island audit (2026-10-11) - VERDICT: island look APPROVED as a whole; two blockers go to S7
Seen: ranking 1-10, 22-camera pages iteration_4, before/after/cover summary. The island now has a coherent warm dusk look (string lights, striped umbrellas, bright houses, sand, palms, richer farm crops, brick/roof colour, distant hills). Triangles -5..-41 %, draw calls not higher at 25/25 cameras, 1,498 colliders unchanged, 24/24.
BLOCKERS
1. Rank 1 is still unfixed: the headland is a tall regular brown cone (cover: low, wide, layered rock island). 
2. Island build time regressed (916 -> 1115 ms median, warm 992 -> 1017): unacceptable for the web build; find and fix.
CARRIED: sea reflections, sparse props, flat light in some views (harbor, beach), A-pose people at 3 m.
Next: S7 (these two), then S4 (final before/after sheets + 40-60 s video + local builds).

---

## Review 13 - S5 people (2026-10-11) - VERDICT: APPROVED (style-consistent); next S6 whole-island audit + fixes
Seen: cast previous vs S5 vs cover, cafe 3 m before/after, VN portraits previous vs S5. People now share the gull's language: faceted flat shading, round head, black dot eyes, chunky limbs, mitten hands; 665-1,271 tris, 8 body draws (<=10 with props); all 13 modes, recolour, fallback pass; 11 camera views fewer draws; 24/24. Wing colour lightened, paving/planks warmed, headland widened.
CARRIED: stiff A-pose and hard shoulder/leg joints at 3 m; headland still tall; island build sample 597 -> 746 ms (do not claim a startup gain).
NEXT S6: audit the whole island against the cover, rank the worst spots, fix the top 6-8, then S4 (final before/after + video).

---

## Review 12 - S3b richness pass (2026-10-11) - VERDICT: APPROVED as the island look base; people + three polish items next (S5)
Seen: roof/pier/cafe/headland S3 vs S3b vs cover. Good: red-and-white lighthouse and a faceted brown rock base with a grass cap, stronger red roofs, richer greens, deeper blue water, warmer light, shadows cooler; all 17 camera views have fewer draw calls and tris, island build 978 -> 846 ms; 1,498 collision shapes unchanged; 24/24.
OPEN
1. **PEOPLE (the user's explicit complaint): crude, ugly.** Rebuild in the cover/gull style (see prompt_S5_people.txt): faceted flat-shaded chunky simple figures with dot eyes; cover people are small, simple and charming.
2. Headland/lighthouse island is a tall cone; the cover island is low and wide (wide rocky base, gentle slopes, small grass top). Reshape (decor only).
3. Cafe paving is dull grey-beige and the timber has weak contrast; warm it (sun-lit terracotta/sandy stone, golden planks) and add contrast.
4. Gull wings still mid-grey and heavy: lighten toward white/pale lilac-grey with dark tips (as the cover).
5. Remaining from S3: sea reflections weak; rock wall too regular.

---

## Review 11 - S3 kits + ground (2026-10-11) - VERDICT: progress, NOT yet cover quality; S3b richness pass (round 2 of max 3)
Seen: summary roof/pier/cafe/headland before/after/cover. Good: beach turned from dirt into warm sand, planks clearer, striped umbrellas, kit chairs/tables/plates/plants in the cafe, 1,898 tris of new GLBs, draw calls -154..-164, island build 1104 -> 978 ms, 24/24, CC0 manifest kept.
THE BIG GAP NOW IS COLOUR RICHNESS AND WARMTH. The cover is saturated, warm and contrasty (deep blue water with orange glitter, strong terracotta/coral roofs, lush olive greens, golden wood, warm-lit windows, deep cool shadows). Our frames are pale, lilac-grey and low-contrast: floor paving went pale lilac, the water is washed light, the town is pastel mush, the headland became a grey-lilac dome.
OPEN ITEMS (in order)
1. **Palette richness pass** (shared material / shader / vertex colours / light colours, not new models): raise saturation and value contrast of the key materials toward the cover crops: roofs strong terracotta/coral (not teal/pale), walls cream/peach/butter/sage, grass lush olive-green, wood planks warm golden-brown, water deeper blue with warm orange glitter at golden hour, paving warm grey-beige (NOT lilac). Make shadows deeper and cooler (blue-violet) against warm lit sides. Reduce mid-distance haze washing out colour. Measure: take the same cover crops and game crops, compare mean saturation and luminance std-dev (report the numbers before/after); target within about 15 percent of the cover on the lit areas, while sky/glow stay tasteful. Check that the white gull still reads clean white.
2. **Headland / lighthouse island** (compare the cover crop): rounded lilac-grey dome is wrong. Make it a warm brown-grey layered rock base with a grass cap, a red-and-white striped lighthouse with a small white house, two small wind turbines, a few dark pines; sunlit side warm, shadow side cool. Decor only, collision untouched.
3. **Houses on the hill and by the cafe**: apply the richer palette; warm emissive windows at golden hour/dusk (cheap, shared material); keep footprints/colliders. If the existing house assets cannot reach the cover's chunky red-roofed look, build a variant from the fantasy-town-kit pieces (CC0, already in art_src/third_party/_quarantine) and record it in the manifest.
4. **Cafe corner**: add what makes the cover cafe feel alive and warm: glowing round lamp bulbs along the railing, warm-lit shopfront, more striped umbrellas, string lights, planters; keep the area ordered.
5. **Water**: deeper blue gradient, warm glitter path, soft foam along pier posts and shores (reflections of the scene are optional).
Round budget: at most 3 internal iterations; stop early only if the lit areas match the cover crops closely.

---

## Review 10 - S2 cover lighting/atmosphere (2026-10-10) - VERDICT: APPROVED as the lighting base; ground/cliffs/water next (S3)
Seen: summary before/after/cover, roof/pier/town/flight at four times of day (iteration_4).
Good: roof view at golden hour has real cover mood (warm gradient sky, string lights, lamp glows, sun glitter, layered soft hills, lighthouse island with turbines, lit Ferris wheel). Draw calls -2..-9; glow/effects governor-aware; 24/24.
OPEN (go to S3): brown dirt-like beach and ground; headland as one brown block; flat teal water in pier view; sparse plain pier/cafe props; houses lack warm lit windows; sunlit-side warmth and saturation still below the cover; clouds simple. Perf: some CPU/GPU render samples are higher (+44/+118 percent on tiny absolute numbers) - re-measure in S3 with governor on/off, absolute ms.

---

## Review 9 - S1 gull round 2 (2026-10-10) - VERDICT: APPROVED as the new hero gull
Side by side with the cover: big round faceted white head, two black dot eyes, chunky orange beak holding a fry, raised wings with dark tips, yellow flat feet: the goofy charm is back and it reads as the cover gull. IoU front .864 / left .751 / top .872 / right .751 / back .870 (pose-registered), 734 tris, 11 parts, 1 material, draw calls unchanged, 24/24 regression.
CARRIED (handled in S2 and final polish): wings are mid-grey and heavy (cover: white/pale lilac-grey with dark tips); far-wing foreshortening; hard angular joint covers; lighting flatter than the cover.

---

## Review 8 - S1 faceted gull, round 1 (2026-10-10) - VERDICT: right direction, NOT approved; round 2 of max 3
Seen: cover vs old vs new, five views model/reference, silhouette overlay (front 0.863, left 0.455, top 0.722), wardrobe + VN shots.
GOOD (keep): the goofy charm is back: big round faceted head, tiny black dot eyes, chunky orange beak, plump body, yellow flat webbed feet; front/back views match the reference well; 714 tris / 11 parts / 1 material; draw calls not increased.
OPEN ITEMS
1. **Dirty banding / not white.** The body has strong dark-grey horizontal bands (vertex facet tints far too strong, plus the toon bands darken the belly); in game the gull reads dull light-grey, not the clean bright white of the cover gull. Make the base white (F7F7FA), keep per-facet tints very subtle (about +-3 % luminance, cool-grey only on undersides), no horizontal stripes. Verify that in noon/golden/dusk the lit side is near-white and the shadow side a light cool grey-lilac; compare crops against the cover gull, side by side.
2. **Left (side) view IoU 0.455 and top 0.722.** The model pose does not match the reference pose: pose the model with the same wing angles as the reference (raised V of wings in the left view, wings spread in the top view), the same head size/position and body slope, same leg length, and recompute. Target left >= 0.75, top >= 0.85, front stays >= 0.85. Also check the back/right views.
3. **Beak too big and droopy.** Match the reference proportions: shorter, thicker, horizontal, slightly smaller than now; keep the orange-yellow with a small red-orange tip.
4. **Eyes**: keep dots but place them a little lower and more forward on the sides of the face as in the cover (bigger by about 20 %), so they read as goofy at 15 m.
5. **Wings**: when folded (perch, dive) they look like stiff slabs behind the body; give a believable folded shape (still faceted). Remove visible hinge seams at shoulder/elbow through the full animation range.
6. **VN portrait crops** (vn_you, vn_big_bro): the head is cropped; adjust the portrait camera framing so the whole head incl. hat is inside the frame with a little margin (do not change story logic). The necklace floats away from the body on Big Bro: attach it correctly.
7. **Cover comparison sheet** at the end: same pose as the cover (rear 3/4, wings up, holding a fry in the beak at a dusk roof) next to the cover gull crop.

---

## Review 7 - USER VERDICT (2026-10-10): round-14 results REJECTED in direction
The user judged: not a substantive upgrade; the gull lost its goofy cuteness; people look like effortful but ugly low modelling. Reviews 3-6 approvals are RETRACTED where they contradict docs/41_COVER_DIRECTION.md (smooth gull with judgy lidded eyes, feather layers, soft clay look). The target is art_src/reference/cover.jpg. Follow docs/41 from now on.

---

## Review 6 - P2 fries / wardrobe / dog / fish / special people (2026-10-10) - VERDICT: mostly approved; small fix round (round 2 of max 4)
Seen: fry cast, cafe fries at 3/15/60 m, dog before/after, fish contact sheet + in-game fish_nine, three outfits (flight + perch), special cast, face closeups.
Good: carton of golden fries on the cafe table is big, warm and appetising; dog is a charming chunky toy dog (huge upgrade over the blocky one); wardrobe (straw hat + glasses + shirt, top hat + shades + coat, sailor cap) reads and sits correctly on the new gull; 1,935 -> 1,673 draw calls; fish sets 2 draws each.
OPEN ITEMS
1. **Ghost rectangles next to the fish in game** (`iteration_2/game/fish_nine.png`): each fish has a flat grey/blue/brown rectangle floating beside it (old primitive pieces still visible, or mis-parented tail/fin cards?). Find and remove; show the 9 fish in game at 3 m with nothing floating, and the catch-socket shot. Also the fish look matte and dull in game vs. glossy in Blender: add a bit of colour punch (more saturated bodies, lighter bellies, a clear eye highlight) so the rarity colours read at 15 m.
2. **VN box evidence is missing**: `vn_box_0/1/2.png` show distant town shots, not the visual-novel box. Re-capture three speakers (e.g. old man, a child, Big Bro) with the real VN box and live portrait, and fix the Big Bro hat being cropped at the top of the portrait (adjust the portrait camera framing, not the story logic).
3. Check fry sticks in a close-up (960x540): confirm bevelled sticks with a visible golden gradient and salt specks at 3 m; check the hand-held and plate variants too. If a stick still reads as a flat bar, add slight twist/irregularity.
4. Special fry kinds: the colour identity lives only in the carton. Add a subtle tinted glaze or tip to the sticks for the specials so each kind is recognisable at 15 m (keep plain/ordinary golden; keep all glow/halo logic and the plain fry's hidden rules untouched).
Report briefly; then STOP.

---

## Review 5 - P1b round 2 (2026-10-10) - VERDICT: APPROVED (carry defects)
Seen: street 15 m / 60 m noon+golden before/after, crowded town, eight-person cast, numeric saturation/contrast table.
Trees now lush and lobed with warm trunks and forks; roofs are deeper than walls and separate at 60 m; the village reads as a coherent warm storybook town; people are sturdier with cuffs, suspenders, proper apron; draw calls 2,070 -> 1,429; people 9 draws vs 15-17.
CARRIED DEFECTS (final polish pass): faceted crown edges in close-up; plain house backs; raised-hand vs hair overlap; noon contrast still 2-3 % under old; the gull defects in Review 3.
Next: P2 (docs/39_P2_FRIES_WEAR_SPEC.md).

---

## Review 4 - P1b tree/house/person round 1 (2026-10-10) - VERDICT: NOT approved, round 2 of max 4

Seen: eight-style cast, tree variants, house combos, street/crowd before-after at 3/15/60 m, cast in noon/golden/dusk.
Good: people are charming toy-people with dot eyes + blush, 9 draws instead of 15-17, 1.4k tris; the town now has a coherent warm pastel storybook palette; houses have soft eaves, shutters, chimneys; budgets and A/B numbers are excellent (draw calls 2,070 -> 1,429).

OPEN ITEMS (priority order)
1. **TREES ARE SICKLY.** Crowns turned pale olive-khaki and lost the lush green of the old trees; the whole town looks hazy and flat next to the "before" (which had fresh saturated greens and strong contrast). Pastel does not mean faded. Crowns: shadow side deep teal-green (3F7A5A-ish), mid fresh green (6DBE6A-ish), top lit warm yellow-green (B6DB6B-ish), saturated enough to read as foliage at 60 m. Pines likewise deeper, a bit bluer-green, clearly darker than the deciduous crowns. Numeric test on the same street shot before vs after: mean saturation of foliage pixels must be >= 0.9x before; frame luminance contrast (std-dev of luma) >= 0.95x before.
2. **Tree form.** Crowns read as soft broccoli blobs. Make the 3 deciduous variants clearly different (round-lobed, tall oval, wide umbrella) with 4-6 distinct lobes each, a visible lit/shadow separation between lobes, and a slightly longer trunk with a branch fork under the crown. Keep <= 500 tris, one merged mesh, wind weight in vertex alpha.
3. **People - floating white square.** One style (apron) has a flat white rectangle on the torso that looks like a sticker. Build a real apron (bevelled bib + waist band + straps, cream with soft AO). Check every accessory for floating flat cards (vest, backpack, apron, etc.).
4. **People - proportions.** Arms are very thin sausages; legs too. Taper them with thicker upper arms/thighs, add sleeve cuffs, a shoulder/neck definition and slightly bigger rounded shoes so the figure feels sturdy and toy-like, not stick-like. Keep faces as they are (good).
5. **Houses - contrast.** The old white walls + orange roofs popped at 60 m; the new pastel walls + similar-value roofs blend. Make roofs deeper and more saturated than the walls (terracotta, salmon, teal) and walls slightly more saturated pastels; keep the soft look. 60 m readability test: rooftops must separate from walls and from the green.
6. **Whole-scene punch.** Compare the street shot before/after side by side; it should look richer, not hazier. If the soft-toon shader or ambient is lifting blacks or desaturating (tint terms, rim, fog interaction), fix it at the shader level and re-verify the gull still reads as white.

Report as before; include the numeric saturation/contrast comparison and before/after sheets (street at 15 m and 60 m, noon + golden).

---

## Review 3 - P1a hero gull round 2 (2026-10-10) - VERDICT: APPROVED (carry defects)

Seen: before/after + 128 px silhouettes, flight noon/golden/dusk, perch, joint extremes, colour masks.
Now reads as a clean white seagull; wings are long blades with bold dark tips, +19-20 % span; perch is cute and gull-like; face keeps its character (slightly judgy eyes - keep). Colour tests pass (S 0.4 % / 3.6 %). 3,804 tris / 11 parts / 1 material, fewer draw calls than the old gull.
CARRIED DEFECTS (fix in the final polish pass, not now)
- Folded-wing flare pose: primaries read as stiff separate "fingers"; give them overlap and a slight curve.
- The red beak dot looks like a tongue on the perched profile; make it a smaller dot on the upper-beak tip only.
- Coverts seam slightly hard in close-up; primaries slightly straight.
Next: P1b, docs/38_P1B_TREE_HOUSE_PERSON_SPEC.md.

---

## Review 2 - P1a hero gull (2026-10-10) - VERDICT: NOT approved, round 2 of max 4

Seen: Blender turntable/poses (iteration 4), in-game before/after (flare, chase, perch, noon/golden/dusk), big brother.

What is good (keep)
- Face: big glossy eye with highlight, soft brow, hooked yellow beak with red dot. Charming. Keep head and beak exactly in spirit.
- Chubby egg body, layered dark primaries, tail fan, coral legs, 3,884 tris / 11 parts / 1 material and fewer draw calls than before. Pipeline and fallback are right.

OPEN ITEMS (in priority order)
1. **COLOUR: the gull is pink-lilac in game.** At 3 m noon over the sea it reads as a lavender pigeon, not a seagull; the old gull read as a clean white seagull and popped against blue water. Violet is only allowed in the SHADOW side and underside (<= ~35 % strength). Lit body must read near-white warm cream (F7F1E6), back/upper wings soft blue-grey (B9C3D1, NOT lilac), tips charcoal. Pass test: render the gull at 3 m over blue sea at noon and at 15 m over peach ground at golden hour; mean colour of the lit body must be low-saturation (S < 12 %) and warm-neutral; a viewer must say "white seagull". Check both the shader tint terms and the baked vertex colour (lilac AO colour probably leaks into the lit side).
2. **WINGS are weak.** In flight the wings look like thin inflated sausage segments; the old gull's long blade wings with a bold dark tip were a stronger silhouette. Redesign the wing planform: longer and slightly wider span than the old gull, clean curved leading edge, tapered blade for forearm and hand, 5-6 layered primaries with a bold charcoal tip band (about the last 30 % of the hand), thinner trailing edge. Remove the visible segmentation at the shoulder (blend upper arm into the body with a covert mass). Silhouette test: black-on-sky silhouettes of old vs new at 128 px, wings level and wings up; the new one must be at least as readable and clearly more elegant.
3. **Perched pose is a ball.** Add neck definition, a slightly more horizontal body, tail visible behind, and longer visible legs (old legs were longer). Keep it cute but unmistakably a gull.
4. Shoulder/elbow joints: no gaps or intersections through the full flap range and in flare/dive; test the extremes of the existing animation.
5. Review images: the 512 px cap hides detail. For gull close-ups you may now render in-game captures up to 960x540 and Blender poses up to 768 px (a handful of images only; keep fans quiet).

Do not start tree/house/person yet. Report as before, with a before/after sheet that includes the black-silhouette comparison.

---

## Review 1 - P0 pipeline (2026-10-10) - VERDICT: pipeline APPROVED, look NOT yet approved

Seen: Blender contact sheet, before/after, report docs/36_ROUND14_CHANGES.md.

What is good
- Blender -> GLB -> Godot works end to end, one shared material, vertex colour survives, tiny files. Keep common.py and the loader.
- Honest report. Thank you.

OPEN ITEMS
1. **Shader looks washed and cold in game.** The Blender sheet shows rich peach/sage with warm light; in game the same cube turns pale cyan/white on top and grey-blue on the side. The warm-violet shadow and warm gold light are missing. Calibrate `soft_toon.gdshader` against the real scene light and sky (noon AND the sunset sky): the object must stay in its painted palette. Test with a "palette card" mesh (cream F7F1E6, peach D99B87, sage 9FB4A0, coral F28A52, butter F5B53A, charcoal 3A3D48, lilac D8CFE6) in 3 lighting moods (noon, golden hour, dusk). Rules: shadow side = hue shifted toward violet, never grey; lit side = slightly warm; ambient from the sky must not bleach vertex colour. Reduce rim/sky contribution if it is the cause.
2. **Saw-tooth self-shadow on bevels.** Tune shadow bias / normal bias on the scene's DirectionalLight3D (allowed: it is visual only) and/or in the shader, so bevelled edges are clean at the default shadow distance. Check it on the cube and on the gull.
3. **Performance gate was too strict.** One 188-tri cube cannot cost CPU time; differences of 1-3 % over 30 frames are measurement noise. The gate is now: (a) draw calls and tris within budget, (b) draw calls for the asset not higher than the thing it replaces, (c) shader stays cheap (no extra passes, no loops, no texture reads beyond one optional small atlas), (d) a quick same-session A/B of median frame time only when an asset is *replacing* something and the difference is above 5 %. Report numbers, do not stop for noise.
4. Godot shutdown resource-leak warnings: pre-existing, ignore.

## Direction notes for P1 (gull first)
See docs/37_P1A_GULL_SPEC.md.
