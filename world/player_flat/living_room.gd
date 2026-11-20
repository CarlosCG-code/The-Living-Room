extends Node3D

# Salón del jugador (specs/hito2.md D1, D14). Expone anclas, entorno y luces; no conoce a nadie.

const GEOMETRY := "res://assets/models/living_room/living_room.gltf"
const GEOMETRY_MIRROR := "res://assets/models/living_room/living_room_mirror.gltf"
const RAIN_SHADER := preload("res://world/player_flat/window_rain.gdshader")
const GI_DATA :="res://world/player_flat/voxel_gi_data.res"
const GI_DATA_MIRROR := "res://world/player_flat/voxel_gi_data_mirror.res"

## Lluvia: su volumen en la escena, y cuánto baja con un muro o una puerta cerrada entre ella y quien escucha.
## Fuera del salón solo se oye con la puerta abierta y a la vista (usuario, 2026-11-20).
const RAIN_DB := -4.0
const RAIN_OCCLUDED_DB := -40.0
const RAIN_FADE := 4.0  # 1/s

## Se fija antes de añadir la escena al árbol.
@export var mirrored := false

@onready var _rain_sound: AudioStreamPlayer3D = $RainSound


func _ready() -> void:
	var geometry := (load(GEOMETRY_MIRROR if mirrored else GEOMETRY) as PackedScene).instantiate()
	geometry.name = "Geometry"
	add_child(geometry)
	# Lluvia en el cristal (ronda 2 del look-dev): el material del glTF se sustituye por el shader de gotas.
	var glass := geometry.find_child("WindowGlass", true, false) as MeshInstance3D
	if glass:
		var rain := ShaderMaterial.new()
		rain.shader = RAIN_SHADER
		glass.material_override = rain
	var gi_path := GI_DATA_MIRROR if mirrored else GI_DATA
	if ResourceLoader.exists(gi_path):
		$VoxelGI.data = load(gi_path)
	if mirrored:
		# Los nodos del grupo cuelgan de la raíz o de contenedores en el origen, así que su transformada local basta.
		for node in get_tree().get_nodes_in_group(&"mirror_transform"):
			if is_ancestor_of(node):
				(node as Node3D).transform = MirrorMath.mirror_transform((node as Node3D).transform)


func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var hidden := SoundOcclusion.obstacles(get_world_3d().direct_space_state, cam.global_position,
			_rain_sound.global_position, 1) > 0
	var goal := RAIN_DB + (RAIN_OCCLUDED_DB if hidden else 0.0)
	_rain_sound.volume_db = lerpf(_rain_sound.volume_db, goal, 1.0 - exp(-RAIN_FADE * delta))


func get_anchor(anchor_name: StringName) -> Node3D:
	return get_node("Anchors/" + String(anchor_name)) as Node3D


func get_capture_camera(view: StringName) -> Camera3D:
	return get_node_or_null("CaptureCameras/" + String(view)) as Camera3D


func get_environment() -> WorldEnvironment:
	return $WorldEnvironment


func get_voxel_gi() -> VoxelGI:
	return $VoxelGI


func get_reflection_probe() -> ReflectionProbe:
	return $ReflectionProbe


func get_lights() -> Array[Light3D]:
	var lights: Array[Light3D] = []
	for node in get_tree().get_nodes_in_group(&"room_lights"):
		if is_ancestor_of(node):
			lights.append(node as Light3D)
	return lights


## Color y energía de la luz ambiente por estado de iluminación (D9).
func get_ambient() -> Dictionary:
	return get_meta(&"ambient", {})
