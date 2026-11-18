class_name EconomyConfig
extends Resource

@export var generators: Array[GeneratorDef] = []
@export var upgrades: Array[UpgradeDef] = []
@export var cost_growth: float = 1.15
@export var threshold: float = 10000000.0
@export var base_click_value: float = 1.0
@export var events: Array[TvEventDef] = []
@export var event_min: float = 120.0
@export var event_max: float = 240.0


func find_generator(id: StringName) -> GeneratorDef:
	for g in generators:
		if g.id == id:
			return g
	return null


func find_upgrade(id: StringName) -> UpgradeDef:
	for u in upgrades:
		if u.id == id:
			return u
	return null


func find_event(id: StringName) -> TvEventDef:
	for e in events:
		if e.id == id:
			return e
	return null
