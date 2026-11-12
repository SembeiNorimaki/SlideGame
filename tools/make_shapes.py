"""Shared image helpers for the atlas generators.

Every shape is white on a transparent background, centered in a SIZE x SIZE
cell with a PAD-pixel empty border, drawn at SS x resolution then scaled
down for smooth edges. Letters use Inter Light; silhouettes are outlined
with a STROKE-pixel line of about the same thickness.
"""
import os

from PIL import Image, ImageDraw, ImageFont

SIZE = 256        # cell size in the atlas (px) = size shown on screen
PAD = 16          # empty border around each shape (px)
SS = 4            # supersampling factor
STROKE = 14       # outline thickness for silhouettes (px); Inter Light stems are ~15 px
FONT = os.path.join(os.path.dirname(__file__), "fonts", "Inter-Light.otf")


def to_rgba(alpha: Image.Image) -> Image.Image:
    """SS-sized grayscale mask -> SIZE x SIZE white RGBA image."""
    out = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 0))
    out.putalpha(alpha.resize((SIZE, SIZE), Image.LANCZOS))
    return out


def make_glyph(ch: str) -> Image.Image:
    big = SIZE * SS
    box = (SIZE - 2 * PAD) * SS
    # Largest font size whose ink fits in the box.
    size = box
    while True:
        font = ImageFont.truetype(FONT, size)
        l, t, r, b = font.getbbox(ch)
        if r - l <= box and b - t <= box:
            break
        size -= 4
    img = Image.new("L", (big, big), 0)
    ImageDraw.Draw(img).text(((big - (r - l)) / 2 - l, (big - (b - t)) / 2 - t), ch, font=font, fill=255)
    return to_rgba(img)


def make_atlas(images, columns: int = 5) -> Image.Image:
    """Pastes SIZE x SIZE images row by row; unused cells stay transparent."""
    rows = -(-len(images) // columns)
    atlas = Image.new("RGBA", (columns * SIZE, rows * SIZE), (255, 255, 255, 0))
    for i, im in enumerate(images):
        atlas.paste(im, ((i % columns) * SIZE, (i // columns) * SIZE))
    return atlas
