# JUST SOME FRIES

## ▶ Walkthrough video (2 min, narrated)

[![Watch the walkthrough](docs/walkthrough_poster.jpg)](https://kouhoukou.github.io/JUST-SOME-FRIES/walkthrough.html)

**[▶ Watch the walkthrough in your browser](https://kouhoukou.github.io/JUST-SOME-FRIES/walkthrough.html)** · [direct .mp4](https://kouhoukou.github.io/JUST-SOME-FRIES/walkthrough.mp4) · **[▶ Play the game in your browser](https://kouhoukou.github.io/JUST-SOME-FRIES/)**

---

![cover](images/cover.jpg)

> Be a gull. Steal magic fries off a seaside pier, and find out what you were really hungry for.

A small 3D flight game made for **Tripothon**, theme *"A Gift for ____"*.

**A gift for: the part of you that only wanted some fries.**

## ▶ Watch · Play · Download

| | Link |
|---|---|
| **Walkthrough video** (2 min, English narration + subtitles) | **[▶ Watch the walkthrough](https://kouhoukou.github.io/JUST-SOME-FRIES/walkthrough.html)** · [direct .mp4](https://kouhoukou.github.io/JUST-SOME-FRIES/walkthrough.mp4) |
| **Play in the browser** (no install) | **[kouhoukou.github.io/JUST-SOME-FRIES](https://kouhoukou.github.io/JUST-SOME-FRIES/)** |
| **Download for Windows** (the full experience) | **[Releases → JustSomeFries_Windows.zip](https://github.com/KOUHOUKOU/JUST-SOME-FRIES/releases/latest)** · [direct download](https://github.com/KOUHOUKOU/JUST-SOME-FRIES/releases/download/version1/JustSomeFries_Windows.zip) |
| Source (Godot 4 project) | [`game/`](game/) in this repository |

The walkthrough (2 minutes) was recorded straight from the game with Godot's Movie Maker (a test bot does the flying), then cut with an English voice-over. The narration is AI-generated (Microsoft Edge neural text-to-speech, voice *Andrew*) and the subtitles are burned in; the script is in [`docs/walkthrough.srt`](docs/walkthrough.srt). It shows the opening, the first rhythm grabs, Gull Sight, the first time all three drinks make STARLIGHT, a shooting star being caught, and a glimpse of the ending (its last scene is not shown).

## How to play

**Windows:** download the zip from [Releases](https://github.com/KOUHOUKOU/JUST-SOME-FRIES/releases/latest), unzip it and double-click `JustSomeFries.exe` (keep the `.pck` file next to it). If Windows SmartScreen warns about an unknown publisher, click *More info → Run anyway*.

**Browser:** open the [web version](https://kouhoukou.github.io/JUST-SOME-FRIES/) on a desktop computer, wait for it to load, and click the game once so it can take the mouse. Chrome or Edge recommended. The Windows build runs smoother.

| Key | What it does |
|---|---|
| Mouse | steer |
| W / Shift | fly / boost (boost costs stamina) |
| S | brake |
| A / D | bank (double-tap to roll) |
| Space | flap |
| Ctrl (hold) | land anywhere; resting on the ground gets your stamina back |
| **E** | grab: press as each ring hits the green zone (gold counts double) |
| TAB (hold) | Gull Sight: time slows, every fry shows its rarity and the speed it needs; high in the sky it also draws the orbit of a shooting star |
| C | Fry Codex (right-click a wearable to put it on or take it off) |
| F | squawk |
| Esc | pause |

## The game

You fly freely over a sunny seaside town, pier and cafe. Dive at a fry fast enough and the grab becomes a one-key rhythm game: target circles appear around the fry, and every circle sends waves of rings. Press **E** as a ring hits the green zone (green = 1 point, gold = 2, a miss = 0) until you have as many points as the fry has waves. Every circle is judged twice. A silver fry has 2 circles, gold 3, diamond and rainbow fries 5 circles arranged like the Olympic rings. A missed grab costs breath, spooks the fry and the owner notices you: try again once things calm down.

Seven colours of magic fry each change how you fly: top speed, acceleration, ring size, how far you can see, stamina, rest, and how hard you get hurt. Each comes in silver, gold and diamond (and, once a colour is complete, rainbow). Volleyball players spike the ball at you, dogs and kids chase you, and you can steal hats, glasses, socks, coffee, cocktails and ice cream off people. Each drink changes how you feel (sharper senses, easy flight, nothing can hurt you), and **all three at once is STARLIGHT**: thirty seconds of the best flying there is, with a piece of classical music of its own. Hold TAB for Gull Sight: time slows, every fry becomes a big emblem (a hexagon for silver, a star for gold, a cut gem for diamond, a ring of colours for rainbow) and sends a **pillar of light to the sky** whose colour and height tell its rarity.

The island is full of small adventures: fish that leap where the water bubbles (nine kinds, a fish book), grey clouds and **rain clouds that only rain over the sea**, a rainbow between a rain cloud and a white cloud, and a cloud, the sun, a **rainbow** and **shooting stars** that you can catch and wear. They need the fastest flying in the game: a gold-SONIC gull with all three drinks (STARLIGHT) barely reaches the sun, and each asks for five circles (the rainbow seven), every circle twice. A caught star stays with you as a trail of little golden stars, friendly gulls in faint pastel colours who bring you gifts, kind children, and a task board.

The game has two kinds of short film moments, because gulls collect things one after another and nobody wants to be interrupted. The **beats** (4-8 s: the first coffee, cocktail and ice cream, the first fish, a cloud, the fish book) keep you flying: one big hand-lettered comic word (`BZZZT!`, `GLUG~`, `BRRR!`, `SPLASH!`) and a line or two of the gull's thoughts. The **film moments** (about 12 s, with their own music) are all three drinks at once, the first star, the sun, the rainbow, and the day the gull has every kind of magic there is and is still hungry. They never take the controls away: the world slows down and softens at the edges while you keep flying. When you catch a star, a cloud, the sun or a rainbow, the catch is shown in three small close-ups in the corners of the picture and the gull's own thoughts stand in the middle. And then there is the big brother on the cafe roof, who has everything and is still hungry. You can sit next to him and talk.

## Made with

Godot 4.7.1 (GDScript, Compatibility renderer), Claude Code, ChatGPT. Every model, texture and sound effect is generated by code (`tools/audio` renders the sounds offline with numpy). The music is classical and played by real orchestras: public-domain works in public-domain recordings of the Musopen project (via Wikimedia Commons): Grieg's *Morning Mood* (title), Dvořák's *Largo* (ending), Chopin, Debussy, Satie, Mendelssohn, Brahms, Smetana and Borodin for the island's zones and big moments. `tools/audio/real_music.py` cuts, levels and loops them (the raw recordings are not in the repository); the credits name everyone.

## Screenshots

| | |
|---|---|
| ![fry box owner](images/01_fry_box_owner.jpg) | ![pier overview](images/02_pier_overview.jpg) |
| ![gull lock on](images/03_gull_lock_on.jpg) | ![catch the sun](images/04_catch_the_sun.jpg) |
| ![rhythm rings](images/05_rhythm_rings.jpg) | ![pool villa grab](images/06_pool_villa_grab.jpg) |
| ![fry codex](images/07_fry_codex.jpg) | ![sea and quest](images/08_sea_and_quest.jpg) |
| ![the first fry](images/09_the_first_fry.jpg) | ![big brother](images/10_big_bro_visual_novel.jpg) |
| ![starlight and a shooting star](images/11_starlight_moment.jpg) | ![memories](images/12_memories.jpg) |
| ![gull sight emblems](images/13_gull_sight_emblems.jpg) | ![light pillars](images/14_light_pillars.jpg) |
| ![a rainbow in the sky](images/15_rainbow_in_the_sky.jpg) | ![i can see the wind](images/16_i_can_see_the_wind.jpg) |
| ![the task board](images/19_task_board.jpg) | ![a film moment](images/20_flow_moment.jpg) |
| ![a rest on the sea](images/21_rest_on_the_sea.jpg) | ![catching the sun](images/22_catch_moment.jpg) |

## Repository

- `game/`: the Godot project. Open `game/project.godot` with Godot 4.7, or run `godot --path game`.
- `docs/`: the web build served by GitHub Pages, plus the walkthrough video.
- `design/`: design documents, change logs (`33_ROUND12_CHANGES.md` is the latest) and tuning notes.
- `tools/`: `audio/` renders every sound and piece of music offline; `film/make_promo.py` cuts the walkthrough video.
- `images/`: cover and screenshots.
