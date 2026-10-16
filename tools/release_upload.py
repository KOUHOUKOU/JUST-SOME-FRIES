"""Replace the assets of the GitHub release `version1` with the freshly built files and update its notes.

    python tools/release_upload.py

Uses the GitHub token from the Git Credential Manager (`git credential fill`); the token is never printed.
Assets: submission/JustSomeFries_Windows.zip, submission/JustSomeFries_walkthrough.mp4, film/art_remaster_preview.mp4 (uploaded as JustSomeFries_gameplay_preview.mp4).
"""
import hashlib
import json
import subprocess
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REPO = "KOUHOUKOU/JUST-SOME-FRIES"
TAG = "version1"

FILES = [
    (ROOT / "submission" / "JustSomeFries_Windows.zip", "JustSomeFries_Windows.zip", "application/zip"),
    (ROOT / "submission" / "JustSomeFries_walkthrough.mp4", "JustSomeFries_walkthrough.mp4", "video/mp4"),
    (ROOT / "film" / "art_remaster_preview.mp4", "JustSomeFries_gameplay_preview.mp4", "video/mp4"),
]

NOTES = (
    "**Recommended: download `JustSomeFries_Windows.zip` and play locally.** Unzip, double-click `JustSomeFries.exe` (keep the `.pck` next to it). "
    "The in-browser page is only a light trial and may not run stably; the local version has clearer graphics and runs much more smoothly.\n\n"
    "Round 20: the big brother is a character now (one talk for every visit to his roof: your accessories, drinks, fish and each thing of the sky you catch; E talks to him any time) and the ending on the roof is rewritten; "
    "HOLD E fast-forwards the credits and the ending talk; the camera no longer jitters when you launch out of the sea in slow motion; the typing voice is gone and F has a soft new call; "
    "WATCH STORY on the title screen replays the opening and the ending once you have finished the game. Round 19: a steady beat for the rings, a sea-freeze fix, an UNSTICK button, three save slots. "
    "Round 17: the game speaks English, Simplified Chinese, Traditional Chinese and Japanese (pick the language on the first card; L on the title changes it). "
    "Round 16: FISH TIME (surf the sea, launch with Space), the moon and sun as nine circles, F calls a flock, two save slots and KEEP PLAYING, an opening and ending drawn as a four-panel comic (a tribute to *What Fries Ahead*, False Knees #319, by Joshua Barkman), a fix for take-off from the water, and a new trailer. "
    "Round 15 (final content pass): a TAB lesson for Gull Sight, RAINBOW TIME first on the board, a SKY HIGH quest (cloud, star, moon, sun, rainbow, plus a rain cloud), "
    "new drink effects, a friendlier town (strangers leave you drinks, puppies run circles), a rewritten ending on the roof, 24 achievements with a gallery, "
    "redrawn comic panels, a balanced gull and tailored outfits. Round 14: art remaster to match the cover (some props adapted from Kenney's CC0 packs).\n\n"
    "Windows 版推荐下载到本地游玩：网页版可能无法稳定运行，本地版画质更清晰、运行更流畅。游戏支持简体中文、繁體中文和日本語。"
)


def token():
    p = subprocess.run(["git", "credential", "fill"], input="protocol=https\nhost=github.com\n\n", capture_output=True, text=True, timeout=60)
    for line in p.stdout.splitlines():
        if line.startswith("password="):
            return line[9:]
    sys.exit("no GitHub token from the credential helper")


def api(method, url, tok, body=None):
    req = urllib.request.Request(url, method=method, data=(json.dumps(body).encode() if body is not None else None))
    req.add_header("Authorization", "Bearer " + tok)
    req.add_header("Accept", "application/vnd.github+json")
    req.add_header("X-GitHub-Api-Version", "2022-11-28")
    if body is not None:
        req.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(req, timeout=120) as r:
        data = r.read()
        return json.loads(data) if data else {}


def main():
    for f, _, _ in FILES:
        if not f.exists():
            sys.exit("missing " + str(f))
    tok = token()
    rel = api("GET", "https://api.github.com/repos/%s/releases/tags/%s" % (REPO, TAG), tok)
    rid = rel["id"]
    print("release", rid, rel["name"])
    # an asset that is already there with the same bytes (GitHub reports its sha256) is kept, not uploaded again
    have = {a["name"]: a for a in rel.get("assets", [])}
    todo = []
    for f, name, ctype in FILES:
        a = have.get(name)
        digest = "sha256:" + hashlib.sha256(f.read_bytes()).hexdigest()
        if a is not None and a.get("digest", "") == digest and a["size"] == f.stat().st_size:
            print("unchanged, kept:", name)
            continue
        if a is not None:
            api("DELETE", "https://api.github.com/repos/%s/releases/assets/%d" % (REPO, a["id"]), tok)
            print("deleted old asset", name)
        todo.append((f, name, ctype))
    for f, name, ctype in todo:
        url = "https://uploads.github.com/repos/%s/releases/%d/assets?name=%s" % (REPO, rid, name)
        print("uploading", name, round(f.stat().st_size / 1e6, 1), "MB ...", flush=True)
        r = subprocess.run(["curl", "-sS", "--fail-with-body", "-X", "POST", "-H", "Authorization: Bearer " + tok,
                            "-H", "Accept: application/vnd.github+json", "-H", "Content-Type: " + ctype,
                            "--data-binary", "@" + str(f), url, "-o", "NUL"], capture_output=True, text=True, timeout=3000)
        print("  exit", r.returncode, (r.stderr or "")[:200].replace(tok, "***"))
        if r.returncode != 0:
            sys.exit(1)
    api("PATCH", "https://api.github.com/repos/%s/releases/%d" % (REPO, rid), tok, {"body": NOTES})
    rel = api("GET", "https://api.github.com/repos/%s/releases/%d" % (REPO, rid), tok)
    for a in rel["assets"]:
        print("asset", a["name"], a["size"], a.get("digest", ""))


main()
