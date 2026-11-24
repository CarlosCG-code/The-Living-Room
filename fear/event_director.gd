class_name EventDirector
extends RefCounted

# Decide qué suceso inquietante ocurre y cuándo (specs/hito3.md D3): silencios largos y tandas que crecen con el
# progreso, más los obligatorios que la historia necesita. Sin nodos: lo avanza Game.tick.

signal event_started(def: FearEventDef, place: StringName)

## Nada empieza hasta que pasa esto tras el anterior: los parpadeos no llegan a 3 destellos por segundo.
const EVENT_GAP := 0.34
const MANDATORY_DELAY := Vector2(4.0, 10.0)
const FRAME_DELAY := Vector2(1.0, 1.5)
const MANDATORY_GAP := 20.0
const SILENCE_AFTER_MANDATORY := 40.0
const FRAME_EVENT := &"interference"

var _set: FearEventSet
var _rng: RandomNumberGenerator
var _time := 0.0
var _busy := 0.0
var _wait := 0.0  # hasta el siguiente suceso al azar
var _burst_left := 0
var _spent := 0
var _done := {}  # obligatorios cumplidos: id -> true
var _due := {}  # obligatorios con su condición cumplida: id -> momento
var _last_mandatory := -INF
var _ready_at := {}  # id -> momento en que acaba su enfriamiento
var _recent: Array[StringName] = []  # los dos últimos ids
var _last_place: StringName = &""
var _forced: FearEventDef


func _init(p_set: FearEventSet, rng: RandomNumberGenerator) -> void:
	_set = p_set
	_rng = rng
	reset(DirectorState.new())


## Lo borra todo y empieza en silencio; lo obligatorio que ya se cumple en s se da por hecho.
func reset(s: DirectorState) -> void:
	_time = 0.0
	_busy = 0.0
	_wait = _between(_set.silence)
	_burst_left = 0
	_spent = 0
	_done.clear()
	_due.clear()
	_last_mandatory = -INF
	_ready_at.clear()
	_recent.clear()
	_last_place = &""
	_forced = null
	for def in _set.events:
		if _condition_met(def, s):
			_done[def.id] = true


func tick(delta: float, s: DirectorState) -> void:
	_time += delta
	_busy = maxf(0.0, _busy - delta)
	_wait -= delta
	for def in _set.events:
		if _done.has(def.id) or not _condition_met(def, s):
			_due.erase(def.id)  # p. ej. la interferencia se acabó antes
		elif not _due.has(def.id):
			_due[def.id] = _time + _between(FRAME_DELAY if def.kind == FearEventDef.Kind.TV_FRAME else MANDATORY_DELAY)
	if busy() or _start_forced(s) or _start_mandatory(s) or _wait > 0.0:
		return
	_start_random(s)


func busy() -> bool:
	return _busy > 0.0


## Trucos: sale en cuanto pueda, sin mirar condiciones ni enfriamiento.
func force(id: StringName) -> void:
	_forced = _set.find(id)


func _condition_met(def: FearEventDef, s: DirectorState) -> bool:
	if def.mandatory == FearEventDef.Mandatory.NONE or (def.kind == FearEventDef.Kind.TV_FRAME and s.tv_event != FRAME_EVENT):
		return false
	return s.progress >= def.mandatory_progress \
			or (def.mandatory == FearEventDef.Mandatory.ON_PURCHASE and _units(def, s) > 0)


func _start_forced(s: DirectorState) -> bool:
	if _forced == null or not _has_place(_forced, s):
		return false
	var def := _forced
	_forced = null
	_start(def, s)
	_wait = maxf(_wait, _busy + SILENCE_AFTER_MANDATORY)
	return true


func _start_mandatory(s: DirectorState) -> bool:
	if not s.ui_idle or _time < _last_mandatory + MANDATORY_GAP:
		return false
	for def in _set.events:
		if _due.get(def.id, INF) <= _time and _has_place(def, s):
			_due.erase(def.id)
			_done[def.id] = true
			_last_mandatory = _time
			_start(def, s)
			_wait = maxf(_wait, _busy + SILENCE_AFTER_MANDATORY)
			return true
	return false


func _start_random(s: DirectorState) -> void:
	if _burst_left == 0:
		_burst_left = _burst_size(s.progress)
	var def := _pick(s)
	if def == null:
		_burst_left = 0
		_wait = _between(_set.silence)
		return
	if s.progress < 1.0:
		_spent += 1
	_burst_left -= 1
	_start(def, s)
	_wait = def.duration + _between(_set.gap if _burst_left > 0 else _set.silence)


func _burst_size(p: float) -> int:
	if p >= 1.0:
		return _rng.randi_range(2, 4)
	return _rng.randi_range(1, 1 if p < 0.3 else 2 if p < 0.6 else 3)


func _pick(s: DirectorState) -> FearEventDef:
	if s.progress < 1.0 and _spent >= _set.run_budget:
		return null
	var possible: Array[FearEventDef] = []
	for def in _set.events:
		if def.random and s.progress >= def.min_progress and _time >= _ready_at.get(def.id, 0.0) \
				and _unlocked(def, s) and _has_place(def, s):
			possible.append(def)
	if possible.is_empty():
		return null
	var avoid := _recent.slice(_recent.size() - clampi(possible.size() - 2, 0, _recent.size()))
	var fresh := possible.filter(func(def: FearEventDef) -> bool: return def.id not in avoid)
	return fresh[_rng.randi() % fresh.size()]


# Lo obligatorio no entra en el sorteo hasta que ha salido; después ya no mira la máquina.
func _unlocked(def: FearEventDef, s: DirectorState) -> bool:
	if def.mandatory != FearEventDef.Mandatory.NONE:
		return _done.has(def.id)
	return def.requires == &"" or _units(def, s) > 0


func _units(def: FearEventDef, s: DirectorState) -> int:
	return s.owned.get(def.requires, 0)


func _has_place(def: FearEventDef, s: DirectorState) -> bool:
	return def.kind == FearEventDef.Kind.TV_FRAME or not _places(def, s).is_empty()


# Un sonido nunca sale de la zona donde está el jugador.
func _places(def: FearEventDef, s: DirectorState) -> Array[StringName]:
	if def.kind == FearEventDef.Kind.LAMP:
		return s.lamps.call()
	return def.places.filter(func(place: StringName) -> bool: return s.place_zone.call(place) != s.player_zone)


func _start(def: FearEventDef, s: DirectorState) -> void:
	var places := _places(def, s)
	if places.size() > 1:
		places.erase(_last_place)
	var place: StringName = &"" if places.is_empty() else places[_rng.randi() % places.size()]
	if place != &"":
		_last_place = place
	_busy = def.duration + EVENT_GAP
	_ready_at[def.id] = _time + def.cooldown / (1.0 + _units(def, s) / 25.0)
	_recent.append(def.id)
	if _recent.size() > 2:
		_recent.pop_front()
	event_started.emit(def, place)


func _between(r: Vector2) -> float:
	return _rng.randf_range(r.x, r.y)
