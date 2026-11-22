class_name LightFlicker
extends Node

# Parpadeos de casa vieja (usuario, 2026-11-20): cada 2-4 min parpadea UNA lámpara de las que estás viendo, y la
# linterna encendida falla de vez en cuando. Efecto de presentación que escribe a través de LightMixer; cuando
# exista el director de eventos (GDD §5) pasará a ser uno de sus eventos. Nunca más de 3 bajones por segundo
# (GDD, accesibilidad).
# shortcut: aún no lee "Intensidad de efectos" (no existe el ajuste); conectarlo cuando se cree.

const ROOM_WAIT := Vector2(120.0, 240.0)
const ROOM_RETRY := 3.0  # sin ninguna lámpara a la vista, se vuelve a mirar en unos segundos
const TORCH_WAIT := Vector2(45.0, 150.0)
const MIN_DIP_GAP := 0.34  # entre inicios de bajón: menos de 3 por segundo

var _mixer: LightMixer
var _lamps: Array[Light3D] = []
var _torch: Light3D
var _rng := RandomNumberGenerator.new()
var _room_wait := 0.0
var _torch_wait := 0.0
var _room_target: Light3D
var _room_burst: Array[Vector3] = []
var _room_t := 0.0
var _torch_burst: Array[Vector3] = []
var _torch_t := 0.0


func setup(mixer: LightMixer, lights: Array[Light3D], torch: Light3D) -> void:
	_mixer = mixer
	_torch = torch
	for l in lights:
		if l is OmniLight3D:  # lámparas y apliques; no la farola de la calle
			_lamps.append(l)
	_rng.randomize()
	_room_wait = _rng.randf_range(ROOM_WAIT.x, ROOM_WAIT.y)
	_torch_wait = _rng.randf_range(TORCH_WAIT.x, TORCH_WAIT.y)


## Un parpadeo: bajones Vector3(inicio, fin, nivel) en segundos desde el comienzo, ordenados y separados MIN_DIP_GAP.
static func make_burst(rng: RandomNumberGenerator, dips: int, deepest: float, shallowest: float) -> Array[Vector3]:
	var burst: Array[Vector3] = []
	var t := 0.0
	for i in dips:
		var length := rng.randf_range(0.04, 0.13)
		burst.append(Vector3(t, t + length, rng.randf_range(deepest, shallowest)))
		t += rng.randf_range(MIN_DIP_GAP, MIN_DIP_GAP + 0.3)
	return burst


static func level_at(burst: Array[Vector3], t: float) -> float:
	for dip in burst:
		if t >= dip.x and t < dip.y:
			return dip.z
	return 1.0


static func burst_end(burst: Array[Vector3]) -> float:
	return burst[-1].y if not burst.is_empty() else 0.0


func _process(delta: float) -> void:
	if _mixer == null:
		return
	_update_room(delta)
	_update_torch(delta)


func _update_room(delta: float) -> void:
	if _room_target:
		_room_t += delta
		var done := _room_t >= burst_end(_room_burst)
		_mixer.set_light_scale(_room_target, 1.0 if done else level_at(_room_burst, _room_t))
		if done:
			_room_target = null
		return
	_room_wait -= delta
	if _room_wait > 0.0:
		return
	var seen := _visible_lamps()
	if seen.is_empty():
		_room_wait = ROOM_RETRY
		return
	_room_target = seen[_rng.randi() % seen.size()]
	_room_burst = make_burst(_rng, _rng.randi_range(2, 4), 0.03, 0.4)
	_room_t = 0.0
	_room_wait = _rng.randf_range(ROOM_WAIT.x, ROOM_WAIT.y)


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
		var done := _torch_t >= burst_end(_torch_burst)
		_mixer.set_light_scale(_torch, 1.0 if done else level_at(_torch_burst, _torch_t))
		if done:
			_torch_burst.clear()
		return
	_torch_wait -= delta
	if _torch_wait <= 0.0:
		_torch_burst = make_burst(_rng, _rng.randi_range(1, 3), 0.15, 0.55)
		_torch_t = 0.0
		_torch_wait = _rng.randf_range(TORCH_WAIT.x, TORCH_WAIT.y)


# Encendidas, dentro del encuadre, a su alcance y sin muro ni puerta entre la cámara y la bombilla.
func _visible_lamps() -> Array[Light3D]:
	var seen: Array[Light3D] = []
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return seen
	var space := cam.get_world_3d().direct_space_state
	for lamp in _lamps:
		var reach := (lamp as OmniLight3D).omni_range + 3.0
		if lamp.visible and lamp.light_energy > 0.0 and cam.is_position_in_frustum(lamp.global_position) \
				and cam.global_position.distance_to(lamp.global_position) < reach \
				and SoundOcclusion.obstacles(space, cam.global_position, lamp.global_position, 1) == 0:
			seen.append(lamp)
	return seen
