class_name PerkDef
extends Resource

## Mejora permanente: se compra con Carga, en cualquier orden, y se conserva al reiniciar
## (specs/incremental_v2.md §4). Los tipos nuevos van al final: el .tres guarda enteros.

enum Kind {
	START_UPGRADES, START_GENERATORS,
	GENERATOR_DISCOUNT,  ## coste × value; las mejoras de máquina piden × value2 unidades
	CLICK_MULT,  ## clic a mano × value
	CARGA_BONUS,
	COMBO_GRACE,  ## la racha aguanta value s; cada crítico llena value2 de la barra de cinta
	EVENT_BOOST,  ## eventos cada value–value2 s; desvela las mejoras con req_perk = esta
	NAME,  ## producción y clics × value
}

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
@export var value2: float = 1.0
