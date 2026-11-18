class_name PerkDef
extends Resource

## Mejora permanente: se compra con Carga, en orden, y se conserva al reiniciar (specs/incremental.md §6).

enum Kind { START_UPGRADES, START_GENERATORS, GENERATOR_DISCOUNT, CLICK_MULT, CARGA_BONUS }

@export var id: StringName
@export var name_key: String
@export var desc_key: String
@export var cost: int
@export var kind: Kind
## START_UPGRADES: mejoras que cada run trae compradas.
@export var upgrade_ids: Array[StringName] = []
## START_GENERATORS: generador -> unidades con las que empieza cada run.
@export var generators: Dictionary = {}
## GENERATOR_DISCOUNT: fracción del coste que se paga (0,75); CLICK_MULT: multiplicador; CARGA_BONUS: Carga extra.
@export var value: float = 1.0
