class_name UpgradeDef
extends Resource

enum Kind { GENERATOR_MULT, CLICK_MULT, HOLD_RATE, CLICK_PRODUCTION_SHARE, AUTO_CLICK_RATE }

@export var id: StringName
@export var name_key: String
@export var desc_key: String
@export var kind: Kind
@export var target_id: StringName
@export var value: float
@export var cost: float
@export var req_energy_produced: float
@export var req_generator_count: int
