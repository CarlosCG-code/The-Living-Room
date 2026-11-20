class_name Player
extends CharacterBody3D

# El jugador de pie (specs/hito4a.md D6, D7, D11): andar lento, mirar con el ratón, la retícula y el clic en el
# sofá para sentarse. Sentado está inactivo (main.gd lo activa con stand_at y lo desactiva con sit).
# Se mueve en _physics_process: es física de presentación, no lógica de juego (el reloj único sigue en Game).

signal sit_requested

const SPEED := 1.3  # andar lento: no hay correr (usuario, 2026-11-20)
const ACCEL := 5.0
const REACH := 2.0
const PITCH_LIMIT := 1.4

var active := false
var _layout: FlatLayout
var _mirrored := false
var _zone: StringName = &""

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
	_head.rotation.x = 0.0
	velocity = Vector3.ZERO
	reset_physics_interpolation()
	_set_active(true)
	camera.make_current()
	_update_zone()


func sit() -> void:
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
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := Game.settings.mouse_sensitivity
		var r := (event as InputEventMouseMotion).relative * sens
		rotate_y(-r.x)
		_head.rotation.x = clampf(_head.rotation.x - r.y, -PITCH_LIMIT, PITCH_LIMIT)
	elif event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if _is_sofa(_aimed()):
			sit_requested.emit()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		sit_requested.emit()  # main.gd abre además la pausa de la tele
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not camera.current or Engine.time_scale > 1.01:  # cámara libre o tiempo acelerado: atravesaría muros
		velocity = Vector3.ZERO
		return
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish := global_transform.basis * Vector3(input.x, 0.0, input.y) * SPEED
	velocity.x = move_toward(velocity.x, wish.x, ACCEL * delta)
	velocity.z = move_toward(velocity.z, wish.z, ACCEL * delta)
	velocity.y = 0.0 if is_on_floor() else velocity.y - 9.8 * delta
	move_and_slide()
	_update_zone()
	_crosshair.highlight = _is_sofa(_aimed())


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


static func _is_sofa(collider: Object) -> bool:
	return collider is Node and String((collider as Node).name).begins_with("SeatSofa")
