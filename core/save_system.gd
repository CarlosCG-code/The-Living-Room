class_name SaveSystem
extends RefCounted

const FILE_NAME := "run.json"

var warnings: PackedStringArray = []

var _dir: String


func _init(dir: String = "user://") -> void:
	_dir = dir


## Devuelve null si no hay partida legible (partida nueva). Un .tmp legible es el guardado más nuevo y se recupera
## (rota como save_run); si no, nunca borra X ni X.bak.
func load_run(config: EconomyConfig) -> RunState:
	warnings.clear()
	var path := _path()
	var bak := path + ".bak"
	var tmp := path + ".tmp"
	if FileAccess.file_exists(tmp):
		# save_run escribe el .tmp justo antes de rotar: si se lee entero, es el guardado más nuevo y el corte
		# fue antes de terminar de rotar. A medias no se puede leer (JSON cortado) y se borra.
		if _read(tmp, config) != null:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(bak)
				DirAccess.rename_absolute(path, bak)
			DirAccess.rename_absolute(tmp, path)
		else:
			DirAccess.remove_absolute(tmp)
	if FileAccess.file_exists(path):
		var state := _read(path, config)
		if state != null:
			return state
		_quarantine(path, path + ".corrupt")
	if FileAccess.file_exists(bak):
		var state := _read(bak, config)
		if state != null:
			return state
		_quarantine(bak, path + ".bak.corrupt")
	return null


func save_run(state: RunState) -> bool:
	DirAccess.make_dir_recursive_absolute(_dir)
	var path := _path()
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		_warn("cannot write %s.tmp (%s)" % [path, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(state.to_dict(), "", true, true))
	var written := file.get_error()
	file.close()
	if written != OK:  # disco lleno, p. ej.: no se rota nada y el guardado anterior sigue intacto
		_warn("cannot write %s.tmp (%s)" % [path, error_string(written)])
		return false
	if FileAccess.file_exists(path) and DirAccess.rename_absolute(path, path + ".bak") != OK:
		_warn("cannot rotate %s to .bak" % path)
		return false
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		_warn("cannot rename %s.tmp" % path)
		return false
	return true


func _path() -> String:
	return _dir.path_join(FILE_NAME)


func _read(path: String, config: EconomyConfig) -> RunState:
	# JSON.new().parse, no JSON.parse_string: esta última escribe un error del motor que GUT cuenta como fallo.
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return null
	var found: PackedStringArray = []
	var state := RunState.from_dict(json.data, config, found)
	for w in found:
		_warn(w)
	return state


func _quarantine(path: String, dest: String) -> void:
	_warn("unreadable save %s, moved to %s" % [path, dest])
	DirAccess.rename_absolute(path, dest)


func _warn(message: String) -> void:
	warnings.append(message)
	push_warning(message)
