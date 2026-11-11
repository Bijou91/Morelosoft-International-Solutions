## HeroForge.gd - CU-12: Practicar a crear Clases, Objetos y Atributos
## Morelosoft International Solutions - Aula 101: Introducción a la Programación
## Cumple estrictamente con el Diagrama de Secuencia V2 y la Especificación de Casos de Uso (TSP / ISO 29110)
## Responsable: Carlos Manuel Aguirre Norato (Líder Técnico & Software Architect)
extends MiniGameBase

const HeroForgeData = preload("res://scenes/minigames/programacion/heroforge/HeroForgeData.gd")

# ══════════════════════════════════════════════════════════════════════════════
# ESTADO DEL MINIJUEGO
# ══════════════════════════════════════════════════════════════════════════════

var selected_diff: String = "NORMAL"
var diff_config: Dictionary = {}

var hero_classes_queue: Array[Dictionary] = []
var current_hero_index: int = 0
var current_hero: Dictionary = {}
var current_tier_data: Dictionary = {}

# Slots de la Plantilla de Clase (1 en Fácil, 2 en Normal, 3 en Ingeniero)
var required_slots: int = 2
var assigned_attributes: Array = []
var assigned_methods: Array = []

# Banco de Componentes de la ronda (Unificado y mezclado para retar la distinción Atributo/Método)
var bank_all_components: Array[Dictionary] = []
var selected_target_slot: Dictionary = {}
var pending_item_to_assign: Dictionary = {}

# Métricas de partida
var max_lives: int = 3
var current_lives: int = 3
var round_time: float = 45.0
var time_left: float = 45.0
var is_timer_running: bool = false
var is_game_paused: bool = false
var total_score: int = 0
var points_per_char: int = 125
var target_stars: int = 2

# ══════════════════════════════════════════════════════════════════════════════
# NODOS Y CONTENEDORES DE PANTALLA
# ══════════════════════════════════════════════════════════════════════════════

var bg_rect: ColorRect
var screen_start: Control
var screen_game: Control
var screen_pause: Control
var screen_victory: Control
var screen_game_over: Control

# Sub-vistas de ScreenStart
var container_instructions: VBoxContainer
var container_difficulty: VBoxContainer
var lbl_diff_summary: Label
var btn_start_game: Button

# Nodos de ScreenGame (HUD Superior)
var hud_pause_btn: Button
var hud_round_lbl: Label
var hud_timer_lbl: Label
var hud_lives_lbl: Label
var hud_score_lbl: Label
var timer_progress: ProgressBar

# Nodos de Mesa de Forja (Plantilla de Clase)
var hero_badge_lbl: Label
var hero_concept_lbl: Label
var attr_slots_vbox: VBoxContainer
var meth_slots_vbox: VBoxContainer
var attr_slot_buttons: Array[Button] = []
var meth_slot_buttons: Array[Button] = []

# Nodos del Banco de Componentes y Selector de Destino
var bank_grid: GridContainer
var assign_dialog_panel: PanelContainer
var lbl_assign_prompt: Label
var btn_to_attr: Button
var btn_to_meth: Button
var btn_cancel_assign: Button

var btn_instantiate: Button
var status_banner_lbl: Label

# Pantalla de Pausa
var btn_pause_resume: Button
var btn_pause_restart: Button
var btn_pause_back: Button

# Pantalla de Victoria y Derrota
var lbl_victory_stats: Label
var btn_victory_restart: Button
var btn_victory_back: Button
var lbl_gameover_reason: Label
var btn_gameover_restart: Button
var btn_gameover_back: Button

func _ready() -> void:
	minigame_id = "heroforge"
	cu_id = "CU-12"
	minigame_title = "HeroForge"
	subject_name = "Programación"
	super._ready()
	_build_ui()
	_show_screen(screen_start)
	_show_instructions_step()

func _process(delta: float) -> void:
	if is_timer_running and not is_game_paused:
		time_left -= delta
		if time_left <= 0.0:
			time_left = 0.0
			_on_round_timer_timeout()
		_update_hud()

# Atajos de depuración para agilizar auditoría TSP / QA
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if screen_game.visible:
				_on_pause_pressed()
			elif screen_pause.visible:
				_on_resume_pressed()
		elif event.keycode == KEY_F8:
			_trigger_debug_win()

# ══════════════════════════════════════════════════════════════════════════════
# CONSTRUCCIÓN DE LA INTERFAZ DE USUARIO (VIEWPORT 360x640)
# ══════════════════════════════════════════════════════════════════════════════

func _build_ui() -> void:
	# Fondo institucional oscuro
	bg_rect = ColorRect.new()
	bg_rect.color = Color(0.06, 0.08, 0.12, 1.0)
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)

	_build_screen_start()
	_build_screen_game()
	_build_screen_pause()
	_build_screen_victory()
	_build_screen_game_over()

func _show_screen(target_screen: Control) -> void:
	screen_start.visible = (target_screen == screen_start)
	screen_game.visible = (target_screen == screen_game)
	screen_pause.visible = (target_screen == screen_pause)
	screen_victory.visible = (target_screen == screen_victory)
	screen_game_over.visible = (target_screen == screen_game_over)

# ── ScreenStart: Flujo didáctico de dos pasos (Instrucciones POO -> Dificultad) ──
func _build_screen_start() -> void:
	screen_start = Control.new()
	screen_start.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(screen_start)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	screen_start.add_child(scroll)

	var scroll_margin := MarginContainer.new()
	scroll_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_margin.add_theme_constant_override("margin_left", 12)
	scroll_margin.add_theme_constant_override("margin_right", 12)
	scroll_margin.add_theme_constant_override("margin_top", 12)
	scroll_margin.add_theme_constant_override("margin_bottom", 12)
	scroll.add_child(scroll_margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.add_theme_constant_override("separation", 10)
	scroll_margin.add_child(root_vbox)

	# Cabecera
	var title_lbl := Label.new()
	title_lbl.text = "🏛️ HeroForge: Taller de Clases y Objetos"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.add_theme_color_override("font_color", Color("00e5ff"))
	root_vbox.add_child(title_lbl)

	var subtitle_lbl := Label.new()
	subtitle_lbl.text = "CU-12: Aula 101 - Programación Orientada a Objetos"
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_lbl.add_theme_font_size_override("font_size", 10)
	subtitle_lbl.add_theme_color_override("font_color", Color("90a4ae"))
	root_vbox.add_child(subtitle_lbl)

	# ── Paso 1: Contenedor de Instrucciones de POO ──
	container_instructions = VBoxContainer.new()
	container_instructions.add_theme_constant_override("separation", 8)
	root_vbox.add_child(container_instructions)

	var oop_card := PanelContainer.new()
	var oop_style := StyleBoxFlat.new()
	oop_style.bg_color = Color("1a202c")
	oop_style.border_color = Color("2d3748")
	oop_style.set_border_width_all(1)
	oop_style.set_corner_radius_all(6)
	oop_card.add_theme_stylebox_override("panel", oop_style)
	container_instructions.add_child(oop_card)

	var oop_margin := MarginContainer.new()
	oop_margin.add_theme_constant_override("margin_left", 10)
	oop_margin.add_theme_constant_override("margin_right", 10)
	oop_margin.add_theme_constant_override("margin_top", 8)
	oop_margin.add_theme_constant_override("margin_bottom", 8)
	oop_card.add_child(oop_margin)

	var oop_vbox := VBoxContainer.new()
	oop_vbox.add_theme_constant_override("separation", 6)
	oop_margin.add_child(oop_vbox)

	var oop_head := Label.new()
	oop_head.text = "📘 Conceptos Clave de POO:"
	oop_head.add_theme_font_size_override("font_size", 12)
	oop_head.add_theme_color_override("font_color", Color("ffd54f"))
	oop_vbox.add_child(oop_head)

	var oop_body := Label.new()
	oop_body.text = "• Clase: El molde o plano que define las características y acciones de un tipo de héroe.\n• Objeto: El personaje instanciado en memoria a partir de su clase.\n• Atributos (Lado Izquierdo): Variables que describen su estado (clave = valor).\n• Métodos (Lado Derecho): Funciones que definen sus acciones (verbo())."
	oop_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	oop_body.add_theme_font_size_override("font_size", 10)
	oop_body.add_theme_color_override("font_color", Color("eceff1"))
	oop_vbox.add_child(oop_body)

	# Instrucciones didácticas
	var inst_card := PanelContainer.new()
	var inst_style := StyleBoxFlat.new()
	inst_style.bg_color = Color("101622")
	inst_style.border_color = Color("1e293b")
	inst_style.set_border_width_all(1)
	inst_style.set_corner_radius_all(6)
	inst_card.add_theme_stylebox_override("panel", inst_style)
	container_instructions.add_child(inst_card)

	var inst_margin := MarginContainer.new()
	inst_margin.add_theme_constant_override("margin_left", 10)
	inst_margin.add_theme_constant_override("margin_right", 10)
	inst_margin.add_theme_constant_override("margin_top", 8)
	inst_margin.add_theme_constant_override("margin_bottom", 8)
	inst_card.add_child(inst_margin)

	var inst_text := Label.new()
	inst_text.text = "🎯 Reglas del Taller:\n\n1. Lee la descripción de la clase solicitada.\n2. Lado Izquierdo (Azul): Asigna Atributos.\n3. Lado Derecho (Amarillo): Asigna Métodos.\n4. Toca cualquier slot ocupado para retirar la pieza sin penalización.\n5. Presiona '¡Instanciar Objeto!' para forjarlo. ¡Cuidado con los distractores!"
	inst_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inst_text.add_theme_font_size_override("font_size", 10)
	inst_text.add_theme_color_override("font_color", Color("cfd8dc"))
	inst_margin.add_child(inst_text)

	var btn_to_diff := Button.new()
	btn_to_diff.text = "Siguiente: Elegir Dificultad →"
	btn_to_diff.custom_minimum_size = Vector2(0, 42)
	btn_to_diff.add_theme_font_size_override("font_size", 12)
	btn_to_diff.pressed.connect(_show_difficulty_step)
	container_instructions.add_child(btn_to_diff)

	var btn_exit_inst := Button.new()
	btn_exit_inst.text = "← Volver al Salón 101"
	btn_exit_inst.custom_minimum_size = Vector2(0, 36)
	btn_exit_inst.add_theme_font_size_override("font_size", 11)
	btn_exit_inst.pressed.connect(_on_back_pressed)
	container_instructions.add_child(btn_exit_inst)

	# ── Paso 2: Contenedor de Selección de Dificultad ──
	container_difficulty = VBoxContainer.new()
	container_difficulty.add_theme_constant_override("separation", 10)
	root_vbox.add_child(container_difficulty)

	var diff_label := Label.new()
	diff_label.text = "Elige la Dificultad de la Forja:"
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_label.add_theme_font_size_override("font_size", 13)
	container_difficulty.add_child(diff_label)

	var diff_btn_hbox := HBoxContainer.new()
	diff_btn_hbox.add_theme_constant_override("separation", 6)
	container_difficulty.add_child(diff_btn_hbox)

	var btn_facil := Button.new()
	btn_facil.text = "Fácil"
	btn_facil.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_facil.custom_minimum_size = Vector2(0, 38)
	btn_facil.pressed.connect(func(): _select_difficulty("FACIL"))
	diff_btn_hbox.add_child(btn_facil)

	var btn_normal := Button.new()
	btn_normal.text = "Normal"
	btn_normal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_normal.custom_minimum_size = Vector2(0, 38)
	btn_normal.pressed.connect(func(): _select_difficulty("NORMAL"))
	diff_btn_hbox.add_child(btn_normal)

	var btn_ingeniero := Button.new()
	btn_ingeniero.text = "Ingeniero"
	btn_ingeniero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_ingeniero.custom_minimum_size = Vector2(0, 38)
	btn_ingeniero.pressed.connect(func(): _select_difficulty("INGENIERO"))
	diff_btn_hbox.add_child(btn_ingeniero)

	var summary_card := PanelContainer.new()
	var sum_style := StyleBoxFlat.new()
	sum_style.bg_color = Color("141822")
	sum_style.border_color = Color("38bdf8")
	sum_style.set_border_width_all(1)
	sum_style.set_corner_radius_all(6)
	summary_card.add_theme_stylebox_override("panel", sum_style)
	container_difficulty.add_child(summary_card)

	var sum_margin := MarginContainer.new()
	sum_margin.add_theme_constant_override("margin_left", 8)
	sum_margin.add_theme_constant_override("margin_right", 8)
	sum_margin.add_theme_constant_override("margin_top", 8)
	sum_margin.add_theme_constant_override("margin_bottom", 8)
	summary_card.add_child(sum_margin)

	lbl_diff_summary = Label.new()
	lbl_diff_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_diff_summary.add_theme_font_size_override("font_size", 10)
	lbl_diff_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sum_margin.add_child(lbl_diff_summary)

	btn_start_game = Button.new()
	btn_start_game.text = "▶ ¡COMENZAR LA FORJA!"
	btn_start_game.custom_minimum_size = Vector2(0, 44)
	btn_start_game.add_theme_font_size_override("font_size", 13)
	btn_start_game.pressed.connect(_on_start_pressed)
	container_difficulty.add_child(btn_start_game)

	var btn_back_to_inst := Button.new()
	btn_back_to_inst.text = "← Ver Instrucciones"
	btn_back_to_inst.custom_minimum_size = Vector2(0, 34)
	btn_back_to_inst.add_theme_font_size_override("font_size", 11)
	btn_back_to_inst.pressed.connect(_show_instructions_step)
	container_difficulty.add_child(btn_back_to_inst)

	_select_difficulty("NORMAL")

func _show_instructions_step() -> void:
	container_instructions.visible = true
	container_difficulty.visible = false

func _show_difficulty_step() -> void:
	container_instructions.visible = false
	container_difficulty.visible = true

# ── ScreenGame: Mesa de Forja Interactiva (Atributos Izquierda / Métodos Derecha) ──
func _build_screen_game() -> void:
	screen_game = Control.new()
	screen_game.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_game.visible = false
	add_child(screen_game)

	var game_vbox := VBoxContainer.new()
	game_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_vbox.add_theme_constant_override("separation", 6)
	screen_game.add_child(game_vbox)

	# ── TopHUD (Barra superior) ──
	var hud_panel := PanelContainer.new()
	var hud_style := StyleBoxFlat.new()
	hud_style.bg_color = Color("161b22")
	hud_style.set_border_width_all(1)
	hud_style.border_color = Color("30363d")
	hud_panel.add_theme_stylebox_override("panel", hud_style)
	game_vbox.add_child(hud_panel)

	var hud_margin := MarginContainer.new()
	hud_margin.add_theme_constant_override("margin_left", 8)
	hud_margin.add_theme_constant_override("margin_right", 8)
	hud_margin.add_theme_constant_override("margin_top", 4)
	hud_margin.add_theme_constant_override("margin_bottom", 4)
	hud_panel.add_child(hud_margin)

	var hud_hbox := HBoxContainer.new()
	hud_hbox.add_theme_constant_override("separation", 6)
	hud_margin.add_child(hud_hbox)

	hud_pause_btn = Button.new()
	hud_pause_btn.text = "⏸️"
	hud_pause_btn.custom_minimum_size = Vector2(32, 28)
	hud_pause_btn.pressed.connect(_on_pause_pressed)
	hud_hbox.add_child(hud_pause_btn)

	hud_round_lbl = Label.new()
	hud_round_lbl.text = "Héroe 1/4"
	hud_round_lbl.add_theme_font_size_override("font_size", 10)
	hud_round_lbl.add_theme_color_override("font_color", Color("ffd54f"))
	hud_hbox.add_child(hud_round_lbl)

	hud_timer_lbl = Label.new()
	hud_timer_lbl.text = "⏱️ 45s"
	hud_timer_lbl.add_theme_font_size_override("font_size", 10)
	hud_timer_lbl.add_theme_color_override("font_color", Color("40c4ff"))
	hud_hbox.add_child(hud_timer_lbl)

	hud_lives_lbl = Label.new()
	hud_lives_lbl.text = "❤️❤️❤️"
	hud_lives_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud_lives_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_lives_lbl.add_theme_font_size_override("font_size", 10)
	hud_hbox.add_child(hud_lives_lbl)

	hud_score_lbl = Label.new()
	hud_score_lbl.text = "0 pts"
	hud_score_lbl.add_theme_font_size_override("font_size", 10)
	hud_score_lbl.add_theme_color_override("font_color", Color("69f0ae"))
	hud_hbox.add_child(hud_score_lbl)

	# Barra de progreso del tiempo
	timer_progress = ProgressBar.new()
	timer_progress.custom_minimum_size = Vector2(0, 4)
	timer_progress.show_percentage = false
	timer_progress.value = 100.0
	game_vbox.add_child(timer_progress)

	# Área desplazable de juego
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	game_vbox.add_child(scroll)

	var scroll_margin := MarginContainer.new()
	scroll_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_margin.add_theme_constant_override("margin_left", 8)
	scroll_margin.add_theme_constant_override("margin_right", 8)
	scroll_margin.add_theme_constant_override("margin_top", 4)
	scroll_margin.add_theme_constant_override("margin_bottom", 6)
	scroll.add_child(scroll_margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 6)
	scroll_margin.add_child(main_vbox)

	# Ficha del Personaje (Cabecera de Clase)
	var char_header_panel := PanelContainer.new()
	var char_style := StyleBoxFlat.new()
	char_style.bg_color = Color("1a202c")
	char_style.border_color = Color("2d3748")
	char_style.set_border_width_all(1)
	char_style.set_corner_radius_all(6)
	char_header_panel.add_theme_stylebox_override("panel", char_style)
	main_vbox.add_child(char_header_panel)

	var ch_margin := MarginContainer.new()
	ch_margin.add_theme_constant_override("margin_left", 8)
	ch_margin.add_theme_constant_override("margin_right", 8)
	ch_margin.add_theme_constant_override("margin_top", 4)
	ch_margin.add_theme_constant_override("margin_bottom", 4)
	char_header_panel.add_child(ch_margin)

	var ch_vbox := VBoxContainer.new()
	ch_vbox.add_theme_constant_override("separation", 2)
	ch_margin.add_child(ch_vbox)

	hero_badge_lbl = Label.new()
	hero_badge_lbl.text = "class MagoIgneo:"
	hero_badge_lbl.add_theme_font_size_override("font_size", 13)
	hero_badge_lbl.add_theme_color_override("font_color", Color("00e5ff"))
	ch_vbox.add_child(hero_badge_lbl)

	hero_concept_lbl = Label.new()
	hero_concept_lbl.text = "Especialista arcano en piromancia..."
	hero_concept_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_concept_lbl.add_theme_font_size_override("font_size", 9)
	hero_concept_lbl.add_theme_color_override("font_color", Color("a0aec0"))
	ch_vbox.add_child(hero_concept_lbl)

	# Plantilla de la Clase (Columnas: Lado Izquierdo = Atributos | Lado Derecho = Métodos)
	var blueprint_panel := PanelContainer.new()
	var bp_style := StyleBoxFlat.new()
	bp_style.bg_color = Color("141822")
	bp_style.border_color = Color("00e5ff")
	bp_style.set_border_width_all(1)
	bp_style.set_corner_radius_all(6)
	blueprint_panel.add_theme_stylebox_override("panel", bp_style)
	main_vbox.add_child(blueprint_panel)

	var bp_margin := MarginContainer.new()
	bp_margin.add_theme_constant_override("margin_left", 8)
	bp_margin.add_theme_constant_override("margin_right", 8)
	bp_margin.add_theme_constant_override("margin_top", 6)
	bp_margin.add_theme_constant_override("margin_bottom", 6)
	blueprint_panel.add_child(bp_margin)

	var bp_columns := HBoxContainer.new()
	bp_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bp_columns.add_theme_constant_override("separation", 8)
	bp_margin.add_child(bp_columns)

	# Columna Izquierda: Atributos
	var attr_col := VBoxContainer.new()
	attr_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attr_col.add_theme_constant_override("separation", 3)
	bp_columns.add_child(attr_col)

	var attr_title := Label.new()
	attr_title.text = "# ATRIBUTOS:"
	attr_title.add_theme_font_size_override("font_size", 10)
	attr_title.add_theme_color_override("font_color", Color("80d8ff"))
	attr_col.add_child(attr_title)

	var attr_subtitle := Label.new()
	attr_subtitle.text = "(Variables de Estado)"
	attr_subtitle.add_theme_font_size_override("font_size", 8)
	attr_subtitle.add_theme_color_override("font_color", Color("90a4ae"))
	attr_col.add_child(attr_subtitle)

	attr_slots_vbox = VBoxContainer.new()
	attr_slots_vbox.add_theme_constant_override("separation", 4)
	attr_col.add_child(attr_slots_vbox)

	# Columna Derecha: Métodos
	var meth_col := VBoxContainer.new()
	meth_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meth_col.add_theme_constant_override("separation", 3)
	bp_columns.add_child(meth_col)

	var meth_title := Label.new()
	meth_title.text = "# MÉTODOS:"
	meth_title.add_theme_font_size_override("font_size", 10)
	meth_title.add_theme_color_override("font_color", Color("ffe57f"))
	meth_col.add_child(meth_title)

	var meth_subtitle := Label.new()
	meth_subtitle.text = "(Funciones / Acciones)"
	meth_subtitle.add_theme_font_size_override("font_size", 8)
	meth_subtitle.add_theme_color_override("font_color", Color("90a4ae"))
	meth_col.add_child(meth_subtitle)

	meth_slots_vbox = VBoxContainer.new()
	meth_slots_vbox.add_theme_constant_override("separation", 4)
	meth_col.add_child(meth_slots_vbox)

	# Banco de Componentes Disponibles (Mezclados en Grid de 2 columnas)
	var bank_header := Label.new()
	bank_header.text = "Banco de Componentes (Toca un componente para asignarlo):"
	bank_header.add_theme_font_size_override("font_size", 10)
	bank_header.add_theme_color_override("font_color", Color("e2e8f0"))
	main_vbox.add_child(bank_header)

	bank_grid = GridContainer.new()
	bank_grid.columns = 2
	bank_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_grid.add_theme_constant_override("h_separation", 6)
	bank_grid.add_theme_constant_override("v_separation", 4)
	main_vbox.add_child(bank_grid)

	# Mini-diálogo de selección de destino (¿Atributo o Método?)
	assign_dialog_panel = PanelContainer.new()
	var as_style := StyleBoxFlat.new()
	as_style.bg_color = Color("1a2233")
	as_style.border_color = Color("40c4ff")
	as_style.set_border_width_all(2)
	as_style.set_corner_radius_all(6)
	assign_dialog_panel.add_theme_stylebox_override("panel", as_style)
	assign_dialog_panel.visible = false
	main_vbox.add_child(assign_dialog_panel)

	var as_margin := MarginContainer.new()
	as_margin.add_theme_constant_override("margin_left", 8)
	as_margin.add_theme_constant_override("margin_right", 8)
	as_margin.add_theme_constant_override("margin_top", 6)
	as_margin.add_theme_constant_override("margin_bottom", 6)
	assign_dialog_panel.add_child(as_margin)

	var as_vbox := VBoxContainer.new()
	as_vbox.add_theme_constant_override("separation", 6)
	as_margin.add_child(as_vbox)

	lbl_assign_prompt = Label.new()
	lbl_assign_prompt.text = "¿Dónde deseas asignar este componente?"
	lbl_assign_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_assign_prompt.add_theme_font_size_override("font_size", 9)
	lbl_assign_prompt.add_theme_color_override("font_color", Color("eceff1"))
	lbl_assign_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	as_vbox.add_child(lbl_assign_prompt)

	var as_hbox := HBoxContainer.new()
	as_hbox.add_theme_constant_override("separation", 6)
	as_vbox.add_child(as_hbox)

	btn_to_attr = Button.new()
	btn_to_attr.text = "⬅️ Como ATRIBUTO"
	btn_to_attr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_to_attr.custom_minimum_size = Vector2(0, 32)
	btn_to_attr.add_theme_font_size_override("font_size", 9)
	btn_to_attr.add_theme_color_override("font_color", Color("80d8ff"))
	btn_to_attr.pressed.connect(func(): _on_target_section_chosen("ATTR"))
	as_hbox.add_child(btn_to_attr)

	btn_to_meth = Button.new()
	btn_to_meth.text = "Como MÉTODO ➡️"
	btn_to_meth.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_to_meth.custom_minimum_size = Vector2(0, 32)
	btn_to_meth.add_theme_font_size_override("font_size", 9)
	btn_to_meth.add_theme_color_override("font_color", Color("ffe57f"))
	btn_to_meth.pressed.connect(func(): _on_target_section_chosen("METH"))
	as_hbox.add_child(btn_to_meth)

	btn_cancel_assign = Button.new()
	btn_cancel_assign.text = "✖"
	btn_cancel_assign.custom_minimum_size = Vector2(30, 32)
	btn_cancel_assign.add_theme_font_size_override("font_size", 10)
	btn_cancel_assign.pressed.connect(func():
		assign_dialog_panel.visible = false
		pending_item_to_assign.clear()
	)
	as_hbox.add_child(btn_cancel_assign)

	# Botón de Acción Principal e Instrucciones
	btn_instantiate = Button.new()
	btn_instantiate.text = "🔨 ¡Instanciar Objeto! (Validar Clase)"
	btn_instantiate.custom_minimum_size = Vector2(0, 40)
	btn_instantiate.add_theme_font_size_override("font_size", 12)
	btn_instantiate.pressed.connect(_on_instantiate_pressed)
	main_vbox.add_child(btn_instantiate)

	status_banner_lbl = Label.new()
	status_banner_lbl.text = "Asigna atributos a la izquierda y métodos a la derecha."
	status_banner_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_banner_lbl.add_theme_font_size_override("font_size", 9)
	status_banner_lbl.add_theme_color_override("font_color", Color("90a4ae"))
	main_vbox.add_child(status_banner_lbl)

# ── ScreenPause: Pausa didáctica ──
func _build_screen_pause() -> void:
	screen_pause = Control.new()
	screen_pause.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_pause.visible = false
	add_child(screen_pause)

	var pause_bg := ColorRect.new()
	pause_bg.color = Color(0.02, 0.04, 0.08, 0.90)
	pause_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_pause.add_child(pause_bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_pause.add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(240, 200)
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)

	var title := Label.new()
	title.text = "⏸️ Partida en Pausa"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("ffd54f"))
	box.add_child(title)

	var desc := Label.new()
	desc.text = "La mesa de forja está detenida."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color("b0bec5"))
	box.add_child(desc)

	btn_pause_resume = Button.new()
	btn_pause_resume.text = "▶ Continuar Forja"
	btn_pause_resume.custom_minimum_size = Vector2(0, 38)
	btn_pause_resume.pressed.connect(_on_resume_pressed)
	box.add_child(btn_pause_resume)

	btn_pause_restart = Button.new()
	btn_pause_restart.text = "🔄 Reiniciar Nivel"
	btn_pause_restart.custom_minimum_size = Vector2(0, 36)
	btn_pause_restart.pressed.connect(func():
		_set_game_paused(false)
		start_game(selected_diff)
	)
	box.add_child(btn_pause_restart)

	btn_pause_back = Button.new()
	btn_pause_back.text = "🚪 Volver al Salón 101"
	btn_pause_back.custom_minimum_size = Vector2(0, 36)
	btn_pause_back.pressed.connect(_on_back_pressed)
	box.add_child(btn_pause_back)

# ── ScreenVictory: Pantalla Final de Victoria (Con Botones Volver a Jugar Misma Dificultad y Volver al Aula) ──
func _build_screen_victory() -> void:
	screen_victory = Control.new()
	screen_victory.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_victory.visible = false
	add_child(screen_victory)

	var vic_bg := ColorRect.new()
	vic_bg.color = Color(0.04, 0.07, 0.12, 1.0)
	vic_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_victory.add_child(vic_bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_victory.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(280, 270)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("141c2b")
	card_style.border_color = Color("69f0ae")
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(10)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 14)
	card_margin.add_theme_constant_override("margin_right", 14)
	card_margin.add_theme_constant_override("margin_top", 14)
	card_margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(card_margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	card_margin.add_child(box)

	var title := Label.new()
	title.text = "🎉 ¡Mesa de Forja Superada!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("69f0ae"))
	box.add_child(title)

	lbl_victory_stats = Label.new()
	lbl_victory_stats.text = "Puntaje: 500 pts\nEstrellas: ⭐⭐\nVidas restantes: 3"
	lbl_victory_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_victory_stats.add_theme_font_size_override("font_size", 11)
	lbl_victory_stats.add_theme_color_override("font_color", Color("eceff1"))
	box.add_child(lbl_victory_stats)

	btn_victory_restart = Button.new()
	btn_victory_restart.text = "🔄 Volver a Jugar"
	btn_victory_restart.custom_minimum_size = Vector2(0, 40)
	btn_victory_restart.add_theme_font_size_override("font_size", 12)
	btn_victory_restart.pressed.connect(_on_victory_play_again_pressed)
	box.add_child(btn_victory_restart)

	btn_victory_back = Button.new()
	btn_victory_back.text = "🚪 Volver al Salón 101"
	btn_victory_back.custom_minimum_size = Vector2(0, 38)
	btn_victory_back.add_theme_font_size_override("font_size", 12)
	btn_victory_back.pressed.connect(_on_back_pressed)
	box.add_child(btn_victory_back)

func _on_victory_play_again_pressed() -> void:
	if AudioManager and AudioManager.has_method("play_click"):
		AudioManager.play_click()
	start_game(selected_diff)

# ── ScreenGameOver: Pantalla de Fin de Partida ──
func _build_screen_game_over() -> void:
	screen_game_over = Control.new()
	screen_game_over.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_game_over.visible = false
	add_child(screen_game_over)

	var go_bg := ColorRect.new()
	go_bg.color = Color(0.10, 0.04, 0.04, 0.92)
	go_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_game_over.add_child(go_bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_game_over.add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(260, 240)
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)

	var title := Label.new()
	title.text = "💀 Fin de la Partida"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("f44336"))
	box.add_child(title)

	lbl_gameover_reason = Label.new()
	lbl_gameover_reason.text = "Vidas agotadas"
	lbl_gameover_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_gameover_reason.add_theme_font_size_override("font_size", 11)
	lbl_gameover_reason.add_theme_color_override("font_color", Color("ff8a80"))
	box.add_child(lbl_gameover_reason)

	btn_gameover_restart = Button.new()
	btn_gameover_restart.text = "🔄 Reintentar Forja"
	btn_gameover_restart.custom_minimum_size = Vector2(0, 38)
	btn_gameover_restart.pressed.connect(func():
		start_game(selected_diff)
	)
	box.add_child(btn_gameover_restart)

	btn_gameover_back = Button.new()
	btn_gameover_back.text = "🚪 Volver al Salón 101"
	btn_gameover_back.custom_minimum_size = Vector2(0, 36)
	btn_gameover_back.pressed.connect(_on_back_pressed)
	box.add_child(btn_gameover_back)

# ══════════════════════════════════════════════════════════════════════════════
# CONTROLADORES DE DIFICULTAD Y ESTADO INICIAL
# ══════════════════════════════════════════════════════════════════════════════

func _select_difficulty(diff: String) -> void:
	selected_diff = diff
	diff_config = HeroForgeData.get_difficulty_config(selected_diff)

	var slots_text: String = "%d Atributo(s) y %d Método(s)" % [diff_config.required_slots, diff_config.required_slots]
	var text_summary: String = "⚔️ %s:\n• %d Personajes a Forjar\n• %s por personaje\n• %d Vidas  |  %ds por Ronda\n• %d Puntos Totales (%d pts/héroe)\n• Otorga: %s" % [
		diff_config.name,
		diff_config.characters_count,
		slots_text,
		diff_config.max_lives,
		int(diff_config.round_time),
		diff_config.total_score,
		diff_config.points_per_char,
		"⭐".repeat(diff_config.stars)
	]
	lbl_diff_summary.text = text_summary
	if AudioManager and AudioManager.has_method("play_click"):
		AudioManager.play_click()

# ══════════════════════════════════════════════════════════════════════════════
# FN-01: INICIO DE PARTIDA Y CONFIGURACIÓN DE SESIÓN
# ══════════════════════════════════════════════════════════════════════════════

func _on_start_pressed() -> void:
	if AudioManager and AudioManager.has_method("play_click"):
		AudioManager.play_click()
	start_game(selected_diff)

func start_game(difficulty: String = "NORMAL") -> void:
	super.start_game(difficulty)
	selected_diff = difficulty
	diff_config = HeroForgeData.get_difficulty_config(selected_diff)

	max_lives = diff_config.max_lives
	current_lives = max_lives
	round_time = diff_config.round_time
	target_stars = diff_config.stars
	points_per_char = diff_config.points_per_char
	required_slots = diff_config.required_slots

	total_score = 0
	current_hero_index = 0
	hero_classes_queue = diff_config.classes.duplicate()

	_show_screen(screen_game)

	# FN-01: Inicializar vidas y puntaje
	if EventBus.has_signal("session_started"):
		EventBus.emit_signal("session_started", current_lives, total_score)

	_update_hud()
	_load_class_challenge(0)

func _update_hud() -> void:
	if hud_lives_lbl:
		hud_lives_lbl.text = "❤️".repeat(maxi(0, current_lives))
	if hud_score_lbl:
		hud_score_lbl.text = "%d pts" % total_score
	if hud_timer_lbl:
		hud_timer_lbl.text = "⏱️ %ds" % int(ceil(time_left))
	if timer_progress:
		timer_progress.max_value = round_time
		timer_progress.value = time_left
	if hud_round_lbl and hero_classes_queue.size() > 0:
		hud_round_lbl.text = "Héroe %d/%d" % [mini(current_hero_index + 1, hero_classes_queue.size()), hero_classes_queue.size()]

func _set_status(msg: String, color: Color) -> void:
	if status_banner_lbl:
		status_banner_lbl.text = msg
		status_banner_lbl.add_theme_color_override("font_color", color)

# ══════════════════════════════════════════════════════════════════════════════
# FN-02: CARGA DEL RETO Y MANEJO DE LA MESA DE FORJA
# ══════════════════════════════════════════════════════════════════════════════

func _load_class_challenge(index: int) -> void:
	if index >= hero_classes_queue.size():
		_handle_victory()
		return

	current_hero = hero_classes_queue[index]
	assigned_attributes.clear()
	assigned_attributes.resize(required_slots)
	assigned_attributes.fill(null)

	assigned_methods.clear()
	assigned_methods.resize(required_slots)
	assigned_methods.fill(null)

	time_left = round_time
	is_timer_running = true

	# Generar banco para la dificultad seleccionada
	var bank_pack: Dictionary = HeroForgeData.generate_bank_for_hero(current_hero, selected_diff)
	bank_all_components = bank_pack.all_components
	current_tier_data = bank_pack.tier_data
	selected_target_slot.clear()
	pending_item_to_assign.clear()
	if assign_dialog_panel:
		assign_dialog_panel.visible = false

	# Actualizar cabecera de la clase con el concepto del tier
	hero_badge_lbl.text = "class %s:  [%s]" % [current_hero.class_name, current_hero.avatar_symbol]
	hero_badge_lbl.add_theme_color_override("font_color", current_hero.badge_color)
	hero_concept_lbl.text = current_tier_data.concept

	# Reconstruir slots según required_slots (1, 2 o 3)
	_rebuild_slot_buttons()
	_update_slot_displays()
	_render_component_bank()

	btn_instantiate.disabled = false
	btn_instantiate.text = "🔨 ¡Instanciar Objeto! (Validar Clase)"
	if btn_instantiate.pressed.is_connected(_handle_victory):
		btn_instantiate.pressed.disconnect(_handle_victory)
	if not btn_instantiate.pressed.is_connected(_on_instantiate_pressed):
		btn_instantiate.pressed.connect(_on_instantiate_pressed)
	_set_status("Asigna %d Atributo(s) a la izquierda y %d Método(s) a la derecha." % [required_slots, required_slots], Color("90a4ae"))
	_update_hud()

func _rebuild_slot_buttons() -> void:
	for btn in attr_slots_vbox.get_children():
		btn.queue_free()
	for btn in meth_slots_vbox.get_children():
		btn.queue_free()

	attr_slot_buttons.clear()
	meth_slot_buttons.clear()

	for i in range(required_slots):
		var slot_idx: int = i
		var btn_attr := Button.new()
		btn_attr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_attr.custom_minimum_size = Vector2(0, 36)
		btn_attr.add_theme_font_size_override("font_size", 9)
		btn_attr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn_attr.pressed.connect(func(): _on_slot_button_pressed("ATTR", slot_idx))
		attr_slots_vbox.add_child(btn_attr)
		attr_slot_buttons.append(btn_attr)

		var btn_meth := Button.new()
		btn_meth.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_meth.custom_minimum_size = Vector2(0, 36)
		btn_meth.add_theme_font_size_override("font_size", 9)
		btn_meth.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn_meth.pressed.connect(func(): _on_slot_button_pressed("METH", slot_idx))
		meth_slots_vbox.add_child(btn_meth)
		meth_slot_buttons.append(btn_meth)

func _update_slot_displays() -> void:
	for i in range(required_slots):
		if i >= attr_slot_buttons.size() or i >= meth_slot_buttons.size():
			continue

		var attr_btn := attr_slot_buttons[i]
		attr_btn.remove_theme_stylebox_override("normal")
		var attr_item = assigned_attributes[i]
		if attr_item != null:
			attr_btn.text = "✓ " + attr_item.text
			attr_btn.add_theme_color_override("font_color", Color("80d8ff"))
		elif not selected_target_slot.is_empty() and selected_target_slot.get("section", "") == "ATTR" and selected_target_slot.get("index", -1) == i:
			attr_btn.text = "[ Seleccionar Atributo %d ]" % (i + 1)
			attr_btn.add_theme_color_override("font_color", Color("ffd54f"))
		else:
			attr_btn.text = "[ + Atributo %d ]" % (i + 1)
			attr_btn.add_theme_color_override("font_color", Color("78909c"))

		var meth_btn := meth_slot_buttons[i]
		meth_btn.remove_theme_stylebox_override("normal")
		var meth_item = assigned_methods[i]
		if meth_item != null:
			meth_btn.text = "✓ " + meth_item.text
			meth_btn.add_theme_color_override("font_color", Color("ffea00"))
		elif not selected_target_slot.is_empty() and selected_target_slot.get("section", "") == "METH" and selected_target_slot.get("index", -1) == i:
			meth_btn.text = "[ Seleccionar Método %d ]" % (i + 1)
			meth_btn.add_theme_color_override("font_color", Color("ffd54f"))
		else:
			meth_btn.text = "[ + Método %d ]" % (i + 1)
			meth_btn.add_theme_color_override("font_color", Color("78909c"))

func _render_component_bank() -> void:
	for child in bank_grid.get_children():
		child.queue_free()

	# Renderizar todos los componentes del banco de forma unificada y mezclada
	for i in range(bank_all_components.size()):
		var item: Dictionary = bank_all_components[i]
		var btn := Button.new()
		btn.text = item.text
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 36)
		btn.add_theme_font_size_override("font_size", 9)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.add_theme_color_override("font_color", Color("eceff1")) # Color neutral para retar distinción

		var is_assigned: bool = _is_item_assigned(item.id)
		btn.disabled = is_assigned
		if is_assigned:
			btn.modulate = Color(0.35, 0.35, 0.35, 0.5)
		else:
			btn.modulate = Color.WHITE

		var captured_item: Dictionary = item
		btn.pressed.connect(func(): _on_bank_item_clicked(captured_item))
		bank_grid.add_child(btn)

func _is_item_assigned(item_id: String) -> bool:
	for slot in assigned_attributes:
		if slot != null and slot.id == item_id:
			return true
	for slot in assigned_methods:
		if slot != null and slot.id == item_id:
			return true
	return false

func _play_sfx_select() -> void:
	if AudioManager:
		if AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("select")
		elif AudioManager.has_method("play_click"):
			AudioManager.play_click()

func _on_slot_button_pressed(section: String, slot_index: int) -> void:
	if is_game_paused or not is_timer_running:
		return

	var is_filled: bool = false
	if section == "ATTR" and slot_index < assigned_attributes.size() and assigned_attributes[slot_index] != null:
		is_filled = true
	elif section == "METH" and slot_index < assigned_methods.size() and assigned_methods[slot_index] != null:
		is_filled = true

	if is_filled:
		# FA-02.02: Si ya estaba lleno, remover el elemento
		_on_component_removed(section, slot_index)
	else:
		# Seleccionar slot destino para asignación rápida
		if not selected_target_slot.is_empty() and selected_target_slot.get("section") == section and selected_target_slot.get("index") == slot_index:
			selected_target_slot.clear()
			_set_status("Selección cancelada. Toca un componente del banco para asignarlo.", Color("90a4ae"))
		else:
			selected_target_slot = { "section": section, "index": slot_index }
			_set_status("Ranura de %s %d seleccionada. Toca un componente del banco para asignarlo aquí." % [
				"Atributo" if section == "ATTR" else "Método",
				slot_index + 1
			], Color("ffd54f"))
		if AudioManager and AudioManager.has_method("play_click"):
			AudioManager.play_click()
		_update_slot_displays()

func _on_bank_item_clicked(item: Dictionary) -> void:
	if is_game_paused or not is_timer_running:
		return

	# Si el alumno seleccionó previamente un slot en la plantilla, asignar directamente ahí
	if not selected_target_slot.is_empty():
		var sec: String = selected_target_slot.get("section", "ATTR")
		var idx: int = selected_target_slot.get("index", 0)
		selected_target_slot.clear()
		_assign_item_to_slot(item, sec, idx)
		return

	# Si no seleccionó slot previo, mostrar selector de columna (¿Atributo o Método?)
	pending_item_to_assign = item
	lbl_assign_prompt.text = "¿Dónde deseas asignar \"%s\"?" % item.text
	assign_dialog_panel.visible = true
	if AudioManager and AudioManager.has_method("play_click"):
		AudioManager.play_click()

func _on_target_section_chosen(section: String) -> void:
	assign_dialog_panel.visible = false
	if pending_item_to_assign.is_empty():
		return

	var item: Dictionary = pending_item_to_assign
	pending_item_to_assign = {}

	if section == "ATTR":
		var free_slot: int = -1
		for i in range(required_slots):
			if assigned_attributes[i] == null:
				free_slot = i
				break
		if free_slot != -1:
			_assign_item_to_slot(item, "ATTR", free_slot)
		else:
			_set_status("⚠️ La columna de ATRIBUTOS está llena (%d/%d). Toca uno a la izquierda para quitarlo." % [required_slots, required_slots], Color("ffb74d"))
			if AudioManager and AudioManager.has_method("play_click"):
				AudioManager.play_click()
	elif section == "METH":
		var free_slot: int = -1
		for i in range(required_slots):
			if assigned_methods[i] == null:
				free_slot = i
				break
		if free_slot != -1:
			_assign_item_to_slot(item, "METH", free_slot)
		else:
			_set_status("⚠️ La columna de MÉTODOS está llena (%d/%d). Toca uno a la derecha para quitarlo." % [required_slots, required_slots], Color("ffb74d"))
			if AudioManager and AudioManager.has_method("play_click"):
				AudioManager.play_click()

func _assign_item_to_slot(item: Dictionary, section: String, slot_idx: int) -> void:
	if section == "ATTR" and slot_idx < assigned_attributes.size():
		assigned_attributes[slot_idx] = item
	elif section == "METH" and slot_idx < assigned_methods.size():
		assigned_methods[slot_idx] = item

	_play_sfx_select()
	_update_slot_displays()
	_render_component_bank()
	_set_status("'%s' colocado como %s." % [item.text, "Atributo" if section == "ATTR" else "Método"], Color("90a4ae"))

# FA-02.02: Remoción de elemento asignado sin penalización
func _on_component_removed(section: String, slot_index: int) -> void:
	if is_game_paused or not is_timer_running:
		return

	if section == "ATTR" and slot_index < assigned_attributes.size():
		if assigned_attributes[slot_index] != null:
			assigned_attributes[slot_index] = null
			if AudioManager and AudioManager.has_method("play_click"):
				AudioManager.play_click()
			_update_slot_displays()
			_render_component_bank()
	elif section == "METH" and slot_index < assigned_methods.size():
		if assigned_methods[slot_index] != null:
			assigned_methods[slot_index] = null
			if AudioManager and AudioManager.has_method("play_click"):
				AudioManager.play_click()
			_update_slot_displays()
			_render_component_bank()

# ══════════════════════════════════════════════════════════════════════════════
# FN-03 & FN-04: INSTANCIACIÓN, VALIDACIÓN Y TRANSICIÓN FLUIDA
# ══════════════════════════════════════════════════════════════════════════════

func _on_instantiate_pressed() -> void:
	if is_game_paused or not is_timer_running:
		return

	# FA-03.01: Intento de instanciación con plantilla incompleta
	var incomplete: bool = false
	for a in assigned_attributes:
		if a == null:
			incomplete = true
			break
	if not incomplete:
		for m in assigned_methods:
			if m == null:
				incomplete = true
				break

	if incomplete:
		if AudioManager and AudioManager.has_method("play_error"):
			AudioManager.play_error()
		_set_status("⚠️ Plantilla incompleta: Debes asignar %d Atributo(s) y %d Método(s) antes de forjar." % [required_slots, required_slots], Color("ff9800"))
		return

	# FN-04: Validación de la estructura y distractores
	_validate_class()

func _apply_error_style(btn: Button) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.28, 0.08, 0.08, 0.95)
	sb.border_color = Color("ff5252")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", sb)

func _validate_class() -> void:
	var error_attr_indices: Array[int] = []
	var error_meth_indices: Array[int] = []
	var error_messages: Array[String] = []

	# Validar Columna de Atributos (Lado Izquierdo)
	for i in range(required_slots):
		var item: Dictionary = assigned_attributes[i]
		if item.type != HeroForgeData.ComponentType.ATTRIBUTE:
			error_attr_indices.append(i)
			error_messages.append("'%s' es un Método (acción), no debe ir como Atributo" % item.text)
		elif not item.is_correct:
			error_attr_indices.append(i)
			error_messages.append("'%s' no es un Atributo que pertenezca a %s" % [item.text, current_hero.class_name])

	# Validar Columna de Métodos (Lado Derecho)
	for i in range(required_slots):
		var item: Dictionary = assigned_methods[i]
		if item.type != HeroForgeData.ComponentType.METHOD:
			error_meth_indices.append(i)
			error_messages.append("'%s' es un Atributo (estado), no debe ir como Método" % item.text)
		elif not item.is_correct:
			error_meth_indices.append(i)
			error_messages.append("'%s' no es un Método que pertenezca a %s" % [item.text, current_hero.class_name])

	# FA-04.01: Clasificación errónea de componentes o distractor
	if error_attr_indices.size() > 0 or error_meth_indices.size() > 0:
		if AudioManager and AudioManager.has_method("play_error"):
			AudioManager.play_error()

		# Resaltar en ROJO los elementos incorrectos en la plantilla
		for idx in error_attr_indices:
			var btn: Button = attr_slot_buttons[idx]
			btn.text = "✗ " + assigned_attributes[idx].text
			btn.add_theme_color_override("font_color", Color("ff5252"))
			_apply_error_style(btn)

		for idx in error_meth_indices:
			var btn: Button = meth_slot_buttons[idx]
			btn.text = "✗ " + assigned_methods[idx].text
			btn.add_theme_color_override("font_color", Color("ff5252"))
			_apply_error_style(btn)

		_lose_life()
		if current_lives > 0:
			_set_status("❌ Error en la Clase: " + error_messages[0] + " (-1 vida). Corrige los elementos en rojo.", Color("f44336"))
		else:
			_show_game_over("Vidas agotadas por errores de definición de clase.")
		return

	# FN-05 & FN-06: Instanciación Exitosa y Avance Fluido
	_on_hero_instantiated_success()

func _on_hero_instantiated_success() -> void:
	is_timer_running = false

	if AudioManager:
		if AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("success")
		elif AudioManager.has_method("play_success"):
			AudioManager.play_success()

	total_score += points_per_char
	if EventBus.has_signal("score_changed"):
		EventBus.emit_signal("score_changed", total_score)
	_update_hud()

	# Resaltar slots en verde brillante de éxito
	for btn in attr_slot_buttons:
		btn.add_theme_color_override("font_color", Color("69f0ae"))
	for btn in meth_slot_buttons:
		btn.add_theme_color_override("font_color", Color("69f0ae"))

	var is_last_hero: bool = (current_hero_index + 1 >= hero_classes_queue.size())

	if is_last_hero:
		btn_instantiate.disabled = false
		btn_instantiate.text = "🎉 ¡Mesa de Forja Superada! (Toca para ver resultados)"
		if btn_instantiate.pressed.is_connected(_on_instantiate_pressed):
			btn_instantiate.pressed.disconnect(_on_instantiate_pressed)
		if not btn_instantiate.pressed.is_connected(_handle_victory):
			btn_instantiate.pressed.connect(_handle_victory)
		_set_status("🏆 ¡%s forjado! Completaste todos los personajes (+%d pts)." % [current_hero.class_name, points_per_char], Color("ffd54f"))

		# Pausa breve para celebrar y mostrar la Pantalla Final de Victoria
		await get_tree().create_timer(0.6).timeout
		if screen_game.visible:
			_handle_victory()
	else:
		btn_instantiate.disabled = true
		btn_instantiate.text = "✨ ¡%s Instanciado! (+%d pts)" % [current_hero.class_name, points_per_char]
		_set_status("✨ ¡%s forjado con éxito! Cargando siguiente personaje..." % current_hero.class_name, Color("69f0ae"))

		# Transición fluida directa en la misma mesa de forja sin interrumpir con modales
		await get_tree().create_timer(0.8).timeout
		current_hero_index += 1
		_load_class_challenge(current_hero_index)

# ══════════════════════════════════════════════════════════════════════════════
# FA-04.02 & FA-04.03: TIEMPO AGOTADO Y GESTIÓN DE VIDAS
# ══════════════════════════════════════════════════════════════════════════════

func _on_round_timer_timeout() -> void:
	if is_game_paused or not is_timer_running:
		return

	if AudioManager and AudioManager.has_method("play_error"):
		AudioManager.play_error()

	_lose_life()
	if current_lives > 0:
		_set_status("⏳ ¡Tiempo agotado! Pierdes 1 vida.", Color("ff9800"))
		time_left = round_time
	else:
		_show_game_over("Tiempo límite agotado y sin vidas restantes.")

func _lose_life() -> void:
	current_lives = maxi(0, current_lives - 1)
	if EventBus.has_signal("life_lost"):
		EventBus.emit_signal("life_lost", current_lives)
	_update_hud()

# ══════════════════════════════════════════════════════════════════════════════
# FA-02.01: PAUSA Y REANUDACIÓN
# ══════════════════════════════════════════════════════════════════════════════

func _on_pause_pressed() -> void:
	if AudioManager and AudioManager.has_method("play_click"):
		AudioManager.play_click()
	_set_game_paused(true)
	_show_screen(screen_pause)

func _on_resume_pressed() -> void:
	if AudioManager and AudioManager.has_method("play_click"):
		AudioManager.play_click()
	_set_game_paused(false)
	_show_screen(screen_game)

func _set_game_paused(paused: bool) -> void:
	is_game_paused = paused

# FA-04.03: Fin de Partida por Agotamiento de Vidas (Game Over)
func _show_game_over(reason: String) -> void:
	is_timer_running = false
	_set_game_paused(false)

	if AudioManager and AudioManager.has_method("play_game_over"):
		AudioManager.play_game_over()

	if EventBus.has_signal("game_over"):
		EventBus.emit_signal("game_over", "heroforge")

	lbl_gameover_reason.text = reason
	_show_screen(screen_game_over)

# ══════════════════════════════════════════════════════════════════════════════
# FN-07: PANTALLA FINAL DE VICTORIA Y PERSISTENCIA
# ══════════════════════════════════════════════════════════════════════════════

func _handle_victory() -> void:
	is_timer_running = false
	_set_game_paused(false)

	# Puntajes fijos y estrellas fijas estrictamente según dificultad (TSP / Especificación)
	var final_score: int = diff_config.get("total_score", total_score)
	var stars: int = diff_config.get("stars", target_stars)
	var diff_name: String = diff_config.get("name", selected_diff)

	if btn_victory_restart:
		btn_victory_restart.text = "🔄 Volver a Jugar (%s)" % diff_name

	if lbl_victory_stats:
		lbl_victory_stats.text = "⚔️ Dificultad: %s\n🎯 Héroes Forjados: %d/%d\n🏆 Puntos Obtenidos: %d pts\n⭐ Estrellas Ganadas: %s\n❤️ Vidas Restantes: %d" % [
			diff_name,
			hero_classes_queue.size(),
			hero_classes_queue.size(),
			final_score,
			"⭐".repeat(stars),
			current_lives
		]

	# Mostrar la pantalla de victoria INMEDIATAMENTE
	_show_screen(screen_victory)

	if AudioManager:
		if AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("victory")
		elif AudioManager.has_method("play_success"):
			AudioManager.play_success()

	# Persistir progreso de forma resiliente
	if has_method("finish_game"):
		finish_game(true, final_score, stars, "¡Mesa de Forja Superada con Éxito!")
	elif StateManager:
		if StateManager.has_method("record_minigame_result"):
			StateManager.record_minigame_result("heroforge", {
				"success": true,
				"score": final_score,
				"stars": stars
			})
		elif StateManager.has_method("update_minigame_progress"):
			StateManager.update_minigame_progress("heroforge", final_score, stars)

	if EventBus and EventBus.has_signal("progress_saved"):
		EventBus.emit_signal("progress_saved", final_score)

# Salida al Aula 101
func _on_back_pressed() -> void:
	if AudioManager and AudioManager.has_method("play_click"):
		AudioManager.play_click()
	is_timer_running = false
	_set_game_paused(false)
	get_tree().change_scene_to_file("res://scenes/classroom/AulaProgramacion.tscn")

# Atajo de pruebas QA (F8)
func _trigger_debug_win() -> void:
	current_hero_index = hero_classes_queue.size()
	current_lives = max_lives
	total_score = diff_config.get("total_score", 500)
	_handle_victory()
