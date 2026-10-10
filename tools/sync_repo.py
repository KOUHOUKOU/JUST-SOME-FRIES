"""Copy the local project into a clone of the GitHub repo (no git commands here; commit/push separately).

    python -I tools/sync_repo.py <path-to-clone>

Mapping (same layout as the published repo):
  game/            <- game/ (without .godot)
  design/          <- docs/*.md at the top level (specs, round notes, art docs) + TUNING_NOTES.md + design/third_party/ (licences + manifest)
  tools/           <- tools/ without the soundfont binaries, third-party MIDIs, caches, and the private workflow helpers (codex runner, dashboard)
  docs/            <- web/ (the web build used by GitHub Pages); the walkthrough video files are copied separately
  images/          <- new files from art_src/final/images_publish/ are added
Text files are written with LF line endings (the repo stores LF; the Windows files here are CRLF).
README.md and docs/walkthrough.html are edited separately.
"""
import shutil
import sys
from pathlib import Path

CRLF = bytes([13, 10])
LF = bytes([10])
TEXT_EXT = {".md", ".gd", ".py", ".gdshader", ".txt", ".json", ".cfg", ".godot", ".tscn", ".tres", ".import", ".uid", ".html", ".js", ".ps1", ".bat", ".srt", ".remap"}

root = Path(__file__).resolve().parent.parent
clone = Path(sys.argv[1]).resolve()
if not (clone / ".git").exists():
    sys.exit("not a git clone: %s" % clone)


def lf(data):
    return data.replace(CRLF, LF)


def write_if_changed(out, data):
    out.parent.mkdir(parents=True, exist_ok=True)
    if out.suffix.lower() in TEXT_EXT and out.exists() and CRLF in out.read_bytes() and CRLF not in data:
        data = data.replace(LF, CRLF)          # keep the repo's existing CRLF files CRLF so the diff only shows real changes
    if not out.exists() or out.read_bytes() != data:
        out.write_bytes(data)
        return 1
    return 0


def copytree(src, dst, skip):
    if not src.exists():
        return 0
    n = 0
    for p in sorted(src.rglob("*")):
        rel = p.relative_to(src)
        if p.is_dir() or skip(rel, rel.parts, p):
            continue
        data = p.read_bytes()
        if p.suffix.lower() in TEXT_EXT:
            data = lf(data)
        n += write_if_changed(dst / rel, data)
    return n


def prune(dst_root, src_root):
    """remove files in the clone that no longer exist locally (only inside dst_root)"""
    removed = 0
    if not dst_root.exists():
        return 0
    for p in sorted(dst_root.rglob("*")):
        if p.is_file() and not (src_root / p.relative_to(dst_root)).exists():
            p.unlink()
            removed += 1
    return removed


# 1) game
def skip_game(rel, parts, p):
    return parts[0] == ".godot" or "__pycache__" in parts or p.suffix == ".tmp"


n = copytree(root / "game", clone / "game", skip_game)
r = prune(clone / "game", root / "game")
print("game: copied", n, "removed", r)

# 2) design (top-level docs md + TUNING_NOTES + third-party licences)
design = clone / "design"
design.mkdir(exist_ok=True)
n = 0
for f in sorted((root / "docs").glob("*.md")):
    n += write_if_changed(design / f.name, lf(f.read_bytes()))
tn = root / "TUNING_NOTES.md"
if tn.exists():
    n += write_if_changed(design / "TUNING_NOTES.md", lf(tn.read_bytes()))
tp = design / "third_party"
man = root / "art_src" / "third_party" / "ASSET_MANIFEST.md"
if man.exists():
    n += write_if_changed(tp / "ASSET_MANIFEST.md", lf(man.read_bytes()))
for pack in ("pirate-kit", "nature-kit", "food-kit", "furniture-kit", "fantasy-town-kit", "city-kit-suburban", "blocky-characters"):
    lic = root / "art_src" / "third_party" / "_quarantine" / pack / "x" / "License.txt"
    if lic.exists():
        n += write_if_changed(tp / ("License_kenney_%s.txt" % pack), lf(lic.read_bytes()))
print("design: copied", n)


# 3) tools
def skip_tools(rel, parts, p):
    s = "/".join(parts)
    if "__pycache__" in parts or p.suffix in (".pyc", ".sf2", ".zip", ".mid"):
        return True
    if parts[0] in ("codex", "dashboard"):
        return True
    if s.startswith("audio/sf/"):
        return True
    return False


n = copytree(root / "tools", clone / "tools", skip_tools)
print("tools: copied", n)

# 4) docs/ = GitHub Pages web build
n = 0
for f in sorted((root / "web").iterdir()):
    if f.is_file():
        n += write_if_changed(clone / "docs" / f.name, f.read_bytes())
print("pages web build: copied", n)

# 5) extra images
extra = root / "art_src" / "final" / "images_publish"
k = 0
if extra.exists():
    for f in sorted(extra.iterdir()):
        if f.is_file():
            k += write_if_changed(clone / "images" / f.name, f.read_bytes())
print("images: copied", k)
