"""Build the Letters set: assets/sets/letters/atlas.png (A-Z, 5 columns,
64x64 cells, row by row) and game/data/sets/letters.json.

Usage (from the project root):  python3 tools/make_atlas.py
"""
import string

from levels_json import write_levels
from make_shapes import make_atlas

COLUMNS = 5
LETTERS = string.ascii_uppercase

make_atlas(LETTERS, columns=COLUMNS).save("assets/sets/letters/atlas.png")
write_levels("game/data/sets/letters.json", [
    {"atlas_coords": [i % COLUMNS, i // COLUMNS], "solution": {"EN": [ch], "ES": [ch]}}
    for i, ch in enumerate(LETTERS)
])
