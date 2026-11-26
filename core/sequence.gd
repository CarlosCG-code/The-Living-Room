class_name Sequence
extends RefCounted

## Secuencias que dispara un Reiniciar: el vecino tras la run 1 y el apagón tras la run 2 (specs/hito4b.md D1).
## Las reglas son estáticas; la instancia solo lleva los tiempos de la secuencia en curso, que no se guardan:
## al cargar, el paso empieza de nuevo (GDD §3).

const NEIGHBOR := &"neighbor"
const BLACKOUT := &"blackout"

const KNOCK_AT := 3.0  # tras la carta de fin de emisión (D2)
const STAND_AFTER := 1.0  # segundo de silencio entre los golpes y levantarse
const KNOCK_EVERY := 40.0  # si no abre la puerta, vuelven a llamar
const KNOCK_STEP_DB := 2.0
const KNOCK_MAX_DB := 6.0

var _elapsed := 0.0
var _knocks := 0
var _next_knock := KNOCK_AT
var _stood := false
var _door_open := false


static func after_restart(finished_run: int) -> StringName:
	match finished_run:
		1: return NEIGHBOR
		2: return BLACKOUT
	return &""


static func first_step(sequence: StringName) -> StringName:
	match sequence:
		NEIGHBOR: return &"knock"
		BLACKOUT: return &"dark"
	return &""


## Paso siguiente al ocurrir done; &"" = la secuencia se acabó. Un done que no toca deja el paso como está.
static func next(sequence: StringName, step: StringName, done: StringName) -> StringName:
	match [sequence, step, done]:
		[NEIGHBOR, &"knock", &"handed_over"]: return &"free"
		[NEIGHBOR, &"free", &"sat"]: return &""
		[BLACKOUT, &"dark", &"fuse_fixed"]: return &"fixed"
		[BLACKOUT, &"fixed", &"sat"]: return &""
	return step


## Pasos en los que el jugador se queda de pie al cargar (y se guarda su posición).
static func resumes_standing(step: StringName) -> bool:
	return step in [&"free", &"fixed"]


static func flat_variant(run_index: int, sequence: StringName, step: StringName) -> Dictionary:
	return {"mirror": run_index >= 2 and sequence != NEIGHBOR, "dark": step == &"dark"}


## dB de más en la llamada número n (1 = la primera).
static func knock_boost_db(n: int) -> float:
	return minf(KNOCK_MAX_DB, KNOCK_STEP_DB * (n - 1))


## Momentos de este tick: knock, stand. Con la puerta ya abierta no se vuelve a llamar.
func tick(delta: float, sequence: StringName, step: StringName) -> Array[StringName]:
	var cues: Array[StringName] = []
	if sequence != NEIGHBOR or step != &"knock":
		return cues
	_elapsed += delta
	if not _door_open and _elapsed >= _next_knock:
		_knocks += 1
		_next_knock += KNOCK_EVERY
		cues.append(&"knock")
	if not _stood and _knocks > 0 and _elapsed >= KNOCK_AT + STAND_AFTER:
		_stood = true
		cues.append(&"stand")
	return cues


func knocks() -> int:
	return _knocks


func door_opened() -> void:
	_door_open = true
