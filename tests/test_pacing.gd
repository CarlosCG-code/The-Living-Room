extends GutTest

# Test de ritmo de la run 1 (specs/hito1.md §3.5, specs/incremental_v2.md §1 y §10). Simulación determinista:
# semilla 1, pasos de 0,25 s. El jugador abre las cintas en cuanto caen; el activo usa las habilidades.

const CONFIG_PATH := "res://data/economy_run1.tres"
const STEP := 0.25
const MAX_TIME := 3600.0
const BUY_WAIT_LIMIT := 30.0

const GENERATOR_IDS: Array[StringName] = [&"antenna", &"valves", &"audio_frequency", &"tuner", &"remote", &"channel_3"]
const SKILLS: Array[StringName] = [&"sweep", &"surge", &"seek"]  # Sobrecarga es una apuesta: el simulador no la usa
## Minutos al umbral por perfil (§10): premiar el clic separa al activo del tranquilo.
const RANGES := {"activo": Vector2(26, 32), "tranquilo": Vector2(35, 47)}
## Hueco máximo sin nada nuevo (s), contando mejoras, máquinas y fragmentos de lore: el tranquilo avanza más
## despacio y todo se le estira.
const NOVELTY_GAP := {"activo": 150.0, "tranquilo": 400.0}

var config: EconomyConfig


func before_all() -> void:
	config = load(CONFIG_PATH)


func test_config_valid() -> void:
	assert_true(config is EconomyConfig, "el .tres es un EconomyConfig")
	var gen_ids: Array[StringName] = []
	for g in config.generators:
		gen_ids.append(g.id)
		assert_ne(tr(g.name_key), g.name_key, "traducción de %s" % g.name_key)
	assert_eq(gen_ids, GENERATOR_IDS)
	assert_eq(config.upgrades.size(), 30)
	var cells := {}
	for i in GENERATOR_IDS.size():
		cells[Vector2i(i, 2)] = GENERATOR_IDS[i]
	for u in config.upgrades:
		assert_ne(tr(u.name_key), u.name_key, "traducción de %s" % u.name_key)
		assert_ne(tr(u.desc_key), u.desc_key, "traducción de %s" % u.desc_key)
		assert_true(u.requires_id == &"" or gen_ids.has(u.requires_id) or config.find_upgrade(u.requires_id) != null,
				"padre de %s" % u.id)
		assert_false(cells.has(u.tree_cell), "%s pisa la celda de %s" % [u.id, cells.get(u.tree_cell)])
		cells[u.tree_cell] = u.id
		assert_true(u.tree_cell.x >= 0 and u.tree_cell.x < 10 and u.tree_cell.y >= 0 and u.tree_cell.y < 5,
				"celda de %s" % u.id)
		assert_true(ResourceLoader.exists("res://assets/textures/tv/icon_%s.png" % u.icon), "icono de %s" % u.id)
		if u.kind == UpgradeDef.Kind.SKILL:
			assert_true(u.cooldown > 0.0, "enfriamiento de %s" % u.id)
	for p in config.perks:
		assert_ne(tr(p.name_key), p.name_key, "traducción de %s" % p.name_key)


func test_every_upgrade_has_modeled_gain() -> void:
	# Si una mejora no sube los ingresos en valor esperado, el simulador nunca la compra y su rama no se abre.
	for u in config.upgrades:
		if u.kind == UpgradeDef.Kind.SKILL and u.skill == &"overload":
			continue  # apuesta: su valor esperado puede ser bajo a propósito
		var eco := Economy.new(config, null, 1)
		for g in config.generators:
			eco.state.generators[g.id] = 30
		var parent := u.requires_id
		while config.find_upgrade(parent) != null:  # con la rama de la que cuelga ya comprada
			eco.state.upgrades.append(parent)
			parent = config.find_upgrade(parent).requires_id
		eco._recalc()
		var holding := u.kind == UpgradeDef.Kind.HOLD_RATE
		assert_gt(eco.gain_if_bought(u.id, 6.0, holding), 0.0, "%s sube los ingresos" % u.id)


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
	# El clic a mano tiene que notarse: el activo llega claramente antes que el tranquilo.
	var gap := float(sims["tranquilo, con interferencias"]["threshold"]) - float(sims["activo, con interferencias"]["threshold"])
	assert_gt(gap, 180.0, "el activo llega al menos 3 min antes (%.1f min)" % (gap / 60.0))


func test_every_perk_shortens_run_2() -> void:
	# Cada permanente tiene que notarse en la run siguiente, sin romperla (specs/incremental_v2.md §4).
	var base: float = _simulate(6.0, false, true)["threshold"]
	for p in config.perks:
		var t: float = _simulate(6.0, false, true, [p.id])["threshold"]
		gut.p("RUN2 [%s] %.1f min (sin permanentes: %.1f)" % [p.id, t / 60.0, base / 60.0])
		assert_lt(t, base * 0.95, "%s acorta la run al menos un 5 %%" % p.id)
	var all := config.perks.map(func(p: PerkDef) -> StringName: return p.id)
	var t_all: float = _simulate(6.0, false, true, all)["threshold"]
	assert_between(t_all / 60.0, 9.0, 18.0, "con todas, la run 4 dura cerca de 15 min (%.1f)" % (t_all / 60.0))


# --- Simulador ---

func _simulate(manual_cps: float, tranquil: bool, catch_interferences: bool, perks: Array = []) -> Dictionary:
	var eco := Economy.new(config, null, 1)
	if not perks.is_empty():
		eco.state.run_index = 2
		eco.state.carga = 99
		for p in perks:
			eco.buy_perk(p)
	var t := 0.0
	var acc := 0.0
	var purchases: Array[float] = []
	var bought_ids: Array = []
	var appear := {}
	_record_appearances(eco, appear, 0.0)
	var lore := LoreFeed.ratios(load("res://data/lore.tres").get_meta(&"fragments"), eco.state.run_index)
	var threshold_time := -1.0
	while t < MAX_TIME:
		# El perfil tranquilo pasa siempre holding = true: no tiene efecto hasta comprar Dial firme.
		var holding := tranquil
		var cps := 0.0 if tranquil and eco.is_bought(&"dial_hold") else manual_cps
		if catch_interferences and eco.active_event() != null:
			eco.catch_event()
		while not eco.packages().is_empty():
			eco.open_package(0)
		if not tranquil:
			for skill in SKILLS:
				eco.use_skill(skill)
		acc += cps * STEP
		while acc >= 1.0:
			eco.click()
			acc -= 1.0
		_record_appearances(eco, appear, t)  # antes de comprar: lo que aparece y se compra en el mismo paso cuenta
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
		for r in lore:  # los fragmentos de lore también son algo nuevo en la tele
			if eco.state.energy_produced_run >= r * config.threshold and not appear.has("lore_%s" % r):
				appear["lore_%s" % r] = t
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
		var item_cost := eco.cost_of(id)
		if gain <= 0.0:
			# Lo que no sube los ingresos de este perfil (Dial firme para quien no mantiene pulsado) también
			# se compra cuando es barato: un jugador real lo hace, y abre su rama del árbol.
			if item_cost > eco.income_per_second(cps, holding) * 20.0 or item_cost > eco.state.energy:
				continue
			gain = item_cost * 1e-6
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
	var profile := "activo" if label.begins_with("activo") else "tranquilo"
	var novelty := _max_novelty_gap(appear, thr)
	assert_true(novelty <= NOVELTY_GAP[profile], "%s: nada nuevo durante %.0f s" % [label, novelty])
	for i in range(1, GENERATOR_IDS.size()):
		var a: float = appear.get(GENERATOR_IDS[i - 1], INF)
		var b: float = appear.get(GENERATOR_IDS[i], INF)
		var gap := b - a
		assert_true(gap >= 180.0 and gap <= 480.0, "%s: %s aparece %.0f s después de %s" % [label, GENERATOR_IDS[i], gap, GENERATOR_IDS[i - 1]])
	var early := purchases.filter(func(x: float) -> bool: return x < 900.0).size() / 15.0
	assert_true(early >= 3.0 and early <= 8.0, "%s: %.1f compras/min en los minutos 0-15" % [label, early])
	var late_minutes := (thr - 900.0) / 60.0
	var late := purchases.filter(func(x: float) -> bool: return x >= 900.0).size() / maxf(late_minutes, 0.001)
	assert_true(late >= 1.5, "%s: %.1f compras/min desde el minuto 15" % [label, late])
	var minutes := thr / 60.0
	var range_v: Vector2 = RANGES["activo" if label.begins_with("activo") else "tranquilo"]
	assert_true(minutes >= range_v.x and minutes <= range_v.y, "%s: umbral en el minuto %.1f" % [label, minutes])


## Hueco más largo sin nada nuevo en la tienda, hasta el umbral.
func _max_novelty_gap(appear: Dictionary, limit: float) -> float:
	var times: Array[float] = [0.0, limit]
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
	for u in config.upgrades:
		parts.append("%s %.1f" % [u.id, appear.get(u.id, -60.0) / 60.0])
	var purchases: Array[float] = r["purchases"]
	return "PACING [%s] umbral %.1f min | compras %d | apariciones (min): %s" % [
		label, float(r["threshold"]) / 60.0, purchases.size(), ", ".join(parts)]
