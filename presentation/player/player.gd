class_name Player
extends CharacterBody3D

# El jugador de pie (specs/hito4a.md D6, D7, D11): andar lento, mirar con el ratón, la retícula y el clic en el
# sofá para sentarse. Sentado está inactivo (main.gd lo activa con stand_at y lo desactiva con sit).
# Se mueve en _physics_process: es física de presentación, no lógica de juego (el reloj único sigue en Game).

signal sit_requested

const SPEED := 1.1  # andar lento: no hay correr (usuario, 2026-11-20 y 2026-11-25)
const ACCEL := 5.0
const REACH := 2.0
const PITCH_LIMIT := 1.4
## Un paso cada STRIDE metros. Tramos (s) de footsteps_wood.ogg con un paso de zapato de calle cada uno: la
## grabación trae 21 pasos sueltos con 7 calzados distintos.
const STRIDE := 0.65
const STEP_CLIPS: Array[Vector2] = [Vector2(10.35, 10.75), Vector2(11.24, 11.62), Vector2(12.08, 12.45)]

var active := false
var _layout: FlatLayout
var _mirrored := false
var _zone: StringName = &""
var _grabbed: Door
var _stride_left := STRIDE * 0.5
var _step_end := 0.0
var _last_clip := -1
var _steps_to_creak := 4

@onready var _head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var _crosshair: Crosshair = $Hud/Crosshair


func _ready() -> void:
	_set_active(false)


## Datos del piso para saber en qué zona está (no es otro sistema: es un recurso).
func setup(layout: FlatLayout, mirrored: bool) -> void:
	_layout = layout
	_mirrored = mirrored


## Pone al jugador de pie en t (los pies en t.origin, mirando hacia -Z de t) y le da la cámara.
func stand_at(t: Transform3D) -> void:
	var forward := -t.basis.z
	global_transform = Transform3D(Basis(Vector3.UP, atan2(-forward.x, -forward.z)), t.origin)
	_head.rotation.x = clampf(asin(clampf(forward.normalized().y, -1.0, 1.0)), -PITCH_LIMIT, PITCH_LIMIT)  # 0 salvo TLR_PITCH
	velocity = Vector3.ZERO
	reset_physics_interpolation()
	_set_active(true)
	camera.make_current()
	_update_zone()


func sit() -> void:
	_let_go()
	_set_active(false)


func current_zone() -> StringName:
	return _zone


func _set_active(on: bool) -> void:
	active = on
	set_physics_process(on)
	set_process_unhandled_input(on)
	$Shape.disabled = not on
	$Hud.visible = on
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if on else Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if not camera.current:  # la cámara libre de los trucos manda
		return
	if event is InputEventMouseMotion and _grabbed:
		_grabbed.drag((event as InputEventMouseMotion).relative.y)  # con la hoja agarrada la vista no gira
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := Game.settings.mouse_sensitivity
		var r := (event as InputEventMouseMotion).relative * sens
		rotate_y(-r.x)
		_head.rotation.x = clampf(_head.rotation.x - r.y, -PITCH_LIMIT, PITCH_LIMIT)
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			_let_go()
			return
		var aimed := _aimed()
		var door := _door_of(aimed)
		if door and door.try_grab(camera.global_position):
			_grabbed = door
		elif _is_sofa(aimed):
			sit_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		sit_requested.emit()  # main.gd abre además la pausa de la tele
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not camera.current or Engine.time_scale > 1.01:  # cámara libre o tiempo acelerado: atravesaría muros
		velocity = Vector3.ZERO
		return
	# Con la hoja agarrada no se anda (usuario, 2026-11-20): toda la atención en la puerta.
	var input := Vector2.ZERO if _grabbed else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish := global_transform.basis * Vector3(input.x, 0.0, input.y) * SPEED
	velocity.x = move_toward(velocity.x, wish.x, ACCEL * delta)
	velocity.z = move_toward(velocity.z, wish.z, ACCEL * delta)
	velocity.y = 0.0 if is_on_floor() else velocity.y - 9.8 * delta
	move_and_slide()
	_update_zone()
	_footsteps(Vector2(velocity.x, velocity.z).length() * delta)
	if _grabbed and _grabbed.global_position.distance_to(global_position) > REACH + 0.6:
		_let_go()  # se alejó demasiado
	var aimed := _aimed()
	_crosshair.highlight = _grabbed != null or _door_of(aimed) != null or _is_sofa(aimed)


func _update_zone() -> void:
	if _layout == null:
		return
	var zone := _layout.zone_at(Vector2(global_position.x, global_position.z), _mirrored)
	if zone != &"" and zone != _zone:  # dentro de un muro se queda la última
		_zone = zone
		EventBus.player_zone_changed.emit(zone)


func _aimed() -> Object:
	var from := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from - camera.global_basis.z * REACH)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).get("collider")


func _let_go() -> void:
	if _grabbed:
		_grabbed.release()
		_grabbed = null


# Un paso al recorrer cada zancada; el primero tras media zancada, cuando el pie vuelve al suelo (un toque
# corto de tecla no suena: usuario, 2026-11-20). Nunca el mismo tramo dos veces seguidas y con
# un poco de variación de tono, para que no suene a bucle.
func _footsteps(moved: float) -> void:
	var p: AudioStreamPlayer3D = $Footsteps
	if p.playing and p.get_playback_position() >= _step_end:
		p.stop()
	if moved < 0.0005:
		_stride_left = STRIDE * 0.5
		return
	_stride_left -= moved
	if _stride_left > 0.0:
		return
	_stride_left = STRIDE
	var i := randi() % STEP_CLIPS.size()
	if i == _last_clip:
		i = (i + 1) % STEP_CLIPS.size()
	_last_clip = i
	_step_end = STEP_CLIPS[i].y
	p.pitch_scale = randf_range(0.93, 1.04)
	p.play(STEP_CLIPS[i].x)
	var zone := _layout.find_zone(_zone) if _layout else null
	if zone and zone.floor_type == &"wood":
		_creak()


# La madera cruje bajo el pie cada 4 o 5 pisadas (usuario, 2026-11-25).
func _creak() -> void:
	_steps_to_creak -= 1
	if _steps_to_creak == 0:
		_steps_to_creak = randi_range(4, 5)
		($Creak as AudioStreamPlayer3D).play()


static func _door_of(collider: Object) -> Door:
	return (collider as Node).get_parent() as Door if collider is AnimatableBody3D else null


static func _is_sofa(collider: Object) -> bool:
	return collider is Node and String((collider as Node).name).begins_with("SeatSofa")
