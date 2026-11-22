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


# Espejo de pared (PlanarMirror): cristal en x = -2 mirando a +X, ojo delante.
func test_planar_mirror_camera() -> void:
	var centre := Vector3(-2.0, 1.5, 0.3)
	var n := Vector3.RIGHT
	var right := PlanarMirror.right_of(n)
	assert_true(right.is_equal_approx(Vector3(0, 0, -1)), "derecha vista desde la habitación")
	var eye := Vector3(0.5, 1.7, 1.0)
	var cam: Array = PlanarMirror.mirror_camera(eye, centre, n, right)
	var t: Transform3D = cam[0]
	assert_true(t.origin.is_equal_approx(Vector3(-4.5, 1.7, 1.0)), "el ojo, reflejado tras el cristal")
	assert_true((-t.basis.z).is_equal_approx(n), "mira hacia la habitación")
	assert_almost_eq(float(cam[2]), 2.51, 0.0001, "plano cercano 1 cm por delante del cristal")
	assert_almost_eq(float(cam[3]), 2.51 / 2.5, 0.0001)
	# El centro del cristal, visto desde la cámara (su derecha es +Z del mundo): 0,7 m a su izquierda y 0,2 m más bajo.
	assert_true((cam[1] as Vector2).is_equal_approx(Vector2(-0.7, -0.2) * 2.51 / 2.5))
