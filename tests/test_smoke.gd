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
