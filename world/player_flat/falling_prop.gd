class_name FallingProp
extends Node3D

# Un objeto que se cae de verdad cuando suena (usuario, 2026-11-24): resbala hasta el borde, cae dando una vuelta, bota un
# poco y se queda en el suelo.

const GRAVITY := 9.8
const SLIDE := 0.5  # s hasta el borde
const SLIDE_SHARE := 0.6  # lo que recorre a lo largo antes de caer
const HOP := 0.15  # s del bote
const HOP_HEIGHT := 0.03
const YAW := 0.6  # con qué giro queda (rad); al revés en espejo, que cambia el signo de x

var fallen := false
var landing: Vector3
var _home: Vector3
var _drop := 0.0  # s de caída


## Se lleva las mallas del objeto; spot es el punto del suelo (x, z) donde acaba.
func setup(meshes: Array[Node], spot: Vector2) -> void:
	var box := AABB()
	for m: MeshInstance3D in meshes:
		var part := m.global_transform * m.get_aabb()
		box = box.merge(part) if box.has_surface() else part
	global_position = box.get_center()
	for m in meshes:
		m.reparent(self)
	_home = position
	landing = Vector3(spot.x, box.size.y / 2.0, spot.y)
	_drop = sqrt(2.0 * (_home.y - landing.y) / GRAVITY)


## Lo que pasa desde que empieza a moverse hasta que toca el suelo.
func lead() -> float:
	return SLIDE + _drop


func fall() -> void:
	fallen = true
	create_tween().tween_method(_pose, 0.0, lead() + HOP, lead() + HOP)


func _pose(t: float) -> void:
	var slide := minf(t / SLIDE, 1.0)
	var drop := clampf((t - SLIDE) / _drop, 0.0, 1.0)
	var hop := clampf((t - lead()) / HOP, 0.0, 1.0)
	position = _home.lerp(landing, SLIDE_SHARE * slide * slide + (1.0 - SLIDE_SHARE) * drop)
	position.y = lerpf(_home.y, landing.y, drop * drop) + HOP_HEIGHT * sin(PI * hop)
	var ahead := Vector3(landing.x - _home.x, 0.0, landing.z - _home.z).normalized()
	basis = Basis(Vector3.UP, YAW * drop * signf(landing.x)) * Basis(Vector3.UP.cross(ahead), TAU * drop)
