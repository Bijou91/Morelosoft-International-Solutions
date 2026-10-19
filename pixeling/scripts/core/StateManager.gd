## StateManager - PixelIng Core
## Gestor de Estado y Persistencia Local en Godot (user://save_data.json)
## Cumple con la rúbrica SI.03 (Persistencia Offline)
## Responsable: Carlos Manuel Aguirre Norato (Líder Técnico)
extends Node

const SAVE_PATH: String = "user://pixeling_save.json"

const DEFAULT_SETTINGS := {
	"sfx_volume": 1.0,
	"music_volume": 1.0,
	"blue_light_filter": false,
	"high_contrast": false
}

var _contrast_canvas: CanvasLayer = null
var _blue_light_canvas: CanvasLayer = null

var player_data: Dictionary = {
	"profile": {
		"username": "Novato_UAZ",
		"avatar": "rookie"
	},
	"economy": {
		"points": 0
	},
	"settings": {
		"sfx_volume": 1.0,
		"music_volume": 1.0,
		"blue_light_filter": false,
		"high_contrast": false
	},
	"progress": {
		"current_classroom": "classroom_programming",
		"minigames": {
			"roboflow": { "completed": false, "score": 0, "stars": 0 },
			"lluvia_requerimientos": { "completed": false, "score": 0, "stars": 0 },
			"tablas_verdad": { "completed": false, "score": 0, "stars": 0 },
			"terminal_linux": { "completed": false, "score": 0, "stars": 0 },
			"exploracion_archivos": { "completed": false, "score": 0, "stars": 0 },
			"derby_de_bateo": { "completed": false, "score": 0, "stars": 0 },
			"mansion_escape": { "completed": false, "score": 0, "stars": 0 },
			"include_extend": { "completed": false, "score": 0, "stars": 0 },
			"datadrop": { "completed": false, "score": 0, "stars": 0 }
		}
	}
}

func _ready() -> void:
	_setup_contrast_layer()
	_setup_blue_light_layer()
	load_data()
	apply_settings_runtime(player_data.settings)
	print("[StateManager] Datos del jugador cargados: ", player_data.profile.username)

## Paleta Universal Segura para Daltónicos y Alto Contraste (Okabe-Ito / Paul Tol)
## Diseñada con separación espectral y luminancia extrema para Deuteranopía, Protanopía y Tritanopía
const COLORBLIND_PALETTE: Array[Color] = [
	Color("#0072B2"), # 1. Azul cobalto puro (480nm, máxima distinción cromática)
	Color("#E69F00"), # 2. Naranja ámbar cálido (600nm, altísimo contraste con azul)
	Color("#56B4E9"), # 3. Celeste cielo brillante
	Color("#F0E442"), # 4. Amarillo puro de alta luminancia
	Color("#009E73"), # 5. Verde azulado / turquesa profundo (distinguible de rojo/naranja)
	Color("#D55E00"), # 6. Bermellón rojizo oscuro
	Color("#CC79A7"), # 7. Rosa malva suave
	Color("#FFFFFF")  # 8. Blanco puro
]

var _preview_contrast_active: Variant = null

func is_high_contrast_active() -> bool:
	if _preview_contrast_active != null:
		return bool(_preview_contrast_active)
	return bool(player_data.settings.get("high_contrast", false))

func is_colorblind_active() -> bool:
	return is_high_contrast_active()

func get_accessible_color(index: int, fallback_color: Color) -> Color:
	if is_high_contrast_active():
		return COLORBLIND_PALETTE[index % COLORBLIND_PALETTE.size()]
	return fallback_color

func _setup_contrast_layer() -> void:
	# Sin contornos invasivos de pantalla; la accesibilidad visual se aplica
	# de forma orgánica sobre los elementos del juego y botones interactivos.
	pass

func _setup_blue_light_layer() -> void:
	if _blue_light_canvas != null:
		return
	_blue_light_canvas = CanvasLayer.new()
	_blue_light_canvas.name = "BlueLightFilterOverlay"
	_blue_light_canvas.layer = 120
	
	var tint_rect := ColorRect.new()
	tint_rect.name = "WarmTint"
	tint_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint_rect.color = Color(1.0, 0.72, 0.25, 0.16)
	tint_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blue_light_canvas.add_child(tint_rect)
	
	_blue_light_canvas.visible = false
	add_child(_blue_light_canvas)

func apply_blue_light_filter(is_active: bool) -> void:
	if _blue_light_canvas:
		_blue_light_canvas.visible = is_active

func apply_visual_contrast(is_high: bool) -> void:
	if _contrast_canvas:
		_contrast_canvas.visible = is_high
	if is_high:
		RenderingServer.set_default_clear_color(Color(0.0, 0.0, 0.0, 1.0))
	else:
		RenderingServer.set_default_clear_color(Color(0.0588235, 0.0666667, 0.101961, 1.0))

func apply_settings_runtime(settings_dict: Dictionary) -> void:
	var sfx: float = float(settings_dict.get("sfx_volume", DEFAULT_SETTINGS["sfx_volume"]))
	var music: float = float(settings_dict.get("music_volume", DEFAULT_SETTINGS["music_volume"]))
	var blue_light: bool = bool(settings_dict.get("blue_light_filter", DEFAULT_SETTINGS["blue_light_filter"]))
	var contrast: bool = bool(settings_dict.get("high_contrast", DEFAULT_SETTINGS["high_contrast"]))
	
	_preview_contrast_active = contrast
	
	AudioManager.set_sfx_volume(sfx)
	AudioManager.set_music_volume(music)
	apply_blue_light_filter(blue_light)
	apply_visual_contrast(contrast)

func get_settings() -> Dictionary:
	return player_data.settings.duplicate(true)

func get_default_settings() -> Dictionary:
	return DEFAULT_SETTINGS.duplicate(true)

func preview_settings(temp_settings: Dictionary) -> void:
	apply_settings_runtime(temp_settings)
	EventBus.settings_changed.emit(temp_settings)
	EventBus.settings_updated.emit(temp_settings)

func save_settings(new_settings: Dictionary) -> void:
	for k in DEFAULT_SETTINGS:
		player_data.settings[k] = new_settings.get(k, DEFAULT_SETTINGS[k])
	_preview_contrast_active = null
	apply_settings_runtime(player_data.settings)
	EventBus.settings_changed.emit(player_data.settings)
	EventBus.settings_updated.emit(player_data.settings)
	save_data()

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
			if parsed.has("profile") and parsed.profile is Dictionary:
				player_data.profile = parsed.profile
			if parsed.has("economy") and parsed.economy is Dictionary:
				player_data.economy = parsed.economy
			if parsed.has("progress") and parsed.progress is Dictionary:
				player_data.progress = parsed.progress
			if parsed.has("settings") and parsed.settings is Dictionary:
				player_data.settings = parsed.settings
				for k in DEFAULT_SETTINGS:
					if not player_data.settings.has(k):
						player_data.settings[k] = DEFAULT_SETTINGS[k]
			else:
				player_data.settings = DEFAULT_SETTINGS.duplicate(true)

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# F8 o Ctrl+W: Victoria instantánea en el minijuego activo
		if event.keycode == KEY_F8 or (event.keycode == KEY_W and event.ctrl_pressed and not event.shift_pressed):
			var current = get_tree().current_scene
			if current and current.has_method("_trigger_debug_win"):
				current._trigger_debug_win()
		# F9 o Ctrl+Shift+W: Desbloquear y completar todos los minijuegos con 3 estrellas
		elif event.keycode == KEY_F9 or (event.keycode == KEY_W and event.ctrl_pressed and event.shift_pressed):
			debug_unlock_all_minigames()
		# F12 o Ctrl+Shift+R: Resetear progreso para pruebas limpias
		elif event.keycode == KEY_F12 or (event.keycode == KEY_R and event.ctrl_pressed and event.shift_pressed):
			debug_reset_progress()

## Atajo de depuración: Marca todos los minijuegos como completados con 3 estrellas y otorga puntos
func debug_unlock_all_minigames() -> void:
	var all_games := [
		"lluvia_requerimientos",
		"include_extend",
		"roboflow",
		"datadrop",
		"derby_de_bateo",
		"mansion_escape",
		"terminal_linux",
		"exploracion_archivos"
	]
	var minigames: Dictionary = player_data.progress.minigames
	for g in all_games:
		minigames[g] = {
			"completed": true,
			"score": 1000,
			"stars": 3
		}
	player_data.economy.points = 8000
	save_data()
	EventBus.points_updated.emit(player_data.economy.points, 8000)
	for g in all_games:
		EventBus.minigame_completed.emit(g, minigames[g])
	print("[DEBUG QA] ¡Todos los minijuegos desbloqueados con 3 estrellas (⭐⭐⭐) y 8,000 puntos!")

## Atajo de depuración: Resetea el progreso a 0
func debug_reset_progress() -> void:
	var minigames: Dictionary = player_data.progress.minigames
	for g in minigames:
		minigames[g] = {
			"completed": false,
			"score": 0,
			"stars": 0
		}
	player_data.economy.points = 0
	save_data()
	EventBus.points_updated.emit(0, 0)
	for g in minigames:
		EventBus.minigame_completed.emit(g, minigames[g])
	print("[DEBUG QA] Progreso reseteado a 0.")
