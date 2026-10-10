# 36 - Starter prompts for Codex (art round)

Paste ONE prompt per session. Keep sessions short and phase-sized; a fresh session re-reads the docs, so state lives in the files, not in chat.

## Session 0 - capability check (2 minutes, do this first)

```
Before any work: open art_src/hero_gull/gull_left.png and tell me what you see, in 3 sentences (shape, colours, style). Then run
"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" --background --version
and tell me the version. Do not modify any file. If you cannot view images, say so plainly.
```
If it cannot describe the picture, it cannot judge art: use it only for scripts/integration and let someone else review the renders.

## Session 1 - P0 pipeline

```
Read docs/35_ART_UPGRADE_BRIEF.md fully, then AGENTS.md section 11, then the performance and web parts of TUNING_NOTES.md and docs/34_ROUND13_CHANGES.md.
Do phase P0 only: tools/blender/common.py, the turntable/contact-sheet renderer, a Godot loader helper and the soft-toon shader, proven end to end on a rounded cube (Blender -> GLB -> in game, vertex colours visible).
Look at your own renders and screenshots (open the PNGs). Update docs/ART_MANIFEST.md. Then STOP and report: what you built, what you saw, numbers (draw calls, frame time), and any problem. Do not start P1.
```

## Session 2 - P1 vertical slice

```
Read docs/35_ART_UPGRADE_BRIEF.md, docs/ART_MANIFEST.md and docs/ART_REVIEW.md (if it exists; fix open items first).
Do phase P1 only: hero gull, one tree with 3 seeded crown variants, one house with 2 variants, one person. Put them in the game with the new shader and produce art_src/slice/before_after.png from the same camera as an existing "before" shot in shots/.
Follow the review protocol in section 6 (look at every render; three distances in game). Respect the budgets and contracts. Then STOP and wait for approval.
```

## Later sessions

```
Read docs/35_ART_UPGRADE_BRIEF.md, docs/ART_MANIFEST.md, docs/ART_REVIEW.md. Fix every open review item, then do phase P<N> only. Follow sections 3, 4, 6, 7. Stop at the gate and report numbers and honest defects.
```
