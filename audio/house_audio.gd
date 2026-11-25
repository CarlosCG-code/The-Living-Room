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
## Tope al acercarse: como un portazo del piso a un metro. Con el de Godot (3 dB) una cuchara sonaba igual a 6 m que a 1 m.
const MAX_DB := 12.0
## Tic tac: de qué malla del piso sale. Uno por habitación: en el salón, el de pie (también está el de repisa) y en el
## dormitorio, el despertador (también el de bolsillo).
const CLOCKS := {"vintage_grandfather_clock_01*HourHand": preload("res://assets/audio/house/clock_grandfather.ogg"),
		"alarm_clock_01*alarm_clock_01": preload("res://assets/audio/house/clock_alarm.ogg"),
		"orava_clock*": preload("res://assets/audio/house/clock_wall.ogg")}
const CLOCK_DB := -12.0

var _flat: Node3D
var _event: DirectionalSound
var _hum: DirectionalSound
var _silence_left := 0.0


func setup(flat: Node3D) -> void:
	_flat = flat
	_event = DirectionalSound.new(flat.sound_loss)
	_event.unit_size = 5.0
	_event.max_db = MAX_DB
	add_child(_event)
	_hum = DirectionalSound.new(flat.sound_loss)
	_hum.stream = HUM
	_hum.level = OFF_DB
	add_child(_hum)
	_hum.global_position = flat.get_place(&"wall")
	var ambience := AudioStreamPlayer.new()
	ambience.stream = AMBIENCE
	ambience.bus = &"House"
	ambience.volume_db = -30.0
	add_child(ambience)
	if DisplayServer.get_name() != "headless":
		_hum.start()
		ambience.play()
	for clock: String in CLOCKS:
		_add_clock(clock)
	EventBus.fear_event.connect(_on_fear_event)
	EventBus.house_silence.connect(func(seconds: float) -> void: _silence_left = seconds)


func _process(delta: float) -> void:
	_silence_left -= delta
	var target := OFF_DB
	if _silence_left <= 0.0 and Game.economy.owned(&"antenna") > 0:
		target = lerpf(HUM_DB.x, HUM_DB.y, Game.economy.production_level())
	_hum.level = move_toward(_hum.level, target, delta * FADE)


func _on_fear_event(def: FearEventDef, place: StringName) -> void:
	if def.kind != FearEventDef.Kind.SOUND:
		return
	_event.stream = def.sounds.pick_random()
	var prop: FallingProp = _flat.pick_prop(def.id)
	_event.position = prop.landing if prop else _flat.get_place(place)
	_event.level = def.volume_db
	var length := _event.stream.get_length()
	var lead := prop.lead() if prop else 0.0  # suena al tocar el suelo
	var wait := lead
	if randf() < 0.5:
		wait = PRELUDE
		EventBus.house_silence.emit(PRELUDE + length)
	var tween := create_tween()
	tween.tween_callback(prop.fall if prop else _flat.stir.bind(place, length)).set_delay(wait - lead)
	tween.tween_callback(_event.start).set_delay(lead)


func _add_clock(mesh_name: String) -> void:
	var mesh: MeshInstance3D = _flat.find_children(mesh_name, "MeshInstance3D", true, false)[0]
	var tick := DirectionalSound.new(_flat.sound_loss)
	tick.stream = CLOCKS[mesh_name]
	tick.level = CLOCK_DB
	tick.unit_size = 1.0
	add_child(tick)
	tick.global_position = mesh.global_transform * mesh.get_aabb().get_center()
	if DisplayServer.get_name() != "headless":
		tick.start()
