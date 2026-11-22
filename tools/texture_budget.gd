extends SceneTree

# Ajusta la importación de cada textura del piso según su uso, para gastar menos memoria de vídeo (2026-11-22):
# - objetos pequeños (lado mayor < SMALL m): como mucho 512 px; nadie los ve más de cerca que a un palmo;
# - nada pasa de 2048 px;
# - mapas que no son de color (rugosidad y metal): formato de 0,5 bytes por píxel (S3TC/BC1); el color y las
#   normales siguen en BC7.
# Uso: godot --headless --path . -s tools/texture_budget.gd  (después de importar; luego otra --import).
# Imprime BUDGET_CHANGED=<n>: si n > 0, hace falta volver a importar. verify.sh lo hace solo.

const SMALL := 0.3
const SMALL_SIDE := 512
const MAX_SIDE := 2048
const COLOR_SLOTS: Array[StringName] = [&"albedo_texture", &"normal_texture", &"emission_texture", &"detail_albedo",
		&"detail_normal"]

var _biggest := {}  # ruta de la textura -> lado mayor (m) del objeto más grande que la usa
var _color := {}  # ruta -> se usa como color o normal en algún material
var _flat: Node3D


## Parámetros de importación de una textura usada en objetos de hasta `biggest` m. El tope se pone siempre: en
## una textura más pequeña no hace nada, y así no depende del tamaño ya importado.
static func params(biggest: float, color: bool) -> Dictionary:
	return {"process/size_limit": SMALL_SIDE if biggest < SMALL else MAX_SIDE, "compress/high_quality": color}


func _initialize() -> void:
	_flat = (load("res://world/player_flat/flat.tscn") as PackedScene).instantiate()
	root.add_child(_flat)  # en _initialize el árbol aún no está montado: se recorre en el primer fotograma


func _process(_delta: float) -> bool:
	_walk(_flat)
	var changed := 0
	for path: String in _biggest:
		if _apply(path, params(_biggest[path], _color.get(path, false))):
			changed += 1
	print("BUDGET_CHANGED=%d of %d" % [changed, _biggest.size()])
	quit()
	return true


func _walk(n: Node) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var m := n as MeshInstance3D
		var box := m.global_transform * m.get_aabb()
		var ext := maxf(box.size.x, maxf(box.size.y, box.size.z))
		for i in m.mesh.get_surface_count():
			var mat := m.get_active_material(i) as BaseMaterial3D
			if mat == null:
				continue
			for prop in mat.get_property_list():
				var tex: Variant = mat.get(prop["name"])
				if tex is Texture2D and (tex as Texture2D).resource_path.begins_with("res://assets/"):
					var path := (tex as Texture2D).resource_path
					_biggest[path] = maxf(_biggest.get(path, 0.0), ext)
					if StringName(prop["name"]) in COLOR_SLOTS:
						_color[path] = true
	for c in n.get_children():
		_walk(c)


# Escribe los parámetros en el .import si cambian y borra lo importado para que se vuelva a importar.
func _apply(path: String, p: Dictionary) -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(path + ".import") != OK:
		return false
	var dirty := false
	for key: String in p:
		if cfg.get_value("params", key) != p[key]:
			cfg.set_value("params", key, p[key])
			dirty = true
	if not dirty:
		return false
	cfg.save(path + ".import")
	for f: String in cfg.get_value("deps", "dest_files", []):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(f.get_basename() + ".md5"))
	return true
