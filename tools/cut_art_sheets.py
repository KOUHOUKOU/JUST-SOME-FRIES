import sys, os
from PIL import Image, ImageDraw
import numpy as np

ROOT = r"C:\Users\ROG\Desktop\JUST_SOME_FRIES_CODEX_WORKSPACE_v1.0\JUST_SOME_FRIES"
SRC = os.path.join(ROOT, "art_src", "r15")
COMICS = os.path.join(ROOT, "game", "assets", "ui", "comics")
ACHV = os.path.join(ROOT, "game", "assets", "ui", "achv")
os.makedirs(COMICS, exist_ok=True)
os.makedirs(ACHV, exist_ok=True)


def runs(mask1d, min_gap=4, min_len=60):
    out = []
    start = None
    gap = 0
    for i, v in enumerate(mask1d):
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


def tiles(path, ncol, nrow):
    im = Image.open(path).convert("RGB")
    a = np.asarray(im).astype(int)
    nonwhite = (a.sum(axis=2) < 740)  # not (near) white
    cols = runs(nonwhite.sum(axis=0) > 30)
    rows = runs(nonwhite.sum(axis=1) > 30)
    print(os.path.basename(path), "cols", cols, "rows", rows)
    assert len(cols) == ncol and len(rows) == nrow, (len(cols), len(rows))
    out = []
    for r in rows:
        for c in cols:
            out.append(im.crop((c[0], r[0], c[1], r[1])))
    return out


def save_comics(path, ids):
    ts = tiles(path, 3, 3)
    for t, i in zip(ts, ids):
        w, h = t.size
        m = 7                      # drop the sheet's own outline + a hair of the white gutter
        t = t.crop((m, m, w - m, h - m)).resize((384, 384), Image.LANCZOS)
        t.save(os.path.join(COMICS, i + ".png"))


def icon_tiles(path):
    import scipy.ndimage as ndi
    im = Image.open(path).convert("RGB")
    a = np.asarray(im).astype(int)
    nw = ndi.binary_opening(a.sum(axis=2) < 735, structure=np.ones((5, 5)))
    lab, n = ndi.label(nw)
    boxes = []
    for o in ndi.find_objects(lab):
        h = o[0].stop - o[0].start
        w = o[1].stop - o[1].start
        if h > 120 and w > 120:
            boxes.append((o[0].start, o[1].start, o[0].stop, o[1].stop))
    boxes.sort(key=lambda b: (round(b[0] / 100), b[1]))
    assert len(boxes) == 24
    out = []
    for (y0, x0, y1, x1) in boxes:
        w, h = x1 - x0, y1 - y0
        side = min(w, h) - 8
        cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
        out.append(im.crop((cx - side // 2, cy - side // 2, cx + side // 2, cy + side // 2)))
    return out


def save_icons(path, ids):
    ts = icon_tiles(path)
    for t, i in zip(ts, ids):
        t = t.resize((192, 192), Image.LANCZOS).convert("RGBA")
        mask = Image.new("L", (192, 192), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, 191, 191), radius=30, fill=255)
        t.putalpha(mask)
        d = ImageDraw.Draw(t)
        d.rounded_rectangle((1, 1, 190, 190), radius=30, outline=(22, 24, 44, 255), width=5)
        t.save(os.path.join(ACHV, i + ".png"))


save_comics(os.path.join(SRC, "sheet_comics_1.png"), ["smug", "perfect", "mischief", "cool", "fish", "soaked", "rival", "scare", "calm"])
save_comics(os.path.join(SRC, "sheet_comics_2.png"), ["hit_swat_punch", "hit_swat_poke", "hit_swat_sweep", "hit_swat_squirt", "hit_swat_lunge", "hit_crash", "hit_swat_ball", "hit_swat_rival", "hit_swat_grump"])
save_comics(os.path.join(SRC, "sheet_comics_3.png"), ["gift", "friend", "puppy", "cloud", "raincloud", "star", "moon", "sun", "rainbow"])
save_icons(os.path.join(SRC, "sheet_icons.png"), ["first_fry", "plain_first", "enough", "all24", "seven", "rainbowfry", "rainbowtime", "happyhour", "skyall", "clouds2", "moon", "sun",
                                                  "star", "fishall", "bigfish", "wearall", "brolook", "friend", "kind", "puppy", "thermal", "skim", "wall", "innocent"])
print("done")
