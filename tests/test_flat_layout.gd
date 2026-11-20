extends GutTest

# El plano generado (specs/hito4a.md §2, §7).

var layout: FlatLayout = load("res://data/flat_layout.tres")


func test_zone_count_and_no_overlap() -> void:
	assert_eq(layout.zones.size(), 21, "14 habitaciones y 7 tramos de pasillo")
	for i in layout.zones.size():
		for j in range(i + 1, layout.zones.size()):
			var a := layout.zones[i]
			var b := layout.zones[j]
			assert_lt(a.rect.intersection(b.rect).get_area(), 0.0001, "%s y %s se solapan" % [a.id, b.id])


func test_connections_join_touching_zones() -> void:
	for c in layout.connections:
		if c.zone_b == &"":
			continue
		var a := layout.find_zone(c.zone_a).rect
		var b := layout.find_zone(c.zone_b).rect
		assert_not_null(a, String(c.id))
		var gap := maxf(maxf(b.position.x - a.end.x, a.position.x - b.end.x), maxf(b.position.y - a.end.y, a.position.y - b.end.y))
		var seam := c.kind == &"passage" and c.width == 0.0
		assert_almost_eq(gap, 0.0 if seam else 0.15, 0.01, "%s: hueco entre zonas" % c.id)
		var overlap := minf(a.end.x, b.end.x) - maxf(a.position.x, b.position.x)
		if absf(b.position.x - a.end.x) < 0.2 or absf(a.position.x - b.end.x) < 0.2:
			overlap = minf(a.end.y, b.end.y) - maxf(a.position.y, b.position.y)
		assert_gte(overlap, c.width, "%s: cabe el hueco" % c.id)


func test_leaves_open_towards_zone_a_and_sit_in_the_wall() -> void:
	for c in layout.connections:
		if c.kind != &"leaf":
			continue
		assert_almost_eq(c.direction.length(), 1.0, 0.001, String(c.id))
		var a := layout.find_zone(c.zone_a).rect
		var hinge := Vector2(c.hinge.x, c.hinge.z)
		var d := Vector2(c.direction.x, c.direction.z)
		var swing := Vector2(d.y, -d.x) * c.swing  # derivada de R_y(swing·θ)·d en θ = 0, en planta (x, z)
		assert_gt(swing.dot(a.get_center() - hinge), 0.0, "%s abre hacia %s" % [c.id, c.zone_a])
		var mid := hinge + d * c.width * 0.5
		assert_eq(layout.zone_at(mid, false), &"", "%s: el centro del hueco está en el muro" % c.id)


func _reachable(from: StringName, without: StringName = &"") -> Dictionary:
	var dist := {from: 0}
	var queue: Array[StringName] = [from]
	while not queue.is_empty():
		var z: StringName = queue.pop_front()
		for n in layout.neighbors(z):
			if n != without and not dist.has(n):
				dist[n] = dist[z] + 1
				queue.append(n)
	return dist


func test_everything_reachable_from_living_room() -> void:
	assert_eq(_reachable(&"living_room").size(), layout.zones.size())


func test_three_loops_between_corridors() -> void:
	for cut in [&"corridor_side", &"pantry_hall", &"workshop"]:
		assert_true(_reachable(&"corridor_main_m", cut).has(&"corridor_service_m"), "sin %s siguen unidos" % cut)


func test_fuse_box_is_far() -> void:
	assert_eq(layout.fuse_box_zone, &"storage")
	assert_gte(_reachable(&"living_room")[&"storage"], 5)


func test_living_room_unchanged() -> void:
	var r := layout.find_zone(&"living_room").rect
	assert_eq(r, Rect2(-2, -2.5, 4, 5))
	for c in layout.connections:
		if c.id == &"door_living":
			var center := c.hinge + c.direction * c.width * 0.5
			assert_almost_eq(center.x, -2.075, 0.001)
			assert_almost_eq(center.z, -1.6, 0.001, "donde está hoy la puerta del salón")
			assert_almost_eq(c.width, 0.9, 0.001)
			return
	fail_test("falta door_living")


func test_zone_at() -> void:
	assert_eq(layout.zone_at(Vector2.ZERO, false), &"living_room")
	assert_eq(layout.zone_at(Vector2(2.0, 2.5), false), &"living_room", "en el borde")
	assert_eq(layout.zone_at(Vector2(-2.05, 0.0), false), &"", "en el muro")
	var kitchen := layout.find_zone(&"kitchen").rect.get_center()
	assert_eq(layout.zone_at(Vector2(-kitchen.x, kitchen.y), true), &"kitchen", "en espejo se refleja el punto")
	assert_eq(layout.zone_at(kitchen, true), layout.zone_at(Vector2(-kitchen.x, kitchen.y), false))
