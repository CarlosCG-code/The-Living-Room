class_name EconomyConfig
extends Resource

@export var generators: Array[GeneratorDef] = []
@export var upgrades: Array[UpgradeDef] = []
@export var cost_growth: float = 1.15
@export var threshold: float = 10000000.0
## Umbral de cada run como múltiplo de threshold (índice 0 = run 1); las que faltan usan el último.
@export var threshold_mult: Array[float] = []
@export var base_click_value: float = 1.0
@export var events: Array[TvEventDef] = []
@export var event_min: float = 120.0
@export var event_max: float = 240.0
## La primera run enseña los eventos: el primero sale a los first_event_at segundos y es first_event_id.
@export var first_event_at: float = 90.0
@export var first_event_id: StringName = &"interference"
## Mejoras permanentes, en el orden en que se compran.
@export var perks: Array[PerkDef] = []
## Carga al reiniciar: carga_base × raíz(producida / umbral). 3 al llegar; 6 con 4 veces el umbral.
@export var carga_base: float = 3.0
## Crítico de partida (solo clic a mano): probabilidad y multiplicador.
@export var crit_chance: float = 0.05
@export var crit_mult: float = 5.0
## Clics para llenar la barra de cintas, y premio de cada rareza en segundos de ingresos
## (común, rara) y de la negra (producción × black_mult durante black_seconds).
@export var package_bar: float = 60.0
@export var package_seconds: Vector2 = Vector2(20, 60)
@export var black_mult: float = 3.0
@export var black_seconds: float = 15.0
## Tope de clics a mano por segundo (ratón y Espacio juntos): frena los autoclickers y el doble clic.
@export var max_clicks_per_second: float = 10.0


func threshold_for(run_index: int) -> float:
	if threshold_mult.is_empty():
		return threshold
	return threshold * threshold_mult[clampi(run_index - 1, 0, threshold_mult.size() - 1)]


func find_generator(id: StringName) -> GeneratorDef:
	for g in generators:
		if g.id == id:
			return g
	return null


func find_perk(id: StringName) -> PerkDef:
	for p in perks:
		if p.id == id:
			return p
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
