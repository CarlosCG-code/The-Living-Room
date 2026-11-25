class_name Door
extends Node3D

# Puerta como en Visage (specs/hito4a.md D5): con la hoja agarrada, el ratón hacia arriba la aleja de ti y
# hacia abajo la acerca; al soltarla sigue con su inercia. La física es DoorMath; aquí, la hoja, el choque
# con el jugador y los muebles (se para, no empuja) y los sonidos. Se mueve en _physics_process solo mientras
# está agarrada o en movimiento.

const PX_TO_RAD := 0.004  # giro por píxel de ratón con la sensibilidad por defecto
const DEFAULT_SENSITIVITY := 0.0012
const HEIGHT := 2.074
const THICKNESS := 0.04
## Como una puerta de verdad (usuario, 2026-11-21): la hoja va enrasada con la cara del marco del lado hacia el
## que abre (medio muro + 1,5 cm que sobresale el marco), no en medio del muro, y gira en esa esquina: así
## abierta no se cruza con el marco. Holguras de 3 mm a cada jamba (las del piso entran 3 mm en el hueco).
const FACE := 0.09
const HINGE_INSET := 0.006
const LATCH_GAP := 0.009
## Hoja de época modelada en Blender (tools/blender/build_door.py) a este tamaño: 0,885 × 2,074 × 0,04 m.
const LEAF_SCENE := preload("res://assets/models/living_room/door_leaf.gltf")
const SOUNDS := {
	&"creak": preload("res://assets/audio/flat/door_creak.ogg"),
	&"latch": preload("res://assets/audio/flat/door_latch.ogg"),
	&"slam": preload("res://assets/audio/flat/door_slam.ogg"),
	&"locked": preload("res://assets/audio/flat/door_locked.ogg"),
}
## Tramos (s) de door_creak.ogg con crujido limpio: el resto de la grabación trae golpes de picaporte y de
## cierre que, sonando a mitad de un giro, parecían la puerta cerrándose (usuario, 2026-11-20).
const VOLUME_DB := -6.0
const CREAK_SEGMENTS: Array[Vector2] = [Vector2(3.2, 5.05), Vector2(8.5, 12.0), Vector2(18.5, 20.65),
		Vector2(23.4, 24.95), Vector2(36.1, 37.45)]

## Hasta dónde la abre sola un suceso.
const CREEP_ANGLE := deg_to_rad(35.0)

var id: StringName
var locked := false
var angle := 0.0
var velocity := 0.0

var _width := 0.9
var _sign := 1.0  # swing del plano, y además -1 en espejo: reflejar R_y(θ) da R_y(-θ)
var _held := false
var _side := 1.0
var _pending_dy := 0.0
var _leaf: AnimatableBody3D
var _shape: BoxShape3D
var _players := {}
var _creak_end := 0.0


## Coloca la puerta según el plano. La bisagra queda en el origen y la hoja cerrada a lo largo de +X local.
func setup(conn: ConnectionDef, mirrored: bool) -> void:
	id = conn.id
	_width = conn.width - HINGE_INSET - LATCH_GAP
	locked = conn.start == &"locked"
	angle = DoorMath.AJAR_ANGLE if conn.start == &"ajar" else 0.0
	var x := conn.direction.normalized()
	var origin := conn.hinge + x * HINGE_INSET
	if mirrored:  # se reflejan los puntos, no la base: M·t·M ponía la hoja al otro lado de la bisagra
		x.x = -x.x
		origin.x = -origin.x
	transform = Transform3D(Basis(x, Vector3.UP, x.cross(Vector3.UP)), origin)
	_sign = conn.swing * (-1.0 if mirrored else 1.0)
	_build()
	_apply_angle()
	set_physics_process(false)


func _build() -> void:
	_leaf = AnimatableBody3D.new()
	_leaf.name = "Leaf"
	_leaf.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON  # gira en _physics_process
	_leaf.position = _pivot()
	add_child(_leaf)
	_shape = BoxShape3D.new()
	_shape.size = Vector3(_width, HEIGHT, THICKNESS)
	var col := CollisionShape3D.new()
	col.shape = _shape
	col.position = _leaf_center()
	_leaf.add_child(col)
	# Cerrada, la hoja tapa el cuarto de detrás (oclusión, flat.gd); algo más pequeña que ella para que no
	# esconda lo que asoma por sus bordes.
	var occluder := OccluderInstance3D.new()
	var quad := QuadOccluder3D.new()
	quad.size = Vector2(_width - 0.1, HEIGHT - 0.1)
	occluder.occluder = quad
	occluder.position = _leaf_center()
	_leaf.add_child(occluder)
	# El modelo va con la cara de los pernios en su -Z; del otro lado de la puerta se refleja.
	var model := LEAF_SCENE.instantiate() as Node3D
	model.position = Vector3(0.0, 0.02, _sign * THICKNESS / 2.0)  # rendija de 2 cm bajo la hoja, como en el salón
	if _sign < 0.0:
		MirrorMath.reflect_meshes(model, Vector3.AXIS_Z)
	_leaf.add_child(model)
	for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		m.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC  # no deja su sombra horneada al abrirse
	for key: StringName in SOUNDS:
		var p := AudioStreamPlayer3D.new()
		p.stream = SOUNDS[key]
		p.bus = &"Room"  # con un eco ligero
		p.position = Vector3(_width * 0.6, 1.2, 0.0)
		p.volume_db = VOLUME_DB
		p.unit_size = 2.0  # con el valor por defecto (10 m) sonaba igual de cerca desde cualquier punto del piso
		add_child(p)
		_players[key] = p


# Esquina de giro: en la cara del marco del lado hacia el que abre (ahí gira la hoja hacia -Z · _sign).
func _pivot() -> Vector3:
	return Vector3(0.0, 0.0, -_sign * FACE)


# Centro de la hoja respecto a la esquina de giro: hacia dentro del muro.
func _leaf_center() -> Vector3:
	return Vector3(_width / 2.0, 0.02 + HEIGHT / 2.0, _sign * THICKNESS / 2.0)


## Agarrar la hoja desde eye. Con llave no se mueve: suena el traqueteo y devuelve false.
func try_grab(eye: Vector3) -> bool:
	if locked:
		_play(&"locked")
		return false
	# Lado del jugador respecto a hacia dónde se abre: subir el ratón siempre la aleja de él.
	var open_dir := _latch_at(angle + 0.01) - _latch_at(angle)
	_side = 1.0 if (eye - _latch_at(angle)).dot(open_dir) < 0.0 else -1.0
	_held = true
	_pending_dy = 0.0
	set_physics_process(true)
	return true


func drag(mouse_dy: float) -> void:
	_pending_dy += mouse_dy


func release() -> void:
	_held = false


## Se mueve sola y despacio (un suceso, que pone el crujido): se abre un poco o, si ya lo está, se entorna. Con llave, no.
func creep(seconds: float) -> void:
	if locked or is_physics_processing():  # con llave, o en la mano del jugador
		return
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	var step := func(a: float) -> void:
		if _held or _blocked(a):
			tween.kill()
			return
		angle = a
		_apply_angle()
	var to := DoorMath.AJAR_ANGLE if angle > CREEP_ANGLE / 2.0 else CREEP_ANGLE
	tween.tween_method(step, angle, to, seconds).set_trans(Tween.TRANS_SINE)


func _physics_process(delta: float) -> void:
	var sens_scale := Game.settings.mouse_sensitivity / DEFAULT_SENSITIVITY
	var drag_rate := -_pending_dy * PX_TO_RAD * sens_scale / delta * _side if _held else 0.0
	_pending_dy = 0.0
	var r := DoorMath.step(angle, velocity, drag_rate, _held, delta)
	if not is_equal_approx(r.x, angle) and _blocked(r.x):
		velocity = 0.0  # la hoja se para contra el jugador o un mueble, como en Visage
	else:
		angle = r.x
		velocity = r.y
		match int(r.z):
			DoorMath.Event.LATCH:
				_play(&"latch")
			DoorMath.Event.SLAM:
				_play(&"slam")
		_apply_angle()
	_update_creak()
	if not _held and velocity == 0.0:
		set_physics_process(false)


func _apply_angle() -> void:
	_leaf.rotation.y = _sign * angle


func _latch_at(a: float) -> Vector3:
	return global_transform * (_pivot() + Basis(Vector3.UP, _sign * a) * Vector3(_width, 1.0, 0.0))


# ¿Chocaría la hoja en el ángulo a con el jugador o con un mueble? Los muros y marcos no cuentan: la hoja
# gira pegada a ellos en la bisagra.
func _blocked(a: float) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _shape
	q.transform = global_transform * Transform3D(Basis(Vector3.UP, _sign * a), _pivot()) \
			* Transform3D(Basis.IDENTITY, _leaf_center())
	q.exclude = [_leaf.get_rid()]
	for hit in get_world_3d().direct_space_state.intersect_shape(q, 8):
		var c: Object = hit["collider"]
		if c is CharacterBody3D or (c is Node and String((c as Node).name).begins_with("Solid_")) \
				or (c is Node and String((c as Node).name).begins_with("SeatSofa")):
			return true
	return false


# Crujido mientras se mueve con cierta velocidad: más fuerte cuanto más deprisa.
func _update_creak() -> void:
	var p: AudioStreamPlayer3D = _players[&"creak"]
	var speed := absf(velocity)
	if speed > 0.35 and (not p.playing or p.get_playback_position() >= _creak_end):
		var seg: Vector2 = CREAK_SEGMENTS.pick_random()
		_creak_end = seg.y
		p.play(seg.x)
	elif speed < 0.1 and p.playing:
		p.stop()
	p.volume_db = VOLUME_DB + linear_to_db(clampf(speed / 2.0, 0.15, 1.0))


func _play(key: StringName) -> void:
	(_players[key] as AudioStreamPlayer3D).play()
