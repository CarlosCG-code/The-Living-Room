extends GutTest

var view: Control


func before_each() -> void:
	view = (load("res://presentation/ui/factory_view.tscn") as PackedScene).instantiate()
	add_child_autofree(view)
	view.set_process(false)  # sin leer Game.economy: el test le pasa las cantidades


func test_slots_follow_thresholds() -> void:
	view.show_counts({&"antenna": 5})
	assert_true(view.get_node("antenna/slot_0").visible, "1 antena: primer hueco")
	assert_true(view.get_node("antenna/slot_1").visible, "5 antenas: segundo hueco")
	assert_false(view.get_node("antenna/slot_2").visible, "el tercero pide 10")
	assert_false(view.get_node("valves/slot_0").visible, "sin válvulas no hay válvulas")


func test_restart_hides_everything() -> void:
	view.show_counts({&"valves": 50, &"channel_3": 1})
	assert_true(view.get_node("valves/slot_3").visible)
	view.show_counts({})
	for group in view.get_children():
		for slot in group.get_children():
			assert_false((slot as CanvasItem).visible, "%s oculto tras reiniciar" % slot.get_path())


func test_every_generator_has_machines() -> void:
	var config: EconomyConfig = load("res://data/economy_run1.tres")
	for g in config.generators:
		assert_true(view.has_node(NodePath(String(g.id))), "máquinas de %s" % g.id)
