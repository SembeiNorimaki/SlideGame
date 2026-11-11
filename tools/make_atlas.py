"""Build assets/shapes/shapes_atlas.png: letters A-Z, 5 columns, 64x64 cells, row by row."""
import string
from make_shapes import make_atlas

make_atlas(string.ascii_uppercase, columns=5).save("assets/shapes/shapes_atlas.png")
