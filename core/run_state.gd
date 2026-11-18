class_name RunState
extends RefCounted

const VERSION := 3

var run_index: int = 1
var energy: float = 0.0
var energy_produced_run: float = 0.0
var generators: Dictionary = {}  # StringName -> int
var upgrades: Array[StringName] = []
var event_next_in: float = 0.0
var event_id: StringName = &""  # evento activo; vacío si no hay
var event_left: float = 0.0
var play_time: float = 0.0
## Carga sin gastar y mejoras permanentes compradas: pasan de una run a la siguiente.
var carga: int = 0
var perks: Array[StringName] = []


static func new_run(config: EconomyConfig, p_run_index: int, rng: RandomNumberGenerator) -> RunState:
	var state := RunState.new()
	state.run_index = p_run_index
	state.event_next_in = rng.randf_range(config.event_min, config.event_max)
	if p_run_index == 1:
		state.event_next_in = config.first_event_at
	return state


func to_dict() -> Dictionary:
	var gens := {}
	for id: StringName in generators:
		gens[String(id)] = generators[id]
	var ups: Array[String] = []
	for id in upgrades:
		ups.append(String(id))
	return {
		"version": VERSION,
		"run_index": run_index,
		"energy": energy,
		"energy_produced_run": energy_produced_run,
		"generators": gens,
		"upgrades": ups,
		"event": {"next_in": event_next_in, "id": String(event_id), "left": event_left},
		"play_time": play_time,
		"carga": carga,
		"perks": Array(perks).map(func(p: StringName) -> String: return String(p)),
	}


## Devuelve null si el diccionario es ilegible (§4 de specs/hito1.md); los id desconocidos van a warnings.
static func from_dict(d: Dictionary, config: EconomyConfig, warnings: PackedStringArray) -> RunState:
	if not _is_num(d.get("version")):
		return null
	if int(d["version"]) == 1:
		d = migrate_v1(d)
	if int(d["version"]) == 2:
		d = migrate_v2(d)
	if int(d["version"]) != VERSION:
		return null
	for key in ["run_index", "energy", "energy_produced_run", "play_time"]:
		if not _is_num(d.get(key)):
			return null
	var gens = d.get("generators")
	var ups = d.get("upgrades")
	var ev = d.get("event")
	var perks_in = d.get("perks")
	if not _is_num(d.get("carga")) or typeof(perks_in) != TYPE_ARRAY:
		return null
	for item in perks_in:
		if not _is_id(item):
			return null
	if typeof(gens) != TYPE_DICTIONARY or typeof(ups) != TYPE_ARRAY or typeof(ev) != TYPE_DICTIONARY:
		return null
	if not _is_num(ev.get("next_in")) or not _is_num(ev.get("left")) or not _is_id(ev.get("id")):
		return null
	for key in gens:
		if not _is_id(key) or not _is_num(gens[key]):
			return null
	for item in ups:
		if not _is_id(item):
			return null

	var state := RunState.new()
	state.run_index = maxi(1, int(d["run_index"]))
	state.energy = maxf(0.0, float(d["energy"]))
	state.energy_produced_run = maxf(0.0, float(d["energy_produced_run"]))
	state.play_time = maxf(0.0, float(d["play_time"]))
	state.carga = maxi(0, int(d["carga"]))
	for item in perks_in:
		var id := StringName(item)
		if config.find_perk(id) == null:
			warnings.append("unknown perk id: %s" % item)
		elif not state.perks.has(id):
			state.perks.append(id)
	state.event_next_in = maxf(0.0, float(ev["next_in"]))
	var saved_id := StringName(ev["id"])
	if saved_id != &"" and config.find_event(saved_id) == null:
		warnings.append("unknown event id: %s" % saved_id)
	elif saved_id != &"" and float(ev["left"]) > 0.0:
		state.event_id = saved_id
		state.event_left = float(ev["left"])
	for key in gens:
		var id := StringName(key)
		if config.find_generator(id) == null:
			warnings.append("unknown generator id: %s" % key)
			continue
		state.generators[id] = maxi(0, int(gens[key]))
	for item in ups:
		var id := StringName(item)
		if config.find_upgrade(id) == null:
			warnings.append("unknown upgrade id: %s" % item)
			continue
		if not state.upgrades.has(id):
			state.upgrades.append(id)
	return state


## v1 → v2: el bloque "interference" pasa a ser "event" (la interferencia es un evento más).
static func migrate_v1(d: Dictionary) -> Dictionary:
	var out := d.duplicate(true)
	var inter = out.get("interference")
	if typeof(inter) != TYPE_DICTIONARY or not _is_num(inter.get("next_in")) or not _is_num(inter.get("active_left")):
		return out
	out.erase("interference")
	var active: bool = float(inter["active_left"]) > 0.0
	out["event"] = {"next_in": inter["next_in"], "id": "interference" if active else "", "left": inter["active_left"]}
	out["version"] = 2
	return out


## v2 → v3: Carga y mejoras permanentes. Quien ya reinició antes de que existieran recibe 3 de Carga por
## cada reinicio hecho (lo mínimo que habría ganado).
static func migrate_v2(d: Dictionary) -> Dictionary:
	var out := d.duplicate(true)
	var runs_done: int = maxi(0, int(out.get("run_index", 1)) - 1) if _is_num(out.get("run_index")) else 0
	out["carga"] = 3 * runs_done
	out["perks"] = []
	out["version"] = 3
	return out


static func _is_num(v: Variant) -> bool:
	return (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) and is_finite(float(v))


static func _is_id(v: Variant) -> bool:
	return typeof(v) == TYPE_STRING or typeof(v) == TYPE_STRING_NAME
