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
	assert_eq(tree.state_of(&"dial_hold"), &"locked", "Dial firme cuelga de Pulso")
	assert_eq(tree.describe(&"dial_hold"), tr("UI_LOCKED"))
	Game.economy.state.energy = 100.0
	Game.economy.state.energy_produced_run = 200.0
	assert_eq(tree.state_of(&"pulse"), &"affordable")
	Game.economy.buy(&"pulse")
	assert_eq(tree.state_of(&"pulse"), &"bought")
	assert_ne(tree.state_of(&"dial_hold"), &"locked", "comprado Pulso, se desbloquea su rama")


func test_pressing_a_node_asks_to_buy_it() -> void:
	watch_signals(tree)
	tree.get_node_button(&"pulse").pressed.emit()
	assert_signal_emitted_with_parameters(tree, "buy_requested", [&"pulse"])
