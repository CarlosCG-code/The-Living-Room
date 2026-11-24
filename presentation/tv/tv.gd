extends Node3D

# Tele de tubo (specs/hito2.md D5, §5): pantalla con la UI del hito 1 dentro de un SubViewport.

signal screen_state_changed(state: StringName)

const SCREEN_SIZE := Vector2(0.52, 0.39)
const SCREEN_SHADER := preload("res://presentation/tv/tv_screen.gdshader")
const SCREEN_LAYER := 2  # capa de render 2: la del cristal

## Lo que se ve en la pantalla: el incremental en el salón, el menú en el menú principal.
@export var ui_scene: PackedScene = preload("res://presentation/ui/tv_game_ui.tscn")

## Encendida o apagada (apagada: no se dibuja el SubViewport).
var power := true:
	set(value):
		power = value
		_update_power()

var _state: StringName = &""
var _material: ShaderMaterial
# Ambiente: zumbido de la tele (siempre) y dron grave al final de la run; HouseAudio los corta antes de algunos sonidos.
var _hum: AudioStreamPlayer3D
var _drone: AudioStreamPlayer3D
var _silence_left := 0.0
var _screen_sounds: Array[AudioStreamPlayer3D] = []
const SPEAKER_UNIT_SIZE := 4.0  # ~0 dB desde el sofá (a unos 4 m)
const HUM_DB := -17.0
## Oclusión de la tele por muros y puertas entre la cámara y la pantalla (usuario, 2026-11-20: se oía en toda la
## casa). Por número de obstáculos: corte del paso bajo (Hz) y ganancia (dB) de los efectos 2 y 3 del bus TV.
const OCCLUSION: Array[Vector2] = [Vector2(20000.0, 0.0), Vector2(1000.0, -9.0), Vector2(500.0, -16.0),
		Vector2(300.0, -24.0)]
const OCCLUSION_SPEED := 4.0  # 1/s: al cruzar una puerta el sonido se abre en un cuarto de segundo, no de golpe
var _occlusion_lp: AudioEffectLowPassFilter
var _occlusion_gain: AudioEffectAmplify

@onready var _subviewport: SubViewport = $SubViewport
@onready var _screen: MeshInstance3D = $Model/Screen
@onready var _screen_light: Light3D = $ScreenLight
@onready var _input: Node = $TvInput


func _ready() -> void:
	# Los sonidos de la pantalla (AudioStreamPlayer3D dentro del SubViewport) salen del altavoz de la tele, no
	# «dentro de la cabeza» (usuario, 2026-11-19). Se recogen al entrar en el árbol, también los que se crean luego.
	get_tree().node_added.connect(func(node: Node) -> void:
		if node is AudioStreamPlayer3D and _subviewport.is_ancestor_of(node):
			(node as AudioStreamPlayer3D).unit_size = SPEAKER_UNIT_SIZE
			(node as AudioStreamPlayer3D).bus = &"TV"  # filtrado de altavoz pequeño (default_bus_layout.tres)
			_screen_sounds.append(node))
	# La textura se asigna por código: una ViewportTexture puesta en la escena escribe un ERROR al cargar.
	_subviewport.add_child(ui_scene.instantiate())
	_material = ShaderMaterial.new()
	_material.shader = SCREEN_SHADER
	_material.set_shader_parameter(&"screen_tex", _subviewport.get_texture())
	_material.set_shader_parameter(&"warp", TvScreenMath.WARP)
	_screen.material_override = _material
	# La luz de la pantalla está delante del cristal: si lo iluminara, dejaría una mancha en el centro.
	_screen.layers = SCREEN_LAYER
	_screen_light.light_cull_mask &= ~SCREEN_LAYER
	_input.setup(_subviewport, _screen, SCREEN_SIZE)
	_hum = _loop_player("res://assets/audio/tv/tv_hum.wav", HUM_DB)
	_drone = _loop_player("res://assets/audio/tv/drone.wav", -80.0)
	var bus := AudioServer.get_bus_index(&"TV")
	_occlusion_lp = AudioServer.get_bus_effect(bus, 2) as AudioEffectLowPassFilter
	_occlusion_gain = AudioServer.get_bus_effect(bus, 3) as AudioEffectAmplify
	EventBus.settings_changed.connect(_apply_settings)
	EventBus.house_silence.connect(func(seconds: float) -> void: _silence_left = seconds)
	_apply_settings()
	_update_power()


func _process(delta: float) -> void:
	_ambience(delta)
	_occlusion(delta)
	# Un Node3D bajo un Control no hereda transformada: se coloca a mano en la pantalla (la tele se mueve tras _ready).
	for i in range(_screen_sounds.size() - 1, -1, -1):
		var p: Variant = _screen_sounds[i]
		if is_instance_valid(p):
			(p as AudioStreamPlayer3D).global_position = _screen.global_position
		else:
			_screen_sounds.remove_at(i)
	# La luz de la pantalla no cambia con los eventos: en la interferencia aclaraba todo el salón (usuario, 2026-11-19).
	var state: StringName = &"on" if power else &"off"
	if state != _state:
		_state = state
		screen_state_changed.emit(state)


func _apply_settings() -> void:
	_material.set_shader_parameter(&"crt", Game.settings.crt)


func get_screen_node() -> Node3D:
	return _screen


func get_screen_size() -> Vector2:
	return SCREEN_SIZE


func get_subviewport() -> SubViewport:
	return _subviewport


func get_screen_light() -> Light3D:
	return _screen_light


func get_input() -> Node:
	return _input


func _update_power() -> void:
	if not is_node_ready():
		return
	_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if power else SubViewport.UPDATE_DISABLED
	_screen.visible = power


func _loop_player(path: String, volume_db: float) -> AudioStreamPlayer3D:
	var stream: AudioStreamWAV = (load(path) as AudioStreamWAV).duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.volume_db = volume_db
	p.unit_size = 2.0
	p.bus = &"TV"
	add_child(p)
	if DisplayServer.get_name() != "headless":
		p.play()
	return p


# Cuanto más avanza la run (f), más dron. En los silencios (EventBus.house_silence) se corta el zumbido.
func _ambience(delta: float) -> void:
	var f := 0.0
	if Game.running:
		f = clampf(Game.economy.state.energy_produced_run / Game.economy.threshold(), 0.0, 1.0)
	var drone := clampf(inverse_lerp(0.5, 1.0, f), 0.0, 1.0)
	_drone.volume_db = lerpf(-80.0, -12.0, sqrt(drone))
	_silence_left -= delta
	var target := -80.0 if (_silence_left > 0.0 or not power) else HUM_DB
	_hum.volume_db = move_toward(_hum.volume_db, target, delta * 120.0)


# Apaga y amortigua el bus TV según los muros y puertas entre la cámara y la pantalla (SoundOcclusion).
func _occlusion(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null or _occlusion_lp == null or _occlusion_gain == null:
		return
	var target := _screen.global_position
	var end := target + (cam.global_position - target).normalized() * 0.35  # sin llegar a la propia tele
	var hits := SoundOcclusion.obstacles(get_world_3d().direct_space_state, cam.global_position, end,
			OCCLUSION.size() - 1)
	var goal := OCCLUSION[hits]
	var k := 1.0 - exp(-OCCLUSION_SPEED * delta)
	_occlusion_lp.cutoff_hz = exp(lerpf(log(_occlusion_lp.cutoff_hz), log(goal.x), k))
	_occlusion_gain.volume_db = lerpf(_occlusion_gain.volume_db, goal.y, k)
