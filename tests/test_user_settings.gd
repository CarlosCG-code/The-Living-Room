extends GutTest

const PATH := "user://test_settings.cfg"


func after_each() -> void:
	DirAccess.remove_absolute(PATH)


func test_missing_file_gives_defaults() -> void:
	var s := UserSettings.load_from(PATH)
	assert_eq(s.quality, &"medium")
	assert_eq(s.window_mode, &"window")
	assert_almost_eq(s.volume, 0.25, 0.0001)
	assert_almost_eq(s.crt, 1.0, 0.0001)


func test_round_trip() -> void:
	var s := UserSettings.new()
	s.quality = &"ultra"
	s.window_mode = &"borderless"
	s.volume = 0.3
	s.crt = 0.0
	assert_true(s.save_to(PATH))
	var back := UserSettings.load_from(PATH)
	assert_eq(back.quality, &"ultra")
	assert_eq(back.window_mode, &"borderless")
	assert_almost_eq(back.volume, 0.3, 0.0001)
	assert_almost_eq(back.crt, 0.0, 0.0001)


func test_round_trip_new_keys() -> void:
	var s := UserSettings.new()
	s.resolution = Vector2i(1600, 900)
	s.vsync = false
	s.max_fps = 60
	s.brightness = 1.2
	s.film_grain = false
	s.volume_tv = 0.4
	s.volume_room = 0.6
	s.effects_intensity = 0.3
	assert_true(s.save_to(PATH))
	var back := UserSettings.load_from(PATH)
	assert_eq(back.resolution, Vector2i(1600, 900))
	assert_false(back.vsync)
	assert_eq(back.max_fps, 60)
	assert_almost_eq(back.brightness, 1.2, 0.0001)
	assert_false(back.film_grain)
	assert_almost_eq(back.volume_tv, 0.4, 0.0001)
	assert_almost_eq(back.volume_room, 0.6, 0.0001)
	assert_almost_eq(back.effects_intensity, 0.3, 0.0001)


func test_old_file_without_new_keys_keeps_defaults() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "version", 1)
	cfg.set_value("settings", "quality", "high")
	cfg.save(PATH)
	var s := UserSettings.load_from(PATH)
	assert_eq(s.quality, &"high")
	assert_eq(s.resolution, Vector2i.ZERO)
	assert_true(s.vsync)
	assert_eq(s.max_fps, 0)
	assert_almost_eq(s.brightness, 1.0, 0.0001)
	assert_true(s.film_grain)


func test_window_mode_of_an_old_file() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "version", 1)
	cfg.set_value("settings", "fullscreen", true)
	cfg.save(PATH)
	assert_eq(UserSettings.load_from(PATH).window_mode, &"fullscreen")
	cfg.set_value("settings", "window_mode", "otro")
	cfg.save(PATH)
	assert_eq(UserSettings.load_from(PATH).window_mode, &"window")


func test_mouse_sensitivity_round_trip_and_clamp() -> void:
	var s := UserSettings.new()
	assert_eq(s.sensitivity_level(), 4, "0,0012 por defecto: el paso 4 de 10")
	s.mouse_sensitivity = 0.002
	s.save_to(PATH)
	assert_almost_eq(UserSettings.load_from(PATH).mouse_sensitivity, 0.002, 0.000001)
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "version", 1)
	cfg.set_value("settings", "mouse_sensitivity", 5.0)
	cfg.save(PATH)
	assert_eq(UserSettings.load_from(PATH).sensitivity_level(), 10, "fuera de rango: al tope")


func test_bad_new_values_are_corrected() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "version", 1)
	cfg.set_value("settings", "resolution", Vector2i(10, 10))
	cfg.set_value("settings", "max_fps", 59)
	cfg.set_value("settings", "brightness", 9.0)
	cfg.set_value("settings", "render_scale", 0.3)  # clave de un archivo antiguo: se ignora
	cfg.save(PATH)
	var s := UserSettings.load_from(PATH)
	assert_eq(s.resolution, Vector2i.ZERO)
	assert_eq(s.max_fps, 0)
	assert_almost_eq(s.brightness, 1.5, 0.0001)


func test_resolution_options_fit_the_screen() -> void:
	var opts := UserSettings.resolution_options(Vector2i(1920, 1080))
	assert_eq(opts[0], Vector2i.ZERO, "primero, auto")
	assert_true(Vector2i(1920, 1080) in opts, "la de la pantalla también se puede elegir")
	assert_true(Vector2i(2560, 1080) in UserSettings.resolution_options(Vector2i(2560, 1080)), "aunque no sea común")
	assert_false(Vector2i(2560, 1440) in opts, "ninguna mayor que la pantalla")
	assert_true(Vector2i(1280, 720) in opts)
	assert_eq(UserSettings.cycle(opts, Vector2i(777, 777), 1), Vector2i.ZERO, "si no está, vuelve al principio")


func test_bad_values_are_corrected() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", "version", 1)
	cfg.set_value("settings", "quality", "insane")
	cfg.set_value("settings", "volume", 7.0)
	cfg.set_value("settings", "crt", "mucho")
	cfg.set_value("settings", "effects_intensity", 7)
	cfg.save(PATH)
	var s := UserSettings.load_from(PATH)
	assert_eq(s.quality, &"medium")
	assert_almost_eq(s.volume, 1.0, 0.0001)
	assert_almost_eq(s.crt, 1.0, 0.0001)
	assert_almost_eq(s.effects_intensity, 1.0, 0.0001)


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
