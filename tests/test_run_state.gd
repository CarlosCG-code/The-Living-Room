extends GutTest

var config: EconomyConfig


func before_each() -> void:
	config = EconomyConfig.new()
	var g := GeneratorDef.new()
	g.id = &"antenna"
	config.generators = [g]
	var u := UpgradeDef.new()
	u.id = &"pulse"
	config.upgrades = [u]
	var e := TvEventDef.new()
	e.id = &"interference"
	config.events = [e]
	var p := PerkDef.new()
	p.id = &"hands"
	config.perks = [p]


func _valid_dict() -> Dictionary:
	return {
		"version": 4,
		"run_index": 2,
		"energy": 12.5,
		"energy_produced_run": 40.0,
		"generators": {"antenna": 3},
		"upgrades": ["pulse"],
		"event": {"next_in": 150.0, "id": "", "left": 0.0},
		"play_time": 33.0,
		"carga": 0,
		"perks": [],
		"manual_clicks": 0,
		"packages_opened": 0,
		"events_caught": 0,
		"package_bar": 0.0,
		"timers": {},
	}


func test_round_trip() -> void:
	var s := RunState.new()
	s.run_index = 3
	s.energy = 1.5
	s.energy_produced_run = 9.0
	s.generators[&"antenna"] = 4
	s.upgrades.append(&"pulse")
	s.event_next_in = 100.0
	s.event_id = &"interference"
	s.event_left = 2.0
	s.play_time = 77.0
	var w: PackedStringArray = []
	var back := RunState.from_dict(s.to_dict(), config, w)
	assert_not_null(back)
	assert_eq(back.to_dict(), s.to_dict())
	assert_eq(w.size(), 0)


func test_accepts_json_types() -> void:
	# Tras pasar por JSON, los números llegan como float y los id como String.
	var d := _valid_dict()
	d["version"] = 4.0
	d["run_index"] = 2.0
	d["generators"] = {"antenna": 3.0}
	var w: PackedStringArray = []
	var s := RunState.from_dict(d, config, w)
	assert_not_null(s)
	assert_eq(s.run_index, 2)
	assert_eq(s.generators[&"antenna"], 3)


func test_unknown_id_ignored_with_warning() -> void:
	var d := _valid_dict()
	d["generators"] = {"antenna": 1, "ghost": 5}
	d["upgrades"] = ["pulse", "old_upgrade"]
	var w: PackedStringArray = []
	var s := RunState.from_dict(d, config, w)
	assert_not_null(s)
	assert_false(s.generators.has(&"ghost"))
	assert_eq(s.upgrades.size(), 1)
	assert_eq(w.size(), 2)


func test_missing_key_is_unreadable() -> void:
	var d := _valid_dict()
	d.erase("energy")
	assert_null(RunState.from_dict(d, config, PackedStringArray()))


func test_wrong_type_is_unreadable() -> void:
	var d := _valid_dict()
	d["energy"] = "abc"
	assert_null(RunState.from_dict(d, config, PackedStringArray()))


func test_wrong_element_type_is_unreadable() -> void:
	var d := _valid_dict()
	d["upgrades"] = [3]
	assert_null(RunState.from_dict(d, config, PackedStringArray()))
	d = _valid_dict()
	d["generators"] = {"antenna": "tres"}
	assert_null(RunState.from_dict(d, config, PackedStringArray()))


func test_missing_or_newer_version_is_unreadable() -> void:
	var d := _valid_dict()
	d.erase("version")
	assert_null(RunState.from_dict(d, config, PackedStringArray()))
	d = _valid_dict()
	d["version"] = 6
	assert_null(RunState.from_dict(d, config, PackedStringArray()))


func test_negatives_clamped_to_zero() -> void:
	var d := _valid_dict()
	d["energy"] = -5.0
	d["generators"] = {"antenna": -2}
	var s := RunState.from_dict(d, config, PackedStringArray())
	assert_eq(s.energy, 0.0)
	assert_eq(s.generators[&"antenna"], 0)


func test_migrates_v1_active_interference() -> void:
	var d := _valid_dict()
	d.erase("event")
	d.erase("carga")
	d.erase("perks")
	d["version"] = 1
	d["interference"] = {"next_in": 0.0, "active_left": 3.0}
	var s := RunState.from_dict(d, config, PackedStringArray())
	assert_not_null(s)
	assert_eq(s.event_id, &"interference")
	assert_almost_eq(s.event_left, 3.0, 0.0001)
	assert_eq(int(s.to_dict()["version"]), 5)


func test_migrates_v1_idle_interference() -> void:
	var d := _valid_dict()
	d.erase("event")
	d.erase("carga")
	d.erase("perks")
	d["version"] = 1.0
	d["interference"] = {"next_in": 150.0, "active_left": 0.0}
	var s := RunState.from_dict(d, config, PackedStringArray())
	assert_not_null(s)
	assert_eq(s.event_id, &"")
	assert_almost_eq(s.event_next_in, 150.0, 0.0001)


func test_unknown_event_dropped_with_warning() -> void:
	var d := _valid_dict()
	d["event"] = {"next_in": 10.0, "id": "ghost", "left": 2.0}
	var w: PackedStringArray = []
	var s := RunState.from_dict(d, config, w)
	assert_not_null(s)
	assert_eq(s.event_id, &"")
	assert_eq(w.size(), 1)


func test_migrates_v2_gives_carga_for_past_restarts() -> void:
	var d := _valid_dict()
	for key in ["carga", "perks", "manual_clicks", "packages_opened", "events_caught", "package_bar", "timers"]:
		d.erase(key)
	d["version"] = 2
	d["run_index"] = 3
	var s := RunState.from_dict(d, config, PackedStringArray())
	assert_not_null(s)
	assert_eq(s.carga, 6, "dos reinicios hechos: 3 + 3")
	assert_eq(s.perks.size(), 0)


func test_round_trip_keeps_carga_and_perks() -> void:
	var s := RunState.new()
	s.carga = 4
	s.perks.append(&"hands")
	var back := RunState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())), config, PackedStringArray())
	assert_eq(back.carga, 4)
	assert_eq(back.perks, [&"hands"] as Array[StringName])


func test_migrates_v3_refunds_old_perks() -> void:
	var d := _valid_dict()
	for key in ["manual_clicks", "packages_opened", "events_caught", "package_bar", "timers"]:
		d.erase(key)
	d["version"] = 3
	d["carga"] = 1
	d["perks"] = ["hands", "memory"]  # costaban 1 y 2 en la rama fija de la v3
	var s := RunState.from_dict(d, config, PackedStringArray())
	assert_not_null(s)
	assert_eq(s.carga, 4, "1 sin gastar + 3 devueltos")
	assert_eq(s.perks.size(), 0, "las permanentes cambian: se vuelven a elegir")
	assert_eq(s.manual_clicks, 0)


func test_timers_round_trip() -> void:
	var s := RunState.new()
	s.timers["cd_sweep"] = 42.0
	s.package_bar = 12.5
	var back := RunState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())), config, PackedStringArray())
	assert_almost_eq(float(back.timers["cd_sweep"]), 42.0, 0.0001)
	assert_almost_eq(back.package_bar, 12.5, 0.0001)


func test_migrates_v3_removes_what_refunded_perks_gave() -> void:
	var d := _valid_dict()
	for key in ["manual_clicks", "packages_opened", "events_caught", "package_bar", "timers"]:
		d.erase(key)
	d["version"] = 3
	d["perks"] = ["memory"]
	d["generators"] = {"antenna": 12}
	var s := RunState.from_dict(d, config, PackedStringArray())
	assert_eq(s.generators[&"antenna"], 2, "se quitan las 10 que daba Tu memoria")


func test_v5_round_trip() -> void:
	var s := RunState.new()
	s.run_index = 2
	s.sequence = Sequence.NEIGHBOR
	s.step = &"free"
	s.evidence.append(&"uniform")
	s.standing = true
	s.player_pos = Vector3(1.5, 0.0, -2.0)
	s.player_yaw = 0.7
	s.player_pitch = -0.2
	var w := PackedStringArray()
	var back := RunState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())), config, w)
	assert_eq(back.sequence, Sequence.NEIGHBOR)
	assert_eq(back.step, &"free")
	assert_eq(back.evidence, [&"uniform"] as Array[StringName])
	assert_true(back.standing)
	assert_almost_eq(back.player_pos, Vector3(1.5, 0.0, -2.0), Vector3.ONE * 0.0001)
	assert_almost_eq(back.player_yaw, 0.7, 0.0001)
	assert_eq(w.size(), 0)


func test_migrates_v4() -> void:
	var s := RunState.from_dict(_valid_dict(), config, PackedStringArray())
	assert_not_null(s)
	assert_eq(s.sequence, &"")
	assert_eq(s.evidence.size(), 0)
	assert_false(s.standing, "un v4 empieza sentado")
	assert_eq(int(s.to_dict()["version"]), 5)


func _v5() -> Dictionary:
	return RunState.migrate_v4(_valid_dict())


func test_unknown_sequence_or_step_is_dropped() -> void:
	for pair in [["ghost", "knock"], ["neighbor", "fixed"], ["blackout", "free"], ["", "free"], ["neighbor", ""]]:
		var d := _v5()
		d["sequence"] = pair[0]
		d["step"] = pair[1]
		var w := PackedStringArray()
		var s := RunState.from_dict(d, config, w)
		assert_not_null(s)
		assert_eq(s.sequence, &"", str(pair))
		assert_eq(s.step, &"", str(pair))
		assert_eq(w.size(), 1, "avisa: %s" % str(pair))


func test_bad_sequence_types_are_unreadable() -> void:
	var d := _v5()
	d["sequence"] = 3
	assert_null(RunState.from_dict(d, config, PackedStringArray()))
	d = _v5()
	d["evidence"] = "uniform"
	assert_null(RunState.from_dict(d, config, PackedStringArray()))


func test_bad_player_starts_seated() -> void:
	for p in [null, "x", {"standing": true}, {"standing": true, "pos": [1, 2], "yaw": 0, "pitch": 0},
			{"standing": true, "pos": [1, "a", 3], "yaw": 0, "pitch": 0}, {"standing": 1, "pos": [0, 0, 0], "yaw": 0, "pitch": 0}]:
		var d := _v5()
		d["player"] = p
		var s := RunState.from_dict(d, config, PackedStringArray())
		assert_not_null(s, str(p))
		assert_false(s.standing, str(p))


func test_evidence_skips_junk_and_duplicates() -> void:
	var d := _v5()
	d["evidence"] = ["uniform", 4, "uniform", "keys"]
	var s := RunState.from_dict(d, config, PackedStringArray())
	assert_eq(s.evidence, [&"uniform", &"keys"] as Array[StringName])
