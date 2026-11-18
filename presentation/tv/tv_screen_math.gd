class_name TvScreenMath
extends RefCounted

# Conversión del punto donde el rayo toca la pantalla a píxeles del SubViewport (specs/hito2.md §5).
# Espacio local del plano: origen en el centro, +X a la derecha, +Y arriba, metros.
# La imagen está curvada como la de un tubo (specs/incremental_v2.md §9, cambia D5): el shader dibuja en el
# punto u del plano el píxel warp(u), así que el clic en u se manda a warp(u). La misma función, sin invertir.

## Curvatura (crt-lottes): los centros de los lados no se mueven y las esquinas salen fuera (negro).
const WARP := Vector2(0.031, 0.041)


static func hit_to_uv(local_hit: Vector3, screen_size: Vector2) -> Vector2:
	return Vector2(local_hit.x / screen_size.x + 0.5, 0.5 - local_hit.y / screen_size.y)


static func warp(uv: Vector2, k: Vector2 = WARP) -> Vector2:
	var c := uv * 2.0 - Vector2.ONE
	c *= Vector2(1.0 + c.y * c.y * k.x, 1.0 + c.x * c.x * k.y)
	return c * 0.5 + Vector2(0.5, 0.5)


static func hit_to_screen(local_hit: Vector3, screen_size: Vector2, viewport_size: Vector2i,
		k: Vector2 = WARP) -> Vector2:
	return warp(hit_to_uv(local_hit, screen_size), k) * Vector2(viewport_size)


## Dentro de la imagen (no en las esquinas negras de la curvatura).
static func is_inside(local_hit: Vector3, screen_size: Vector2, k: Vector2 = WARP) -> bool:
	var w := warp(hit_to_uv(local_hit, screen_size), k)
	return w.x >= 0.0 and w.x <= 1.0 and w.y >= 0.0 and w.y <= 1.0


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
