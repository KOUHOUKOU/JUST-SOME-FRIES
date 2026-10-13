# Round 17: four languages

The game now speaks **English, 简体中文 (Simplified Chinese), 繁體中文 (Traditional Chinese) and 日本語 (Japanese)**.

## For the player

* When the game starts, a language card comes first (on the cover picture): **English / 简体中文 / 繁體中文 / 日本語**.
  W / S or the mouse to choose, E / Enter / click (or 1-4) to confirm. The card starts on the language picked last time
  (else the computer's language).
* On the title screen a small **"English · L"** tag (top right) opens the card again (click it or press **L**).
* The choice is remembered in `user://language.cfg`. In the browser build a restart / "back to the menu" reload does not
  ask again.
* Everything is translated: the cover, menus, controls page, slots, HUD, Gull Sight, codex and fish book, achievements,
  item cards, the comic opening and ending (four-panel strip, VN boxes, captions, beats, memories), the big brother,
  the people in town, signs, title cards and credits. The title logo on the cover picture stays as drawn
  ("JUST SOME FRIES"); in the text the game is called 不过是些薯条 / 不過是些薯條 / ただのポテト.

## How it works (`game/scripts/systems/loc.gd`, class `Loc`)

* English stays the source text in the code. `game/assets/i18n/strings.json` maps every English line to the three
  translations. It is built from the tables in `tools/i18n/tr_*.py` by `python tools/i18n/build.py`.
* Labels, buttons and 3D labels are translated by the engine (a `Translation` subclass, `Loc.LocTr`, answers every
  lookup). Drawn text goes through `Loc.t()`: every `draw_string*` / `get_string_size` call in the game was wrapped,
  and the places that type text letter by letter (story, four-panel strip, dialogue) translate the whole line first.
* Lines with numbers or names are **templates**: the key is the code's format string (`"SLOT %d"`), the translation
  uses `{0} {1}` for the values (`"存档 {0}"`), and `%s` values are translated themselves (fry names, colours, places).
  Lines joined with `\n`, `|` or three spaces are translated part by part; a missing line simply stays English.
* Chinese and Japanese text wraps between characters (`Loc.wrap`, no line starts with a closing mark), types at about
  0.42 x the English letters per second and is held a little longer per letter (`Loc.cps`, `Loc.read_len`).
* Fonts: the engine font has no Chinese / Japanese letters, so two subsets of **Noto Sans SC / Noto Sans JP**
  (SIL Open Font License 1.1, `game/assets/fonts/OFL.txt`) with only the letters the translations use are added as
  fallbacks (~430 KB + ~300 KB; the browser build has no system fonts). The order picks Japanese letter shapes for
  Japanese. The comic lettering uses a lighter face for these letters (many small strokes).
* Credits: a LANGUAGES block names the four languages and the fonts.

## Adding or changing a line

1. Edit the right `tools/i18n/tr_*.py` (english key exactly as shown on screen, or its `%` format string).
2. `python tools/i18n/build.py` (rebuilds the JSON and the font subsets, checks the `{n}` placeholders).
3. Check with a dev run: `--lang=zh_CN|zh_TW|ja --loc-log` writes every shown line that had no translation to
   `shots/loc_miss_*.txt`.

## Tests

* `--r17`: the language card, then cover / controls / pause / slot cards / achievements in all four languages
  (`shots/r17_*.png`).
* The existing story / HUD bots run in any language with `--lang=..`: `--r16d` (comic opening), `--r16c` (ending),
  `--r8c`, `--r8e`, `--credits`, `--showcase`, `--codex`, `--r15a`, `--r15b`, `--r16b`.
