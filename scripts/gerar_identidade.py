"""Gera os assets vetoriais simples do livro e os recursos Android, sem rede."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "brand"
ASSETS.mkdir(parents=True, exist_ok=True)
GREEN = "#153E35"
CREAM = "#F0E7CF"
GOLD = "#CCA56A"


def mark(background):
    image = Image.new("RGBA", (1024, 1024), background)
    draw = ImageDraw.Draw(image)
    draw.polygon([(230, 298), (492, 347), (492, 730), (230, 681)], fill=CREAM)
    draw.polygon([(532, 347), (794, 298), (794, 681), (532, 730)], fill=CREAM)
    draw.line([(256, 700), (492, 750), (512, 741), (532, 750), (768, 700)], fill=GOLD, width=14, joint="curve")
    for y in (408, 472, 536, 600):
        draw.line([(282, y), (437, y + 29)], fill="#8F9D88", width=10)
    for y in (510, 574, 638):
        draw.line([(587, y), (742, y - 29)], fill="#8F9D88", width=10)
    draw.polygon([(656, 324), (714, 313), (714, 472), (685, 455), (656, 485)], fill=GOLD)
    return image


icon = mark(GREEN)
foreground = mark((0, 0, 0, 0))
icon.save(ASSETS / "icon.png")
foreground.save(ASSETS / "icon_foreground.png")
foreground.resize((384, 384), Image.Resampling.LANCZOS).save(ASSETS / "splash.png")
resources = ROOT / "android" / "app" / "src" / "main" / "res"
for density, size in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
    directory = resources / f"mipmap-{density}"
    directory.mkdir(parents=True, exist_ok=True)
    icon.resize((size, size), Image.Resampling.LANCZOS).convert("RGB").save(directory / "ic_launcher.png")
drawable = resources / "drawable"
drawable.mkdir(parents=True, exist_ok=True)
foreground.resize((288, 288), Image.Resampling.LANCZOS).save(drawable / "splash_logo.png")
foreground.resize((432, 432), Image.Resampling.LANCZOS).save(drawable / "icon_foreground.png")
print("Identidade visual e ícones Android gerados.")
