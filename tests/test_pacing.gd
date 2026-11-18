extends GutTest

# Test de ritmo de la run 1 (specs/hito1.md §3.5 y §7). Simulación determinista: semilla 1, pasos de 0,25 s.

const CONFIG_PATH := "res://data/economy_run1.tres"
const STEP := 0.25
const MAX_TIME := 3600.0
const BUY_WAIT_LIMIT := 30.0

const GENERATOR_IDS: Array[StringName] = [&"antenna", &"valves", &"audio_frequency", &"tuner", &"remote", &"channel_3"]
const CLICK_UPGRADE_IDS: Array[StringName] = [&"pulse", &"dial_hold", &"pulse_strong", &"resonance", &"dial_auto", &"dial_auto_2"]

var config: EconomyConfig


func before_all() -> void:
	config = load(CONFIG_PATH)


func test_config_valid() -> void:
	assert_true(config is EconomyConfig, "el .tres es un EconomyConfig")
	assert_eq(config.generators.size(), 6)
	assert_eq(config.upgrades.size(), 18)
	var gen_ids: Array[StringName] = []
	for g in config.generators:
		assert_true(g is GeneratorDef)
		gen_ids.append(g.id)
		assert_ne(tr(g.name_key), g.name_key, "traducción de %s" % g.name_key)
	assert_eq(gen_ids, GENERATOR_IDS)
	var expected_upgrades: Array[StringName] = []
	for gid in GENERATOR_IDS:
		expected_upgrades.append(StringName("%s_x2_10" % gid))
		expected_upgrades.append(StringName("%s_x2_25" % gid))
	expected_upgrades.append_array(CLICK_UPGRADE_IDS)
	var upg_ids: Array[StringName] = []
	for u in config.upgrades:
		assert_true(u is UpgradeDef)
		upg_ids.append(u.id)
		assert_ne(tr(u.name_key), u.name_key, "traducción de %s" % u.name_key)
		assert_ne(tr(u.desc_key), u.desc_key, "traducción de %s" % u.desc_key)
		if u.kind == UpgradeDef.Kind.GENERATOR_MULT:
			assert_true(gen_ids.has(u.target_id), "target_id de %s" % u.id)
			assert_true(u.req_generator_count == 10 or u.req_generator_count == 25, "requisito de %s" % u.id)
	assert_eq(upg_ids, expected_upgrades)


func test_pacing_ranges() -> void:
	var sims := {
		"activo, sin interferencias": _simulate(6.0, false, false),
		"activo, con interferencias": _simulate(6.0, false, true),
		"tranquilo, sin interferencias": _simulate(0.5, true, false),
		"tranquilo, con interferencias": _simulate(0.5, true, true),
	}
	for label: String in sims:
		var r: Dictionary = sims[label]
		gut.p(_describe(label, r))
		_assert_ranges(label, r)


# --- Simulador ---

func _simulate(manual_cps: float, tranquil: bool, catch_interferences: bool) -> Dictionary:
	var eco := Economy.new(config, null, 1)
	var t := 0.0
	var acc := 0.0
	var purchases: Array[float] = []
	var bought_ids: Array = []
	var appear := {}
	_record_appearances(eco, appear, 0.0)
	var threshold_time := -1.0
	while t < MAX_TIME:
		# El perfil tranquilo pasa siempre holding = true: no tiene efecto hasta comprar Dial firme.
		var holding := tranquil
		var cps := 0.0 if tranquil and eco.is_bought(&"dial_hold") else manual_cps
		if catch_interferences and eco.active_event() != null:
			eco.catch_event()
		acc += cps * STEP
		while acc >= 1.0:
			eco.click()
			acc -= 1.0
		while true:
			var choice := _choose(eco, cps, holding)
			if choice == &"":
				break
			eco.buy(choice)
			purchases.append(t)
			bought_ids.append([t, choice])
		eco.tick(STEP, holding)
		t += STEP
		_record_appearances(eco, appear, t)
		if eco.can_restart():
			threshold_time = t
			break
	return {"purchases": purchases, "bought": bought_ids, "appear": appear, "threshold": threshold_time}


func _choose(eco: Economy, cps: float, holding: bool) -> StringName:
	var best_id := &""
	var best_score := 0.0
	var best_affordable_id := &""
	var best_affordable_score := 0.0
	var candidates: Array[StringName] = []
	for g in eco.visible_generators():
		candidates.append(g.id)
	for u in eco.visible_upgrades():
		candidates.append(u.id)
	for id in candidates:
		var gain := eco.gain_if_bought(id, cps, holding)
		if gain <= 0.0:
			continue
		var item_cost := eco.cost_of(id)
		var score := gain / item_cost
		if score > best_score:  # en un empate gana el primero (orden del .tres)
			best_score = score
			best_id = id
		if item_cost <= eco.state.energy and score > best_affordable_score:
			best_affordable_score = score
			best_affordable_id = id
	if best_id == &"":
		return &""
	var cost := eco.cost_of(best_id)
	if cost <= eco.state.energy:
		return best_id
	var income := eco.income_per_second(cps, holding)
	var wait := INF if income <= 0.0 else (cost - eco.state.energy) / income
	return best_affordable_id if wait > BUY_WAIT_LIMIT else &""


func _record_appearances(eco: Economy, appear: Dictionary, t: float) -> void:
	for g in eco.visible_generators():
		if not appear.has(g.id):
			appear[g.id] = t
	for u in eco.visible_upgrades():
		if not appear.has(u.id):
			appear[u.id] = t


# --- Rangos (specs/hito1.md §3.5) ---

func _assert_ranges(label: String, r: Dictionary) -> void:
	var thr: float = r["threshold"]
	assert_true(thr > 0.0, "%s: llega al umbral antes de 60 min" % label)
	if thr <= 0.0:
		return
	var purchases: Array[float] = r["purchases"]
	var appear: Dictionary = r["appear"]
	assert_true(purchases.size() > 0 and purchases[0] <= 15.0, "%s: primera compra antes de 15 s" % label)
	assert_true(_max_novelty_gap(appear) <= 180.0, "%s: nada nuevo durante más de 3 min (%.0f s)" % [label, _max_novelty_gap(appear)])
	for i in range(1, GENERATOR_IDS.size()):
		var a: float = appear.get(GENERATOR_IDS[i - 1], INF)
		var b: float = appear.get(GENERATOR_IDS[i], INF)
		var gap := b - a
		assert_true(gap >= 240.0 and gap <= 420.0, "%s: %s aparece %.0f s después de %s" % [label, GENERATOR_IDS[i], gap, GENERATOR_IDS[i - 1]])
	var early := purchases.filter(func(x: float) -> bool: return x < 900.0).size() / 15.0
	assert_true(early >= 3.0 and early <= 8.0, "%s: %.1f compras/min en los minutos 0-15" % [label, early])
	var late_minutes := (thr - 900.0) / 60.0
	var late := purchases.filter(func(x: float) -> bool: return x >= 900.0).size() / maxf(late_minutes, 0.001)
	assert_true(late >= 1.5, "%s: %.1f compras/min desde el minuto 15" % [label, late])
	var minutes := thr / 60.0
	assert_true(minutes >= 30.0 and minutes <= 40.0, "%s: umbral en el minuto %.1f" % [label, minutes])


func _max_novelty_gap(appear: Dictionary) -> float:
	var limit: float = appear.get(&"channel_3", INF)
	var times: Array[float] = [0.0]
	for id in appear:
		if appear[id] <= limit:
			times.append(appear[id])
	times.sort()
	var gap := 0.0
	for i in range(1, times.size()):
		gap = maxf(gap, times[i] - times[i - 1])
	return gap


func _describe(label: String, r: Dictionary) -> String:
	var appear: Dictionary = r["appear"]
	var parts: PackedStringArray = []
	for gid in GENERATOR_IDS:
		parts.append("%s %.1f" % [gid, appear.get(gid, -60.0) / 60.0])
	for uid in CLICK_UPGRADE_IDS:
		parts.append("%s %.1f" % [uid, appear.get(uid, -60.0) / 60.0])
	var purchases: Array[float] = r["purchases"]
	return "PACING [%s] umbral %.1f min | compras %d | apariciones (min): %s" % [
		label, float(r["threshold"]) / 60.0, purchases.size(), ", ".join(parts)]
