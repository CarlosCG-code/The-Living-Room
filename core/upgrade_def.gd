class_name UpgradeDef
extends Resource

## Mejora de la run (specs/incremental_v2.md §3). Los tipos nuevos van al final: el .tres guarda enteros.
enum Kind {
	GENERATOR_MULT,  ## producción y bono de clic de target_id × value
	CLICK_MULT,  ## todos los clics × value
	HOLD_RATE,  ## mantener pulsado = value clics/s
	CLICK_PRODUCTION_SHARE,  ## el clic a mano suma value × producción
	AUTO_CLICK_RATE,  ## value clics/s automáticos
	CRIT_CHANCE,  ## +value de probabilidad de crítico (solo a mano)
	CRIT_MULT,  ## el crítico pasa a × value
	COMBO,  ## racha hasta × value
	MANUAL_CLICK_MULT,  ## clic a mano × value
	CLICK_PER_OWNED,  ## clic +value por cada generador que tengas
	GENERATOR_CLICK_MULT,  ## bono de clic de target_id × value
	GENERATOR_SYNERGY,  ## producción de target_id (vacío = todos) +value por unidad de source_id
	PACKAGE_UNLOCK,  ## aparece la barra de cintas
	PACKAGE_RATE,  ## la barra mide × value
	PACKAGE_RARITY,  ## rara = value, negra = value2
	PACKAGE_REWARD,  ## cintas × value
	EVENT_REWARD,  ## eventos (target_id; vacío = todos) × value, y frecuencia × value2 (1 = igual)
	SKILL,  ## habilidad del mando: skill, duration, cooldown, value, value2
	AUTO_ECHO,  ## los clics automáticos también hacen racha y crítico
	PRODUCTION_MULT,  ## toda la producción × value
}

@export var id: StringName
@export var name_key: String
@export var desc_key: String
@export var kind: Kind
@export var target_id: StringName
@export var value: float
@export var value2: float = 1.0
@export var cost: float
@export var req_energy_produced: float
@export var req_generator_count: int
@export var req_manual_clicks: int
@export var req_packages: int
@export var req_events_caught: int
## Padre en el árbol de mejoras: debe estar comprado (o, si es un generador, tener al menos uno).
@export var requires_id: StringName
## SKILL: &"sweep" (clics automáticos extra), &"surge" (clic × value), &"seek" (provoca un evento),
## &"overload" (apuesta: producción × value o tele apagada value2 s).
@export var skill: StringName
@export var duration: float
@export var cooldown: float
@export var source_id: StringName
## Celda del árbol en la tele (rejilla de 10 × 5) e icono (assets/textures/tv/icon_<icon>.png).
@export var tree_cell: Vector2i
@export var icon: StringName
## Mejoras de consumo: aviso antes de comprar («Notarás algo en casa»).
@export var warning_key: String
