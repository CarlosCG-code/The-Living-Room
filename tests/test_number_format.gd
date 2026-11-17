extends GutTest


func test_energy() -> void:
	assert_eq(NumberFormat.energy(0), "0")
	assert_eq(NumberFormat.energy(12345), "12.345")
	assert_eq(NumberFormat.energy(1000000), "1.000.000")
	assert_eq(NumberFormat.energy(99.6), "99")


func test_rate() -> void:
	assert_eq(NumberFormat.rate(0), "0,0/s")
	assert_eq(NumberFormat.rate(0.2), "0,2/s")
	assert_eq(NumberFormat.rate(99.9), "99,9/s")
	assert_eq(NumberFormat.rate(99.96), "100/s")
	assert_eq(NumberFormat.rate(1555.2), "1.555/s")
	assert_eq(NumberFormat.rate(1555.6), "1.556/s")
