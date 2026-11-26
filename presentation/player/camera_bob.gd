class_name CameraBob
extends RefCounted

# La cámara viva de pie (specs/hito4b.md D3b), rehecha para que parezca un cuerpo (usuario, 2026-11-26):
# - andando, la cabeza cae de golpe en cada pisada y sube despacio, se mece hacia el pie que apoya cada dos
#   pasos y da una cabezada leve con el golpe del talón;
# - todo va por un muelle con algo de rebote: al pararse, el peso se asienta en vez de cortarse;
# - quieta, respira (la inspiración, más corta que la espiración) y se balancea muy despacio, sin repetirse,
#   como cualquiera que está de pie.
# Sin nodos: player.gd la avanza en _physics_process y aplica position y rotation a la cámara.

# Algo más suave a petición del usuario (2026-11-26): menos bajada y un golpe menos seco (exponente 2, no 3).
const STEP_DROP := 0.022  # m que baja la cabeza al apoyar el pie
const STEP_SHARPNESS := 2.0  # más alto, golpe más estrecho y seco
const STEP_SIDE := 0.013  # m de vaivén lateral, de un pie al otro
const STEP_ROLL := 0.007  # rad (~0,4°) de ladeo hacia el pie que apoya
const STEP_NOD := 0.007  # rad (~0,4°) de cabezada con el golpe del talón
const BREATH_RISE := 0.008  # m que sube el pecho al inspirar
const BREATH_PITCH := 0.004  # rad: la cabeza sube un poco con él
const BREATH_PERIOD := 4.2  # s, unas 14 respiraciones por minuto
const BREATH_IN := 0.4  # parte del ciclo que dura la inspiración
const SWAY := 0.004  # m de balanceo postural, de lado y adelante-atrás
const SPRING := 16.0  # rad/s
const DAMPING := 0.7  # < 1: rebota un poco al asentarse

var position := Vector3.ZERO
var pitch := 0.0
var roll := 0.0

var _steps := 0.0  # pasos andados: el pie apoya en k + 0,5, cuando suena (player.gd, media zancada)
var _amp := 0.0  # 0 quieto, 1 andando a velocidad normal
var _t := 0.0
var _vel := Vector3.ZERO
var _rot_vel := Vector2.ZERO


## speed: velocidad horizontal (m/s); full_speed: la de andar normal; stride: metros por paso.
func update(delta: float, speed: float, full_speed: float, stride: float) -> void:
	if _amp < 0.05 and speed < 0.01:
		_steps = 0.0  # al echar a andar, la primera pisada cae con su sonido
	_steps += speed * delta / stride
	_amp = lerpf(_amp, clampf(speed / full_speed, 0.0, 1.0), 1.0 - exp(-delta * 5.0))
	_t += delta
	var target := target_pose(_steps, _amp, _t)
	_spring(delta, target)


## La pose a la que tiende la cámara: (x, y, z) en metros y (cabeceo, ladeo) en radianes. Pura, para los tests.
static func target_pose(steps: float, amp: float, t: float) -> Array:
	var contact := pow(0.5 - 0.5 * cos(TAU * steps), STEP_SHARPNESS)  # 1 al apoyar: el golpe, estrecho; cresta larga
	var side := sin(PI * steps)  # un ciclo cada dos pasos
	var breath := breath_curve(fmod(t, BREATH_PERIOD) / BREATH_PERIOD)
	var still := 1.0 - amp
	var sway_x := SWAY * (0.6 * sin(TAU * 0.13 * t) + 0.4 * sin(TAU * 0.29 * t + 1.7))
	var sway_z := SWAY * (0.6 * sin(TAU * 0.09 * t + 0.6) + 0.4 * sin(TAU * 0.23 * t + 2.9))
	var pos := Vector3(
		STEP_SIDE * amp * side + sway_x * still,
		-STEP_DROP * amp * contact + BREATH_RISE * breath * still,
		sway_z * still)
	var rot := Vector2(
		-STEP_NOD * amp * contact + BREATH_PITCH * breath * still,
		-STEP_ROLL * amp * side)
	return [pos, rot]


## 0-1 a lo largo de un ciclo: sube en BREATH_IN y baja en el resto, las dos con suavidad.
static func breath_curve(u: float) -> float:
	if u < BREATH_IN:
		return smoothstep(0.0, 1.0, u / BREATH_IN)
	return 1.0 - smoothstep(0.0, 1.0, (u - BREATH_IN) / (1.0 - BREATH_IN))


func _spring(delta: float, target: Array) -> void:
	var k := SPRING * SPRING
	var c := 2.0 * DAMPING * SPRING
	_vel += ((target[0] as Vector3) - position) * k * delta - _vel * c * delta
	position += _vel * delta
	var rot := Vector2(pitch, roll)
	_rot_vel += ((target[1] as Vector2) - rot) * k * delta - _rot_vel * c * delta
	rot += _rot_vel * delta
	pitch = rot.x
	roll = rot.y
