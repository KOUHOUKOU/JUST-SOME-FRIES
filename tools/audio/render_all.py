import sys, time, os
import numpy as np
from synth import *
import music

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "game", "assets", "audio", "music")
names = sys.argv[1:] or list(music.TRACKS.keys())
for n in names:
    t0 = time.time()
    x = music.TRACKS[n]()
    rms = float(np.sqrt(np.mean(x ** 2)))
    print("%-10s %6.1f s  peak %.2f  rms %.3f (%.1f dBFS)  %.1f s to render" % (n, len(x) / SR, np.max(np.abs(x)), rms, 20 * np.log10(rms + 1e-9), time.time() - t0), flush=True)
    write_ogg(x, os.path.join(OUT, n + ".ogg"), quality=4)
