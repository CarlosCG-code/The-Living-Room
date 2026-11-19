class_name UpgradeTree
extends Control

# Árbol de mejoras (specs/incremental_v2.md §3): cada mejora es un nodo en su celda (tree_cell del .tres) unido
# a su padre. Se revela por anillos: solo se ve lo que cuelga de algo ya comprado; lo que aún no se puede
# comprar sale como «???». Se navega con el ratón o con las flechas, se compra con clic o Intro y se cierra con Esc.
# Solo pinta: lee Game.economy y pide las compras con buy_requested.

signal buy_requested(id: StringName)
signal close_requested

const NODE := Vector2(20, 20)
const ICONS := "res://assets/textures/tv/icon_"
# Rejilla de 10 × 5 celdas en la pantalla de 320 × 240 (esquina de la celda 0,0 y paso).
const GRID_ORIGIN := Vector2(8, 22)
const GRID_STEP := Vector2(31, 31)
const GENERATOR_ROW := 2
# Estilo: el menú de una tele de los 90 (OSD), desaturado (specs/incremental_v2.md §5): azul sucio de fondo,
# texto gris claro, selección en el ámbar de la luz, comprado en el verde del fósforo.
const CHALK := Color("c8d0dc")
const DIM := Color("2b3a5c")
const GOLD := Color("e0a048")
const GREEN := Color("9fd9ae")
const RED := Color("b0564a")
const MIST := Color("8a96ae")
const PANEL := Color("1c2a4a")
const BAR := Color("0f1729")
const TILE := Color("16223d")
## Los iconos usan la paleta nocturna del mundo: sobre el azul del menú se aclaran un poco.
const ICON_LIFT := Color(1.6, 1.6, 1.7)
const CARD_TOP := 180.0

var _buttons := {}  # StringName -> Button
var _icons := {}  # StringName -> Texture2D
var _selected: StringName = &""
var _card := {}  # "title" | "cost" | "body" | "effect" -> Label


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	var config := Game.economy.config
	for i in config.generators.size():
		var g := config.generators[i]
		_add_node(g.id, cell_position(Vector2i(i, GENERATOR_ROW)), g.id)
	for u in config.upgrades:
		_add_node(u.id, cell_position(u.tree_cell), u.icon)
	var title := Label.new()
	title.text = tr("UI_SHOP_TITLE").to_upper()
	title.position = Vector2(8, 3)
	title.add_theme_color_override(&"font_color", CHALK)
	add_child(title)
	var close := Button.new()
	close.text = tr("UI_CLOSE_HINT")
	close.flat = true
	close.add_theme_color_override(&"font_color", MIST)
	close.position = Vector2(246, -1)
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
		for id: StringName in _buttons:
			(_buttons[id] as Button).visible = is_revealed(id)
		queue_redraw()


static func cell_position(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2(cell) * GRID_STEP


## Se ve en el árbol (aunque sea como «???»): no tiene padre o su padre ya está comprado o poseído.
func is_revealed(id: StringName) -> bool:
	var parent := _parent_of(id)
	if parent == &"" or Game.economy.config.find_generator(id) != null:
		return true
	var u := Game.economy.config.find_upgrade(id)
	if u and u.req_perk != &"" and not Game.economy.state.perks.has(u.req_perk):
		return false  # la rama escondida no se insinúa: aparece de golpe al comprar la permanente
	return Game.economy.owned(parent) > 0 or Game.economy.is_bought(parent)


## Lleva el foco al primer nodo comprable (o al primero) para usar el teclado.
func focus_first() -> void:
	var eco := Game.economy
	for id: StringName in _buttons:
		if eco.is_visible(id) and not eco.is_bought(id):
			_buttons[id].grab_focus()
			return
	_buttons[Game.economy.config.generators[0].id].grab_focus()


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
		return tr(_locked_key(id))
	var c := card(id)
	return " — ".join(PackedStringArray([c.get("title", ""), c.get("body", ""), c.get("effect", ""), c.get("cost", "")]))


func _locked_key(id: StringName) -> String:
	var u := Game.economy.config.find_upgrade(id)
	return "UI_LOCKED_RUN" if u and u.req_run > Game.economy.state.run_index else "UI_LOCKED"


## Textos de la ficha: title, cost (y cost_color), body y effect.
func card(id: StringName) -> Dictionary:
	if id == &"":
		return {}
	var eco := Game.economy
	var state := state_of(id)
	if state == &"locked":
		return {"title": "???", "body": tr(_locked_key(id)), "cost_color": DIM}
	var cost_text := tr("UI_BOUGHT") if state == &"bought" else NumberFormat.energy(eco.cost_of(id))
	var cost_color: Color = {&"bought": GREEN, &"affordable": GOLD}.get(state, RED)
	var g := eco.config.find_generator(id)
	if g:
		return {"title": tr("UI_GENERATOR_TITLE") % [tr(g.name_key), eco.owned(id)], "cost": cost_text,
			"cost_color": cost_color, "body": tr(g.name_key + "_DESC"),
			"effect": tr("UI_EFFECT_OWNED") % [NumberFormat.per_click(eco.generator_click_bonus(id)),
				NumberFormat.rate(eco.generator_production(id))]}
	var u := eco.config.find_upgrade(id)
	var body := tr(u.desc_key)
	if u.warning_key != "" and state != &"bought":
		body += " " + tr(u.warning_key)
	return {"title": tr(u.name_key), "cost": cost_text, "cost_color": cost_color, "body": body,
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
		UpgradeDef.Kind.CRIT_CHANCE:
			var c := eco.mods.crit_chance * 100.0
			return tr("UI_EFFECT_CRIT") % [_num(c), _num(c + u.value * 100.0)]
		UpgradeDef.Kind.CRIT_MULT:
			return tr("UI_EFFECT_CRIT_MULT") % [_num(eco.mods.crit_mult), _num(u.value)]
		UpgradeDef.Kind.COMBO:
			return tr("UI_EFFECT_COMBO") % [_num(eco.mods.combo_max), _num(u.value)]
		UpgradeDef.Kind.SKILL:
			return tr("UI_EFFECT_SKILL") % [_num(u.duration), _num(u.cooldown)]
		UpgradeDef.Kind.PRODUCTION_MULT, UpgradeDef.Kind.GENERATOR_SYNERGY:
			var p := eco.production_per_second()
			var gain := eco.gain_if_bought(u.id, 0.0, false)
			return tr("UI_EFFECT_PROD") % [NumberFormat.rate(p), NumberFormat.rate(p + gain)]
		UpgradeDef.Kind.MANUAL_CLICK_MULT, UpgradeDef.Kind.CLICK_PER_OWNED, UpgradeDef.Kind.GENERATOR_CLICK_MULT:
			var now := eco.manual_click_value()
			var gain := eco.gain_if_bought(u.id, 1.0, false) / (1.0 + eco.auto_clicks_per_second(false))
			return tr("UI_EFFECT_CLICK") % [NumberFormat.per_click(now), NumberFormat.per_click(now + gain)]
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
	draw_rect(Rect2(0, 0, size.x, 14), BAR)
	var card_rect := Rect2(0, CARD_TOP, size.x, size.y - CARD_TOP)
	draw_rect(card_rect, BAR)
	draw_line(Vector2(0, CARD_TOP), Vector2(size.x, CARD_TOP), Color(MIST, 0.5))
	for id: StringName in _buttons:
		var parent := _parent_of(id)
		if parent != &"" and _buttons.has(parent) and is_revealed(id):
			var lit := state_of(id) != &"locked"
			draw_line(_center(parent), _center(id), Color(CHALK, 0.55) if lit else DIM)
	var font := get_theme_default_font()
	for id: StringName in _buttons:
		if not is_revealed(id):
			continue
		var b: Button = _buttons[id]
		var r := Rect2(b.position, NODE)
		var state := state_of(id)
		draw_rect(Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0.1, 0.5))  # sombra dura de OSD
		draw_rect(r, Color("2a3f5e") if state == &"bought" else TILE)
		var border: Color = {&"bought": GREEN, &"affordable": CHALK, &"available": Color(CHALK, 0.6),
			&"locked": DIM}[state]
		draw_rect(r, border, false)
		if state == &"locked":
			# Lo que aún no se puede comprar: solo se intuye.
			draw_string(font, r.position + Vector2(7, 14), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, MIST)
		else:
			draw_texture(_icons[id], r.position + Vector2(4, 4), ICON_LIFT)
		if state == &"affordable":
			draw_rect(Rect2(r.position + Vector2(r.size.x - 4, 1), Vector2(3, 3)), GOLD)  # se puede comprar
		var count := Game.economy.owned(id)
		if count > 0:
			# Unidades del generador, dentro del nodo abajo a la derecha (fuera pisaría la fila de abajo).
			var text := str(count)
			var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
			var at := r.end - Vector2(w + 1, 2)
			draw_rect(Rect2(at - Vector2(1, 7), Vector2(w + 2, 8)), Color(0, 0, 0.1, 0.8))
			draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, CHALK)
		if b.has_focus() or id == _selected:
			draw_rect(r.grow(2), GOLD, false)
			draw_rect(r.grow(3), Color(GOLD, 0.35), false)


func _center(id: StringName) -> Vector2:
	return (_buttons[id] as Button).position + NODE / 2
