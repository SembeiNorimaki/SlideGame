"""Shared image helpers for the atlas generators.

Every shape is white on a transparent background, centered in a SIZE x SIZE
cell with a PAD-pixel empty border, drawn at SS x resolution then scaled
down for smooth edges. Letters use Inter Light; silhouettes are outlined
with a STROKE-pixel line of about the same thickness.
"""
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont
from scipy import ndimage

SIZE = 256        # cell size in the atlas (px) = size shown on screen
PAD = 16          # empty border around each shape (px)
SS = 4            # supersampling factor
STROKE = 14       # outline thickness for silhouettes (px); Inter Light stems are ~15 px
FONTS = os.path.join(os.path.dirname(__file__), "fonts")
FONT = os.path.join(FONTS, "Inter-Light.otf")
SYMBOL_FONT = os.path.join(FONTS, "DejaVuSans.ttf")  # dingbats / pictographs


def to_rgba(alpha: Image.Image) -> Image.Image:
    """SS-sized grayscale mask -> SIZE x SIZE white RGBA image."""
    out = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 0))
    out.putalpha(alpha.resize((SIZE, SIZE), Image.LANCZOS))
    return out


def make_glyph(ch: str, font_path: str = FONT) -> Image.Image:
    """A character drawn as-is (thin strokes with Inter Light)."""
    big = SIZE * SS
    box = (SIZE - 2 * PAD) * SS
    # Largest font size whose ink fits in the box.
    size = box
    while True:
        font = ImageFont.truetype(font_path, size)
        l, t, r, b = font.getbbox(ch)
        if r - l <= box and b - t <= box:
            break
        size -= 4
    img = Image.new("L", (big, big), 0)
    ImageDraw.Draw(img).text(((big - (r - l)) / 2 - l, (big - (b - t)) / 2 - t), ch, font=font, fill=255)
    return to_rgba(img)


def fit(mask: Image.Image) -> Image.Image:
    """Crops a grayscale drawing to its ink and scales it to fill the cell box
    (inside the padding), centered on an SS-sized canvas."""
    ink = mask.crop(mask.getbbox())
    box = (SIZE - 2 * PAD) * SS
    scale = min(box / ink.width, box / ink.height)
    ink = ink.resize((max(1, round(ink.width * scale)), max(1, round(ink.height * scale))), Image.LANCZOS)
    big = Image.new("L", (SIZE * SS, SIZE * SS), 0)
    big.paste(ink, ((big.width - ink.width) // 2, (big.height - ink.height) // 2))
    return big


def outline(big: Image.Image, stroke=STROKE) -> Image.Image:
    """Keeps only the band within `stroke` px of an edge (outer edge and holes).
    stroke=None returns the shape solid."""
    if not stroke:
        return big
    filled = np.array(big) > 127
    inside = ndimage.distance_transform_edt(filled)
    return Image.fromarray(((filled & (inside <= stroke * SS)) * 255).astype(np.uint8))


def make_outlined_glyph(ch: str, font_path: str = SYMBOL_FONT, stroke=STROKE) -> Image.Image:
    """A solid pictograph character (e.g. ✂) turned into a thin outline."""
    font = ImageFont.truetype(font_path, 1000)
    img = Image.new("L", (1400, 1400), 0)
    ImageDraw.Draw(img).text((200, 100), ch, font=font, fill=255)
    return to_rgba(outline(fit(img), stroke))


def make_atlas(images, columns: int = 5) -> Image.Image:
    """Pastes SIZE x SIZE images row by row; unused cells stay transparent."""
    rows = -(-len(images) // columns)
    atlas = Image.new("RGBA", (columns * SIZE, rows * SIZE), (255, 255, 255, 0))
    for i, im in enumerate(images):
        atlas.paste(im, ((i % columns) * SIZE, (i // columns) * SIZE))
    return atlas
