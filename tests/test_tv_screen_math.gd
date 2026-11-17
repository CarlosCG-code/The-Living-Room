extends GutTest

const SCREEN := Vector2(0.4, 0.3)
const VIEWPORT := Vector2i(960, 720)


func test_center_maps_to_center() -> void:
	assert_eq(TvScreenMath.hit_to_screen(Vector3.ZERO, SCREEN, VIEWPORT), Vector2(480, 360))


func test_corners() -> void:
	assert_eq(TvScreenMath.hit_to_screen(Vector3(-0.2, 0.15, 0), SCREEN, VIEWPORT), Vector2(0, 0))
	assert_eq(TvScreenMath.hit_to_screen(Vector3(0.2, 0.15, 0), SCREEN, VIEWPORT), Vector2(960, 0))
	assert_eq(TvScreenMath.hit_to_screen(Vector3(-0.2, -0.15, 0), SCREEN, VIEWPORT), Vector2(0, 720))
	assert_eq(TvScreenMath.hit_to_screen(Vector3(0.2, -0.15, 0), SCREEN, VIEWPORT), Vector2(960, 720))


func test_top_edge_is_y_zero() -> void:
	assert_almost_eq(TvScreenMath.hit_to_screen(Vector3(0.05, 0.15, 0), SCREEN, VIEWPORT).y, 0.0, 0.001)


func test_is_inside() -> void:
	assert_true(TvScreenMath.is_inside(Vector3(0.1, -0.1, 0), SCREEN))
	assert_false(TvScreenMath.is_inside(Vector3(0.21, 0, 0), SCREEN))
	assert_false(TvScreenMath.is_inside(Vector3(0, -0.16, 0), SCREEN))


func test_other_viewport_size() -> void:
	var vp := Vector2i(640, 480)
	assert_eq(TvScreenMath.hit_to_screen(Vector3.ZERO, SCREEN, vp), Vector2(320, 240))
	assert_eq(TvScreenMath.hit_to_screen(Vector3(0.2, -0.15, 0), SCREEN, vp), Vector2(640, 480))


func test_ray_plane_hits_known_plane() -> void:
	# Plano en z = -2 mirando a +Z; rayo desde el origen hacia -Z.
	var plane := Transform3D(Basis.IDENTITY, Vector3(0.1, 0, -2))
	var hit = TvScreenMath.ray_plane(Vector3.ZERO, Vector3(0, 0, -1), plane)
	assert_not_null(hit)
	assert_almost_eq((hit as Vector3).x, -0.1, 0.0001)
	assert_almost_eq((hit as Vector3).z, 0.0, 0.0001)


func test_ray_plane_parallel_or_behind_is_null() -> void:
	var plane := Transform3D(Basis.IDENTITY, Vector3(0, 0, -2))
	assert_null(TvScreenMath.ray_plane(Vector3.ZERO, Vector3(1, 0, 0), plane))
	assert_null(TvScreenMath.ray_plane(Vector3.ZERO, Vector3(0, 0, 1), plane))
