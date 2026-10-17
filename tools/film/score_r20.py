"""The score of the round-20 trailer: real recordings (Musopen, public domain: see the credits of the game) edited into one piece with an arc, plus a few synthesised hits.

    python tools/film/score_r20.py [T_HIT]      ->  film/score_r20.wav (48 kHz stereo) and film/score_r20_beats.json

  0.0 - 17     Debussy, Clair de lune (the story: one fry on the floor, a hungry gull)
 16.4 - 54     Grieg, Morning Mood: the quiet start, the swell on the first dive (src 49 s = trailer 27 s), the full orchestra, the last phrase
 51.7 - 89.7   Mendelssohn, 'Italian' symphony, first movement: the drop at src 35.3 s = trailer 54.0 (RAINBOW TIME), the whole sunny second theme
 89.5 - 120    Dvorak, Largo (New World): the long build, the great climax at src 490 s = trailer T_HIT, then the quiet return
  + a riser into the drop, a deep hit on the drop, a low hit under the title
The loudness of every piece is levelled to the same range; the joins are equal-power cross-fades. Beat times (strong onsets of the finished score) go to the json for the editor.
"""
import json, os, subprocess, sys
import numpy as np
from scipy import signal

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "tools", "audio", "src")
FILM = os.path.join(ROOT, "film")
SR = 48000


def read(name, a, b):
    f = [x for x in os.listdir(os.path.join(SRC, name)) if x.startswith("src.")][0]
    cmd = ["ffmpeg", "-v", "error", "-ss", str(a), "-t", str(b - a), "-i", os.path.join(SRC, name, f), "-ac", "2", "-ar", str(SR), "-f", "f32le", "-"]
    return np.frombuffer(subprocess.run(cmd, capture_output=True, check=True).stdout, dtype="<f4").reshape(-1, 2).astype(np.float64)


def rms_db(x):
    return 20 * np.log10(np.sqrt(np.mean(x ** 2)) + 1e-9)


def envelope_gain(x, target_db, win=3.0, strength=0.5, max_db=7.0):
    """a slow leveller (quiet passages are lifted a little, the loudest are held): keeps the arc of the music but not its extremes"""
    mono = x.mean(axis=1)
    hop = int(0.25 * SR)
    w = int(win * SR)
    env = np.array([20 * np.log10(np.sqrt(np.mean(mono[max(0, i - w // 2): i + w // 2] ** 2)) + 1e-7) for i in range(0, len(mono), hop)])
    g = np.clip(-(env - target_db) * strength, -max_db, max_db)
    t_env = np.arange(len(env)) * hop
    gain = 10 ** (np.interp(np.arange(len(mono)), t_env, g) / 20.0)
    return x * gain[:, None]


def place(buf, x, t, fade_in, fade_out):
    n = len(x)
    x = x.copy()
    if fade_in > 0:
        k = int(fade_in * SR)
        x[:k] *= np.sin(np.linspace(0, np.pi / 2, k))[:, None]
    if fade_out > 0:
        k = int(fade_out * SR)
        x[-k:] *= np.cos(np.linspace(0, np.pi / 2, k))[:, None]
    i = int(t * SR)
    m = min(n, len(buf) - i)
    buf[i:i + m] += x[:m]


def noise_riser(dur, f0=300.0, f1=9000.0, seed=3):
    rng = np.random.default_rng(seed)
    n = int(dur * SR)
    w = rng.standard_normal(n)
    out = np.zeros(n)
    blocks = 40
    L = n // blocks
    for b in range(blocks):
        fc = f0 * (f1 / f0) ** (b / blocks)
        sos = signal.butter(2, [fc * 0.7 / (SR / 2), min(fc * 1.4, SR * 0.45) / (SR / 2)], "band", output="sos")
        out[b * L:(b + 1) * L] = signal.sosfilt(sos, w[b * L:(b + 1) * L])
    env = np.linspace(0, 1, n) ** 2.2
    return out * env


def boom(dur=2.4, f0=62.0, f1=28.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = f1 + (f0 - f1) * np.exp(-t / 0.35)
    ph = 2 * np.pi * np.cumsum(f) / SR
    body = np.sin(ph) * np.exp(-t / 0.9)
    rng = np.random.default_rng(5)
    sos = signal.butter(2, 900 / (SR / 2), "low", output="sos")
    burst = signal.sosfilt(sos, rng.standard_normal(n)) * np.exp(-t / 0.12)
    return body * 0.9 + burst * 0.5


def main():
    A = json.load(open(os.path.join(FILM, "anchors_r20.json")))
    SWELL, DROP, E_START, T_HIT, TITLE, TOTAL = A["SWELL"], A["DROP"] + 0.1, A["E_START"], A["T_HIT"] + 0.15, A["TITLE"], A["TOTAL"]
    buf = np.zeros((int((TOTAL + 1.0) * SR), 2))
    # --- 1 Clair de lune
    x = read("clair", 0.6, 17.4)
    x = envelope_gain(x, -27.0, strength=0.4)
    place(buf, x, 0.0, 0.0, 2.0)
    # --- 2 Morning Mood: the swell (src 48.6 s) lands on the steal; it ends a beat after the drop begins
    sw_src = 48.6
    t_in = 15.0
    src_in = sw_src - (SWELL + 0.25 - t_in)
    src_out = sw_src + (DROP - SWELL - 0.25) + 1.2
    x = read("morning", src_in, src_out)
    x = envelope_gain(x, -23.0, strength=0.3, max_db=5.0)
    place(buf, x * 0.95, t_in, 2.4, 1.0)
    # --- 3 the Italian symphony: the drop (src 35.47 s, the grid fitted by fit_grid.py) = the RAINBOW TIME lettering
    d_src = 35.47
    x = read("italian", d_src - 3.0, d_src + (E_START - DROP) + 1.4)
    x = envelope_gain(x, -16.0, strength=0.5, max_db=7.0)
    place(buf, x * 1.12, DROP - 3.0, 2.0, 2.4)
    # --- 4 the Largo: its climax (src 490 s) = "...same."
    pre = (T_HIT - E_START) + 1.0
    x = read("largo", 490.0 - pre, 490.0 + (TOTAL - T_HIT) + 0.3)
    x = envelope_gain(x, -22.0, strength=0.45, max_db=8.0)
    place(buf, x * 1.1, E_START - 1.0, 3.0, 3.5)
    # --- the hits
    rs = noise_riser(3.4)
    place(buf, np.stack([rs, rs], axis=1) * 0.16, DROP - 3.4, 0.0, 0.0)
    b1 = boom()
    place(buf, np.stack([b1, b1], axis=1) * 0.42, DROP, 0.0, 0.0)
    b2 = boom(3.6, 55.0, 26.0)
    place(buf, np.stack([b2, b2], axis=1) * 0.34, TITLE + 0.4, 0.0, 0.0)
    # a soft master: gentle saturation, nothing above -1 dB
    buf = np.tanh(buf * 1.1) / np.tanh(1.1)
    buf /= max(1.0, np.max(np.abs(buf)) / 0.89)
    import wave
    pcm = (np.clip(buf, -1, 1) * 32767).astype("<i2")
    out = os.path.join(FILM, "score_r20.wav")
    with wave.open(out, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print("score", round(len(buf) / SR, 1), "s, peak %.2f" % np.max(np.abs(buf)), A)

main()
