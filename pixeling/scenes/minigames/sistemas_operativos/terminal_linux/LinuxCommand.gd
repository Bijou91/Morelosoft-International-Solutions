## LinuxCommand.gd - CU-16: Practicar a resolver un desafío de comandos Linux
## Morelosoft International Solutions - Materia: Sistemas Operativos y Linux
## Minijuego pixel art con simulación de terminal retro de comandos Linux (estilo Fallout 4 Hacking)
extends MiniGameBase

const LinuxQuestions = preload("res://scenes/minigames/sistemas_operativos/terminal_linux/LinuxQuestions.gd")

# Referencias del HUD superior
@onready var btn_pause: Button = $TopHUD/BtnPause
@onready var time_bar: ProgressBar = $TopHUD/TimeBar
@onready var time_label: Label = $TopHUD/TimeLabel
@onready var hearts_container: HBoxContainer = $TopHUD/HeartsContainer
@onready var question_counter_label: Label = $TopHUD/QuestionCounter

# Referencias de la sección del docente
@onready var teacher_label: Label = $TeacherSection/BubblePanel/TeacherLabel
@onready var teacher_texture: TextureRect = $TeacherSection/TeacherTexture

# Referencias de la terminal CRT
@onready var crt_panel: Panel = $CRTContainer/TerminalPanel
@onready var columns_hbox: HBoxContainer = $CRTContainer/TerminalPanel/ColumnsHBox
@onready var left_column: VBoxContainer = $CRTContainer/TerminalPanel/ColumnsHBox/LeftColumn
@onready var right_column: VBoxContainer = $CRTContainer/TerminalPanel/ColumnsHBox/RightColumn
@onready var terminal_log_label: Label = $CRTContainer/TerminalPanel/TerminalLogLabel

# Referencias de controles inferiores (D-Pad y teclado con manos)
@onready var btn_up: Button = $ControlsSection/DPad/BtnUp
@onready var btn_down: Button = $ControlsSection/DPad/BtnDown
@onready var btn_left: Button = $ControlsSection/DPad/BtnLeft
@onready var btn_right: Button = $ControlsSection/DPad/BtnRight
@onready var btn_enter: Button = $ControlsSection/BtnEnter

# Modales de interfaz
@onready var modal_difficulty: Control = $Modals/DifficultyModal
@onready var btn_diff_facil: Button = $Modals/DifficultyModal/Panel/VBox/BtnFacil
@onready var btn_diff_normal: Button = $Modals/DifficultyModal/Panel/VBox/BtnNormal
@onready var btn_diff_ing: Button = $Modals/DifficultyModal/Panel/VBox/BtnIngeniero

@onready var modal_tutorial: Control = $Modals/TutorialModal
@onready var tutorial_body: Label = $Modals/TutorialModal/Panel/VBox/Scroll/TutorialText
@onready var btn_tutorial_start: Button = $Modals/TutorialModal/Panel/VBox/BtnStartTutorial

@onready var modal_pause: Control = $Modals/PauseModal
@onready var btn_pause_resume: Button = $Modals/PauseModal/Panel/VBox/BtnResume
@onready var btn_pause_restart: Button = $Modals/PauseModal/Panel/VBox/BtnRestart
@onready var btn_pause_exit: Button = $Modals/PauseModal/Panel/VBox/BtnExit

@onready var modal_game_over: Control = $Modals/GameOverModal
@onready var game_over_desc: Label = $Modals/GameOverModal/Panel/VBox/DescLabel
@onready var btn_game_over_retry: Button = $Modals/GameOverModal/Panel/VBox/BtnRetry
@onready var btn_game_over_exit: Button = $Modals/GameOverModal/Panel/VBox/BtnExit

@onready var modal_victory: Control = $Modals/VictoryModal
@onready var victory_summary: Label = $Modals/VictoryModal/Panel/VBox/SummaryLabel
@onready var btn_victory_exit: Button = $Modals/VictoryModal/Panel/VBox/BtnExit
@onready var btn_victory_play_again: Button = $Modals/VictoryModal/Panel/VBox/BtnPlayAgain

# Texturas de corazones pixel art
var heart_full_tex: Texture2D = preload("res://assets/terminal_linux/heart_full.png")
var heart_empty_tex: Texture2D = preload("res://assets/terminal_linux/heart_empty.png")

# Catálogos para la matriz estilo Fallout
const ALL_LINUX_COMMANDS: Array[String] = [
	"pwd", "ls", "cd", "clear", "mkdir", "touch", "cat",
	"cp", "mv", "rm", "head", "tail", "less", "man",
	"grep", "find", "chmod", "sudo", "ps", "top", "kill",
	"wc", "sort", "uniq", "history"
]

const FAKE_WORDS: Array[String] = [
	"TOOL", "RACE", "TASK", "LOCK", "DATA", "USER", "HOST",
	"BYTE", "PORT", "NODE", "FAIL", "CORE", "LINK", "WALL",
	"DOME", "EAST", "LOUD", "LACK", "BALL", "DEAL", "TALK",
	"LOVE", "SAFE", "CODE", "FILE", "SCAN", "HALT", "ZONE",
	"ECHO", "BASE", "SYNC", "DROP", "PING", "TEST", "ROOT",
	"SECTOR", "CIPHER", "STATUS", "DEVICE", "SIGNAL", "DRIVER",
	"BINARY", "THREAD", "OUTPUT", "MODULE", "HEADER", "STREAM",
	"PACKET", "VECTOR", "CLIENT", "PROMPT", "SERVER"
]

const FAKE_HEX: Array[String] = [
	"0x7F", "0xAA", "0xC4", "0x9B", "0x2E", "0x5D", "0x0F", "0xEE", "0x1A", "0x8C", "0x3B", "0xD2"
]

const FAKE_BRACKETS: Array[String] = [
	"[!]", "{!}", "<*>", "(?)", "[#]", "{%}", "[:]"
]

const NOISE_CHARS: Array[String] = [
	"!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "-", "=", "+",
	"\\", "/", "|", "?", ";", ":", ",", ".", "~", "'", "\"", "[", "]", "{", "}", "<", ">"
]

# Estado de juego
const TOTAL_QUESTIONS: int = 5
const ROWS_PER_COLUMN: int = 12

# Layout de terminal por dificultad
# FACIL: 1 columna, 1 token por fila
# NORMAL: 2 columnas, 1 token por fila
# INGENIERO: 2 columnas, 2 tokens por fila
var layout_columns: int = 2   # columnas activas (1 o 2)
var layout_slots: int = 2     # tokens por fila (1 o 2)
var round_questions: Array[Dictionary] = []
var current_question_index: int = 0
var current_question: Dictionary = {}

var max_lives: int = 3
var current_lives: int = 3
var total_score: int = 0
var correct_answers_count: int = 0

# Temporizador
var time_limit_per_question: float = 25.0
var time_remaining: float = 25.0
var is_timer_active: bool = false
var is_game_paused: bool = false
var is_waiting_next: bool = false

# Matriz de tokens interactivos
var all_tokens: Array[Dictionary] = []
var active_token_index: int = 0

# Estilos de resaltado y parpadeo estilo terminal Fallout
var style_active_token: StyleBoxFlat
var style_active_token_dim: StyleBoxFlat
var style_normal_token: StyleBoxEmpty
var blink_timer: float = 0.0
var blink_state: bool = true

func _ready() -> void:
	super._ready()
	minigame_id = "terminal_linux"
	cu_id = "CU-16"
	minigame_title = "Linux Command"
	subject_name = "Sistemas Operativos y Linux"

	_setup_token_styles()
	_connect_signals()
	_hide_all_modals()
	_show_difficulty_selection()

func _setup_token_styles() -> void:
	style_normal_token = StyleBoxEmpty.new()
	style_normal_token.content_margin_left = 2.0
	style_normal_token.content_margin_right = 2.0
	style_normal_token.content_margin_top = 0.0
	style_normal_token.content_margin_bottom = 0.0

	# Cuadro completamente verde con texto negro (fase encendida)
	style_active_token = StyleBoxFlat.new()
	style_active_token.bg_color = Color("33ff55") # Verde fosforescente brillante
	style_active_token.set_corner_radius_all(1)
	style_active_token.content_margin_left = 2.0
	style_active_token.content_margin_right = 2.0
	style_active_token.content_margin_top = 0.0
	style_active_token.content_margin_bottom = 0.0

	# Cuadro verde oscuro con borde verde (fase de parpadeo)
	style_active_token_dim = StyleBoxFlat.new()
	style_active_token_dim.bg_color = Color(0.06, 0.24, 0.11, 1.0)
	style_active_token_dim.border_color = Color("33ff55")
	style_active_token_dim.set_border_width_all(1)
	style_active_token_dim.set_corner_radius_all(1)
	style_active_token_dim.content_margin_left = 2.0
	style_active_token_dim.content_margin_right = 2.0
	style_active_token_dim.content_margin_top = 0.0
	style_active_token_dim.content_margin_bottom = 0.0

func _connect_signals() -> void:
	# Controles D-Pad y Enter — solo señales internas, sin mouse/touch
	btn_up.pressed.connect(_on_dpad_up)
	btn_down.pressed.connect(_on_dpad_down)
	btn_left.pressed.connect(_on_dpad_left)
	btn_right.pressed.connect(_on_dpad_right)
	btn_enter.pressed.connect(_on_enter_pressed)
	btn_pause.pressed.connect(_on_pause_pressed)

	# Los controles D-Pad y Enter son puramente visuales (decorativos).
	# El juego se controla solo con teclado (WASD/flechas/Enter).
	# NO deshabilitar mouse_filter aquí — los botones visuales no tienen
	# señales conectadas a la lógica del juego, eso es suficiente.
	# (Los tokens de respuesta en la terminal SÍ tienen mouse_filter=IGNORE
	#  para evitar que el jugador los seleccione directamente con click/touch)

	# Selector de dificultad
	btn_diff_facil.pressed.connect(func(): _on_difficulty_chosen("FACIL"))
	btn_diff_normal.pressed.connect(func(): _on_difficulty_chosen("NORMAL"))
	btn_diff_ing.pressed.connect(func(): _on_difficulty_chosen("INGENIERO"))

	# Tutorial
	btn_tutorial_start.pressed.connect(_start_match)

	# Pausa
	btn_pause_resume.pressed.connect(_resume_game)
	btn_pause_restart.pressed.connect(_restart_match)
	btn_pause_exit.pressed.connect(_exit_to_classroom)

	# Game Over
	btn_game_over_retry.pressed.connect(_restart_match)
	btn_game_over_exit.pressed.connect(_exit_to_classroom)

	# Victoria
	btn_victory_exit.pressed.connect(_exit_to_classroom)
	btn_victory_play_again.pressed.connect(_show_difficulty_selection)

func _process(delta: float) -> void:
	if not is_timer_active or is_game_paused or is_waiting_next:
		return

	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		is_timer_active = false
		_on_time_out()

	# Parpadeo continuo del cursor en el elemento seleccionado
	blink_timer += delta
	if blink_timer >= 0.28:
		blink_timer = 0.0
		blink_state = not blink_state
		_apply_active_token_blink()

	_update_timer_display()

func _unhandled_input(event: InputEvent) -> void:
	if not is_timer_active or is_game_paused or is_waiting_next:
		return

	if event.is_action_pressed("ui_up") or (event is InputEventKey and event.pressed and event.keycode == KEY_W):
		_on_dpad_up()
	elif event.is_action_pressed("ui_down") or (event is InputEventKey and event.pressed and event.keycode == KEY_S):
		_on_dpad_down()
	elif event.is_action_pressed("ui_left") or (event is InputEventKey and event.pressed and event.keycode == KEY_A):
		_on_dpad_left()
	elif event.is_action_pressed("ui_right") or (event is InputEventKey and event.pressed and event.keycode == KEY_D):
		_on_dpad_right()
	elif event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE)):
		_on_enter_pressed()

# ==================== FLUJO DE SELECCIÓN Y TUTORIAL ====================

func _show_difficulty_selection() -> void:
	_hide_all_modals()
	modal_difficulty.visible = true
	teacher_label.text = "¡Bienvenido al Desafío de Terminal Linux!\nSelecciona el nivel de dificultad para comenzar."
	terminal_log_label.text = "ROBCO INDUSTRIES (TM) TERMLINK - INACTIVO"

func _on_difficulty_chosen(diff: String) -> void:
	AudioManager.play_click()
	current_difficulty = diff

	match diff:
		"FACIL":
			max_lives = 5
			time_limit_per_question = 30.0
			layout_columns = 1
			layout_slots = 1
		"NORMAL":
			max_lives = 3
			time_limit_per_question = 25.0
			layout_columns = 2
			layout_slots = 1
		"INGENIERO":
			max_lives = 1
			time_limit_per_question = 20.0
			layout_columns = 2
			layout_slots = 2

	current_lives = max_lives
	_show_tutorial()

func _show_tutorial() -> void:
	_hide_all_modals()
	modal_tutorial.visible = true
	
	var diff_name: String = current_difficulty.capitalize()
	var layout_desc: String
	match current_difficulty:
		"FACIL":
			layout_desc = "1 columna · 1 opción por fila — más fácil de escanear"
		"NORMAL":
			layout_desc = "2 columnas · 1 opción por fila — nivel medio"
		_:
			layout_desc = "2 columnas · 2 opciones por fila — máxima dificultad"

	var rules_text: String = """OBJETIVO DEL CASO DE USO 16:
Descifra la memoria de la terminal hacker retro y ejecuta el comando de Linux solicitado.

MECÁNICA DE TERMINAL FALLOUT:
1. Lee la situación problemática que te plantea el profesor en el globo superior.
2. En la terminal verás datos entremezclados: palabras en inglés, códigos hexadecimales, bloques de símbolos y ~7 comandos reales de Linux.
3. Solo UNO de los comandos de Linux es el correcto para la situación.
4. Usa el D-Pad (Arriba, Abajo, Izquierda, Derecha) para navegar entre los datos resaltados en verde.
5. Presiona ENTER para ejecutar el comando seleccionado.

REGLAS DE PARTIDA:
• Dificultad: %s (%d vidas) — %s
• Tiempo por desafío: %d segundos. Si el tiempo se agota, equivale a perder 1 vida.
• Seleccionar un comando erróneo o basura de memoria descontará 1 vida.
• ¡Completa los 5 desafíos para ganar estrellas y puntos para tu perfil!""" % [diff_name, max_lives, layout_desc, int(time_limit_per_question)]

	tutorial_body.text = rules_text

func _start_match() -> void:
	AudioManager.play_click()
	_hide_all_modals()
	super.start_game(current_difficulty)

	total_score = 0
	correct_answers_count = 0
	current_question_index = 0
	current_lives = max_lives
	is_game_paused = false
	is_waiting_next = false

	# Generar las 5 preguntas del banco
	round_questions = LinuxQuestions.get_round_questions(current_difficulty)
	_update_lives_hud()

	EventBus.minigame_started.emit(minigame_id, current_difficulty)
	_load_question(0)

# ==================== CARGA DE DESAFÍO Y GENERACIÓN DE MATRIZ ====================

func _load_question(index: int) -> void:
	if index >= TOTAL_QUESTIONS or index >= round_questions.size():
		_handle_victory()
		return

	current_question_index = index
	current_question = round_questions[index]
	question_counter_label.text = "DESAFÍO %d / %d" % [current_question_index + 1, TOTAL_QUESTIONS]

	# Texto del profesor
	teacher_label.text = current_question.get("situation", "¿Qué comando ejecutas?")

	# Construir la matriz completa estilo Fallout Hacking
	_build_fallout_matrix()

	# Reiniciar temporizador
	time_remaining = time_limit_per_question
	is_timer_active = true
	is_waiting_next = false
	_update_timer_display()

func _build_fallout_matrix() -> void:
	# Limpiar columnas
	for child in left_column.get_children():
		child.queue_free()
	for child in right_column.get_children():
		child.queue_free()
	all_tokens.clear()

	terminal_log_label.text = "ROBCO INDUSTRIES (TM) TERMLINK - SELECT SYSTEM COMMAND"

	# Mostrar u ocultar la columna derecha según layout
	right_column.visible = (layout_columns == 2)

	var correct_cmd: String = current_question.get("command", "pwd")

	# 1. Preparar pool de distractores de comandos reales de Linux
	var linux_pool: Array[String] = []
	for cmd in ALL_LINUX_COMMANDS:
		if cmd != correct_cmd:
			linux_pool.append(cmd)
	linux_pool.shuffle()

	var real_linux_distractors: Array[String] = []
	for i in range(mini(6, linux_pool.size())):
		real_linux_distractors.append(linux_pool[i])

	# 2. Preparar pool de falsos
	var fake_words_copy: Array = FAKE_WORDS.duplicate()
	fake_words_copy.shuffle()
	var fake_hex_copy: Array = FAKE_HEX.duplicate()
	fake_hex_copy.shuffle()
	var fake_brackets_copy: Array = FAKE_BRACKETS.duplicate()
	fake_brackets_copy.shuffle()

	# 3. Calcular cuántos tokens necesitamos según el layout
	# tokens_needed = ROWS_PER_COLUMN * layout_columns * layout_slots
	var tokens_needed: int = ROWS_PER_COLUMN * layout_columns * layout_slots

	var tokens_to_place: Array[Dictionary] = []

	# El correcto siempre va
	tokens_to_place.append({ "text": correct_cmd, "type": "CORRECT" })

	# Los distractores de comandos reales
	for cmd in real_linux_distractors:
		tokens_to_place.append({ "text": cmd, "type": "LINUX_CMD" })

	# Rellenar con falsos hasta completar tokens_needed (con margen)
	var fill_needed: int = tokens_needed - tokens_to_place.size() + 5
	for i in range(fill_needed):
		var roll: int = i % 3
		if roll == 0:
			tokens_to_place.append({ "text": fake_words_copy[i % fake_words_copy.size()], "type": "FAKE_WORD" })
		elif roll == 1:
			tokens_to_place.append({ "text": fake_hex_copy[i % fake_hex_copy.size()], "type": "FAKE_HEX" })
		else:
			tokens_to_place.append({ "text": fake_brackets_copy[i % fake_brackets_copy.size()], "type": "FAKE_BRACKET" })

	# Barajar los tokens
	tokens_to_place.shuffle()

	# GARANTÍA: la respuesta correcta debe quedar dentro del rango visible.
	# Si quedó en un índice >= tokens_needed (zona que no se coloca), la movemos
	# a una posición aleatoria dentro del rango visible.
	var correct_idx: int = -1
	for i in range(tokens_to_place.size()):
		if tokens_to_place[i].get("type", "") == "CORRECT":
			correct_idx = i
			break
	if correct_idx >= tokens_needed:
		var swap_to: int = randi() % tokens_needed
		var tmp: Dictionary = tokens_to_place[swap_to]
		tokens_to_place[swap_to] = tokens_to_place[correct_idx]
		tokens_to_place[correct_idx] = tmp

	# 4. Ajustar alineación del HBox según cantidad de columnas
	if layout_columns == 1:
		# Fácil: 1 columna centrada horizontalmente
		columns_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	else:
		# Normal/Ingeniero: 2 columnas ocupan todo el ancho
		columns_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN

	# 5. Distribuir tokens en las filas y columnas según el layout
	var token_idx: int = 0
	var base_addr_left: int = 0xD320 + current_question_index * 0x0040
	var base_addr_right: int = base_addr_left + ROWS_PER_COLUMN * 12

	for row in range(ROWS_PER_COLUMN):
		# Columna izquierda siempre presente
		var addr_l: String = "0x%04X" % (base_addr_left + row * 12)
		_create_terminal_row(left_column, 0, row, addr_l, tokens_to_place, token_idx)
		token_idx += layout_slots

		# Columna derecha solo en NORMAL e INGENIERO
		if layout_columns == 2:
			var addr_r: String = "0x%04X" % (base_addr_right + row * 12)
			_create_terminal_row(right_column, 1, row, addr_r, tokens_to_place, token_idx)
			token_idx += layout_slots

	active_token_index = 0
	_update_active_token_highlight()

func _create_terminal_row(parent_col: VBoxContainer, col_idx: int, row_idx: int, addr_str: String, token_pool: Array[Dictionary], pool_start: int) -> void:
	var row_hbox := HBoxContainer.new()
	row_hbox.custom_minimum_size = Vector2(0, 16)
	row_hbox.add_theme_constant_override("separation", 1)

	# Etiqueta de dirección hexadecimal (ej: 0xD320)
	var lbl_addr := Label.new()
	lbl_addr.text = addr_str + " "
	lbl_addr.add_theme_font_size_override("font_size", 9)
	lbl_addr.add_theme_color_override("font_color", Color(0.18, 0.65, 0.32))
	row_hbox.add_child(lbl_addr)

	# Caracteres de ruido iniciales
	row_hbox.add_child(_create_noise_label(_random_noise(1)))

	# layout_slots determina cuántos tokens van en esta fila (1 o 2)
	for slot in range(layout_slots):
		if pool_start + slot < token_pool.size():
			var t_data: Dictionary = token_pool[pool_start + slot]
			var btn := _create_token_button(t_data.text, all_tokens.size())
			row_hbox.add_child(btn)

			var token_entry := {
				"text": t_data.text,
				"type": t_data.type,
				"button": btn,
				"col": col_idx,
				"row": row_idx,
				"slot": slot,
				# grid_x: en INGENIERO hay 4 posiciones (col*2+slot),
				# en NORMAL hay 2 (col*1+slot=col), en FACIL hay 1 (siempre 0)
				"grid_x": col_idx * layout_slots + slot,
				"grid_y": row_idx,
				"index": all_tokens.size()
			}
			all_tokens.append(token_entry)

			# Caracteres de ruido entre tokens o al final
			row_hbox.add_child(_create_noise_label(_random_noise(1)))

	parent_col.add_child(row_hbox)

func _create_token_button(text: String, _token_index: int) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.flat = false
	btn.focus_mode = FOCUS_NONE
	# IMPORTANTE: deshabilitar completamente mouse y touch.
	# El jugador NO puede seleccionar respuestas haciendo click/touch.
	# Solo puede navegar con el D-Pad (teclado) y confirmar con ENTER.
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_theme_font_size_override("font_size", 9)
	_set_button_visuals(btn, false, false)

	return btn

func _create_noise_label(noise_str: String) -> Label:
	var lbl := Label.new()
	lbl.text = noise_str
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color(0.25, 0.72, 0.35))
	return lbl

func _random_noise(length: int) -> String:
	var res: String = ""
	for i in range(length):
		res += NOISE_CHARS.pick_random()
	return res

func _update_active_token_highlight() -> void:
	blink_timer = 0.0
	blink_state = true
	for i in range(all_tokens.size()):
		var t_entry: Dictionary = all_tokens[i]
		var btn: Button = t_entry.button
		var is_active: bool = (i == active_token_index)
		_set_button_visuals(btn, is_active, blink_state)

func _apply_active_token_blink() -> void:
	if active_token_index >= 0 and active_token_index < all_tokens.size():
		var btn: Button = all_tokens[active_token_index].button
		_set_button_visuals(btn, true, blink_state)

func _set_button_visuals(btn: Button, is_active: bool, is_lit: bool) -> void:
	if is_active:
		var style: StyleBox = style_active_token if is_lit else style_active_token_dim
		var text_c: Color = Color("000000") if is_lit else Color("33ff55")
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("focus", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_color_override("font_color", text_c)
		btn.add_theme_color_override("font_hover_color", text_c)
		btn.add_theme_color_override("font_focus_color", text_c)
		btn.add_theme_color_override("font_pressed_color", text_c)
	else:
		btn.add_theme_stylebox_override("normal", style_normal_token)
		btn.add_theme_stylebox_override("hover", style_normal_token)
		btn.add_theme_stylebox_override("focus", style_normal_token)
		btn.add_theme_stylebox_override("pressed", style_normal_token)
		var green_c := Color("33ff55")
		btn.add_theme_color_override("font_color", green_c)
		btn.add_theme_color_override("font_hover_color", Color("77ff99"))
		btn.add_theme_color_override("font_focus_color", green_c)
		btn.add_theme_color_override("font_pressed_color", green_c)

# ==================== NAVEGACIÓN D-PAD ====================

func _find_token_by_grid(gx: int, gy: int) -> int:
	for i in range(all_tokens.size()):
		var t: Dictionary = all_tokens[i]
		if t.get("grid_x", -1) == gx and t.get("grid_y", -1) == gy:
			return i
	return -1

func _on_dpad_up() -> void:
	if all_tokens.is_empty(): return
	AudioManager.play_step()
	var cur: Dictionary = all_tokens[active_token_index]
	var next_y: int = (cur.grid_y - 1 + ROWS_PER_COLUMN) % ROWS_PER_COLUMN
	var target_idx: int = _find_token_by_grid(cur.grid_x, next_y)
	if target_idx != -1:
		active_token_index = target_idx
		_update_active_token_highlight()

func _on_dpad_down() -> void:
	if all_tokens.is_empty(): return
	AudioManager.play_step()
	var cur: Dictionary = all_tokens[active_token_index]
	var next_y: int = (cur.grid_y + 1) % ROWS_PER_COLUMN
	var target_idx: int = _find_token_by_grid(cur.grid_x, next_y)
	if target_idx != -1:
		active_token_index = target_idx
		_update_active_token_highlight()

func _on_dpad_left() -> void:
	if all_tokens.is_empty(): return
	AudioManager.play_step()
	var cur: Dictionary = all_tokens[active_token_index]
	# Total de posiciones grid_x = layout_columns * layout_slots
	var total_x: int = layout_columns * layout_slots
	if total_x <= 1:
		return  # En FACIL (1 col, 1 slot) no hay movimiento lateral
	var next_x: int = (cur.grid_x - 1 + total_x) % total_x
	var target_idx: int = _find_token_by_grid(next_x, cur.grid_y)
	if target_idx != -1:
		active_token_index = target_idx
		_update_active_token_highlight()

func _on_dpad_right() -> void:
	if all_tokens.is_empty(): return
	AudioManager.play_step()
	var cur: Dictionary = all_tokens[active_token_index]
	var total_x: int = layout_columns * layout_slots
	if total_x <= 1:
		return  # En FACIL no hay movimiento lateral
	var next_x: int = (cur.grid_x + 1) % total_x
	var target_idx: int = _find_token_by_grid(next_x, cur.grid_y)
	if target_idx != -1:
		active_token_index = target_idx
		_update_active_token_highlight()

# ==================== VALIDACIÓN Y REGLAS DE NEGOCIO ====================

func _on_enter_pressed() -> void:
	if not is_timer_active or is_waiting_next:
		return
	if active_token_index < 0 or active_token_index >= all_tokens.size():
		return

	var token_entry: Dictionary = all_tokens[active_token_index]
	_validate_token(token_entry)

func _validate_token(token_entry: Dictionary) -> void:
	is_timer_active = false
	is_waiting_next = true
	var chosen_text: String = token_entry.text
	var token_type: String = token_entry.type
	var correct_cmd: String = current_question.get("command", "")

	if token_type == "CORRECT" or chosen_text == correct_cmd:
		# Acierto (FN-04, FN-05, FN-06, FN-07)
		correct_answers_count += 1
		AudioManager.play_success()

		var base_points: int = 150
		match current_difficulty:
			"FACIL": base_points = 100
			"NORMAL": base_points = 200
			"INGENIERO": base_points = 350

		var time_bonus: int = int(time_remaining * 8)
		var round_points: int = base_points + time_bonus
		total_score += round_points

		terminal_log_label.text = "[ ACCESO CONCEDIDO ]\nCOMANDO '%s' VÁLIDO (+%d pts)" % [chosen_text, round_points]
		teacher_label.text = current_question.get("feedback_correct", "¡Comando correcto!")

		await get_tree().create_timer(2.0).timeout
		if is_inside_tree():
			_load_question(current_question_index + 1)

	elif token_type == "LINUX_CMD":
		# Es un comando de Linux real, pero no el que resuelve la situación
		AudioManager.play_error()
		terminal_log_label.text = "[ ACCESO DENEGADO ]\n'%s' NO RESUELVE ESTA SITUACIÓN" % chosen_text
		teacher_label.text = "El comando '%s' es un comando real de Linux, pero no resuelve la situación planteada. El requerido era '%s'." % [chosen_text, correct_cmd]
		_deduct_life("Comando incorrecto para la situación")

	else:
		# Es una palabra falsa, hex o corchete de ruido
		AudioManager.play_error()
		terminal_log_label.text = "[ ERROR DE SINTAXIS ]\n'%s' NO ES UN COMANDO LINUX" % chosen_text
		teacher_label.text = "¡Cuidado! '%s' es un dato residual de memoria en la terminal, no un comando de Linux. Busca entre los comandos del sistema." % chosen_text
		_deduct_life("Sintaxis inválida seleccionada")

func _on_time_out() -> void:
	AudioManager.play_error()
	terminal_log_label.text = "[ TIEMPO EXPIRADO ]\nSESIÓN TERMINADA POR INACTIVIDAD"
	teacher_label.text = "¡Se agotó el tiempo límite para responder este desafío!"
	_deduct_life("Tiempo límite agotado")

func _deduct_life(reason: String) -> void:
	current_lives = maxi(0, current_lives - 1)
	_update_lives_hud()
	EventBus.life_lost.emit(current_lives)

	if current_lives <= 0:
		_handle_game_over(reason)
	else:
		is_waiting_next = true
		await get_tree().create_timer(2.2).timeout
		if is_inside_tree():
			_load_question(current_question_index + 1)

func _handle_game_over(reason: String) -> void:
	is_timer_active = false
	is_waiting_next = false
	AudioManager.play_game_over()
	EventBus.game_over.emit(minigame_id)

	game_over_desc.text = "Causa: %s.\nTe has quedado sin vidas en dificultad %s.\n(No se registrará puntuación según el reglamento)." % [reason, current_difficulty]
	modal_game_over.visible = true

func _handle_victory() -> void:
	is_timer_active = false
	is_waiting_next = false
	AudioManager.play_success()

	var stars: int = 1
	if current_lives == max_lives:
		stars = 3
	elif current_lives >= 2:
		stars = 2

	var lives_bonus: int = current_lives * 50
	total_score += lives_bonus

	finish_game(true, total_score, stars, "Desafío de Comandos Linux completado con éxito")

	victory_summary.text = """¡Ronda de 5 desafíos superada con éxito!

• Dificultad: %s
• Aciertos: %d / 5
• Vidas conservadas: %d / %d
• Estrellas obtenidas: %d / 3
• Puntuación total registrada: %d puntos""" % [current_difficulty, correct_answers_count, current_lives, max_lives, stars, total_score]

	modal_victory.visible = true

# ==================== HUD Y VISUALES ====================

func _update_timer_display() -> void:
	var ratio: float = clampf(time_remaining / time_limit_per_question, 0.0, 1.0)
	time_bar.value = ratio * 100.0
	time_label.text = "%02d s" % int(ceil(time_remaining))

func _update_lives_hud() -> void:
	for child in hearts_container.get_children():
		child.queue_free()

	for i in range(max_lives):
		var heart_rect := TextureRect.new()
		heart_rect.custom_minimum_size = Vector2(16, 16)
		heart_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		if i < current_lives:
			heart_rect.texture = heart_full_tex
		else:
			heart_rect.texture = heart_empty_tex

		hearts_container.add_child(heart_rect)

# ==================== PAUSA Y NAVEGACIÓN ====================

func _on_pause_pressed() -> void:
	AudioManager.play_click()
	is_game_paused = true
	modal_pause.visible = true

func _resume_game() -> void:
	AudioManager.play_click()
	is_game_paused = false
	modal_pause.visible = false

func _restart_match() -> void:
	AudioManager.play_click()
	_hide_all_modals()
	_start_match()

func _exit_to_classroom() -> void:
	AudioManager.play_click()
	if ResourceLoader.exists("res://scenes/classroom/SistemaOperativoLinux.tscn"):
		get_tree().change_scene_to_file("res://scenes/classroom/SistemaOperativoLinux.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/campus/Lobby.tscn")

func _hide_all_modals() -> void:
	modal_difficulty.visible = false
	modal_tutorial.visible = false
	modal_pause.visible = false
	modal_game_over.visible = false
	modal_victory.visible = false
