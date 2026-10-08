"""Round 12: the calls of the gulls (gull_far, chirp, proud, lure, cry, rival_call) were written to RISE and were then cut off at their loudest point: a weak sound that grows
and suddenly disappears - heard as a strange noise now and then, most of all at sea and in the quiet of the ending. Every call now fades out naturally (a cosine tail over the
last ~40 % of its length) and fades in over 12 ms. Run once after render_sfx.py (it keeps a copy of the originals in old_sfx_r11/)."""
import wave, os, shutil, numpy as np
HERE = os.path.dirname(os.path.abspath(__file__))
SFX = os.path.join(HERE, "..", "..", "game", "assets", "audio", "sfx")
BAK = os.path.join(HERE, "old_sfx_r11")
CALLS = {"gull_far": 0.45, "chirp": 0.4, "proud": 0.4, "lure": 0.4, "cry": 0.35, "rival_call": 0.4}
os.makedirs(BAK, exist_ok=True)
for n, tail in CALLS.items():
    p = os.path.join(SFX, n + ".wav")
    b = os.path.join(BAK, n + ".wav")
    if not os.path.exists(b):
        shutil.copy2(p, b)
    w = wave.open(b)
    sr, ch, sw = w.getframerate(), w.getnchannels(), w.getsampwidth()
    x = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2").astype(np.float64)
    w.close()
    L = len(x) // ch
    x = x.reshape(L, ch)
    env = np.ones(L)
    f = int(0.012 * sr)
    env[:f] = np.linspace(0, 1, f) ** 2
    t0 = int(L * (1.0 - tail))
    env[t0:] = 0.5 * (1 + np.cos(np.pi * np.linspace(0, 1, L - t0)))
    y = (x * env[:, None]).astype("<i2")
    with wave.open(p, "wb") as o:
        o.setnchannels(ch); o.setsampwidth(sw); o.setframerate(sr); o.writeframes(y.tobytes())
    print("faded", n, "%.2f s" % (L / sr))
