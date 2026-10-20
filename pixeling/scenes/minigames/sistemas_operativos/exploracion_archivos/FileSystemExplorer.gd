## FileSystemExplorer.gd - CU-17: Practicar la exploración del sistema de archivos para localizar una flag mediante comandos Linux
## Morelosoft International Solutions - Materia: Sistemas Operativos y Linux
extends MiniGameBase

const LinuxChallenges = preload("res://scenes/minigames/sistemas_operativos/exploracion_archivos/LinuxFileSystemChallenges.gd")

# HUD Superior
@onready var btn_pause: Button = $TopHUD/BtnPause
@onready var time_bar: ProgressBar = $TopHUD/TimeBar
@onready var time_label: Label = $TopHUD/TimeLabel
@onready var hearts_container: HBoxContainer = $TopHUD/HeartsContainer
@onready var challenge_label: Label = $TopHUD/ChallengeLabel

# Sección Profesor
@onready var teacher_label: Label = $TeacherSection/BubblePanel/TeacherLabel
@onready var teacher_texture: TextureRect = $TeacherSection/TeacherTexture

# Terminal Superior (Prompt y Consola de salida interactiva)
@onready var terminal_prompt_label: Label = $CRTContainer/TerminalPanel/TerminalPromptLabel
@onready var terminal_scroll: ScrollContainer = $CRTContainer/TerminalPanel/ConsoleScroll
@onready var terminal_output: RichTextLabel = $CRTContainer/TerminalPanel/ConsoleScroll/TerminalOutput

# Sección Inferior: Submit Flag
@onready var flag_input: LineEdit = $CRTContainer/TerminalPanel/SubmitSection/FlagHBox/FlagInput
@onready var btn_submit_flag: Button = $CRTContainer/TerminalPanel/SubmitSection/FlagHBox/BtnSubmit

# Sección de Controles y Botones de Comandos
@onready var commands_container: HFlowContainer = $ControlsSection/CommandsContainer
@onready var picker_modal: Control = $Modals/PickerModal
@onready var picker_title: Label = $Modals/PickerModal/Panel/VBox/PickerTitle
@onready var picker_options_container: VBoxContainer = $Modals/PickerModal/Panel/VBox/Scroll/OptionsContainer
@onready var btn_picker_cancel: Button = $Modals/PickerModal/Panel/VBox/BtnCancel

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

# Texturas de corazones
var heart_full_tex: Texture2D = preload("res://assets/terminal_linux/heart_full.png")
var heart_empty_tex: Texture2D = preload("res://assets/terminal_linux/heart_empty.png")

# Estado del desafío
var current_challenge: Dictionary = {}
var current_path: String = "/home/user"
var simulated_fs: Dictionary = {}
var max_lives: int = 3
var current_lives: int = 3
var time_limit: float = 60.0
var time_remaining: float = 60.0
var is_timer_active: bool = false
var is_game_paused: bool = false
var current_match_generation: int = 0
var total_score: int = 0

func _ready() -> void:
	super._ready()
	minigame_id = "exploracion_archivos"
	cu_id = "CU-17"
	minigame_title = "Exploración de Archivos y Flag"
	subject_name = "Sistemas Operativos y Linux"

	_connect_signals()
	_hide_all_modals()
	_show_difficulty_selection()

func _connect_signals() -> void:
	btn_pause.pressed.connect(_on_pause_pressed)
	btn_submit_flag.pressed.connect(_on_submit_flag_pressed)
	flag_input.text_submitted.connect(func(_text): _on_submit_flag_pressed())

	# Modales de Dificultad
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

	# Cancelar picker
	btn_picker_cancel.pressed.connect(_close_picker)

func _process(delta: float) -> void:
	if not is_timer_active or is_game_paused:
		return

	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_on_time_out()

	_update_timer_display()

# ==================== FLUJO DE SELECCIÓN Y TUTORIAL ====================

func _show_difficulty_selection() -> void:
	_hide_all_modals()
	modal_difficulty.visible = true
	teacher_label.text = "¡Bienvenido a la Práctica de Exploración de Archivos (CU-17)!\nSelecciona el nivel de dificultad para comenzar."
	terminal_prompt_label.text = "user@is-pixelverse:~$ [MODO INACTIVO]"

func _on_difficulty_chosen(diff: String) -> void:
	AudioManager.play_click()
	current_difficulty = diff

	match diff:
		"FACIL":
			max_lives = 3
			time_limit = 60.0
			total_score = 250
		"NORMAL":
			max_lives = 2
			time_limit = 30.0
			total_score = 500
		"INGENIERO":
			max_lives = 1
			time_limit = 40.0
			total_score = 750

	current_lives = max_lives
	_show_tutorial()

func _show_tutorial() -> void:
	_hide_all_modals()
	modal_tutorial.visible = true

	var diff_name: String = current_difficulty.capitalize()
	var rules_text: String = """INSTRUCCIONES DEL DESAFÍO:
Usa comandos de Linux para explorar el sistema de archivos, inspeccionar directorios y leer documentos hasta localizar la FLAG oculta.

CÓMO JUGAR:
1. Lee la situación planteada por el profesor en la parte superior.
2. Utiliza los botones de comandos interactivos ubicados en la parte inferior (ls, cd, cat, head, tail, etc.).
3. Al presionar comandos con destino (como 'cd' o 'cat'), podrás seleccionar el archivo o carpeta deseada.
4. Cuando encuentres la flag dentro de los archivos, escríbela en el campo inferior SUBMIT FLAG tal como aparece: Flag{...} y presiona ENVIAR.

REGLAS DE PARTIDA:
• Dificultad: %s (%d vidas)
• Puntuación de recompensa: %d puntos
• Tiempo por intento: %d segundos
• Si el tiempo se agota o envías una flag incorrecta, perderás 1 vida.""" % [diff_name, max_lives, total_score, int(time_limit)]

	tutorial_body.text = rules_text

func _start_match() -> void:
	AudioManager.play_click()
	_hide_all_modals()
	super.start_game(current_difficulty)

	current_match_generation += 1
	current_lives = max_lives
	is_game_paused = false
	flag_input.text = ""

	# Cargar desafío aleatorio
	current_challenge = LinuxChallenges.get_random_challenge(current_difficulty)
	current_path = current_challenge.get("initial_path", "/home/user")
	simulated_fs = current_challenge.get("files", {}).duplicate(true)

	_update_lives_hud()
	_setup_command_buttons()

	# Configurar textos
	challenge_label.text = "DESAFÍO: %s" % current_difficulty
	teacher_label.text = current_challenge.get("situation", "Explora el sistema para hallar la flag.")
	
	# Reiniciar salida de terminal limpia
	terminal_output.clear()
	_update_prompt_display()

	time_remaining = time_limit
	is_timer_active = true
	_update_timer_display()

	EventBus.minigame_started.emit(minigame_id, current_difficulty)

# ==================== INTERACCIÓN CON TERMINAL Y COMANDOS ====================

func _update_prompt_display() -> void:
	var prompt_base: String = current_challenge.get("prompt_user", "user@is-pixelverse:~$")
	# Extraer prefijo de usuario
	var prefix: String = "user@is-pixelverse"
	if prompt_base.begins_with("root"):
		prefix = "root@is-pixelverse"
	
	var display_path: String = current_path
	if current_path == "/home/user":
		display_path = "~"
	elif current_path.begins_with("/home/user/"):
		display_path = "~/" + current_path.trim_prefix("/home/user/")

	terminal_prompt_label.text = "%s:%s$" % [prefix, display_path]

func _setup_command_buttons() -> void:
	for child in commands_container.get_children():
		commands_container.remove_child(child)
		child.queue_free()

	var cmds: Array = current_challenge.get("available_commands", ["ls", "cd", "cat", "pwd", "clear"])
	for cmd in cmds:
		var btn := Button.new()
		btn.text = cmd
		btn.custom_minimum_size = Vector2(60, 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 11)
		btn.focus_mode = FOCUS_NONE
		btn.pressed.connect(func(): _on_command_button_clicked(cmd))
		commands_container.add_child(btn)

func _on_command_button_clicked(cmd: String) -> void:
	if not is_timer_active or is_game_paused:
		return

	AudioManager.play_click()
	match cmd:
		"ls":
			_exec_ls(false)
		"ls -a":
			_exec_ls(true)
		"pwd":
			_exec_pwd()
		"clear":
			_exec_clear()
		"cd":
			_open_cd_picker()
		"cat":
			_open_file_picker("cat")
		"head":
			_open_file_picker("head")
		"tail":
			_open_file_picker("tail")
		"grep":
			_open_file_picker("grep")
		"find":
			_exec_find()
		_:
			_append_terminal_line("$ " + cmd)
			_append_terminal_line("Comando no reconocido en la simulación.")

func _append_terminal_line(text: String) -> void:
	terminal_output.append_text(text + "\n")
	# Auto-scroll al final
	await get_tree().process_frame
	terminal_scroll.scroll_vertical = int(terminal_scroll.get_v_scroll_bar().max_value)

# ==================== IMPLEMENTACIÓN DE COMANDOS LINUX ====================

func _exec_pwd() -> void:
	_append_terminal_line("$ pwd")
	_append_terminal_line("[color=#77ff99]" + current_path + "[/color]")

func _exec_clear() -> void:
	terminal_output.clear()
	_update_prompt_display()

func _exec_ls(show_hidden: bool) -> void:
	var cmd_str: String = "ls -a" if show_hidden else "ls"
	_append_terminal_line("$ " + cmd_str)

	var dir_info: Dictionary = simulated_fs.get(current_path, {})
	var dirs: Array = dir_info.get("dirs", [])
	var files: Dictionary = dir_info.get("files", {})

	var entries: Array[String] = []
	if show_hidden:
		entries.append("[color=#55aaff].[/color]")
		entries.append("[color=#55aaff]..[/color]")

	for d in dirs:
		if not show_hidden and d.begins_with("."):
			continue
		entries.append("[color=#55aaff]" + d + "/[/color]")

	for f in files.keys():
		if not show_hidden and str(f).begins_with("."):
			continue
		entries.append("[color=#ffffff]" + str(f) + "[/color]")

	if entries.is_empty():
		_append_terminal_line("[color=#888888](directorio vacío)[/color]")
	else:
		_append_terminal_line("  ".join(entries))

func _exec_find() -> void:
	_append_terminal_line("$ find . -type f")
	var found_any := false
	for path in simulated_fs.keys():
		if path.begins_with(current_path):
			var files_dict: Dictionary = simulated_fs[path].get("files", {})
			for f in files_dict.keys():
				found_any = true
				var rel: String = path.trim_prefix(current_path).trim_prefix("/")
				var full_rel: String = "./" + (rel + "/" if rel != "" else "") + str(f)
				_append_terminal_line("[color=#ffffff]" + full_rel + "[/color]")
	if not found_any:
		_append_terminal_line("[color=#888888]No se encontraron archivos.[/color]")

func _open_cd_picker() -> void:
	var dir_info: Dictionary = simulated_fs.get(current_path, {})
	var subdirs: Array = dir_info.get("dirs", []).duplicate()

	var options: Array[Dictionary] = []
	var base_path: String = current_challenge.get("initial_path", "/home/user")
	# Permitir retroceder con '..' solo si estamos dentro de una subcarpeta respecto a la base
	if current_path != base_path and current_path.begins_with(base_path):
		options.append({"label": ".. (Directorio anterior)", "target": ".."})

	for d in subdirs:
		options.append({"label": d + "/", "target": d})

	if options.is_empty():
		_append_terminal_line("$ cd")
		_append_terminal_line("[color=#ff8888]No hay subcarpetas para cambiar en este directorio.[/color]")
		return

	_show_picker("Seleccionar directorio para 'cd':", options, func(target: String):
		_do_cd(target)
	)

func _do_cd(target: String) -> void:
	_append_terminal_line("$ cd " + target)
	var base_path: String = current_challenge.get("initial_path", "/home/user")

	if target == "..":
		if current_path != base_path and current_path.begins_with(base_path):
			var parts: Array = current_path.split("/", false)
			if parts.size() > 1:
				parts.pop_back()
				var new_p: String = "/" + "/".join(parts)
				if new_p.begins_with(base_path):
					current_path = new_p
				else:
					current_path = base_path
			else:
				current_path = base_path
		else:
			_append_terminal_line("[color=#ffcc00]Ya te encuentras en el directorio base del desafío.[/color]")
	else:
		var target_path: String = (current_path + "/" + target) if current_path != "/" else ("/" + target)
		if simulated_fs.has(target_path):
			current_path = target_path
		else:
			_append_terminal_line("[color=#ff8888]bash: cd: %s: No existe el archivo o el directorio[/color]" % target)

	_update_prompt_display()

func _open_file_picker(cmd: String) -> void:
	var dir_info: Dictionary = simulated_fs.get(current_path, {})
	var files: Dictionary = dir_info.get("files", {})

	var options: Array[Dictionary] = []
	for f in files.keys():
		options.append({"label": str(f), "target": str(f)})

	if options.is_empty():
		_append_terminal_line("$ " + cmd)
		_append_terminal_line("[color=#ff8888]No hay archivos en este directorio para ejecutar '" + cmd + "'.[/color]")
		return

	_show_picker("Seleccionar archivo para '%s':" % cmd, options, func(target: String):
		_do_file_cmd(cmd, target)
	)

func _do_file_cmd(cmd: String, filename: String) -> void:
	var dir_info: Dictionary = simulated_fs.get(current_path, {})
	var files: Dictionary = dir_info.get("files", {})
	var content: String = str(files.get(filename, ""))

	if cmd == "grep":
		_append_terminal_line("$ grep -i 'flag' %s" % filename)
	else:
		_append_terminal_line("$ %s %s" % [cmd, filename])

	match cmd:
		"cat":
			_append_terminal_line("[color=#ffffff]" + content + "[/color]")
		"head":
			var lines := content.split("\n")
			var count := mini(5, lines.size())
			var head_lines: Array = []
			for i in range(count):
				head_lines.append(lines[i])
			_append_terminal_line("[color=#ffffff]" + "\n".join(head_lines) + "[/color]")
		"tail":
			var lines := content.split("\n")
			var start := maxi(0, lines.size() - 5)
			var tail_lines: Array = []
			for i in range(start, lines.size()):
				tail_lines.append(lines[i])
			_append_terminal_line("[color=#ffffff]" + "\n".join(tail_lines) + "[/color]")
		"grep":
			var matched_lines: Array = []
			for line in content.split("\n"):
				if "flag" in line.to_lower():
					matched_lines.append(line)
			if matched_lines.is_empty():
				_append_terminal_line("[color=#888888](Sin coincidencias para 'flag')[/color]")
			else:
				_append_terminal_line("[color=#33ff55]" + "\n".join(matched_lines) + "[/color]")

# ==================== MODAL DE SELECCIÓN DE PARÁMETROS ====================

func _show_picker(title: String, options: Array[Dictionary], callback: Callable) -> void:
	picker_title.text = title
	for child in picker_options_container.get_children():
		picker_options_container.remove_child(child)
		child.queue_free()

	for opt in options:
		var btn := Button.new()
		btn.text = opt.label
		btn.custom_minimum_size = Vector2(0, 36)
		btn.pressed.connect(func():
			_close_picker()
			callback.call(opt.target)
		)
		picker_options_container.add_child(btn)

	picker_modal.visible = true

func _close_picker() -> void:
	AudioManager.play_click()
	picker_modal.visible = false

# ==================== ENVÍO Y VALIDACIÓN DE LA FLAG ====================

func _on_submit_flag_pressed() -> void:
	if not is_timer_active or is_game_paused:
		return

	var entered: String = flag_input.text.strip_edges()
	if entered == "":
		_append_terminal_line("[color=#ffcc00][ AVISO ] Ingresa una flag antes de enviar.[/color]")
		return

	var expected_flag: String = current_challenge.get("flag", "Flag{none}").strip_edges()

	# Acepta tanto "Flag{xyz}" como solo "xyz" si el usuario escribió solo lo de adentro
	var is_correct: bool = (entered.to_lower() == expected_flag.to_lower())
	var inside_expected: String = expected_flag.trim_prefix("Flag{").trim_suffix("}").strip_edges()
	if entered.to_lower() == inside_expected.to_lower():
		is_correct = true

	if is_correct:
		_handle_victory()
	else:
		_handle_wrong_flag(entered)

func _handle_wrong_flag(entered: String) -> void:
	AudioManager.play_error()
	_append_terminal_line("[color=#ff3333][ FLAG INCORRECTA ] '%s' no es válida (-1 Vida).[/color]" % entered)
	teacher_label.text = "¡Esa no es la flag correcta! Revisa cuidadosamente el contenido de los archivos."
	flag_input.text = ""
	_deduct_life("Flag incorrecta ingresada")

func _on_time_out() -> void:
	AudioManager.play_error()
	_append_terminal_line("[color=#ff3333][ TIEMPO EXPIRADO ] El contador llegó a 0 (-1 Vida).[/color]")
	teacher_label.text = "¡Se agotó el tiempo! El contador se reinicia mientras tengas vidas."
	_deduct_life("Tiempo límite agotado")

func _deduct_life(reason: String) -> void:
	current_lives = maxi(0, current_lives - 1)
	_update_lives_hud()
	EventBus.life_lost.emit(current_lives)

	if current_lives <= 0:
		_handle_game_over(reason)
	else:
		# Reinicia tiempo del intento según FA-03.02
		time_remaining = time_limit
		_update_timer_display()

func _handle_game_over(reason: String) -> void:
	is_timer_active = false
	AudioManager.play_game_over()
	EventBus.game_over.emit(minigame_id)
	finish_game(false, 0, 0, "Partida finalizada: " + reason)

	game_over_desc.text = "Causa: %s.\nTe has quedado sin vidas en dificultad %s.\n(No se registrará puntuación según el reglamento)." % [reason, current_difficulty]
	modal_game_over.visible = true

func _handle_victory() -> void:
	_hide_all_modals()
	is_timer_active = false
	AudioManager.play_success()

	_append_terminal_line("[color=#33ff55][ FLAG CORRECTA ] ¡Felicidades! Desafío completado (+%d pts).[/color]" % total_score)
	teacher_label.text = "¡Excelente trabajo! Has demostrado dominio en la navegación del sistema de archivos Linux."

	var stars: int = 1
	if current_lives == max_lives:
		stars = 3
	elif current_lives >= 2:
		stars = 2

	finish_game(true, total_score, stars, "Exploración de sistema de archivos superada con éxito")

	victory_summary.text = """¡Desafío de Exploración de Archivos superado con éxito!

• Dificultad: %s
• Flag encontrada: %s
• Vidas conservadas: %d / %d
• Estrellas obtenidas: %d / 3
• Puntuación registrada: %d puntos""" % [current_difficulty, current_challenge.get("flag", ""), current_lives, max_lives, stars, total_score]

	modal_victory.visible = true

# ==================== HUD Y MODALES ====================

func _update_timer_display() -> void:
	var ratio: float = clampf(time_remaining / time_limit, 0.0, 1.0)
	time_bar.value = ratio * 100.0
	time_label.text = "%02d s" % int(ceil(time_remaining))

func _update_lives_hud() -> void:
	for child in hearts_container.get_children():
		hearts_container.remove_child(child)
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
	picker_modal.visible = false
