extends GutTest

var view: FactoryView


func before_each() -> void:
	view = FactoryView.new()
	view.size = Vector2(212, 240)
	add_child_autofree(view)
	view.set_process(false)  # sin leer Game.economy: el test le pasa las cantidades


func _machines(id: StringName) -> Array[TextureButton]:
	return view.get_group(id)["machines"]


func test_slots_follow_thresholds() -> void:
	view.show_counts({&"antenna": 5})
	var antennas := _machines(&"antenna")
	assert_true(antennas[0].visible, "1 antena: primer hueco")
	assert_true(antennas[1].visible, "5 antenas: segundo hueco")
	assert_false(antennas[2].visible, "el tercero pide 10")
	assert_true((view.get_group(&"antenna")["cable"] as CanvasItem).visible, "con antenas, cable con corriente")
	assert_false(_machines(&"valves")[0].visible, "sin válvulas no hay válvulas")
	assert_false((view.get_group(&"valves")["cable"] as CanvasItem).visible)


func test_restart_hides_everything() -> void:
	view.show_counts({&"valves": 50, &"channel_3": 1})
	assert_true(_machines(&"valves")[2].visible)
	view.show_counts({})
	for id: StringName in FactoryView.LAYOUT:
		for m in _machines(id):
			assert_false(m.visible, "%s oculto tras reiniciar" % id)
		assert_false((view.get_group(id)["cable"] as CanvasItem).visible)


func test_every_generator_has_machines() -> void:
	var config: EconomyConfig = load("res://data/economy_run1.tres")
	for g in config.generators:
		assert_false(view.get_group(g.id).is_empty(), "máquinas de %s" % g.id)


func test_pressing_a_machine_asks_for_a_click() -> void:
	watch_signals(view)
	view.get_receptor().pressed.emit()
	assert_signal_emitted(view, "machine_pressed", "el receptor sintoniza desde el principio")


func test_interference_travels_along_a_powered_cable() -> void:
	view.show_counts({&"valves": 1})
	var e := TvEventDef.new()
	e.id = &"interference"
	e.reward_min_clicks = 1.0
	var cable: FactoryCable = view.get_group(&"valves")["cable"]
	var sparks: Node2D = view.get_node("Sparks")
	var catch_button: Button = view.get_node("Catch")
	view.show_event(e, 0.0)
	assert_true(catch_button.visible)
	assert_almost_eq(sparks.position, cable.point_at(0.0), Vector2(0.01, 0.01), "salen del único cable con corriente")
	view.show_event(e, 0.5)
	assert_almost_eq(sparks.position, cable.midpoint(), Vector2(0.01, 0.01), "y viajan por él")
	watch_signals(view)
	catch_button.pressed.emit()
	assert_signal_emitted(view, "event_pressed")
	view.show_event(null, 0.0)
	assert_false(catch_button.visible)


func test_clear_signal_cannot_be_caught() -> void:
	var e := TvEventDef.new()
	e.id = &"clear_signal"
	e.production_mult = 2.0
	view.show_event(e, 0.5)
	assert_false((view.get_node("Catch") as Button).visible)
