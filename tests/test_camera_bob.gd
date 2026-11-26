extends GutTest

# Balanceo de la cámara (specs/hito4b.md D3b).


func test_still_only_breathes() -> void:
	var o := CameraBob.offset(0.0, 0.0, CameraBob.BREATH_PERIOD / 4.0)
	assert_eq(o.x, 0.0)
	assert_eq(o.z, 0.0)
	assert_almost_eq(o.y, CameraBob.BREATH_Y, 0.0001, "a un cuarto del ciclo, la respiración en lo alto")


func test_lowest_on_each_footstep() -> void:
	for k in 3:
		assert_almost_eq(CameraBob.offset(k + 0.5, 1.0, 0.0).y, -CameraBob.BOB_Y, 0.0001, "pisada %d" % k)
		assert_almost_eq(CameraBob.offset(float(k), 1.0, 0.0).y, 0.0, 0.0001, "entre pisadas, arriba")


func test_sways_every_two_steps() -> void:
	var a := CameraBob.offset(0.5, 1.0, 0.0)
	var b := CameraBob.offset(1.5, 1.0, 0.0)
	assert_almost_eq(a.x, CameraBob.BOB_X, 0.0001)
	assert_almost_eq(b.x, -CameraBob.BOB_X, 0.0001, "un pie y el otro")
	assert_almost_eq(a.z, -b.z, 0.0001)


func test_settles_with_amplitude() -> void:
	assert_almost_eq(CameraBob.offset(0.5, 0.0, 0.0).length(), 0.0, 0.0001, "parado no se balancea")
	assert_almost_eq(CameraBob.offset(0.5, 0.5, 0.0).y, -CameraBob.BOB_Y * 0.5, 0.0001)
