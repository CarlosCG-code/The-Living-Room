class_name LightFlicker
extends Node

# Parpadeos de casa vieja (usuario, 2026-11-20): la lámpara que diga el director (suceso LAMP) y, de vez en cuando, la
# linterna encendida; nunca a la vez. Escribe a través de LightMixer. Nunca más de 3 bajones por segundo, y la
# profundidad va con «Intensidad de efectos» (GDD, accesibilidad).

const SOFT_TIME := 1.5  # con intensidad 0, un solo bajón suave
const SOFT_LEVEL := 0.75
const TORCH_WAIT := Vector2(45.0, 150.0)
const MIN_DIP_GAP := 0.34  # entre inicios de bajón: menos de 3 por segundo

var _mixer: LightMixer
var _lamps: Array[Light3D] = []
var _torch: Light3D
var _zones := {}  # lámpara -> su zona
var _rng := RandomNumberGenerator.new()
var _torch_wait := 0.0
var _room_target: Light3D
var _room_burst: Array[Vector3] = []
var _room_t := 0.0
var _torch_burst: Array[Vector3] = []
var _torch_t := 0.0


func setup(mixer: LightMixer, lights: Array[Light3D], torch: Light3D, layout: FlatLayout, mirrored: bool) -> void:
	_mixer = mixer
	_torch = torch
	for l in lights:
		if l is OmniLight3D:  # lámparas y apliques; no la farola de la calle
			_lamps.append(l)
			_zones[l] = layout.zone_at(Vector2(l.global_position.x, l.global_position.z), mirrored)
	_rng.randomize()
	_torch_wait = _rng.randf_range(TORCH_WAIT.x, TORCH_WAIT.y)
	EventBus.fear_event.connect(_on_fear_event)


## Un parpadeo: bajones Vector3(inicio, fin, nivel) en segundos desde el comienzo, ordenados y separados MIN_DIP_GAP.
static func make_burst(rng: RandomNumberGenerator, dips: int, deepest: float, shallowest: float) -> Array[Vector3]:
	var burst: Array[Vector3] = []
	var t := 0.0
	for i in dips:
		var length := rng.randf_range(0.04, 0.13)
		burst.append(Vector3(t, t + length, rng.randf_range(deepest, shallowest)))
		t += rng.randf_range(MIN_DIP_GAP, MIN_DIP_GAP + 0.3)
	return burst


static func level_at(burst: Array[Vector3], t: float, intensity := 1.0) -> float:
	if intensity <= 0.0:
		return 1.0 - (1.0 - SOFT_LEVEL) * sin(PI * clampf(t / SOFT_TIME, 0.0, 1.0))
	for dip in burst:
		if t >= dip.x and t < dip.y:
			return lerpf(1.0, dip.z, intensity)
	return 1.0


static func burst_end(burst: Array[Vector3], intensity := 1.0) -> float:
	if intensity <= 0.0:
		return SOFT_TIME
	return burst[-1].y if not burst.is_empty() else 0.0


func _on_fear_event(def: FearEventDef, place: StringName) -> void:
	if def.kind != FearEventDef.Kind.LAMP:
		return
	for lamp in _lamps:
		if lamp.name == place:
			_room_target = lamp
			_room_burst = make_burst(_rng, _rng.randi_range(2, 4), 0.03, 0.4)
			_room_t = 0.0


func _process(delta: float) -> void:
	if _mixer == null:
		return
	_update_room(delta)
	_update_torch(delta)


func _update_room(delta: float) -> void:
	if _room_target == null or (_room_t == 0.0 and not _torch_burst.is_empty()):  # espera a que acabe la linterna
		return
	_room_t += delta
	var intensity := Game.settings.effects_intensity
	var done := _room_t >= burst_end(_room_burst, intensity)
	_mixer.set_light_scale(_room_target, 1.0 if done else level_at(_room_burst, _room_t, intensity))
	if done:
		_room_target = null


func _update_torch(delta: float) -> void:
	if _torch == null:
		return
	if not _torch.visible:
		if not _torch_burst.is_empty():  # apagada a mitad de un fallo: al encenderla salía tenue (usuario, 2026-11-22)
			_torch_burst.clear()
			_mixer.set_light_scale(_torch, 1.0)
		return
	if not _torch_burst.is_empty():
		_torch_t += delta
		var intensity := Game.settings.effects_intensity
		var done := _torch_t >= burst_end(_torch_burst, intensity)
		_mixer.set_light_scale(_torch, 1.0 if done else level_at(_torch_burst, _torch_t, intensity))
		if done:
			_torch_burst.clear()
		return
	_torch_wait -= delta
	if _torch_wait <= 0.0 and _room_target == null:
		_torch_burst = make_burst(_rng, _rng.randi_range(1, 3), 0.15, 0.55)
		_torch_t = 0.0
		_torch_wait = _rng.randf_range(TORCH_WAIT.x, TORCH_WAIT.y)


## Lámparas encendidas de la zona del jugador (se ve su luz en la pared) o a la vista: dentro del encuadre, a su
## alcance y sin muro ni puerta entre la cámara y la bombilla.
func visible_lamps(zone: StringName) -> Array[StringName]:
	var seen: Array[StringName] = []
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return seen
	var space := cam.get_world_3d().direct_space_state
	for lamp in _lamps:
		var reach := (lamp as OmniLight3D).omni_range + 3.0
		if lamp.visible and lamp.light_energy > 0.0 and (_zones[lamp] == zone \
				or (cam.is_position_in_frustum(lamp.global_position) \
				and cam.global_position.distance_to(lamp.global_position) < reach \
				and SoundOcclusion.obstacles(space, cam.global_position, lamp.global_position, 1) == 0)):
			seen.append(lamp.name)
	return seen
