"""Draw the "shapes" set: simple white silhouettes on transparent background.
Each shape is drawn large, cropped to its ink, scaled to fit the cell
(same 4px padding as the letters), then downsampled to 64x64.

Usage (from the project root):  python3 tools/make_silhouettes.py
Writes assets/sets/shapes/atlas.png and game/data/sets/shapes.json.
"""
import math
import os

from PIL import Image, ImageDraw

from levels_json import write_levels

SIZE = 64
PAD = 4
COLUMNS = 5
C = 1024  # drawing canvas
ON, OFF = 255, 0


def canvas():
    img = Image.new("L", (C, C), OFF)
    return img, ImageDraw.Draw(img)


def circle(d, cx, cy, r, fill=ON):
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=fill)


def ngon(n, cx, cy, r, rot=-90):
    return [(cx + r * math.cos(math.radians(rot + i * 360 / n)),
             cy + r * math.sin(math.radians(rot + i * 360 / n))) for i in range(n)]


# ---- shapes -------------------------------------------------------------

def star(d):
    pts = []
    for i in range(10):
        r = 480 if i % 2 == 0 else 195
        a = math.radians(-90 + i * 36)
        pts.append((512 + r * math.cos(a), 530 + r * math.sin(a)))
    d.polygon(pts, fill=ON)


def heart(d):
    pts = []
    for i in range(400):
        t = 2 * math.pi * i / 400
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((512 + x * 28, 480 - y * 28))
    d.polygon(pts, fill=ON)


def moon(d):
    circle(d, 512, 512, 420)
    circle(d, 680, 400, 360, OFF)


def sun(d):
    for i in range(8):
        a = math.radians(i * 45)
        tip = (512 + 490 * math.cos(a), 512 + 490 * math.sin(a))
        l = (512 + 300 * math.cos(a - 0.22), 512 + 300 * math.sin(a - 0.22))
        r = (512 + 300 * math.cos(a + 0.22), 512 + 300 * math.sin(a + 0.22))
        d.polygon([tip, l, r], fill=ON)
    circle(d, 512, 512, 250)


def house(d):
    d.polygon([(512, 100), (920, 470), (104, 470)], fill=ON)
    d.rectangle((210, 460, 814, 900), fill=ON)
    d.rectangle((680, 170, 780, 380), fill=ON)  # chimney
    d.rectangle((450, 640, 574, 900), fill=OFF)  # door
    d.rectangle((640, 560, 740, 650), fill=OFF)  # window


def arrow(d):
    d.polygon([(100, 420), (560, 420), (560, 250), (930, 512),
               (560, 774), (560, 604), (100, 604)], fill=ON)


def cross(d):
    d.rectangle((400, 100, 624, 924), fill=ON)
    d.rectangle((100, 400, 924, 624), fill=ON)


def triangle(d):
    d.polygon(ngon(3, 512, 580, 470), fill=ON)


def circle_shape(d):
    circle(d, 512, 512, 440)


def square(d):
    d.rectangle((140, 140, 884, 884), fill=ON)


def diamond(d):
    d.polygon([(512, 60), (840, 512), (512, 964), (184, 512)], fill=ON)


def hexagon(d):
    d.polygon(ngon(6, 512, 512, 450, rot=0), fill=ON)


def cloud(d):
    circle(d, 330, 600, 200)
    circle(d, 540, 470, 260)
    circle(d, 740, 600, 190)
    d.rounded_rectangle((150, 560, 900, 790), radius=110, fill=ON)


def key(d):
    circle(d, 280, 512, 210)
    circle(d, 280, 512, 95, OFF)
    d.rectangle((440, 470, 930, 560), fill=ON)
    d.rectangle((760, 560, 820, 680), fill=ON)
    d.rectangle((860, 560, 930, 720), fill=ON)


def umbrella(d):
    d.pieslice((90, 140, 934, 984), 180, 360, fill=ON)
    for cx in (195, 406, 618, 829):  # scalloped edge
        circle(d, cx, 562, 106, OFF)
    d.rectangle((490, 500, 534, 840), fill=ON)
    d.arc((380, 730, 534, 900), 0, 180, fill=ON, width=44)


def cup(d):
    circle(d, 720, 520, 190)
    circle(d, 720, 520, 105, OFF)
    d.polygon([(170, 250), (710, 250), (660, 840), (220, 840)], fill=ON)
    d.rounded_rectangle((90, 840, 790, 920), radius=40, fill=ON)


def tree(d):
    d.polygon([(512, 60), (760, 380), (264, 380)], fill=ON)
    d.polygon([(512, 230), (840, 610), (184, 610)], fill=ON)
    d.polygon([(512, 420), (920, 830), (104, 830)], fill=ON)
    d.rectangle((440, 820, 584, 970), fill=ON)


def fish(d):
    d.ellipse((120, 300, 760, 724), fill=ON)
    d.polygon([(680, 512), (940, 300), (940, 724)], fill=ON)
    circle(d, 290, 460, 42, OFF)


def lightning(d):
    d.polygon([(600, 60), (240, 560), (480, 560), (380, 964),
               (790, 420), (540, 420), (700, 60)], fill=ON)


def drop(d):
    circle(d, 512, 650, 300)
    d.polygon([(512, 70), (240, 520), (784, 520)], fill=ON)
    d.polygon([(512, 70), (226, 560), (798, 560)], fill=ON)


def leaf(d):
    # vesica: intersection of two circles, tilted 45 degrees, plus a stem
    a = Image.new("L", (C, C), OFF)
    b = Image.new("L", (C, C), OFF)
    ImageDraw.Draw(a).ellipse((512 - 600 + 400, 512 - 600, 512 + 600 + 400, 512 + 600), fill=ON)
    ImageDraw.Draw(b).ellipse((512 - 600 - 400, 512 - 600, 512 + 600 - 400, 512 + 600), fill=ON)
    from PIL import ImageChops
    v = ImageChops.multiply(a, b).rotate(-45, resample=Image.BICUBIC, center=(512, 512))
    d._image.paste(ON, mask=v)
    d.line([(230, 794), (90, 934)], fill=ON, width=56)  # stem
    d.line([(270, 754), (680, 344)], fill=OFF, width=26)  # vein


def mushroom(d):
    d.pieslice((90, 110, 934, 800), 180, 360, fill=ON)
    d.rounded_rectangle((90, 420, 934, 470), radius=20, fill=ON)
    d.rounded_rectangle((380, 440, 644, 900), radius=70, fill=ON)
    circle(d, 330, 300, 60, OFF)
    circle(d, 620, 230, 70, OFF)
    circle(d, 720, 380, 45, OFF)


def bell(d):
    d.pieslice((260, 120, 764, 600), 180, 360, fill=ON)
    d.polygon([(260, 360), (764, 360), (820, 680), (900, 760),
               (124, 760), (204, 680)], fill=ON)
    circle(d, 512, 830, 90)
    circle(d, 512, 105, 55)


def crown(d):
    d.polygon([(130, 760), (130, 300), (320, 520), (512, 220),
               (704, 520), (894, 300), (894, 760)], fill=ON)
    d.rectangle((130, 790, 894, 880), fill=ON)
    for x, y in ((130, 270), (512, 190), (894, 270)):
        circle(d, x, y, 60)


def bone(d):
    d.rectangle((260, 430, 764, 594), fill=ON)
    for x in (230, 794):
        circle(d, x, 400, 120)
        circle(d, x, 624, 120)


# (drawing function, accepted answers per language). The first answer of
# each language is the main one; the rest are accepted synonyms.
SHAPES = [
    (star, {"EN": ["star"], "ES": ["estrella"]}),
    (heart, {"EN": ["heart"], "ES": ["corazón"]}),
    (moon, {"EN": ["moon", "crescent", "crescent moon"], "ES": ["luna", "media luna"]}),
    (sun, {"EN": ["sun"], "ES": ["sol"]}),
    (house, {"EN": ["house", "home"], "ES": ["casa"]}),
    (arrow, {"EN": ["arrow"], "ES": ["flecha"]}),
    (cross, {"EN": ["cross", "plus"], "ES": ["cruz", "más"]}),
    (triangle, {"EN": ["triangle"], "ES": ["triángulo"]}),
    (circle_shape, {"EN": ["circle", "disc", "disk", "dot"], "ES": ["círculo", "circunferencia", "punto"]}),
    (square, {"EN": ["square"], "ES": ["cuadrado"]}),
    (diamond, {"EN": ["diamond", "rhombus"], "ES": ["rombo", "diamante"]}),
    (hexagon, {"EN": ["hexagon"], "ES": ["hexágono"]}),
    (cloud, {"EN": ["cloud"], "ES": ["nube"]}),
    (key, {"EN": ["key"], "ES": ["llave"]}),
    (umbrella, {"EN": ["umbrella"], "ES": ["paraguas"]}),
    (cup, {"EN": ["cup", "mug"], "ES": ["taza"]}),
    (tree, {"EN": ["tree", "pine", "pine tree", "fir", "christmas tree"], "ES": ["árbol", "pino", "abeto", "árbol de navidad"]}),
    (fish, {"EN": ["fish"], "ES": ["pez", "pescado"]}),
    (lightning, {"EN": ["lightning", "bolt", "lightning bolt", "thunderbolt"], "ES": ["rayo", "relámpago"]}),
    (drop, {"EN": ["drop", "droplet", "water drop", "raindrop", "teardrop"], "ES": ["gota", "gota de agua", "lágrima"]}),
    (leaf, {"EN": ["leaf"], "ES": ["hoja"]}),
    (mushroom, {"EN": ["mushroom", "toadstool"], "ES": ["seta", "champiñón", "hongo"]}),
    (bell, {"EN": ["bell"], "ES": ["campana"]}),
    (crown, {"EN": ["crown"], "ES": ["corona"]}),
    (bone, {"EN": ["bone"], "ES": ["hueso"]}),
]


def render(fn) -> Image.Image:
    img, d = canvas()
    d._image = img
    fn(d)
    ink = img.crop(img.getbbox())
    box = (SIZE - 2 * PAD) * 8
    scale = min(box / ink.width, box / ink.height)
    ink = ink.resize((max(1, round(ink.width * scale)), max(1, round(ink.height * scale))), Image.LANCZOS)
    big = Image.new("L", (SIZE * 8, SIZE * 8), OFF)
    big.paste(ink, ((big.width - ink.width) // 2, (big.height - ink.height) // 2))
    alpha = big.resize((SIZE, SIZE), Image.LANCZOS)
    out = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 0))
    out.putalpha(alpha)
    return out


def main():
    rows = -(-len(SHAPES) // COLUMNS)
    atlas = Image.new("RGBA", (COLUMNS * SIZE, rows * SIZE), (255, 255, 255, 0))
    levels = []
    for i, (fn, solution) in enumerate(SHAPES):
        col, row = i % COLUMNS, i // COLUMNS
        atlas.paste(render(fn), (col * SIZE, row * SIZE))
        levels.append({"atlas_coords": [col, row], "solution": solution})
    os.makedirs("assets/sets/shapes", exist_ok=True)
    atlas.save("assets/sets/shapes/atlas.png")
    write_levels("game/data/sets/shapes.json", levels)


if __name__ == "__main__":
    main()
