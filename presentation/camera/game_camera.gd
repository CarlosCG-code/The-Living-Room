extends Camera3D

# Cámara de juego (specs/hito2.md D2, D3). En este hito, pose fija de reveal = 0: desde el asiento,
# mirando a la pantalla y con un campo de visión estrecho que la encuadra de cerca. El zoom out
# (interpolar reveal hacia el salón entero) llega en el hito 3.

## Fracción de la altura de la imagen que ocupa la pantalla de la tele con reveal = 0.
const SCREEN_FILL := 0.5  # 0,62 solo dejaba ver la tele; 0,5 enseña la pared de alrededor (usuario, 2026-11-19)

var _tv_input: Node


func setup(seat: Node3D, screen: Node3D, screen_size: Vector2, tv_input: Node, fill: float = SCREEN_FILL) -> void:
	_tv_input = tv_input
	global_position = seat.global_position
	var target := screen.global_position
	look_at(target, Vector3.UP)
	var distance := global_position.distance_to(target)
	var visible_height := screen_size.y / fill
	fov = rad_to_deg(2.0 * atan(visible_height * 0.5 / distance))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func get_flashlight() -> SpotLight3D:
	return $Flashlight


func _unhandled_input(event: InputEvent) -> void:
	# La posición del evento, no la del cursor: GoPeak inyecta eventos sin mover el cursor del sistema.
	if _tv_input and event is InputEventMouse and current:
		var pos: Vector2 = (event as InputEventMouse).position
		_tv_input.forward(project_ray_origin(pos), project_ray_normal(pos), event)
	elif _tv_input and event is InputEventKey and current:
		_tv_input.forward_key(event)
