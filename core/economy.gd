class_name Economy
extends RefCounted

signal purchased(item_id: StringName)
signal restarted(run_index: int)

var config: EconomyConfig
var state: RunState

var _rng := RandomNumberGenerator.new()
# Derivados de las mejoras compradas; se recalculan al comprar y al reiniciar.
var _gen_mult: Dictionary = {}  # StringName -> float
var _click_mult: float = 1.0
var _production_share: float = 0.0
var _hold_rate: float = 0.0
var _auto_rate: float = 0.0


func _init(p_config: EconomyConfig, p_state: RunState = null, rng_seed: int = -1) -> void:
	config = p_config
	if rng_seed == -1:
		_rng.randomize()
	else:
		_rng.seed = rng_seed
	state = p_state if p_state != null else RunState.new_run(config, 1, _rng)
	_recalc()


# --- Acciones ---

func click() -> void:
	_gain(click_value())


func tick(delta: float, holding: bool) -> void:
	_gain(production_per_second() * delta)
	_gain(click_value() * _auto_clicks(holding) * delta)
	if state.event_id != &"":
		state.event_left -= delta
		if state.event_left <= 0.0:
			_end_event()
	else:
		state.event_next_in -= delta
		if state.event_next_in <= 0.0:
			_start_event()
	state.play_time += delta


func buy(id: StringName) -> bool:
	if not is_visible(id) or is_bought(id) or state.energy < cost_of(id):
		return false
	state.energy -= cost_of(id)
	if config.find_generator(id) != null:
		state.generators[id] = owned(id) + 1
	else:
		state.upgrades.append(id)
		_recalc()
	purchased.emit(id)
	return true


## Atrapa el evento activo si se puede atrapar; da su ráfaga una sola vez.
func catch_event() -> bool:
	var e := active_event()
	if e == null or not e.catchable():
		return false
	_gain(maxf(e.reward_production_seconds * production_per_second(), e.reward_min_clicks * click_value()))
	_end_event()
	return true


func restart() -> bool:
	if not can_restart():
		return false
	state = RunState.new_run(config, state.run_index + 1, _rng)
	_recalc()
	restarted.emit(state.run_index)
	return true


# --- Consultas ---

func production_per_second() -> float:
	var e := active_event()
	return _production(_gen_mult, &"", 0) * (e.production_mult if e else 1.0)


## Producción total por segundo de un generador (poseídos × base × multiplicador).
func generator_production(id: StringName) -> float:
	var g := config.find_generator(id)
	return 0.0 if g == null else owned(id) * g.base_production * _gen_mult.get(id, 1.0)


## (clic base + bonos de los generadores) × multiplicador de clic + parte de la producción.
func click_value() -> float:
	return _click_base(_gen_mult, &"", 0) * _click_mult + _production_share * production_per_second()


## Energía que suma un generador a cada clic (poseídos × bono × multiplicadores).
func generator_click_bonus(id: StringName) -> float:
	var g := config.find_generator(id)
	return 0.0 if g == null else owned(id) * g.click_bonus * _gen_mult.get(id, 1.0) * _click_mult


func cost_of(id: StringName) -> float:
	var g := config.find_generator(id)
	if g != null:
		return ceilf(g.base_cost * pow(config.cost_growth, owned(id)))
	var u := config.find_upgrade(id)
	return u.cost if u != null else INF


func is_visible(id: StringName) -> bool:
	var g := config.find_generator(id)
	if g != null:
		return state.energy_produced_run >= g.req_energy_produced and _parent_met(g.requires_id)
	var u := config.find_upgrade(id)
	if u == null or not _parent_met(u.requires_id):
		return false
	if state.energy_produced_run < u.req_energy_produced:
		return false
	return u.req_generator_count == 0 or owned(u.target_id) >= u.req_generator_count


func is_bought(id: StringName) -> bool:
	return state.upgrades.has(id)


func owned(id: StringName) -> int:
	return state.generators.get(id, 0)


func can_restart() -> bool:
	return state.energy_produced_run >= config.threshold


func active_event() -> TvEventDef:
	return config.find_event(state.event_id) if state.event_id != &"" else null


## 0 al empezar el evento activo, 1 al acabar (0 si no hay).
func event_progress() -> float:
	var e := active_event()
	return 0.0 if e == null else clampf(1.0 - state.event_left / e.duration, 0.0, 1.0)


func visible_generators() -> Array[GeneratorDef]:
	var result: Array[GeneratorDef] = []
	for g in config.generators:
		if is_visible(g.id):
			result.append(g)
	return result


func visible_upgrades() -> Array[UpgradeDef]:
	var result: Array[UpgradeDef] = []
	for u in config.upgrades:
		if is_visible(u.id) and not is_bought(u.id):
			result.append(u)
	return result


## Clics por segundo que no hace la mano: mantener pulsado (si se mantiene) y Dial solo.
func auto_clicks_per_second(holding: bool) -> float:
	return _auto_clicks(holding)


func income_per_second(manual_cps: float, holding: bool) -> float:
	return _income(manual_cps, holding, _gen_mult, &"", 0, _click_mult, _production_share, _hold_rate, _auto_rate)


## Cuánto subiría income_per_second con esa compra, sin comprar ni exigir Energía.
func gain_if_bought(id: StringName, manual_cps: float, holding: bool) -> float:
	var before := income_per_second(manual_cps, holding)
	if config.find_generator(id) != null:
		return _income(manual_cps, holding, _gen_mult, id, 1, _click_mult, _production_share, _hold_rate, _auto_rate) - before
	var u := config.find_upgrade(id)
	if u == null or is_bought(id):
		return 0.0
	var gm := _gen_mult
	var cm := _click_mult
	var share := _production_share
	var hold := _hold_rate
	var auto := _auto_rate
	match u.kind:
		UpgradeDef.Kind.GENERATOR_MULT:
			gm = _gen_mult.duplicate()
			gm[u.target_id] = gm.get(u.target_id, 1.0) * u.value
		UpgradeDef.Kind.CLICK_MULT:
			cm *= u.value
		UpgradeDef.Kind.CLICK_PRODUCTION_SHARE:
			share += u.value
		UpgradeDef.Kind.HOLD_RATE:
			hold = maxf(hold, u.value)
		UpgradeDef.Kind.AUTO_CLICK_RATE:
			auto = maxf(auto, u.value)
	return _income(manual_cps, holding, gm, &"", 0, cm, share, hold, auto) - before


# --- Internos ---

func _parent_met(parent: StringName) -> bool:
	if parent == &"":
		return true
	return owned(parent) > 0 if config.find_generator(parent) != null else is_bought(parent)


func _gain(amount: float) -> void:
	state.energy += amount
	state.energy_produced_run += amount


func _start_event() -> void:
	var total := 0.0
	for e in config.events:
		total += e.weight
	var roll := _rng.randf() * total
	for e in config.events:
		roll -= e.weight
		if roll < 0.0:
			state.event_id = e.id
			state.event_left = e.duration
			return
	_end_event()  # sin eventos en la config: solo se reprograma


func _end_event() -> void:
	state.event_id = &""
	state.event_left = 0.0
	state.event_next_in = _rng.randf_range(config.event_min, config.event_max)


func _auto_clicks(holding: bool) -> float:
	return (_hold_rate if holding else 0.0) + _auto_rate


func _production(gen_mult: Dictionary, extra_id: StringName, extra_count: int) -> float:
	var total := 0.0
	for g in config.generators:
		var count := owned(g.id) + (extra_count if g.id == extra_id else 0)
		total += count * g.base_production * gen_mult.get(g.id, 1.0)
	return total


func _click_base(gen_mult: Dictionary, extra_id: StringName, extra_count: int) -> float:
	var total := config.base_click_value
	for g in config.generators:
		var count := owned(g.id) + (extra_count if g.id == extra_id else 0)
		total += count * g.click_bonus * gen_mult.get(g.id, 1.0)
	return total


func _income(manual_cps: float, holding: bool, gen_mult: Dictionary, extra_id: StringName, extra_count: int,
		click_mult: float, share: float, hold: float, auto: float) -> float:
	var prod := _production(gen_mult, extra_id, extra_count)
	var per_click := _click_base(gen_mult, extra_id, extra_count) * click_mult + share * prod
	return prod + per_click * (manual_cps + (hold if holding else 0.0) + auto)


func _recalc() -> void:
	_gen_mult = {}
	_click_mult = 1.0
	_production_share = 0.0
	_hold_rate = 0.0
	_auto_rate = 0.0
	for id in state.upgrades:
		var u := config.find_upgrade(id)
		if u == null:
			continue
		match u.kind:
			UpgradeDef.Kind.GENERATOR_MULT:
				_gen_mult[u.target_id] = _gen_mult.get(u.target_id, 1.0) * u.value
			UpgradeDef.Kind.CLICK_MULT:
				_click_mult *= u.value
			UpgradeDef.Kind.CLICK_PRODUCTION_SHARE:
				_production_share += u.value
			UpgradeDef.Kind.HOLD_RATE:
				_hold_rate = maxf(_hold_rate, u.value)
			UpgradeDef.Kind.AUTO_CLICK_RATE:
				_auto_rate = maxf(_auto_rate, u.value)
