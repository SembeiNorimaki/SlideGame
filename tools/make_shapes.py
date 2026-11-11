"""Generate shape images: white glyph on transparent background, centered.
Usage: python3 tools/make_shapes.py A [B C ...]   -> assets/shapes/<letter>.png
"""
import sys, os
from PIL import Image, ImageDraw, ImageFont

SIZE = 64           # final image size (px)
PAD = 4             # empty border around the glyph (px)
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
SS = 8              # supersampling for smooth, accurate edges


def make_glyph(ch: str) -> Image.Image:
    big = SIZE * SS
    box = (SIZE - 2 * PAD) * SS
    # Find the largest font size whose ink fits in the box.
    size = box
    while True:
        font = ImageFont.truetype(FONT, size)
        l, t, r, b = font.getbbox(ch)
        if r - l <= box and b - t <= box:
            break
        size -= 4
    img = Image.new("L", (big, big), 0)
    d = ImageDraw.Draw(img)
    x = (big - (r - l)) / 2 - l
    y = (big - (b - t)) / 2 - t
    d.text((x, y), ch, font=font, fill=255)
    alpha = img.resize((SIZE, SIZE), Image.LANCZOS)
    out = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 0))
    out.putalpha(alpha)
    return out


if __name__ == "__main__":
    os.makedirs("assets/shapes", exist_ok=True)
    for ch in sys.argv[1:]:
        make_glyph(ch).save(f"assets/shapes/{ch}.png")


def make_atlas(chars: str, columns: int = 5) -> Image.Image:
    """Cells are SIZE x SIZE, filled row by row; unused cells stay transparent."""
    rows = -(-len(chars) // columns)
    atlas = Image.new("RGBA", (columns * SIZE, rows * SIZE), (255, 255, 255, 0))
    for i, ch in enumerate(chars):
        atlas.paste(make_glyph(ch), ((i % columns) * SIZE, (i // columns) * SIZE))
    return atlas
