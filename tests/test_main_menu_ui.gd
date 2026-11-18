extends GutTest

var menu: MainMenuUI
var _saved: UserSettings


func before_each() -> void:
	_saved = Game.settings
	Game.settings = UserSettings.new()  # TLR_NO_SAVE: no se escribe nada en disco
	var vp := SubViewport.new()
	vp.size = Vector2i(320, 240)
	add_child_autofree(vp)
	menu = (load("res://presentation/ui/main_menu_ui.tscn") as PackedScene).instantiate()
	vp.add_child(menu)
	await wait_process_frames(2)


func after_each() -> void:
	Game.settings = _saved


func _focus() -> Control:
	return menu.get_viewport().gui_get_focus_owner()


func test_a_button_has_focus_on_open() -> void:
	assert_not_null(_focus(), "con teclado o mando siempre hay algo seleccionado")


func test_options_take_and_give_back_focus() -> void:
	menu.show_options()
	assert_eq(_focus(), menu.get_option_button("quality"))
	menu.show_main()
	assert_not_null(_focus())
	assert_true(_focus().is_visible_in_tree())


func test_pressing_an_option_changes_the_setting() -> void:
	menu.show_options()
	menu.get_option_button("quality").pressed.emit()
	assert_eq(Game.settings.quality, &"high")
	menu.get_option_button("crt").pressed.emit()
	assert_almost_eq(Game.settings.crt, 0.0, 0.0001, "fuerte → no")
	menu.get_option_button("crt").pressed.emit()
	assert_almost_eq(Game.settings.crt, 0.5, 0.0001, "no → suave")


func test_volume_wraps_to_zero() -> void:
	Game.settings.volume = 1.0
	menu.show_options()
	menu.get_option_button("volume").pressed.emit()
	assert_almost_eq(Game.settings.volume, 0.0, 0.0001)
