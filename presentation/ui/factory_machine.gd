class_name FactoryMachine
extends Control

# Una máquina de la fábrica dibujada con líneas de un píxel, como tiza (specs/hito2.md D19).
# Coordenadas en píxeles del SubViewport de 320 × 240; el origen es la esquina superior izquierda.

const CHALK := Color(0.86, 0.86, 0.8)
const GLOW := Color(1.0, 0.6, 0.2)
const RED := Color(1.0, 0.25, 0.2)
const GREEN := Color(0.4, 1.0, 0.5)

var kind: StringName
## Giro del mando del dial (radianes); lo mueve la UI al clicar y con los clics automáticos.
var angle := 0.0
var _t := 0.0


func _init(p_kind: StringName = &"") -> void:
	kind = p_kind
	mouse_filter = MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	match kind:
		&"antenna":
			_antenna()
		&"valves":
			_valves()
		&"audio_frequency":
			_audio()
		&"tuner":
			_tuner()
		&"remote":
			_remote()
		&"channel_3":
			_channel_3()
		&"factory":
			_factory()
		&"dial":
			_dial()


func _blink(period: float) -> bool:
	return fmod(_t, period) < period * 0.5


func _px(x: float, y: float, color: Color, w: float = 1.0, h: float = 1.0) -> void:
	draw_rect(Rect2(x, y, w, h), color)


func _antenna() -> void:
	draw_line(Vector2(7, 35), Vector2(7, 4), CHALK)
	draw_line(Vector2(2, 35), Vector2(12, 35), CHALK)
	for i in 4:
		var half := 6 - i
		var y := 8 + i * 5
		draw_line(Vector2(7 - half, y), Vector2(7 + half, y), CHALK)
	if _blink(1.2):
		_px(6, 2, RED, 2, 2)


func _valves() -> void:
	draw_rect(Rect2(0, 10, 20, 4), CHALK, false)
	for i in 3:
		var x := 2 + i * 6
		draw_line(Vector2(x, 10), Vector2(x, 3), CHALK)
		draw_line(Vector2(x + 3, 10), Vector2(x + 3, 3), CHALK)
		draw_line(Vector2(x + 1, 2), Vector2(x + 2, 2), CHALK)
		var heat := 0.6 + 0.4 * sin(_t * 9.0 + i * 2.0)
		_px(x + 1, 5, Color(GLOW, heat), 2, 4)


func _audio() -> void:
	draw_rect(Rect2(0, 0, 16, 20), CHALK, false)
	draw_rect(Rect2(2, 2, 12, 8), CHALK, false)
	var wave := PackedVector2Array()
	for x in range(3, 14):
		wave.append(Vector2(x, roundf(6 + 2 * sin(x * 0.9 + _t * 6.0))))
	draw_polyline(wave, GREEN)
	draw_arc(Vector2(5, 15), 2, 0, TAU, 8, CHALK)
	draw_arc(Vector2(11, 15), 2, 0, TAU, 8, CHALK)


func _tuner() -> void:
	draw_rect(Rect2(0, 2, 18, 14), CHALK, false)
	draw_arc(Vector2(6, 9), 4, 0, TAU, 12, CHALK)
	draw_line(Vector2(6, 9), Vector2(6, 9) + Vector2.from_angle(_t * 1.5) * 3, CHALK)
	_px(11, 5, GLOW, 5, 3)


func _remote() -> void:
	draw_rect(Rect2(0, 0, 8, 20), CHALK, false)
	if _blink(0.8):
		_px(3, 2, RED, 2, 2)
	for r in 4:
		for c in 2:
			_px(2 + c * 3, 7 + r * 3, CHALK)


func _channel_3() -> void:
	draw_line(Vector2(4, 59), Vector2(8, 21), CHALK)
	draw_line(Vector2(18, 59), Vector2(14, 21), CHALK)
	for i in 4:
		var y0 := 59 - i * 9
		var y1 := y0 - 9
		var l0 := 4 + (59 - y0) * 4.0 / 38.0
		var l1 := 4 + (59 - y1) * 4.0 / 38.0
		if i % 2 == 0:
			draw_line(Vector2(l0, y0), Vector2(22 - l1, y1), CHALK)
		else:
			draw_line(Vector2(22 - l0, y0), Vector2(l1, y1), CHALK)
	draw_rect(Rect2(2, 6, 18, 14), CHALK, false)
	draw_string(get_theme_default_font(), Vector2(8, 17), "3", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, RED)
	if _blink(1.6):
		_px(10, 2, RED, 2, 2)


func _factory() -> void:
	var body := PackedVector2Array([Vector2(0, 6), Vector2(60, 2), Vector2(56, 50), Vector2(4, 47), Vector2(0, 6)])
	draw_polyline(body, CHALK)
	draw_rect(Rect2(6, -7, 6, 9), CHALK, false)
	for i in 3:
		var age := fmod(_t * 0.5 + i / 3.0, 1.0)
		draw_arc(Vector2(9 - age * 6, -9 - age * 14), 1 + age * 2, 0, TAU, 8, Color(CHALK, 1.0 - age))
	_centered(tr("UI_FACTORY").to_upper(), 22, CHALK)
	_centered("> " + tr("UI_SHOP_TITLE"), 36, GLOW if _blink(1.5) else CHALK)


func _centered(text: String, y: float, color: Color) -> void:
	var font := get_theme_default_font()
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	draw_string(font, Vector2(roundf(30 - w / 2), y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)


func _dial() -> void:
	var c := (size / 2).round()
	draw_arc(c, 16, 0, TAU, 24, CHALK)
	draw_arc(c, 12, 0, TAU, 20, CHALK)
	for i in 12:
		var a := i * TAU / 12
		draw_line(c + Vector2.from_angle(a) * 18, c + Vector2.from_angle(a) * 20, CHALK)
	draw_line(c, (c + Vector2.from_angle(angle - PI / 2) * 11).round(), GLOW)
