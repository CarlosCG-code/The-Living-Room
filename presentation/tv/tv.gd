extends Node3D

# Tele de tubo (specs/hito2.md D5, §5): pantalla con la UI del hito 1 dentro de un SubViewport.

signal screen_state_changed(state: StringName)

const SCREEN_SIZE := Vector2(0.52, 0.39)
const SCREEN_SHADER := preload("res://presentation/tv/tv_screen.gdshader")

## Lo que se ve en la pantalla: el incremental en el salón, el menú en el menú principal.
@export var ui_scene: PackedScene = preload("res://presentation/ui/tv_game_ui.tscn")

## Encendida o apagada (apagada: no se dibuja el SubViewport).
var power := true:
	set(value):
		power = value
		_update_power()

var _state: StringName = &""
var _material: ShaderMaterial

@onready var _subviewport: SubViewport = $SubViewport
@onready var _screen: MeshInstance3D = $Model/Screen
@onready var _screen_light: Light3D = $ScreenLight
@onready var _input: Node = $TvInput


func _ready() -> void:
	# La textura se asigna por código: una ViewportTexture puesta en la escena escribe un ERROR al cargar.
	_subviewport.add_child(ui_scene.instantiate())
	_material = ShaderMaterial.new()
	_material.shader = SCREEN_SHADER
	_material.set_shader_parameter(&"screen_tex", _subviewport.get_texture())
	_screen.material_override = _material
	_input.setup(_subviewport, _screen, SCREEN_SIZE)
	EventBus.settings_changed.connect(_apply_settings)
	_apply_settings()
	_update_power()


func _process(_delta: float) -> void:
	var state: StringName = &"off"
	# En pausa la tele sigue encendida: si su luz cambiara, el salón cambiaría de color detrás del menú.
	if power:
		var e := Game.economy.active_event()
		state = &"interference" if e and e.id == &"interference" else &"on"
	if state != _state:
		_state = state
		screen_state_changed.emit(state)


func _apply_settings() -> void:
	_material.set_shader_parameter(&"crt", Game.settings.crt)


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
