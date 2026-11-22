extends Node3D

# Piso del jugador (specs/hito4a.md D4): el salón (living_room.tscn, igual que antes) y el resto del piso,
# construido por tools/blender/build_flat.py a partir de data/flat_layout.tres.

const LIVING_ROOM := preload("res://world/player_flat/living_room.tscn")
const GEOMETRY := "res://assets/models/living_room/flat.gltf"
const GEOMETRY_MIRROR := "res://assets/models/living_room/flat_mirror.gltf"
const LAYOUT: FlatLayout = preload("res://data/flat_layout.tres")
## Ventanas de fachada: llevan el fondo de ciudad del salón (las del patio de luces dan a la oscuridad).
const LIVING_LAYER := 1 << 1
const FACADE_WINDOWS: Array[StringName] = [&"bedroom_main", &"dining_room", &"workshop"]
## La farola por las ventanas que no son la del salón: más tenue, para que esos cuartos sigan casi a oscuras.
const STREET_COPY := 0.6
## Lo que el tapón de cada muro queda por dentro de sus bordes (m).
const OCCLUDER_INSET := 0.05

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
	# Las lámparas (Fixture_*, furnish_flat.py) no dan sombra: su luz va dentro y si no quedaría tapada.
	for m: MeshInstance3D in geometry.find_children("Fixture_*", "MeshInstance3D", true, false):
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# El cristal tampoco: tapaba la luz de la farola en los cuartos de la fachada.
	for m: MeshInstance3D in geometry.find_children("WindowGlass_*", "MeshInstance3D", true, false):
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for conn in LAYOUT.connections:
		if conn.kind == &"leaf":
			var door := Door.new()
			door.name = String(conn.id)
			add_child(door)
			door.setup(conn, mirrored)
			doors.append(door)
	_add_lamps(geometry)
	_add_occluder(geometry)
	_keep_living_light_inside()
	_add_mirrors(geometry)
	_add_acoustics()
	var backdrop := living_room.get_node("WindowBackdrop") as Node3D
	for zone in FACADE_WINDOWS:
		var marker := geometry.find_child("Window_" + zone, true, false) as Node3D
		if marker:
			var copy := backdrop.duplicate() as Node3D
			add_child(copy)
			copy.position.z = marker.position.z  # misma fachada que la ventana del salón: solo cambia a lo largo
			_add_street_light(marker.position.z)


func get_layout() -> FlatLayout:
	return LAYOUT


# Espejos de verdad (PlanarMirror) sobre el cristal de cada Mirror_<zona> (material «Mirror», furnish_flat.py y
# build_living_room.py). La cara buena es la que da a su habitación.
func _add_mirrors(geometry: Node) -> void:
	for root: Node in [living_room, geometry]:
		for m: MeshInstance3D in root.find_children("Mirror_*", "MeshInstance3D", true, false):
			var glass := _glass_box(m)
			var zone: ZoneDef = LAYOUT.find_zone(StringName(String(m.name).trim_prefix("Mirror_")))
			if glass.size == Vector3.ZERO or zone == null:
				continue
			var c := zone.rect.get_center()
			var inside := Vector3(-c.x if mirrored else c.x, 0.0, c.y)
			var thin := Vector3.AXIS_X if glass.size.x < glass.size.z else Vector3.AXIS_Z
			var normal := Vector3.ZERO
			normal[thin] = signf(inside[thin] - glass.get_center()[thin])
			var mirror := PlanarMirror.new()
			mirror.name = "PlanarMirror_%s" % zone.id
			add_child(mirror)
			mirror.setup(glass.get_center(), normal, Vector2(glass.size[2 - thin], glass.size.y))


# Caja global de la superficie con el material «Mirror» (el marco va en la misma malla).
func _glass_box(m: MeshInstance3D) -> AABB:
	for i in m.mesh.get_surface_count():
		var mat := m.get_active_material(i)
		if mat and mat.resource_name == "Mirror":
			var verts: PackedVector3Array = m.mesh.surface_get_arrays(i)[Mesh.ARRAY_VERTEX]
			var box := AABB(m.global_transform * verts[0], Vector3.ZERO)
			for v in verts:
				box = box.expand(m.global_transform * v)
			return box
	return AABB()


# Las lámparas sin sombra del salón (apliques y lámpara de mesa) solo alumbran lo del salón: sin sombra, su luz
# cruzaba las paredes hasta el pasillo y los cuartos de al lado (usuario, 2026-11-22). Con sombra el salón quedaba
# mucho más oscuro; con capas cuesta nada. El salón y la hoja de su puerta van también en la capa 2.
func _keep_living_light_inside() -> void:
	for g: GeometryInstance3D in living_room.find_children("*", "GeometryInstance3D", true, false):
		g.layers |= LIVING_LAYER
	for door in doors:
		if door.name == "door_living":
			for g: GeometryInstance3D in door.find_children("*", "GeometryInstance3D", true, false):
				g.layers |= LIVING_LAYER
	for light in living_room.get_lights():
		if not light.shadow_enabled:
			light.light_cull_mask = LIVING_LAYER


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


# La farola de la calle entra también por las otras ventanas de la fachada: luz fría que deja ver siluetas en los
# cuartos a oscuras sin alumbrarlos (usuario, 2026-11-22: luces que den miedo). Más tenue que en el salón.
func _add_street_light(z: float) -> void:
	var street := living_room.get_node("StreetLight") as SpotLight3D
	var copy := street.duplicate() as SpotLight3D
	copy.name = "StreetLight_%d" % _lights.size()
	copy.remove_from_group(&"room_lights")
	add_child(copy)
	copy.position.z = z
	copy.distance_fade_enabled = true
	copy.distance_fade_begin = 12.0
	copy.distance_fade_length = 4.0
	for key: StringName in [&"base_normal", &"base_dark"]:
		copy.set_meta(key, float(street.get_meta(key)) * STREET_COPY)
	_lights.append(copy)


# Lámparas tenues, como los apliques del salón; se apagan con la distancia. Con sombra: sin ella la luz atraviesa
# los muros (usuario, 2026-11-20). Son pocas (LIT_ZONES de flat_layout.py) y la sombra se apaga antes. Si la zona
# tiene una lámpara propia (vacío LampAt_<zona> del glTF), la luz sale de ella; si no, del techo.
func _add_lamps(geometry: Node) -> void:
	for zone in LAYOUT.zones:
		for l: Dictionary in zone.lights:
			var lamp := OmniLight3D.new()
			lamp.name = "Lamp_%s" % zone.id
			var p: Vector3 = l["pos"]
			lamp.position = Vector3(-p.x if mirrored else p.x, p.y, p.z)
			var at := geometry.find_child("LampAt_" + String(zone.id), true, false) as Node3D
			if at:
				lamp.position = to_local(at.global_position)
			lamp.light_color = l["color"]
			lamp.light_energy = l["energy"]
			lamp.omni_range = l["range"]
			lamp.omni_attenuation = 1.0
			lamp.light_specular = 0.0
			lamp.distance_fade_enabled = true
			lamp.distance_fade_begin = 12.0
			lamp.distance_fade_length = 4.0
			lamp.shadow_enabled = true
			lamp.distance_fade_shadow = 16.0  # sombra mientras haya luz: a 10 m se apagaba antes y la luz cruzaba los muros
			lamp.light_size = 0.05  # como los apliques: LightMixer la usa para las sombras suaves
			lamp.set_meta(&"base_normal", l["base_normal"])
			lamp.set_meta(&"base_dark", l["base_dark"])
			add_child(lamp)
			_lights.append(lamp)

# Oclusión: los muros tapan lo que hay detrás y no se dibuja (las sombras y la GI no cambian: no la usan).
# Cada muro (una caja) tapa con un rectángulo en su plano medio, algo más pequeño que él: en su cara, el cálculo
# aproximado de Godot escondía a ratos lo colgado en la pared al moverse (el espejo salía sin reflejo, 2026-11-22).
func _add_occluder(geometry: Node) -> void:
	var walls := geometry.find_children("Wall_*", "MeshInstance3D", true, false)
	walls.append_array(geometry.find_children("Lintel_*", "MeshInstance3D", true, false))
	walls.append_array(living_room.find_children("Wall*", "MeshInstance3D", true, false))
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	for m: MeshInstance3D in walls:
		var box := global_transform.affine_inverse() * m.global_transform * m.get_aabb()
		var along := 0 if box.size.z <= box.size.x else 2  # el eje largo en planta; el corto es el grosor
		var half := Vector3.ZERO
		half[along] = box.size[along] / 2.0 - OCCLUDER_INSET
		half.y = box.size.y / 2.0 - OCCLUDER_INSET
		if half[along] <= 0.0 or half.y <= 0.0:
			continue
		var c := box.get_center()
		var base := vertices.size()
		var side := Vector3.ZERO
		side[along] = half[along]
		vertices.append_array([c - side - Vector3(0, half.y, 0), c + side - Vector3(0, half.y, 0),
				c + side + Vector3(0, half.y, 0), c - side + Vector3(0, half.y, 0)])
		indices.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
	var occluder := ArrayOccluder3D.new()
	occluder.set_arrays(vertices, indices)
	var instance := OccluderInstance3D.new()
	instance.name = "WallOccluder"
	instance.occluder = occluder
	add_child(instance)
