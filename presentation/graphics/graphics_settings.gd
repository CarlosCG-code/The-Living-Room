class_name GraphicsSettings
extends RefCounted

# Ajustes gráficos y presets (specs/hito2.md D15). Escribe propiedades de nodos y recursos; lo que solo
# existe en el servidor de render se aplica con RenderingServer y queda anotado en `current`.

const PRESETS := {
	&"low": {
		# GI en todos (usuario, 2026-11-22: en bajo y medio «la iluminación baja»): sin ella el salón perdía un tercio de luz.
		"gi": true, "gi_quality": RenderingServer.VOXEL_GI_QUALITY_LOW, "fog": false,
		"shadow_atlas": 1024, "shadow_filter": RenderingServer.SHADOW_QUALITY_HARD, "flashlight_shadow": false, "soft_shadows": false,
		"ssao": false, "ssao_quality": RenderingServer.ENV_SSAO_QUALITY_LOW,
		"ssil": false, "ssil_quality": RenderingServer.ENV_SSIL_QUALITY_LOW,
		"probe": true, "taa": false, "fxaa": true, "scale": 0.67, "max_height": 720, "glow": false, "half": true,
		"mirror_rows": 192,  # espejos en todos los presets (usuario, 2026-11-22)
	},
	&"medium": {
		"gi": true, "gi_quality": RenderingServer.VOXEL_GI_QUALITY_LOW, "fog": false,
		"shadow_atlas": 2048, "shadow_filter": RenderingServer.SHADOW_QUALITY_SOFT_LOW, "flashlight_shadow": true, "soft_shadows": true,
		"ssao": true, "ssao_quality": RenderingServer.ENV_SSAO_QUALITY_LOW,
		"ssil": false, "ssil_quality": RenderingServer.ENV_SSIL_QUALITY_LOW,
		"probe": true, "taa": true, "fxaa": false, "scale": 0.85, "max_height": 900, "glow": true, "half": true,
		"mirror_rows": 320,
	},
	&"high": {
		"gi": true, "gi_quality": RenderingServer.VOXEL_GI_QUALITY_LOW, "fog": true,
		"shadow_atlas": 4096, "shadow_filter": RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM, "flashlight_shadow": true, "soft_shadows": true,
		"ssao": true, "ssao_quality": RenderingServer.ENV_SSAO_QUALITY_MEDIUM,
		"ssil": true, "ssil_quality": RenderingServer.ENV_SSIL_QUALITY_MEDIUM,
		"probe": true, "taa": true, "fxaa": false, "scale": 1.0, "max_height": 1080, "glow": true, "half": true,
		"mirror_rows": 512,
	},
	&"ultra": {
		"gi": true, "gi_quality": RenderingServer.VOXEL_GI_QUALITY_HIGH, "fog": true,
		"shadow_atlas": 8192, "shadow_filter": RenderingServer.SHADOW_QUALITY_SOFT_HIGH, "flashlight_shadow": true, "soft_shadows": true,
		"ssao": true, "ssao_quality": RenderingServer.ENV_SSAO_QUALITY_HIGH,
		"ssil": true, "ssil_quality": RenderingServer.ENV_SSIL_QUALITY_HIGH,
		"probe": true, "taa": true, "fxaa": false, "scale": 1.0, "max_height": 1440, "glow": true, "half": false,
		"mirror_rows": 768,
	},
}
const AMBIENT_GI_SCALE := 0.4  # con iluminación global, la luz ambiente base se baja (D9)
const NO_SSIL_AMBIENT := 1.2

var current: Dictionary = {}
## Claves del preset forzadas (p. ej. TLR_OFF en depuración); sobreviven a cada apply_preset.
var overrides: Dictionary = {}
## Del jugador (UserSettings): multiplicador de exposición, escala 3D (0 = la del preset) y filas de la
## resolución elegida (0 = auto).
var brightness := 1.0
var user_scale := 0.0
var max_rows := 0

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


## Escala del 3D: la del preset, pero sin pasar de max_height filas internas. En un monitor 4K el 3D no se
## dibuja a 2160 filas: los efectos de pantalla (SSAO, SSIL, TAA) cuestan por píxel y la tele no lo necesita.
static func render_scale(scale: float, max_height: float, viewport_height: float) -> float:
	if viewport_height <= 0.0:
		return scale
	return clampf(minf(scale, max_height / viewport_height), 0.25, 1.0)


func apply_preset(preset: StringName) -> void:
	current = (PRESETS[preset] as Dictionary).duplicate()
	current["preset"] = preset
	current.merge(overrides, true)
	_apply()


## Escala 3D final. Con resolución elegida (rows > 0), el 3D se dibuja a esas filas por la escala (la del
## jugador o, en auto, la del preset), aunque pasen del tope del preset: el jugador lo pidió. En auto, la
## escala sin pasar del tope de filas del preset (salvo que el jugador fijara la escala).
static func final_scale(preset: Dictionary, user_scale: float, rows: int, viewport_height: float) -> float:
	var scale: float = user_scale if user_scale > 0.0 else preset["scale"]
	if rows > 0 and viewport_height > 0.0:
		return clampf(scale * rows / viewport_height, 0.25, 1.0)
	return render_scale(scale, INF if user_scale > 0.0 else float(preset["max_height"]), viewport_height)


func _apply() -> void:
	var gi: bool = current["gi"]
	if _voxel_gi:
		_voxel_gi.visible = gi
	RenderingServer.voxel_gi_set_quality(current["gi_quality"])
	if _mixer:
		# Sin SSIL (bajo y medio) falta la luz que rebota de cerca: algo más de ambiente lo iguala con el alto.
		_mixer.set_ambient_gi_scale((AMBIENT_GI_SCALE if gi else 1.0) * (1.0 if current["ssil"] else NO_SSIL_AMBIENT))
		# Sin TAA (bajo), las sombras suaves (light_size) salen con ruido: se dibujan duras.
		_mixer.set_soft_shadows(current["soft_shadows"])
	if _environment:
		_environment.volumetric_fog_enabled = current["fog"]
		_environment.ssao_enabled = current["ssao"]
		_environment.ssil_enabled = current["ssil"]
		# Halo de la pantalla sobre el marco y la pared (niveles en living_room.tscn); barato, fuera en bajo.
		_environment.glow_enabled = current["glow"]
		_environment.tonemap_exposure = _base_exposure * brightness
	# «half»: SSAO, SSIL y la GI a media resolución (como Godot por defecto); con TAA casi no se nota y es de lo
	# que más GPU ahorra. Solo el ultra los calcula a resolución completa.
	var half: bool = current["half"]
	RenderingServer.environment_set_ssao_quality(current["ssao_quality"], half, 0.5, 2, 50.0, 300.0)
	RenderingServer.environment_set_ssil_quality(current["ssil_quality"], half, 0.5, 4, 50.0, 300.0)
	RenderingServer.gi_set_use_half_resolution(half)
	RenderingServer.positional_soft_shadow_filter_set_quality(current["shadow_filter"])
	if _flashlight:
		_flashlight.shadow_enabled = current["flashlight_shadow"]
	if _probe:
		_probe.visible = current["probe"]
	if _viewport:
		# Espejos (PlanarMirror): filas del reflejo; en bajo no se pintan.
		_viewport.get_tree().call_group(&"mirrors", &"set_rows", current["mirror_rows"])
		_viewport.positional_shadow_atlas_size = current["shadow_atlas"]
		_viewport.use_taa = current["taa"]
		_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if current["fxaa"] else Viewport.SCREEN_SPACE_AA_DISABLED
		var scale := final_scale(current, user_scale, max_rows, _viewport.get_visible_rect().size.y)
		_viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if scale < 1.0 else Viewport.SCALING_3D_MODE_BILINEAR
		_viewport.scaling_3d_scale = scale
