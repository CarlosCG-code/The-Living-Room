extends SceneTree

# Prepara (bake) el VoxelGI del salón y saca de él el del espejo (specs/hito2.md §6 paso 3). El del espejo no se
# hornea: su rejilla no cae igual sobre la geometría reflejada y los metales y cristales salían con otra luz.
# Necesita render real: "$GODOT" --path . -s tools/bake_voxel_gi.gd   (sin --headless)

const ROOM := "res://world/player_flat/living_room.tscn"
const OUTPUT := "res://world/player_flat/voxel_gi_data.res"
const OUTPUT_MIRROR := "res://world/player_flat/voxel_gi_data_mirror.res"


func _init() -> void:
	var room := (load(ROOM) as PackedScene).instantiate()
	get_root().add_child(room)
	await process_frame
	await process_frame
	# Sin el brillo propio de las pantallas: horneado, seguía dando luz con las lámparas apagadas.
	for m: MeshInstance3D in room.find_children("*", "MeshInstance3D", true, false):
		for i in m.mesh.get_surface_count():
			var material := m.mesh.surface_get_material(i) as BaseMaterial3D
			if material:
				material.emission_enabled = false
	var gi: VoxelGI = room.get_voxel_gi()
	gi.bake()
	print("BAKE %s (%s)" % [OUTPUT, error_string(ResourceSaver.save(gi.data, OUTPUT))])
	print("BAKE %s (%s)" % [OUTPUT_MIRROR, error_string(ResourceSaver.save(_mirrored(gi.data), OUTPUT_MIRROR))])
	room.queue_free()
	await process_frame
	quit()


## Los mismos datos con la x al revés.
func _mirrored(data: VoxelGIData) -> VoxelGIData:
	var d: Dictionary = data.get("_data")
	var size: Vector3 = d["octree_size"]
	# Cada celda del árbol: sus 8 hijos; el bit 0 del índice es la x.
	var octree: PackedInt32Array = (d["octree_cells"] as PackedByteArray).to_int32_array()
	for i in range(0, octree.size(), 2):
		var left := octree[i]
		octree[i] = octree[i + 1]
		octree[i + 1] = left
	# Datos de cada celda: posición en su nivel (11 bits de x), color, emisión y normal (un byte con signo por eje).
	var cells: PackedInt32Array = (d["octree_data"] as PackedByteArray).to_int32_array()
	var cell := 0
	var level := 0
	for count: int in d["level_counts"]:
		for i in count:
			cells[cell] = (cells[cell] & ~0x7ff) | ((1 << level) - 1 - (cells[cell] & 0x7ff))
			cells[cell + 3] = (cells[cell + 3] & ~0xff) | (-cells[cell + 3] & 0xff)
			cell += 4
		level += 1
	var distances := Image.new()
	distances.load_png_from_buffer(d["octree_df_png"])
	# El PNG lleva x e y en cada fila: se pasa a una x por fila para voltearla.
	distances = Image.create_from_data(int(size.x), int(size.y * size.z), false, Image.FORMAT_L8, distances.get_data())
	distances.flip_x()
	var to_cell: Transform3D = d["to_cell_xform"]
	to_cell.origin.x = size.x - to_cell.origin.x
	var out := VoxelGIData.new()
	out.allocate(to_cell, d["bounds"], size, octree.to_byte_array(), cells.to_byte_array(), distances.get_data(), d["level_counts"])
	out.dynamic_range = data.dynamic_range
	out.energy = data.energy
	out.bias = data.bias
	out.normal_bias = data.normal_bias
	out.propagation = data.propagation
	out.use_two_bounces = data.use_two_bounces
	out.interior = data.interior
	return out
