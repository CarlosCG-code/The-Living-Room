extends Node

# Reenvía los eventos de ratón al SubViewport de la tele (specs/hito2.md D3, §5).
# Soltar siempre: un botón pulsado en la pantalla se suelta aunque el cursor haya salido, en (-1, -1),
# para que el control haga button_up sin contar un clic.

const OUTSIDE := Vector2(-1, -1)

var _subviewport: SubViewport
var _screen: Node3D
var _screen_size: Vector2
var _pressed: Dictionary = {}  # MouseButton -> true
var _was_inside := false


func setup(subviewport: SubViewport, screen: Node3D, screen_size: Vector2) -> void:
	_subviewport = subviewport
	_screen = screen
	_screen_size = screen_size


func forward(origin: Vector3, dir: Vector3, event: InputEventMouse) -> void:
	var hit = TvScreenMath.ray_plane(origin, dir, _screen.global_transform)
	var inside: bool = hit != null and TvScreenMath.is_inside(hit, _screen_size)
	var pos := TvScreenMath.hit_to_screen(hit, _screen_size, _subviewport.size) if inside else OUTSIDE
	if event is InputEventMouseButton:
		_forward_button(event, inside, pos)
	elif event is InputEventMouseMotion:
		if inside:
			_was_inside = true
			_push(event, pos)
		elif _was_inside:
			_was_inside = false
			_subviewport.notification(Node.NOTIFICATION_VP_MOUSE_EXIT)


func _forward_button(event: InputEventMouseButton, inside: bool, pos: Vector2) -> void:
	var wheel := event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN,
			MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]
	if wheel or event.pressed:
		if not inside:
			return
		if not wheel:
			_pressed[event.button_index] = true
		_push(event, pos)
	elif _pressed.has(event.button_index) or inside:
		_pressed.erase(event.button_index)
		if not inside:
			_push_motion_outside()
		_push(event, pos)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		release_all()


func release_all() -> void:
	if not _pressed.is_empty():
		_push_motion_outside()
	for button: MouseButton in _pressed.keys():
		var ev := InputEventMouseButton.new()
		ev.button_index = button
		ev.pressed = false
		_push(ev, OUTSIDE)
	_pressed.clear()


# El botón solo deja de contar el clic si antes ve el ratón fuera de él.
func _push_motion_outside() -> void:
	var motion := InputEventMouseMotion.new()
	motion.button_mask = _mask()
	_push(motion, OUTSIDE)


func _mask() -> int:
	var mask := 0
	for button: MouseButton in _pressed.keys():
		mask |= 1 << (button - 1)
	return mask


func _push(event: InputEventMouse, pos: Vector2) -> void:
	var ev := event.duplicate() as InputEventMouse
	ev.position = pos
	ev.global_position = pos
	_subviewport.push_input(ev, true)
