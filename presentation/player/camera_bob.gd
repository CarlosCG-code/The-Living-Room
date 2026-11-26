class_name CameraBob
extends RefCounted

# La cámara viva al andar y quieto (specs/hito4b.md D3b): función pura para poder probarla.

const BOB_Y := 0.015  # la vista baja en cada pisada
const BOB_X := 0.008  # vaivén lateral, cada dos pasos
const ROLL := 0.007  # ~0,4°
const BREATH_Y := 0.004
const BREATH_PERIOD := 4.0


## steps: pasos recorridos (la pisada suena en k + 0,5); amp: 0 parado, 1 andando; t: segundos para la respiración.
## Devuelve (x, y, inclinación) de la cámara respecto a la cabeza.
static func offset(steps: float, amp: float, t: float) -> Vector3:
	var y := -BOB_Y * amp * (0.5 - 0.5 * cos(TAU * steps))
	var side := sin(PI * steps) * amp
	var breath := BREATH_Y * sin(TAU * t / BREATH_PERIOD) * (1.0 - amp)
	return Vector3(BOB_X * side, y + breath, ROLL * side)
