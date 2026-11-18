class_name LoreFragmentDef
extends Resource

## Fragmento de lore que cruza la señal de la tele (specs/incremental_v2.md §7): sale cuando la Energía
## producida en la run pasa ratio × umbral. No suma Evidencia.

@export var run: int = 1  ## run en la que sale (1-4)
@export var ratio: float  ## fracción del umbral (puede pasar de 1: premia esperar)
@export var text_key: String
## Si no está vacío, solo sale con esa permanente comprada (p. ej. &"name": la tabla te reconoce).
@export var needs_perk: StringName
