# 20 · Comic panel pictures (lower-left pop-ups) — prompts for ChatGPT image generation

When something happens to the gull, a little tilted "photo/comic panel" slides in at the **lower-left** of the screen with a funny
picture and a one-line caption (the caption is written by the game, so **the pictures must contain no text at all**).
Right now the game draws simple placeholders in code. Drop your finished pictures in and they replace the placeholders automatically.

## Where to put the files

| Option | Folder | Notes |
|---|---|---|
| Play from source (`PLAY.bat`) | `game/assets/ui/comics/<id>.png` | works immediately, no import needed |
| Standalone `build/JustSomeFries.exe` | a folder named `comics` **next to the exe** (`build/comics/<id>.png`) | easiest, no rebuild |
| Baked into the build | `game/assets/ui/comics/` then run `BUILD.bat` | `BUILD.bat` imports new pictures first |

* **Format:** PNG, **square**, 1024 × 1024 (512 × 512 also fine). Full-bleed picture (the background is part of the picture, no transparency needed).
* A missing file simply keeps the placeholder, so you can add them one at a time.

## The 10 pictures

| File name (`<id>.png`) | When it pops up | Caption in game (random pick) |
|---|---|---|
| `smug.png` | every normal successful snatch | "MINE NOW." / "SMUG, AND SALTY." / "CRISP. SLIGHTLY ILLEGAL." |
| `perfect.png` | a **gold** (perfect) grab or perfect slip | "PERFECT. EVEN THE FRY IS IMPRESSED." / "NOBODY SAW A THING." |
| `mischief.png` | stealing a hat / ice cream / balloon / beach ball | "TROUBLE, BUT CUTE." / "IT SUITS ME." |
| `hit_swat_punch.png` | punched by an old man / adult | "POW. A PUNCH. FROM A GRANDPARENT." |
| `hit_swat_poke.png` | poked by the umbrella lady / a parent | "POKED. WITH AN UMBRELLA." |
| `hit_swat_sweep.png` | swept by the market vendor's broom | "SWEPT UP WITH THE CRUMBS." |
| `hit_swat_squirt.png` | squirted by the kid's water gun | "SQUIRTED. BY A CHILD." |
| `hit_swat_lunge.png` | a guard dog jumps at the gull | "A DOG. OF COURSE." |
| `hit_crash.png` | flying into a wall at speed | "THE WALL WAS REAL." |
| `soaked.png` | first splash into the sea | "WET. DEEPLY DISGRUNTLED." |

## How to keep the gull consistent (do this in ONE chat)

1. Open **one** ChatGPT conversation for all ten pictures. Don't start a new chat in between.
2. Send the **character sheet** prompt below first. Pick the gull you like, and keep saying *"the same gull as in the character sheet"*.
3. For every picture, paste the **STYLE BLOCK** + the picture's own prompt. If the gull drifts, reply
   *"Same gull as the character sheet: same beak, same eyes, same proportions. Redo."*
4. Ask for **no text, no letters, no speech bubbles, no sound-effect words** every time (the game adds the caption itself).

### Character sheet prompt (send this first)

```
Character design sheet for a cartoon seagull, the hero of a small comedy game.
Plump, round, slightly goofy seagull. Pure white head and body, light-grey back and wings with dark-grey wing tips.
Chunky bright yellow-orange beak with one small red dot near the tip. Round black eyes with a tiny white highlight,
expressive, deadpan. Short orange legs and webbed feet. Rounded, friendly, slightly silly proportions: big head, small body.
Thick dark-navy outline (about the same weight everywhere), flat colours with a single soft shadow tone, no gradients,
sticker / comic-panel style. Show: front view, side view, and four expressions on a plain white background:
smug (half-closed eyes, raised brow), cool (wearing black sunglasses), knocked-out (X eyes, beak open), soaked (droopy and dripping).
No text, no letters, no labels.
```

### STYLE BLOCK (paste this before every picture prompt)

```
Square 1:1 comic-panel illustration, full-bleed. Same cartoon seagull as in the character sheet
(plump, white, grey wings, yellow-orange beak with a red dot, round black eyes), thick dark-navy outline, flat colours
with one soft shadow tone, no gradients, bright warm seaside palette. Bold simple background (comic action-burst rays or a flat colour).
Slapstick, family-friendly, no blood, no injuries. Absolutely NO text, letters, numbers, speech bubbles or sound-effect words.
```

### Picture prompts (paste after the STYLE BLOCK)

**smug.png**
```
The gull in the middle of the frame, looking extremely pleased with itself: half-closed eyes, one raised brow, a tiny smirk,
a golden french fry sticking out of its beak. Soft sky-blue action-burst background, one small sparkle.
```

**perfect.png**
```
The gull wearing black sunglasses, chin up, a bunch of golden french fries held in its beak like a trophy, tiny sparkles around it.
Warm golden-yellow action-burst background. The most smug and effortless the gull has ever looked.
```

**mischief.png**
```
The gull wearing a too-big straw sun hat that it clearly just stole, sideways grin, looking pleased and a bit guilty.
Soft lilac action-burst background.
```

**hit_swat_punch.png**
```
Slapstick impact: a wrinkly elderly hand in a grey cardigan sleeve punches in from the left and bops the gull on the cheek;
the gull's eyes are X marks, beak open, feathers flying, small stars circling its head. Yellow-orange action-burst background.
Only the fist and sleeve are visible, no face of the attacker.
```

**hit_swat_poke.png**
```
Slapstick: a purple umbrella tip comes down from the top-right and pokes the gull on top of its head;
the gull is squashed down a little with X eyes and an open beak, a few feathers popping up. Yellow-orange action-burst background.
Only the umbrella is visible, no person.
```

**hit_swat_sweep.png**
```
Slapstick: a straw broom sweeps in from the left and scoops the gull sideways like a pile of crumbs;
the gull has spiral dizzy eyes, a few feathers and crumbs flying. Yellow-orange action-burst background.
Only the broom is visible, no person.
```

**hit_swat_squirt.png**
```
Slapstick: a bright orange toy water gun at the left squirts a thick jet of water straight into the gull's face;
the gull squints with one droopy brow, drops flying everywhere. Light-blue action-burst background.
Only the water gun is visible, no child.
```

**hit_swat_lunge.png**
```
Slapstick: a big angry cartoon brown dog (floppy ears, wide-open mouth with teeth, cute not scary) fills the top-left of the frame;
a small gull at the bottom-right has X eyes and an open beak, feathers flying. Yellow-orange action-burst background.
```

**hit_crash.png**
```
Slapstick: the gull has flown flat into a red-brick wall on the right side of the frame: face squashed against the bricks,
X eyes, stars and a few cracks in the wall, feathers flying. Yellow-orange action-burst background.
```

**soaked.png**
```
The gull sitting in the sea after a splash: completely soaked, feathers stuck down, droopy eyebrows, water drops falling off its beak,
a few blue wave arcs under it. Light-blue action-burst background. Deeply disgruntled expression.
```

## Optional follow-ups (not used by the game yet)

If you like the set and want more, tell me and I will wire them in: `lost_fry.png` (the fry splatting on the floor), `slipped.png`
(the gull sliding under a swing), `hungry.png` (the gull staring at the café table). Say the word and I'll add the ids.


---

## Round 4 additions (new pictures; the game draws placeholders until you add them)

`smug` and `perfect` now take the colour of the fry's rarity (blue = rare, purple = epic, gold = legendary) and show **one** fry stick in the beak.
If you want your own art per rarity, add `smug_1.png` / `smug_2.png` / `smug_3.png` and `perfect_1.png` / `perfect_2.png` / `perfect_3.png`
(background in blue / purple / gold). Without them the plain `smug.png` / `perfect.png` is used.

| File name | When | Caption in game | Picture |
|---|---|---|---|
| `fish.png` | catching a fish | "A FISH. NOT A FRY. STILL FUNNY." | the gull, beak full of a shiny fish, droplets everywhere, very proud |
| `cool.png` | wearing 3 / all stolen accessories | "GETTING DANGEROUSLY STYLISH." / "FULLY ARMED. STILL HUNGRY." | the gull in sunglasses, a gold chain and a tiny pipe, deadpan |
| `hit_swat_ball.png` | hit by the volleyball | "VOLLEYBALL. THE NET WAS RIGHT THERE." | a beach volleyball flattening the gull's face, stars |
| `hit_swat_rival.png` | bumped by a rival gull | "A GULL. THE AUDACITY." | a scruffy brown-winged gull glaring at our gull |
| `hit_swat_grump.png` | swatted by a grumpy stranger | "SHOO'D. WITH A NEWSPAPER." | a rolled newspaper mid-swing |
| `rival.png` | a rival gull stole the fry | "A GULL BEAT YOU TO IT." | a scruffy gull flying off with a fry, our gull staring after it |
| `scare.png` | a kid shouted BOO | "A KID. A VERY LOUD KID." | a kid's wide-open mouth, the gull startled |

Prompt skeleton (use the same STYLE BLOCK as above):
`<the picture column>, comic action-burst background, the gull is the same one as in the character sheet.`
