"""Round 10: the music, played by real orchestras.
Every piece below is a public-domain work in a public-domain recording (the Musopen project, via Wikimedia Commons; the recordings were released to the public domain,
see CREDITS in game/scripts/ui/title_cards.gd and docs/31_ROUND10_CHANGES.md). The raw files live in tools/audio/src/<name>/src.* (large, not in git; the downloader is
described in docs/31). This script cuts the passages we want, gently levels them (the loudest bars are not allowed to be 25 dB above the quietest ones), makes the
loops seamless (an equal-power cross-fade of the end onto the start) and writes the OGGs the game plays.

  python real_music.py [name ...]        (no name = everything)
"""
import os, subprocess, sys
import numpy as np
from scipy import signal
import synth

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "src")
OUT = os.path.join(HERE, "..", "..", "game", "assets", "audio", "music")
SR = 32000


def cut(name, start, end, ext="flac"):
    path = os.path.join(SRC, name, "src." + ext)
    cmd = ["ffmpeg", "-v", "error", "-ss", str(start), "-t", str(end - start), "-i", path, "-ac", "2", "-ar", str(SR), "-f", "f32le", "-"]
    p = subprocess.run(cmd, capture_output=True, check=True)
    return np.frombuffer(p.stdout, dtype="<f4").reshape(-1, 2).astype(np.float64)


def level(x, strength=0.55, target_db=-24.0, max_db=9.0, win=2.5):
    """a slow leveller: a passage that is 20 dB louder than another becomes ~9 dB louder, never more than max_db of change"""
    mono = np.mean(x, axis=1)
    hop = int(0.25 * SR)
    w = int(win * SR)
    env = []
    for i in range(0, len(mono), hop):
        seg = mono[max(0, i - w // 2): i + w // 2]
        env.append(20 * np.log10(np.sqrt(np.mean(seg ** 2)) + 1e-6))
    env = np.array(env)
    g = np.clip(-(env - target_db) * strength, -max_db, max_db)
    g = signal.savgol_filter(g, 15, 2) if len(g) > 20 else g
    t_env = np.arange(len(env)) * hop
    gain = 10 ** (np.interp(np.arange(len(mono)), t_env, g) / 20.0)
    return x * gain[:, None]


def fade(x, fin=0.0, fout=0.0):
    x = x.copy()
    if fin > 0:
        n = int(fin * SR)
        x[:n] *= (np.linspace(0, 1, n) ** 1.5)[:, None]
    if fout > 0:
        n = int(fout * SR)
        x[-n:] *= (np.linspace(1, 0, n) ** 1.5)[:, None]
    return x


def loop(x, xf=5.0):
    """seamless: the last `xf` seconds are blended (equal power) into the first `xf` seconds, and removed from the end"""
    n = int(xf * SR)
    head = x[:n]
    tail = x[-n:]
    t = np.linspace(0, np.pi / 2, n)[:, None]
    blend = head * np.sin(t) + tail * np.cos(t)
    return np.concatenate([blend, x[n:-n]], axis=0)


def finish(x, target=-23.0):
    for c in range(2):
        x[:, c] = synth.hp(x[:, c], 28, 1)
    x = synth.normalize_rms(x, target, 0.93)
    return x


def write(x, name, quality=5):
    synth.write_ogg(x, os.path.join(OUT, name + ".ogg"), quality=quality, sr=SR)
    print("%-11s %6.1f s  peak %.2f  rms %.1f dBFS" % (name, len(x) / SR, np.max(np.abs(x)), 20 * np.log10(np.sqrt(np.mean(x ** 2)) + 1e-9)), flush=True)


# ------------------------------------------------------------------ the pieces
PIECES = {}


def piece(f):
    PIECES[f.__name__] = f
    return f


@piece
def title():
    """Grieg, Morning Mood (Peer Gynt suite no. 1): the whole piece, 3 min 49, as one loop"""
    x = cut("morning", 0, 229.0, "flac")
    x = level(x, 0.45)
    x = loop(x, 6.0)
    write(finish(x), "title")


@piece
def ending_mem():
    """Chopin, Nocturne in E-flat Op. 9 no. 2 (Frank Levy): the first 52 seconds, quietly, while the memories drift by"""
    x = cut("nocturne", 0, 52.0, "flac")
    x = level(x, 0.5)
    x = loop(x, 4.0)
    write(finish(x, -25.0), "ending_mem")


@piece
def ending():
    """Dvorak, Largo from the 'New World' symphony: the build (from 7 min 43) to its great climax (8 min 10, about 25 s in), then the theme comes home again, quietly"""
    start = float(os.environ.get("LARGO_START", 463.0))
    x = cut("largo", start, start + 150.0, "ogg")
    x = level(x, 0.55, max_db=11.0)
    x = fade(x, 0.8, 9.0)
    write(finish(x), "ending")


@piece
def cine_joy():
    """Mendelssohn, 'Italian' symphony, first movement: the opening bars (STARLIGHT: going very fast)"""
    x = cut("italian", 0.0, 13.0, "flac")
    x = fade(level(x, 0.3), 0.15, 1.6)
    write(finish(x), "cine_joy")


@piece
def cine_wish():
    """Debussy, Clair de lune (Laurens Goedhart): the opening (a falling star; a rainbow)"""
    x = cut("clair", 2.0, 17.0, "ogg")
    x = fade(level(x, 0.4), 0.6, 2.2)
    write(finish(x), "cine_wish")


@piece
def cine_sun():
    """Grieg, Morning Mood: the sunrise swell and the full orchestra (the sun)"""
    x = cut("morning", 45.2, 58.5, "flac")
    x = fade(level(x, 0.3), 0.25, 2.2)
    write(finish(x), "cine_sun")


@piece
def cine_home():
    """Brahms, symphony no. 3, third movement: the cellos' wistful theme (every kind of magic, and still hungry)"""
    x = cut("brahms3", 0.0, 14.0, "flac")
    x = fade(level(x, 0.4), 0.5, 2.2)
    write(finish(x), "cine_home")


@piece
def star():
    """Mendelssohn, 'Italian' symphony, first movement, the sunny second theme and development: STARLIGHT, 30 seconds of everything going right (a loop)"""
    x = cut("italian", 33.0, 75.0, "flac")
    x = level(x, 0.5)
    x = loop(x, 4.0)
    write(finish(x), "star")


@piece
def boardwalk():
    """Mendelssohn, 'Italian' symphony, third movement: a gentle stroll (the boardwalk)"""
    x = cut("italian3", 0.0, 150.0, "flac")
    x = level(x, 0.5)
    x = loop(x, 6.0)
    write(finish(x), "boardwalk")


@piece
def beach():
    """Satie, Gymnopedie no. 1 (guitar, Michael Laucke): a lazy afternoon (the beach)"""
    x = cut("satie", 0.0, 171.0, "flac")
    x = level(x, 0.4)
    x = loop(x, 6.0)
    write(finish(x, -24.0), "beach")


@piece
def sea():
    """Smetana, Vltava: the river, the sea (the part where the whole river flows)"""
    x = cut("vltava", 56.0, 206.0, "flac")
    x = level(x, 0.55)
    x = loop(x, 6.0)
    write(finish(x), "sea")


@piece
def hill():
    """Brahms, symphony no. 3, third movement: warm and a little wistful (the hill behind the town)"""
    x = cut("brahms3", 0.0, 135.0, "flac")
    x = level(x, 0.5)
    x = loop(x, 6.0)
    write(finish(x), "hill")


@piece
def summit():
    """Mendelssohn, 'Scottish' symphony, third movement (Adagio): wide and noble (the summit)"""
    x = cut("scottish3", 125.0, 265.0, "flac")
    x = level(x, 0.55)
    x = loop(x, 6.0)
    write(finish(x), "summit")


@piece
def sky():
    """Borodin, In the Steppes of Central Asia: a huge calm (the sky)"""
    x = cut("borodin", 228.0, 332.0, "flac")
    x = level(x, 0.5)
    x = loop(x, 6.0)
    write(finish(x), "sky")


if __name__ == "__main__":
    names = sys.argv[1:] or list(PIECES)
    for n in names:
        PIECES[n]()
