## RoboFlow.gd - Minijuego de Control de Flujos
## Minijuego educativo de programación secuencial de un autómata
## Cumple estrictamente con el Diagrama de Secuencia y Casos de Uso (TSP A26 / ISO/IEC 29110)
## Responsable: Carlos Manuel Aguirre Norato (Líder Técnico)
extends MiniGameBase

# Configuración de mapa según dificultad
var grid_cols: int = 5
var grid_rows: int = 6
var max_instructions: int = 15
var max_lives: int = 3
var current_lives: int = 3
var start_pos := Vector2i(2, 0)
var current_pos := Vector2i(2, 0)
var current_dir: String = "S" # N, E, S, O
var goal_pos := Vector2i(2, 5)
var obstacles: Array[Vector2i] = []

var instructions: Array[String] = []
var is_running: bool = false
var attempts: int = 0
var selected_diff: String = "NORMAL"

# Referencias a Pantallas Principales
@onready var screen_start = $ScreenStart
@onready var screen_game = $ScreenGame
@onready var screen_victory = $ScreenVictory
@onready var screen_game_over = $ScreenGameOver

# Nodos - Pantalla de Inicio
@onready var btn_diff_facil = $ScreenStart/VBox/DiffSelector/BtnDiffFacil
@onready var btn_diff_normal = $ScreenStart/VBox/DiffSelector/BtnDiffNormal
@onready var btn_diff_ing = $ScreenStart/VBox/DiffSelector/BtnDiffIng
@onready var btn_iniciar = $ScreenStart/VBox/BtnIniciar

# Nodos - Pantalla de Juego
@onready var status_label: Label = $ScreenGame/Margin/VBox/StatusBanner/Label
@onready var board_grid: GridContainer = $ScreenGame/Margin/VBox/BoardPanel/GridBoard
@onready var pipeline_container: HBoxContainer = $ScreenGame/Margin/VBox/PipelineSection/Scroll/PipelineSlots
@onready var pipeline_title: Label = $ScreenGame/Margin/VBox/PipelineSection/Label
@onready var btn_fwd: Button = $ScreenGame/Margin/VBox/Palette/BtnFwd
@onready var btn_left: Button = $ScreenGame/Margin/VBox/Palette/BtnLeft
@onready var btn_right: Button = $ScreenGame/Margin/VBox/Palette/BtnRight
@onready var btn_del: Button = $ScreenGame/Margin/VBox/Controls/BtnDel
@onready var btn_clear: Button = $ScreenGame/Margin/VBox/Controls/BtnClear
@onready var btn_run: Button = $ScreenGame/Margin/VBox/Controls/BtnRun
@onready var btn_back: Button = $ScreenGame/Margin/VBox/TopHUD/BtnBack
@onready var lives_label: Label = $ScreenGame/Margin/VBox/TopHUD/LivesLabel

# Nodos - Pantallas de Fin
@onready var lbl_victory_stats = $ScreenVictory/VBox/LblStats
@onready var btn_victory_back = $ScreenVictory/VBox/BtnVolver
@onready var lbl_gameover_reason = $ScreenGameOver/VBox/LblReason
@onready var btn_gameover_restart = $ScreenGameOver/VBox/BtnReiniciar
@onready var btn_gameover_back = $ScreenGameOver/VBox/BtnVolver

func _ready() -> void:
	super._ready()
	minigame_id = "roboflow"
	minigame_title = "RoboFlow: Control de Flujos"
	subject_name = "Introducción a la Programación"

	# Conexiones: Pantalla de Inicio
	btn_diff_facil.pressed.connect(func(): select_difficulty_ui("FACIL"))
	btn_diff_normal.pressed.connect(func(): select_difficulty_ui("NORMAL"))
	btn_diff_ing.pressed.connect(func(): select_difficulty_ui("INGENIERO"))
	btn_iniciar.pressed.connect(_on_iniciar_pressed)

	# Conexiones: Pantalla de Juego
	btn_fwd.pressed.connect(func(): add_instruction("FORWARD"))
	btn_left.pressed.connect(func(): add_instruction("TURN_LEFT"))
	btn_right.pressed.connect(func(): add_instruction("TURN_RIGHT"))
	btn_del.pressed.connect(remove_last_instruction)
	btn_clear.pressed.connect(reiniciar_nivel)
	btn_run.pressed.connect(run_program)
	btn_back.pressed.connect(_on_back_pressed)

	# Conexiones: Pantallas Finales
	btn_victory_back.pressed.connect(_on_back_pressed)
	btn_gameover_restart.pressed.connect(_on_iniciar_pressed)
	btn_gameover_back.pressed.connect(_on_back_pressed)

	_show_screen(screen_start)
	select_difficulty_ui("NORMAL")

func _show_screen(screen: Control) -> void:
	screen_start.visible = false
	screen_game.visible = false
	screen_victory.visible = false
	screen_game_over.visible = false
	screen.visible = true

func select_difficulty_ui(diff: String) -> void:
	selected_diff = diff
	btn_diff_facil.modulate = Color(1,1,1) if diff != "FACIL" else Color(0.3, 0.9, 0.3)
	btn_diff_normal.modulate = Color(1,1,1) if diff != "NORMAL" else Color(0.3, 0.9, 0.3)
	btn_diff_ing.modulate = Color(1,1,1) if diff != "INGENIERO" else Color(0.3, 0.9, 0.3)
	if AudioManager.has_method("play_click"):
		AudioManager.play_click()

func _on_iniciar_pressed() -> void:
	if AudioManager.has_method("play_click"):
		AudioManager.play_click()
	
	current_difficulty = selected_diff
	setup_level(current_difficulty)
	_show_screen(screen_game)

func setup_level(diff: String) -> void:
	current_difficulty = diff
	match diff:
		"FACIL":
			grid_cols = 5
			grid_rows = 5
			max_instructions = 15
			max_lives = 3
			current_lives = 3
			start_pos = Vector2i(0, 0)
			goal_pos = Vector2i(4, 4)
			obstacles = [Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(3, 3)]
		"NORMAL":
			grid_cols = 6
			grid_rows = 6
			max_instructions = 25
			max_lives = 3
			current_lives = 3
			start_pos = Vector2i(0, 0)
			goal_pos = Vector2i(5, 5)
			obstacles = [
				Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3),
				Vector2i(3, 2), Vector2i(3, 3), Vector2i(3, 4), Vector2i(3, 5),
				Vector2i(4, 1), Vector2i(5, 1)
			]
		"INGENIERO":
			grid_cols = 7
			grid_rows = 7
			max_instructions = 45
			max_lives = 1
			current_lives = 1
			start_pos = Vector2i(0, 0)
			goal_pos = Vector2i(6, 6)
			obstacles = [
				Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(4, 0),
				Vector2i(4, 1), Vector2i(4, 2), Vector2i(4, 3), Vector2i(2, 4),
				Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4), Vector2i(1, 6),
				Vector2i(2, 6), Vector2i(6, 2)
			]

	instructions.clear()
	reset_robot()
	build_board_ui()
	update_pipeline_ui()
	update_lives_display()
	btn_run.disabled = false
	attempts = 0
	is_running = false
	pipeline_title.text = "LÍNEA DE EJECUCIÓN (Límite: %d):" % max_instructions
	
	if EventBus.has_signal("minigame_started"):
		EventBus.minigame_started.emit(minigame_id, current_difficulty)
		
	set_status("Dificultad %s iniciada. Construye tu algoritmo." % current_difficulty)

func update_lives_display() -> void:
	if lives_label:
		lives_label.text = "Vidas: %d / %d" % [current_lives, max_lives]

func reset_robot() -> void:
	current_pos = start_pos
	current_dir = "S"

func build_board_ui() -> void:
	for child in board_grid.get_children():
		child.queue_free()

	board_grid.columns = grid_cols

	for y in range(grid_rows):
		for x in range(grid_cols):
			var cell := PanelContainer.new()
			cell.custom_minimum_size = Vector2(40, 40)
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var lbl := Label.new()
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.name = "CellLabel"

			var pos := Vector2i(x, y)
			if pos in obstacles:
				lbl.text = "[X]"
				cell.modulate = Color(0.8, 0.3, 0.3)
			elif pos == goal_pos:
				lbl.text = "META"
				cell.modulate = Color(0.3, 0.9, 0.4)
			else:
				lbl.text = "·"

			cell.add_child(lbl)
			cell.set_meta("grid_pos", pos)
			board_grid.add_child(cell)

	update_robot_display()

func update_robot_display() -> void:
	var arrows := { "N": "^", "E": ">", "S": "v", "O": "<" }
	for cell in board_grid.get_children():
		var pos: Vector2i = cell.get_meta("grid_pos", Vector2i(-1, -1))
		var lbl: Label = cell.get_node("CellLabel")
		if pos == current_pos:
			lbl.text = "R" + arrows.get(current_dir, "v")
			cell.modulate = Color(0.2, 0.8, 1.0)
		elif pos in obstacles:
			lbl.text = "[X]"
			cell.modulate = Color(0.8, 0.3, 0.3)
		elif pos == goal_pos:
			lbl.text = "META"
			cell.modulate = Color(0.3, 0.9, 0.4)
		else:
			lbl.text = "·"
			cell.modulate = Color(1, 1, 1, 0.8)

func add_instruction(cmd: String) -> void:
	if is_running or current_lives <= 0:
		return
	if instructions.size() >= max_instructions:
		if AudioManager.has_method("play_error"):
			AudioManager.play_error()
		set_status("Límite de %d instrucciones alcanzado." % max_instructions)
		return

	if AudioManager.has_method("play_click"):
		AudioManager.play_click()
	instructions.append(cmd)
	update_pipeline_ui()

func remove_last_instruction() -> void:
	if is_running or instructions.is_empty() or current_lives <= 0:
		return
	if AudioManager.has_method("play_click"):
		AudioManager.play_click()
	instructions.pop_back()
	update_pipeline_ui()

func reiniciar_nivel() -> void:
	if is_running:
		return
	if AudioManager.has_method("play_click"):
		AudioManager.play_click()
	instructions.clear()
	current_lives = max_lives
	reset_robot()
	update_robot_display()
	update_pipeline_ui()
	update_lives_display()
	btn_run.disabled = false
	set_status("Nivel reiniciado. Vidas restauradas a %d." % max_lives)

func update_pipeline_ui() -> void:
	for child in pipeline_container.get_children():
		child.queue_free()

	var labels := { "FORWARD": "AVAN", "TURN_LEFT": "IZQ", "TURN_RIGHT": "DER" }
	
	for i in range(instructions.size()):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(45, 45)
		var lbl := Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.text = "%d\n%s" % [i + 1, labels.get(instructions[i], "")]
		slot.modulate = Color(0.3, 0.9, 1.0)
		slot.add_child(lbl)
		pipeline_container.add_child(slot)
		
	# Mover el scroll al final
	await get_tree().process_frame
	var scroll = pipeline_container.get_parent() as ScrollContainer
	if scroll:
		scroll.scroll_horizontal = int(scroll.get_h_scroll_bar().max_value)

func deduct_life(reason: String) -> void:
	current_lives = maxi(0, current_lives - 1)
	update_lives_display()
	
	if AudioManager.has_method("play_error"):
		AudioManager.play_error()
		
	if EventBus.has_signal("life_lost"):
		EventBus.life_lost.emit(current_lives)

	if current_lives <= 0:
		handle_game_over(reason)
	else:
		set_status("FALLO: %s (-1 vida). Restantes: %d." % [reason, current_lives])
		reset_robot()
		update_robot_display()

func handle_game_over(reason: String) -> void:
	is_running = false
	if AudioManager.has_method("play_game_over"):
		AudioManager.play_game_over()
		
	if EventBus.has_signal("game_over"):
		EventBus.game_over.emit(minigame_id)
		
	lbl_gameover_reason.text = "Motivo: " + reason
	_show_screen(screen_game_over)

func run_program() -> void:
	if is_running:
		return
	if current_lives <= 0:
		return
	if instructions.is_empty():
		if AudioManager.has_method("play_error"):
			AudioManager.play_error()
		set_status("¡El flujo está vacío! Agrega instrucciones.")
		return

	is_running = true
	attempts += 1
	reset_robot()
	update_robot_display()
	set_status("Compilando y ejecutando flujo...")

	var dirs := ["N", "E", "S", "O"]
	var deltas := {
		"N": Vector2i(0, -1),
		"E": Vector2i(1, 0),
		"S": Vector2i(0, 1),
		"O": Vector2i(-1, 0)
	}

	for i in range(instructions.size()):
		if not is_running:
			break

		var cmd: String = instructions[i]
		if cmd == "FORWARD":
			var delta: Vector2i = deltas.get(current_dir, Vector2i.ZERO)
			var next_pos: Vector2i = current_pos + delta

			if next_pos.x < 0 or next_pos.x >= grid_cols or next_pos.y < 0 or next_pos.y >= grid_rows:
				is_running = false
				deduct_life("Fuera de los límites del tablero")
				return

			if next_pos in obstacles:
				is_running = false
				deduct_life("Colisión contra obstáculo")
				return

			current_pos = next_pos
			if AudioManager.has_method("play_step"):
				AudioManager.play_step()
				
		elif cmd == "TURN_LEFT":
			var idx: int = dirs.find(current_dir)
			current_dir = dirs[(idx + 3) % 4]
			if AudioManager.has_method("play_rotate"):
				AudioManager.play_rotate()
				
		elif cmd == "TURN_RIGHT":
			var idx: int = dirs.find(current_dir)
			current_dir = dirs[(idx + 1) % 4]
			if AudioManager.has_method("play_rotate"):
				AudioManager.play_rotate()

		update_robot_display()
		await get_tree().create_timer(0.40).timeout

		if current_pos == goal_pos:
			handle_victory()
			return

	is_running = false
	if current_pos != goal_pos:
		deduct_life("Fin de instrucciones sin alcanzar la meta")

func handle_victory() -> void:
	is_running = false
	if AudioManager.has_method("play_success"):
		AudioManager.play_success()

	var stars: int = 1
	var perfect_steps = 0
	match current_difficulty:
		"FACIL": perfect_steps = 10
		"NORMAL": perfect_steps = 18
		"INGENIERO": perfect_steps = 28
		
	if instructions.size() <= perfect_steps and current_lives == max_lives:
		stars = 3
	elif instructions.size() <= max_instructions:
		stars = 2

	var base_score: int = 250
	match current_difficulty:
		"FACIL": base_score = 100
		"NORMAL": base_score = 250
		"INGENIERO": base_score = 500

	var lives_bonus: int = current_lives * 40
	var final_score: int = maxi(50, base_score * stars + lives_bonus - (attempts - 1) * 20)
	var steps_taken: int = instructions.size()
	
	lbl_victory_stats.text = "Pasos Tomados: %d\nPuntuación Final: %d\nEstrellas: %d\nVidas Restantes: %d" % [steps_taken, final_score, stars, current_lives]
	
	finish_game(true, final_score, stars, "Flujo completado exitosamente")
	_show_screen(screen_victory)

func set_status(msg: String) -> void:
	if status_label:
		status_label.text = msg

func _on_back_pressed() -> void:
	if AudioManager.has_method("play_click"):
		AudioManager.play_click()
	if ResourceLoader.exists("res://scenes/classroom/AulaProgramacion.tscn"):
		get_tree().change_scene_to_file("res://scenes/classroom/AulaProgramacion.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/campus/Lobby.tscn")
