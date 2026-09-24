## DerbyDeBateo.gd - Minijuego de Lógica y Algoritmos
## Preguntas aleatorias con temporizador. Aislado en logica/derby_de_bateo/
## Extiende MiniGameBase. Listo para sistema de vidas compartido (hooks preparados).
## Responsable del módulo: Implementación aislada para Aula 103
extends MiniGameBase

# --- Configuración por dificultad ---
# --- Configuración por dificultad ---
const TIMER_BY_DIFF: Dictionary = {
	"FACIL": 10.0,
	"NORMAL": 20.0,
	"INGENIERO": 60.0
}

const OPTIONS_BY_DIFF: Dictionary = {
	"FACIL": 2,
	"NORMAL": 3,
	"INGENIERO": 5
}
const LIVES_BY_DIFF: Dictionary = {
	"FACIL": 10,
	"NORMAL": 5,
	"INGENIERO": 3
}
const SCORE_BASE: Dictionary = {
	"FACIL": 50,
	"NORMAL": 100,
	"INGENIERO": 200
}

# --- Estado del minijuego ---
var questions: Array = []
var current_question: Dictionary = {}
var current_options: Array[String] = []
var correct_option_index: int = -1
var time_left: float = 10.0
var is_playing: bool = false
var is_answering: bool = false
var max_lives: int = 3
var current_lives: int = 3
var streak: int = 0
var total_correct: int = 0
var total_answered: int = 0
var total_score: int = 0

# --- Rutas de JSON (aisladas en esta carpeta) ---
const DATA_PATHS: Dictionary = {
	"FACIL": "res://scenes/minigames/logica/derby_de_bateo/data/questions_facil.json",
	"NORMAL": "res://scenes/minigames/logica/derby_de_bateo/data/questions_normal.json",
	"INGENIERO": "res://scenes/minigames/logica/derby_de_bateo/data/questions_ingeniero.json"
}

# --- Referencias UI ---
@onready var btn_back: Button = $TopHUD/BtnBack
@onready var lives_label: Label = $TopHUD/LivesLabel
@onready var title_label: Label = $TopHUD/Title

@onready var difficulty_selector: HBoxContainer = $VBox/DifficultySelector
@onready var btn_diff_facil: Button = $VBox/DifficultySelector/BtnDiffFacil
@onready var btn_diff_normal: Button = $VBox/DifficultySelector/BtnDiffNormal
@onready var btn_diff_ing: Button = $VBox/DifficultySelector/BtnDiffIng

@onready var status_label: Label = $VBox/StatusBanner/Label
@onready var question_panel: PanelContainer = $VBox/QuestionPanel
@onready var question_label: Label = $VBox/QuestionPanel/Margin/QuestionLabel
@onready var options_container: VBoxContainer = $VBox/OptionsContainer
@onready var timer_label: Label = $VBox/BottomBar/TimerLabel
@onready var score_label: Label = $VBox/BottomBar/ScoreLabel
@onready var streak_label: Label = $VBox/BottomBar/StreakLabel

#Logica de pausa
@onready var btn_pause: Button = $TopHUD/BtnPause
@onready var pause_overlay: ColorRect = $PauseOverlay
@onready var btn_resume: Button = $PauseOverlay/VBox/BtnResume
@onready var btn_exit: Button = $PauseOverlay/VBox/BtnExit

# Logica de Game Over
@onready var game_over_overlay: ColorRect = $GameOverOverlay
@onready var go_title_label: Label = $GameOverOverlay/VBox/TitleLabel
@onready var go_reason_label: Label = $GameOverOverlay/VBox/ReasonLabel
@onready var go_stats_label: Label = $GameOverOverlay/VBox/StatsLabel
@onready var btn_go_retry: Button = $GameOverOverlay/VBox/BtnRetry
@onready var btn_go_exit: Button = $GameOverOverlay/VBox/BtnExit

func _ready() -> void:
	super._ready()
	minigame_id = "derby_de_bateo"
	minigame_title = "Derby de Bateo: Proposiciones Lógicas"
	subject_name = "Lógica y Algoritmos"

	btn_back.pressed.connect(_on_back_pressed)
	btn_diff_facil.pressed.connect(func(): _on_difficulty_selected("FACIL"))
	btn_diff_normal.pressed.connect(func(): _on_difficulty_selected("NORMAL"))
	btn_diff_ing.pressed.connect(func(): _on_difficulty_selected("INGENIERO"))

	_show_difficulty_selector()
	set_status("Elige dificultad para comenzar el Derby de Bateo")
	
	# Conectar nuevos botones
	btn_pause.pressed.connect(_on_pause_pressed)
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)
	
	# Conectar el botón de la pantalla de Game Over
	btn_go_exit.pressed.connect(_on_go_exit_pressed)
	
	# Conectar el botón de reintentar
	btn_go_retry.pressed.connect(_on_go_retry_pressed)

	# CRÍTICO: Permitir que el menú de pausa funcione mientras el juego está congelado
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if not is_playing or is_answering:
		return
	time_left -= delta
	_update_timer_ui()
	if time_left <= 0.0:
		_on_timeout()

# ---------------------------------------------------------------------------
# Flujo principal
# ---------------------------------------------------------------------------

func start_game(difficulty: String = "NORMAL") -> void:
	super.start_game(difficulty)
	_load_questions(difficulty)
	max_lives = LIVES_BY_DIFF.get(difficulty, 3)
	current_lives = max_lives
	streak = 0
	total_correct = 0
	total_answered = 0
	total_score = 0
	is_playing = true
	is_answering = false

	difficulty_selector.visible = false
	question_panel.visible = true
	options_container.visible = true
	$VBox/BottomBar.visible = true
	
	btn_back.visible = false
	btn_pause.visible = true
	
	EventBus.minigame_started.emit(minigame_id, current_difficulty)
	_update_lives_display()
	_update_score_ui()
	_next_question()

func _on_difficulty_selected(diff: String) -> void:
	AudioManager.play_click()
	start_game(diff)

func _show_difficulty_selector() -> void:
	difficulty_selector.visible = true
	question_panel.visible = false
	options_container.visible = false
	$VBox/BottomBar.visible = false
	is_playing = false
	
	btn_back.visible = true
	if btn_pause: # Comprobación de seguridad por si el nodo aún no carga
		btn_pause.visible = false

func _load_questions(diff: String) -> void:
	questions.clear()
	var path: String = DATA_PATHS.get(diff, DATA_PATHS["NORMAL"])
	if not FileAccess.file_exists(path):
		push_error("[DerbyDeBateo] No se encontró el JSON: " + path)
		set_status("Error: no hay preguntas para esta dificultad")
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[DerbyDeBateo] No se pudo abrir: " + path)
		return

	var json_text: String = file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(json_text)
	if parsed is Array:
		questions = parsed
		questions.shuffle()
	else:
		push_error("[DerbyDeBateo] JSON inválido en: " + path)

func _next_question() -> void:
	if questions.is_empty():
		# Recargar y barajar de nuevo para modo infinito
		_load_questions(current_difficulty)
		if questions.is_empty():
			set_status("No hay preguntas disponibles")
			return

	current_question = questions.pop_front()
	_build_options()
	question_label.text = str(current_question.get("question", "Pregunta no disponible"))
	time_left = TIMER_BY_DIFF.get(current_difficulty, 10.0)
	is_answering = false
	_update_timer_ui()
	set_status("¡Responde antes de que se acabe el tiempo!")

func _build_options() -> void:
	# Limpiar botones anteriores
	for child in options_container.get_children():
		child.queue_free()

	var num_options: int = OPTIONS_BY_DIFF.get(current_difficulty, 3)
	var correct: String = str(current_question.get("correct", ""))
	var incorrects: Array = current_question.get("incorrect", [])

	# Tomar solo las incorrectas necesarias
	var selected_incorrects: Array = incorrects.duplicate()
	selected_incorrects.shuffle()
	selected_incorrects = selected_incorrects.slice(0, num_options - 1)

	current_options.clear()
	current_options.append(correct)
	for inc in selected_incorrects:
		current_options.append(str(inc))

	current_options.shuffle()
	correct_option_index = current_options.find(correct)

	for i in range(current_options.size()):
		var btn := Button.new()
		btn.text = current_options[i]
		btn.custom_minimum_size = Vector2(0, 52)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var idx := i
		btn.pressed.connect(func(): _on_option_pressed(idx))
		options_container.add_child(btn)

# ---------------------------------------------------------------------------
# Respuestas y vidas
# ---------------------------------------------------------------------------

func _on_option_pressed(index: int) -> void:
	if not is_playing or is_answering:
		return
	is_answering = true
	total_answered += 1

	if index == correct_option_index:
		_handle_correct()
	else:
		_handle_incorrect("Respuesta incorrecta")

func _on_timeout() -> void:
	if not is_playing or is_answering:
		return
	is_answering = true
	total_answered += 1
	_handle_incorrect("¡Se acabó el tiempo!")

func _handle_correct() -> void:
	AudioManager.play_success()
	total_correct += 1
	streak += 1
	var points: int = SCORE_BASE.get(current_difficulty, 100)
	# Bonus por racha
	points += mini(streak * 10, 50)
	total_score += points
	set_status("¡Correcto! +%d pts  |  Racha: %d" % [points, streak])
	_update_score_ui()

	# Pequeña pausa visual y siguiente pregunta (modo infinito mientras haya vidas)
	await get_tree().create_timer(0.9).timeout
	if is_playing and current_lives > 0:
		_next_question()

func _handle_incorrect(reason: String) -> void:
	AudioManager.play_error()
	streak = 0
	_deduct_life(reason)

func _deduct_life(reason: String) -> void:
	current_lives = maxi(0, current_lives - 1)
	_update_lives_display()
	EventBus.life_lost.emit(current_lives)

	if current_lives <= 0:
		_handle_game_over(reason)
	else:
		set_status("%s  (-1 vida. Quedan %d)" % [reason, current_lives])
		await get_tree().create_timer(1.2).timeout
		if is_playing:
			_next_question()

func _handle_game_over(reason: String) -> void:
	is_playing = false
	AudioManager.play_game_over()
	EventBus.game_over.emit(minigame_id)

	var stars: int = 0
	if total_correct >= 10:
		stars = 3
	elif total_correct >= 5:
		stars = 2
	elif total_correct >= 2:
		stars = 1

	var final_score: int = total_correct * SCORE_BASE.get(current_difficulty, 100)
	
	# Mostrar mensaje rápido en el banner
	set_status("GAME OVER. Revisa tus resultados.")
	
	# Llenar la pantalla de estadísticas
	go_reason_label.text = reason
	go_stats_label.text = "Aciertos: %d\nPuntos Totales: %d\nEstrellas: %d" % [total_correct, final_score, stars]
	
	# Llamar a finish_game para guardar el progreso internamente
	finish_game(total_correct > 0, final_score, stars, "Derby finalizado con %d aciertos" % total_correct)
	
	# Mostrar la pantalla superpuesta
	game_over_overlay.visible = true

# ---------------------------------------------------------------------------
# UI helpers
# ---------------------------------------------------------------------------

func _update_timer_ui() -> void:
	if timer_label:
		var secs: int = ceili(maxf(0.0, time_left))
		
		timer_label.text = "⏱ %ds" % secs
		if secs <= 3:
			timer_label.modulate = Color(1.0, 0.3, 0.3)
		else:
			timer_label.modulate = Color.WHITE

func _update_lives_display() -> void:
	if lives_label:
		lives_label.text = "Vidas: %d / %d" % [current_lives, max_lives]

func _update_score_ui() -> void:
	if score_label:
		score_label.text = "Aciertos: %d | Pts: %d" % [total_correct, total_score]
	if streak_label:
		streak_label.text = "Racha: %d" % streak

func set_status(msg: String) -> void:
	if status_label:
		status_label.text = msg

func _on_back_pressed() -> void:
	AudioManager.play_click()
	is_playing = false
	# Preferir volver al aula de Lógica si existe
	if ResourceLoader.exists("res://scenes/classroom/AulaLogica.tscn"):
		get_tree().change_scene_to_file("res://scenes/classroom/AulaLogica.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/campus/Lobby.tscn")

# ---------------------------------------------------------------------------
# Sistema de Pausa
# ---------------------------------------------------------------------------

func _on_pause_pressed() -> void:
	# Evitar pausar si estamos en el selector de dificultad o procesando un error
	if not is_playing or is_answering:
		return
	
	AudioManager.play_click()
	get_tree().paused = true
	pause_overlay.visible = true

func _on_resume_pressed() -> void:
	AudioManager.play_click()
	get_tree().paused = false
	pause_overlay.visible = false

func _on_exit_pressed() -> void:
	# Despausar antes de cambiar de escena para evitar bugs en el aula
	get_tree().paused = false 
	_on_back_pressed()

func _on_go_exit_pressed() -> void:
	AudioManager.play_click()
	# Esto utilizará tu lógica existente para volver al aula
	_on_back_pressed()
	
func _on_go_retry_pressed() -> void:
	AudioManager.play_click()
	
	# Ocultar la pantalla de Game Over
	game_over_overlay.visible = false
	
	# Volver a mostrar el selector de dificultad 
	_show_difficulty_selector()
	set_status("Elige dificultad para volver a intentar")
