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
	for btn in left_buttons:
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
		btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	else:
		btn.remove_theme_stylebox_override("normal")
		btn.remove_theme_color_override("font_color")

# Estado de partida
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

	_connect_ui_signals()
	cable_canvas.draw.connect(_on_cable_canvas_draw)
	_show_screen(screen_start)
	_select_difficulty("NORMAL")

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

func _connect_ui_signals() -> void:
	btn_diff_facil.pressed.connect(func(): _select_difficulty("FACIL"))
	btn_diff_normal.pressed.connect(func(): _select_difficulty("NORMAL"))
	btn_diff_ing.pressed.connect(func(): _select_difficulty("INGENIERO"))
	btn_start_play.pressed.connect(_on_btn_start_pressed)
	btn_start_back.pressed.connect(_on_back_to_classroom)

	btn_pause.pressed.connect(_on_pause_pressed)
	btn_pause_resume.pressed.connect(_on_resume_pressed)
	btn_pause_restart.pressed.connect(_on_restart_pressed)
	btn_pause_exit.pressed.connect(_on_back_to_classroom)

	btn_victory_retry.pressed.connect(_on_restart_pressed)
	btn_victory_exit.pressed.connect(_on_back_to_classroom)
	btn_gameover_retry.pressed.connect(_on_restart_pressed)
	btn_gameover_exit.pressed.connect(_on_back_to_classroom)

func _show_screen(active_screen: Control) -> void:
	screen_start.visible = (active_screen == screen_start)
	screen_game.visible = (active_screen == screen_game)
	screen_pause.visible = (active_screen == screen_pause)
	screen_victory.visible = (active_screen == screen_victory)
	screen_game_over.visible = (active_screen == screen_game_over)

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

	# Columna izquierda: Valores literales ("Dato")
	for i in range(round_pairs.size()):
		var item: Dictionary = round_pairs[i]
		var btn := Button.new()
		btn.text = "  %s  ●" % item.literal
		btn.name = "LeftPort_%d" % i
		btn.custom_minimum_size = Vector2(100, 36)
		btn.add_theme_font_size_override("font_size", 11)
		btn.focus_mode = Control.FOCUS_NONE
		btn.alignment = HORIZONTAL_ALIGNMENT_RIGHT

		var idx: int = i
		btn.button_down.connect(func(): _on_left_port_down(idx))
		btn.pressed.connect(func(): _on_left_port_clicked(idx))
		left_container.add_child(btn)
		left_buttons.append(btn)

	# Columna derecha: 6 Tipos de variable requeridos (int, float, string, bool, char, list)
	for type_info in DataDropQuestions.ALL_TYPES:
		var btn := Button.new()
		btn.text = "●  %s" % type_info.label.replace("\n", " ")
		btn.name = "RightPort_%s" % type_info.type
		btn.custom_minimum_size = Vector2(108, 38)
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 10)
		btn.focus_mode = Control.FOCUS_NONE
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		# Color temático sutil en el borde/texto del receptor
		btn.modulate = Color.WHITE

		var t_name: String = type_info.type
		btn.pressed.connect(func(): _on_right_port_clicked(t_name))
		right_container.add_child(btn)
		right_buttons[type_info.type] = btn

	left_scroll.scroll_vertical = 0
	_update_accessibility_styles()

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
		left_btn.modulate = Color(0.4, 0.4, 0.4)

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
	for i in range(left_buttons.size()):
		var btn: Button = left_buttons[i]
		if is_instance_valid(btn) and not btn.disabled:
			if i == selected_source_index:
				btn.modulate = Color("ffea00")
			else:
				btn.modulate = Color.WHITE

func _get_left_port_pos(index: int) -> Vector2:
	if index >= 0 and index < left_buttons.size():
		var btn: Button = left_buttons[index]
		if is_instance_valid(btn):
			return _to_canvas_local(btn.global_position + Vector2(btn.size.x, btn.size.y * 0.5))
	return Vector2.ZERO

## Renderizado de cables garantizado sobre CableCanvas
func _on_cable_canvas_draw() -> void:
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
	const SEGMENTS: int = 18
	for i in range(SEGMENTS + 1):
		var t: float = float(i) / float(SEGMENTS)
		var p: Vector2 = (1.0 - t) * (1.0 - t) * from_pos + 2.0 * (1.0 - t) * t * control_p + t * t * to_pos
		points.append(p)

	# Borde exterior oscuro para contraste de cable físico
	var is_hc: bool = StateManager.is_high_contrast_active()
	var border_w: float = width + (5.0 if is_hc else 3.0)
	var border_col: Color = Color(0.0, 0.0, 0.0, 1.0) if is_hc else Color(0.04, 0.05, 0.07, 0.9)
	cable_canvas.draw_polyline(points, border_col, border_w, true)
	cable_canvas.draw_circle(from_pos, border_w * 0.5 + 1.0, border_col)
	cable_canvas.draw_circle(to_pos, border_w * 0.5 + 1.0, border_col)

	# Línea interior de color brillante
	cable_canvas.draw_polyline(points, color, width, true)
	cable_canvas.draw_circle(from_pos, width * 0.5, color)
	cable_canvas.draw_circle(to_pos, width * 0.5, color)

func _update_hud() -> void:
	pairs_counter_label.text = "PARES: %d / %d" % [completed_connections.size(), round_pairs.size()]
	hearts_label.text = "❤ ".repeat(current_lives) + "♡ ".repeat(max_lives - current_lives)
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

	lbl_gameover_reason.text = "FA-04.01 Tiempo Límite Agotado (%ds).\nEl reloj alcanzó cero antes de asociar todos los pares requeridos." % int(time_limit)
	_show_screen(screen_game_over)

## FA-04.02: Agotamiento de vidas -> Despliega Game Over especificando la causa del término
func _on_game_over_lives() -> void:
	is_timer_active = false
	AudioManager.play_game_over()
	EventBus.game_over.emit(minigame_id)

	lbl_gameover_reason.text = "FA-04.02 Vidas Agotadas.\nEl total de vidas llegó a cero debido a enlaces erróneos de cables."
	_show_screen(screen_game_over)

## FN-06: Finalización exitosa con todos los pares asociados
func _on_all_pairs_connected() -> void:
	is_timer_active = false
	AudioManager.play_success()
	total_score = base_score

	# Cálculo de estrellas según tiempo sobrante y vidas conservadas
	var stars: int = 1
	var time_ratio: float = time_remaining / time_limit
	if current_lives == max_lives and time_ratio >= 0.35:
		stars = 3
	elif current_lives >= 2 or time_ratio >= 0.2:
		stars = 2

	var stars_str: String = "⭐".repeat(stars) + "☆".repeat(3 - stars)
	var time_spent: int = int(time_limit - time_remaining)

	lbl_victory_stats.text = "%s\n\nPuntuación Total: %d pts\nTiempo Empleado: %d seg\nVidas Conservadas: %d / %d" % [
		stars_str, total_score, time_spent, current_lives, max_lives
	]

	finish_game(true, total_score, stars, "¡Todos los tipos clasificados correctamente!")
	_show_screen(screen_victory)

## FA-02.03: Suspensión de la partida (Pausa)
func _on_pause_pressed() -> void:
	if not is_timer_active:
		return
	AudioManager.play_click()
	is_game_paused = true
	_show_screen(screen_pause)

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
