# 06 — AUDIO AND MUSIC SPEC

Audio is one of the highest-value polish layers. Implement hooks early, but final files may be supplied manually.

## Audio buses

- Master
- Music
- SFX
- Ambience
- UI (optional)

## Required ambience

Continuous:
- ocean waves
- wind
- occasional distant gull
- optional quiet marina/crowd murmur.

At the ending, ocean + wind must remain after music fades.

## Player sounds

Expected logical filenames / paths may be created as placeholders:

- `gull_flap`
- `gull_dash_whoosh`
- `gull_wind_loop`
- `gull_call_01..04`
- `gull_triumph`
- `gull_hit`
- `gull_land_rustle`
- `fry_crunch`

F key:
- random gull call from small pool
- cooldown ~0.7 s
- zero gameplay benefit.

## NPC reactions

Do not record or synthesize full dialogue.

Short vocalizations only.

Elder:
- gentle surprise / "Oh!"

Adult:
- short "Hey!" / gasp

Child:
- laugh / squeal / surprise.

A few clips may be pitch-randomized slightly.

## Gameplay/UI sounds

- target readiness tick
- valid lock cue
- timing success click
- timing failure dull click
- successful snatch pop
- human swat whoosh
- hit thump
- Gull Sense unlock chime
- special upgrade sting
- Prism chime
- achievement toast
- Ordinary Fry crunch.

## Music direction

Only one main gameplay loop is required.

Character:
- playful
- breezy
- mischievous
- coastal
- light, not epic
- not sentimental piano
- not cartoon slapstick overload.

Suggested musical structure:
- ~95–110 BPM
- light percussion
- plucked/pizzicato/mallet-like lead
- warm bass
- compact memorable 60–100 sec loop.

## Music state behavior

### Act I
Normal full loop.

### Gull Sense complete
Small one-shot musical lift over loop.

### Act II
Normal loop.

### Special Fry
Short sting overlays existing music.

### TAB
Music volume reduced; optional mild low-pass.

### 7/7 transition
Percussive energy falls first.

### STILL HUNGRY
Main music fades substantially or stops.

### Prism phase
Mostly ambience. Optional faint musical bed only if it does not weaken the quiet transition.

### Ordinary Fry
Do not restore heroic music.

### Ending
Sea + wind dominate.

## Asset sourcing rule

The coding agent must not spend quota searching broadly for sounds.

If files are absent:
- wire placeholders / AudioStreamPlayer nodes
- use no-op/null-safe playback
- keep the game functioning.

Human can later drop CC0/public-domain WAV/OGG files into agreed paths.
