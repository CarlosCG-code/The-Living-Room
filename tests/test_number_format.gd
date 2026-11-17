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


func test_per_click() -> void:
	assert_eq(NumberFormat.per_click(0), "0,00")
	assert_eq(NumberFormat.per_click(0.012), "0,01")
	assert_eq(NumberFormat.per_click(9.994), "9,99")
	assert_eq(NumberFormat.per_click(9.996), "10")
	assert_eq(NumberFormat.per_click(1234.6), "1.235")
