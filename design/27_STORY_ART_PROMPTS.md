# 27 · Story art prompts (optional — the game is complete without them)

The cover illustration (`JSF.png`, now `game/assets/ui/cover.jpg`) is already used: as the title screen and as the poster at the end. The comic panels of the opening are drawn from the 3D world. If you want to replace a panel by a painting, generate it in the **same style as the cover** (soft low-poly 3D, warm golden-hour light, a white low-poly gull with an orange-yellow beak) and save it as a PNG (16:9, at least 1600x900) with the exact name below in `game/assets/ui/story/`. The game picks it up by itself (a slow 5 % zoom is added). No code change.

Style line to put in front of every prompt:
> Soft low-poly 3D illustration, warm sunrise light, pastel Mediterranean harbour town on a hill, clean shapes, gentle shadows, the same look as a cozy indie game cover. The hero is a small white low-poly seagull with a chunky yellow-orange beak and orange legs (same design in every picture). No text, no letters, no logo.

| file | panel | prompt (after the style line) |
|---|---|---|
| `o1_age.png` | "THIS IS AN AGE OF MAGIC." | A wide aerial view of the whole harbour town at sunrise from the sea side: the hill with houses, the pier with a Ferris wheel, yellow harbour cranes, a lighthouse. Tiny glowing sparkles drift up from some of the rooftops. |
| `o2_wind.png` | "THE WIND LISTENS TO CERTAIN FRIES." | A close view of one small cafe table with a red carton of golden fries that glows softly; swirling soft white wind lines bend toward it; an old man in a white cap stands behind the table. |
| `o3_carton.png` | "BREATH IS SOLD BY THE CARTON." | A low-angle view of a red-and-yellow striped fry stand with a giant carton of fries on its roof; small puffs of air rise from the cartons on the counter. |
| `o4_pier.png` | "AND SOMEWHERE ON A PIER," | A long wooden pier seen from the water, a Ferris wheel at its end, calm turquoise sea, one tiny figure walking on the pier. |
| `o5_gull.png` | "A SEAGULL IS HUNGRY." | The small white seagull on a terracotta rooftop, looking out over the town with big round dark eyes, a thought of a fry above the town, a faint rumbling-stomach feeling. |

Extra panels if you want to extend the story later (not used yet): the big brother (the same gull, much bigger, with a black top hat, black sunglasses, a gold chain, a pipe and a long plaid coat) looking down at the little gull, from a low angle; the little gull from the front with a question mark; the old man's cafe corner at golden hour.

## Music and sound
`tools/audio/` renders everything (Python 3, numpy, scipy, ffmpeg): `python tools/audio/render_all.py` (music, 9 files) and `python tools/audio/render_sfx.py` (97 sounds + the list `audio_names.gd`). Edit `music.py` to change a tune, `sfx.py` to change a sound, then re-run and open the Godot project once (`godot --headless --path game --import`).
| `o3b_cafe.png` | (round 8) "A SLOW MORNING AT THE CAFE." | The cafe terrace, low angle: a small round table with a red carton of fries, an old man in a white cap sitting beside it, a sleepy morning, long soft shadows. One fry lies on the floor by the table leg, small and plain, with nothing special about it. |

(Round 8: the panels `o4_pier` and `o5_gull` keep their names; the new cafe panel is `o3b_cafe`.)

