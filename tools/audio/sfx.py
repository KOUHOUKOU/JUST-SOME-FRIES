"""
Sound effects of JUST SOME FRIES (round 7): natural, soft, a little funny. Rendered offline (numpy), one .ogg per sound.
The old procedural sounds were sine sweeps and low thuds ("dong dong dong" when landing and bumping); these are made of feathers, air, taps, wood and water.
"""
import os
import numpy as np
from synth import *

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "game", "assets", "audio", "sfx")
SOUNDS = {}


def sound(fn):
    SOUNDS[fn.__name__] = fn
    return fn


def env_exp(n, tau, attack=0.002):
    t = t_of(n)
    return np.exp(-t / tau) * np.minimum(t / max(attack, 1e-4), 1.0)


def nz(dur, color="white"):
    return noise(int(dur * SR), color)


def tap(center, dur=0.04, res=0.0, tau=0.012, hard=1.0):
    """a single small contact: a burst of noise around `center` Hz, optionally with a woody resonance"""
    n = int(max(dur, 0.03) * SR)
    x = bp(noise(n), center * 0.6, center * 1.7, 2) * env_exp(n, tau, 0.0007)
    if res > 0:
        t = t_of(n)
        x += 0.8 * np.sin(2 * np.pi * res * t) * np.exp(-t / (tau * 3.2))
    return x * hard


def gull_voice(f0, f1, dur, vib=14.0, vib_hz=7.0, breath=0.05, formants=(1500, 2900), body=0.8):
    n = int(dur * SR)
    t = t_of(n)
    u = t / dur
    f = f0 + (f1 - f0) * u + np.sin(2 * np.pi * vib_hz * t) * vib * np.sin(np.pi * u)
    ph = 2 * np.pi * np.cumsum(f) / SR
    src = signal.sawtooth(ph, 0.5) * 0.7 + np.sin(ph) * 0.5
    voiced = bp(src, formants[0] * 0.8, formants[0] * 1.3, 2) + 0.6 * bp(src, formants[1] * 0.8, formants[1] * 1.2, 2) + body * lp(src, 900, 1) * 0.5
    voiced += breath * bp(noise(n), 1200, 5000)
    env = np.power(np.maximum(np.sin(np.pi * u), 0.0), 0.6) * np.minimum(t / 0.015, 1.0)
    return voiced * env


def echo_mix(parts):
    """parts: [(array, start_sec)] -> one mono array"""
    end = max(int(s * SR) + len(a) for a, s in parts)
    out = np.zeros(end)
    for a, s in parts:
        mix_into(out, a, s)
    return out


def trim(x, thr=0.004, pad=0.04):
    idx = np.nonzero(np.abs(x) > thr * np.max(np.abs(x)))[0]
    if len(idx) == 0:
        return x
    return x[: min(len(x), idx[-1] + int(pad * SR))]


def finish(x, peak=0.7, fin=0.002, fout=0.02):
    return normalize(fade(trim(x), fin, fout), peak)


# ------------------------------------------------------------------ the gull's own voice
@sound
def chirp():
    return finish(echo_mix([(gull_voice(920, 700, 0.3, 18), 0.0), (gull_voice(860, 650, 0.26, 18), 0.34)]), 0.55)


@sound
def happy():
    return finish(echo_mix([(gull_voice(680, 880, 0.2, 10, 5), 0.0), (gull_voice(740, 950, 0.24, 10, 5), 0.24)]), 0.5)


@sound
def cry():
    return finish(echo_mix([(gull_voice(1000, 540, 0.42, 36, 9, 0.08), 0.0)]), 0.62)


@sound
def proud():
    return finish(echo_mix([(gull_voice(760, 1020, 0.3, 14, 6), 0.0), (gull_voice(900, 1180, 0.38, 14, 6), 0.33)]), 0.55)


@sound
def lure():
    return finish(echo_mix([(gull_voice(940, 580, 0.5, 30, 8), 0.0), (gull_voice(900, 560, 0.5, 30, 8), 0.54)]), 0.6)


@sound
def gull_far():
    x = echo_mix([(gull_voice(780, 620, 0.4, 16), 0.0), (gull_voice(720, 580, 0.4, 16), 0.5)])
    return finish(lp(x, 2600, 2), 0.4)


@sound
def rival_call():
    return finish(echo_mix([(gull_voice(720, 520, 0.34, 55, 11, 0.12), 0.0), (gull_voice(680, 490, 0.3, 55, 11, 0.12), 0.32)]), 0.6)


@sound
def boo():
    return finish(echo_mix([(gull_voice(500, 780, 0.26, 38, 9), 0.0), (gull_voice(540, 820, 0.22, 38, 9), 0.0)]), 0.55)


@sound
def oh():
    n = int(0.24 * SR)
    t = t_of(n)
    u = t / 0.24
    f = 190 + 45 * np.sin(np.pi * u)
    ph = 2 * np.pi * np.cumsum(f) / SR
    src = signal.sawtooth(ph) * 0.6
    v = bp(src, 420, 600, 2) + 0.6 * bp(src, 760, 1000, 2) + 0.25 * bp(src, 2200, 2800, 2)
    return finish(v * np.sin(np.pi * u) ** 0.8, 0.5)


@sound
def bark():
    n = int(0.17 * SR)
    t = t_of(n)
    u = t / 0.17
    f = 380 - 180 * u
    ph = 2 * np.pi * np.cumsum(f) / SR
    src = signal.sawtooth(ph) * 0.7 + 0.2 * noise(n)
    v = bp(src, 500, 900, 2) + 0.6 * bp(src, 1300, 2000, 2)
    return finish(v * np.exp(-t / 0.07) * np.minimum(t / 0.004, 1.0), 0.6)


@sound
def growl():
    n = int(0.95 * SR)
    t = t_of(n)
    f = 70 + 16 * np.sin(2 * np.pi * 5.5 * t) + 12 * np.sin(2 * np.pi * 2.1 * t)
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = lp(signal.sawtooth(ph), 420, 2) * (0.6 + 0.4 * np.sin(2 * np.pi * 11 * t))
    x += lp(noise(n, "brown"), 200, 1) * 0.3
    return finish(x * np.sin(np.pi * t / 0.95) ** 0.8, 0.55, 0.02, 0.1)


# ------------------------------------------------------------------ wings, wind, water, bodies
def flap_(seed_shift=0.0, size=1.0):
    n = int(0.42 * SR)
    down = bp(nz(0.42), 320, 1700 + 500 * size, 2) * env_exp(n, 0.07, 0.018)
    up = np.zeros(n)
    k = int(0.15 * SR)
    up[k:] = (bp(nz(0.42), 500, 2400, 2) * env_exp(n, 0.05, 0.02))[: n - k] * 0.55
    x = down + up
    x += 0.2 * np.roll(lp(nz(0.42, "pink"), 900), int(0.03 * SR)) * env_exp(n, 0.1, 0.02)
    return x


@sound
def flap():
    return finish(flap_(0, 1.0), 0.5)


@sound
def flap2():
    return finish(flap_(0, 0.8), 0.46)


@sound
def boost():
    n = int(0.9 * SR)
    t = t_of(n)
    u = t / 0.9
    x = noise(n)
    sw = np.zeros(n)
    # a swept band: use a few fixed bandpasses cross-faded
    for i, (a, b) in enumerate([(250, 700), (500, 1500), (1000, 3200), (1800, 5200)]):
        c = bp(x, a, b, 2)
        w = np.exp(-((u - (0.15 + 0.2 * i)) ** 2) / 0.05)
        sw += c * w
    sw *= np.sin(np.pi * np.clip(u * 0.95, 0, 1)) ** 1.5
    sw += 0.15 * lp(noise(n, "pink"), 700) * np.sin(np.pi * u)
    return finish(sw, 0.5, 0.01, 0.1)


@sound
def roll():
    n = int(0.42 * SR)
    t = t_of(n)
    u = t / 0.42
    x = bp(noise(n), 700, 2800, 2) * np.sin(np.pi * u) ** 1.3
    x += 0.4 * bp(noise(n), 300, 1000, 2) * np.sin(np.pi * u) ** 2
    return finish(x, 0.42)


@sound
def whoosh():
    n = int(0.55 * SR)
    t = t_of(n)
    u = t / 0.55
    x = bp(noise(n), 350, 2200, 2) * np.sin(np.pi * u) ** 1.7
    x += 0.35 * bp(noise(n, "pink"), 150, 600, 1) * np.sin(np.pi * u)
    return finish(x, 0.4, 0.01, 0.08)


@sound
def splash():
    n = int(0.8 * SR)
    t = t_of(n)
    x = lp(noise(n), 6500, 2) * env_exp(n, 0.16, 0.002)
    x += 0.5 * bp(noise(n), 800, 2500, 2) * env_exp(n, 0.35, 0.004)
    parts = []
    for i in range(7):
        st = 0.02 + 0.09 * i + 0.03 * rng.random()
        f0 = 500 + 700 * rng.random()
        m = int(0.06 * SR)
        tt = t_of(m)
        b = np.sin(2 * np.pi * (f0 + 1800 * tt) * tt) * np.exp(-tt / 0.02) * 0.25
        parts.append((b, st))
    x = x + echo_mix(parts + [(np.zeros(n), 0.0)])[:n]
    return finish(x, 0.62, 0.001, 0.1)


@sound
def shake():
    n = int(0.55 * SR)
    t = t_of(n)
    am = 0.55 + 0.45 * np.sign(np.sin(2 * np.pi * 22 * t))
    x = bp(noise(n), 1400, 5200, 2) * am * np.sin(np.pi * t / 0.55) ** 0.8
    return finish(x, 0.4)


@sound
def tumble():
    n = int(0.7 * SR)
    t = t_of(n)
    am = 0.5 + 0.5 * np.sin(2 * np.pi * 17 * t)
    x = bp(noise(n), 700, 3200, 2) * am * np.exp(-t / 0.35) * np.minimum(t / 0.01, 1.0)
    bonk = np.zeros(n)
    b = marimba(hz(52), 0.3, 0.7)[: int(0.4 * SR)]
    bonk[: len(b)] = b
    x = x + bonk * 1.1
    return finish(x, 0.55, 0.002, 0.1)


@sound
def thud():
    """a body bumping into something: a soft 'whump' with a puff of feathers (no deep sine boom)"""
    n = int(0.3 * SR)
    t = t_of(n)
    x = lp(noise(n), 520, 2) * env_exp(n, 0.06, 0.002) * 1.2
    x += 0.5 * np.sin(2 * np.pi * (170 - 70 * np.minimum(t / 0.15, 1)) * t) * np.exp(-t / 0.05)
    x += 0.35 * bp(noise(n), 900, 3500, 2) * env_exp(n, 0.1, 0.004)
    return finish(x, 0.6)


@sound
def bump():
    n = int(0.22 * SR)
    t = t_of(n)
    x = lp(noise(n), 700, 2) * env_exp(n, 0.04, 0.002) + 0.35 * bp(noise(n), 1200, 4000, 2) * env_exp(n, 0.07, 0.003)
    x += 0.4 * np.sin(2 * np.pi * 210 * t) * np.exp(-t / 0.035)
    return finish(x, 0.45)


def land_(center, res, tau, rustle=1.0, two=True, lo=False):
    n = int(0.36 * SR)
    x = np.zeros(n)
    rus = bp(noise(n), 700, 4200, 2) * env_exp(n, 0.08, 0.012) * 0.55 * rustle
    x += rus
    t1 = tap(center, 0.05, res, tau)
    mix_into(x, t1, 0.025, 1.0)
    if two:
        mix_into(x, tap(center * 1.1, 0.05, res, tau), 0.085, 0.7)
    if lo:
        mix_into(x, lp(noise(int(0.1 * SR)), 380, 1) * env_exp(int(0.1 * SR), 0.03, 0.002) * 0.7, 0.02)
    return x


@sound
def land():
    return finish(land_(2200, 0, 0.012, 1.0), 0.5)           # generic = a little soft tap


@sound
def land_grass():
    return finish(land_(1500, 0, 0.016, 1.3), 0.45)


@sound
def land_sand():
    return finish(lp(land_(1100, 0, 0.02, 1.2, True, True), 2600, 2), 0.45)


@sound
def land_wood():
    return finish(land_(1700, 330, 0.018, 0.9), 0.55)


@sound
def land_stone():
    return finish(land_(3200, 0, 0.009, 0.8), 0.5)


@sound
def land_roof():
    return finish(land_(2400, 560, 0.014, 0.9), 0.52)


def step_(center, res, tau, hard=1.0):
    n = int(0.12 * SR)
    x = tap(center, 0.05, res, tau, hard)
    x = np.concatenate([x, np.zeros(max(n - len(x), 0))])
    return x


for _name, _args in {"step_grass": (1600, 0, 0.012), "step_sand": (1000, 0, 0.018), "step_wood": (1800, 300, 0.012), "step_stone": (3400, 0, 0.007), "step_roof": (2500, 540, 0.01)}.items():
    def _mk(args=_args, nm=_name):
        def f():
            return finish(step_(*args), 0.36, 0.0005, 0.02)
        f.__name__ = nm
        return f
    SOUNDS[_name] = _mk()
    SOUNDS[_name + "2"] = (lambda args=_args, nm=_name: (lambda: finish(step_(args[0] * 1.12, args[1] * 1.1, args[2] * 1.1, 0.9), 0.34, 0.0005, 0.02)))()


# ------------------------------------------------------------------ the fry
@sound
def snatch():
    n = int(0.28 * SR)
    x = np.zeros(n)
    mix_into(x, tap(2600, 0.04, 0, 0.007), 0.0, 1.0)
    mix_into(x, tap(2000, 0.04, 0, 0.008), 0.045, 0.8)
    mix_into(x, bp(noise(int(0.2 * SR)), 500, 2500, 2) * env_exp(int(0.2 * SR), 0.05, 0.004), 0.02, 0.5)
    return finish(x, 0.6)


@sound
def crunch():
    n = int(0.4 * SR)
    x = np.zeros(n)
    for i, (st, c, a) in enumerate([(0.0, 3000, 1.0), (0.055, 2400, 0.85), (0.12, 3400, 0.9), (0.2, 2200, 0.6)]):
        m = int(0.05 * SR)
        b = hp(noise(m), 1500) * env_exp(m, 0.012, 0.0005)
        b += bp(noise(m), c * 0.5, c, 2) * env_exp(m, 0.02, 0.0005)
        mix_into(x, b, st, a)
    return finish(x, 0.55)


@sound
def miss():
    return finish(tap(900, 0.08, 220, 0.03) * 1.0 + 0.3 * bp(nz(0.08), 600, 2000), 0.38)


@sound
def clack():
    return finish(tap(2400, 0.05, 300, 0.012) + tap(1800, 0.05, 0, 0.01), 0.45)


@sound
def alert():
    return finish(bell(hz(76), 0.3, 0.6, (1.0, 2.0), (0.14, 0.06)), 0.3)


@sound
def tooslow():
    return finish(marimba(hz(52), 0.2, 0.6) * 1.0, 0.4)


@sound
def squirt():
    n = int(0.45 * SR)
    t = t_of(n)
    am = 0.7 + 0.3 * np.sin(2 * np.pi * 40 * t)
    return finish(bp(noise(n), 2500, 7000, 2) * am * np.sin(np.pi * np.clip(t / 0.45, 0, 1)) ** 0.5, 0.4)


@sound
def broom():
    n = int(0.33 * SR)
    t = t_of(n)
    return finish(bp(noise(n), 900, 4500, 2) * np.sin(np.pi * t / 0.33) ** 1.4, 0.4)


@sound
def heartbeat():
    n = int(0.55 * SR)
    x = np.zeros(n)
    for st, a in [(0.0, 1.0), (0.2, 0.7)]:
        m = int(0.14 * SR)
        tt = t_of(m)
        b = np.sin(2 * np.pi * (70 - 25 * tt / 0.14) * tt) * np.exp(-tt / 0.04) + 0.3 * lp(noise(m), 200, 1) * np.exp(-tt / 0.03)
        mix_into(x, b, st, a)
    return finish(x, 0.5)


@sound
def bop():
    n = int(0.18 * SR)
    t = t_of(n)
    x = lp(noise(n), 800, 2) * env_exp(n, 0.04, 0.001) + 0.7 * np.sin(2 * np.pi * (200 - 80 * t / 0.18) * t) * np.exp(-t / 0.06)
    return finish(x, 0.6)


@sound
def pop():
    n = int(0.12 * SR)
    t = t_of(n)
    x = np.sin(2 * np.pi * (300 + 1400 * t / 0.12) * t) * np.exp(-t / 0.03)
    mix_into(x, tap(2200, 0.03), 0.0, 0.4)
    return finish(x, 0.45)


@sound
def bubble():
    parts = []
    for st, f in [(0.0, 520), (0.11, 700)]:
        m = int(0.1 * SR)
        tt = t_of(m)
        parts.append((np.sin(2 * np.pi * (f + 900 * tt / 0.1) * tt) * np.exp(-tt / 0.03) * 0.8, st))
    return finish(echo_mix(parts), 0.4)


@sound
def boing():
    n = int(0.4 * SR)
    t = t_of(n)
    f = 200 + 300 * np.exp(-t / 0.08) * np.cos(2 * np.pi * 14 * t * 0.5)
    ph = 2 * np.pi * np.cumsum(f * (1 + 0.5 * np.exp(-t / 0.1))) / SR
    return finish(np.sin(ph) * np.exp(-t / 0.15), 0.5)


# ------------------------------------------------------------------ UI, comic and story
@sound
def blip():
    n = int(0.045 * SR)
    t = t_of(n)
    x = (np.sin(2 * np.pi * 760 * t) + 0.3 * np.sin(2 * np.pi * 1520 * t)) * np.sin(np.pi * t / 0.045) ** 1.5
    return finish(x, 0.3, 0.001, 0.004)


@sound
def tick_ui():
    return finish(bell(hz(88), 0.1, 0.5, (1.0, 2.76), (0.07, 0.03)), 0.28)


@sound
def ui_go():
    parts = [(bell(hz(m), 0.5, 0.6, (1.0, 2.01, 3.0), (0.5, 0.2, 0.1)), 0.07 * i) for i, m in enumerate([72, 76, 79, 84])]
    return finish(echo_mix(parts), 0.5)


@sound
def slam():
    """a comic impact: a woody thump, a crack and a burst of air; nothing deep or scary"""
    n = int(0.7 * SR)
    t = t_of(n)
    x = np.sin(2 * np.pi * (120 - 60 * np.minimum(t / 0.2, 1)) * t) * np.exp(-t / 0.12) * 0.8
    x += lp(noise(n), 1200, 1) * env_exp(n, 0.1, 0.001) * 0.7
    mix_into(x, tap(2600, 0.05, 700, 0.015), 0.0, 0.9)
    x += bp(noise(n), 800, 6000, 1) * env_exp(n, 0.28, 0.003) * 0.45
    return finish(x, 0.8, 0.001, 0.1)


@sound
def star_on():
    parts = []
    for i, m in enumerate([72, 76, 79, 84, 88, 91, 96, 100]):
        parts.append((bell(hz(m), 0.9, 0.7, (1.0, 2.0, 3.01), (0.9, 0.5, 0.25)) * (0.8 + 0.04 * i), 0.07 * i))
    n = int(1.6 * SR)
    t = t_of(n)
    sw = bp(noise(n), 300, 6000, 1) * np.sin(np.pi * np.clip(t / 1.6, 0, 1)) ** 2 * 0.25
    sh = echo_mix(parts)
    out = np.zeros(max(len(sh), n))
    out[: len(sh)] += sh
    out[:n] += sw
    return finish(out, 0.7, 0.002, 0.2)


@sound
def star_off():
    parts = [(bell(hz(m), 0.8, 0.5, (1.0, 2.0), (0.8, 0.4)), 0.1 * i) for i, m in enumerate([91, 86, 83, 79])]
    return finish(echo_mix(parts), 0.45, 0.002, 0.2)


@sound
def vision_on():
    n = int(0.6 * SR)
    t = t_of(n)
    x = bp(noise(n), 300, 2400, 2) * np.sin(np.pi * np.clip(t / 0.6, 0, 1)) ** 1.5 * 0.5
    x += bell(hz(84), 0.5, 0.5, (1.0, 2.0), (0.4, 0.2))[:n] * 0.6
    return finish(x, 0.45)


@sound
def vision_off():
    n = int(0.45 * SR)
    t = t_of(n)
    x = bp(noise(n), 250, 1800, 2) * np.sin(np.pi * np.clip(t / 0.45, 0, 1)) * 0.5
    return finish(x, 0.35)


# ------------------------------------------------------------------ rewards: bells and marimba, never fanfares
def arp_bell(notes, step=0.09, dec=(1.2, 0.5, 0.2), tail=0.8, vel=0.6, ratios=(1.0, 2.0, 3.0)):
    parts = [(bell(hz(m), tail, vel, ratios, dec), step * i) for i, m in enumerate(notes)]
    return echo_mix(parts)


@sound
def success():
    return finish(arp_bell([72, 79], 0.1, (0.5, 0.25, 0.1)), 0.5)


@sound
def perfect():
    return finish(arp_bell([91, 96], 0.05, (0.9, 0.4, 0.2), 1.0), 0.5)


@sound
def chime():
    return finish(bell(hz(81), 1.6, 0.6, (1.0, 2.0, 3.0), (1.2, 0.5, 0.2)) + 0.5 * bell(hz(88), 1.6, 0.5, (1.0, 2.0), (1.2, 0.4)), 0.45, 0.002, 0.3)


@sound
def gs_tick():
    return finish(bell(hz(84), 0.5, 0.6, (1.0, 2.76), (0.3, 0.12)), 0.4)


@sound
def gs_complete():
    return finish(arp_bell([72, 76, 79], 0.12, (1.0, 0.45, 0.2), 1.2), 0.55, 0.002, 0.3)


for _i, _notes in enumerate([[84, 88, 91], [86, 90, 93], [81, 85, 88], [83, 86, 91], [88, 91, 95], [79, 83, 86], [85, 89, 92]]):
    SOUNDS["prism_%d" % _i] = (lambda notes=_notes: (lambda: finish(arp_bell(notes, 0.07, (0.5, 0.25, 0.1), 0.7), 0.4)))()

_UP = {"red": [60, 67, 72, 76, 79], "blue": [62, 69, 74, 78, 81], "purple": [65, 72, 77, 81, 84], "green": [64, 71, 76, 79, 83], "pink": [66, 73, 78, 82, 85],
       "orange": [59, 66, 71, 75, 78], "cyan": [67, 74, 79, 83, 86]}
def _special(notes):
    x = arp_bell(notes, 0.1, (1.5, 0.6, 0.3), 1.2, 0.6)
    p = piano(hz(notes[0] - 12), 1.5, 0.5)
    out = np.zeros(max(len(x), len(p)))
    out[: len(x)] += x
    out[: len(p)] += p * 0.4
    return finish(out, 0.55, 0.002, 0.3)


for _k, _n in _UP.items():
    SOUNDS["special_" + _k] = (lambda notes=_n: (lambda: _special(notes)))()


@sound
def reward_1():
    return finish(arp_bell([72, 76, 79], 0.09, (1.1, 0.5, 0.2), 0.9), 0.5, 0.002, 0.3)


@sound
def reward_2():
    x = arp_bell([72, 76, 79, 84], 0.1, (1.4, 0.6, 0.25), 1.2)
    p = piano(hz(60), 1.6, 0.5)
    out = np.zeros(max(len(x), len(p)))
    out[: len(x)] += x
    out[: len(p)] += p * 0.6
    return finish(out, 0.55, 0.002, 0.3)


@sound
def reward_3():
    x = arp_bell([72, 76, 79, 84, 88], 0.11, (1.8, 0.8, 0.35), 1.6)
    p = piano(hz(60), 2.4, 0.6)
    sp = arp_bell([96, 100, 96, 100], 0.16, (0.6, 0.3, 0.1), 0.9, 0.5)
    out = np.zeros(max(len(x), len(p), len(sp) + int(0.7 * SR)))
    out[: len(x)] += x
    out[: len(p)] += p * 0.7
    mix_into(out, sp, 0.7, 0.5)
    return finish(out, 0.6, 0.002, 0.4)


@sound
def equip():
    return finish(arp_bell([84, 88, 91], 0.06, (0.4, 0.2, 0.1), 0.5), 0.4)


@sound
def heart():
    return finish(arp_bell([88, 95], 0.08, (0.5, 0.25, 0.1), 0.6), 0.35)


@sound
def feed():
    return finish(arp_bell([79, 84], 0.1, (0.6, 0.3, 0.12), 0.7), 0.4)


@sound
def sip():
    n = int(0.3 * SR)
    t = t_of(n)
    x = bp(noise(n), 500, 1800, 2) * np.sin(np.pi * t / 0.3) ** 1.2 * 0.7
    x += 0.5 * np.sin(2 * np.pi * (300 + 500 * t / 0.3) * t) * np.sin(np.pi * t / 0.3) ** 2 * 0.3
    return finish(x, 0.4)


@sound
def warn():
    return finish(echo_mix([(marimba(hz(52), 0.3, 0.7), 0.0), (marimba(hz(47), 0.3, 0.6), 0.11)]), 0.5)


@sound
def fry_fly():
    n = int(0.55 * SR)
    t = t_of(n)
    x = bp(noise(n), 800, 4800, 1) * np.sin(np.pi * t / 0.55) ** 2 * 0.45
    return finish(x + 0.4 * np.sin(2 * np.pi * (500 + 1200 * t / 0.55) * t) * np.sin(np.pi * t / 0.55) ** 2 * 0.2, 0.3)


@sound
def tonic():
    return finish(bell(hz(72), 3.5, 0.7, (1.0, 2.0, 3.0), (2.5, 1.2, 0.6)) + 0.6 * bell(hz(60), 3.5, 0.6, (1.0, 2.0), (2.5, 1.0)), 0.5, 0.005, 0.5)


@sound
def ring_ok():
    return finish(marimba(hz(72), 0.4, 0.8), 0.5)


@sound
def ring_gold():
    x = arp_bell([76, 83, 91], 0.045, (0.6, 0.3, 0.12), 0.7)
    m = marimba(hz(76), 0.5, 0.9)
    out = np.zeros(max(len(x), len(m)))
    out[: len(x)] += x
    out[: len(m)] += m * 0.7
    return finish(out, 0.55)


@sound
def ring_miss():
    return finish(tap(700, 0.09, 190, 0.035) * 1.0, 0.35)


@sound
def buff_coffee():
    n = int(0.5 * SR)
    t = t_of(n)
    sw = bp(noise(n), 400, 3600, 2) * np.sin(np.pi * t / 0.5) * 0.3
    ab = arp_bell([79, 86], 0.16, (0.8, 0.3, 0.1), 0.9)
    mix_into(ab, sw, 0.0)
    return finish(ab, 0.5)


@sound
def buff_alcohol():
    parts = [(marimba(hz(m), 0.5, 0.7), 0.1 * i) for i, m in enumerate([67, 71, 74, 79])]
    return finish(echo_mix(parts), 0.5)


@sound
def buff_ice():
    return finish(arp_bell([84, 88, 91, 96, 100, 103], 0.065, (0.7, 0.3, 0.12), 0.7), 0.42)


@sound
def buff_end():
    return finish(arp_bell([76, 69], 0.14, (0.7, 0.3, 0.1), 0.9), 0.38)


# ------------------------------------------------------------------ round 8: the friend, the stars, the cinema
from synth_extra import harp2, celesta, glock, swell, pluck


def _mix(parts, n=None):
    out = echo_mix(parts)
    return out


@sound
def friend_come():
    """a friend lands next to you: a small music-box 'hello' in G (three notes, a rising fourth and a rest)"""
    parts = [(celesta(hz(m), 0.6, 0.55), 0.0 + 0.16 * i) for i, m in enumerate([79, 83, 86])]
    parts.append((celesta(hz(91), 1.2, 0.5), 0.62))
    parts.append((harp2(hz(55), 1.2, 0.5), 0.0))
    return finish(echo_mix(parts), 0.5, 0.002, 0.35)


@sound
def friend_gift():
    """the gift changes beaks: a warm rising arpeggio, a soft low note under it and a shimmer on top (about 3 s)"""
    notes = [55, 59, 62, 67, 71, 74, 79]
    parts = [(harp2(hz(m), 1.4, 0.55), 0.13 * i) for i, m in enumerate(notes)]
    parts += [(celesta(hz(m + 12), 1.4, 0.45), 0.13 * i + 0.05) for i, m in enumerate(notes[2:])]
    parts.append((piano(hz(43), 2.6, 0.45), 0.0))
    parts.append((celesta(hz(98), 2.2, 0.5), 0.95))
    parts.append((celesta(hz(95), 2.2, 0.4), 1.15))
    x = echo_mix(parts)
    n = len(x)
    pad = np.zeros(n)
    for m in (55, 59, 62, 67):
        sv = strings(hz(m), 2.0, 0.4, voices=3, attack=0.7, release=1.1, cutoff=1300)
        mix_into(pad, sv, 0.3, 0.45)
    return finish(x + pad[:n], 0.55, 0.002, 0.5)


@sound
def meteor_pass():
    """a shooting star crossing the sky: a soft air rush with a thin falling glass tone"""
    n = int(2.4 * SR)
    t = t_of(n)
    u = t / 2.4
    air = bp(noise(n), 1500, 7000, 1) * np.sin(np.pi * u) ** 2 * 0.45
    f = 3200 * np.exp(-1.1 * u) + 600
    ph = 2 * np.pi * np.cumsum(f) / SR
    tone = (np.sin(ph) + 0.3 * np.sin(2 * ph)) * np.sin(np.pi * u) ** 3 * 0.25
    for k in range(5):
        mix_into(tone, bell(hz(96 - 3 * k), 0.8, 0.4, (1.0, 2.0), (0.4, 0.15)), 0.15 + 0.3 * k, 0.5)
    return finish(air + tone, 0.4, 0.01, 0.4)


@sound
def meteor_get():
    """the star is yours: a quick pentatonic cascade of bells, then a long warm chord with sparkles"""
    notes = [72, 76, 79, 84, 88, 91, 96, 100]
    parts = [(bell(hz(m), 1.2, 0.6, (1.0, 2.0, 3.01), (0.9, 0.5, 0.25)), 0.055 * i) for i, m in enumerate(notes)]
    parts += [(celesta(hz(m), 1.6, 0.5), 0.5 + 0.12 * i) for i, m in enumerate([84, 88, 91, 96])]
    parts.append((piano(hz(60), 2.4, 0.5), 0.45))
    parts.append((harp2(hz(67), 2.4, 0.5), 0.5))
    return finish(echo_mix(parts), 0.6, 0.002, 0.6)


@sound
def cine_in():
    """the picture narrows to a film frame: a low breath and a high shimmer"""
    n = int(1.4 * SR)
    t = t_of(n)
    u = t / 1.4
    x = lp(noise(n, "pink"), 700, 2) * np.sin(np.pi * u) ** 2 * 0.5
    sh = np.zeros(n)
    for i, m in enumerate([79, 83, 86]):
        mix_into(sh, bell(hz(m), 1.0, 0.4, (1.0, 2.0, 3.0), (0.6, 0.3, 0.1)), 0.1 + 0.15 * i, 0.5)
    return finish(x + sh, 0.35, 0.02, 0.4)


@sound
def cine_out():
    n = int(1.0 * SR)
    t = t_of(n)
    u = t / 1.0
    x = lp(noise(n, "pink"), 900, 2) * np.sin(np.pi * u) ** 2 * 0.4
    sh = np.zeros(n)
    for i, m in enumerate([86, 83, 79]):
        mix_into(sh, bell(hz(m), 0.8, 0.4, (1.0, 2.0), (0.4, 0.15)), 0.1 + 0.12 * i, 0.5)
    return finish(x + sh, 0.32, 0.01, 0.3)


@sound
def vn_next():
    return finish(echo_mix([(tap(2400, 0.04, 880, 0.01) * 0.6, 0.0), (bell(hz(91), 0.2, 0.4, (1.0, 2.0), (0.08, 0.04)), 0.0)]), 0.22, 0.001, 0.04)


@sound
def vn_pop():
    return finish(echo_mix([(marimba(hz(79), 0.2, 0.6), 0.0), (0.5 * marimba(hz(86), 0.2, 0.5), 0.0)]), 0.3, 0.001, 0.08)


@sound
def star_riser():
    """STARLIGHT is coming: a riser, bells climbing, and a soft burst at the top"""
    x = swell(2.6, 300.0, 5200.0, 0.55)
    n = len(x)
    out = np.zeros(n + int(1.2 * SR))
    out[:n] += x
    for i, m in enumerate([72, 76, 79, 84, 88, 91, 96, 100, 103]):
        mix_into(out, bell(hz(m), 0.8, 0.5, (1.0, 2.0, 3.0), (0.6, 0.3, 0.12)), 0.5 + 0.2 * i, 0.5)
    mix_into(out, bell(hz(108), 1.5, 0.6, (1.0, 2.0, 3.0), (1.2, 0.5, 0.2)), 2.55, 0.8)
    mix_into(out, piano(hz(60), 1.4, 0.6), 2.55, 0.6)
    return finish(out, 0.5, 0.02, 0.5)


@sound
def drop_tick():
    """the old man's fry lands on the table: a tiny, dry tick - nothing special"""
    return finish(echo_mix([(tap(1800, 0.05, 520, 0.012) * 0.8, 0.0), (tap(900, 0.06, 0, 0.02) * 0.4, 0.0)]), 0.3, 0.001, 0.05)


# ------------------------------------------------------------------ ambience loops
def loopify(x, xf=0.8):
    """a seamless loop: crossfade the end into the beginning"""
    n = int(xf * SR)
    head = x[:n] * np.linspace(0, 1, n)
    tail = x[-n:] * np.linspace(1, 0, n)
    body = x[n:-n].copy()
    out = np.concatenate([body])
    out[:n] += tail[: len(out)][:n] if len(out) >= n else 0
    out[-n:] += head if len(out) >= n else 0
    return out


@sound
def wind():
    n = int(7.0 * SR)
    t = t_of(n)
    x = lp(noise(n, "pink"), 1100, 2)
    gust = 0.6 + 0.4 * np.sin(2 * np.pi * t / 3.5) * np.sin(2 * np.pi * t / 5.1 + 1.0)
    x = x * gust
    x += 0.4 * bp(noise(n), 600, 2400, 2) * (0.4 + 0.6 * np.sin(2 * np.pi * t / 2.3 + 2.0) ** 2) * 0.35
    return normalize(loopify(x), 0.55)


@sound
def waves():
    n = int(14.0 * SR)
    t = t_of(n)
    swell = 0.35 + 0.65 * (0.5 + 0.5 * np.sin(2 * np.pi * t / 7.0 - 1.2)) ** 1.4
    swell2 = 0.5 + 0.5 * np.sin(2 * np.pi * t / 4.7 + 0.4)
    x = lp(noise(n, "brown"), 520, 2) * swell * 1.6
    foam = hp(lp(noise(n), 9000, 1), 1800) * (swell ** 3) * (0.5 + 0.5 * swell2) * 0.5
    return normalize(loopify(x + foam, 1.0), 0.55)


@sound
def murmur():
    n = int(10.0 * SR)
    t = t_of(n)
    base = bp(noise(n, "pink"), 180, 1600, 2)
    am = 0.35 + 0.65 * np.abs(np.sin(2 * np.pi * t * 0.9 + 1.3 * np.sin(2 * np.pi * t * 0.31))) * (0.6 + 0.4 * np.sin(2 * np.pi * t * 3.1 + np.sin(t * 1.7)))
    x = base * am
    for k in range(9):
        st = 0.5 + k * 1.05 + rng.random() * 0.4
        d = 0.12 + 0.12 * rng.random()
        m = int(d * SR)
        tt = t_of(m)
        f = 260 + 200 * rng.random()
        v = (signal.sawtooth(2 * np.pi * np.cumsum(f * (1 + 0.15 * np.sin(8 * tt))) / SR) * np.sin(np.pi * tt / d))
        v = bp(v, 400, 1200, 2) * 0.12
        mix_into(x, v, st)
    return normalize(loopify(x, 0.8), 0.5)


NAMES_NO_FADE = ["wind", "waves", "murmur"]
