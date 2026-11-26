extends GutTest

# Prueba de integración: una partida de punta a punta con la escena real de la tele y la economía de Game
# (TLR_NO_SAVE: no toca la partida real). Menú → jugar → clics → mejoras → cintas → habilidades → eventos →
# pausa → reinicio con su carta → Carga → run 2 → guardar y cargar.

var ui: Node
var eco: Economy
var _saved_state: RunState
var _saved_settings: UserSettings


func before_each() -> void:
	_saved_state = Game.economy.state
	_saved_settings = Game.settings
	Game.settings = UserSettings.new()
	Game.economy.state = RunState.new_run(Game.economy.config, 1, RandomNumberGenerator.new())
	Game.economy._recalc()
	eco = Game.economy
	var vp := SubViewport.new()
	vp.size = Vector2i(320, 240)
	add_child_autofree(vp)
	ui = (load("res://presentation/ui/tv_game_ui.tscn") as PackedScene).instantiate()
	vp.add_child(ui)
	await wait_process_frames(2)


func after_each() -> void:
	Game.running = false
	Game.set_holding(false)
	Game.economy.state = _saved_state
	Game.economy._recalc()
	Game.settings = _saved_settings


func _key(keycode: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode
	ev.pressed = true
	ui._unhandled_input(ev)


func _action(action: StringName, pressed := true) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ui._unhandled_input(ev)


func _start_playing() -> void:
	ui.start_in_menu()
	ui._menu.play_requested.emit()
	await wait_seconds(0.6)


func _rich(amount: float) -> void:
	eco.state.energy = amount
	eco.state.energy_produced_run = amount


func test_menu_freezes_the_run_and_play_starts_it() -> void:
	ui.start_in_menu()
	assert_true(ui.is_in_menu())
	var e0 := eco.state.energy
	Game.tick(5.0)
	assert_eq(eco.state.energy, e0, "en el menú no pasa el tiempo")
	ui._menu.play_requested.emit()
	await wait_seconds(0.6)
	assert_true(Game.running)
	assert_true(ui._osd.is_intro_visible(), "partida nueva: carta de ajuste")


func test_click_shows_real_amount_and_respects_cap() -> void:
	await _start_playing()
	eco.state.perks.append(&"pulse")
	eco._recalc()
	var e0 := eco.state.energy
	ui._click(Vector2(150, 150))
	assert_almost_eq(eco.state.energy - e0, eco.manual_click_value() if not eco.last_click_crit else eco.state.energy - e0,
			0.0001)
	assert_false(ui._osd.is_intro_visible(), "el primer clic quita la carta")
	var counted := 0
	for i in 30:
		var before := eco.state.manual_clicks
		ui._click(Vector2(150, 150))
		counted += eco.state.manual_clicks - before
	assert_eq(counted, 9, "tope de 10 clics por segundo (1 ya gastado)")


func test_shop_pause_and_keys() -> void:
	await _start_playing()
	_action(&"tv_shop")
	assert_true(ui._tree.visible, "E abre las mejoras")
	_action(&"ui_cancel")
	assert_false(ui._tree.visible, "Esc las cierra")
	_action(&"ui_cancel")
	assert_true(ui.is_paused(), "Esc abre la pausa")
	assert_false(Game.running)
	var clicks := eco.state.manual_clicks
	_action(&"tv_click")
	assert_eq(eco.state.manual_clicks, clicks, "en pausa, Espacio no clica")
	_key(KEY_1)
	assert_false(ui._tree.visible)
	ui.close_pause()
	assert_true(Game.running)


func test_buy_from_tree_and_tapes_and_skills() -> void:
	await _start_playing()
	_rich(100000.0)
	ui._tree.buy_requested.emit(&"pulse")
	assert_true(eco.is_bought(&"pulse"))
	assert_true(Game.buy(&"tuning"))
	assert_true(Game.buy(&"dial_hold"))
	assert_false(Game.buy(&"sweep"), "las habilidades se abren en la run 2")
	eco.state.run_index = 2
	assert_true(Game.buy(&"sweep"))
	# Cinta: se llena la barra a mano y aparece en su hueco de la nieve; al pulsarla da Energía y desaparece.
	eco.state.package_bar = eco.bar_size() - 0.5
	ui._click(Vector2(150, 150))
	assert_eq(eco.packages().size(), 1)
	await wait_process_frames(1)
	var slot: int = eco.packages()[0]["slot"]
	assert_true(ui._factory.get_tape(slot).visible)
	var e0 := eco.state.energy
	ui._factory.package_pressed.emit(slot)
	assert_eq(eco.packages().size(), 0)
	assert_true(eco.state.energy > e0 or eco.timer(&"black") > 0.0, "la cinta da Energía o el ×3 de la negra")
	# Habilidad con la tecla 1.
	_key(KEY_1)
	assert_gt(eco.timer(&"sweep"), 0.0, "tecla 1: Barrido")
	assert_gt(eco.skill_cooldown(&"sweep"), 0.0)


func test_event_catch_through_the_screen() -> void:
	await _start_playing()
	var e := eco.config.find_event(&"interference")
	eco.state.event_id = e.id
	eco.state.event_left = e.duration
	await wait_process_frames(2)
	var e0 := eco.state.energy
	ui._factory.event_pressed.emit()
	assert_eq(eco.state.events_caught, 1)
	assert_gt(eco.state.energy, e0)
	assert_eq(eco.state.event_id, &"")


func test_restart_card_then_carga_then_run_2() -> void:
	await _start_playing()
	_rich(eco.config.threshold * 1.2)
	ui._osd.restart_pressed.emit()
	await wait_process_frames(2)
	assert_true(Game.in_sequence(), "tras la run 1 llama el vecino (specs/hito4b.md D1)")
	assert_eq(eco.state.run_index, 2)
	assert_eq(eco.state.carga, 3)
	var clicks := eco.state.manual_clicks
	_action(&"tv_click")
	assert_eq(eco.state.manual_clicks, clicks, "durante la carta no se clica")
	await wait_seconds(EndOfBroadcast.DURATION + 0.3)
	assert_false(ui.is_restarting(), "la Carga espera a que acabe la secuencia")
	assert_true(ui._static.visible, "la tele se queda sin señal")
	_action(&"tv_click")
	assert_eq(eco.state.manual_clicks, clicks, "sin señal no se clica")
	Game.sequence_done(&"handed_over")
	Game.sequence_done(&"sat")
	await wait_process_frames(1)
	assert_true(ui.is_restarting(), "al sentarse tras el vecino, la pantalla de Carga")
	assert_false(ui._static.visible)
	assert_true(Game.buy_perk(&"pulse"))
	ui._carga.start_requested.emit()
	assert_true(Game.running)
	assert_false(ui.is_restarting())
	assert_almost_eq(eco.manual_click_value(), eco.click_value() * 1.4, 0.0001, "Tu pulso se nota en la run 2")


func test_save_and_load_keeps_everything() -> void:
	_rich(5000.0)
	Game.buy(&"pulse")
	Game.buy(&"tuning")
	eco.state.perks.append(&"name")
	eco.state.carga = 2
	eco.state.manual_clicks = 77
	eco.state.package_bar = 12.0
	eco.state.timers["cd_sweep"] = 30.0
	eco._recalc()
	var dir := "user://test_flow_save"
	var saves := SaveSystem.new(dir)
	assert_true(saves.save_run(eco.state))
	var loaded := saves.load_run(eco.config)
	var again := Economy.new(eco.config, loaded, 1)
	assert_almost_eq(again.manual_click_value(), eco.manual_click_value(), 0.0001, "mismas mejoras y permanentes")
	assert_eq(again.state.manual_clicks, 77)
	assert_almost_eq(again.state.package_bar, 12.0, 0.0001)
	assert_almost_eq(again.skill_cooldown(&"sweep"), 30.0, 0.0001)
	assert_true(again.mods.packages)
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	DirAccess.remove_absolute(dir)


func test_the_frame_shows_through_the_snow_and_the_picture_comes_back() -> void:
	ui.start_playing()
	ui.show_frame(PlaceholderTexture2D.new())
	var frame: TextureRect = ui.get_node("Frame")
	var times := [0]
	frame.visibility_changed.connect(func() -> void: times[0] += int(frame.visible))
	assert_true(ui._static.visible)
	await wait_seconds(2.5)
	assert_eq(times[0], ui.FRAME_COUNT)
	assert_false(ui._static.visible)
	assert_false(is_instance_valid(frame))


func test_load_mid_sequence_repeats_it_without_carga() -> void:
	eco.state = RunState.new_run(eco.config, 2, RandomNumberGenerator.new())
	eco.state.carga = 3
	eco.state.sequence = Sequence.NEIGHBOR
	eco.state.step = &"knock"
	eco._recalc()
	await _start_playing()
	assert_false(ui.is_restarting(), "no se salta la secuencia")
	assert_true(ui._static.visible)
	assert_true(Game.running, "el reloj corre: los golpes llegan")
