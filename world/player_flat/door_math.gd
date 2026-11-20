class_name DoorMath
extends RefCounted

# Física de la hoja de una puerta (specs/hito4a.md D5). Función pura: la usa door.gd en cada paso de física.
# angle en radianes (0 = cerrada, positivo = abierta hacia zona_a); velocity en rad/s.

enum Event { NONE, LATCH, SLAM }

const MAX_ANGLE := deg_to_rad(100.0)
const AJAR_ANGLE := deg_to_rad(6.0)
## Lo deprisa que la hoja sigue al ratón mientras se arrastra (1/s).
const GRIP := 12.0
## Rozamiento al soltarla: frena de forma exponencial (1/s) y del todo por debajo de STOP.
const FRICTION := 1.6
const STOP := 0.03
## Llegar a 0 más despacio que esto la cierra con el pestillo; más deprisa, portazo y rebote.
const LATCH_SPEED := 1.5
const BOUNCE := 0.2
const BOUNCE_MAX := 0.3


## drag: velocidad que pide el ratón (rad/s) mientras held. Devuelve Vector3(ángulo, velocidad, Event).
static func step(angle: float, velocity: float, drag: float, held: bool, delta: float) -> Vector3:
	var was_open := angle > 0.0  # ya cerrada y empujada hacia el marco: sin sonido (antes, pestillo a cada paso)
	if held:
		velocity = lerpf(velocity, drag, 1.0 - exp(-GRIP * delta))
	else:
		velocity *= exp(-FRICTION * delta)
		if absf(velocity) < STOP:
			velocity = 0.0
	angle += velocity * delta
	var event := Event.NONE
	if angle <= 0.0 and velocity < 0.0:
		if not was_open:
			velocity = 0.0
		elif -velocity > LATCH_SPEED:
			event = Event.SLAM
			velocity = minf(-velocity * BOUNCE, BOUNCE_MAX)
		else:
			event = Event.LATCH
			velocity = 0.0
		angle = 0.0
	elif angle >= MAX_ANGLE:
		angle = MAX_ANGLE
		velocity = minf(velocity, 0.0)
	return Vector3(angle, velocity, event)
