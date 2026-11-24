class_name MirrorMath
extends RefCounted

# Reflejo en el plano x = 0 del salón sin escala negativa: M · t · M, con M = invertir X (specs/hito2.md D14).

const _FLIP := Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1))


static func mirror_transform(t: Transform3D) -> Transform3D:
	var basis := _FLIP * t.basis * _FLIP
	var origin := Vector3(-t.origin.x, t.origin.y, t.origin.z)
	return Transform3D(basis, origin)


## Con escala negativa, Godot invierte la luz de los materiales de doble cara (los que exporta Blender): se ponen de una.
static func single_sided(root: Node) -> void:
	for m: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		for s in m.mesh.get_surface_count():
			var material := m.mesh.surface_get_material(s) as BaseMaterial3D
			if material:
				material.cull_mode = BaseMaterial3D.CULL_BACK
