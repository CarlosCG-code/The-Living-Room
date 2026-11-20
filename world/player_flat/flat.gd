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
var doors: Array[Door] = []
var _lights: Array[Light3D] = []


func _ready() -> void:
	living_room = LIVING_ROOM.instantiate()
	living_room.mirrored = mirrored
	add_child(living_room)
	var geometry := (load(GEOMETRY_MIRROR if mirrored else GEOMETRY) as PackedScene).instantiate()
	geometry.name = "FlatGeometry"
	add_child(geometry)
	# La hoja horneada en el glTF del salón la sustituye su Door (specs/hito4a.md D3).
	for leaf_name in ["DoorLeaf", "DoorHandle"]:
		var leaf := living_room.find_child(leaf_name, true, false)
		if leaf:
			leaf.free()
	for conn in LAYOUT.connections:
		if conn.kind == &"leaf":
			var door := Door.new()
			door.name = String(conn.id)
			add_child(door)
			door.setup(conn, mirrored)
			doors.append(door)
	_add_lamps()
	_add_acoustics()
	var backdrop := living_room.get_node("WindowBackdrop") as Node3D
	for zone in FACADE_WINDOWS:
		var marker := geometry.find_child("Window_" + zone, true, false) as Node3D
		if marker:
			var copy := backdrop.duplicate() as Node3D
			add_child(copy)
			copy.position.z = marker.position.z  # misma fachada que la ventana del salón: solo cambia a lo largo


func get_layout() -> FlatLayout:
	return LAYOUT


## Las del salón y las del resto del piso: todas pasan por el único LightMixer (specs/hito4a.md D8, D12).
func get_lights() -> Array[Light3D]:
	return living_room.get_lights() + _lights


# Eco de la casa: los sonidos 3D del piso (bus House) mandan parte al bus Room, la reverberación. El salón tiene
# su propia área (RoomAcoustics), con más prioridad.
func _add_acoustics() -> void:
	var r: Rect2 = LAYOUT.zones[0].rect
	for zone in LAYOUT.zones:
		r = r.merge(zone.rect)
	var area := Area3D.new()
	area.name = "FlatAcoustics"
	area.monitoring = false
	area.priority = -1
	area.reverb_bus_enabled = true
	area.reverb_bus_name = &"Room"
	area.reverb_bus_amount = 0.45
	area.reverb_bus_uniformity = 0.6
	var box := BoxShape3D.new()
	box.size = Vector3(r.size.x, 2.6, r.size.y)
	var shape := CollisionShape3D.new()
	shape.shape = box
	area.add_child(shape)
	var c := r.get_center()
	area.position = Vector3(-c.x if mirrored else c.x, 1.3, c.y)
	add_child(area)


# Lámparas de techo tenues, como los apliques del salón; se apagan con la distancia. Con sombra: sin ella la luz
# atraviesa los muros (usuario, 2026-11-20). Son pocas (LIT_ZONES de flat_layout.py) y la sombra se apaga antes.
func _add_lamps() -> void:
	for zone in LAYOUT.zones:
		for l: Dictionary in zone.lights:
			var lamp := OmniLight3D.new()
			lamp.name = "Lamp_%s" % zone.id
			var p: Vector3 = l["pos"]
			lamp.position = Vector3(-p.x if mirrored else p.x, p.y, p.z)
			lamp.light_color = l["color"]
			lamp.light_energy = l["energy"]
			lamp.omni_range = l["range"]
			lamp.omni_attenuation = 1.0
			lamp.light_specular = 0.0
			lamp.distance_fade_enabled = true
			lamp.distance_fade_begin = 12.0
			lamp.distance_fade_length = 4.0
			lamp.shadow_enabled = true
			lamp.distance_fade_shadow = 10.0
			lamp.light_size = 0.05  # como los apliques: LightMixer la usa para las sombras suaves
			lamp.set_meta(&"base_normal", l["base_normal"])
			lamp.set_meta(&"base_dark", l["base_dark"])
			add_child(lamp)
			_lights.append(lamp)
