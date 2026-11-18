class_name GeneratorDef
extends Resource

@export var id: StringName
@export var name_key: String
@export var base_cost: float
@export var base_production: float
## Energía que suma cada unidad a cada clic, antes del multiplicador de clic.
@export var click_bonus: float = 0.0
@export var req_energy_produced: float
## Padre en el árbol de mejoras: generador del que hay que tener al menos uno.
@export var requires_id: StringName
