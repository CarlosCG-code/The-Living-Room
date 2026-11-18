extends Node3D

# Menú principal (GDD §3: «solo la tele y algo de fondo»): la tele encendida en la oscuridad, vista
# desde un poco más lejos que en el juego, con el menú en su pantalla. Jugar carga el salón.
# Variables TLR_* solo en la build de depuración: con TLR_SKIP_MENU=1, TLR_VIEW o TLR_BENCHMARK se
# entra directamente al salón (capturas y benchmark).

const GAME_SCENE := "res://presentation/main.tscn"
## Fracción de la altura de la imagen que ocupa la pantalla: se ve la tele entera y la antena.
const SCREEN_FILL := 0.3

@onready var _tv: Node3D = $Tv
@onready var _camera: Camera3D = $GameCamera


func _ready() -> void:
	if _dev("TLR_SKIP_MENU") == "1" or _dev("TLR_BENCHMARK") == "1" or _dev("TLR_VIEW") != "":
		get_tree().change_scene_to_file.call_deferred(GAME_SCENE)
		return
	_camera.setup($Seat, _tv.get_screen_node(), _tv.get_screen_size(), _tv.get_input(), SCREEN_FILL)
	var menu: MainMenuUI = _tv.get_subviewport().get_child(0)
	menu.play_requested.connect(func() -> void: get_tree().change_scene_to_file(GAME_SCENE))
	# Salir pasa por el cierre normal: Game guarda la partida antes de cerrar.
	menu.quit_requested.connect(func() -> void: get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST))
	print("BOOT_OK")


func _dev(variable: String) -> String:
	return OS.get_environment(variable) if OS.is_debug_build() else ""
