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
	mixer.set_flashlight_on(true)
	mixer.set_state(&"dark")
	assert_false(lamp.visible)
	assert_true(street.visible)
	assert_almost_eq(street.light_energy, 0.2, 0.0001)
	assert_true(flashlight.visible)
	assert_eq(env.ambient_light_color, Color(0.05, 0.05, 0.08))


func test_glow_follows_its_light() -> void:
	var bulb := StandardMaterial3D.new()
	bulb.set_meta(&"base_energy", 4.0)
	lamp.set_meta(&"glow", [bulb])
	mixer.set_light_scale(lamp, 0.25)
	assert_almost_eq(bulb.emission_energy_multiplier, 1.0, 0.0001, "parpadeo")
	mixer.set_light_scale(lamp, 1.0)
	assert_almost_eq(bulb.emission_energy_multiplier, 4.0, 0.0001)
	mixer.set_state(&"dark")
	assert_eq(bulb.emission_energy_multiplier, 0.0, "apagada no brilla")


func test_factor_multiplies_base() -> void:
	mixer.set_factor(0.5)
	assert_almost_eq(lamp.light_energy, 1.0, 0.0001)


func test_screen_light_follows_tv() -> void:
	mixer.set_tv_state(&"on")
	assert_almost_eq(screen_light.light_energy, 1.0, 0.0001)
	mixer.set_tv_state(&"off")
	assert_false(screen_light.visible)


func test_ambient_scales_with_gi() -> void:
	mixer.set_ambient_gi_scale(0.4)
	assert_almost_eq(env.ambient_light_energy, 0.2, 0.0001)


func test_soft_shadows_off_and_back() -> void:
	lamp.light_size = 0.3
	mixer.set_soft_shadows(false)
	assert_eq(lamp.light_size, 0.0, "en bajo, sombras duras: sin ruido")
	mixer.set_soft_shadows(true)
	assert_almost_eq(lamp.light_size, 0.3, 0.0001)


func test_flashlight_follows_switch_in_any_state() -> void:
	assert_false(flashlight.visible, "empieza apagada")
	mixer.set_flashlight_on(true)
	assert_true(flashlight.visible, "con luz también se enciende con F")
	mixer.set_state(&"dark")
	assert_true(flashlight.visible)
	mixer.set_flashlight_on(false)
	assert_false(flashlight.visible, "apagada con F")


func test_light_scale_dims_without_hiding() -> void:
	mixer.set_light_scale(lamp, 0.1)
	assert_almost_eq(lamp.light_energy, 0.2, 0.0001)
	assert_true(lamp.visible, "un bajón no apaga la luz: no rehace sus sombras")
	mixer.set_light_scale(lamp, 1.0)
	assert_almost_eq(lamp.light_energy, 2.0, 0.0001)


func test_flicker_bursts_stay_under_three_dips_per_second() -> void:
	var rng := RandomNumberGenerator.new()
	for s in 200:
		rng.seed = s
		var burst := LightFlicker.make_burst(rng, 4, 0.03, 0.4)
		for i in burst.size():
			assert_between(burst[i].z, 0.0, 1.0)
			if i > 0:
				assert_gte(burst[i].x - burst[i - 1].x, LightFlicker.MIN_DIP_GAP)
		assert_eq(LightFlicker.level_at(burst, LightFlicker.burst_end(burst) + 0.01), 1.0, "termina encendida")
