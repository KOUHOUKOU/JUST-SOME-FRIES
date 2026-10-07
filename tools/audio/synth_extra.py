"""
More instruments for the round-8 music (a warm, pastoral palette): a tuned Karplus-Strong string (guitar / pizzicato / harp), a clarinet,
an accordion, a glockenspiel and a few soft percussion hits. numpy + scipy only, like synth.py.
"""
import numpy as np
from scipy import signal
from synth import *


def pluck(f, dur, vel=0.7, ring=1.6, bright=3600.0, pos=0.18, body=True):
    """Karplus-Strong string with a first-order all-pass for exact tuning.  ring = seconds until -60 dB, bright = lowpass of the pluck, pos = pick position"""
    n = int((dur + 0.5) * SR)
    n = max(n, int(min(ring, 2.5) * SR))
    L = SR / f - 0.5
    N = int(np.floor(L - 0.5))
    D = L - N
    c = (1.0 - D) / (1.0 + D)
    g = 10.0 ** (-3.0 / (f * ring))
    a = np.zeros(N + 3)
    a[0] = 1.0
    a[1] += c
    a[N] -= g * 0.5 * c
    a[N + 1] -= g * 0.5 * (1.0 + c)
    a[N + 2] -= g * 0.5
    x = np.zeros(n)
    burst = rng.standard_normal(N + 2)
    burst = lp(burst, bright * (0.55 + 0.6 * vel), 1)
    k = max(int(pos * N), 1)
    burst[k:] -= 0.75 * burst[:-k]                 # pick position comb: a thinner or a rounder tone
    x[: N + 2] = burst
    y = signal.lfilter([1.0, c], a, x)
    y -= np.mean(y)
    m = np.max(np.abs(y)) + 1e-9
    y = y / m
    if body:
        y = y + 0.18 * lp(y, 260, 1)               # a little body resonance
    # the release: the string is damped when the note ends
    off = int(dur * SR)
    if off < n:
        y[off:] *= np.exp(-np.arange(n - off) / (0.12 * SR))
    return y * (0.1 + 0.17 * vel) * np.minimum(t_of(n) / 0.0012, 1.0)


def guitar2(f, dur, vel=0.7):
    return pluck(f, dur, vel, ring=1.9, bright=3000.0, pos=0.16)


def pizz(f, dur, vel=0.7):
    return pluck(f, min(dur, 0.35), vel, ring=0.42, bright=4800.0, pos=0.12, body=False) * 1.15


def harp2(f, dur, vel=0.7):
    return pluck(f, dur, vel, ring=2.6, bright=5200.0, pos=0.25, body=False) * 1.1


def banjo(f, dur, vel=0.7):
    return pluck(f, min(dur, 0.6), vel, ring=0.7, bright=7000.0, pos=0.08, body=False)


def clarinet(f, dur, vel=0.6, vib=0.0035):
    n = int((dur + 0.2) * SR)
    t = t_of(n)
    v = 1.0 + vib * np.sin(2 * np.pi * 5.0 * t) * np.clip((t - 0.25) / 0.35, 0, 1)
    ph = 2 * np.pi * np.cumsum(f * v) / SR
    x = np.zeros(n)
    for k, a in zip((1, 3, 5, 7, 9), (1.0, 0.42, 0.2, 0.1, 0.05)):        # a clarinet is made of the odd harmonics
        if f * k < SR * 0.45:
            x += a * np.sin(k * ph)
    x += 0.05 * np.sin(2 * ph)
    x += bp(noise(n), 1200, 4200) * 0.03
    env = adsr(n, 0.055, 0.1, 0.88, 0.14)
    return lp(x, 3600, 1) * env * (0.15 + 0.1 * vel)


def accordion(f, dur, vel=0.5):
    n = int((dur + 0.3) * SR)
    t = t_of(n)
    out = np.zeros(n)
    for cents in (-7.0, 0.0, 6.0):
        ff = f * 2.0 ** (cents / 1200.0)
        ph = 2 * np.pi * np.cumsum(ff * np.ones(n)) / SR
        out += signal.square(ph, 0.35) * 0.5 + signal.sawtooth(ph) * 0.3
    out = lp(out / 3.0, 2300, 2) * (1.0 + 0.06 * np.sin(2 * np.pi * 5.6 * t))
    return out * adsr(n, 0.09, 0.15, 0.85, 0.22) * (0.1 + 0.09 * vel)


def glock(f, dur, vel=0.6):
    return bell(f, dur, vel, ratios=(1.0, 2.76, 5.4), decays=(0.9, 0.3, 0.1)) * 0.9


def celesta(f, dur, vel=0.6):
    return bell(f, dur, vel, ratios=(1.0, 4.0, 9.2), decays=(1.4, 0.3, 0.08)) * 0.95


def tamb(vel=0.6):
    n = int(0.16 * SR)
    t = t_of(n)
    x = bp(noise(n), 5200, 12000) * (np.exp(-t / 0.05) + 0.6 * np.exp(-((t - 0.02) / 0.012) ** 2))
    x += 0.35 * np.sin(2 * np.pi * 7400 * t) * np.exp(-t / 0.03)
    return x * (0.08 + 0.16 * vel)


def brush(vel=0.6):
    n = int(0.14 * SR)
    t = t_of(n)
    return bp(noise(n), 1800, 7500) * np.minimum(t / 0.02, 1.0) * np.exp(-t / 0.06) * (0.1 + 0.2 * vel)


def soft_kick(vel=0.6):
    return kick(vel, 90.0, 48.0, 0.22) * 0.8


def woodblock(vel=0.6):
    n = int(0.08 * SR)
    t = t_of(n)
    return (np.sin(2 * np.pi * 980 * t) * 0.7 + np.sin(2 * np.pi * 1480 * t) * 0.3) * np.exp(-t / 0.018) * (0.15 + 0.25 * vel)


def swell(dur, f0=300.0, f1=4200.0, vol=0.6):
    """a riser: filtered noise opening up + a rising shimmer"""
    n = int(dur * SR)
    t = t_of(n)
    u = t / dur
    x = noise(n)
    out = np.zeros(n)
    seg = 24
    for i in range(seg):
        a, b = int(n * i / seg), int(n * (i + 1) / seg)
        fc = f0 * (f1 / f0) ** ((i + 0.5) / seg)
        out[a:b] = bp(x, fc * 0.7, fc * 1.4, 1)[a:b]
    out *= u ** 1.6
    ph = 2 * np.pi * np.cumsum(500 * (3500 / 500) ** u) / SR
    out += 0.35 * np.sin(ph) * u ** 2
    return out * vol
