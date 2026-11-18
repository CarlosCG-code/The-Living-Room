class_name CargaScreen
extends Control

# Pantalla tras pulsar Reiniciar (specs/incremental.md §5-6), con el estilo del menú azul de la tele:
# la Carga que tienes, las mejoras permanentes (en cualquier orden) y «Empezar la run N».
# Solo pinta: compra con Game.buy_perk y avisa con start_requested.

signal start_requested

const ROW_TOP := 34.0
const ROW_H := 29.0

var _carga: Label
var _rows := {}  # StringName -> {"button": Button, "desc": Label}
var _start: Button


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	position = Vector2.ZERO
	size = Vector2(320, 240)
	var title := _label(tr("UI_CARGA_TITLE"), Vector2(8, 3), UpgradeTree.CHALK)
	title.size.x = 120
	_carga = _label("", Vector2(160, 3), UpgradeTree.GOLD)
	_carga.size.x = 152
	_carga.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var y := ROW_TOP
	for p in Game.economy.config.perks:
		var b := Button.new()
		b.flat = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.position = Vector2(12, y)
		b.size = Vector2(296, 12)
		b.focus_mode = FOCUS_ALL
		b.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
		b.pressed.connect(_buy.bind(p.id))
		b.focus_entered.connect(queue_redraw)
		add_child(b)
		var desc := _label(tr(p.desc_key), Vector2(20, y + 12), UpgradeTree.MIST)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(288, 0)
		desc.size = Vector2(288, 18)
		desc.add_theme_constant_override(&"line_spacing", 0)
		_rows[p.id] = {"button": b, "desc": desc}
		y += ROW_H
	_start = Button.new()
	_start.flat = true
	_start.focus_mode = FOCUS_ALL
	_start.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	_start.add_theme_color_override(&"font_color", UpgradeTree.CHALK)
	_start.add_theme_color_override(&"font_focus_color", UpgradeTree.GOLD)
	_start.position = Vector2(0, 216)
	_start.size = Vector2(320, 16)
	_start.pressed.connect(start_requested.emit)
	_start.focus_entered.connect(queue_redraw)
	add_child(_start)


## Al abrirse: pone los textos y el foco en la primera mejora que se pueda pagar, si no en Empezar.
func open() -> void:
	show()
	_refresh()
	_focus_next()


func _buy(id: StringName) -> void:
	if Game.buy_perk(id):
		_refresh()
		_focus_next()


func _affordable(p: PerkDef) -> bool:
	return not Game.economy.has_perk(p.id) and Game.economy.state.carga >= p.cost


func _focus_next() -> void:
	for p in Game.economy.config.perks:
		if _affordable(p):
			(_rows[p.id]["button"] as Button).grab_focus()
			return
	_start.grab_focus()


func _refresh() -> void:
	var eco := Game.economy
	_carga.text = tr("UI_CARGA") % eco.state.carga
	_start.text = tr("UI_START_RUN") % eco.state.run_index
	for p in eco.config.perks:
		var b: Button = _rows[p.id]["button"]
		var bought := eco.has_perk(p.id)
		var cost := tr("UI_BOUGHT") if bought else tr("UI_CARGA_COST") % p.cost
		b.text = "%s  ·  %s" % [tr(p.name_key), cost]
		var color: Color = UpgradeTree.GREEN if bought else (UpgradeTree.CHALK if _affordable(p) else UpgradeTree.MIST)
		b.add_theme_color_override(&"font_color", color)
		b.add_theme_color_override(&"font_focus_color", UpgradeTree.GOLD)
		b.add_theme_color_override(&"font_hover_color", UpgradeTree.GOLD)
		(_rows[p.id]["desc"] as Label).modulate.a = 1.0 if bought or _affordable(p) else 0.5
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UpgradeTree.PANEL)
	draw_rect(Rect2(0, 0, size.x, 14), UpgradeTree.BAR)
	draw_rect(Rect2(0, 210, size.x, 30), UpgradeTree.BAR)
	draw_line(Vector2(0, 210), Vector2(size.x, 210), Color(UpgradeTree.MIST, 0.5))
	# Un punto por mejora: lleno si está comprada, hueco si aún no.
	var eco := Game.economy
	var x := 8.0
	var y := ROW_TOP + 6.0
	for i in eco.config.perks.size():
		var p: PerkDef = eco.config.perks[i]
		var dot := Rect2(x - 2, y - 2, 5, 5)
		if eco.has_perk(p.id):
			draw_rect(dot, UpgradeTree.GREEN)
		else:
			draw_rect(dot, UpgradeTree.CHALK if _affordable(p) else UpgradeTree.DIM, false)
		var b: Button = _rows[p.id]["button"]
		if b.has_focus():
			draw_rect(Rect2(10, y - 7, 300, ROW_H - 2), Color(UpgradeTree.GOLD, 0.12))
		y += ROW_H
	if _start.has_focus():
		draw_rect(Rect2(0, 214, size.x, 20), Color(UpgradeTree.GOLD, 0.12))


func get_start_button() -> Button:
	return _start


func _label(text: String, pos: Vector2, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.mouse_filter = MOUSE_FILTER_IGNORE
	l.add_theme_color_override(&"font_color", color)
	add_child(l)
	return l
