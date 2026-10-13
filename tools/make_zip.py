"""Round 16/17: the Windows submission zip (build/JustSomeFries.exe + .pck + HOW_TO_PLAY.txt).   python tools/make_zip.py"""
import os, zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HOW = """JUST SOME FRIES (Windows)

RECOMMENDED: play this Windows version. It has the clearest graphics and runs much smoother than the browser trial.

1. Unzip this folder anywhere.
2. Double-click JustSomeFries.exe. Keep JustSomeFries.pck in the same folder.
   If Windows SmartScreen says "Windows protected your PC", click "More info" -> "Run anyway".

Mouse = steer   W = fly   Shift = boost   S = brake   A/D = bank (double-tap = roll)
Space = flap   Ctrl (hold) = land / rest   E = grab (press as each ring closes; green good, gold perfect)
TAB (hold) = Gull Sight (the world and your drinks slow down while you look)   C = Fry Codex   Esc = pause
F = squawk: on a roof it calls the gulls; on the ground a calm crowd says hello, a wary one chases you off.
Catch a fish and FISH TIME begins: on the sea W surfs, Space launches you at the fish that keep jumping.
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
