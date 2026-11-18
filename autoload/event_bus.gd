extends Node

@warning_ignore("unused_signal")
signal purchase_made(item_id: StringName)
@warning_ignore("unused_signal")
signal run_restarted(run_index: int)
@warning_ignore("unused_signal")
signal settings_changed
## La tele muestra (true) o deja de mostrar (false) el menú principal: el salón se oscurece.
@warning_ignore("unused_signal")
signal tv_menu_changed(open: bool)
