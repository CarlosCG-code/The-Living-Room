extends GutTest

var view: FactoryView


func before_each() -> void:
	view = FactoryView.new()
	view.size = Vector2(212, 240)
	add_child_autofree(view)
	view.set_process(false)  # sin leer Game.economy: el test le pasa las cantidades


func _machines(id: StringName) -> Array[FactoryMachine]:
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


func test_interference_sparks_from_a_powered_cable() -> void:
	view.show_counts({&"valves": 1})
	view.set_interference(true)
	var cable: FactoryCable = view.get_group(&"valves")["cable"]
	var catch_button: Button = view.get_node("Catch")
	assert_true(catch_button.visible)
	assert_almost_eq((view.get_node("Sparks") as Node2D).position, cable.midpoint(), Vector2(0.01, 0.01),
			"las chispas salen del único cable con corriente")
	watch_signals(view)
	catch_button.pressed.emit()
	assert_signal_emitted(view, "interference_pressed")
	view.set_interference(false)
	assert_false(catch_button.visible)
