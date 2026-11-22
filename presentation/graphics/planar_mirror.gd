class_name PlanarMirror
extends Node3D

# Espejo de verdad (usuario, 2026-11-22: con la sonda de reflejo salía negro o raro): una cámara reflejada al otro
# lado del cristal pinta la habitación en un SubViewport y un quad lo muestra encima del cristal. Proyección de
# tronco (FRUSTUM) ajustada al cristal con el plano cercano sobre él: no hace falta recortar lo que hay detrás.
# Solo se pinta si el espejo sale en pantalla, está cerca y se mira de frente; GraphicsSettings fija las filas
# («mirror_rows»; 0 = apagado).

const MAX_DISTANCE := 6.0
const GLASS_LAYER := 1 << 19  # el quad no se ve desde su propia cámara

var _size: Vector2  # ancho y alto del cristal (m)
var _centre: Vector3
var _normal: Vector3  # hacia la habitación
var _right: Vector3  # derecha del cristal vista desde la habitación
var _rows := 512
var _viewport: SubViewport
var _camera: Camera3D
var _material: ShaderMaterial
var _on_screen := false


## Punto reflejado en el plano (punto del plano, normal unitaria).
static func reflect_point(p: Vector3, plane_point: Vector3, normal: Vector3) -> Vector3:
	return p - 2.0 * normal * (p - plane_point).dot(normal)


## Derecha del cristal vista desde la habitación (se mira hacia −normal con el techo arriba).
static func right_of(normal: Vector3) -> Vector3:
	return (-normal).cross(Vector3.UP).normalized()


## Cámara del reflejo: en el punto reflejado del ojo, mirando a la habitación; su derecha es la izquierda del
## espejo (el shader da la vuelta a la imagen). El plano cercano va 1 cm por delante del cristal: el del modelo
## (de dos caras) quedaba justo en él y tapaba la vista. Devuelve [transform, desplazamiento, cerca, escala]: el
## tronco se mide en el plano cercano, así que el alto del cristal se multiplica por la escala.
static func mirror_camera(eye: Vector3, centre: Vector3, normal: Vector3, right: Vector3) -> Array:
	var pos := reflect_point(eye, centre, normal)
	var up := normal.cross(right)
	var to_glass := centre - pos
	var depth := to_glass.dot(normal)
	var k := (depth + 0.01) / depth
	return [Transform3D(Basis(-right, up, -normal), pos), Vector2(to_glass.dot(-right), to_glass.dot(up)) * k, depth + 0.01, k]


## centre y normal en coordenadas globales; size en metros.
func setup(centre: Vector3, normal: Vector3, size: Vector2) -> void:
	_size = size
	_centre = centre
	_normal = normal.normalized()
	_right = right_of(_normal)
	add_to_group(&"mirrors")
	_viewport = SubViewport.new()
	_viewport.positional_shadow_atlas_size = 2048  # sin atlas las lámparas con sombra atraviesan los muros
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_viewport.use_hdr_2d = true  # luz lineal sin recortar: la curva y la exposición las pone la pantalla principal
	add_child(_viewport)
	_camera = Camera3D.new()
	# Sin interpolación física: la cámara se coloca cada fotograma ya con la posición interpolada del ojo. Interpolada
	# otra vez, iba por detrás de su plano cercano (que no se interpola) y, al acercarse al espejo, el plano quedaba
	# detrás del muro y se veía la pared de la habitación de atrás (usuario, 2026-11-22).
	_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_camera.projection = Camera3D.PROJECTION_FRUSTUM
	_camera.cull_mask &= ~GLASS_LAYER
	_viewport.add_child(_camera)
	_use_world_environment.call_deferred()
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = size
	quad.mesh = mesh
	quad.layers = GLASS_LAYER
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_material = ShaderMaterial.new()
	_material.shader = preload("res://presentation/graphics/planar_mirror.gdshader")
	_material.set_shader_parameter(&"reflection", _viewport.get_texture())
	quad.material_override = _material
	add_child(quad)
	# El quad mira a +Z: se gira hacia la habitación, 6 mm por delante del cristal (a 2 mm la pared asomaba al moverse).
	quad.global_transform = Transform3D(Basis(_right, _normal.cross(_right), _normal), centre + _normal * 0.006)
	var notifier := VisibleOnScreenNotifier3D.new()
	notifier.aabb = AABB(Vector3(-size.x / 2, -size.y / 2, -0.01), Vector3(size.x, size.y, 0.02))
	quad.add_child(notifier)
	notifier.screen_entered.connect(func() -> void: _on_screen = true)
	notifier.screen_exited.connect(func() -> void: _on_screen = false)
	set_rows(_rows)


# El reflejo se ve a través de la pantalla principal, que ya aplica tonemap, color y efectos: aquí van en lineal
# y sin los efectos caros (SSAO, SSIL, niebla, brillo), o la imagen salía dos veces oscurecida y costaba el doble.
func _use_world_environment() -> void:
	var world_env := get_world_3d().environment
	if world_env == null:
		return
	var env := world_env.duplicate() as Environment
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	env.adjustment_enabled = false
	env.ssao_enabled = false
	env.ssil_enabled = false
	env.volumetric_fog_enabled = false
	env.glow_enabled = false
	_camera.environment = env


func set_rows(rows: int) -> void:
	_rows = rows
	if _viewport and rows > 0:
		_viewport.size = Vector2i(maxi(1, roundi(rows * _size.x / _size.y)), rows)


# Presentación, no lógica de juego: la cámara del reflejo sigue a la del jugador cada fotograma.
func _process(_delta: float) -> void:
	var cam3d := get_viewport().get_camera_3d()
	# La posición que se dibuja (con interpolación física), no la del último tick: si no, el reflejo iba con retraso
	# y bailaba al moverse (usuario, 2026-11-22).
	var eye := cam3d.get_global_transform_interpolated().origin if cam3d else Vector3.INF
	var active := _rows > 0 and _on_screen and cam3d != null and eye.distance_to(_centre) < MAX_DISTANCE \
			and (eye - _centre).dot(_normal) > 0.05
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	if active:  # al dejar de pintarse se queda la última imagen, no un negro de golpe
		_material.set_shader_parameter(&"active", true)
		var cam := mirror_camera(eye, _centre, _normal, _right)
		_camera.global_transform = cam[0]
		_camera.set_frustum(_size.y * cam[3], cam[1], cam[2], 40.0)
