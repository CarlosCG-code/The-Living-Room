class_name MirrorMath
extends RefCounted

# Reflejo en el plano x = 0 del salón sin escala negativa: M · t · M, con M = invertir X (specs/hito2.md D14).

const _FLIP := Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1))


static func mirror_transform(t: Transform3D) -> Transform3D:
	var basis := _FLIP * t.basis * _FLIP
	var origin := Vector3(-t.origin.x, t.origin.y, t.origin.z)
	return Transform3D(basis, origin)


static var _reflected := {}  # [malla, eje] -> malla reflejada


## Refleja las mallas hijas de root en un eje (0 = x, 2 = z) sin escala negativa: con ella, Godot invierte la luz de los
## materiales de doble cara (los que exporta Blender) y la normal con que se calcula la luz rebotada.
static func reflect_meshes(root: Node, axis: int) -> void:
	var flip := _flip(axis)
	for m: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		m.transform = Transform3D(flip * m.basis * flip, flip * m.position)
		var key := [m.mesh, axis]
		if not _reflected.has(key):
			_reflected[key] = reflect_mesh(m.mesh, axis)
		m.mesh = _reflected[key]


static func reflect_mesh(mesh: Mesh, axis: int) -> Mesh:
	var flip := _flip(axis)
	var out := ImporterMesh.new()
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		for part: int in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL]:
			var points: PackedVector3Array = arrays[part]
			for i in points.size():
				points[i] = flip * points[i]
			arrays[part] = points
		if arrays[Mesh.ARRAY_TANGENT] != null:
			var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
			for i in range(0, tangents.size(), 4):
				tangents[i + axis] *= -1.0
				tangents[i + 3] *= -1.0
			arrays[Mesh.ARRAY_TANGENT] = tangents
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		indices.reverse()
		arrays[Mesh.ARRAY_INDEX] = indices
		out.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, mesh.surface_get_material(s))
	out.generate_lods(60.0, 60.0, [])  # como al importar
	return out.get_mesh()


static func _flip(axis: int) -> Basis:
	var diagonal := Vector3.ONE
	diagonal[axis] = -1.0
	return Basis.from_scale(diagonal)
