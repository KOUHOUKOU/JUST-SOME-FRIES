"""Round 9: the music people hear first and last. Two adaptations of public-domain classics, played by real sampled instruments
(FluidSynth + GeneralUser GS, see sf_render.py), arranged warm and a little bit cheeky for a small seagull with a big appetite:

  title   "Morning at the Pier"  - Grieg, "Morning Mood" (Peer Gynt Suite no.1, 1875). G major, 6/8. Flute, nylon guitar, harp, clarinet, strings, horn, celesta.
                                   The tune asks its question (the five-note pentatonic rise) and the last bar stays on the dominant: it never answers.
  ending  "Home"                 - Dvorak, Largo from the Symphony no.9 "From the New World" (1893; "Goin' Home"). D-flat major, 4/4. English horn, clarinet,
                                   strings, harp. The melody notes are the real ones (read from a reference MIDI of the public-domain score, tools/audio/ref);
                                   the opening question of "Morning Mood" returns in the middle, quietly, and this time the last chord is home.
"""
import numpy as np
from midi_util import Score
import sf_render as R

# ---------------------------------------------------------------- helpers
CH = {  # chord tones: [bass, 5th, octave, 3rd, high]
    "G": [43, 50, 55, 59, 62], "Em": [40, 47, 52, 55, 59], "C": [48, 55, 60, 64, 67], "D": [50, 57, 62, 66, 69], "Bm": [47, 54, 59, 62, 66],
    "Am": [45, 52, 57, 60, 64], "G/B": [47, 50, 55, 59, 62], "D/F#": [42, 50, 57, 62, 66],
    "Bb": [46, 53, 58, 62, 65], "Gm": [43, 50, 55, 58, 62], "Eb": [51, 58, 63, 67, 70], "F": [53, 60, 65, 69, 72],
}
PAD = {  # a three-note voicing for the strings
    "G": [55, 62, 67], "Em": [55, 59, 64], "C": [55, 60, 64], "D": [57, 62, 66], "Bm": [54, 59, 62], "Am": [57, 60, 64], "G/B": [55, 59, 62], "D/F#": [57, 62, 66],
    "Bb": [58, 62, 65], "Gm": [58, 62, 67], "Eb": [58, 63, 67], "F": [57, 60, 65],
}
THIRD_BELOW = {74: 71, 71: 67, 69: 66, 67: 64, 76: 72, 72: 69, 77: 74, 70: 67, 79: 76}


def seq(S, t, start, notes, vel=70, gain=0):
    """notes: [(midi, beats)], midi None = rest. Returns the beat after the phrase."""
    b = start
    for m, d in notes:
        if m is not None:
            S.add(t, b, d * 0.98, m + gain, vel)
        b += d
    return b


def eighths(lst):
    return [(m, d * 0.5) for m, d in lst]


def swell(t, beat, vals, step=1.5):
    for i, v in enumerate(vals):
        t["cc"].append((beat + i * step, 11, v))


def title():
    S = Score(80, sig=(6, 8))
    bar = 3.0                                   # 6 eighths of 0.5 beat
    gtr = S.track(24, pan=46, vol=116, reverb=55)
    harp = S.track(46, pan=84, vol=104, reverb=75)
    bass = S.track(32, pan=64, vol=100, reverb=25)
    pad = S.track(48, pan=64, vol=88, reverb=80)
    fl = S.track(73, pan=78, vol=90, reverb=70)
    cl = S.track(71, pan=44, vol=120, reverb=62)
    ob = S.track(68, pan=88, vol=112, reverb=62)
    hn = S.track(60, pan=56, vol=100, reverb=70)
    vn = S.track(40, pan=70, vol=104, reverb=75)
    cel = S.track(8, pan=96, vol=110, reverb=95)
    for t in (fl, vn):
        t["tight"] = True
    P1 = eighths([(74, 1), (71, 1), (69, 1), (67, 1), (69, 1), (71, 1)])
    P2a = eighths([(74, 1), (71, 1), (74, 1), (76, 1), (71, 1), (76, 1)])
    P2b = eighths([(74, 1), (71, 1), (69, 1), (67, 3)])
    THEME = [P1, P1, P2a, P2b]

    def shift(phrase, k):
        return [(None if m is None else m + k, d) for m, d in phrase]

    def thirds(phrase):
        return [(THIRD_BELOW.get(m, m - 3) if m is not None else None, d) for m, d in phrase]

    # ---------------- the plan: (name, chords per bar)
    A = ["G", "Em", "C", ("D", "G")]
    plan = [("intro", ["G", "G"]), ("A", A), ("A2", A), ("B", ["Bb", "Gm", "Eb", ("F", "Bb")]), ("A3", A), ("inter", ["G", "D/F#", "Em", "C"]), ("A4", ["G", "Em", "C", "D"]), ("coda", ["D", "D"])]
    b0 = 0.0
    bars = []
    for name, chords in plan:
        for i, ch in enumerate(chords):
            bars.append((name, i, ch, b0))
            b0 += bar
    total = b0
    # ---------------- the accompaniment, bar by bar
    for k, (name, i, ch, b) in enumerate(bars):
        halves = ch if isinstance(ch, tuple) else (ch, ch)
        sec = name
        for h in (0, 1):
            c = CH[halves[h]]
            base = b + h * 1.5
            soft = 0.7 if sec in ("intro", "inter", "coda") else 1.0
            for j, idx in enumerate([0, 1, 2, 3, 2, 1]):
                if j in (0, 1, 2) :
                    pass
            # nylon guitar: the classic 6/8 arpeggio, each half bar three eighths
            pat = [0, 1, 2] if h == 0 else [3, 2, 1]
            for j, ix in enumerate(pat):
                S.add(gtr, base + j * 0.5, 0.9, c[ix], int((50 - 4 * j) * soft + (6 if sec in ("A3",) else 0)))
        c0 = CH[halves[0]]
        c1 = CH[halves[1]]
        if sec not in ("intro",) or i == 1:
            S.add(bass, b, 1.4, c0[0], 56 if sec != "coda" else 40)
            S.add(bass, b + 1.5, 1.4, c1[1] - 12 + 12 if False else c1[0] + 7, 46 if sec != "coda" else 34)
        # strings: long chords, swelling with the phrase
        if sec in ("A2", "B", "A3", "A4", "coda") or (sec == "intro" and i == 1):
            for m in PAD[halves[0]]:
                S.add(pad, b, bar * 0.99, m, 44 if sec in ("A2", "intro") else 54 if sec == "B" else 60 if sec in ("A3", "A4") else 36)
        # a harp stroke on the downbeat of the fuller sections
        if sec in ("A3", "B", "A4") or (sec in ("A2",) and i % 2 == 0):
            for j, ix in enumerate([0, 1, 2, 3, 4]):
                S.add(harp, b + j * 0.17, 1.6, CH[halves[0]][ix] + 12, 46)
    # ---------------- the melody
    def bar_start(name, i=0):
        for (n, ii, ch, b) in bars:
            if n == name and ii == i:
                return b
    # A: the flute asks the question
    b = bar_start("A")
    for ph in THEME:
        b = seq(S, fl, b, ph, 70)
    # A2: the clarinet, low and warm, with the flute floating above it
    b = bar_start("A2")
    for ph in THEME:
        b = seq(S, cl, b, shift(ph, -12), 62)
    b = bar_start("A2")
    for ph in THEME:
        b = seq(S, fl, b, [(m, d) for m, d in ph], 40)
    # B: the same tune a minor third higher (Bb major): violins and horn - the sun comes up
    b = bar_start("B")
    for ph in THEME:
        b = seq(S, vn, b, shift(ph, 3), 72)
    b = bar_start("B")
    for ph in THEME:
        b = seq(S, hn, b, shift(ph, -9), 62)
    swell(pad, bar_start("B"), [60, 74, 90, 100, 110, 100, 90, 80], 1.5)
    # A3: home again, bigger: flute + oboe a third below + celesta sparkles + harp
    b = bar_start("A3")
    for ph in THEME:
        b = seq(S, fl, b, ph, 78)
    b = bar_start("A3")
    for ph in THEME:
        b = seq(S, ob, b, thirds(ph), 56)
    b = bar_start("A3")
    for ph in THEME:
        b = seq(S, cel, b, shift(ph, 12), 44)
    swell(pad, bar_start("A3"), [100, 110, 120, 120, 110, 100, 100, 90], 1.5)
    # interlude: the guitar alone (and a few glockenspiel stars)
    b = bar_start("inter")
    for j, m in enumerate([86, 83, 79, 81, 83, 79, 86, 90]):
        S.add(cel, b + j * 1.5 + 0.5, 1.2, m, 40)
    # A4: the flute again, and the last two bars lose their nerve: the tune stops on A, over D
    b = bar_start("A4")
    b = seq(S, fl, b, P1, 66)
    b = seq(S, fl, b, P1, 58)
    b = seq(S, fl, b, P2a, 62)
    seq(S, fl, b, eighths([(74, 1), (71, 1), (69, 4)]), 58)
    seq(S, cl, bar_start("A4"), shift(P1, -12) + shift(P1, -12) + shift(P2a, -12) + eighths([(62, 1), (59, 1), (57, 4)]), 44)
    # coda: D, a few high stars, nothing resolved
    b = bar_start("coda")
    for j, m in enumerate([90, 93, 86, 81]):
        S.add(cel, b + j * 1.5, 2.0, m, 38 - 4 * j)
    S.add(fl, b + 0.0, 5.5, 81, 38)
    swell(pad, b, [90, 70, 50, 30], 1.5)
    # a breath of rubato at the end of every phrase
    for name, i, ch, bb in bars:
        if i == 3:
            S.tempo(bb + 1.5, 76)
            S.tempo(bb + bar, 80)
    R.humanize(S, 7)
    return S, total


def render_title():
    S, total = title()
    x, sr = R.render_wav(S, "title", gain=0.85)
    secs = total * 60.0 / 80.0
    x = R.finish(x, loop_len_sec=secs)
    R.to_ogg(x, "title")


if __name__ == "__main__":
    import sys
    which = sys.argv[1:] or ["title", "ending_mem", "ending"]
    if "title" in which:
        render_title()
    if "ending_mem" in which or "ending" in which:
        import music9_end as E
        if "ending_mem" in which:
            E.render_ending_mem()
        if "ending" in which:
            E.render_ending()
