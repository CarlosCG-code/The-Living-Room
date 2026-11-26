extends Node

@warning_ignore("unused_signal")
signal purchase_made(item_id: StringName)
@warning_ignore("unused_signal")
signal run_restarted(run_index: int)
@warning_ignore("unused_signal")
signal settings_changed
## El jugador de pie entra en otra zona del piso (specs/hito4a.md D8).
@warning_ignore("unused_signal")
signal player_zone_changed(zone: StringName)
## El director suelta un suceso (specs/hito3.md D3). place: zona, puerta, lámpara o un sitio del salón (flat.gd).
@warning_ignore("unused_signal")
signal fear_event(def: FearEventDef, place: StringName)
## Los zumbidos de la tele y de la casa se cortan: el preludio de un sonido (specs/hito3.md D6).
@warning_ignore("unused_signal")
signal house_silence(seconds: float)
## Momento de una secuencia (specs/hito4b.md D1): knock, stand, el nombre del paso nuevo, o finished.
@warning_ignore("unused_signal")
signal sequence_cue(id: StringName)
