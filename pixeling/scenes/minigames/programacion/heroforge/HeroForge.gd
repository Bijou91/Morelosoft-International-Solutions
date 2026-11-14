## HeroForge.gd - CU-12: Practicar a crear Clases, Objetos y Atributos
## Morelosoft International Solutions - Aula 101: Introducción a la Programación
## Cumple estrictamente con el Diagrama de Secuencia V2 y la Especificación de Casos de Uso (TSP / ISO 29110)
## Responsable: Carlos Manuel Aguirre Norato (Líder Técnico & Software Architect)
extends MiniGameBase

const HeroForgeData = preload("res://scenes/minigames/programacion/heroforge/HeroForgeData.gd")

# Estilos oficiales Kenney UI Pack (Classic UI)
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

const STYLE_PANEL_INNER = preload("res://scenes/ui/theme/classic/panel_inner_plate.tres")
const STYLE_PANEL_SCREWS = preload("res://scenes/ui/theme/classic/panel_screws.tres")
const STYLE_PANEL_GLASS = preload("res://scenes/ui/theme/classic/panel_glass.tres")

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

# Banco de Componentes de la ronda (Separado por Atributos / Métodos)
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
var is_transitioning_hero: bool = false
var is_victory_shown: bool = false
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
var flow_template: Control

# Nodos y Texturas del Personaje Modular POO
var hero_stage_panel: PanelContainer
var hero_modular_box: Control
var hero_crest_lbl: Label
var mod_base: TextureRect
var mod_armor: TextureRect
var mod_helmet: TextureRect
var mod_weapon: TextureRect
var mod_aura: TextureRect
var lbl_pairs_status: Label

const TEX_HERO_BASE = preload("res://assets/minigames/aula101/hero_base.svg")
const TEX_HERO_ARMOR = preload("res://assets/minigames/aula101/hero_armor.svg")
const TEX_HERO_HELMET = preload("res://assets/minigames/aula101/hero_helmet.svg")
const TEX_HERO_WEAPON = preload("res://assets/minigames/aula101/hero_weapon.svg")
const TEX_HERO_AURA = preload("res://assets/minigames/aula101/hero_aura.svg")

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
var hud_hearts_bar: HBoxContainer
var hud_score_lbl: Label
var timer_progress: ProgressBar
var _compact_sb_cache: Dictionary = {}

func _get_compact_btn_sb(key: String, base_sb: StyleBoxTexture) -> StyleBoxTexture:
	if _compact_sb_cache.has(key):
		return _compact_sb_cache[key] as StyleBoxTexture
	var sb := base_sb.duplicate() as StyleBoxTexture
	sb.content_margin_left = 7.0
	sb.content_margin_right = 7.0
	sb.content_margin_top = 4.0
	sb.content_margin_bottom = 6.0
	_compact_sb_cache[key] = sb
	return sb

# Nodos de Mesa de Forja (Plantilla de Clase)
var hero_badge_lbl: Label
var hero_concept_lbl: Label
var attr_slots_vbox: VBoxContainer
var meth_slots_vbox: VBoxContainer
var attr_slot_buttons: Array[Button] = []
var meth_slot_buttons: Array[Button] = []

# Nodos del Banco de Componentes (Grid de 2 Columnas: Atributos / Métodos)
var bank_grid: GridContainer

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

	flow_template = create_flow_template({
		"title": "HeroForge",
		"subtitle": "CU-12: Clases, Objetos y Atributos",
		"classroom_path": "res://scenes/classroom/AulaProgramacion.tscn",
		"sections": [
			{
				"title": "📘 Conceptos Clave de POO:",
				"text": "• Clase: El molde o plano que define las características y acciones de un tipo de héroe.\n• Objeto: El personaje instanciado en memoria a partir de su clase.\n• Atributos (Lado Izquierdo): Variables que describen su estado (clave = valor).\n• Métodos (Lado Derecho): Funciones que definen sus acciones (verbo())."
			},
			{
				"title": "🎯 Reglas del Taller:",
				"text": "1. Lee la descripción de la clase solicitada.\n2. Lado Izquierdo (Azul): Asigna Atributos.\n3. Lado Derecho (Amarillo): Asigna Métodos.\n4. Toca cualquier slot ocupado para retirar la pieza sin penalización.\n5. Presiona '¡Instanciar Objeto!' para forjarlo. ¡Cuidado con los distractores!"
			}
		],
		"difficulties": {
			"FACIL": {
				"name": "Fácil",
				"info": "Modo: Fácil (1★)\n• 3 Personajes a Forjar (1 Atributo y 1 Método c/u)\n• 5 Vidas  |  60s por Ronda  |  300 Puntos Totales"
			},
			"NORMAL": {
				"name": "Normal",
				"info": "Modo: Normal (2★)\n• 4 Personajes a Forjar (2 Atributos y 2 Métodos c/u)\n• 3 Vidas  |  45s por Ronda  |  500 Puntos Totales"
			},
			"INGENIERO": {
				"name": "Ingeniero",
				"info": "Modo: Ingeniero (3★)\n• 5 Personajes a Forjar (3 Atributos y 3 Métodos c/u)\n• 1 Vida  |  30s por Ronda  |  750 Puntos Totales"
			}
		},
		"default_difficulty": "NORMAL",
		"on_start": func(diff: String):
			selected_diff = diff
			_on_start_pressed(),
		"on_back": func():
			_on_back_pressed(),
		"on_resume": func():
			_on_resume_pressed(),
		"on_restart": func():
			_set_game_paused(false)
			start_game(selected_diff)
	})

	_show_screen(screen_start)

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
			if screen_game and screen_game.visible:
				_on_pause_pressed()
			elif is_game_paused:
				_on_resume_pressed()
		elif event.keycode == KEY_F8:
			_trigger_debug_win()

# ══════════════════════════════════════════════════════════════════════════════
# CONSTRUCCIÓN DE LA INTERFAZ DE USUARIO (VIEWPORT 360x640)
# ══════════════════════════════════════════════════════════════════════════════

func _build_ui() -> void:
	# Fondo didáctico de hoja de libreta con 80% opacidad / 20% transparencia
	attach_notebook_background(self, 0.80)

	_build_screen_start()
	_build_screen_game()
	_build_screen_pause()
	_build_screen_victory()
	_build_screen_game_over()

func _show_screen(target_screen: Control) -> void:
	if screen_start: screen_start.visible = false
	if screen_game: screen_game.visible = false
	if screen_pause: screen_pause.visible = false
	if screen_victory: screen_victory.visible = false
	if screen_game_over: screen_game_over.visible = false

	if flow_template:
		if target_screen == screen_start:
			flow_template.show_instructions()
		else:
			flow_template.hide_all()

	if target_screen:
		target_screen.visible = true

func _build_screen_start() -> void:
	screen_start = Control.new()
	screen_start.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(screen_start)

# ── ScreenGame: Mesa de Forja Interactiva (Atributos Izquierda / Métodos Derecha) ──
func _build_screen_game() -> void:
	screen_game = Control.new()
	screen_game.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_game.visible = false
	add_child(screen_game)

	var game_vbox := VBoxContainer.new()
	game_vbox.name = "GameVBox"
	game_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_vbox.offset_left = 10.0
	game_vbox.offset_top = 10.0
	game_vbox.offset_right = -10.0
	game_vbox.offset_bottom = -8.0
	game_vbox.add_theme_constant_override("separation", 5)
	screen_game.add_child(game_vbox)

	# ── TopHUD (Barra superior unificada Aula 101) ──
	var hud_panel := PanelContainer.new()
	hud_panel.name = "TopHUDPanel"
	style_aula101_hud_panel(hud_panel)
	game_vbox.add_child(hud_panel)

	var hud_hbox := HBoxContainer.new()
	hud_hbox.name = "TopHUD"
	hud_hbox.custom_minimum_size.y = 30.0
	hud_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hud_hbox.add_theme_constant_override("separation", 5)
	hud_panel.add_child(hud_hbox)

	hud_pause_btn = Button.new()
	style_aula101_pause_button(hud_pause_btn)
	hud_pause_btn.pressed.connect(_on_pause_pressed)
	hud_hbox.add_child(hud_pause_btn)

	hud_round_lbl = Label.new()
	hud_round_lbl.text = "Héroe 1/4"
	hud_round_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_round_lbl.add_theme_font_size_override("font_size", 10)
	hud_round_lbl.add_theme_color_override("font_color", Color("ffd54f"))
	hud_hbox.add_child(hud_round_lbl)

	# Barra de tiempo inline (cohesiva con DataDrop)
	timer_progress = ProgressBar.new()
	timer_progress.custom_minimum_size = Vector2(32, 12)
	timer_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timer_progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	timer_progress.show_percentage = false
	timer_progress.value = 100.0
	style_kenney_progress_bar(timer_progress, Color(0.1, 0.9, 1.0, 1.0))
	hud_hbox.add_child(timer_progress)

	hud_timer_lbl = Label.new()
	hud_timer_lbl.text = "45s"
	hud_timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_timer_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_timer_lbl.add_theme_font_size_override("font_size", 10)
	hud_timer_lbl.add_theme_color_override("font_color", Color("40c4ff"))
	hud_hbox.add_child(hud_timer_lbl)

	hud_lives_lbl = Label.new()
	hud_lives_lbl.visible = false
	hud_hbox.add_child(hud_lives_lbl)

	hud_hearts_bar = create_aula101_hearts_bar(current_lives, max_lives, 14.0)
	hud_hbox.add_child(hud_hearts_bar)

	hud_score_lbl = Label.new()
	hud_score_lbl.text = "0 pts"
	hud_score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud_score_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hud_score_lbl.add_theme_font_size_override("font_size", 10)
	hud_score_lbl.add_theme_color_override("font_color", Color("69f0ae"))
	hud_hbox.add_child(hud_score_lbl)

	# Área desplazable compacta de mesa de forja
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	game_vbox.add_child(scroll)

	var main_vbox := VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 5)
	scroll.add_child(main_vbox)

	# Ficha del Personaje (Cabecera de Clase compacta y legible)
	var char_header_panel := PanelContainer.new()
	var sb_char_hdr := STYLE_PANEL_INNER.duplicate() as StyleBoxTexture
	if sb_char_hdr:
		sb_char_hdr.content_margin_left = 8.0
		sb_char_hdr.content_margin_right = 8.0
		sb_char_hdr.content_margin_top = 5.0
		sb_char_hdr.content_margin_bottom = 5.0
		char_header_panel.add_theme_stylebox_override("panel", sb_char_hdr)
	else:
		char_header_panel.add_theme_stylebox_override("panel", STYLE_PANEL_INNER)
	char_header_panel.custom_minimum_size.y = 78.0
	main_vbox.add_child(char_header_panel)

	var ch_hbox := HBoxContainer.new()
	ch_hbox.add_theme_constant_override("separation", 8)
	char_header_panel.add_child(ch_hbox)

	var ch_vbox := VBoxContainer.new()
	ch_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ch_vbox.add_theme_constant_override("separation", 2)
	ch_hbox.add_child(ch_vbox)

	hero_badge_lbl = Label.new()
	hero_badge_lbl.text = "class MagoIgneo:"
	hero_badge_lbl.add_theme_font_size_override("font_size", 12)
	hero_badge_lbl.add_theme_color_override("font_color", Color("00e5ff"))
	ch_vbox.add_child(hero_badge_lbl)
	lock_dynamic_label_box(hero_badge_lbl, null, 18.0, 12, 8, 0.0, 0.0, false, true)

	hero_concept_lbl = Label.new()
	hero_concept_lbl.text = "Especialista arcano en piromancia..."
	hero_concept_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_concept_lbl.add_theme_font_size_override("font_size", 9)
	hero_concept_lbl.add_theme_color_override("font_color", Color("a0aec0"))
	ch_vbox.add_child(hero_concept_lbl)
	lock_dynamic_label_box(hero_concept_lbl, null, 34.0, 9, 7, 0.0, 0.0, true, false)

	lbl_pairs_status = Label.new()
	lbl_pairs_status.text = "Pares POO: 0/2"
	lbl_pairs_status.add_theme_font_size_override("font_size", 9)
	lbl_pairs_status.add_theme_color_override("font_color", Color("ffd54f"))
	ch_vbox.add_child(lbl_pairs_status)
	lock_dynamic_label_box(lbl_pairs_status, null, 14.0, 9, 7, 0.0, 0.0, false, true)

	# Pedestal Kenney + Caja del Personaje Modular
	hero_stage_panel = PanelContainer.new()
	hero_stage_panel.custom_minimum_size = Vector2(66, 70)
	hero_stage_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sb_stage := STYLE_PANEL_INNER.duplicate() as StyleBoxTexture
	if sb_stage:
		sb_stage.content_margin_left = 4.0
		sb_stage.content_margin_right = 4.0
		sb_stage.content_margin_top = 4.0
		sb_stage.content_margin_bottom = 4.0
		sb_stage.modulate_color = Color(0.18, 0.24, 0.36, 0.92)
		hero_stage_panel.add_theme_stylebox_override("panel", sb_stage)
	ch_hbox.add_child(hero_stage_panel)

	hero_modular_box = Control.new()
	hero_modular_box.custom_minimum_size = Vector2(58, 62)
	hero_modular_box.pivot_offset = Vector2(29, 31)
	hero_stage_panel.add_child(hero_modular_box)

	mod_aura = _create_mod_layer(TEX_HERO_AURA, false)
	mod_base = _create_mod_layer(TEX_HERO_BASE, true)
	mod_armor = _create_mod_layer(TEX_HERO_ARMOR, false)
	mod_helmet = _create_mod_layer(TEX_HERO_HELMET, false)
	mod_weapon = _create_mod_layer(TEX_HERO_WEAPON, false)

	hero_crest_lbl = Label.new()
	hero_crest_lbl.name = "HeroCrestLabel"
	hero_crest_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hero_crest_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	hero_crest_lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hero_crest_lbl.custom_minimum_size = Vector2(22, 22)
	hero_crest_lbl.offset_left = -22
	hero_crest_lbl.offset_top = 1
	hero_crest_lbl.offset_right = -1
	hero_crest_lbl.offset_bottom = 23
	hero_crest_lbl.add_theme_font_size_override("font_size", 15)
	hero_crest_lbl.z_index = 5
	hero_crest_lbl.modulate.a = 0.55
	hero_modular_box.add_child(hero_crest_lbl)

	# Plantilla de la Clase (Atributos Izquierda | Métodos Derecha)
	var blueprint_panel := PanelContainer.new()
	var sb_bp := STYLE_PANEL_INNER.duplicate() as StyleBoxTexture
	if sb_bp:
		sb_bp.content_margin_left = 7.0
		sb_bp.content_margin_right = 7.0
		sb_bp.content_margin_top = 5.0
		sb_bp.content_margin_bottom = 5.0
		blueprint_panel.add_theme_stylebox_override("panel", sb_bp)
	else:
		blueprint_panel.add_theme_stylebox_override("panel", STYLE_PANEL_INNER)
	main_vbox.add_child(blueprint_panel)

	var bp_columns := HBoxContainer.new()
	bp_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bp_columns.add_theme_constant_override("separation", 6)
	blueprint_panel.add_child(bp_columns)

	# Columna Izquierda: Atributos
	var attr_col := VBoxContainer.new()
	attr_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attr_col.add_theme_constant_override("separation", 3)
	bp_columns.add_child(attr_col)

	var attr_title := Label.new()
	attr_title.text = "# ATRIBUTOS"
	attr_title.add_theme_font_size_override("font_size", 10)
	attr_title.add_theme_color_override("font_color", Color("80d8ff"))
	attr_col.add_child(attr_title)

	attr_slots_vbox = VBoxContainer.new()
	attr_slots_vbox.add_theme_constant_override("separation", 3)
	attr_col.add_child(attr_slots_vbox)

	# Columna Derecha: Métodos
	var meth_col := VBoxContainer.new()
	meth_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meth_col.add_theme_constant_override("separation", 3)
	bp_columns.add_child(meth_col)

	var meth_title := Label.new()
	meth_title.text = "# MÉTODOS"
	meth_title.add_theme_font_size_override("font_size", 10)
	meth_title.add_theme_color_override("font_color", Color("ffe57f"))
	meth_col.add_child(meth_title)

	meth_slots_vbox = VBoxContainer.new()
	meth_slots_vbox.add_theme_constant_override("separation", 3)
	meth_col.add_child(meth_slots_vbox)

	# Banco de Componentes Disponibles
	var bank_header := Label.new()
	bank_header.text = "Banco de Componentes:"
	bank_header.add_theme_font_size_override("font_size", 10)
	bank_header.add_theme_color_override("font_color", Color("e2e8f0"))
	main_vbox.add_child(bank_header)

	bank_grid = GridContainer.new()
	bank_grid.columns = 2
	bank_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bank_grid.add_theme_constant_override("h_separation", 6)
	bank_grid.add_theme_constant_override("v_separation", 3)
	main_vbox.add_child(bank_grid)

	# Pie fijo siempre visible (Acción principal + Barra de estado)
	btn_instantiate = Button.new()
	btn_instantiate.name = "BtnInstantiate"
	btn_instantiate.text = "¡Instanciar Objeto!"
	style_kenney_button(btn_instantiate, "green", 38.0)
	btn_instantiate.modulate.a = 0.95
	btn_instantiate.pressed.connect(_on_instantiate_pressed)
	game_vbox.add_child(btn_instantiate)

	var status_banner_panel := PanelContainer.new()
	status_banner_panel.name = "StatusBanner"
	var sb_status := STYLE_PANEL_INNER.duplicate() as StyleBoxTexture
	if sb_status:
		sb_status.modulate_color = Color(0.16, 0.22, 0.32, 0.88)
		status_banner_panel.add_theme_stylebox_override("panel", sb_status)
	else:
		status_banner_panel.add_theme_stylebox_override("panel", STYLE_PANEL_INNER)
	game_vbox.add_child(status_banner_panel)

	status_banner_lbl = Label.new()
	status_banner_lbl.text = "Toca atributos (azul) a la izquierda y métodos (amarillo) a la derecha."
	status_banner_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_banner_lbl.add_theme_font_size_override("font_size", 9)
	status_banner_lbl.add_theme_color_override("font_color", Color("90a4ae"))
	status_banner_panel.add_child(status_banner_lbl)
	lock_dynamic_label_box(status_banner_lbl, status_banner_panel, 36.0, 10, 7, 2.0, 0.0, true, true, 4.0)
	stabilize_hud_label(hud_round_lbl, 56.0)
	stabilize_hud_label(hud_timer_lbl, 26.0)
	stabilize_hud_label(hud_score_lbl, 44.0)
	update_aula101_hearts_bar(hud_hearts_bar, current_lives, max_lives, hud_lives_lbl, 14.0)

# ── ScreenPause: Pausa universal manejada por MiniGameFlowTemplate ──
func _build_screen_pause() -> void:
	screen_pause = Control.new()
	screen_pause.visible = false
	add_child(screen_pause)

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
	is_victory_shown = false
	is_transitioning_hero = false
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
	update_aula101_hearts_bar(hud_hearts_bar, current_lives, max_lives, hud_lives_lbl, 14.0)
	if hud_score_lbl:
		hud_score_lbl.text = "%d pts" % total_score
	if hud_timer_lbl:
		hud_timer_lbl.text = "%ds" % int(ceil(time_left))
		hud_timer_lbl.modulate = Color("ff3366") if time_left <= 10.0 else Color.WHITE
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

	is_transitioning_hero = false
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

	# Actualizar cabecera de la clase con el concepto del tier
	hero_badge_lbl.text = "class %s:" % current_hero.class_name
	hero_badge_lbl.add_theme_color_override("font_color", current_hero.badge_color)
	hero_concept_lbl.text = current_tier_data.concept

	# Personalizar colores y apariencia del héroe actual (7 clases de HeroForgeData)
	var hero_color: Color = current_hero.badge_color
	mod_aura.modulate = hero_color
	mod_armor.modulate = hero_color
	mod_base.modulate = Color(1.0, 1.0, 1.0, 1.0)

	match current_hero.id:
		"mago_igneo":
			mod_base.modulate = Color(1.0, 0.92, 0.88)
			mod_armor.modulate = Color("ff5722")
			mod_helmet.modulate = Color("ff7043")
			mod_weapon.modulate = Color("ffab91")
		"guerrero_tanque":
			mod_base.modulate = Color(0.95, 0.96, 1.0)
			mod_armor.modulate = Color("ffa000")
			mod_helmet.modulate = Color("ffc107")
			mod_weapon.modulate = Color("ffe082")
		"arquero_sombra":
			mod_base.modulate = Color(0.88, 0.98, 0.92)
			mod_armor.modulate = Color("2e7d32")
			mod_helmet.modulate = Color("43a047")
			mod_weapon.modulate = Color("a5d6a7")
		"robot_reparador":
			mod_base.modulate = Color(0.82, 0.96, 1.0)
			mod_armor.modulate = Color("00b8d4")
			mod_helmet.modulate = Color("00e5ff")
			mod_weapon.modulate = Color("80d8ff")
		"nave_exploradora":
			mod_base.modulate = Color(0.90, 0.88, 1.0)
			mod_armor.modulate = Color("7c4dff")
			mod_helmet.modulate = Color("b388ff")
			mod_weapon.modulate = Color("e040fb")
		"alquimista_pociones":
			mod_base.modulate = Color(0.96, 0.90, 1.0)
			mod_armor.modulate = Color("ab47bc")
			mod_helmet.modulate = Color("ce93d8")
			mod_weapon.modulate = Color("69f0ae")
		"hacker_ciberespacio":
			mod_base.modulate = Color(0.80, 1.0, 0.96)
			mod_armor.modulate = Color("00acc1")
			mod_helmet.modulate = Color("26c6da")
			mod_weapon.modulate = Color("69f0ae")
		_:
			mod_helmet.modulate = hero_color
			mod_weapon.modulate = hero_color

	if is_instance_valid(hero_stage_panel):
		var sb_stage := STYLE_PANEL_INNER.duplicate() as StyleBoxTexture
		if sb_stage:
			sb_stage.modulate_color = hero_color.darkened(0.62)
			sb_stage.modulate_color.a = 0.92
			hero_stage_panel.add_theme_stylebox_override("panel", sb_stage)

	if is_instance_valid(hero_crest_lbl):
		hero_crest_lbl.text = current_hero.avatar_symbol
		hero_crest_lbl.modulate.a = 0.60

	# Reconstruir slots según required_slots (1, 2 o 3)
	_rebuild_slot_buttons()
	_update_slot_displays()
	_render_component_bank()

	btn_instantiate.disabled = false
	btn_instantiate.text = "¡Instanciar Objeto!"
	if btn_instantiate.pressed.is_connected(_handle_victory):
		btn_instantiate.pressed.disconnect(_handle_victory)
	if not btn_instantiate.pressed.is_connected(_on_instantiate_pressed):
		btn_instantiate.pressed.connect(_on_instantiate_pressed)
	_set_status("Toca atributos (azul) a la izquierda y métodos (amarillo) a la derecha.", Color("90a4ae"))
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
		btn_attr.custom_minimum_size = Vector2(0, 30)
		btn_attr.add_theme_font_size_override("font_size", 9)
		btn_attr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn_attr.set_meta("kenney_custom_managed", true)
		btn_attr.pressed.connect(func(): _on_slot_button_pressed("ATTR", slot_idx))
		attr_slots_vbox.add_child(btn_attr)
		lock_dynamic_button_box(btn_attr, 30.0, 10, 7, true, 152.0)
		attr_slot_buttons.append(btn_attr)

		var btn_meth := Button.new()
		btn_meth.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn_meth.custom_minimum_size = Vector2(0, 30)
		btn_meth.add_theme_font_size_override("font_size", 9)
		btn_meth.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn_meth.set_meta("kenney_custom_managed", true)
		btn_meth.pressed.connect(func(): _on_slot_button_pressed("METH", slot_idx))
		meth_slots_vbox.add_child(btn_meth)
		lock_dynamic_button_box(btn_meth, 30.0, 10, 7, true, 152.0)
		meth_slot_buttons.append(btn_meth)

func _apply_accessibility_mode(is_active: bool) -> void:
	super._apply_accessibility_mode(is_active)
	if not is_active and is_inside_tree():
		if is_instance_valid(attr_slots_vbox) and required_slots > 0 and assigned_attributes.size() == required_slots:
			_update_slot_displays()
		if is_instance_valid(bank_grid) and bank_all_components.size() > 0:
			_render_component_bank()

func _create_mod_layer(tex: Texture2D, initial_vis: bool) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.visible = initial_vis
	hero_modular_box.add_child(tr)
	return tr

func _update_modular_character(completed_pairs: int) -> void:
	if not is_instance_valid(hero_modular_box):
		return

	mod_base.visible = true
	var crest = hero_modular_box.get_node_or_null("HeroCrestLabel")

	if required_slots <= 1:
		var is_done: bool = completed_pairs >= 1
		mod_armor.visible = is_done
		mod_helmet.visible = is_done
		mod_weapon.visible = is_done
		mod_aura.visible = is_done
		if crest: crest.modulate.a = 0.95 if is_done else 0.35
	elif required_slots == 2:
		mod_armor.visible = (completed_pairs >= 1)
		mod_helmet.visible = (completed_pairs >= 2)
		mod_weapon.visible = (completed_pairs >= 2)
		mod_aura.visible = (completed_pairs >= 2)
		if crest: crest.modulate.a = 0.95 if completed_pairs >= 2 else (0.65 if completed_pairs == 1 else 0.35)
	else:
		mod_armor.visible = (completed_pairs >= 1)
		mod_helmet.visible = (completed_pairs >= 2)
		mod_weapon.visible = (completed_pairs >= 3)
		mod_aura.visible = (completed_pairs >= 3)
		if crest: crest.modulate.a = 0.95 if completed_pairs >= 3 else (0.45 + 0.2 * completed_pairs)

	if lbl_pairs_status:
		lbl_pairs_status.text = "Pares POO: %d/%d" % [completed_pairs, required_slots]
		if completed_pairs >= required_slots:
			lbl_pairs_status.modulate = Color("00e676")
			var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(hero_modular_box, "scale", Vector2(1.12, 1.12), 0.15)
			tw.tween_property(hero_modular_box, "scale", Vector2.ONE, 0.2)
		else:
			lbl_pairs_status.modulate = Color("ffd54f")

func _update_slot_displays() -> void:
	var filled_attrs: int = 0
	var filled_meths: int = 0

	for i in range(required_slots):
		if i >= attr_slot_buttons.size() or i >= meth_slot_buttons.size():
			continue

		var attr_btn := attr_slot_buttons[i]
		var attr_item = assigned_attributes[i]
		if attr_item != null:
			filled_attrs += 1
			attr_btn.text = "✓ " + attr_item.text
			attr_btn.add_theme_stylebox_override("normal", _get_compact_btn_sb("blue_norm", STYLE_BTN_BLUE_NORM))
			attr_btn.add_theme_stylebox_override("hover", _get_compact_btn_sb("blue_hov", STYLE_BTN_BLUE_HOV))
			attr_btn.add_theme_stylebox_override("pressed", _get_compact_btn_sb("blue_press", STYLE_BTN_BLUE_PRESS))
			attr_btn.add_theme_color_override("font_color", Color.WHITE)
			attr_btn.add_theme_color_override("font_hover_color", Color.WHITE)
		else:
			attr_btn.text = "+ Atributo %d" % (i + 1)
			attr_btn.add_theme_stylebox_override("normal", _get_compact_btn_sb("neu_norm", STYLE_BTN_NEUTRAL_NORM))
			attr_btn.add_theme_stylebox_override("hover", _get_compact_btn_sb("neu_hov", STYLE_BTN_NEUTRAL_HOV))
			attr_btn.add_theme_stylebox_override("pressed", _get_compact_btn_sb("neu_press", STYLE_BTN_NEUTRAL_PRESS))
			attr_btn.add_theme_color_override("font_color", Color(0.20, 0.45, 0.75))
			attr_btn.add_theme_color_override("font_hover_color", Color(0.10, 0.35, 0.65))
		fit_control_text_now(attr_btn)

		var meth_btn := meth_slot_buttons[i]
		var meth_item = assigned_methods[i]
		if meth_item != null:
			filled_meths += 1
			meth_btn.text = "✓ " + meth_item.text
			meth_btn.add_theme_stylebox_override("normal", _get_compact_btn_sb("yel_norm", STYLE_BTN_YELLOW_NORM))
			meth_btn.add_theme_stylebox_override("hover", _get_compact_btn_sb("yel_hov", STYLE_BTN_YELLOW_HOV))
			meth_btn.add_theme_stylebox_override("pressed", _get_compact_btn_sb("yel_press", STYLE_BTN_YELLOW_PRESS))
			meth_btn.add_theme_color_override("font_color", Color(0.24, 0.18, 0.02, 1.0))
			meth_btn.add_theme_color_override("font_hover_color", Color(0.34, 0.24, 0.02, 1.0))
		else:
			meth_btn.text = "+ Método %d" % (i + 1)
			meth_btn.add_theme_stylebox_override("normal", _get_compact_btn_sb("neu_norm", STYLE_BTN_NEUTRAL_NORM))
			meth_btn.add_theme_stylebox_override("hover", _get_compact_btn_sb("neu_hov", STYLE_BTN_NEUTRAL_HOV))
			meth_btn.add_theme_stylebox_override("pressed", _get_compact_btn_sb("neu_press", STYLE_BTN_NEUTRAL_PRESS))
			meth_btn.add_theme_color_override("font_color", Color(0.70, 0.55, 0.10))
			meth_btn.add_theme_color_override("font_hover_color", Color(0.60, 0.45, 0.05))
		fit_control_text_now(meth_btn)

	var completed_pairs: int = mini(filled_attrs, filled_meths)
	_update_modular_character(completed_pairs)

func _render_component_bank() -> void:
	for child in bank_grid.get_children():
		child.queue_free()

	# Separar en atributos (izq) y métodos (der) para preservar el esquema por columnas
	var attrs: Array[Dictionary] = []
	var meths: Array[Dictionary] = []
	for item in bank_all_components:
		var is_attr: bool = (item.get("expected_section", "") == "ATTR" or item.get("type", 0) == HeroForgeData.ComponentType.ATTRIBUTE)
		if is_attr:
			attrs.append(item)
		else:
			meths.append(item)

	var max_rows: int = maxi(attrs.size(), meths.size())
	for r in range(max_rows):
		# Columna 0: Atributos en Azul
		if r < attrs.size():
			var item: Dictionary = attrs[r]
			var btn := Button.new()
			btn.text = item.text
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(0, 30)
			btn.add_theme_font_size_override("font_size", 9)
			btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn.set_meta("kenney_custom_managed", true)

			btn.add_theme_stylebox_override("normal", _get_compact_btn_sb("blue_norm", STYLE_BTN_BLUE_NORM))
			btn.add_theme_stylebox_override("hover", _get_compact_btn_sb("blue_hov", STYLE_BTN_BLUE_HOV))
			btn.add_theme_stylebox_override("pressed", _get_compact_btn_sb("blue_press", STYLE_BTN_BLUE_PRESS))
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.add_theme_color_override("font_hover_color", Color.WHITE)

			var is_assigned: bool = _is_item_assigned(item.id)
			btn.disabled = is_assigned
			if is_assigned:
				btn.modulate = Color(0.4, 0.4, 0.4, 0.35)
			else:
				btn.modulate = Color(1.0, 1.0, 1.0, 1.0)

			var cap_item: Dictionary = item
			btn.pressed.connect(func(): _on_bank_item_clicked(cap_item))
			bank_grid.add_child(btn)
			lock_dynamic_button_box(btn, 30.0, 10, 7, true, 154.0)
		else:
			var spacer := Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bank_grid.add_child(spacer)

		# Columna 1: Métodos en Amarillo
		if r < meths.size():
			var item: Dictionary = meths[r]
			var btn := Button.new()
			btn.text = item.text
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(0, 30)
			btn.add_theme_font_size_override("font_size", 9)
			btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn.set_meta("kenney_custom_managed", true)

			btn.add_theme_stylebox_override("normal", _get_compact_btn_sb("yel_norm", STYLE_BTN_YELLOW_NORM))
			btn.add_theme_stylebox_override("hover", _get_compact_btn_sb("yel_hov", STYLE_BTN_YELLOW_HOV))
			btn.add_theme_stylebox_override("pressed", _get_compact_btn_sb("yel_press", STYLE_BTN_YELLOW_PRESS))
			btn.add_theme_color_override("font_color", Color(0.24, 0.18, 0.02, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(0.34, 0.24, 0.02, 1.0))

			var is_assigned: bool = _is_item_assigned(item.id)
			btn.disabled = is_assigned
			if is_assigned:
				btn.modulate = Color(0.4, 0.4, 0.4, 0.35)
			else:
				btn.modulate = Color(1.0, 1.0, 1.0, 1.0)

			var cap_item: Dictionary = item
			btn.pressed.connect(func(): _on_bank_item_clicked(cap_item))
			bank_grid.add_child(btn)
			lock_dynamic_button_box(btn, 30.0, 10, 7, true, 154.0)
		else:
			var spacer := Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bank_grid.add_child(spacer)

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
		# Remover el elemento y devolverlo al banco inmediatamente
		_on_component_removed(section, slot_index)

func _on_bank_item_clicked(item: Dictionary) -> void:
	if is_game_paused or not is_timer_running:
		return

	_play_sfx_select()

	var is_attr: bool = (item.get("expected_section", "") == "ATTR" or item.get("type", 0) == HeroForgeData.ComponentType.ATTRIBUTE)
	if is_attr:
		var free_slot: int = -1
		for i in range(required_slots):
			if assigned_attributes[i] == null:
				free_slot = i
				break
		if free_slot != -1:
			_assign_item_to_slot(item, "ATTR", free_slot)
		else:
			_set_status("⚠️ Ranuras de ATRIBUTOS llenas (%d/%d). Toca uno asignado para quitarlo." % [required_slots, required_slots], Color("ffb74d"))
			if AudioManager and AudioManager.has_method("play_error"):
				AudioManager.play_error()
	else:
		var free_slot: int = -1
		for i in range(required_slots):
			if assigned_methods[i] == null:
				free_slot = i
				break
		if free_slot != -1:
			_assign_item_to_slot(item, "METH", free_slot)
		else:
			_set_status("⚠️ Ranuras de MÉTODOS llenas (%d/%d). Toca uno asignado para quitarlo." % [required_slots, required_slots], Color("ffb74d"))
			if AudioManager and AudioManager.has_method("play_error"):
				AudioManager.play_error()

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
	if is_game_paused or not is_timer_running or is_transitioning_hero or is_victory_shown:
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
	btn.add_theme_stylebox_override("normal", STYLE_BTN_RED_NORM)
	btn.add_theme_stylebox_override("hover", STYLE_BTN_RED_HOV)
	btn.add_theme_stylebox_override("pressed", STYLE_BTN_RED_PRESS)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

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
	if is_transitioning_hero or is_victory_shown:
		return
	is_transitioning_hero = true
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
		if not is_instance_valid(self) or not is_inside_tree():
			return
		if not is_victory_shown and screen_game.visible:
			_handle_victory()
	else:
		btn_instantiate.disabled = true
		btn_instantiate.text = "✨ ¡%s Instanciado! (+%d pts)" % [current_hero.class_name, points_per_char]
		_set_status("✨ ¡%s forjado con éxito! Cargando siguiente personaje..." % current_hero.class_name, Color("69f0ae"))

		# Transición fluida directa en la misma mesa de forja sin interrumpir con modales
		await get_tree().create_timer(0.8).timeout
		if not is_instance_valid(self) or not is_inside_tree() or not screen_game.visible or is_victory_shown:
			return
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
	flow_template.show_pause()

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

	finish_game(false, total_score, 0, reason)
	if flow_template:
		flow_template.show_game_over(reason, total_score)
	else:
		lbl_gameover_reason.text = reason
		_show_screen(screen_game_over)

# ══════════════════════════════════════════════════════════════════════════════
# FN-07: PANTALLA FINAL DE VICTORIA Y PERSISTENCIA
# ══════════════════════════════════════════════════════════════════════════════

func _handle_victory() -> void:
	if is_victory_shown:
		return
	is_victory_shown = true
	is_transitioning_hero = false
	is_timer_running = false
	_set_game_paused(false)
	if is_instance_valid(btn_instantiate):
		btn_instantiate.disabled = true

	# Puntajes fijos y estrellas fijas estrictamente según dificultad (TSP / Especificación)
	var final_score: int = diff_config.get("total_score", total_score)
	var stars: int = diff_config.get("stars", target_stars)
	var diff_name: String = diff_config.get("name", selected_diff)

	var prev_high: int = StateManager.get_minigame_high_score(minigame_id) if StateManager else 0
	var is_record: bool = final_score > prev_high

	if has_method("finish_game"):
		finish_game(true, final_score, stars, "¡Mesa de Forja Superada con Éxito!")
	elif StateManager and StateManager.has_method("record_minigame_result"):
		StateManager.record_minigame_result("heroforge", {
			"success": true,
			"score": final_score,
			"stars": stars
		})

	if flow_template:
		var total_accum: int = StateManager.get_points() if StateManager else final_score
		flow_template.show_victory(final_score, stars, total_accum, is_record, "¡HÉROES FORJADOS!")
	else:
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
		_show_screen(screen_victory)

	if AudioManager:
		if AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("victory")
		elif AudioManager.has_method("play_success"):
			AudioManager.play_success()

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
