extends Control

# Solo pinta: lee Game.economy y reenvía la entrada a Game. Sin lógica de juego.
# La tele empieza en el menú principal (canal del menú); «Jugar» cambia de canal con nieve y pasa al
# incremental. «Menú principal» en la pausa hace lo contrario. Todo en la misma escena del salón.
# Pantalla de 320 × 240 en pixel art (specs/hito2.md D19): la fábrica ocupa toda la pantalla, arriba una
# barra con los datos y el árbol de mejoras se abre encima al pulsar la fábrica (o con E).
# Teclado: Espacio sintoniza (mantenerlo = mantener pulsado), E abre o cierra las mejoras, Esc las cierra,
# flechas e Intro se mueven por el árbol y compran.

const CHANNEL_CHANGE := 0.4  # segundos de nieve al cambiar de canal

@onready var _osd: TvOsd = $Osd
@onready var _factory: FactoryView = $FactoryView
@onready var _tree: UpgradeTree = $UpgradeTree
@onready var _purchase_sound: AudioStreamPlayer = $PurchaseSound

const CLICK_SOUND := preload("res://assets/audio/tv/click_relay.wav")
var _click_sound: AudioStreamPlayer
var _shake: Tween

var _menu: MainMenuUI
var _pause: MainMenuUI
var _static: ColorRect
var _card_open := false  # carta de fin de la emisión en pantalla
var _carga: CargaScreen


func _ready() -> void:
	_osd.restart_pressed.connect(_restart)
	_osd.skill_pressed.connect(func(skill: StringName) -> void: Game.use_skill(skill))
	_factory.package_pressed.connect(_open_package)
	_factory.generator_shown.connect(func(id: StringName) -> void:
		var g := Game.economy.config.find_generator(id)
		_osd.notify("+ " + tr(g.name_key)))
	_factory.machine_pressed.connect(_click)
	_factory.hold_changed.connect(Game.set_holding)
	_factory.shop_requested.connect(_open_shop)
	_factory.event_pressed.connect(Game.catch_event)
	# Cada evento suena siempre igual: el jugador aprende a girarse hacia la tele al oírlo.
	var event_sound := AudioStreamPlayer.new()
	event_sound.volume_db = -6.0
	add_child(event_sound)
	_factory.event_started.connect(func(id: StringName) -> void:
		var path := "res://assets/audio/tv/event_%s.wav" % id
		if ResourceLoader.exists(path):
			event_sound.stream = load(path)
			event_sound.play())
	_tree.buy_requested.connect(Game.buy)
	_tree.close_requested.connect(_close_shop)
	EventBus.purchase_made.connect(func(_id: StringName) -> void:
		_purchase_sound.play()
		shake(2))
	_click_sound = AudioStreamPlayer.new()
	_click_sound.stream = CLICK_SOUND
	_click_sound.volume_db = -10.0
	_click_sound.max_polyphony = 4
	add_child(_click_sound)
	_carga = CargaScreen.new()
	_carga.hide()
	add_child(_carga)
	_carga.start_requested.connect(func() -> void:
		_carga.hide()
		Game.set_holding(false)  # Espacio pudo quedarse pulsado durante la carta
		Game.running = true)
	_pause = (load("res://presentation/ui/main_menu_ui.tscn") as PackedScene).instantiate()
	_pause.pause_menu = true
	_pause.name = "PauseMenu"
	_pause.hide()
	add_child(_pause)
	_pause.resume_requested.connect(close_pause)
	_pause.menu_requested.connect(func() -> void: _change_channel(_show_menu))
	_pause.quit_requested.connect(_quit)
	_menu = (load("res://presentation/ui/main_menu_ui.tscn") as PackedScene).instantiate()
	_menu.name = "TvMenu"
	_menu.hide()
	add_child(_menu)
	_menu.play_requested.connect(func() -> void: _change_channel(_start_playing))
	_menu.quit_requested.connect(_quit)
	_static = ColorRect.new()
	_static.name = "Static"
	_static.size = Vector2(320, 240)
	_static.mouse_filter = MOUSE_FILTER_STOP  # durante la nieve no se puede clicar nada
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://presentation/ui/tv_static.gdshader")
	_static.material = mat
	_static.hide()
	add_child(_static)


## Arranque del juego: la tele muestra el menú y la partida está parada.
func start_in_menu() -> void:
	_show_menu()


## Arranque directo a la partida (capturas y benchmark).
func start_playing() -> void:
	_start_playing()


func is_in_menu() -> bool:
	return _menu.visible


func _show_menu() -> void:
	Game.set_holding(false)
	Game.running = false
	_pause.hide()
	_tree.hide()
	_osd.hide_intro()
	_menu.show()
	_menu.show_main()
	EventBus.tv_menu_changed.emit(true)


func _start_playing() -> void:
	_menu.hide()
	Game.running = true
	EventBus.tv_menu_changed.emit(false)
	# Partida nueva: carta de ajuste con lo básico (se va con el primer clic).
	if Game.economy.state.run_index == 1 and Game.economy.state.energy_produced_run == 0.0:
		_osd.show_intro(tr("UI_INTRO"))


## Cambio de canal: nieve un instante y después lo que toque.
func _change_channel(then: Callable) -> void:
	_static.show()
	await get_tree().create_timer(CHANNEL_CHANGE).timeout
	then.call()
	_static.hide()


# Salir pasa por el cierre normal: Game guarda la partida antes de cerrar.
func _quit() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _process(_delta: float) -> void:
	var eco := Game.economy
	var state := eco.state
	_osd.show_values(NumberFormat.energy(state.energy), NumberFormat.rate(eco.production_per_second()),
		NumberFormat.per_click(eco.click_value()), state.energy_produced_run / eco.threshold(),
		eco.carga_if_restarted() if eco.can_restart() else -1, not _tree.visible and _has_affordable(eco),
		NumberFormat.energy(eco.next_carga_at()) if eco.can_restart() else "")
	var skills := {}
	for skill: StringName in TvOsd.SKILLS:
		if eco.has_skill(skill):
			var u: UpgradeDef = eco.mods.skills[skill]
			skills[skill] = [eco.skill_cooldown(skill) / u.cooldown, eco.timer(skill) > 0.0]
	_osd.show_extras(eco.bar_fraction() if eco.mods.packages else -1.0, eco.combo_fraction(), skills)


func _unhandled_input(event: InputEvent) -> void:
	if _pause.visible or _carga.visible or _menu.visible or _static.visible or _card_open:
		return
	if event.is_action_pressed("ui_cancel") and not _tree.visible:
		open_pause()
		get_viewport().set_input_as_handled()
		return
	if _tree.visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("tv_shop"):
			_close_shop()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("tv_shop"):
		_open_shop()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo 			and event.keycode >= KEY_1 and event.keycode < KEY_1 + TvOsd.SKILLS.size():
		Game.use_skill(TvOsd.SKILLS[event.keycode - KEY_1])  # habilidades del mando: teclas 1-4
		get_viewport().set_input_as_handled()
	elif event.is_action("tv_click") and not event.is_echo():
		if event.is_pressed():
			_click(_factory.press_receptor())
		Game.set_holding(event.is_pressed())
		get_viewport().set_input_as_handled()


## Abre la cinta del hueco slot y enseña lo que da (Energía, o el ×3 de la cinta negra).
func _open_package(slot: int) -> void:
	var packages := Game.economy.packages()
	for i in packages.size():
		if packages[i]["slot"] == slot:
			var rarity: int = packages[i]["rarity"]
			var amount := Game.open_package(i)
			var at := _factory.get_tape(slot).position + Vector2(12, 0)
			var text := ("×%d" % int(Game.economy.config.black_mult)) if rarity == Economy.Rarity.BLACK 				else "+" + NumberFormat.energy(amount)
			_factory.float_text(at, text, rarity != Economy.Rarity.COMMON)
			shake(3 if rarity == Economy.Rarity.BLACK else 2)
			return


## Reiniciar: la run nueva espera parada mientras se gasta la Carga.
func _restart() -> void:
	_close_shop()
	if Game.restart():
		Game.set_holding(false)
		Game.running = false
		await _end_of_broadcast()
		_carga.open()


## Carta de «fin de la emisión» con un tono de prueba que desafina, antes de la pantalla de Carga.
func _end_of_broadcast() -> void:
	var card := EndOfBroadcast.new()
	_card_open = true
	add_child(card)
	var tone := AudioStreamPlayer.new()
	tone.stream = preload("res://assets/audio/tv/test_tone.wav")
	tone.volume_db = -14.0
	card.add_child(tone)
	tone.play()
	await get_tree().create_timer(EndOfBroadcast.DURATION).timeout
	card.queue_free()
	_card_open = false


func is_restarting() -> bool:
	return _carga.visible


func _click(at: Vector2) -> void:
	if not Game.running:
		return  # menú, pausa, carta o Carga: la partida está parada y el clic no cuenta
	_osd.hide_intro()
	var amount := Game.click()
	if amount <= 0.0:
		return  # por encima del tope de clics por segundo: no cuenta ni se ve
	# Lo ganado de verdad (con Tu pulso, racha y crítico), no el valor base del clic.
	var crit := Game.economy.last_click_crit
	_factory.float_text(at, "+" + NumberFormat.per_click(amount), crit)
	_factory.click_burst(at + Vector2(0, 6), crit)
	# Relé: el tono varía un poco en cada clic y sube con la racha; el crítico suena más grave.
	_click_sound.pitch_scale = (0.8 if crit else 1.0) * randf_range(0.94, 1.06) * (1.0 + 0.12 * Game.economy.combo_fraction())
	_click_sound.play()
	if crit:
		shake(1)


## Sacude la imagen de la tele px píxeles enteros un instante (compras, críticos, cintas). Solo la imagen:
## la cámara no se mueve.
func shake(px: int) -> void:
	if _shake:
		_shake.kill()
	position = Vector2.ZERO
	_shake = create_tween()
	for i in 3:
		_shake.tween_property(self, "position", Vector2(randi_range(-px, px), randi_range(-px, px)), 0.04)
	_shake.tween_property(self, "position", Vector2.ZERO, 0.04)


## Esc durante la partida: la partida se para y la tele muestra el menú de pausa.
func open_pause() -> void:
	Game.set_holding(false)
	Game.running = false
	_pause.show()
	_pause.show_main()


func close_pause() -> void:
	_pause.hide()
	Game.running = true


func is_paused() -> bool:
	return _pause.visible


func _open_shop() -> void:
	Game.set_holding(false)
	_tree.show()
	_tree.focus_first()


func _close_shop() -> void:
	_tree.hide()


func _has_affordable(eco: Economy) -> bool:
	for g in eco.visible_generators():
		if eco.state.energy >= eco.cost_of(g.id):
			return true
	for u in eco.visible_upgrades():
		if eco.state.energy >= u.cost:
			return true
	return false
