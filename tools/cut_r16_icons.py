import sys, os
sys.path.insert(0, r'C:\Users\ROG\Desktop\JUST_SOME_FRIES_CODEX_WORKSPACE_v1.0\JUST_SOME_FRIES\tools')
import numpy as np
from PIL import Image
import scipy.ndimage as ndi
import cut_r16 as C

ids = ["first_fry", "plain_first", "enough", "all24", "seven", "rainbowfry", "rainbowtime", "happyhour", "skyall", "clouds2", "moon", "sun",
       "star", "fishall", "bigfish", "wearall", "brolook", "friend", "kind", "puppy", "thermal", "skim", "wall", "innocent",
       "fishstreak", "callgulls", "callkind", "callshoo", "freeplay", "locked"]
path = os.path.join(C.SRC, "sheet_icons_b.png")
im = Image.open(path).convert("RGB")
a = np.asarray(im).astype(int)
nonwhite = a.sum(axis=2) < 735
cols = C.runs(nonwhite.sum(axis=0) > 40, min_gap=3, min_len=60)
rows = C.runs(nonwhite.sum(axis=1) > 40, min_gap=3, min_len=60)
print(len(cols), cols, len(rows), rows)
assert len(cols) == 6 and len(rows) == 5
k = 0
for r in rows:
    for c in cols:
        t = im.crop((c[0] - 2, r[0] - 2, c[1] + 2, r[1] + 2)).resize((192, 192), Image.LANCZOS).convert("RGBA")
        arr = np.asarray(t).copy()
        white = (arr[:, :, :3].astype(int).sum(axis=2) > 735)
        lab, n = ndi.label(white)
        border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
        for b in border:
            arr[lab == b, 3] = 0
        Image.fromarray(arr).save(os.path.join(C.ACHV, ids[k] + ".png"))
        k += 1
print("icons", k)
