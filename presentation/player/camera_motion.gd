class_name CameraMotion
extends Node3D

# Levantarse con la cámara, sin cuerpo (specs/hito4b.md D3): la animación mueve Pivot en el espacio del ancla
# (el suelo bajo el asiento) e inclina Tilt (cabeceo y ladeo); Yaw, entre los dos, gira la cabeza hacia la puerta.
# Con el giro debajo del cabeceo, girar mirando abajo ladeaba toda la vista.

signal finished(anim: StringName)

const LIBRARY: AnimationLibrary = preload("res://data/camera_anims.tres")
const BLEND := 0.3  # de donde esté la cámara al primer fotograma
const STAND_FOV := 70.0
const DOOR_LOOK := 0.55  # parte del giro hacia la puerta antes de levantarse, como quien duda
const DOOR_TURN := 0.7
const DOOR_PAUSE := 0.3
const DOOR_FOV_TIME := 2.0  # la vista se abre despacio desde que empieza el giro hasta media subida (usuario, 2026-11-26)
const SOUNDS := {
	&"sofa": [preload("res://assets/audio/room/sofa_rise_a.ogg"), preload("res://assets/audio/room/sofa_rise_b.ogg"),
			preload("res://assets/audio/room/sofa_rise_c.ogg")],  # uno al azar (usuario, 2026-11-26)
	&"step": [preload("res://assets/audio/flat/floor_step_1.ogg")],
}
const SOUND_DB := {&"sofa": -32.0, &"step": -6.0}  # los muelles, muy bajos: sonaban demasiado (usuario, 2026-11-26)

var busy := false
var camera := Camera3D.new()

var _pivot := Node3D.new()
var _yaw := Node3D.new()
var _tilt := Node3D.new()
var _anim := AnimationPlayer.new()
var _sound := AudioStreamPlayer3D.new()


func _init() -> void:
	name = "CameraMotion"
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # se mueve en _process, como la cámara de la tele
	_pivot.name = "Pivot"
	_yaw.name = "Yaw"
	_tilt.name = "Tilt"
	add_child(_pivot)
	_pivot.add_child(_yaw)
	_yaw.add_child(_tilt)
	_tilt.add_child(camera)
	_sound.bus = &"Room"
	_yaw.add_child(_sound)
	_anim.add_animation_library(&"camera", LIBRARY)
	add_child(_anim)


## Se levanta desde from (la cámara sentada) sobre anchor; door_yaw: lo que gira la cabeza hacia la puerta (0 = nada).
func play(anim: StringName, anchor: Transform3D, from: Camera3D, door_yaw := 0.0) -> void:
	busy = true
	global_transform = anchor
	_yaw.rotation = Vector3.ZERO
	_anim.play(&"camera/" + anim)
	_anim.seek(0.0, true)
	_anim.pause()
	camera.fov = from.fov
	await _blend_from(from)
	var length := _anim.current_animation_length
	if door_yaw != 0.0:  # al apartar la vista de la tele deja de mirarla de cerca: el FOV se abre desde el giro, sin prisa
		var fov := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		fov.tween_property(camera, "fov", STAND_FOV, DOOR_FOV_TIME)
		var look := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		look.tween_property(_yaw, "rotation:y", door_yaw * DOOR_LOOK, DOOR_TURN)
		look.tween_interval(DOOR_PAUSE)
		await look.finished
	var rest := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if door_yaw != 0.0:
		rest.tween_property(_yaw, "rotation:y", door_yaw, length * 0.75).set_delay(length * 0.15)
	else:
		rest.tween_property(camera, "fov", STAND_FOV, length * 0.6).set_delay(length * 0.2)
	_anim.play()
	await _anim.animation_finished
	if rest.is_running():
		await rest.finished
	busy = false
	finished.emit(anim)


func _blend_from(from: Camera3D) -> void:
	var travel := Camera3D.new()
	add_child(travel)
	travel.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	travel.global_transform = from.global_transform
	travel.fov = from.fov
	travel.make_current()
	var tween := travel.create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(travel, "global_transform", camera.global_transform, BLEND)
	await tween.finished
	camera.make_current()
	travel.queue_free()


func _cue(id: StringName) -> void:
	_sound.stream = (SOUNDS[id] as Array).pick_random()
	_sound.volume_db = SOUND_DB[id]
	_sound.play()
