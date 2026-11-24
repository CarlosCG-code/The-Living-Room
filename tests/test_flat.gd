extends GutTest

# El piso montado (specs/hito4a.md §7): una Door por hoja y, en espejo, cada hoja es el reflejo de la normal.

const FLAT := preload("res://world/player_flat/flat.tscn")


func _flat(mirrored: bool) -> Node3D:
	var f := FLAT.instantiate()
	f.mirrored = mirrored
	add_child_autofree(f)
	return f


func test_one_door_per_leaf() -> void:
	var f: Node3D = _flat(false)
	var leaves: Array = f.get_layout().connections.filter(func(c: ConnectionDef) -> bool: return c.kind == &"leaf")
	assert_eq(f.doors.size(), leaves.size())
	for m: MeshInstance3D in f.find_children("*", "MeshInstance3D", true, false):
		if m.name != &"WindowBackdrop":  # sin luz: le da igual
			assert_gt(m.global_basis.determinant(), 0.0, "%s: la escala negativa invierte su luz" % m.name)
	assert_null(f.living_room.find_child("DoorLeaf", true, false), "la hoja horneada del salón ya no está")


func test_mirrored_leaf_is_reflection_of_normal_leaf() -> void:
	var normal: Node3D = _flat(false)
	var mirror: Node3D = _flat(true)
	for i in normal.doors.size():
		var a: Door = normal.doors[i]
		var b: Door = mirror.doors[i]
		for deg in [0.0, 35.0, 90.0]:
			a.angle = deg_to_rad(deg)
			b.angle = deg_to_rad(deg)
			a._apply_angle()
			b._apply_angle()
			# Lo que se ve: el centro de la hoja y su canto del pestillo, reflejados en x.
			for p in [_leaf_center(a), a._latch_at(a.angle)]:
				var i_b: Vector3 = _leaf_center(b) if p == _leaf_center(a) else b._latch_at(b.angle)
				assert_almost_eq(i_b, Vector3(-p.x, p.y, p.z), Vector3.ONE * 0.001, "%s a %d°" % [a.id, deg])


## Cada malla y cada colisión del piso en espejo ocupa el sitio reflejado de la normal (un objeto girado se reflejaba
## sobre su propio eje y acababa dentro del muro: repisas, alacena, retrete).
func test_mirrored_geometry_is_reflection_of_normal() -> void:
	var normal: Node3D = _flat(false)
	var mirror: Node3D = _flat(true)
	var checked := 0
	for path: NodePath in [^"FlatGeometry", ^"LivingRoom/Geometry"]:
		for type: String in ["MeshInstance3D", "CollisionShape3D"]:
			for a: Node3D in normal.get_node(path).find_children("*", type, true, false):
				var b := mirror.get_node_or_null(String(path) + "/" + String(normal.get_node(path).get_path_to(a))) as Node3D
				if b == null:
					fail_test("falta %s en el espejo" % a.name)
					continue
				var box_a := _world_box(a)
				var box_b := _world_box(b)
				var c := box_a.get_center()
				checked += 1
				if box_b.get_center().distance_to(Vector3(-c.x, c.y, c.z)) > 0.01 or (box_b.size - box_a.size).length() > 0.02:
					fail_test("%s: %s frente a %s" % [a.name, box_b, box_a])
	assert_gt(checked, 500)


## Las normales y la textura de cada malla, también reflejadas (Blender estropeaba las normales al reflejar y la luz salía distinta).
func test_mirrored_normals_and_uvs_are_reflection_of_normal() -> void:
	var normal: Node3D = _flat(false)
	var mirror: Node3D = _flat(true)
	var seen := {}
	var total := 0
	var bad_uv := 0
	var bad_normal := 0
	for path: NodePath in [^"FlatGeometry", ^"LivingRoom/Geometry"]:
		for a: MeshInstance3D in normal.get_node(path).find_children("*", "MeshInstance3D", true, false):
			if seen.has(a.mesh):
				continue
			seen[a.mesh] = true
			var b := mirror.get_node(String(path) + "/" + String(normal.get_node(path).get_path_to(a))) as MeshInstance3D
			for s in a.mesh.get_surface_count():
				var va := _vertices(a, s, 1.0)
				var vb := _vertices(b, s, -1.0)
				for key: String in va:
					total += 1
					if not vb.has(key):
						bad_uv += 1
					elif not va[key].any(func(n: Vector3) -> bool: return vb[key].any(func(m: Vector3) -> bool: return n.dot(m) > 0.98)):
						bad_normal += 1
	assert_gt(total, 100000)
	assert_lt(float(bad_uv) / total, 0.02, "posición y textura")
	assert_lt(float(bad_normal) / total, 0.005, "normales")


## Posición en el mundo y UV (redondeadas) -> normales que hay ahí.
func _vertices(m: MeshInstance3D, surface: int, x_sign: float) -> Dictionary:
	var arrays := m.mesh.surface_get_arrays(surface)
	var flip := Vector3(x_sign, 1.0, 1.0)
	var out := {}
	if arrays[Mesh.ARRAY_TEX_UV] == null:
		return out
	for i: int in range(0, arrays[Mesh.ARRAY_VERTEX].size()):
		var p: Vector3 = (m.global_transform * arrays[Mesh.ARRAY_VERTEX][i]) * flip
		var uv: Vector2 = arrays[Mesh.ARRAY_TEX_UV][i]
		var key := "%d,%d,%d,%d,%d" % [roundi(p.x * 300), roundi(p.y * 300), roundi(p.z * 300), roundi(uv.x * 100), roundi(uv.y * 100)]
		if not out.has(key):
			out[key] = []
		out[key].append(((m.global_basis * arrays[Mesh.ARRAY_NORMAL][i]).normalized()) * flip)
	return out


## Luces, sonidos, zonas de eco, sondas, partículas y anclas: todo lo que no es malla, también en su sitio reflejado.
func test_mirrored_nodes_are_reflection_of_normal() -> void:
	var normal: Node3D = _flat(false)
	var mirror: Node3D = _flat(true)
	var checked := 0
	for type: String in ["Light3D", "AudioStreamPlayer3D", "Area3D", "ReflectionProbe", "VoxelGI", "GPUParticles3D", "Marker3D", "Camera3D"]:
		# Por orden y no por ruta: los nombres automáticos no coinciden.
		var all_a := normal.find_children("*", type, true, false)
		var all_b := mirror.find_children("*", type, true, false)
		assert_eq(all_b.size(), all_a.size(), type)
		for i in mini(all_a.size(), all_b.size()):
			var a: Node3D = all_a[i]
			var b: Node3D = all_b[i]
			checked += 1
			var p := a.global_position
			assert_almost_eq(b.global_position, Vector3(-p.x, p.y, p.z), Vector3.ONE * 0.001, a.name)
			var forward := a.global_basis.z
			if a is AudioStreamPlayer3D:  # suenan igual hacia todos lados
				continue
			assert_almost_eq(b.global_basis.z, Vector3(-forward.x, forward.y, forward.z), Vector3.ONE * 0.001, "%s: hacia dónde mira" % a.name)
			if a is Light3D:
				assert_eq((b as Light3D).light_energy, (a as Light3D).light_energy, a.name)
				assert_eq((b as Light3D).light_cull_mask, (a as Light3D).light_cull_mask, a.name)
	assert_gt(checked, 50)
	var wind: Array = [normal, mirror].map(func(f: Node3D) -> Vector3: return (f.living_room.get_node("Rain").process_material as ParticleProcessMaterial).gravity)
	assert_almost_eq(wind[1], Vector3(-wind[0].x, wind[0].y, wind[0].z), Vector3.ONE * 0.001, "viento de la lluvia")


## Cada lámpara enciende sus bombillas y nada brilla sin una luz dentro.
func test_only_lit_lamps_glow() -> void:
	for mirrored in [false, true]:
		var f: Node3D = _flat(mirrored)
		var glowing := []
		for light: Light3D in f.get_lights():
			if light is OmniLight3D:
				assert_gt((light.get_meta(&"glow", []) as Array).size(), 0, "%s sin bombilla" % light.name)
				glowing.append_array(light.get_meta(&"glow", []))
		for m: MeshInstance3D in f.find_children("*", "MeshInstance3D", true, false):
			for s in m.mesh.get_surface_count():
				var material := m.get_active_material(s) as BaseMaterial3D
				if material and material.emission_enabled:
					assert_has(glowing, material, "%s brilla sin luz (espejo: %s)" % [m.name, mirrored])


## La ciudad de las ventanas también: cada punto del plano queda en su sitio reflejado.
func test_mirrored_backdrop_is_reflection_of_normal() -> void:
	var a := _flat(false).living_room.get_node("WindowBackdrop") as Node3D
	var b := _flat(true).living_room.get_node("WindowBackdrop") as Node3D
	var p := a.global_transform * Vector3(1.0, 1.0, 0.0)
	assert_almost_eq(b.global_transform * Vector3(1.0, 1.0, 0.0), Vector3(-p.x, p.y, p.z), Vector3.ONE * 0.001)


func _world_box(n: Node3D) -> AABB:
	if n is MeshInstance3D:
		return n.global_transform * (n as MeshInstance3D).get_aabb()
	return n.global_transform * (n as CollisionShape3D).shape.get_debug_mesh().get_aabb()


func _leaf_center(d: Door) -> Vector3:
	var col := d.get_node("Leaf").find_children("*", "CollisionShape3D", true, false)[0] as CollisionShape3D
	return col.global_position


## La hoja cerrada queda enrasada con la cara del marco del lado hacia el que abre, dentro del hueco.
func test_closed_leaf_sits_flush_in_the_opening() -> void:
	var f: Node3D = _flat(false)
	for d: Door in f.doors:
		var conn: ConnectionDef = f.get_layout().connections.filter(func(c: ConnectionDef) -> bool: return c.id == d.id)[0]
		var into_a := (d._latch_at(0.001) - d._latch_at(0.0)).normalized()  # hacia donde abre: zona_a
		var c := _leaf_center(d) - conn.hinge
		var mid := conn.direction.normalized() * conn.width / 2.0
		assert_almost_eq(c.dot(conn.direction.normalized()), mid.length(), 0.01, "%s: centrada en el hueco" % d.id)
		assert_almost_eq(c.dot(into_a), Door.FACE - Door.THICKNESS / 2.0, 0.01, "%s: hacia zona_a" % d.id)


## Ningún mueble (furnish_flat.py) queda en el giro de una hoja: todas abren hasta 90°, también en espejo.
func test_doors_open_without_hitting_furniture() -> void:
	for mirrored in [false, true]:
		var f: Node3D = _flat(mirrored)
		await get_tree().physics_frame
		await get_tree().physics_frame
		for d: Door in f.doors:
			if d.locked:
				continue
			for deg in [30.0, 60.0, 90.0]:
				assert_false(d._blocked(deg_to_rad(deg)), "%s a %d° (espejo: %s)" % [d.id, deg, mirrored])
		remove_child(f)  # los dos pisos se solapan en el espacio: el siguiente se prueba solo
		await get_tree().physics_frame


func test_locked_front_door_does_not_grab() -> void:
	var f: Node3D = _flat(false)
	var front: Door = f.get_node("door_front")
	assert_true(front.locked)
	assert_false(front.try_grab(Vector3.ZERO))


func test_sound_occlusion_counts_walls_not_furniture() -> void:
	var f: Node3D = _flat(false)
	await wait_physics_frames(2)
	var space := (f as Node3D).get_world_3d().direct_space_state
	var rain := (f.living_room.get_node("RainSound") as Node3D).global_position
	var sofa := (f.living_room.get_node("Anchors/SeatAnchor") as Node3D).global_position + Vector3.UP * 0.5
	assert_eq(SoundOcclusion.obstacles(space, sofa, rain), 0, "dentro del salón la lluvia se oye")
	assert_gt(SoundOcclusion.obstacles(space, Vector3(-2.75, 1.6, 4.6), rain), 0, "desde el pasillo la tapa un muro")


# Oclusión: los muros del piso y del salón, en triángulos; en espejo, el mismo contorno reflejado en x.
func test_wall_occluder_covers_flat_and_mirrors() -> void:
	var boxes: Array[AABB] = []
	for mirrored in [false, true]:
		var occ := (_flat(mirrored).get_node("WallOccluder") as OccluderInstance3D).occluder as ArrayOccluder3D
		assert_gt(occ.vertices.size(), 100)
		assert_eq(occ.indices.size() % 3, 0)
		var box := AABB(occ.vertices[0], Vector3.ZERO)
		for v in occ.vertices:
			box = box.expand(v)
		boxes.append(box)
	assert_almost_eq(boxes[1].position.x, -boxes[0].end.x, 0.01)
	assert_almost_eq(boxes[1].size, boxes[0].size, Vector3.ONE * 0.01)


# La lluvia se mueve en cada fotograma: si diera sombra, obligaría a redibujar cada fotograma la sombra de todas
# las lámparas a su alcance (miles de objetos de más). Su sombra no se notaba.
func test_rain_casts_no_shadow() -> void:
	var rain := _flat(false).living_room.get_node("Rain") as GeometryInstance3D
	assert_eq(rain.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)


# Polvo: cubre todas las zonas (también en espejo) y no da sombra, por lo mismo que la lluvia.
func test_dust_covers_every_zone_and_casts_no_shadow() -> void:
	for mirrored in [false, true]:
		var f: Node3D = _flat(mirrored)
		var dust := f.get_node("Dust") as GPUParticles3D
		assert_eq(dust.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
		var half: Vector3 = (dust.process_material as ParticleProcessMaterial).emission_box_extents
		for zone in (f.get_layout() as FlatLayout).zones:
			var c := zone.rect.get_center()
			var p := Vector3(-c.x if mirrored else c.x, 1.3, c.y) - dust.position
			assert_true(absf(p.x) < half.x and absf(p.z) < half.z, "polvo en %s" % zone.id)


func test_places_of_the_director() -> void:
	var normal: Node3D = _flat(false)
	var mirror: Node3D = _flat(true)
	var layout: FlatLayout = normal.get_layout()
	assert_almost_eq(normal.get_place(&"kitchen"), Vector3(-9.95, 1.0, -5.35), Vector3.ONE * 0.0001)
	assert_eq(normal.get_place(&"ceiling"), Vector3(0.0, 2.6, 0.0))
	assert_eq(normal.get_place(&"wall"), Vector3(0.0, 1.3, 2.5))
	assert_eq(normal.get_place_zone(&"wall"), &"")
	for conn in layout.connections:
		if conn.kind == &"leaf":
			assert_eq(normal.get_place_zone(conn.id), conn.zone_a, String(conn.id))
	for id: StringName in normal.ROOM_PLACES:
		assert_eq(normal.get_place_zone(id), id)
	for id: StringName in [&"kitchen", &"bathroom", &"door_front", &"door_gallery", &"wall", &"ceiling", &"behind_sofa", &"rocking_chair"]:
		var p: Vector3 = normal.get_place(id)
		assert_almost_eq(mirror.get_place(id), Vector3(-p.x, p.y, p.z), Vector3.ONE * 0.0001)
		assert_eq(mirror.get_place_zone(id), normal.get_place_zone(id))


func test_props_fall_to_free_floor_in_their_room() -> void:
	var zones := {&"spoon": &"kitchen", &"tool": &"workshop", &"book": &"bedroom_3", &"bath_fall": &"bathroom"}
	var homes := {}
	for mirrored: bool in [false, true]:
		var f: Node3D = _flat(mirrored)
		await wait_physics_frames(2)
		var zone_at := func(p: Vector3) -> StringName: return f.get_layout().zone_at(Vector2(p.x, p.z), mirrored)
		for event: StringName in f.PROPS:
			for prop: FallingProp in f.props[event]:
				var home := prop.position
				var label := "%s espejo=%s" % [prop.name, mirrored]
				assert_gt(prop.get_child_count(), 0, label)
				assert_eq(zone_at.call(home), zones[event], label)
				assert_eq(zone_at.call(prop.landing), zones[event], label)
				assert_between(prop.lead(), 0.8, HouseAudio.PRELUDE, label)
				if mirrored:
					assert_almost_eq(home, Vector3(-homes[prop.name].x, homes[prop.name].y, homes[prop.name].z), Vector3.ONE * 0.01, label)
				homes[prop.name] = home
				prop._pose(prop.lead())
				assert_almost_eq(prop.position, prop.landing, Vector3.ONE * 0.001, label)
				prop._pose(0.0)
				assert_almost_eq(prop.position, home, Vector3.ONE * 0.001, label)
				var q := PhysicsShapeQueryParameters3D.new()
				q.shape = BoxShape3D.new()
				(q.shape as BoxShape3D).size = Vector3(0.24, 0.1, 0.24)
				q.transform.origin = prop.landing + Vector3.UP * 0.1
				assert_true(f.get_world_3d().direct_space_state.intersect_shape(q).is_empty(), "%s: cae dentro de algo" % label)
		f.free()


func test_pick_prop_leaves_the_fallen_for_last() -> void:
	var f: Node3D = _flat(false)
	assert_null(f.pick_prop(&"pipes"))
	for i in f.props[&"tool"].size():
		var prop: FallingProp = f.pick_prop(&"tool")
		assert_false(prop.fallen)
		prop.fallen = true
	assert_not_null(f.pick_prop(&"tool"), "sin nadie mirando, uno vuelve a su sitio")


func test_a_door_creeps_open_and_back_unless_locked() -> void:
	var f: Node3D = _flat(false)
	await wait_physics_frames(2)
	for id: StringName in [&"door_bedroom_3", &"door_gallery", &"door_front"]:
		var door: Door = f.doors.filter(func(d: Door) -> bool: return d.id == id)[0]
		var before := door.angle
		f.stir(id, 0.1)
		await wait_seconds(0.3)
		if door.locked:
			assert_eq(door.angle, before)
			continue
		assert_almost_eq(door.angle, Door.CREEP_ANGLE, 0.001, String(id))
		f.stir(id, 0.1)
		await wait_seconds(0.3)
		assert_almost_eq(door.angle, DoorMath.AJAR_ANGLE, 0.001, String(id))


func test_the_rocking_chair_rolls_and_ends_at_rest() -> void:
	for mirrored: bool in [false, true]:
		var f: Node3D = _flat(mirrored)
		var rest: Transform3D = f._chair.transform
		f._rock(f.ROCK_PERIOD * 1.25, 10.0)
		var lean: Vector3 = f._chair.basis.y
		assert_almost_eq(lean.angle_to(Vector3.UP), f.ROCK_ANGLE, 0.001)
		assert_lt(lean.z, 0.0, "hacia el salón")
		assert_gt(lean.x * (1.0 if mirrored else -1.0), 0.0)
		f._rock(10.0, 10.0)
		assert_almost_eq(f._chair.transform.origin, rest.origin, Vector3.ONE * 0.0001)


func test_each_ear_hears_where_an_event_comes_from() -> void:
	assert_eq(HouseAudio.ears(Vector3(0, 0, -3)), Vector3.ZERO)
	var right := HouseAudio.ears(Vector3(2, 0, 0))
	assert_between(right.x, 0.6, 0.7, "ms")
	assert_eq(right.y, HouseAudio.FAR_EAR_DB)
	var left := HouseAudio.ears(Vector3(-2, 0, 0))
	assert_almost_eq(left, Vector3(-right.x, -right.y, 0.0), Vector3.ONE * 0.0001)
	assert_almost_eq(HouseAudio.ears(Vector3(0, 0, 4)), Vector3(0, 0, 1), Vector3.ONE * 0.0001)
	var ahead := HouseAudio.ears(Vector3(3, 0, -2))
	var behind := HouseAudio.ears(Vector3(3, 0, 2))
	assert_eq(ahead.x, behind.x)
	assert_gt(behind.z, ahead.z)
