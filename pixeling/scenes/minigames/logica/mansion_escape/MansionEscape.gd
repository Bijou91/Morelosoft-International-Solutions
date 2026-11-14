## MansionEscape.gd - CU-14: Practicar evaluación de diagramas de Venn
## Minijuego "Mansión del escape (Diagramas de Venn)" del aula de Lógica y Algoritmos.
## Estructura calcada de DerbyDeBateo: extiende MiniGameBase, selector de dificultad
## dentro de la misma escena, menú de pausa y pantalla de resultados (overlays).
## Aislado en logica/mansion_escape/ (no toca autoloads ni escenas de otras aulas).
##
## JSON de retos (data/questions_<dificultad>.json):
##   [ {"question": "A ∩ B", "correct": "v2_q01_correct.png"}, ... ]
## Respuesta correcta = nombre de archivo. Los distractores se toman de los archivos
## hermanos "<prefijo>_inc1.png", "<prefijo>_inc2.png"... (prefijo = nombre correcto sin "_correct.png").
extends MiniGameBase

# ---------------------------------------------------------------------------
# Rutas (cambia ASSET_DIR si guardas tus PNG en otra carpeta)
# ---------------------------------------------------------------------------
const ASSET_DIR: String = "res://assets/logica/mansion_escape/"
const FONT_FILE: String = "DejaVuSans.ttf"   # fuente con símbolos ∩ ∪ Δ ′ (opcional, ver ASSET_DIR)
const DATA_DIR: String = "res://scenes/minigames/logica/mansion_escape/data/"
const AULA_SCENE: String = "res://scenes/classroom/AulaLogica.tscn"
const LOBBY_SCENE: String = "res://scenes/campus/Lobby.tscn"

# ---------------------------------------------------------------------------
# Configuración por dificultad (valores tomados del CU-14)
#   timer          -> segundos para responder los 5 retos EN CONJUNTO
#   lives          -> vidas
#   points         -> puntos por respuesta correcta
#   penalty        -> puntos que se restan por respuesta incorrecta
#   enemy_interval -> cada cuántos segundos el enemigo baja un piso
#   start_gap      -> pisos de ventaja inicial del enemigo (1 = empieza en el piso inmediato de arriba)
# ---------------------------------------------------------------------------
const CONFIG: Dictionary = {
	"FACIL": {
		"name": "FÁCIL",
		"timer": 60.0,
		"lives": 7,
		"points": 50,
		"penalty": 10,
		"enemy_interval": 15.0,
		"start_gap": 1,
		"description": "7 vidas, 60s en total, 50 pts/acierto.\nEl fantasma baja cada 15s."
	},
	"NORMAL": {
		"name": "NORMAL",
		"timer": 90.0,
		"lives": 5,
		"points": 100,
		"penalty": 20,
		"enemy_interval": 20.0,
		"start_gap": 1,
		"description": "5 vidas, 90s en total, 100 pts/acierto.\nEl fantasma baja cada 20s."
	},
	"INGENIERO": {
		"name": "INGENIERO",
		"timer": 135.0,
		"lives": 3,
		"points": 200,
		"penalty": 40,
		"enemy_interval": 27.0,
		"start_gap": 1,
		"description": "3 vidas, 135s en total, 200 pts/acierto.\nEl fantasma baja cada 27s."
	}
}

# --- Reglas generales (ajustables) ---
const RETOS_TOTAL: int = 5
const NUM_DOORS: int = 5
const MAX_INCORRECT_FILES: int = 8       # cuántos "_incN.png" busca por reto (se eligen 4 al azar)
const PLAYER_SPEED: float = 150.0        # px/s
const STUN_TIME: float = 1.5             # inmovilización tras fallar (FA-06.01)
const WRONG_ENEMY_PENALTY: float = 5.0   # segundos que se restan al contador interno
const ENEMY_SLOW_TIME: float = 5.0       # duración de la ralentización tras acertar
const ENEMY_SLOW_FACTOR: float = 0.4     # 1.0 = velocidad normal
const GHOST_PATROL_SPEED: float = 55.0   # px/s del fantasma cuando está en el piso de arriba
const SCROLL_TIME: float = 0.55          # duración del "zoom/desplazamiento" entre pisos

# --- Medidas del escenario (px). El escenario muestra SIEMPRE 2 pisos: arriba y actual ---
const DOOR_SIZE: Vector2 = Vector2(46, 58)
const PLAYER_SIZE: float = 36.0
const ENEMY_SIZE: float = 36.0
const LINE_MARGIN: float = 8.0           # distancia del suelo al borde inferior de cada piso
const OVERLAY_Z: int = 10                # z_index de pausa / instrucciones / game over (mayor que barandal y avisos)
const WALL_TILE_PX: float = 64.0         # tamaño en pantalla de UN mosaico de pared.png (más grande = ladrillos más grandes)

## Pared en mosaico: repite pared.png a un tamaño fijo (WALL_TILE_PX) en lugar de estirar
## una sola imagen. Se dibuja a mano para no depender de texture_repeat.
class WallTile extends Control:
	var tex: Texture2D = null
	var tile_px: float = 64.0
	var fallback: Color = Color(0.12, 0.16, 0.24)

	func _init() -> void:
		clip_contents = true
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if tex == null:
			draw_rect(Rect2(Vector2.ZERO, size), fallback)
			return
		var cols: int = int(ceil(size.x / tile_px))
		var rows: int = int(ceil(size.y / tile_px))
		for r in range(rows):
			for c in range(cols):
				draw_texture_rect(tex, Rect2(float(c) * tile_px, float(r) * tile_px, tile_px, tile_px), false)

enum State { SELECTING, INSTRUCTIONS, PLAYING, RESOLVING, ENDED }
enum GhostMode { STATIC, PATROL }

# --- Estado del minijuego ---
var state: int = State.SELECTING
var run_id: int = 0                      # invalida awaits pendientes al reintentar/salir
var rng := RandomNumberGenerator.new()
var retos: Array = []
var reto_index: int = 0
var door_files: Array[String] = []       # archivo de imagen que hay detrás de cada puerta 1..5
var last_correct_door: int = -1          # para que la correcta no repita número seguido
var last_first_reto: String = ""         # para que dos sesiones seguidas no empiecen igual
var floor_level: int = 1

var time_left: float = 60.0
var max_lives: int = 7
var current_lives: int = 7
var total_score: int = 0
var total_correct: int = 0
var mistakes: int = 0

var enemy_interval: float = 15.0
var enemy_timer: float = 15.0
var enemy_gap: int = 3                   # pisos que hay entre el fantasma y el alumno (0 = alcanzado)
var enemy_slow_left: float = 0.0
var stun_left: float = 0.0
var ghost_mode: int = GhostMode.STATIC
var ghost_dir: float = 1.0

var move_dir_buttons: int = 0
var selected_door: int = -1

# --- Nodos creados por código ---
var option_slots: Array[Dictionary] = []
var world: Control                       # contiene los 3 pisos (arriba, actual, siguiente)
var floors: Array[Dictionary] = []       # [0]=arriba  [1]=actual  [2]=siguiente (fuera de cámara)
var player: TextureRect
var enemy: TextureRect
var ghost_note: Control
var ghost_note_label: Label
var toast_label: Label
var toast_tween: Tween
var enemy_tween: Tween
var stage_w: float = 336.0
var stage_h: float = 176.0
var symbol_font: Font = null
var _diagram_sky: TextureRect = null   # cielo detrás de los diagramas
var _diagram_moon: TextureRect = null  # luna detrás de los diagramas
var _menu_bg: TextureRect = null        # imagen de la mansión en la pantalla de selección de dificultad
var flow_template: Control

# --- Referencias UI ---
@onready var btn_back: Button = $TopHUD/BtnBack
@onready var btn_pause: Button = $TopHUD/BtnPause

@onready var difficulty_selector: HBoxContainer = $VBox/DifficultySelector
@onready var btn_diff_facil: Button = $VBox/DifficultySelector/BtnDiffFacil
@onready var btn_diff_normal: Button = $VBox/DifficultySelector/BtnDiffNormal
@onready var btn_diff_ing: Button = $VBox/DifficultySelector/BtnDiffIng

@onready var hud_row: HBoxContainer = $VBox/HudRow
@onready var timer_label: Label = $VBox/HudRow/TimerLabel
@onready var progress_label: Label = $VBox/HudRow/ProgressLabel
@onready var lives_label: Label = $VBox/HudRow/LivesLabel
@onready var question_panel: PanelContainer = $VBox/QuestionPanel
@onready var question_label: Label = $VBox/QuestionPanel/Margin/QuestionLabel
@onready var options_area: VBoxContainer = $VBox/OptionsArea
@onready var row_top: HBoxContainer = $VBox/OptionsArea/RowTop
@onready var row_bottom: HBoxContainer = $VBox/OptionsArea/RowBottom
@onready var stage: Control = $VBox/Stage
@onready var controls: HBoxContainer = $VBox/Controls
@onready var btn_left: Button = $VBox/Controls/BtnLeft
@onready var btn_right: Button = $VBox/Controls/BtnRight
@onready var btn_enter: Button = $VBox/Controls/BtnEnter

# Overlay de Instrucciones (idéntico a Cinturón de Hipótesis)
var instructions_overlay: ColorRect
var instr_diff_label: Label
var instr_desc_label: Label

# Pausa
@onready var pause_overlay: ColorRect = $PauseOverlay
@onready var btn_resume: Button = $PauseOverlay/VBox/BtnResume
@onready var btn_exit: Button = $PauseOverlay/VBox/BtnExit

# Game Over / Resultados
@onready var game_over_overlay: ColorRect = $GameOverOverlay
@onready var go_title_label: Label = $GameOverOverlay/VBox/TitleLabel
@onready var go_reason_label: Label = $GameOverOverlay/VBox/ReasonLabel
@onready var go_stats_label: Label = $GameOverOverlay/VBox/StatsLabel
@onready var btn_go_retry: Button = $GameOverOverlay/VBox/BtnRetry
@onready var btn_go_exit: Button = $GameOverOverlay/VBox/BtnExit


func _ready() -> void:
	super._ready()
	minigame_id = "mansion_escape"
	cu_id = "CU-14"
	minigame_title = "Mansión del Escape: Diagramas de Venn"
	subject_name = "Lógica y Algoritmos"
	rng.randomize()                       # semilla distinta en cada sesión

	var f_path: String = ASSET_DIR + FONT_FILE
	if ResourceLoader.exists(f_path):
		symbol_font = load(f_path) as Font
		question_label.add_theme_font_override("font", symbol_font)

	_build_instructions_overlay()

	btn_back.pressed.connect(_on_back_pressed)
	btn_diff_facil.pressed.connect(func(): _on_difficulty_selected("FACIL"))
	btn_diff_normal.pressed.connect(func(): _on_difficulty_selected("NORMAL"))
	btn_diff_ing.pressed.connect(func(): _on_difficulty_selected("INGENIERO"))

	# Controles del personaje (mantener presionado para moverse)
	btn_left.button_down.connect(func(): move_dir_buttons = -1)
	btn_left.button_up.connect(func(): _release_move(-1))
	btn_right.button_down.connect(func(): move_dir_buttons = 1)
	btn_right.button_up.connect(func(): _release_move(1))
	btn_enter.pressed.connect(_on_enter_pressed)

	# Pausa
	btn_pause.pressed.connect(_on_pause_pressed)
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)
	# Game over
	btn_go_exit.pressed.connect(_on_go_exit_pressed)
	btn_go_retry.pressed.connect(_on_go_retry_pressed)

	_build_options_ui()
	_build_diagram_background()  # cielo + luna detrás de los diagramas de Venn
	_build_menu_background()     # imagen de la mansión para la pantalla de selección
	_build_stage()
	stage.resized.connect(_layout_stage)

	# Estabilizar recuadros de texto y HUD
	lock_dynamic_label_box(question_label, question_panel, 46.0, 16, 9, 4.0, 2.0, true, true, 4.0)
	stabilize_hud_label(timer_label, 52.0)
	stabilize_hud_label(progress_label, 118.0)
	stabilize_hud_label(lives_label, 52.0)

	_build_flow_template()
	_show_difficulty_selector()

	# Los overlays van por encima de todo lo del escenario (barandal z=1, avisos z=2)
	pause_overlay.z_index = OVERLAY_Z
	game_over_overlay.z_index = OVERLAY_Z
	if instructions_overlay:
		instructions_overlay.z_index = OVERLAY_Z

	# CRÍTICO: el menú de pausa debe funcionar con el árbol pausado
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	# Atajo de teclado para probar en PC (Enter / Espacio = ENTRAR)
	if state == State.PLAYING and event.is_action_pressed("ui_accept") and not event.is_echo():
		_on_enter_pressed()


func _process(delta: float) -> void:
	# INSTRUCTIONS / RESOLVING / ENDED: el temporizador y el enemigo están detenidos
	if state != State.PLAYING:
		return

	# Contador de tiempo global (5 retos en conjunto)
	time_left -= delta
	_update_timer_ui()
	if time_left <= 0.0:
		_on_time_up()
		return

	# Personaje: inmovilizado temporalmente o libre
	if stun_left > 0.0:
		stun_left = maxf(0.0, stun_left - delta)
		player.modulate = Color(1.0, 0.45, 0.45) if int(stun_left * 8.0) % 2 == 0 else Color.WHITE
		if stun_left <= 0.0:
			player.modulate = Color.WHITE
	else:
		_move_player(delta)

	# Fantasma patrullando el piso de arriba (izquierda <-> derecha)
	if ghost_mode == GhostMode.PATROL and enemy.visible and not (enemy_tween != null and enemy_tween.is_running()):
		enemy.position.x += ghost_dir * GHOST_PATROL_SPEED * delta
		if enemy.position.x <= 0.0:
			enemy.position.x = 0.0
			ghost_dir = 1.0
		elif enemy.position.x >= stage_w - ENEMY_SIZE:
			enemy.position.x = stage_w - ENEMY_SIZE
			ghost_dir = -1.0
		enemy.flip_h = ghost_dir < 0.0

	# Contador interno del enemigo (invisible para el alumno)
	var speed_mult: float = 1.0
	if enemy_slow_left > 0.0:
		enemy_slow_left -= delta
		speed_mult = ENEMY_SLOW_FACTOR
	enemy_timer -= delta * speed_mult
	if enemy_timer <= 0.0:
		_enemy_advance()


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
	rules_label.text = "• Observa la operación de conjuntos que aparece arriba (A ∩ B, A ∪ B, etc.).\n• Muévete con ◀ y ▶ hacia la puerta con el diagrama de Venn correcto y pulsa ENTRAR.\n• Puerta correcta: desciendes un piso, sumas puntos y ralentizas al fantasma.\n• Puerta incorrecta: pierdes 1 vida (-1 ❤️) y el fantasma avanza más rápido.\n• ¡Supera los 5 pisos antes de que se acabe el tiempo o te alcance!"
	rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_label.add_theme_font_size_override("font_size", 11)
	rules_label.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	if symbol_font:
		rules_label.add_theme_font_override("font", symbol_font)
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

func _on_start_game_pressed() -> void:
	AudioManager.play_click()
	if instructions_overlay:
		instructions_overlay.visible = false
	start_game(current_difficulty)

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


# ---------------------------------------------------------------------------
# Construcción de la interfaz dinámica
# ---------------------------------------------------------------------------

func _tex(file_name: String) -> Texture2D:
	# Rutas posibles por si los PNG están en assets o junto a la escena
	var candidates: Array[String] = [
		ASSET_DIR + file_name,
		"res://assets/logica/mansion_escape/" + file_name,
		"res://scenes/minigames/logica/mansion_escape/" + file_name,
	]
	for path in candidates:
		if ResourceLoader.exists(path):
			var res = load(path)
			if res is Texture2D:
				return res as Texture2D
	push_warning("MansionEscape: no se encontró textura '%s'" % file_name)
	return null

func _placeholder(color: Color) -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, color)
	g.set_color(1, color)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 16
	t.height = 16
	return t

func _make_sprite(file_name: String, fallback: Color, size: Vector2) -> TextureRect:
	var tr := TextureRect.new()
	var t: Texture2D = _tex(file_name)
	tr.texture = t if t != null else _placeholder(fallback)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.size = size
	return tr

## R1..R5: R2 y R4 arriba, R1, R3 y R5 abajo (como en la interfaz del CU-14)
func _build_options_ui() -> void:
	for i in range(NUM_DOORS):
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(104, 78)

		var tex := TextureRect.new()
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel.add_child(tex)

		var badge := Label.new()
		badge.text = str(i + 1)
		badge.add_theme_font_size_override("font_size", 13)
		badge.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
		badge.add_theme_color_override("font_outline_color", Color.BLACK)
		badge.add_theme_constant_override("outline_size", 5)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tex.add_child(badge)
		badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		badge.offset_left = -22.0
		badge.offset_right = -3.0

		var missing := Label.new()
		missing.visible = false
		missing.add_theme_font_size_override("font_size", 9)
		missing.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		missing.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		missing.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		tex.add_child(missing)
		missing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		if i % 2 == 1:
			row_top.add_child(panel)
		else:
			row_bottom.add_child(panel)
		option_slots.append({"panel": panel, "tex": tex, "missing": missing})

## Cielo + luna SOLO detrás de los diagramas (OptionsArea).
## No van en el Stage ni a la altura de la pared. Si los diagramas los tapan, no importa.
## Oscurecidos para no robar el foco.
## Fondo de la pantalla de selección de dificultad: ajustado a la ALTURA (sin deformar,
## centrado y recortando lo que sobre a los lados). Solo se ve mientras state == SELECTING.
func _build_menu_background() -> void:
	var tex: Texture2D = _tex("pantalla_mansion.png")
	if tex == null:
		return
	_menu_bg = TextureRect.new()
	_menu_bg.name = "MenuBg"
	_menu_bg.texture = tex
	_menu_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_menu_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_menu_bg.modulate = Color(0.42, 0.45, 0.56, 1.0)   # mismo oscurecido que el estadio del Derby de bateo
	_menu_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_bg.visible = false
	add_child(_menu_bg)
	move_child(_menu_bg, 1)   # justo encima del ColorRect de fondo, debajo de toda la UI

func _build_diagram_background() -> void:
	# Hijos del root de la escena (no del VBox), para no romper el layout de OptionsArea.
	# Se posicionan encima del área de diagramas con z bajo.
	_diagram_sky = TextureRect.new()
	_diagram_sky.name = "DiagramSky"
	_diagram_sky.texture = _tex("cielo.png")
	if _diagram_sky.texture == null:
		_diagram_sky.texture = _placeholder(Color(0.05, 0.06, 0.14))
	_diagram_sky.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_diagram_sky.stretch_mode = TextureRect.STRETCH_SCALE
	_diagram_sky.modulate = Color(0.40, 0.43, 0.55, 1.0)
	_diagram_sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# (sin z_index negativo: quedaría detrás del ColorRect de fondo y no se vería)
	add_child(_diagram_sky)
	# Justo después del ColorRect de fondo de la escena
	move_child(_diagram_sky, 1)

	_diagram_moon = TextureRect.new()
	_diagram_moon.name = "DiagramMoon"
	_diagram_moon.texture = _tex("luna.png")
	if _diagram_moon.texture == null:
		_diagram_moon.texture = _placeholder(Color(0.75, 0.8, 0.95))
	_diagram_moon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_diagram_moon.stretch_mode = TextureRect.STRETCH_SCALE
	_diagram_moon.modulate = Color(0.50, 0.53, 0.65, 1.0)
	_diagram_moon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_diagram_moon)
	move_child(_diagram_moon, 2)

	options_area.resized.connect(_layout_diagram_background)
	options_area.visibility_changed.connect(_layout_diagram_background)
	call_deferred("_layout_diagram_background")

func _layout_diagram_background() -> void:
	if _diagram_sky == null or _diagram_moon == null:
		return
	# Solo visibles cuando hay diagramas en pantalla
	var show_bg: bool = options_area.visible and options_area.size.x > 4.0 and options_area.size.y > 4.0
	_diagram_sky.visible = show_bg
	_diagram_moon.visible = show_bg
	if not show_bg:
		return
	# Rect global del área de opciones → coords locales del root
	var gr: Rect2 = options_area.get_global_rect()
	var inv := get_global_transform_with_canvas().affine_inverse()
	var local_pos: Vector2 = inv * gr.position
	_diagram_sky.position = local_pos
	_diagram_sky.size = gr.size
	var ms := 48.0
	_diagram_moon.size = Vector2(ms, ms)
	_diagram_moon.position = Vector2(local_pos.x + maxf(8.0, gr.size.x - ms - 10.0), local_pos.y + 6.0)

## Un piso = pared (detrás de puertas) + puertas + antorchas (entre puertas) + barandal (delante)
## Sin cielo ni luna aquí.
func _make_floor() -> Dictionary:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(root)

	# Pared detrás de las puertas
	var wall := WallTile.new()
	wall.tex = _tex("pared.png")
	wall.tile_px = WALL_TILE_PX
	root.add_child(wall)

	var line := ColorRect.new()
	line.color = Color(0.22, 0.26, 0.36)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(line)

	var doors: Array[TextureRect] = []
	for i in range(NUM_DOORS):
		var door := _make_sprite("door.png", Color(0.4, 0.28, 0.22), DOOR_SIZE)
		var num := Label.new()
		num.text = str(i + 1)
		num.add_theme_font_size_override("font_size", 18)
		num.add_theme_color_override("font_color", Color.WHITE)
		num.add_theme_color_override("font_outline_color", Color.BLACK)
		num.add_theme_constant_override("outline_size", 6)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		door.add_child(num)
		num.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		num.offset_top = 8.0
		root.add_child(door)
		doors.append(door)

	# Antorchas solo entre puertas (no extremos)
	var torches: Array[TextureRect] = []
	for i in range(NUM_DOORS - 1):
		var torch := _make_sprite("antorcha.png", Color(0.25, 0.75, 1.0), Vector2(22, 34))
		root.add_child(torch)
		torches.append(torch)

	# Barandal delante
	var railing := TextureRect.new()
	railing.texture = _tex("barandal.png")
	if railing.texture == null:
		railing.texture = _placeholder(Color(0.35, 0.4, 0.55))
	railing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	railing.stretch_mode = TextureRect.STRETCH_SCALE
	railing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	railing.z_index = 1   # por encima del personaje/fantasma (z 0), que van entre puertas y barandal
	root.add_child(railing)

	return {
		"root": root,
		"wall": wall,
		"line": line,
		"doors": doors,
		"torches": torches,
		"railing": railing
	}

func _build_stage() -> void:
	# Solo pisos + personaje + fantasma. Cielo/luna NO van aquí.
	world = Control.new()
	world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(world)
	for k in range(3):
		floors.append(_make_floor())

	enemy = _make_sprite("ghost.png", Color(1, 0.3, 0.3), Vector2(ENEMY_SIZE, ENEMY_SIZE))
	stage.add_child(enemy)
	player = _make_sprite("pacman.png", Color(1, 0.9, 0.1), Vector2(PLAYER_SIZE, PLAYER_SIZE))
	stage.add_child(player)

	ghost_note = Control.new()
	ghost_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost_note.z_index = 2
	ghost_note.position = Vector2(4, 2)
	var g_icon := _make_sprite("ghost.png", Color(1, 0.3, 0.3), Vector2(22, 22))
	ghost_note.add_child(g_icon)
	ghost_note_label = Label.new()
	ghost_note_label.position = Vector2(26, 3)
	ghost_note_label.add_theme_font_size_override("font_size", 11)
	ghost_note_label.add_theme_color_override("font_outline_color", Color.BLACK)
	ghost_note_label.add_theme_constant_override("outline_size", 4)
	ghost_note.add_child(ghost_note_label)
	stage.add_child(ghost_note)

	toast_label = Label.new()
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_label.z_index = 2
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	toast_label.add_theme_font_size_override("font_size", 13)
	toast_label.add_theme_color_override("font_outline_color", Color.BLACK)
	toast_label.add_theme_constant_override("outline_size", 5)
	toast_label.modulate.a = 0.0
	stage.add_child(toast_label)

func _floor_h() -> float:
	return stage_h * 0.5

func _floor_line_y() -> float:
	return _floor_h() - LINE_MARGIN

func _player_y() -> float:
	return _floor_h() + _floor_line_y() - PLAYER_SIZE

func _layout_floors() -> void:
	var fh: float = _floor_h()
	var slot_w: float = stage_w / float(NUM_DOORS)
	var line_y: float = _floor_line_y()
	var torch_size := Vector2(22.0, 34.0)
	var railing_h := 22.0

	for idx in range(floors.size()):
		var f: Dictionary = floors[idx]
		var root: Control = f["root"]
		root.position = Vector2(0.0, float(idx) * fh)
		root.size = Vector2(stage_w, fh)

		var wall: Control = f["wall"]
		wall.position = Vector2.ZERO          # la pared cubre todo el piso, en mosaico
		wall.size = Vector2(stage_w, fh)

		var line: ColorRect = f["line"]
		line.position = Vector2(0.0, line_y)
		line.size = Vector2(stage_w, 3.0)

		var doors: Array = f["doors"]
		for i in range(NUM_DOORS):
			(doors[i] as Control).position = Vector2(
				slot_w * (float(i) + 0.5) - DOOR_SIZE.x * 0.5,
				line_y - DOOR_SIZE.y
			)

		var torches: Array = f["torches"]
		for i in range(torches.size()):
			# Entre puerta i e i+1
			var tx: float = slot_w * (float(i) + 1.0) - torch_size.x * 0.5
			var ty: float = line_y - DOOR_SIZE.y * 0.70 - torch_size.y * 0.5
			(torches[i] as Control).position = Vector2(tx, ty)
			(torches[i] as Control).size = torch_size

		var railing: TextureRect = f["railing"]
		railing.position = Vector2(0.0, line_y - railing_h * 0.45)
		railing.size = Vector2(stage_w, railing_h)

	(floors[0]["root"] as Control).modulate = Color(1, 1, 1, 0.45)
	(floors[1]["root"] as Control).modulate = Color.WHITE
	(floors[2]["root"] as Control).modulate = Color.WHITE

func _layout_stage() -> void:
	stage_w = maxf(stage.size.x, 100.0)
	stage_h = maxf(stage.size.y, 150.0)
	world.position = Vector2.ZERO
	_layout_floors()
	_layout_diagram_background()

	player.position.y = _player_y()
	player.position.x = clampf(player.position.x, 0.0, stage_w - PLAYER_SIZE)
	toast_label.position = Vector2(4, 2)
	toast_label.size = Vector2(stage_w - 8.0, 20.0)
	_refresh_ghost(false)


# ---------------------------------------------------------------------------
# Flujo principal (FN-01 ... FN-10)
# ---------------------------------------------------------------------------

func _on_difficulty_selected(diff: String) -> void:
	AudioManager.play_click()
	current_difficulty = diff
	var cfg: Dictionary = CONFIG.get(diff, CONFIG["NORMAL"])
	instr_diff_label.text = "Dificultad: %s" % cfg.get("name", diff)
	instr_desc_label.text = cfg.get("description", "")
	difficulty_selector.visible = false
	btn_back.visible = false
	if instructions_overlay:
		instructions_overlay.visible = true
	state = State.INSTRUCTIONS

func start_game(difficulty: String = "NORMAL") -> void:
	super.start_game(difficulty)
	run_id += 1
	state = State.PLAYING

	var cfg: Dictionary = CONFIG.get(difficulty, CONFIG["NORMAL"])
	if not _load_retos(difficulty):
		_show_difficulty_selector()
		return

	max_lives = int(cfg["lives"])
	current_lives = max_lives
	time_left = float(cfg["timer"])
	enemy_interval = float(cfg["enemy_interval"])
	enemy_timer = enemy_interval
	enemy_gap = int(cfg["start_gap"])
	enemy_slow_left = 0.0
	stun_left = 0.0
	move_dir_buttons = 0
	total_score = 0
	total_correct = 0
	mistakes = 0
	reto_index = 0
	floor_level = 1
	selected_door = -1
	ghost_mode = GhostMode.STATIC

	if instructions_overlay:
		instructions_overlay.visible = false
	difficulty_selector.visible = false
	if _menu_bg:
		_menu_bg.visible = false
	hud_row.visible = true
	question_panel.visible = true
	options_area.visible = true
	stage.visible = true
	controls.visible = true
	btn_back.visible = false
	btn_pause.visible = true
	game_over_overlay.visible = false
	pause_overlay.visible = false
	toast_label.modulate.a = 0.0

	player.modulate = Color.WHITE
	player.flip_h = false

	_update_lives_display()
	_update_score_ui()
	_update_timer_ui()

	# Esperar un frame para que el contenedor calcule el tamaño real del escenario
	var rid: int = run_id
	await get_tree().process_frame
	if rid != run_id or not is_inside_tree():
		return
	_layout_stage()
	player.position.x = stage_w * 0.5 - PLAYER_SIZE * 0.5

	EventBus.minigame_started.emit(minigame_id, current_difficulty)
	_next_reto()

func _build_flow_template() -> void:
	flow_template = create_flow_template({
		"title": "Mansión del Escape",
		"subtitle": "CU-14 · Diagramas de Venn",
		"classroom_path": AULA_SCENE,
		"objective": "Identifica el diagrama de Venn correcto antes de que se agote el tiempo o te alcance el fantasma.",
		"rules": [
			"Observa la operación de conjuntos que aparece arriba (A ∩ B, A ∪ B, etc.).",
			"Muévete con ◀ y ▶ hacia la puerta con el diagrama de Venn correcto y pulsa ENTRAR.",
			"Puerta correcta: desciendes un piso, sumas puntos y ralentizas al fantasma.",
			"Puerta incorrecta: pierdes 1 vida (-1 ❤️) y el fantasma avanza más rápido.",
			"¡Supera los 5 pisos antes de que se acabe el tiempo o te alcance!"
		],
		"difficulties": {
			"FACIL": {
				"name": "Fácil",
				"info": "Fácil: " + CONFIG["FACIL"]["description"]
			},
			"NORMAL": {
				"name": "Normal",
				"info": "Normal: " + CONFIG["NORMAL"]["description"]
			},
			"INGENIERO": {
				"name": "Ingeniero",
				"info": "Ingeniero: " + CONFIG["INGENIERO"]["description"]
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
			_on_go_retry_pressed()
	})


func _show_difficulty_selector() -> void:
	state = State.SELECTING
	if _menu_bg:
		_menu_bg.visible = false if flow_template else true
	difficulty_selector.visible = false if flow_template else true
	hud_row.visible = false
	question_panel.visible = false
	options_area.visible = false
	stage.visible = false
	controls.visible = false
	if instructions_overlay:
		instructions_overlay.visible = false
	if pause_overlay:
		pause_overlay.visible = false
	if game_over_overlay:
		game_over_overlay.visible = false
	btn_back.visible = false if flow_template else true
	btn_pause.visible = false
	if flow_template:
		flow_template.show_instructions()

## Baraja con la semilla propia (distinta en cada sesión)
func _shuffled(arr: Array) -> Array:
	var a: Array = arr.duplicate()
	for i in range(a.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp
	return a

func _load_retos(diff: String) -> bool:
	retos.clear()
	var path: String = DATA_DIR + "questions_%s.json" % diff.to_lower()
	if not FileAccess.file_exists(path):
		push_error("[MansionEscape] No se encontró el JSON: " + path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[MansionEscape] No se pudo abrir: " + path)
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Array) or (parsed as Array).is_empty():
		push_error("[MansionEscape] JSON inválido o vacío en: " + path)
		return false

	var pool: Array = []
	for item in (parsed as Array):
		if item is Dictionary and item.has("question") and item.has("correct"):
			pool.append(item)
		else:
			push_warning("[MansionEscape] Reto ignorado (faltan 'question'/'correct'): " + str(item))
	if pool.is_empty():
		return false

	pool = _shuffled(pool)
	# Dos sesiones seguidas no empiezan con el mismo reto
	if pool.size() > 1 and str(pool[0]["correct"]) == last_first_reto:
		var j: int = rng.randi_range(1, pool.size() - 1)
		var tmp = pool[0]
		pool[0] = pool[j]
		pool[j] = tmp
	retos = pool.slice(0, RETOS_TOTAL)
	last_first_reto = str(retos[0]["correct"])
	return true

## FN-02: muestra la operación y reparte las 5 imágenes en las 5 puertas
func _next_reto() -> void:
	var reto: Dictionary = retos[reto_index]
	var correct_file: String = str(reto["correct"])
	question_label.text = str(reto["question"])

	# Distractores: "<prefijo>_inc1.png", "_inc2.png"... Se eligen 4 al azar entre los que existan
	var prefix: String = correct_file.get_basename().trim_suffix("_correct")
	var found: Array = []
	var absent: Array = []
	for n in range(1, MAX_INCORRECT_FILES + 1):
		var f: String = "%s_inc%d.png" % [prefix, n]
		if ResourceLoader.exists(ASSET_DIR + f):
			found.append(f)
		else:
			absent.append(f)
	var incorrect: Array = _shuffled(found)
	while incorrect.size() < NUM_DOORS - 1 and not absent.is_empty():
		incorrect.append(absent.pop_front())      # archivo faltante: se mostrará el aviso "falta ..."
	incorrect = incorrect.slice(0, NUM_DOORS - 1)

	var all_files: Array = _shuffled([correct_file] + incorrect)
	# La correcta no cae dos veces seguidas en el mismo número de puerta
	var idx: int = all_files.find(correct_file)
	if idx == last_correct_door and all_files.size() > 1:
		var other: int = (idx + rng.randi_range(1, all_files.size() - 1)) % all_files.size()
		var tmp = all_files[idx]
		all_files[idx] = all_files[other]
		all_files[other] = tmp
	last_correct_door = all_files.find(correct_file)

	door_files.clear()
	for i in range(NUM_DOORS):
		var file_name: String = str(all_files[i])
		door_files.append(file_name)
		var slot: Dictionary = option_slots[i]
		var t: Texture2D = _tex(file_name)
		(slot["tex"] as TextureRect).texture = t
		var missing: Label = slot["missing"]
		missing.visible = (t == null)
		if t == null:
			missing.text = "falta\n" + file_name

	# El personaje reaparece al centro del piso actual
	player.position = Vector2(stage_w * 0.5 - PLAYER_SIZE * 0.5, _player_y())
	player.modulate = Color.WHITE
	selected_door = -1
	_update_selected_door()
	_apply_selection_colors()
	_update_score_ui()


# ---------------------------------------------------------------------------
# Movimiento y selección de puerta
# ---------------------------------------------------------------------------

func _release_move(dir: int) -> void:
	if move_dir_buttons == dir:
		move_dir_buttons = 0

func _move_player(delta: float) -> void:
	var dir: int = move_dir_buttons
	dir += int(signf(Input.get_axis("ui_left", "ui_right")))
	dir = clampi(dir, -1, 1)
	if dir != 0:
		player.position.x = clampf(player.position.x + float(dir) * PLAYER_SPEED * delta, 0.0, stage_w - PLAYER_SIZE)
		player.flip_h = dir < 0
	_update_selected_door()

func _update_selected_door() -> void:
	var cx: float = player.position.x + PLAYER_SIZE * 0.5
	var slot_w: float = stage_w / float(NUM_DOORS)
	var idx: int = clampi(int(cx / slot_w), 0, NUM_DOORS - 1)
	var door_cx: float = slot_w * (float(idx) + 0.5)
	var new_sel: int = idx if absf(cx - door_cx) <= DOOR_SIZE.x * 0.5 + 6.0 else -1
	if new_sel != selected_door:
		selected_door = new_sel
		_apply_selection_colors()

func _apply_selection_colors() -> void:
	var doors: Array = floors[1]["doors"]
	for i in range(NUM_DOORS):
		(option_slots[i]["panel"] as Control).modulate = _selection_color(i)
		(doors[i] as Control).modulate = _selection_color(i)

func _selection_color(i: int) -> Color:
	if selected_door == -1 or i == selected_door:
		return Color.WHITE
	return Color(0.7, 0.7, 0.7)

func _flash(node: CanvasItem, color: Color, idx: int) -> void:
	node.modulate = color
	var tw := create_tween()
	tw.tween_property(node, "modulate", _selection_color(idx), 0.5)


# ---------------------------------------------------------------------------
# Respuestas (FN-05 / FN-06 / FA-06.01)
# ---------------------------------------------------------------------------

func _on_enter_pressed() -> void:
	if state != State.PLAYING or stun_left > 0.0:
		return
	if selected_door < 0:
		AudioManager.play_error()
		_toast("Párate frente a una puerta")
		return
	# Validación por NOMBRE DE ARCHIVO: la imagen de la puerta elegida vs. la respuesta del JSON
	var chosen_file: String = door_files[selected_door]
	var correct_file: String = str(retos[reto_index]["correct"])
	if chosen_file == correct_file:
		_handle_correct()
	else:
		_handle_incorrect()

func _handle_correct() -> void:
	state = State.RESOLVING            # FN-06: el contador se detiene
	var rid: int = run_id
	var cfg: Dictionary = CONFIG[current_difficulty]
	AudioManager.play_success()

	var points: int = int(cfg["points"])
	total_score += points
	total_correct += 1
	reto_index += 1
	_toast("¡Correcto! +%d pts" % points)
	_update_score_ui()

	# El personaje entra por la puerta
	var doors: Array = floors[1]["doors"]
	_flash(doors[selected_door], Color(1.0, 0.95, 0.5), selected_door)
	var tw := create_tween()
	tw.tween_property(player, "modulate:a", 0.0, 0.3)

	await get_tree().create_timer(0.5, false).timeout
	if rid != run_id or not is_inside_tree() or state == State.ENDED:
		return

	if total_correct >= retos.size():   # FN-08
		_handle_win()
		return

	# El alumno baja un piso: la cámara se desplaza y el enemigo se ralentiza
	floor_level += 1
	enemy_gap += 1
	enemy_slow_left = ENEMY_SLOW_TIME
	var ok: bool = await _scroll_floors(rid)
	if not ok:
		return
	_next_reto()
	player.modulate.a = 0.0
	create_tween().tween_property(player, "modulate:a", 1.0, 0.25)
	state = State.PLAYING

## "Cámara con zoom": el piso actual sube y se queda visible (atenuado); aparece el siguiente abajo
func _scroll_floors(rid: int) -> bool:
	var fh: float = _floor_h()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(world, "position:y", -fh, SCROLL_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(floors[1]["root"], "modulate", Color(1, 1, 1, 0.45), SCROLL_TIME)
	if enemy.visible:                   # si estaba en el piso de arriba, se va con él
		if enemy_tween != null and enemy_tween.is_valid():
			enemy_tween.kill()
		tw.tween_property(enemy, "position:y", enemy.position.y - fh, SCROLL_TIME)
	await tw.finished
	if rid != run_id or not is_inside_tree():
		return false
	floors = [floors[1], floors[2], floors[0]]   # reasignar roles: arriba / actual / siguiente
	world.position = Vector2.ZERO
	_layout_floors()
	_refresh_ghost(false)
	return true

func _handle_incorrect() -> void:
	AudioManager.play_error()
	mistakes += 1
	var cfg: Dictionary = CONFIG[current_difficulty]
	total_score = maxi(0, total_score - int(cfg["penalty"]))
	_update_score_ui()
	if selected_door >= 0:
		_flash(option_slots[selected_door]["panel"], Color(1.0, 0.3, 0.3), selected_door)
	_apply_life_loss("Puerta equivocada")

## FA-06.01: -1 vida, enemigo se acelera, personaje inmovilizado. Vuelve al FN-05.
func _apply_life_loss(reason: String) -> void:
	current_lives = maxi(0, current_lives - 1)
	_update_lives_display()
	EventBus.life_lost.emit(current_lives)

	if current_lives <= 0:
		_handle_game_over("Te quedaste sin vidas")
		return

	# Se restan 5 s al contador interno; si ya era menor a 5, el descenso es instantáneo
	if enemy_timer < WRONG_ENEMY_PENALTY:
		_enemy_advance()
		if state != State.PLAYING:
			return
	else:
		enemy_timer -= WRONG_ENEMY_PENALTY

	stun_left = STUN_TIME
	_toast("%s (-1 vida)" % reason)

func _on_time_up() -> void:
	time_left = 0.0
	_update_timer_ui()
	_handle_game_over("¡Se acabó el tiempo!")


# ---------------------------------------------------------------------------
# Enemigo: sólo se ve si está en el piso de arriba; si no, sprite estático + nota
# ---------------------------------------------------------------------------

func _enemy_advance() -> void:
	enemy_gap -= 1
	enemy_timer = enemy_interval
	AudioManager.play_step()
	if enemy_gap <= 0:
		_enemy_catch()                  # FA-06.02: el enemigo alcanza al alumno
	else:
		_refresh_ghost(true)

func _refresh_ghost(animate: bool) -> void:
	var up_y: float = _floor_line_y() - ENEMY_SIZE     # suelo del piso de arriba
	if enemy_gap >= 2:
		ghost_mode = GhostMode.STATIC
		enemy.visible = false
		ghost_note.visible = true
		ghost_note_label.text = "A %d pisos arriba" % enemy_gap
		ghost_note_label.add_theme_color_override("font_color", Color(1, 0.55, 0.55) if enemy_gap == 2 else Color(1, 1, 1))
	else:
		# enemy_gap == 1: está en el piso de arriba, patrullando de izquierda a derecha
		var was_static: bool = (ghost_mode == GhostMode.STATIC)
		ghost_mode = GhostMode.PATROL
		ghost_note.visible = false
		enemy.visible = true
		if enemy_tween != null and enemy_tween.is_valid():
			enemy_tween.kill()
		if animate and was_static and is_inside_tree():
			# baja desde arriba hasta el piso visible
			enemy.position = Vector2(rng.randf_range(0.0, stage_w - ENEMY_SIZE), -ENEMY_SIZE)
			enemy_tween = create_tween()
			enemy_tween.tween_property(enemy, "position:y", up_y, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		else:
			enemy.position.y = up_y
			if was_static:
				enemy.position.x = rng.randf_range(0.0, stage_w - ENEMY_SIZE)

## El fantasma cae al piso del alumno y se acaba la partida
func _enemy_catch() -> void:
	state = State.RESOLVING
	var rid: int = run_id
	ghost_note.visible = false
	enemy.visible = true
	if enemy_tween != null and enemy_tween.is_valid():
		enemy_tween.kill()
	if ghost_mode == GhostMode.STATIC:
		enemy.position = Vector2(player.position.x, -ENEMY_SIZE)
	ghost_mode = GhostMode.PATROL
	var target := Vector2(clampf(player.position.x, 0.0, stage_w - ENEMY_SIZE), _player_y())
	enemy_tween = create_tween()
	enemy_tween.tween_property(enemy, "position", target, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await enemy_tween.finished
	if rid != run_id or not is_inside_tree():
		return
	_handle_game_over("¡El fantasma te alcanzó!")


# ---------------------------------------------------------------------------
# Resultados (FN-09 / FN-10) y Game Over
# ---------------------------------------------------------------------------

func _handle_win() -> void:
	state = State.ENDED
	move_dir_buttons = 0
	var stars: int = 1
	if current_lives * 2 >= max_lives:
		stars += 1
	if mistakes == 0:
		stars += 1
	go_title_label.text = "¡ESCAPASTE!"
	go_title_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	_show_results("Saliste de la mansión a salvo", stars, true)

func _handle_game_over(reason: String) -> void:
	state = State.ENDED
	move_dir_buttons = 0
	AudioManager.play_game_over()
	EventBus.game_over.emit(minigame_id)
	go_title_label.text = "¡JUEGO TERMINADO!"
	go_title_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	_show_results(reason, 0, false)

func _show_results(reason: String, stars: int, success: bool) -> void:
	var prev_high: int = StateManager.get_minigame_high_score(minigame_id) if StateManager else 0
	var is_record: bool = total_score > prev_high
	go_reason_label.text = reason
	go_stats_label.text = "Retos correctos: %d/%d\nPuntos Totales: %d\nEstrellas: %d" % [total_correct, retos.size(), total_score, stars]
	finish_game(success, total_score, stars, "Mansión del escape: %d retos correctos" % total_correct)
	if flow_template:
		if success:
			var total_accum: int = StateManager.get_points() if StateManager else total_score
			flow_template.show_victory(total_score, stars, total_accum, is_record, "¡ESCAPASTE DE LA MANSIÓN!")
		else:
			flow_template.show_game_over(reason, total_score)
		return
	game_over_overlay.visible = true


# ---------------------------------------------------------------------------
# UI helpers
# ---------------------------------------------------------------------------

func _update_timer_ui() -> void:
	if timer_label:
		var secs: int = ceili(maxf(0.0, time_left))
		timer_label.text = "⏱ %ds" % secs
		timer_label.modulate = Color(1.0, 0.3, 0.3) if secs <= 10 else Color.WHITE

func _update_lives_display() -> void:
	if lives_label:
		lives_label.text = "♥ x %d" % current_lives

func _update_score_ui() -> void:
	if progress_label:
		progress_label.text = "Piso %d/%d | %d pts" % [mini(floor_level, RETOS_TOTAL), RETOS_TOTAL, total_score]

## Mensaje breve que se desvanece (sustituye al banner de instrucciones de arriba)
func _toast(msg: String) -> void:
	if toast_label == null:
		return
	toast_label.text = msg
	toast_label.modulate.a = 1.0
	if toast_tween != null and toast_tween.is_valid():
		toast_tween.kill()
	toast_tween = create_tween()
	toast_tween.tween_interval(1.1)
	toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.5)

func _on_back_pressed() -> void:
	AudioManager.play_click()
	run_id += 1
	state = State.ENDED
	get_tree().paused = false
	if ResourceLoader.exists(AULA_SCENE):
		get_tree().change_scene_to_file(AULA_SCENE)
	else:
		get_tree().change_scene_to_file(LOBBY_SCENE)


# ---------------------------------------------------------------------------
# Sistema de Pausa (misma lógica que Derby de Bateo)
# ---------------------------------------------------------------------------

func _on_pause_pressed() -> void:
	if state != State.PLAYING:
		return
	AudioManager.play_click()
	move_dir_buttons = 0
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
	pause_overlay.visible = false
	get_tree().paused = false
	_on_back_pressed()

func _on_go_exit_pressed() -> void:
	_on_back_pressed()

## CU-14 FA-06.02: "reintentar" vuelve al FN-02 con la misma dificultad (sin repetir las instrucciones).
func _on_go_retry_pressed() -> void:
	AudioManager.play_click()
	game_over_overlay.visible = false
	if instructions_overlay:
		instructions_overlay.visible = false
	start_game(current_difficulty)
