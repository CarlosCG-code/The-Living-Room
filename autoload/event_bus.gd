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
## El director suelta un suceso (specs/hito3.md D3). place: zona, puerta, lámpara, «ceiling» o «wall».
@warning_ignore("unused_signal")
signal fear_event(def: FearEventDef, place: StringName)
