class_name TvEventDef
extends Resource

## Evento de la tele (interferencia, estrella fugaz…): sale al azar cada event_min–event_max segundos.

@export var id: StringName
@export var weight: float = 1.0
@export var duration: float = 8.0
## Si se atrapa con un clic: max(segundos de producción, clics). 0 y 0 = no se atrapa.
@export var reward_production_seconds: float = 0.0
@export var reward_min_clicks: float = 0.0
## Multiplica la producción mientras dura (1 = no cambia).
@export var production_mult: float = 1.0


func catchable() -> bool:
	return reward_production_seconds > 0.0 or reward_min_clicks > 0.0
