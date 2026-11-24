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
	assert_not_null(_focus())
	assert_true(_focus().is_visible_in_tree())
	menu.show_page("UI_PAGE_GRAPHICS")
	assert_eq(_focus(), menu.get_option_button("quality"))
	menu.show_options()
	assert_eq((_focus() as Button).text, tr("UI_PAGE_GRAPHICS"), "al volver, el foco queda en el apartado")
	menu.show_main()
	assert_not_null(_focus())
	assert_true(_focus().is_visible_in_tree())


func test_every_page_focuses_a_visible_row() -> void:
	for page: String in MainMenuUI.PAGES:
		menu.show_page(page)
		assert_not_null(_focus(), page)
		assert_true(_focus().is_visible_in_tree(), page)
		await wait_process_frames(1)
		var column := _focus().get_parent() as Control
		assert_lte(column.get_global_rect().end.y, 240.0, page + ": cabe en la tele")
		for row: Control in column.get_children():
			assert_lte(row.get_global_rect().size.x, 320.0, page + ": " + (row as Button).text)


func test_cancel_goes_back_one_level() -> void:
	menu.show_page("UI_PAGE_AUDIO")
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	menu._unhandled_input(esc)
	assert_eq((_focus() as Button).text, tr("UI_PAGE_AUDIO"), "de un apartado a la lista")
	menu._unhandled_input(esc)
	assert_eq(_focus(), menu._play, "de la lista al menú")


func _arrow_right(echo: bool) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = KEY_RIGHT
	e.physical_keycode = KEY_RIGHT
	e.pressed = true
	e.echo = echo
	return e


func test_held_arrow_keeps_focus_and_only_repeats_percentages() -> void:
	menu.show_page("UI_PAGE_DISPLAY")
	var brightness := menu.get_option_button("brightness")
	brightness.grab_focus()
	Game.settings.brightness = 1.3
	for i in 5:
		menu.get_viewport().push_input(_arrow_right(i > 0))
		await wait_process_frames(1)
	assert_eq(_focus(), brightness, "mantener la flecha no mueve el foco")
	assert_almost_eq(Game.settings.brightness, 1.5, 0.0001, "repite y se queda en el tope, sin dar la vuelta")
	var res := menu.get_option_button("vsync")
	res.grab_focus()
	for i in 4:
		menu.get_viewport().push_input(_arrow_right(i > 0))
		await wait_process_frames(1)
	assert_eq(_focus(), res)
	assert_false(Game.settings.vsync, "un cambio por pulsación: las repeticiones no lo vuelven a cambiar")


func test_new_rows_cycle() -> void:
	menu.get_option_button("max_fps").pressed.emit()
	assert_eq(Game.settings.max_fps, 30)
	Game.settings.brightness = 1.5
	menu.get_option_button("brightness").pressed.emit()
	assert_almost_eq(Game.settings.brightness, 0.5, 0.0001, "del máximo da la vuelta al mínimo")
	menu.get_option_button("vsync").pressed.emit()
	assert_false(Game.settings.vsync)
	menu.get_option_button("effects_intensity").pressed.emit()
	assert_almost_eq(Game.settings.effects_intensity, 0.0, 0.0001)
	menu.get_option_button("volume_tv").pressed.emit()
	assert_almost_eq(Game.settings.volume_tv, 0.0, 0.0001)


func test_pressing_an_option_changes_the_setting() -> void:
	menu.show_options()
	menu.get_option_button("quality").pressed.emit()
	assert_eq(Game.settings.quality, &"high")
	menu.get_option_button("crt").pressed.emit()
	assert_almost_eq(Game.settings.crt, 0.0, 0.0001, "fuerte → no")
	menu.get_option_button("crt").pressed.emit()
	assert_almost_eq(Game.settings.crt, 0.5, 0.0001, "no → suave")


func test_pause_menu_change_shows_in_main_menu() -> void:
	var pause: MainMenuUI = (load("res://presentation/ui/main_menu_ui.tscn") as PackedScene).instantiate()
	pause.pause_menu = true
	menu.get_parent().add_child(pause)
	await wait_process_frames(1)
	pause.get_option_button("volume").pressed.emit()
	assert_eq(menu.get_option_button("volume").text, pause.get_option_button("volume").text)
	pause.free()


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
	Game.economy.state.carga = 2
	var screen := CargaScreen.new()
	menu.get_parent().add_child(screen)
	screen.open()
	await wait_process_frames(1)
	var focused := screen.get_viewport().gui_get_focus_owner() as Button
	assert_not_null(focused, "foco en la primera mejora que se puede pagar")
	focused.pressed.emit()
	assert_true(Game.economy.has_perk(&"memory"))
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


func test_continue_with_unspent_carga_reopens_carga_screen() -> void:
	var saved_state := Game.economy.state
	Game.economy.state = RunState.new()
	Game.economy.state.run_index = 2
	Game.economy.state.carga = 2
	var vp := SubViewport.new()
	vp.size = Vector2i(320, 240)
	add_child_autofree(vp)
	var ui: Node = (load("res://presentation/ui/tv_game_ui.tscn") as PackedScene).instantiate()
	vp.add_child(ui)
	ui.start_playing()
	assert_true(ui.is_restarting(), "se salió en la pantalla de Carga: vuelve a ella")
	assert_false(Game.running)
	Game.economy.state = saved_state
	Game.economy._recalc()
	Game.running = false
