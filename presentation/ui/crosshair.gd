class_name Crosshair
extends Control

# Punto en el centro de la pantalla, solo de pie (specs/hito4a.md D11): crece sobre lo que se puede usar.

const SIZE := 2.0
const SIZE_HIGHLIGHT := 5.0

var highlight := false:
	set(value):
		if value != highlight:
			highlight = value
			queue_redraw()


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_circle(size / 2.0, SIZE_HIGHLIGHT if highlight else SIZE, Color(0.85, 0.85, 0.8, 0.7 if highlight else 0.45))
