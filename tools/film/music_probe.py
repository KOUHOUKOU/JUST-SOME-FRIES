"""Looks at the source recordings (tools/audio/src/*) before the trailer's score is cut: loudness per second and the strongest onsets.
    python tools/film/music_probe.py italian 0 90
"""
import subprocess, sys, os
import numpy as np

SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio", "src")


def load(name, a, b, sr=16000):
    f = [x for x in os.listdir(os.path.join(SRC, name)) if x.startswith("src.")][0]
    cmd = ["ffmpeg", "-v", "error", "-ss", str(a), "-t", str(b - a), "-i", os.path.join(SRC, name, f), "-ac", "1", "-ar", str(sr), "-f", "f32le", "-"]
    return np.frombuffer(subprocess.run(cmd, capture_output=True, check=True).stdout, dtype="<f4"), sr


def envelope(x, sr, hop=0.5):
    n = int(hop * sr)
    return np.array([20 * np.log10(np.sqrt(np.mean(x[i:i + n] ** 2)) + 1e-6) for i in range(0, len(x) - n, n)])


def onsets(x, sr, thr=1.6):
    """spectral-flux onsets (times in s, strength)"""
    n, hop = 1024, 256
    win = np.hanning(n)
    prev = None
    flux = []
    for i in range(0, len(x) - n, hop):
        S = np.abs(np.fft.rfft(x[i:i + n] * win))
        S = np.log1p(S * 8.0)
        if prev is not None:
            flux.append(np.sum(np.maximum(S - prev, 0.0)))
        else:
            flux.append(0.0)
        prev = S
    flux = np.array(flux)
    k = int(0.5 * sr / hop)
    med = np.array([np.median(flux[max(0, i - k):i + k]) for i in range(len(flux))])
    out = []
    last = -1.0
    for i in range(1, len(flux) - 1):
        t = i * hop / sr
        if flux[i] > flux[i - 1] and flux[i] >= flux[i + 1] and flux[i] > med[i] * thr + 1.0 and t - last > 0.18:
            out.append((t, float(flux[i] / (med[i] + 1.0))))
            last = t
    return out


if __name__ == "__main__":
    name, a, b = sys.argv[1], float(sys.argv[2]), float(sys.argv[3])
    x, sr = load(name, a, b)
    env = envelope(x, sr, 1.0)
    print("loudness per second (dB), start at %.0f s:" % a)
    print(" ".join("%d" % round(v) for v in env))
    on = onsets(x, sr)
    print("onsets:", len(on), " strongest 24:", " ".join("%.2f" % (t + a) for t, s in sorted(sorted(on, key=lambda z: -z[1])[:24])))
