extends GutTest

# Trucos de depuración (tools/dev_cheats.gd): que cada uno haga lo que dice sin romper la partida.

var cheats: CanvasLayer


func before_each() -> void:
	cheats = (load("res://tools/dev_cheats.gd") as GDScript).new()
	add_child_autofree(cheats)
	cheats._new_game()


func after_all() -> void:
	Engine.time_scale = 1.0
	Game.economy.state = RunState.new_run(Game.economy.config, 1, RandomNumberGenerator.new())
	Game.economy._recalc()


func test_threshold_and_restart() -> void:
	cheats._to_ratio(1.0)
	assert_true(Game.economy.can_restart())
	cheats._restart_now()
	assert_eq(Game.economy.state.run_index, 2)
	assert_gt(Game.economy.state.carga, 0)


func test_runs_open_their_branches() -> void:
	cheats._set_run(3)
	cheats._give(1e9)
	cheats._add_machines()
	cheats._add_machines()
	Game.economy.state.events_caught = 10
	Game.economy.state.manual_clicks = 10000
	Game.economy.state.packages_opened = 100
	cheats._buy_all()
	for i in 4:  # cada compra abre la siguiente de la rama
		cheats._buy_all()
	assert_true(Game.economy.is_bought(&"bypass"), "en la run 3 está el consumo")
	assert_false(Game.economy.is_bought(&"overload"), "Sobrecarga es de la run 4")
	assert_false(Game.economy.is_bought(&"ghost_image"), "la rama escondida pide Tus ojos")
	cheats._all_perks()
	cheats._buy_all()
	assert_true(Game.economy.is_bought(&"ghost_image"))


func test_events_tapes_and_new_game() -> void:
	cheats._start_event(&"silhouette")
	assert_eq(Game.economy.active_event().id, &"silhouette")
	cheats._drop(2)
	cheats._drop(0)
	cheats._drop(1)
	assert_eq(Game.economy.packages().size(), 2, "nunca más de 2 cintas")
	cheats._speed(20.0)
	cheats._new_game()
	assert_eq(Game.economy.state.run_index, 1)
	assert_eq(Game.economy.packages().size(), 0)
	assert_eq(Engine.time_scale, 1.0)
