class_name ZoneDef
extends Resource

# Una habitación o un tramo de pasillo del piso (specs/hito4a.md §5). Lo genera tools/blender/flat_layout.py.

@export var id: StringName
@export var name_key := ""
## Interior en planta (x, z de Godot), sin reflejar.
@export var rect: Rect2
@export var floor_type: StringName = &"wood"
## Lámparas: pos, color, energy, range, base_normal, base_dark.
@export var lights: Array[Dictionary] = []
