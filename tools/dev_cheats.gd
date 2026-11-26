extends CanvasLayer

# Trucos para probar el juego (petición del usuario, 2026-11-19). Solo en la build de depuración: lo carga DevBoot y
# tools/ no se exporta (sin class_name: la build no debe conocerlo). F1 lo abre y lo cierra. Herramienta de desarrollo: sus textos no pasan por tr().

const TOGGLE_KEY := KEY_F1
## El panel se diseña para 1080 de alto y se escala a la ventana (en 4K salía diminuto).
const DESIGN_HEIGHT := 1080.0
const WIDTH := 560.0
const RARITY_NAMES := ["común", "rara", "negra"]

var _panel: PanelContainer
var _status: Label
var _box: VBoxContainer
## Cámara libre para revisar el salón (usuario, 2026-11-19): sin colisiones, a propósito, para mirar de cerca.
var _fly: Camera3D
var _fly_prev: Camera3D
const FLY_SPEED := 1.4
## Radianes por píxel de ratón; F1 la cambia (usuario, 2026-11-20: era demasiado alta).
var look_sens := 0.0012


func _ready() -> void:
	name = "DevCheats"
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS  # también con el menú de pausa abierto
	_panel = PanelContainer.new()
	_panel.position = Vector2(12, 12)
	_panel.custom_minimum_size = Vector2(WIDTH, 0)
	_panel.visible = false
	var theme := Theme.new()
	theme.default_font_size = 18
	_panel.theme = theme
	add_child(_panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(WIDTH, DESIGN_HEIGHT - 40.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)
	_box = VBoxContainer.new()
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_box)
	# Aviso fijo: si no se ve, no es la versión de pruebas (la build de build/ no trae trucos).
	var hint := Label.new()
	hint.name = "Hint"
	hint.text = "MODO PRUEBAS · F1: trucos"
	hint.modulate.a = 0.6
	hint.position = Vector2(12, DESIGN_HEIGHT - 40.0)
	add_child(hint)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(_status)
	_build()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == TOGGLE_KEY:
		_panel.visible = not _panel.visible
		if _fly:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _panel.visible else Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	elif _fly and event.is_action_pressed("ui_cancel"):
		_toggle_fly()
		get_viewport().set_input_as_handled()
	elif _fly and not _panel.visible and event is InputEventMouse:
		if event is InputEventMouseMotion:
			var r: Vector2 = (event as InputEventMouseMotion).relative * look_sens
			_fly.rotate_y(-r.x)
			_fly.rotation.x = clampf(_fly.rotation.x - r.y, -1.5, 1.5)
		get_viewport().set_input_as_handled()  # la tele no debe recibir clics mientras se vuela


func _process(delta: float) -> void:
	scale = Vector2.ONE * get_viewport().get_visible_rect().size.y / DESIGN_HEIGHT
	if _fly and not _panel.visible:
		_fly_step(delta / maxf(Engine.time_scale, 0.001))
	if not _panel.visible:
		return
	var eco := Game.economy
	var s := eco.state
	_status.text = "TRUCOS (F1)\nRun %d · Energía %s · producida %s / %s (%.0f %%) · progreso %.2f\nCarga %d · permanentes %s\nMejoras %d · evento: %s · cintas %d · tiempo ×%s · partida %s\nSensibilidad del ratón: %.1f" % [
		s.run_index, NumberFormat.energy(s.energy), NumberFormat.energy(s.energy_produced_run),
		NumberFormat.energy(eco.threshold()), 100.0 * s.energy_produced_run / eco.threshold(), eco.run_progress(), s.carga,
		", ".join(PackedStringArray(s.perks)), s.upgrades.size(),
		String(s.event_id) if s.event_id != &"" else "-", eco.packages().size(), Engine.time_scale,
		"en marcha" if Game.running else "parada", look_sens * 1000.0]


func _build() -> void:
	_section("Atajos")
	_row([["Levantarse y moverse (WASD, ratón, Espacio/C, Mayús; Esc vuelve)", _toggle_fly]])
	_row([["Sensibilidad −", func() -> void: look_sens = maxf(look_sens / 1.5, 0.0002)],
		["Sensibilidad +", func() -> void: look_sens = minf(look_sens * 1.5, 0.01)]])
	_row([["Jugar ya (sin menú)", _play], ["Abrir árbol", _open_tree]])
	_row([["Desbloquear todo el árbol", _reveal_all], ["Comprarlo todo", _buy_everything]])
	_section("Empezar una run (con las permanentes que tengas)")
	_row([["Mitad de la run 1", _half_run], ["Run 1", _start_run.bind(1)], ["Run 2", _start_run.bind(2)], ["Run 3", _start_run.bind(3)], ["Run 4", _start_run.bind(4)]])
	_section("Energía")
	_row([["+1 min de ingresos", func() -> void: _give(maxf(eco_income(), 10.0) * 60.0)],
		["+10 min", func() -> void: _give(maxf(eco_income(), 10.0) * 600.0)]])
	_row([["+1 K", func() -> void: _give(1e3)], ["+1 M", func() -> void: _give(1e6)],
		["+1 G", func() -> void: _give(1e9)]])
	_row([["Al 50 % del umbral", func() -> void: _to_ratio(0.5)], ["Al umbral", func() -> void: _to_ratio(1.0)],
		["Al ×4 del umbral", func() -> void: _to_ratio(4.0)]])
	_section("Compras")
	_row([["Comprar todo lo visible", _buy_all], ["+10 de cada máquina", _add_machines]])
	_section("Runs y Carga")
	_row([["Reiniciar ya", _restart_now], ["+5 Carga", func() -> void: Game.economy.state.carga += 5],
		["Siguiente paso de la secuencia", _next_step]])
	_row([["Todas las permanentes", _all_perks], ["Quitar permanentes", _no_perks]])
	_section("Eventos y cintas")
	var events: Array = []
	for e in Game.economy.config.events:
		events.append([String(e.id), _start_event.bind(e.id)])
	_row(events)
	_row([["Cinta común", _drop.bind(0)], ["Cinta rara", _drop.bind(1)], ["Cinta negra", _drop.bind(2)]])
	_row([["Quitar enfriamientos", _clear_cooldowns], ["Llenar barra de cinta", _fill_bar]])
	_section("Director: suceso ya")
	var fear: Array = []
	for def in (load(Game.FEAR_EVENTS_PATH) as FearEventSet).events:
		fear.append([String(def.id), Game.director.force.bind(def.id)])
	_row(fear)
	_section("Tiempo")
	_row([["×1", _speed.bind(1.0)], ["×5", _speed.bind(5.0)], ["×20", _speed.bind(20.0)], ["×60", _speed.bind(60.0)]])
	_section("Salón (recarga la escena)")
	_row([["Normal", _room.bind("0", "0")], ["Espejo", _room.bind("1", "0")], ["A oscuras", _room.bind("0", "1")],
		["Espejo y oscuras", _room.bind("1", "1")]])
	_section("Partida")
	_row([["Partida nueva", _new_game], ["Guardar ahora", func() -> void: Game._save()]])
	# Para dar con fallos que solo se ven jugando (espejo que parpadea al moverse, 2026-11-22). Se pierde al cambiar
	# ajustes o preset: GraphicsSettings los vuelve a aplicar.
	_section("Diagnóstico de gráficos (alterna; se pierde al cambiar ajustes)")
	var vp := get_viewport()
	var env := func() -> Object: return vp.find_world_3d().environment if vp.find_world_3d() else null
	var view := func() -> Object: return vp
	_toggles([["TAA", view, "use_taa"], ["Oclusión", view, "use_occlusion_culling"],
		["Niebla", env, "volumetric_fog_enabled"], ["Niebla temporal", env, "volumetric_fog_temporal_reprojection_enabled"],
		["SSIL", env, "ssil_enabled"], ["SSAO", env, "ssao_enabled"], ["Brillo (glow)", env, "glow_enabled"]])


func _section(title: String) -> void:
	var l := Label.new()
	l.text = "— " + title
	_box.add_child(l)


# Botones de sí/no: [nombre, objeto: Callable -> Object, propiedad bool]; el texto dice el estado actual («?» si
# el objeto aún no existe, p. ej. el entorno antes de cargar el salón).
func _toggles(items: Array) -> void:
	var row := HFlowContainer.new()
	for it: Array in items:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		var label := func() -> void:
			var o: Object = it[1].call()
			button.text = "%s: %s" % [it[0], "?" if o == null else ("sí" if o.get(it[2]) else "no")]
		button.pressed.connect(func() -> void:
			var o: Object = it[1].call()
			if o:
				o.set(it[2], not o.get(it[2]))
			label.call())
		button.visibility_changed.connect(label)  # al abrir el menú, el estado real (los ajustes pueden haberlo cambiado)
		label.call()
		row.add_child(button)
	_box.add_child(row)


func _row(buttons: Array) -> void:
	var row := HFlowContainer.new()
	for b: Array in buttons:
		var button := Button.new()
		button.text = b[0]
		button.focus_mode = Control.FOCUS_NONE  # Espacio es el clic de la tele: no debe pulsar el último botón
		button.pressed.connect(b[1])
		row.add_child(button)
	_box.add_child(row)


func eco_income() -> float:
	return Game.economy.income_now()


# Los argumentos sin tipo: GoPeak (call_runtime_method) los pasa como texto y así Claude también puede usarlos.
func _give(value) -> void:
	var amount := float(value)
	Game.economy.state.energy += amount
	Game.economy.state.energy_produced_run += amount


func _to_ratio(value) -> void:
	var ratio := float(value)
	var missing := ratio * Game.economy.threshold() - Game.economy.state.energy_produced_run
	if missing > 0.0:
		_give(missing)


func _buy_all() -> void:
	var eco := Game.economy
	for u in eco.visible_upgrades():
		eco.state.energy = maxf(eco.state.energy, eco.cost_of(u.id))
		eco.buy(u.id)


func _add_machines() -> void:
	var eco := Game.economy
	for g in eco.config.generators:
		eco.state.generators[g.id] = eco.owned(g.id) + 10
	eco._recalc()
	EventBus.purchase_made.emit(eco.config.generators[0].id)  # la fábrica de la tele redibuja sus máquinas


## Como pulsar Reiniciar: carta de fin de la emisión y pantalla de Carga (si no hay partida en pantalla, directo).
func _restart_now() -> void:
	_to_ratio(1.0)
	var ui := _ui()
	if ui and Game.running:
		ui._restart()
	else:
		Game.restart()


## Da por hecho el paso de la secuencia en curso (specs/hito4b.md D17).
func _next_step() -> void:
	var done := {&"knock": &"handed_over", &"dark": &"fuse_fixed", &"free": &"sat", &"fixed": &"sat"}
	Game.sequence_done(done.get(Game.economy.state.step, &""))


func _set_run(value) -> void:
	var run := int(value)
	Game.economy.state.run_index = run
	Game.economy._recalc()


## Como tras reiniciar: run nueva con la Carga y las permanentes de ahora.
func _start_run(value) -> void:
	var run := int(value)
	var eco := Game.economy
	var old := eco.state
	eco.state = RunState.new_run(eco.config, run, RandomNumberGenerator.new())
	eco.state.carga = old.carga
	eco.state.perks = old.perks.duplicate()
	eco.state.evidence = old.evidence.duplicate()
	eco.packages().clear()
	for id in old.perks:
		eco._grant_start(eco.config.find_perk(id))
	eco._recalc()
	EventBus.run_restarted.emit(run)
	_play()


## La mitad de la run 1, con sus máquinas ya compradas (el director las da por hechas).
func _half_run() -> void:
	_start_run(1)
	var eco := Game.economy
	for g in eco.config.generators.slice(0, 5):
		eco.state.generators[g.id] = 5
	_give(sqrt(Economy.PROGRESS_FROM * eco.threshold()))
	eco._recalc()


## Cumple los requisitos de todo el árbol (clics, cintas, eventos, máquinas, permanentes) sin comprar nada.
func _reveal_all() -> void:
	var eco := Game.economy
	_set_run(4)
	_all_perks()
	eco.state.manual_clicks = maxi(eco.state.manual_clicks, 100000)
	eco.state.packages_opened = maxi(eco.state.packages_opened, 1000)
	eco.state.events_caught = maxi(eco.state.events_caught, 1000)
	for g in eco.config.generators:
		eco.state.generators[g.id] = maxi(eco.owned(g.id), 30)
	_to_ratio(1.0)
	eco._recalc()


## Todo el árbol comprado, rama a rama (cada compra abre la siguiente).
func _buy_everything() -> void:
	_reveal_all()
	var before := -1
	while Game.economy.state.upgrades.size() != before:
		before = Game.economy.state.upgrades.size()
		_buy_all()


func _ui() -> Node:
	for n in get_tree().root.find_children("*", "Control", true, false):
		if n.has_method("start_playing") and n.has_method("open_pause"):
			return n
	return null


## A jugar desde donde esté la tele: cierra menú, pausa, árbol y pantalla de Carga.
func _play() -> void:
	var ui := _ui()
	if ui == null:
		return
	ui._carga.hide()
	ui._pause.hide()
	ui._close_shop()
	ui.start_playing()


func _open_tree() -> void:
	_play()
	var ui := _ui()
	if ui:
		ui._open_shop()


func _all_perks() -> void:
	var eco := Game.economy
	for p in eco.config.perks:
		eco.state.carga = maxi(eco.state.carga, p.cost)
		eco.buy_perk(p.id)


func _no_perks() -> void:
	Game.economy.state.perks.clear()
	Game.economy._recalc()


func _start_event(value) -> void:
	var id := StringName(value)
	var eco := Game.economy
	var e := eco.config.find_event(id)
	eco.state.event_id = id
	eco.state.event_left = e.duration


func _drop(value) -> void:
	var rarity := int(value)
	var eco := Game.economy
	if eco.packages().size() >= Economy.MAX_PACKAGES:
		return
	var used := eco.packages().map(func(p: Dictionary) -> int: return p["slot"])
	eco.packages().append({"rarity": rarity, "left": Economy.PACKAGE_LIFE, "slot": 0 if not used.has(0) else 1})
	eco.package_dropped.emit(rarity)


func _clear_cooldowns() -> void:
	var timers := Game.economy.state.timers
	for key: String in timers.keys():
		if key.begins_with("cd_"):
			timers.erase(key)


func _fill_bar() -> void:
	var eco := Game.economy
	eco.state.package_bar = eco.bar_size() - 0.01


func _speed(value) -> void:
	var factor := float(value)
	Engine.time_scale = factor


# Las variantes del salón se eligen al crear la escena (TLR_MIRROR, TLR_DARK): se fijan y se recarga.
func _room(mirror: String, dark: String) -> void:
	OS.set_environment("TLR_MIRROR", mirror)
	OS.set_environment("TLR_DARK", dark)
	OS.set_environment("TLR_SKIP_MENU", "1")
	get_tree().reload_current_scene()


func _new_game() -> void:
	var eco := Game.economy
	eco.state = RunState.new_run(eco.config, 1, RandomNumberGenerator.new())
	eco.packages().clear()
	eco._recalc()
	Engine.time_scale = 1.0
	Game._save()


func _toggle_fly() -> void:
	if _fly:
		if is_instance_valid(_fly_prev):
			_fly_prev.make_current()
		_fly.queue_free()
		_fly = null
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	_fly_prev = get_viewport().get_camera_3d()
	if _fly_prev == null:
		return
	_fly = Camera3D.new()
	_fly.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF  # se mueve en _process
	_fly.name = "FlyCamera"
	_fly.fov = 70.0
	_fly_prev.get_parent().add_child(_fly)
	_fly.global_position = _fly_prev.global_position
	_fly.rotation = Vector3(_fly_prev.global_rotation.x, _fly_prev.global_rotation.y, 0.0)
	_fly.make_current()
	_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _fly_step(delta: float) -> void:
	var b := _fly.global_basis
	var v := Vector3.ZERO
	for pair: Array in [[KEY_W, -b.z], [KEY_S, b.z], [KEY_A, -b.x], [KEY_D, b.x], [KEY_SPACE, Vector3.UP], [KEY_C, Vector3.DOWN]]:
		if Input.is_physical_key_pressed(pair[0]):
			v += pair[1]
	var speed := FLY_SPEED * (3.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 1.0)
	_fly.global_position += v.normalized() * speed * delta
