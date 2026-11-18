extends Node

const CONFIG_PATH := "res://data/economy_run1.tres"
const AUTOSAVE_INTERVAL := 300.0

var economy: Economy

var _saves := SaveSystem.new()
var _holding := false
var _since_save := 0.0
# TLR_NO_SAVE=1 (tests y verify.sh): no se toca la partida real. Va en una variable de entorno porque GUT rechaza argumentos que no conoce.
var _no_save := OS.get_environment("TLR_NO_SAVE") == "1"


func _ready() -> void:
	get_tree().auto_accept_quit = false
	var config: EconomyConfig = load(CONFIG_PATH)
	var state: RunState = null if _no_save else _saves.load_run(config)
	economy = Economy.new(config, state)
	economy.purchased.connect(func(id: StringName) -> void: EventBus.purchase_made.emit(id))
	economy.restarted.connect(_on_restarted)
	if state == null:
		_save()


func tick(delta: float) -> void:
	economy.tick(delta, _holding)
	_since_save += delta
	if _since_save >= AUTOSAVE_INTERVAL:
		_save()


func click() -> void:
	economy.click()


func set_holding(value: bool) -> void:
	_holding = value


func buy(id: StringName) -> bool:
	return economy.buy(id)


func catch_event() -> bool:
	return economy.catch_event()


func restart() -> bool:
	return economy.restart()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		set_holding(false)
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save()  # si falla, se cierra igual
		get_tree().quit()


func _on_restarted(run_index: int) -> void:
	EventBus.run_restarted.emit(run_index)
	_save()


func _save() -> void:
	_since_save = 0.0
	if not _no_save:
		_saves.save_run(economy.state)
