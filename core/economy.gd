class_name Economy
extends RefCounted

# Economía de la run (specs/incremental_v2.md). Todas las mejoras se reducen a unos modificadores (Mods):
# el juego los usa en tiempo real y gain_if_bought los usa en valor esperado (el test de ritmo compra con
# ellos), así que una mejora nueva solo se describe una vez, en _apply_upgrade.

signal purchased(item_id: StringName)
signal restarted(run_index: int)
signal perk_bought(perk_id: StringName)
signal package_dropped(rarity: int)
signal package_opened(rarity: int, amount: float)
signal skill_used(skill: StringName, success: bool)

enum Rarity { COMMON, RARE, BLACK }

const STREAK_INTERVAL := 0.5  # un clic a menos de esto del anterior sube la racha
const STREAK_FULL := 20  # clics seguidos para la racha máxima
const AUTO_BAR_FILL := 0.25  # lo que llena la barra un clic automático (uno a mano llena 1)
const HOLD_BAR_FILL := 0.5  # mantener pulsado sigue siendo tu mano: llena la mitad y hace racha (sin crítico)
const ECHO_MULT := 1.25  # Eco: los clics automáticos valen más, además de hacer racha y crítico
const PACKAGE_LIFE := 20.0  # una cinta sin abrir se pierde a los 20 s
const MAX_PACKAGES := 2
const INCOME_SMOOTH := 10.0  # segundos de media de «ingresos por segundo»
const SWEEP_CPS := 10.0
const SIM_COMBO_CPS := 2.0  # en valor esperado, a partir de estos clics/s se cuenta la racha llena


## Modificadores derivados de las mejoras y permanentes compradas.
class Mods:
	var gen_mult := {}  # id -> × (producción y bono de clic)
	var gen_click_mult := {}  # id -> × (solo bono de clic)
	var synergies: Array = []  # [target_id, source_id, por unidad]
	var prod_mult := 1.0
	var click_mult := 1.0
	var manual_mult := 1.0
	var per_owned := 0.0
	var share := 0.0
	var hold := 0.0
	var auto := 0.0
	var crit_chance := 0.0
	var crit_mult := 1.0
	var combo_max := 1.0
	var combo_grace := 1.2
	var echo := false
	var packages := false
	var bar_mult := 1.0
	var rare := 0.17
	var black := 0.03
	var package_mult := 1.0
	var event_mult := {}  # id de evento (o &"" para todos) -> ×
	var event_freq := 1.0
	var skills := {}  # skill -> UpgradeDef
	var discount := 1.0
	var machine_req := 1.0
	var crit_bar_fill := 0.0
	var eyes: PerkDef = null

	func copy() -> Mods:
		var m := Mods.new()
		for p in get_property_list():
			if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				var v = get(p.name)
				m.set(p.name, v.duplicate() if v is Dictionary or v is Array else v)
		return m


var config: EconomyConfig
var state: RunState
var mods := Mods.new()
## El último clic a mano fue crítico (para la presentación).
var last_click_crit := false

var _rng := RandomNumberGenerator.new()  # eventos y cintas
var _click_rng := RandomNumberGenerator.new()  # críticos: no mueve la secuencia de eventos
var _click_budget: float = 0.0  # clics a mano que quedan este segundo; no se guarda
var _streak := 0
var _since_click := INF
var _packages: Array[Dictionary] = []  # cintas en la nieve: {rarity, left}; no se guardan
var _income_ema := 0.0
var _tick_gain := 0.0


func _init(p_config: EconomyConfig, p_state: RunState = null, rng_seed: int = -1) -> void:
	config = p_config
	if rng_seed == -1:
		_rng.randomize()
		_click_rng.randomize()
	else:
		_rng.seed = rng_seed
		_click_rng.seed = rng_seed + 1
	state = p_state if p_state != null else RunState.new_run(config, 1, _rng)
	_click_budget = config.max_clicks_per_second
	_recalc()


# --- Acciones ---

## Clic a mano. Devuelve la Energía ganada (0 si se pasa del tope de clics por segundo o la tele está apagada).
func click() -> float:
	if _click_budget < 1.0 or timer(&"tv_off") > 0.0:
		return 0.0
	_click_budget -= 1.0
	_streak = mini(STREAK_FULL, _streak + 1) if _since_click < STREAK_INTERVAL else 1
	_since_click = 0.0
	last_click_crit = _click_rng.randf() < mods.crit_chance
	var amount := manual_click_value(last_click_crit)
	_gain(amount)
	state.manual_clicks += 1
	_fill_bar(1.0 + (mods.crit_bar_fill * bar_size() if last_click_crit else 0.0))
	return amount


func tick(delta: float, holding: bool) -> void:
	_click_budget = minf(config.max_clicks_per_second, _click_budget + config.max_clicks_per_second * delta)
	_since_click += delta
	if _since_click > mods.combo_grace:
		_streak = 0
	var off := timer(&"tv_off") > 0.0
	if not off:
		_gain(production_per_second() * delta)
		var auto_cps := auto_clicks_per_second(false)
		var hold_cps := mods.hold if holding else 0.0
		_gain((auto_click_value() * auto_cps + hold_click_value() * hold_cps) * delta)
		_fill_bar((AUTO_BAR_FILL * auto_cps + HOLD_BAR_FILL * hold_cps) * delta)
	for i in range(_packages.size() - 1, -1, -1):
		_packages[i]["left"] -= delta
		if _packages[i]["left"] <= 0.0:
			_packages.remove_at(i)
	for key: String in state.timers.keys():
		state.timers[key] -= delta
		if state.timers[key] <= 0.0:
			state.timers.erase(key)
	if state.event_id != &"":
		state.event_left -= delta
		if state.event_left <= 0.0:
			_end_event()
	else:
		state.event_next_in -= delta
		if state.event_next_in <= 0.0:
			_start_event()
	if delta > 0.0:
		_income_ema += (_tick_gain / delta - _income_ema) * minf(1.0, delta / INCOME_SMOOTH)
	_tick_gain = 0.0
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
	_gain(event_reward(e), false)
	state.events_caught += 1
	if mods.eyes:
		state.timers["bump"] = 3600.0  # la siguiente cinta sube un grado
	_end_event()
	return true


## Abre la cinta i de la nieve. Devuelve la Energía que da (0 si no existe).
func open_package(i: int) -> float:
	if i < 0 or i >= _packages.size():
		return 0.0
	var rarity: int = _packages[i]["rarity"]
	_packages.remove_at(i)
	var amount := 0.0
	if rarity == Rarity.BLACK:
		state.timers["black"] = config.black_seconds
	else:
		var seconds := config.package_seconds.x if rarity == Rarity.COMMON else config.package_seconds.y
		amount = seconds * income_now() * mods.package_mult
		_gain(amount, false)
	state.packages_opened += 1
	package_opened.emit(rarity, amount)
	return amount


## Usa una habilidad del mando si está comprada y sin enfriamiento.
func use_skill(skill: StringName) -> bool:
	var u: UpgradeDef = mods.skills.get(skill)
	if u == null or skill_cooldown(skill) > 0.0 or timer(&"tv_off") > 0.0:
		return false
	state.timers["cd_" + String(skill)] = u.cooldown
	var success := true
	match skill:
		&"sweep", &"surge":
			state.timers[String(skill)] = u.duration
		&"seek":
			if state.event_id == &"":
				_start_event()
		&"overload":
			success = _rng.randf() < 0.7
			if success:
				state.timers["overload"] = u.duration
			else:
				state.timers["tv_off"] = u.value2
	skill_used.emit(skill, success)
	return true


func restart() -> bool:
	if not can_restart():
		return false
	var carga := state.carga + carga_if_restarted()
	var perks := state.perks.duplicate()
	state = RunState.new_run(config, state.run_index + 1, _rng)
	state.carga = carga
	state.perks = perks
	_packages.clear()
	_streak = 0
	for id in perks:
		_grant_start(config.find_perk(id))
	_recalc()
	restarted.emit(state.run_index)
	return true


## Carga que daría reiniciar ahora (0 si aún no se puede).
func carga_if_restarted() -> int:
	if not can_restart():
		return 0
	var bonus := 0
	for id in state.perks:
		var p := config.find_perk(id)
		if p and p.kind == PerkDef.Kind.CARGA_BONUS:
			bonus += int(p.value)
	return int(floorf(config.carga_base * sqrt(state.energy_produced_run / config.threshold))) + bonus


## Las permanentes se compran en cualquier orden, con Carga suficiente. Lo que da al empezar la run se da ya.
func buy_perk(id: StringName) -> bool:
	var p := config.find_perk(id)
	if p == null or has_perk(id) or state.carga < p.cost:
		return false
	state.carga -= p.cost
	state.perks.append(id)
	_grant_start(p)
	_recalc()
	perk_bought.emit(id)
	return true


func has_perk(id: StringName) -> bool:
	return state.perks.has(id)


# --- Consultas ---

func production_per_second() -> float:
	if timer(&"tv_off") > 0.0:
		return 0.0
	var e := active_event()
	var buff := (e.production_mult if e else 1.0)
	if timer(&"black") > 0.0:
		buff *= config.black_mult
	if timer(&"overload") > 0.0:
		buff *= (mods.skills[&"overload"] as UpgradeDef).value if mods.skills.has(&"overload") else 1.0
	return _production(mods, &"", 0) * buff


## Producción total por segundo de un generador (sin efectos temporales).
func generator_production(id: StringName) -> float:
	var g := config.find_generator(id)
	return 0.0 if g == null else owned(id) * g.base_production * _gen_prod_mult(mods, g.id)


## Valor de un clic automático (y la base de todos): bonos de los generadores × multiplicadores.
func click_value() -> float:
	var surge := 1.0
	if timer(&"surge") > 0.0 and mods.skills.has(&"surge"):
		surge = (mods.skills[&"surge"] as UpgradeDef).value
	return _click_raw(mods, &"", 0) * surge


## Valor de un clic a mano: × mano × racha × crítico + parte de la producción.
func manual_click_value(crit: bool = false) -> float:
	return click_value() * mods.manual_mult * combo_mult() * (mods.crit_mult if crit else 1.0) \
		+ mods.share * production_per_second()


func auto_click_value() -> float:
	if not mods.echo:
		return click_value()
	return click_value() * ECHO_MULT * combo_mult() * (1.0 + mods.crit_chance * (mods.crit_mult - 1.0))


## Clic de mantener pulsado: tu mano, con racha llena pero sin crítico.
func hold_click_value() -> float:
	return click_value() * mods.manual_mult * mods.combo_max


## 1 sin racha; hasta combo_max con la racha llena.
func combo_mult() -> float:
	return 1.0 + (mods.combo_max - 1.0) * float(_streak) / STREAK_FULL


func combo_fraction() -> float:
	return float(_streak) / STREAK_FULL if mods.combo_max > 1.0 else 0.0


## Energía que suma un generador a cada clic (poseídos × bono × multiplicadores).
func generator_click_bonus(id: StringName) -> float:
	var g := config.find_generator(id)
	if g == null:
		return 0.0
	return owned(id) * g.click_bonus * mods.gen_mult.get(id, 1.0) * mods.gen_click_mult.get(id, 1.0) * mods.click_mult


## Ingresos por segundo de ahora (media de los últimos segundos, sin ráfagas); base de cintas y eventos.
func income_now() -> float:
	# Como mínimo, un clic por segundo: al principio no hay producción y la cinta no puede dar 0.
	return maxf(_income_ema, maxf(production_per_second() + auto_click_value() * auto_clicks_per_second(false),
			click_value()))


func event_reward(e: TvEventDef) -> float:
	var mult: float = mods.event_mult.get(e.id, 1.0) * mods.event_mult.get(&"", 1.0)
	return maxf(e.reward_production_seconds * income_now(), e.reward_min_clicks * click_value()) * mult


func cost_of(id: StringName) -> float:
	var g := config.find_generator(id)
	if g != null:
		return ceilf(g.base_cost * pow(config.cost_growth, owned(id)) * mods.discount)
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
	if state.manual_clicks < u.req_manual_clicks or state.packages_opened < u.req_packages:
		return false
	if state.events_caught < u.req_events_caught:
		return false
	return u.req_generator_count == 0 or owned(u.target_id) >= ceili(u.req_generator_count * mods.machine_req)


func is_bought(id: StringName) -> bool:
	return state.upgrades.has(id)


func owned(id: StringName) -> int:
	return state.generators.get(id, 0)


func total_owned() -> int:
	var n := 0
	for id: StringName in state.generators:
		n += state.generators[id]
	return n


func can_restart() -> bool:
	return state.energy_produced_run >= config.threshold


func active_event() -> TvEventDef:
	return config.find_event(state.event_id) if state.event_id != &"" else null


## 0 al empezar el evento activo, 1 al acabar (0 si no hay).
func event_progress() -> float:
	var e := active_event()
	return 0.0 if e == null else clampf(1.0 - state.event_left / e.duration, 0.0, 1.0)


func timer(key: StringName) -> float:
	return state.timers.get(String(key), 0.0)


func skill_cooldown(skill: StringName) -> float:
	return timer(StringName("cd_" + String(skill)))


func has_skill(skill: StringName) -> bool:
	return mods.skills.has(skill)


func packages() -> Array[Dictionary]:
	return _packages


## Lo que mide la barra de cintas (en clics a mano).
func bar_size() -> float:
	return config.package_bar * mods.bar_mult


func bar_fraction() -> float:
	return state.package_bar / bar_size() if mods.packages else 0.0


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


## Clics por segundo que no hace la mano: mantener pulsado (si se mantiene), Dial solo y Barrido.
func auto_clicks_per_second(holding: bool) -> float:
	return (mods.hold if holding else 0.0) + mods.auto + (SWEEP_CPS if timer(&"sweep") > 0.0 else 0.0)


## Ingresos por segundo en valor esperado (crítico, racha, cintas, eventos y habilidades medias).
func income_per_second(manual_cps: float, holding: bool) -> float:
	return _income(mods, manual_cps, holding, &"", 0)


## Cuánto subiría income_per_second con esa compra, sin comprar ni exigir Energía.
func gain_if_bought(id: StringName, manual_cps: float, holding: bool) -> float:
	var before := income_per_second(manual_cps, holding)
	if config.find_generator(id) != null:
		return _income(mods, manual_cps, holding, id, 1) - before
	var u := config.find_upgrade(id)
	if u == null or is_bought(id):
		return 0.0
	var m := mods.copy()
	_apply_upgrade(m, u)
	return _income(m, manual_cps, holding, &"", 0) - before


# --- Internos ---

func _parent_met(parent: StringName) -> bool:
	if parent == &"":
		return true
	return owned(parent) > 0 if config.find_generator(parent) != null else is_bought(parent)


func _gain(amount: float, counts_for_rate: bool = true) -> void:
	state.energy += amount
	state.energy_produced_run += amount
	if counts_for_rate:
		_tick_gain += amount


func _fill_bar(amount: float) -> void:
	if not mods.packages:
		return
	state.package_bar += amount
	while state.package_bar >= bar_size():
		state.package_bar -= bar_size()
		if _packages.size() < MAX_PACKAGES:
			var rarity := _roll_rarity()
			_packages.append({"rarity": rarity, "left": PACKAGE_LIFE})
			package_dropped.emit(rarity)


func _roll_rarity() -> int:
	var roll := _rng.randf()
	var rarity := Rarity.BLACK if roll < mods.black else (Rarity.RARE if roll < mods.black + mods.rare else Rarity.COMMON)
	if state.timers.has("bump"):
		state.timers.erase("bump")
		rarity = mini(rarity + 1, Rarity.BLACK)
	return rarity


func _start_event() -> void:
	# El primer evento de la partida es siempre el mismo (enseña a clicar lo raro).
	var first := config.find_event(config.first_event_id)
	if first and state.run_index == 1 and state.play_time <= config.first_event_at + 1.0:
		state.event_id = first.id
		state.event_left = first.duration
		return
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
	var lo := config.event_min
	var hi := config.event_max
	if mods.eyes:
		lo = mods.eyes.value
		hi = mods.eyes.value2
	state.event_next_in = _rng.randf_range(lo, hi) * mods.event_freq


func _gen_prod_mult(m: Mods, id: StringName) -> float:
	var mult: float = m.gen_mult.get(id, 1.0)
	for s: Array in m.synergies:
		if s[0] == &"" or s[0] == id:
			mult *= 1.0 + float(s[2]) * owned(s[1])
	return mult


func _production(m: Mods, extra_id: StringName, extra_count: int) -> float:
	var total := 0.0
	for g in config.generators:
		var count := owned(g.id) + (extra_count if g.id == extra_id else 0)
		total += count * g.base_production * _gen_prod_mult(m, g.id)
	return total * m.prod_mult


func _click_raw(m: Mods, extra_id: StringName, extra_count: int) -> float:
	var total := config.base_click_value
	var units := total_owned() + extra_count
	for g in config.generators:
		var count := owned(g.id) + (extra_count if g.id == extra_id else 0)
		total += count * g.click_bonus * m.gen_mult.get(g.id, 1.0) * m.gen_click_mult.get(g.id, 1.0)
	return total * m.click_mult * (1.0 + m.per_owned * units)


func _income(m: Mods, manual_cps: float, holding: bool, extra_id: StringName, extra_count: int) -> float:
	var prod := _production(m, extra_id, extra_count)
	var raw := _click_raw(m, extra_id, extra_count)
	var crit := 1.0 + m.crit_chance * (m.crit_mult - 1.0)
	var combo := m.combo_max if manual_cps >= SIM_COMBO_CPS else 1.0
	var surge_up := 0.0
	var sweep_cps := 0.0
	if m.skills.has(&"surge"):
		var s: UpgradeDef = m.skills[&"surge"]
		surge_up = s.duration / s.cooldown * (s.value - 1.0)
	if m.skills.has(&"sweep"):
		var s: UpgradeDef = m.skills[&"sweep"]
		sweep_cps = SWEEP_CPS * s.duration / s.cooldown
	if m.skills.has(&"overload"):
		var s: UpgradeDef = m.skills[&"overload"]
		prod *= 1.0 + (0.7 * s.duration * (s.value - 1.0) - 0.3 * s.value2) / s.cooldown
	var auto_cps := m.auto + sweep_cps
	var hold_cps := m.hold if holding else 0.0
	var auto_value := raw * (1.0 + surge_up) * ((ECHO_MULT * crit * combo) if m.echo else 1.0)
	var hold_value := raw * (1.0 + surge_up) * m.manual_mult * m.combo_max
	var manual_value := raw * (1.0 + surge_up) * m.manual_mult * crit * combo + m.share * prod
	var income := prod + manual_cps * manual_value + auto_cps * auto_value + hold_cps * hold_value
	if m.packages:
		var fill := manual_cps + AUTO_BAR_FILL * auto_cps + HOLD_BAR_FILL * hold_cps
		var per_second := fill / (config.package_bar * m.bar_mult)
		var common := 1.0 - m.rare - m.black
		var seconds := common * config.package_seconds.x + m.rare * config.package_seconds.y
		var black_value := m.black * config.black_seconds * (config.black_mult - 1.0) * prod
		income += per_second * (seconds * income * m.package_mult + black_value)
	var catchable := 0.0
	var weights := 0.0
	for e in config.events:
		weights += e.weight
		if e.catchable():
			catchable += e.weight * e.reward_production_seconds * m.event_mult.get(e.id, 1.0) * m.event_mult.get(&"", 1.0)
	if weights > 0.0:
		var interval := (config.event_min + config.event_max) * 0.5 * m.event_freq
		if m.skills.has(&"seek"):
			interval = 1.0 / (1.0 / interval + 1.0 / (m.skills[&"seek"] as UpgradeDef).cooldown)
		income += income * (catchable / weights) / interval
	return income


func _recalc() -> void:
	var m := Mods.new()
	m.crit_chance = config.crit_chance
	m.crit_mult = config.crit_mult
	for id in state.perks:
		var p := config.find_perk(id)
		if p == null:
			continue
		match p.kind:
			PerkDef.Kind.CLICK_MULT:
				m.manual_mult *= p.value
			PerkDef.Kind.GENERATOR_DISCOUNT:
				m.discount *= p.value
				m.machine_req *= p.value2
			PerkDef.Kind.COMBO_GRACE:
				m.combo_grace = p.value
				m.crit_bar_fill = p.value2
			PerkDef.Kind.EVENT_BOOST:
				m.eyes = p
	for id in state.upgrades:
		var u := config.find_upgrade(id)
		if u != null:
			_apply_upgrade(m, u)
	mods = m


func _apply_upgrade(m: Mods, u: UpgradeDef) -> void:
	match u.kind:
		UpgradeDef.Kind.GENERATOR_MULT:
			m.gen_mult[u.target_id] = m.gen_mult.get(u.target_id, 1.0) * u.value
		UpgradeDef.Kind.CLICK_MULT:
			m.click_mult *= u.value
		UpgradeDef.Kind.CLICK_PRODUCTION_SHARE:
			m.share += u.value
		UpgradeDef.Kind.HOLD_RATE:
			m.hold = maxf(m.hold, u.value)
		UpgradeDef.Kind.AUTO_CLICK_RATE:
			m.auto = maxf(m.auto, u.value)
		UpgradeDef.Kind.CRIT_CHANCE:
			m.crit_chance += u.value
		UpgradeDef.Kind.CRIT_MULT:
			m.crit_mult = maxf(m.crit_mult, u.value)
		UpgradeDef.Kind.COMBO:
			m.combo_max = maxf(m.combo_max, u.value)
		UpgradeDef.Kind.MANUAL_CLICK_MULT:
			m.manual_mult *= u.value
		UpgradeDef.Kind.CLICK_PER_OWNED:
			m.per_owned += u.value
		UpgradeDef.Kind.GENERATOR_CLICK_MULT:
			m.gen_click_mult[u.target_id] = m.gen_click_mult.get(u.target_id, 1.0) * u.value
		UpgradeDef.Kind.GENERATOR_SYNERGY:
			m.synergies.append([u.target_id, u.source_id, u.value])
		UpgradeDef.Kind.PACKAGE_UNLOCK:
			m.packages = true
		UpgradeDef.Kind.PACKAGE_RATE:
			m.bar_mult *= u.value
		UpgradeDef.Kind.PACKAGE_RARITY:
			m.rare = maxf(m.rare, u.value)
			m.black = maxf(m.black, u.value2)
		UpgradeDef.Kind.PACKAGE_REWARD:
			m.package_mult *= u.value
		UpgradeDef.Kind.EVENT_REWARD:
			m.event_mult[u.target_id] = m.event_mult.get(u.target_id, 1.0) * u.value
			m.event_freq *= u.value2
		UpgradeDef.Kind.SKILL:
			m.skills[u.skill] = u
		UpgradeDef.Kind.AUTO_ECHO:
			m.echo = true
		UpgradeDef.Kind.PRODUCTION_MULT:
			m.prod_mult *= u.value


# Lo que una mejora permanente da al empezar la run: mejoras ya compradas y generadores.
func _grant_start(p: PerkDef) -> void:
	if p == null:
		return
	for id in p.upgrade_ids:
		if not state.upgrades.has(id):
			state.upgrades.append(id)
	for id: StringName in p.generators:
		state.generators[id] = maxi(owned(id), int(p.generators[id]))
