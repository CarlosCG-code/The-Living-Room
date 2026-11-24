class_name FearEventSet
extends Resource

@export var events: Array[FearEventDef] = []
## Segundos de silencio entre tandas y entre los sucesos de una tanda.
@export var silence := Vector2(60.0, 150.0)
@export var gap := Vector2(8.0, 25.0)
## Sucesos al azar por run mientras el progreso no llega a 1.
@export var run_budget := 45


func find(id: StringName) -> FearEventDef:
	for def in events:
		if def.id == id:
			return def
	return null
