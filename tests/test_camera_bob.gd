extends GutTest

# La cámara viva de pie (specs/hito4b.md D3b).


func _run(bob: CameraBob, seconds: float, speed: float) -> void:
	for i in int(seconds * 60.0):
		bob.update(1.0 / 60.0, speed, 1.1, 0.65)


func test_footstep_is_the_lowest_point() -> void:
	var at_contact: Vector3 = CameraBob.target_pose(0.5, 1.0, 0.0)[0]
	var mid: Vector3 = CameraBob.target_pose(1.0, 1.0, 0.0)[0]
	assert_almost_eq(at_contact.y, -CameraBob.STEP_DROP, 0.0001, "al apoyar el pie, abajo del todo")
	assert_almost_eq(mid.y, 0.0, 0.0001, "entre pisadas, arriba")
	assert_gt((CameraBob.target_pose(0.75, 1.0, 0.0)[0] as Vector3).y, -CameraBob.STEP_DROP * 0.2,
			"el golpe es estrecho: a un cuarto de paso ya casi ha subido")


func test_sways_toward_each_foot() -> void:
	var a: Vector3 = CameraBob.target_pose(0.5, 1.0, 0.0)[0]
	var b: Vector3 = CameraBob.target_pose(1.5, 1.0, 0.0)[0]
	assert_almost_eq(a.x, CameraBob.STEP_SIDE, 0.0001)
	assert_almost_eq(b.x, -CameraBob.STEP_SIDE, 0.0001, "un pie y el otro")


func test_breath_inhales_faster_than_it_exhales() -> void:
	assert_almost_eq(CameraBob.breath_curve(0.0), 0.0, 0.0001)
	assert_almost_eq(CameraBob.breath_curve(CameraBob.BREATH_IN), 1.0, 0.0001)
	assert_almost_eq(CameraBob.breath_curve(0.999), 0.0, 0.01)
	assert_lt(CameraBob.BREATH_IN, 0.5)


func test_walking_moves_and_stopping_settles() -> void:
	var bob := CameraBob.new()
	_run(bob, 3.0, 1.1)
	var lowest := 0.0
	for i in 60:
		bob.update(1.0 / 60.0, 1.1, 1.1, 0.65)
		lowest = minf(lowest, bob.position.y)
	assert_lt(lowest, -CameraBob.STEP_DROP * 0.5, "andando, la cabeza baja con los pasos")
	_run(bob, 2.0, 0.0)
	assert_lt(absf(bob.position.y), CameraBob.BREATH_RISE + 0.002, "parado, solo respira")
	assert_lt(absf(bob.roll), 0.002)


func test_still_breathes_and_sways_without_walking_motion() -> void:
	var bob := CameraBob.new()
	var ys := []
	for i in 600:
		bob.update(1.0 / 60.0, 0.0, 1.1, 0.65)
		ys.append(bob.position.y)
	assert_gt(ys.max() - ys.min(), CameraBob.BREATH_RISE * 0.7, "respira")
	assert_lt(ys.max() - ys.min(), CameraBob.BREATH_RISE * 1.5)
