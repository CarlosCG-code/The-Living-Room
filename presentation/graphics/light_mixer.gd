class_name LightMixer
extends RefCounted

# Único sitio que escribe la intensidad de las luces y la luz ambiente (specs/hito2.md D10).
# energía = base(estado) × factor. Cada luz del salón lleva en metadatos base_normal y base_dark.

const TV_SCREEN_SCALE := {&"on": 1.0, &"off": 0.0}

var _room_lights: Array[Light3D]
var _screen_light: Light3D
var _flashlight: Light3D
var _environment: Environment
var _ambient: Dictionary  # estado -> {"color": Color, "energy": float}
var _screen_base: float
var _flashlight_base: float

var _state: StringName = &"normal"
var _flashlight_on := false
var _tv_state: StringName = &"on"
var _factor := 1.0
var _ambient_gi_scale := 1.0
var _scale := {}  # Light3D -> factor de parpadeo (LightFlicker); sin entrada, 1


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


## La linterna se ve siempre que el jugador la lleve encendida (F, de pie), con luz o a oscuras (usuario, 2026-11-20).
func set_flashlight_on(on: bool) -> void:
	_flashlight_on = on
	apply()


func set_tv_state(state: StringName) -> void:
	_tv_state = state
	apply()


## La producción baja las lámparas y, a medias, la luz ambiente; la pantalla (es la que consume) y la farola no.
func set_factor(f: float) -> void:
	_factor = f
	apply()


## Sombras suaves (light_size) o duras; el tamaño original queda en el metadato base_size.
func set_soft_shadows(on: bool) -> void:
	for light: Light3D in _room_lights + ([_screen_light, _flashlight] as Array[Light3D]):
		if light == null:
			continue
		if not light.has_meta("base_size"):
			light.set_meta("base_size", light.light_size)
		light.light_size = float(light.get_meta("base_size")) if on else 0.0


## Factor momentáneo de una luz (parpadeos). No cambia su visibilidad: encender y apagar rehace sombras.
func set_light_scale(light: Light3D, s: float) -> void:
	if s >= 1.0:
		_scale.erase(light)
	else:
		_scale[light] = s
	apply()


func set_ambient_gi_scale(f: float) -> void:
	_ambient_gi_scale = f
	apply()


func apply() -> void:
	var key := "base_dark" if _state == &"dark" else "base_normal"
	for light in _room_lights:
		var energy: float = light.get_meta(key, 0.0) * (_factor if light is OmniLight3D else 1.0)
		light.light_energy = energy * _scale.get(light, 1.0)
		light.visible = energy > 0.0
		for material: BaseMaterial3D in light.get_meta(&"glow", []):
			material.emission_energy_multiplier = float(material.get_meta(&"base_energy")) * light.light_energy / float(light.get_meta("base_normal"))
	if _screen_light:
		var screen_energy: float = _screen_base * TV_SCREEN_SCALE.get(_tv_state, 1.0)
		_screen_light.light_energy = screen_energy
		_screen_light.visible = screen_energy > 0.0
	if _flashlight:
		_flashlight.light_energy = _flashlight_base * _scale.get(_flashlight, 1.0)
		_flashlight.visible = _flashlight_on
	if _environment and _ambient.has(_state):
		var amb: Dictionary = _ambient[_state]
		_environment.ambient_light_color = amb["color"]
		_environment.ambient_light_energy = float(amb["energy"]) * _ambient_gi_scale * lerpf(1.0, _factor, 0.5)
