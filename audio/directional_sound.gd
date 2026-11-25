class_name DirectionalSound
extends AudioStreamPlayer3D

# Un sonido de la casa que llega desde su sitio con unos auriculares o dos altavoces (usuario, 2026-11-24). El reparto de
# Godot solo da 6 dB de lado a lado y nada distingue delante de detrás: al oído lejano le llega más tarde (Woodworth) y más
# bajo, y lo de detrás, más apagado. Cada uno lleva su bus, que envía a HouseEvents (eco y limitador).

const HEAD_MS := 0.255  # radio de la cabeza entre la velocidad del sonido
const FAR_EAR_DB := 15.0
const CENTER_DB := -3.0  # en el centro suenan los dos oídos: la misma potencia que a un lado
const BEHIND_CUTOFF := 0.5
const OPEN_CUTOFF := 20000.0
const CUTOFF_PER_DB := 0.1  # lo que se pierde en muros y puertas se va antes en los agudos: con 20 dB, 2,7 kHz
const LOSS_FADE := 80.0  # dB/s, al abrir una puerta o cruzarla

## dB, sin muros por medio.
var level := 0.0
var _loss_to: Callable  # (Vector3) -> float: Flat.sound_loss
var _loss := 0.0
var _low_pass := AudioEffectLowPassFilter.new()
var _ears := AudioEffectDelay.new()  # toma 1, oído izquierdo; toma 2, derecho
@onready var _stereo := AudioServer.get_speaker_mode() == AudioServer.SPEAKER_MODE_STEREO


func _init(loss_to: Callable) -> void:
	_loss_to = loss_to


func _ready() -> void:
	attenuation_filter_cutoff_hz = 20500.0  # sin filtro por distancia: el del muro basta para apagar los sonidos
	var i := AudioServer.bus_count
	AudioServer.add_bus()
	AudioServer.set_bus_name(i, "Directional%d" % get_instance_id())
	bus = AudioServer.get_bus_name(i)  # después de crearlo: si no existe, Godot lo cambia por Master
	AudioServer.set_bus_send(i, &"HouseEvents")
	AudioServer.add_bus_effect(i, _low_pass)
	if _stereo:
		panning_strength = 0.0
		_ears.dry = 0.0
		_ears.tap1_pan = -1.0
		_ears.tap2_pan = 1.0
		AudioServer.add_bus_effect(i, _ears)


func _exit_tree() -> void:
	stop()
	AudioServer.remove_bus(AudioServer.get_bus_index(bus))


func _process(delta: float) -> void:
	if playing:
		_loss = move_toward(_loss, _loss_to.call(global_position), delta * LOSS_FADE)
		_aim()


func start() -> void:
	_loss = _loss_to.call(global_position)
	_aim()
	play()


# En cada fotograma: el sonido se queda en su sitio al girar la cabeza o andar, y se abre al abrir una puerta.
func _aim() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var at := ears(cam.global_basis.inverse() * (global_position - cam.global_position))
	_low_pass.cutoff_hz = OPEN_CUTOFF * exp(-CUTOFF_PER_DB * _loss) * lerpf(1.0, BEHIND_CUTOFF, at.z)
	volume_db = level - _loss
	if not _stereo:
		return
	volume_db -= CENTER_DB
	var center := CENTER_DB * (1.0 - absf(at.y) / FAR_EAR_DB)
	_ears.tap1_delay_ms = maxf(at.x, 0.0)
	_ears.tap2_delay_ms = maxf(-at.x, 0.0)
	_ears.tap1_level_db = center - maxf(at.y, 0.0)
	_ears.tap2_level_db = center - maxf(-at.y, 0.0)


## Para un sonido en esa dirección (cámara: -Z delante, +X derecha): retraso (ms) y pérdida (dB) del oído lejano, positivos
## si viene de la derecha, y cuánto está detrás (0-1).
static func ears(to: Vector3) -> Vector3:
	var dir := to.normalized()
	return Vector3(HEAD_MS * (asin(clampf(dir.x, -1.0, 1.0)) + dir.x), FAR_EAR_DB * dir.x, maxf(0.0, dir.z))
