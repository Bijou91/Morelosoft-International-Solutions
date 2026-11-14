## CinturonHipotesis.gd — Minijuego CU-15: Practicar a comprobar hipótesis de inducción
## En este minijuego, el alumno pilota una nave espacial para esquivar asteroides que
## anulan la hipótesis (obstáculos) y disparar al asteroide único que contiene el paso lógico
## correcto en orden secuencial de la inducción matemática.
## Cumple con la Especificación CU-15 y su Diagrama de Secuencia.
extends MiniGameBase

# ══════════════════════════════════════════════════════════════════════════════
# FONDO ESTRELLADO DINÁMICO
# ══════════════════════════════════════════════════════════════════════════════

## Estrellas (cuadritos pixel-art) con posición, velocidad, tamaño, parpadeo y deriva
## lateral aleatorios. Caen despacio (como si la nave avanzara) y se reciclan al salir.
class StarField extends Control:
	const STAR_COUNT: int = 90
	const SPEED_MIN: float = 8.0     # estrellas lejanas (pequeñas y lentas)
	const SPEED_MAX: float = 60.0    # estrellas cercanas (grandes y rápidas)
	const DRIFT_MAX: float = 7.0     # deriva lateral máxima (px/s)

	var running: bool = true         # false = estrellas congeladas (p. ej. en pausa)
	var _stars: Array = []
	var _rng := RandomNumberGenerator.new()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true

	func _ready() -> void:
		_rng.randomize()
		resized.connect(_regenerate)
		_regenerate()

	func _regenerate() -> void:
		if size.x <= 1.0 or size.y <= 1.0:
			return
		_stars.clear()
		for i in range(STAR_COUNT):
			_stars.append(_new_star(true))

	func _new_star(anywhere: bool) -> Dictionary:
		var depth: float = _rng.randf()   # 0 = lejana, 1 = cercana
		var tint: float = _rng.randf()
		var col := Color(1.0, 1.0, 1.0)
		if tint > 0.80:
			col = Color(0.65, 0.80, 1.0)      # azulada
		elif tint > 0.65:
			col = Color(1.0, 0.92, 0.70)      # amarillenta
		return {
			"pos": Vector2(_rng.randf_range(0.0, size.x), _rng.randf_range(0.0, size.y) if anywhere else -4.0),
			"speed": lerpf(SPEED_MIN, SPEED_MAX, depth) * _rng.randf_range(0.8, 1.2),
			"size": 1.0 if depth < 0.6 else (2.0 if depth < 0.9 else 3.0),
			"drift": _rng.randf_range(-DRIFT_MAX, DRIFT_MAX),
			"drift_target": _rng.randf_range(-DRIFT_MAX, DRIFT_MAX),
			"drift_timer": _rng.randf_range(1.0, 4.0),
			"phase": _rng.randf_range(0.0, TAU),
			"twinkle": _rng.randf_range(1.0, 4.0),
			"color": col,
		}

	func _process(delta: float) -> void:
		if not running or _stars.is_empty():
			return
		for i in range(_stars.size()):
			var st: Dictionary = _stars[i]
			# Deriva lateral: cambia de objetivo al azar cada cierto tiempo y se suaviza
			st["drift_timer"] = float(st["drift_timer"]) - delta
			if float(st["drift_timer"]) <= 0.0:
				st["drift_target"] = _rng.randf_range(-DRIFT_MAX, DRIFT_MAX)
				st["drift_timer"] = _rng.randf_range(1.0, 4.0)
			st["drift"] = lerpf(float(st["drift"]), float(st["drift_target"]), minf(1.0, delta * 0.8))

			var pos: Vector2 = st["pos"]
			pos.y += float(st["speed"]) * delta
			pos.x += float(st["drift"]) * delta
			st["phase"] = float(st["phase"]) + float(st["twinkle"]) * delta

			if pos.y > size.y + 4.0:
				# Sale por abajo: reaparece arriba como una estrella nueva (valores al azar)
				_stars[i] = _new_star(false)
				continue
			pos.x = wrapf(pos.x, 0.0, size.x)
			st["pos"] = pos
		queue_redraw()

	func _draw() -> void:
		for st in _stars:
			var tw: float = 0.5 + 0.5 * sin(float(st["phase"]))
			var c: Color = st["color"]
			c.a = 0.30 + 0.70 * tw
			var sz: float = float(st["size"])
			draw_rect(Rect2((st["pos"] as Vector2).floor(), Vector2(sz, sz)), c)

# ══════════════════════════════════════════════════════════════════════════════
# CONSTANTES
# ══════════════════════════════════════════════════════════════════════════════

const DATA_PATHS: Dictionary = {
	"FACIL": "res://scenes/minigames/logica/cinturon_hipotesis/data/questions_facil.json",
	"NORMAL": "res://scenes/minigames/logica/cinturon_hipotesis/data/questions_normal.json",
	"INGENIERO": "res://scenes/minigames/logica/cinturon_hipotesis/data/questions_ingeniero.json"
}

const CLASSROOM_SCENE: String = "res://scenes/classroom/AulaLogica.tscn"

# Rutas de efectos de sonido
const SFX_DISPARO_PATH: String = "res://assets/logica/cinturon_hipotesis/sfx/disparo.wav"
const SFX_VIDA_MENOS_PATH: String = "res://assets/logica/cinturon_hipotesis/sfx/vidaMenos.wav"
const SFX_EXPLOSION_PATH: String = "res://assets/logica/cinturon_hipotesis/sfx/explosion.wav"
const SFX_CORRECTO_PATH: String = "res://assets/logica/cinturon_hipotesis/sfx/correcto.wav"

# Sprites y texturas (van directo en assets/logica/cinturon_hipotesis/)
const TEX_SHIP_PATH: String = "res://assets/logica/cinturon_hipotesis/nave_galaga.png"
const TEX_AST_CORRECT_PATH: String = "res://assets/logica/cinturon_hipotesis/textura_terreno_verde.png"
const TEX_AST_WRONG_PATH: String = "res://assets/logica/cinturon_hipotesis/textura_terreno_rojo.png"
const SHIP_DRAW_SIZE: Vector2 = Vector2(30, 32)   # tamaño en pantalla de la nave (la imagen es una cuadrícula de 15x16)
const AST_TEX_TILE_PX: float = 128.0              # tamaño en pantalla de UN mosaico de textura (256 px de origen -> 2 px por "pixel" del arte)
const AST_BORDER_CORRECT: Color = Color(0.45, 0.85, 0.50)
const AST_BORDER_WRONG: Color = Color(1.0, 0.55, 0.35)

var ship_texture: Texture2D
var ast_tex_correct: Texture2D
var ast_tex_wrong: Texture2D

var sfx_disparo_stream: AudioStream
var sfx_vida_menos_stream: AudioStream
var sfx_explosion_stream: AudioStream
var sfx_correcto_stream: AudioStream

var sfx_player: AudioStreamPlayer

const DIFFICULTY_CONFIG: Dictionary = {
	"FACIL": {
		"name": "FÁCIL",
		"lives": 5,
		"time": 60.0,
		"score_per_hit": 50,
		"steps_count": 3,
		"correct_size": Vector2(175, 75),
		"incorrect_size": Vector2(130, 55),
		"speed_min": 45.0,
		"speed_max": 70.0,
		"description": "5 vidas, 60s, 50 pts/acierto. Asteroides correctos más grandes y errores pequeños."
	},
	"NORMAL": {
		"name": "NORMAL",
		"lives": 3,
		"time": 75.0,
		"score_per_hit": 100,
		"steps_count": 4,
		"correct_size": Vector2(150, 65),
		"incorrect_size": Vector2(150, 65),
		"speed_min": 60.0,
		"speed_max": 95.0,
		"description": "3 vidas, 75s, 100 pts/acierto. Mismo tamaño para ambos tipos de asteroides."
	},
	"INGENIERO": {
		"name": "INGENIERO",
		"lives": 2,
		"time": 90.0,
		"score_per_hit": 200,
		"steps_count": 5,
		"correct_size": Vector2(130, 55),
		"incorrect_size": Vector2(175, 75),
		"speed_min": 80.0,
		"speed_max": 125.0,
		"description": "2 vidas, 90s, 200 pts/acierto. Asteroides correctos más pequeños y errores grandes."
	}
}

# ══════════════════════════════════════════════════════════════════════════════
# ESTADO DEL JUEGO
# ══════════════════════════════════════════════════════════════════════════════

var current_state: String = "DIFFICULTY_SELECT" # INSTRUCTIONS, PLAYING, PAUSED, GAME_OVER, VICTORY
var lives: int = 3
var max_lives: int = 3
var score: int = 0
var time_remaining: float = 75.0
var total_time: float = 75.0

var exercises: Array = []
var current_exercise: Dictionary = {}
var current_step_index: int = 0
var total_steps: int = 3

# Elementos del juego dinámico
var ship_pos: Vector2 = Vector2.ZERO
var ship_speed: float = 240.0
var move_dir: Vector2 = Vector2.ZERO
var is_invulnerable: bool = false
var invulnerable_timer: float = 0.0

# Almacén de entidades
var bullets: Array = [] # { pos: Vector2, speed: float, active: bool }
var asteroids: Array = [] # { pos: Vector2, vel: Vector2, text: String, is_correct: bool, step_idx: int, size: Vector2, active: bool }
var spawn_timer: float = 0.0
var spawn_interval: float = 2.2

# Controles táctiles
var touch_left: bool = false
var touch_right: bool = false
var touch_up: bool = false
var touch_down: bool = false

# Advertencia visual (Flash rojo al disparar a asteroide incorrecto)
var warning_flash_alpha: float = 0.0

# ══════════════════════════════════════════════════════════════════════════════
# NODOS UI
# ══════════════════════════════════════════════════════════════════════════════

var hud_lives_label: Label
var hud_timer_label: Label
var hud_score_label: Label
var hud_step_progress_label: Label
var hud_step_badges_container: HBoxContainer
var hypothesis_title_label: Label

var game_area: Control
var star_field: StarField
var warning_overlay: ColorRect

# Overlays
var difficulty_overlay: ColorRect
var instructions_overlay: ColorRect
var pause_overlay: ColorRect
var game_over_overlay: ColorRect
var victory_overlay: ColorRect

var instr_diff_label: Label
var instr_desc_label: Label
var go_title_label: Label
var go_reason_label: Label
var go_score_label: Label
var vic_score_label: Label
var vic_stats_label: Label
var flow_template: Control

# ══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	super._ready()
	minigame_id = "cinturon_hipotesis"
	cu_id = "CU-15"
	minigame_title = "Cinturón de Hipótesis: Inducción Matemática"
	subject_name = "Lógica y Algoritmos"

	_init_audio()
	_init_textures()
	_build_ui()
	_build_flow_template()
	_show_overlay("INSTRUCTIONS")

func _init_audio() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "HypothesisSFXPlayer"
	add_child(sfx_player)

	if ResourceLoader.exists(SFX_DISPARO_PATH):
		sfx_disparo_stream = load(SFX_DISPARO_PATH)
	if ResourceLoader.exists(SFX_VIDA_MENOS_PATH):
		sfx_vida_menos_stream = load(SFX_VIDA_MENOS_PATH)
	if ResourceLoader.exists(SFX_EXPLOSION_PATH):
		sfx_explosion_stream = load(SFX_EXPLOSION_PATH)
	if ResourceLoader.exists(SFX_CORRECTO_PATH):
		sfx_correcto_stream = load(SFX_CORRECTO_PATH)

func _init_textures() -> void:
	ship_texture = _load_texture(TEX_SHIP_PATH)
	ast_tex_correct = _load_texture(TEX_AST_CORRECT_PATH)
	ast_tex_wrong = _load_texture(TEX_AST_WRONG_PATH)

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	push_warning("[CinturonHipotesis] No se encontró la textura: " + path + " (abre el proyecto en el editor para importarla). Se usa el dibujo por defecto.")
	return null

func _play_sfx(stream: AudioStream) -> void:
	if not stream or not sfx_player:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _process(delta: float) -> void:
	if current_state != "PLAYING":
		return

	# 1. Temporizador de juego
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_update_hud()
		_on_timeout()
		return
	_update_hud()

	# 2. Invulnerabilidad temporal
	if is_invulnerable:
		invulnerable_timer -= delta
		if invulnerable_timer <= 0.0:
			is_invulnerable = false

	# 3. Warning flash fade
	if warning_flash_alpha > 0.0:
		warning_flash_alpha = max(0.0, warning_flash_alpha - delta * 3.0)
		if warning_overlay:
			warning_overlay.color = Color(1.0, 0.1, 0.1, warning_flash_alpha * 0.35)

	# 4. Movimiento de nave
	_process_player_movement(delta)

	# 5. Spawning de asteroides
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_asteroid_wave()

	# 6. Actualización de balas
	_update_bullets(delta)

	# 7. Actualización de asteroides y colisiones
	_update_asteroids(delta)

	# Redibujar escenario
	if game_area:
		game_area.queue_redraw()

# ══════════════════════════════════════════════════════════════════════════════
# CONSTRUCCIÓN DE INTERFAZ (UI PROCEDURAL COMPATIBLE)
# ══════════════════════════════════════════════════════════════════════════════

func _build_ui() -> void:
	set_anchors_preset(PRESET_FULL_RECT)

	# Fondo espacial: negro puro con estrellas dinámicas (detrás de la nave)
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.0, 0.0, 0.0, 1.0)
	add_child(bg)

	star_field = StarField.new()
	star_field.name = "StarField"
	star_field.set_anchors_preset(PRESET_FULL_RECT)
	add_child(star_field)

	# Área de juego interactiva (Dibuja estrellas, nave, disparos y asteroides)
	game_area = Control.new()
	game_area.set_anchors_preset(PRESET_FULL_RECT)
	game_area.draw.connect(_on_game_area_draw)
	add_child(game_area)

	# Overlay de advertencia / impacto
	warning_overlay = ColorRect.new()
	warning_overlay.set_anchors_preset(PRESET_FULL_RECT)
	warning_overlay.mouse_filter = MOUSE_FILTER_IGNORE
	warning_overlay.color = Color(1, 0, 0, 0)
	add_child(warning_overlay)

	# Contenedor superior (HUD)
	var top_hud := PanelContainer.new()
	top_hud.anchor_left = 0.0
	top_hud.anchor_top = 0.0
	top_hud.anchor_right = 1.0
	top_hud.offset_bottom = 125.0
	top_hud.clip_contents = true
	var hud_sb := StyleBoxFlat.new()
	hud_sb.bg_color = Color(0.08, 0.10, 0.16, 0.88)
	hud_sb.border_width_bottom = 2
	hud_sb.border_color = Color(0.2, 0.4, 0.7, 0.7)
	top_hud.add_theme_stylebox_override("panel", hud_sb)
	add_child(top_hud)

	var hud_margin := MarginContainer.new()
	hud_margin.add_theme_constant_override("margin_left", 8)
	hud_margin.add_theme_constant_override("margin_right", 8)
	hud_margin.add_theme_constant_override("margin_top", 6)
	hud_margin.add_theme_constant_override("margin_bottom", 6)
	top_hud.add_child(hud_margin)

	var hud_vbox := VBoxContainer.new()
	hud_vbox.add_theme_constant_override("separation", 4)
	hud_margin.add_child(hud_vbox)

	# Fila 1 del HUD: Pausa | Vidas | Tiempo | Puntos
	var top_row := HBoxContainer.new()
	hud_vbox.add_child(top_row)

	var pause_btn := Button.new()
	pause_btn.text = "||"
	pause_btn.custom_minimum_size = Vector2(36, 30)
	style_kenney_button(pause_btn, "neutral", 30.0)
	pause_btn.add_theme_font_size_override("font_size", 11)
	pause_btn.pressed.connect(_on_pause_button_pressed)
	top_row.add_child(pause_btn)

	hud_lives_label = Label.new()
	hud_lives_label.text = " ❤️ x3"
	hud_lives_label.add_theme_font_size_override("font_size", 15)
	hud_lives_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.4))
	top_row.add_child(hud_lives_label)
	stabilize_hud_label(hud_lives_label, 52.0)

	var spacer1 := Control.new()
	spacer1.size_flags_horizontal = SIZE_EXPAND_FILL
	top_row.add_child(spacer1)

	hud_timer_label = Label.new()
	hud_timer_label.text = "⏱ 01:15"
	hud_timer_label.add_theme_font_size_override("font_size", 16)
	hud_timer_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	top_row.add_child(hud_timer_label)
	stabilize_hud_label(hud_timer_label, 72.0)

	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = SIZE_EXPAND_FILL
	top_row.add_child(spacer2)

	hud_score_label = Label.new()
	hud_score_label.text = "⭐ 0"
	hud_score_label.add_theme_font_size_override("font_size", 15)
	hud_score_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	top_row.add_child(hud_score_label)
	stabilize_hud_label(hud_score_label, 58.0)

	# Fila 2 del HUD: Progreso de pasos (ej: 1/3) y Badges de pasos con resplandor
	var steps_row := HBoxContainer.new()
	steps_row.add_theme_constant_override("separation", 6)
	hud_vbox.add_child(steps_row)

	hud_step_progress_label = Label.new()
	hud_step_progress_label.text = "1/3"
	hud_step_progress_label.add_theme_font_size_override("font_size", 13)
	hud_step_progress_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	steps_row.add_child(hud_step_progress_label)

	hud_step_badges_container = HBoxContainer.new()
	hud_step_badges_container.size_flags_horizontal = SIZE_EXPAND_FILL
	hud_step_badges_container.add_theme_constant_override("separation", 4)
	steps_row.add_child(hud_step_badges_container)

	# Fila 3 del HUD: Título de la Hipótesis actual
	hypothesis_title_label = Label.new()
	hypothesis_title_label.text = "Cargando hipótesis..."
	hypothesis_title_label.size_flags_horizontal = SIZE_EXPAND_FILL
	hypothesis_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hypothesis_title_label.add_theme_font_size_override("font_size", 11)
	hypothesis_title_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
	hud_vbox.add_child(hypothesis_title_label)
	lock_dynamic_label_box(hypothesis_title_label, null, 38.0, 11, 7, 2.0, 0.0, true, false)

	# Panel de Controles Virtuales Móviles (inferior)
	_build_mobile_controls()

	# Creación de Overlays (Dificultad, Instrucciones, Pausa, Game Over, Victoria)
	_build_overlays()

func _build_mobile_controls() -> void:
	var controls_panel := PanelContainer.new()
	controls_panel.anchor_left = 0.0
	controls_panel.anchor_top = 1.0
	controls_panel.anchor_right = 1.0
	controls_panel.anchor_bottom = 1.0
	controls_panel.offset_top = -120.0
	var c_sb := StyleBoxFlat.new()
	c_sb.bg_color = Color(0.06, 0.08, 0.12, 0.70)
	c_sb.border_width_top = 1
	c_sb.border_color = Color(0.2, 0.3, 0.5, 0.5)
	controls_panel.add_theme_stylebox_override("panel", c_sb)
	add_child(controls_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	controls_panel.add_child(margin)

	var hbox := HBoxContainer.new()
	margin.add_child(hbox)

	# D-Pad en Grid
	var dpad_grid := GridContainer.new()
	dpad_grid.columns = 3
	dpad_grid.add_theme_constant_override("h_separation", 4)
	dpad_grid.add_theme_constant_override("v_separation", 4)
	hbox.add_child(dpad_grid)

	# Fila 1: [Vacio, Arriba, Vacio]
	dpad_grid.add_child(Control.new())
	var btn_up := _create_arrow_btn("▲", func(p): touch_up = p)
	dpad_grid.add_child(btn_up)
	dpad_grid.add_child(Control.new())

	# Fila 2: [Izq, Abajo, Der]
	var btn_left := _create_arrow_btn("◀", func(p): touch_left = p)
	dpad_grid.add_child(btn_left)
	var btn_down := _create_arrow_btn("▼", func(p): touch_down = p)
	dpad_grid.add_child(btn_down)
	var btn_right := _create_arrow_btn("▶", func(p): touch_right = p)
	dpad_grid.add_child(btn_right)

	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	# Botón Disparar / Acción
	var btn_shoot := Button.new()
	btn_shoot.text = "DISPARAR\n🔥"
	btn_shoot.custom_minimum_size = Vector2(100, 75)
	var shoot_sb := StyleBoxFlat.new()
	shoot_sb.bg_color = Color(0.75, 0.2, 0.25, 0.9)
	shoot_sb.set_corner_radius_all(8)
	shoot_sb.set_border_width_all(2)
	shoot_sb.border_color = Color(1.0, 0.6, 0.6)
	btn_shoot.add_theme_stylebox_override("normal", shoot_sb)
	btn_shoot.pressed.connect(_on_shoot_pressed)
	hbox.add_child(btn_shoot)

func _create_arrow_btn(label: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(34, 32)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.22, 0.32, 0.85)
	sb.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sb)
	btn.button_down.connect(func(): callback.call(true))
	btn.button_up.connect(func(): callback.call(false))
	return btn

# ══════════════════════════════════════════════════════════════════════════════
# CONSTRUCCIÓN DE MODALES Y OVERLAYS
# ══════════════════════════════════════════════════════════════════════════════

func _build_overlays() -> void:
	# 1. Overlay Selección de Dificultad
	difficulty_overlay = _create_overlay()
	add_child(difficulty_overlay)
	var d_vbox := _create_overlay_vbox(difficulty_overlay, "CINTURÓN DE HIPÓTESIS", "Lógica y Algoritmos (CU-15)")

	var d_desc := Label.new()
	d_desc.text = "Comprueba hipótesis de inducción matemática navegando en el cinturón de asteroides.\nSelecciona tu dificultad:"
	d_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d_desc.add_theme_font_size_override("font_size", 12)
	d_vbox.add_child(d_desc)

	for diff_key in ["FACIL", "NORMAL", "INGENIERO"]:
		var cfg: Dictionary = DIFFICULTY_CONFIG[diff_key]
		var btn := Button.new()
		btn.text = "%s (%s pasos - %ds)" % [cfg["name"], cfg["steps_count"], cfg["time"]]
		btn.custom_minimum_size = Vector2(250, 42)
		btn.pressed.connect(func(): _on_difficulty_chosen(diff_key))
		d_vbox.add_child(btn)

	var d_back_btn := Button.new()
	d_back_btn.text = "Volver al Aula de Lógica"
	d_back_btn.custom_minimum_size = Vector2(250, 36)
	d_back_btn.pressed.connect(_on_return_to_classroom)
	d_vbox.add_child(d_back_btn)

	# 2. Overlay Instrucciones del Caso de Uso
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
	instr_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instr_desc_label.add_theme_font_size_override("font_size", 12)
	i_vbox.add_child(instr_desc_label)

	var rules_label := Label.new()
	rules_label.text = "• Pilota tu nave esquivando asteroides (Chocar = -1 Vida).\n• Dispara únicamente al asteroide con el paso lógico correcto en orden secuencial (+Puntos).\n• Disparar a un asteroide incorrecto o fuera de turno = -1 Vida.\n• Completa todos los pasos antes de que acabe el tiempo."
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

	# 3. Overlay de Pausa (FA-03.01)
	pause_overlay = _create_overlay()
	add_child(pause_overlay)
	var p_vbox := _create_overlay_vbox(pause_overlay, "JUEGO PAUSADO", "Tiempo congelado")

	var resume_btn := Button.new()
	resume_btn.text = "Reanudar Partida"
	resume_btn.custom_minimum_size = Vector2(220, 40)
	resume_btn.pressed.connect(_on_resume_pressed)
	p_vbox.add_child(resume_btn)

	var p_exit_btn := Button.new()
	p_exit_btn.text = "Salir al Aula"
	p_exit_btn.custom_minimum_size = Vector2(220, 36)
	p_exit_btn.pressed.connect(_on_return_to_classroom)
	p_vbox.add_child(p_exit_btn)

	# 4. Overlay Game Over (FA-03.04 y FA-03.05)
	game_over_overlay = _create_overlay()
	add_child(game_over_overlay)
	var go_vbox := _create_overlay_vbox(game_over_overlay, "GAME OVER", "")
	go_title_label = go_vbox.get_child(0) as Label

	go_reason_label = Label.new()
	go_reason_label.text = "Se han agotado tus vidas."
	go_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	go_reason_label.add_theme_font_size_override("font_size", 13)
	go_vbox.add_child(go_reason_label)

	go_score_label = Label.new()
	go_score_label.text = "Puntaje final: 0"
	go_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_score_label.add_theme_font_size_override("font_size", 15)
	go_score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	go_vbox.add_child(go_score_label)

	var retry_btn := Button.new()
	retry_btn.text = "Reintentar"
	retry_btn.custom_minimum_size = Vector2(220, 40)
	retry_btn.pressed.connect(_on_retry_pressed)
	go_vbox.add_child(retry_btn)

	var go_exit_btn := Button.new()
	go_exit_btn.text = "Volver al Aula"
	go_exit_btn.custom_minimum_size = Vector2(220, 36)
	go_exit_btn.pressed.connect(_on_return_to_classroom)
	go_vbox.add_child(go_exit_btn)

	# 5. Overlay Victoria (FN-06)
	victory_overlay = _create_overlay()
	add_child(victory_overlay)
	var vic_vbox := _create_overlay_vbox(victory_overlay, "¡HIPÓTESIS COMPROBADA!", "¡Victoria!")

	vic_score_label = Label.new()
	vic_score_label.text = "Puntaje acumulado: 0 pts"
	vic_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vic_score_label.add_theme_font_size_override("font_size", 16)
	vic_score_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
	vic_vbox.add_child(vic_score_label)

	vic_stats_label = Label.new()
	vic_stats_label.text = "Completaste exitosamente todos los pasos lógicos."
	vic_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vic_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vic_stats_label.add_theme_font_size_override("font_size", 12)
	vic_vbox.add_child(vic_stats_label)

	var v_retry_btn := Button.new()
	v_retry_btn.text = "Jugar de Nuevo"
	v_retry_btn.custom_minimum_size = Vector2(220, 40)
	v_retry_btn.pressed.connect(_on_retry_pressed)
	vic_vbox.add_child(v_retry_btn)

	var v_exit_btn := Button.new()
	v_exit_btn.text = "Volver al Aula"
	v_exit_btn.custom_minimum_size = Vector2(220, 36)
	v_exit_btn.pressed.connect(_on_return_to_classroom)
	vic_vbox.add_child(v_exit_btn)

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

func _build_flow_template() -> void:
	flow_template = create_flow_template({
		"title": "Cinturón de Hipótesis",
		"subtitle": "Lógica y Algoritmos (CU-15)",
		"classroom_path": CLASSROOM_SCENE,
		"objective": "Comprueba hipótesis de inducción matemática navegando en el cinturón de asteroides.",
		"rules": [
			"Pilota tu nave esquivando asteroides (Chocar = -1 Vida).",
			"Dispara únicamente al asteroide con el paso lógico correcto en orden secuencial (+Puntos).",
			"Disparar a un asteroide incorrecto o fuera de turno = -1 Vida.",
			"Completa todos los pasos antes de que acabe el tiempo."
		],
		"difficulties": {
			"FACIL": {
				"name": "Fácil",
				"info": "Fácil (3 pasos - 60s)\n" + DIFFICULTY_CONFIG["FACIL"]["description"]
			},
			"NORMAL": {
				"name": "Normal",
				"info": "Normal (4 pasos - 75s)\n" + DIFFICULTY_CONFIG["NORMAL"]["description"]
			},
			"INGENIERO": {
				"name": "Ingeniero",
				"info": "Ingeniero (5 pasos - 90s)\n" + DIFFICULTY_CONFIG["INGENIERO"]["description"]
			}
		},
		"default_difficulty": "NORMAL",
		"on_start": func(diff: String):
			current_difficulty = diff
			super.start_game(diff)
			_on_start_game_pressed(),
		"on_back": func():
			_on_return_to_classroom(),
		"on_resume": func():
			_on_resume_pressed(),
		"on_restart": func():
			_on_retry_pressed()
	})


func _show_overlay(state_name: String) -> void:
	current_state = state_name
	if star_field:
		star_field.running = (state_name != "PAUSED")   # las estrellas se congelan solo en pausa
	if flow_template:
		difficulty_overlay.visible = false
		instructions_overlay.visible = false
		pause_overlay.visible = false
		game_over_overlay.visible = false
		victory_overlay.visible = false
		match state_name:
			"DIFFICULTY_SELECT", "INSTRUCTIONS":
				flow_template.show_instructions()
			"PAUSED":
				flow_template.show_pause()
			"PLAYING":
				flow_template.hide_all()
		return
	difficulty_overlay.visible = (state_name == "DIFFICULTY_SELECT")
	instructions_overlay.visible = (state_name == "INSTRUCTIONS")
	pause_overlay.visible = (state_name == "PAUSED")
	game_over_overlay.visible = (state_name == "GAME_OVER")
	victory_overlay.visible = (state_name == "VICTORY")

# ══════════════════════════════════════════════════════════════════════════════
# FLUJO DEL JUEGO
# ══════════════════════════════════════════════════════════════════════════════

func _on_difficulty_chosen(diff: String) -> void:
	current_difficulty = diff
	var cfg: Dictionary = DIFFICULTY_CONFIG[diff]
	instr_diff_label.text = "Dificultad: %s" % cfg["name"]
	instr_desc_label.text = cfg["description"]
	_show_overlay("INSTRUCTIONS")

func _on_start_game_pressed() -> void:
	_load_questions_for_difficulty(current_difficulty)
	_setup_match()
	_show_overlay("PLAYING")

func _setup_match() -> void:
	var cfg: Dictionary = DIFFICULTY_CONFIG[current_difficulty]
	max_lives = cfg["lives"]
	lives = max_lives
	total_time = cfg["time"]
	time_remaining = total_time
	score = 0
	total_steps = cfg["steps_count"]
	current_step_index = 0

	# Seleccionar ejercicio aleatorio
	if exercises.is_empty():
		_generate_default_exercise()
	else:
		exercises.shuffle()
		current_exercise = exercises[0]

	# Centrar nave (360 x 640 área, zona de juego encima de los controles)
	var viewport_sz := get_viewport_rect().size
	ship_pos = Vector2(viewport_sz.x * 0.5, viewport_sz.y - 170.0)

	bullets.clear()
	asteroids.clear()
	spawn_timer = 0.0

	_refresh_step_badges()
	_update_hud()

func _generate_default_exercise() -> void:
	current_exercise = {
		"id": "DEF-01",
		"hypothesis": "Demostrar que 1 + 2 + ... + n = n(n+1)/2",
		"steps": [
			"Paso 1: Probar caso base n = 1: 1 = 1(2)/2 = 1",
			"Paso 2: Asumir hipótesis para n = k: 1+...+k = k(k+1)/2",
			"Paso 3: Probar para k+1: k(k+1)/2 + (k+1) = (k+1)(k+2)/2"
		],
		"distractors": [
			"Probar caso base en n = 0 y afirmar que 0/0 es indeterminado",
			"Asumir P(k+1) para deducir P(k)",
			"Restar k+1 en vez de sumarlo a la hipótesis"
		]
	}

func _load_questions_for_difficulty(diff: String) -> void:
	var path: String = DATA_PATHS.get(diff, "")
	exercises.clear()
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		var json_text := file.get_as_text()
		var parsed = JSON.parse_string(json_text)
		if parsed is Array:
			exercises = parsed

# ══════════════════════════════════════════════════════════════════════════════
# CONTROL DE LA NAVE Y ENTRADAS
# ══════════════════════════════════════════════════════════════════════════════

func _process_player_movement(delta: float) -> void:
	move_dir = Vector2.ZERO
	# Teclado / gamepad
	if Input.is_action_pressed("ui_left") or touch_left:
		move_dir.x -= 1.0
	if Input.is_action_pressed("ui_right") or touch_right:
		move_dir.x += 1.0
	if Input.is_action_pressed("ui_up") or touch_up:
		move_dir.y -= 1.0
	if Input.is_action_pressed("ui_down") or touch_down:
		move_dir.y += 1.0

	if move_dir.length_squared() > 0.0:
		move_dir = move_dir.normalized()
		ship_pos += move_dir * ship_speed * delta

	# Límites de la pantalla (permite a la nave salir la mitad de su cuerpo por los costados para esquivar)
	var vp := get_viewport_rect().size
	ship_pos.x = clamp(ship_pos.x, 0.0, vp.x)
	ship_pos.y = clamp(ship_pos.y, 140.0, vp.y - 140.0)

func _unhandled_input(event: InputEvent) -> void:
	if current_state != "PLAYING":
		return
	if event.is_action_pressed("ui_accept"):
		_on_shoot_pressed()

func _on_shoot_pressed() -> void:
	if current_state != "PLAYING":
		return
	# Disparar proyectil desde la punta de la nave
	bullets.append({
		"pos": ship_pos + Vector2(0, -18),
		"speed": 400.0,
		"active": true
	})
	_play_sfx(sfx_disparo_stream)

# ══════════════════════════════════════════════════════════════════════════════
# SPAWN Y MOVIMIENTO DE ASTEROIDES (FN-02)
# ══════════════════════════════════════════════════════════════════════════════

func _spawn_asteroid_wave() -> void:
	if current_exercise.is_empty():
		return

	var vp := get_viewport_rect().size
	var cfg: Dictionary = DIFFICULTY_CONFIG[current_difficulty]
	var steps: Array = current_exercise.get("steps", [])
	var distractors: Array = current_exercise.get("distractors", [])

	# Contar entidades activas en la pantalla útil (área donde nave y asteroides interactúan)
	var active_in_screen: int = 0
	var has_correct_on_screen: bool = false
	for a in asteroids:
		if a["active"] and a["pos"].y < vp.y - 120.0:
			active_in_screen += 1
			if a["is_correct"]:
				has_correct_on_screen = true

	# Control estricto: Nunca permitir más de 10 entidades en pantalla útil
	const MAX_ENTITIES_ON_SCREEN: int = 10
	if active_in_screen >= MAX_ENTITIES_ON_SCREEN:
		return

	var will_spawn_correct: bool = !has_correct_on_screen

	# Opción C: Escalonamiento progresivo por dificultad
	# Fácil: 2 fijos | Normal: alternado 2 o 3 (50/50) | Ingeniero: 3 fijos
	var desired_spawn: int = 2
	match current_difficulty:
		"FACIL":
			desired_spawn = 2
		"NORMAL":
			desired_spawn = 2 if randf() < 0.5 else 3
		"INGENIERO":
			desired_spawn = 3

	var max_can_spawn: int = min(desired_spawn, MAX_ENTITIES_ON_SCREEN - active_in_screen)
	if max_can_spawn <= 0:
		return
	var count_to_spawn: int = max_can_spawn

	for i in range(count_to_spawn):
		var spawn_x: float = randf_range(50.0, vp.x - 50.0)
		var spawn_y: float = randf_range(-80.0, -20.0)
		var speed_y: float = randf_range(cfg["speed_min"], cfg["speed_max"])
		var vel := Vector2(randf_range(-15.0, 15.0), speed_y)

		var is_this_correct: bool = false
		var text: String = ""
		var ast_size: Vector2 = cfg["incorrect_size"]
		var step_idx: int = -1

		if will_spawn_correct and i == 0:
			# Asteroide único que contiene el paso lógico actual
			is_this_correct = true
			will_spawn_correct = false
			step_idx = current_step_index
			if current_step_index < steps.size():
				text = steps[current_step_index]
			ast_size = cfg["correct_size"]
		else:
			# Asteroide incorrecto o distractor (incluyendo pasos adelantados no elegibles)
			var pick_distractor: bool = randf() > 0.4
			if !pick_distractor and steps.size() > 1:
				# Mostrar un paso que es correcto pero NO es el paso actual (ej. paso 3 cuando buscas paso 1)
				var other_indices: Array = []
				for s_i in range(steps.size()):
					if s_i != current_step_index:
						other_indices.append(s_i)
				if !other_indices.is_empty():
					other_indices.shuffle()
					step_idx = other_indices[0]
					text = steps[step_idx]
				else:
					text = distractors.pick_random() if !distractors.is_empty() else "Anulación lógica"
			else:
				text = distractors.pick_random() if !distractors.is_empty() else "Falacia inductiva"
			ast_size = cfg["incorrect_size"]

		asteroids.append({
			"pos": Vector2(spawn_x, spawn_y),
			"vel": vel,
			"text": text,
			"is_correct": is_this_correct,
			"step_idx": step_idx,
			"size": ast_size,
			"tex_off": Vector2(randi_range(0, 63) * 2.0, randi_range(0, 63) * 2.0),
			"active": true
		})

# ══════════════════════════════════════════════════════════════════════════════
# ACTUALIZACIÓN DE PROYECTILES Y ASTEROIDES
# ══════════════════════════════════════════════════════════════════════════════

func _update_bullets(delta: float) -> void:
	for b in bullets:
		if not b["active"]:
			continue
		b["pos"].y -= b["speed"] * delta
		if b["pos"].y < 90.0:
			b["active"] = false

	# Limpiar balas inactivas
	var alive_bullets: Array = []
	for b in bullets:
		if b["active"]:
			alive_bullets.append(b)
	bullets = alive_bullets

func _update_asteroids(delta: float) -> void:
	var vp := get_viewport_rect().size

	for a in asteroids:
		if not a["active"]:
			continue

		a["pos"] += a["vel"] * delta
		if a["pos"].y > vp.y - 90.0:
			a["active"] = false

		var ast_rect := Rect2(a["pos"] - a["size"] * 0.5, a["size"])

		# 1. Colisión Proyectil vs Asteroide (FN-04 / FA-03.02)
		for b in bullets:
			if not b["active"]:
				continue
			if ast_rect.has_point(b["pos"]):
				b["active"] = false
				a["active"] = false
				_on_asteroid_shot(a)
				break

		# 2. Colisión Física Nave vs Asteroide (FA-03.03)
		# Hitbox de núcleo compacta (estilo arcade/shmup): ~50% del tamaño visual para evitar quedar encerrado
		if a["active"] and not is_invulnerable:
			var ship_core_rect := Rect2(ship_pos - Vector2(4, 5), Vector2(8, 10))
			if ast_rect.intersects(ship_core_rect):
				a["active"] = false
				_on_ship_collision()

	# Limpiar asteroides inactivos
	var alive_asteroids: Array = []
	for a in asteroids:
		if a["active"]:
			alive_asteroids.append(a)
	asteroids = alive_asteroids

# ══════════════════════════════════════════════════════════════════════════════
# IMPACTOS Y REGLAS DE NEGOCIO
# ══════════════════════════════════════════════════════════════════════════════

func _on_asteroid_shot(asteroid_data: Dictionary) -> void:
	var cfg: Dictionary = DIFFICULTY_CONFIG[current_difficulty]

	# Validar si corresponde al paso correcto
	if asteroid_data["is_correct"] and asteroid_data["step_idx"] == current_step_index:
		# FN-04: Respuesta correcta (impacto asteroide correcto)
		_play_sfx(sfx_correcto_stream)
		score += int(cfg["score_per_hit"])
		current_step_index += 1
		_refresh_step_badges()
		_update_hud()

		# Eliminar cualquier otro asteroide que pudiera haber sido de ese paso
		for other in asteroids:
			if other["step_idx"] == asteroid_data["step_idx"]:
				other["active"] = false

		# FN-05 / FN-06: Validar si se completó la hipótesis
		if current_step_index >= total_steps:
			_on_victory()
	else:
		# FA-03.02: Disparo a asteroide incorrecto / anulación / paso fuera de turno (explosión asteroide no correcto)
		_play_sfx(sfx_explosion_stream)
		_trigger_warning()
		_apply_damage("¡Disparaste a un paso erróneo o fuera de turno!")

func _on_ship_collision() -> void:
	# FA-03.03: Colisión física con asteroide
	_play_sfx(sfx_explosion_stream)
	_trigger_warning()
	is_invulnerable = true
	invulnerable_timer = 1.5
	_apply_damage("¡Colisión con asteroide! Esquiva los obstáculos.")

func _apply_damage(reason_text: String) -> void:
	lives -= 1
	_play_sfx(sfx_vida_menos_stream)
	_update_hud()

	if lives <= 0:
		# FA-03.05: Game Over por vidas agotadas
		_on_game_over(reason_text)

func _trigger_warning() -> void:
	warning_flash_alpha = 1.0

# ══════════════════════════════════════════════════════════════════════════════
# FIN DE PARTIDA: VICTORIA O DERROTA
# ══════════════════════════════════════════════════════════════════════════════

func _on_victory() -> void:
	current_state = "VICTORY"
	vic_score_label.text = "Puntaje final acumulado: %d pts" % score
	vic_stats_label.text = "Demostración completa de %d pasos en dificultad %s.\nTiempo restante: %ds" % [
		total_steps, DIFFICULTY_CONFIG[current_difficulty]["name"], int(time_remaining)
	]

	# Guardar y notificar al StateManager (1 a 3 estrellas según vidas conservadas)
	var stars: int = 1
	if lives == max_lives:
		stars = 3
	elif lives >= 2:
		stars = 2

	var prev_high: int = StateManager.get_minigame_high_score(minigame_id) if StateManager else 0
	var is_record: bool = score > prev_high
	finish_game(true, score, stars, "Hipótesis comprobada con éxito")
	_show_overlay("VICTORY")
	if flow_template:
		var total_accum: int = StateManager.get_points() if StateManager else score
		flow_template.show_victory(score, stars, total_accum, is_record, "¡HIPÓTESIS COMPROBADA!")

func _on_timeout() -> void:
	# FA-03.04: Hipótesis inconclusa por tiempo -> Penalización del 50% de puntos
	score = int(score * 0.5)
	_on_game_over("Se agotó el tiempo de supervivencia. Penalización del 50% de puntos.")

func _on_game_over(reason: String) -> void:
	current_state = "GAME_OVER"
	go_reason_label.text = reason
	go_score_label.text = "Puntaje final: %d pts" % score
	finish_game(false, score, 0, reason)
	_show_overlay("GAME_OVER")
	if flow_template:
		flow_template.show_game_over(reason, score)

# ══════════════════════════════════════════════════════════════════════════════
# DIBUJADO DE LA ESCENA ESPACIAL
# ══════════════════════════════════════════════════════════════════════════════

func _on_game_area_draw() -> void:
	if current_state != "PLAYING" and current_state != "PAUSED":
		return

	# 1. Dibujar proyectiles
	for b in bullets:
		if b["active"]:
			game_area.draw_line(b["pos"], b["pos"] + Vector2(0, -10), Color(0.4, 0.9, 1.0), 3.0)
			game_area.draw_circle(b["pos"], 2.5, Color(1.0, 1.0, 1.0))

	# 2. Dibujar nave espacial
	_draw_spaceship(ship_pos)

	# 3. Dibujar asteroides con sus textos
	for a in asteroids:
		if a["active"]:
			_draw_asteroid(a)

func _draw_spaceship(pos: Vector2) -> void:
	# Sprite de la nave (si falta la imagen se usa el dibujo vectorial de respaldo de abajo)
	if ship_texture != null:
		var tint := Color.WHITE
		if is_invulnerable and int(Time.get_ticks_msec() / 100) % 2 == 0:
			tint = Color(1.0, 1.0, 1.0, 0.5)   # parpadeo de invulnerabilidad
		var ship_rect := Rect2((pos - SHIP_DRAW_SIZE * 0.5).round(), SHIP_DRAW_SIZE)
		game_area.draw_texture_rect(ship_texture, ship_rect, false, tint)
		return

	var body_color := Color(0.3, 0.7, 1.0)
	if is_invulnerable:
		# Parpadeo de invulnerabilidad
		if int(Time.get_ticks_msec() / 100) % 2 == 0:
			body_color = Color(1.0, 1.0, 1.0, 0.5)

	# Silueta triangular de nave espacial compacta (mayor maniobrabilidad)
	var p1 := pos + Vector2(0, -11)
	var p2 := pos + Vector2(-9, 10)
	var p3 := pos + Vector2(0, 6)
	var p4 := pos + Vector2(9, 10)
	var points := PackedVector2Array([p1, p2, p3, p4])
	game_area.draw_colored_polygon(points, body_color)
	game_area.draw_polyline(PackedVector2Array([p1, p2, p3, p4, p1]), Color(0.9, 0.95, 1.0), 1.2)

	# Propulsor de fuego
	var flame_p1 := pos + Vector2(-3, 8)
	var flame_p2 := pos + Vector2(3, 8)
	var flame_tip := pos + Vector2(0, 14 + randf_range(0, 3))
	game_area.draw_colored_polygon(PackedVector2Array([flame_p1, flame_p2, flame_tip]), Color(1.0, 0.5, 0.1, 0.8))

func _draw_asteroid(a: Dictionary) -> void:
	var pos: Vector2 = a["pos"]
	var sz: Vector2 = a["size"]
	var rect := Rect2(pos - sz * 0.5, sz)

	# Color y contorno del asteroide
	var base_col := Color(0.24, 0.22, 0.28)
	var border_col := Color(0.5, 0.45, 0.6)

	if a["is_correct"]:
		# Asteroide con paso correcto: sutil tono cian/azulado
		base_col = Color(0.18, 0.28, 0.38)
		border_col = Color(0.4, 0.8, 1.0)

	# Dibujar base del asteroide: textura verde (correcto) o naranja/roja (incorrecto)
	var ast_tex: Texture2D = ast_tex_correct if a["is_correct"] else ast_tex_wrong
	if ast_tex != null:
		var snapped_rect := Rect2(rect.position.round(), rect.size)
		_draw_tiled_texture(ast_tex, snapped_rect, AST_TEX_TILE_PX, a.get("tex_off", Vector2.ZERO))
		border_col = AST_BORDER_CORRECT if a["is_correct"] else AST_BORDER_WRONG
	else:
		game_area.draw_rect(rect, base_col, true)
	game_area.draw_rect(rect, border_col, false, 2.0)

	# Texto del paso o distractor en el interior del asteroide
	var font := ThemeDB.fallback_font
	var font_size := 9
	var text: String = a["text"]

	# Dividir texto en líneas para que quepa dentro del asteroide
	var max_w := sz.x - 10.0
	var words := text.split(" ")
	var lines: Array[String] = []
	var curr_line := ""

	for w in words:
		var test_line = curr_line + (" " if curr_line != "" else "") + w
		if font.get_string_size(test_line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_w:
			lines.append(curr_line)
			curr_line = w
		else:
			curr_line = test_line
	if curr_line != "":
		lines.append(curr_line)

	# Imprimir líneas centradas
	var total_h := lines.size() * (font_size + 2)
	var start_y := rect.position.y + (rect.size.y - total_h) * 0.5 + font_size

	for line in lines:
		var line_w := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var line_x := rect.position.x + (rect.size.x - line_w) * 0.5
		if ast_tex != null:
			# Contorno oscuro para que el texto se lea sobre la textura
			game_area.draw_string_outline(font, Vector2(line_x, start_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0, 0, 0, 0.95))
		game_area.draw_string(font, Vector2(line_x, start_y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.95, 0.95, 1.0))
		start_y += font_size + 2

## Rellena `rect` repitiendo `tex` en mosaicos de `tile_px` (sin deformar). `off` desplaza el patrón
## para que cada asteroide se vea distinto (usar múltiplos de 2 px para no romper el pixel-art).
func _draw_tiled_texture(tex: Texture2D, rect: Rect2, tile_px: float, off: Vector2) -> void:
	var k: float = float(tex.get_width()) / tile_px   # px de la imagen por px de pantalla
	var origin: Vector2 = rect.position - Vector2(fposmod(off.x, tile_px), fposmod(off.y, tile_px))
	var ty: float = origin.y
	while ty < rect.end.y:
		var tx: float = origin.x
		while tx < rect.end.x:
			var tile := Rect2(Vector2(tx, ty), Vector2(tile_px, tile_px))
			var part: Rect2 = tile.intersection(rect)
			if part.size.x > 0.0 and part.size.y > 0.0:
				game_area.draw_texture_rect_region(tex, part, Rect2((part.position - tile.position) * k, part.size * k))
			tx += tile_px
		ty += tile_px

# ══════════════════════════════════════════════════════════════════════════════
# ACTUALIZACIÓN DE ESTADO Y HUD
# ══════════════════════════════════════════════════════════════════════════════

func _update_hud() -> void:
	if hud_lives_label:
		hud_lives_label.text = " ❤️ x%d" % lives
	if hud_score_label:
		hud_score_label.text = "⭐ %d" % score
	if hud_timer_label:
		var mins := int(time_remaining) / 60
		var secs := int(time_remaining) % 60
		hud_timer_label.text = "⏱ %02d:%02d" % [mins, secs]
	if hud_step_progress_label:
		hud_step_progress_label.text = "%d/%d" % [min(current_step_index + 1, total_steps), total_steps]
	if hypothesis_title_label and not current_exercise.is_empty():
		hypothesis_title_label.text = current_exercise.get("hypothesis", "")

func _refresh_step_badges() -> void:
	if not hud_step_badges_container:
		return

	for child in hud_step_badges_container.get_children():
		child.queue_free()

	for i in range(total_steps):
		var badge := PanelContainer.new()
		var b_sb := StyleBoxFlat.new()
		b_sb.set_corner_radius_all(4)

		if i < current_step_index:
			# Paso ya superado: verde
			b_sb.bg_color = Color(0.2, 0.6, 0.3, 0.9)
			b_sb.set_border_width_all(1)
			b_sb.border_color = Color(0.4, 1.0, 0.5)
		elif i == current_step_index:
			# Paso actual: resaltado con resplandor dorado / amarillo según el boceto
			b_sb.bg_color = Color(0.7, 0.55, 0.1, 0.95)
			b_sb.set_border_width_all(2)
			b_sb.border_color = Color(1.0, 0.9, 0.3)
		else:
			# Pasos futuros: tenue
			b_sb.bg_color = Color(0.15, 0.18, 0.25, 0.8)
			b_sb.set_border_width_all(1)
			b_sb.border_color = Color(0.3, 0.35, 0.45)

		badge.add_theme_stylebox_override("panel", b_sb)

		var lbl := Label.new()
		lbl.text = " P%d " % (i + 1)
		lbl.add_theme_font_size_override("font_size", 10)
		if i == current_step_index:
			lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		else:
			lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		badge.add_child(lbl)

		hud_step_badges_container.add_child(badge)

# ══════════════════════════════════════════════════════════════════════════════
# CONTROLADORES DE BOTONES
# ══════════════════════════════════════════════════════════════════════════════

func _on_pause_button_pressed() -> void:
	if current_state == "PLAYING":
		_show_overlay("PAUSED")

func _on_resume_pressed() -> void:
	if current_state == "PAUSED":
		_show_overlay("PLAYING")

func _on_retry_pressed() -> void:
	_setup_match()
	_show_overlay("PLAYING")

func _on_return_to_classroom() -> void:
	if get_tree():
		get_tree().change_scene_to_file(CLASSROOM_SCENE)
