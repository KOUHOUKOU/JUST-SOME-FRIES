"""
Joins the four recorded segments (film/seg1..4.avi, see autotest.gd `film`) into the 2-minute promotional video with a spoken narration (edge-tts, a neural voice)
and burned-in subtitles. Run from the project folder:  python tools/film/make_promo.py
Outputs: film/promo.mp4 (+ film/promo.srt, film/promo_10MB.mp4).
"""
import asyncio, os, shutil, subprocess, sys
import edge_tts

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
FILM = os.path.join(ROOT, "film")
os.chdir(FILM)
VOICE = "en-US-AndrewNeural"
RATE = "-3%"
GAP = 0.25

# (segment file, source start, source end, lead-in silence, [sentences]); a clip is stretched (last frame held) if the sentences need more time
CLIPS = [
    ("seg1.avi", 0.0, 3.6, 0.3, ["Just Some Fries.", "One very hungry seagull. One very small wish."]),
    ("seg1.avi", 4.4, 12.4, 0.2, ["It begins with a fry that nobody notices."]),
    ("seg1.avi", 21.0, 36.0, 0.2, ["A big gull asks a small one where he is headed.", "Down to the pier, says the small one. For some fries."]),
    ("seg2.avi", 2.2, 8.8, 0.2, ["Dive. Lock on. When the world slows down, find the rhythm."]),
    ("seg2.avi", 9.6, 12.8, 0.2, ["Every fry is a tiny rhythm game."]),
    ("seg2.avi", 14.0, 18.6, 0.2, ["Hold Tab, and the island shows you what it hides."]),
    ("seg3.avi", 4.5, 14.0, 0.2, ["Coffee. A cocktail. Ice cream.", "All three at once, and it is Rainbow Time."]),
    ("seg12.avi", 1.0, 6.8, 0.2, ["Nothing costs anything. Nothing can hurt you."]),
    ("seg12.avi", 10.5, 17.5, 0.2, ["So fast, that the moon is just another fry."]),
    ("seg12.avi", 33.5, 40.5, 0.2, ["And the sun."]),
    ("seg12.avi", 48.4, 54.4, 0.2, ["A rainbow fry. Perfectly caught."]),
    ("seg11.avi", 8.8, 16.8, 0.2, ["Catch a fish, and the sea becomes your surfboard."]),
    ("seg11.avi", 17.6, 26.8, 0.2, ["Surf. Then press Space... and launch."]),
    ("seg11.avi", 26.0, 31.5, 0.2, ["The fish keep jumping. So do you."]),
    ("seg3.avi", 22.5, 31.5, 0.2, ["Even a falling star."]),
    ("seg13.avi", 1.0, 13.5, 0.2, ["The hat. The shades. The chain. And a flock that comes when you call."]),
    ("seg13.avi", 14.0, 29.5, 0.2, ["You have the whole sky... and somehow, you are still on the roof.", "Still hungry."]),
    ("seg14.avi", 17.5, 39.5, 0.2, ["Until one fry falls at your feet.", "And you remember everything."]),
    ("seg14.avi", 92.5, 98.0, 0.2, []),
    ("seg14.avi", 98.5, 116.5, 0.2, ["Where does it end? It had something to do with the fries."]),
    ("seg14.avi", 118.5, 124.5, 0.2, []),
]
CARD_LINES = ["Just Some Fries.", "Download the Windows version for the best experience."]
CARD = 4.2
SRC_FILE = {}


def dur(path):
    out = subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path])
    return float(out.decode().strip())


async def tts(text, path):
    await edge_tts.Communicate(text, VOICE, rate=RATE).save(path)


async def main():
    jobs = []
    for ci, (_, _, _, _, sents) in enumerate(CLIPS):
        for ti, s in enumerate(sents):
            p = "n%02d_%d.mp3" % (ci, ti)
            if not os.path.exists(p):
                jobs.append(tts(s, p))
    await asyncio.gather(*jobs)
    t = 0.0
    info, subs, nar = [], [], []
    for ci, (src, a, b, lead, sents) in enumerate(CLIPS):
        cur = lead
        for ti, s in enumerate(sents):
            d = dur("n%02d_%d.mp3" % (ci, ti))
            subs.append((t + cur, t + cur + d + 0.1, s, False))
            nar.append(("n%02d_%d.mp3" % (ci, ti), t + cur))
            cur += d + GAP
        need = cur - GAP + 0.4 if sents else 0.0
        length = max(b - a, need)
        info.append((src, a, b, length, t))
        t += length
    # the end card speaks too
    for ti, sline in enumerate(CARD_LINES):
        p = "ncard_%d.mp3" % ti
        if not os.path.exists(p):
            await tts(sline, p)
    cur = 0.5
    for ti, sline in enumerate(CARD_LINES):
        d = dur("ncard_%d.mp3" % ti)
        subs.append((t + cur, t + cur + d + 0.1, sline, True))
        nar.append(("ncard_%d.mp3" % ti, t + cur))
        cur += d + GAP
    global CARD
    CARD = max(CARD, cur + 0.6)
    print("clips", round(t, 1), "s + card", CARD)
    shutil.copy("C:/Windows/Fonts/arial.ttf", "arial.ttf")
    shutil.copy("C:/Windows/Fonts/arialbd.ttf", "arialbd.ttf")
    inputs = []
    idx = {}
    for src in sorted(set(c[0] for c in CLIPS)):
        idx[src] = len(inputs) // 2
        inputs += ["-i", src]
    n_vid = len(idx)
    for p, _ in nar:
        inputs += ["-i", p]
    F, vparts = [], []
    for i, (src, a, b, length, st) in enumerate(info):
        k = idx[src]
        avail = b - a
        pad = max(0.0, length - avail)
        vf = "[%d:v]trim=start=%s:end=%s,setpts=PTS-STARTPTS,fps=30,scale=1280:720" % (k, a, b)
        if pad > 0:
            vf += ",tpad=stop_mode=clone:stop_duration=%.3f" % pad
        vf += ",fade=t=in:st=0:d=0.25,fade=t=out:st=%.3f:d=0.3[v%d]" % (length - 0.3, i)
        af = ("[%d:a]atrim=start=%s:end=%s,asetpts=PTS-STARTPTS,aresample=48000,apad=whole_dur=%.3f,atrim=end=%.3f,volume=0.55,"
              "afade=t=in:st=0:d=0.25,afade=t=out:st=%.3f:d=0.3[a%d]") % (k, a, b, length, length, length - 0.3, i)
        F += [vf, af]
        vparts.append("[v%d][a%d]" % (i, i))
    F.append("color=c=0x14110d:s=1280x720:r=30:d=%s[cardv0]" % CARD)
    F.append("anullsrc=r=48000:cl=stereo,atrim=duration=%s[carda]" % CARD)
    F.append("[cardv0]drawtext=fontfile=arialbd.ttf:text='JUST SOME FRIES':fontcolor=0xf0b453:fontsize=84:x=(w-text_w)/2:y=h/2-110,"
             "drawtext=fontfile=arial.ttf:text='Recommended - download the Windows version':fontcolor=white:fontsize=40:x=(w-text_w)/2:y=h/2,"
             "drawtext=fontfile=arial.ttf:text='github.com/KOUHOUKOU/JUST-SOME-FRIES/releases':fontcolor=0xcfc3b0:fontsize=32:x=(w-text_w)/2:y=h/2+60,"
             "drawtext=fontfile=arial.ttf:text='Clearer and smoother locally - the browser version is only a light trial':fontcolor=0xcfc3b0:fontsize=26:x=(w-text_w)/2:y=h/2+110,"
             "drawtext=fontfile=arial.ttf:text='kouhoukou.github.io/JUST-SOME-FRIES':fontcolor=0xcfc3b0:fontsize=24:x=(w-text_w)/2:y=h/2+152,"
             "drawtext=fontfile=arial.ttf:text='Our ending is a tribute to WHAT FRIES AHEAD - False Knees #319, by Joshua Barkman':fontcolor=0x9a8f7c:fontsize=22:x=(w-text_w)/2:y=h/2+206,"
             "fade=t=in:st=0:d=0.5,fade=t=out:st=%s:d=0.5[cardv]" % (CARD - 0.5))
    vparts.append("[cardv][carda]")
    F.append("".join(vparts) + "concat=n=%d:v=1:a=1[cv][ca]" % (len(CLIPS) + 1))
    chain, prev, cnt = [], "cv", 0
    for k, (a, b, s, card) in enumerate(subs):
        fn = "psub%02d.txt" % k
        with open(fn, "w", encoding="utf-8", newline="") as f:
            f.write(s)
        nxt = "sv%d" % cnt
        cnt += 1
        chain.append("[%s]drawtext=fontfile=arialbd.ttf:textfile=%s:fontcolor=white:fontsize=34:box=1:boxcolor=black@0.55:boxborderw=10:x=(w-text_w)/2:y=%s:enable='between(t,%.3f,%.3f)'[%s]" % (prev, fn, 'h-110' if card else '30', a, b, nxt))
        prev = nxt
    F += chain
    F.append("[%s]null[outv]" % prev)
    for k, (p, st) in enumerate(nar):
        ms = int(st * 1000)
        F.append("[%d:a]aresample=48000,adelay=%d|%d,volume=1.7[n%d]" % (n_vid + k, ms, ms, k))
    F.append("".join("[n%d]" % k for k in range(len(nar))) + "amix=inputs=%d:normalize=0:dropout_transition=0[nar]" % len(nar))
    F.append("[ca]volume=1.0[bed]")
    F.append("[bed][nar]amix=inputs=2:normalize=0:duration=first,loudnorm=I=-16:TP=-1.5:LRA=9[outa]")
    with open("filter.txt", "w", encoding="utf-8", newline="\n") as f:
        f.write(";\n".join(F))
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-stats"] + inputs + ["-filter_complex_script", "filter.txt", "-map", "[outv]", "-map", "[outa]",
        "-c:v", "libx264", "-crf", "27", "-preset", "medium", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "160k", "-movflags", "+faststart", "promo.mp4"]
    print("running ffmpeg...")
    subprocess.check_call(cmd)

    def ts(x):
        h, r = divmod(x, 3600)
        m, s = divmod(r, 60)
        return "%02d:%02d:%02d,%03d" % (int(h), int(m), int(s), int((s - int(s)) * 1000))
    with open("promo.srt", "w", encoding="utf-8") as f:
        for k, (a, b, s, card) in enumerate(subs, 1):
            f.write("%d\n%s --> %s\n%s\n\n" % (k, ts(a), ts(b), s))
    print("done", round(dur("promo.mp4"), 1), "s")


asyncio.run(main())
