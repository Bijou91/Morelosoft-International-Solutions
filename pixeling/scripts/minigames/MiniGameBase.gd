## MiniGameBase - Contrato Arquitectónico para Minijuegos en Godot 4
## Todo minijuego (CU-07, CU-10, CU-13, CU-16) debe heredar de esta clase base.
## Responsable de la Arquitectura: Carlos Manuel Aguirre Norato (Líder Técnico)
class_name MiniGameBase
extends Control

signal game_finished(result: Dictionary)

@export var minigame_id: String = "minijuego"
@export var cu_id: String = "" # Retrocompatibilidad opcional
@export var minigame_title: String = "Minijuego"
@export var subject_name: String = "Materia"

var current_difficulty: String = "NORMAL" # FACIL, NORMAL, INGENIERO
var start_time_ms: int = 0

func _ready() -> void:
	start_time_ms = Time.get_ticks_msec()

## Método virtual que cada minijuego debe sobreescribir para inicializar su lógica y dificultad
func start_game(difficulty: String = "NORMAL") -> void:
	current_difficulty = difficulty
	start_time_ms = Time.get_ticks_msec()

## Finaliza el minijuego, registra el resultado y emite la señal al gestor de estado
func finish_game(success: bool, score: int, stars: int, message: String = "") -> void:
	var time_elapsed_sec: int = int((Time.get_ticks_msec() - start_time_ms) / 1000.0)
	var active_id: String = minigame_id if minigame_id != "" else cu_id
	var result := {
		"game_id": active_id,
		"title": minigame_title,
		"success": success,
		"score": score,
		"stars": stars,
		"message": message,
		"time_elapsed": time_elapsed_sec
	}
	
	StateManager.record_minigame_result(active_id, result)
	game_finished.emit(result)
