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


func _valid_dict() -> Dictionary:
	return {
		"version": 1,
		"run_index": 2,
		"energy": 12.5,
		"energy_produced_run": 40.0,
		"generators": {"antenna": 3},
		"upgrades": ["pulse"],
		"interference": {"next_in": 150.0, "active_left": 0.0},
		"play_time": 33.0,
	}


func test_round_trip() -> void:
	var s := RunState.new()
	s.run_index = 3
	s.energy = 1.5
	s.energy_produced_run = 9.0
	s.generators[&"antenna"] = 4
	s.upgrades.append(&"pulse")
	s.interference_next_in = 100.0
	s.interference_active_left = 2.0
	s.play_time = 77.0
	var w: PackedStringArray = []
	var back := RunState.from_dict(s.to_dict(), config, w)
	assert_not_null(back)
	assert_eq(back.to_dict(), s.to_dict())
	assert_eq(w.size(), 0)


func test_accepts_json_types() -> void:
	# Tras pasar por JSON, los números llegan como float y los id como String.
	var d := _valid_dict()
	d["version"] = 1.0
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
	d["version"] = 2
	assert_null(RunState.from_dict(d, config, PackedStringArray()))


func test_negatives_clamped_to_zero() -> void:
	var d := _valid_dict()
	d["energy"] = -5.0
	d["generators"] = {"antenna": -2}
	var s := RunState.from_dict(d, config, PackedStringArray())
	assert_eq(s.energy, 0.0)
	assert_eq(s.generators[&"antenna"], 0)
