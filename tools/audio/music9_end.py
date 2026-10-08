"""Round 9, the ending: two pieces.
  ending_mem  while the gull remembers (the polaroids): the question of "Morning Mood" in a quiet D-flat, a solo piano that is joined, one voice at a time, by
              the things the gull remembers. 16 bars of 6/8, loops until the big brother lands.
  ending      the Largo of Dvorak's "New World" Symphony (the melody notes are the real ones, read from a reference MIDI of the public-domain score), from the moment
              the big brother lands. The timeline is built around the scene: the climb reaches its high F when the little gull says its first words, and the last
              long D-flat (home) rings under "...same."
"""
from midi_util import Score
import midi_util as mu
import sf_render as R


def largo_melody():
    import json, os
    jp = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ref", "largo_melody.json")
    if os.path.exists(jp):
        return [tuple(n) for n in json.load(open(jp))["notes"]]
    tpb, tempo, tracks, sig = mu.read("ref/largo.mid")
    out = []
    for (a, b, m, v, ch) in tracks[1]:
        if 24 * tpb <= a < 84 * tpb:
            out.append((a / tpb - 24.0, (b - a) / tpb, m))
    return out


# the question of "Morning Mood" in D-flat: 5 3 2 1 2 3  (Ab F Eb Db Eb F)
Q1 = [(68, 1), (65, 1), (63, 1), (61, 1), (63, 1), (65, 1)]
Q2 = [(68, 1), (65, 1), (68, 1), (70, 1), (65, 1), (70, 1)]
Q3 = [(68, 1), (65, 1), (63, 4)]          # ...and it stops on the 2: still a question


def ending_mem():
    S = Score(60, sig=(6, 8))
    bar = 3.0
    pn = S.track(0, pan=58, vol=100, reverb=70)
    ha = S.track(46, pan=84, vol=88, reverb=80)
    pad = S.track(48, pan=64, vol=72, reverb=85)
    cel = S.track(8, pan=96, vol=112, reverb=95)
    fl = S.track(73, pan=76, vol=84, reverb=80)
    bs = S.track(42, pan=60, vol=60, reverb=40)
    cl = S.track(71, pan=48, vol=100, reverb=75)
    for t in (pn, fl, cl):
        t["tight"] = True
    ch = {"Db": [37, 49, 56, 61, 65, 68], "Gb": [42, 54, 58, 61, 66, 70], "Ab": [44, 56, 60, 63, 68, 72], "Bbm": [46, 53, 58, 61, 65, 70]}
    padv = {"Db": [53, 56, 61], "Gb": [54, 58, 61], "Ab": [56, 60, 63], "Bbm": [53, 58, 61]}
    prog = ["Db", "Db", "Gb", "Ab"] * 4
    for i, c in enumerate(prog):
        b = i * bar
        tn = ch[c]
        for j, ix in enumerate([0, 2, 3, 4, 3, 2]):
            S.add(pn, b + j * 0.5, 0.9, tn[ix], 40 - 3 * (j % 3))
        S.add(bs, b, 2.8, tn[0], 44)
        if i >= 4:
            for m in padv[c]:
                S.add(pad, b, bar * 0.99, m, 38 if i < 8 else 46)

    def phrase(t, start_bar, notes_by_bar, vel, shift=0):
        for k, notes in enumerate(notes_by_bar):
            b = (start_bar + k) * bar
            for m, d in notes:
                if m is not None:
                    S.add(t, b, d * 0.5 * 0.98, m + shift, vel)
                b += d * 0.5
    seqs = [Q1, Q1, Q2, Q3]
    phrase(pn, 0, seqs, 62)                     # bars 1-4: the piano alone
    phrase(pn, 4, seqs, 56)                     # bars 5-8: the piano, with a celesta an octave up
    phrase(cel, 4, seqs, 54, 12)
    phrase(fl, 8, seqs, 50)                     # bars 9-12: the flute takes it, the harp sparkles
    for i in range(8, 12):
        for j in range(5):
            S.add(ha, i * bar + j * 0.3, 1.8, ch[prog[i]][1 + j % 5] + 12, 36)
    phrase(cl, 12, seqs, 54, -12)               # bars 13-16: clarinet low, the piano an octave up, the strings full
    phrase(pn, 12, seqs, 50, 12)
    for i, v in enumerate([40, 50, 70, 80, 90, 100, 110, 110]):
        pad["cc"].append(((8 + i) * bar * 0.5, 11, v))
    R.humanize(S, 5)
    return S, 16 * bar


def render_ending_mem():
    S, total = ending_mem()
    x, sr = R.render_wav(S, "ending_mem", gain=0.85, reverb=(0.7, 0.35, 0.9, 0.6))
    x = R.finish(x, loop_len_sec=total)
    R.to_ogg(x, "ending_mem")


def ending():
    S = Score(62, sig=(4, 4))
    CHD = {
        "Db": (37, [53, 56, 61], [49, 56, 61, 65, 68]), "Ab": (44, [56, 60, 63], [56, 63, 68, 72, 75]), "Bbm": (46, [53, 58, 61], [46, 53, 58, 61, 65]),
        "Gb": (42, [54, 58, 61], [54, 61, 66, 70, 73]), "Eb": (39, [55, 58, 63], [51, 58, 63, 67, 70]),
    }
    gl = S.track(46, pan=82, vol=74, reverb=75)         # harp
    bs = S.track(42, pan=60, vol=64, reverb=40)         # cello
    pad = S.track(48, pan=64, vol=70, reverb=85)        # strings
    ac = S.track(69, pan=70, vol=127, reverb=75)        # English horn
    cl = S.track(71, pan=52, vol=127, reverb=70)
    ob = S.track(68, pan=86, vol=124, reverb=70)
    fl = S.track(73, pan=76, vol=84, reverb=75)
    vn = S.track(40, pan=74, vol=96, reverb=85)         # solo violin for the climb
    hn = S.track(60, pan=56, vol=90, reverb=75)
    cel = S.track(8, pan=98, vol=118, reverb=95)
    for t in (ac, cl, ob, fl, vn):
        t["tight"] = True
    mel = largo_melody()

    def melody(t, a, b, at, shift=0, vel=70):
        for (s, d, m) in mel:
            if a <= s < b:
                S.add(t, s - a + at, d * 0.97, m + shift, vel)

    def comp(start, chords_per_bar, vel=48, harp=True, pv=46):
        for i, c in enumerate(chords_per_bar):
            bb = start + i * 4
            halves = c if isinstance(c, tuple) else (c, c)
            d0, d1 = CHD[halves[0]], CHD[halves[1]]
            same = halves[0] == halves[1]
            for m in d0[1]:
                S.add(pad, bb, 3.97 if same else 1.97, m, pv)
            S.add(bs, bb, 3.9 if same else 1.9, d0[0], 52)
            if not same:
                for m in d1[1]:
                    S.add(pad, bb + 2, 1.97, m, pv)
                S.add(bs, bb + 2, 1.9, d1[0], 50)
            if harp:
                for h in (0, 1):
                    dd = (d0, d1)[h]
                    for j in range(4):
                        S.add(gl, bb + h * 2 + j * 0.5, 1.2, dd[2][j] + (12 if j >= 2 else 0), vel - 2 * j)

    def swell(t, beat, vals, step=2.0):
        for i, v in enumerate(vals):
            t["cc"].append((beat + i * step, 11, v))
    # chorale (strings only): Db  Ab, a held breath before the horn
    for i, c in enumerate(["Db", "Ab"]):
        for m in CHD[c][1]:
            S.add(pad, i * 2, 1.98, m, 34 + 6 * i)
        S.add(bs, i * 2, 1.9, CHD[c][0], 40)
    TA, TA2, TB, TC, TCODA = 4, 12, 20, 28, 48
    comp(TA, ["Db", ("Db", "Ab"), "Ab", ("Ab", "Ab")], 42, True, 38)
    melody(ac, 0, 8, TA, 0, 74)
    comp(TA2, ["Db", ("Db", "Ab"), "Ab", ("Ab", "Db")], 46, True, 44)
    melody(cl, 8, 16, TA2, 0, 72)
    melody(ac, 8, 16, TA2, -12, 54)
    comp(TB, ["Bbm", "Gb", "Bbm", ("Gb", "Ab")], 50, True, 52)
    melody(ob, 16, 24, TB, 0, 72)
    melody(vn, 16, 24, TB, 12, 40)
    swell(pad, TB, [70, 90, 105, 115], 2.0)
    comp(TC, ["Db", "Gb", ("Ab", "Ab"), ("Ab", "Db")], 54, True, 66)
    comp(TC + 8, [("Db", "Gb"), ("Ab", "Ab"), ("Db", "Db"), "Db"], 54, True, 70)
    comp(TC + 16, ["Db"], 52, True, 64)
    melody(vn, 40, 60, TC, 0, 86)
    melody(fl, 40, 60, TC, 12, 60)
    melody(hn, 40, 60, TC, -12, 64)
    melody(ac, 40, 60, TC, -12, 50)
    swell(pad, TC, [115, 122, 127, 127, 124, 127, 127, 127, 127, 120], 2.0)
    # coda: the chord rings; the question of "Morning Mood" is asked once more in the celesta - and this time it is answered: it ends on the 1
    for m in CHD["Db"][1]:
        S.add(pad, TCODA, 14.0, m, 58)
    S.add(bs, TCODA, 12.0, 37, 52)
    S.add(bs, TCODA + 0.01, 12.0, 49, 38)
    swell(pad, TCODA, [110, 100, 90, 80, 70, 60, 50], 2.0)
    ans = [80, 77, 75, 73, 75, 77, 73]
    b = TCODA + 1.0
    for k2, m in enumerate(ans):
        S.add(cel, b, 2.4 if k2 == len(ans) - 1 else 1.4, m, 52)
        b += 1.0
    S.add(cel, b, 7.0, 85, 34)
    for j, m in enumerate([61, 68, 73, 77, 80]):
        S.add(gl, TCODA + 9.0 + j * 0.2, 4.0, m, 38)
    S.tempo(TC + 12, 58)
    S.tempo(TCODA, 54)
    S.tempo(TCODA + 8, 48)
    R.humanize(S, 11)
    return S, 62


def render_ending():
    S, total = ending()
    x, sr = R.render_wav(S, "ending", gain=0.85, reverb=(0.7, 0.35, 0.9, 0.65))
    x = R.finish(x, loop_len_sec=None, fade_out=2.5)
    R.to_ogg(x, "ending")
