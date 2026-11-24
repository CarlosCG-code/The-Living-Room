class_name FearEventDef
extends Resource

# Un suceso del director (specs/hito3.md D3).

enum Kind { SOUND, LAMP, TV_FRAME }
enum Mandatory { NONE, ON_PURCHASE, ON_PROGRESS }

@export var id: StringName
@export var kind := Kind.SOUND
@export var min_progress := 0.0
## Máquina que hace falta tener (vacío = ninguna).
@export var requires: StringName
@export var mandatory := Mandatory.NONE
## Progreso al que sale obligatoriamente; con ON_PURCHASE, aunque no se compre la máquina (2 = nunca).
@export var mandatory_progress := 2.0
## Entra en el sorteo de las tandas.
@export var random := true
@export var cooldown := 0.0
## En los sonidos, la del archivo más largo más 1,5 s de preludio.
@export var duration := 0.0
@export var places: Array[StringName] = []
@export var sounds: Array[AudioStream] = []
@export var volume_db := 0.0
@export var subtitle_key := ""
