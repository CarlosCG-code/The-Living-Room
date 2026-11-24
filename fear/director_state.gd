class_name DirectorState
extends RefCounted

# Lo que el director necesita saber en cada tick; lo rellena Game.tick (specs/hito3.md D3). Los valores por defecto
# son los de una partida sin escena: sentado y sin lámparas a la vista.

var progress := 0.0
var owned := {}
var tv_event: StringName = &""
## false con el árbol, la carta o la Carga en pantalla.
var ui_idle := true
var player_zone: StringName = &"living_room"
## (place: StringName) -> StringName: la zona del lugar; &"" si vale con el jugador dentro (techo y pared).
var place_zone := func(place: StringName) -> StringName: return place
## () -> Array[StringName]: lámparas a la vista. Se pregunta solo al sortear: mirar cada una cuesta un rayo.
var lamps := func() -> Array[StringName]: return [] as Array[StringName]
