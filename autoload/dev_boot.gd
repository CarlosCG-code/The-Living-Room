extends Node

const RUNTIME_SCRIPT := "res://addons/godot_mcp_runtime/mcp_runtime_autoload.gd"


func _ready() -> void:
	load_runtime(RUNTIME_SCRIPT, get_tree().root)


## Devuelve null y no añade nada fuera de la build de depuración o si el script no existe.
func load_runtime(script_path: String, parent: Node) -> Node:
	# ResourceLoader.exists, no FileAccess.file_exists: en la build los scripts se exportan como .gdc.
	if not OS.is_debug_build() or not ResourceLoader.exists(script_path):
		return null
	var runtime: Node = (load(script_path) as GDScript).new()
	parent.add_child.call_deferred(runtime)
	return runtime
