"""Round 18 (b): renders a listening sheet of what a player hears, so that it can be judged by ear without starting the game.

    python tools/audio/r18_preview.py        ->  shots/r18_tunes_preview.mp3  (and a .txt that says what each part is)

It plays the sample bank of assets/audio/notes with the SAME rules as systems/tunes.gd:
  EASY  a good press = the voice of the family (an octave higher for the small fries) + a bright 'ting' of tinkle bells; a gold press = two notes a skip apart + a run of bells
  HARD  the tune plays by itself on every beat (quietly); a hit adds a bright voice (xylophone + tinkle + the family) on top of its beat, shinier with the streak; two beats are missed on purpose
  then the welcome song of a friend gull (assets/audio/sfx/friend_welcome.wav)
"""
import os, re, subprocess, random
import numpy as np
from scipy import signal
import wave

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
NOTES = os.path.join(ROOT, "game", "assets", "audio", "notes")
SFX = os.path.join(ROOT, "game", "assets", "audio", "sfx")
SR = 32000
src = open(os.path.join(ROOT, "game", "scripts", "systems", "tunes.gd"), encoding="utf-8").read()
blk = src[src.index("const SONGS = {") + len("const SONGS = "):]
blk = blk[: blk.index("\n}\n") + 2]
SONGS = eval(blk)
MIDIS = [55, 58, 61, 64, 67, 70, 73, 76, 79, 82, 85, 88, 91, 94, 97, 100]
SCALE = [60, 62, 64, 65, 67, 69, 71, 72, 74, 76, 77, 79, 81, 83, 84]
PENT = [0, 2, 4, 7, 9]
cache = {}


def sample(inst, m):
    best = min(MIDIS, key=lambda x: abs(x - m))
    key = (inst, best)
    if key not in cache:
        out = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", os.path.join(NOTES, "%s_%d.ogg" % (inst, best)), "-f", "f32le", "-ar", str(SR), "-ac", "1", "-"], capture_output=True, check=True).stdout
        cache[key] = np.frombuffer(out, dtype="<f4").copy()
    x = cache[key]
    ratio = 2.0 ** ((m - best) / 12.0)
    if abs(ratio - 1.0) > 1e-3:
        n = int(len(x) / ratio)
        x = signal.resample(x, n)
    return x


def segment(song, n, rnd):
    ph = SONGS[song]
    start = rnd.randrange(max(len(ph) - 1, 1))
    out = []
    i = start
    while len(out) < n:
        out += ph[i % len(ph)]
        i += 1
    return out[:n]


def resolve(notes):
    stable = [60, 64, 67, 72, 76, 79, 84, 57, 69]
    last = notes[-1]
    notes[-1] = min(stable, key=lambda s: abs(s - last))
    return notes


def top(m):
    return m if m <= 100 else m - 12


def up_pent(m, k):
    cur = m
    while k > 0 and cur < 110:
        cur += 1
        if cur % 12 in PENT:
            k -= 1
    return cur


def put(buf, inst, m, t, db):
    x = sample(inst, m) * 10 ** (db / 20.0)
    i0 = int(t * SR)
    if i0 >= len(buf):
        return
    buf[i0:i0 + len(x)] += x[: len(buf) - i0]


def lifted(m, lift):
    m += lift
    while m > 96:
        m -= 12
    return m


def easy_play(notes, inst, pad, lift, golds, step=0.34):
    buf = np.zeros(int((len(notes) * step + 3.0) * SR))
    t = 0.0
    i = 0
    while i < len(notes):
        gold = i in golds and i + 1 < len(notes)
        m = lifted(notes[i], lift)
        put(buf, inst, m, t, -2.0)
        put(buf, "tinkle", top(m + 12), t, -11.0)
        if gold:
            put(buf, "glock", top(m + 12), t, -8.0)
            m2 = lifted(notes[i + 1], lift)
            put(buf, inst, m2, t + 0.07, -1.5)
            put(buf, "tinkle", top(m2 + 12), t + 0.07, -11.0)
            tp = top(m2 + 12)
            for k in range(3):
                put(buf, "tinkle", top(up_pent(tp, 1 + k)), t + 0.13 + 0.055 * k, -12.0 - 1.5 * k)
            i += 2
        else:
            i += 1
        if pad and (i - 1) % 4 == 0:
            put(buf, "pad", m, t, -19.0)
        t += step
    return buf


def hard_play(notes, inst, pad, lift, missed, step=0.30):
    buf = np.zeros(int((len(notes) * step + 3.0) * SR))
    combo = 0
    for i, n in enumerate(notes):
        t = i * step
        m = lifted(n, lift)
        put(buf, inst, m, t, -8.0)
        if pad and i % 4 == 0:
            put(buf, "pad", m, t, -21.0)
        if i in missed:
            combo = 0
            continue
        combo += 1
        up = 0.35 * min(combo, 8)
        put(buf, "xylo", top(m + 12), t, -7.0 + up)
        put(buf, "tinkle", top(m + 12), t, -9.0 + up)
        put(buf, inst, m, t, -3.0 + up)
        if combo >= 3 and combo % 2 == 1:
            put(buf, "glock", top(up_pent(m + 12, 2)), t, -10.0 + up)
    return buf


def wav_mono(path):
    with wave.open(path) as w:
        sr = w.getframerate()
        x = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2").astype(np.float64) / 32768.0
        if w.getnchannels() == 2:
            x = x.reshape(-1, 2).mean(axis=1)
    if sr != SR:
        x = signal.resample(x, int(len(x) * SR / sr))
    return x


def main():
    rnd = random.Random(18)
    parts = []
    names = []
    # EASY: what a press sounds like (silver, gold, diamond, a starter fry, a fish)
    for label, song, n, inst, pad, lift, golds in [
        ("EASY starter fry   - kalimba - Frere Jacques (a gold on the 3rd and 6th point)", "jacques", 8, "kalimba", False, 12, {2, 5}),
        ("EASY silver fry    - music box - Brahms' Lullaby", "lullaby", 8, "musicbox", False, 12, {1, 4}),
        ("EASY gold fry      - harp - Greensleeves", "greensleeves", 9, "harp", False, 0, {2, 6}),
        ("EASY diamond fry   - celesta + pad - Pachelbel's Canon", "canon", 10, "celesta", True, 0, {0, 3, 6}),
        ("EASY fish          - marimba - Row, Row, Row Your Boat", "row", 8, "marimba", False, 12, {2, 5}),
    ]:
        notes = resolve(segment(song, n, rnd))
        parts.append(easy_play(notes, inst, pad, lift, golds))
        names.append(label)
    # HARD: the music plays by itself, hits shine
    for label, song, n, inst, pad, lift, missed in [
        ("HARD silver fry    - the tune plays by itself, every hit shines (beat 5 missed)", "lullaby", 12, "musicbox", False, 12, {4}),
        ("HARD gold fry      - harp (beats 3 and 9 missed)", "greensleeves", 15, "harp", False, 0, {2, 8}),
        ("HARD diamond fry   - celesta + pad, quicker (a long streak)", "canon", 20, "celesta", True, 0, {13}),
    ]:
        notes = resolve(segment(song, n, rnd))
        parts.append(hard_play(notes, inst, pad, lift, missed, step=0.27 if "diamond" in label else 0.30))
        names.append(label)
    # the welcome of a friend gull, twice (a second of silence between)
    wel = wav_mono(os.path.join(SFX, "friend_welcome.wav")) * 0.8
    parts.append(np.concatenate([wel, np.zeros(SR)]))
    names.append("FRIEND GULL welcome song (lands next to you; the hearts ring bells on top of it)")
    hello = wav_mono(os.path.join(SFX, "hello.wav")) * 0.8
    parts.append(np.concatenate([hello, np.zeros(SR)]))
    names.append("FRIEND GULL hello (when it comes flying in)")
    allx = np.concatenate([np.concatenate([p, np.zeros(int(1.2 * SR))]) for p in parts])
    allx = allx / (np.max(np.abs(allx)) + 1e-9) * 0.8
    outdir = os.path.join(ROOT, "shots")
    wav = os.path.join(outdir, "r18_tunes_preview.wav")
    with wave.open(wav, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((allx * 32767).astype("<i2").tobytes())
    mp3 = os.path.join(outdir, "r18_tunes_preview.mp3")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-b:a", "160k", mp3], check=True)
    os.remove(wav)
    t = 0.0
    lines = []
    for m, nm in zip(parts, names):
        lines.append("%5.1f s  %s" % (t, nm))
        t += len(m) / SR + 1.2
    open(os.path.join(outdir, "r18_tunes_preview.txt"), "w", encoding="utf-8").write("\n".join(lines) + "\n")
    print("\n".join(lines))


main()
