class_name HouseAudio
extends Node

# Los sonidos de la casa (specs/hito3.md D6): los sucesos del director, de uno en uno, y dos capas continuas
# (el edificio y el zumbido eléctrico de la pared).

const PRELUDE := 1.5  # silencio antes de la mitad de los sonidos
const AMBIENCE := preload("res://assets/audio/house/building.ogg")
const HUM := preload("res://assets/audio/house/wall_hum.ogg")
const HUM_DB := Vector2(-30.0, -18.0)  # según la producción
const OFF_DB := -80.0
const FADE := 120.0  # dB/s, como el zumbido de la tele
## Como mucho cuenta un muro: con la tabla de la tele una cuchara o unas pastillas no se reconocerían. Corte del paso bajo y ganancia.
const OPEN := Vector2(20000.0, 0.0)
const WALLED := Vector2(5000.0, -6.0)

var _flat: Node3D
var _event := AudioStreamPlayer3D.new()
var _hum := AudioStreamPlayer3D.new()
var _silence_left := 0.0


func setup(flat: Node3D) -> void:
	_flat = flat
	_event.bus = &"HouseEvents"
	_event.unit_size = 5.0
	_event.attenuation_filter_cutoff_hz = 20500.0  # sin filtro por distancia: el del muro basta para apagar los sonidos
	add_child(_event)
	_hum.stream = HUM
	_hum.bus = &"House"
	_hum.volume_db = OFF_DB
	add_child(_hum)
	_hum.global_position = flat.get_place(&"wall")
	var ambience := AudioStreamPlayer.new()
	ambience.stream = AMBIENCE
	ambience.bus = &"House"
	ambience.volume_db = -30.0
	add_child(ambience)
	if DisplayServer.get_name() != "headless":
		_hum.play()
		ambience.play()
	EventBus.fear_event.connect(_on_fear_event)
	EventBus.house_silence.connect(func(seconds: float) -> void: _silence_left = seconds)


func _process(delta: float) -> void:
	_silence_left -= delta
	var target := OFF_DB
	if _silence_left <= 0.0 and Game.economy.owned(&"antenna") > 0:
		target = lerpf(HUM_DB.x, HUM_DB.y, Game.economy.production_level())
	_hum.volume_db = move_toward(_hum.volume_db, target, delta * FADE)


func _on_fear_event(def: FearEventDef, place: StringName) -> void:
	if def.kind != FearEventDef.Kind.SOUND:
		return
	_event.stream = def.sounds.pick_random()
	_event.position = _flat.get_place(place)
	var occlusion := WALLED if _behind_a_wall() else OPEN
	var bus := AudioServer.get_bus_index(&"HouseEvents")
	(AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter).cutoff_hz = occlusion.x
	_event.volume_db = def.volume_db + occlusion.y
	if randf() < 0.5:
		_event.play()
		return
	EventBus.house_silence.emit(PRELUDE + _event.stream.get_length())
	create_tween().tween_callback(_event.play).set_delay(PRELUDE)


func _behind_a_wall() -> bool:
	var cam := get_viewport().get_camera_3d()
	return cam != null and SoundOcclusion.obstacles(cam.get_world_3d().direct_space_state, cam.global_position, _event.global_position, 1) > 0
