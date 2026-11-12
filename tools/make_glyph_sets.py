"""Build the Symbols and Objects sets from font characters.

- Symbols: drawn with Inter Light, thin strokes like the Letters set.
- Objects: solid pictographs from DejaVu Sans, outlined like the Shapes set.

Usage (from the project root):  python3 tools/make_glyph_sets.py
Writes assets/sets/<set>/atlas.png and game/data/sets/<set>.json.
"""
import os

from levels_json import write_levels
from make_shapes import make_atlas, make_glyph, make_outlined_glyph

COLUMNS = 5

# (character, accepted answers per language). The first answer of each
# language is the main one; the rest are accepted synonyms.
SYMBOLS = [
    ("?", {"EN": ["question mark", "question"], "ES": ["interrogación", "signo de interrogación", "interrogante", "pregunta"]}),
    ("!", {"EN": ["exclamation mark", "exclamation point", "exclamation"], "ES": ["exclamación", "signo de exclamación", "admiración"]}),
    ("$", {"EN": ["dollar", "dollar sign"], "ES": ["dólar", "signo de dólar"]}),
    ("@", {"EN": ["at", "at sign"], "ES": ["arroba"]}),
    ("&", {"EN": ["ampersand", "and"], "ES": ["et", "ampersand", "y"]}),
    ("#", {"EN": ["hash", "hashtag", "number sign", "pound sign"], "ES": ["almohadilla", "numeral", "hashtag", "almohada"]}),
    ("%", {"EN": ["percent", "percentage", "per cent"], "ES": ["porcentaje", "por ciento"]}),
    ("+", {"EN": ["plus", "add"], "ES": ["más", "suma"]}),
    ("=", {"EN": ["equals", "equal", "equal sign", "equals sign"], "ES": ["igual", "signo igual"]}),
    ("€", {"EN": ["euro"], "ES": ["euro"]}),
    ("£", {"EN": ["pound", "pound sterling"], "ES": ["libra", "libra esterlina"]}),
    ("¥", {"EN": ["yen"], "ES": ["yen"]}),
    ("✓", {"EN": ["check", "check mark", "tick"], "ES": ["check", "visto", "tic", "marca de verificación"]}),
    ("©", {"EN": ["copyright"], "ES": ["copyright", "derechos de autor"]}),
    ("*", {"EN": ["asterisk", "star"], "ES": ["asterisco", "estrella"]}),
    ("∞", {"EN": ["infinity", "infinite"], "ES": ["infinito"]}),
    ("π", {"EN": ["pi"], "ES": ["pi"]}),
    ("÷", {"EN": ["divide", "division", "divided by"], "ES": ["división", "dividir", "entre"]}),
    ("±", {"EN": ["plus minus", "plus or minus"], "ES": ["más menos", "más o menos"]}),
    ("≠", {"EN": ["not equal", "not equals", "different"], "ES": ["distinto", "no igual", "diferente"]}),
    ("<", {"EN": ["less than", "smaller than"], "ES": ["menor que", "menor"]}),
    ("√", {"EN": ["square root", "root"], "ES": ["raíz", "raíz cuadrada"]}),
    ("Σ", {"EN": ["sigma", "sum"], "ES": ["sigma", "sumatorio", "suma"]}),
    ("Ω", {"EN": ["omega", "ohm"], "ES": ["omega", "ohmio"]}),
    ("ñ", {"EN": ["n tilde", "enye", "ene"], "ES": ["eñe"]}),
]

OBJECTS = [
    ("✂", {"EN": ["scissors"], "ES": ["tijeras", "tijera"]}),
    ("✈", {"EN": ["airplane", "plane", "aeroplane", "aircraft", "jet"], "ES": ["avión", "aeroplano"]}),
    ("✉", {"EN": ["envelope", "letter", "mail", "email"], "ES": ["sobre", "carta", "correo"]}),
    ("☎", {"EN": ["telephone", "phone"], "ES": ["teléfono"]}),
    ("⚓", {"EN": ["anchor"], "ES": ["ancla"]}),
    ("✏", {"EN": ["pencil"], "ES": ["lápiz"]}),
    ("☕", {"EN": ["coffee", "cup", "mug", "tea", "hot drink"], "ES": ["café", "taza", "té"]}),
    ("♠", {"EN": ["spade", "spades"], "ES": ["pica", "picas"]}),
    ("♣", {"EN": ["club", "clubs", "clover"], "ES": ["trébol", "tréboles"]}),
    ("❄", {"EN": ["snowflake", "snow", "flake"], "ES": ["copo de nieve", "copo", "nieve"]}),
    ("✿", {"EN": ["flower", "blossom"], "ES": ["flor"]}),
    ("⚙", {"EN": ["gear", "cog", "cogwheel", "settings"], "ES": ["engranaje", "rueda dentada", "piñón", "ajustes"]}),
    ("⚖", {"EN": ["scales", "scale", "balance", "justice"], "ES": ["balanza", "justicia"]}),
    ("⚑", {"EN": ["flag"], "ES": ["bandera"]}),
    ("♞", {"EN": ["knight", "horse"], "ES": ["caballo"]}),
    ("♜", {"EN": ["rook", "castle", "tower"], "ES": ["torre"]}),
    ("♚", {"EN": ["king"], "ES": ["rey"]}),
    ("♟", {"EN": ["pawn"], "ES": ["peón"]}),
    ("☠", {"EN": ["skull", "skull and crossbones", "pirate", "poison", "danger"], "ES": ["calavera", "pirata", "veneno", "peligro"]}),
    ("⚛", {"EN": ["atom"], "ES": ["átomo"]}),
    ("♻", {"EN": ["recycle", "recycling"], "ES": ["reciclaje", "reciclar"]}),
    ("⚔", {"EN": ["swords", "crossed swords", "sword"], "ES": ["espadas", "espada", "espadas cruzadas"]}),
    ("⌨", {"EN": ["keyboard"], "ES": ["teclado"]}),
    ("☯", {"EN": ["yin yang", "yinyang"], "ES": ["yin yang", "yin y yang"]}),
    ("✌", {"EN": ["peace", "victory", "peace sign", "v sign"], "ES": ["paz", "victoria", "signo de paz"]}),
]


def build(set_id, items, render):
    os.makedirs(f"assets/sets/{set_id}", exist_ok=True)
    make_atlas([render(ch) for ch, _ in items], columns=COLUMNS).save(f"assets/sets/{set_id}/atlas.png")
    write_levels(f"game/data/sets/{set_id}.json", [
        {"atlas_coords": [i % COLUMNS, i // COLUMNS], "solution": solution}
        for i, (_ch, solution) in enumerate(items)
    ])


if __name__ == "__main__":
    build("symbols", SYMBOLS, make_glyph)
    build("objects", OBJECTS, make_outlined_glyph)
