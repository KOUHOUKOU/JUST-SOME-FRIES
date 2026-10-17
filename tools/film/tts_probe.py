"""Does the online voice (edge-tts) answer?  Tries the installed library as it is, then with newer Edge version strings (a header value, nothing is downloaded).
    python tools/film/tts_probe.py
"""
import asyncio, os, sys
import edge_tts
from edge_tts import constants, communicate as comm


async def one(text="Just some fries."):
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "film", "_tts_probe.mp3")
    await edge_tts.Communicate(text, "en-US-AndrewNeural").save(out)
    return os.path.getsize(out)


async def main():
    try:
        print("as installed:", await one())
        return
    except Exception as e:
        print("as installed: FAILED", str(e)[:70])
    for major in range(144, 160):
        full = "%d.0.%d.%d" % (major, 3700 + (major - 144) * 60, 60 + major % 40)
        constants.CHROMIUM_FULL_VERSION = full
        constants.CHROMIUM_MAJOR_VERSION = str(major)
        constants.SEC_MS_GEC_VERSION = "1-" + full
        for mod in (comm, constants):
            if hasattr(mod, "SEC_MS_GEC_VERSION"):
                mod.SEC_MS_GEC_VERSION = "1-" + full
        try:
            n = await one()
            print("works with", full, n)
            return
        except Exception as e:
            print(full, "FAILED", str(e)[:50])


asyncio.run(main())
