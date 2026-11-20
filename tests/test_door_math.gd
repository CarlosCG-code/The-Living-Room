extends GutTest

const DT := 1.0 / 60.0


func _run(angle: float, velocity: float, drag: float, held: bool, seconds: float, dt := DT) -> Vector3:
	var r := Vector3(angle, velocity, 0)
	for i in roundi(seconds / dt):
		r = DoorMath.step(r.x, r.y, drag, held, dt)
	return r


func test_fast_drag_opens_faster_than_slow() -> void:
	assert_gt(_run(0, 0, 3.0, true, 0.3).x, _run(0, 0, 0.6, true, 0.3).x)


func test_released_door_slows_to_a_stop() -> void:
	var r := _run(0.5, 1.0, 0, false, 6.0)
	assert_eq(r.y, 0.0, "se para")
	assert_between(r.x, 0.5, DoorMath.MAX_ANGLE)


func test_held_still_stops_the_door() -> void:
	assert_almost_eq(_run(0.5, 2.0, 0.0, true, 0.6).y, 0.0, 0.01, "agarrada sin mover el ratón, la hoja se queda quieta")


func test_limits() -> void:
	var open := _run(1.0, 0, 50.0, true, 2.0)
	assert_almost_eq(open.x, DoorMath.MAX_ANGLE, 0.0001)
	assert_gte(_run(0.3, 0, -50.0, true, 2.0).x, 0.0)


func test_slow_close_latches() -> void:
	var r := DoorMath.step(0.01, -0.9, 0, false, DT)
	assert_eq(int(r.z), DoorMath.Event.LATCH)
	assert_eq(r.x, 0.0)
	assert_eq(r.y, 0.0)


func test_fast_close_slams_and_bounces() -> void:
	var r := DoorMath.step(0.01, -4.0, 0, false, DT)
	assert_eq(int(r.z), DoorMath.Event.SLAM)
	assert_gt(r.y, 0.0, "rebota un poco hacia abierta")


func test_same_result_with_different_frame_rates() -> void:
	var a := _run(0.2, 0, 2.0, true, 0.5, 1.0 / 30.0)
	var b := _run(0.2, 0, 2.0, true, 0.5, 1.0 / 144.0)
	a = _run(a.x, a.y, 0, false, 0.5, 1.0 / 30.0)
	b = _run(b.x, b.y, 0, false, 0.5, 1.0 / 144.0)
	assert_almost_eq(a.x, b.x, deg_to_rad(1.0), "menos de 1° tras 1 s")
