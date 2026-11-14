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
var start_pos := Vector2i(4, 4)
var current_pos := Vector2i(4, 4)
var current_dir: String = "N" # N, E, S, O
var goal_pos := Vector2i(0, 0)
var obstacles: Array[Vector2i] = []

var instructions: Array[String] = []
var is_running: bool = false
var is_game_paused: bool = false
var attempts: int = 0
var selected_diff: String = "NORMAL"

# Referencias a Pantallas Principales
@onready var screen_start = $ScreenStart
@onready var screen_game = $ScreenGame
@onready var screen_pause = $ScreenPause
@onready var screen_victory = $ScreenVictory
@onready var screen_game_over = $ScreenGameOver

# Nodos - Pantalla de Inicio
@onready var btn_diff_facil = $ScreenStart/VBox/DiffSelector/BtnDiffFacil
@onready var btn_diff_normal = $ScreenStart/VBox/DiffSelector/BtnDiffNormal
@onready var btn_diff_ing = $ScreenStart/VBox/DiffSelector/BtnDiffIng
@onready var btn_iniciar = $ScreenStart/VBox/BtnIniciar
@onready var diff_label: Label = $ScreenStart/VBox/DiffLabel
@onready var diff_selector: HBoxContainer = $ScreenStart/VBox/DiffSelector

var flow_template: Control
var dir_chip: Label
var hearts_bar: HBoxContainer
var hud_mode_label: Label

const DIR_DELTAS := {
	"N": Vector2i(0, -1),
	"E": Vector2i(1, 0),
	"S": Vector2i(0, 1),
	"O": Vector2i(-1, 0)
}
const DIR_LABELS := {
	"N": "🧭 Vista: ▲ Arriba",
	"E": "🧭 Vista: ▶ Derecha",
	"S": "🧭 Vista: ▼ Abajo",
	"O": "🧭 Vista: ◀ Izquierda"
}

const TEX_ROBOT = preload("res://assets/minigames/aula101/robot.svg")
const TEX_FLAG = preload("res://assets/minigames/aula101/flag_meta.svg")
const TEX_OBSTACLE = preload("res://assets/minigames/aula101/obstacle.svg")

# Nodos - Pantalla de Juego
@onready var status_label: Label = $ScreenGame/Margin/VBox/StatusBanner/Label
@onready var board_grid: GridContainer = $ScreenGame/Margin/VBox/BoardPanel/GridBoard
@onready var pipeline_container: HBoxContainer = $ScreenGame/Margin/VBox/PipelineSection/Scroll/PipelineSlots
@onready var pipeline_title: Label = $ScreenGame/Margin/VBox/PipelineSection/Label
@onready var btn_fwd: Button = $ScreenGame/Margin/VBox/ActionGrid/BtnFwd
@onready var btn_left: Button = $ScreenGame/Margin/VBox/ActionGrid/BtnLeft
@onready var btn_right: Button = $ScreenGame/Margin/VBox/ActionGrid/BtnRight
@onready var btn_del: Button = $ScreenGame/Margin/VBox/ActionGrid/BtnDel
@onready var btn_clear: Button = $ScreenGame/Margin/VBox/ActionGrid/BtnClear
@onready var btn_run: Button = $ScreenGame/Margin/VBox/ActionGrid/BtnRun
@onready var btn_pause: Button = $ScreenGame/Margin/VBox/TopHUD/BtnPause
@onready var lives_label: Label = $ScreenGame/Margin/VBox/TopHUD/LivesLabel

# Nodos - Pantallas de Fin y Pausa
@onready var lbl_victory_stats = $ScreenVictory/VBox/LblStats
@onready var btn_victory_back = $ScreenVictory/VBox/BtnVolver
@onready var lbl_gameover_reason = $ScreenGameOver/VBox/LblReason
@onready var btn_gameover_restart = $ScreenGameOver/VBox/BtnReiniciar
@onready var btn_gameover_back = $ScreenGameOver/VBox/BtnVolver
@onready var btn_pause_resume = $ScreenPause/VBox/BtnResume
@onready var btn_pause_restart = $ScreenPause/VBox/BtnRestart
@onready var btn_pause_back = $ScreenPause/VBox/BtnBack

func _ready() -> void:
	super._ready()
	minigame_id = "roboflow"
	minigame_title = "RoboFlow"
	subject_name = "Introducción a la Programación"

	# Desactivar pantallas estáticas redundantes del .tscn
	screen_start.visible = false
	screen_pause.visible = false

	# Fondo didáctico de hoja de libreta con 80% opacidad / 20% transparencia
	$ColorRect.visible = false
	attach_notebook_background(self, 0.80)

	# Estilos Kenney UI para los 6 botones de ejecución y pausa
	style_kenney_button(btn_fwd, "blue", 42.0)
	style_kenney_button(btn_left, "yellow", 42.0)
	style_kenney_button(btn_right, "yellow", 42.0)
	style_kenney_button(btn_del, "red", 42.0)
	style_kenney_button(btn_clear, "neutral", 42.0)
	style_kenney_button(btn_run, "green", 42.0)

	# Estandarización del TopHUD del Aula 101 (misma barra, botón "||" y corazones pixel-art)
	var game_margin := get_node_or_null("ScreenGame/Margin") as MarginContainer
	if is_instance_valid(game_margin):
		game_margin.add_theme_constant_override("margin_left", 10)
		game_margin.add_theme_constant_override("margin_top", 10)
		game_margin.add_theme_constant_override("margin_right", 10)
		game_margin.add_theme_constant_override("margin_bottom", 10)
	var top_hud := get_node_or_null("ScreenGame/Margin/VBox/TopHUD") as HBoxContainer
	if is_instance_valid(top_hud):
		var lead_spacer := top_hud.get_node_or_null("Spacer") as Control
		if is_instance_valid(lead_spacer):
			lead_spacer.visible = false
		style_aula101_pause_button(btn_pause)
		hud_mode_label = Label.new()
		hud_mode_label.name = "ModeLabel"
		hud_mode_label.text = "NIVEL: NORMAL"
		hud_mode_label.add_theme_font_size_override("font_size", 10)
		hud_mode_label.add_theme_color_override("font_color", Color("ffd54f"))
		hud_mode_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		stabilize_hud_label(hud_mode_label, 110.0)
		top_hud.add_child(hud_mode_label)
		top_hud.move_child(hud_mode_label, btn_pause.get_index() + 1)
		hearts_bar = create_aula101_hearts_bar(current_lives, max_lives, 14.0)
		top_hud.add_child(hearts_bar)
		wrap_hbox_in_aula101_hud_panel(top_hud)
	else:
		style_aula101_pause_button(btn_pause)

	btn_fwd.text = "▲ AVANZAR"
	btn_left.text = "↶ GIRO IZQ"
	btn_right.text = "↷ GIRO DER"
	btn_del.text = "⌫ BORRAR"
	btn_clear.text = "↺ REINICIAR"
	btn_run.text = "▶ EJECUTAR"

	for b in [btn_fwd, btn_left, btn_right, btn_del, btn_clear, btn_run]:
		b.modulate.a = 0.90

	# Recuadro de estado y título de rutina + chip de orientación fijos (sin redimensionar la pantalla)
	var status_banner := $ScreenGame/Margin/VBox/StatusBanner as PanelContainer
	if is_instance_valid(status_banner):
		style_kenney_panel(status_banner, "inner")
	lock_dynamic_label_box(status_label, status_banner, 48.0, 12, 7, 2.0, 0.0, true, true, 6.0)

	var pipe_sec := pipeline_title.get_parent()
	if pipe_sec:
		var title_idx := pipeline_title.get_index()
		var pipe_header := HBoxContainer.new()
		pipe_header.name = "PipelineHeader"
		pipe_header.add_theme_constant_override("separation", 6)
		pipe_sec.add_child(pipe_header)
		pipe_sec.move_child(pipe_header, title_idx)

		pipe_sec.remove_child(pipeline_title)
		pipeline_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pipe_header.add_child(pipeline_title)
		lock_dynamic_label_box(pipeline_title, null, 22.0, 11, 7, 0.0, 0.0, false, true)

		var chip_panel := PanelContainer.new()
		chip_panel.name = "DirChipPanel"
		chip_panel.custom_minimum_size = Vector2(142, 24)
		chip_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
		chip_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var chip_sb := StyleBoxFlat.new()
		chip_sb.bg_color = Color(0.05, 0.14, 0.24, 0.92)
		chip_sb.border_color = Color(0.15, 0.90, 1.0, 0.90)
		chip_sb.set_border_width_all(1)
		chip_sb.set_corner_radius_all(6)
		chip_sb.content_margin_left = 6
		chip_sb.content_margin_right = 6
		chip_sb.content_margin_top = 1
		chip_sb.content_margin_bottom = 1
		chip_panel.add_theme_stylebox_override("panel", chip_sb)
		pipe_header.add_child(chip_panel)

		dir_chip = Label.new()
		dir_chip.name = "DirChipLabel"
		dir_chip.text = DIR_LABELS["N"]
		dir_chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dir_chip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		dir_chip.add_theme_color_override("font_color", Color(0.55, 0.96, 1.0))
		dir_chip.add_theme_font_size_override("font_size", 10)
		chip_panel.add_child(dir_chip)
		lock_dynamic_label_box(dir_chip, chip_panel, 22.0, 10, 7, 4.0, 0.0, false, true, 1.0)
	else:
		lock_dynamic_label_box(pipeline_title, null, 20.0, 11, 8, 0.0, 0.0, false, true)
	update_lives_display()

	# Marco cybernetico para el tablero del laberinto
	var parent_panel: CenterContainer = board_grid.get_parent() as CenterContainer
	if parent_panel and not board_grid.get_parent().is_class("PanelContainer"):
		var cyber_panel := PanelContainer.new()
		var cp_style := StyleBoxFlat.new()
		cp_style.bg_color = Color(0.03, 0.06, 0.12, 0.85)
		cp_style.border_color = Color(0.0, 0.90, 1.0, 0.85)
		cp_style.set_border_width_all(2)
		cp_style.set_corner_radius_all(8)
		cp_style.set_content_margin_all(8)
		cyber_panel.add_theme_stylebox_override("panel", cp_style)
		
		parent_panel.remove_child(board_grid)
		cyber_panel.add_child(board_grid)
		parent_panel.add_child(cyber_panel)

	# Conexiones: Pantalla de Juego
	btn_fwd.pressed.connect(func(): add_instruction("FORWARD"))
	btn_left.pressed.connect(func(): add_instruction("TURN_LEFT"))
	btn_right.pressed.connect(func(): add_instruction("TURN_RIGHT"))
	btn_del.pressed.connect(remove_last_instruction)
	btn_clear.pressed.connect(reiniciar_nivel)
	btn_run.pressed.connect(run_program)
	btn_pause.pressed.connect(_on_pause_pressed)

	# Conexiones: Pantallas Finales
	btn_victory_back.pressed.connect(_on_back_pressed)
	btn_gameover_restart.pressed.connect(func(): start_game(selected_diff))
	btn_gameover_back.pressed.connect(_on_back_pressed)

	# Plantilla Universal de Flujo (Instrucciones -> Dificultad -> Pausa)
	flow_template = create_flow_template({
		"title": "RoboFlow",
		"subtitle": "CU-10: Control de Flujos",
		"classroom_path": "res://scenes/classroom/AulaProgramacion.tscn",
		"objective": "Guía al robot desde su posición inicial hasta la casilla META.",
		"rules": [
			"Usa los botones AVANZAR, GIRAR IZQUIERDA y GIRAR DERECHA para armar tu rutina sin exceder el límite de pasos.",
			"Puedes borrar el último paso o limpiar la rutina antes de ejecutar.",
			"Si el robot choca contra un obstáculo [X], sale del tablero o termina sin llegar a la META, pierdes 1 vida."
		],
		"difficulties": {
			"FACIL": {
				"name": "Fácil",
				"info": "Fácil: 3 vidas, máx. 15 pasos, 245 pts\nTablero 5x5 • Obstáculos básicos"
			},
			"NORMAL": {
				"name": "Normal",
				"info": "Normal: 3 vidas, máx. 25 pasos, 490 pts\nTablero 6x6 • Ruta en 'S'"
			},
			"INGENIERO": {
				"name": "Ingeniero",
				"info": "Ingeniero: 1 vida, máx. 45 pasos, 735 pts\nTablero 7x7 • Ruta serpiente estricta"
			}
		},
		"default_difficulty": "NORMAL",
		"on_start": func(diff: String):
			selected_diff = diff
			start_game(diff),
		"on_back": func():
			_on_back_pressed(),
		"on_resume": func():
			is_game_paused = false,
		"on_restart": func():
			start_game(selected_diff)
	})

func _on_pause_pressed() -> void:
	if is_running:
		return
	is_game_paused = true
	flow_template.show_pause()

func _show_screen(screen: Control) -> void:
	screen_start.visible = false
	screen_game.visible = false
	screen_victory.visible = false
	screen_game_over.visible = false
	screen_pause.visible = false
	if screen == screen_start:
		flow_template.show_instructions()
	else:
		flow_template.hide_all()
	screen.visible = true

func _on_iniciar_pressed() -> void:
	if AudioManager.has_method("play_click"):
		AudioManager.play_click()
	start_game(selected_diff)

func start_game(diff: String = "NORMAL") -> void:
	super.start_game(diff)
	current_difficulty = diff
	selected_diff = diff
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
			start_pos = Vector2i(4, 4)
			goal_pos = Vector2i(0, 0)
			obstacles = [Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(3, 3)]
		"NORMAL":
			grid_cols = 6
			grid_rows = 6
			max_instructions = 25
			max_lives = 3
			current_lives = 3
			start_pos = Vector2i(5, 5)
			goal_pos = Vector2i(0, 0)
			# Ruta en 'S' garantizada sin atajo por esquina superior derecha (5,0)
			obstacles = [
				Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 4),
				Vector2i(3, 3), Vector2i(3, 4), Vector2i(3, 5), Vector2i(4, 1),
				Vector2i(5, 0)
			]
		"INGENIERO":
			grid_cols = 7
			grid_rows = 7
			max_instructions = 45
			max_lives = 1
			current_lives = 1
			start_pos = Vector2i(6, 6)
			goal_pos = Vector2i(0, 0)
			# Ruta serpiente estricta
			obstacles = [
				Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1),
				Vector2i(5, 0), Vector2i(6, 0), Vector2i(6, 1), Vector2i(6, 2), Vector2i(5, 2),
				Vector2i(0, 2), Vector2i(0, 3),
				Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3),
				Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5)
			]

	instructions.clear()
	reset_robot()
	build_board_ui()
	update_pipeline_ui()
	update_lives_display()
	btn_run.disabled = false
	attempts = 0
	is_running = false
	pipeline_title.text = "RUTINA (Máx: %d):" % max_instructions
	
	if EventBus.has_signal("minigame_started"):
		EventBus.minigame_started.emit(minigame_id, current_difficulty)
		
	set_status("Dificultad %s iniciada. Diseña el flujo." % current_difficulty)

func update_lives_display() -> void:
	if is_instance_valid(hud_mode_label):
		hud_mode_label.text = "NIVEL: %s" % current_difficulty
	update_aula101_hearts_bar(hearts_bar, current_lives, max_lives, lives_label, 14.0)

func reset_robot() -> void:
	current_pos = start_pos
	current_dir = "N"

func build_board_ui() -> void:
	for child in board_grid.get_children():
		child.queue_free()

	board_grid.columns = grid_cols
	var cell_size: float = 38.0 if grid_cols <= 5 else (32.0 if grid_cols == 6 else 28.0)

	for y in range(grid_rows):
		for x in range(grid_cols):
			var cell := PanelContainer.new()
			cell.custom_minimum_size = Vector2(cell_size, cell_size)
			
			var cell_style := StyleBoxFlat.new()
			cell_style.bg_color = Color(0.06, 0.10, 0.18, 0.85)
			cell_style.border_color = Color(1.0, 1.0, 1.0, 0.85) # Cuadrícula blanca nítida
			cell_style.set_border_width_all(1)
			cell_style.set_content_margin_all(0)
			cell_style.set_corner_radius_all(3)
			cell.add_theme_stylebox_override("panel", cell_style)

			var center := CenterContainer.new()
			center.set_anchors_preset(Control.PRESET_FULL_RECT)
			cell.add_child(center)

			var icon := TextureRect.new()
			icon.name = "CellIcon"
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(cell_size - 6.0, cell_size - 6.0)
			icon.visible = false
			center.add_child(icon)

			var lbl := Label.new()
			lbl.name = "CellLabel"
			lbl.text = "·"
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.add_theme_font_size_override("font_size", 14)
			lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.45))
			center.add_child(lbl)

			var dir_overlay := Control.new()
			dir_overlay.name = "DirOverlay"
			dir_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			dir_overlay.z_index = 2
			dir_overlay.visible = false
			dir_overlay.set_meta("dir", "N")
			dir_overlay.draw.connect(_draw_dir_overlay.bind(dir_overlay))
			cell.add_child(dir_overlay)

			var pos := Vector2i(x, y)
			cell.set_meta("grid_pos", pos)
			board_grid.add_child(cell)

	update_robot_display()

func _draw_dir_overlay(overlay: Control) -> void:
	var w: float = overlay.size.x
	var h: float = overlay.size.y
	if w <= 2.0 or h <= 2.0:
		return
	var d: String = str(overlay.get_meta("dir", "N"))
	var pts := PackedVector2Array()
	var tip_half: float = 5.0
	var tip_depth: float = 7.0
	match d:
		"N":
			pts = PackedVector2Array([
				Vector2(w * 0.5, 0.5),
				Vector2(w * 0.5 + tip_half, tip_depth),
				Vector2(w * 0.5 - tip_half, tip_depth)
			])
		"S":
			pts = PackedVector2Array([
				Vector2(w * 0.5, h - 0.5),
				Vector2(w * 0.5 + tip_half, h - tip_depth),
				Vector2(w * 0.5 - tip_half, h - tip_depth)
			])
		"E":
			pts = PackedVector2Array([
				Vector2(w - 0.5, h * 0.5),
				Vector2(w - tip_depth, h * 0.5 - tip_half),
				Vector2(w - tip_depth, h * 0.5 + tip_half)
			])
		"O":
			pts = PackedVector2Array([
				Vector2(0.5, h * 0.5),
				Vector2(tip_depth, h * 0.5 - tip_half),
				Vector2(tip_depth, h * 0.5 + tip_half)
			])
		_:
			return
	overlay.draw_colored_polygon(pts, Color(0.15, 0.98, 1.0, 1.0))
	var closed_pts := PackedVector2Array([pts[0], pts[1], pts[2], pts[0]])
	overlay.draw_polyline(closed_pts, Color(0.02, 0.08, 0.14, 0.95), 1.4, true)

func _apply_accessibility_mode(is_active: bool) -> void:
	super._apply_accessibility_mode(is_active)
	update_robot_display()

func update_robot_display() -> void:
	var rot_angles := { "N": 0.0, "E": 90.0, "S": 180.0, "O": 270.0 }
	var cell_size: float = 38.0 if grid_cols <= 5 else (32.0 if grid_cols == 6 else 28.0)
	var icon_size: Vector2 = Vector2(cell_size - 6.0, cell_size - 6.0)
	var pivot: Vector2 = icon_size * 0.5
	var ahead_pos: Vector2i = current_pos + DIR_DELTAS.get(current_dir, Vector2i.ZERO)

	if is_instance_valid(dir_chip):
		dir_chip.text = DIR_LABELS.get(current_dir, "🧭 Vista: ▲ Arriba")

	for cell in board_grid.get_children():
		var pos: Vector2i = cell.get_meta("grid_pos", Vector2i(-1, -1))
		var icon: TextureRect = cell.find_child("CellIcon", true, false)
		var lbl: Label = cell.find_child("CellLabel", true, false)
		var dir_overlay: Control = cell.find_child("DirOverlay", true, false)
		var cell_style: StyleBoxFlat = cell.get_theme_stylebox("panel") as StyleBoxFlat
		if not icon or not lbl:
			continue

		var is_ahead: bool = (pos == ahead_pos)
		if cell_style:
			if pos == current_pos:
				cell_style.bg_color = Color(0.06, 0.16, 0.28, 0.92)
				cell_style.border_color = Color(0.0, 0.95, 1.0, 1.0)
				cell_style.set_border_width_all(2)
			elif is_ahead and pos in obstacles:
				cell_style.bg_color = Color(0.32, 0.08, 0.10, 0.92)
				cell_style.border_color = Color(1.0, 0.35, 0.30, 1.0)
				cell_style.set_border_width_all(2)
			elif is_ahead:
				cell_style.bg_color = Color(0.06, 0.24, 0.32, 0.90)
				cell_style.border_color = Color(0.25, 0.95, 1.0, 1.0)
				cell_style.set_border_width_all(2)
			else:
				cell_style.bg_color = Color(0.06, 0.10, 0.18, 0.85)
				cell_style.border_color = Color(1.0, 1.0, 1.0, 0.85)
				cell_style.set_border_width_all(1)

		if pos == current_pos:
			icon.visible = true
			icon.texture = TEX_ROBOT
			icon.custom_minimum_size = icon_size
			icon.pivot_offset = pivot
			icon.rotation_degrees = rot_angles.get(current_dir, 0.0)
			lbl.visible = false
			cell.modulate = Color.WHITE
			if dir_overlay:
				dir_overlay.set_meta("dir", current_dir)
				dir_overlay.visible = true
				dir_overlay.queue_redraw()
		elif pos in obstacles:
			icon.visible = true
			icon.texture = TEX_OBSTACLE
			icon.custom_minimum_size = icon_size
			icon.pivot_offset = Vector2.ZERO
			icon.rotation_degrees = 0.0
			lbl.visible = false
			cell.modulate = Color.WHITE
			if dir_overlay:
				dir_overlay.visible = false
		elif pos == goal_pos:
			icon.visible = true
			icon.texture = TEX_FLAG
			icon.custom_minimum_size = icon_size
			icon.pivot_offset = Vector2.ZERO
			icon.rotation_degrees = 0.0
			lbl.visible = false
			cell.modulate = Color.WHITE
			if dir_overlay:
				dir_overlay.visible = false
		else:
			icon.visible = false
			lbl.visible = true
			lbl.text = "·"
			lbl.add_theme_color_override("font_color", Color(0.55, 0.98, 1.0, 0.95) if is_ahead else Color(1.0, 1.0, 1.0, 0.45))
			cell.modulate = Color.WHITE if is_ahead else Color(1, 1, 1, 0.85)
			if dir_overlay:
				dir_overlay.visible = false

func add_instruction(cmd: String) -> void:
	if is_running or current_lives <= 0:
		return
	if instructions.size() >= max_instructions:
		if AudioManager.has_method("play_error"):
			AudioManager.play_error()
		set_status("Límite de %d instrucciones." % max_instructions)
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
	is_running = false
	is_game_paused = false
	if AudioManager.has_method("play_click"):
		AudioManager.play_click()
	instructions.clear()
	current_lives = max_lives
	reset_robot()
	update_robot_display()
	update_pipeline_ui()
	update_lives_display()
	btn_run.disabled = false
	set_status("Nivel reiniciado. Vidas: %d." % max_lives)

func update_pipeline_ui() -> void:
	for child in pipeline_container.get_children():
		child.queue_free()

	var labels := { "FORWARD": "AVAN", "TURN_LEFT": "IZQ", "TURN_RIGHT": "DER" }
	
	for i in range(instructions.size()):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(40, 40)
		var lbl := Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.text = "%d\n%s" % [i + 1, labels.get(instructions[i], "")]
		slot.modulate = Color(0.3, 0.9, 1.0)
		slot.add_child(lbl)
		pipeline_container.add_child(slot)
		
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
		set_status("FALLO: %s (-1 vida)." % reason)
		reset_robot()
		update_robot_display()

func handle_game_over(reason: String) -> void:
	is_running = false
	if AudioManager.has_method("play_game_over"):
		AudioManager.play_game_over()
		
	if EventBus.has_signal("game_over"):
		EventBus.game_over.emit(minigame_id)
		
	finish_game(false, 0, 0, reason)
	if flow_template:
		flow_template.show_game_over(reason, 0)
	else:
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
		set_status("El flujo está vacío.")
		return

	is_running = true
	attempts += 1
	reset_robot()
	update_robot_display()
	set_status("Compilando y ejecutando...")

	var dirs := ["N", "E", "S", "O"]
	var deltas := {
		"N": Vector2i(0, -1),
		"E": Vector2i(1, 0),
		"S": Vector2i(0, 1),
		"O": Vector2i(-1, 0)
	}

	for i in range(instructions.size()):
		while is_game_paused:
			if not is_inside_tree() or not is_running:
				return
			await get_tree().process_frame

		if not is_running:
			return

		var cmd: String = instructions[i]
		if cmd == "FORWARD":
			var delta: Vector2i = deltas.get(current_dir, Vector2i.ZERO)
			var next_pos: Vector2i = current_pos + delta

			if next_pos.x < 0 or next_pos.x >= grid_cols or next_pos.y < 0 or next_pos.y >= grid_rows:
				is_running = false
				deduct_life("Fuera del tablero")
				return

			if next_pos in obstacles:
				is_running = false
				deduct_life("Choque en obstáculo")
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

		var elapsed: float = 0.0
		while elapsed < 0.40:
			if not is_inside_tree() or not is_running:
				return
			if not is_game_paused:
				elapsed += get_process_delta_time()
			await get_tree().process_frame

		while is_game_paused:
			if not is_inside_tree() or not is_running:
				return
			await get_tree().process_frame

		if not is_running:
			return

		if current_pos == goal_pos:
			handle_victory()
			return

	is_running = false
	if current_pos != goal_pos:
		deduct_life("Fin sin alcanzar la meta")

func handle_victory() -> void:
	is_running = false
	if AudioManager.has_method("play_success"):
		AudioManager.play_success()

	# Puntuación y estrellas exactas según dificultad (RF-31 / CU-10 FN-06)
	var stars: int = 1
	var final_score: int = 245
	match current_difficulty:
		"FACIL":
			stars = 1
			final_score = 245
		"NORMAL":
			stars = 2
			final_score = 490
		"INGENIERO":
			stars = 3
			final_score = 735
	var steps_taken: int = instructions.size()
	
	var prev_high: int = StateManager.get_minigame_high_score(minigame_id) if StateManager else 0
	var is_record: bool = final_score > prev_high
	finish_game(true, final_score, stars, "Flujo completado exitosamente")
	if flow_template:
		var total_accum: int = StateManager.get_points() if StateManager else final_score
		flow_template.show_victory(final_score, stars, total_accum, is_record, "¡ROBOT EN LA META!")
	else:
		lbl_victory_stats.text = "Pasos Tomados: %d\nPuntos: %d\nEstrellas: %d\nVidas Restantes: %d" % [steps_taken, final_score, stars, current_lives]
		_show_screen(screen_victory)

func set_status(msg: String) -> void:
	if status_label:
		status_label.text = msg

func _on_back_pressed() -> void:
	is_running = false
	is_game_paused = false
	if AudioManager.has_method("play_click"):
		AudioManager.play_click()
	if ResourceLoader.exists("res://scenes/classroom/AulaProgramacion.tscn"):
		get_tree().change_scene_to_file("res://scenes/classroom/AulaProgramacion.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/campus/Lobby.tscn")
