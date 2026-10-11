"""Round 16: cut the Codex sheets (art_src/r16/sheet_*.png, 3x3 panels with white gutters) into the game's pictures.
   python tools/cut_r16.py [a b c d e ...]"""
import sys, os
from PIL import Image
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "art_src", "r16")
COMICS = os.path.join(ROOT, "game", "assets", "ui", "comics")
ILLU = os.path.join(ROOT, "game", "assets", "ui", "art")
ACHV = os.path.join(ROOT, "game", "assets", "ui", "achv")
YK = os.path.join(ROOT, "game", "assets", "ui", "yonkoma")
for d in (COMICS, ILLU, ACHV, YK):
    os.makedirs(d, exist_ok=True)

IDS = {
    "a": ("sheet_comics_a.png", COMICS, ["smug", "perfect", "mischief", "cool", "fish", "soaked", "rival", "scare", "calm"]),
    "b": ("sheet_comics_b.png", COMICS, ["hit_swat_punch", "hit_swat_poke", "hit_swat_sweep", "hit_swat_squirt", "hit_swat_lunge", "hit_crash", "hit_swat_ball", "hit_swat_rival", "hit_swat_grump"]),
    "c": ("sheet_comics_c.png", COMICS, ["gift", "friend", "puppy", "cloud", "raincloud", "star", "moon", "sun", "rainbow"]),
    "d": ("sheet_comics_d.png", COMICS, ["fishtime", "fishcombo", "call_roof", "call_hello", "call_shoo", "tablesson", "roof_rest", "bro_talk", "free_play"]),
    "g": ("sheet_yonkoma.png", YK, ["p1", "p2", "p3", "p4"]),
    "h": ("sheet_open.png", YK, ["o1", "o2", "o3", "o4"]),
    "e": ("sheet_icons_a.png", ILLU, ["icon", "plain_fry", "fry_red", "fry_orange", "fry_green", "fry_cyan", "fry_blue", "fry_purple", "fry_pink"]),
}


def runs(mask, min_gap=3, min_len=80):
    out = []
    start = None
    gap = 0
    end = 0
    for i, v in enumerate(mask):
        if v:
            if start is None:
                start = i
            gap = 0
            end = i
        else:
            if start is not None:
                gap += 1
                if gap >= min_gap:
                    if end - start >= min_len:
                        out.append((start, end + 1))
                    start = None
    if start is not None and end - start >= min_len:
        out.append((start, end + 1))
    return out


def tiles(path, n=3):
    im = Image.open(path).convert("RGB")
    a = np.asarray(im).astype(int)
    nonwhite = a.sum(axis=2) < 735
    cols = runs(nonwhite.sum(axis=0) > 40)
    rows = runs(nonwhite.sum(axis=1) > 40)
    print(os.path.basename(path), im.size, "cols", cols, "rows", rows)
    if len(cols) != n or len(rows) != n:
        # fall back to an even grid inside the outer margin
        xs = np.where(nonwhite.sum(axis=0) > 40)[0]
        ys = np.where(nonwhite.sum(axis=1) > 40)[0]
        x0, x1, y0, y1 = xs[0], xs[-1] + 1, ys[0], ys[-1] + 1
        cw = (x1 - x0) / n
        ch = (y1 - y0) / n
        cols = [(int(x0 + i * cw), int(x0 + (i + 1) * cw)) for i in range(n)]
        rows = [(int(y0 + i * ch), int(y0 + (i + 1) * ch)) for i in range(n)]
        print("  (even grid fallback)")
    out = []
    for r in rows:
        for c in cols:
            out.append(im.crop((c[0], r[0], c[1], r[1])))
    return out


def main(keys):
    for k in keys:
        fname, outdir, ids = IDS[k]
        p = os.path.join(SRC, fname)
        if not os.path.exists(p):
            print("missing", p)
            continue
        for t, i in zip(tiles(p, 2 if k in ("g", "h") else 3), ids):
            w, h = t.size
            m = 6          # drop a hair of the white gutter; the panel keeps its own ink frame
            t = t.crop((m, m, w - m, h - m)).resize((640, 640) if k in ("g", "h") else (384, 384), Image.LANCZOS)
            t.save(os.path.join(outdir, i + ".png"))
        print("cut", k, len(ids))


if __name__ == "__main__":
    main(sys.argv[1:] or list(IDS))
