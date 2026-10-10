# 34 · Round 13 — "the two gulls, and the browser" (2026-10-10: the final check)

New dev checks: `[R13]` lines in `--r8c` (the opening) and `--r8e` (the ending): the two gulls are never closer than 3 m (`autotest.gd gull_gap`, `GULL_GAP_MIN`); `--r13reload` (the browser's restart by page reload).
New tool: `tools/web/patch_index.py` (run after every web export, see below).

## 1. The big brother and the little gull overlapped (opening and ending)
Cause: in round 12 the big brother was scaled to 2.3x a gull, but the places of the two gulls were still the ones made for a 1.0 gull (3.3 m apart on the roof in the opening, **1.6 m** apart on the cafe floor in the ending): the big brother's beak almost touched the little gull in the opening, and in the ending his body stood on top of it.

| Scene | Before | Now |
|---|---|---|
| Opening (roof) | little gull (-9.5, -0.8), big brother (-6.2, -1.3): 3.3 m | little gull at the west end of the roof (`WB.SPAWN_POS` -11.6, -0.8), big brother (`WB.BRO_POS` -5.8, -1.3): **5.8 m**. The five camera shots of the scene (two-shot, close on him, "no answer", looks away) are re-aimed; the little gull's spawn (and its first view of the cafe table, the respawn point, the perch pad) moved with it. |
| Ending (cafe floor) | little gull (-8.5, 5.0), he lands at (-6.9, 5.1): 1.6 m | little gull (-9.2, 5.0), he lands at (-5.5, 5.1): **3.7 m**, the dropped fry lies between them. People who could walk through the picture between the camera and the two gulls are hidden for the scene (it used to happen twice). |
| Roof talks (`bro_chat`) | the little gull could be sitting right at his side | if it is closer than 4 m it is placed 4.2 m west of him, facing him, before the camera starts |

Checked with the real flow (`--r8c`, `--r8e`) and contact sheets; the new `[R13]` checks keep it that way. (The promo video `walkthrough.mp4` was recorded before this fix: its opening still shows the old places until it is recorded again.)

## 2. The browser version (stops, freezes, "crashes")
Measured in a real Chrome (RTX 5070 Ti laptop, 144 Hz screen, a 1266x666 canvas, own temporary profile; `?diag=1`, bots `--soak` / `--r9cine`; Chrome started with `--disable-renderer-backgrounding --disable-backgrounding-occluded-windows`, because a window that is covered by another one gets **no animation frames at all**: an early run that looked like "a 26 s first frame" was exactly that, not a real number).

What the numbers say:
* **Memory is not the problem in a session of this length**: the wasm heap stays at 255-313 MB for 5 minutes (no growth), the JS heap 100-300 MB, no lost WebGL context, no abort.
* **The game is CPU-bound in the browser**: 23-44 fps on this strong machine (frame 23-38 ms; natively 12-30 ms); draw calls 500-3,300; everything runs on one thread. Weaker laptops will be slower: the browser version cannot be made 60 fps.
* **Freezes**: the first picture takes **8-35 s** (the island is built in one go: 1.8-4.3 s in the browser; the rest is the browser preparing the graphics); then, in the first 5 minutes of flying, **10 frames longer than 0.25 s, four of them 2.7-4.0 s** (the grass/flower MultiMeshes appearing and new areas, new materials); in the **film moments** the browser ran at 2-4 fps (frames of 250-530 ms) and each moment began with a ~5 s freeze.
* **Cause of the slow film moments**: the blur at the edges read the whole screen with mipmaps every frame (`story.gd BLUR_SHADER`, `hint_screen_texture`). Switching it off (`?lite=2`, dev switch) took the hitches from 67 to 25 in the same run and the moments back to their real length (13 s).
* The three **close-ups** each draw the island again (switching them off: 67 -> 50 hitches).
* **Restart** built a second island inside the same wasm heap (the heap only ever grows: that is the classic way a long session ends in an out-of-memory crash).
* **Laptops with two graphics chips**: the page asked for the default GPU, so Chrome could choose the weak integrated one (this machine has Intel + NVIDIA; the check on the page now shows which one is used); Godot also asked for `preserveDrawingBuffer` (a copy of the whole picture every frame) and a high-DPI screen (125-200 %) multiplies the number of pixels (here DPR 1.5).

What changed:
| Cause | Change |
|---|---|
| the first frame | `world_flora.gd`: the grass/flower/pebble scatter is **time-sliced over the following frames** (10 ms per frame on the paused title screen, 3 ms while flying), so the island's synchronous build is 1.0 s native instead of 2.2 s; `[PERF] the island was built in N ms`, `slowest build steps`, `graphics prepared in N ms` |
| freezes while flying | `main.gd _web_warm_up`: behind the loading screen, before the title appears, the camera is sent over 12 places of the island (a burst of sparks, the sun / cloud / star / rainbow props shown once) so the browser prepares everything once. Result in the same 5-minute flight: **no frame longer than 0.4 s after the first 45 s** (it was 10 hitches, 2.8 s at the worst, spread over the whole flight) |
| slow film moments | the blur is a **plain dark vignette in the browser** (`VIGNETTE_SHADER`, no screen texture); the close-ups are redrawn every third frame (staggered) |
| restart | `main._reload`: in the browser the page is **reloaded** (clean heap) instead of `reload_current_scene`; the choice (new run / menu) goes through `sessionStorage` (`GS._ready`); 0.8 s wait so a fresh save reaches the browser's storage. Verified end to end in Chrome (`--r13reload`) |
| GPU / pixels / copy | `tools/web/patch_index.py`: `powerPreference: high-performance`, `preserveDrawingBuffer: false`, `devicePixelRatio` capped at 1 (`?hq=1` turns the cap off) |
| the page | a **start card** (honest instructions: light version, 30-90 s first load, desktop Chrome/Edge with hardware acceleration, High-performance GPU on laptops, save now and then, download link, video link, controls; it shows the graphics chip in use and warns about software drawing / integrated graphics / phones). The engine starts after the click (also needed for sound). A **loading screen** with a spinner (a CSS animation keeps turning while the page is frozen), the download percentage and "preparing the graphics n of 12" |
| "it just died" | a watchdog: lost WebGL context, wasm abort / out of memory, or no frame for 15 s -> a card that says what happened with **Reload** (and "keep waiting" for the stall case); the first-load stall limit is 150 s |
| measuring | `?diag=1`: fps, frame time, longest frame, hitches, wasm and JS memory, canvas size, GPU in a corner + a `[JSF-DIAG]` line every 10 s and a `[JSF-HITCH]` line for every frame longer than 250 ms in the console; `?autostart=1` skips the card; `?lite=N` (dev) 1 = no close-ups, 2 = no blur |

After a web export: `python tools/web/patch_index.py web/index.html film/poster_new.jpg` (the poster becomes `cover.jpg` next to the page; the script refuses a second run on a patched file and fails loudly if Godot's template changes).

## 3. What still is not known / limits
* The normal flow (menu, no bot) in the real browser: download, island 4.3 s, first frame 8.5 s, graphics prepared in 1.2 s, then the title at the display rate; 2 frames over 1 s in the first 110 s, 3 over 0.25 s. A **cold** machine / a weaker laptop will take longer (up to ~35 s for the first picture on this one before the warm-up existed).
* Not run in a browser: the whole 15-minute game, the real ending (credits end in the page reload; the reload itself is tested), sound quality (the audio runs in the browser's audio thread; I cannot listen).
* The browser build stays the light version: expect 20-40 fps. The Windows download is the real game.
