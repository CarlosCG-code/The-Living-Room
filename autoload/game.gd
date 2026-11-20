extends Node

const CONFIG_PATH := "res://data/economy_run1.tres"
const AUTOSAVE_INTERVAL := 300.0
const SETTINGS_PATH := "user://settings.cfg"

var economy: Economy
var settings: UserSettings
## La partida solo avanza dentro del salón; en el menú principal está quieta.
var running := false

var _saves := SaveSystem.new()
var _holding := false
var _since_save := 0.0
var _window_applied := []  # [pantalla completa, resolución] aplicados por última vez
# TLR_NO_SAVE=1 (tests y verify.sh): no se toca la partida real. Va en una variable de entorno porque GUT rechaza argumentos que no conoce.
# Con GUT tampoco, aunque falte la variable.
var _no_save := OS.get_environment("TLR_NO_SAVE") == "1" or "gut_cmdln" in " ".join(OS.get_cmdline_args())


func _ready() -> void:
	get_tree().auto_accept_quit = false
	var config: EconomyConfig = load(CONFIG_PATH)
	var state: RunState = null if _no_save else _saves.load_run(config)
	economy = Economy.new(config, state)
	economy.purchased.connect(func(id: StringName) -> void: EventBus.purchase_made.emit(id))
	economy.restarted.connect(_on_restarted)
	if state == null:
		_save()
	settings = UserSettings.new() if _no_save else UserSettings.load_from(SETTINGS_PATH)
	apply_settings()


## Aplica lo global (pantalla, fps, volumen) y avisa a las escenas (calidad, brillo, filtro de la tele).
func apply_settings() -> void:
	if DisplayServer.get_name() != "headless":
		_apply_window()
		var vsync := DisplayServer.VSYNC_ENABLED if settings.vsync else DisplayServer.VSYNC_DISABLED
		if DisplayServer.window_get_vsync_mode() != vsync:  # cambiarlo rehace la cadena de imágenes: un tirón
			DisplayServer.window_set_vsync_mode(vsync)
	Engine.max_fps = settings.max_fps
	AudioServer.set_bus_volume_db(0, linear_to_db(settings.volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"TV"), linear_to_db(settings.volume_tv))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Room"), linear_to_db(settings.volume_room))
	EventBus.settings_changed.emit()


# En ventana, la resolución es el tamaño de la ventana (centrada; «la de la pantalla» = maximizada); en
# pantalla completa la ventana ocupa la pantalla y la resolución solo limita el 3D (main.gd). Solo se toca
# si cambió el modo o la resolución: así subir el volumen no deshace la ventana que el jugador arrastró.
func _apply_window() -> void:
	var wanted := [settings.fullscreen, settings.resolution]
	if wanted == _window_applied:
		return
	_window_applied = wanted
	if settings.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	if settings.resolution == Vector2i.ZERO:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var screen := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	# Tamaño y posición son del área de dibujo; el marco y la barra de título van aparte y deben caber.
	var border := DisplayServer.window_get_size_with_decorations() - DisplayServer.window_get_size()
	var room := Vector2(screen.size - border)
	var fit := minf(1.0, minf(room.x / settings.resolution.x, room.y / settings.resolution.y))
	var size := Vector2i(Vector2(settings.resolution) * fit)  # si no cabe, se encoge sin deformarse
	DisplayServer.window_set_size(size)
	var corner := screen.position + (screen.size - size - border) / 2
	DisplayServer.window_set_position(corner + Vector2i(border.x / 2, border.y - border.x / 2))


func save_settings() -> void:
	if not _no_save:
		settings.save_to(SETTINGS_PATH)


func has_progress() -> bool:
	return economy.state.energy_produced_run > 0.0 or economy.state.run_index > 1


func tick(delta: float) -> void:
	if not running:
		return
	economy.tick(delta, _holding)
	_since_save += delta
	if _since_save >= AUTOSAVE_INTERVAL:
		_save()


## Clic a mano: Energía ganada (0 si no cuenta).
func click() -> float:
	return economy.click() if running else 0.0


# Con la partida parada (menú, pausa, carta, Carga) no se clica, ni se usan habilidades ni se abren cintas.
func use_skill(skill: StringName) -> bool:
	return running and economy.use_skill(skill)


func open_package(i: int) -> float:
	return economy.open_package(i) if running else 0.0


func buy_perk(id: StringName) -> bool:
	return economy.buy_perk(id)


func set_holding(value: bool) -> void:
	_holding = value


func buy(id: StringName) -> bool:
	return economy.buy(id)


func catch_event() -> bool:
	return running and economy.catch_event()


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
