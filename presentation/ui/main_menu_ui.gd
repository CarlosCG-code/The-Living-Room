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
## Apartados de Ajustes (clave de su título → filas). En la tele de 320 × 240 no caben todas a la vez.
const PAGES := {
	"UI_PAGE_DISPLAY": ["fullscreen", "resolution", "vsync", "max_fps", "brightness"],
	"UI_PAGE_GRAPHICS": ["quality", "render_scale", "film_grain", "crt"],
	"UI_PAGE_AUDIO": ["volume", "volume_tv", "volume_room"],
}

const REPEATABLE: Array[String] = ["brightness", "volume", "volume_tv", "volume_room"]

var _main: VBoxContainer
var _options: VBoxContainer  # lista de apartados
var _pages := {}  # clave del apartado -> VBoxContainer
var _page := ""  # apartado abierto ("" = ninguno)
var _title: Label
var _play: Button
var _rows := {}  # clave del ajuste -> Button
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
	for page: String in PAGES:
		_button(_options, tr(page), show_page.bind(page))
		var column := _column(84, 0)
		column.hide()
		_pages[page] = column
		for key: String in PAGES[page]:
			var b := _button(column, "", _change.bind(key, 1, true), 14)
			b.gui_input.connect(_on_option_input.bind(key))
			_rows[key] = b
		_button(column, tr("UI_BACK"), show_options, 14)
	_button(_options, tr("UI_BACK"), show_main)
	# El menú principal y el de pausa son dos instancias vivas a la vez: las dos repintan con cualquier cambio.
	EventBus.settings_changed.connect(_refresh)
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
	if _page != "":
		show_options()
	elif _options.visible:
		show_main()
	elif pause_menu:
		resume_requested.emit()
	else:
		return
	get_viewport().set_input_as_handled()


## Lista de apartados. Al volver de uno, el foco queda en ese apartado.
func show_options() -> void:
	var back_from := _page
	_hide_all()
	_options.show()
	_title.text = tr("UI_SETTINGS")
	var i := PAGES.keys().find(back_from)
	(_options.get_child(maxi(i, 0)) as Button).grab_focus()


func show_page(page: String) -> void:
	_hide_all()
	_page = page
	(_pages[page] as Control).show()
	_title.text = tr(page)
	(_rows[PAGES[page][0]] as Button).grab_focus()


func show_main() -> void:
	_hide_all()
	_title.text = tr("UI_PAUSED") if pause_menu else tr("TITLE")
	if not pause_menu:
		_play.text = tr("UI_CONTINUE") if Game.has_progress() else tr("UI_PLAY")
	_main.show()
	_play.grab_focus()


func _hide_all() -> void:
	_page = ""
	_main.hide()
	_options.hide()
	for c: Control in _pages.values():
		c.hide()


func get_option_button(key: String) -> Button:
	return _rows[key]


func _on_option_input(event: InputEvent, key: String) -> void:
	# Con la tecla mantenida llegan repeticiones (echo): se aceptan siempre, para que la navegación de Godot no
	# mueva el foco, pero solo repiten los porcentajes; la ventana o el preset no se rehacen 20 veces por segundo.
	if event.is_action_pressed("ui_right", true) or event.is_action_pressed("ui_left", true):
		if not event.is_echo() or key in REPEATABLE:
			_change(key, 1 if event.is_action_pressed("ui_right", true) else -1)
		accept_event()


## wrap: con clic o Intro los porcentajes dan la vuelta (del máximo al mínimo); con flechas se quedan en el tope.
func _change(key: String, step: int, wrap := false) -> void:
	var s := Game.settings
	match key:
		"quality":
			s.next_quality(step)
		"fullscreen":
			s.fullscreen = not s.fullscreen
		"resolution":
			s.resolution = UserSettings.cycle(UserSettings.resolution_options(_screen_size()), s.resolution, step)
		"vsync":
			s.vsync = not s.vsync
		"max_fps":
			s.max_fps = UserSettings.cycle(UserSettings.FPS_LIMITS, s.max_fps, step)
		"brightness":
			s.brightness = _step(s.brightness, step, UserSettings.BRIGHTNESS_MIN, UserSettings.BRIGHTNESS_MAX, wrap)
		"render_scale":
			s.render_scale = UserSettings.cycle(UserSettings.RENDER_SCALES, s.render_scale, step)
		"film_grain":
			s.film_grain = not s.film_grain
		"volume", "volume_tv", "volume_room":
			s.set(key, _step(s.get(key), step, 0.0, 1.0, wrap))
		"crt":
			var i := CRT_LEVELS.find(_nearest_crt(s.crt))
			s.crt = CRT_LEVELS[posmod(i + step, CRT_LEVELS.size())]
	Game.apply_settings()
	Game.save_settings()
	_refresh()


# Un paso de 10 %.
static func _step(v: float, step: int, lo: float, hi: float, wrap: bool) -> float:
	var next := snappedf(v + step * VOLUME_STEP, VOLUME_STEP)
	return lo if wrap and next > hi + 0.001 else clampf(next, lo, hi)


func _screen_size() -> Vector2i:
	return DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())


func _refresh() -> void:
	var s := Game.settings
	var yes_no := func(on: bool) -> String: return tr("UI_ON") if on else tr("UI_OFF")
	var percent := func(v: float) -> int: return roundi(v * 100.0)
	(_rows["quality"] as Button).text = tr("UI_QUALITY") % tr("QUALITY_" + String(s.quality).to_upper())
	(_rows["fullscreen"] as Button).text = tr("UI_FULLSCREEN") % tr("UI_SCREEN_FULL" if s.fullscreen else "UI_SCREEN_WINDOW")
	var res := tr("UI_AUTO") if s.resolution == Vector2i.ZERO else "%dx%d" %[s.resolution.x, s.resolution.y]
	(_rows["resolution"] as Button).text = tr("UI_RESOLUTION") % res
	(_rows["vsync"] as Button).text = tr("UI_VSYNC") % yes_no.call(s.vsync)
	(_rows["max_fps"] as Button).text = tr("UI_MAX_FPS") % (tr("UI_UNLIMITED") if s.max_fps == 0 else str(s.max_fps))
	(_rows["brightness"] as Button).text = tr("UI_BRIGHTNESS") % percent.call(s.brightness)
	(_rows["render_scale"] as Button).text = tr("UI_RENDER_SCALE") % (tr("UI_AUTO") if s.render_scale == 0.0
			else "%d %%" % percent.call(s.render_scale))
	(_rows["film_grain"] as Button).text = tr("UI_FILM_GRAIN") % yes_no.call(s.film_grain)
	(_rows["volume"] as Button).text = tr("UI_VOLUME") % percent.call(s.volume)
	(_rows["volume_tv"] as Button).text = tr("UI_VOLUME_TV") % percent.call(s.volume_tv)
	(_rows["volume_room"] as Button).text = tr("UI_VOLUME_ROOM") % percent.call(s.volume_room)
	var crt_name: String = ["UI_CRT_OFF", "UI_CRT_SOFT", "UI_CRT_FULL"][CRT_LEVELS.find(_nearest_crt(s.crt))]
	(_rows["crt"] as Button).text = tr("UI_CRT") % tr(crt_name)


func _nearest_crt(v: float) -> float:
	var best := CRT_LEVELS[0]
	for level in CRT_LEVELS:
		if absf(level - v) < absf(best - v):
			best = level
	return best


func _column(y: float = 104, separation: int = 4) -> VBoxContainer:
	var c := VBoxContainer.new()
	c.add_theme_constant_override(&"separation", separation)
	c.position = Vector2(0, y)
	c.size = Vector2(320, 0)
	add_child(c)
	return c


func _button(parent: Container, text: String, action: Callable, font_size: int = 16) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = FOCUS_ALL
	# Texto sin caja: el filtro de la tele llenaba de colores los marcos finos. El foco se ve en dorado.
	b.flat = true
	b.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	b.add_theme_font_size_override(&"font_size", font_size)
	b.add_theme_color_override(&"font_color", DIM)
	b.size_flags_horizontal = SIZE_SHRINK_CENTER
	# Menús en columna: izquierda/derecha nunca mueven el foco (en las filas de ajustes cambian el valor).
	b.focus_neighbor_left = NodePath(".")
	b.focus_neighbor_right = NodePath(".")
	b.pressed.connect(action)
	# El ratón mueve el foco solo cuando se mueve de verdad: al cambiar un ajuste, el texto y la tele se
	# redibujan y Godot puede mandar un «ratón entra» falso que se llevaba el foco a otra fila.
	b.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseMotion and (event as InputEventMouseMotion).relative != Vector2.ZERO and not b.has_focus():
			b.grab_focus())
	parent.add_child(b)
	return b
