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
const CHALK := Color("c9d0e0")
const DIM := Color("2c3350")
const GOLD := Color("e0b85a")
const GREEN := Color("62c47a")
const RED := Color("b0484a")
const MIST := Color("7d8fb0")
const PANEL := Color("06070c")
const CARD_TOP := 180.0

var _buttons := {}  # StringName -> Button
var _icons := {}  # StringName -> Texture2D
var _selected: StringName = &""
var _card := {}  # "title" | "cost" | "body" | "effect" -> Label


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
	# Ficha de la mejora seleccionada: nombre y coste, descripción y efecto con números.
	for key: String in ["title", "cost", "body", "effect"]:
		var l := Label.new()
		l.size = Vector2(296, 10)
		l.position = Vector2(12, {"title": CARD_TOP + 4, "cost": CARD_TOP + 4, "body": CARD_TOP + 16,
			"effect": CARD_TOP + 40}[key])
		l.add_theme_color_override(&"font_color", {"title": GOLD, "body": CHALK, "effect": MIST}.get(key, CHALK))
		_card[key] = l
		add_child(l)
	(_card["cost"] as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	(_card["body"] as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	(_card["body"] as Label).size.y = 26


func _process(_delta: float) -> void:
	if visible:
		var c := card(_selected)
		for key: String in _card:
			(_card[key] as Label).text = c.get(key, "")
		(_card["cost"] as Label).add_theme_color_override(&"font_color", c.get("cost_color", CHALK))
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
	if id != &"" and state_of(id) == &"locked":
		return tr("UI_LOCKED")
	var c := card(id)
	return " — ".join(PackedStringArray([c.get("title", ""), c.get("body", ""), c.get("effect", ""), c.get("cost", "")]))


## Textos de la ficha: title, cost (y cost_color), body y effect.
func card(id: StringName) -> Dictionary:
	if id == &"":
		return {}
	var eco := Game.economy
	var state := state_of(id)
	if state == &"locked":
		return {"title": "???", "body": tr("UI_LOCKED"), "cost_color": DIM}
	var cost_text := tr("UI_BOUGHT") if state == &"bought" else NumberFormat.energy(eco.cost_of(id))
	var cost_color: Color = {&"bought": GREEN, &"affordable": GOLD}.get(state, RED)
	var g := eco.config.find_generator(id)
	if g:
		return {"title": tr("UI_GENERATOR_TITLE") % [tr(g.name_key), eco.owned(id)], "cost": cost_text,
			"cost_color": cost_color, "body": tr(g.name_key + "_DESC"),
			"effect": tr("UI_EFFECT_OWNED") % [NumberFormat.per_click(eco.generator_click_bonus(id)),
				NumberFormat.rate(eco.generator_production(id))]}
	var u := eco.config.find_upgrade(id)
	var target := tr(eco.config.find_generator(u.target_id).name_key) if u.target_id != &"" else ""
	var title := tr(u.name_key) % target if target != "" else tr(u.name_key)
	var body := tr(u.desc_key) % target if target != "" else tr(u.desc_key)
	return {"title": title, "cost": cost_text, "cost_color": cost_color, "body": body,
		"effect": "" if state == &"bought" else _effect(u)}


## Qué cambia al comprarla, con los números de ahora.
func _effect(u: UpgradeDef) -> String:
	var eco := Game.economy
	match u.kind:
		UpgradeDef.Kind.GENERATOR_MULT:
			var c := eco.generator_click_bonus(u.target_id)
			var p := eco.generator_production(u.target_id)
			return tr("UI_EFFECT_GEN") % [NumberFormat.per_click(c), NumberFormat.per_click(c * u.value),
				NumberFormat.rate(p), NumberFormat.rate(p * u.value)]
		UpgradeDef.Kind.CLICK_MULT, UpgradeDef.Kind.CLICK_PRODUCTION_SHARE:
			# Con 1 clic/s a mano, lo que sube la Energía/s es lo que sube cada clic por todos los clics.
			var now := eco.click_value()
			var gain := eco.gain_if_bought(u.id, 1.0, false) / (1.0 + eco.auto_clicks_per_second(false))
			return tr("UI_EFFECT_CLICK") % [NumberFormat.per_click(now), NumberFormat.per_click(now + gain)]
		UpgradeDef.Kind.HOLD_RATE:
			return tr("UI_EFFECT_HOLD") % _num(u.value)
		UpgradeDef.Kind.AUTO_CLICK_RATE:
			return tr("UI_EFFECT_AUTO") % [_num(eco.auto_clicks_per_second(false)), _num(u.value)]
	return ""


## 6 → "6", 2.5 → "2,5".
func _num(x: float) -> String:
	return ("%.1f" % x).trim_suffix(".0").replace(".", ",")


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
	draw_rect(Rect2(Vector2.ZERO, size), PANEL)
	# Marco doble apagado y esquinas marcadas, como una placa vieja atornillada.
	draw_rect(Rect2(2, 2, size.x - 4, size.y - 4), DIM, false)
	draw_rect(Rect2(4, 4, size.x - 8, size.y - 8), Color(DIM, 0.5), false)
	for corner: Vector2 in [Vector2(2, 2), Vector2(size.x - 5, 2), Vector2(2, size.y - 5), Vector2(size.x - 5, size.y - 5)]:
		draw_rect(Rect2(corner, Vector2(3, 3)), MIST)
	var card_rect := Rect2(8, CARD_TOP, size.x - 16, size.y - CARD_TOP - 8)
	draw_rect(card_rect, Color("0d1019"))
	draw_rect(card_rect, Color(GOLD, 0.35) if _selected != &"" else DIM, false)
	draw_line(card_rect.position + Vector2(4, 14), Vector2(card_rect.end.x - 4, card_rect.position.y + 14), DIM)
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
		draw_rect(r.grow(1), Color(0, 0, 0, 0.6))  # sombra
		draw_rect(r, Color("10142a") if state != &"locked" else Color("090b14"))
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
