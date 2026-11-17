class_name TvScreenMath
extends RefCounted

# Conversión del punto donde el rayo toca la pantalla a píxeles del SubViewport (specs/hito2.md §5).
# Espacio local del plano: origen en el centro, +X a la derecha, +Y arriba, metros.


static func hit_to_screen(local_hit: Vector3, screen_size: Vector2, viewport_size: Vector2i) -> Vector2:
	var u := local_hit.x / screen_size.x + 0.5
	var v := 0.5 - local_hit.y / screen_size.y
	return Vector2(u * viewport_size.x, v * viewport_size.y)


static func is_inside(local_hit: Vector3, screen_size: Vector2) -> bool:
	return absf(local_hit.x) <= screen_size.x * 0.5 and absf(local_hit.y) <= screen_size.y * 0.5


## Punto de corte del rayo con el plano XY de plane_xform, en espacio local del plano; null si no corta.
static func ray_plane(origin: Vector3, dir: Vector3, plane_xform: Transform3D) -> Variant:
	var inv := plane_xform.affine_inverse()
	var o := inv * origin
	var d := inv.basis * dir
	if is_zero_approx(d.z):
		return null
	var t := -o.z / d.z
	if t < 0.0:
		return null
	return o + d * t
