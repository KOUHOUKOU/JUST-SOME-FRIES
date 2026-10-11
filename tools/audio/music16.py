"""Round 16: FISH TIME. The sea has its own piece while the gull surfs: "Row, Row, Row Your Boat" (a public-domain nursery round, 1852) played as a sea-shanty jig
by a tin whistle, a fiddle, an accordion and a banjo, entering one after the other the way a round does (every two bars), over a stomping bass, a strummed guitar and a
bodhran-and-tambourine drum pattern. The key climbs C -> D -> E (the voices all lift together), steps back down, and the turn-around lands on the first bar of the loop.

  python music16.py        ->  game/assets/audio/music/fish.ogg
"""
import numpy as np
from midi_util import Score
import sf_render as R

BPM = 176                       # quarter notes per minute: a 6/8 jig at ~117 dotted-quarter beats
BAR = 3.0                       # six eighths = three quarter-note beats
# the tune, in eighths of a 6/8 bar: (midi in C major, length in eighths). 8 bars.
TUNE = [
    [(60, 3), (60, 3)],
    [(60, 2), (62, 1), (64, 3)],
    [(64, 2), (62, 1), (64, 2), (65, 1)],
    [(67, 6)],
    [(72, 1), (72, 1), (72, 1), (67, 1), (67, 1), (67, 1)],
    [(64, 1), (64, 1), (64, 1), (60, 1), (60, 1), (60, 1)],
    [(67, 2), (65, 1), (64, 2), (62, 1)],
    [(60, 6)],
]
# the key of every bar of the piece (global bar -> semitones above C)
SECTIONS = [(2, 18, 0), (18, 26, 2), (26, 34, 4), (34, 42, 2), (42, 50, 0)]
TOTAL = 52


def key_of(bar):
    for a, b, k in SECTIONS:
        if a <= bar < b:
            return k
    return 0


def chord_for(idx, k):
    """one chord per bar of the tune (I, I, I, I, I, I, V, I)"""
    if idx == 6:
        return 43 + k, [55 + k, 59 + k, 62 + k, 67 + k]          # G, B, D
    return 36 + k, [52 + k, 55 + k, 60 + k, 64 + k]                  # C, E, G (the bass note is the low C)


def build():
    S = Score(BPM, sig=(6, 8))
    whistle = S.track(78, pan=70, vol=112, reverb=45)
    fiddle = S.track(110, pan=40, vol=104, reverb=45)
    accord = S.track(21, pan=88, vol=96, reverb=40)
    banjo = S.track(105, pan=56, vol=100, reverb=30)
    bass = S.track(32, pan=64, vol=110, reverb=20)
    gtr = S.track(25, pan=50, vol=96, reverb=30)
    drums = S.track(0, ch=9, vol=100, pan=64, reverb=25)
    for t in (whistle, fiddle, accord, banjo):
        t["tight"] = True
    # the voices of the round: (track, entry bar, octave shift, velocity)
    voices = [(whistle, 2, 12, 96), (fiddle, 4, 12, 82), (accord, 6, 0, 76), (banjo, 8, 12, 78)]
    for bar in range(TOTAL):
        b0 = bar * BAR
        k = key_of(bar)
        for t, entry, octv, vel in voices:
            if bar < entry or bar >= TOTAL - 2:
                continue
            idx = (bar - entry) % 8
            beat = b0
            for m, d in TUNE[idx]:
                dur = d * 0.5
                S.add(t, beat, dur * (0.97 if t is not banjo else 0.55), m + k + octv, vel + (6 if m >= 67 else 0))
                beat += dur
        # the rhythm section: bass on the two big pulses, strummed chords on the off-beats, a jig groove on the drums
        if bar < TOTAL - 2:
            idx0 = (bar - 2) % 8 if bar >= 2 else 0
            root, ch = chord_for(idx0, k)
            S.add(bass, b0, 1.2, root, 100)
            S.add(bass, b0 + 1.5, 1.2, root + (7 if idx0 != 6 else 5), 88)
            for off in (0.5, 1.0, 2.0, 2.5):
                for j, m in enumerate(ch):
                    S.add(gtr, b0 + off + j * 0.012, 0.4, m, 62 if off in (0.5, 2.0) else 54)
            S.add(drums, b0, 0.3, 36, 100)
            S.add(drums, b0 + 1.5, 0.3, 36, 84)
            S.add(drums, b0 + 1.5, 0.3, 38 if bar % 2 else 37, 70)
            for e in range(6):
                S.add(drums, b0 + e * 0.5, 0.2, 54, 56 if e % 3 == 0 else 38)
            if bar % 4 == 3:
                S.add(drums, b0 + 2.5, 0.2, 39, 80)
        else:
            # the turn-around: a pedal on G and a drum fill, landing on the loop's first bar
            S.add(bass, b0, 1.4, 43, 96)
            S.add(bass, b0 + 1.5, 1.4, 43, 90)
            for e in range(6):
                S.add(drums, b0 + e * 0.5, 0.2, 38, 50 + e * 8)
            S.add(drums, b0, 0.3, 36, 96)
            if bar == TOTAL - 1:
                for m in (55, 59, 62, 67):
                    S.add(gtr, b0 + 1.5, 1.4, m, 80)
    return S


if __name__ == "__main__":
    S = build()
    R.humanize(S, seed=16, timing=0.01, vel=4)
    x, sr = R.render_wav(S, "fish", gain=0.9, reverb=(0.4, 0.4, 0.8, 0.4))
    secs = TOTAL * BAR * 60.0 / BPM
    x = R.finish(x, loop_len_sec=secs)
    R.to_ogg(x, "fish", quality=5)
