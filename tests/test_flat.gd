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
	for m: MeshInstance3D in f.doors[0].find_children("*", "MeshInstance3D", true, false):
		for s in m.mesh.get_surface_count():
			assert_eq((m.mesh.surface_get_material(s) as BaseMaterial3D).cull_mode, BaseMaterial3D.CULL_BACK, "luz invertida al reflejar la hoja")
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
