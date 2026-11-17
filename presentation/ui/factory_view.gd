extends Control

# Fábrica del fondo de la tele (specs/hito2.md D20). La escena la genera tools/blender/build_factory.py:
# un hijo por generador con sus máquinas («huecos») en orden de aparición. Solo pinta: lee Game.economy.

## Unidades del generador necesarias para que aparezca cada hueco (el k-ésimo pide THRESHOLDS[k]).
const THRESHOLDS: Array[int] = [1, 5, 10, 25, 50]
const FADE_IN := 0.6


func _process(_delta: float) -> void:
	show_counts(Game.economy.state.generators)


func show_counts(counts: Dictionary) -> void:
	for group in get_children():
		if group.name == &"Background":
			continue
		var owned: int = counts.get(StringName(group.name), 0)
		for k in group.get_child_count():
			var slot := group.get_child(k) as CanvasItem
			var on := owned >= THRESHOLDS[mini(k, THRESHOLDS.size() - 1)]
			if on == slot.visible:
				continue
			slot.visible = on
			if on:
				slot.modulate.a = 0.0
				slot.create_tween().tween_property(slot, "modulate:a", 1.0, FADE_IN)
