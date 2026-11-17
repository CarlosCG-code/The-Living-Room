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
	config.interference_min = 120
	config.interference_max = 240
	config.interference_duration = 8
	config.reward_production_seconds = 60
	config.reward_min_clicks = 50
	eco = Economy.new(config, null, 42)


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
	var next := eco.state.interference_next_in
	assert_between(next, 120.0, 240.0)
	eco.tick(next - 0.5, false)
	assert_false(eco.interference_active())
	eco.tick(1.0, false)
	assert_true(eco.interference_active())
	eco.tick(7.5, false)
	assert_true(eco.interference_active())
	eco.tick(1.0, false)
	assert_false(eco.interference_active())
	assert_between(eco.state.interference_next_in, 120.0, 240.0)


func test_catch_interference_pays_once() -> void:
	eco.tick(eco.state.interference_next_in + 0.1, false)
	var e0 := eco.state.energy
	assert_true(eco.catch_interference())
	assert_almost_eq(eco.state.energy - e0, 50.0, 0.0001)  # sin producción: mínimo de 50 clics
	assert_false(eco.catch_interference())
	assert_false(eco.interference_active())


func test_catch_reward_uses_production() -> void:
	_give(1000)
	for i in 10:
		eco.buy(&"a")
	eco.tick(eco.state.interference_next_in + 0.1, false)
	var e0 := eco.state.energy
	eco.catch_interference()
	assert_almost_eq(eco.state.energy - e0, 60.0 * 10.0, 0.0001)


func test_missed_interference_pays_nothing() -> void:
	eco.tick(eco.state.interference_next_in + 0.1, false)
	var e0 := eco.state.energy
	eco.tick(9.0, false)
	assert_false(eco.interference_active())
	assert_almost_eq(eco.state.energy, e0, 0.0001)


func test_restart_cancels_active_interference() -> void:
	_give(2000)
	eco.tick(eco.state.interference_next_in + 0.1, false)
	assert_true(eco.interference_active())
	eco.restart()
	assert_false(eco.interference_active())
	assert_between(eco.state.interference_next_in, 120.0, 240.0)


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
	assert_eq(other.state.interference_next_in, eco.state.interference_next_in)
