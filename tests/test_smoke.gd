extends GutTest


func test_translation_es() -> void:
	var previous: String = TranslationServer.get_locale()
	TranslationServer.set_locale("es")
	assert_eq(tr("TITLE"), "The Living Room")
	TranslationServer.set_locale(previous)


func test_devboot_skips_without_addon() -> void:
	var boot: Node = (load("res://autoload/dev_boot.gd") as GDScript).new()
	var parent := Node.new()
	var result: Node = boot.load_runtime("res://no_existe.gd", parent)
	await wait_process_frames(1)
	assert_null(result)
	assert_eq(parent.get_child_count(), 0)
	boot.free()
	parent.free()


func test_layers_of_the_house_loop() -> void:
	for stream: AudioStreamOggVorbis in [HouseAudio.AMBIENCE, HouseAudio.HUM]:
		assert_true(stream.loop, stream.resource_path)


func test_autosave_waits_for_the_end_of_an_event() -> void:
	Game.running = true
	Game.economy.state = RunState.new_run(Game.economy.config, 1, RandomNumberGenerator.new())
	Game.economy._recalc()
	Game.tick(0.01)
	watch_signals(EventBus)
	Game.director.force(&"denture")
	Game._since_save = Game.AUTOSAVE_INTERVAL
	Game.tick(0.01)
	assert_signal_emitted(EventBus, "fear_event")
	Game.tick(0.01)
	assert_gt(Game._since_save, Game.AUTOSAVE_INTERVAL, "en mitad de un suceso no se guarda")
	for i in 20:
		Game.tick(1.0)
	assert_lt(Game._since_save, 20.0)
	Game.economy.state = RunState.new_run(Game.economy.config, 1, RandomNumberGenerator.new())
	Game.director.force(&"denture")
	Game.tick(0.01)
	assert_false(Game.director.busy(), "con otra run, el director empieza de cero")
	Game.running = false
