extends GutTest

const PATH := "user://test_settings.cfg"


func after_each() -> void:
	DirAccess.remove_absolute(PATH)


func test_missing_file_gives_defaults() -> void:
	var s := UserSettings.load_from(PATH)
	assert_eq(s.quality, &"medium")
	assert_false(s.fullscreen)
	assert_almost_eq(s.volume, 0.25, 0.0001)
	assert_almost_eq(s.crt, 1.0, 0.0001)


func test_round_trip() -> void:
	var s := UserSettings.new()
	s.quality = &"ultra"
	s.fullscreen = true
	s.volume = 0.3
	s.crt = 0.0
	assert_true(s.save_to(PATH))
	var back := UserSettings.load_from(PATH)
	assert_eq(back.quality, &"ultra")
	assert_true(back.fullscreen)
	assert_almost_eq(back.volume, 0.3, 0.0001)
	assert_almost_eq(back.crt, 0.0, 0.0001)


func test_bad_values_are_corrected() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "version", 1)
	cfg.set_value("settings", "quality", "insane")
	cfg.set_value("settings", "volume", 7.0)
	cfg.set_value("settings", "crt", "mucho")
	cfg.save(PATH)
	var s := UserSettings.load_from(PATH)
	assert_eq(s.quality, &"medium")
	assert_almost_eq(s.volume, 1.0, 0.0001)
	assert_almost_eq(s.crt, 1.0, 0.0001)


func test_other_version_gives_defaults() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "version", 2)
	cfg.set_value("settings", "quality", "low")
	cfg.save(PATH)
	assert_eq(UserSettings.load_from(PATH).quality, &"medium")


func test_next_quality_wraps() -> void:
	var s := UserSettings.new()
	s.quality = &"ultra"
	s.next_quality()
	assert_eq(s.quality, &"low")
	s.next_quality(-1)
	assert_eq(s.quality, &"ultra")
