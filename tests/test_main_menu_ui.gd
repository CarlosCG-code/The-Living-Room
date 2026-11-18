extends GutTest

var menu: MainMenuUI
var _saved: UserSettings


func before_each() -> void:
	_saved = Game.settings
	Game.settings = UserSettings.new()  # TLR_NO_SAVE: no se escribe nada en disco
	var vp := SubViewport.new()
	vp.size = Vector2i(320, 240)
	add_child_autofree(vp)
	menu = (load("res://presentation/ui/main_menu_ui.tscn") as PackedScene).instantiate()
	vp.add_child(menu)
	await wait_process_frames(2)


func after_each() -> void:
	Game.settings = _saved


func _focus() -> Control:
	return menu.get_viewport().gui_get_focus_owner()


func test_a_button_has_focus_on_open() -> void:
	assert_not_null(_focus(), "con teclado o mando siempre hay algo seleccionado")


func test_options_take_and_give_back_focus() -> void:
	menu.show_options()
	assert_eq(_focus(), menu.get_option_button("quality"))
	menu.show_main()
	assert_not_null(_focus())
	assert_true(_focus().is_visible_in_tree())


func test_pressing_an_option_changes_the_setting() -> void:
	menu.show_options()
	menu.get_option_button("quality").pressed.emit()
	assert_eq(Game.settings.quality, &"high")
	menu.get_option_button("crt").pressed.emit()
	assert_almost_eq(Game.settings.crt, 0.0, 0.0001, "fuerte → no")
	menu.get_option_button("crt").pressed.emit()
	assert_almost_eq(Game.settings.crt, 0.5, 0.0001, "no → suave")


func test_volume_wraps_to_zero() -> void:
	Game.settings.volume = 1.0
	menu.show_options()
	menu.get_option_button("volume").pressed.emit()
	assert_almost_eq(Game.settings.volume, 0.0, 0.0001)


func test_pause_stops_the_run_and_resume_restarts_it() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(320, 240)
	add_child_autofree(vp)
	var ui: Node = (load("res://presentation/ui/tv_game_ui.tscn") as PackedScene).instantiate()
	vp.add_child(ui)
	Game.running = true
	ui.open_pause()
	assert_true(ui.is_paused())
	assert_false(Game.running, "en pausa la economía no avanza")
	ui.close_pause()
	assert_false(ui.is_paused())
	assert_true(Game.running)
	Game.running = false


func test_carga_screen_buys_next_perk_and_starts() -> void:
	var saved_state := Game.economy.state
	Game.economy.state = RunState.new()
	Game.economy.state.carga = 1
	var screen := CargaScreen.new()
	menu.get_parent().add_child(screen)
	screen.open()
	await wait_process_frames(1)
	var focused := screen.get_viewport().gui_get_focus_owner() as Button
	assert_not_null(focused, "foco en la primera mejora, que se puede pagar")
	focused.pressed.emit()
	assert_true(Game.economy.has_perk(&"hands"))
	assert_eq(screen.get_viewport().gui_get_focus_owner(), screen.get_start_button(), "sin Carga, el foco va a Empezar")
	watch_signals(screen)
	screen.get_start_button().pressed.emit()
	assert_signal_emitted(screen, "start_requested")
	Game.economy.state = saved_state
	Game.economy._recalc()


func test_tv_starts_in_menu_and_play_changes_channel() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(320, 240)
	add_child_autofree(vp)
	var ui: Node = (load("res://presentation/ui/tv_game_ui.tscn") as PackedScene).instantiate()
	vp.add_child(ui)
	ui.start_in_menu()
	assert_true(ui.is_in_menu())
	assert_false(Game.running, "en el menú la partida no avanza")
	var tv_menu: MainMenuUI = null
	for child in ui.get_children():
		if child is MainMenuUI and not child.pause_menu:
			tv_menu = child
	tv_menu.play_requested.emit()
	await wait_seconds(0.6)
	assert_false(ui.is_in_menu())
	assert_true(Game.running, "tras el cambio de canal, a jugar")
	Game.running = false
