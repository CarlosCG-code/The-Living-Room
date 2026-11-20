class_name SoundOcclusion
extends RefCounted

# Cuántos muros y puertas hay en la recta entre quien escucha y una fuente de sonido (usuario, 2026-11-20: la
# tele y la lluvia se oían en toda la casa). Los muebles (Solid_*, SeatSofa) y el jugador no cuentan: no tapan
# el sonido de una habitación. Aproximación por línea recta: una puerta abierta en la línea de visión deja pasar.


static func obstacles(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, max_count := 3) -> int:
	var dir := (to - from).normalized()
	var q := PhysicsRayQueryParameters3D.create(from, to)
	var count := 0
	while count < max_count and from.distance_to(to) > 0.05:
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			break
		var c: Object = hit["collider"]
		var n := String((c as Node).name) if c is Node else ""
		if not (c is CharacterBody3D or n.begins_with("Solid_") or n.begins_with("SeatSofa")):
			count += 1
		# Sigue desde dentro del obstáculo: un rayo que empieza dentro de una forma no la vuelve a tocar.
		q.from = (hit["position"] as Vector3) + dir * 0.02
		if (to - q.from).dot(dir) <= 0.0:
			break
	return count
