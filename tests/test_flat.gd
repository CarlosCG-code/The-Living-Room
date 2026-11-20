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
			var expected := MirrorMath.mirror_transform(a.get_node("Leaf").global_transform)
			var got: Transform3D = b.get_node("Leaf").global_transform
			assert_true(got.is_equal_approx(expected), "%s a %d°" % [a.id, deg])


func test_locked_front_door_does_not_grab() -> void:
	var f: Node3D = _flat(false)
	var front: Door = f.get_node("door_front")
	assert_true(front.locked)
	assert_false(front.try_grab(Vector3.ZERO))
