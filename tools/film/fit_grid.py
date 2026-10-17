"""Fits a steady beat grid (period, phase) to a passage of a source recording:  python tools/film/fit_grid.py italian 30 72"""
import sys
import numpy as np
sys.path.insert(0, __import__("os").path.dirname(__import__("os").path.abspath(__file__)))
from music_probe import load


def flux_of(x, sr, n=1024, hop=128):
    win = np.hanning(n)
    prev = None
    out = []
    for i in range(0, len(x) - n, hop):
        S = np.log1p(np.abs(np.fft.rfft(x[i:i + n] * win)) * 8.0)
        out.append(0.0 if prev is None else float(np.sum(np.maximum(S - prev, 0.0))))
        prev = S
    f = np.array(out)
    f = f - np.convolve(f, np.ones(int(0.4 * sr / hop)) / int(0.4 * sr / hop), "same")
    f[f < 0] = 0
    return f, hop / sr


if __name__ == "__main__":
    name, a, b = sys.argv[1], float(sys.argv[2]), float(sys.argv[3])
    x, sr = load(name, a, b)
    f, dt = flux_of(x, sr)
    t = np.arange(len(f)) * dt + a
    best = None
    for P in np.arange(0.70, 0.95, 0.0005):
        for ph in np.arange(0.0, P, 0.01):
            g = np.arange(a + ph, b, P)
            idx = np.clip(((g - a) / dt).astype(int), 0, len(f) - 1)
            # a small window around each grid point
            s = sum(f[max(0, i - 2):i + 3].max() for i in idx)
            s /= len(idx)
            if best is None or s > best[0]:
                best = (s, P, ph)
    s, P, ph = best
    print("period %.4f s, a grid point at %.3f s (score %.2f)" % (P, a + ph, s))
    g = [a + ph + k * P for k in range(int((b - a) / P))]
    print("first grid points:", " ".join("%.2f" % v for v in g[:12]))
