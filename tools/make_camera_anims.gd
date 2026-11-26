extends SceneTree

# Escribe data/camera_anims.tres: las animaciones de la cámara al levantarse (specs/hito4b.md D3).
# Uso: godot --headless --path . -s tools/make_camera_anims.gd
# Espacio del ancla: el suelo bajo el asiento, mirando hacia -Z (la tele). Giros en radianes: x < 0 mira abajo.

const OUT := "res://data/camera_anims.tres"

# [instante, posición, giro (cabeceo, guiñada, ladeo)]
const STAND := [
	[0.00, Vector3(0.0, 1.10, 0.05), Vector3(-0.08, 0.0, 0.0)],     # sentado
	[0.35, Vector3(0.0, 1.06, -0.04), Vector3(-0.26, 0.0, 0.0)],    # se echa adelante
	[0.75, Vector3(0.01, 1.00, -0.22), Vector3(-0.46, 0.0, 0.02)],  # todo el peso delante, mirando abajo
	[1.05, Vector3(0.02, 1.17, -0.34), Vector3(-0.36, 0.0, 0.015)], # el tirón al despegar del asiento
	[1.55, Vector3(0.0, 1.50, -0.50), Vector3(-0.12, 0.0, -0.015)], # sube
	[1.85, Vector3(-0.01, 1.63, -0.62), Vector3(0.04, 0.0, -0.01)], # se pasa un poco
	[2.15, Vector3(0.0, 1.585, -0.60), Vector3(-0.02, 0.0, 0.008)], # se recoloca
	[2.50, Vector3(0.0, 1.60, -0.60), Vector3(0.0, 0.0, 0.0)],      # de pie, quieto
]
# [instante, sonido]
const STAND_CUES := [[0.70, &"sofa"], [1.95, &"step"]]


func _init() -> void:
	var lib := AnimationLibrary.new()
	lib.add_animation(&"stand", _build(STAND, STAND_CUES))
	var err := ResourceSaver.save(lib, OUT)
	print("CAMERA_ANIMS %s %s" % [OUT, error_string(err)])
	quit(0 if err == OK else 1)


func _build(keys: Array, cues: Array) -> Animation:
	var a := Animation.new()
	a.length = keys[-1][0]
	var pos := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(pos, "Pivot:position")
	var rot := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(rot, "Pivot/Yaw/Tilt:rotation")
	for t in [pos, rot]:
		a.track_set_interpolation_type(t, Animation.INTERPOLATION_CUBIC)
	for k in keys:
		a.track_insert_key(pos, k[0], k[1])
		a.track_insert_key(rot, k[0], k[2])
	var calls := a.add_track(Animation.TYPE_METHOD)
	a.track_set_path(calls, ".")
	for c in cues:
		a.track_insert_key(calls, c[0], {"method": &"_cue", "args": [c[1]]})
	return a
