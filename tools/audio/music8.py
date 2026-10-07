"""
Round 8: the pieces that people hear first and last, and the ones for the cinematic moments.  Original compositions (a warm, pastoral, plucked-and-woodwind
palette - a quiet cousin of the farm-sim soundtracks, never a copy), plus ONE arrangement of a public-domain classic for STARLIGHT:
  title      "Morning at the Pier"   G major, 84 bpm. A fingerpicked guitar, a clarinet, a flute, a celesta. The tune asks a question and never answers it.
  ending     "Home"                  the same tune, slower, and this time it comes home to G.
  star       after Mozart, Rondo alla Turca (1783, public domain): a marimba gallop for STARLIGHT, with an original major-key middle.
  cine_joy   the first time all three drinks are in (and a fish): a skipping little tune
  cine_wish  the first shooting star: harp and celesta
  cine_home  all 24 fries: a solo piano that does not finish its sentence
"""
import numpy as np
from synth import *
from synth_extra import *

# chords: (bass, triad)
G = (43, [55, 59, 62])
EM = (40, [55, 59, 64])
C = (48, [55, 60, 64])
D = (50, [57, 62, 66])
DSUS = (50, [57, 62, 67])
AM = (45, [57, 60, 64])


def arp(T, ch, bar, vel=0.5, pan=-0.25, gain=1.0, instr=guitar2, pat=(0, 2, 3, 2, 1, 2, 3, 2)):
    bass, tones = ch
    notes = [bass] + tones
    for k, idx in enumerate(pat):
        m = notes[idx]
        T.note(instr, m, bar, k * 0.5, 1.2 if idx == 0 else 0.9, vel + (0.12 if k % 4 == 0 else 0.0), pan + 0.05 * (k % 3), gain)


A_MEL = ["D5/1 B4/0.5 G4/0.5 B4/1 D5/1", "E5/1.5 D5/0.5 B4/1 G4/1", "C5/1 E5/1 D5/1 C5/1", "B4/2 A4/1 r/1",
         "D5/1 B4/0.5 G4/0.5 B4/1 D5/1", "G5/1.5 E5/0.5 D5/1 B4/1", "A4/1 C5/1 E5/1 G5/1", "F#5/2 D5/1 r/1"]
B_MEL = ["B5/1.5 G5/0.5 E5/1 G5/1", "F#5/1.5 A5/0.5 F#5/1 D5/1", "E5/1.5 G5/0.5 C6/1 B5/1", "A5/1 B5/1 G5/2",
         "B5/1.5 G5/0.5 E5/1 G5/1", "F#5/1.5 A5/0.5 D6/1 C#6/1", "B5/1 G5/1 E5/1 C5/1", "A4/2 B4/1 C5/1"]
A_PROG = [G, EM, C, D, G, EM, C, D]
B_PROG = [EM, D, C, G, EM, D, C, D]


def lower(tokens, octaves=1):
    """'D5/1 B4/0.5' -> one octave lower"""
    out = []
    for tok in tokens.split():
        name, d = tok.split("/")
        if name != "r":
            i = 1
            while name[i] in "#b":
                i += 1
            name = name[:i] + str(int(name[i:]) - octaves)
        out.append(name + "/" + d)
    return " ".join(out)


def higher(tokens, octaves=1):
    return lower(tokens, -octaves)


# ------------------------------------------------------------------ TITLE
def title():
    T = Track(84, 40, 4, tail=5.0)
    prog = [G, EM, C, D] + A_PROG + B_PROG + A_PROG + B_PROG + [G, EM, C, DSUS]
    for bar, ch in enumerate(prog):
        sec = "intro" if bar < 4 else "A" if bar < 12 else "B" if bar < 20 else "A2" if bar < 28 else "B2" if bar < 36 else "out"
        arp(T, ch, bar, vel=0.46 if sec in ("intro", "out") else 0.5)
        if bar >= 2:
            T.note(pluck_bass, ch[0], bar, 0, 1.8, 0.62, -0.1, 0.9)
            T.note(pluck_bass, ch[0] + 7, bar, 2, 1.6, 0.5, -0.1, 0.8)
        if sec in ("A", "A2", "B", "B2"):
            T.hit(brush, bar, 1, 0.35, 0.2, 0.7)
            T.hit(brush, bar, 3, 0.4, 0.2, 0.7)
        if sec in ("B", "B2"):
            for k in range(8):
                T.hit(shaker, bar, k * 0.5 + 0.25 if False else k * 0.5, 0.18 + 0.1 * (k % 2 == 0), 0.35, 0.6)
            T.hit(soft_kick, bar, 0, 0.45, 0.0, 0.6)
            T.hit(soft_kick, bar, 2, 0.35, 0.0, 0.5)
            T.chord(strings, ch[1], bar, 0, 4, 0.3, 0.0, 0.5, voices=4, attack=0.9, release=1.0, cutoff=1400)
        if sec == "A2":
            T.chord(accordion, [ch[1][0], ch[1][2]], bar, 0, 4, 0.4, 0.15, 0.7)
        if sec == "intro" and bar == 3:
            for k, m in enumerate([86, 90, 93, 98]):
                T.note(glock, m, bar, 2 + k * 0.4, 1.5, 0.4, 0.3, 0.6)
    # the melody
    for i, ph in enumerate(A_MEL):
        T.parse(clarinet, ph, 4 + i, 0, 0.58, 0.12, 1.15)                      # A: clarinet
        T.parse(celesta, higher(ph), 20 + i, 0, 0.5, 0.25, 0.8)                 # A2: celesta an octave up
        T.parse(clarinet, ph, 20 + i, 0, 0.4, -0.05, 0.8)
    for i, ph in enumerate(B_MEL):
        T.parse(flute, ph, 12 + i, 0, 0.56, 0.12, 1.1)                          # B: flute
        T.parse(flute, ph, 28 + i, 0, 0.58, 0.1, 1.0)                           # B2: flute + clarinet below + pizzicato echoes
        T.parse(clarinet, lower(ph), 28 + i, 0, 0.45, -0.08, 0.8)
        if i % 2 == 0:
            T.note(glock, midi(ph.split()[0].split("/")[0]) + 12, 28 + i, 0, 1.0, 0.45, 0.3, 0.6)
    # a little bass-line answer in the B parts
    for i in range(8):
        T.note(pizz, B_PROG[i][1][0] + 12, 12 + i, 2.5, 0.4, 0.5, 0.25, 0.7)
    # the coda: the tune loses its nerve
    T.parse(clarinet, "B4/2 D5/2", 36, 0, 0.5, 0.1, 1.0)
    T.parse(clarinet, "E5/2 B4/2", 37, 0, 0.45, 0.1, 1.0)
    T.parse(clarinet, "C5/2 E5/2", 38, 0, 0.45, 0.1, 1.0)
    T.parse(clarinet, "A4/3 r/1", 39, 0, 0.45, 0.1, 1.0)
    T.note(celesta, 93, 38, 3, 1.0, 0.4, 0.3, 0.6)
    return T.render(0.3, 2.4, 4800.0, 0.8, 51)


# ------------------------------------------------------------------ ENDING
def ending():
    T = Track(72, 32, 4, tail=8.0)
    prog = [G, EM, C, D] + A_PROG + B_PROG + A_PROG + [G, C, G, G]
    for bar, ch in enumerate(prog):
        sec = "intro" if bar < 4 else "A" if bar < 12 else "B" if bar < 20 else "A2" if bar < 28 else "out"
        if sec == "intro":
            T.note(piano, ch[0], bar, 0, 3.8, 0.4, -0.15, 1.0)
            for k, m in enumerate([ch[1][0], ch[1][1], ch[1][2], ch[1][1]]):
                T.note(piano, m, bar, k, 1.2, 0.3, 0.1, 0.8)
            T.chord(strings, ch[1], bar, 0, 4, 0.22, 0.0, 0.45, voices=4, attack=1.2, release=1.4, cutoff=1200)
        elif sec == "out":
            T.note(piano, ch[0], bar, 0, 4, 0.45, -0.15, 1.0)
            T.chord(piano, ch[1], bar, 0, 4, 0.34, 0.1, 0.8, spread=0.12)
            T.chord(strings, ch[1], bar, 0, 4, 0.34, 0.0, 0.6, voices=5, attack=1.0, release=2.0, cutoff=1500)
        else:
            arp(T, ch, bar, vel=0.4 if sec == "A" else 0.46)
            T.note(pluck_bass, ch[0], bar, 0, 1.8, 0.55, -0.1, 0.9)
            T.note(pluck_bass, ch[0] + 7, bar, 2, 1.6, 0.45, -0.1, 0.8)
            T.chord(strings, ch[1], bar, 0, 4, 0.28 if sec == "A" else 0.36, 0.0, 0.55, voices=4, attack=1.0, release=1.2, cutoff=1400)
            if sec in ("B", "A2"):
                T.chord(accordion, [ch[1][0], ch[1][2]], bar, 0, 4, 0.35, 0.15, 0.6)
    # the tune again - slower, and this time the last phrase goes home
    home_a = A_MEL[:7] + ["D5/1 F#5/1 G5/2"]
    for i, ph in enumerate(home_a):
        T.parse(piano, ph, 4 + i, 0, 0.55, 0.05, 1.1)
        T.parse(flute, ph, 4 + i, 0, 0.48, 0.15, 0.7)
    T.note(piano, 67, 11, 2, 2, 0.5, 0.0, 0.7)
    for i, ph in enumerate(B_MEL):
        T.parse(clarinet, ph, 12 + i, 0, 0.55, 0.1, 1.0)
        T.parse(celesta, higher(ph), 12 + i, 0, 0.38, 0.3, 0.6)
    for i, ph in enumerate(A_MEL):
        last = (i == 7)
        T.parse(celesta, higher(ph if not last else "D5/1 F#5/1 G5/2"), 20 + i, 0, 0.55, 0.25, 0.9)
        T.parse(flute, ph if not last else "D5/1 F#5/1 G5/2", 20 + i, 0, 0.55, 0.0, 1.0)
        T.parse(clarinet, lower(ph if not last else "D5/1 F#5/1 G5/2"), 20 + i, 0, 0.4, -0.15, 0.7)
    # coda: "yes, that one"
    T.parse(flute, "D5/2 B4/2", 28, 0, 0.5, 0.1, 0.9)
    T.parse(flute, "E5/2 C5/2", 29, 0, 0.5, 0.1, 0.9)
    T.parse(flute, "B4/2 D5/2", 30, 0, 0.5, 0.1, 0.9)
    T.parse(flute, "G4/4", 31, 0, 0.5, 0.1, 0.9)
    T.note(celesta, 91, 30, 2, 2, 0.45, 0.3, 0.7)
    T.note(bell, 79, 31, 0, 6, 0.4, 0.2, 0.8)
    T.note(bell, 98, 31, 0.5, 6, 0.3, -0.2, 0.6)
    return T.render(0.4, 3.6, 4200.0, 0.82, 53)


# ------------------------------------------------------------------ STARLIGHT: after Mozart's Rondo alla Turca (A minor / A major), a marimba gallop
TURK_A = ["B4/.25 A4/.25 G#4/.25 A4/.25 C5/1 D5/.25 C5/.25 B4/.25 C5/.25 E5/1",
          "F5/.25 E5/.25 D#5/.25 E5/.25 B5/.25 A5/.25 G#5/.25 A5/.25 B5/.25 A5/.25 G#5/.25 A5/.25 C6/1",
          "A5/.5 C6/.5 B5/.25 A5/.25 G#5/.25 A5/.25 E5/1 r/1",
          "A5/.5 C6/.5 B5/.25 A5/.25 G#5/.25 A5/.25 A5/2"]
TURK_A_CH = [[(AM, 2), (("E7"), 2)], [(AM, 2), ("E7", 2)], [(AM, 2), ("E7", 2)], [(AM, 2), (AM, 2)]]
TURK_B = ["E5/.5 A5/.5 C#6/.5 A5/.5 E6/1 C#6/1", "D6/.5 A5/.5 F#5/.5 A5/.5 D6/2", "G#5/.5 B5/.5 E6/.5 B5/.5 G#5/1 B5/1", "A5/2 C#6/1 E6/1",
          "F#5/.5 A5/.5 C#6/.5 A5/.5 F#6/1 C#6/1", "D6/.5 C#6/.5 B5/.5 A5/.5 F#5/2", "G#5/.5 B5/.5 D6/.5 B5/.5 G#5/.5 E5/.5 G#5/1", "A5/1 C#6/1 A5/1 E5/1"]
TURK_B_PROG = [("A", 45, [57, 61, 64]), ("D", 50, [57, 62, 66]), ("E", 52, [56, 59, 64]), ("A", 45, [57, 61, 64]),
               ("F#m", 42, [57, 61, 66]), ("D", 50, [57, 62, 66]), ("E", 52, [56, 59, 64]), ("A", 45, [57, 61, 64])]
E7 = (40, [56, 59, 62])


def star():
    T = Track(138, 36, 4, tail=3.0)
    am = (45, [57, 60, 64])
    e7 = (52, [56, 59, 62])

    def drums(bar, level=1.0, fill=False):
        T.hit(soft_kick, bar, 0, 0.6 * level, 0.0, 0.7)
        T.hit(soft_kick, bar, 2, 0.5 * level, 0.0, 0.6)
        T.hit(brush, bar, 1, 0.5 * level, 0.15, 0.8)
        T.hit(brush, bar, 3, 0.55 * level, 0.15, 0.8)
        for k in range(8):
            T.hit(tamb, bar, k * 0.5 + 0.5 if False else k * 0.5, 0.3 + 0.25 * (k % 2 == 1), 0.3, 0.55 * level)
        if fill:
            for k in range(6):
                T.hit(brush, bar, 3 + k / 6.0, 0.3 + 0.1 * k, 0.0, 0.8)

    def oompah(bar, ch_a, ch_b, level=1.0):
        # two chords per bar (beats 0-2 and 2-4): a bass note, then two off-beat stabs
        for half, ch in enumerate((ch_a, ch_b)):
            b0 = half * 2
            T.note(pluck_bass, ch[0], bar, b0, 0.9, 0.7 * level, -0.2, 1.0)
            for beat in (b0 + 0.5, b0 + 1.0, b0 + 1.5):
                T.chord(pizz, ch[1], bar, beat, 0.3, 0.5 * level, 0.1, 0.7, spread=0.02)

    # 0-1: the run-up: a rising arpeggio and a snare roll
    notes = [57, 60, 64, 69, 72, 76, 81, 84]
    for k, m in enumerate(notes):
        T.note(marimba, m, 0, k * 0.5, 0.5, 0.45 + 0.05 * k, 0.1, 0.8)
    for k in range(16):
        T.hit(brush, 1, k * 0.25, 0.2 + 0.04 * k, 0.0, 0.9)
    T.note(bell, 93, 1, 3.5, 1.0, 0.4, 0.2, 0.6)
    # 2-5 A (marimba), 6-9 A again (flute joins), 10-17 B (major), 18-21 A (strings + clarinet), 22-29 B (full), 30-33 A (finale), 34-35 tag
    secs = [(2, "A", 0), (6, "A", 1), (10, "B", 0), (18, "A", 2), (22, "B", 1), (30, "A", 3)]
    for start, kind, v in secs:
        if kind == "A":
            for i, ph in enumerate(TURK_A):
                bar = start + i
                oompah(bar, am, e7 if i < 3 else am, 0.8 + 0.1 * v)
                drums(bar, 0.7 + 0.1 * v, fill=(i == 3 and v in (0, 2)))
                if v == 0:
                    T.parse(marimba, ph, bar, 0, 0.72, 0.15, 1.0)
                elif v == 1:
                    T.parse(marimba, ph, bar, 0, 0.7, 0.2, 0.9)
                    T.parse(flute, higher(ph), bar, 0, 0.5, -0.1, 0.6)
                elif v == 2:
                    T.parse(clarinet, ph, bar, 0, 0.6, 0.0, 0.9)
                    T.parse(celesta, higher(ph), bar, 0, 0.45, 0.3, 0.7)
                    T.chord(strings, am[1], bar, 0, 4, 0.3, 0.0, 0.5, voices=4, attack=0.3, release=0.4, cutoff=1800)
                else:
                    T.parse(brass, ph, bar, 0, 0.7, 0.0, 0.7)
                    T.parse(marimba, higher(ph), bar, 0, 0.7, 0.2, 0.9)
                    T.chord(strings, am[1], bar, 0, 4, 0.34, 0.0, 0.55, voices=4, attack=0.2, release=0.4, cutoff=2200)
        else:
            for i, ph in enumerate(TURK_B):
                bar = start + i
                name, root, ch = TURK_B_PROG[i]
                oompah(bar, (root, ch), (root + 7 if name != "E" else root + 7, ch), 0.85 + 0.1 * v)
                drums(bar, 0.85 + 0.1 * v, fill=(i == 7))
                if v == 0:
                    T.parse(marimba, ph, bar, 0, 0.72, 0.15, 1.0)
                    T.parse(glock, higher(ph), bar, 0, 0.4, 0.35, 0.5)
                else:
                    T.parse(flute, ph, bar, 0, 0.6, 0.1, 0.9)
                    T.parse(marimba, ph, bar, 0, 0.72, 0.2, 0.9)
                    T.parse(brass, lower(ph), bar, 0, 0.55, -0.1, 0.45)
                    T.chord(strings, ch, bar, 0, 4, 0.34, 0.0, 0.5, voices=4, attack=0.2, release=0.4, cutoff=2300)
    # the tag: a last flourish that lands on the first chord of the loop's intro
    for k, m in enumerate([81, 79, 76, 72, 69, 64, 60, 57]):
        T.note(marimba, m, 34, k * 0.5, 0.5, 0.6, -0.1, 0.8)
    T.chord(marimba, [57, 60, 64, 69], 35, 0, 1.0, 0.7, 0.0, 0.7)
    T.hit(soft_kick, 35, 0, 0.7, 0.0, 0.8)
    return T.render(0.2, 1.6, 6000.0, 0.85, 57)


# ------------------------------------------------------------------ CINEMATIC PIECES
def cine_joy():
    T = Track(124, 16, 4, tail=4.0)
    D_ = ("D", 50, [57, 62, 66])
    A_ = ("A", 45, [57, 61, 64])
    BM = ("Bm", 47, [59, 62, 66])
    G_ = ("G", 43, [55, 59, 62])
    prog = [D_, A_, BM, G_, D_, A_, G_, A_] * 2
    tune1 = ["F#5/.5 A5/.5 D6/1 C#6/.5 B5/.5 A5/1", "E5/.5 G#5/.5 A5/1 B5/.5 C#6/.5 E6/1", "D6/.5 C#6/.5 B5/.5 A5/.5 B5/1 D6/1", "B5/.5 A5/.5 G5/.5 F#5/.5 G5/2",
             "F#5/.5 A5/.5 D6/1 F#6/1 E6/1", "E6/.5 D6/.5 C#6/1 B5/.5 A5/.5 B5/1", "G5/1 B5/1 D6/1 B5/1", "A5/1 C#6/1 E6/2"]
    for bar, (name, root, ch) in enumerate(prog):
        T.note(pluck_bass, root, bar, 0, 0.8, 0.7, -0.2, 1.0)
        T.note(pluck_bass, root + 7, bar, 2, 0.8, 0.6, -0.2, 0.9)
        for k in range(8):
            T.note(marimba, ch[[0, 1, 2, 1][k % 4]] + 12, bar, k * 0.5, 0.5, 0.45 + 0.1 * (k % 2 == 0), 0.15 - 0.3 * (k % 2), 0.7)
        for beat in (0.5, 1.5, 2.5, 3.5):
            T.chord(pizz, ch, bar, beat, 0.3, 0.4, 0.1, 0.5, spread=0.02)
        T.hit(woodblock, bar, 1, 0.5, 0.3, 0.5)
        T.hit(woodblock, bar, 3, 0.55, -0.3, 0.5)
        T.hit(soft_kick, bar, 0, 0.5, 0.0, 0.5)
        if bar >= 8:
            T.chord(strings, ch, bar, 0, 4, 0.3, 0.0, 0.4, voices=4, attack=0.3, release=0.4, cutoff=2200)
    for i, ph in enumerate(tune1):
        T.parse(flute if i < 8 else celesta, ph, i, 0, 0.58, 0.1, 0.9)
        T.parse(flute, ph, 8 + i, 0, 0.6, 0.1, 0.8)
        T.parse(glock, higher(ph), 8 + i, 0, 0.4, 0.3, 0.45)
    return T.render(0.22, 1.8, 6000.0, 0.82, 61)


def cine_wish():
    T = Track(66, 12, 4, tail=6.0)
    prog = [("D", 38, [62, 66, 69, 74]), ("Bm", 35, [62, 66, 71, 74]), ("G", 43, [62, 67, 71, 74]), ("A", 45, [61, 64, 69, 73]),
            ("D", 38, [62, 66, 69, 74]), ("F#m", 42, [61, 66, 69, 73]), ("G", 43, [62, 67, 71, 74]), ("A", 45, [61, 64, 69, 73]),
            ("Bm", 35, [62, 66, 71, 74]), ("G", 43, [62, 67, 71, 74]), ("A", 45, [61, 64, 69, 73]), ("D", 38, [62, 66, 69, 74])]
    mel = ["A5/2 F#5/1 D5/1", "B5/2 A5/1 F#5/1", "G5/1.5 B5/0.5 D6/2", "C#6/3 A5/1", "D6/2 A5/1 F#5/1", "C#6/2 A5/1 F#5/1", "B5/1 D6/1 G6/2", "E6/4",
           "F#6/2 D6/2", "D6/1 B5/1 G5/2", "E6/2 C#6/2", "D6/4"]
    for bar, (name, root, ch) in enumerate(prog):
        for k in range(8):
            m = ch[[0, 1, 2, 3, 2, 1, 2, 3][k]]
            T.note(harp2, m, bar, k * 0.5, 1.5, 0.45 + 0.1 * (k % 4 == 0), -0.3 + 0.1 * k, 0.8)
        T.note(strings, root + 12, bar, 0, 4, 0.34, 0.0, 0.5, voices=4, attack=1.2, release=1.4, cutoff=1300)
        if bar >= 2:
            T.chord(strings, ch[1:], bar, 0, 4, 0.3, 0.1, 0.4, voices=4, attack=1.4, release=1.6, cutoff=1700)
        T.parse(celesta, mel[bar], bar, 0, 0.5, 0.25, 0.9)
        if bar % 2 == 0:
            T.note(bell, 100 - (bar % 4), bar, 2.5, 2, 0.3, 0.4, 0.5)
    return T.render(0.45, 3.8, 3800.0, 0.78, 63)


def cine_home():
    T = Track(60, 12, 4, tail=6.0)
    Em_ = (40, [55, 59, 64])
    C_ = (48, [55, 60, 64])
    G_ = (43, [55, 59, 62])
    D_ = (50, [57, 62, 66])
    prog = [Em_, C_, G_, D_, Em_, C_, G_, D_, Em_, C_, G_, DSUS]
    mel = ["B4/2 G4/1 E4/1", "E5/2 D5/1 C5/1", "D5/2 B4/1 G4/1", "A4/3 r/1", "B4/2 G4/1 E4/1", "E5/2 G5/1 E5/1", "D5/1.5 B4/0.5 G4/2", "F#4/2 A4/2", "B4/2 E5/2", "C5/2 E5/2", "D5/3 r/1", "A4/4"]
    for bar, ch in enumerate(prog):
        T.note(piano, ch[0], bar, 0, 3.6, 0.38, -0.15, 1.0)
        for k, m in enumerate([ch[1][0], ch[1][1], ch[1][2], ch[1][1]]):
            T.note(piano, m, bar, k, 1.4, 0.26, 0.1, 0.8)
        if bar >= 1:
            T.chord(strings, ch[1], bar, 0, 4, 0.24, 0.0, 0.4, voices=4, attack=1.4, release=1.8, cutoff=1200)
        T.parse(piano if bar < 8 else clarinet, mel[bar], bar, 0, 0.5, 0.05, 1.1)
    T.note(celesta, 93, 11, 1, 3, 0.4, 0.3, 0.6)
    return T.render(0.42, 3.8, 3600.0, 0.78, 65)


TRACKS8 = {"title": title, "ending": ending, "star": star, "cine_joy": cine_joy, "cine_wish": cine_wish, "cine_home": cine_home}
