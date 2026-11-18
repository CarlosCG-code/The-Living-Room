class_name FactoryCable
extends Node2D

# Cable de una máquina a la fábrica: goma oscura con su sombra y pulsos de electricidad ámbar
# que viajan hacia la fábrica (specs/hito2.md D19).

const RUBBER := Color("2a2f3f")
const RUBBER_SHADOW := Color("12151f")
const PULSE := Color("ffc861")
const FAULT := Color(1.0, 0.35, 0.2)

## Velocidad de los pulsos (px/s) y cuántos hay a la vez en el cable.
var speed := 20.0
var pulses := 2
## Con una interferencia, el cable parpadea en rojo.
var sparking := false

var _curve := Curve2D.new()
var _offset := 0.0


func _init(from: Vector2, to: Vector2, sag: float) -> void:
	_curve.bake_interval = 2.0
	var handle := (to - from) * 0.4
	_curve.add_point(from, Vector2.ZERO, Vector2(handle.x, handle.y + sag))
	_curve.add_point(to, Vector2(-handle.x, -handle.y + sag), Vector2.ZERO)


func _process(delta: float) -> void:
	_offset += speed * delta
	queue_redraw()


func midpoint() -> Vector2:
	return point_at(0.5)


## Punto del cable: 0 en la máquina, 1 en la fábrica.
func point_at(t: float) -> Vector2:
	return _curve.sample_baked(_curve.get_baked_length() * clampf(t, 0.0, 1.0))


func _draw() -> void:
	var points := _curve.get_baked_points()
	var fault := sparking and fmod(_offset, 6.0) < 3.0
	draw_polyline(points, FAULT if fault else RUBBER)
	var shifted := PackedVector2Array()
	for p in points:
		shifted.append(p + Vector2(0, 1))
	draw_polyline(shifted, RUBBER_SHADOW)
	var length := _curve.get_baked_length()
	for i in pulses:
		var p := _curve.sample_baked(fposmod(_offset + i * length / pulses, length)).round()
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), PULSE)
