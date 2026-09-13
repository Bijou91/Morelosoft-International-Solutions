## EventBus - PixelIng Core
## Patrón de Señales Globales Desacopladas (Pub-Sub) para Godot 4
## Responsable: Carlos Manuel Aguirre Norato (Líder Técnico)
extends Node

# Señales de Navegación
signal change_scene_requested(scene_path: String, params: Dictionary)
signal location_changed(new_location_id: String)

# Señales de Minijuegos
signal minigame_started(cu_id: String, difficulty: String)
signal minigame_completed(cu_id: String, result: Dictionary)
signal life_lost(lives_remaining: int)
signal game_over(minigame_id: String)

# Señales de Estado y Economía
signal points_updated(new_total: int, delta: int)
signal settings_updated(settings_dict: Dictionary)

func _ready() -> void:
	print("[EventBus] Sistema de señales globales inicializado.")
