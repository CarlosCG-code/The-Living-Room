class_name UpgradeTree
extends Control

# Árbol de mejoras (specs/hito2.md D19): cada mejora es un nodo unido a su padre (requires_id del .tres).
# Se navega con el ratón o con las flechas, se compra con clic o Intro y se cierra con Esc o la X.
# Solo pinta: lee Game.economy y pide las compras con buy_requested.

signal buy_requested(id: StringName)
signal close_requested

const NODE := Vector2(20, 20)
const ICONS := "res://assets/textures/tv/icon_"
# Posición (esquina superior izquierda) de cada nodo en la pantalla de 320 × 240.
const POSITIONS := {
	&"pulse": Vector2(20, 24), &"resonance": Vector2(116, 24), &"dial_auto": Vector2(164, 24),
	&"dial_auto_2": Vector2(212, 24), &"pulse_strong": Vector2(56, 54), &"dial_hold": Vector2(92, 54),
	&"antenna": Vector2(20, 92), &"valves": Vector2(68, 92), &"audio_frequency": Vector2(116, 92),
	&"tuner": Vector2(164, 92), &"remote": Vector2(212, 92), &"channel_3": Vector2(260, 92),
}
const ROW_X2_10 := 122.0
const ROW_X2_25 := 154.0
const CHALK := Color("e8f0ff")
const DIM := Color("44558a")
const GOLD := Color("ffd36b")
const GREEN := Color("6cf08a")

var _buttons := {}  # StringName -> Button
var _icons := {}  # StringName -> Texture2D
var _selected: StringName = &""
var _info: Label


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	var config := Game.economy.config
	for g in config.generators:
		_add_node(g.id, POSITIONS[g.id], g.id)
		_add_node(StringName("%s_x2_10" % g.id), Vector2(POSITIONS[g.id].x, ROW_X2_10), g.id)
		_add_node(StringName("%s_x2_25" % g.id), Vector2(POSITIONS[g.id].x, ROW_X2_25), g.id)
	for u in config.upgrades:
		if POSITIONS.has(u.id):
			_add_node(u.id, POSITIONS[u.id], u.id)
	var title := Label.new()
	title.text = tr("UI_SHOP_TITLE")
	title.position = Vector2(6, 4)
	add_child(title)
	var close := Button.new()
	close.text = tr("UI_CLOSE")
	close.position = Vector2(290, 3)
	close.focus_mode = FOCUS_NONE
	close.pressed.connect(close_requested.emit)
	add_child(close)
	_info = Label.new()
	_info.position = Vector2(8, 192)
	_info.size = Vector2(304, 44)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_info)


func _process(_delta: float) -> void:
	if visible:
		_info.text = describe(_selected)
		queue_redraw()


## Lleva el foco al primer nodo comprable (o al primero) para usar el teclado.
func focus_first() -> void:
	var eco := Game.economy
	for id: StringName in _buttons:
		if eco.is_visible(id) and not eco.is_bought(id):
			_buttons[id].grab_focus()
			return
	_buttons.values()[0].grab_focus()


func get_node_button(id: StringName) -> Button:
	return _buttons.get(id)


func state_of(id: StringName) -> StringName:
	var eco := Game.economy
	if eco.is_bought(id):
		return &"bought"
	if not eco.is_visible(id):
		return &"locked"
	return &"affordable" if eco.state.energy >= eco.cost_of(id) else &"available"


func describe(id: StringName) -> String:
	if id == &"":
		return ""
	var eco := Game.economy
	if state_of(id) == &"locked":
		return tr("UI_LOCKED")
	var g := eco.config.find_generator(id)
	if g:
		return tr("UI_GENERATOR_ROW") % [tr(g.name_key), eco.owned(id), NumberFormat.per_click(eco.generator_click_bonus(id)),
			NumberFormat.rate(eco.generator_production(id)), NumberFormat.energy(eco.cost_of(id))]
	var u := eco.config.find_upgrade(id)
	var name := tr(u.name_key) if u.target_id == &"" else tr(u.name_key) % tr(eco.config.find_generator(u.target_id).name_key)
	var desc := tr(u.desc_key) if u.target_id == &"" else tr(u.desc_key) % tr(eco.config.find_generator(u.target_id).name_key)
	if eco.is_bought(id):
		return "%s: %s — %s" % [name, desc, tr("UI_BOUGHT")]
	return tr("UI_UPGRADE_ROW") % [name, desc, NumberFormat.energy(u.cost)]


func _add_node(id: StringName, pos: Vector2, icon: StringName) -> void:
	var b := Button.new()
	b.flat = true
	b.position = pos
	b.size = NODE
	b.focus_mode = FOCUS_ALL
	b.pressed.connect(func() -> void: buy_requested.emit(id))
	b.focus_entered.connect(func() -> void: _selected = id)
	b.mouse_entered.connect(func() -> void: _selected = id)
	add_child(b)
	_buttons[id] = b
	_icons[id] = load(ICONS + String(icon) + ".png")


func _parent_of(id: StringName) -> StringName:
	var config := Game.economy.config
	var g := config.find_generator(id)
	if g:
		# La cadena de generadores solo se dibuja: cada uno cuelga del anterior.
		var i := config.generators.find(g)
		return config.generators[i - 1].id if i > 0 else &""
	var u := config.find_upgrade(id)
	return u.requires_id if u else &""


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0b0e1a"))
	draw_rect(Rect2(2, 2, size.x - 4, size.y - 4), CHALK, false)
	draw_line(Vector2(4, 188), Vector2(size.x - 4, 188), DIM)
	var blink := fmod(Time.get_ticks_msec() / 1000.0, 0.8) < 0.5
	for id: StringName in _buttons:
		var parent := _parent_of(id)
		if parent != &"" and _buttons.has(parent):
			var lit := state_of(id) != &"locked"
			draw_line(_center(parent), _center(id), GOLD if lit else DIM)
	var font := get_theme_default_font()
	for id: StringName in _buttons:
		var b: Button = _buttons[id]
		var r := Rect2(b.position, NODE)
		var state := state_of(id)
		draw_rect(r, Color("1b2340"))
		var border: Color = {&"bought": GREEN, &"affordable": GOLD if blink else CHALK,
			&"available": CHALK, &"locked": DIM}[state]
		draw_rect(r, border, false)
		var icon: Texture2D = _icons[id]
		draw_texture(icon, r.position + Vector2(4, 4), Color(1, 1, 1, 0.25) if state == &"locked" else Color.WHITE)
		var count := Game.economy.owned(id)
		var tag := ""
		if String(id).ends_with("_x2_10"):
			tag = "x2"
		elif String(id).ends_with("_x2_25"):
			tag = "x4"
		elif count > 0:
			tag = str(count)
		if tag != "":
			# A la derecha del nodo, donde no pasan las ramas.
			draw_string(font, r.position + Vector2(r.size.x + 2, 9), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, GOLD)
		if b.has_focus() or id == _selected:
			draw_rect(r.grow(2), GOLD, false)


func _center(id: StringName) -> Vector2:
	return (_buttons[id] as Button).position + NODE / 2
