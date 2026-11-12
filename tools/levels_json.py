"""Writes a set's levels file: one level per line, UTF-8, accents kept."""
import json
import os


def write_levels(path, levels):
    """levels: list of {"atlas_coords": [col, row], "solution": {"EN": [...], ...}}"""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    lines = ",\n".join("    " + json.dumps(l, ensure_ascii=False) for l in levels)
    with open(path, "w", encoding="utf-8") as f:
        f.write('{\n  "levels": [\n' + lines + "\n  ]\n}\n")
