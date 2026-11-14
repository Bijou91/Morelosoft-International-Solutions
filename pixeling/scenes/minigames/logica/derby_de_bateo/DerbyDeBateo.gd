## DerbyDeBateo.gd - Minijuego de Lógica y Algoritmos
## Preguntas aleatorias con temporizador. Aislado en logica/derby_de_bateo/
## Extiende MiniGameBase. Listo para sistema de vidas compartido (hooks preparados).
## Responsable del módulo: Implementación aislada para Aula 103
extends MiniGameBase

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

const DIFFICULTY_CONFIG: Dictionary = {
	"FACIL": {
		"name": "FÁCIL",
		"description": "10 vidas, 10s por pregunta, 2 opciones.\n50 pts base por acierto (+bonus de racha)."
	},
	"NORMAL": {
		"name": "NORMAL",
		"description": "5 vidas, 20s por pregunta, 3 opciones.\n100 pts base por acierto (+bonus de racha)."
	},
	"INGENIERO": {
		"name": "INGENIERO",
		"description": "3 vidas, 60s por pregunta, 5 opciones.\n200 pts base por acierto (+bonus de racha)."
	}
}

# --- Assets visuales y de audio (aislados en esta carpeta) ---
const ASSET_DIR: String = "res://assets/logica/derby_de_bateo/"
const STADIUM_DIM: Color = Color(0.42, 0.45, 0.56, 1.0)   # oscurece el estadio para no opacar el texto
const HOME_RUN_SIZE: float = 240.0                         # tamaño del pop-up "HOME RUN!" en pantalla
const HOME_RUN_POP_TIME: float = 0.22
const HOME_RUN_HOLD_TIME: float = 0.35
const HOME_RUN_FADE_TIME: float = 0.25

var _stadium_bg: TextureRect = null
var _home_run_popup: TextureRect = null
var _home_run_tween: Tween = null
var _sfx_charge: AudioStreamPlayer = null
var _sfx_wrong: AudioStreamPlayer = null

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

# Overlay de Instrucciones (idéntico a Cinturón de Hipótesis)
var instructions_overlay: ColorRect
var instr_diff_label: Label
var instr_desc_label: Label
var flow_template: Control

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

	_build_instructions_overlay()
	_build_visuals_and_audio()

	# Estabilizar recuadros de texto y HUD
	lock_dynamic_label_box(status_label, status_label.get_parent() as Control, 38.0, 12, 7, 4.0, 2.0, true, true, 4.0)
	lock_dynamic_label_box(question_label, question_panel, 96.0, 13, 8, 6.0, 4.0, true, true, 6.0)
	stabilize_hud_label(lives_label, 86.0)
	stabilize_hud_label(timer_label, 52.0)
	stabilize_hud_label(score_label, 120.0)
	stabilize_hud_label(streak_label, 68.0)

	btn_back.pressed.connect(_on_back_pressed)
	btn_diff_facil.pressed.connect(func(): _on_difficulty_selected("FACIL"))
	btn_diff_normal.pressed.connect(func(): _on_difficulty_selected("NORMAL"))
	btn_diff_ing.pressed.connect(func(): _on_difficulty_selected("INGENIERO"))

	_build_flow_template()
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

# ---------------------------------------------------------------------------
# Fondo de estadio, pop-up de Home Run y efectos de sonido propios del minijuego
# ---------------------------------------------------------------------------

func _load_asset(file_name: String) -> Resource:
	var path: String = ASSET_DIR + file_name
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("[DerbyDeBateo] No se encontró el asset: " + path + " (abre el proyecto en el editor para importarlo)")
	return null

func _build_visuals_and_audio() -> void:
	# Estadio: ocupa toda la pantalla, ajustado a la altura (sin deformarse), y va oscurecido
	var stadium_tex := _load_asset("estadio_beisbol.png") as Texture2D
	if stadium_tex != null:
		_stadium_bg = TextureRect.new()
		_stadium_bg.name = "StadiumBg"
		_stadium_bg.texture = stadium_tex
		_stadium_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		_stadium_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		# Ajuste por ALTURA: escala uniforme (sin deformar), centrado, y recorta lo que sobre a los lados
		_stadium_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_stadium_bg.modulate = STADIUM_DIM
		_stadium_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_stadium_bg)
		move_child(_stadium_bg, 1)   # justo encima del ColorRect de fondo, debajo de toda la UI

	# Pop-up "HOME RUN!": justo encima del VBox y debajo de los overlays (pausa / game over)
	var hr_tex := _load_asset("home_run.png") as Texture2D
	if hr_tex != null:
		var half: float = HOME_RUN_SIZE * 0.5
		_home_run_popup = TextureRect.new()
		_home_run_popup.name = "HomeRunPopup"
		_home_run_popup.texture = hr_tex
		_home_run_popup.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_home_run_popup.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_home_run_popup.set_anchors_preset(Control.PRESET_CENTER)
		_home_run_popup.offset_left = -half
		_home_run_popup.offset_top = -half
		_home_run_popup.offset_right = half
		_home_run_popup.offset_bottom = half
		_home_run_popup.pivot_offset = Vector2(half, half)
		_home_run_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_home_run_popup.visible = false
		add_child(_home_run_popup)
		move_child(_home_run_popup, $VBox.get_index() + 1)

	# Sonidos propios (no se toca el AudioManager compartido)
	_sfx_charge = _make_sfx_player("SfxCharge", "baseball_charge.mp3")
	_sfx_wrong = _make_sfx_player("SfxWrong", "wrong_buzzer.mp3")

func _make_sfx_player(node_name: String, file_name: String) -> AudioStreamPlayer:
	var stream := _load_asset(file_name) as AudioStream
	if stream == null:
		return null
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.stream = stream
	add_child(player)
	return player

func _play_sfx(player: AudioStreamPlayer) -> void:
	player.volume_db = linear_to_db(maxf(AudioManager.sfx_volume, 0.0001))
	player.play()

func _show_home_run() -> void:
	if _home_run_popup == null:
		return
	if _home_run_tween != null and _home_run_tween.is_valid():
		_home_run_tween.kill()
	_home_run_popup.visible = true
	_home_run_popup.modulate = Color.WHITE
	_home_run_popup.scale = Vector2(0.2, 0.2)
	_home_run_popup.rotation_degrees = -12.0

	_home_run_tween = create_tween()
	_home_run_tween.set_parallel(true)
	_home_run_tween.tween_property(_home_run_popup, "scale", Vector2.ONE, HOME_RUN_POP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_home_run_tween.tween_property(_home_run_popup, "rotation_degrees", 0.0, HOME_RUN_POP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_home_run_tween.chain().tween_interval(HOME_RUN_HOLD_TIME)
	_home_run_tween.chain().tween_property(_home_run_popup, "modulate:a", 0.0, HOME_RUN_FADE_TIME)
	_home_run_tween.chain().tween_callback(func(): _home_run_popup.visible = false)

func _hide_home_run() -> void:
	if _home_run_tween != null and _home_run_tween.is_valid():
		_home_run_tween.kill()
	if _home_run_popup != null:
		_home_run_popup.visible = false

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
	_hide_home_run()
	_load_questions(difficulty)
	max_lives = LIVES_BY_DIFF.get(difficulty, 3)
	current_lives = max_lives
	streak = 0
	total_correct = 0
	total_answered = 0
	total_score = 0
	is_playing = true
	is_answering = false

	if instructions_overlay:
		instructions_overlay.visible = false
	if pause_overlay:
		pause_overlay.visible = false
	if game_over_overlay:
		game_over_overlay.visible = false
	if flow_template:
		flow_template.hide_all()
	get_tree().paused = false
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
	current_difficulty = diff
	var cfg: Dictionary = DIFFICULTY_CONFIG.get(diff, DIFFICULTY_CONFIG["NORMAL"])
	instr_diff_label.text = "Dificultad: %s" % cfg["name"]
	instr_desc_label.text = cfg["description"]
	difficulty_selector.visible = false
	btn_back.visible = false
	instructions_overlay.visible = true

func _on_start_game_pressed() -> void:
	AudioManager.play_click()
	if instructions_overlay:
		instructions_overlay.visible = false
	start_game(current_difficulty)

func _build_flow_template() -> void:
	flow_template = create_flow_template({
		"title": "Derby de Bateo",
		"subtitle": "CU-13 · Proposiciones Lógicas",
		"classroom_path": "res://scenes/classroom/AulaLogica.tscn",
		"objective": "Resuelve proposiciones y silogismos lógicos antes de que se agote el tiempo.",
		"rules": [
			"Lee atentamente la proposición o silogismo lógico en pantalla.",
			"Selecciona la opción correcta antes de que se agote el tiempo.",
			"Cada fallo o tiempo agotado resta 1 vida (-1 ❤️).",
			"¡Encadena aciertos consecutivos para ganar bonus por racha!"
		],
		"difficulties": {
			"FACIL": {
				"name": "Fácil",
				"info": "Fácil: " + DIFFICULTY_CONFIG["FACIL"]["description"]
			},
			"NORMAL": {
				"name": "Normal",
				"info": "Normal: " + DIFFICULTY_CONFIG["NORMAL"]["description"]
			},
			"INGENIERO": {
				"name": "Ingeniero",
				"info": "Ingeniero: " + DIFFICULTY_CONFIG["INGENIERO"]["description"]
			}
		},
		"default_difficulty": "NORMAL",
		"on_start": func(diff: String):
			current_difficulty = diff
			start_game(diff),
		"on_back": func():
			_on_back_pressed(),
		"on_resume": func():
			_on_resume_pressed(),
		"on_restart": func():
			start_game(current_difficulty)
	})


func _show_difficulty_selector() -> void:
	if instructions_overlay:
		instructions_overlay.visible = false
	if pause_overlay:
		pause_overlay.visible = false
	if game_over_overlay:
		game_over_overlay.visible = false
	difficulty_selector.visible = false if flow_template else true
	question_panel.visible = false
	options_container.visible = false
	$VBox/BottomBar.visible = false
	is_playing = false

	btn_back.visible = false if flow_template else true
	if btn_pause: # Comprobación de seguridad por si el nodo aún no carga
		btn_pause.visible = false
	if flow_template:
		flow_template.show_instructions()

# ---------------------------------------------------------------------------
# Construcción del Overlay de Instrucciones (Estilo Cinturón de Hipótesis)
# ---------------------------------------------------------------------------

func _build_instructions_overlay() -> void:
	instructions_overlay = _create_overlay()
	add_child(instructions_overlay)
	var i_vbox := _create_overlay_vbox(instructions_overlay, "INSTRUCCIONES", "Cómo jugar")

	instr_diff_label = Label.new()
	instr_diff_label.text = "Dificultad: NORMAL"
	instr_diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instr_diff_label.add_theme_font_size_override("font_size", 14)
	instr_diff_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	i_vbox.add_child(instr_diff_label)

	instr_desc_label = Label.new()
	instr_desc_label.text = ""
	instr_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instr_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instr_desc_label.add_theme_font_size_override("font_size", 12)
	i_vbox.add_child(instr_desc_label)

	var rules_label := Label.new()
	rules_label.text = "• Lee atentamente la proposición o silogismo lógico en pantalla.\n• Selecciona la opción correcta antes de que se agote el tiempo.\n• Cada fallo o tiempo agotado resta 1 vida (-1 ❤️).\n• ¡Encadena aciertos consecutivos para ganar bonus por racha!"
	rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_label.add_theme_font_size_override("font_size", 11)
	rules_label.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	i_vbox.add_child(rules_label)

	var start_btn := Button.new()
	start_btn.text = "COMENZAR PARTIDA"
	start_btn.custom_minimum_size = Vector2(250, 44)
	var s_sb := StyleBoxFlat.new()
	s_sb.bg_color = Color(0.2, 0.6, 0.3, 0.9)
	s_sb.set_corner_radius_all(6)
	start_btn.add_theme_stylebox_override("normal", s_sb)
	start_btn.pressed.connect(_on_start_game_pressed)
	i_vbox.add_child(start_btn)

func _create_overlay() -> ColorRect:
	var cr := ColorRect.new()
	cr.set_anchors_preset(PRESET_FULL_RECT)
	cr.color = Color(0.04, 0.06, 0.1, 0.94)
	cr.visible = false
	return cr

func _create_overlay_vbox(parent: Control, title: String, subtitle: String) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	parent.add_child(center)

	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(310, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.13, 0.20, 0.98)
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.3, 0.5, 0.8, 0.8)
	p.add_theme_stylebox_override("panel", sb)
	center.add_child(p)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	p.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 16)
	t.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	vbox.add_child(t)

	if subtitle != "":
		var s := Label.new()
		s.text = subtitle
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.add_theme_font_size_override("font_size", 11)
		s.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
		vbox.add_child(s)

	return vbox

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
		lock_dynamic_button_box(btn, 48.0, 11, 7, true, 280.0)

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
	# Acierto: pop-up "HOME RUN!" + efecto de carga de béisbol al mismo tiempo
	_show_home_run()
	if _sfx_charge != null:
		_play_sfx(_sfx_charge)
	else:
		AudioManager.play_success()   # respaldo si falta el mp3
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
	if _sfx_wrong != null:
		_play_sfx(_sfx_wrong)
	else:
		AudioManager.play_error()   # respaldo si falta el mp3
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
	_hide_home_run()
	AudioManager.play_game_over()
	EventBus.game_over.emit(minigame_id)

	var stars: int = 0
	if total_correct >= 10:
		stars = 3
	elif total_correct >= 5:
		stars = 2
	elif total_correct >= 2:
		stars = 1

	var final_score: int = total_score
	var prev_high: int = StateManager.get_minigame_high_score(minigame_id) if StateManager else 0
	var is_record: bool = final_score > prev_high

	# Mostrar mensaje rápido en el banner
	set_status("GAME OVER. Revisa tus resultados.")

	# Llenar la pantalla de estadísticas
	go_reason_label.text = reason
	go_stats_label.text = "Aciertos: %d\nPuntos Totales: %d\nEstrellas: %d" % [total_correct, final_score, stars]

	# Llamar a finish_game para guardar el progreso internamente
	finish_game(total_correct > 0, final_score, stars, "Derby finalizado con %d aciertos" % total_correct)

	if flow_template:
		if stars > 0:
			var total_accum: int = StateManager.get_points() if StateManager else final_score
			flow_template.show_victory(final_score, stars, total_accum, is_record, "¡DERBY COMPLETADO!")
		else:
			flow_template.show_game_over(reason, final_score)
		return

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
	if flow_template:
		flow_template.show_pause()
	else:
		pause_overlay.visible = true

func _on_resume_pressed() -> void:
	AudioManager.play_click()
	get_tree().paused = false
	if flow_template:
		flow_template.hide_pause()
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
