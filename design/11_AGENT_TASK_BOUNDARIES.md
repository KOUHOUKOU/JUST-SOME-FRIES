# 11 — AGENT TASK BOUNDARIES AND QUOTA POLICY

## Primary Codex / CodeX agent

Use for direct construction.

Good tasks:
- "Implement Milestone 1 exactly from spec."
- "Implement the snatch loop for one Elder encounter."
- "Complete Milestone 3 without visual polish."
- "Fix this exact movement bug."

Bad tasks:
- "Make this game more fun."
- "Redesign the progression."
- "Browse for the best assets."
- "Try three different architectures."

The docs already answer design questions.

## Secondary Claude / other agent

Reserve as a specialist, not a parallel co-author.

Best uses:
- difficult movement bug
- GLB import/orientation failure
- Godot export failure
- collision anomaly
- code review of one failing subsystem
- performance diagnosis.

Provide it only:
- exact symptoms
- relevant scripts/scenes
- desired behavior
- error output.

Do not give it the entire project and ask for an independent rewrite unless primary implementation has catastrophically failed.

## Human lane

Human should handle:
- selecting/generating hero gull
- aesthetic yes/no judgments
- final audio acquisition
- playtesting feel
- recording submission video
- final contest upload.

This prevents expensive agent usage on subjective selection tasks.

## Prompt discipline

Preferred pattern:

> Read AGENTS.md and only the files listed as Required reading for Milestone N. Implement Milestone N in the existing project. Do not redesign. Keep existing working systems intact. Run the project/tests you can run, fix blockers, and stop when the milestone acceptance criteria are satisfied. Report only concrete changes, remaining blockers, and files I must supply manually.

For debugging:

> Do not refactor unrelated code. Diagnose the following exact bug: [symptom]. Expected: [behavior]. Actual: [behavior]. Inspect only the smallest relevant file set first. Make the smallest reliable fix and verify it does not break the milestone acceptance tests.
