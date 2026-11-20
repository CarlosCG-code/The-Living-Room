extends GutTest

# Comprueba la tabla de presets de specs/hito2.md D15. Se actualiza con los valores finales de la fase 2c.

var viewport: SubViewport
var env: Environment
var gi: VoxelGI
var probe: ReflectionProbe
var flashlight: SpotLight3D
var mixer: LightMixer
var settings: GraphicsSettings


func before_each() -> void:
	viewport = SubViewport.new()
	add_child_autofree(viewport)
	env = Environment.new()
	env.tonemap_exposure = 1.0
	gi = autofree(VoxelGI.new())
	probe = autofree(ReflectionProbe.new())
	flashlight = autofree(SpotLight3D.new())
	var lights: Array[Light3D] = []
	mixer = LightMixer.new(lights, null, flashlight, env, {&"normal": {"color": Color.WHITE, "energy": 1.0}})
	settings = GraphicsSettings.new(viewport, env, gi, probe, flashlight, mixer)


func test_low() -> void:
	settings.apply_preset(&"low")
	assert_false(gi.visible)
	assert_false(env.volumetric_fog_enabled)
	assert_false(env.ssao_enabled)
	assert_false(env.ssil_enabled)
	assert_true(probe.visible, "la sonda es el reflejo del cristal: barata, en todos los presets")
	assert_false(flashlight.shadow_enabled)
	assert_eq(viewport.positional_shadow_atlas_size, 1024)
	assert_eq(viewport.screen_space_aa, Viewport.SCREEN_SPACE_AA_FXAA)
	assert_false(viewport.use_taa)
	assert_almost_eq(viewport.scaling_3d_scale, 0.67, 0.001)
	assert_eq(viewport.scaling_3d_mode, Viewport.SCALING_3D_MODE_FSR)
	assert_almost_eq(env.ambient_light_energy, 1.0, 0.001)


func test_medium() -> void:
	settings.apply_preset(&"medium")
	assert_false(gi.visible)
	assert_true(env.ssao_enabled)
	assert_true(probe.visible)
	assert_true(flashlight.shadow_enabled)
	assert_eq(viewport.positional_shadow_atlas_size, 2048)
	assert_almost_eq(viewport.scaling_3d_scale, 0.85, 0.001)
	assert_true(viewport.use_taa, "sin TAA las sombras suaves y el SSAO se ven con grano")
	assert_eq(settings.current["ssao_quality"], RenderingServer.ENV_SSAO_QUALITY_LOW)


func test_high() -> void:
	settings.apply_preset(&"high")
	assert_true(gi.visible)
	assert_true(env.volumetric_fog_enabled)
	assert_true(env.ssil_enabled)
	assert_true(viewport.use_taa)
	assert_eq(viewport.positional_shadow_atlas_size, 4096)
	assert_eq(viewport.scaling_3d_mode, Viewport.SCALING_3D_MODE_BILINEAR)
	assert_almost_eq(env.ambient_light_energy, 0.4, 0.001)
	assert_eq(settings.current["gi_quality"], RenderingServer.VOXEL_GI_QUALITY_LOW)


func test_low_then_ultra_is_full_ultra() -> void:
	settings.apply_preset(&"low")
	settings.apply_preset(&"ultra")
	assert_true(gi.visible)
	assert_eq(viewport.positional_shadow_atlas_size, 8192)
	assert_almost_eq(viewport.scaling_3d_scale, 1.0, 0.001)
	assert_eq(settings.current["gi_quality"], RenderingServer.VOXEL_GI_QUALITY_HIGH)
	assert_eq(settings.current["shadow_filter"], RenderingServer.SHADOW_QUALITY_SOFT_HIGH)


func test_override_only_touches_its_key_and_survives_reapply() -> void:
	settings.overrides = {"gi": false}
	settings.apply_preset(&"high")
	settings.apply_preset(&"high")
	assert_false(gi.visible)
	assert_true(env.volumetric_fog_enabled)
	assert_almost_eq(env.ambient_light_energy, 1.0, 0.001)


func test_render_scale_caps_internal_height() -> void:
	assert_almost_eq(GraphicsSettings.render_scale(1.0, 1440, 2160), 1440.0 / 2160.0, 0.0001, "alto en 4K: 1440 filas")
	assert_almost_eq(GraphicsSettings.render_scale(1.0, 1440, 1080), 1.0, 0.0001, "en 1080p no se escala")
	assert_almost_eq(GraphicsSettings.render_scale(0.85, 1080, 1080), 0.85, 0.0001, "manda la escala del preset si es menor")
	assert_almost_eq(GraphicsSettings.render_scale(1.0, 720, 0), 1.0, 0.0001, "sin tamaño de ventana, sin cambios")
	assert_almost_eq(GraphicsSettings.render_scale(1.0, 100, 4320), 0.25, 0.0001, "nunca por debajo de 0,25")


func test_final_scale_user_choices() -> void:
	var high: Dictionary = GraphicsSettings.PRESETS[&"high"]
	assert_almost_eq(GraphicsSettings.final_scale(high, 0.0, 0, 2160), 1080.0 / 2160.0, 0.0001, "auto: manda el preset")
	assert_almost_eq(GraphicsSettings.final_scale(high, 1.0, 0, 2160), 1.0, 0.0001, "escala elegida: sin el tope del preset")
	assert_almost_eq(GraphicsSettings.final_scale(high, 1.0, 1440, 2160), 1440.0 / 2160.0, 0.0001, "la resolución elegida limita")
	assert_almost_eq(GraphicsSettings.final_scale(high, 0.0, 720, 1080), 720.0 / 1080.0, 0.0001)


func test_brightness_survives_preset_change() -> void:
	settings.brightness = 1.3
	settings.apply_preset(&"low")
	settings.apply_preset(&"ultra")
	assert_almost_eq(env.tonemap_exposure, 1.3, 0.0001)
