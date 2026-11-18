class_name FactoryView
extends Control

# Pantalla de la tele en pixel art (specs/hito2.md D19): bosque nevado de noche, la fábrica en el centro
# y alrededor las máquinas de cada generador, unidas a ella por cables con electricidad. Se clican las
# máquinas (y el receptor, que está desde el principio) para sintonizar; la fábrica abre las mejoras.
# Solo pinta: lee Game.economy y avisa con señales; tv_game_ui las conecta con Game.

signal machine_pressed(at: Vector2)
signal hold_changed(holding: bool)
signal shop_requested
signal event_pressed

const TEX := "res://assets/textures/tv/"
# Eventos (core/tv_event_def.gd): la estrella cruza el cielo; la silueta sale en uno de estos sitios.
const STAR_FROM := Vector2(300, 14)
const STAR_TO := Vector2(40, 58)
const SILHOUETTE_SPOTS: Array[Vector2] = [Vector2(196, 131), Vector2(300, 134), Vector2(112, 129), Vector2(24, 133)]
const SHADOW := Color("05060b")
## Oscurece y enfría el fondo pintado para que la tele no parezca alegre.
const BG_TINT := Color(0.4, 0.43, 0.58)
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
var _event_layer: Node2D
var _vignette: TextureRect
var _event_id: StringName = &""
var _event_t := 0.0
var _event_at := Vector2.ZERO
var _faulty: FactoryCable
var _auto_acc := 0.0
var _flicker_left := 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	var bg := TextureRect.new()
	bg.texture = load(TEX + "background.png")
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	bg.modulate = BG_TINT
	add_child(bg)
	_event_layer = Node2D.new()
	_event_layer.draw.connect(_draw_event)
	add_child(_event_layer)
	add_child(_particles(Vector2(160, -4), Vector2(170, 1), 70, 9.0, Vector2(4, 14), Color(0.75, 0.8, 0.92, 0.55)))
	add_child(TvFog.make())

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
	_catch.pressed.connect(event_pressed.emit)
	add_child(_catch)
	_vignette = _make_vignette()
	add_child(_vignette)
	_hint = _label(tr("UI_EVENT_CLEAR_SIGNAL"), Vector2.ZERO, Color("7fe0b0"))
	_hint.visible = false
	# Los textos van por encima de la viñeta para que se lean en los bordes.
	for child in get_children():
		if child is Label:
			move_child(child, -1)


func _process(delta: float) -> void:
	var eco := Game.economy
	show_counts(eco.state.generators)
	show_event(eco.active_event(), eco.event_progress())
	_shop_hint.visible = _has_affordable(eco) and fmod(Time.get_ticks_msec() / 1000.0, 1.0) < 0.6
	_flicker(delta)
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


## Muestra el evento activo de la tele (null = ninguno); t va de 0 (empieza) a 1 (acaba).
func show_event(e: TvEventDef, t: float) -> void:
	var id: StringName = e.id if e else &""
	if id != _event_id:
		_start_event(e)
	_event_t = t
	if id == &"":
		return
	match id:
		&"interference":
			# Las chispas viajan por el cable desde la máquina hasta la fábrica.
			_event_at = _faulty.point_at(t) if _faulty else FACTORY_POS + Vector2(28, 25)
		&"shooting_star":
			_event_at = STAR_FROM.lerp(STAR_TO, t)
		&"clear_signal":
			_event_at = Vector2(160, 30)
	_sparks.position = _event_at
	_catch.position = (_event_at - CATCH_SIZE / 2).clamp(Vector2.ZERO, size - CATCH_SIZE)
	var hint_size := _hint.get_combined_minimum_size()
	_hint.position = (_event_at + Vector2(-hint_size.x / 2, 10)).round().clamp(Vector2(0, 14), size - hint_size)
	_event_layer.queue_redraw()


func _start_event(e: TvEventDef) -> void:
	var id: StringName = e.id if e else &""
	_event_id = id
	if _faulty:
		_faulty.sparking = false
		_faulty = null
	if id == &"interference":
		var powered: Array[FactoryCable] = []
		for gid: StringName in _groups:
			var cable: FactoryCable = _groups[gid]["cable"]
			if cable.visible:
				powered.append(cable)
		if not powered.is_empty():
			_faulty = powered.pick_random()
			_faulty.sparking = true
	elif id == &"silhouette":
		_event_at = SILHOUETTE_SPOTS.pick_random()
	_sparks.emitting = id == &"interference"
	_catch.visible = e != null and e.catchable()
	# Solo la Señal clara se anuncia: lo demás hay que verlo (pedido del usuario, 2026-11-18).
	_hint.visible = id == &"clear_signal"
	_event_layer.queue_redraw()


func _draw_event() -> void:
	var c := _event_layer
	match _event_id:
		&"shooting_star":
			var dir := (STAR_TO - STAR_FROM).normalized()
			for k in 10:
				var p := (_event_at - dir * k * 2.0).round()
				c.draw_rect(Rect2(p, Vector2(1, 1)), Color(1, 1, 0.9, 1.0 - k / 10.0))
			c.draw_rect(Rect2(_event_at.round() - Vector2(1, 1), Vector2(2, 2)), Color.WHITE)
		&"clear_signal":
			# Aurora: bandas verdosas que ondulan; entra y sale suave.
			var alpha := sin(PI * _event_t) * 0.35
			var time := Time.get_ticks_msec() / 1000.0
			for band in 3:
				for x in range(0, 320, 2):
					var y := 22.0 + band * 7.0 + sin(x * 0.03 + time * 0.8 + band) * 6.0
					c.draw_rect(Rect2(x, y, 2, 10 - band * 2), Color(0.4, 1.0, 0.7 - band * 0.15, alpha * (1.0 - band * 0.25)))
		&"silhouette":
			# Figura quieta entre los árboles: aparece despacio y parpadea al final.
			var a := clampf(_event_t * 4.0, 0.0, 1.0)
			if _event_t > 0.8 and fmod(_event_t * 40.0, 2.0) < 1.0:
				a *= 0.3
			var feet := _event_at
			c.draw_rect(Rect2(feet + Vector2(-3, -16), Vector2(6, 16)), Color(SHADOW, a))  # cuerpo
			c.draw_rect(Rect2(feet + Vector2(-4, -15), Vector2(1, 9)), Color(SHADOW, a))  # brazos largos
			c.draw_rect(Rect2(feet + Vector2(3, -15), Vector2(1, 9)), Color(SHADOW, a))
			c.draw_rect(Rect2(feet + Vector2(-2, -21), Vector2(4, 5)), Color(SHADOW, a))  # cabeza
			c.draw_rect(Rect2(feet + Vector2(-1, -19), Vector2(1, 1)), Color(0.9, 0.85, 0.8, a * 0.9))  # ojos
			c.draw_rect(Rect2(feet + Vector2(1, -19), Vector2(1, 1)), Color(0.9, 0.85, 0.8, a * 0.9))


## Viñeta: oscurece los bordes de la pantalla.
func _make_vignette() -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, Color(SHADOW, 0.0))
	g.set_color(1, Color(SHADOW, 0.85))
	g.add_point(0.4, Color(SHADOW, 0.0))
	g.add_point(0.75, Color(SHADOW, 0.45))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.05, 1.05)
	tex.width = 160
	tex.height = 120
	var v := TextureRect.new()
	v.name = "Vignette"
	v.texture = tex
	v.size = Vector2(320, 240)
	v.stretch_mode = TextureRect.STRETCH_SCALE
	v.mouse_filter = MOUSE_FILTER_IGNORE
	return v


## De vez en cuando la luz de la fábrica falla un instante.
func _flicker(delta: float) -> void:
	if _flicker_left > 0.0:
		_flicker_left -= delta
	elif randf() < delta / 9.0:
		_flicker_left = randf_range(0.06, 0.25)
	_factory.modulate = Color(0.45, 0.45, 0.55) if _flicker_left > 0.0 else Color.WHITE


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
