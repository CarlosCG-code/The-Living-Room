extends GutTest

# Árbol de mejoras sobre la economía de Game (TLR_NO_SAVE: partida nueva en cada ejecución).

var tree: UpgradeTree
var saved_state: RunState


func before_each() -> void:
	saved_state = Game.economy.state
	Game.economy.state = RunState.new_run(Game.economy.config, 1, RandomNumberGenerator.new())
	tree = UpgradeTree.new()
	tree.size = Vector2(320, 240)
	add_child_autofree(tree)


func after_each() -> void:
	Game.economy.state = saved_state


func test_every_upgrade_and_generator_has_a_node() -> void:
	var config := Game.economy.config
	for g in config.generators:
		assert_not_null(tree.get_node_button(g.id), "nodo de %s" % g.id)
	for u in config.upgrades:
		assert_not_null(tree.get_node_button(u.id), "nodo de %s" % u.id)


func test_states_follow_the_economy() -> void:
	assert_eq(tree.state_of(&"pulse"), &"available", "Pulso se ve desde el principio")
	assert_false(tree.is_revealed(&"bare_cable"), "Cable pelado cuelga de Pulso: ni se ve")
	Game.economy.state.energy = 100.0
	Game.economy.state.energy_produced_run = 200.0
	assert_eq(tree.state_of(&"pulse"), &"affordable")
	Game.economy.buy(&"pulse")
	assert_eq(tree.state_of(&"pulse"), &"bought")
	assert_true(tree.is_revealed(&"bare_cable"), "comprado Pulso, se ve su rama")
	assert_eq(tree.state_of(&"bare_cable"), &"locked", "pero pide más Energía producida")
	assert_eq(tree.describe(&"bare_cable"), tr("UI_LOCKED_ENERGY") % NumberFormat.short(350.0), "dice cuánto falta")
	Game.economy.state.energy_produced_run = 400.0
	assert_ne(tree.state_of(&"bare_cable"), &"locked")


func test_nodes_sit_in_their_cells() -> void:
	for u in Game.economy.config.upgrades:
		assert_eq(tree.get_node_button(u.id).position, UpgradeTree.cell_position(u.tree_cell), "celda de %s" % u.id)


func test_effect_numbers_keep_two_decimals() -> void:
	assert_eq(tree._num(1.35), "1,35", "Taquicardia salía «×1,4»")
	assert_eq(tree._num(2.5), "2,5")
	assert_eq(tree._num(300.0), "300")


func test_pressing_a_node_asks_to_buy_it() -> void:
	watch_signals(tree)
	tree.get_node_button(&"pulse").pressed.emit()
	assert_signal_emitted_with_parameters(tree, "buy_requested", [&"pulse"])


func test_locked_cards_say_what_is_missing() -> void:
	var eco := Game.economy
	eco.state.upgrades.append(&"dial_hold")
	eco.state.upgrades.append(&"antenna_tune")
	eco.state.generators[&"antenna"] = 10
	eco._recalc()
	assert_eq(tree.describe(&"sweep"), tr("UI_LOCKED_RUN"), "las habilidades son de la run 2")
	assert_eq(tree.describe(&"antenna_25"), "Antena: tienes 10 de 25.")
	assert_eq(tree.describe(&"sharp_eye"), "Cosas raras atrapadas: 0 de 1.")
	assert_false(tree.is_revealed(&"ghost_image"), "la rama escondida ni se insinúa sin Tus ojos")
	eco.state.perks.append(&"eyes")
	eco.state.upgrades.append(&"sharp_eye")
	assert_true(tree.is_revealed(&"ghost_image"))
	eco.state.perks.clear()
	eco.state.upgrades.clear()
	eco.state.generators.clear()
	eco._recalc()
