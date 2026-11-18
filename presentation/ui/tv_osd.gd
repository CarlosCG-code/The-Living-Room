class_name TvOsd
extends Control

# Texto en pantalla de la tele (OSD), como el de una tele o un vídeo de los 90: fósforo verde pálido con
# sombra dura y pegado a las esquinas (sin mayúsculas: la fuente no tiene las acentuadas). Arriba la Energía y el ritmo; abajo la barra de
# reinicio, los avisos («+ ANTENA») y la tecla de las mejoras. Solo pinta: tv_game_ui le pasa los datos.

signal restart_pressed
signal skill_pressed(skill: StringName)

const PHOSPHOR := Color("b8f5c4")
const PHOSPHOR_DIM := Color("5f8f6c")
const AMBER := Color("ffc861")
const SHADOW := Color(0, 0, 0, 0.85)
const NOTICE_TIME := 3.0
const BAR_SEGMENTS := 20
## Habilidades del mando en orden de tecla (1-4) e icono de cada una.
const SKILLS: Array[StringName] = [&"sweep", &"surge", &"seek", &"overload"]
const SKILL_ROW := Vector2(246, 196)

var _energy: Label
var _energy_caption: Label
var _rates: Label
var _restart_caption: Label
var _prompt: Label
var _notice: Label
var _restart: Button
var _progress := 0.0
var _notice_tween: Tween
var _intro: Label
var _tape := -1.0  # fracción de la barra de cintas (-1: aún no hay cintas)
var _combo := 0.0
var _skills := {}  # skill -> {"button": TextureButton, "cd": fracción de espera, "active": bool}


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)
	_energy_caption = _label(Vector2(6, 4), 8, PHOSPHOR_DIM)
	_energy_caption.text = tr("OSD_ENERGY")
	_energy = _label(Vector2(6, 13), 16, PHOSPHOR)
	_rates = _label(Vector2(6, 31), 8, PHOSPHOR_DIM)
	_restart_caption = _label(Vector2(6, 218), 8, PHOSPHOR_DIM)
	_restart_caption.text = tr("OSD_RESTART")
	_notice = _label(Vector2(6, 204), 8, PHOSPHOR)
	_notice.modulate.a = 0.0
	_prompt = _label(Vector2(160, 226), 8, AMBER)
	_prompt.size.x = 154
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prompt.text = tr("OSD_SHOP_PROMPT")
	# Carta de ajuste del principio: centrada, sobre una franja oscura para leerse encima de la nieve.
	# Debajo del receptor, para no tapar la fábrica ni lo que hay que clicar.
	_intro = _label(Vector2(0, 180), 8, PHOSPHOR)
	_intro.size = Vector2(320, 30)
	_intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intro.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color(0, 0, 0, 0.6)
	_intro.add_theme_stylebox_override(&"normal", plate)
	_intro.hide()
	for i in SKILLS.size():
		var b := TextureButton.new()
		b.texture_normal = load("res://assets/textures/tv/icon_%s.png" % SKILLS[i])
		b.position = SKILL_ROW + Vector2(i * 17, 0)
		b.focus_mode = FOCUS_NONE
		b.visible = false
		b.pressed.connect(skill_pressed.emit.bind(SKILLS[i]))
		add_child(b)
		_skills[SKILLS[i]] = {"button": b, "cd": 0.0, "active": false}
	_restart = Button.new()
	_restart.text = tr("UI_RESTART")
	_restart.focus_mode = FOCUS_NONE
	_restart.flat = true
	_restart.add_theme_color_override(&"font_color", AMBER)
	_restart.position = Vector2(118, 214)
	_restart.visible = false
	_restart.pressed.connect(restart_pressed.emit)
	add_child(_restart)


## restart_carga: Carga que daría reiniciar ya, o -1 si aún no se puede.
func show_values(energy: String, per_second: String, per_click: String, progress: float, restart_carga: int,
		shop_ready: bool) -> void:
	_energy.text = energy
	_rates.text = "%s  ·  %s" % [per_second, tr("OSD_PER_CLICK") % per_click]
	_progress = clampf(progress, 0.0, 1.0)
	_restart.visible = restart_carga >= 0
	if restart_carga >= 0:
		_restart.text = tr("UI_RESTART_CONFIRM") % restart_carga
	# Parpadeo de OSD: encendido y apagado secos, no un fundido.
	_prompt.visible = shop_ready and fmod(Time.get_ticks_msec() / 1000.0, 1.2) < 0.8
	queue_redraw()


func show_intro(text: String) -> void:
	_intro.text = text
	_intro.show()


func hide_intro() -> void:
	_intro.hide()


func is_intro_visible() -> bool:
	return _intro.visible


## Barra de cintas (fracción, o -1 si aún no hay), racha (0-1) y habilidades {skill: [espera 0-1, activa]}.
func show_extras(tape: float, combo: float, skills: Dictionary) -> void:
	_tape = tape
	_combo = combo
	for skill: StringName in _skills:
		var row: Dictionary = _skills[skill]
		(row["button"] as TextureButton).visible = skills.has(skill)
		if skills.has(skill):
			row["cd"] = skills[skill][0]
			row["active"] = skills[skill][1]
	queue_redraw()


## Aviso abajo a la izquierda que se va solo («+ ANTENA»).
func notify(text: String) -> void:
	_notice.text = text
	if _notice_tween:
		_notice_tween.kill()
	_notice.modulate.a = 1.0
	_notice_tween = create_tween()
	_notice_tween.tween_interval(NOTICE_TIME)
	_notice_tween.tween_property(_notice, "modulate:a", 0.0, 0.0)


func _draw() -> void:
	var font := get_theme_default_font()
	# Barra de cintas: diez segmentos bajo el ritmo; se llena con tus clics.
	if _tape >= 0.0:
		for i in 10:
			var r := Rect2(Vector2(6 + i * 4, 42), Vector2(3, 3))
			draw_rect(Rect2(r.position + Vector2(1, 1), r.size), SHADOW)
			draw_rect(r, PHOSPHOR if float(i) < _tape * 10.0 else Color(PHOSPHOR_DIM, 0.35))
	# Latido de la racha: un punto ámbar que crece y late más deprisa cuanto más alta va.
	if _combo > 0.0:
		var beat := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * TAU * (1.0 + 2.0 * _combo))
		var side := 2.0 + roundf(_combo * 3.0 * beat)
		draw_rect(Rect2(Vector2(50, 43.5) - Vector2(side, side) / 2.0, Vector2(side, side)), AMBER)
	# Habilidades: oscurecidas según la espera, con su tecla; la activa, recuadrada.
	for i in SKILLS.size():
		var row: Dictionary = _skills[SKILLS[i]]
		var b: TextureButton = row["button"]
		if not b.visible:
			continue
		var r := Rect2(b.position, Vector2(12, 12))
		var cd: float = row["cd"]
		if cd > 0.0:
			draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * cd)), Color(0, 0, 0, 0.7))
		if row["active"]:
			draw_rect(r.grow(1), AMBER, false)
		draw_string(font, r.position + Vector2(-5, 12), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
			PHOSPHOR if cd <= 0.0 else PHOSPHOR_DIM)
	# Barra de reinicio en segmentos, como la del volumen de una tele.
	var origin := Vector2(6, 228)
	for i in BAR_SEGMENTS:
		var r := Rect2(origin + Vector2(i * 5, 0), Vector2(4, 6))
		var lit := float(i) < _progress * BAR_SEGMENTS
		draw_rect(Rect2(r.position + Vector2(1, 1), r.size), SHADOW)
		draw_rect(r, PHOSPHOR if lit else Color(PHOSPHOR_DIM, 0.35))


func _label(pos: Vector2, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.mouse_filter = MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", color)
	l.add_theme_color_override(&"font_shadow_color", SHADOW)
	l.add_theme_constant_override(&"shadow_offset_x", 1)
	l.add_theme_constant_override(&"shadow_offset_y", 1)
	l.add_theme_constant_override(&"shadow_outline_size", 0)
	add_child(l)
	return l
