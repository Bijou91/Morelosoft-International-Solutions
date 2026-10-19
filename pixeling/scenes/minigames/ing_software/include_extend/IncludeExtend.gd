## IncludeExtend.gd — Minijuego CU-08: ¿Include o Extend?
## El alumno observa un par de casos de uso y decide, contra reloj, si su relación es
## «include» (comportamiento obligatorio) o «extend» (comportamiento opcional/condicional).
## Cumple con la Especificación CU-08 y su Diagrama de Secuencia (TSP / ISO/IEC 29110).
## Responsable: Karol Christopher Espino Galicia
extends MiniGameBase

# ══════════════════════════════════════════════════════════════════════════════
# CONSTANTES
# ══════════════════════════════════════════════════════════════════════════════

const RelationArrowScript = preload("res://scenes/minigames/ing_software/include_extend/RelationArrow.gd")

const DATA_PATH: String = "res://scenes/minigames/ing_software/include_extend/data/escenarios.json"
const CLASSROOM_SCENE: String = "res://scenes/classroom/AulaIngSoftware.tscn"
const LOBBY_SCENE: String = "res://scenes/campus/Lobby.tscn"

## Duración de la retroalimentación (seg). Al fallar se da más tiempo para leer la explicación.
const FEEDBACK_TIME_OK: float = 1.2
const FEEDBACK_TIME_FAIL: float = 2.2

## Configuración por dificultad (Precondición 5 de la especificación + tiempo de reacción acordado).
const DIFFICULTY_CONFIG: Dictionary = {
	"FACIL":     { "name": "FÁCIL",     "lives": 10, "points": 10, "time": 90.0, "reaction": 10.0 },
	"NORMAL":    { "name": "NORMAL",    "lives": 5,  "points": 20, "time": 75.0, "reaction": 7.0 },
	"INGENIERO": { "name": "INGENIERO", "lives": 3,  "points": 30, "time": 60.0, "reaction": 5.0 },
}

## Escenarios de respaldo por si el JSON no se puede cargar (evita que el juego se rompa).
const FALLBACK_SCENARIOS: Array = [
	{ "contexto": "El usuario interactúa con el cajero automático.", "cu_base": "Retirar efectivo",
	  "cu_relacionado": "Validar PIN", "relacion": "include",
	  "regla": "El cajero siempre pide el PIN antes de entregar dinero.",
	  "explicacion": "Validar PIN ocurre SIEMPRE al retirar efectivo → «include»." },
	{ "contexto": "El usuario termina un retiro en el cajero automático.", "cu_base": "Retirar efectivo",
	  "cu_relacionado": "Imprimir comprobante", "relacion": "extend",
	  "regla": "El comprobante solo se imprime si el usuario lo solicita.",
	  "explicacion": "Imprimir comprobante es opcional → «extend»." },
]

# ── Paleta pixel art "aula" ──
const COL_BG: Color = Color("1a1c2c")
const COL_BG_LINE: Color = Color("232741")
const COL_PANEL: Color = Color("262b44")
const COL_PANEL_BORDER: Color = Color("5a6988")
const COL_BOARD: Color = Color("1f3b2d")
const COL_WOOD: Color = Color("6b4226")
const COL_CHALK: Color = Color("e8e6d9")
const COL_CHALK_DIM: Color = Color("a9b8a8")
const COL_INK: Color = Color("1a1c2c")
const COL_OK: Color = Color("3fae5a")
const COL_WARN: Color = Color("e0a030")
const COL_ERR: Color = Color("d9483b")
const COL_ACCENT: Color = Color("f2c14e")
const COL_INCLUDE: Color = Color("3b6fb6")
const COL_EXTEND: Color = Color("8e4fb5")
const COL_SHADOW: Color = Color(0, 0, 0, 0.55)

# ══════════════════════════════════════════════════════════════════════════════
# ESTADO
# ══════════════════════════════════════════════════════════════════════════════

## Máquina de estados: todos los temporizadores avanzan solo en QUESTION / FEEDBACK,
## por lo que la pausa (FA-02.01) congela todo sin depender de await/timers externos.
enum State { DIFFICULTY, INSTRUCTIONS, QUESTION, FEEDBACK, PAUSED, GAME_OVER, VICTORY }

var state: int = State.DIFFICULTY
var state_before_pause: int = State.QUESTION
var selected_difficulty: String = "NORMAL"

var max_lives: int = 5
var current_lives: int = 5
var points_per_hit: int = 20
var game_duration: float = 75.0
var reaction_time: float = 7.0

var score: int = 0
var total_answered: int = 0
var total_correct: int = 0
var time_remaining: float = 0.0
var question_time_remaining: float = 0.0
var feedback_time_remaining: float = 0.0

var all_scenarios: Array = []
var scenario_bag: Array = []
var current_scenario: Dictionary = {}
var last_scenario_id: String = ""

# ══════════════════════════════════════════════════════════════════════════════
# REFERENCIAS UI (asignadas en _build_ui)
# ══════════════════════════════════════════════════════════════════════════════

var content_root: MarginContainer
var lives_label: Label
var score_label: Label
var global_bar: ProgressBar
var global_time_label: Label
var global_fill_tier: int = -1
var global_fill_styles: Array = []

var context_label: Label
var uc_base_label: Label
var uc_related_label: Label
var relation_arrow # Instancia de RelationArrow.gd (tipado dinámico)
var feedback_label: Label
var rule_label: Label
var question_bar: ProgressBar
var question_time_label: Label
var question_fill_ok: StyleBoxFlat
var question_fill_danger: StyleBoxFlat

var btn_include: Button
var btn_extend: Button

var difficulty_overlay: ColorRect
var instructions_overlay: ColorRect
var pause_overlay: ColorRect
var game_over_overlay: ColorRect
var victory_overlay: ColorRect

var instr_difficulty_label: Label
var game_over_score_label: Label
var game_over_stats_label: Label
var victory_stars_label: Label
var victory_score_label: Label
var victory_stats_label: Label

# ══════════════════════════════════════════════════════════════════════════════
# CICLO DE VIDA
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	super._ready()
	minigame_id = "include_extend"
	cu_id = "CU-08"
	minigame_title = "¿Include o Extend?"
	subject_name = "Introducción a la Ingeniería de Software"

	_load_scenarios()
	_build_ui()
	_show_difficulty_selector()


func _process(delta: float) -> void:
	match state:
		State.QUESTION:
			if _tick_global_timer(delta):
				return
			question_time_remaining -= delta
			_update_question_timer()
			if question_time_remaining <= 0.0:
				_on_question_timeout()
		State.FEEDBACK:
			# Si ya no quedan vidas, el reloj global se detiene: el final será Game Over.
			if current_lives > 0 and _tick_global_timer(delta):
				return
			feedback_time_remaining -= delta
			if feedback_time_remaining <= 0.0:
				_next_scenario()


func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_ESCAPE, KEY_P:
			_toggle_pause()
		KEY_LEFT, KEY_I:
			_on_answer_pressed("include")
		KEY_RIGHT, KEY_E:
			_on_answer_pressed("extend")


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if _is_playing() or state == State.PAUSED:
				_toggle_pause()
			elif state == State.DIFFICULTY or state == State.INSTRUCTIONS:
				_go_to_classroom()
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			# La app pasa a segundo plano (llamada, notificación) → pausa automática (FA-02.01).
			if _is_playing():
				_toggle_pause()

# ══════════════════════════════════════════════════════════════════════════════
# CARGA DE DATOS
# ══════════════════════════════════════════════════════════════════════════════

func _load_scenarios() -> void:
	all_scenarios.clear()
	if FileAccess.file_exists(DATA_PATH):
		var file := FileAccess.open(DATA_PATH, FileAccess.READ)
		if file:
			var parsed = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Array:
				for item in parsed:
					if item is Dictionary and item.has("cu_base") and item.has("cu_relacionado") and item.has("relacion"):
						all_scenarios.append(item)

	if all_scenarios.is_empty():
		push_error("[IncludeExtend] No se pudo cargar %s. Usando escenarios de respaldo." % DATA_PATH)
		all_scenarios = FALLBACK_SCENARIOS.duplicate(true)


## "Bolsa" barajada: no se repite un escenario hasta agotar el banco completo.
func _draw_scenario() -> Dictionary:
	if scenario_bag.is_empty():
		scenario_bag = all_scenarios.duplicate()
		scenario_bag.shuffle()
		# Evitar que el primero de la nueva bolsa sea igual al último mostrado
		if scenario_bag.size() > 1 and str(scenario_bag[0].get("id", "")) == last_scenario_id:
			scenario_bag.push_back(scenario_bag.pop_front())
	var scenario: Dictionary = scenario_bag.pop_front()
	last_scenario_id = str(scenario.get("id", ""))
	return scenario

# ══════════════════════════════════════════════════════════════════════════════
# CONSTRUCCIÓN DE UI (generada por código; estilo pixel art sin sprites)
# ══════════════════════════════════════════════════════════════════════════════

func _build_ui() -> void:
	# ── Fondo con líneas horizontales tipo scanline ──
	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var vp_size: Vector2 = get_viewport_rect().size
	for i in range(int(vp_size.y / 8.0) + 1):
		if i % 2 == 0:
			continue
		var line := ColorRect.new()
		line.color = COL_BG_LINE
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.position = Vector2(0, i * 8.0)
		line.size = Vector2(vp_size.x, 2)
		bg.add_child(line)

	# ── Contenedor principal ──
	content_root = MarginContainer.new()
	content_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		content_root.add_theme_constant_override("margin_" + side, 8)
	add_child(content_root)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	content_root.add_child(vbox)

	vbox.add_child(_build_top_hud())
	vbox.add_child(_build_global_timer())
	var board := _build_board()
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(board)
	vbox.add_child(_build_answer_buttons())

	# ── Overlays (el último añadido queda encima) ──
	_build_overlay_victory()
	_build_overlay_game_over()
	_build_overlay_pause()
	_build_overlay_instructions()
	_build_overlay_difficulty()


func _build_top_hud() -> Control:
	var hud := HBoxContainer.new()
	hud.add_theme_constant_override("separation", 6)

	var btn_back := _make_button("←", COL_PANEL, 14, Vector2(40, 32))
	btn_back.pressed.connect(_on_hud_back_pressed)
	hud.add_child(btn_back)

	var lives_box := _make_badge()
	lives_label = _make_label("❤ 5/5", 12, Color("ff6b6b"))
	lives_box.add_child(lives_label)
	hud.add_child(lives_box)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(spacer)

	var score_box := _make_badge()
	score_label = _make_label("🪙 0", 12, COL_ACCENT)
	score_box.add_child(score_label)
	hud.add_child(score_box)

	var btn_pause := _make_button("II", COL_PANEL, 13, Vector2(40, 32))
	btn_pause.pressed.connect(_toggle_pause)
	hud.add_child(btn_pause)
	return hud


func _build_global_timer() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	global_fill_styles = [
		_make_pixel_box(COL_OK, COL_OK, 0, false),
		_make_pixel_box(COL_WARN, COL_WARN, 0, false),
		_make_pixel_box(COL_ERR, COL_ERR, 0, false),
	]

	global_bar = ProgressBar.new()
	global_bar.show_percentage = false
	global_bar.custom_minimum_size = Vector2(0, 14)
	global_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	global_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	global_bar.add_theme_stylebox_override("background", _make_pixel_box(COL_PANEL, COL_PANEL_BORDER, 2, false))
	row.add_child(global_bar)

	global_time_label = _make_label("1:30", 12, COL_CHALK)
	global_time_label.custom_minimum_size = Vector2(40, 0)
	row.add_child(global_time_label)
	return row


func _build_board() -> PanelContainer:
	var board := PanelContainer.new()
	board.add_theme_stylebox_override("panel", _make_pixel_box(COL_BOARD, COL_WOOD, 4, true))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	board.add_child(margin)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	margin.add_child(v)

	# ── Escenario (FN-01) ──
	v.add_child(_make_label("▌ESCENARIO", 10, COL_ACCENT, false))
	context_label = _make_label("", 13, COL_CHALK, false, true)
	context_label.custom_minimum_size = Vector2(0, 40)
	v.add_child(context_label)

	v.add_child(_make_expand_spacer())

	# ── Diagrama: (Caso base) - - ? - - (Caso relacionado) ──
	var diagram := HBoxContainer.new()
	diagram.alignment = BoxContainer.ALIGNMENT_CENTER
	diagram.add_theme_constant_override("separation", 2)
	v.add_child(diagram)

	var base_parts: Array = _make_use_case_oval()
	diagram.add_child(base_parts[0])
	uc_base_label = base_parts[1]

	relation_arrow = RelationArrowScript.new()
	relation_arrow.custom_minimum_size = Vector2(60, 70)
	relation_arrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diagram.add_child(relation_arrow)

	var rel_parts: Array = _make_use_case_oval()
	diagram.add_child(rel_parts[0])
	uc_related_label = rel_parts[1]

	# ── Retroalimentación didáctica ──
	feedback_label = _make_label("", 11, COL_CHALK, true, true)
	feedback_label.custom_minimum_size = Vector2(0, 44)
	v.add_child(feedback_label)

	v.add_child(_make_expand_spacer())

	# ── Regla de negocio ──
	var rule_box := PanelContainer.new()
	rule_box.add_theme_stylebox_override("panel", _make_pixel_box(Color(0, 0, 0, 0.25), COL_CHALK_DIM, 1, false))
	var rule_v := VBoxContainer.new()
	rule_v.add_theme_constant_override("separation", 2)
	rule_box.add_child(rule_v)
	rule_v.add_child(_make_label("📜 REGLA DE NEGOCIO", 9, COL_ACCENT, false))
	rule_label = _make_label("", 11, COL_CHALK, false, true)
	rule_v.add_child(rule_label)
	v.add_child(rule_box)

	# ── Temporizador de reacción por pregunta ──
	var q_row := HBoxContainer.new()
	q_row.add_theme_constant_override("separation", 6)
	q_row.add_child(_make_label("⏱", 12, COL_CHALK))

	question_fill_ok = _make_pixel_box(COL_ACCENT, COL_ACCENT, 0, false)
	question_fill_danger = _make_pixel_box(COL_ERR, COL_ERR, 0, false)
	question_bar = ProgressBar.new()
	question_bar.show_percentage = false
	question_bar.custom_minimum_size = Vector2(0, 10)
	question_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	question_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	question_bar.add_theme_stylebox_override("background", _make_pixel_box(Color(0, 0, 0, 0.35), COL_CHALK_DIM, 1, false))
	question_bar.add_theme_stylebox_override("fill", question_fill_ok)
	q_row.add_child(question_bar)

	question_time_label = _make_label("7s", 12, COL_CHALK)
	question_time_label.custom_minimum_size = Vector2(28, 0)
	q_row.add_child(question_time_label)
	v.add_child(q_row)

	return board


func _build_answer_buttons() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	btn_include = _make_button("«include»", COL_INCLUDE, 16, Vector2(0, 56))
	btn_include.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_include.pressed.connect(func(): _on_answer_pressed("include"))
	row.add_child(btn_include)

	btn_extend = _make_button("«extend»", COL_EXTEND, 16, Vector2(0, 56))
	btn_extend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_extend.pressed.connect(func(): _on_answer_pressed("extend"))
	row.add_child(btn_extend)
	return row

# ── Overlays ─────────────────────────────────────────────────────────────────

func _build_overlay_difficulty() -> void:
	var parts: Array = _create_overlay(Color(0, 0, 0, 0.85))
	difficulty_overlay = parts[0]
	var vbox: VBoxContainer = parts[1]

	var title := Label.new()
	title.text = "⚖️  ¿Include o Extend?"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Evalúa escenarios y determina rápidamente\nsi su relación es Include o Extend"
	sub.add_theme_font_size_override("font_size", 9)
	sub.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var lbl_diff := Label.new()
	lbl_diff.text = "Selecciona la dificultad:"
	lbl_diff.add_theme_font_size_override("font_size", 10)
	lbl_diff.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	lbl_diff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_diff)

	var btn_facil := Button.new()
	btn_facil.text = "🟢  Fácil  (10 vidas)"
	btn_facil.add_theme_font_size_override("font_size", 12)
	btn_facil.custom_minimum_size = Vector2(0, 38)
	btn_facil.pressed.connect(func(): _on_difficulty_selected("FACIL"))
	vbox.add_child(btn_facil)

	var btn_normal := Button.new()
	btn_normal.text = "🟡  Normal  (5 vidas)"
	btn_normal.add_theme_font_size_override("font_size", 12)
	btn_normal.custom_minimum_size = Vector2(0, 38)
	btn_normal.pressed.connect(func(): _on_difficulty_selected("NORMAL"))
	vbox.add_child(btn_normal)

	var btn_ing := Button.new()
	btn_ing.text = "🔴  Ingeniero  (3 vidas)"
	btn_ing.add_theme_font_size_override("font_size", 12)
	btn_ing.custom_minimum_size = Vector2(0, 38)
	btn_ing.pressed.connect(func(): _on_difficulty_selected("INGENIERO"))
	vbox.add_child(btn_ing)

	var btn_back := Button.new()
	btn_back.text = "←  Volver al Salón"
	btn_back.add_theme_font_size_override("font_size", 11)
	btn_back.custom_minimum_size = Vector2(0, 34)
	btn_back.pressed.connect(_go_to_classroom)
	vbox.add_child(btn_back)


func _build_overlay_instructions() -> void:
	var parts: Array = _create_overlay(Color(0, 0, 0, 0.82))
	instructions_overlay = parts[0]
	var vbox: VBoxContainer = parts[1]

	var title := Label.new()
	title.text = "📋  INSTRUCCIONES"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	instr_difficulty_label = Label.new()
	instr_difficulty_label.text = "Dificultad: NORMAL — 5 vidas"
	instr_difficulty_label.add_theme_font_size_override("font_size", 10)
	instr_difficulty_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	instr_difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(instr_difficulty_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var rules: Array[String] = [
		"🟢  Seleccionar la relación correcta\n     rápidamente = +Puntos",
		"🔴  Seleccionar la opción\n     incorrecta = -1 Vida",
		"⚠️  Dejar que se acabe el tiempo\n     de reacción por pregunta = -1 Vida",
		"⏱  Sobrevive hasta que el\n     temporizador global termine para ganar",
	]
	for rule_text in rules:
		var rule_lbl := Label.new()
		rule_lbl.text = rule_text
		rule_lbl.add_theme_font_size_override("font_size", 9)
		rule_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		vbox.add_child(rule_lbl)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	var btn_start := Button.new()
	btn_start.text = "▶  ¡COMENZAR!"
	btn_start.add_theme_font_size_override("font_size", 14)
	btn_start.custom_minimum_size = Vector2(0, 42)
	btn_start.pressed.connect(_on_start_pressed)
	vbox.add_child(btn_start)

	var btn_change := Button.new()
	btn_change.text = "←  Cambiar Dificultad"
	btn_change.add_theme_font_size_override("font_size", 11)
	btn_change.custom_minimum_size = Vector2(0, 34)
	btn_change.pressed.connect(func():
		AudioManager.play_click()
		_show_difficulty_selector()
	)
	vbox.add_child(btn_change)


func _build_overlay_pause() -> void:
	var parts: Array = _create_overlay(Color(0, 0, 0, 0.70))
	pause_overlay = parts[0]
	var vbox: VBoxContainer = parts[1]

	var title := Label.new()
	title.text = "⏸  PAUSA"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1, 0.92, 0.6))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var btn_resume := Button.new()
	btn_resume.text = "▶  Reanudar"
	btn_resume.add_theme_font_size_override("font_size", 13)
	btn_resume.custom_minimum_size = Vector2(0, 40)
	btn_resume.pressed.connect(_toggle_pause)
	vbox.add_child(btn_resume)

	var btn_salon := Button.new()
	btn_salon.text = "←  Volver al Salón"
	btn_salon.add_theme_font_size_override("font_size", 12)
	btn_salon.custom_minimum_size = Vector2(0, 38)
	btn_salon.pressed.connect(_go_to_classroom)
	vbox.add_child(btn_salon)


func _build_overlay_game_over() -> void:
	var parts: Array = _create_overlay(Color(0.15, 0, 0, 0.85))
	game_over_overlay = parts[0]
	var vbox: VBoxContainer = parts[1]

	var title := Label.new()
	title.text = "💀  GAME OVER"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	game_over_score_label = Label.new()
	game_over_score_label.text = "Puntaje: 0"
	game_over_score_label.add_theme_font_size_override("font_size", 13)
	game_over_score_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	game_over_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(game_over_score_label)

	game_over_stats_label = Label.new()
	game_over_stats_label.text = ""
	game_over_stats_label.add_theme_font_size_override("font_size", 10)
	game_over_stats_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	game_over_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(game_over_stats_label)

	var btn_retry := Button.new()
	btn_retry.text = "🔄  Reiniciar Actividad"
	btn_retry.add_theme_font_size_override("font_size", 13)
	btn_retry.custom_minimum_size = Vector2(0, 40)
	btn_retry.pressed.connect(_on_retry_pressed)
	vbox.add_child(btn_retry)

	var btn_salon := Button.new()
	btn_salon.text = "←  Volver al Salón"
	btn_salon.add_theme_font_size_override("font_size", 11)
	btn_salon.custom_minimum_size = Vector2(0, 36)
	btn_salon.pressed.connect(_go_to_classroom)
	vbox.add_child(btn_salon)


func _build_overlay_victory() -> void:
	var parts: Array = _create_overlay(Color(0, 0.05, 0.1, 0.85))
	victory_overlay = parts[0]
	var vbox: VBoxContainer = parts[1]

	var title := Label.new()
	title.text = "🏆  ¡COMPLETADO!"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	victory_stars_label = Label.new()
	victory_stars_label.text = "⭐⭐⭐"
	victory_stars_label.add_theme_font_size_override("font_size", 22)
	victory_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(victory_stars_label)

	victory_score_label = Label.new()
	victory_score_label.text = "Puntaje: 0"
	victory_score_label.add_theme_font_size_override("font_size", 14)
	victory_score_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	victory_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(victory_score_label)

	victory_stats_label = Label.new()
	victory_stats_label.text = ""
	victory_stats_label.add_theme_font_size_override("font_size", 10)
	victory_stats_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	victory_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(victory_stats_label)

	# Opciones de salida al finalizar la actividad
	var btn_salon := Button.new()
	btn_salon.text = "📚  Volver al Salón"
	btn_salon.add_theme_font_size_override("font_size", 13)
	btn_salon.custom_minimum_size = Vector2(0, 40)
	btn_salon.pressed.connect(_go_to_classroom)
	vbox.add_child(btn_salon)

	var btn_campus := Button.new()
	btn_campus.text = "🚪  Salir al Campus"
	btn_campus.add_theme_font_size_override("font_size", 13)
	btn_campus.custom_minimum_size = Vector2(0, 40)
	btn_campus.pressed.connect(_go_to_campus)
	vbox.add_child(btn_campus)

# ══════════════════════════════════════════════════════════════════════════════
# HELPERS DE UI (estilo pixel art: sin esquinas redondeadas ni antialiasing)
# ══════════════════════════════════════════════════════════════════════════════

func _make_pixel_box(bg: Color, border: Color, border_w: int = 2, shadow: bool = true, radius: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.anti_aliasing = false
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border_w)
	sb.border_color = border
	if shadow:
		sb.shadow_color = COL_SHADOW
		sb.shadow_size = 1
		sb.shadow_offset = Vector2(3, 3)
	sb.content_margin_left = 6.0
	sb.content_margin_right = 6.0
	sb.content_margin_top = 4.0
	sb.content_margin_bottom = 4.0
	return sb


func _make_label(text: String, font_size: int, color: Color, centered: bool = true, wrap: bool = false) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if centered:
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if wrap:
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl


func _make_button(text: String, color: Color, font_size: int, min_size: Vector2) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", COL_CHALK)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", COL_ACCENT)
	btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))
	btn.add_theme_stylebox_override("normal", _make_pixel_box(color, color.darkened(0.45), 2, true))
	btn.add_theme_stylebox_override("hover", _make_pixel_box(color.lightened(0.15), color.lightened(0.4), 2, true))
	var pressed_sb := _make_pixel_box(color.darkened(0.2), color.darkened(0.55), 2, false)
	pressed_sb.content_margin_top = 6.0 # efecto de "botón hundido"
	pressed_sb.content_margin_bottom = 2.0
	btn.add_theme_stylebox_override("pressed", pressed_sb)
	btn.add_theme_stylebox_override("disabled", _make_pixel_box(color.darkened(0.55), color.darkened(0.7), 2, false))
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.mouse_entered.connect(func():
		if not btn.disabled:
			btn.pivot_offset = btn.size / 2.0
			create_tween().tween_property(btn, "scale", Vector2(1.03, 1.03), 0.08))
	btn.mouse_exited.connect(func():
		create_tween().tween_property(btn, "scale", Vector2.ONE, 0.08))
	return btn


func _make_badge() -> PanelContainer:
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override("panel", _make_pixel_box(COL_PANEL, COL_PANEL_BORDER, 2, true))
	return badge


## Óvalo de caso de uso UML. Devuelve [panel, label].
func _make_use_case_oval() -> Array:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(106, 66)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb := _make_pixel_box(COL_CHALK, COL_INK, 2, true, 33)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	panel.add_theme_stylebox_override("panel", sb)

	var lbl := Label.new()
	lbl.custom_minimum_size = Vector2(86, 0)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", COL_INK)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(lbl)
	return [panel, lbl]


func _make_pixel_separator() -> Control:
	var sep := ColorRect.new()
	sep.color = COL_PANEL_BORDER
	sep.custom_minimum_size = Vector2(0, 2)
	return sep


func _make_expand_spacer() -> Control:
	var s := Control.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return s


func _make_stylebox(color: Color, corner_radius: int = 4, border_width: int = 0, border_color: Color = Color.BLACK) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(corner_radius)
	if border_width > 0:
		sb.border_width_left = border_width
		sb.border_width_right = border_width
		sb.border_width_top = border_width
		sb.border_width_bottom = border_width
		sb.border_color = border_color
	sb.content_margin_left = 4.0
	sb.content_margin_right = 4.0
	sb.content_margin_top = 2.0
	sb.content_margin_bottom = 2.0
	return sb


## Crea un overlay genérico: fondo semitransparente + VBoxContainer centrado.
## Devuelve [overlay_rect, vbox_container].
func _create_overlay(bg_color: Color = Color(0, 0, 0, 0.75)) -> Array:
	var overlay := ColorRect.new()
	overlay.color = bg_color
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 0)
	panel.add_theme_stylebox_override("panel", _make_stylebox(Color(0.12, 0.13, 0.18, 0.95), 12, 2, Color(0.4, 0.45, 0.55)))
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	add_child(overlay)
	return [overlay, vbox]


func _show_overlay(target: ColorRect) -> void:
	for o in [difficulty_overlay, instructions_overlay, pause_overlay, game_over_overlay, victory_overlay]:
		if is_instance_valid(o):
			o.visible = (o == target)
	if target and is_inside_tree():
		target.modulate.a = 0.0
		var tw := create_tween()
		if tw:
			tw.tween_property(target, "modulate:a", 1.0, 0.15)
	elif target:
		target.modulate.a = 1.0

# ══════════════════════════════════════════════════════════════════════════════
# FLUJO PRE-PARTIDA: Dificultad → Instrucciones → Juego (Precondiciones 5 y 6)
# ══════════════════════════════════════════════════════════════════════════════

func _show_difficulty_selector() -> void:
	state = State.DIFFICULTY
	_reset_board()
	_show_overlay(difficulty_overlay)


func _on_difficulty_selected(diff: String) -> void:
	AudioManager.play_click()
	selected_difficulty = diff
	var cfg: Dictionary = DIFFICULTY_CONFIG.get(diff, DIFFICULTY_CONFIG["NORMAL"])
	max_lives = cfg["lives"]
	points_per_hit = cfg["points"]
	game_duration = cfg["time"]
	reaction_time = cfg["reaction"]

	var diff_names := {"FACIL": "FÁCIL", "NORMAL": "NORMAL", "INGENIERO": "INGENIERO"}
	instr_difficulty_label.text = "Dificultad: %s — %d vidas" % [diff_names.get(diff, diff), max_lives]
	state = State.INSTRUCTIONS
	_show_overlay(instructions_overlay)


func _on_start_pressed() -> void:
	AudioManager.play_click()
	_start_game_play()


func _start_game_play() -> void:
	super.start_game(selected_difficulty)

	score = 0
	total_answered = 0
	total_correct = 0
	current_lives = max_lives
	time_remaining = game_duration
	scenario_bag.clear()

	global_bar.max_value = game_duration
	global_fill_tier = -1
	question_bar.max_value = reaction_time
	_update_hud()
	_update_global_timer()

	_show_overlay(null)
	# Diagrama de secuencia: "Manda a iniciar el minijuego" → EventBus
	EventBus.minigame_started.emit(minigame_id, selected_difficulty)
	_next_scenario()

# ══════════════════════════════════════════════════════════════════════════════
# LÓGICA DEL JUEGO
# ══════════════════════════════════════════════════════════════════════════════

## FN-01: presenta un nuevo par de casos de uso.
func _next_scenario() -> void:
	if current_lives <= 0:
		_handle_game_over()
		return

	current_scenario = _draw_scenario()
	context_label.text = str(current_scenario.get("contexto", ""))
	uc_base_label.text = str(current_scenario.get("cu_base", "Caso base"))
	uc_related_label.text = str(current_scenario.get("cu_relacionado", "Caso relacionado"))
	rule_label.text = "\"%s\"" % str(current_scenario.get("regla", ""))
	relation_arrow.set_mode(RelationArrowScript.Mode.NEUTRAL, COL_CHALK)
	feedback_label.text = "¿Cuál es la relación?"
	feedback_label.add_theme_color_override("font_color", COL_CHALK_DIM)

	question_time_remaining = reaction_time
	_update_question_timer()
	_set_answer_buttons_enabled(true)
	state = State.QUESTION


## FN-02: el alumno selecciona la relación.
func _on_answer_pressed(answer: String) -> void:
	if state != State.QUESTION:
		return
	total_answered += 1
	var correct: String = str(current_scenario.get("relacion", "include"))
	if answer == correct:
		_register_success()
	else:
		_register_failure("✘ Incorrecto")


## FA-02.03: se agotó el tiempo de reacción de la pregunta.
func _on_question_timeout() -> void:
	if state != State.QUESTION:
		return
	total_answered += 1
	_register_failure("⏱ ¡Tiempo agotado!")


## FN-03: respuesta correcta → suma puntos (en sesión) y nuevo escenario.
func _register_success() -> void:
	total_correct += 1
	score += points_per_hit
	AudioManager.play_success()
	_update_hud()
	_show_floating_text("+%d" % points_per_hit, COL_OK, score_label.get_global_rect().position + Vector2(0, 24))
	_pulse(score_label)
	_reveal_answer(true, "✔ ¡Correcto!")


## FA-02.02 / FA-02.03: registra el fallo y descuenta una vida.
func _register_failure(title: String) -> void:
	AudioManager.play_error()
	current_lives = maxi(0, current_lives - 1)
	_update_hud()
	EventBus.life_lost.emit(current_lives)
	_flash_screen(COL_ERR)
	_shake_screen()
	_pulse(lives_label)
	_reveal_answer(false, title)


## Retroalimentación didáctica: muestra la flecha UML correcta y la explicación.
func _reveal_answer(was_correct: bool, title: String) -> void:
	state = State.FEEDBACK
	feedback_time_remaining = FEEDBACK_TIME_OK if was_correct else FEEDBACK_TIME_FAIL
	_set_answer_buttons_enabled(false)

	var correct: String = str(current_scenario.get("relacion", "include"))
	var color: Color = COL_OK if was_correct else COL_ERR
	var arrow_mode: int = RelationArrowScript.Mode.INCLUDE if correct == "include" else RelationArrowScript.Mode.EXTEND
	relation_arrow.set_mode(arrow_mode, color.lightened(0.2))

	feedback_label.text = "%s\n%s" % [title, str(current_scenario.get("explicacion", ""))]
	feedback_label.add_theme_color_override("font_color", color.lightened(0.25))

	# Resaltar el botón con la respuesta correcta
	var correct_btn: Button = btn_include if correct == "include" else btn_extend
	correct_btn.modulate = Color(1.3, 1.3, 1.3)

# ══════════════════════════════════════════════════════════════════════════════
# FIN DE PARTIDA / PAUSA
# ══════════════════════════════════════════════════════════════════════════════

## FA-02.04: vidas en cero → fin anticipado. Se guarda el puntaje obtenido (igual que CU-07).
func _handle_game_over() -> void:
	state = State.GAME_OVER
	_set_answer_buttons_enabled(false)
	AudioManager.play_game_over()
	EventBus.game_over.emit(minigame_id)

	finish_game(false, score, 0, "Sin vidas — %d/%d aciertos" % [total_correct, total_answered])

	if is_instance_valid(game_over_score_label):
		game_over_score_label.text = "Puntaje: %d" % score
	if is_instance_valid(game_over_stats_label):
		game_over_stats_label.text = _stats_text()
	_show_overlay(game_over_overlay)


## FN-05: el temporizador global terminó con vidas restantes → victoria.
func _handle_victory() -> void:
	state = State.VICTORY
	_set_answer_buttons_enabled(false)
	AudioManager.play_success()

	var stars: int = _calculate_stars()
	# Registra resultado → StateManager guarda partida (user://pixeling_save.json) → EventBus notifica
	finish_game(true, score, stars, "¡Relaciones UML identificadas! %d/%d aciertos" % [total_correct, total_answered])

	if is_instance_valid(victory_stars_label):
		victory_stars_label.text = "⭐".repeat(stars) + "☆".repeat(3 - stars)
	if is_instance_valid(victory_score_label):
		victory_score_label.text = "Puntaje: %d" % score
	if is_instance_valid(victory_stats_label):
		victory_stats_label.text = _stats_text()
	_show_overlay(victory_overlay)


## Estrellas por precisión: ≥80% ⭐⭐⭐ · ≥60% ⭐⭐ · sobrevivir ⭐.
func _calculate_stars() -> int:
	if total_answered == 0:
		return 1
	var accuracy: float = float(total_correct) / float(total_answered)
	if accuracy >= 0.8:
		return 3
	elif accuracy >= 0.6:
		return 2
	return 1


func _stats_text() -> String:
	var accuracy: int = 0
	if total_answered > 0:
		accuracy = int(round(100.0 * total_correct / total_answered))
	return "Aciertos: %d/%d  ·  Precisión: %d%%" % [total_correct, total_answered, accuracy]


## FA-02.01: pausa / reanuda. Los temporizadores se congelan porque _process solo
## avanza en QUESTION/FEEDBACK. Al reanudar se vuelve exactamente al estado previo (FN-02).
func _toggle_pause() -> void:
	if state == State.PAUSED:
		state = state_before_pause
		_show_overlay(null)
		AudioManager.play_click()
	elif _is_playing():
		state_before_pause = state
		state = State.PAUSED
		_show_overlay(pause_overlay)
		AudioManager.play_click()


func _is_playing() -> bool:
	return state == State.QUESTION or state == State.FEEDBACK

# ══════════════════════════════════════════════════════════════════════════════
# TEMPORIZADORES Y HUD
# ══════════════════════════════════════════════════════════════════════════════

## Descuenta el reloj global. Devuelve true si la actividad terminó (FN-04 → FN-05).
func _tick_global_timer(delta: float) -> bool:
	time_remaining -= delta
	_update_global_timer()
	if time_remaining <= 0.0:
		time_remaining = 0.0
		_handle_victory()
		return true
	return false


func _update_global_timer() -> void:
	global_bar.value = maxf(time_remaining, 0.0)
	var secs: int = ceili(maxf(time_remaining, 0.0))
	global_time_label.text = "%d:%02d" % [secs / 60, secs % 60]

	var ratio: float = time_remaining / game_duration if game_duration > 0.0 else 0.0
	var tier: int = 0 if ratio > 0.5 else (1 if ratio > 0.25 else 2)
	if tier != global_fill_tier:
		global_fill_tier = tier
		global_bar.add_theme_stylebox_override("fill", global_fill_styles[tier])


func _update_question_timer() -> void:
	var t: float = maxf(question_time_remaining, 0.0)
	question_bar.value = t
	question_time_label.text = "%ds" % ceili(t)
	var danger: bool = t <= 2.0
	question_bar.add_theme_stylebox_override("fill", question_fill_danger if danger else question_fill_ok)
	# Parpadeo en los últimos 2 segundos
	question_time_label.modulate.a = (0.4 + 0.6 * absf(sin(t * 8.0))) if danger else 1.0
	question_time_label.add_theme_color_override("font_color", COL_ERR if danger else COL_CHALK)


func _update_hud() -> void:
	lives_label.text = "❤ %d/%d" % [current_lives, max_lives]
	score_label.text = "🪙 %d" % score


func _set_answer_buttons_enabled(enabled: bool) -> void:
	btn_include.disabled = not enabled
	btn_extend.disabled = not enabled
	btn_include.modulate = Color.WHITE
	btn_extend.modulate = Color.WHITE


func _reset_board() -> void:
	context_label.text = ""
	uc_base_label.text = "Caso base"
	uc_related_label.text = "Caso relacionado"
	rule_label.text = ""
	feedback_label.text = ""
	relation_arrow.set_mode(RelationArrowScript.Mode.NEUTRAL, COL_CHALK)
	_set_answer_buttons_enabled(false)

# ══════════════════════════════════════════════════════════════════════════════
# MICRO-ANIMACIONES
# ══════════════════════════════════════════════════════════════════════════════

func _show_floating_text(text: String, color: Color, pos: Vector2) -> void:
	var lbl := _make_label(text, 16, color)
	lbl.position = pos
	lbl.z_index = 20
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)
	var tween := create_tween()
	tween.tween_property(lbl, "position:y", pos.y + 30.0, 0.7)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 0.7)
	tween.tween_callback(lbl.queue_free)


func _flash_screen(color: Color) -> void:
	var flash := ColorRect.new()
	flash.color = Color(color.r, color.g, color.b, 0.25)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 15
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)


func _shake_screen() -> void:
	var tween := create_tween()
	for offset in [Vector2(-6, 0), Vector2(5, 0), Vector2(-3, 0), Vector2(2, 0), Vector2.ZERO]:
		tween.tween_property(content_root, "position", offset, 0.04)


func _pulse(node: Control) -> void:
	node.pivot_offset = node.size / 2.0
	var tween := create_tween()
	tween.tween_property(node, "scale", Vector2(1.3, 1.3), 0.08)
	tween.tween_property(node, "scale", Vector2.ONE, 0.12)

# ══════════════════════════════════════════════════════════════════════════════
# NAVEGACIÓN
# ══════════════════════════════════════════════════════════════════════════════

func _on_hud_back_pressed() -> void:
	# Durante la partida, "Volver" abre la pausa para evitar salidas accidentales.
	if _is_playing():
		_toggle_pause()
	else:
		_go_to_classroom()


## FA-02.04: reinicio inmediato con la misma dificultad.
func _on_retry_pressed() -> void:
	AudioManager.play_click()
	_start_game_play()


func _go_to_classroom() -> void:
	AudioManager.play_click()
	state = State.DIFFICULTY
	if ResourceLoader.exists(CLASSROOM_SCENE):
		get_tree().change_scene_to_file(CLASSROOM_SCENE)
	else:
		get_tree().change_scene_to_file(LOBBY_SCENE)


func _go_to_campus() -> void:
	AudioManager.play_click()
	state = State.DIFFICULTY
	get_tree().change_scene_to_file(LOBBY_SCENE)
