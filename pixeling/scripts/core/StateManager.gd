## StateManager - PixelIng Core
## Gestor de Estado y Persistencia Local en Godot (user://save_data.json)
## Cumple con la rúbrica SI.03 (Persistencia Offline)
## Responsable: Carlos Manuel Aguirre Norato (Líder Técnico)
extends Node

const SAVE_PATH: String = "user://pixeling_save.json"

var player_data: Dictionary = {
	"profile": {
		"username": "Novato_UAZ",
		"avatar": "rookie"
	},
	"economy": {
		"points": 0
	},
	"settings": {
		"sfx_volume": 0.8,
		"music_volume": 0.6,
		"high_contrast": false
	},
	"progress": {
		"current_classroom": "classroom_programming",
		"minigames": {
			"roboflow": { "completed": false, "score": 0, "stars": 0 },
			"lluvia_requerimientos": { "completed": false, "score": 0, "stars": 0 },
			"tablas_verdad": { "completed": false, "score": 0, "stars": 0 },
			"terminal_linux": { "completed": false, "score": 0, "stars": 0 },
			"derby_de_bateo": { "completed": false, "score": 0, "stars": 0 }
		}
	}
}

func _ready() -> void:
	load_data()
	print("[StateManager] Datos del jugador cargados: ", player_data.profile.username)

func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_str := JSON.stringify(player_data, "\t")
		file.store_string(json_str)
		file.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_data()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_str := file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(json_str)
		if parsed is Dictionary:
			player_data = parsed

func record_minigame_result(game_id: String, result: Dictionary) -> void:
	var minigames: Dictionary = player_data.progress.minigames
	if not minigames.has(game_id):
		minigames[game_id] = { "completed": false, "score": 0, "stars": 0 }

	var current: Dictionary = minigames[game_id]
	var score: int = result.get("score", 0)
	var stars: int = result.get("stars", 0)
	var success: bool = result.get("success", false)

	if score > current.score:
		current.score = score
	if stars > current.stars:
		current.stars = stars
	if success:
		current.completed = true

	# Sumar puntos ganados
	player_data.economy.points += score
	save_data()

	EventBus.points_updated.emit(player_data.economy.points, score)
	EventBus.minigame_completed.emit(game_id, result)

func get_minigame_data(game_id: String) -> Dictionary:
	return player_data.progress.minigames.get(game_id, { "completed": false, "score": 0, "stars": 0 })

func get_points() -> int:
	return player_data.economy.points

func get_username() -> String:
	return player_data.profile.username
