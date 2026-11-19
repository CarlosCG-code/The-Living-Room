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


func test_short_fits_the_osd() -> void:
	assert_eq(NumberFormat.short(950), "950")
	assert_eq(NumberFormat.short(12345), "12,3 K")
	assert_eq(NumberFormat.short(112_000_000), "112 M")
	assert_eq(NumberFormat.short(80_000_000), "80 M", "sin «,0»")
	assert_eq(NumberFormat.short(3_000), "3 K")
	assert_eq(NumberFormat.short(1_599_999_999), "1,5 G")
