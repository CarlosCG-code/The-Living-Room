class_name GraphicsSettings
extends RefCounted

# Ajustes gráficos y presets (specs/hito2.md D15). Escribe propiedades de nodos y recursos; lo que solo
# existe en el servidor de render se aplica con RenderingServer y queda anotado en `current`.

const PRESETS := {
	&"low": {
		"gi": false, "gi_quality": RenderingServer.VOXEL_GI_QUALITY_LOW, "fog": false,
		"shadow_atlas": 1024, "shadow_filter": RenderingServer.SHADOW_QUALITY_HARD, "flashlight_shadow": false,
		"ssao": false, "ssao_quality": RenderingServer.ENV_SSAO_QUALITY_LOW,
		"ssil": false, "ssil_quality": RenderingServer.ENV_SSIL_QUALITY_LOW,
		"probe": false, "taa": false, "fxaa": true, "scale": 0.67,
	},
	&"medium": {
		"gi": false, "gi_quality": RenderingServer.VOXEL_GI_QUALITY_LOW, "fog": false,
		"shadow_atlas": 2048, "shadow_filter": RenderingServer.SHADOW_QUALITY_SOFT_LOW, "flashlight_shadow": true,
		"ssao": true, "ssao_quality": RenderingServer.ENV_SSAO_QUALITY_LOW,
		"ssil": false, "ssil_quality": RenderingServer.ENV_SSIL_QUALITY_LOW,
		"probe": true, "taa": false, "fxaa": true, "scale": 0.85,
	},
	&"high": {
		"gi": true, "gi_quality": RenderingServer.VOXEL_GI_QUALITY_LOW, "fog": true,
		"shadow_atlas": 4096, "shadow_filter": RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM, "flashlight_shadow": true,
		"ssao": true, "ssao_quality": RenderingServer.ENV_SSAO_QUALITY_MEDIUM,
		"ssil": true, "ssil_quality": RenderingServer.ENV_SSIL_QUALITY_MEDIUM,
		"probe": true, "taa": true, "fxaa": false, "scale": 1.0,
	},
	&"ultra": {
		"gi": true, "gi_quality": RenderingServer.VOXEL_GI_QUALITY_HIGH, "fog": true,
		"shadow_atlas": 8192, "shadow_filter": RenderingServer.SHADOW_QUALITY_SOFT_HIGH, "flashlight_shadow": true,
		"ssao": true, "ssao_quality": RenderingServer.ENV_SSAO_QUALITY_HIGH,
		"ssil": true, "ssil_quality": RenderingServer.ENV_SSIL_QUALITY_HIGH,
		"probe": true, "taa": true, "fxaa": false, "scale": 1.0,
	},
}
const AMBIENT_GI_SCALE := 0.4  # con iluminación global, la luz ambiente base se baja (D9)

var current: Dictionary = {}

var _viewport: Viewport
var _environment: Environment
var _voxel_gi: VoxelGI
var _probe: ReflectionProbe
var _flashlight: SpotLight3D
var _mixer: LightMixer
var _base_exposure: float


func _init(viewport: Viewport, environment: Environment, voxel_gi: VoxelGI, probe: ReflectionProbe,
		flashlight: SpotLight3D, mixer: LightMixer) -> void:
	_viewport = viewport
	_environment = environment
	_voxel_gi = voxel_gi
	_probe = probe
	_flashlight = flashlight
	_mixer = mixer
	_base_exposure = environment.tonemap_exposure if environment else 1.0


func apply_preset(preset: StringName) -> void:
	current = (PRESETS[preset] as Dictionary).duplicate()
	current["preset"] = preset
	current["brightness"] = 1.0
	_apply()


func set_gi(enabled: bool) -> void:
	current["gi"] = enabled
	_apply()


func set_brightness(v: float) -> void:
	current["brightness"] = v
	_apply()


func _apply() -> void:
	var gi: bool = current["gi"]
	if _voxel_gi:
		_voxel_gi.visible = gi
	RenderingServer.voxel_gi_set_quality(current["gi_quality"])
	if _mixer:
		_mixer.set_ambient_gi_scale(AMBIENT_GI_SCALE if gi else 1.0)
	if _environment:
		_environment.volumetric_fog_enabled = current["fog"]
		_environment.ssao_enabled = current["ssao"]
		_environment.ssil_enabled = current["ssil"]
		_environment.tonemap_exposure = _base_exposure * float(current["brightness"])
	RenderingServer.environment_set_ssao_quality(current["ssao_quality"], current["ssao_quality"] == RenderingServer.ENV_SSAO_QUALITY_LOW, 0.5, 2, 50.0, 300.0)
	RenderingServer.environment_set_ssil_quality(current["ssil_quality"], current["ssil_quality"] == RenderingServer.ENV_SSIL_QUALITY_LOW, 0.5, 4, 50.0, 300.0)
	RenderingServer.positional_soft_shadow_filter_set_quality(current["shadow_filter"])
	if _flashlight:
		_flashlight.shadow_enabled = current["flashlight_shadow"]
	if _probe:
		_probe.visible = current["probe"]
	if _viewport:
		_viewport.positional_shadow_atlas_size = current["shadow_atlas"]
		_viewport.use_taa = current["taa"]
		_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if current["fxaa"] else Viewport.SCREEN_SPACE_AA_DISABLED
		var scale: float = current["scale"]
		_viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if scale < 1.0 else Viewport.SCALING_3D_MODE_BILINEAR
		_viewport.scaling_3d_scale = scale
