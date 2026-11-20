class_name RoomActivation
extends RefCounted

# Qué zonas llevan su VoxelGI encendido (specs/hito4a.md D8): la actual, siempre primera, y sus vecinas por
# cualquier conexión, de la más cercana a la más lejana, como mucho MAX (el límite de VoxelGI de Forward+).

const MAX := 8


static func active(layout: FlatLayout, zone: StringName, from: Vector2) -> Array[StringName]:
	var near := layout.neighbors(zone)
	var dist := {}
	for id in near:
		dist[id] = _distance(layout.find_zone(id).rect, from)
	near.sort_custom(func(a: StringName, b: StringName) -> bool:
		return dist[a] < dist[b] or (dist[a] == dist[b] and String(a) < String(b)))
	var out: Array[StringName] = [zone]
	out.append_array(near.slice(0, MAX - 1))
	return out


static func _distance(r: Rect2, p: Vector2) -> float:
	return p.distance_to(p.clamp(r.position, r.end))
