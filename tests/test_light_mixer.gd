extends GutTest

var lamp: OmniLight3D
var street: OmniLight3D
var screen_light: OmniLight3D
var flashlight: SpotLight3D
var env: Environment
var mixer: LightMixer


func before_each() -> void:
	lamp = autofree(OmniLight3D.new())
	lamp.set_meta("base_normal", 2.0)
	lamp.set_meta("base_dark", 0.0)
	street = autofree(OmniLight3D.new())
	street.set_meta("base_normal", 0.5)
	street.set_meta("base_dark", 0.2)
	screen_light = autofree(OmniLight3D.new())
	screen_light.light_energy = 1.0
	flashlight = autofree(SpotLight3D.new())
	flashlight.light_energy = 3.0
	env = Environment.new()
	var ambient := {
		&"normal": {"color": Color(0.3, 0.3, 0.35), "energy": 0.5},
		&"dark": {"color": Color(0.05, 0.05, 0.08), "energy": 0.1},
	}
	var lights: Array[Light3D] = [lamp, street]
	mixer = LightMixer.new(lights, screen_light, flashlight, env, ambient)


func test_normal_state() -> void:
	assert_eq(lamp.light_energy, 2.0)
	assert_true(lamp.visible)
	assert_false(flashlight.visible)
	assert_almost_eq(env.ambient_light_energy, 0.5, 0.0001)


func test_dark_keeps_only_street_and_flashlight() -> void:
	mixer.set_state(&"dark")
	assert_false(lamp.visible)
	assert_true(street.visible)
	assert_almost_eq(street.light_energy, 0.2, 0.0001)
	assert_true(flashlight.visible)
	assert_eq(env.ambient_light_color, Color(0.05, 0.05, 0.08))


func test_factor_multiplies_base() -> void:
	mixer.set_factor(0.5)
	assert_almost_eq(lamp.light_energy, 1.0, 0.0001)


func test_screen_light_follows_tv() -> void:
	mixer.set_tv_state(&"interference")
	assert_almost_eq(screen_light.light_energy, 1.6, 0.0001)
	mixer.set_tv_state(&"off")
	assert_false(screen_light.visible)


func test_ambient_scales_with_gi() -> void:
	mixer.set_ambient_gi_scale(0.4)
	assert_almost_eq(env.ambient_light_energy, 0.2, 0.0001)


func test_menu_is_dark_without_flashlight() -> void:
	mixer.set_state(&"menu")
	assert_eq(lamp.light_energy, 0.0, "salón apagado")
	assert_false(flashlight.visible, "sin linterna en el menú")
	assert_almost_eq(screen_light.light_energy, 0.1, 0.0001, "la tele apenas ilumina la pared")
	assert_almost_eq(env.ambient_light_energy, 0.1, 0.001, "luz ambiente de «a oscuras»")
