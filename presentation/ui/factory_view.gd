class_name FactoryView
extends Control

# Fábrica de la tele (specs/hito2.md D19): las máquinas de cada generador, unidas por cables a la
# fábrica, con electricidad que corre hacia ella. Pulsar la fábrica abre la tienda; las interferencias
# salen como chispas de un cable. Solo pinta: lee Game.economy y avisa con señales.

signal shop_requested
signal interference_pressed

## El nombre de una máquina se ve unos segundos al aparecer por primera vez y luego se desvanece.
const LABEL_HOLD := 3.0
## Unidades del generador necesarias para cada hueco (el k-ésimo pide THRESHOLDS[k]).
const THRESHOLDS: Array[int] = [1, 5, 10, 25, 50]
const FADE_IN := 0.6
const FACTORY_RECT := Rect2(120, 96, 60, 50)
const CATCH_SIZE := Vector2(44, 36)
# Por generador: huecos (esquina superior izquierda), tamaño de la máquina, etiqueta y cable (desde, hasta, caída).
const LAYOUT := {
	&"antenna": {"slots": [Vector2(8, 22), Vector2(26, 22), Vector2(44, 22)], "size": Vector2(14, 36),
		"label": Vector2(8, 8), "cable": [Vector2(58, 52), Vector2(121, 104), 14.0]},
	&"channel_3": {"slots": [Vector2(166, 18)], "size": Vector2(22, 60),
		"label": Vector2(160, 4), "cable": [Vector2(177, 78), Vector2(174, 98), 2.0]},
	&"valves": {"slots": [Vector2(6, 112), Vector2(30, 112), Vector2(54, 112)], "size": Vector2(20, 14),
		"label": Vector2(6, 98), "cable": [Vector2(74, 120), Vector2(121, 124), 10.0]},
	&"audio_frequency": {"slots": [Vector2(6, 210), Vector2(24, 210)], "size": Vector2(16, 20),
		"label": Vector2(4, 198), "cable": [Vector2(40, 220), Vector2(128, 146), 20.0]},
	&"tuner": {"slots": [Vector2(50, 214), Vector2(70, 214)], "size": Vector2(18, 16),
		"label": Vector2(40, 202), "cable": [Vector2(88, 222), Vector2(144, 147), 16.0]},
	&"remote": {"slots": [Vector2(104, 210), Vector2(114, 210)], "size": Vector2(8, 20),
		"label": Vector2(96, 198), "cable": [Vector2(118, 210), Vector2(160, 146), 8.0]},
}

var _groups := {}  # StringName -> {"machines": Array[FactoryMachine], "cable": FactoryCable, "label": Label}
var _sparks: CPUParticles2D
var _catch: Button
var _hint: Label
var _interference_on := false
var _faulty: FactoryCable


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	for id: StringName in LAYOUT:
		var spec: Dictionary = LAYOUT[id]
		var cable := FactoryCable.new(spec["cable"][0], spec["cable"][1], spec["cable"][2])
		cable.visible = false
		add_child(cable)
		var machines: Array[FactoryMachine] = []
		for pos: Vector2 in spec["slots"]:
			var m := FactoryMachine.new(id)
			m.position = pos
			m.size = spec["size"]
			m.visible = false
			add_child(m)
			machines.append(m)
		var label := Label.new()
		var gen := Game.economy.config.find_generator(id)
		label.text = tr(gen.name_key) if gen else String(id)
		label.position = spec["label"]
		label.visible = false
		label.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(label)
		_groups[id] = {"machines": machines, "cable": cable, "label": label}

	var factory := Button.new()
	factory.flat = true
	factory.focus_mode = FOCUS_NONE
	factory.position = FACTORY_RECT.position
	factory.size = FACTORY_RECT.size
	factory.pressed.connect(shop_requested.emit)
	add_child(factory)
	var drawing := FactoryMachine.new(&"factory")
	drawing.size = FACTORY_RECT.size
	factory.add_child(drawing)

	_sparks = CPUParticles2D.new()
	_sparks.name = "Sparks"
	_sparks.emitting = false
	_sparks.amount = 48
	_sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_sparks.emission_sphere_radius = 3.0
	_sparks.lifetime = 0.6
	_sparks.direction = Vector2.UP
	_sparks.spread = 180.0
	_sparks.initial_velocity_min = 30.0
	_sparks.initial_velocity_max = 70.0
	_sparks.gravity = Vector2(0, 120)
	_sparks.scale_amount_min = 2.0
	_sparks.scale_amount_max = 3.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 1.0, 0.7))
	ramp.set_color(1, Color(1.0, 0.3, 0.1, 0.0))
	_sparks.color_ramp = ramp
	add_child(_sparks)
	_catch = Button.new()
	_catch.name = "Catch"
	_catch.flat = true
	_catch.focus_mode = FOCUS_NONE
	_catch.size = CATCH_SIZE
	_catch.visible = false
	_catch.pressed.connect(interference_pressed.emit)
	add_child(_catch)
	_hint = Label.new()
	_hint.text = tr("UI_INTERFERENCE")
	_hint.visible = false
	_hint.mouse_filter = MOUSE_FILTER_IGNORE
	var backing := StyleBoxFlat.new()
	backing.bg_color = Color.BLACK
	backing.set_content_margin_all(1)
	_hint.add_theme_stylebox_override(&"normal", backing)
	_hint.add_theme_color_override(&"font_color", FactoryCable.FAULT)
	add_child(_hint)


func _process(_delta: float) -> void:
	var eco := Game.economy
	show_counts(eco.state.generators)
	set_interference(eco.interference_active())


func show_counts(counts: Dictionary) -> void:
	for id: StringName in _groups:
		var group: Dictionary = _groups[id]
		var owned: int = counts.get(id, 0)
		var machines: Array[FactoryMachine] = group["machines"]
		for k in machines.size():
			_set_shown(machines[k], owned >= THRESHOLDS[mini(k, THRESHOLDS.size() - 1)])
		_set_shown(group["cable"], owned > 0)
		_announce(group["label"], owned > 0)
		var cable: FactoryCable = group["cable"]
		cable.speed = 18.0 + 10.0 * log(1.0 + owned)
		cable.pulses = clampi(1 + owned / 5, 1, 6)


func set_interference(active: bool) -> void:
	if active == _interference_on:
		return
	_interference_on = active
	if active:
		var at := FACTORY_RECT.get_center()
		var powered: Array[FactoryCable] = []
		for id: StringName in _groups:
			var cable: FactoryCable = _groups[id]["cable"]
			if cable.visible:
				powered.append(cable)
		if not powered.is_empty():
			_faulty = powered.pick_random()
			_faulty.sparking = true
			at = _faulty.midpoint()
		_sparks.position = at
		_catch.position = (at - CATCH_SIZE / 2).clamp(Vector2.ZERO, size - CATCH_SIZE)
		var hint_size := _hint.get_combined_minimum_size()
		_hint.position = (at + Vector2(-hint_size.x / 2, 10)).round().clamp(Vector2.ZERO, size - hint_size)
	elif _faulty:
		_faulty.sparking = false
		_faulty = null
	_sparks.emitting = active
	_catch.visible = active
	_hint.visible = active


func get_group(id: StringName) -> Dictionary:
	return _groups.get(id, {})


func _announce(label: Label, on: bool) -> void:
	if on == label.visible:
		return
	label.visible = on
	if on:
		label.modulate.a = 0.0
		var tween := label.create_tween()
		tween.tween_property(label, "modulate:a", 1.0, FADE_IN)
		tween.tween_interval(LABEL_HOLD)
		tween.tween_property(label, "modulate:a", 0.0, 1.0)


func _set_shown(item: CanvasItem, on: bool) -> void:
	if on == item.visible:
		return
	item.visible = on
	if on:
		item.modulate.a = 0.0
		item.create_tween().tween_property(item, "modulate:a", 1.0, FADE_IN)
