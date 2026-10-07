"""
A small offline synthesizer for JUST SOME FRIES (numpy + scipy only).
Everything is rendered to float arrays at SR and written out as .ogg with ffmpeg.
Instruments are physical-ish models (modal piano / harp / bells / marimba, detuned string pad, breathy flute, reed),
effects are a stereo room reverb (generated impulse response) and soft limiting.
"""
import numpy as np
from scipy import signal
import subprocess, os, wave, struct

SR = 32000
rng = np.random.default_rng(7)


# ------------------------------------------------------------------ basics
def hz(m):
    return 440.0 * 2.0 ** ((m - 69) / 12.0)


NOTE_BASE = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def midi(name):
    """'F#5' -> 78, 'Bb3' -> 58"""
    n = NOTE_BASE[name[0]]
    i = 1
    while i < len(name) and name[i] in "#b":
        n += 1 if name[i] == "#" else -1
        i += 1
    return n + 12 * (int(name[i:]) + 1)


def t_of(n):
    return np.arange(n) / SR


def adsr(n, a, d, s, r):
    e = np.ones(n)
    na = max(int(a * SR), 1)
    nd = max(int(d * SR), 1)
    nr = max(int(r * SR), 1)
    e[:na] = np.linspace(0, 1, na)[:n]
    if n > na:
        k = min(nd, n - na)
        e[na:na + k] = np.linspace(1, s, k)
        e[na + k:] = s
    if n > nr:
        e[-nr:] *= np.linspace(1, 0, nr)
    return e


def lp(x, fc, order=2):
    sos = signal.butter(order, min(fc, SR * 0.45) / (SR / 2), "low", output="sos")
    return signal.sosfilt(sos, x)


def hp(x, fc, order=2):
    sos = signal.butter(order, fc / (SR / 2), "high", output="sos")
    return signal.sosfilt(sos, x)


def bp(x, f0, f1, order=2):
    sos = signal.butter(order, [f0 / (SR / 2), min(f1, SR * 0.45) / (SR / 2)], "band", output="sos")
    return signal.sosfilt(sos, x)


def noise(n, color="white"):
    w = rng.standard_normal(n)
    if color == "pink":
        b = [0.049922035, -0.095993537, 0.050612699, -0.004408786]
        a = [1, -2.494956002, 2.017265875, -0.522189400]
        w = signal.lfilter(b, a, w)
        w /= np.max(np.abs(w)) + 1e-9
    elif color == "brown":
        w = np.cumsum(w)
        w -= np.linspace(w[0], w[-1], n)
        w /= np.max(np.abs(w)) + 1e-9
    return w


def normalize(x, peak=0.89):
    m = np.max(np.abs(x)) + 1e-9
    return x * (peak / m)


def normalize_rms(x, target_db=-23.0, peak_limit=0.93):
    r = np.sqrt(np.mean(x ** 2)) + 1e-9
    y = x * (10 ** (target_db / 20.0) / r)
    m = np.max(np.abs(y))
    if m > peak_limit:
        y = np.tanh(y / peak_limit) * peak_limit            # a soft ceiling rather than a hard clip
    return y


def fade(x, fin=0.005, fout=0.02):
    x = x.copy()
    ni = int(fin * SR)
    no = int(fout * SR)
    if ni > 0 and len(x) > ni:
        x[:ni] *= np.linspace(0, 1, ni)
    if no > 0 and len(x) > no:
        x[-no:] *= np.linspace(1, 0, no)
    return x


def softclip(x, k=1.0):
    return np.tanh(x * k) / np.tanh(k)


def stereo(mono, pan=0.0):
    """pan -1..1 (equal power)"""
    a = (pan + 1.0) * np.pi / 4.0
    return np.stack([mono * np.cos(a), mono * np.sin(a)], axis=1)


def mix_into(buf, x, start_sec, gain=1.0):
    i0 = int(start_sec * SR)
    if i0 >= len(buf):
        return
    n = min(len(x), len(buf) - i0)
    if n > 0:
        buf[i0:i0 + n] += x[:n] * gain


def mix_st(buf, x, start_sec, gain=1.0):
    i0 = int(start_sec * SR)
    if i0 >= buf.shape[0]:
        return
    n = min(x.shape[0], buf.shape[0] - i0)
    if n > 0:
        buf[i0:i0 + n] += x[:n] * gain


# ------------------------------------------------------------------ reverb
_ir_cache = {}


def room_ir(seconds=2.2, damp=4500.0, pre=0.012, seed=3):
    key = (seconds, damp, pre, seed)
    if key in _ir_cache:
        return _ir_cache[key]
    r = np.random.default_rng(seed)
    n = int(seconds * SR)
    t = np.arange(n) / SR
    out = []
    for ch in range(2):
        w = r.standard_normal(n)
        w = w * np.exp(-t * (6.9 / seconds))                       # -60 dB at `seconds`
        # early reflections
        for k in range(12):
            d = int((0.004 + 0.011 * k + 0.003 * r.random()) * SR)
            if d < n:
                w[d] += (0.7 ** k) * (1 if r.random() < 0.5 else -1) * 1.8
        w = lp(w, damp, 1)
        # darker tail
        tail = lp(w, 1800, 1)
        mixk = np.clip(t / seconds * 1.6, 0, 1)
        w = w * (1 - mixk) + tail * mixk
        w[: int(pre * SR)] = 0
        out.append(w)
    ir = np.stack(out, axis=1)
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    _ir_cache[key] = ir
    return ir


def reverb(x, wet=0.25, seconds=2.2, damp=4500.0, seed=3):
    """x: (n,2) -> (n,2) dry/wet mix, same length (tail is cut: render with a tail yourself)"""
    ir = room_ir(seconds, damp, seed=seed)
    l = signal.fftconvolve(x[:, 0], ir[:, 0])[: len(x)]
    r = signal.fftconvolve(x[:, 1], ir[:, 1])[: len(x)]
    wetsig = np.stack([l, r], axis=1)
    return x * (1.0 - wet * 0.5) + wetsig * wet * 2.2


# ------------------------------------------------------------------ instruments (all return mono float arrays)
def piano(f, dur, vel=0.7, bright=1.0):
    n = int((dur + 0.5) * SR)
    t = t_of(n)
    out = np.zeros(n)
    B = 0.00018 * (f / 261.0) ** 1.4
    base_tau = 3.6 * (261.0 / f) ** 0.55 + 0.4
    nh = 9
    for k in range(1, nh + 1):
        fk = f * k * np.sqrt(1 + B * k * k)
        if fk > SR * 0.45:
            break
        amp = (1.0 / k ** (1.05 - 0.25 * vel)) * (1.0 if k < 3 else bright * (0.55 + 0.6 * vel))
        tau = base_tau / (1.0 + 0.9 * (k - 1))
        ph = rng.uniform(0, 2 * np.pi)
        out += amp * np.sin(2 * np.pi * fk * t + ph) * np.exp(-t / tau)
    # two slightly detuned strings: a little beating in the fundamental
    out += 0.35 * np.sin(2 * np.pi * f * 1.0013 * t) * np.exp(-t / (base_tau * 0.9))
    # hammer thump
    nh2 = int(0.012 * SR)
    ham = lp(rng.standard_normal(nh2), 2400 * (0.6 + vel)) * np.hanning(nh2) * 0.5
    out[:nh2] += ham
    env = np.ones(n)
    nr = int(0.18 * SR)
    off = int(dur * SR)
    if off < n:
        env[off:] = np.exp(-np.arange(n - off) / (0.09 * SR))
    out *= env * np.minimum(t / 0.002, 1.0)
    return out * (0.12 + 0.2 * vel)


def harp(f, dur, vel=0.7):
    n = int((max(dur, 1.4) + 0.6) * SR)
    t = t_of(n)
    out = np.zeros(n)
    for k in range(1, 12):
        fk = f * k
        if fk > SR * 0.45:
            break
        out += (1.0 / k ** 1.25) * np.sin(2 * np.pi * fk * t + k) * np.exp(-t / (1.7 / (k ** 0.8)))
    pick = int(0.006 * SR)
    out[:pick] += lp(rng.standard_normal(pick), 3500) * 0.2 * np.hanning(pick)
    return out * (0.1 + 0.18 * vel) * np.minimum(t / 0.0015, 1.0)


def guitar(f, dur, vel=0.7):
    n = int((max(dur, 0.9) + 0.4) * SR)
    t = t_of(n)
    out = np.zeros(n)
    for k in range(1, 14):
        fk = f * k
        if fk > SR * 0.45:
            break
        out += (1.0 / k ** 1.1) * np.sin(2 * np.pi * fk * t) * np.exp(-t / (1.1 / (k ** 0.55)))
    out = lp(out, 2800, 1) * 1.6
    pick = int(0.004 * SR)
    out[:pick] += hp(rng.standard_normal(pick), 800) * 0.1
    return out * (0.1 + 0.16 * vel) * np.minimum(t / 0.001, 1.0)


def bell(f, dur, vel=0.7, ratios=(1.0, 2.756, 5.404, 8.93), decays=(1.8, 0.8, 0.35, 0.18)):
    n = int((max(dur, 0.6) + 1.2) * SR)
    t = t_of(n)
    out = np.zeros(n)
    for r, tau, a in zip(ratios, decays, (1.0, 0.45, 0.2, 0.08)):
        fk = f * r
        if fk > SR * 0.45:
            continue
        out += a * np.sin(2 * np.pi * fk * t) * np.exp(-t / tau)
    return out * (0.08 + 0.14 * vel) * np.minimum(t / 0.002, 1.0)


def musicbox(f, dur, vel=0.7):
    return bell(f, dur, vel, ratios=(1.0, 2.0, 3.0, 4.2), decays=(1.1, 0.5, 0.25, 0.1))


def marimba(f, dur, vel=0.7):
    n = int(1.1 * SR)
    t = t_of(n)
    out = np.sin(2 * np.pi * f * t) * np.exp(-t / 0.45)
    out += 0.45 * np.sin(2 * np.pi * f * 3.95 * t) * np.exp(-t / 0.09)
    out += 0.12 * np.sin(2 * np.pi * f * 9.2 * t) * np.exp(-t / 0.03)
    k = int(0.004 * SR)
    out[:k] += lp(rng.standard_normal(k), 1800) * 0.25
    return out * (0.14 + 0.2 * vel) * np.minimum(t / 0.001, 1.0)


def strings(f, dur, vel=0.5, voices=5, detune=9.0, attack=0.45, release=0.7, cutoff=2400):
    n = int((dur + release) * SR)
    t = t_of(n)
    out = np.zeros(n)
    for v in range(voices):
        cents = (v - (voices - 1) / 2.0) * detune / max((voices - 1) / 2.0, 1)
        ff = f * 2.0 ** (cents / 1200.0)
        # vibrato that is different for every voice
        vib = 1.0 + 0.0035 * np.sin(2 * np.pi * (4.6 + 0.37 * v) * t + v)
        ph = 2 * np.pi * np.cumsum(ff * vib) / SR
        out += signal.sawtooth(ph + v)
    out = lp(out / voices, cutoff, 2)
    env = adsr(n, attack, 0.2, 0.9, release)
    return out * env * (0.14 + 0.1 * vel)


def flute(f, dur, vel=0.6, vib_depth=0.004):
    n = int((dur + 0.25) * SR)
    t = t_of(n)
    vib = 1.0 + vib_depth * np.sin(2 * np.pi * 5.1 * t) * np.clip((t - 0.2) / 0.3, 0, 1)
    ph = 2 * np.pi * np.cumsum(f * vib) / SR
    tone = np.sin(ph) + 0.22 * np.sin(2 * ph) + 0.06 * np.sin(3 * ph)
    breath = bp(noise(n), 1500, 5200) * 0.07
    env = adsr(n, 0.07, 0.1, 0.85, 0.2)
    return (tone + breath * (0.5 + env)) * env * (0.15 + 0.1 * vel)


def reed(f, dur, vel=0.6):
    n = int((dur + 0.2) * SR)
    t = t_of(n)
    trem = 1.0 + 0.12 * np.sin(2 * np.pi * 5.8 * t)
    ph = 2 * np.pi * np.cumsum(f * (1 + 0.002 * np.sin(2 * np.pi * 5.0 * t))) / SR
    x = signal.sawtooth(ph, 0.3) * 0.6 + np.sin(ph) * 0.5 + signal.square(ph + 0.4) * 0.15
    x = lp(x, 2600, 2)
    return x * adsr(n, 0.05, 0.1, 0.85, 0.15) * trem * (0.1 + 0.1 * vel)


def brass(f, dur, vel=0.8):
    n = int((dur + 0.15) * SR)
    t = t_of(n)
    ph = 2 * np.pi * np.cumsum(f * (1 + 0.002 * np.sin(2 * np.pi * 5.5 * t))) / SR
    x = signal.sawtooth(ph) + 0.5 * signal.sawtooth(ph * 1.004)
    sweep = np.clip(t / 0.08, 0, 1)
    x = lp(x, 1400 + 2200 * vel, 2) * (0.5 + 0.5 * sweep)
    return x * adsr(n, 0.025, 0.1, 0.85, 0.1) * (0.1 + 0.12 * vel)


def bass(f, dur, vel=0.7):
    n = int((dur + 0.3) * SR)
    t = t_of(n)
    x = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(2 * np.pi * 2 * f * t) * np.exp(-t / 0.3) + 0.12 * np.sin(2 * np.pi * 3 * f * t) * np.exp(-t / 0.15)
    return x * np.exp(-t / (0.9 + dur)) * adsr(n, 0.004, 0.05, 1.0, 0.12) * (0.16 + 0.12 * vel)


def pluck_bass(f, dur, vel=0.7):
    n = int((dur + 0.2) * SR)
    t = t_of(n)
    x = np.sin(2 * np.pi * f * t) * np.exp(-t / 0.55) + 0.3 * np.sin(4 * np.pi * f * t) * np.exp(-t / 0.2)
    return x * (0.18 + 0.12 * vel) * np.minimum(t / 0.002, 1.0)


# ------------------------------------------------------------------ percussion
def kick(vel=0.7, f0=110.0, f1=46.0, dur=0.28):
    n = int(dur * SR)
    t = t_of(n)
    ph = 2 * np.pi * np.cumsum(f1 + (f0 - f1) * np.exp(-t / 0.035)) / SR
    return np.sin(ph) * np.exp(-t / 0.09) * (0.35 + 0.4 * vel)


def snare(vel=0.7, dur=0.2):
    n = int(dur * SR)
    t = t_of(n)
    return (bp(noise(n), 1400, 7000) * np.exp(-t / 0.05) * 0.5 + np.sin(2 * np.pi * 190 * t) * np.exp(-t / 0.05) * 0.3) * (0.3 + 0.5 * vel)


def hat(vel=0.6, dur=0.08):
    n = int(dur * SR)
    t = t_of(n)
    return hp(noise(n), 6000) * np.exp(-t / 0.018) * (0.1 + 0.2 * vel)


def shaker(vel=0.6, dur=0.12):
    n = int(dur * SR)
    t = t_of(n)
    return bp(noise(n), 4000, 11000) * np.minimum(t / 0.012, 1.0) * np.exp(-t / 0.035) * (0.1 + 0.2 * vel)


def rim(vel=0.6):
    n = int(0.06 * SR)
    t = t_of(n)
    return (np.sin(2 * np.pi * 1700 * t) * 0.6 + hp(noise(n), 1500) * 0.4) * np.exp(-t / 0.012) * (0.2 + 0.3 * vel)


def timpani(f, vel=0.8, dur=1.2):
    n = int(dur * SR)
    t = t_of(n)
    out = np.sin(2 * np.pi * (f + 14 * np.exp(-t / 0.12)) * t) * np.exp(-t / 0.5)
    out += lp(noise(n), 400) * np.exp(-t / 0.03) * 0.3
    return out * (0.25 + 0.3 * vel)


# ------------------------------------------------------------------ score helpers
class Track:
    """Collects notes of one stereo track (loopable)."""

    def __init__(self, bpm, bars, beats_per_bar=4, tail=5.0):
        self.bpm = bpm
        self.beat = 60.0 / bpm
        self.bar = self.beat * beats_per_bar
        self.bpb = beats_per_bar
        self.length = self.bar * bars
        self.tail = tail
        self.buf = np.zeros((int((self.length + tail) * SR), 2))

    def at(self, bar, beat):
        return bar * self.bar + beat * self.beat

    def note(self, instr, m, bar, beat, beats, vel=0.7, pan=0.0, gain=1.0, **kw):
        f = hz(m)
        x = instr(f, beats * self.beat, vel, **kw)
        mix_st(self.buf, stereo(x, pan), self.at(bar, beat), gain)

    def hit(self, fn, bar, beat, vel=0.7, pan=0.0, gain=1.0, **kw):
        x = fn(vel, **kw)
        mix_st(self.buf, stereo(x, pan), self.at(bar, beat), gain)

    def parse(self, instr, text, bar, beat=0.0, vel=0.7, pan=0.0, gain=1.0, **kw):
        """'F#5/3 A5/2 G5/1 r/1' - note / beats. Returns (bar, beat) after the phrase."""
        pos = bar * self.bpb + beat
        for tok in text.split():
            name, d = tok.split("/")
            d = float(d)
            if name != "r":
                v = vel
                if name.endswith("!"):
                    name = name[:-1]
                    v = min(vel + 0.15, 1.0)
                b, bt = divmod(pos, self.bpb)
                self.note(instr, midi(name), int(b), bt, d, v, pan, gain, **kw)
            pos += d
        b, bt = divmod(pos, self.bpb)
        return int(b), bt

    def chord(self, instr, notes, bar, beat, beats, vel=0.5, pan=0.0, gain=1.0, spread=0.0, **kw):
        for i, m in enumerate(notes):
            self.note(instr, m, bar, beat + i * spread, beats - i * spread, vel, pan, gain, **kw)

    def render(self, wet=0.28, seconds=2.4, damp=4200.0, peak=0.85, seed=3):
        x = self.buf
        x = reverb(x, wet, seconds, damp, seed)
        # fold the tail onto the start: a seamless loop
        L = int(self.length * SR)
        out = x[:L].copy()
        tail = x[L:]
        n = min(len(tail), L)
        out[:n] += tail[:n]
        out = hp(out.T, 28).T if False else out
        for c in range(2):
            out[:, c] = hp(out[:, c], 30, 1)
        out = normalize_rms(out, -23.0, 0.93)
        return out


# ------------------------------------------------------------------ output
def write_ogg(x, path, quality=4, sr=SR):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    x = np.clip(x, -1.0, 1.0)
    if x.ndim == 1:
        x = x[:, None]
    pcm = (x * 32767).astype("<i2")
    tmp = path + ".tmp.wav"
    with wave.open(tmp, "wb") as w:
        w.setnchannels(pcm.shape[1])
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp, "-c:a", "libvorbis", "-q:a", str(quality), path], check=True)
    os.remove(tmp)


def write_wav(x, path, sr=SR):
    """16-bit PCM: no decoding at run time (important in the browser, where everything runs on one thread)"""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    x = np.clip(x, -1.0, 1.0)
    if x.ndim == 1:
        x = x[:, None]
    pcm = (x * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(pcm.shape[1])
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())
