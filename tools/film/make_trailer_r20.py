"""The round-20 trailer (2 minutes): the story, the flight, RAINBOW TIME, a fish, a rainbow, a falling star, and the roof.

    python tools/film/make_trailer_r20.py            (needs edge_tts: run WITHOUT -I)

Reads the recordings film/seg*.avi (tools/film/record_all.py --only=1,30,31,22,11,12,40,41, and film/seg_end.avi = `--r20ending --nomusic`), writes film/trailer_r20.mp4 (+ .srt).
Every shot is (name, source, in, duration, speed, options). The sections that sit on the Mendelssohn drive are cut in whole pulses of its beat (0.824 s) from the drop; the
score (tools/film/score_r20.py) is built from the anchors this script writes (film/anchors_r20.json): the swell of Morning Mood lands on the steal, the drop of the Italian symphony
on the "RAINBOW TIME" lettering, the climax of the Largo on "...same.".
"""
import asyncio, hashlib, json, os, subprocess, sys
import edge_tts

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
FILM = os.path.join(ROOT, "film")
os.chdir(FILM)
VOICE = "en-US-AndrewNeural"
RATE = "-8%"
PITCH = "-3Hz"
W, H, FPS = 1280, 720, 30
PULSE = 0.824                      # the beat of the Italian symphony's drive (tools/film/fit_grid.py)
FONT_IMPACT = "C\\:/Windows/Fonts/impact.ttf"
FONT_SERIF = "C\\:/Windows/Fonts/georgiab.ttf"
FONT_SANS = "C\\:/Windows/Fonts/arialbd.ttf"


def p(n):
    return n * PULSE


# (name, src, in, duration, speed, options)   options: fi (fade in from black), fo (fade out), flash, zoom, mute, sfx (dB)
SHOTS = [
    # ---------------------------------------------------------------- A  the story: one fry, a hungry gull
    ("tk",        "seg1.avi",   13.55, 2.2, 1.0, {"fi": 0.5}),
    ("magic",     "seg1.avi",    4.0,  2.0, 1.0, {}),
    ("wind",      "seg1.avi",    6.1,  1.9, 1.0, {}),
    ("breath",    "seg1.avi",    8.3,  1.5, 1.0, {}),
    ("pier",      "seg1.avi",   16.1,  1.7, 1.0, {}),
    ("hungry",    "seg1.avi",   18.1,  2.5, 1.0, {"zoom": 0.05}),
    ("comic",     "seg1.avi",   22.3,  1.7, 4.0, {"mute": True}),
    ("bubble",    "seg1.avi",   31.9,  1.5, 1.0, {}),
    # ---------------------------------------------------------------- B  the first fry, Gull Sight, three drinks
    ("sniff",     "seg1.avi",   36.7,  1.9, 1.0, {}),
    ("takeoff",   "seg30.avi",   2.4,  2.4, 1.0, {}),
    ("swing",     "seg30.avi",   4.8,  2.0, 1.0, {}),
    ("dive",      "seg30.avi",   6.4,  2.0, 1.0, {}),
    ("beak",      "seg30.avi",  18.95, 1.5, 1.0, {"flash": 0.22, "zoom": 0.05}),          # <- the swell of Morning Mood
    ("second",    "seg30.avi",  11.8,  1.5, 1.0, {}),
    ("sight",     "seg31.avi",   2.9,  2.1, 1.0, {}),
    ("takeoff2",  "seg31.avi",   5.0,  1.4, 1.0, {}),
    ("icecream",  "seg31.avi",  12.0,  1.8, 1.0, {}),
    ("cocktail",  "seg31.avi",  27.0,  1.9, 1.0, {}),
    ("allthree",  "seg31.avi",  29.9,  3.6, 1.0, {}),
    # ---------------------------------------------------------------- C  RAINBOW TIME (on the beat from here)
    ("slam",      "seg31.avi",  33.5,  p(3), 1.0, {"flash": 0.3}),                       # <- the drop
    ("wheee",     "seg31.avi",  38.0,  p(2), 1.0, {}),
    ("soar1",     "seg22.avi",   1.1,  p(3), 1.0, {}),
    ("soar2",     "seg22.avi",   4.0,  p(3), 1.0, {}),
    ("soar3",     "seg22.avi",   8.2,  p(3), 1.0, {}),
    ("soar4",     "seg22.avi",  12.0,  p(2), 1.0, {}),
    ("soar5",     "seg22.avi",  19.0,  p(3), 1.0, {}),
    ("soar6",     "seg22.avi",  21.8,  p(2), 1.0, {}),
    # ---------------------------------------------------------------- D  a fish, a rainbow, a falling star, the moon
    ("fish1",     "seg11.avi",   9.3,  p(3), 1.0, {}),
    ("fish2",     "seg11.avi",  13.0,  p(2), 1.0, {}),
    ("fish3",     "seg11.avi",  22.3,  p(2), 1.0, {}),
    ("bow1",      "seg40.avi",   1.0,  p(3), 1.0, {"zoom": 0.04}),
    ("bow2",      "seg40.avi",   5.0,  p(2), 1.6, {}),
    ("bow3",      "seg40.avi",  11.0,  p(2), 1.0, {"flash": 0.2}),
    ("star1",     "seg41.avi",  10.5,  p(2), 1.5, {}),
    ("star2",     "seg41.avi",  14.8,  p(2), 1.0, {"flash": 0.2}),
    ("star3",     "seg41.avi",  18.3,  p(2), 1.0, {}),
    ("moon",      "seg12.avi",  12.0,  p(2), 1.0, {"fo": 0.4}),
    # ---------------------------------------------------------------- E  the roof
    ("bite",      "seg_end.avi",   4.5, 2.2, 1.8, {"fi": 0.3}),
    ("memories",  "seg_end.avi",  17.0, 3.0, 3.0, {"mute": True}),
    ("arrive",    "seg_end.avi",  66.0, 1.6, 1.0, {}),
    ("hats",      "seg_end.avi",  70.6, 2.0, 1.0, {}),
    ("whatsthat", "seg_end.avi",  85.4, 1.6, 1.0, {}),
    ("justafry",  "seg_end.avi",  90.2, 1.8, 1.0, {}),
    ("doesnt",    "seg_end.avi", 108.4, 1.8, 1.0, {}),
    ("somefries", "seg_end.avi", 114.0, 1.4, 1.0, {}),
    ("falls",     "seg_end.avi", 117.4, 2.0, 1.0, {}),
    ("same",      "seg_end.avi", 121.8, 3.4, 1.0, {}),                                   # <- the climax of the Largo
    ("shades",    "seg_end.avi", 142.6, 2.2, 1.0, {}),
    ("colour",    "seg_end.avi", 147.0, 2.4, 1.0, {}),
    ("warm",      "seg_end.avi", 162.6, 2.4, 1.0, {}),
    ("salt",      "seg_end.avi", 169.0, 3.0, 2.0, {}),
    ("sea",       "seg_end.avi", 196.4, 3.4, 1.0, {}),
    ("good",      "seg_end.avi", 238.0, 2.4, 1.0, {}),
    ("comicend",  "seg_end.avi", 283.2, 2.4, 1.0, {}),
    ("enough",    "seg_end.avi", 296.6, 2.2, 1.0, {}),
    ("cover",     "seg_end.avi", 304.0, 5.0, 1.0, {"fo": 1.2}),
    ("black",     "BLACK",         0.0, 1.0, 1.0, {}),
]

# voice: (shot, offset, text)
VOICE_LINES = [
    ("tk",        0.9, "One fry. On the floor. And nobody noticed."),
    ("hungry",    0.0, "...except one very hungry seagull."),
    ("takeoff",   0.3, "Dive. Lock on. And when the world slows down... find the rhythm."),
    ("sight",     0.0, "Hold Tab. Everything that glows is a fry."),
    ("icecream",  0.45, "Coffee. A cocktail. Ice cream."),
    ("allthree",  ("end", "DROP", 0.3), "All three at once... and the wind turns to colour."),
    ("fish1",     0.2, "Catch a fish."),
    ("bow1",      0.5, "Catch a rainbow."),
    ("star1",     0.2, "Catch a falling star."),
    ("cover",     0.9, "Just some fries."),
]

# text slams over the picture: (shot, offset, seconds, text, size, x, y, font)
TEXTS = [
    ("takeoff",  0.15, 1.1, "FLY.",   150, "100",       "(h-text_h)-90", FONT_IMPACT),
    ("dive",     0.25, 1.1, "DIVE.",  150, "100",       "(h-text_h)-90", FONT_IMPACT),
    ("beak",     0.0,  1.2, "STEAL.", 170, "(w-text_w)/2", "(h-text_h)/2+120", FONT_IMPACT),
    ("fish1",    0.2,  1.3, "A FISH.",         92, "70",  "70", FONT_IMPACT),
    ("bow1",     0.4,  1.3, "A RAINBOW.",      92, "70",  "70", FONT_IMPACT),
    ("star1",    0.1,  1.3, "A FALLING STAR.", 92, "70",  "70", FONT_IMPACT),
    ("cover",    1.2,  3.6, "play it free  -  Windows and your browser", 34, "(w-text_w)/2", "h-120", FONT_SERIF),
    ("cover",    1.9,  2.9, "github.com/KOUHOUKOU/JUST-SOME-FRIES",      30, "(w-text_w)/2", "h-76",  FONT_SANS),
]


def dur(path):
    out = subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path])
    return float(out.decode().strip())


async def tts(text, path):
    await edge_tts.Communicate(text, VOICE, rate=RATE, pitch=PITCH).save(path)


def esc(s):
    return s.replace("\\", "\\\\").replace(":", "\\:").replace("'", "\\'").replace("%", "\\%")


async def main():
    # ---- the timeline
    starts, lens = {}, []
    t = 0.0
    for name, src, a, d, sp, o in SHOTS:
        starts[name] = t
        lens.append(d)
        t += d
    total = t
    print("shots", len(SHOTS), "total", round(total, 2), "s")
    anchors = {"SWELL": starts["beak"], "DROP": starts["slam"], "E_START": starts["bite"], "T_HIT": starts["same"], "TITLE": starts["cover"], "TOTAL": total}
    json.dump(anchors, open("anchors_r20.json", "w"))
    print(anchors)
    # ---- the score (built from the anchors)
    subprocess.check_call([sys.executable, os.path.join(ROOT, "tools", "film", "score_r20.py")])
    # ---- voice
    cues = []
    for shot, off, text in VOICE_LINES:
        pth = "tr_v_%s.mp3" % hashlib.md5((VOICE + RATE + PITCH + text).encode()).hexdigest()[:10]
        if not os.path.exists(pth) or os.path.getsize(pth) == 0:
            try:
                await tts(text, pth)
            except Exception as e:                     # (the online voice is not reachable: the cut is made without it, see --voice-sapi)
                print("no voice for %r: %s" % (text, str(e)[:80]))
                continue
        if isinstance(off, tuple):                      # ("end", anchor, gap): the line ends `gap` seconds before the anchor
            st0 = anchors[off[1]] - off[2] - dur(pth)
        else:
            st0 = starts[shot] + off
        cues.append((pth, st0, text))
    for pth, st0, text in cues:
        print("voice %6.2f-%6.2f  %s" % (st0, st0 + dur(pth), text))
    # ---- inputs
    inputs, idx = [], {}
    for src in sorted(set(s[1] for s in SHOTS if s[1] != "BLACK")):
        idx[src] = len(idx)
        inputs += ["-i", src]
    n_in = len(idx)
    inputs += ["-i", "score_r20.wav"]
    score_i = n_in
    n_in += 1
    voice_i0 = n_in
    for pth, _, _ in cues:
        inputs += ["-i", pth]
        n_in += 1
    # ---- video + footage sound of every shot
    F, parts = [], []
    for i, (name, src, a, d, sp, o) in enumerate(SHOTS):
        if src == "BLACK":
            F.append("color=c=black:s=%dx%d:r=%d:d=%.3f,setsar=1[v%d]" % (W, H, FPS, d, i))
            F.append("anullsrc=r=48000:cl=stereo,atrim=duration=%.3f[a%d]" % (d, i))
            parts.append("[v%d][a%d]" % (i, i))
            continue
        k = idx[src]
        b = a + d * sp
        vf = "[%d:v]trim=start=%.4f:end=%.4f,setpts=(PTS-STARTPTS)/%s,fps=%d,scale=%d:%d,setsar=1" % (k, a, b, sp, FPS, W, H)
        if o.get("zoom"):
            z = o["zoom"]
            vf += ",scale=w='trunc(%d*(1+%.3f*t/%.3f)/2)*2':h='trunc(%d*(1+%.3f*t/%.3f)/2)*2':eval=frame,crop=%d:%d" % (W, z, d, H, z, d, W, H)
        if o.get("fi"):
            vf += ",fade=t=in:st=0:d=%.3f" % o["fi"]
        if o.get("flash"):
            vf += ",fade=t=in:st=0:d=%.3f:color=white" % o["flash"]
        if o.get("fo"):
            vf += ",fade=t=out:st=%.3f:d=%.3f" % (d - o["fo"], o["fo"])
        vf += "[v%d]" % i
        af = "[%d:a]atrim=start=%.4f:end=%.4f,asetpts=PTS-STARTPTS,aresample=48000" % (k, a, b)
        if abs(sp - 1.0) > 0.01:
            s2, chain = sp, []
            while s2 > 2.0:
                chain.append("atempo=2.0")
                s2 /= 2.0
            chain.append("atempo=%s" % s2)
            af += "," + ",".join(chain)
        vol = 0.0 if o.get("mute") else 10 ** (o.get("sfx", 0.0) / 20.0)
        af += ",volume=%.3f,apad=whole_dur=%.3f,atrim=end=%.3f,afade=t=in:st=0:d=0.03,afade=t=out:st=%.3f:d=0.05[a%d]" % (vol, d, d, max(0.0, d - 0.05), i)
        F += [vf, af]
        parts.append("[v%d][a%d]" % (i, i))
    F.append("".join(parts) + "concat=n=%d:v=1:a=1[cv][csfx]" % len(SHOTS))
    # ---- the look: a little warmth and contrast, soft vignette, fine grain; then the type
    F.append("[cv]eq=contrast=1.06:saturation=1.12:gamma=0.98,vignette=angle=0.52,noise=alls=5:allf=t[gv]")
    prev = "gv"
    for k, (shot, off, secs, text, size, x, y, font) in enumerate(TEXTS):
        fn = "tr20_text%02d.txt" % k
        with open(fn, "w", encoding="utf-8", newline="") as f:
            f.write(text)
        st = starts[shot] + off
        en = st + secs
        alpha = "if(lt(t,%.3f),(t-%.3f)/0.14,if(gt(t,%.3f),(%.3f-t)/0.25,1))" % (st + 0.14, st, en - 0.25, en)
        nxt = "tx%d" % k
        F.append("[%s]drawtext=fontfile='%s':textfile=%s:fontcolor=white:fontsize=%d:x=%s:y=%s:borderw=5:bordercolor=black@0.85:shadowx=4:shadowy=5:shadowcolor=black@0.6:alpha='%s':enable='between(t,%.3f,%.3f)'[%s]"
                 % (prev, font, fn, size, x, y, alpha, st, en, nxt))
        prev = nxt
    F.append("[%s]format=yuv420p[outv]" % prev)
    # ---- the sound: footage effects, score, voice (the score ducks under the voice), a limiter
    F.append("[csfx]volume=0.85,highpass=f=40[sfxb]")
    F.append("[%d:a]aresample=48000,volume=1.0[score]" % score_i)
    vo = []
    for k, (pth, st, text) in enumerate(cues):
        ms = int(st * 1000)
        F.append("[%d:a]aresample=48000,highpass=f=90,equalizer=f=250:t=q:w=1:g=2,equalizer=f=3500:t=q:w=1.2:g=2,aecho=0.8:0.7:70|150:0.2|0.1,adelay=%d|%d,volume=2.0[vo%d]" % (voice_i0 + k, ms, ms, k))
        vo.append("[vo%d]" % k)
    F.append("".join(vo) + "amix=inputs=%d:normalize=0:dropout_transition=0,apad=whole_dur=%.3f,atrim=end=%.3f[voice]" % (len(vo), total, total))
    if not vo:
        F[-1] = "anullsrc=r=48000:cl=stereo,atrim=duration=%.3f[voice]" % total
    F.append("[voice]asplit=2[voice_a][voice_b]")
    F.append("[score][voice_a]sidechaincompress=threshold=0.03:ratio=5:attack=20:release=500:makeup=1[scoreduck]")
    F.append("[sfxb][scoreduck][voice_b]amix=inputs=3:normalize=0:duration=first:dropout_transition=0,loudnorm=I=-16:TP=-2.0:LRA=11,alimiter=limit=0.8:level=disabled[outa]")
    with open("filter_trailer_r20.txt", "w", encoding="utf-8", newline="\n") as f:
        f.write(";\n".join(F))
    out = "trailer_r20.mp4"
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-stats"] + inputs + ["-filter_complex_script", "filter_trailer_r20.txt", "-map", "[outv]", "-map", "[outa]",
        "-c:v", "libx264", "-crf", "20", "-preset", "medium", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", out]
    print("running ffmpeg ...")
    subprocess.check_call(cmd)

    def ts(x):
        h, r = divmod(x, 3600)
        m, s = divmod(r, 60)
        return "%02d:%02d:%02d,%03d" % (int(h), int(m), int(s), int((s - int(s)) * 1000))
    with open("trailer_r20.srt", "w", encoding="utf-8") as f:
        for k, (pth, st, text) in enumerate(cues, 1):
            f.write("%d\n%s --> %s\n%s\n\n" % (k, ts(st), ts(st + dur(pth) + 0.2), text))
    print("done", round(dur(out), 1), "s")


asyncio.run(main())
