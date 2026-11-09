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

# Plantilla de Clase actual (2 atributos y 2 métodos)
var assigned_attributes: Array = [null, null]
var assigned_methods: Array = [null, null]

# Banco de componentes de la ronda (8 items barajados)
var bank_items: Array[Dictionary] = []

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
# NODOS Y CONTENEDORES DE PANTALLA (Generados de forma programática y resiliente)
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

# Nodos de Mesa de Forja
var hero_badge_lbl: Label
var hero_concept_lbl: Label
var slot_attr_btn1: Button
var slot_attr_btn2: Button
var slot_meth_btn1: Button
var slot_meth_btn2: Button
var bank_grid: GridContainer
var btn_instantiate: Button
var status_banner_lbl: Label

# Modal de Héroe Instanciado (FN-05 / FN-06)
var modal_instance_overlay: PanelContainer
var modal_instance_avatar_lbl: Label
var modal_instance_title_lbl: Label
var modal_instance_desc_lbl: Label
var modal_instance_next_btn: Button

# Nodos de ScreenPause
var btn_pause_resume: Button
var btn_pause_restart: Button
var btn_pause_back: Button

# Nodos de ScreenVictory
var lbl_victory_stats: Label
var btn_victory_restart: Button
var btn_victory_back: Button

# Nodos de ScreenGameOver
var lbl_gameover_reason: Label
var btn_gameover_restart: Button
var btn_gameover_back: Button

# ══════════════════════════════════════════════════════════════════════════════
# CICLO DE VIDA (Godot 4)
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	super._ready()
	minigame_id = "heroforge"
	cu_id = "CU-12"
	minigame_title = "HeroForge (Clases, Objetos y Atributos)"
	subject_name = "Introducción a la Programación"

	_build_ui_hierarchy()
	_apply_accessibility_mode(StateManager.is_high_contrast_active() if StateManager else false)

	_show_screen(screen_start)
	_show_instructions_step()

func _process(delta: float) -> void:
	if is_timer_running and not is_game_paused and screen_game.visible:
		time_left -= delta
		if timer_progress:
			timer_progress.value = time_left
		if hud_timer_lbl:
			hud_timer_lbl.text = "⏱️ %02ds" % [maxi(0, int(ceil(time_left)))]
			if time_left <= 10.0:
				hud_timer_lbl.add_theme_color_override("font_color", Color("f44336"))
			else:
				hud_timer_lbl.add_theme_color_override("font_color", Color("ffeb3b"))

		if time_left <= 0.0:
			_on_round_timer_timeout()

# ══════════════════════════════════════════════════════════════════════════════
# CONSTRUCCIÓN PROGRAMÁTICA DE LA INTERFAZ (Pixel Art / Mobile 360x640)
# ══════════════════════════════════════════════════════════════════════════════

func _build_ui_hierarchy() -> void:
	# Fondo Base
	bg_rect = ColorRect.new()
	bg_rect.color = Color("0d1117") # Fondo oscuro espacial/ciberpunk
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)

	# 1. PANTALLA DE INICIO (ScreenStart)
	_build_screen_start()

	# 2. PANTALLA DE JUEGO (ScreenGame)
	_build_screen_game()

	# 3. PANTALLA DE PAUSA (ScreenPause)
	_build_screen_pause()

	# 4. PANTALLA DE VICTORIA (ScreenVictory)
	_build_screen_victory()

	# 5. PANTALLA DE GAME OVER (ScreenGameOver)
	_build_screen_game_over()

func _build_screen_start() -> void:
	screen_start = Control.new()
	screen_start.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(screen_start)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	screen_start.add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	scroll.add_child(margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.add_theme_constant_override("separation", 14)
	margin.add_child(root_vbox)

	# Título común
	var title := Label.new()
	title.text = "⚔️ HeroForge 🔨"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("00e5ff"))
	root_vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "CU-12: Clases, Objetos y Atributos\nAula 101 - Intro a Programación"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color("90a4ae"))
	root_vbox.add_child(subtitle)

	# ── Paso 1: Contenedor de Instrucciones ──
	container_instructions = VBoxContainer.new()
	container_instructions.add_theme_constant_override("separation", 12)
	root_vbox.add_child(container_instructions)

	var panel_oop := PanelContainer.new()
	var style_oop := StyleBoxFlat.new()
	style_oop.bg_color = Color("161b22")
	style_oop.border_color = Color("30363d")
	style_oop.set_border_width_all(1)
	style_oop.set_corner_radius_all(6)
	panel_oop.add_theme_stylebox_override("panel", style_oop)
	container_instructions.add_child(panel_oop)

	var oop_margin := MarginContainer.new()
	oop_margin.add_theme_constant_override("margin_left", 12)
	oop_margin.add_theme_constant_override("margin_right", 12)
	oop_margin.add_theme_constant_override("margin_top", 10)
	oop_margin.add_theme_constant_override("margin_bottom", 10)
	panel_oop.add_child(oop_margin)

	var oop_text := Label.new()
	oop_text.text = "📚 Conceptos Clave de POO:\n\n• CLASE: El molde o plano del héroe.\n• ATRIBUTOS: Sus datos y características (ej. elemento, vida, mana).\n• MÉTODOS: Sus acciones y habilidades (ej. lanzar_fuego(), defender()).\n• OBJETO: La instancia real creada a partir de la Clase."
	oop_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	oop_text.add_theme_font_size_override("font_size", 11)
	oop_text.add_theme_color_override("font_color", Color("eceff1"))
	oop_margin.add_child(oop_text)

	var inst_box := PanelContainer.new()
	inst_box.add_theme_stylebox_override("panel", style_oop.duplicate())
	container_instructions.add_child(inst_box)

	var inst_margin := MarginContainer.new()
	inst_margin.add_theme_constant_override("margin_left", 12)
	inst_margin.add_theme_constant_override("margin_right", 12)
	inst_margin.add_theme_constant_override("margin_top", 10)
	inst_margin.add_theme_constant_override("margin_bottom", 10)
	inst_box.add_child(inst_margin)

	var inst_text := Label.new()
	inst_text.text = "🎯 Reglas de la Partida:\n\n1. Lee la descripción del héroe solicitado.\n2. Toca componentes del banco para llenar los 2 slots de Atributos y 2 de Métodos.\n3. Puedes tocar un slot ocupado para retirar la pieza sin perder vidas.\n4. Presiona '¡Instanciar Objeto!' para forjarlo. ¡Cuidado con los distractores!"
	inst_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inst_text.add_theme_font_size_override("font_size", 11)
	inst_text.add_theme_color_override("font_color", Color("cfd8dc"))
	inst_margin.add_child(inst_text)

	var btn_to_diff := Button.new()
	btn_to_diff.text = "Siguiente: Elegir Dificultad →"
	btn_to_diff.custom_minimum_size = Vector2(0, 44)
	btn_to_diff.add_theme_font_size_override("font_size", 13)
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
	container_difficulty.add_theme_constant_override("separation", 12)
	root_vbox.add_child(container_difficulty)

	var diff_label := Label.new()
	diff_label.text = "Elige la Dificultad de la Forja:"
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_label.add_theme_font_size_override("font_size", 13)
	container_difficulty.add_child(diff_label)

	var diff_btn_hbox := HBoxContainer.new()
	diff_btn_hbox.add_theme_constant_override("separation", 8)
	container_difficulty.add_child(diff_btn_hbox)

	var btn_facil := Button.new()
	btn_facil.text = "Fácil"
	btn_facil.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_facil.custom_minimum_size = Vector2(0, 40)
	btn_facil.pressed.connect(func(): _select_difficulty("FACIL"))
	diff_btn_hbox.add_child(btn_facil)

	var btn_normal := Button.new()
	btn_normal.text = "Normal"
	btn_normal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_normal.custom_minimum_size = Vector2(0, 40)
	btn_normal.pressed.connect(func(): _select_difficulty("NORMAL"))
	diff_btn_hbox.add_child(btn_normal)

	var btn_ing := Button.new()
	btn_ing.text = "Ingeniero"
	btn_ing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_ing.custom_minimum_size = Vector2(0, 40)
	btn_ing.pressed.connect(func(): _select_difficulty("INGENIERO"))
	diff_btn_hbox.add_child(btn_ing)

	var summary_panel := PanelContainer.new()
	summary_panel.add_theme_stylebox_override("panel", style_oop.duplicate())
	container_difficulty.add_child(summary_panel)

	var sum_margin := MarginContainer.new()
	sum_margin.add_theme_constant_override("margin_left", 12)
	sum_margin.add_theme_constant_override("margin_right", 12)
	sum_margin.add_theme_constant_override("margin_top", 10)
	sum_margin.add_theme_constant_override("margin_bottom", 10)
	summary_panel.add_child(sum_margin)

	lbl_diff_summary = Label.new()
	lbl_diff_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_diff_summary.add_theme_font_size_override("font_size", 11)
	lbl_diff_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sum_margin.add_child(lbl_diff_summary)

	btn_start_game = Button.new()
	btn_start_game.text = "▶ ¡COMENZAR LA FORJA!"
	btn_start_game.custom_minimum_size = Vector2(0, 46)
	btn_start_game.add_theme_font_size_override("font_size", 14)
	btn_start_game.pressed.connect(_on_start_pressed)
	container_difficulty.add_child(btn_start_game)

	var btn_back_to_inst := Button.new()
	btn_back_to_inst.text = "← Ver Instrucciones"
	btn_back_to_inst.custom_minimum_size = Vector2(0, 36)
	btn_back_to_inst.add_theme_font_size_override("font_size", 11)
	btn_back_to_inst.pressed.connect(_show_instructions_step)
	container_difficulty.add_child(btn_back_to_inst)

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
	hud_margin.add_theme_constant_override("margin_top", 6)
	hud_margin.add_theme_constant_override("margin_bottom", 6)
	hud_panel.add_child(hud_margin)

	var hud_hbox := HBoxContainer.new()
	hud_hbox.add_theme_constant_override("separation", 8)
	hud_margin.add_child(hud_hbox)

	hud_pause_btn = Button.new()
	hud_pause_btn.text = "⏸️"
	hud_pause_btn.custom_minimum_size = Vector2(34, 30)
	hud_pause_btn.pressed.connect(_on_pause_pressed)
	hud_hbox.add_child(hud_pause_btn)

	hud_round_lbl = Label.new()
	hud_round_lbl.text = "Héroe 1/3"
	hud_round_lbl.add_theme_font_size_override("font_size", 11)
	hud_round_lbl.add_theme_color_override("font_color", Color("00e5ff"))
	hud_hbox.add_child(hud_round_lbl)

	hud_timer_lbl = Label.new()
	hud_timer_lbl.text = "⏱️ 45s"
	hud_timer_lbl.add_theme_font_size_override("font_size", 11)
	hud_timer_lbl.add_theme_color_override("font_color", Color("ffeb3b"))
	hud_hbox.add_child(hud_timer_lbl)

	hud_lives_lbl = Label.new()
	hud_lives_lbl.text = "❤️❤️❤️"
	hud_lives_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud_lives_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_lives_lbl.add_theme_font_size_override("font_size", 11)
	hud_hbox.add_child(hud_lives_lbl)

	hud_score_lbl = Label.new()
	hud_score_lbl.text = "0 pts"
	hud_score_lbl.add_theme_font_size_override("font_size", 11)
	hud_score_lbl.add_theme_color_override("font_color", Color("76ff03"))
	hud_hbox.add_child(hud_score_lbl)

	# Barra de progreso del tiempo de ronda
	timer_progress = ProgressBar.new()
	timer_progress.custom_minimum_size = Vector2(0, 4)
	timer_progress.show_percentage = false
	game_vbox.add_child(timer_progress)

	# ── Contenido con Scroll para la Forja ──
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	game_vbox.add_child(scroll)

	var scroll_margin := MarginContainer.new()
	scroll_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_margin.add_theme_constant_override("margin_left", 10)
	scroll_margin.add_theme_constant_override("margin_right", 10)
	scroll_margin.add_theme_constant_override("margin_top", 4)
	scroll_margin.add_theme_constant_override("margin_bottom", 8)
	scroll.add_child(scroll_margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 8)
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
	ch_margin.add_theme_constant_override("margin_top", 6)
	ch_margin.add_theme_constant_override("margin_bottom", 6)
	char_header_panel.add_child(ch_margin)

	var ch_vbox := VBoxContainer.new()
	ch_vbox.add_theme_constant_override("separation", 2)
	ch_margin.add_child(ch_vbox)

	hero_badge_lbl = Label.new()
	hero_badge_lbl.text = "class MagoIgneo:"
	hero_badge_lbl.add_theme_font_size_override("font_size", 14)
	hero_badge_lbl.add_theme_color_override("font_color", Color("00e5ff"))
	ch_vbox.add_child(hero_badge_lbl)

	hero_concept_lbl = Label.new()
	hero_concept_lbl.text = "Especialista arcano en piromancia..."
	hero_concept_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hero_concept_lbl.add_theme_font_size_override("font_size", 10)
	hero_concept_lbl.add_theme_color_override("font_color", Color("a0aec0"))
	ch_vbox.add_child(hero_concept_lbl)

	# Plantilla de la Clase (Sección Atributos y Sección Métodos)
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

	var bp_vbox := VBoxContainer.new()
	bp_vbox.add_theme_constant_override("separation", 6)
	bp_margin.add_child(bp_vbox)

	# Sección # Atributos
	var attr_title := Label.new()
	attr_title.text = "# ATRIBUTOS (Características del Objeto):"
	attr_title.add_theme_font_size_override("font_size", 11)
	attr_title.add_theme_color_override("font_color", Color("00e5ff"))
	bp_vbox.add_child(attr_title)

	var attr_slots_hbox := HBoxContainer.new()
	attr_slots_hbox.add_theme_constant_override("separation", 6)
	bp_vbox.add_child(attr_slots_hbox)

	slot_attr_btn1 = _create_slot_button("Slot Atributo 1", func(): _on_component_removed("ATTR", 0))
	attr_slots_hbox.add_child(slot_attr_btn1)

	slot_attr_btn2 = _create_slot_button("Slot Atributo 2", func(): _on_component_removed("ATTR", 1))
	attr_slots_hbox.add_child(slot_attr_btn2)

	# Sección # Métodos
	var meth_title := Label.new()
	meth_title.text = "# MÉTODOS (Funciones / Acciones del Objeto):"
	meth_title.add_theme_font_size_override("font_size", 11)
	meth_title.add_theme_color_override("font_color", Color("ffea00"))
	bp_vbox.add_child(meth_title)

	var meth_slots_hbox := HBoxContainer.new()
	meth_slots_hbox.add_theme_constant_override("separation", 6)
	bp_vbox.add_child(meth_slots_hbox)

	slot_meth_btn1 = _create_slot_button("Slot Método 1", func(): _on_component_removed("METH", 0))
	meth_slots_hbox.add_child(slot_meth_btn1)

	slot_meth_btn2 = _create_slot_button("Slot Método 2", func(): _on_component_removed("METH", 1))
	meth_slots_hbox.add_child(slot_meth_btn2)

	# Banco de Componentes Disponibles
	var bank_header := Label.new()
	bank_header.text = "Banco de Componentes (Toca para asignar a la plantilla):"
	bank_header.add_theme_font_size_override("font_size", 11)
	bank_header.add_theme_color_override("font_color", Color("e2e8f0"))
	main_vbox.add_child(bank_header)

	bank_grid = GridContainer.new()
	bank_grid.columns = 2
	bank_grid.add_theme_constant_override("h_separation", 6)
	bank_grid.add_theme_constant_override("v_separation", 6)
	main_vbox.add_child(bank_grid)

	# Botón de Acción Principal e Instrucciones
	btn_instantiate = Button.new()
	btn_instantiate.text = "🔨 ¡Instanciar Objeto! (Validar Clase)"
	btn_instantiate.custom_minimum_size = Vector2(0, 42)
	btn_instantiate.add_theme_font_size_override("font_size", 13)
	btn_instantiate.pressed.connect(_on_instantiate_pressed)
	main_vbox.add_child(btn_instantiate)

	status_banner_lbl = Label.new()
	status_banner_lbl.text = "Asigna 2 atributos y 2 métodos para instanciar la clase."
	status_banner_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_banner_lbl.add_theme_font_size_override("font_size", 10)
	status_banner_lbl.add_theme_color_override("font_color", Color("90a4ae"))
	main_vbox.add_child(status_banner_lbl)

	# ── Modal de Héroe Instanciado Exitosamente (FN-05 / FN-06) ──
	_build_modal_instance_overlay()

func _create_slot_button(default_text: String, on_press: Callable) -> Button:
	var btn := Button.new()
	btn.text = "[ %s ]" % default_text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 36)
	btn.add_theme_font_size_override("font_size", 10)
	btn.pressed.connect(on_press)
	return btn

func _build_modal_instance_overlay() -> void:
	modal_instance_overlay = PanelContainer.new()
	modal_instance_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_instance_overlay.visible = false

	var overlay_style := StyleBoxFlat.new()
	overlay_style.bg_color = Color(0.04, 0.06, 0.10, 0.94)
	modal_instance_overlay.add_theme_stylebox_override("panel", overlay_style)
	screen_game.add_child(modal_instance_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_instance_overlay.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 260)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("1a202c")
	card_style.border_color = Color("4caf50")
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 14)
	card_margin.add_theme_constant_override("margin_right", 14)
	card_margin.add_theme_constant_override("margin_top", 14)
	card_margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(card_margin)

	var card_vbox := VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 10)
	card_margin.add_child(card_vbox)

	modal_instance_avatar_lbl = Label.new()
	modal_instance_avatar_lbl.text = "🧙‍♂️🔥"
	modal_instance_avatar_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_instance_avatar_lbl.add_theme_font_size_override("font_size", 34)
	card_vbox.add_child(modal_instance_avatar_lbl)

	modal_instance_title_lbl = Label.new()
	modal_instance_title_lbl.text = "¡Instancia Creada con Éxito!"
	modal_instance_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_instance_title_lbl.add_theme_font_size_override("font_size", 14)
	modal_instance_title_lbl.add_theme_color_override("font_color", Color("4caf50"))
	card_vbox.add_child(modal_instance_title_lbl)

	modal_instance_desc_lbl = Label.new()
	modal_instance_desc_lbl.text = "Objeto MagoIgneo() en memoria..."
	modal_instance_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_instance_desc_lbl.add_theme_font_size_override("font_size", 10)
	modal_instance_desc_lbl.add_theme_color_override("font_color", Color("e2e8f0"))
	card_vbox.add_child(modal_instance_desc_lbl)

	modal_instance_next_btn = Button.new()
	modal_instance_next_btn.text = "▶ Siguiente Héroe →"
	modal_instance_next_btn.custom_minimum_size = Vector2(0, 38)
	modal_instance_next_btn.add_theme_font_size_override("font_size", 12)
	modal_instance_next_btn.pressed.connect(_on_next_hero_pressed)
	card_vbox.add_child(modal_instance_next_btn)

func _build_screen_pause() -> void:
	screen_pause = Control.new()
	screen_pause.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_pause.visible = false
	add_child(screen_pause)

	var pause_bg := ColorRect.new()
	pause_bg.color = Color(0.04, 0.05, 0.08, 0.88)
	pause_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_pause.add_child(pause_bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_pause.add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(240, 200)
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	var lbl := Label.new()
	lbl.text = "⏸️ Partida en Pausa"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color("ffeb3b"))
	box.add_child(lbl)

	var tip := Label.new()
	tip.text = "El tiempo y la mesa de forja están congelados."
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.add_theme_font_size_override("font_size", 10)
	tip.add_theme_color_override("font_color", Color("90a4ae"))
	box.add_child(tip)

	btn_pause_resume = Button.new()
	btn_pause_resume.text = "▶ Continuar Partida"
	btn_pause_resume.custom_minimum_size = Vector2(0, 40)
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

func _build_screen_victory() -> void:
	screen_victory = Control.new()
	screen_victory.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_victory.visible = false
	add_child(screen_victory)

	var vic_bg := ColorRect.new()
	vic_bg.color = Color(0.04, 0.08, 0.06, 0.92)
	vic_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_victory.add_child(vic_bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_victory.add_child(center)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(260, 260)
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	var title := Label.new()
	title.text = "🏆 ¡Forja Superada!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("76ff03"))
	box.add_child(title)

	lbl_victory_stats = Label.new()
	lbl_victory_stats.text = "Puntaje: 500 pts\nEstrellas: ⭐⭐\nVidas restantes: 3"
	lbl_victory_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_victory_stats.add_theme_font_size_override("font_size", 12)
	lbl_victory_stats.add_theme_color_override("font_color", Color("eceff1"))
	box.add_child(lbl_victory_stats)

	btn_victory_restart = Button.new()
	btn_victory_restart.text = "🔄 Jugar Otra Vez"
	btn_victory_restart.custom_minimum_size = Vector2(0, 40)
	btn_victory_restart.pressed.connect(func():
		_show_screen(screen_start)
		_show_difficulty_step()
	)
	box.add_child(btn_victory_restart)

	btn_victory_back = Button.new()
	btn_victory_back.text = "🚪 Volver al Salón 101"
	btn_victory_back.custom_minimum_size = Vector2(0, 36)
	btn_victory_back.pressed.connect(_on_back_pressed)
	box.add_child(btn_victory_back)

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
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)

	var title := Label.new()
	title.text = "💀 Fin de la Partida"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("f44336"))
	box.add_child(title)

	lbl_gameover_reason = Label.new()
	lbl_gameover_reason.text = "Vidas agotadas"
	lbl_gameover_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_gameover_reason.add_theme_font_size_override("font_size", 12)
	lbl_gameover_reason.add_theme_color_override("font_color", Color("ff8a80"))
	box.add_child(lbl_gameover_reason)

	btn_gameover_restart = Button.new()
	btn_gameover_restart.text = "🔄 Reintentar Forja"
	btn_gameover_restart.custom_minimum_size = Vector2(0, 40)
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
# GESTIÓN DE PANTALLAS Y PRE-PARTIDA
# ══════════════════════════════════════════════════════════════════════════════

func _show_screen(active_screen: Control) -> void:
	screen_start.visible = (active_screen == screen_start)
	screen_game.visible = (active_screen == screen_game)
	screen_pause.visible = (active_screen == screen_pause)
	screen_victory.visible = (active_screen == screen_victory)
	screen_game_over.visible = (active_screen == screen_game_over)

func _show_instructions_step() -> void:
	if AudioManager:
		AudioManager.play_click()
	container_instructions.visible = true
	container_difficulty.visible = false

func _show_difficulty_step() -> void:
	if AudioManager:
		AudioManager.play_click()
	container_instructions.visible = false
	container_difficulty.visible = true
	_select_difficulty(selected_diff)

func _select_difficulty(diff: String) -> void:
	selected_diff = diff
	diff_config = HeroForgeData.get_difficulty_config(selected_diff)

	var text_summary: String = "⚔️ %s:\n• %d Personajes a Instanciar\n• %d Vidas  |  %ds por Ronda\n• %d Puntos Totales (%d pts/héroe)\n• Otorga: %s" % [
		diff_config.name,
		diff_config.characters_count,
		diff_config.max_lives,
		int(diff_config.round_time),
		diff_config.total_score,
		diff_config.points_per_char,
		"⭐".repeat(diff_config.stars)
	]
	lbl_diff_summary.text = text_summary
	if AudioManager:
		AudioManager.play_click()

# ══════════════════════════════════════════════════════════════════════════════
# FN-01: INICIO DE PARTIDA Y CONFIGURACIÓN DE SESIÓN
# ══════════════════════════════════════════════════════════════════════════════

func _on_start_pressed() -> void:
	if AudioManager:
		AudioManager.play_click()
	start_game(selected_diff)

func start_game(difficulty: String = "NORMAL") -> void:
	super.start_game(difficulty)
	selected_diff = difficulty
	diff_config = HeroForgeData.get_difficulty_config(selected_diff)

	max_lives = diff_config.max_lives
	current_lives = max_lives
	round_time = diff_config.round_time
	time_left = round_time
	points_per_char = diff_config.points_per_char
	target_stars = diff_config.stars
	total_score = 0
	current_hero_index = 0
	is_game_paused = false
	is_timer_running = false

	hero_classes_queue = diff_config.classes.duplicate()

	# FN-01: Inicializar sesión en EventBus y HUD
	if EventBus.has_signal("session_started"):
		EventBus.emit_signal("session_started", current_lives, total_score)
	_update_hud()

	_show_screen(screen_game)

	# Carga del primer reto
	_load_class_challenge(current_hero_index)

func _update_hud() -> void:
	if hud_lives_lbl:
		hud_lives_lbl.text = "❤️".repeat(current_lives) + "🖤".repeat(maxi(0, max_lives - current_lives))
	if hud_score_lbl:
		hud_score_lbl.text = "%d pts" % total_score
	if hud_round_lbl:
		hud_round_lbl.text = "Héroe %d/%d" % [current_hero_index + 1, hero_classes_queue.size()]
	if timer_progress:
		timer_progress.max_value = round_time
		timer_progress.value = time_left

# ══════════════════════════════════════════════════════════════════════════════
# FN-02: CARGA DEL RETO Y MANEJO DE LA MESA DE FORJA
# ══════════════════════════════════════════════════════════════════════════════

func _load_class_challenge(index: int) -> void:
	if index >= hero_classes_queue.size():
		_handle_victory()
		return

	current_hero = hero_classes_queue[index]
	assigned_attributes = [null, null]
	assigned_methods = [null, null]

	time_left = round_time
	is_timer_running = true

	modal_instance_overlay.visible = false

	# Actualizar cabecera de la clase
	hero_badge_lbl.text = "class %s:  [%s]" % [current_hero.class_name, current_hero.avatar_symbol]
	hero_badge_lbl.add_theme_color_override("font_color", current_hero.badge_color)
	hero_concept_lbl.text = current_hero.concept

	# Generar y renderizar banco de componentes
	bank_items = HeroForgeData.generate_bank_for_hero(current_hero)
	_render_component_bank()
	_update_slot_displays()

	_set_status("Selecciona los 2 Atributos y 2 Métodos correctos para esta clase.", Color("90a4ae"))
	_update_hud()

func _render_component_bank() -> void:
	for child in bank_grid.get_children():
		child.queue_free()

	for i in range(bank_items.size()):
		var item: Dictionary = bank_items[i]
		var btn := Button.new()
		btn.text = item.text
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 36)
		btn.add_theme_font_size_override("font_size", 10)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		# Distinción de estilo visual: Atributos en azul/cian, Métodos en amarillo/ámbar
		if item.type == HeroForgeData.ComponentType.ATTRIBUTE:
			btn.add_theme_color_override("font_color", Color("80d8ff"))
		else:
			btn.add_theme_color_override("font_color", Color("ffe57f"))

		var is_assigned: bool = _is_item_assigned(item.id)
		btn.disabled = is_assigned
		if is_assigned:
			btn.modulate = Color(0.4, 0.4, 0.4, 0.6)
		else:
			btn.modulate = Color.WHITE

		var captured_item: Dictionary = item
		btn.pressed.connect(func(): _on_component_assigned(captured_item))
		bank_grid.add_child(btn)

func _is_item_assigned(item_id: String) -> bool:
	for slot in assigned_attributes:
		if slot != null and slot.id == item_id:
			return true
	for slot in assigned_methods:
		if slot != null and slot.id == item_id:
			return true
	return false

func _on_component_assigned(item: Dictionary) -> void:
	if is_game_paused or not is_timer_running:
		return

	# Si es atributo, busca slot libre en Atributos
	if item.type == HeroForgeData.ComponentType.ATTRIBUTE:
		if assigned_attributes[0] == null:
			assigned_attributes[0] = item
		elif assigned_attributes[1] == null:
			assigned_attributes[1] = item
		else:
			_set_status("⚠️ Los 2 slots de Atributos ya están llenos. Toca uno para quitarlo.", Color("ffb74d"))
			if AudioManager:
				AudioManager.play_click()
			return
	else: # Es método
		if assigned_methods[0] == null:
			assigned_methods[0] = item
		elif assigned_methods[1] == null:
			assigned_methods[1] = item
		else:
			_set_status("⚠️ Los 2 slots de Métodos ya están llenos. Toca uno para quitarlo.", Color("ffb74d"))
			if AudioManager:
				AudioManager.play_click()
			return

	if AudioManager:
		if AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("select")
		elif AudioManager.has_method("play_click"):
			AudioManager.play_click()

	_update_slot_displays()
	_render_component_bank()

# FA-02.02: Remoción de elemento asignado
func _on_component_removed(section: String, slot_index: int) -> void:
	if is_game_paused or not is_timer_running:
		return

	if section == "ATTR" and slot_index < assigned_attributes.size() and assigned_attributes[slot_index] != null:
		assigned_attributes[slot_index] = null
		if AudioManager:
			AudioManager.play_click()
	elif section == "METH" and slot_index < assigned_methods.size() and assigned_methods[slot_index] != null:
		assigned_methods[slot_index] = null
		if AudioManager:
			AudioManager.play_click()

	_update_slot_displays()
	_render_component_bank()
	_set_status("Elemento devuelto al banco.", Color("90a4ae"))

func _update_slot_displays() -> void:
	# Slot Atributo 1
	if assigned_attributes[0] != null:
		slot_attr_btn1.text = "✓ " + assigned_attributes[0].text
		slot_attr_btn1.add_theme_color_override("font_color", Color("00e5ff"))
	else:
		slot_attr_btn1.text = "[ + Asignar Atributo 1 ]"
		slot_attr_btn1.add_theme_color_override("font_color", Color("78909c"))

	# Slot Atributo 2
	if assigned_attributes[1] != null:
		slot_attr_btn2.text = "✓ " + assigned_attributes[1].text
		slot_attr_btn2.add_theme_color_override("font_color", Color("00e5ff"))
	else:
		slot_attr_btn2.text = "[ + Asignar Atributo 2 ]"
		slot_attr_btn2.add_theme_color_override("font_color", Color("78909c"))

	# Slot Método 1
	if assigned_methods[0] != null:
		slot_meth_btn1.text = "✓ " + assigned_methods[0].text
		slot_meth_btn1.add_theme_color_override("font_color", Color("ffea00"))
	else:
		slot_meth_btn1.text = "[ + Asignar Método 1 ]"
		slot_meth_btn1.add_theme_color_override("font_color", Color("78909c"))

	# Slot Método 2
	if assigned_methods[1] != null:
		slot_meth_btn2.text = "✓ " + assigned_methods[1].text
		slot_meth_btn2.add_theme_color_override("font_color", Color("ffea00"))
	else:
		slot_meth_btn2.text = "[ + Asignar Método 2 ]"
		slot_meth_btn2.add_theme_color_override("font_color", Color("78909c"))

# ══════════════════════════════════════════════════════════════════════════════
# FN-03 & FN-04: INSTANCIACIÓN Y VALIDACIÓN DE LA CLASE
# ══════════════════════════════════════════════════════════════════════════════

func _on_instantiate_pressed() -> void:
	if is_game_paused or not is_timer_running:
		return

	# FA-03.01: Intento de instanciación con plantilla incompleta
	if assigned_attributes[0] == null or assigned_attributes[1] == null or assigned_methods[0] == null or assigned_methods[1] == null:
		if AudioManager:
			AudioManager.play_error()
		_set_status("⚠️ Plantilla incompleta: Debes asignar 2 Atributos y 2 Métodos antes de forjar.", Color("ff9800"))
		return

	# FN-04: Validación de la estructura y distractores
	_validate_class()

func _validate_class() -> void:
	var errors: Array[String] = []

	# Validar Atributos
	for i in range(2):
		var item: Dictionary = assigned_attributes[i]
		if not item.is_correct:
			errors.append("Atributo distractor: '%s' no pertenece a %s" % [item.text, current_hero.class_name])
		elif item.expected_section != "ATTR":
			errors.append("Error de tipo: '%s' es un método, no un atributo" % item.text)

	# Validar Métodos
	for i in range(2):
		var item: Dictionary = assigned_methods[i]
		if not item.is_correct:
			errors.append("Método distractor: '%s' no pertenece a %s" % [item.text, current_hero.class_name])
		elif item.expected_section != "METH":
			errors.append("Error de tipo: '%s' es un atributo, no un método" % item.text)

	# FA-04.01: Clasificación errónea de componentes o distractor
	if errors.size() > 0:
		if AudioManager:
			AudioManager.play_error()

		_lose_life()
		if current_lives > 0:
			_set_status("❌ Error en la Clase: " + errors[0] + " (-1 vida)", Color("f44336"))
		else:
			_show_game_over("Vidas agotadas por errores de definición de clase.")
		return

	# FN-05 / FN-06: Construcción válida e Instanciación Exitosa
	_on_hero_instantiated_success()

func _on_hero_instantiated_success() -> void:
	is_timer_running = false

	if AudioManager:
		AudioManager.play_success()

	total_score += points_per_char
	if EventBus.has_signal("score_changed"):
		EventBus.emit_signal("score_changed", total_score)
	_update_hud()

	# Mostrar tarjeta del objeto forjado
	modal_instance_avatar_lbl.text = current_hero.avatar_symbol
	modal_instance_title_lbl.text = "¡%s Instanciado con Éxito! (+%d pts)" % [current_hero.class_name, points_per_char]
	modal_instance_desc_lbl.text = current_hero.instance_lore
	modal_instance_overlay.visible = true

func _on_next_hero_pressed() -> void:
	if AudioManager:
		AudioManager.play_click()
	modal_instance_overlay.visible = false
	current_hero_index += 1
	_load_class_challenge(current_hero_index)

# ══════════════════════════════════════════════════════════════════════════════
# CONTROL DE TIEMPO, VIDAS Y FLUJOS DE EXCEPCIÓN
# ══════════════════════════════════════════════════════════════════════════════

func _lose_life() -> void:
	current_lives = maxi(0, current_lives - 1)
	if EventBus.has_signal("life_lost"):
		EventBus.emit_signal("life_lost", current_lives)
	_update_hud()

# FA-04.02: Tiempo límite de ronda agotado
func _on_round_timer_timeout() -> void:
	if not is_timer_running or is_game_paused:
		return

	if AudioManager:
		AudioManager.play_error()

	_lose_life()

	if current_lives > 0:
		time_left = round_time
		_set_status("⏱️ ¡Tiempo agotado para este héroe! (-1 vida). Reloj reiniciado.", Color("ff9800"))
	else:
		_show_game_over("Tiempo límite agotado y te quedaste sin vidas.")

# FA-02.01: Suspensión de la partida (Pausa)
func _on_pause_pressed() -> void:
	if AudioManager:
		AudioManager.play_click()
	_set_game_paused(true)

func _on_resume_pressed() -> void:
	if AudioManager:
		AudioManager.play_click()
	_set_game_paused(false)

func _set_game_paused(paused: bool) -> void:
	is_game_paused = paused
	screen_pause.visible = paused

# FA-04.03: Game Over
func _show_game_over(reason: String) -> void:
	is_timer_running = false
	_set_game_paused(false)

	if AudioManager:
		AudioManager.play_game_over()

	lbl_gameover_reason.text = reason
	_show_screen(screen_game_over)

# FN-07: Victoria y Persistencia Atómica
func _handle_victory() -> void:
	is_timer_running = false
	_set_game_paused(false)

	if AudioManager:
		if AudioManager.has_method("play_sfx"):
			AudioManager.play_sfx("victory")
		elif AudioManager.has_method("play_success"):
			AudioManager.play_success()

	var stars: int = target_stars
	if current_lives == max_lives:
		stars = mini(3, stars + 1)

	var lives_bonus: int = current_lives * 25
	var final_score: int = total_score + lives_bonus

	lbl_victory_stats.text = "🎯 Héroes Forjados: %d/%d\n🏆 Puntos Obtenidos: %d (+%d bonus vidas)\n⭐ Estrellas Ganadas: %s\n❤️ Vidas Restantes: %d" % [
		hero_classes_queue.size(),
		hero_classes_queue.size(),
		final_score,
		lives_bonus,
		"⭐".repeat(stars),
		current_lives
	]

	# Persistir mediante MiniGameBase y StateManager
	finish_game(true, final_score, stars, "Forja de Clases completada con éxito")

	if EventBus.has_signal("progress_saved"):
		EventBus.emit_signal("progress_saved", final_score)

	_show_screen(screen_victory)

func _set_status(msg: String, color: Color) -> void:
	if status_banner_lbl:
		status_banner_lbl.text = msg
		status_banner_lbl.add_theme_color_override("font_color", color)

func _on_back_pressed() -> void:
	is_timer_running = false
	_set_game_paused(false)

	if AudioManager:
		AudioManager.play_click()

	if ResourceLoader.exists("res://scenes/classroom/AulaProgramacion.tscn"):
		get_tree().change_scene_to_file("res://scenes/classroom/AulaProgramacion.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/campus/Lobby.tscn")

# ══════════════════════════════════════════════════════════════════════════════
# MODO DEPURACIÓN QA (F8 / Ctrl+W)
# ══════════════════════════════════════════════════════════════════════════════

func _trigger_debug_win() -> void:
	current_hero_index = hero_classes_queue.size()
	total_score = diff_config.get("total_score", 500)
	current_lives = max_lives
	_handle_victory()
