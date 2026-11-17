extends Node3D

# Tele de tubo (specs/hito2.md D5, §5): pantalla con la UI del hito 1 dentro de un SubViewport.

signal screen_state_changed(state: StringName)

const SCREEN_SIZE := Vector2(0.52, 0.39)
const SCREEN_SHADER := preload("res://presentation/tv/tv_screen.gdshader")

## Encendida o apagada (apagada: no se dibuja el SubViewport).
var power := true:
	set(value):
		power = value
		_update_power()

var _state: StringName = &""

@onready var _subviewport: SubViewport = $SubViewport
@onready var _screen: MeshInstance3D = $Model/Screen
@onready var _screen_light: Light3D = $ScreenLight
@onready var _input: Node = $TvInput


func _ready() -> void:
	# La textura se asigna por código: una ViewportTexture puesta en la escena escribe un ERROR al cargar.
	var material := ShaderMaterial.new()
	material.shader = SCREEN_SHADER
	material.set_shader_parameter(&"screen_tex", _subviewport.get_texture())
	_screen.material_override = material
	_input.setup(_subviewport, _screen, SCREEN_SIZE)
	_update_power()


func _process(_delta: float) -> void:
	var state: StringName = &"off"
	if power:
		state = &"interference" if Game.economy.interference_active() else &"on"
	if state != _state:
		_state = state
		screen_state_changed.emit(state)


func get_screen_node() -> Node3D:
	return _screen


func get_screen_size() -> Vector2:
	return SCREEN_SIZE


func get_subviewport() -> SubViewport:
	return _subviewport


func get_screen_light() -> Light3D:
	return _screen_light


func get_input() -> Node:
	return _input


func _update_power() -> void:
	if not is_node_ready():
		return
	_subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if power else SubViewport.UPDATE_DISABLED
	_screen.visible = power
