extends Node

# Punto de montaje (specs/hito2.md D1, §5): salón, tele, cámara, luces y ajustes gráficos. Es también
# la escena de arranque: el menú principal se muestra en la tele.
# Variables TLR_* solo en la build de depuración; la exportada las ignora.

const FLAT := preload("res://world/player_flat/flat.tscn")
const TV := preload("res://presentation/tv/tv.tscn")
const CAMERA := preload("res://presentation/camera/game_camera.tscn")
const PLAYER := preload("res://presentation/player/player.tscn")
const STAND_OFFSET := 0.6  # de pie, delante del asiento hacia la tele
const TRANSITION := 0.5
const VIEWS: Array[StringName] = [&"game", &"sofa", &"window", &"door", &"corner"]

var mixer: LightMixer
var settings: GraphicsSettings

var _room: Node3D
var _film_grain: CanvasLayer
var _camera: Camera3D
var _player: Player
var _ui: Node
var _flashlight_on := false


func _ready() -> void:
	# Interpolación física (project.godot) solo para el jugador, que anda en _physics_process; el resto de la
	# escena se mueve en _process y con ella daría tirones.
	physics_interpolation_mode = PHYSICS_INTERPOLATION_MODE_OFF
	var flat := FLAT.instantiate()
	flat.mirrored = _dev("TLR_MIRROR") == "1"
	add_child(flat)
	var room: Node3D = flat.living_room  # anclas, entorno, luces y cámaras de captura siguen siendo del salón
	_room = room
	var tv := TV.instantiate()
	add_child(tv)
	tv.global_transform = room.get_anchor(&"TvAnchor").global_transform
	var camera := CAMERA.instantiate()
	add_child(camera)
	camera.setup(room.get_anchor(&"SeatAnchor"), tv.get_screen_node(), tv.get_screen_size(), tv.get_input())
	_camera = camera
	_player = PLAYER.instantiate()
	add_child(_player)
	_player.setup(flat.get_layout(), flat.mirrored)
	_player.sit_requested.connect(_sit_down)

	var environment: Environment = room.get_environment().environment
	mixer = LightMixer.new(flat.get_lights(), tv.get_screen_light(), camera.get_flashlight(), environment, room.get_ambient())
	settings = GraphicsSettings.new(get_viewport(), environment, room.get_voxel_gi(), room.get_reflection_probe(),
			camera.get_flashlight(), mixer)
	var dev_preset := StringName(_dev("TLR_PRESET"))
	if _dev("TLR_GI") == "0":
		settings.overrides["gi"] = false
	# TLR_OFF=ssil,fog,…: apaga esas claves (solo las de sí/no) del preset para medir cuánto cuesta cada efecto.
	for key in _dev("TLR_OFF").split(",", false):
		if GraphicsSettings.PRESETS[&"high"].get(key) is bool:
			settings.overrides[key] = false
	var flicker := LightFlicker.new()
	flicker.name = "LightFlicker"
	add_child(flicker)
	flicker.setup(mixer, flat.get_lights(), camera.get_flashlight())
	_add_film_grain()
	_apply_user_settings()
	var preset_now := func() -> StringName: return dev_preset if dev_preset in GraphicsSettings.PRESETS else Game.settings.quality
	settings.apply_preset(preset_now.call())
	EventBus.settings_changed.connect(func() -> void:
		_apply_user_settings()
		settings.apply_preset(preset_now.call()))
	# Al pasar a pantalla completa (o cambiar la ventana) se recalcula la resolución interna del 3D.
	get_viewport().size_changed.connect(func() -> void: settings.apply_preset(settings.current["preset"]))
	tv.screen_state_changed.connect(mixer.set_tv_state)
	# El menú tiene la misma luz que la partida (usuario, 2026-11-19).
	if _dev("TLR_DARK") == "1":
		set_lighting_state(&"dark")
	# El juego arranca en el menú de la tele; las capturas y el benchmark entran directamente a jugar.
	var ui: Node = tv.get_subviewport().get_child(0)
	var skip_menu := _dev("TLR_SKIP_MENU") == "1" or _dev("TLR_BENCHMARK") == "1" or _dev("TLR_VIEW") not in ["", "game"]
	_ui = ui
	if skip_menu:
		ui.start_playing()
	else:
		ui.start_in_menu()
	# TLR_SPAWN=<zona>: de pie en el centro de esa zona (capturas del piso).
	var spawn := StringName(_dev("TLR_SPAWN"))
	if spawn != &"":
		var zone: ZoneDef = flat.get_layout().find_zone(spawn)
		if zone == null:
			push_warning("TLR_SPAWN: zona desconocida %s" % spawn)
		else:
			var c := zone.rect.get_center()
			# TLR_YAW / TLR_PITCH=grados (hacia dónde mira; pitch negativo, hacia el suelo) y TLR_FLASH=1 (linterna
			# encendida), para capturar las habitaciones a oscuras.
			var look := Vector3(deg_to_rad(float(_dev("TLR_PITCH"))), deg_to_rad(float(_dev("TLR_YAW"))), 0.0)
			_stand(Transform3D(Basis.from_euler(look), Vector3(-c.x if flat.mirrored else c.x, 0.0, c.y)))
			if _dev("TLR_FLASH") == "1":
				_flashlight_on = true
				mixer.set_flashlight_on(true)

	var view := _dev("TLR_VIEW")
	if view != "" and view != "game":
		var capture: Camera3D = room.get_capture_camera(StringName(view))
		if capture:
			capture.make_current()
	if _dev("TLR_BENCHMARK") == "1":
		var bench := Benchmark.new()
		bench.label = "preset=%s mirror=%s dark=%s gi=%s off=%s" % [settings.current["preset"], room.mirrored,
				_dev("TLR_DARK") == "1", settings.current["gi"], _dev("TLR_OFF")]
		if spawn != &"":  # con TLR_SPAWN mide desde ese sitio del piso
			bench.cameras.append(_player.camera)
		else:
			bench.cameras.append(camera)
			for v in VIEWS.slice(1):
				bench.cameras.append(room.get_capture_camera(v))
		add_child(bench)
	tree_exiting.connect(func() -> void: Game.running = false)
	print("BOOT_OK")
	# TLR_SHOT=ruta.png: guarda lo que se ve a los 6 s (la GI y el TAA ya asentados) y cierra.
	if _dev("TLR_SHOT") != "":
		await get_tree().create_timer(6.0).timeout
		get_viewport().get_texture().get_image().save_png(_dev("TLR_SHOT"))
		get_tree().quit()


func _apply_user_settings() -> void:
	var s := Game.settings
	settings.brightness = s.brightness
	settings.user_scale = s.render_scale
	settings.max_rows = s.resolution.y
	_film_grain.visible = s.film_grain


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	# Q, solo en la build de pruebas: en la normal, levantarse llega con el repartidor (specs/hito4a.md D7, P2).
	if (event as InputEventKey).physical_keycode == KEY_Q and OS.is_debug_build() and not _player.active and _ui.is_idle():
		var seat: Transform3D = _room.get_anchor(&"SeatAnchor").global_transform
		_stand(Transform3D(seat.basis, Vector3(seat.origin.x, 0.0, seat.origin.z) - seat.basis.z * STAND_OFFSET))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("flashlight") and _player.active:
		_flashlight_on = not _flashlight_on
		mixer.set_flashlight_on(_flashlight_on)


func _stand(t: Transform3D) -> void:
	Game.set_holding(false)
	_player.stand_at(t)
	_camera.get_flashlight().reparent(_player.camera, false)
	_transition(_camera, _player.camera)


## Clic en el sofá o Esc de pie: se sienta; con Esc, además, la pausa de la tele (no hay pausa propia de pie).
func _sit_down() -> void:
	var paused := Input.is_action_pressed("ui_cancel")
	_player.sit()
	_flashlight_on = false  # sentado no alumbra la tele: al levantarse se vuelve a encender con F
	mixer.set_flashlight_on(false)
	_player.camera.get_node("Flashlight").reparent(_camera, false)
	_transition(_player.camera, _camera)
	if paused:
		_ui.open_pause()


# La cámara viaja de una pose a la otra en TRANSITION segundos; mientras, el jugador no se mueve.
func _transition(from: Camera3D, to: Camera3D) -> void:
	var travel := Camera3D.new()
	add_child(travel)
	travel.global_transform = from.global_transform
	travel.fov = from.fov
	travel.make_current()
	var tween := travel.create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	tween.tween_property(travel, "global_transform", to.global_transform, TRANSITION)
	tween.tween_property(travel, "fov", to.fov, TRANSITION)
	tween.chain().tween_callback(func() -> void:
		to.make_current()
		travel.queue_free())


func _add_film_grain() -> void:
	var layer := CanvasLayer.new()
	_film_grain = layer
	layer.name = "FilmGrain"
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = ShaderMaterial.new()
	(rect.material as ShaderMaterial).shader = preload("res://presentation/graphics/film_grain.gdshader")
	layer.add_child(rect)
	add_child(layer)


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
