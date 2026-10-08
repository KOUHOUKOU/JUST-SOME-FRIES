import sys, copy
import numpy as np
import music9 as M, music9_end as E, sf_render as R
which = sys.argv[1] if len(sys.argv) > 1 else "title"
S, total = (M.title() if which == "title" else E.ending() if which == "ending" else E.ending_mem())
full, sr = R.render_wav(S, "bal_full", gain=0.85)
def db(x): return 20*np.log10(np.sqrt(np.mean(x**2))+1e-9)
print("FULL %.1f dB  peak %.2f" % (db(full), np.max(np.abs(full))))
progs = {}
for i, t in enumerate(S.tracks):
    S2 = copy.deepcopy(S)
    S2.tracks = [S2.tracks[i]]
    if not S2.tracks[0]["notes"]:
        continue
    x, _ = R.render_wav(S2, "bal_t", gain=0.85)
    print("track %d prog %3d  %.1f dB  (%d notes)" % (i, t["prog"], db(x), len(t["notes"])))
