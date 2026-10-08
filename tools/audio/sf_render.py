"""Render a midi_util.Score with FluidSynth + the GeneralUser GS SoundFont (tools/audio/sf, see README there), then finish it the same way as every other piece
of this game: loudness -23 dBFS RMS, a seamless loop (the reverb tail is folded onto the start) or a clean ending, OGG.
"""
import os, subprocess, wave, random
import numpy as np
from scipy import signal
import synth

HERE = os.path.dirname(os.path.abspath(__file__))
FS = os.path.join(HERE, "sf", "fluidsynth-v2.6.1-win10-x64-cpp11", "bin", "fluidsynth.exe")
SF2 = os.path.join(HERE, "sf", "GeneralUser-GS.sf2")
OUT = os.path.join(HERE, "..", "..", "game", "assets", "audio", "music")
TMP = os.path.join(HERE, "sf", "tmp")
SR = 32000


def humanize(score, seed=1, timing=0.012, vel=5):
    """a little looseness: +-12 ms and +-5 velocity (the melody is kept tighter by its own `tight` flag)"""
    r = random.Random(seed)
    for t in score.tracks:
        tight = t.get("tight", False)
        out = []
        for (b, d, m, v) in t["notes"]:
            if not tight:
                b = max(0.0, b + r.uniform(-timing, timing) * score.bpm / 60.0)
                v = int(min(127, max(1, v + r.randint(-vel, vel))))
            out.append((b, d, m, v))
        t["notes"] = out


def render_wav(score, name, gain=0.9, reverb=(0.55, 0.35, 0.8, 0.55)):
    os.makedirs(TMP, exist_ok=True)
    mid = os.path.join(TMP, name + ".mid")
    wav = os.path.join(TMP, name + ".wav")
    score.write(mid)
    room, damp, width, level = reverb
    cmd = [FS, "-ni", "-g", str(gain), "-r", str(SR), "-R", "1", "-C", "1",
           "-o", "synth.reverb.room-size=%s" % room, "-o", "synth.reverb.damp=%s" % damp, "-o", "synth.reverb.width=%s" % width, "-o", "synth.reverb.level=%s" % level,
           "-o", "synth.chorus.level=1.2", "-o", "synth.polyphony=256",
           "-F", wav, SF2, mid]
    subprocess.run(cmd, check=True, cwd=os.path.dirname(FS), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    with wave.open(wav, "rb") as w:
        n = w.getnframes()
        sr = w.getframerate()
        data = np.frombuffer(w.readframes(n), dtype="<i2").astype(np.float64) / 32768.0
        ch = w.getnchannels()
    x = data.reshape(-1, ch)
    if ch == 1:
        x = np.repeat(x, 2, axis=1)
    return x, sr


def finish(x, loop_len_sec=None, fade_out=0.0):
    """loop_len_sec: fold everything after it onto the start (a seamless loop); fade_out: fade the end (a piece that plays once)"""
    if loop_len_sec is not None:
        L = int(loop_len_sec * SR)
        out = x[:L].copy()
        tail = x[L:]
        n = min(len(tail), L)
        out[:n] += tail[:n]
        x = out
    else:
        # trim the silence at the end
        env = np.max(np.abs(x), axis=1)
        idx = np.where(env > 0.002)[0]
        if len(idx):
            x = x[: idx[-1] + int(0.4 * SR)]
    for c in range(2):
        x[:, c] = synth.hp(x[:, c], 30, 1)
    x = synth.normalize_rms(x, -23.0, 0.93)
    if fade_out > 0.0:
        n = int(fade_out * SR)
        x[-n:] *= np.linspace(1.0, 0.0, n)[:, None] ** 1.5
    return x


def to_ogg(x, name, quality=5):
    synth.write_ogg(x, os.path.join(OUT, name + ".ogg"), quality=quality)
    print("%-10s %6.1f s  peak %.2f  rms %.1f dBFS" % (name, len(x) / SR, np.max(np.abs(x)), 20 * np.log10(np.sqrt(np.mean(x ** 2)) + 1e-9)), flush=True)
