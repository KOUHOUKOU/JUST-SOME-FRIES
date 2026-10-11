"""Re-record the five --film segments with the current game, then cut the promo (tools/film/make_promo.py).

    python -I tools/film/record_all.py [--skip-record] [--only=1,2]

* Old segments are moved to film/_old_segments/ first (nothing is deleted).
* The game runs with APPDATA / LOCALAPPDATA redirected into art_src/final/runtime_film so the real save file is never touched.
* One segment at a time (the machine stays calm), 1280x720, 30 fps, Godot Movie Maker.
* The promo step runs WITHOUT -I (it needs edge_tts from the user site-packages); the cached narration mp3s in film/ are reused.
"""
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
FILM = ROOT / "film"
GODOT = r"D:\Tools\Godot\4.7.1\Godot_v4.7.1-stable_win64_console.exe"
ORDER = [1, 2, 3, 11, 12, 13, 14]
LOG = FILM / "record_all.log"


def log(msg):
    line = time.strftime("%H:%M:%S ") + msg
    print(line, flush=True)
    with open(LOG, "a", encoding="utf-8") as f:
        f.write(line + "\n")


only = None
for a in sys.argv[1:]:
    if a.startswith("--only="):
        only = [int(x) for x in a[7:].split(",")]
order = only or ORDER

if "--skip-record" not in sys.argv:
    old = FILM / "_old_segments"
    old.mkdir(exist_ok=True)
    for n in order:
        f = FILM / ("seg%d.avi" % n)
        if f.exists():
            shutil.move(str(f), str(old / ("seg%d_%d.avi" % (n, int(time.time())))))
    rt = ROOT / "art_src" / "final" / "runtime_film"
    (rt / "appdata").mkdir(parents=True, exist_ok=True)
    (rt / "local").mkdir(parents=True, exist_ok=True)
    env = dict(os.environ, APPDATA=str(rt / "appdata"), LOCALAPPDATA=str(rt / "local"))
    for n in order:
        out = FILM / ("seg%d.avi" % n)
        t0 = time.time()
        log("record seg%d ..." % n)
        cmd = [GODOT, "--position", "-30000,-30000", "--path", str(ROOT / "game"), "--resolution", "1280x720", "--max-fps", "30",
               "--write-movie", str(out), "--fixed-fps", "30", "--", "--film", "--seg=%d" % n, "--movie-fps=30"]
        with open(FILM / ("seg%d_godot.log" % n), "w", encoding="utf-8", errors="replace") as lf:
            try:
                subprocess.run(cmd, cwd=str(ROOT), env=env, stdout=lf, stderr=subprocess.STDOUT, timeout=45 * 60, creationflags=0x00004000)   # BELOW_NORMAL priority, window far off screen
            except subprocess.TimeoutExpired:
                log("seg%d TIMEOUT" % n)
        size = out.stat().st_size if out.exists() else 0
        log("seg%d done in %.0f s, %.1f MB" % (n, time.time() - t0, size / 1e6))
        if size == 0:
            log("seg%d FAILED, stopping" % n)
            sys.exit(1)

if "--no-promo" in sys.argv:
    sys.exit(0)
log("cutting the promo ...")
py = shutil.which("python") or sys.executable
r = subprocess.run([py, str(ROOT / "tools" / "film" / "make_promo.py")], cwd=str(ROOT))
log("make_promo exit %s" % r.returncode)
p = FILM / "promo.mp4"
log("promo.mp4: %s" % ("%.1f MB" % (p.stat().st_size / 1e6) if p.exists() else "missing"))
