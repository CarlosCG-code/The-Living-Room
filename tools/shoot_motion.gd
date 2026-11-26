extends SceneTree

# Capturas cuadro a cuadro de la cámara al levantarse (specs/hito4b.md D3), para revisarla sin jugar.
# Uso (con renderer real, no headless): TLR_SKIP_MENU=1 TLR_NO_SAVE=1 TLR_SHOTS=<carpeta> godot --path . -s tools/shoot_motion.gd
# TLR_MOTION=door (por defecto) o stand. Las capturas no van al repositorio.


func _initialize() -> void:
	change_scene_to_file("res://presentation/main.tscn")
	await create_timer(8.0).timeout  # GI, TAA y shaders asentados
	var dir := OS.get_environment("TLR_SHOTS")
	current_scene._stand_from_seat(OS.get_environment("TLR_MOTION") != "stand")
	for i in 20:
		root.get_texture().get_image().save_png("%s/f%02d.png" % [dir, i])
		await create_timer(0.2).timeout
	quit()
