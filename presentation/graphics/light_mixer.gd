class_name LightMixer
extends RefCounted

# Único sitio que escribe la intensidad de las luces y la luz ambiente (specs/hito2.md D10).
# energía = base(estado) × factor. Cada luz del salón lleva en metadatos base_normal y base_dark.

const TV_SCREEN_SCALE := {&"on": 1.0, &"off": 0.0}
## En el menú la tele apenas ilumina la pared: el salón se intuye, no se ve (medido en capturas).
const MENU_SCREEN_SCALE := 0.1

var _room_lights: Array[Light3D]
var _screen_light: Light3D
var _flashlight: Light3D
var _environment: Environment
var _ambient: Dictionary  # estado -> {"color": Color, "energy": float}
var _screen_base: float
var _flashlight_base: float

var _state: StringName = &"normal"
var _tv_state: StringName = &"on"
var _factor := 1.0
var _ambient_gi_scale := 1.0


func _init(room_lights: Array[Light3D], screen_light: Light3D, flashlight: Light3D,
		environment: Environment, ambient: Dictionary) -> void:
	_room_lights = room_lights
	_screen_light = screen_light
	_flashlight = flashlight
	_environment = environment
	_ambient = ambient
	_screen_base = screen_light.light_energy if screen_light else 0.0
	_flashlight_base = flashlight.light_energy if flashlight else 0.0
	apply()


func set_state(state: StringName) -> void:
	_state = state
	apply()


func set_tv_state(state: StringName) -> void:
	_tv_state = state
	apply()


func set_factor(f: float) -> void:
	_factor = f
	apply()


func set_ambient_gi_scale(f: float) -> void:
	_ambient_gi_scale = f
	apply()


func apply() -> void:
	# «menu»: el salón a oscuras salvo la calle y la tele, sin linterna (el menú no debe enseñar el sofá).
	var key := "base_dark" if _state in [&"dark", &"menu"] else "base_normal"
	for light in _room_lights:
		var energy: float = light.get_meta(key, 0.0) * _factor
		light.light_energy = energy
		light.visible = energy > 0.0
	if _screen_light:
		var screen_energy: float = _screen_base * TV_SCREEN_SCALE.get(_tv_state, 1.0) * _factor
		if _state == &"menu":
			screen_energy *= MENU_SCREEN_SCALE
		_screen_light.light_energy = screen_energy
		_screen_light.visible = screen_energy > 0.0
	if _flashlight:
		_flashlight.light_energy = _flashlight_base
		_flashlight.visible = _state == &"dark"
	var amb_key: StringName = &"dark" if _state == &"menu" else _state
	if _environment and _ambient.has(amb_key):
		var amb: Dictionary = _ambient[amb_key]
		_environment.ambient_light_color = amb["color"]
		_environment.ambient_light_energy = float(amb["energy"]) * _ambient_gi_scale * _factor
