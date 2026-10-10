"""Compose existing PNG evidence, without rendering again (installed Pillow)."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
FOLDER = ROOT / "art_src/p0/game"


def sheet(entries, destination):
    rows = (len(entries) + 1) // 2
    image = Image.new("RGB", (512, 168 * rows), "#eee7dc")
    draw = ImageDraw.Draw(image)
    for index, (name, label) in enumerate(entries):
        x, y = index % 2 * 256, index // 2 * 168
        with Image.open(FOLDER / (name + ".png")) as source:
            source = source.convert("RGB")
            source.thumbnail((256, 144), Image.Resampling.LANCZOS)
            image.paste(source, (x, y + 24))
        draw.text((x + 7, y + 5), label, fill="#302b32")
    image.save(FOLDER / destination)


if __name__ == "__main__":
    sheet([("close_before", "BEFORE: primitive / flat colour"),
           ("close_after", "AFTER: GLB / vertex AO / soft-toon")], "before_after.png")
    sheet([(d + "_" + style, f"{d}: {style}")
           for d in ("close", "15m", "60m") for style in ("before", "after")], "distance_sheet.png")
    sheet([("close_after", "Authored vertex colours"),
           ("close_white_vertex_ablation", "Same mesh: COLOR_0 forced white"),
           ("close_governor3", "Governor 3: 60% / no shadows")], "diagnostics.png")
