"""Round 16/17: the Windows submission zip (build/JustSomeFries.exe + .pck + HOW_TO_PLAY.txt).   python tools/make_zip.py"""
import os, zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HOW = """JUST SOME FRIES (Windows)

RECOMMENDED: play this Windows version. It has the clearest graphics and runs much smoother than the browser trial.

1. Unzip this folder anywhere.
2. Double-click JustSomeFries.exe. Keep JustSomeFries.pck in the same folder.
   If Windows SmartScreen says "Windows protected your PC", click "More info" -> "Run anyway".

EASY or HARD: the game asks when you start a new run (EASY = the way in: lots of breath, clear rings, a friendly town;
HARD = the race and a real rhythm game: one gold band, the music plays by itself and you press E on the beat, breath that runs out, a clock for the 24 fries). You can switch in the pause menu.

HOW TO GET A FRY:  1  climb above it.  2  put it in the middle of the screen (hold TAB: the world slows down).  3  dive at it with Shift.  4  press E when a white ring hits the green (HARD: on the beat, in the gold ring).
Mouse = steer   W = fly   Shift = boost   S = brake   A/D = bank (double-tap = roll)   R = turn right round   Q = hide / show the goals board
Space = flap   Ctrl (hold) = land / rest   E = grab (press as each ring closes; green good, gold perfect)
TAB (hold) = Gull Sight (the world slows down while you look)   C = Fry Codex   Esc = pause
F = squawk: on a roof it calls the gulls; on the ground a calm crowd says hello, a wary one chases you off.
Catch a fish and OCEAN TIME begins: on the sea W surfs, hold TAB to lock the fish in the middle of the view, Space launches you straight at it.
Two save slots. After the end, HOLD E at the credits to keep playing (the big brother has things to say).

Languages: English, 简体中文, 繁體中文, 日本語. The game asks when it starts; on the title screen press L to change it.

Walkthrough video: https://kouhoukou.github.io/JUST-SOME-FRIES/walkthrough.html
Source: https://github.com/KOUHOUKOU/JUST-SOME-FRIES

Third-party art: some props (boats, barrels, crates, palms, rocks, tables, chairs, plants, plates, drinks) are adapted from Kenney's CC0 asset packs (kenney.nl). Licences: design/third_party in the repository.
"""
out = os.path.join(ROOT, "submission", "JustSomeFries_Windows.zip")
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as z:
    z.writestr("JustSomeFries/HOW_TO_PLAY.txt", HOW.encode("utf-8-sig"))
    z.write(os.path.join(ROOT, "build", "JustSomeFries.exe"), "JustSomeFries/JustSomeFries.exe")
    z.write(os.path.join(ROOT, "build", "JustSomeFries.pck"), "JustSomeFries/JustSomeFries.pck")
print(out, os.path.getsize(out) // 1048576, "MB")
