extends SceneTree

# Prepara (bake) el VoxelGI del salón en sus dos versiones (specs/hito2.md §6 paso 3).
# Necesita render real: "$GODOT" --path . -s tools/bake_voxel_gi.gd   (sin --headless)

const ROOM := "res://world/player_flat/living_room.tscn"
const OUTPUTS := {false: "res://world/player_flat/voxel_gi_data.res", true: "res://world/player_flat/voxel_gi_data_mirror.res"}


func _init() -> void:
	for mirrored: bool in [false, true]:
		var room := (load(ROOM) as PackedScene).instantiate()
		room.mirrored = mirrored
		get_root().add_child(room)
		await process_frame
		await process_frame
		var gi: VoxelGI = room.get_voxel_gi()
		gi.bake()
		var err := ResourceSaver.save(gi.data, OUTPUTS[mirrored])
		print("BAKE mirrored=%s -> %s (%s)" % [mirrored, OUTPUTS[mirrored], error_string(err)])
		room.queue_free()
		await process_frame
	quit()
