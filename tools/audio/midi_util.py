"""A tiny MIDI reader / writer (no dependencies): enough to read a reference tune and to write the scores that FluidSynth renders."""
import struct

NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]


def name(m):
    return "%s%d" % (NAMES[m % 12], m // 12 - 1)


def _vlq(data, i):
    v = 0
    while True:
        b = data[i]
        i += 1
        v = (v << 7) | (b & 0x7F)
        if not b & 0x80:
            return v, i


def read(path):
    """-> (ticks_per_beat, tempo_us, [track: [(tick_on, tick_off, midi, vel, channel)]], time_sig)"""
    data = open(path, "rb").read()
    assert data[:4] == b"MThd"
    n_tracks = struct.unpack(">H", data[10:12])[0]
    tpb = struct.unpack(">H", data[12:14])[0]
    i = 14
    tempo = 500000
    sig = (4, 4)
    tracks = []
    for _ in range(n_tracks):
        assert data[i:i + 4] == b"MTrk"
        ln = struct.unpack(">I", data[i + 4:i + 8])[0]
        j = i + 8
        end = j + ln
        t = 0
        run = 0
        on = {}
        notes = []
        while j < end:
            d, j = _vlq(data, j)
            t += d
            b = data[j]
            if b == 0xFF:
                typ = data[j + 1]
                l, k = _vlq(data, j + 2)
                body = data[k:k + l]
                if typ == 0x51:
                    tempo = int.from_bytes(body, "big")
                elif typ == 0x58:
                    sig = (body[0], 2 ** body[1])
                j = k + l
                continue
            if b in (0xF0, 0xF7):
                l, k = _vlq(data, j + 1)
                j = k + l
                continue
            if b & 0x80:
                run = b
                j += 1
            st = run & 0xF0
            ch = run & 0x0F
            if st in (0xC0, 0xD0):
                j += 1
                continue
            a, c = data[j], data[j + 1]
            j += 2
            if st == 0x90 and c > 0:
                on[(ch, a)] = (t, c)
            elif st == 0x80 or (st == 0x90 and c == 0):
                if (ch, a) in on:
                    t0, v = on.pop((ch, a))
                    notes.append((t0, t, a, v, ch))
        tracks.append(sorted(notes))
        i = end
    return tpb, tempo, tracks, sig


class Score:
    """notes in BEATS (quarter notes). Several tracks, each with a GM program; tempo changes allowed."""

    def __init__(self, bpm, tpb=480, sig=(4, 4)):
        self.tpb = tpb
        self.bpm = bpm
        self.sig = sig
        self.tracks = []          # {"prog": n, "ch": c, "notes": [(beat, dur, midi, vel)], "cc": [(beat, cc, val)], "bank": b}
        self.tempos = [(0.0, bpm)]

    def track(self, prog, ch=None, vol=100, pan=64, reverb=40, chorus=0, bank=0):
        if ch is None:
            ch = len(self.tracks)
            if ch >= 9:
                ch += 1
        t = {"prog": prog, "ch": ch, "notes": [], "cc": [(0.0, 7, vol), (0.0, 10, pan), (0.0, 91, reverb), (0.0, 93, chorus)], "bank": bank}
        self.tracks.append(t)
        return t

    def add(self, t, beat, dur, m, vel=80):
        t["notes"].append((beat, dur, int(m), int(vel)))

    def tempo(self, beat, bpm):
        self.tempos.append((beat, bpm))

    def write(self, path):
        def vlq(v):
            out = [v & 0x7F]
            v >>= 7
            while v:
                out.append((v & 0x7F) | 0x80)
                v >>= 7
            return bytes(reversed(out))

        def trk(events):
            events.sort(key=lambda e: (e[0], e[1]))
            body = b""
            last = 0
            for t, _, data in events:
                body += vlq(t - last) + data
                last = t
            body += vlq(0) + b"\xff\x2f\x00"
            return b"MTrk" + struct.pack(">I", len(body)) + body

        T = lambda b: int(round(b * self.tpb))
        chunks = []
        ev = []
        for b, bpm in self.tempos:
            ev.append((T(b), 0, b"\xff\x51\x03" + int(60000000 / bpm).to_bytes(3, "big")))
        ev.append((0, 0, b"\xff\x58\x04" + bytes([self.sig[0], {2: 1, 4: 2, 8: 3}[self.sig[1]], 24, 8])))
        chunks.append(trk(ev))
        for t in self.tracks:
            ev = []
            ch = t["ch"]
            if t["bank"]:
                ev.append((0, 0, bytes([0xB0 | ch, 0, t["bank"]])))
            ev.append((0, 1, bytes([0xC0 | ch, t["prog"]])))
            for b, cc, val in t["cc"]:
                ev.append((T(b), 0, bytes([0xB0 | ch, cc, int(val)])))
            for b, d, m, v in t["notes"]:
                ev.append((T(b), 3, bytes([0x90 | ch, m, v])))
                ev.append((max(T(b + d) - 2, T(b) + 1), 2, bytes([0x80 | ch, m, 0])))
            chunks.append(trk(ev))
        hdr = b"MThd" + struct.pack(">IHHH", 6, 1, len(chunks), self.tpb)
        open(path, "wb").write(hdr + b"".join(chunks))
