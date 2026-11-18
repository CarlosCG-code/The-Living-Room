extends Control

# Solo pinta: lee Game.economy y reenvía la entrada a Game. Sin lógica de juego.
# Pantalla de 320 × 240 en pixel art (specs/hito2.md D19): la fábrica ocupa toda la pantalla, arriba una
# barra con los datos y el árbol de mejoras se abre encima al pulsar la fábrica (o con E).
# Teclado: Espacio sintoniza (mantenerlo = mantener pulsado), E abre o cierra las mejoras, Esc las cierra,
# flechas e Intro se mueven por el árbol y compran.

const MENU_SCENE := "res://world/main_menu/main_menu.tscn"

@onready var _osd: TvOsd = $Osd
@onready var _factory: FactoryView = $FactoryView
@onready var _tree: UpgradeTree = $UpgradeTree
@onready var _purchase_sound: AudioStreamPlayer = $PurchaseSound

var _hinted := false
var _pause: MainMenuUI


func _ready() -> void:
	_osd.restart_pressed.connect(Game.restart)
	_factory.generator_shown.connect(func(id: StringName) -> void:
		var g := Game.economy.config.find_generator(id)
		_osd.notify("+ " + tr(g.name_key)))
	_factory.machine_pressed.connect(_click)
	_factory.hold_changed.connect(Game.set_holding)
	_factory.shop_requested.connect(_open_shop)
	_factory.event_pressed.connect(Game.catch_event)
	_tree.buy_requested.connect(Game.buy)
	_tree.close_requested.connect(_close_shop)
	EventBus.purchase_made.connect(func(_id: StringName) -> void: _purchase_sound.play())
	_pause = (load("res://presentation/ui/main_menu_ui.tscn") as PackedScene).instantiate()
	_pause.pause_menu = true
	_pause.hide()
	add_child(_pause)
	_pause.resume_requested.connect(close_pause)
	_pause.menu_requested.connect(func() -> void: get_tree().change_scene_to_file(MENU_SCENE))
	# Salir pasa por el cierre normal: Game guarda la partida antes de cerrar.
	_pause.quit_requested.connect(func() -> void: get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST))


func _process(_delta: float) -> void:
	var eco := Game.economy
	var state := eco.state
	_osd.show_values(NumberFormat.energy(state.energy), NumberFormat.rate(eco.production_per_second()),
		NumberFormat.per_click(eco.click_value()), state.energy_produced_run / eco.config.threshold,
		eco.can_restart(), not _tree.visible and _has_affordable(eco))
	if not _hinted and state.energy_produced_run == 0.0:
		_hinted = true
		_factory.float_text(_factory.get_receptor().position + Vector2(13, -2), tr("UI_HINT_CLICK"))


func _unhandled_input(event: InputEvent) -> void:
	if _pause.visible:
		return
	if event.is_action_pressed("ui_cancel") and not _tree.visible:
		open_pause()
		get_viewport().set_input_as_handled()
		return
	if _tree.visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("tv_shop"):
			_close_shop()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("tv_shop"):
		_open_shop()
		get_viewport().set_input_as_handled()
	elif event.is_action("tv_click") and not event.is_echo():
		if event.is_pressed():
			_click(_factory.press_receptor())
		Game.set_holding(event.is_pressed())
		get_viewport().set_input_as_handled()


func _click(at: Vector2) -> void:
	Game.click()
	_factory.float_text(at, "+" + NumberFormat.per_click(Game.economy.click_value()))


## Esc durante la partida: la partida se para y la tele muestra el menú de pausa.
func open_pause() -> void:
	Game.set_holding(false)
	Game.running = false
	_pause.show()
	_pause.show_main()


func close_pause() -> void:
	_pause.hide()
	Game.running = true


func is_paused() -> bool:
	return _pause.visible


func _open_shop() -> void:
	Game.set_holding(false)
	_tree.show()
	_tree.focus_first()


func _close_shop() -> void:
	_tree.hide()


func _has_affordable(eco: Economy) -> bool:
	for g in eco.visible_generators():
		if eco.state.energy >= eco.cost_of(g.id):
			return true
	for u in eco.visible_upgrades():
		if eco.state.energy >= u.cost:
			return true
	return false
