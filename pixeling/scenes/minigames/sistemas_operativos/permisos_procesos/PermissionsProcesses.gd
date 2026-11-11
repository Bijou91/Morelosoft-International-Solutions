## PermissionsProcesses.gd - CU-18: Practicar a administrar permisos y procesos
## Morelosoft International Solutions - Materia: Sistemas Operativos y Linux
## Minijuego educativo con terminal Linux simulada, gestión de permisos y procesos
extends MiniGameBase

const LinuxData = preload("res://scenes/minigames/sistemas_operativos/permisos_procesos/LinuxMissionData.gd")
const ShellClass = preload("res://scenes/minigames/sistemas_operativos/permisos_procesos/VirtualLinuxShell.gd")

# HUD Superior
@onready var btn_pause: Button = $TopHUD/BtnPause
@onready var time_bar: ProgressBar = $TopHUD/TimeBar
@onready var time_label: Label = $TopHUD/TimeLabel
@onready var hearts_container: HBoxContainer = $TopHUD/HeartsContainer
@onready var challenge_label: Label = $TopHUD/ChallengeLabel

# Sección Profesor
@onready var teacher_label: Label = $TeacherSection/BubblePanel/TeacherLabel
@onready var teacher_texture: TextureRect = $TeacherSection/TeacherTexture

# Pantalla Dividida (Laptop CRT)
# 1. Panel Superior: Terminal Interactiva Integrada
@onready var terminal_prompt_label: Label = $CRTContainer/LaptopScreen/TerminalPane/HeaderBar/TerminalPromptLabel
@onready var terminal_scroll: ScrollContainer = $CRTContainer/LaptopScreen/TerminalPane/ConsoleScroll
@onready var terminal_output: RichTextLabel = $CRTContainer/LaptopScreen/TerminalPane/ConsoleScroll/TerminalOutput

# 2. Panel Inferior: Lista de Objetivos de Misión
@onready var objectives_header: Label = $CRTContainer/LaptopScreen/ObjectivesPane/ObjHeaderBar/ObjectivesHeaderLabel
@onready var objectives_scroll: ScrollContainer = $CRTContainer/LaptopScreen/ObjectivesPane/ObjectivesScroll
@onready var objectives_container: VBoxContainer = $CRTContainer/LaptopScreen/ObjectivesPane/ObjectivesScroll/ObjectivesVBox

# Sección Inferior: Manos y Teclado Virtual Real
@onready var hands_texture: TextureRect = $ControlsSection/HandsTexture
@onready var quick_bar: HBoxContainer = $ControlsSection/KeyboardRoot/QuickBar
@onready var keyboard_keys_vbox: VBoxContainer = $ControlsSection/KeyboardRoot/KeysVBox
@onready var btn_toggle_keyboard_mode: Button = $ControlsSection/KeyboardRoot/Row4/BtnToggleMode
@onready var btn_key_space: Button = $ControlsSection/KeyboardRoot/Row4/BtnSpace
@onready var btn_key_backspace: Button = $ControlsSection/KeyboardRoot/Row4/BtnBackspace
@onready var btn_key_enter: Button = $ControlsSection/KeyboardRoot/Row4/BtnEnter

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

# Estado de juego
var shell: VirtualLinuxShell
var current_mission: Dictionary = {}
var objectives_status: Array[bool] = []
var max_lives: int = 3
var current_lives: int = 3
var time_limit: float = 90.0
var time_remaining: float = 90.0
var total_score: int = 300
var is_timer_active: bool = false
var is_game_paused: bool = false

# Buffer de texto de la terminal (estilo terminal real)
var terminal_history: String = ""
var current_input_text: String = ""
var cursor_visible: bool = true
var cursor_timer: float = 0.0

# Estado del Teclado Virtual: "ABC" o "123"
var keyboard_mode: String = "ABC"
var history_index: int = -1

func _ready() -> void:
	super._ready()
	minigame_id = "permisos_procesos"
	cu_id = "CU-18"
	minigame_title = "Administrar permisos y procesos"
	subject_name = "Sistemas Operativos y Linux"

	shell = ShellClass.new()
	shell.state_changed.connect(_on_shell_state_changed)
	shell.risky_action_detected.connect(_on_risky_action_detected)

	_connect_signals()
	_setup_virtual_keyboard()
	_hide_all_modals()
	_show_difficulty_selection()

func _connect_signals() -> void:
	btn_pause.pressed.connect(_on_pause_pressed)

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

	# Teclas especiales del teclado virtual
	btn_toggle_keyboard_mode.pressed.connect(_toggle_keyboard_mode)
	btn_key_space.pressed.connect(func(): _append_input_char(" "))
	btn_key_backspace.pressed.connect(_on_backspace_pressed)
	btn_key_enter.pressed.connect(_submit_current_command)

func _process(delta: float) -> void:
	if not is_timer_active or is_game_paused:
		return

	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_on_time_out()

	_update_timer_display()

	# Parpadeo del cursor en el último renglón de la terminal
	cursor_timer += delta
	if cursor_timer >= 0.45:
		cursor_timer = 0.0
		cursor_visible = not cursor_visible
		_render_terminal_display()

# ==================== FLUJO DE SELECCIÓN Y TUTORIAL ====================

func _show_difficulty_selection() -> void:
	_hide_all_modals()
	modal_difficulty.visible = true
	teacher_label.text = "¡Bienvenido a la Misión de Permisos y Procesos (CU-18)!\nSelecciona tu nivel de dificultad para comenzar."
	terminal_prompt_label.text = "user@is-pixelverse:~$ [MODO ESPERA]"

func _on_difficulty_chosen(diff: String) -> void:
	AudioManager.play_click()
	current_difficulty = diff

	match diff:
		"FACIL":
			max_lives = 3
			total_score = 300
			time_limit = 90.0
		"NORMAL":
			max_lives = 2
			total_score = 600
			time_limit = 60.0
		"INGENIERO":
			max_lives = 1
			total_score = 900
			time_limit = 45.0

	current_lives = max_lives
	_show_tutorial()

func _show_tutorial() -> void:
	_hide_all_modals()
	modal_tutorial.visible = true

	var diff_name: String = current_difficulty.capitalize()
	var rules_text: String = """INSTRUCCIONES DE LA MISIÓN:
En este desafío administrarás permisos y procesos de un sistema GNU/Linux mediante comandos en una terminal simulada completamente segura.

COMANDOS CLAVE:
• ps aux  o  top : Inspecciona procesos activos, PIDs y consumo de recursos.
• kill <PID>  o  killall <nombre> : Termina procesos maliciosos o rebeldes.
• ls -l : Inspecciona archivos con sus permisos detallados (rwx) y dueños.
• chmod <modo> <archivo> : Cambia permisos en notación octal (755, 600) o simbólica (+x, -x, u+w, o-r).
• chown <usuario> <archivo> : Modifica el dueño de un archivo.
• cat <archivo> : Lee el contenido de un archivo.
• ./script.sh : Ejecuta un script verificando que tenga permisos 'x'.

REGLAS DE PARTIDA:
• Dificultad: %s (%d vidas)
• Puntos de recompensa: %d puntos
• Tiempo disponible: %d segundos
• Si el tiempo se agota, perderás 1 vida y el contador se reiniciará.
• ¡CUIDADO! Si ejecutas una acción riesgosa (como terminar procesos vitales del kernel como systemd o asignar permisos inseguros), el sistema revertirá la acción y perderás 1 vida.""" % [diff_name, max_lives, total_score, int(time_limit)]

	tutorial_body.text = rules_text

func _start_match() -> void:
	AudioManager.play_click()
	_hide_all_modals()
	super.start_game(current_difficulty)

	current_lives = max_lives
	is_game_paused = false
	current_input_text = ""
	history_index = -1
	cursor_visible = true
	cursor_timer = 0.0

	# Cargar datos de la misión según la dificultad elegida
	current_mission = LinuxData.get_random_mission(current_difficulty)
	var init_procs: Array = current_mission.get("initial_processes", [])
	var init_fs: Dictionary = current_mission.get("initial_fs", {})
	var init_path: String = current_mission.get("initial_path", "/home/user")
	var prompt_usr: String = current_mission.get("prompt_user", "user@is-pixelverse:~$")

	# Inicializar la shell simulada
	shell.initialize(init_procs, init_fs, init_path, "user")

	# Inicializar objetivos
	var objs: Array = current_mission.get("objectives", [])
	objectives_status.clear()
	for _o in objs:
		objectives_status.append(false)

	# Configurar HUD
	challenge_label.text = "DESAFÍO: %s" % current_difficulty
	teacher_label.text = current_mission.get("situation", "Resuelve la situación mediante la terminal.")
	_update_lives_hud()

	# Configurar pantalla y terminal inicial
	terminal_prompt_label.text = prompt_usr
	terminal_history = ""
	_append_terminal_line("[color=#00e676]╔═════════════════════════════════════════════════════════════╗[/color]")
	_append_terminal_line("[color=#00e676]║[/color] [color=#ffffff]PixelVerse Linux Simulator v2.0 - Terminal Interactiva[/color]       [color=#00e676]║[/color]")
	_append_terminal_line("[color=#00e676]╚═════════════════════════════════════════════════════════════╝[/color]")
	_append_terminal_line("[color=#888888]GNU bash, versión 5.2.15-release (x86_64-pc-linux-gnu)[/color]")
	_append_terminal_line("[color=#aaccff]Escribe comandos en el renglón activo o usa el teclado virtual inferior.[/color]\n")

	# Dibujar objetivos iniciales
	_refresh_objectives_display()

	# Iniciar temporizador
	time_remaining = time_limit
	is_timer_active = true
	_update_timer_display()

	EventBus.minigame_started.emit(minigame_id, current_difficulty)

# ==================== RENDERIZADO DE TERMINAL REAL ====================

## Renderiza el contenido acumulado de la terminal, dejando el renglón activo
## con el prompt actual y el cursor parpadeante en la última línea
func _render_terminal_display() -> void:
	var prompt_str := "[color=#22ddff]%s[/color]" % shell.get_prompt_text()
	var cursor_char := "█" if cursor_visible else " "
	var active_line := "%s[color=#ffffff]%s[/color][color=#00e5ff]%s[/color]" % [prompt_str, current_input_text, cursor_char]

	if terminal_history == "":
		terminal_output.text = active_line
	else:
		terminal_output.text = terminal_history + "\n" + active_line

	await get_tree().process_frame
	if is_instance_valid(terminal_scroll):
		terminal_scroll.scroll_vertical = int(terminal_scroll.get_v_scroll_bar().max_value)

func _append_terminal_line(text: String) -> void:
	if terminal_history == "":
		terminal_history = text
	else:
		terminal_history += "\n" + text
	_render_terminal_display()

# ==================== ENTRADA Y EJECUCIÓN DE COMANDOS ====================

func _submit_current_command() -> void:
	if not is_timer_active or is_game_paused:
		return

	var raw_cmd: String = current_input_text.strip_edges()
	var prompt_str := "[color=#22ddff]%s[/color]" % shell.get_prompt_text()

	# Se estampa la línea ejecutada en el historial acumulado
	if terminal_history == "":
		terminal_history = "%s[color=#ffffff]%s[/color]" % [prompt_str, current_input_text]
	else:
		terminal_history += "\n%s[color=#ffffff]%s[/color]" % [prompt_str, current_input_text]

	current_input_text = ""
	history_index = -1
	cursor_visible = true
	cursor_timer = 0.0

	# Si envió línea vacía, simplemente despliega el nuevo prompt en el renglón siguiente
	if raw_cmd == "":
		_render_terminal_display()
		return

	# FN-03 y FN-04: El sistema valida y ejecuta de manera simulada el comando
	var result: Dictionary = shell.execute_command(raw_cmd)
	var out: String = result.get("output", "")
	var is_risky: bool = result.get("is_risky", false)
	var is_error: bool = result.get("is_error", false)

	# FN-05: El sistema muestra en la terminal el resultado de la ejecución
	if out == "__CLEAR__":
		terminal_history = ""
	elif out != "":
		terminal_history += "\n" + out

	_render_terminal_display()

	# FA-04.01: Acción riesgosa o contraria a la misión
	if is_risky:
		AudioManager.play_error()
		teacher_label.text = "¡Cuidado! Esa acción ponía en riesgo la estabilidad del sistema."
		_deduct_life("Acción peligrosa ejecutada")
		return

	# FA-03.01: Error de comando o sintaxis (no se descuenta vida)
	if is_error:
		AudioManager.play_click()

	# FN-06: Verificar objetivos cumplidos y actualizar estado
	_check_mission_objectives()

func _check_mission_objectives() -> void:
	var objs: Array = current_mission.get("objectives", [])
	var new_statuses: Array[bool] = LinuxData.evaluate_objectives(shell, objs)

	var newly_completed_any := false
	for i in range(objs.size()):
		if not objectives_status[i] and new_statuses[i]:
			objectives_status[i] = true
			newly_completed_any = true
			var desc: String = objs[i].get("desc", "")
			_append_terminal_line("[color=#33ff77][✓ OBJETIVO CUMPLIDO] %s[/color]" % desc)
		elif objectives_status[i] and not new_statuses[i]:
			objectives_status[i] = false

	if newly_completed_any:
		AudioManager.play_success()

	_refresh_objectives_display()

	# FN-08: Verificar si todos los objetivos fueron cumplidos
	var all_done := true
	for done in objectives_status:
		if not done:
			all_done = false
			break

	if all_done and not objectives_status.is_empty():
		_handle_victory()

func _refresh_objectives_display() -> void:
	for child in objectives_container.get_children():
		objectives_container.remove_child(child)
		child.queue_free()

	var objs: Array = current_mission.get("objectives", [])
	var completed_count := 0

	for i in range(objs.size()):
		var is_done: bool = objectives_status[i] if i < objectives_status.size() else false
		if is_done:
			completed_count += 1

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var icon := Label.new()
		icon.custom_minimum_size = Vector2(20, 0)
		icon.add_theme_font_size_override("font_size", 10)

		var desc := Label.new()
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 9)
		desc.text = str(objs[i].get("desc", ""))

		if is_done:
			icon.text = "[✓]"
			icon.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 1.0))
			desc.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5, 0.9))
		else:
			icon.text = "[  ]"
			icon.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.8))
			desc.add_theme_color_override("font_color", Color(0.88, 0.90, 0.94, 1.0))

		row.add_child(icon)
		row.add_child(desc)
		objectives_container.add_child(row)

	objectives_header.text = "📋 OBJETIVOS DE LA MISIÓN (%d / %d):" % [completed_count, objs.size()]

func _on_shell_state_changed() -> void:
	_render_terminal_display()

func _on_risky_action_detected(reason: String) -> void:
	teacher_label.text = "¡Alerta! %s" % reason

# ==================== TECLADO VIRTUAL INTERACTIVO ====================

func _setup_virtual_keyboard() -> void:
	# Configurar barra de chips de comandos rápidos
	for child in quick_bar.get_children():
		quick_bar.remove_child(child)
		child.queue_free()

	var quick_cmds: Array[String] = ["ps aux", "kill ", "chmod ", "chown ", "ls -l", "cat ", "clear"]
	for q in quick_cmds:
		var btn := Button.new()
		btn.text = q.strip_edges()
		btn.custom_minimum_size = Vector2(40, 24)
		btn.add_theme_font_size_override("font_size", 9)
		btn.focus_mode = FOCUS_NONE
		btn.pressed.connect(func(): _insert_quick_token(q))
		quick_bar.add_child(btn)

	_render_keyboard_layout()

func _render_keyboard_layout() -> void:
	for child in keyboard_keys_vbox.get_children():
		keyboard_keys_vbox.remove_child(child)
		child.queue_free()

	var rows: Array[Array] = []
	if keyboard_mode == "ABC":
		rows = [
			["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"],
			["a", "s", "d", "f", "g", "h", "j", "k", "l", "-"],
			["z", "x", "c", "v", "b", "n", "m", "/", ".", "_"]
		]
	else:
		rows = [
			["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
			["+x", "-x", "600", "644", "755", "700", "777", "9", "|", "-"],
			[":", "=", "~", "*", "$", ";", "/", ".", "_", "#"]
		]

	for r in rows:
		var row_box := HBoxContainer.new()
		row_box.add_theme_constant_override("separation", 3)
		row_box.alignment = BoxContainer.ALIGNMENT_CENTER

		for key_char in r:
			var btn := Button.new()
			btn.text = str(key_char)
			btn.custom_minimum_size = Vector2(26, 26)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.add_theme_font_size_override("font_size", 10)
			btn.focus_mode = FOCUS_NONE
			btn.pressed.connect(func(): _append_input_char(str(key_char)))
			row_box.add_child(btn)

		keyboard_keys_vbox.add_child(row_box)

func _toggle_keyboard_mode() -> void:
	AudioManager.play_click()
	if keyboard_mode == "ABC":
		keyboard_mode = "123"
		btn_toggle_keyboard_mode.text = "ABC"
	else:
		keyboard_mode = "ABC"
		btn_toggle_keyboard_mode.text = "123"
	_render_keyboard_layout()

func _insert_quick_token(token: String) -> void:
	AudioManager.play_click()
	if current_input_text == "" or current_input_text.ends_with(" "):
		current_input_text += token
	else:
		current_input_text += " " + token
	cursor_visible = true
	cursor_timer = 0.0
	_render_terminal_display()

func _append_input_char(c: String) -> void:
	AudioManager.play_step()
	current_input_text += c
	cursor_visible = true
	cursor_timer = 0.0
	_render_terminal_display()

func _on_backspace_pressed() -> void:
	AudioManager.play_step()
	if current_input_text.length() > 0:
		current_input_text = current_input_text.substr(0, current_input_text.length() - 1)
		cursor_visible = true
		cursor_timer = 0.0
		_render_terminal_display()

# Soporte para teclado físico del ordenador (PC / Mac)
func _unhandled_key_input(event: InputEvent) -> void:
	if not is_timer_active or is_game_paused:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_submit_current_command()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_BACKSPACE:
			_on_backspace_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_UP:
			_navigate_history(-1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			_navigate_history(1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_C and event.ctrl_pressed:
			# Ctrl+C cancelar renglón actual estilo bash
			var prompt_str := "[color=#22ddff]%s[/color]" % shell.get_prompt_text()
			_append_terminal_line("%s[color=#ffffff]%s^C[/color]" % [prompt_str, current_input_text])
			current_input_text = ""
			history_index = -1
			get_viewport().set_input_as_handled()
		elif event.unicode >= 32 and event.unicode != 127:
			_append_input_char(char(event.unicode))
			get_viewport().set_input_as_handled()

func _navigate_history(direction: int) -> void:
	var hist: Array = shell.command_history
	if hist.is_empty():
		return
	if history_index == -1:
		history_index = hist.size()
	history_index = clampi(history_index + direction, 0, hist.size() - 1)
	current_input_text = str(hist[history_index])
	cursor_visible = true
	cursor_timer = 0.0
	_render_terminal_display()

# ==================== GESTIÓN DE TIEMPO, VIDAS Y RESULTADOS ====================

func _on_time_out() -> void:
	AudioManager.play_error()
	_append_terminal_line("[color=#ff3333][ TIEMPO EXPIRADO ] El contador llegó a 0 (-1 Vida).[/color]")
	teacher_label.text = "¡Se agotó el tiempo! El temporizador se reinicia para este intento."
	_deduct_life("Tiempo límite agotado")

func _deduct_life(reason: String) -> void:
	current_lives = maxi(0, current_lives - 1)
	_update_lives_hud()
	EventBus.life_lost.emit(current_lives)

	if current_lives <= 0:
		_handle_game_over(reason)
	else:
		# FA-02.02: Reinicia el contador de acuerdo con la dificultad seleccionada
		time_remaining = time_limit
		_update_timer_display()

func _handle_game_over(reason: String) -> void:
	is_timer_active = false
	AudioManager.play_game_over()
	EventBus.game_over.emit(minigame_id)
	finish_game(false, 0, 0, "Misión fallida: " + reason)

	game_over_desc.text = "Causa: %s.\nHas agotado todas tus vidas en dificultad %s.\n(No se registrarán puntos según las reglas del caso de uso)." % [reason, current_difficulty]
	modal_game_over.visible = true

func _handle_victory() -> void:
	_hide_all_modals()
	is_timer_active = false
	AudioManager.play_success()

	_append_terminal_line("[color=#33ff77]═════════════════════════════════════════════════════════════[/color]")
	_append_terminal_line("[color=#33ff77][✓ MISIÓN CUMPLIDA] ¡Todos los objetivos fueron completados con éxito![/color]")
	_append_terminal_line("[color=#33ff77]Puntuación otorgada: +%d puntos.[/color]" % total_score)
	_append_terminal_line("[color=#33ff77]═════════════════════════════════════════════════════════════[/color]")

	teacher_label.text = "¡Excelente labor de administración! Has asegurado el sistema correctamente."

	var stars: int = 1
	if current_lives == max_lives:
		stars = 3
	elif current_lives >= 2:
		stars = 2

	finish_game(true, total_score, stars, "Misión de administración de permisos y procesos completada")

	victory_summary.text = """¡Misión de Administración de Permisos y Procesos Superada!

• Dificultad: %s
• Puntos de Misión: %d pts
• Vidas Conservadas: %d / %d
• Estrellas Obtenidas: %d / 3
• Objetivos Completados: 100%%""" % [current_difficulty, total_score, current_lives, max_lives, stars]

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
