extends Control

# Solo pinta: lee Game.economy y reenvía la entrada a Game. Sin lógica de juego.
# Pantalla de 320 × 240 en pixel art (specs/hito2.md D19): la fábrica ocupa toda la pantalla, arriba una
# barra con los datos y el árbol de mejoras se abre encima al pulsar la fábrica (o con E).
# Teclado: Espacio sintoniza (mantenerlo = mantener pulsado), E abre o cierra las mejoras, Esc las cierra,
# flechas e Intro se mueven por el árbol y compran.

@onready var _hud: Label = $Hud/Text
@onready var _restart_button: Button = $Hud/RestartButton
@onready var _factory: FactoryView = $FactoryView
@onready var _tree: UpgradeTree = $UpgradeTree
@onready var _purchase_sound: AudioStreamPlayer = $PurchaseSound

var _hinted := false


func _ready() -> void:
	_restart_button.text = tr("UI_RESTART")
	_restart_button.pressed.connect(Game.restart)
	_factory.machine_pressed.connect(_click)
	_factory.hold_changed.connect(Game.set_holding)
	_factory.shop_requested.connect(_open_shop)
	_factory.interference_pressed.connect(Game.catch_interference)
	_tree.buy_requested.connect(Game.buy)
	_tree.close_requested.connect(_close_shop)
	EventBus.purchase_made.connect(func(_id: StringName) -> void: _purchase_sound.play())


func _process(_delta: float) -> void:
	var eco := Game.economy
	var state := eco.state
	var percent := mini(100, int(100.0 * state.energy_produced_run / eco.config.threshold))
	_hud.text = tr("UI_HUD") % [NumberFormat.energy(state.energy), NumberFormat.rate(eco.production_per_second()),
		NumberFormat.per_click(eco.click_value()), percent]
	_restart_button.visible = eco.can_restart()
	if not _hinted and state.energy_produced_run == 0.0:
		_hinted = true
		_factory.float_text(_factory.get_receptor().position + Vector2(13, -2), tr("UI_HINT_CLICK"))


func _unhandled_input(event: InputEvent) -> void:
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


func _open_shop() -> void:
	Game.set_holding(false)
	_tree.show()
	_tree.focus_first()


func _close_shop() -> void:
	_tree.hide()
