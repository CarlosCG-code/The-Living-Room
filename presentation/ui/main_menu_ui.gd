class_name MainMenuUI
extends Control

# Menú principal dentro de la tele (320 × 240): Jugar/Continuar, Ajustes y Salir. Con pause_menu = true es
# el menú de pausa que se abre con Esc durante la partida: Reanudar, Ajustes, Menú principal y Salir. Los ajustes cambian
# con clic o Intro (siguiente valor) y con izquierda/derecha; Esc vuelve. Siempre hay un botón con foco
# para jugar solo con teclado o mando. Solo pinta y avisa: el menú del mundo hace el cambio de escena.

signal play_requested
signal quit_requested
signal resume_requested
signal menu_requested

const CRT_LEVELS: Array[float] = [0.0, 0.5, 1.0]
const VOLUME_STEP := 0.1
const DIM := Color("5a6480")

var _main: VBoxContainer
var _options: VBoxContainer
var _title: Label
var _play: Button
var _rows := {}  # "quality" | "fullscreen" | "volume" | "crt" -> Button
var _glitch_left := 0.0
## Menú de pausa (se fija antes de añadirlo al árbol).
var pause_menu := false


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	# En pausa se ve la partida detrás, muy oscurecida.
	bg.color = Color(0.016, 0.02, 0.035, 0.88) if pause_menu else Color("040509")
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)
	if not pause_menu:
		add_child(TvFog.make(Color(0.35, 0.38, 0.5)))
	_title = Label.new()
	_title.text = tr("TITLE")
	_title.add_theme_font_size_override(&"font_size", 24)
	_title.add_theme_color_override(&"font_color", Color("c9d0e0"))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.position = Vector2(0, 48)
	_title.size = Vector2(320, 30)
	add_child(_title)

	_main = _column()
	if pause_menu:
		_title.text = tr("UI_PAUSED")
		_play = _button(_main, tr("UI_RESUME"), resume_requested.emit)
		_button(_main, tr("UI_SETTINGS"), show_options)
		_button(_main, tr("UI_MAIN_MENU"), menu_requested.emit)
	else:
		_play = _button(_main, tr("UI_CONTINUE") if Game.has_progress() else tr("UI_PLAY"), play_requested.emit)
		_button(_main, tr("UI_SETTINGS"), show_options)
	_button(_main, tr("UI_QUIT"), quit_requested.emit)

	_options = _column()
	_options.hide()
	for key: String in ["quality", "fullscreen", "volume", "crt"]:
		var b := _button(_options, "", _change.bind(key, 1))
		b.gui_input.connect(_on_option_input.bind(key))
		_rows[key] = b
	_button(_options, tr("UI_BACK"), show_main)
	_refresh()
	_play.grab_focus.call_deferred()


func _process(delta: float) -> void:
	# De vez en cuando el título se tuerce un instante, como una señal que se pierde.
	if _glitch_left > 0.0:
		_glitch_left -= delta
	elif randf() < delta / 6.0:
		_glitch_left = randf_range(0.05, 0.15)
	_title.position.x = randf_range(-3.0, 3.0) if _glitch_left > 0.0 else 0.0
	_title.modulate.a = 0.55 if _glitch_left > 0.0 else 1.0


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event.is_action_pressed("ui_cancel"):
		return
	if _options.visible:
		show_main()
	elif pause_menu:
		resume_requested.emit()
	else:
		return
	get_viewport().set_input_as_handled()


func show_options() -> void:
	_main.hide()
	_options.show()
	(_rows["quality"] as Button).grab_focus()


func show_main() -> void:
	_options.hide()
	_main.show()
	_play.grab_focus()


func get_option_button(key: String) -> Button:
	return _rows[key]


func _on_option_input(event: InputEvent, key: String) -> void:
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_left"):
		_change(key, 1 if event.is_action_pressed("ui_right") else -1)
		accept_event()


func _change(key: String, step: int) -> void:
	var s := Game.settings
	match key:
		"quality":
			s.next_quality(step)
		"fullscreen":
			s.fullscreen = not s.fullscreen
		"volume":
			# Con clic da la vuelta: de 100 % pasa a 0 %.
			var v := snappedf(s.volume + step * VOLUME_STEP, VOLUME_STEP)
			s.volume = 0.0 if v > 1.0 + 0.001 else clampf(v, 0.0, 1.0)
		"crt":
			var i := CRT_LEVELS.find(_nearest_crt(s.crt))
			s.crt = CRT_LEVELS[posmod(i + step, CRT_LEVELS.size())]
	Game.apply_settings()
	Game.save_settings()
	_refresh()


func _refresh() -> void:
	var s := Game.settings
	(_rows["quality"] as Button).text = tr("UI_QUALITY") % tr("QUALITY_" + String(s.quality).to_upper())
	(_rows["fullscreen"] as Button).text = tr("UI_FULLSCREEN") % tr("UI_SCREEN_FULL" if s.fullscreen else "UI_SCREEN_WINDOW")
	(_rows["volume"] as Button).text = tr("UI_VOLUME") % roundi(s.volume * 100.0)
	var crt_name: String = ["UI_CRT_OFF", "UI_CRT_SOFT", "UI_CRT_FULL"][CRT_LEVELS.find(_nearest_crt(s.crt))]
	(_rows["crt"] as Button).text = tr("UI_CRT") % tr(crt_name)


func _nearest_crt(v: float) -> float:
	var best := CRT_LEVELS[0]
	for level in CRT_LEVELS:
		if absf(level - v) < absf(best - v):
			best = level
	return best


func _column() -> VBoxContainer:
	var c := VBoxContainer.new()
	c.add_theme_constant_override(&"separation", 4)
	c.position = Vector2(0, 104)
	c.size = Vector2(320, 0)
	add_child(c)
	return c


func _button(parent: Container, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = FOCUS_ALL
	# Texto sin caja: el filtro de la tele llenaba de colores los marcos finos. El foco se ve en dorado.
	b.flat = true
	b.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	b.add_theme_font_size_override(&"font_size", 16)
	b.add_theme_color_override(&"font_color", DIM)
	b.size_flags_horizontal = SIZE_SHRINK_CENTER
	b.pressed.connect(action)
	# El ratón también mueve el foco: nunca hay dos botones marcados a la vez.
	b.mouse_entered.connect(b.grab_focus)
	parent.add_child(b)
	return b
