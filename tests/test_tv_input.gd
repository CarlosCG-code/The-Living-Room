extends GutTest

# Pantalla de 0,4 × 0,3 m en el origen mirando a +Z; SubViewport de 960 × 720 con un botón en el centro.
const SCREEN := Vector2(0.4, 0.3)
const CAMERA := Vector3(0, 0, 1)

var subviewport: SubViewport
var button: Button
var screen: Node3D
var tv_input: Node


func before_each() -> void:
	subviewport = SubViewport.new()
	subviewport.size = Vector2i(960, 720)
	add_child_autofree(subviewport)
	button = Button.new()
	button.position = Vector2(380, 310)
	button.size = Vector2(200, 100)
	subviewport.add_child(button)
	screen = Node3D.new()
	add_child_autofree(screen)
	tv_input = (load("res://presentation/tv/tv_input.gd") as GDScript).new()
	add_child_autofree(tv_input)
	tv_input.setup(subviewport, screen, SCREEN)
	watch_signals(button)


func _click(pressed: bool, inside: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	var dir := Vector3(0, 0, -1) if inside else Vector3(1, 0, -0.1).normalized()
	tv_input.forward(CAMERA, dir, ev)


func test_click_inside_presses() -> void:
	_click(true, true)
	_click(false, true)
	assert_signal_emit_count(button, "pressed", 1)


func test_release_outside_lets_go_without_click() -> void:
	_click(true, true)
	assert_signal_emit_count(button, "button_down", 1)
	_click(false, false)
	assert_signal_emit_count(button, "button_up", 1)
	assert_signal_emit_count(button, "pressed", 0)


func test_focus_out_releases() -> void:
	_click(true, true)
	tv_input.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_signal_emit_count(button, "button_up", 1)
	assert_signal_emit_count(button, "pressed", 0)


func test_wheel_scrolls_only_inside() -> void:
	button.visible = false
	var scroll := ScrollContainer.new()
	scroll.size = Vector2(960, 720)
	var content := Control.new()
	content.custom_minimum_size = Vector2(100, 3000)
	scroll.add_child(content)
	subviewport.add_child(scroll)
	await wait_physics_frames(2)
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	tv_input.forward(CAMERA, Vector3(1, 0, -0.1).normalized(), wheel)
	assert_eq(scroll.scroll_vertical, 0, "fuera de la pantalla no desplaza")
	tv_input.forward(CAMERA, Vector3(0, 0, -1), wheel)
	assert_gt(scroll.scroll_vertical, 0, "dentro de la pantalla desplaza")


func test_press_outside_is_ignored() -> void:
	_click(true, false)
	_click(false, false)
	assert_signal_emit_count(button, "button_down", 0)
