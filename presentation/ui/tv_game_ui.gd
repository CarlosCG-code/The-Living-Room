extends Control

# Solo pinta: lee Game.economy y reenvía la entrada a Game. Sin lógica de juego.
# Pantalla de 320 × 240 (specs/hito2.md D19): fábrica a la izquierda, panel con el dial a la derecha
# y la tienda en una ventana que se abre al pulsar la fábrica.

@onready var _energy_label: Label = $Side/EnergyLabel
@onready var _production_label: Label = $Side/ProductionLabel
@onready var _click_label: Label = $Side/ClickLabel
@onready var _dial: Button = $Side/Dial
@onready var _restart_button: Button = $Side/RestartButton
@onready var _restart_progress: Label = $Side/RestartProgress
@onready var _factory: FactoryView = $FactoryView
@onready var _shop_window: Panel = $ShopWindow
@onready var _shop_list: VBoxContainer = $ShopWindow/Box/ShopScroll/ShopList
@onready var _purchase_sound: AudioStreamPlayer = $PurchaseSound

var _rows: Dictionary = {}  # StringName -> Button
var _knob := FactoryMachine.new(&"dial")


func _ready() -> void:
	_restart_button.text = tr("UI_RESTART")
	$ShopWindow/Box/Header/Title.text = tr("UI_SHOP_TITLE")
	$ShopWindow/Box/Header/Close.text = tr("UI_CLOSE")
	$ShopWindow/Box/Header/Close.pressed.connect(_shop_window.hide)
	_factory.shop_requested.connect(_shop_window.show)
	_factory.interference_pressed.connect(Game.catch_interference)
	_dial.pressed.connect(Game.click)
	_dial.pressed.connect(func() -> void: _knob.angle += TAU / 12)
	# El mando y su texto debajo, dentro del botón (el texto de un Button siempre va centrado).
	_knob.size = Vector2(44, 44)
	_dial.add_child(_knob)
	var dial_label := Label.new()
	dial_label.text = tr("UI_DIAL")
	dial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dial_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dial.add_child(dial_label)
	_dial.resized.connect(func() -> void:
		dial_label.position = Vector2(0, _dial.size.y - 14)
		dial_label.size.x = _dial.size.x
		_knob.position = Vector2((_dial.size.x - 44) / 2, (_dial.size.y - 14 - 44) / 2).round())
	_dial.button_down.connect(Game.set_holding.bind(true))
	_dial.button_up.connect(Game.set_holding.bind(false))
	_restart_button.pressed.connect(Game.restart)
	EventBus.purchase_made.connect(func(_id: StringName) -> void: _purchase_sound.play())
	EventBus.run_restarted.connect(func(_run: int) -> void: _clear_rows())


func _process(delta: float) -> void:
	var eco := Game.economy
	# Dial solo y mantener pulsado: el mando gira solo, una muesca por clic.
	_knob.angle += eco.auto_clicks_per_second(_dial.button_pressed) * TAU / 12 * delta
	var state := eco.state
	_energy_label.text = tr("UI_ENERGY") % NumberFormat.energy(state.energy)
	_production_label.text = tr("UI_PRODUCTION") % NumberFormat.rate(eco.production_per_second())
	_click_label.text = tr("UI_PER_CLICK") % NumberFormat.per_click(eco.click_value())
	_restart_button.disabled = not eco.can_restart()
	_restart_progress.text = tr("UI_RESTART_PROGRESS") % [
		NumberFormat.energy(state.energy_produced_run), NumberFormat.energy(eco.config.threshold)]
	for g in eco.visible_generators():
		var row := _row(g.id)
		row.text = tr("UI_GENERATOR_ROW") % [
			tr(g.name_key), eco.owned(g.id), NumberFormat.per_click(eco.generator_click_bonus(g.id)),
			NumberFormat.rate(eco.generator_production(g.id)), NumberFormat.energy(eco.cost_of(g.id))]
		row.disabled = state.energy < eco.cost_of(g.id)
	for u in eco.visible_upgrades():
		var row := _row(u.id)
		row.text = tr("UI_UPGRADE_ROW") % [_upgrade_text(eco, u.name_key, u), _upgrade_text(eco, u.desc_key, u),
			NumberFormat.energy(u.cost)]
		row.disabled = state.energy < u.cost
	for id: StringName in _rows.keys():
		if eco.is_bought(id):
			_rows[id].queue_free()
			_rows.erase(id)


func _row(id: StringName) -> Button:
	if not _rows.has(id):
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		# Sin partir líneas, una fila larga ensancharía la ventana más allá de la pantalla.
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(Game.buy.bind(id))
		_shop_list.add_child(button)
		_rows[id] = button
	return _rows[id]


func _upgrade_text(eco: Economy, key: String, u: UpgradeDef) -> String:
	if u.target_id == &"":
		return tr(key)
	return tr(key) % tr(eco.config.find_generator(u.target_id).name_key)


func _clear_rows() -> void:
	for id: StringName in _rows:
		_rows[id].queue_free()
	_rows.clear()
