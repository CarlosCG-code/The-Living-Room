class_name TvOsd
extends Control

# Texto en pantalla de la tele (OSD), como el de una tele o un vídeo de los 90: fósforo verde pálido con
# sombra dura y pegado a las esquinas (sin mayúsculas: la fuente no tiene las acentuadas). Arriba la Energía y el ritmo; abajo la barra de
# reinicio, los avisos («+ ANTENA») y la tecla de las mejoras. Solo pinta: tv_game_ui le pasa los datos.

signal restart_pressed

const PHOSPHOR := Color("b8f5c4")
const PHOSPHOR_DIM := Color("5f8f6c")
const AMBER := Color("ffc861")
const SHADOW := Color(0, 0, 0, 0.85)
const NOTICE_TIME := 3.0
const BAR_SEGMENTS := 20

var _energy: Label
var _energy_caption: Label
var _rates: Label
var _restart_caption: Label
var _prompt: Label
var _notice: Label
var _restart: Button
var _progress := 0.0
var _notice_tween: Tween


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
	_restart = Button.new()
	_restart.text = tr("UI_RESTART")
	_restart.focus_mode = FOCUS_NONE
	_restart.flat = true
	_restart.add_theme_color_override(&"font_color", AMBER)
	_restart.position = Vector2(118, 214)
	_restart.visible = false
	_restart.pressed.connect(restart_pressed.emit)
	add_child(_restart)


func show_values(energy: String, per_second: String, per_click: String, progress: float, can_restart: bool,
		shop_ready: bool) -> void:
	_energy.text = energy
	_rates.text = "%s  ·  %s" % [per_second, tr("OSD_PER_CLICK") % per_click]
	_progress = clampf(progress, 0.0, 1.0)
	_restart.visible = can_restart
	# Parpadeo de OSD: encendido y apagado secos, no un fundido.
	_prompt.visible = shop_ready and fmod(Time.get_ticks_msec() / 1000.0, 1.2) < 0.8
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
