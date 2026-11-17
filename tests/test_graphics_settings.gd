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
	assert_false(probe.visible)
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


func test_set_gi_only_touches_gi() -> void:
	settings.apply_preset(&"high")
	settings.set_gi(false)
	assert_false(gi.visible)
	assert_true(env.volumetric_fog_enabled)
	assert_almost_eq(env.ambient_light_energy, 1.0, 0.001)
