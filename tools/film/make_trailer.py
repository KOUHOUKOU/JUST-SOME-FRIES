"""The 2-minute trailer: cuts the recorded film segments (film/segN.avi, recorded with --nomusic) into a montage with its own score (the game's own music files),
a few spoken lines (edge-tts, voice Andrew) and burned-in subtitles for those lines.

    python tools/film/make_trailer.py            (needs edge_tts: run WITHOUT -I)

Outputs film/trailer.mp4, film/trailer.srt, film/trailer_10MB.mp4
The timeline is a list of SHOTS (source, in, out, speed, fades). Voice lines and music pieces hang on shots (shot index + offset), so re-cutting a shot moves them with it.
"""
import asyncio, hashlib, os, shutil, subprocess, sys
import edge_tts

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
FILM = os.path.join(ROOT, "film")
MUSIC = os.path.join(ROOT, "game", "assets", "audio", "music")
SFX = os.path.join(ROOT, "game", "assets", "audio", "sfx")
os.chdir(FILM)
VOICE = "en-US-AndrewNeural"
RATE = "-2%"
W, H, FPS = 1280, 720, 30

# (name, source, in, out, speed, fade_in, fade_out)   (a fade is a dip to black)
SHOTS = []
exec(open(os.path.join(ROOT, "tools", "film", "trailer_shots.py"), encoding="utf-8").read())
# trailer_shots.py defines SHOTS, VOICE_LINES, MUSIC_CUES, CARD (see that file)


def dur(path):
    out = subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path])
    return float(out.decode().strip())


async def tts(text, path):
    await edge_tts.Communicate(text, VOICE, rate=RATE).save(path)


async def main():
    # --- timeline
    starts = {}
    t = 0.0
    lens = []
    for i, (name, src, a, b, spd, fi, fo) in enumerate(SHOTS):
        L = (b - a) / spd
        starts[name] = t
        lens.append(L)
        t += L
    total = t
    print("shots", len(SHOTS), "total", round(total, 1), "s")
    # --- voice
    cues = []
    for k, (shot, off, text) in enumerate(VOICE_LINES):
        p = "tr_v_%s.mp3" % hashlib.md5((VOICE + RATE + text).encode()).hexdigest()[:10]
        if not os.path.exists(p) or os.path.getsize(p) == 0:
            await tts(text, p)
        cues.append((p, starts[shot] + off, text))
    inputs = []
    idx = {}
    for src in sorted(set(s[1] for s in SHOTS if s[1] != "BLACK")):
        idx[src] = len(inputs) // 2
        inputs += ["-i", src]
    n_vid = len(idx)
    n_in = n_vid
    for p, _, _ in cues:
        inputs += ["-i", p]
    voice_idx0 = n_in
    n_in += len(cues)
    music_idx = []
    for (shot, off, f, ss, length, vol, fade_in, fade_out) in MUSIC_CUES:
        inputs += ["-stream_loop", "-1", "-i", os.path.join(MUSIC, f)]
        music_idx.append(n_in)
        n_in += 1
    sfx_idx = []
    for (shot, off, f, vol) in SFX_CUES:
        inputs += ["-i", os.path.join(SFX, f)]
        sfx_idx.append(n_in)
        n_in += 1
    # --- video / sfx of every shot
    F, vparts = [], []
    for i, (name, src, a, b, spd, fi, fo) in enumerate(SHOTS):
        L = lens[i]
        if src == "BLACK":
            F.append("color=c=black:s=%dx%d:r=%d:d=%.3f,setsar=1[v%d]" % (W, H, FPS, L, i))
            F.append("anullsrc=r=48000:cl=stereo,atrim=duration=%.3f[a%d]" % (L, i))
            vparts.append("[v%d][a%d]" % (i, i))
            continue
        k = idx[src]
        vf = "[%d:v]trim=start=%s:end=%s,setpts=(PTS-STARTPTS)/%s,fps=%d,scale=%d:%d,setsar=1" % (k, a, b, spd, FPS, W, H)
        if fi > 0:
            vf += ",fade=t=in:st=0:d=%s" % fi
        if fo > 0:
            vf += ",fade=t=out:st=%.3f:d=%s" % (L - fo, fo)
        vf += "[v%d]" % i
        af = "[%d:a]atrim=start=%s:end=%s,asetpts=PTS-STARTPTS,aresample=48000" % (k, a, b)
        if abs(spd - 1.0) > 0.01:
            sp = spd
            chain = []
            while sp > 2.0:
                chain.append("atempo=2.0")
                sp /= 2.0
            while sp < 0.5:
                chain.append("atempo=0.5")
                sp /= 0.5
            chain.append("atempo=%s" % sp)
            af += "," + ",".join(chain)
        af += ",apad=whole_dur=%.3f,atrim=end=%.3f,afade=t=in:st=0:d=0.04,afade=t=out:st=%.3f:d=0.06[a%d]" % (L, L, max(0.0, L - 0.06), i)
        F += [vf, af]
        vparts.append("[v%d][a%d]" % (i, i))
    F.append("".join(vparts) + "concat=n=%d:v=1:a=1[cv][csfx]" % len(SHOTS))
    # --- subtitles (the voice lines only) + the end card text on the last shot
    prev = "cv"
    cnt = 0
    for k, (shot, off, dur_s, text, size, y, color) in enumerate(CARD):
        fn = "tr_card%02d.txt" % k
        with open(fn, "w", encoding="utf-8", newline="") as f:
            f.write(text)
        st = starts[shot] + off
        nxt = "sv%d" % cnt
        cnt += 1
        F.append("[%s]drawtext=fontfile=arialbd.ttf:textfile=%s:fontcolor=%s:fontsize=%d:x=(w-text_w)/2:y=%s:alpha='min(1,(t-%.3f)/0.5)':enable='between(t,%.3f,%.3f)'[%s]" % (prev, fn, color, size, y, st, st, st + dur_s, nxt))
        prev = nxt
    F.append("[%s]null[outv]" % prev)
    # --- audio: sfx of the footage + the score + the voice + a few game sounds
    F.append("[csfx]volume=%s[sfxb]" % SFX_VOL)
    mus = []
    for k, ((shot, off, f, ss, length, vol, fi_, fo_), ii) in enumerate(zip(MUSIC_CUES, music_idx)):
        st = starts[shot] + off
        if isinstance(length, str):                 # "to:shot" = until that shot starts (plus the tail of its fade)
            length = starts[length[3:]] - st + 0.3
        ms = int(st * 1000)
        F.append("[%d:a]atrim=start=%s:end=%s,asetpts=PTS-STARTPTS,aresample=48000,volume=%s,afade=t=in:st=0:d=%s,afade=t=out:st=%.3f:d=%s,adelay=%d|%d[m%d]" % (ii, ss, ss + length, vol, fi_, length - fo_, fo_, ms, ms, k))
        mus.append("[m%d]" % k)
    F.append("".join(mus) + "amix=inputs=%d:normalize=0:dropout_transition=0,apad=whole_dur=%.3f,atrim=end=%.3f[score]" % (len(mus), total, total))
    vo = []
    for k, ((p, st, text)) in enumerate(cues):
        ms = int(st * 1000)
        F.append("[%d:a]aresample=48000,adelay=%d|%d,volume=1.9[vo%d]" % (voice_idx0 + k, ms, ms, k))
        vo.append("[vo%d]" % k)
    F.append("".join(vo) + "amix=inputs=%d:normalize=0:dropout_transition=0,apad=whole_dur=%.3f,atrim=end=%.3f[voice]" % (len(vo), total, total))
    F.append("[voice]asplit=2[voice_a][voice_b]")
    F.append("[score][voice_a]sidechaincompress=threshold=0.03:ratio=6:attack=15:release=450:makeup=1[scoreduck]")
    gs = []
    for k, ((shot, off, f, vol), ii) in enumerate(zip(SFX_CUES, sfx_idx)):
        ms = int((starts[shot] + off) * 1000)
        F.append("[%d:a]aresample=48000,volume=%s,adelay=%d|%d[g%d]" % (ii, vol, ms, ms, k))
        gs.append("[g%d]" % k)
    mix_in = "[sfxb][scoreduck][voice_b]" + "".join(gs)
    F.append("%samix=inputs=%d:normalize=0:duration=first:dropout_transition=0,loudnorm=I=-15:TP=-2:LRA=9,alimiter=limit=0.85:level=disabled[outa]" % (mix_in, 3 + len(gs)))
    with open("filter_trailer.txt", "w", encoding="utf-8", newline="\n") as f:
        f.write(";\n".join(F))
    cmd = ["ffmpeg", "-y", "-loglevel", "error", "-stats"] + inputs + ["-filter_complex_script", "filter_trailer.txt", "-map", "[outv]", "-map", "[outa]",
        "-c:v", "libx264", "-crf", "25", "-preset", "medium", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", "trailer.mp4"]
    print("running ffmpeg ...")
    subprocess.check_call(cmd)

    def ts(x):
        h, r = divmod(x, 3600)
        m, s = divmod(r, 60)
        return "%02d:%02d:%02d,%03d" % (int(h), int(m), int(s), int((s - int(s)) * 1000))
    with open("trailer.srt", "w", encoding="utf-8") as f:
        for k, (p, st, text) in enumerate(cues, 1):
            f.write("%d\n%s --> %s\n%s\n\n" % (k, ts(st), ts(st + dur(p) + 0.2), text))
    subprocess.check_call(["ffmpeg", "-y", "-loglevel", "error", "-i", "trailer.mp4", "-i", "trailer.srt", "-map", "0", "-map", "1", "-c", "copy", "-c:s", "mov_text",
                           "-metadata:s:s:0", "language=eng", "-movflags", "+faststart", "trailer_s.mp4"])
    os.replace("trailer_s.mp4", "trailer.mp4")
    print("done", round(dur("trailer.mp4"), 1), "s")


asyncio.run(main())
