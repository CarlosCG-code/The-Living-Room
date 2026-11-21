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
