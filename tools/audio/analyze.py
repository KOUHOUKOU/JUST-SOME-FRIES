
import sys, numpy as np, subprocess, wave
from synth import SR
# usage: analyze.py file.ogg : decodes with ffmpeg and prints loudness, pitch-class energy and a few sanity numbers
p = sys.argv[1]
raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", p, "-f", "s16le", "-ac", "1", "-ar", str(SR), "-"], capture_output=True).stdout
x = np.frombuffer(raw, dtype="<i2").astype(np.float64) / 32768.0
rms = np.sqrt(np.mean(x ** 2))
print("%s: %.1f s  rms %.1f dBFS  peak %.2f  clipped %.3f%%" % (p, len(x) / SR, 20 * np.log10(rms + 1e-9), np.max(np.abs(x)), 100.0 * np.mean(np.abs(x) > 0.98)))
n = 2 ** 15
chroma = np.zeros(12)
win = np.hanning(n)
for i in range(0, len(x) - n, n):
    sp = np.abs(np.fft.rfft(x[i:i + n] * win))
    fr = np.fft.rfftfreq(n, 1.0 / SR)
    for k in range(1, len(sp)):
        f = fr[k]
        if 80 < f < 2000:
            pc = int(round(12 * np.log2(f / 440.0) + 69)) % 12
            chroma[pc] += sp[k] ** 2
chroma /= chroma.sum()
names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
order = np.argsort(-chroma)
print("pitch classes: " + "  ".join("%s %.0f%%" % (names[i], 100 * chroma[i]) for i in order[:8]))
# loop seam: the last 50 ms vs the first 50 ms
a = x[-1600:]
b = x[:1600]
print("loop seam: end rms %.4f, start rms %.4f, jump at the seam %.4f" % (np.sqrt(np.mean(a ** 2)), np.sqrt(np.mean(b ** 2)), abs(x[-1] - x[0])))
