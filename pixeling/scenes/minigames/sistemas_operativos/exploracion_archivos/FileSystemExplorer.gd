## FileSystemExplorer.gd - CU-17: Practicar la exploración del sistema de archivos para localizar una flag mediante comandos Linux
## Morelosoft International Solutions - Materia: Sistemas Operativos y Linux
extends MiniGameBase

const LinuxChallenges = preload("res://scenes/minigames/sistemas_operativos/exploracion_archivos/LinuxFileSystemChallenges.gd")

const MUSIC_FILE_SYSTEM = "res://assets/terminal_linux/SegundoMinijuego/musica/Before_the_Timeout.mp3"

# HUD Superior
@onready var btn_pause: Button = $TopHUD/BtnPause
@onready var time_bar: ProgressBar = $TopHUD/TimeBar
@onready var time_label: Label = $TopHUD/TimeLabel
@onready var hearts_container: HBoxContainer = $TopHUD/HeartsContainer
@onready var challenge_label: Label = $TopHUD/ChallengeLabel

# Sección Profesor
@onready var teacher_label: Label = $TeacherSection/BubblePanel/TeacherLabel
@onready var teacher_texture: TextureRect = $TeacherSection/TeacherTexture
@onready var bubble_panel: PanelContainer = $TeacherSection/BubblePanel

# Texturas para la animación de habla del docente (sprites detallados con fondo transparente)
var teacher_tex_idle: Texture2D = preload("res://assets/terminal_linux/ProfesorNormal.png")
var teacher_tex_talk: Texture2D = preload("res://assets/terminal_linux/ProfesorHablando.png")

# Estado de animación del docente y typewriter estilo Balatro
var is_teacher_speaking: bool = false
var target_dialogue_text: String = ""
var typewriter_char_index: float = 0.0
var typewriter_chars_per_sec: float = 38.0
var balatro_anim_time: float = 0.0
var talk_frame_timer: float = 0.0
var talk_current_frame: int = 0
var typewriter_player: AudioStreamPlayer
var typewriter_sfx_streams: Array[AudioStreamWAV] = []
var typewriter_tween: Tween

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
var flow_template: Control

func _ready() -> void:
	super._ready()
	minigame_id = "exploracion_archivos"
	cu_id = "CU-17"
	minigame_title = "Exploración de Archivos y Flag"
	subject_name = "Sistemas Operativos y Linux"

	_init_typewriter_audio()
	if bubble_panel:
		bubble_panel.gui_input.connect(_on_bubble_panel_gui_input)
		bubble_panel.pivot_offset = bubble_panel.size * 0.5
	if teacher_texture:
		teacher_texture.pivot_offset = Vector2(teacher_texture.size.x * 0.5, teacher_texture.size.y)
	_connect_signals()
	lock_dynamic_label_box(teacher_label, teacher_label.get_parent() as Control, 80.0, 11, 7, 4.0, 2.0, true, true, 4.0)
	lock_dynamic_label_box(terminal_prompt_label, null, 17.0, 10, 7, 0.0, 0.0, false, true)
	stabilize_hud_label(time_label, 42.0)
	stabilize_hud_label(challenge_label, 68.0)
	_build_flow_template()
	_hide_all_modals()
	_show_tutorial()

func _connect_signals() -> void:
	btn_pause.pressed.connect(_on_pause_pressed)
	btn_submit_flag.pressed.connect(_on_submit_flag_pressed)
	flag_input.text_submitted.connect(func(_text): _on_submit_flag_pressed())

	# Modales de Dificultad
	btn_diff_facil.pressed.connect(func(): _on_difficulty_chosen("FACIL"))
	btn_diff_normal.pressed.connect(func(): _on_difficulty_chosen("NORMAL"))
	btn_diff_ing.pressed.connect(func(): _on_difficulty_chosen("INGENIERO"))

	# Tutorial avanza a Selección de Dificultad
	btn_tutorial_start.pressed.connect(_show_difficulty_selection)

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
	# 1. Movimiento visual orgánico estilo Balatro para el diálogo
	_update_balatro_dialogue_motion(delta)

	# 2. Generación progresiva (typewriter) y animación de habla del docente
	_update_typewriter_and_talking(delta)

	if not is_timer_active or is_game_paused:
		return

	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_on_time_out()

	_update_timer_display()

func _unhandled_input(event: InputEvent) -> void:
	# Si el profesor está hablando, permitir adelantar/completar el texto con Enter/Espacio
	if is_teacher_speaking:
		if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE)):
			_finish_typewriter_immediately()
			get_viewport().set_input_as_handled()
			return

# ==================== FLUJO DE SELECCIÓN Y TUTORIAL ====================

func _build_flow_template() -> void:
	flow_template = create_flow_template({
		"title": "Exploración de Archivos",
		"subtitle": "CU-17 · Sistema de Archivos Linux",
		"classroom_path": "res://scenes/classroom/SistemaOperativoLinux.tscn",
		"objective": "Usa comandos de Linux para explorar directorios y documentos hasta localizar la FLAG oculta.",
		"rules": [
			"1. Lee la situación planteada por el profesor en la parte superior.",
			"2. Utiliza los botones de comandos (ls, cd, cat, head, tail, etc.) abajo.",
			"3. Al elegir 'cd' o 'cat', selecciona el archivo o carpeta deseada.",
			"4. Escribe la flag exacta Flag{...} en SUBMIT FLAG y presiona ENVIAR. Error o tiempo agotado = -1 vida."
		],
		"difficulties": {
			"FACIL": {
				"name": "Fácil",
				"info": "Fácil: 3 vidas · 60s · 250 puntos (Exploración guiada)"
			},
			"NORMAL": {
				"name": "Normal",
				"info": "Normal: 2 vidas · 30s · 500 puntos (Archivos ocultos)"
			},
			"INGENIERO": {
				"name": "Ingeniero",
				"info": "Ingeniero: 1 vida · 40s · 750 puntos (Rutas complejas y permisos)"
			}
		},
		"default_difficulty": "NORMAL",
		"on_start": func(diff: String):
			_on_difficulty_chosen(diff),
		"on_back": func():
			_exit_to_classroom(),
		"on_resume": func():
			_resume_game(),
		"on_restart": func():
			_restart_match()
	})


func _show_tutorial() -> void:
	_hide_all_modals()
	if flow_template:
		flow_template.show_instructions()
		return
	modal_tutorial.visible = true
	btn_tutorial_start.text = "SELECCIONAR DIFICULTAD ➔"

	_speak_teacher("¡Bienvenido a la Práctica de Exploración de Archivos (CU-17)!\nLee las instrucciones del desafío antes de elegir tu dificultad.", 42.0)
	terminal_prompt_label.text = "user@is-pixelverse:~$ [MODO INSTRUCCIONES]"

	var rules_text: String = """INSTRUCCIONES DEL DESAFÍO:
Usa comandos de Linux para explorar el sistema de archivos, inspeccionar directorios y leer documentos hasta localizar la FLAG oculta.

CÓMO JUGAR:
1. Lee la situación planteada por el profesor en la parte superior.
2. Utiliza los botones de comandos interactivos ubicados en la parte inferior (ls, cd, cat, head, tail, etc.).
3. Al presionar comandos con destino (como 'cd' o 'cat'), podrás seleccionar el archivo o carpeta deseada.
4. Cuando encuentres la flag dentro de los archivos, escríbela en el campo inferior SUBMIT FLAG tal como aparece: Flag{...} y presiona ENVIAR.

NIVELES DE DIFICULTAD:
• Fácil: 3 vidas · 60s · 250 puntos (Exploración guiada)
• Normal: 2 vidas · 30s · 500 puntos (Archivos ocultos)
• Ingeniero: 1 vida · 40s · 750 puntos (Rutas complejas y permisos)

REGLAS DE PARTIDA:
• Si el tiempo se agota o envías una flag incorrecta, perderás 1 vida."""

	tutorial_body.text = rules_text

func _show_difficulty_selection() -> void:
	AudioManager.play_click()
	_hide_all_modals()
	if flow_template:
		flow_template.show_difficulty()
		return
	modal_difficulty.visible = true
	_speak_teacher("Selecciona el nivel de dificultad para iniciar el desafío.", 42.0)
	terminal_prompt_label.text = "user@is-pixelverse:~$ [SELECCIÓN DIFICULTAD]"

func _on_difficulty_chosen(diff: String) -> void:
	AudioManager.play_click()
	AudioManager.stop_music()
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
	_start_match()

func _start_match() -> void:
	AudioManager.play_click()
	_hide_all_modals()
	if flow_template:
		flow_template.hide_all()
	super.start_game(current_difficulty)

	# Iniciar música temática en bucle del segundo minijuego (Before the Timeout)
	if AudioManager and AudioManager.has_method("play_music"):
		AudioManager.play_music(MUSIC_FILE_SYSTEM, true)

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
	_speak_teacher(current_challenge.get("situation", "Explora el sistema para hallar la flag."), 38.0)
	
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
	_speak_teacher("¡Esa no es la flag correcta! Revisa cuidadosamente el contenido de los archivos.", 48.0)
	flag_input.text = ""
	_deduct_life("Flag incorrecta ingresada")

func _on_time_out() -> void:
	AudioManager.play_error()
	_append_terminal_line("[color=#ff3333][ TIEMPO EXPIRADO ] El contador llegó a 0 (-1 Vida).[/color]")
	_speak_teacher("¡Se agotó el tiempo! El contador se reinicia mientras tengas vidas.", 45.0)
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
	_close_picker()
	if AudioManager and AudioManager.has_method("stop_music"):
		AudioManager.stop_music()
	AudioManager.play_game_over()
	EventBus.game_over.emit(minigame_id)
	finish_game(false, 0, 0, "Partida finalizada: " + reason)

	if flow_template:
		flow_template.show_game_over("Causa: %s\nDificultad: %s" % [reason, current_difficulty], 0)
		return

	game_over_desc.text = "Causa: %s.\nTe has quedado sin vidas en dificultad %s.\n(No se registrará puntuación según el reglamento)." % [reason, current_difficulty]
	modal_game_over.visible = true

func _handle_victory() -> void:
	_hide_all_modals()
	_close_picker()
	is_timer_active = false
	if AudioManager and AudioManager.has_method("stop_music"):
		AudioManager.stop_music()
	AudioManager.play_success()

	_append_terminal_line("[color=#33ff55][ FLAG CORRECTA ] ¡Felicidades! Desafío completado (+%d pts).[/color]" % total_score)
	_speak_teacher("¡Excelente trabajo! Has demostrado dominio en la navegación del sistema de archivos Linux.", 45.0)

	var stars: int = 1
	if current_lives == max_lives:
		stars = 3
	elif current_lives >= 2:
		stars = 2

	var prev_high: int = StateManager.get_minigame_high_score(minigame_id) if StateManager else 0
	var is_record: bool = total_score > prev_high
	finish_game(true, total_score, stars, "Exploración de sistema de archivos superada con éxito")

	if flow_template:
		var total_accum: int = StateManager.get_points() if StateManager else total_score
		flow_template.show_victory(total_score, stars, total_accum, is_record, "¡FLAG LOCALIZADA!")
		return

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
	if AudioManager and AudioManager.has_method("pause_music"):
		AudioManager.pause_music(true)
	if flow_template:
		flow_template.show_pause()
	else:
		modal_pause.visible = true

func _resume_game() -> void:
	AudioManager.play_click()
	is_game_paused = false
	if AudioManager and AudioManager.has_method("pause_music"):
		AudioManager.pause_music(false)
	if flow_template:
		flow_template.hide_pause()
	modal_pause.visible = false

func _restart_match() -> void:
	AudioManager.play_click()
	_hide_all_modals()
	_start_match()

func _exit_to_classroom() -> void:
	AudioManager.play_click()
	if AudioManager and AudioManager.has_method("stop_music"):
		AudioManager.stop_music()
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

# ==================== ANIMACIÓN Y DIÁLOGO ESTILO BALATRO ====================

func _init_typewriter_audio() -> void:
	typewriter_player = AudioStreamPlayer.new()
	typewriter_player.name = "TypewriterSFX"
	typewriter_player.bus = "Master"
	add_child(typewriter_player)
	_sync_typewriter_volume()

	var eb = get_node_or_null("/root/EventBus")
	if eb:
		if not eb.settings_changed.is_connected(_on_audio_settings_changed):
			eb.settings_changed.connect(_on_audio_settings_changed)
		if not eb.settings_updated.is_connected(_on_audio_settings_changed):
			eb.settings_updated.connect(_on_audio_settings_changed)
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_signal("sfx_volume_changed"):
		if not am.sfx_volume_changed.is_connected(_on_sfx_vol_changed):
			am.sfx_volume_changed.connect(_on_sfx_vol_changed)

	typewriter_sfx_streams.clear()
	var base_freqs := [420.0, 480.0, 540.0, 600.0, 660.0]
	for freq in base_freqs:
		var stream := _generate_chatter_tone(freq, 0.038)
		if stream:
			typewriter_sfx_streams.append(stream)

func _on_audio_settings_changed(_settings: Dictionary = {}) -> void:
	_sync_typewriter_volume()

func _on_sfx_vol_changed(_vol: float = 1.0) -> void:
	_sync_typewriter_volume()

func _sync_typewriter_volume() -> void:
	if not typewriter_player:
		return
	var sfx_vol := 1.0
	var am = get_node_or_null("/root/AudioManager")
	if am:
		sfx_vol = float(am.sfx_volume)
	elif has_node("/root/StateManager"):
		var sm = get_node("/root/StateManager")
		if sm.has_method("get_settings"):
			sfx_vol = float(sm.get_settings().get("sfx_volume", 1.0))

	if sfx_vol <= 0.001:
		typewriter_player.volume_db = -80.0
	else:
		typewriter_player.volume_db = linear_to_db(sfx_vol) - 10.0

func _generate_chatter_tone(freq: float, duration: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * duration)
	var byte_data := PackedByteArray()
	byte_data.resize(sample_count)

	for i in range(sample_count):
		var t := float(i) / float(sample_rate)
		var env := sin(PI * (float(i) / float(sample_count)))
		var val := sin(2.0 * PI * freq * t) * env
		var byte_val := clampi(int((val * 0.5 + 0.5) * 255.0), 0, 255)
		byte_data[i] = byte_val

	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_8_BITS
	s.mix_rate = sample_rate
	s.stereo = false
	s.data = byte_data
	return s

func _speak_teacher(new_text: String, chars_per_sec: float = 38.0) -> void:
	target_dialogue_text = new_text
	typewriter_chars_per_sec = chars_per_sec
	typewriter_char_index = 0.0
	is_teacher_speaking = true
	talk_current_frame = 1
	talk_frame_timer = 0.0

	teacher_label.text = new_text
	teacher_label.visible_characters = 0

	# Punch / bounce pop estilo Balatro al iniciar nuevo diálogo
	if is_instance_valid(bubble_panel):
		if bubble_panel.size != Vector2.ZERO:
			bubble_panel.pivot_offset = bubble_panel.size * 0.5
		if is_instance_valid(typewriter_tween) and typewriter_tween.is_running():
			typewriter_tween.kill()
		typewriter_tween = create_tween()
		bubble_panel.scale = Vector2(1.08, 0.92)
		typewriter_tween.tween_property(bubble_panel, "scale", Vector2.ONE, 0.32)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)

	if is_instance_valid(teacher_texture):
		if teacher_texture.size != Vector2.ZERO:
			teacher_texture.pivot_offset = Vector2(teacher_texture.size.x * 0.5, teacher_texture.size.y)
		teacher_texture.texture = teacher_tex_talk

func _finish_typewriter_immediately() -> void:
	if not is_teacher_speaking:
		return
	is_teacher_speaking = false
	teacher_label.visible_characters = -1
	if is_instance_valid(teacher_texture):
		teacher_texture.texture = teacher_tex_idle
		teacher_texture.rotation = 0.0
		teacher_texture.scale = Vector2.ONE

func _on_bubble_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_teacher_speaking:
			_finish_typewriter_immediately()

func _update_balatro_dialogue_motion(delta: float) -> void:
	balatro_anim_time += delta
	var t := balatro_anim_time

	if is_instance_valid(bubble_panel):
		if bubble_panel.pivot_offset == Vector2.ZERO and bubble_panel.size != Vector2.ZERO:
			bubble_panel.pivot_offset = bubble_panel.size * 0.5

		# Oscilación armónica senoidal estilo Balatro: sutil inclinación y respiración
		var sway := sin(t * 2.4) * 0.016 + cos(t * 1.6) * 0.006
		if is_teacher_speaking:
			sway += sin(t * 26.0) * 0.004

		bubble_panel.rotation = sway

		if typewriter_tween == null or not typewriter_tween.is_running():
			var breath_x := 1.0 + sin(t * 3.2) * 0.013
			var breath_y := 1.0 - sin(t * 3.2) * 0.013
			bubble_panel.scale = Vector2(breath_x, breath_y)

func _update_typewriter_and_talking(delta: float) -> void:
	if not is_instance_valid(teacher_texture):
		return

	if teacher_texture.pivot_offset == Vector2.ZERO and teacher_texture.size != Vector2.ZERO:
		teacher_texture.pivot_offset = Vector2(teacher_texture.size.x * 0.5, teacher_texture.size.y)

	if not is_teacher_speaking:
		# Animación idle del docente (respiración tranquila y suave cabeceo)
		var idle_t := balatro_anim_time
		teacher_texture.rotation = sin(idle_t * 1.8) * 0.012
		teacher_texture.scale = Vector2(1.0 + cos(idle_t * 2.4) * 0.01, 1.0 + sin(idle_t * 2.4) * 0.014)
		return

	# Progreso de la máquina de escribir
	var prev_idx := int(typewriter_char_index)
	typewriter_char_index += delta * typewriter_chars_per_sec
	var current_visible := int(typewriter_char_index)
	var total_chars := target_dialogue_text.length()

	if current_visible < total_chars:
		if teacher_label.visible_characters != current_visible:
			teacher_label.visible_characters = current_visible

		if current_visible > prev_idx:
			var char_at := target_dialogue_text.substr(mini(current_visible - 1, total_chars - 1), 1)
			if char_at != " " and char_at != "\n" and char_at != "\t":
				if typewriter_player and not typewriter_sfx_streams.is_empty():
					_sync_typewriter_volume()
					var am = get_node_or_null("/root/AudioManager")
					var cur_sfx: float = am.sfx_volume if am else 1.0
					if cur_sfx > 0.001 and not typewriter_player.playing:
						typewriter_player.stream = typewriter_sfx_streams.pick_random()
						typewriter_player.pitch_scale = randf_range(0.92, 1.14)
						typewriter_player.play()

		# Movimiento corporal al hablar (cabeceo rítmico y gesticulación)
		var speak_t := balatro_anim_time * 15.0
		teacher_texture.rotation = sin(speak_t) * 0.035 + cos(speak_t * 0.7) * 0.015
		teacher_texture.scale = Vector2(1.0 + sin(speak_t * 1.2) * 0.025, 1.0 - sin(speak_t * 1.2) * 0.025)

		# Alternancia de bocas (animación de habla con los nuevos sprites detallados)
		talk_frame_timer += delta
		if talk_frame_timer >= 0.12:
			talk_frame_timer = 0.0
			talk_current_frame = 1 - talk_current_frame
			teacher_texture.texture = teacher_tex_talk if talk_current_frame == 1 else teacher_tex_idle
	else:
		teacher_label.visible_characters = -1
		is_teacher_speaking = false
		teacher_texture.texture = teacher_tex_idle
		teacher_texture.rotation = 0.0
		teacher_texture.scale = Vector2.ONE
