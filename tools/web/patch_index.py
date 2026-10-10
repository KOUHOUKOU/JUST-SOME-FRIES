#!/usr/bin/env python3
"""Round 13: hardens the Godot web export's index.html (run after every `godot --export-release Web`).

    python tools/web/patch_index.py web/index.html [poster.jpg]

What it adds (all of it guarded by try/catch: the page must never break because of the patch):
  * a start card (honest instructions: browser build is the light version, GPU hint, first load can freeze, download link) - the engine only starts
    after the click, which also satisfies the browser's "audio needs a gesture" rule;
  * a loading screen with a spinner that keeps turning while the page is frozen (CSS animation, not JavaScript), the download progress, and the game's
    own "preparing the graphics n of m" steps (main.gd `_web_warm_up` calls JSF.warm / JSF.gameReady);
  * WebGL context attributes: powerPreference "high-performance" (a laptop with two graphics chips otherwise gives the browser the weak one) and
    preserveDrawingBuffer false (Godot asks for true: a copy of the whole picture every frame);
  * devicePixelRatio capped at 1 (a 150 % / 200 % display otherwise makes the canvas 2.25x / 4x as many pixels); ?hq=1 turns the cap off;
  * a watchdog: lost WebGL context, wasm abort / out of memory, or no frame for a long time -> a card that says what happened and offers a reload
    (instead of a silent frozen picture);
  * ?diag=1 shows fps / frame time / hitches / memory / GPU in a corner, prints a [JSF-DIAG] line every 10 s and a [JSF-HITCH] line for every frame
    longer than 250 ms; ?autostart=1 skips the card.
"""
import re
import shutil
import sys
from pathlib import Path

MARK_BEGIN = "<!-- JSF-PATCH-BEGIN -->"
MARK_END = "<!-- JSF-PATCH-END -->"

CSS = r"""
<style>
#jsf-card, #jsf-stop { position: fixed; inset: 0; z-index: 50; display: flex; align-items: center; justify-content: center; padding: 16px; box-sizing: border-box;
  font: 15px/1.5 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; color: #f6ecdc; }
#jsf-card { background: #14100d url(cover.jpg) center / cover no-repeat; }
#jsf-card::before, #jsf-stop::before { content: ""; position: absolute; inset: 0; background: linear-gradient(180deg, rgba(14,10,8,.55), rgba(14,10,8,.88)); }
#jsf-stop { background: rgba(14,10,8,.82); }
.jsf-box { position: relative; max-width: 640px; width: 100%; max-height: 100%; overflow: auto; background: rgba(32,24,18,.9); border: 1px solid rgba(255,214,120,.35);
  border-radius: 14px; padding: 22px 26px 20px; box-shadow: 0 10px 40px rgba(0,0,0,.5); }
.jsf-box h1 { margin: 0 0 2px; font-size: 28px; letter-spacing: .06em; color: #ffd36b; }
.jsf-box .tag { margin: 0 0 14px; color: #d9c7a8; }
.jsf-box ul { margin: 10px 0 14px; padding-left: 20px; }
.jsf-box li { margin: 5px 0; color: #eadcc4; }
.jsf-box b { color: #ffe3a1; }
.jsf-row { display: flex; flex-wrap: wrap; gap: 10px; align-items: center; margin-top: 8px; }
.jsf-btn { appearance: none; border: 0; border-radius: 10px; padding: 12px 22px; font: inherit; font-weight: 700; cursor: pointer; text-decoration: none; display: inline-block; }
.jsf-go { background: #ffc94d; color: #2b1c05; font-size: 17px; }
.jsf-go:hover { background: #ffd978; }
.jsf-alt { background: rgba(255,255,255,.1); color: #f6ecdc; border: 1px solid rgba(255,255,255,.25); }
.jsf-alt:hover { background: rgba(255,255,255,.18); }
.jsf-warn { margin: 0 0 12px; padding: 10px 14px; border-radius: 10px; background: rgba(255,179,71,.14); border: 1px solid rgba(255,179,71,.55); color: #ffe7c2; }
.jsf-warn b { color: #ffd36b; }
#jsf-chip { display: none; position: fixed; left: 8px; bottom: 8px; z-index: 30; font: 12px/1.3 system-ui, sans-serif; color: #fff; background: rgba(20,14,8,.55); padding: 5px 9px; border-radius: 14px;
  opacity: .55; transition: opacity .2s; text-decoration: none; }
#jsf-chip:hover { opacity: 1; background: rgba(20,14,8,.85); }
#jsf-gpu { margin-top: 12px; font-size: 12.5px; color: #b9a98d; word-break: break-word; }
#jsf-gpu.warn { color: #ffb36b; }
#jsf-load { display: none; position: fixed; inset: 0; z-index: 40; align-items: center; justify-content: center; flex-direction: column; text-align: center; padding: 20px; box-sizing: border-box;
  background: #14100d url(cover.jpg) center / cover no-repeat; color: #f6ecdc; font: 16px/1.5 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }
#jsf-load::before { content: ""; position: absolute; inset: 0; background: rgba(14,10,8,.72); }
#jsf-load > * { position: relative; }
#jsf-load h1 { margin: 0 0 18px; font-size: 26px; letter-spacing: .06em; color: #ffd36b; }
.jsf-spin { width: 46px; height: 46px; border-radius: 50%; border: 5px solid rgba(255,211,107,.25); border-top-color: #ffd36b; animation: jsfspin .9s linear infinite; will-change: transform; }
@keyframes jsfspin { to { transform: rotate(360deg); } }
#jsf-load-bar { width: min(420px, 70vw); height: 6px; border-radius: 3px; background: rgba(255,255,255,.15); margin: 18px 0 12px; overflow: hidden; }
#jsf-load-bar > div { height: 100%; width: 0%; background: #ffc94d; }
#jsf-load-text { max-width: 520px; color: #eadcc4; min-height: 3em; }
#jsf-load-sub { max-width: 520px; color: #b9a98d; font-size: 13px; margin-top: 6px; }
#jsf-diag { position: fixed; left: 6px; top: 6px; z-index: 60; background: rgba(0,0,0,.65); color: #9dffb0; font: 12px/1.35 ui-monospace, Consolas, monospace; padding: 5px 8px;
  border-radius: 6px; white-space: pre; pointer-events: none; display: none; }
</style>
"""

CARD = r"""
<div id="jsf-card">
  <div class="jsf-box">
    <h1>JUST SOME FRIES</h1>
    <p class="tag">Be a gull. Steal magic fries off a seaside pier, and find out what you were really hungry for.</p>
    <div class="jsf-warn"><b>Recommended: download the Windows version and play it locally.</b> The browser page is only a light trial and may not run stably (slow first load, lower frame rate, simplified graphics). The local version has clearer graphics and runs much more smoothly.<br><b>&#25512;&#33616;&#19979;&#36733;&#21040;&#26412;&#22320;&#36827;&#34892;&#28216;&#29609;&#65306;</b>&#32593;&#39029;&#29256;&#21487;&#33021;&#26080;&#27861;&#31283;&#23450;&#36816;&#34892;&#65288;&#39318;&#27425;&#21152;&#36733;&#24456;&#24930;&#12289;&#24103;&#29575;&#36739;&#20302;&#12289;&#30011;&#36136;&#34987;&#31616;&#21270;&#65289;&#65292;&#26412;&#22320;&#29256;&#30011;&#36136;&#26356;&#28165;&#26224;&#12289;&#36816;&#34892;&#26356;&#27969;&#30021;&#12290;</div>
    <div class="jsf-row">
      <a class="jsf-btn jsf-go" href="https://github.com/KOUHOUKOU/JUST-SOME-FRIES/releases/latest" target="_blank" rel="noopener">&#11015; Download the full game (Windows) - recommended</a>
      <button class="jsf-btn jsf-alt" id="jsf-play">&#9654; Quick trial in the browser (light version)</button>
      <a class="jsf-btn jsf-alt" href="walkthrough.html" target="_blank" rel="noopener">Watch the 2-minute video</a>
    </div>
    <ul>
      <li>The browser trial is a <b>light version</b> (it runs on one thread inside your browser, about 20-40 fps, and some effects are simpler). The <b>Windows download</b> is the real game.</li>
      <li><b>The first load takes 30 to 90 seconds</b>: the page downloads 65 MB, builds the island and prepares the graphics, and freezes between the steps. A spinner shows that it is alive. After that the game should not freeze again.</li>
      <li>Use <b>desktop Chrome or Edge</b> with <b>hardware acceleration ON</b>. Close heavy tabs and apps first. A keyboard and mouse are needed.</li>
      <li>On a laptop with two graphics chips: Windows Settings &gt; System &gt; Display &gt; Graphics &gt; add your browser &gt; Options &gt; <b>High performance</b>.</li>
      <li>If it ever stops, reload the page. Use <b>SAVE</b> in the pause menu (Esc) now and then; the game continues from the last save.</li>
      <li>Mouse steer &middot; W fly &middot; Shift boost &middot; E grab &middot; Tab Gull Sight &middot; Esc pause. Click the game once so it can take the mouse.</li>
    </ul>
    <div id="jsf-gpu"></div>
  </div>
</div>
<div id="jsf-stop" style="display:none">
  <div class="jsf-box">
    <h1 id="jsf-stop-title">The game stopped</h1>
    <p id="jsf-stop-text" class="tag"></p>
    <div class="jsf-row">
      <button class="jsf-btn jsf-go" id="jsf-reload">Reload the game</button>
      <a class="jsf-btn jsf-alt" href="https://github.com/KOUHOUKOU/JUST-SOME-FRIES/releases/latest" target="_blank" rel="noopener">Download for Windows</a>
      <button class="jsf-btn jsf-alt" id="jsf-dismiss" style="display:none">Keep waiting</button>
    </div>
  </div>
</div>
<div id="jsf-load">
  <h1>JUST SOME FRIES</h1>
  <div class="jsf-spin"></div>
  <div id="jsf-load-bar"><div></div></div>
  <div id="jsf-load-text">Starting...</div>
  <div id="jsf-load-sub">The first load takes a while and the picture freezes now and then; the spinner keeps turning. This happens only once. Please keep this tab open.</div>
</div>
<a id="jsf-chip" href="https://github.com/KOUHOUKOU/JUST-SOME-FRIES/releases/latest" target="_blank" rel="noopener">Light browser trial &middot; for clearer, smoother play download the Windows version &#8599; &middot; &#25512;&#33616;&#19979;&#36733;&#26412;&#22320;&#29256;</a>
<div id="jsf-diag"></div>
"""

# runs before index.js: it must be in place before the engine asks for its WebGL context
HEAD_JS = r"""
<script>
(function () {
	'use strict';
	var q = new URLSearchParams(location.search);
	var J = window.JSF = { diag: q.has('diag'), hq: q.has('hq'), autostart: q.has('autostart'), frames: 0, lastFrame: 0, started: false, ready: false, warming: false, stopped: false,
		lostCount: 0, errors: [], longest: 0, hitches: 0, hitchLog: [], fps: 0, ms: 0, startedAt: 0, renderer: '?', engine: null };
	// the game (main.gd _web_warm_up) says how far its "preparing the graphics" is, and when it is done
	J.gameReady = function () {
		J.warming = false; J.ready = true;
		var l = document.getElementById('jsf-load'); if (l) { l.style.display = 'none'; }
		var c = document.getElementById('jsf-chip'); if (c && !new URLSearchParams(location.search).has('nochip')) { c.style.display = 'block'; }
	};
	J.warm = function (i, n) {
		J.warming = true;
		var t = document.getElementById('jsf-load-text');
		if (t) { t.textContent = 'Preparing the graphics: ' + i + ' of ' + n + '. The picture freezes between the steps.'; }
		var b = document.querySelector('#jsf-load-bar > div'); if (b) { b.style.width = Math.round(100 * i / n) + '%'; }
	};
	J.fail = function (err) {
		// Godot's own error notice (it sits under the loading screen): bring it up
		var l = document.getElementById('jsf-load'); if (l) { l.style.display = 'none'; }
		var st = document.getElementById('status'); if (st) { st.style.zIndex = 60; }
	};
	J.progress = function (cur, total) {
		if (J.warming) { return; }
		var t = document.getElementById('jsf-load-text'); var b = document.querySelector('#jsf-load-bar > div');
		if (cur > 0 && total > 0) {
			if (t) { t.textContent = 'Downloading the game... ' + Math.round(100 * cur / total) + ' %'; }
			if (b) { b.style.width = Math.round(100 * cur / total) + '%'; }
			if (cur >= total && t) { t.textContent = 'Building the island...'; }
		}
	};
	try {
		var gc = HTMLCanvasElement.prototype.getContext;
		HTMLCanvasElement.prototype.getContext = function (t, a) {
			try {
				if (t === 'webgl2' || t === 'webgl') {
					a = Object.assign({}, a || {}, { powerPreference: 'high-performance', preserveDrawingBuffer: false });
				}
			} catch (e) { /* keep the original attributes */ }
			return gc.call(this, t, a);
		};
	} catch (e) { J.errors.push('gl patch: ' + e); }
	try {
		var real = window.devicePixelRatio || 1;
		var use = J.hq ? real : Math.min(real, 1);
		J.dpr = use; J.realDpr = real;
		if (use !== real) { Object.defineProperty(window, 'devicePixelRatio', { get: function () { return use; }, configurable: true }); }
	} catch (e) { J.errors.push('dpr patch: ' + e); }
	try {
		var raf = window.requestAnimationFrame.bind(window);
		var prev = 0, acc = 0, n = 0;
		window.requestAnimationFrame = function (cb) {
			return raf(function (t) {
				if (J.started) {
					var now = performance.now();
					if (prev) {
						var d = now - prev;
						if (J.ready && d > J.longest) { J.longest = d; }
						if (J.ready && d > 250) {
							J.hitches++;
							if (J.hitchLog.length < 60) { J.hitchLog.push([Math.round((now - J.startedAt) / 1000), Math.round(d)]); }
							if (J.diag) { console.log('[JSF-HITCH] ' + Math.round((now - J.startedAt) / 1000) + 's into the session: one frame took ' + Math.round(d) + ' ms'); }
						}
						acc += d; n++;
						if (acc >= 1000) { J.fps = n * 1000 / acc; J.ms = acc / n; acc = 0; n = 0; }
					}
					prev = now; J.lastFrame = now; J.frames++;
					// no preparation phase announced by the game (a dev bot, or an older build): three frames in = the game is up
					if (J.frames >= 3 && !J.ready && !J.warming) { J.gameReady(); }
				}
				return cb(t);
			});
		};
	} catch (e) { J.errors.push('raf patch: ' + e); }
})();
</script>
"""

TAIL_JS = r"""
<script>
(function () {
	'use strict';
	var J = window.JSF;
	var $ = function (id) { return document.getElementById(id); };
	var card = $('jsf-card'), stop = $('jsf-stop'), diag = $('jsf-diag');
	function gpuName() {
		try {
			var c = document.createElement('canvas');
			var gl = c.getContext('webgl2', { powerPreference: 'high-performance' });
			if (!gl) { return null; }
			var e = gl.getExtension('WEBGL_debug_renderer_info');
			var r = e ? gl.getParameter(e.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER);
			var l = gl.getExtension('WEBGL_lose_context'); if (l) { l.loseContext(); }
			return String(r);
		} catch (err) { return null; }
	}
	var gpu = gpuName();
	J.renderer = gpu || 'no WebGL 2';
	var g = $('jsf-gpu');
	if (g) {
		if (!gpu) {
			g.className = 'warn'; g.textContent = 'This browser cannot create a WebGL 2 picture (hardware acceleration may be off). The game cannot run here: please try Chrome or Edge, or download the Windows version.';
		} else if (/swiftshader|llvmpipe|software|basic render/i.test(gpu)) {
			g.className = 'warn'; g.textContent = 'Graphics: ' + gpu + ' - this is SOFTWARE drawing. Turn hardware acceleration ON in the browser settings, or the game will crawl.';
		} else if (/intel|uhd|iris/i.test(gpu) && !/nvidia|geforce|rtx|gtx|radeon|rx /i.test(gpu)) {
			g.className = 'warn'; g.textContent = 'Graphics in use: ' + gpu + ' - if this computer also has a stronger graphics card, set the browser to High performance (see above).';
		} else {
			g.textContent = 'Graphics in use: ' + gpu;
		}
	}
	if (/Android|iPhone|iPad|Mobile/i.test(navigator.userAgent) || ('ontouchstart' in window && screen.width < 900)) {
		if (g) { g.className = 'warn'; g.textContent = 'This looks like a phone or tablet. The game needs a keyboard and mouse: please open it on a computer. ' + (g.textContent || ''); }
	}

	function showStop(title, text, canWait) {
		if (J.stopped && !canWait) { return; }
		if (!canWait) { J.stopped = true; }
		$('jsf-stop-title').textContent = title;
		$('jsf-stop-text').textContent = text;
		$('jsf-dismiss').style.display = canWait ? 'inline-block' : 'none';
		stop.style.display = 'flex';
	}
	$('jsf-reload').onclick = function () { location.reload(); };
	$('jsf-dismiss').onclick = function () { stop.style.display = 'none'; };

	J.onPrint = function (s) { /* (hook for later: the game's own [PERF] lines pass through here) */ };
	J.onPrintError = function (s) {
		try {
			var t = String(s);
			if (/abort|out of memory|cannot enlarge memory|memory access out of bounds|unreachable|OOM/i.test(t)) {
				J.errors.push(t.slice(0, 160));
				showStop('The game stopped', 'The browser ran out of memory or the game crashed (' + t.slice(0, 120) + '). Reload to continue from your last save. The Windows version does not have this limit.', false);
			}
		} catch (e) { /* ignore */ }
	};
	document.addEventListener('webglcontextlost', function () {
		J.lostCount++;
		showStop('The graphics were reset', 'The browser took the graphics card away from the game (it was busy, low on memory, or another program needed it). Reload to continue from your last save.', false);
	}, true);
	window.addEventListener('error', function (e) {
		try { if (e && e.error && /RuntimeError|memory|abort/i.test(String(e.error))) { J.onPrintError(String(e.error)); } } catch (x) { /* ignore */ }
	});
	window.addEventListener('unhandledrejection', function (e) {
		try { if (e && e.reason && /RuntimeError|out of memory|abort/i.test(String(e.reason))) { J.onPrintError(String(e.reason)); } } catch (x) { /* ignore */ }
	});

	// watchdog: no frame for a long time. (While the island is built and the graphics are prepared, single frames can take up to a minute.)
	var warned = 0;
	setInterval(function () {
		try {
			if (!J.started || J.stopped || document.hidden) { warned = 0; return; }
			var now = performance.now();
			var idle = J.lastFrame ? now - J.lastFrame : now - J.startedAt;
			var limit = J.ready ? 15000 : 150000;
			if (idle > limit && !warned) {
				warned = now;
				showStop(J.ready ? 'The game seems stuck' : 'Still loading...', J.ready
					? 'No picture for ' + Math.round(idle / 1000) + ' seconds. It may recover by itself (a memory clean-up or a busy computer): you can keep waiting, or reload.'
					: 'Loading is taking very long on this computer. You can keep waiting, or download the Windows version.', true);
			} else if (idle < 2000 && warned) {
				warned = 0; stop.style.display = 'none';
			}
		} catch (e) { /* ignore */ }
	}, 2000);

	// ?diag=1: numbers in the corner and one console line every 10 s
	function memText() {
		var s = '';
		try {
			var rt = J.engine && J.engine.rtenv;
			var buf = rt && (rt.HEAPU8 ? rt.HEAPU8.buffer : (rt.wasmMemory ? rt.wasmMemory.buffer : null));
			if (buf) { s += 'wasm ' + Math.round(buf.byteLength / 1048576) + ' MB  '; }
			if (performance.memory) { s += 'js ' + Math.round(performance.memory.usedJSHeapSize / 1048576) + ' MB'; }
		} catch (e) { /* ignore */ }
		return s || 'mem n/a';
	}
	function line() {
		var cv = document.getElementById('canvas');
		return 'fps ' + J.fps.toFixed(0) + '  frame ' + J.ms.toFixed(0) + ' ms  longest ' + J.longest.toFixed(0) + ' ms  hitches>250ms ' + J.hitches + '\n' + memText() +
			'\ncanvas ' + (cv ? cv.width + 'x' + cv.height : '?') + '  dpr ' + J.dpr + '/' + J.realDpr + '  lost ' + J.lostCount + '\n' + J.renderer +
			(J.errors.length ? '\nERR ' + J.errors[J.errors.length - 1] : '');
	}
	if (J.diag) {
		diag.style.display = 'block';
		setInterval(function () { diag.textContent = line(); }, 500);
		setInterval(function () { if (J.started) { console.log('[JSF-DIAG] t=' + Math.round((performance.now() - J.startedAt) / 1000) + 's ' + line().replace(/\n/g, ' | ')); } }, 10000);
	}

	// the engine itself is started by the card's button (or at once with ?autostart=1)
	J.go = function () {
		if (J.started || !window.__jsfStartGame) { return; }
		J.started = true; J.startedAt = performance.now();
		card.style.display = 'none';
		var ld = $('jsf-load'); if (ld) { ld.style.display = 'flex'; }
		window.__jsfStartGame();
	};
	$('jsf-play').onclick = J.go;
	if (J.autostart) { J.go(); }
})();
</script>
"""


def patch(html_path: Path, poster: Path | None) -> None:
    src = html_path.read_text(encoding="utf-8")
    if MARK_BEGIN in src:
        print("already patched:", html_path, "(export again to get a pristine index.html)")
        if poster is not None and poster.exists():
            shutil.copyfile(poster, html_path.parent / "cover.jpg")
        return
    orig = src

    # 1. head: css + card + the early script (before index.js is loaded)
    if "<script src=\"index.js\"></script>" not in src:
        raise SystemExit("patch_index: <script src=\"index.js\"> not found")
    src = src.replace("<script src=\"index.js\"></script>", MARK_BEGIN + CSS + CARD + HEAD_JS + MARK_END + "\n\t\t<script src=\"index.js\"></script>", 1)

    # 2. the engine start becomes a function the card calls
    start_re = re.compile(r"\} else \{\n(\t+)setStatusMode\('progress'\);\n\t+engine\.startGame\(\{")
    m = start_re.search(src)
    if not m:
        raise SystemExit("patch_index: engine.startGame block not found (Godot template changed?)")
    ind = m.group(1)
    rest = src[m.end():]
    if "'onProgress': function (current, total) {" not in rest:
        raise SystemExit("patch_index: onProgress not found (Godot template changed?)")
    rest = rest.replace("'onProgress': function (current, total) {",
                        "'onProgress': function (current, total) {\n" + ind + "\tif (window.JSF && window.JSF.progress) { window.JSF.progress(current, total); }", 1)
    src = (src[: m.start()] + "} else {\n" + ind + "window.__jsfStartGame = function () {\n" + ind + "setStatusMode('progress');\n" + ind + "window.JSF.engine = engine;\n" + ind +
           "engine.startGame({\n" + ind + "'onPrint': function () { var s = Array.prototype.join.call(arguments, ' '); console.log(s); window.JSF.onPrint(s); },\n" +
           ind + "'onPrintError': function () { var s = Array.prototype.join.call(arguments, ' '); console.error(s); window.JSF.onPrintError(s); }," + rest)
    if "function displayFailureNotice(err) {" not in src:
        raise SystemExit("patch_index: displayFailureNotice not found")
    src = src.replace("function displayFailureNotice(err) {", "function displayFailureNotice(err) {\n\t\tif (window.JSF && window.JSF.fail) { window.JSF.fail(err); }", 1)
    end_old = "\t\t}).then(() => {\n\t\t\tsetStatusMode('hidden');\n\t\t}, displayFailureNotice);\n\t}\n}());"
    if end_old not in src:
        raise SystemExit("patch_index: end of the startGame block not found")
    end_new = "\t\t}).then(() => {\n\t\t\tsetStatusMode('hidden');\n\t\t}, displayFailureNotice);\n\t};\n\t}\n}());"
    src = src.replace(end_old, end_new, 1)

    # 3. the tail script (card logic) after the engine block
    if "\t</body>" not in src:
        raise SystemExit("patch_index: </body> not found")
    src = src.replace("\t</body>", MARK_BEGIN + TAIL_JS + MARK_END + "\n\t</body>", 1)
    if src == orig:
        raise SystemExit("patch_index: nothing changed")
    html_path.write_text(src, encoding="utf-8", newline="\n")
    if poster is not None and poster.exists():
        shutil.copyfile(poster, html_path.parent / "cover.jpg")
    print("patched", html_path, "(+cover.jpg)" if poster is not None and poster.exists() else "")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    patch(Path(sys.argv[1]), Path(sys.argv[2]) if len(sys.argv) > 2 else None)
