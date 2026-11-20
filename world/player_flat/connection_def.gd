class_name ConnectionDef
extends Resource

# Puerta (hoja) o vano entre dos zonas (specs/hito4a.md §5). zone_b vacío = el rellano, fuera del piso.

@export var id: StringName
## La hoja abre hacia zone_a.
@export var zone_a: StringName
@export var zone_b: StringName
@export var kind: StringName = &"leaf"  # leaf | passage
@export var start: StringName = &"closed"  # closed | ajar | locked | open
## Solo en hojas: bisagra en el suelo y dirección de la hoja cerrada (bisagra -> pestillo). Girar en positivo
## sobre Y la abre hacia zone_a.
@export var hinge: Vector3
@export var direction: Vector3
@export var width := 0.0
