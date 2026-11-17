class_name RunState
extends RefCounted

const VERSION := 1

var run_index: int = 1
var energy: float = 0.0
var energy_produced_run: float = 0.0
var generators: Dictionary = {}  # StringName -> int
var upgrades: Array[StringName] = []
var interference_next_in: float = 0.0
var interference_active_left: float = 0.0
var play_time: float = 0.0


static func new_run(config: EconomyConfig, p_run_index: int, rng: RandomNumberGenerator) -> RunState:
	var state := RunState.new()
	state.run_index = p_run_index
	state.interference_next_in = rng.randf_range(config.interference_min, config.interference_max)
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
		"interference": {"next_in": interference_next_in, "active_left": interference_active_left},
		"play_time": play_time,
	}


## Devuelve null si el diccionario es ilegible (§4 de specs/hito1.md); los id desconocidos van a warnings.
static func from_dict(d: Dictionary, config: EconomyConfig, warnings: PackedStringArray) -> RunState:
	if not _is_num(d.get("version")) or int(d["version"]) != VERSION:
		return null
	for key in ["run_index", "energy", "energy_produced_run", "play_time"]:
		if not _is_num(d.get(key)):
			return null
	var gens = d.get("generators")
	var ups = d.get("upgrades")
	var inter = d.get("interference")
	if typeof(gens) != TYPE_DICTIONARY or typeof(ups) != TYPE_ARRAY or typeof(inter) != TYPE_DICTIONARY:
		return null
	if not _is_num(inter.get("next_in")) or not _is_num(inter.get("active_left")):
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
	state.interference_next_in = maxf(0.0, float(inter["next_in"]))
	state.interference_active_left = maxf(0.0, float(inter["active_left"]))
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


static func _is_num(v: Variant) -> bool:
	return (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) and is_finite(float(v))


static func _is_id(v: Variant) -> bool:
	return typeof(v) == TYPE_STRING or typeof(v) == TYPE_STRING_NAME
