"""Round 20: three soft, natural sounds. (python tools/audio/r20_audio.py [name ...] ; previews: shots/r20_preview.mp3)

lure       the call of F. It used to be a sawtooth with a nasal 1.5 / 2.9 kHz formant (a buzzing squawk). Now: a warm two-note coo, a round 'oo' that opens to an 'ah'
           (formants at 450 / 900 / 2200 Hz, soft harmonic roll-off, a little breath, a slow vibrato), in the room. Nothing above ~3 kHz.
page       a comic panel turns: a soft slide of paper and one muffled tap of wood. Noise only, nothing tonal that could ring.
surf_soft  a calm bed of the sea for the quiet last scene of the ending: two slow swells of pink noise under a moving low-pass, in stereo, seamlessly looped (20 s).
"""
import os, sys, shutil
import numpy as np
from scipy import signal
import synth
from synth import SR, bp, lp, hp, noise, t_of, fade, normalize, write_wav

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "game", "assets", "audio", "sfx")
rng = np.random.default_rng(20)


def vowel(f0_curve, dur, formants, breath=0.03, vib=0.012, vib_hz=5.2, rolloff=1.5):
    """a voiced sound: a harmonic source (1/n^rolloff) shaped by resonant formants. f0_curve(u) gives Hz, u = 0..1"""
    n = int(dur * SR)
    t = t_of(n)
    u = t / dur
    f = f0_curve(u) * (1.0 + vib * np.sin(2 * np.pi * vib_hz * t) * np.sin(np.pi * u))
    ph = np.cumsum(2 * np.pi * f / SR)
    src = np.zeros(n)
    for h in range(1, 28):
        fh = f * h
        amp = (1.0 / h ** rolloff) * (fh < SR * 0.42)
        src += amp * np.sin(h * ph)
    out = np.zeros(n)
    for fc, q, g in formants:
        sos = signal.tf2sos(*signal.iirpeak(fc / (SR / 2), q))
        out += g * signal.sosfilt(sos, src)
    out += breath * lp(noise(n), 3200, 2)
    env = np.minimum(t / 0.045, 1.0) ** 1.5 * np.exp(-((u - 0.45) / 0.55) ** 4) * np.minimum((dur - t) / 0.12, 1.0)
    return out * env


def lure():
    # note 1: 'oo' rising a fourth, note 2: a shorter 'ah' falling back; both a little under a gull's usual pitch, so that it reads as friendly
    a = vowel(lambda u: 330 + 90 * u ** 0.7, 0.46, [(450, 6, 1.0), (900, 8, 0.45), (2200, 10, 0.08)])
    b = vowel(lambda u: 420 - 70 * u, 0.40, [(700, 6, 1.0), (1150, 8, 0.4), (2300, 10, 0.07)])
    n = int(1.0 * SR)
    x = np.zeros(n)
    x[: len(a)] += a
    i = int(0.42 * SR)
    x[i:i + len(b)] += 0.8 * b
    x = lp(x, 3000, 2)
    st = np.stack([x, x], axis=1)
    st = synth.reverb(st, wet=0.22, seconds=0.9, damp=3500.0)
    m = fade(st.mean(axis=1), 0.004, 0.08)
    return normalize(m, 0.5)


def page():
    n = int(0.26 * SR)
    t = t_of(n)
    slide = bp(noise(n), 1400, 4200, 2) * np.exp(-((t - 0.07) / 0.06) ** 2) * 0.55
    slide = lp(slide, 4500, 2)
    tap_n = int(0.07 * SR)
    tt = t_of(tap_n)
    tap = bp(noise(tap_n), 160, 520, 2) * np.exp(-tt / 0.018) * np.minimum(tt / 0.001, 1.0)
    x = slide.copy()
    x[:tap_n] += 0.8 * tap
    x = fade(x, 0.003, 0.05)
    return normalize(x, 0.4)


def _loop_noise(n, xf):
    """pink noise of exactly n samples whose end flows into its start (equal-power cross-fade of the first `xf` samples with the extra tail)"""
    base = noise(n + xf, "pink")
    k = np.linspace(0, np.pi / 2, xf)
    y = base[:n].copy()
    y[:xf] = base[:xf] * np.sin(k) + base[n:n + xf] * np.cos(k)
    return y


def surf_soft():
    secs = 20
    n = secs * SR
    t = t_of(n)
    outs = []
    for ch in range(2):
        base = _loop_noise(n, SR)
        triple = np.tile(base, 3)                       # filter a tripled copy and keep the middle: no filter start-up at the seam
        dark = lp(triple, 380, 2)[n:2 * n]
        mid = lp(triple, 900, 2)[n:2 * n]
        bright = lp(triple, 1900, 1)[n:2 * n]
        # two slow swells, a whole number of cycles in 20 s (2 and 3), a different phase in each ear
        sw = 0.55 + 0.30 * np.sin(2 * np.pi * 2 * t / secs + ch * 0.9) + 0.15 * np.sin(2 * np.pi * 3 * t / secs + 1.7 + ch)
        w = np.clip(sw, 0, 1)
        y = dark * (1.0 - w) + mid * w + 0.35 * bright * w ** 2     # brighter as a swell comes in
        outs.append(y * (0.25 + 0.75 * sw))
    st = np.stack(outs, axis=1)
    st /= np.max(np.abs(st)) + 1e-9
    return st * 0.6


SOUNDS = {"lure": lure, "page": page, "surf_soft": surf_soft}

if __name__ == "__main__":
    names = sys.argv[1:] or list(SOUNDS)
    old = os.path.join(os.path.dirname(os.path.abspath(__file__)), "old_sfx_r20")
    os.makedirs(old, exist_ok=True)
    for nm in names:
        path = os.path.join(OUT, nm + ".wav")
        if os.path.exists(path) and not os.path.exists(os.path.join(old, nm + ".wav")):
            shutil.copy(path, os.path.join(old, nm + ".wav"))
        x = np.nan_to_num(SOUNDS[nm]())
        write_wav(x, path)
        print("%-10s %5.2f s  peak %.2f" % (nm, len(x) / SR, np.max(np.abs(x))))
