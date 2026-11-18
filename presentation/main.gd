extends Node

# Punto de montaje (specs/hito2.md D1, §5): salón, tele, cámara, luces y ajustes gráficos. Es también
# la escena de arranque: el menú principal se muestra en la tele, con el salón a oscuras.
# Variables TLR_* solo en la build de depuración; la exportada las ignora.

const ROOM := preload("res://world/player_flat/living_room.tscn")
const TV := preload("res://presentation/tv/tv.tscn")
const CAMERA := preload("res://presentation/camera/game_camera.tscn")
const VIEWS: Array[StringName] = [&"game", &"sofa", &"window", &"door", &"corner"]

var mixer: LightMixer
var settings: GraphicsSettings

var _room: Node3D


func _ready() -> void:
	var room := ROOM.instantiate()
	_room = room
	room.mirrored = _dev("TLR_MIRROR") == "1"
	add_child(room)
	var tv := TV.instantiate()
	add_child(tv)
	tv.global_transform = room.get_anchor(&"TvAnchor").global_transform
	var camera := CAMERA.instantiate()
	add_child(camera)
	camera.setup(room.get_anchor(&"SeatAnchor"), tv.get_screen_node(), tv.get_screen_size(), tv.get_input())

	var environment: Environment = room.get_environment().environment
	mixer = LightMixer.new(room.get_lights(), tv.get_screen_light(), camera.get_flashlight(), environment, room.get_ambient())
	settings = GraphicsSettings.new(get_viewport(), environment, room.get_voxel_gi(), room.get_reflection_probe(),
			camera.get_flashlight(), mixer)
	var preset := _dev("TLR_PRESET")
	settings.apply_preset(StringName(preset) if preset in ["low", "medium", "high", "ultra"] else Game.settings.quality)
	EventBus.settings_changed.connect(func() -> void: settings.apply_preset(Game.settings.quality))
	# Al pasar a pantalla completa (o cambiar la ventana) se recalcula la resolución interna del 3D.
	get_viewport().size_changed.connect(func() -> void: settings.apply_preset(settings.current["preset"]))
	if _dev("TLR_GI") == "0":
		settings.set_gi(false)
	tv.screen_state_changed.connect(mixer.set_tv_state)
	var play_light: StringName = &"dark" if _dev("TLR_DARK") == "1" else &"normal"
	EventBus.tv_menu_changed.connect(func(open: bool) -> void: set_lighting_state(&"menu" if open else play_light))
	# El juego arranca en el menú de la tele; las capturas y el benchmark entran directamente a jugar.
	var ui: Node = tv.get_subviewport().get_child(0)
	var skip_menu := _dev("TLR_SKIP_MENU") == "1" or _dev("TLR_BENCHMARK") == "1" or _dev("TLR_VIEW") not in ["", "game"]
	if skip_menu:
		ui.start_playing()
	else:
		ui.start_in_menu()

	var view := _dev("TLR_VIEW")
	if view != "" and view != "game":
		var capture: Camera3D = room.get_capture_camera(StringName(view))
		if capture:
			capture.make_current()
	if _dev("TLR_BENCHMARK") == "1":
		var bench := Benchmark.new()
		bench.label = "preset=%s mirror=%s dark=%s gi=%s" % [settings.current["preset"], room.mirrored,
				_dev("TLR_DARK") == "1", settings.current["gi"]]
		bench.cameras.append(camera)
		for v in VIEWS.slice(1):
			bench.cameras.append(room.get_capture_camera(v))
		add_child(bench)
	tree_exiting.connect(func() -> void: Game.running = false)
	print("BOOT_OK")


func set_lighting_state(state: StringName) -> void:
	mixer.set_state(state)
	_recapture_probe()


# La sonda en modo «una vez» se vuelve a capturar si se pone un instante en «siempre».
func _recapture_probe() -> void:
	var probe: ReflectionProbe = _room.get_reflection_probe()
	if DisplayServer.get_name() == "headless":
		return
	probe.update_mode = ReflectionProbe.UPDATE_ALWAYS
	await get_tree().process_frame
	await get_tree().process_frame
	probe.update_mode = ReflectionProbe.UPDATE_ONCE


func _dev(variable: String) -> String:
	return OS.get_environment(variable) if OS.is_debug_build() else ""
