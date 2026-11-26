class_name CameraBob
extends RefCounted

# La cámara viva al andar y quieto (specs/hito4b.md D3b): función pura para poder probarla.

# Más fuerte a petición del usuario (2026-11-26); «Movimiento de cámara» lo baja.
const BOB_Y := 0.028  # la vista baja en cada pisada
const BOB_X := 0.016  # vaivén lateral, cada dos pasos
const ROLL := 0.014  # ~0,8°
const BREATH_Y := 0.009
const BREATH_PERIOD := 3.6


## steps: pasos recorridos (la pisada suena en k + 0,5); amp: 0 parado, 1 andando; t: segundos para la respiración.
## Devuelve (x, y, inclinación) de la cámara respecto a la cabeza.
static func offset(steps: float, amp: float, t: float) -> Vector3:
	var y := -BOB_Y * amp * (0.5 - 0.5 * cos(TAU * steps))
	var side := sin(PI * steps) * amp
	var breath := BREATH_Y * sin(TAU * t / BREATH_PERIOD) * (1.0 - amp)
	return Vector3(BOB_X * side, y + breath, ROLL * side)
