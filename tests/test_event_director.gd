extends GutTest

# Director de eventos (specs/hito3.md D3), con semilla fija y sin escena.

const EVENTS: FearEventSet = preload("res://data/fear_events.tres")
const LAYOUT: FlatLayout = preload("res://data/flat_layout.tres")
const DT := 0.1
const MANDATORY: Array[StringName] = [&"wall_ticks", &"cry", &"voices", &"remote", &"knocks", &"pills", &"glasses", &"denture"]

var director: EventDirector
var state: DirectorState
var log: Array[Dictionary] = []  # {t, id, place}
var now := 0.0


func before_each() -> void:
	_make(EVENTS, 1)


func _make(events: FearEventSet, seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	director = EventDirector.new(events, rng)
	state = DirectorState.new()
	log = []
	now = 0.0
	director.event_started.connect(func(def: FearEventDef, place: StringName) -> void:
		log.append({"t": now, "id": def.id, "place": place, "duration": def.duration}))


func _run(seconds: float, each := Callable()) -> void:
	for i in roundi(seconds / DT):
		now += DT
		if each.is_valid():
			each.call()
		director.tick(DT, state)


func _ids() -> Array:
	return log.map(func(e: Dictionary) -> StringName: return e["id"])


func _def(id: StringName, cooldown := 0.0) -> FearEventDef:
	var def := FearEventDef.new()
	def.id = id
	def.duration = 3.0
	def.cooldown = cooldown
	def.places = [&"kitchen", &"bathroom"]
	return def


func _set_of(defs: Array) -> FearEventSet:
	var events := FearEventSet.new()
	events.events.assign(defs)
	return events


func test_starts_in_silence_and_never_two_at_once() -> void:
	state.progress = 1.0
	_run(3600.0)
	assert_gt(log.size(), 20)
	assert_between(log[0]["t"], 4.0, 240.5)
	for i in range(1, log.size()):
		assert_gte(log[i]["t"] - log[i - 1]["t"], log[i - 1]["duration"] + 0.33)


func test_bursts_grow_with_progress_and_silences_do_not_shrink() -> void:
	for p: float in [0.0, 0.5, 0.9, 1.0]:
		_make(_set_of([_def(&"a"), _def(&"b"), _def(&"c"), _def(&"d")]), 7)
		state.progress = p
		_run(7200.0)
		var sizes := [1]
		var silences := []
		for i in range(1, log.size()):
			var pause: float = log[i]["t"] - log[i - 1]["t"] - 3.0
			if pause < 30.0:
				assert_between(pause, 7.9, 25.1)
				sizes[-1] += 1
			else:
				silences.append(pause)
				sizes.append(1)
		sizes.pop_back()  # la última tanda puede quedar a medias
		assert_between(silences.min(), 89.9, 240.1)
		assert_between(silences.max(), 89.9, 240.1)
		var expected: Array = {0.0: [1, 1], 0.5: [1, 2], 0.9: [1, 3], 1.0: [2, 4]}[p]
		assert_eq([sizes.min(), sizes.max()], expected, "tandas con p = %s" % p)


func test_any_number_of_possible_events_keeps_going() -> void:
	for n in 4:
		_make(_set_of([_def(&"a"), _def(&"b"), _def(&"c")].slice(0, n)), 3)
		state.progress = 0.9
		_run(3600.0)
		assert_eq(log.is_empty(), n == 0, "%d posibles" % n)
		if n == 3:  # con 3, uno de los dos últimos no se repite
			for i in range(1, log.size()):
				assert_ne(log[i]["id"], log[i - 1]["id"])


func test_places_do_not_repeat() -> void:
	_make(_set_of([_def(&"a")]), 3)
	_run(3600.0)
	for i in range(1, log.size()):
		assert_ne(log[i]["place"], log[i - 1]["place"])


func test_min_progress_requires_cooldown_and_units() -> void:
	var late := _def(&"late")
	late.min_progress = 0.5
	var machine := _def(&"machine", 1000.0)
	machine.requires = &"remote"
	_make(_set_of([late, machine]), 5)
	_run(2000.0)
	assert_true(log.is_empty())
	state.owned = {&"remote": 25}  # la mitad de enfriamiento
	_run(3000.0)
	assert_gt(log.size(), 2)
	for i in range(1, log.size()):
		assert_between(log[i]["t"] - log[i - 1]["t"], 500.0, 800.0)


func test_budget_only_below_the_threshold() -> void:
	_make(_set_of([_def(&"a"), _def(&"b"), _def(&"c")]), 5)
	state.progress = 0.9
	_run(20000.0)
	assert_eq(log.size(), 30)
	state.progress = 1.0
	_run(3000.0)
	assert_gt(log.size(), 35)


func test_lamps_only_if_seen() -> void:
	_make(_set_of([EVENTS.find(&"lamp_flicker")]), 5)
	_run(2000.0)
	assert_true(log.is_empty())
	state.lamps = func() -> Array[StringName]: return [&"SconceL"] as Array[StringName]
	_run(1000.0)
	assert_eq(log[0]["place"], &"SconceL")


func test_sound_never_in_the_player_zone() -> void:
	state.progress = 1.0
	state.player_zone = &"bathroom"
	state.place_zone = func(place: StringName) -> StringName: return &"" if place == &"ceiling" else place
	_run(7200.0)
	for e in log:
		assert_ne(e["place"], &"bathroom")
	assert_false(&"denture" in _ids(), "solo suena en el baño")
	assert_true(&"steps_above" in _ids())


func test_mandatory_on_purchase_once_and_spaced() -> void:
	_run(1.0)
	state.owned = {&"valves": 1, &"tuner": 1}
	var bought := now
	_run(60.0)
	assert_eq(_ids(), [&"wall_ticks", &"voices"])
	assert_between(log[0]["t"] - bought, 4.0, 10.2)
	assert_between(log[1]["t"] - log[0]["t"], 20.0, 20.3)
	_run(30.0)
	assert_eq(log.size(), 2)


func test_mandatory_leaves_silence_behind() -> void:
	for n in 20:
		_make(EVENTS, n)
		_run(85.0)
		state.owned = {&"valves": 1}
		_run(200.0)
		var i := _ids().find(&"wall_ticks")
		if i + 1 < log.size():
			assert_gte(log[i + 1]["t"] - log[i]["t"], log[i]["duration"] + 40.0)


func test_mandatory_waits_for_the_screen() -> void:
	state.owned = {&"valves": 1}
	state.ui_idle = false
	_run(60.0)
	assert_true(log.is_empty())
	state.ui_idle = true
	_run(0.2)
	assert_eq(_ids(), [&"wall_ticks"])


func test_knocks_come_without_the_purchase() -> void:
	director.reset(state)
	state.progress = 0.84
	_run(120.0)
	assert_false(&"knocks" in _ids())
	state.progress = 0.85
	_run(120.0)
	assert_true(&"knocks" in _ids())


func test_frame_only_during_interference() -> void:
	_make(_set_of([EVENTS.find(&"tv_frame")]), 2)
	state.progress = 0.8
	_run(60.0)
	assert_true(log.is_empty())
	state.tv_event = &"interference"
	_run(0.5)
	state.tv_event = &""  # se atrapó antes: se espera a la siguiente
	_run(10.0)
	assert_true(log.is_empty())
	state.tv_event = &"interference"
	var start := now
	_run(8.0)
	assert_eq(log.size(), 1)
	assert_between(log[0]["t"] - start, 1.0, 1.7)
	state.tv_event = &""
	_run(60.0)
	state.tv_event = &"interference"
	_run(8.0)
	assert_eq(log.size(), 1, "una sola vez")


func test_reset_forgets_everything_and_takes_the_past_as_done() -> void:
	state.owned = {&"valves": 1}
	state.progress = 0.6
	director.reset(state)
	_run(80.0)
	assert_true(log.is_empty(), "empieza en silencio y lo ya comprado no se repite")
	director.force(&"fall")
	_run(0.2)
	assert_true(director.busy())
	director.reset(DirectorState.new())
	assert_false(director.busy())


func test_force() -> void:
	director.force(&"denture")
	_run(0.2)
	assert_eq(_ids(), [&"denture"])


# Jugador activo medido con el simulador de ritmo: minuto -> progreso (D1).
func _active(minute: float) -> float:
	var points: Array[Vector2] = [Vector2(2, 0), Vector2(10, 0.3), Vector2(20, 0.6), Vector2(24, 0.79), Vector2(28, 0.92), Vector2(30, 1)]
	for i in range(1, points.size()):
		if minute <= points[i].x:
			return clampf(remap(minute, points[i - 1].x, points[i].x, points[i - 1].y, points[i].y), 0.0, 1.0)
	return 1.0


func test_thirty_minutes_of_run_one() -> void:
	var buys := {&"antenna": 0.2, &"valves": 2.0, &"audio_frequency": 5.0, &"tuner": 9.0, &"remote": 14.0, &"channel_3": 20.0}
	for n in 20:
		_make(EVENTS, n)
		state.lamps = func() -> Array[StringName]: return [&"SconceL", &"SconceR"] as Array[StringName]
		state.place_zone = func(place: StringName) -> StringName: return &"" if place in [&"ceiling", &"wall"] else place
		_run(1800.0, func() -> void:
			state.progress = _active(now / 60.0)
			state.tv_event = &"interference" if fmod(now, 180.0) < 8.0 else &""
			for id: StringName in buys:
				if now / 60.0 >= buys[id] and not state.owned.has(id):
					state.owned[id] = 1)
		assert_between(log.size(), 16, 31, "semilla %d" % n)
		for id in MANDATORY + ([&"tv_frame"] as Array[StringName]):
			assert_true(id in _ids(), "%s con la semilla %d" % [id, n])
		for i in range(1, log.size()):
			assert_lt(log[i]["t"] - log[i - 1]["t"], 285.0, "silencio con la semilla %d" % n)


# --- Datos ---

# Byte de canales de la cabecera de identificación Vorbis: tipo 1, «vorbis», versión (4 bytes), canales.
func _channels(path: String) -> int:
	var head := FileAccess.get_file_as_bytes(path).slice(0, 200)
	for i in head.size() - 12:
		if head[i] == 1 and head.slice(i + 1, i + 7).get_string_from_ascii() == "vorbis":
			return head[i + 11]
	return -1



func test_data() -> void:
	var config: EconomyConfig = load(Game.CONFIG_PATH)
	var ids := {}
	for def in EVENTS.events:
		assert_false(ids.has(def.id), "id repetido: %s" % def.id)
		ids[def.id] = true
		if def.requires != &"":
			assert_not_null(config.find_generator(def.requires), "%s: máquina" % def.id)
		for place in def.places:
			var leaf := LAYOUT.connections.any(func(c: ConnectionDef) -> bool: return c.id == place and c.kind == &"leaf")
			assert_true(place in [&"ceiling", &"wall"] or leaf or LAYOUT.find_zone(place) != null, "%s: %s" % [def.id, place])
		if def.kind == FearEventDef.Kind.SOUND:
			assert_ne(tr(def.subtitle_key), def.subtitle_key, "%s: subtítulo" % def.id)
			assert_false(def.places.is_empty(), String(def.id))
			assert_false(def.sounds.is_empty(), "%s: sin sonidos" % def.id)
			var longest := 0.0
			for sound in def.sounds:
				longest = maxf(longest, sound.get_length())
				assert_eq(_channels(sound.resource_path), 1, "%s: en 3D, mono" % sound.resource_path)
			assert_almost_eq(def.duration, longest + HouseAudio.PRELUDE, 0.06, "%s: duración" % def.id)
		elif def.kind == FearEventDef.Kind.LAMP:
			assert_gte(def.duration, 2.4)
