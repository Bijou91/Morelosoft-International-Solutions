## DataDrop.gd - CU-11: Practicar el clasificar tipos de Datos y Variables
## Morelosoft International Solutions - Materia: Introducción a la Programación (Aula 101)
## Trazabilidad estricta con TSP_Morelosoft_EspecificacionCUs_v2.docx
## Responsable: Carlos Manuel Aguirre Norato (Líder Técnico)
extends MiniGameBase

const DataDropQuestions = preload("res://scenes/minigames/programacion/datadrop/DataDropQuestions.gd")

# Paleta viva retro para cables de conexionado
const CABLE_COLORS: Array[Color] = [
	Color("ff3366"), # Rosa neón
	Color("00e5ff"), # Cian brillante
	Color("ffea00"), # Amarillo eléctrico
	Color("76ff03"), # Verde lima
	Color("d500f9"), # Púrpura eléctrico
	Color("ff6d00"), # Naranja brillante
	Color("00e676"), # Verde esmeralda
	Color("304ffe")  # Azul índigo
]

func _get_cable_color(index: int) -> Color:
	if StateManager.is_high_contrast_active():
		return StateManager.COLORBLIND_PALETTE[index % StateManager.COLORBLIND_PALETTE.size()]
	return CABLE_COLORS[index % CABLE_COLORS.size()]

func _update_accessibility_styles() -> void:
	var is_accessible: bool = StateManager.is_high_contrast_active()
	for i in range(left_buttons.size()):
		var btn: Button = left_buttons[i]
		if is_instance_valid(btn):
			_apply_button_contrast(btn, is_accessible)
	for type_key in right_buttons:
		var btn: Button = right_buttons[type_key]
		if is_instance_valid(btn):
			_apply_button_contrast(btn, is_accessible)
	cable_canvas.queue_redraw()

func _apply_button_contrast(btn: Button, is_accessible: bool) -> void:
	if is_accessible:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.10, 0.12, 0.18, 1.0)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(1.0, 0.90, 0.20, 0.95) # Resaltado dorado / blanco
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_left = 5
		style.corner_radius_bottom_right = 5
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.6, 1.0))
	else:
		if btn.has_meta("left_idx"):
			_apply_left_port_style(int(btn.get_meta("left_idx")), btn)
		elif btn.has_meta("port_type"):
			_apply_right_port_style(str(btn.get_meta("port_type")), btn)

# Estado de partida
const TYPE_COLORS := {
	"int": Color(0.12, 0.53, 0.90, 0.88),       # Azul neón
	"float": Color(0.68, 0.26, 0.86, 0.88),     # Púrpura brillante
	"string": Color(0.18, 0.76, 0.42, 0.88),    # Verde esmeralda
	"bool": Color(0.96, 0.74, 0.12, 0.88),      # Amarillo dorado
	"char": Color(0.98, 0.48, 0.15, 0.88),      # Naranja fuego
	"list": Color(0.32, 0.42, 0.92, 0.88)       # Índigo cyber
}

# Estilos Kenney UI Pack (Classic UI)
const STYLE_BTN_NEUTRAL_NORM = preload("res://scenes/ui/theme/classic/btn_neutral_normal.tres")
const STYLE_BTN_NEUTRAL_HOV = preload("res://scenes/ui/theme/classic/btn_neutral_hover.tres")
const STYLE_BTN_NEUTRAL_PRESS = preload("res://scenes/ui/theme/classic/btn_neutral_pressed.tres")

const STYLE_BTN_BLUE_NORM = preload("res://scenes/ui/theme/classic/btn_blue_normal.tres")
const STYLE_BTN_BLUE_HOV = preload("res://scenes/ui/theme/classic/btn_blue_hover.tres")
const STYLE_BTN_BLUE_PRESS = preload("res://scenes/ui/theme/classic/btn_blue_pressed.tres")

const STYLE_BTN_YELLOW_NORM = preload("res://scenes/ui/theme/classic/btn_yellow_normal.tres")
const STYLE_BTN_YELLOW_HOV = preload("res://scenes/ui/theme/classic/btn_yellow_hover.tres")
const STYLE_BTN_YELLOW_PRESS = preload("res://scenes/ui/theme/classic/btn_yellow_pressed.tres")

const STYLE_BTN_GREEN_NORM = preload("res://scenes/ui/theme/classic/btn_green_normal.tres")
const STYLE_BTN_GREEN_HOV = preload("res://scenes/ui/theme/classic/btn_green_hover.tres")
const STYLE_BTN_GREEN_PRESS = preload("res://scenes/ui/theme/classic/btn_green_pressed.tres")

const STYLE_BTN_RED_NORM = preload("res://scenes/ui/theme/classic/btn_red_normal.tres")
const STYLE_BTN_RED_HOV = preload("res://scenes/ui/theme/classic/btn_red_hover.tres")
const STYLE_BTN_RED_PRESS = preload("res://scenes/ui/theme/classic/btn_red_pressed.tres")

const STYLE_PANEL_GLASS = preload("res://scenes/ui/theme/classic/panel_glass.tres")
const STYLE_PANEL_INNER = preload("res://scenes/ui/theme/classic/panel_inner_plate.tres")
const TEX_PANEL_GLASS_SCREWS = preload("res://assets/interfazUI/kenney_ui-pack-space-expansion/PNG/Extra/Double/panel_glass_screws.png")

var round_pairs: Array[Dictionary] = [] # [{literal, type, desc}]
var completed_connections: Array[Dictionary] = [] # [{left_index, target_type, color, from_node, to_node}]
var selected_source_index: int = -1
var is_dragging: bool = false
var drag_current_pos: Vector2 = Vector2.ZERO
var left_buttons: Array[Button] = []
var right_buttons: Dictionary = {} # String (tipo) -> Button

var max_lives: int = 3
var current_lives: int = 3
var total_score: int = 0
var base_score: int = 520
var time_limit: float = 30.0
var time_remaining: float = 30.0
var is_timer_active: bool = false
var is_game_paused: bool = false
var selected_diff: String = "NORMAL"

# Efecto de chispa / error visual
var error_flash_timer: float = 0.0
var error_spark_from: Vector2 = Vector2.ZERO
var error_spark_to: Vector2 = Vector2.ZERO

# Referencias de pantallas
@onready var screen_start: Control = $ScreenStart
@onready var screen_game: Control = $ScreenGame
@onready var screen_pause: Control = $ScreenPause
@onready var screen_victory: Control = $ScreenVictory
@onready var screen_game_over: Control = $ScreenGameOver

# Referencias HUD
@onready var btn_pause: Button = $ScreenGame/VBox/TopHUD/BtnPause
@onready var pairs_counter_label: Label = $ScreenGame/VBox/TopHUD/PairsCounter
@onready var time_bar: ProgressBar = $ScreenGame/VBox/TopHUD/TimeBar
@onready var time_label: Label = $ScreenGame/VBox/TopHUD/TimeLabel
@onready var hearts_label: Label = $ScreenGame/VBox/TopHUD/HeartsLabel
var hearts_bar: HBoxContainer

# Referencias del Tablero
@onready var board_panel: Panel = $ScreenGame/VBox/BoardSection/BoardPanel
@onready var left_scroll: ScrollContainer = $ScreenGame/VBox/BoardSection/BoardPanel/HBox/LeftScroll
@onready var left_container: VBoxContainer = $ScreenGame/VBox/BoardSection/BoardPanel/HBox/LeftScroll/LeftColumn
@onready var right_container: VBoxContainer = $ScreenGame/VBox/BoardSection/BoardPanel/HBox/RightColumn
@onready var cable_canvas: Control = $ScreenGame/VBox/BoardSection/BoardPanel/CableCanvas
@onready var status_banner_label: Label = $ScreenGame/VBox/StatusBanner/Label

# Referencias Pantalla de Inicio
@onready var btn_diff_facil: Button = $ScreenStart/VBox/DiffSelector/BtnFacil
@onready var btn_diff_normal: Button = $ScreenStart/VBox/DiffSelector/BtnNormal
@onready var btn_diff_ing: Button = $ScreenStart/VBox/DiffSelector/BtnIngeniero
@onready var btn_start_play: Button = $ScreenStart/VBox/BtnStartPlay
@onready var btn_start_back: Button = $ScreenStart/VBox/BtnStartBack
@onready var lbl_diff_info: Label = $ScreenStart/VBox/DiffInfoLabel
@onready var lbl_desc: Label = $ScreenStart/VBox/Desc
@onready var lbl_diff_label: Label = $ScreenStart/VBox/DiffLabel
@onready var diff_selector: HBoxContainer = $ScreenStart/VBox/DiffSelector

var flow_template: Control

# Referencias Pantallas Finales y Pausa
@onready var btn_pause_resume: Button = $ScreenPause/VBox/BtnResume
@onready var btn_pause_restart: Button = $ScreenPause/VBox/BtnRestart
@onready var btn_pause_exit: Button = $ScreenPause/VBox/BtnExit

@onready var lbl_victory_stats: Label = $ScreenVictory/VBox/StatsLabel
@onready var btn_victory_retry: Button = $ScreenVictory/VBox/BtnRetry
@onready var btn_victory_exit: Button = $ScreenVictory/VBox/BtnExit

@onready var lbl_gameover_reason: Label = $ScreenGameOver/VBox/ReasonLabel
@onready var btn_gameover_retry: Button = $ScreenGameOver/VBox/BtnRetry
@onready var btn_gameover_exit: Button = $ScreenGameOver/VBox/BtnExit

func _ready() -> void:
	super._ready()
	minigame_id = "datadrop"
	cu_id = "CU-11"
	minigame_title = "DataDrop"
	subject_name = "Introducción a la Programación"

	screen_start.visible = false
	screen_pause.visible = false

	# Fondo didáctico de hoja de libreta con 80% opacidad / 20% transparencia
	$Background.visible = false
	attach_notebook_background(self, 0.80)

	# Estandarización del TopHUD del Aula 101 (tarjeta Kenney, botón "||", barra y corazones pixel-art)
	var top_hud := $ScreenGame/VBox/TopHUD as HBoxContainer
	style_aula101_pause_button(btn_pause)
	time_bar.custom_minimum_size = Vector2(32.0, 12.0)
	time_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	style_kenney_progress_bar(time_bar, Color(0.1, 0.9, 1.0, 1.0))
	if is_instance_valid(top_hud):
		hearts_bar = create_aula101_hearts_bar(current_lives, max_lives, 14.0)
		top_hud.add_child(hearts_bar)
		wrap_hbox_in_aula101_hud_panel(top_hud)
	if is_instance_valid(board_panel):
		var sb_board := StyleBoxTexture.new()
		sb_board.texture = TEX_PANEL_GLASS_SCREWS
		sb_board.texture_margin_left = 20.0
		sb_board.texture_margin_top = 20.0
		sb_board.texture_margin_right = 20.0
		sb_board.texture_margin_bottom = 20.0
		sb_board.modulate_color = Color(0.16, 0.24, 0.36, 0.78)
		board_panel.add_theme_stylebox_override("panel", sb_board)
	var status_banner := $ScreenGame/VBox/StatusBanner as PanelContainer
	if is_instance_valid(status_banner):
		var sb_banner := STYLE_PANEL_INNER.duplicate() as StyleBoxTexture
		if sb_banner:
			sb_banner.modulate_color = Color(0.16, 0.22, 0.32, 0.88)
			status_banner.add_theme_stylebox_override("panel", sb_banner)
	lock_dynamic_label_box(status_banner_label, status_banner, 50.0, 12, 7, 2.0, 0.0, true, true, 6.0)
	pairs_counter_label.add_theme_font_size_override("font_size", 10)
	pairs_counter_label.add_theme_color_override("font_color", Color("ffd54f"))
	time_label.add_theme_font_size_override("font_size", 10)
	stabilize_hud_label(pairs_counter_label, 62.0)
	stabilize_hud_label(time_label, 28.0)
	update_aula101_hearts_bar(hearts_bar, current_lives, max_lives, hearts_label, 14.0)

	_connect_ui_signals()
	cable_canvas.clip_contents = true
	cable_canvas.draw.connect(_on_cable_canvas_draw)
	if is_instance_valid(left_scroll) and is_instance_valid(left_scroll.get_v_scroll_bar()):
		left_scroll.get_v_scroll_bar().value_changed.connect(func(_val): cable_canvas.queue_redraw())

	# Plantilla Universal de Flujo (Instrucciones -> Dificultad -> Pausa)
	flow_template = create_flow_template({
		"title": "DataDrop",
		"subtitle": "CU-11: Clasificación de Tipos y Variables",
		"classroom_path": "res://scenes/classroom/AulaProgramacion.tscn",
		"objective": "Clasifica los valores sueltos conectándolos con su tipo de variable.",
		"rules": [
			"Toca o arrastra un valor de la columna izquierda hacia uno de los 6 tipos de datos a la derecha (int, float, string, bool, char, list).",
			"Si aciertas, el cable queda fijo y el emisor se inhabilita.",
			"Si conectas un tipo incorrecto, ocurrirá un cortocircuito y perderás 1 vida.",
			"Si sueltas el cable en el centro vacío, se retrae sin penalización."
		],
		"difficulties": {
			"FACIL": {
				"name": "Fácil",
				"info": "Modo: Fácil\n• Pares a conectar: 4\n• Vidas: 5  • Tiempo: 60s  • Puntos: 300"
			},
			"NORMAL": {
				"name": "Normal",
				"info": "Modo: Normal\n• Pares a conectar: 6\n• Vidas: 3  • Tiempo: 30s  • Puntos: 520"
			},
			"INGENIERO": {
				"name": "Ingeniero",
				"info": "Modo: Ingeniero\n• Pares a conectar: 8\n• Vidas: 1  • Tiempo: 15s  • Puntos: 765"
			}
		},
		"default_difficulty": "NORMAL",
		"on_start": func(diff: String):
			selected_diff = diff
			_on_btn_start_pressed(),
		"on_back": func():
			_on_back_to_classroom(),
		"on_resume": func():
			_on_resume_pressed(),
		"on_restart": func():
			_on_restart_pressed()
	})

func _connect_ui_signals() -> void:
	btn_pause.pressed.connect(_on_pause_pressed)
	btn_pause_resume.pressed.connect(_on_resume_pressed)
	btn_pause_restart.pressed.connect(_on_restart_pressed)
	btn_pause_exit.pressed.connect(_on_back_to_classroom)

	btn_victory_retry.pressed.connect(_on_restart_pressed)
	btn_victory_exit.pressed.connect(_on_back_to_classroom)
	btn_gameover_retry.pressed.connect(_on_restart_pressed)
	btn_gameover_exit.pressed.connect(_on_back_to_classroom)

func _show_screen(active_screen: Control) -> void:
	screen_start.visible = false
	screen_game.visible = false
	screen_pause.visible = false
	screen_victory.visible = false
	screen_game_over.visible = false
	if active_screen == screen_start:
		flow_template.show_instructions()
	else:
		flow_template.hide_all()
	active_screen.visible = true

func _on_pause_pressed() -> void:
	if not is_timer_active:
		return
	AudioManager.play_click()
	is_game_paused = true
	flow_template.show_pause()

func _apply_accessibility_mode(is_active: bool) -> void:
	super._apply_accessibility_mode(is_active)
	_update_accessibility_styles()

func _process(delta: float) -> void:
	if is_timer_active and not is_game_paused:
		time_remaining -= delta
		if time_remaining <= 0.0:
			time_remaining = 0.0
			is_timer_active = false
			_on_time_expired()
		_update_timer_hud()

	if error_flash_timer > 0.0:
		error_flash_timer -= delta
		cable_canvas.queue_redraw()

	if is_dragging or selected_source_index >= 0:
		cable_canvas.queue_redraw()

func _input(event: InputEvent) -> void:
	if not is_timer_active or is_game_paused:
		return

	if event is InputEventMouseMotion:
		if is_dragging or selected_source_index >= 0:
			drag_current_pos = _to_canvas_local(event.global_position)
			cable_canvas.queue_redraw()

	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			if is_dragging and selected_source_index >= 0:
				_handle_drop_release(mb.global_position)

	elif event is InputEventScreenDrag:
		if is_dragging or selected_source_index >= 0:
			drag_current_pos = _to_canvas_local(event.position)
			cable_canvas.queue_redraw()

	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event
		if not st.pressed:
			if is_dragging and selected_source_index >= 0:
				_handle_drop_release(st.position)

func _to_canvas_local(global_pos: Vector2) -> Vector2:
	return cable_canvas.get_global_transform().affine_inverse() * global_pos

## Precondiciones de CU-11:
## Fácil: 5 vidas, 60s, 300 pts.
## Normal: 3 vidas, 30s, 520 pts.
## Ingeniero: 1 vida, 15s, 765 pts.
func _select_difficulty(diff: String) -> void:
	selected_diff = diff
	AudioManager.play_click()

	btn_diff_facil.modulate = Color.WHITE if diff == "FACIL" else Color(0.6, 0.6, 0.6)
	btn_diff_normal.modulate = Color.WHITE if diff == "NORMAL" else Color(0.6, 0.6, 0.6)
	btn_diff_ing.modulate = Color.WHITE if diff == "INGENIERO" else Color(0.6, 0.6, 0.6)

	var conf := DataDropQuestions.get_difficulty_config(diff)
	lbl_diff_info.text = "Modo: %s\n• Pares a conectar: %d\n• Vidas: %d  • Tiempo: %ds  • Puntos: %d" % [
		conf.name, conf.pairs_count, conf.max_lives, int(conf.time_limit), conf.base_score
	]

func _on_btn_start_pressed() -> void:
	AudioManager.play_click()
	start_game(selected_diff)

## FN-01: Inicialización del panel de conexionado
func start_game(difficulty: String = "NORMAL") -> void:
	super.start_game(difficulty)
	selected_diff = difficulty
	var conf := DataDropQuestions.get_difficulty_config(difficulty)

	max_lives = conf.max_lives
	current_lives = max_lives
	total_score = 0
	time_limit = conf.time_limit
	time_remaining = time_limit
	base_score = conf.base_score
	is_timer_active = true
	is_game_paused = false
	selected_source_index = -1
	is_dragging = false
	drag_current_pos = Vector2.ZERO
	completed_connections.clear()
	error_flash_timer = 0.0

	round_pairs = DataDropQuestions.generate_round_pairs(difficulty)

	_build_board_ui()
	_update_hud()
	_show_screen(screen_game)

	status_banner_label.text = "Toca o arrastra un valor (izquierda) hacia su tipo de variable (derecha)."
	status_banner_label.modulate = Color("00e5ff")

	EventBus.minigame_started.emit(cu_id, difficulty)

func _build_board_ui() -> void:
	for child in left_container.get_children():
		left_container.remove_child(child)
		child.queue_free()
	for child in right_container.get_children():
		right_container.remove_child(child)
		child.queue_free()

	left_buttons.clear()
	right_buttons.clear()

	# Columna izquierda: Valores literales ("Dato") con assets Kenney UI
	for i in range(round_pairs.size()):
		var item: Dictionary = round_pairs[i]
		var btn := Button.new()
		btn.text = "%s  ●" % item.literal
		btn.name = "LeftPort_%d" % i
		btn.custom_minimum_size = Vector2(104, 38)
		btn.add_theme_font_size_override("font_size", 11)
		btn.focus_mode = Control.FOCUS_NONE
		btn.alignment = HORIZONTAL_ALIGNMENT_RIGHT
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.set_meta("kenney_custom_managed", true)
		btn.set_meta("left_idx", i)

		# Botón con relieve táctil Kenney oficial
		_apply_left_port_style(i, btn)

		var idx: int = i
		btn.button_down.connect(func(): _on_left_port_down(idx))
		btn.pressed.connect(func(): _on_left_port_clicked(idx))
		left_container.add_child(btn)
		left_buttons.append(btn)

	# Columna derecha: 6 Tipos de variable en recuadros Kenney estilizados
	for type_info in DataDropQuestions.ALL_TYPES:
		var btn := Button.new()
		btn.text = "●  %s" % type_info.label.replace("\n", " ")
		btn.name = "RightPort_%s" % type_info.type
		btn.custom_minimum_size = Vector2(115, 40)
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 10)
		btn.focus_mode = Control.FOCUS_NONE
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.set_meta("kenney_custom_managed", true)
		btn.set_meta("port_type", type_info.type)

		_apply_right_port_style(type_info.type, btn)

		var t_name: String = type_info.type
		btn.pressed.connect(func(): _on_right_port_clicked(t_name))
		right_container.add_child(btn)
		right_buttons[type_info.type] = btn

	left_scroll.scroll_vertical = 0
	_update_accessibility_styles()

func _apply_left_port_style(idx: int, btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	if _is_left_completed(idx):
		btn.add_theme_stylebox_override("disabled", STYLE_BTN_GREEN_NORM)
		btn.add_theme_stylebox_override("normal", STYLE_BTN_GREEN_NORM)
		btn.add_theme_stylebox_override("hover", STYLE_BTN_GREEN_HOV)
		btn.add_theme_stylebox_override("pressed", STYLE_BTN_GREEN_PRESS)
		btn.add_theme_color_override("font_color", Color(0.04, 0.22, 0.08, 0.90))
		btn.add_theme_color_override("font_disabled_color", Color(0.04, 0.22, 0.08, 0.90))
	elif idx == selected_source_index:
		btn.add_theme_stylebox_override("normal", STYLE_BTN_YELLOW_NORM)
		btn.add_theme_stylebox_override("hover", STYLE_BTN_YELLOW_HOV)
		btn.add_theme_stylebox_override("pressed", STYLE_BTN_YELLOW_PRESS)
		btn.add_theme_color_override("font_color", Color(0.24, 0.18, 0.02, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(0.18, 0.12, 0.01, 1.0))
	else:
		btn.add_theme_stylebox_override("normal", STYLE_BTN_NEUTRAL_NORM)
		btn.add_theme_stylebox_override("hover", STYLE_BTN_NEUTRAL_HOV)
		btn.add_theme_stylebox_override("pressed", STYLE_BTN_NEUTRAL_PRESS)
		btn.add_theme_color_override("font_color", Color(0.15, 0.18, 0.25, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(0.05, 0.08, 0.15, 1.0))

func _apply_right_port_style(type_key: String, btn: Button) -> void:
	if not is_instance_valid(btn):
		return
	match type_key:
		"int":
			btn.add_theme_stylebox_override("normal", STYLE_BTN_BLUE_NORM)
			btn.add_theme_stylebox_override("hover", STYLE_BTN_BLUE_HOV)
			btn.add_theme_stylebox_override("pressed", STYLE_BTN_BLUE_PRESS)
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.add_theme_color_override("font_hover_color", Color.WHITE)
		"float":
			btn.add_theme_stylebox_override("normal", STYLE_BTN_BLUE_NORM)
			btn.add_theme_stylebox_override("hover", STYLE_BTN_BLUE_HOV)
			btn.add_theme_stylebox_override("pressed", STYLE_BTN_BLUE_PRESS)
			btn.add_theme_color_override("font_color", Color(0.82, 0.96, 1.0))
			btn.add_theme_color_override("font_hover_color", Color.WHITE)
		"string":
			btn.add_theme_stylebox_override("normal", STYLE_BTN_GREEN_NORM)
			btn.add_theme_stylebox_override("hover", STYLE_BTN_GREEN_HOV)
			btn.add_theme_stylebox_override("pressed", STYLE_BTN_GREEN_PRESS)
			btn.add_theme_color_override("font_color", Color(0.04, 0.22, 0.08, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(0.02, 0.14, 0.04, 1.0))
		"bool":
			btn.add_theme_stylebox_override("normal", STYLE_BTN_YELLOW_NORM)
			btn.add_theme_stylebox_override("hover", STYLE_BTN_YELLOW_HOV)
			btn.add_theme_stylebox_override("pressed", STYLE_BTN_YELLOW_PRESS)
			btn.add_theme_color_override("font_color", Color(0.24, 0.18, 0.02, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(0.18, 0.12, 0.01, 1.0))
		"char":
			btn.add_theme_stylebox_override("normal", STYLE_BTN_RED_NORM)
			btn.add_theme_stylebox_override("hover", STYLE_BTN_RED_HOV)
			btn.add_theme_stylebox_override("pressed", STYLE_BTN_RED_PRESS)
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.add_theme_color_override("font_hover_color", Color.WHITE)
		"list", _:
			btn.add_theme_stylebox_override("normal", STYLE_BTN_NEUTRAL_NORM)
			btn.add_theme_stylebox_override("hover", STYLE_BTN_NEUTRAL_HOV)
			btn.add_theme_stylebox_override("pressed", STYLE_BTN_NEUTRAL_PRESS)
			btn.add_theme_color_override("font_color", Color(0.22, 0.10, 0.36, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(0.14, 0.06, 0.24, 1.0))

func _on_left_port_down(index: int) -> void:
	if is_game_paused or not is_timer_active or _is_left_completed(index):
		return
	selected_source_index = index
	is_dragging = true
	drag_current_pos = _get_left_port_pos(index)
	_highlight_left_buttons()
	cable_canvas.queue_redraw()

func _on_left_port_clicked(index: int) -> void:
	if is_game_paused or not is_timer_active or _is_left_completed(index):
		return
	selected_source_index = index
	AudioManager.play_click()
	var item: Dictionary = round_pairs[index]
	status_banner_label.text = "Dato seleccionado: %s. Ahora toca su tipo de variable a la derecha." % item.literal
	status_banner_label.modulate = Color("ffea00")
	drag_current_pos = _get_left_port_pos(index)
	_highlight_left_buttons()
	cable_canvas.queue_redraw()

func _handle_drop_release(global_drop_pos: Vector2) -> void:
	is_dragging = false
	if selected_source_index < 0:
		return

	# Comprobar si se soltó sobre algún botón receptor
	for t_name in right_buttons:
		var btn: Button = right_buttons[t_name]
		if is_instance_valid(btn) and btn.get_global_rect().has_point(global_drop_pos):
			_verify_connection(selected_source_index, t_name)
			selected_source_index = -1
			_highlight_left_buttons()
			cable_canvas.queue_redraw()
			return

	# Si se soltó sobre el mismo botón izquierdo de origen, mantenerlo seleccionado para modo clic
	if selected_source_index >= 0 and selected_source_index < left_buttons.size():
		var left_btn: Button = left_buttons[selected_source_index]
		if is_instance_valid(left_btn) and left_btn.get_global_rect().has_point(global_drop_pos):
			# No cancelar: se mantiene seleccionado
			cable_canvas.queue_redraw()
			return

	# FA-02.02: Si se soltó en la zona intermedia entre contenedores, se retrae sin penalización
	AudioManager.play_click()
	status_banner_label.text = "Cable retraído al borne emisor (FA-02.02)."
	status_banner_label.modulate = Color.WHITE
	selected_source_index = -1
	_highlight_left_buttons()
	cable_canvas.queue_redraw()

func _on_right_port_clicked(target_type: String) -> void:
	if is_game_paused or not is_timer_active:
		return

	if selected_source_index >= 0:
		_verify_connection(selected_source_index, target_type)
		selected_source_index = -1
		is_dragging = false
		_highlight_left_buttons()
		cable_canvas.queue_redraw()
	else:
		status_banner_label.text = "Primero selecciona un dato de la columna izquierda."
		status_banner_label.modulate = Color("ffea00")

## FN-03: Verifica correspondencia lógica entre valor y tipo
func _verify_connection(left_index: int, target_type: String) -> void:
	if left_index < 0 or left_index >= round_pairs.size() or left_index >= left_buttons.size():
		return
	if not right_buttons.has(target_type):
		return

	var item: Dictionary = round_pairs[left_index]
	var is_correct: bool = (item.type == target_type)

	var left_btn: Button = left_buttons[left_index]
	var right_btn: Button = right_buttons[target_type]

	if not is_instance_valid(left_btn) or not is_instance_valid(right_btn):
		return

	if is_correct:
		# FN-04: Conexión Correcta (Fija cable, sonido de éxito, actualiza puntos en pantalla)
		AudioManager.play_success()
		var cable_color: Color = _get_cable_color(completed_connections.size())

		completed_connections.append({
			"left_index": left_index,
			"target_type": target_type,
			"color": cable_color,
			"from_node": left_btn,
			"to_node": right_btn
		})

		left_btn.disabled = true
		left_btn.add_theme_stylebox_override("disabled", STYLE_BTN_GREEN_NORM)
		left_btn.add_theme_color_override("font_disabled_color", Color(0.04, 0.22, 0.08, 0.85))
		left_btn.modulate = Color(0.9, 1.0, 0.9, 0.9)

		# Suma de puntaje según dificultad (acumulado únicamente en total_score)
		var pair_score: int = int(float(base_score) / float(round_pairs.size()))
		if completed_connections.size() >= round_pairs.size():
			pair_score = base_score - total_score
		total_score += pair_score

		status_banner_label.text = "✓ ¡Correcto! %s corresponde a %s (+%d pts)" % [item.literal, target_type, pair_score]
		status_banner_label.modulate = Color("76ff03")

		_update_hud()
		cable_canvas.queue_redraw()

		# FN-05 / FN-06: Si se asociaron todos los pares requeridos
		if completed_connections.size() >= round_pairs.size():
			_on_all_pairs_connected()

	else:
		# FA-02.01: Enlace erróneo de cable (Resta una vida, alerta auditiva, chispa visual)
		AudioManager.play_error()
		current_lives -= 1
		EventBus.life_lost.emit(current_lives)

		# Registrar chispa de error
		error_flash_timer = 0.4
		error_spark_from = _to_canvas_local(left_btn.global_position + Vector2(left_btn.size.x, left_btn.size.y * 0.5))
		error_spark_to = _to_canvas_local(right_btn.global_position + Vector2(0, right_btn.size.y * 0.5))

		status_banner_label.text = "✗ ¡Error! %s NO es %s (-1 vida)" % [item.literal, target_type]
		status_banner_label.modulate = Color("ff3366")

		_update_hud()
		cable_canvas.queue_redraw()

		# FA-04.02: Si derivado de FA-02.01 el total de vidas disminuye a cero -> Fin del caso de uso
		if current_lives <= 0:
			_on_game_over_lives()

func _is_left_completed(idx: int) -> bool:
	for conn in completed_connections:
		if conn.left_index == idx:
			return true
	return false

func _highlight_left_buttons() -> void:
	var is_accessible: bool = StateManager.is_high_contrast_active()
	for i in range(left_buttons.size()):
		var btn: Button = left_buttons[i]
		if is_instance_valid(btn) and not btn.disabled:
			if is_accessible:
				_apply_button_contrast(btn, true)
				if i == selected_source_index:
					var sb_sel := btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
					if sb_sel:
						sb_sel.bg_color = Color(0.26, 0.22, 0.06, 1.0)
						btn.add_theme_stylebox_override("normal", sb_sel)
			else:
				_apply_left_port_style(i, btn)

func _get_left_port_pos(index: int) -> Vector2:
	if index >= 0 and index < left_buttons.size():
		var btn: Button = left_buttons[index]
		if is_instance_valid(btn):
			return _to_canvas_local(btn.global_position + Vector2(btn.size.x, btn.size.y * 0.5))
	return Vector2.ZERO

## Renderizado de cables garantizado sobre CableCanvas
func _on_cable_canvas_draw() -> void:
	# 0. Sockets / boquillas cibernéticas en los puertos visibles
	for i in range(left_buttons.size()):
		var l_btn: Button = left_buttons[i]
		if is_instance_valid(l_btn) and l_btn.size.x > 0.0:
			var pt := _to_canvas_local(l_btn.global_position + Vector2(l_btn.size.x, l_btn.size.y * 0.5))
			if pt.y >= 4.0 and pt.y <= cable_canvas.size.y - 4.0:
				var ring_col := Color("ffd54f") if i == selected_source_index else (Color("69f0ae") if _is_left_completed(i) else Color(0.24, 0.30, 0.42, 1.0))
				cable_canvas.draw_circle(pt, 7.0, Color(0.10, 0.14, 0.20, 1.0))
				cable_canvas.draw_circle(pt, 4.5, ring_col)
				cable_canvas.draw_circle(pt, 2.0, Color.WHITE)

	for type_key in right_buttons:
		var r_btn: Button = right_buttons[type_key]
		if is_instance_valid(r_btn) and r_btn.size.x > 0.0:
			var pt := _to_canvas_local(r_btn.global_position + Vector2(0.0, r_btn.size.y * 0.5))
			var t_col: Color = TYPE_COLORS.get(type_key, Color.CYAN)
			cable_canvas.draw_circle(pt, 7.0, Color(0.10, 0.14, 0.20, 1.0))
			cable_canvas.draw_circle(pt, 4.5, t_col)
			cable_canvas.draw_circle(pt, 2.0, Color.WHITE)

	# 1. Dibujar todos los cables conectados y completados (FN-04)
	for i in range(completed_connections.size()):
		var conn: Dictionary = completed_connections[i]
		var l_node: Button = conn.get("from_node", null)
		var r_node: Button = conn.get("to_node", null)
		if is_instance_valid(l_node) and is_instance_valid(r_node):
			var from_p := _to_canvas_local(l_node.global_position + Vector2(l_node.size.x, l_node.size.y * 0.5))
			var to_p := _to_canvas_local(r_node.global_position + Vector2(0, r_node.size.y * 0.5))
			var cable_color: Color = _get_cable_color(i)
			var w: float = 8.0 if StateManager.is_high_contrast_active() else 6.0
			_draw_cable_with_border(from_p, to_p, cable_color, w)

	# 2. Dibujar chispa de cortocircuito en error (FA-02.01)
	if error_flash_timer > 0.0:
		var alpha: float = clampf(error_flash_timer / 0.4, 0.2, 1.0)
		var col_err := Color(1.0, 0.1, 0.2, alpha)
		_draw_cable_with_border(error_spark_from, error_spark_to, col_err, 7.0)
		cable_canvas.draw_circle(error_spark_to, 9.0, Color("ffea00"))

	# 3. Dibujar cable activo trazándose (FN-02)
	if selected_source_index >= 0:
		var from_p := _get_left_port_pos(selected_source_index)
		var to_p := drag_current_pos
		if from_p != Vector2.ZERO and to_p != Vector2.ZERO:
			var active_color: Color = _get_cable_color(completed_connections.size())
			var w: float = 7.0 if StateManager.is_high_contrast_active() else 5.0
			_draw_cable_with_border(from_p, to_p, active_color, w)

func _draw_cable_with_border(from_pos: Vector2, to_pos: Vector2, color: Color, width: float) -> void:
	var mid_x: float = (from_pos.x + to_pos.x) * 0.5
	var sag: float = clampf(abs(to_pos.x - from_pos.x) * 0.12, 12.0, 32.0)
	var control_p := Vector2(mid_x, maxf(from_pos.y, to_pos.y) + sag)

	var points := PackedVector2Array()
	const SEGMENTS: int = 24
	for i in range(SEGMENTS + 1):
		var t: float = float(i) / float(SEGMENTS)
		var p: Vector2 = (1.0 - t) * (1.0 - t) * from_pos + 2.0 * (1.0 - t) * t * control_p + t * t * to_pos
		points.append(p)

	# 1. Cubierta exterior corrugada tipo manguera/tubo cibernético (Gris metálico/goma)
	var hose_w: float = width + 8.0
	var outer_casing_col := Color(0.12, 0.14, 0.18, 0.95)
	cable_canvas.draw_polyline(points, outer_casing_col, hose_w, true)

	# 2. Anillos estriados de la manguera corrugada (efecto tubo flexible)
	var ring_col := Color(0.28, 0.32, 0.40, 0.95)
	for i in range(1, SEGMENTS):
		if i % 2 == 0:
			var pt := points[i]
			var dir := (points[i + 1] - points[i - 1]).normalized()
			var normal := Vector2(-dir.y, dir.x)
			cable_canvas.draw_line(pt - normal * (hose_w * 0.5), pt + normal * (hose_w * 0.5), ring_col, 2.0)

	# 3. Flujo interno de energía / plasma neón en el centro del tubo
	var core_w: float = maxf(3.0, width * 0.6)
	cable_canvas.draw_polyline(points, color, core_w, true)

	# 4. Núcleo brillante ultra-luminoso central
	var glow_w: float = maxf(1.5, core_w * 0.35)
	cable_canvas.draw_polyline(points, Color.WHITE.lerp(color, 0.4), glow_w, true)

	# 5. Boquillas / Conectores cibernéticos en los puertos de inicio y fin
	for pt in [from_pos, to_pos]:
		cable_canvas.draw_circle(pt, hose_w * 0.5 + 2.0, Color(0.18, 0.22, 0.30, 1.0))
		cable_canvas.draw_circle(pt, hose_w * 0.5 - 1.0, color)
		cable_canvas.draw_circle(pt, glow_w + 1.0, Color.WHITE)

func _update_hud() -> void:
	pairs_counter_label.text = "PARES: %d/%d" % [completed_connections.size(), round_pairs.size()]
	update_aula101_hearts_bar(hearts_bar, current_lives, max_lives, hearts_label, 14.0)
	_update_timer_hud()

func _update_timer_hud() -> void:
	time_label.text = "%ds" % int(ceil(time_remaining))
	time_bar.max_value = time_limit
	time_bar.value = time_remaining

	if time_remaining <= 10.0:
		time_label.modulate = Color("ff3366")
	else:
		time_label.modulate = Color.WHITE

## FA-04.01: Finalización del tiempo límite -> Paraliza sesión y despliega Game Over por tiempo agotado
func _on_time_expired() -> void:
	is_timer_active = false
	AudioManager.play_game_over()
	EventBus.game_over.emit(minigame_id)
	finish_game(false, total_score, 0, "Tiempo agotado")
	var reason := "Tiempo Límite Agotado (%ds).\nEl reloj alcanzó cero antes de asociar todos los datos." % int(time_limit)
	if flow_template:
		flow_template.show_game_over(reason, total_score)
	else:
		lbl_gameover_reason.text = reason
		_show_screen(screen_game_over)

## FA-04.02: Agotamiento de vidas -> Despliega Game Over especificando la causa del término
func _on_game_over_lives() -> void:
	is_timer_active = false
	AudioManager.play_game_over()
	EventBus.game_over.emit(minigame_id)
	finish_game(false, total_score, 0, "Vidas agotadas")
	var reason := "Vidas Agotadas.\nEl total de vidas llegó a cero debido a enlaces incompatibles."
	if flow_template:
		flow_template.show_game_over(reason, total_score)
	else:
		lbl_gameover_reason.text = reason
		_show_screen(screen_game_over)

## FN-06: Finalización exitosa con todos los pares asociados
func _on_all_pairs_connected() -> void:
	is_timer_active = false
	AudioManager.play_success()
	total_score = base_score

	# Estrellas y puntos exactos según dificultad (RF-38 / CU-11 FN-06)
	var stars: int = 2
	match selected_diff:
		"FACIL": stars = 1
		"NORMAL": stars = 2
		"INGENIERO": stars = 3

	var prev_high: int = StateManager.get_minigame_high_score(minigame_id) if StateManager else 0
	var is_record: bool = total_score > prev_high
	finish_game(true, total_score, stars, "¡Todos los tipos clasificados correctamente!")
	if flow_template:
		var total_accum: int = StateManager.get_points() if StateManager else total_score
		flow_template.show_victory(total_score, stars, total_accum, is_record, "¡DATOS ENLAZADOS!")
	else:
		var stars_str: String = "⭐".repeat(stars) + "☆".repeat(3 - stars)
		var time_spent: int = int(time_limit - time_remaining)
		lbl_victory_stats.text = "%s\n\nPuntuación Total: %d pts\nTiempo Empleado: %d seg\nVidas Conservadas: %d / %d" % [
			stars_str, total_score, time_spent, current_lives, max_lives
		]
		_show_screen(screen_victory)

## FA-02.03: Suspensión de la partida (Pausa)
func _on_resume_pressed() -> void:
	AudioManager.play_click()
	is_game_paused = false
	_show_screen(screen_game)

func _on_restart_pressed() -> void:
	AudioManager.play_click()
	start_game(selected_diff)

func _on_back_to_classroom() -> void:
	AudioManager.play_click()
	get_tree().change_scene_to_file("res://scenes/classroom/AulaProgramacion.tscn")
