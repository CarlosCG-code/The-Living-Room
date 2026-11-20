extends GutTest

var layout: FlatLayout = load("res://data/flat_layout.tres")


func test_current_first_then_neighbors() -> void:
	var active := RoomActivation.active(layout, &"corridor_service_m", Vector2.ZERO)
	assert_eq(active[0], &"corridor_service_m")
	for n in layout.neighbors(&"corridor_service_m"):
		assert_has(active, n, "vecinas por hoja (cerrada o no) y por vano")
	assert_lte(active.size(), RoomActivation.MAX)


func test_never_more_than_max_nearest_first() -> void:
	var l := FlatLayout.new()
	var hub := ZoneDef.new()
	hub.id = &"hub"
	hub.rect = Rect2(0, 0, 1, 1)
	l.zones.append(hub)
	for i in 10:
		var z := ZoneDef.new()
		z.id = StringName("z%02d" % i)
		z.rect = Rect2(2 + i, 0, 1, 1)
		l.zones.append(z)
		var c := ConnectionDef.new()
		c.zone_a = z.id
		c.zone_b = &"hub"
		l.connections.append(c)
	var tie := ZoneDef.new()
	tie.id = &"a_tie"
	tie.rect = Rect2(2, 0, 1, 1)  # a la misma distancia que z00: gana por id
	l.zones.append(tie)
	var c2 := ConnectionDef.new()
	c2.zone_a = &"a_tie"
	c2.zone_b = &"hub"
	l.connections.append(c2)
	var active := RoomActivation.active(l, &"hub", Vector2(0.5, 0.5))
	assert_eq(active.size(), 8)
	assert_eq(active.slice(0, 3), [&"hub", &"a_tie", &"z00"] as Array[StringName])
	assert_does_not_have(active, &"z09", "la más lejana se queda fuera")
