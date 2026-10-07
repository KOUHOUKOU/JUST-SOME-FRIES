"""
The music of JUST SOME FRIES (round 7). Every piece is an ARRANGEMENT in the spirit of a famous public-domain work (all composed before 1929),
written out note by note and rendered by synth.py:
  title      after Satie, Gymnopedie No. 1  (the opening and the menu: a slow waltz that never comes home)
  boardwalk  after Pachelbel, Canon in D    (the cafe and the boardwalk: a ground bass and a melody that keeps getting busier)
  beach      a bossa nova in G              (sun, ukulele and marimba)
  hill       after Bach, Prelude in C       (the old town on its stairs: broken chords on a harp)
  sea        after Debussy, Clair de lune   (the pier and the open water: floating chords in D flat)
  summit     after Grieg, Morning Mood      (the plaza and the farm: a flute over strings)
  sky        after Bach, Air on the G string(high above the clouds: long lines)
  star       after Rossini, William Tell    (STARLIGHT: a gallop)
  ending     a quiet piece in C             (it finally comes home)
"""
import numpy as np
from synth import *

OUT = None  # set by render_all.py


# ------------------------------------------------------------------ chord helpers
def chord_tones(root, quality="maj"):
    r = {"maj": [0, 4, 7], "min": [0, 3, 7], "dom7": [0, 4, 7, 10], "maj7": [0, 4, 7, 11], "min7": [0, 3, 7, 10], "sus": [0, 5, 7], "maj9": [0, 4, 7, 11, 14],
         "min9": [0, 3, 7, 10, 14], "add9": [0, 4, 7, 14]}[quality]
    return [root + i for i in r]


def arp5(root, quality="maj", octave_root=48):
    """the five notes of a Bach-prelude bar: the bass, then the upper chord tones"""
    t = chord_tones(octave_root + (root % 12), quality)
    third, fifth = t[1], t[2]
    if len(t) > 3:
        return [t[0], fifth, t[3], third + 12, fifth + 12]
    return [t[0], third, fifth, t[0] + 12, third + 12]


# ------------------------------------------------------------------ TITLE: after Satie's Gymnopedie No. 1 (D major, 3/4, Lent et douloureux)
def title():
    T = Track(66, 32, 3, tail=5.0)
    G = ([43], [59, 62, 66])      # Gmaj7
    D = ([38], [57, 61, 66])      # Dmaj7
    EM = ([40], [55, 59, 62])     # Em7
    A7 = ([33], [55, 61, 64])     # A7
    BM = ([35], [57, 62, 66])     # Bm7
    prog = [G, D] * 4 + [G, D, G, D, G, D, EM, A7] + [G, D, G, D, G, D, EM, A7] + [EM, A7, D, BM, EM, A7, D, G]
    for bar, (bass, ch) in enumerate(prog):
        T.note(piano, bass[0], bar, 0, 2.6, 0.42, -0.1, 1.0)
        T.chord(piano, ch, bar, 1, 1, 0.33, 0.08, 0.9)
        T.chord(piano, ch, bar, 2, 1, 0.3, 0.08, 0.85)
        if bar >= 8:
            T.chord(strings, [ch[0], ch[2]], bar, 0, 3, 0.25, 0.0, 0.5, voices=4, attack=1.0, release=1.2, cutoff=1500)
    # the melody (from bar 8): F# A G F# - C# B C# D ...  long notes, neighbour notes, nothing resolves
    A = ["F#5/3", "A5/2 G5/1", "F#5/2 C#5/1", "B4/3", "C#5/1 B4/1 C#5/1", "D5/3", "E5/2 D5/1", "C#5/3"]
    A2 = ["F#5/3", "A5/2 B5/1", "A5/2 F#5/1", "D5/3", "C#5/1 D5/1 E5/1", "F#5/3", "E5/2 D5/1", "C#5/3"]
    B = ["G5/3", "E5/2 F#5/1", "D5/3", "F#5/2 E5/1", "B4/3", "C#5/2 E5/1", "F#5/3", "A5/3"]
    for i, ph in enumerate(A):
        T.parse(piano, ph, 8 + i, 0, 0.55, 0.05, 1.1)
    for i, ph in enumerate(A2):
        T.parse(piano, ph, 16 + i, 0, 0.55, 0.05, 1.1)
        if i in (0, 3, 7):
            T.note(musicbox, 90, 16 + i, 0, 2, 0.35, 0.3, 0.7)           # F#6, a music-box echo
    for i, ph in enumerate(B):
        T.parse(piano, ph, 24 + i, 0, 0.55, 0.05, 1.1)
    # a few high sparkles
    for bar, m in [(3, 93), (7, 90), (11, 97), (19, 93), (27, 88)]:
        T.note(musicbox, m, bar, 1.5, 1.5, 0.28, 0.4, 0.55)
    return T.render(0.38, 3.2, 3800.0, 0.8, 5)


# ------------------------------------------------------------------ BOARDWALK: after Pachelbel's Canon in D
def boardwalk():
    T = Track(78, 32, 4, tail=5.0)
    chords = [("D", [62, 66, 69]), ("A", [61, 64, 69]), ("Bm", [62, 66, 71]), ("F#m", [61, 66, 69]), ("G", [62, 67, 71]), ("D", [62, 66, 69]), ("G", [62, 67, 71]), ("A", [61, 64, 69])]
    bass = [50, 45, 47, 42, 43, 38, 43, 45]
    guide = [78, 76, 74, 73, 71, 69, 71, 73]          # F# E D C# B A B C#  (the famous falling line)
    hi = [[74, 78, 81], [73, 76, 81], [74, 78, 83], [73, 78, 81], [74, 79, 83], [74, 78, 81], [74, 79, 83], [73, 76, 81]]
    for cyc in range(8):
        b0 = cyc * 4
        for i in range(8):
            bar = b0 + i // 2
            beat = (i % 2) * 2.0
            ch = chords[i][1]
            # ground bass: every cycle, plucked
            T.note(pluck_bass, bass[i], bar, beat, 2, 0.7, -0.2, 1.0)
            # harp: quarter notes at first, then eighths
            lo = [ch[0] - 12, ch[1] - 12, ch[2] - 12]
            if cyc < 2:
                for k, m in enumerate([lo[0], lo[1], lo[2], lo[1]]):
                    T.note(harp, m, bar, beat + k * 0.5, 1.0, 0.55, -0.15, 0.9)
            else:
                for k, m in enumerate([lo[0], lo[1], lo[2], lo[1], lo[0] + 12, lo[1], lo[2], lo[1]]):
                    T.note(harp, m, bar, beat + k * 0.25, 1.0, 0.5 + 0.1 * (k % 2 == 0), -0.15, 0.85)
            if cyc >= 1:
                T.chord(strings, [ch[0] - 12, ch[1] - 12, ch[2] - 12], bar, beat, 2, 0.28, 0.0, 0.6, voices=4, attack=0.35, release=0.5, cutoff=1900)
            # the melody, getting busier with every round of the cycle
            g = guide[i]
            if cyc == 1:
                T.note(flute, g, bar, beat, 2, 0.5, 0.15, 1.0)
            elif cyc == 2:
                T.note(flute, g, bar, beat, 1, 0.55, 0.15, 1.0)
                T.note(flute, hi[i][0] if hi[i][0] != g else hi[i][1], bar, beat + 1, 1, 0.5, 0.15, 1.0)
            elif cyc in (3, 4):
                seq = [g, hi[i][0] + 0, g, hi[i][1]] if cyc == 3 else [hi[i][1], g, hi[i][0], hi[i][2]]
                for k, m in enumerate(seq):
                    T.note(musicbox if cyc == 3 else flute, m if cyc == 4 else m, bar, beat + k * 0.5, 0.6, 0.55, 0.2, 1.0)
            elif cyc in (5, 6):
                seq = [hi[i][0], hi[i][1], hi[i][2], hi[i][1], hi[i][0], hi[i][1], hi[i][2], g]
                for k, m in enumerate(seq):
                    T.note(musicbox if cyc == 5 else flute, m + (12 if cyc == 6 and k == 7 else 0), bar, beat + k * 0.25, 0.4, 0.5 + 0.12 * (k % 2 == 0), 0.2, 1.0)
            elif cyc == 7:
                T.note(flute, g, bar, beat, 2, 0.55, 0.15, 1.0)
            # soft time-keeping
            if cyc >= 2:
                for k in range(4):
                    T.hit(shaker, bar, beat + k * 0.5, 0.45 + 0.2 * (k % 2 == 0), 0.3, 0.7)
                T.hit(rim, bar, beat + 1, 0.3, 0.1, 0.5)
    return T.render(0.3, 2.4, 4800.0, 0.82, 11)


# ------------------------------------------------------------------ BEACH: a bossa nova in G
def beach():
    T = Track(108, 32, 4, tail=4.0)
    chords = [("Gmaj7", 43, [59, 62, 66, 69]), ("E7", 40, [56, 62, 64, 68]), ("Am7", 45, [55, 60, 64, 67]), ("D7", 38, [54, 60, 62, 69]),
              ("Gmaj7", 43, [59, 62, 66, 69]), ("Bm7", 47, [57, 62, 66, 69]), ("Cmaj7", 48, [55, 59, 64, 67]), ("D7", 38, [54, 60, 62, 69])]
    mel = ["D5/1 B4/0.5 D5/0.5 G5/1.5 F#5/0.5", "E5/1 B4/0.5 G#4/0.5 B4/1.5 D5/0.5", "C5/1 E5/0.5 C5/0.5 A4/1.5 B4/0.5", "C5/1 A4/0.5 F#4/0.5 A4/1 C5/1",
           "B4/1 D5/0.5 G5/0.5 B5/1.5 A5/0.5", "F#5/1 D5/0.5 B4/0.5 D5/1.5 F#5/0.5", "E5/1 G5/0.5 E5/0.5 C5/1.5 D5/0.5", "F#5/1 A5/0.5 F#5/0.5 D5/2"]
    for bar in range(32):
        name, root, ch = chords[bar % 8]
        # bossa bass: root, fifth, root, fifth
        T.note(pluck_bass, root, bar, 0, 1.4, 0.8, -0.2, 1.0)
        T.note(pluck_bass, root + 7, bar, 1.5, 0.9, 0.6, -0.2, 0.9)
        T.note(pluck_bass, root, bar, 2.5, 1.4, 0.7, -0.2, 0.9)
        T.note(pluck_bass, root + 7, bar, 3.5, 0.5, 0.55, -0.2, 0.8)
        # ukulele stabs
        for beat in [0.5, 1.5, 3.0]:
            T.chord(guitar, ch, bar, beat, 0.6, 0.55, 0.25, 0.7, spread=0.03)
        # percussion
        for k in range(8):
            T.hit(shaker, bar, k * 0.5, 0.5 + 0.25 * (k % 2 == 0), 0.35, 0.8)
        T.hit(kick, bar, 0, 0.5, 0.0, 0.55, f0=95.0, f1=50.0)
        T.hit(kick, bar, 2.5, 0.4, 0.0, 0.45, f0=95.0, f1=50.0)
        T.hit(rim, bar, 1.5, 0.45, 0.15, 0.6)
        T.hit(rim, bar, 3.0, 0.4, 0.15, 0.55)
        if bar >= 4:
            T.chord(strings, [ch[0] - 12, ch[1] - 12, ch[2] - 12], bar, 0, 4, 0.2, 0.0, 0.45, voices=3, attack=0.5, release=0.6, cutoff=1500)
    # the tune: marimba, then flute, then both, then flute
    for rep in range(4):
        for i, ph in enumerate(mel):
            bar = rep * 8 + i
            if rep == 0:
                T.parse(marimba, ph, bar, 0, 0.7, 0.2, 1.0)
            elif rep == 1:
                T.parse(flute, ph, bar, 0, 0.6, 0.15, 0.9)
            elif rep == 2:
                T.parse(marimba, ph, bar, 0, 0.7, 0.2, 0.9)
                T.parse(musicbox, ph.replace("5", "6"), bar, 0, 0.4, 0.4, 0.5)
            else:
                T.parse(flute, ph, bar, 0, 0.62, 0.15, 0.9)
                T.parse(marimba, ph, bar, 0.5 if False else 0, 0.45, -0.2, 0.55)
    return T.render(0.22, 1.8, 6000.0, 0.82, 17)


# ------------------------------------------------------------------ HILL: after Bach's Prelude in C (a harp, a cello, a little bell)
def hill():
    T = Track(64, 32, 4, tail=5.0)
    prog = [(0, "maj"), (2, "min7"), (7, "dom7"), (0, "maj"), (9, "min"), (2, "dom7"), (7, "maj"), (7, "sus"), (4, "min"), (9, "min7"), (2, "dom7"), (7, "maj"),
            (0, "maj"), (5, "maj"), (7, "dom7"), (0, "maj")] * 2
    top_line = [76, 74, 74, 76, 76, 74, 74, 72, 71, 72, 74, 74, 76, 77, 74, 72]
    for bar, (root, q) in enumerate(prog):
        notes = arp5(root, q, 48)
        for half in range(2):
            pat = [notes[0], notes[1], notes[2], notes[3], notes[4], notes[2], notes[3], notes[4]]
            for k, m in enumerate(pat):
                T.note(harp, m, bar, half * 2 + k * 0.25, 1.0, 0.5 + 0.12 * (k == 0), -0.1 + 0.2 * (k / 7.0), 0.85)
        # a cello holding the root, and from the second round a slow melody on top
        T.note(strings, notes[0] - 12, bar, 0, 4, 0.4, -0.2, 0.55, voices=3, attack=0.6, release=0.8, cutoff=900)
        if bar >= 4:
            T.note(strings, notes[3] + 0, bar, 0, 4, 0.3, 0.2, 0.35, voices=4, attack=0.8, release=1.0, cutoff=1700)
        if bar >= 16:
            T.note(flute, top_line[bar % 16], bar, 0, 3.2, 0.5, 0.2, 0.9)
        if bar % 8 == 7:
            T.note(bell, 95, bar, 2, 2, 0.4, 0.35, 0.6)
    return T.render(0.34, 2.8, 4200.0, 0.8, 23)


# ------------------------------------------------------------------ SEA: after Debussy's Clair de lune (D flat, floating)
def sea():
    T = Track(120, 32, 6, tail=5.5)           # a beat = an eighth note (6 to the bar)
    Db, Eb, F, Gb, Ab, Bb = 61, 63, 65, 66, 68, 70
    prog = [("Dbmaj9", [Db - 12, Ab - 12, F, Ab, Eb + 12]), ("Dbmaj9", [Db - 12, Ab - 12, F, Ab, Eb + 12]), ("Gbmaj7", [Gb - 12, Db, Bb - 12 + 12, Db + 12, F + 12 - 12]),
            ("Ebm9", [Eb - 12, Bb - 12, Gb, Bb, F + 12]), ("Ab", [Ab - 12, Eb, Ab, Bb + 0, Db + 12]), ("Dbmaj9", [Db - 12, Ab - 12, F, Ab, Eb + 12]),
            ("Gbmaj7", [Gb - 12, Db, Bb, Db + 12, F + 12]), ("Dbmaj9", [Db - 12, Ab - 12, F, Ab, Eb + 12])]
    melody = ["F5/3 Ab5/1.5 F5/1.5", "Eb5/3 Db5/3", "Bb4/3 Db5/1.5 Eb5/1.5", "F5/6", "Ab5/3 Bb5/1.5 Ab5/1.5", "F5/3 Eb5/1.5 Db5/1.5", "Bb4/3 Db5/3", "Db5/6"]
    for bar in range(32):
        name, ch = prog[bar % 8]
        # flowing harp arpeggio: six notes up, a little more air each time round
        for k in range(6):
            m = ch[[0, 1, 2, 3, 4, 3][k]]
            T.note(harp, m, bar, k, 2.0, 0.5, -0.3 + 0.1 * k, 0.8)
        T.note(strings, ch[0], bar, 0, 6, 0.4, -0.2, 0.5, voices=4, attack=0.9, release=1.2, cutoff=1100)
        T.chord(strings, [ch[2], ch[3]], bar, 0, 6, 0.3, 0.2, 0.35, voices=4, attack=1.2, release=1.4, cutoff=1500)
        if bar >= 8:
            T.parse(flute if (bar // 8) % 2 == 1 else celesta_like, melody[bar % 8], bar, 0, 0.5, 0.15, 0.85)
        if bar % 8 == 3:
            T.note(bell, 101, bar, 3, 3, 0.3, 0.4, 0.5)
    return T.render(0.42, 3.4, 3600.0, 0.78, 29)


def celesta_like(f, dur, vel=0.5):
    return musicbox(f, dur, vel)


# ------------------------------------------------------------------ SUMMIT: after Grieg's Morning Mood (E major, a flute at dawn)
def summit():
    T = Track(150, 40, 6, tail=4.5)             # an eighth per beat
    Eroot, Aroot, Broot, Croot = 40, 45, 47, 49
    # [bass, chord tones] per bar
    cyc = [("E", 40, [56, 59, 64]), ("A", 45, [57, 61, 64]), ("E", 40, [56, 59, 64]), ("B", 47, [54, 59, 63]),
           ("C#m", 49, [56, 61, 64]), ("A", 45, [57, 61, 64]), ("B", 47, [54, 59, 63]), ("E", 40, [56, 59, 64])]
    theme = ["B4/2 G#4/1 E4/2 G#4/1", "A4/2 F#4/1 E4/3", "B4/2 G#4/1 E4/2 G#4/1", "F#4/2 D#4/1 B3/3",
             "C#5/2 B4/1 G#4/2 B4/1", "A4/2 C#5/1 E5/3", "D#5/2 B4/1 F#4/2 B4/1", "G#4/6"]
    theme_up = ["G#5/2 E5/1 B4/2 E5/1", "F#5/2 D5/1 C#5/3", "G#5/2 E5/1 B4/2 E5/1", "B5/2 F#5/1 D#5/3",
                "E5/2 D#5/1 B4/2 D#5/1", "C#5/2 E5/1 A5/3", "F#5/2 D#5/1 B4/2 D#5/1", "E5/6"]
    for bar in range(40):
        name, root, ch = cyc[bar % 8]
        T.note(pluck_bass, root, bar, 0, 2.5, 0.6, -0.2, 0.9)
        T.note(pluck_bass, root + 7, bar, 3, 2.5, 0.45, -0.2, 0.7)
        T.chord(strings, ch, bar, 0, 6, 0.3, 0.0, 0.5, voices=4, attack=0.8, release=1.0, cutoff=1700)
        if bar >= 2:
            for k, m in enumerate([ch[0], ch[1], ch[2], ch[1]]):
                T.note(harp, m + 12, bar, k * 1.5, 1.5, 0.4, 0.3, 0.55)
        ph = bar % 8
        if bar >= 4 and (bar // 8) in (0, 1, 3):
            T.parse(flute, theme[ph], bar, 0, 0.55, 0.1, 1.0)
        elif (bar // 8) == 2:
            T.parse(flute, theme_up[ph], bar, 0, 0.58, 0.1, 1.0)
            T.parse(strings, theme[ph].replace("5", "4").replace("3", "3"), bar, 0, 0.3, -0.15, 0.4, voices=3, attack=0.3, release=0.4, cutoff=1500)
        elif (bar // 8) == 4:
            T.parse(flute, theme_up[ph], bar, 0, 0.6, 0.1, 1.0)
            T.parse(musicbox, theme_up[ph].replace("5", "6"), bar, 0, 0.3, 0.3, 0.5)
    return T.render(0.34, 2.8, 4400.0, 0.8, 31)


# ------------------------------------------------------------------ SKY: after Bach's Air (slow lines, a few stars)
def sky():
    T = Track(56, 24, 4, tail=6.0)
    prog = [("D", 38, [57, 62, 66]), ("Bm", 35, [59, 62, 66]), ("G", 43, [59, 62, 67]), ("A", 45, [57, 61, 64])]
    line = ["A5/3 F#5/1", "D5/2 F#5/2", "B5/3 A5/1", "G5/2 E5/2", "F#5/3 D5/1", "B4/2 D5/2", "G5/2 B5/2", "A5/4",
            "D6/3 B5/1", "A5/2 F#5/2", "G5/3 B5/1", "E5/2 C#5/2", "D5/3 F#5/1", "A5/2 G5/2", "F#5/2 E5/2", "D5/4"]
    for bar in range(24):
        name, root, ch = prog[bar % 4]
        T.note(bass, root + 12, bar, 0, 2, 0.5, -0.2, 0.6)
        T.note(bass, root + 12, bar, 2, 2, 0.4, -0.2, 0.5)
        T.chord(strings, [ch[0], ch[1], ch[2]], bar, 0, 4, 0.34, 0.0, 0.55, voices=5, attack=1.3, release=1.6, cutoff=1500)
        for k, m in enumerate([ch[0] + 12, ch[1] + 12, ch[2] + 12, ch[1] + 12]):
            T.note(harp, m, bar, k, 2.0, 0.35, -0.3 + 0.2 * k / 3.0, 0.5)
        if bar >= 4:
            T.parse(flute if bar % 8 < 4 else strings, line[(bar - 4) % 16], bar, 0, 0.5, 0.1, 0.8) if bar >= 4 and (bar - 4) < 16 else None
        if bar % 4 == 1:
            T.note(bell, 102 - (bar % 8), bar, 2, 2, 0.3, 0.45, 0.5)
    return T.render(0.45, 4.0, 3400.0, 0.78, 37)


# ------------------------------------------------------------------ STAR: after Rossini's William Tell finale (a gallop in G)
def star():
    T = Track(172, 48, 2, tail=3.0)
    fan = ["D5/0.5 D5/0.5 G5/1", "D5/0.5 D5/0.5 G5/1", "D5/0.5 D5/0.5 G5/0.5 B5/0.5", "D6/2",
           "E6/0.5 E6/0.5 C6/1", "E6/0.5 E6/0.5 C6/1", "D6/0.5 D6/0.5 B5/0.5 G5/0.5", "A5/1 D5/1"]
    chords = [(43, [55, 59, 62]), (43, [55, 59, 62]), (43, [55, 59, 62]), (50, [57, 62, 66]), (48, [55, 60, 64]), (48, [55, 60, 64]), (43, [55, 59, 62]), (50, [57, 62, 66])]
    for bar in range(48):
        root, ch = chords[bar % 8]
        # strings: the galloping ostinato (8th, 8th, quarter)
        for beat, d in [(0, 0.5), (0.5, 0.5), (1, 1.0)]:
            T.chord(strings, ch, bar, beat, d * 0.9, 0.55, 0.0, 0.5, voices=3, attack=0.01, release=0.05, cutoff=3000, detune=6.0)
        T.note(pluck_bass, root, bar, 0, 0.5, 0.9, -0.2, 1.0)
        T.note(pluck_bass, root + 7, bar, 1, 0.5, 0.8, -0.2, 0.9)
        T.hit(kick, bar, 0, 0.7, 0.0, 0.6, f0=110.0, f1=55.0)
        T.hit(snare, bar, 1, 0.55, 0.0, 0.5)
        T.hit(hat, bar, 0.5, 0.6, 0.3, 0.6)
        T.hit(hat, bar, 1.5, 0.6, 0.3, 0.6)
        if bar % 8 == 7:
            for k in range(8):
                T.hit(snare, bar, 1 + k * 0.125, 0.3 + 0.07 * k, 0.0, 0.5)
        ph = bar % 8
        if bar >= 2:
            T.parse(brass, fan[ph], bar, 0, 0.85, 0.0, 0.95)
        if bar >= 16 and bar < 32:
            T.parse(flute, fan[ph].replace("5", "6"), bar, 0, 0.6, 0.25, 0.5)
    return T.render(0.18, 1.4, 6500.0, 0.85, 41)


# ------------------------------------------------------------------ ENDING: a quiet piece in C (it finally comes home)
def ending():
    T = Track(64, 14, 4, tail=7.0)
    prog = [(48, [64, 67, 72]), (43, [62, 67, 71]), (45, [60, 64, 69]), (41, [60, 65, 69]), (48, [64, 67, 72]), (43, [62, 67, 71]), (45, [60, 64, 69]), (41, [60, 65, 69]),
            (43, [62, 67, 71]), (48, [64, 67, 72]), (48, [64, 67, 72, 76]), (48, [64, 67, 72, 76])]
    mel = ["E5/2 G5/2", "D5/2 B4/2", "C5/2 E5/2", "A4/1 C5/1 F5/2", "G5/2 E5/2", "D5/1 E5/1 G5/2", "E5/2 A5/2", "F5/2 C5/1 A4/1", "G5/2 B5/2", "C6/4"]
    for bar, (root, ch) in enumerate(prog):
        T.note(piano, root, bar, 0, 3.8, 0.5, -0.2, 1.0)
        for k, m in enumerate([ch[0] - 12, ch[1] - 12, ch[2] - 12, ch[1] - 12, ch[0], ch[1] - 12, ch[2] - 12, ch[1] - 12]):
            T.note(piano, m, bar, k * 0.5, 1.0, 0.32, 0.1, 0.55)
        T.chord(strings, [ch[0] - 12, ch[1] - 12, ch[2] - 12], bar, 0, 4, 0.34, 0.0, 0.55, voices=4, attack=1.0, release=1.4, cutoff=1500)
    for i, ph in enumerate(mel):
        T.parse(piano, ph, i + 2, 0, 0.62, 0.05, 1.15)
    # the tonic, at last: a bell and a full C major chord
    T.note(bell, 96, 11, 0, 8, 0.5, 0.2, 0.8)
    T.note(bell, 84, 11, 0, 8, 0.45, -0.2, 0.7)
    T.note(strings, 60, 11, 0, 6, 0.5, 0.0, 0.7, voices=5, attack=1.0, release=3.0, cutoff=1700)
    out = T.render(0.45, 4.2, 3600.0, 0.8, 43)
    return out


TRACKS = {"title": title, "boardwalk": boardwalk, "beach": beach, "hill": hill, "sea": sea, "summit": summit, "sky": sky, "star": star, "ending": ending}

# round 8: the title, the ending, STARLIGHT and the cinematic pieces are replaced (see music8.py)
from music8 import TRACKS8
TRACKS.update(TRACKS8)
