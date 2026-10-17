"""A contact sheet with the time of every frame burned in (to pick the in/out points of the trailer's shots).
    python tools/film/timesheet.py film/seg30.avi 0 30 [step=1.0] [cols=6] [out.png]
"""
import subprocess, sys, os

src, a, b = sys.argv[1], float(sys.argv[2]), float(sys.argv[3])
step = float(sys.argv[4]) if len(sys.argv) > 4 else 1.0
cols = int(sys.argv[5]) if len(sys.argv) > 5 else 6
out = sys.argv[6] if len(sys.argv) > 6 else os.path.join(os.path.dirname(os.path.abspath(src)), "cs", os.path.basename(src).replace(".avi", "") + "_%d_%d.png" % (a, b))
n = int((b - a) / step) + 1
rows = (n + cols - 1) // cols
w = 1920 // cols
vf = "fps=1/%s,scale=%d:-1,drawtext=fontfile='C\\:/Windows/Fonts/arialbd.ttf':text='%%{pts\\:flt\\:%.1f}':x=6:y=h-th-6:fontsize=22:fontcolor=yellow:box=1:boxcolor=black@0.6,tile=%dx%d" % (step, w, a, cols, rows)
cmd = ["ffmpeg", "-v", "error", "-y", "-ss", str(a), "-t", str(b - a + 0.01), "-i", src, "-vf", vf, "-frames:v", "1", out]
subprocess.run(cmd, check=True)
print(out)
