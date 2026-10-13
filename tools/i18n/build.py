"""Builds the game's language data (round 17).

    python tools/i18n/build.py            -> game/assets/i18n/strings.json + game/assets/fonts/jsf_sc.ttf, jsf_jp.ttf

The tables live in tr_*.py next to this file: (english, simplified chinese, traditional chinese, japanese).
English is the key: it must be exactly the text the code shows (or its % format string for lines with numbers / names;
the translations then use {0} {1} .. for the values, in the order of the English placeholders).
The fonts are subsets of Noto Sans SC / JP (SIL Open Font License 1.1, see game/assets/fonts/OFL.txt) with only the
letters the game uses, so they stay small for the browser build.
"""
import importlib.util, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
GAME = os.path.join(ROOT, "game")
OUT_JSON = os.path.join(GAME, "assets", "i18n", "strings.json")
FONT_DIR = os.path.join(GAME, "assets", "fonts")
SRC_FONTS = {"jsf_sc": r"C:\Windows\Fonts\NotoSansSC-VF.ttf", "jsf_jp": r"C:\Windows\Fonts\NotoSansJP-VF.ttf"}
WEIGHT = 500
LANGS = ["zh_CN", "zh_TW", "ja"]
SPEC = re.compile(r"%(-?0?\d*)(\.\d+)?([dfis])")


def load_tables():
    rows = []
    for f in sorted(os.listdir(HERE)):
        if f.startswith("tr_") and f.endswith(".py"):
            spec = importlib.util.spec_from_file_location(f[:-3], os.path.join(HERE, f))
            m = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(m)
            for r in m.T:
                rows.append((f, r))
    return rows


def main():
    rows = load_tables()
    data = {}
    errors = 0
    for f, r in rows:
        if len(r) != 4:
            print("!! bad row", f, r)
            errors += 1
            continue
        en, cn, tw, ja = r
        n = len(SPEC.findall(en))
        for lang, v in zip(LANGS, (cn, tw, ja)):
            used = [int(x) for x in re.findall(r"\{(\d+)\}", v)]
            if any(u >= n for u in used):
                print(f"!! {f}: {lang} uses a placeholder the English has not got: {en!r} -> {v!r}")
                errors += 1
            if n and not used and lang:
                print(f"   note {f}: {lang} drops every value of {en!r}")
            if re.search(r"%[-0-9.]*[dfs]", v):
                print(f"!! {f}: {lang} still has a % placeholder: {v!r}")
                errors += 1
        new = {"zh_CN": cn, "zh_TW": tw, "ja": ja}
        if en in data and data[en] != new:
            print(f"   note: {en!r} is translated twice; the later one ({f}) wins")
        data[en] = new
    os.makedirs(os.path.dirname(OUT_JSON), exist_ok=True)
    with open(OUT_JSON, "w", encoding="utf-8", newline="\n") as fo:
        json.dump(data, fo, ensure_ascii=False, indent=0, sort_keys=True)
    print(f"{len(data)} strings -> {OUT_JSON}")
    # ---- the fonts
    chars = {"jsf_sc": set(), "jsf_jp": set()}
    extra = "简体中文繁體中文日本語语言語言言語·…—「」『』（）！？，。、：；～・“”‘’《》【】〈〉％"
    for v in data.values():
        chars["jsf_sc"].update(v["zh_CN"] + v["zh_TW"])
        chars["jsf_jp"].update(v["ja"])
    for k in chars:
        chars[k].update(extra)
        chars[k] = {c for c in chars[k] if ord(c) > 0x7F}
    if "--no-fonts" not in sys.argv:
        from fontTools.ttLib import TTFont
        from fontTools.varLib import instancer
        from fontTools import subset
        os.makedirs(FONT_DIR, exist_ok=True)
        for name, src in SRC_FONTS.items():
            font = TTFont(src)
            cmap = font.getBestCmap()
            missing = sorted(c for c in chars[name] if ord(c) not in cmap)
            if missing:
                print(f"!! {name}: the source font lacks {''.join(missing)}")
            font = instancer.instantiateVariableFont(font, {"wght": WEIGHT})
            opts = subset.Options()
            opts.layout_features = ["*"]
            opts.name_IDs = ["*"]
            opts.notdef_outline = True
            opts.hinting = False
            sub = subset.Subsetter(opts)
            sub.populate(unicodes=sorted(ord(c) for c in chars[name]))
            sub.subset(font)
            out = os.path.join(FONT_DIR, name + ".ttf")
            font.save(out)
            print(f"{name}: {len(chars[name])} letters -> {out} ({os.path.getsize(out) // 1024} KB)")
    if errors:
        print(f"{errors} ERRORS")
        sys.exit(1)


if __name__ == "__main__":
    main()
