class_name ShapeAtlas
extends RefCounted
## Cuts a 64x64 shape out of the shapes atlas.

const TEXTURE := preload("res://assets/shapes/shapes_atlas.png")
const CELL := Vector2i(64, 64)


## coords: cell (column, row) as given by atlas_coords in levels.json.
static func texture_at(coords: Vector2i) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas = TEXTURE
	tex.region = Rect2(Vector2(coords * CELL), Vector2(CELL))
	return tex
