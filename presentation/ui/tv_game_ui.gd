extends Control

# Solo pinta: lee Game.economy y reenvía la entrada a Game. Sin lógica de juego.

@onready var _energy_label: Label = $Layout/Left/EnergyLabel
@onready var _production_label: Label = $Layout/Left/ProductionLabel
@onready var _dial: Button = $Layout/Left/Dial
@onready var _restart_button: Button = $Layout/Left/RestartButton
@onready var _restart_progress: Label = $Layout/Left/RestartProgress
@onready var _shop_list: VBoxContainer = $Layout/ShopScroll/ShopList
@onready var _interference: Button = $Interference
@onready var _purchase_sound: AudioStreamPlayer = $PurchaseSound

var _rows: Dictionary = {}  # StringName -> Button


func _ready() -> void:
	_dial.text = tr("UI_DIAL")
	_restart_button.text = tr("UI_RESTART")
	$Interference/Hint.text = tr("UI_INTERFERENCE")
	_dial.pressed.connect(Game.click)
	_dial.button_down.connect(Game.set_holding.bind(true))
	_dial.button_up.connect(Game.set_holding.bind(false))
	_restart_button.pressed.connect(Game.restart)
	_interference.pressed.connect(Game.catch_interference)
	EventBus.purchase_made.connect(func(_id: StringName) -> void: _purchase_sound.play())
	EventBus.run_restarted.connect(func(_run: int) -> void: _clear_rows())


func _process(_delta: float) -> void:
	var eco := Game.economy
	var state := eco.state
	_energy_label.text = tr("UI_ENERGY") % NumberFormat.energy(state.energy)
	_production_label.text = tr("UI_PRODUCTION") % NumberFormat.rate(eco.production_per_second())
	_restart_button.disabled = not eco.can_restart()
	_restart_progress.text = tr("UI_RESTART_PROGRESS") % [
		NumberFormat.energy(state.energy_produced_run), NumberFormat.energy(eco.config.threshold)]
	_interference.visible = eco.interference_active()
	for g in eco.visible_generators():
		var row := _row(g.id)
		row.text = tr("UI_GENERATOR_ROW") % [
			tr(g.name_key), eco.owned(g.id), NumberFormat.rate(eco.generator_production(g.id)), NumberFormat.energy(eco.cost_of(g.id))]
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
