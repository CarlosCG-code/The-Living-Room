extends GutTest


func _rotated() -> Transform3D:
	var b := Basis.from_euler(Vector3(0.3, 1.1, -0.4))
	return Transform3D(b, Vector3(1.5, 0.8, -2.0))


func test_twice_is_identity() -> void:
	var t := _rotated()
	var back := MirrorMath.mirror_transform(MirrorMath.mirror_transform(t))
	assert_true(back.is_equal_approx(t))


func test_no_negative_scale() -> void:
	var m := MirrorMath.mirror_transform(_rotated())
	assert_almost_eq(m.basis.determinant(), 1.0, 0.0001)


func test_point_x_flips() -> void:
	var m := MirrorMath.mirror_transform(Transform3D(Basis.IDENTITY, Vector3(2, 1, 3)))
	assert_eq(m.origin, Vector3(-2, 1, 3))


func test_facing_plus_x_faces_minus_x() -> void:
	# Un nodo que mira a +X (su -Z apunta a +X).
	var t := Transform3D(Basis.looking_at(Vector3(1, 0, 0)), Vector3.ZERO)
	var m := MirrorMath.mirror_transform(t)
	assert_true((-m.basis.z).is_equal_approx(Vector3(-1, 0, 0)))


func test_basis_stays_orthonormal() -> void:
	var m := MirrorMath.mirror_transform(_rotated())
	assert_true(m.basis.orthonormalized().is_equal_approx(m.basis))
