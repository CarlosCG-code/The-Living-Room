class_name FactoryView
extends Control

# Pantalla de la tele en pixel art (specs/hito2.md D19): bosque nevado de noche, la fábrica en el centro
# y alrededor las máquinas de cada generador, unidas a ella por cables con electricidad. Se clican las
# máquinas (y el receptor, que está desde el principio) para sintonizar; la fábrica abre las mejoras.
# Solo pinta: lee Game.economy y avisa con señales; tv_game_ui las conecta con Game.

signal machine_pressed(at: Vector2)
signal hold_changed(holding: bool)
signal shop_requested
signal interference_pressed

const TEX := "res://assets/textures/tv/"
## Unidades del generador necesarias para cada hueco (el k-ésimo pide THRESHOLDS[k]).
const THRESHOLDS: Array[int] = [1, 5, 10, 25, 50]
const FADE_IN := 0.6
const LABEL_HOLD := 3.0
const FACTORY_POS := Vector2(132, 92)
const RECEPTOR_FEET := Vector2(147, 174)
const CATCH_SIZE := Vector2(40, 32)
# Por generador: pies de cada hueco (abajo a la izquierda), etiqueta y cable (desde, hasta, caída).
const LAYOUT := {
	&"antenna": {"slots": [Vector2(62, 132), Vector2(80, 136), Vector2(98, 132)],
		"label": Vector2(58, 84), "cable": [Vector2(106, 118), Vector2(134, 120), 6.0]},
	&"channel_3": {"slots": [Vector2(226, 134)], "label": Vector2(212, 66),
		"cable": [Vector2(232, 118), Vector2(186, 122), 6.0]},
	&"valves": {"slots": [Vector2(54, 168), Vector2(78, 170), Vector2(102, 168)],
		"label": Vector2(50, 140), "cable": [Vector2(116, 160), Vector2(134, 136), 4.0]},
	&"audio_frequency": {"slots": [Vector2(74, 214), Vector2(96, 216)],
		"label": Vector2(40, 218), "cable": [Vector2(108, 198), Vector2(140, 142), 8.0]},
	&"tuner": {"slots": [Vector2(204, 214), Vector2(228, 212)],
		"label": Vector2(196, 218), "cable": [Vector2(212, 198), Vector2(178, 142), 8.0]},
	&"remote": {"slots": [Vector2(232, 172), Vector2(246, 174)],
		"label": Vector2(212, 144), "cable": [Vector2(236, 160), Vector2(186, 136), 4.0]},
}

var _groups := {}  # StringName -> {"machines": Array[TextureButton], "cable": FactoryCable, "label": Label}
var _receptor: TextureButton
var _factory: TextureButton
var _shop_hint: Label
var _sparks: CPUParticles2D
var _catch: Button
var _hint: Label
var _interference_on := false
var _faulty: FactoryCable
var _auto_acc := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	var bg := TextureRect.new()
	bg.texture = load(TEX + "background.png")
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)
	add_child(_particles(Vector2(160, -4), Vector2(170, 1), 70, 9.0, Vector2(4, 14), Color(0.91, 0.94, 1.0, 0.8)))

	var cables: Array[FactoryCable] = []
	for id: StringName in LAYOUT:
		var spec: Dictionary = LAYOUT[id]
		var cable := FactoryCable.new(spec["cable"][0], spec["cable"][1], spec["cable"][2])
		cable.visible = false
		add_child(cable)
		cables.append(cable)
	_factory = _sprite_button(load(TEX + "factory.png"), FACTORY_POS)
	_factory.pressed.connect(shop_requested.emit)
	add_child(_particles(FACTORY_POS + Vector2(44, 0), Vector2(2, 1), 10, 3.0, Vector2(-8, -10), Color(0.66, 0.74, 0.88, 0.7)))
	_shop_hint = _label(tr("UI_SHOP_TITLE"), FACTORY_POS + Vector2(10, -12), Color("ffd36b"))

	var i := 0
	for id: StringName in LAYOUT:
		var spec: Dictionary = LAYOUT[id]
		var tex: Texture2D = load(TEX + String(id) + ".png")
		var machines: Array[TextureButton] = []
		for feet: Vector2 in spec["slots"]:
			var m := _machine(tex, feet)
			m.visible = false
			machines.append(m)
		var gen := Game.economy.config.find_generator(id)
		var label := _label(tr(gen.name_key) if gen else String(id), spec["label"], Color.WHITE)
		label.visible = false
		_groups[id] = {"machines": machines, "cable": cables[i], "label": label}
		i += 1
	_receptor = _machine(load(TEX + "receptor.png"), RECEPTOR_FEET)

	_sparks = _particles(Vector2.ZERO, Vector2(3, 3), 48, 0.6, Vector2.ZERO, Color(1.0, 0.95, 0.6))
	_sparks.name = "Sparks"
	_sparks.emitting = false
	_sparks.direction = Vector2.UP
	_sparks.spread = 180.0
	_sparks.initial_velocity_min = 30.0
	_sparks.initial_velocity_max = 70.0
	_sparks.gravity = Vector2(0, 120)
	_sparks.scale_amount_max = 2.0
	_sparks.preprocess = 0.0
	add_child(_sparks)
	_catch = Button.new()
	_catch.name = "Catch"
	_catch.flat = true
	_catch.focus_mode = FOCUS_NONE
	_catch.size = CATCH_SIZE
	_catch.visible = false
	_catch.pressed.connect(interference_pressed.emit)
	add_child(_catch)
	_hint = _label(tr("UI_INTERFERENCE"), Vector2.ZERO, FactoryCable.FAULT)
	_hint.visible = false


func _process(delta: float) -> void:
	var eco := Game.economy
	show_counts(eco.state.generators)
	set_interference(eco.interference_active())
	_shop_hint.visible = _has_affordable(eco) and fmod(Time.get_ticks_msec() / 1000.0, 1.0) < 0.6
	# Dial solo (y mantener pulsado): las máquinas dan saltitos solas, uno por clic automático.
	_auto_acc += eco.auto_clicks_per_second(_any_held()) * delta
	while _auto_acc >= 1.0:
		_auto_acc -= 1.0
		_bounce(_random_machine())


func show_counts(counts: Dictionary) -> void:
	for id: StringName in _groups:
		var group: Dictionary = _groups[id]
		var owned: int = counts.get(id, 0)
		var machines: Array[TextureButton] = group["machines"]
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
		var at := FACTORY_POS + Vector2(28, 25)
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
		_hint.position = (at + Vector2(-hint_size.x / 2, 10)).round().clamp(Vector2(0, 12), size - hint_size)
	elif _faulty:
		_faulty.sparking = false
		_faulty = null
	_sparks.emitting = active
	_catch.visible = active
	_hint.visible = active


## Número que sube y se desvanece donde se ha clicado.
func float_text(at: Vector2, text: String) -> void:
	var label := _label(text, (at + Vector2(-8, -14)).round(), Color("ffd36b"))
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 14, 0.7)
	tween.tween_property(label, "modulate:a", 0.0, 0.7)
	tween.chain().tween_callback(label.queue_free)


## Pulsación desde el teclado: salta el receptor como si se hubiera clicado.
func press_receptor() -> Vector2:
	_bounce(_receptor)
	return _receptor.position + Vector2(_receptor.size.x / 2, 0)


func get_group(id: StringName) -> Dictionary:
	return _groups.get(id, {})


func get_receptor() -> TextureButton:
	return _receptor


func _machine(tex: Texture2D, feet: Vector2) -> TextureButton:
	var b := _sprite_button(tex, feet - Vector2(0, tex.get_height()))
	b.pivot_offset = Vector2(tex.get_width() / 2.0, tex.get_height())
	b.button_down.connect(func() -> void: hold_changed.emit(true))
	b.button_up.connect(func() -> void: hold_changed.emit(false))
	b.pressed.connect(func() -> void:
		_bounce(b)
		machine_pressed.emit(b.position + Vector2(b.size.x / 2, 0)))
	return b


func _sprite_button(tex: Texture2D, pos: Vector2) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = tex
	b.position = pos
	b.focus_mode = FOCUS_NONE
	# Solo cuenta el clic sobre los píxeles visibles del sprite.
	var mask := BitMap.new()
	mask.create_from_image_alpha(tex.get_image())
	b.texture_click_mask = mask
	add_child(b)
	return b


func _label(text: String, pos: Vector2, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.mouse_filter = MOUSE_FILTER_IGNORE
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_color_override(&"font_outline_color", Color("0b0e1a"))
	label.add_theme_constant_override(&"outline_size", 2)
	add_child(label)
	return label


func _particles(pos: Vector2, extents: Vector2, amount: int, lifetime: float, velocity: Vector2,
		color: Color) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = amount
	p.lifetime = lifetime
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = extents
	p.direction = velocity.normalized() if velocity != Vector2.ZERO else Vector2.DOWN
	p.spread = 15.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = velocity.length() * 0.7
	p.initial_velocity_max = velocity.length() * 1.3
	p.color = color
	p.preprocess = lifetime
	return p


func _bounce(item: Control) -> void:
	if item == null:
		return
	item.scale = Vector2(1.15, 0.8)
	item.create_tween().tween_property(item, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


func _random_machine() -> TextureButton:
	var shown: Array[TextureButton] = [_receptor]
	for id: StringName in _groups:
		for m: TextureButton in _groups[id]["machines"]:
			if m.visible:
				shown.append(m)
	return shown.pick_random()


func _any_held() -> bool:
	if _receptor.button_pressed:
		return true
	for id: StringName in _groups:
		for m: TextureButton in _groups[id]["machines"]:
			if m.button_pressed:
				return true
	return false


func _has_affordable(eco: Economy) -> bool:
	for g in eco.visible_generators():
		if eco.state.energy >= eco.cost_of(g.id):
			return true
	for u in eco.visible_upgrades():
		if eco.state.energy >= u.cost:
			return true
	return false


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
