extends GutTest

# Configuración pequeña propia: no lee data/economy_run1.tres, así el ajuste del ritmo no rompe estos tests.

var config: EconomyConfig
var eco: Economy


func _gen(id: StringName, cost: float, prod: float, req: float) -> GeneratorDef:
	var g := GeneratorDef.new()
	g.id = id
	g.name_key = "GEN_" + String(id).to_upper()
	g.base_cost = cost
	g.base_production = prod
	g.req_energy_produced = req
	return g


func _upg(id: StringName, kind: UpgradeDef.Kind, value: float, cost: float,
		req_energy: float = 0.0, target: StringName = &"", req_count: int = 0) -> UpgradeDef:
	var u := UpgradeDef.new()
	u.id = id
	u.kind = kind
	u.value = value
	u.cost = cost
	u.req_energy_produced = req_energy
	u.target_id = target
	u.req_generator_count = req_count
	return u


func before_each() -> void:
	config = EconomyConfig.new()
	config.generators = [_gen(&"a", 10, 1.0, 0), _gen(&"b", 100, 10.0, 50)]
	config.upgrades = [
		_upg(&"pulse", UpgradeDef.Kind.CLICK_MULT, 2, 5),
		_upg(&"pulse2", UpgradeDef.Kind.CLICK_MULT, 2, 5),
		_upg(&"a_x2", UpgradeDef.Kind.GENERATOR_MULT, 2, 20, 0, &"a", 2),
		_upg(&"a_x2b", UpgradeDef.Kind.GENERATOR_MULT, 2, 20, 0, &"a", 2),
		_upg(&"hold", UpgradeDef.Kind.HOLD_RATE, 4, 5),
		_upg(&"share", UpgradeDef.Kind.CLICK_PRODUCTION_SHARE, 0.5, 5),
		_upg(&"auto1", UpgradeDef.Kind.AUTO_CLICK_RATE, 2, 5),
		_upg(&"auto2", UpgradeDef.Kind.AUTO_CLICK_RATE, 5, 5),
		_upg(&"late", UpgradeDef.Kind.CLICK_MULT, 2, 5, 1000),
	]
	config.cost_growth = 1.15
	config.threshold = 1000
	config.base_click_value = 1
	config.event_min = 120
	config.event_max = 240
	config.events = [_event(&"interference", 8, 60, 50, 1)]
	eco = Economy.new(config, null, 42)


func _event(id: StringName, duration: float, reward_s: float, reward_clicks: float, mult: float) -> TvEventDef:
	var e := TvEventDef.new()
	e.id = id
	e.duration = duration
	e.reward_production_seconds = reward_s
	e.reward_min_clicks = reward_clicks
	e.production_mult = mult
	return e


func _active() -> bool:
	return eco.active_event() != null


func _give(amount: float) -> void:
	eco.state.energy += amount
	eco.state.energy_produced_run += amount


func test_click_adds_click_value() -> void:
	eco.click()
	assert_eq(eco.state.energy, 1.0)
	assert_eq(eco.state.energy_produced_run, 1.0)


func test_buy_generator_cost_grows_with_ceil() -> void:
	_give(100)
	assert_true(eco.buy(&"a"))
	assert_eq(eco.state.energy, 90.0)
	assert_eq(eco.owned(&"a"), 1)
	assert_eq(eco.cost_of(&"a"), ceilf(10 * 1.15))  # 11.5 -> 12


func test_cannot_buy_without_energy() -> void:
	_give(5)
	assert_false(eco.buy(&"a"))
	assert_eq(eco.owned(&"a"), 0)


func test_cannot_buy_invisible_generator() -> void:
	eco.state.energy = 1000  # Energía sin producirla: b exige 50 producidos
	assert_false(eco.is_visible(&"b"))
	assert_false(eco.buy(&"b"))


func test_cannot_buy_upgrade_twice_or_without_requirement() -> void:
	_give(100)
	assert_true(eco.buy(&"pulse"))
	assert_false(eco.buy(&"pulse"))
	assert_false(eco.buy(&"late"))  # exige 1000 producidos
	assert_false(eco.buy(&"a_x2"))  # exige 2 de a


func test_tick_adds_production_and_play_time() -> void:
	_give(22)  # 10 + ceil(11,5) = 22
	assert_true(eco.buy(&"a"))
	assert_true(eco.buy(&"a"))  # 2 x 1/s
	var before := eco.state.energy
	eco.tick(1.5, false)
	assert_almost_eq(eco.state.energy - before, 3.0, 0.0001)
	assert_almost_eq(eco.state.play_time, 1.5, 0.0001)


func test_multipliers_multiply() -> void:
	_give(200)
	eco.buy(&"a")
	eco.buy(&"a")
	eco.buy(&"a_x2")
	eco.buy(&"a_x2b")
	assert_almost_eq(eco.production_per_second(), 2 * 1.0 * 4, 0.0001)
	eco.buy(&"pulse")
	eco.buy(&"pulse2")
	assert_almost_eq(eco.click_value(), 4.0, 0.0001)


func test_tree_parent_must_be_bought_or_owned() -> void:
	config.find_upgrade(&"pulse2").requires_id = &"pulse"
	config.find_generator(&"b").requires_id = &"a"
	_give(200)
	assert_false(eco.is_visible(&"pulse2"), "sin Pulso no aparece su hija")
	assert_false(eco.is_visible(&"b"), "sin ninguna «a» no aparece «b»")
	eco.buy(&"pulse")
	eco.buy(&"a")
	assert_true(eco.is_visible(&"pulse2"))
	assert_true(eco.is_visible(&"b"))


func test_generator_click_bonus() -> void:
	config.generators[0].click_bonus = 0.5
	_give(200)
	eco.buy(&"a")
	eco.buy(&"a")
	eco.buy(&"a_x2")
	assert_almost_eq(eco.click_value(), 1.0 + 2 * 0.5 * 2, 0.0001, "el ×2 del generador dobla su bono")
	eco.buy(&"pulse")
	assert_almost_eq(eco.click_value(), (1.0 + 2.0) * 2, 0.0001, "Pulso dobla también los bonos")
	assert_almost_eq(eco.generator_click_bonus(&"a"), 4.0, 0.0001)
	# Una «a» más: +1 × 2 de producción y +0,5 × 2 × 2 por clic a 1 clic/s.
	assert_almost_eq(eco.gain_if_bought(&"a", 1.0, false), 2.0 + 2.0, 0.0001)


func test_click_production_share() -> void:
	_give(100)
	eco.buy(&"a")
	eco.buy(&"share")
	assert_almost_eq(eco.click_value(), 1.0 + 0.5 * 1.0, 0.0001)


func test_hold_rate_only_when_holding() -> void:
	_give(5)
	eco.buy(&"hold")
	var e0 := eco.state.energy
	eco.tick(1.0, false)
	assert_almost_eq(eco.state.energy, e0, 0.0001)
	eco.tick(1.0, true)
	assert_almost_eq(eco.state.energy, e0 + 4.0, 0.0001)


func test_auto_click_takes_highest_rate() -> void:
	_give(10)
	eco.buy(&"auto2")
	eco.buy(&"auto1")
	var e0 := eco.state.energy
	eco.tick(1.0, false)
	assert_almost_eq(eco.state.energy, e0 + 5.0, 0.0001)


func test_restart_requires_threshold_and_resets() -> void:
	_give(500)
	eco.buy(&"a")
	eco.buy(&"pulse")
	assert_false(eco.restart())
	_give(600)
	watch_signals(eco)
	assert_true(eco.restart())
	assert_eq(eco.state.run_index, 2)
	assert_eq(eco.state.energy, 0.0)
	assert_eq(eco.state.energy_produced_run, 0.0)
	assert_eq(eco.state.play_time, 0.0)
	assert_eq(eco.owned(&"a"), 0)
	assert_false(eco.is_bought(&"pulse"))
	assert_eq(eco.click_value(), 1.0)
	assert_signal_emit_count(eco, "restarted", 1)


func test_interference_appears_in_range_and_lasts() -> void:
	var next := eco.state.event_next_in
	assert_almost_eq(next, 90.0, 0.0001, "el primero de la partida, a los 90 s")
	eco.tick(next - 0.5, false)
	assert_false(_active())
	eco.tick(1.0, false)
	assert_true(_active())
	eco.tick(7.5, false)
	assert_true(_active())
	eco.tick(1.0, false)
	assert_false(_active())
	assert_between(eco.state.event_next_in, 120.0, 240.0)


func test_catch_interference_pays_once() -> void:
	eco.tick(eco.state.event_next_in + 0.1, false)
	var e0 := eco.state.energy
	assert_true(eco.catch_event())
	assert_almost_eq(eco.state.energy - e0, 50.0, 0.0001)  # sin producción: mínimo de 50 clics
	assert_false(eco.catch_event())
	assert_false(_active())


func test_catch_reward_uses_production() -> void:
	_give(1000)
	for i in 10:
		eco.buy(&"a")
	eco.tick(eco.state.event_next_in + 0.1, false)
	var e0 := eco.state.energy
	eco.catch_event()
	assert_almost_eq(eco.state.energy - e0, 60.0 * 10.0, 0.0001)


func test_missed_interference_pays_nothing() -> void:
	eco.tick(eco.state.event_next_in + 0.1, false)
	var e0 := eco.state.energy
	eco.tick(9.0, false)
	assert_false(_active())
	assert_almost_eq(eco.state.energy, e0, 0.0001)


func test_restart_cancels_active_interference() -> void:
	_give(2000)
	eco.tick(eco.state.event_next_in + 0.1, false)
	assert_true(_active())
	eco.restart()
	assert_false(_active())
	assert_between(eco.state.event_next_in, 120.0, 240.0)


func test_gain_if_bought_does_not_change_state() -> void:
	_give(100)
	eco.buy(&"a")
	var snapshot := eco.state.to_dict()
	var gain := eco.gain_if_bought(&"a", 2.0, false)
	assert_almost_eq(gain, 1.0, 0.0001)
	assert_almost_eq(eco.gain_if_bought(&"pulse", 2.0, false), 2.0, 0.0001)
	assert_almost_eq(eco.gain_if_bought(&"hold", 0.0, true), 4.0, 0.0001)
	assert_almost_eq(eco.gain_if_bought(&"hold", 0.0, false), 0.0, 0.0001)
	assert_eq(eco.state.to_dict(), snapshot)


func test_purchase_signal_once_per_buy() -> void:
	_give(100)
	watch_signals(eco)
	eco.buy(&"a")
	eco.buy(&"pulse")
	eco.buy(&"pulse")  # ya comprada: no emite
	assert_signal_emit_count(eco, "purchased", 2)


func test_same_seed_same_interference() -> void:
	var other := Economy.new(config, null, 42)
	assert_eq(other.state.event_next_in, eco.state.event_next_in)


func test_clear_signal_doubles_production_and_cannot_be_caught() -> void:
	config.events = [_event(&"clear_signal", 20, 0, 0, 2)]
	_give(1000)
	for i in 10:
		eco.buy(&"a")
	var base := eco.production_per_second()
	eco.tick(eco.state.event_next_in + 0.1, false)
	assert_almost_eq(eco.production_per_second(), base * 2.0, 0.0001)
	assert_false(eco.catch_event())
	eco.tick(20.0, false)
	assert_almost_eq(eco.production_per_second(), base, 0.0001)


func test_event_picked_by_weight() -> void:
	var never := _event(&"never", 5, 1, 1, 1)
	never.weight = 0.0
	config.events = [never, _event(&"always", 5, 1, 1, 1)]
	for i in 20:
		eco.tick(eco.state.event_next_in + 0.1, false)
		assert_eq(eco.state.event_id, &"always")
		eco.catch_event()


func test_event_progress_goes_from_0_to_1() -> void:
	eco.tick(eco.state.event_next_in + 0.01, false)
	assert_almost_eq(eco.event_progress(), 0.0, 0.01)
	eco.tick(4.0, false)
	assert_almost_eq(eco.event_progress(), 0.5, 0.01)


func test_no_events_only_reschedules() -> void:
	config.events = []
	eco.tick(eco.state.event_next_in + 0.1, false)
	assert_false(_active())
	assert_between(eco.state.event_next_in, 120.0, 240.0)


func _perk(id: StringName, cost: int, kind: PerkDef.Kind, value: float = 1.0) -> PerkDef:
	var p := PerkDef.new()
	p.id = id
	p.cost = cost
	p.kind = kind
	p.value = value
	return p


func _restart_with(produced: float) -> void:
	eco.state.energy_produced_run = produced
	assert_true(eco.restart())


func test_click_cap_per_second() -> void:
	var counted := 0
	for i in 30:
		if eco.click():
			counted += 1
	assert_eq(counted, 10, "sin tiempo, solo 10 clics")
	eco.tick(0.5, false)
	counted = 0
	for i in 30:
		if eco.click():
			counted += 1
	assert_eq(counted, 5, "medio segundo repone 5")


func test_carga_grows_with_square_root() -> void:
	assert_eq(eco.carga_if_restarted(), 0, "sin llegar al umbral no hay Carga")
	eco.state.energy_produced_run = 1000
	assert_eq(eco.carga_if_restarted(), 3)
	eco.state.energy_produced_run = 4000
	assert_eq(eco.carga_if_restarted(), 6)


func test_restart_keeps_carga_and_perks() -> void:
	config.perks = [_perk(&"p1", 1, PerkDef.Kind.CLICK_MULT, 2.0)]
	_restart_with(1000)
	assert_eq(eco.state.carga, 3)
	assert_true(eco.buy_perk(&"p1"))
	assert_eq(eco.state.carga, 2)
	_restart_with(1000)
	assert_eq(eco.state.carga, 5)
	assert_true(eco.has_perk(&"p1"))


func test_perks_in_order_and_need_carga() -> void:
	config.perks = [_perk(&"p1", 2, PerkDef.Kind.CLICK_MULT, 2.0), _perk(&"p2", 1, PerkDef.Kind.CARGA_BONUS)]
	eco.state.carga = 5
	assert_false(eco.buy_perk(&"p2"), "antes, la anterior")
	assert_true(eco.buy_perk(&"p1"))
	assert_false(eco.buy_perk(&"p1"), "no se compra dos veces")
	eco.state.carga = 0
	assert_false(eco.buy_perk(&"p2"), "sin Carga no")


func test_perk_effects() -> void:
	var start := _perk(&"hands", 0, PerkDef.Kind.START_UPGRADES)
	start.upgrade_ids = [&"hold"]
	var gens := _perk(&"memory", 0, PerkDef.Kind.START_GENERATORS)
	gens.generators = {&"a": 3}
	config.perks = [start, gens, _perk(&"habit", 0, PerkDef.Kind.GENERATOR_DISCOUNT, 0.5),
		_perk(&"pulse_p", 0, PerkDef.Kind.CLICK_MULT, 2.0), _perk(&"name", 0, PerkDef.Kind.CARGA_BONUS, 1.0)]
	for p in config.perks:
		assert_true(eco.buy_perk(p.id))
	assert_true(eco.is_bought(&"hold"), "Tus manos: la mejora viene comprada")
	assert_eq(eco.owned(&"a"), 3, "Tu memoria: generadores al empezar")
	assert_almost_eq(eco.click_value(), 2.0, 0.0001, "Tu pulso dobla el clic (base 1)")
	assert_eq(eco.cost_of(&"a"), ceilf(10 * pow(1.15, 3) * 0.5), "Tu costumbre abarata")
	eco.state.energy_produced_run = 1000
	assert_eq(eco.carga_if_restarted(), 4, "Tu nombre: +1")
	_restart_with(1000)
	assert_eq(eco.owned(&"a"), 3, "la run nueva empieza con ellos")
	assert_true(eco.is_bought(&"hold"))


func test_first_event_of_the_game_is_fixed_and_early() -> void:
	config.first_event_at = 90.0
	config.first_event_id = &"interference"
	config.events = [_event(&"clear_signal", 20, 0, 0, 2), _event(&"interference", 8, 60, 50, 1)]
	eco = Economy.new(config, null, 7)
	assert_almost_eq(eco.state.event_next_in, 90.0, 0.0001)
	eco.tick(90.1, false)
	assert_eq(eco.state.event_id, &"interference")
