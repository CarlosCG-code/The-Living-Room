extends Node3D

# Piso del jugador (specs/hito4a.md D4): el salón (living_room.tscn, igual que antes) y el resto del piso,
# construido por tools/blender/build_flat.py a partir de data/flat_layout.tres.

const LIVING_ROOM := preload("res://world/player_flat/living_room.tscn")
const GEOMETRY := "res://assets/models/living_room/flat.gltf"
const GEOMETRY_MIRROR := "res://assets/models/living_room/flat_mirror.gltf"
const LAYOUT: FlatLayout = preload("res://data/flat_layout.tres")
## Ventanas de fachada: llevan el fondo de ciudad del salón (las del patio de luces dan a la oscuridad).
const FACADE_WINDOWS: Array[StringName] = [&"bedroom_main", &"dining_room", &"workshop"]

## Se fija antes de añadir la escena al árbol.
@export var mirrored := false

var living_room: Node3D


func _ready() -> void:
	living_room = LIVING_ROOM.instantiate()
	living_room.mirrored = mirrored
	add_child(living_room)
	var geometry := (load(GEOMETRY_MIRROR if mirrored else GEOMETRY) as PackedScene).instantiate()
	geometry.name = "FlatGeometry"
	add_child(geometry)
	# shortcut: sin la hoja horneada del salón la puerta queda abierta; la sustituye una Door en el paso 4.
	for leaf_name in ["DoorLeaf", "DoorHandle"]:
		var leaf := living_room.find_child(leaf_name, true, false)
		if leaf:
			leaf.queue_free()
	var backdrop := living_room.get_node("WindowBackdrop") as Node3D
	for zone in FACADE_WINDOWS:
		var marker := geometry.find_child("Window_" + zone, true, false) as Node3D
		if marker:
			var copy := backdrop.duplicate() as Node3D
			add_child(copy)
			copy.position.z = marker.position.z  # misma fachada que la ventana del salón: solo cambia a lo largo


func get_layout() -> FlatLayout:
	return LAYOUT
