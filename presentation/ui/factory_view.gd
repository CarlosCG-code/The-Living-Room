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
## Primera máquina de un generador (para el aviso del OSD); no salta al cargar la partida.
signal generator_shown(id: StringName)
## Empieza un evento (para su sonido).
signal event_started(id: StringName)
## Se ha clicado la cinta del hueco slot (0 o 1).
signal package_pressed(slot: int)

const TEX := "res://assets/textures/tv/"
# Eventos (core/tv_event_def.gd): la estrella cruza el cielo; la silueta sale en uno de estos sitios.
const STAR_FROM := Vector2(300, 14)
const STAR_TO := Vector2(40, 58)
# Pies de la silueta en cada run: lejos y en el borde (1), al otro lado (2), junto a la fábrica (3) y justo
# detrás del cristal (4: grande, quieta y sin ojos). Siempre en la nieve abierta, donde se recorta.
const SILHOUETTE_SPOTS_BY_RUN := {
	1: [Vector2(40, 190), Vector2(292, 170)],
	2: [Vector2(262, 194), Vector2(122, 198)],
	3: [Vector2(214, 162), Vector2(120, 150)],
	4: [Vector2(160, 236)],
}
## Ventanas de la fábrica (en su dibujo): se apagan de una en una a lo largo de la run.
const FACTORY_WINDOWS: Array[Rect2] = [Rect2(6, 22, 11, 8), Rect2(22, 22, 11, 8), Rect2(38, 22, 11, 8)]
const SHADOW := Color("05060b")
## Texto en pantalla (números al clicar, aviso de la Señal clara): mismo fósforo que el OSD.
const OSD_TEXT := Color("b8f5c4")
## Unidades del generador necesarias para cada hueco (el k-ésimo pide THRESHOLDS[k]).
const THRESHOLDS: Array[int] = [1, 5, 10, 25, 50]
const FADE_IN := 0.6
const LABEL_HOLD := 3.0
const FACTORY_POS := Vector2(132, 92)
const RECEPTOR_FEET := Vector2(147, 174)
const CATCH_SIZE := Vector2(48, 40)
## Dónde caen las cintas si no queda sitio libre en la nieve (hueco 0 y 1), lejos de las máquinas.
const PACKAGE_SLOTS: Array[Vector2] = [Vector2(170, 196), Vector2(250, 158)]
## Esquina de arriba a la izquierda de una cinta: nieve abierta, entre los árboles de los lados.
const TAPE_AREA := Rect2(36, 120, 236, 84)
const TAPE_MARGIN := 3.0
## Lo que una cinta no tapa además de máquinas, fábrica y receptor: árboles de abajo y textos del OSD.
const TAPE_BLOCKED: Array[Rect2] = [Rect2(28, 186, 58, 54), Rect2(232, 182, 70, 58), Rect2(0, 196, 150, 44),
		Rect2(140, 205, 180, 35)]
const TAPE_ICONS := ["tape", "tape_rare", "tape_black"]
## Zona de clic del receptor, mucho mayor que su dibujo (26 × 24): al clicar deprisa el ratón se mueve.
const RECEPTOR_HITBOX := Vector2(64, 52)
# Por generador: pies de cada hueco (abajo a la izquierda), etiqueta y cable (desde, hasta, caída).
const LAYOUT := {
	&"antenna": {"slots": [Vector2(62, 132), Vector2(80, 136), Vector2(98, 132)], "cable": [Vector2(106, 118), Vector2(134, 120), 6.0]},
	&"channel_3": {"slots": [Vector2(226, 134)], "cable": [Vector2(232, 118), Vector2(186, 122), 6.0]},
	&"valves": {"slots": [Vector2(54, 168), Vector2(78, 170), Vector2(102, 168)], "cable": [Vector2(116, 160), Vector2(134, 136), 4.0]},
	&"audio_frequency": {"slots": [Vector2(74, 214), Vector2(96, 216)], "cable": [Vector2(108, 198), Vector2(140, 142), 8.0]},
	&"tuner": {"slots": [Vector2(204, 214), Vector2(228, 212)], "cable": [Vector2(212, 198), Vector2(178, 142), 8.0]},
	&"remote": {"slots": [Vector2(232, 172), Vector2(246, 174)], "cable": [Vector2(236, 160), Vector2(186, 136), 4.0]},
}

var _groups := {}  # StringName -> {"machines": Array[TextureButton], "cable": FactoryCable, "shown": bool}
var _receptor: TextureButton
var _factory: TextureButton
var _counts_seen := false
var _sparks: CPUParticles2D
var _catch: Button
var _hint: Label
var _event_layer: Node2D
var _marker: Node2D
var _tapes: Array[TextureButton] = []
var _click_sparks: CPUParticles2D
var _snow: CPUParticles2D
var _pool: TextureRect
var _dark_windows: Node2D
var _windows_off := 0
var _run := 1
var _dread := 0.0
var _freeze_left := 0.0
var _silhouette_scale := 1.0
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
	add_child(bg)
	_event_layer = Node2D.new()
	_event_layer.draw.connect(_draw_event)
	add_child(_event_layer)
	_snow = _particles(Vector2(160, -4), Vector2(170, 1), 70, 9.0, Vector2(4, 14), Color(0.75, 0.8, 0.92, 0.55))
	add_child(_snow)
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
	_dark_windows = Node2D.new()
	_dark_windows.draw.connect(func() -> void:
		for k in _windows_off:
			_dark_windows.draw_rect(FACTORY_WINDOWS[FACTORY_WINDOWS.size() - 1 - k], Color("0b0e16")))
	_factory.add_child(_dark_windows)
	# Humo lento de la chimenea, que se va hacia la izquierda con el viento.
	var smoke := _particles(FACTORY_POS + Vector2(44, 0), Vector2(2, 1), 16, 5.0, Vector2(-6, -9), Color(0.45, 0.5, 0.6, 0.45))
	smoke.scale_amount_min = 1.0
	smoke.scale_amount_max = 3.0
	add_child(smoke)
	_light_pool()

	var i := 0
	for id: StringName in LAYOUT:
		var spec: Dictionary = LAYOUT[id]
		var tex: Texture2D = load(TEX + String(id) + ".png")
		var machines: Array[TextureButton] = []
		for feet: Vector2 in spec["slots"]:
			var m := _machine(tex, feet)
			m.visible = false
			machines.append(m)
		_groups[id] = {"machines": machines, "cable": cables[i], "shown": false}
		i += 1
	_receptor = _machine(load(TEX + "receptor.png"), RECEPTOR_FEET)
	_widen_hitbox(_receptor, RECEPTOR_HITBOX)

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
	_click_sparks = _particles(Vector2.ZERO, Vector2(1, 1), 4, 0.35, Vector2.ZERO, Color(1.0, 0.85, 0.5))
	_click_sparks.one_shot = true
	_click_sparks.explosiveness = 1.0
	_click_sparks.emitting = false
	_click_sparks.preprocess = 0.0
	_click_sparks.direction = Vector2.UP
	_click_sparks.spread = 70.0
	_click_sparks.initial_velocity_min = 25.0
	_click_sparks.initial_velocity_max = 50.0
	_click_sparks.gravity = Vector2(0, 160)
	add_child(_click_sparks)
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
	for slot in PACKAGE_SLOTS.size():
		var t := TextureButton.new()
		t.name = "Tape%d" % slot
		t.position = PACKAGE_SLOTS[slot]
		t.focus_mode = FOCUS_NONE
		# Al doble exacto (píxeles enteros): una cinta de 12 × 12 se perdía en la nieve.
		t.ignore_texture_size = true
		t.stretch_mode = TextureButton.STRETCH_SCALE
		t.size = Vector2(24, 24)
		t.pivot_offset = Vector2(12, 24)
		t.visible = false
		t.pressed.connect(package_pressed.emit.bind(slot))
		add_child(t)
		_tapes.append(t)
	# Paleta fija: todo lo de debajo (el mundo) cae en 12 colores. Las marcas, los números y el OSD, encima.
	var palette := ColorRect.new()
	palette.name = "Palette"
	palette.size = Vector2(320, 240)
	palette.mouse_filter = MOUSE_FILTER_IGNORE
	var palette_mat := ShaderMaterial.new()
	palette_mat.shader = preload("res://presentation/ui/palette.gdshader")
	palette.material = palette_mat
	add_child(palette)
	# Marcas de OSD alrededor de lo que se puede atrapar: por encima de la viñeta, para que se vean siempre.
	_marker = Node2D.new()
	_marker.name = "Marker"
	_marker.draw.connect(_draw_marker)
	add_child(_marker)
	_hint = _label(tr("UI_EVENT_CLEAR_SIGNAL"), Vector2.ZERO, Color("8fe8b8"))
	_hint.visible = false
	# Los textos van por encima de la viñeta para que se lean en los bordes.
	for child in get_children():
		if child is Label:
			move_child(child, -1)


func _process(delta: float) -> void:
	var eco := Game.economy
	show_counts(eco.state.generators)
	show_event(eco.active_event(), eco.event_progress())
	show_packages(eco.packages())
	set_dread(eco.state.energy_produced_run / eco.threshold(), eco.state.run_index)
	if _freeze_left > 0.0:
		_freeze_left -= delta
		_snow.speed_scale = 0.0
	elif _run >= 3 and _dread > 0.5 and randf() < delta / 40.0:
		_freeze_left = 1.0  # la nieve se para en el aire un segundo
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
		if owned > 0 and not group["shown"] and _counts_seen:
			generator_shown.emit(id)
		group["shown"] = owned > 0
		var cable: FactoryCable = group["cable"]
		cable.speed = 18.0 + 10.0 * log(1.0 + owned)
		cable.pulses = clampi(1 + floori(owned / 5.0), 1, 6)
	_counts_seen = true


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
	_catch.position = (event_center() - CATCH_SIZE / 2).clamp(Vector2.ZERO, size - CATCH_SIZE)
	var hint_size := _hint.get_combined_minimum_size()
	# Por debajo de y = 46: más arriba pisaba el «/s · /clic» del OSD.
	_hint.position = (_event_at + Vector2(-hint_size.x / 2, 10)).round().clamp(Vector2(0, 46), size - hint_size)
	_event_layer.queue_redraw()
	_marker.queue_redraw()


## Centro de lo que hay que clicar (la silueta se mide desde los pies).
func event_center() -> Vector2:
	return _event_at + (Vector2(0, -10) if _event_id == &"silhouette" else Vector2.ZERO)


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
		_event_at = (SILHOUETTE_SPOTS_BY_RUN[_run] as Array).pick_random()
		_silhouette_scale = 3.0 if _run >= 4 else 1.0
	_sparks.emitting = id == &"interference"
	_catch.visible = e != null and e.catchable()
	# Solo la Señal clara se anuncia: lo demás hay que verlo (pedido del usuario, 2026-11-18).
	_hint.visible = id == &"clear_signal"
	_event_layer.queue_redraw()
	_marker.queue_redraw()
	if id != &"" and Game.running:
		event_started.emit(id)  # en el menú (partida cargada con un evento) no suena


func _draw_event() -> void:
	var c := _event_layer
	match _event_id:
		&"shooting_star":
			# Estela larga que se apaga, cabeza de 3 × 3 con halo en cruz y un destello que gira.
			var dir := (STAR_TO - STAR_FROM).normalized()
			for k in 26:
				var p := (_event_at - dir * k).round()
				var fade := 1.0 - k / 26.0
				c.draw_rect(Rect2(p, Vector2(1, 1)), Color(1.0, 0.95, 0.75, fade * fade))
			var head := _event_at.round()
			c.draw_rect(Rect2(head - Vector2(1, 1), Vector2(3, 3)), Color.WHITE)
			var halo := Color(1.0, 0.9, 0.6, 0.55)
			for off: Vector2 in [Vector2(-3, 0), Vector2(3, 0), Vector2(0, -3), Vector2(0, 3)]:
				c.draw_rect(Rect2(head + off, Vector2(1, 1)), halo)
			if fmod(Time.get_ticks_msec() / 250.0, 2.0) < 1.0:
				for off: Vector2 in [Vector2(-2, -2), Vector2(2, 2), Vector2(-2, 2), Vector2(2, -2)]:
					c.draw_rect(Rect2(head + off, Vector2(1, 1)), halo)
		&"clear_signal":
			# Aurora: bandas verdosas que ondulan; entra y sale suave.
			# Cada run, la aurora tiene menos color (en la 4.ª ya es gris).
			var alpha := sin(PI * _event_t) * 0.35 * (1.0 - 0.2 * (_run - 1))
			var time := Time.get_ticks_msec() / 1000.0
			for band in 3:
				for x in range(0, 320, 2):
					var y := 22.0 + band * 7.0 + sin(x * 0.03 + time * 0.8 + band) * 6.0
					c.draw_rect(Rect2(x, y, 2, 10 - band * 2), Color(0.62, 0.85, 0.68, alpha * (1.0 - band * 0.25)))
		&"silhouette":
			# Figura quieta en la nieve: aparece despacio (no es un susto) y al final se va apagando a golpes.
			var a := clampf(_event_t * 3.0, 0.0, 1.0)
			if _event_t > 0.8 and fmod(_event_t * 20.0, 2.0) < 1.0:
				a *= 0.3
			var feet := _event_at
			var k := _silhouette_scale  # en la run 4 está justo detrás del cristal: enorme
			c.draw_rect(Rect2(feet + Vector2(-3, -16) * k, Vector2(6, 16) * k), Color(SHADOW, a))  # cuerpo
			c.draw_rect(Rect2(feet + Vector2(-4, -15) * k, Vector2(1, 9) * k), Color(SHADOW, a))  # brazos largos
			c.draw_rect(Rect2(feet + Vector2(3, -15) * k, Vector2(1, 9) * k), Color(SHADOW, a))
			c.draw_rect(Rect2(feet + Vector2(-2, -21) * k, Vector2(4, 5) * k), Color(SHADOW, a))  # cabeza
			if _run >= 4:
				return  # sin ojos
			c.draw_rect(Rect2(feet + Vector2(-6, 0), Vector2(12, 2)), Color(SHADOW, a * 0.5))  # sombra en la nieve
			# Ojos que brillan: lo primero que se ve.
			for eye: Vector2 in [Vector2(-1, -19), Vector2(1, -19)]:
				c.draw_rect(Rect2(feet + eye, Vector2(1, 1)), Color(1.0, 0.95, 0.85, a))
				c.draw_rect(Rect2(feet + eye + Vector2(0, -1), Vector2(1, 1)), Color(1.0, 0.9, 0.7, a * 0.35))


## Esquinas de OSD que laten (2 por segundo como mucho) alrededor de lo que se puede atrapar.
func _draw_marker() -> void:
	if not _catch.visible:
		return
	var pulse := 0.55 + 0.45 * sin(Time.get_ticks_msec() / 1000.0 * TAU * 2.0)
	var color := Color(0.72, 0.96, 0.77, 0.4 + 0.6 * pulse)
	var half := Vector2(14, 14) + Vector2(2, 2) * pulse
	var r := Rect2((event_center() - half).round(), (half * 2).round())
	var arm := 5.0
	for corner: Vector2 in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
		var sx := 1.0 if corner.x == r.position.x else -1.0
		var sy := 1.0 if corner.y == r.position.y else -1.0
		_marker.draw_line(corner, corner + Vector2(arm * sx, 0), color)
		_marker.draw_line(corner, corner + Vector2(0, arm * sy), color)


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


## Terror progresivo (specs/incremental_v2.md §6): f = Energía producida / umbral; run = número de run.
## Las ventanas se apagan de una en una (el juego se come la corriente), la nieve se vuelve gris y lenta y los
## cables laten como un corazón. Todo depende de f y de la run, así que se recompone al cargar la partida.
func set_dread(f: float, run: int) -> void:
	_run = clampi(run, 1, 4)
	_dread = clampf(f, 0.0, 1.0)
	var lit_min := 1 if _run >= 4 else 0  # en la última run queda una sola ventana: la tuya
	var off := mini(floori(inverse_lerp(0.2, 0.9, _dread) * 3.0 + 0.0001) if _dread >= 0.2 else 0, 3 - lit_min)
	if _run >= 4:
		off = maxi(off, 2)
	if off != _windows_off:
		_windows_off = off
		_dark_windows.queue_redraw()
		_pool.modulate.a = 1.0 - off / 3.0
	var gray := clampf(inverse_lerp(0.5, 1.0, _dread), 0.0, 1.0)
	_snow.color = Color(0.75, 0.8, 0.92, 0.55).lerp(Color(0.45, 0.47, 0.5, 0.5), gray)
	if _freeze_left <= 0.0:
		_snow.speed_scale = lerpf(1.0, 0.55, gray)
	var beat := clampf(inverse_lerp(0.6, 1.0, _dread), 0.0, 1.0) + (0.3 if _run >= 3 else 0.0)
	for id: StringName in _groups:
		(_groups[id]["cable"] as FactoryCable).beat = minf(beat, 1.0)


func windows_off() -> int:
	return _windows_off


## Dibuja las cintas que hay en la nieve: cada una en su hueco, con el icono de su rareza; parpadea al final.
func show_packages(packages: Array[Dictionary]) -> void:
	var shown := [false, false]
	for p in packages:
		var t := _tapes[p["slot"]]
		shown[p["slot"]] = true
		t.texture_normal = load("res://assets/textures/tv/icon_%s.png" % TAPE_ICONS[p["rarity"]])
		if not t.visible:
			t.position = _tape_spot(t)
			t.visible = true
			_bounce(t)
		var left: float = p["left"]
		t.modulate.a = 0.35 if left < 5.0 and fmod(left * 2.0, 1.0) < 0.5 else 1.0
	for slot in _tapes.size():
		if not shown[slot]:
			_tapes[slot].visible = false


## Sitio al azar en la nieve para una cinta que aparece, sin tocar las máquinas que se ven, la fábrica, el
## receptor, la otra cinta ni el OSD (petición del usuario, 2026-11-19). Se recorren todos los sitios: con todas
## las máquinas compradas quedan pocos huecos y probar al azar casi nunca daba con uno.
func _tape_spot(tape: TextureButton) -> Vector2:
	var blocked: Array[Rect2] = []
	for b in TAPE_BLOCKED + [_factory.get_rect(), _receptor.get_rect()]:
		blocked.append(b.grow(TAPE_MARGIN))
	for g: Dictionary in _groups.values():
		for m: TextureButton in g["machines"]:
			if m.visible:
				blocked.append(m.get_rect().grow(TAPE_MARGIN))
	for other in _tapes:
		if other != tape and other.visible:
			blocked.append(other.get_rect().grow(TAPE_MARGIN))
	var free: Array[Vector2] = []
	for y in range(TAPE_AREA.position.y, TAPE_AREA.end.y, 4):
		for x in range(TAPE_AREA.position.x, TAPE_AREA.end.x, 4):
			var r := Rect2(Vector2(x, y), tape.size)
			if not blocked.any(func(b: Rect2) -> bool: return b.intersects(r)):
				free.append(r.position)
	return free.pick_random() if not free.is_empty() else PACKAGE_SLOTS[_tapes.find(tape)]


func get_tape(slot: int) -> TextureButton:
	return _tapes[slot]


## Número que sube y se desvanece donde se ha clicado.
## Número que salta donde se ha clicado: un poco desviado para que no se tapen; el crítico, el doble de
## grande, en ámbar, y se queda un instante antes de subir.
func float_text(at: Vector2, text: String, crit: bool = false) -> void:
	var offset := Vector2(randi_range(-6, 6), 0)
	var label := _label(text, (at + offset + Vector2(-8, -14)).round(), FactoryCable.PULSE if crit else OSD_TEXT)
	if crit:
		label.add_theme_font_size_override(&"font_size", 16)
		label.position.y -= 8
	var rise := 10.0 if crit else 12.0
	var tween := label.create_tween()
	if crit:
		tween.tween_interval(0.12)
	tween.set_parallel()
	tween.tween_property(label, "position:y", label.position.y - rise, 0.6).set_trans(Tween.TRANS_CUBIC) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.2).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


## Chispas sueltas al clicar (más en un crítico).
func click_burst(at: Vector2, crit: bool = false) -> void:
	_click_sparks.position = at
	_click_sparks.amount = 10 if crit else 4
	_click_sparks.restart()


## Pulsación desde el teclado: salta el receptor como si se hubiera clicado.
func press_receptor() -> Vector2:
	_bounce(_receptor)
	return top_of(_receptor)


## Centro de la parte de arriba del dibujo (no de la zona de clic, que puede ser mayor).
func top_of(b: TextureButton) -> Vector2:
	return b.position + Vector2(b.size.x / 2, (b.size.y - b.texture_normal.get_height()) / 2)


func get_group(id: StringName) -> Dictionary:
	return _groups.get(id, {})


func get_receptor() -> TextureButton:
	return _receptor


func _machine(tex: Texture2D, feet: Vector2) -> TextureButton:
	var b := _sprite_button(tex, feet - Vector2(0, tex.get_height()))
	b.pivot_offset = Vector2(tex.get_width() / 2.0, tex.get_height())
	# Sombra en la nieve: ancla la máquina al suelo (la luna está arriba a la derecha).
	var shadow := TextureRect.new()
	shadow.texture = _shadow_texture()
	shadow.show_behind_parent = true
	shadow.mouse_filter = MOUSE_FILTER_IGNORE
	shadow.size = Vector2(tex.get_width() + 6, 6)
	shadow.position = Vector2(-5, tex.get_height() - 4)
	b.add_child(shadow)
	b.button_down.connect(func() -> void: hold_changed.emit(true))
	b.button_up.connect(func() -> void: hold_changed.emit(false))
	b.pressed.connect(func() -> void:
		_bounce(b)
		machine_pressed.emit(top_of(b)))
	return b


## Agranda la zona de clic sin mover ni estirar el dibujo: rectángulo entero, sin máscara de píxeles.
func _widen_hitbox(b: TextureButton, hit: Vector2) -> void:
	var tex_size := b.texture_normal.get_size()
	b.texture_click_mask = null
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
	b.position -= (hit - tex_size) / 2.0
	b.size = hit
	b.pivot_offset = Vector2(hit.x / 2.0, (hit.y + tex_size.y) / 2.0)
	for child in b.get_children():
		(child as Control).position += (hit - tex_size) / 2.0


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
	label.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override(&"shadow_offset_x", 1)
	label.add_theme_constant_override(&"shadow_offset_y", 1)
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
	p.fixed_fps = 10  # el mundo se mueve a 10 fps, como stop-motion (§5)
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


func _set_shown(item: CanvasItem, on: bool) -> void:
	if on == item.visible:
		return
	item.visible = on
	if on:
		item.modulate.a = 0.0
		item.create_tween().tween_property(item, "modulate:a", 1.0, FADE_IN)


static var _shadow_tex: GradientTexture2D


static func _shadow_texture() -> GradientTexture2D:
	if _shadow_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(0.01, 0.015, 0.03, 0.75))
		g.set_color(1, Color(0.01, 0.015, 0.03, 0.0))
		_shadow_tex = GradientTexture2D.new()
		_shadow_tex.gradient = g
		_shadow_tex.fill = GradientTexture2D.FILL_RADIAL
		_shadow_tex.fill_from = Vector2(0.5, 0.5)
		_shadow_tex.fill_to = Vector2(1.0, 0.5)
		_shadow_tex.width = 32
		_shadow_tex.height = 8
	return _shadow_tex


## Luz cálida de las ventanas sobre la nieve: el único punto cálido de la escena.
func _light_pool() -> void:
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.72, 0.35, 0.22))
	g.set_color(1, Color(1.0, 0.72, 0.35, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(1.0, 0.0)
	tex.width = 64
	tex.height = 24
	var pool := TextureRect.new()
	pool.name = "LightPool"
	pool.texture = tex
	pool.stretch_mode = TextureRect.STRETCH_SCALE
	pool.size = Vector2(96, 30)
	pool.position = FACTORY_POS + Vector2(-20, 48)
	pool.mouse_filter = MOUSE_FILTER_IGNORE
	_pool = pool
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	pool.material = add
	add_child(pool)
