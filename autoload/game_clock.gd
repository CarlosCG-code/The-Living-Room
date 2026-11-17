extends Node

# El único _process con lógica de juego (CLAUDE.md, Arquitectura).


func _process(delta: float) -> void:
	Game.tick(delta)
