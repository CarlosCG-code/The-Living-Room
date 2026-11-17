extends GutTest

const DIR := "user://test_save"

var config: EconomyConfig
var saves: SaveSystem
var path := DIR.path_join("run.json")


func before_each() -> void:
	_clean()
	config = EconomyConfig.new()
	var g := GeneratorDef.new()
	g.id = &"antenna"
	config.generators = [g]
	saves = SaveSystem.new(DIR)


func after_each() -> void:
	_clean()


func _clean() -> void:
	if DirAccess.dir_exists_absolute(DIR):
		for f in DirAccess.get_files_at(DIR):
			DirAccess.remove_absolute(DIR.path_join(f))
		DirAccess.remove_absolute(DIR)


func _state(energy: float) -> RunState:
	var s := RunState.new()
	s.energy = energy
	s.energy_produced_run = energy
	s.generators[&"antenna"] = 2
	s.interference_next_in = 123.456789012345
	return s


func _write(file_path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var f := FileAccess.open(file_path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func test_first_time_returns_null_without_warnings() -> void:
	assert_null(saves.load_run(config))
	assert_eq(saves.warnings.size(), 0)


func test_save_and_load_through_json() -> void:
	var s := _state(1234.5678901234)
	assert_true(saves.save_run(s))
	var back := saves.load_run(config)
	assert_not_null(back)
	assert_eq(back.to_dict(), s.to_dict())


func test_save_rotates_previous_to_bak() -> void:
	saves.save_run(_state(1))
	saves.save_run(_state(2))
	var bak_text := FileAccess.get_file_as_string(path + ".bak")
	assert_string_contains(bak_text, "\"energy\":1.0")


func test_corrupt_main_loads_bak_and_keeps_it() -> void:
	saves.save_run(_state(1))
	saves.save_run(_state(2))  # run.json = 2, run.json.bak = 1
	_write(path, "{esto no es json")
	var loaded := saves.load_run(config)
	assert_not_null(loaded)
	assert_eq(loaded.energy, 1.0)
	assert_true(FileAccess.file_exists(path + ".corrupt"))
	assert_false(FileAccess.file_exists(path))
	saves.save_run(_state(3))
	var bak := SaveSystem.new(DIR)
	DirAccess.remove_absolute(path)  # forzamos a leer el .bak
	assert_eq(bak.load_run(config).energy, 1.0)


func test_both_corrupt_returns_null_and_quarantines() -> void:
	_write(path, "basura")
	_write(path + ".bak", "basura")
	assert_null(saves.load_run(config))
	assert_true(FileAccess.file_exists(path + ".corrupt"))
	assert_true(FileAccess.file_exists(path + ".bak.corrupt"))


func test_only_bak_loads_without_corrupt() -> void:
	saves.save_run(_state(7))
	DirAccess.rename_absolute(path, path + ".bak")
	var loaded := saves.load_run(config)
	assert_eq(loaded.energy, 7.0)
	assert_false(FileAccess.file_exists(path + ".corrupt"))


func test_only_bak_unreadable() -> void:
	_write(path + ".bak", "basura")
	assert_null(saves.load_run(config))
	assert_true(FileAccess.file_exists(path + ".bak.corrupt"))


func test_corrupt_main_without_bak_returns_null() -> void:
	_write(path, "basura")
	assert_null(saves.load_run(config))
	assert_true(FileAccess.file_exists(path + ".corrupt"))


func test_version_2_and_missing_version_unreadable() -> void:
	var d := _state(5).to_dict()
	d["version"] = 2
	_write(path, JSON.stringify(d))
	assert_null(saves.load_run(config))
	d.erase("version")
	_write(path, JSON.stringify(d))
	assert_null(saves.load_run(config))


func test_leftover_tmp_is_removed() -> void:
	_write(path + ".tmp", "a medias")
	saves.load_run(config)
	assert_false(FileAccess.file_exists(path + ".tmp"))
