class_name Drip
extends Node3D

# Un grifo que gotea (usuario, 2026-11-25): la gota crece en la boca del caño, cae y suena al tocar la loza.

const SOUNDS: Array[AudioStream] = [preload("res://assets/audio/house/drip_1.ogg"), preload("res://assets/audio/house/drip_2.ogg"),
		preload("res://assets/audio/house/drip_3.ogg"), preload("res://assets/audio/house/drip_4.ogg"),
		preload("res://assets/audio/house/drip_5.ogg")]
const GRAVITY := 9.8
const GROW := 2.4  # s colgando del caño
const RADIUS := 0.004

var _drop := MeshInstance3D.new()
var _sound: DirectionalSound


func _init(loss: Callable) -> void:
	_sound = DirectionalSound.new(loss)


## El nodo va en la boca del caño; height es lo que cae (m).
func setup(height: float) -> void:
	var water := StandardMaterial3D.new()
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.albedo_color = Color(0.75, 0.8, 0.85, 0.6)
	water.roughness = 0.05
	var mesh := SphereMesh.new()
	mesh.radius = RADIUS
	mesh.height = RADIUS * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	mesh.material = water
	_drop.mesh = mesh
	_drop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_drop)
	var sounds := AudioStreamRandomizer.new()
	for s in SOUNDS:
		sounds.add_stream(-1, s)
	_sound.stream = sounds
	_sound.unit_size = 1.0
	_sound.position.y = -height
	add_child(_sound)
	var tween := create_tween().set_loops()
	tween.tween_method(func(t: float) -> void: _drop.scale = Vector3.ONE * maxf(t, 0.01), 0.0, 1.0, GROW)
	tween.tween_method(func(t: float) -> void: _drop.position.y = -height * t * t, 0.0, 1.0, sqrt(2.0 * height / GRAVITY))
	tween.tween_callback(_land)


func _land() -> void:
	_drop.position.y = 0.0
	_drop.scale = Vector3.ONE * 0.01
	if DisplayServer.get_name() != "headless":
		_sound.start()
