class_name EndOfBroadcast
extends Control

# Carta de «fin de la emisión» que sale al pulsar Reiniciar (specs/incremental_v2.md §6): barras de ajuste
# apagadas, el aviso y un tono de prueba que desafina (lo pone tv_game_ui). Analog horror: un formato
# oficial y tranquilo que no debería estar ahí.

const DURATION := 2.5
const BARS: Array[Color] = [Color("8a8f96"), Color("5b6370"), Color("3a4250"), Color("232a36"),
	Color("151a24"), Color("0b0e16"), Color("232a36")]


func _ready() -> void:
	position = Vector2.ZERO
	size = Vector2(320, 240)
	mouse_filter = MOUSE_FILTER_STOP
	var title := Label.new()
	title.text = tr("UI_END_OF_BROADCAST")
	title.add_theme_font_size_override(&"font_size", 16)
	title.add_theme_color_override(&"font_color", Color("c8d0dc"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 150)
	title.size = Vector2(320, 20)
	add_child(title)
	var sub := Label.new()
	sub.text = tr("UI_END_OF_BROADCAST_SUB")
	sub.add_theme_color_override(&"font_color", Color("8a96ae"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 176)
	sub.size = Vector2(320, 12)
	add_child(sub)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("05060b"))
	var w := size.x / BARS.size()
	for i in BARS.size():
		draw_rect(Rect2(i * w, 20, w + 1, 110), BARS[i])
