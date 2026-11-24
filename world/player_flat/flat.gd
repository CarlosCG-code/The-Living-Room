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

## Hasta dónde se busca la luz de una bombilla alrededor de ella (m).
const GLOW_REACH := 0.35

## Sitios del salón de los que sale un suceso, sin reflejar: techo, pared frente al sofá, suelo detrás del sofá y
## mecedora (build_living_room.py).
const LIVING_PLACES := {&"ceiling": Vector3(0.0, 2.6, 0.0), &"wall": Vector3(0.0, 1.3, 2.5),
		&"behind_sofa": Vector3(0.0, 0.1, -2.35), &"rocking_chair": Vector3(0.95, 0.4, 1.95)}

## De qué sale en las demás habitaciones lo que no se cae, sin reflejar: mesilla, lavabo, bajante de la cisterna, mesa del comedor
## y el muro del pasillo (tuberías).
const ROOM_PLACES := {&"bedroom_main": Vector3(1.45, 0.7, 6.65), &"bathroom": Vector3(-5.2, 0.95, 1.8),
		&"service_toilet": Vector3(-11.4, 1.5, -8.98), &"dining_room": Vector3(0.45, 0.9, -4.83),
		&"corridor_main_m": Vector3(-2.25, 1.3, -0.1), &"wardrobe": Vector3(-0.35, 1.75, 3.65)}
## Boca del grifo del baño que gotea, sin reflejar, y lo que cae la gota hasta la loza (furnish_flat.py, basin y tap).
const DRIP := Vector3(-5.06, 0.9, 1.875)
const DRIP_HEIGHT := 0.129
const WARDROBE_DOOR := "GothicCabinet_01*door1"
const WARDROBE_ANGLE := deg_to_rad(50.0)

## Lo que se cae con un suceso: con qué empieza el nombre de sus nodos (furnish_flat.py) y dónde acaba en el suelo (x, z),
## sin reflejar.
const PROPS := {
	&"spoon": {"MetalSpoon": Vector2(-9.3, -4.42)},
	&"tool": {"cross_pein_hammer": Vector2(0.25, -9.5), "adjustable_wrench": Vector2(-0.75, -9.35),
			"pipe_wrench": Vector2(-3.7, -9.55), "tongue_groove_pliers": Vector2(-4.07, -9.6)},
	&"book": {"old_book_red": Vector2(-4.86, -2.6)},
	&"bath_fall": {"lambis_shell": Vector2(-3.9, 0.15)},
}
## La mecedora rueda sobre sus patines: hacia dónde mira, a cuánto de su origen se apoya y con qué radio (de su malla).
const ROCK_FACING := Vector3(-0.342, 0.0, -0.94)
const ROCK_CONTACT := 0.12
const ROCK_RADIUS := 1.2
const ROCK_ANGLE := deg_to_rad(7.0)
const ROCK_PERIOD := 2.1  # s, como en la grabación

## Se fija antes de añadir la escena al árbol.
@export var mirrored := false

var living_room: Node3D
var doors: Array[Door] = []
var props := {}  # id de suceso -> Array[FallingProp]
var _lights: Array[Light3D] = []
var _chair: Node3D
var _chair_rest: Transform3D
var _wardrobe := Node3D.new()  # en los pernios de la puerta


func _ready() -> void:
	living_room = LIVING_ROOM.instantiate()
	living_room.mirrored = mirrored
	add_child(living_room)
	_chair = living_room.find_child("Rockingchair_01", true, false)
	_chair_rest = _chair.transform
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
	_add_props(geometry)
	_add_wardrobe(geometry)
	var drip := Drip.new()
	drip.position = Vector3(-DRIP.x if mirrored else DRIP.x, DRIP.y, DRIP.z)
	add_child(drip)
	drip.setup(DRIP_HEIGHT)
	_add_lamps(geometry)
	_link_glow()
	_add_occluder(geometry)
	_keep_living_light_inside()
	_add_mirrors(geometry)
	_add_acoustics()
	_fit_dust()
	var backdrop := living_room.get_node("WindowBackdrop") as Node3D
	for zone in FACADE_WINDOWS:
		var marker := geometry.find_child("Window_" + zone, true, false) as Node3D
		if marker:
			var copy := backdrop.duplicate() as Node3D
			add_child(copy)
			copy.position.z = marker.position.z  # misma fachada que la ventana del salón: solo cambia a lo largo
			# Se solapan: en el mismo plano ganaba uno u otro según el orden de dibujo.
			copy.position.x += signf(copy.position.x) * 0.01 * (FACADE_WINDOWS.find(zone) + 1)
			_add_street_light(marker.position.z)


func get_layout() -> FlatLayout:
	return LAYOUT


## De dónde sale el sonido de un suceso (specs/hito3.md D4): un mueble de la zona (o su centro), una hoja (0,4 m hacia
## zone_a), o un punto del salón (LIVING_PLACES).
func get_place(id: StringName) -> Vector3:
	var p := _place(id)
	return Vector3(-p.x if mirrored else p.x, p.y, p.z)


## Zona de un lugar; &"" en los del salón, que suenan aunque el jugador esté allí.
func get_place_zone(id: StringName) -> StringName:
	if LIVING_PLACES.has(id):
		return &""
	var p := _place(id)
	return LAYOUT.zone_at(Vector2(p.x, p.z), false)


# Sin reflejar.
func _place(id: StringName) -> Vector3:
	if LIVING_PLACES.has(id):
		return LIVING_PLACES[id]
	if ROOM_PLACES.has(id):
		return ROOM_PLACES[id]
	var zone := LAYOUT.find_zone(id)
	if zone:
		var c := zone.rect.get_center()
		return Vector3(c.x, 1.0, c.y)
	for conn in LAYOUT.connections:
		if conn.id == id and conn.kind == &"leaf":
			var leaf := conn.hinge + conn.direction * conn.width / 2.0
			return Vector3(leaf.x, 1.0, leaf.z) + Vector3.UP.cross(conn.direction) * conn.swing * 0.4
	push_error("Lugar desconocido: %s" % id)
	return Vector3.ZERO


func _add_props(geometry: Node) -> void:
	for event: StringName in PROPS:
		props[event] = []
		for start: String in PROPS[event]:
			var spot: Vector2 = PROPS[event][start]
			var prop := FallingProp.new()
			prop.name = "Prop_" + start
			add_child(prop)
			prop.setup(geometry.find_children(start + "*", "MeshInstance3D", true, false), Vector2(-spot.x if mirrored else spot.x, spot.y))
			props[event].append(prop)


func _add_wardrobe(geometry: Node) -> void:
	var leaf: MeshInstance3D = geometry.find_children(WARDROBE_DOOR, "MeshInstance3D", true, false)[0]
	leaf.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC  # no deja su sombra horneada al abrirse
	var box := leaf.global_transform * leaf.get_aabb()
	_wardrobe.position = Vector3(box.end.x if mirrored else box.position.x, 0.0, box.position.z + 0.04)
	add_child(_wardrobe)
	leaf.reparent(_wardrobe)


## Lo que se cae con ese suceso, o null. Uno ya caído vuelve a su sitio, pero nunca a la vista del jugador.
func pick_prop(event: StringName) -> FallingProp:
	var ready: Array = props.get(event, []).filter(func(p: FallingProp) -> bool: return not p.fallen)
	if ready.is_empty():
		ready = props.get(event, []).filter(func(p: FallingProp) -> bool: return not _in_sight(p.global_position))
	return null if ready.is_empty() else ready.pick_random()


func _in_sight(p: Vector3) -> bool:
	var cam := get_viewport().get_camera_3d()
	return cam != null and cam.is_position_in_frustum(p) 			and SoundOcclusion.obstacles(get_world_3d().direct_space_state, cam.global_position, p, 1) == 0


## Mueve lo que suena sin caerse: una puerta, la del armario (se abre o, si ya lo está, se cierra) o la mecedora.
func stir(place: StringName, seconds: float) -> void:
	for door in doors:
		if door.id == place:
			door.creep(seconds)
	if place == &"wardrobe":
		var open := WARDROBE_ANGLE if mirrored else -WARDROBE_ANGLE
		create_tween().tween_property(_wardrobe, "rotation:y", 0.0 if _wardrobe.rotation.y else open, seconds).set_trans(Tween.TRANS_SINE)
	if place == &"rocking_chair":
		create_tween().tween_method(_rock.bind(seconds), 0.0, seconds, seconds)


func _rock(t: float, seconds: float) -> void:
	var swing := ROCK_ANGLE * minf(1.0, minf(t, seconds - t) / 2.0) * sin(TAU * t / ROCK_PERIOD)
	var facing := Vector3(-ROCK_FACING.x if mirrored else ROCK_FACING.x, 0.0, ROCK_FACING.z)
	var rest := facing * ROCK_CONTACT + Vector3.UP * ROCK_RADIUS
	_chair.transform = _chair_rest * Transform3D(Basis.IDENTITY, rest + facing * ROCK_RADIUS * swing) 			* Transform3D(Basis(Vector3.UP.cross(facing), swing), Vector3.ZERO) * Transform3D(Basis.IDENTITY, -rest)


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
	var r := _bounds()
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


# Polvo en suspensión por todo el piso (usuario, 2026-11-23). Lo alumbran las lámparas y la linterna: a oscuras no se ve.
func _fit_dust() -> void:
	var r := _bounds()
	var half := Vector3(r.size.x / 2.0, 1.3, r.size.y / 2.0)
	var c := r.get_center()
	var dust := $Dust as GPUParticles3D
	dust.position = Vector3(-c.x if mirrored else c.x, 1.3, c.y)
	dust.visibility_aabb = AABB(-half, half * 2.0)
	(dust.process_material as ParticleProcessMaterial).emission_box_extents = half


## Posición de la luz de la tele: dust.gdshader la atenúa.
func set_tv_light(position_3d: Vector3) -> void:
	((($Dust as GPUParticles3D).draw_pass_1 as QuadMesh).material as ShaderMaterial).set_shader_parameter("tv_position", position_3d)


func _bounds() -> Rect2:
	var r: Rect2 = LAYOUT.zones[0].rect
	for zone in LAYOUT.zones:
		r = r.merge(zone.rect)
	return r


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
			# Sin light_size: las sombras suaves por contacto (PCSS) salían dentadas con el mapa de sombra de cada lámpara.
			lamp.set_meta(&"base_normal", l["base_normal"])
			lamp.set_meta(&"base_dark", l["base_dark"])
			add_child(lamp)
			_lights.append(lamp)


# Lo que se ve encendido (bombillas, cristales, pantallas) brilla solo si su luz da luz (usuario, 2026-11-24): su material
# queda en el metadato «glow» de la luz que tiene dentro y LightMixer lo sube y baja con ella. Sin luz dentro, no brilla.
func _link_glow() -> void:
	for root: Node in [living_room, get_node(^"FlatGeometry")]:
		for m: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
			for i in m.mesh.get_surface_count():
				var lit := m.get_active_material(i) as BaseMaterial3D
				if lit == null or not lit.emission_enabled:
					continue
				var material := lit.duplicate() as BaseMaterial3D  # el original lo comparten otras lámparas
				m.set_surface_override_material(i, material)
				var box := (m.global_transform * m.get_aabb()).grow(GLOW_REACH)
				var lights := get_lights().filter(func(l: Light3D) -> bool: return l is OmniLight3D and box.has_point(l.global_position))
				if lights.is_empty():
					material.emission_enabled = false
					continue
				material.set_meta(&"base_energy", material.emission_energy_multiplier)
				lights[0].set_meta(&"glow", lights[0].get_meta(&"glow", []) + [material])


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
