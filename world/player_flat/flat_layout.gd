class_name FlatLayout
extends Resource

# Plano del piso (specs/hito4a.md D1). Datos generados por tools/blender/flat_layout.py; no se edita a mano.

@export var zones: Array[ZoneDef] = []
@export var connections: Array[ConnectionDef] = []
@export var fuse_box_zone: StringName


func find_zone(id: StringName) -> ZoneDef:
	for z in zones:
		if z.id == id:
			return z
	return null


## Zona que contiene el punto de planta (x, z de Godot); &"" si cae en un muro. En espejo se refleja el punto.
func zone_at(p: Vector2, mirrored: bool) -> StringName:
	var q := Vector2(-p.x, p.y) if mirrored else p
	for z in zones:
		if z.rect.has_point(q) or _on_far_edge(z.rect, q):
			return z.id
	return &""


## Zonas unidas a esta por cualquier conexión (hoja o vano), sin el rellano.
func neighbors(id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for c in connections:
		var other := c.zone_b if c.zone_a == id else c.zone_a if c.zone_b == id else &""
		if other != &"" and other not in out:
			out.append(other)
	return out


# Rect2.has_point excluye el borde derecho e inferior; un punto justo ahí también es de la zona.
static func _on_far_edge(r: Rect2, q: Vector2) -> bool:
	return q.x >= r.position.x and q.y >= r.position.y and q.x <= r.end.x and q.y <= r.end.y
