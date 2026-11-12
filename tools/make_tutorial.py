"""Draw the tutorial's shape: a smiley face, outlined like the Shapes set.
It isn't any real level, so the tutorial doesn't give an answer away.

Usage (from the project root):  python3 tools/make_tutorial.py
Writes assets/tutorial/smiley.png (256x256).
"""
import os

from PIL import Image, ImageDraw

from make_shapes import fit, outline, to_rgba


def smiley() -> Image.Image:
    img = Image.new("L", (1024, 1024), 0)
    d = ImageDraw.Draw(img)
    d.ellipse((62, 62, 962, 962), fill=255)          # face
    d.ellipse((300, 290, 420, 470), fill=0)          # left eye
    d.ellipse((604, 290, 724, 470), fill=0)          # right eye
    d.chord((250, 380, 774, 800), 20, 160, fill=0)   # smile
    return img


if __name__ == "__main__":
    os.makedirs("assets/tutorial", exist_ok=True)
    to_rgba(outline(fit(smiley()))).save("assets/tutorial/smiley.png")
