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
## De dónde viene cada suceso con unos auriculares o dos altavoces (usuario, 2026-11-24). El reparto de Godot solo da 6 dB
## de lado a lado y nada distingue delante de detrás: al oído lejano le llega más tarde (Woodworth) y más bajo, y lo de
## detrás, más apagado.
const HEAD_MS := 0.255  # radio de la cabeza entre la velocidad del sonido
const FAR_EAR_DB := 15.0
const CENTER_DB := -3.0  # en el centro suenan los dos oídos: la misma potencia que a un lado
const BEHIND_CUTOFF := 0.5

var _flat: Node3D
var _event := AudioStreamPlayer3D.new()
var _hum := AudioStreamPlayer3D.new()
var _silence_left := 0.0
var _cutoff := OPEN.x
@onready var _stereo := AudioServer.get_speaker_mode() == AudioServer.SPEAKER_MODE_STEREO


func setup(flat: Node3D) -> void:
	_flat = flat
	_event.bus = &"HouseEvents"
	_event.unit_size = 5.0
	_event.attenuation_filter_cutoff_hz = 20500.0  # sin filtro por distancia: el del muro basta para apagar los sonidos
	if _stereo:
		_event.panning_strength = 0.0  # lo hace _aim
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
	if _event.playing:
		_aim()


func _on_fear_event(def: FearEventDef, place: StringName) -> void:
	if def.kind != FearEventDef.Kind.SOUND:
		return
	_event.stream = def.sounds.pick_random()
	var prop: FallingProp = _flat.pick_prop(def.id)
	_event.position = prop.landing if prop else _flat.get_place(place)
	var occlusion := WALLED if _behind_a_wall() else OPEN
	_cutoff = occlusion.x
	_event.volume_db = def.volume_db + occlusion.y - (CENTER_DB if _stereo else 0.0)
	var length := _event.stream.get_length()
	var lead := prop.lead() if prop else 0.0  # suena al tocar el suelo
	var wait := lead
	if randf() < 0.5:
		wait = PRELUDE
		EventBus.house_silence.emit(PRELUDE + length)
	var tween := create_tween()
	tween.tween_callback(prop.fall if prop else _flat.stir.bind(place, length)).set_delay(wait - lead)
	tween.tween_callback(_play).set_delay(lead)


func _play() -> void:
	_aim()
	_event.play()


# En cada fotograma: de pie, el sonido se queda en su sitio al girar la cabeza.
func _aim() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var bus := AudioServer.get_bus_index(&"HouseEvents")
	var at := ears(cam.global_basis.inverse() * (_event.global_position - cam.global_position))
	(AudioServer.get_bus_effect(bus, 0) as AudioEffectLowPassFilter).cutoff_hz = _cutoff * lerpf(1.0, BEHIND_CUTOFF, at.z)
	if not _stereo:
		return
	var delay := AudioServer.get_bus_effect(bus, 1) as AudioEffectDelay  # toma 1, oído izquierdo; toma 2, derecho
	var center := CENTER_DB * (1.0 - absf(at.y) / FAR_EAR_DB)
	delay.tap1_delay_ms = maxf(at.x, 0.0)
	delay.tap2_delay_ms = maxf(-at.x, 0.0)
	delay.tap1_level_db = center - maxf(at.y, 0.0)
	delay.tap2_level_db = center - maxf(-at.y, 0.0)


## Para un sonido en esa dirección (cámara: -Z delante, +X derecha): retraso (ms) y pérdida (dB) del oído lejano, positivos
## si viene de la derecha, y cuánto está detrás (0-1).
static func ears(to: Vector3) -> Vector3:
	var dir := to.normalized()
	return Vector3(HEAD_MS * (asin(clampf(dir.x, -1.0, 1.0)) + dir.x), FAR_EAR_DB * dir.x, maxf(0.0, dir.z))


func _behind_a_wall() -> bool:
	var cam := get_viewport().get_camera_3d()
	return cam != null and SoundOcclusion.obstacles(cam.get_world_3d().direct_space_state, cam.global_position, _event.global_position, 1) > 0
