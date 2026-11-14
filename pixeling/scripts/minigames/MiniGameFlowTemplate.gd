## MiniGameFlowTemplate.gd
## Componente / Plantilla Universal para Pantallas de Minijuegos en Godot 4
## Estandariza:
##   1. Paso 1: Instrucciones y Reglas (Kenney UI + Fondo de Aula)
##   2. Paso 2: Selección de Dificultad (Kenney UI + Selector Interactivo)
##   3. Pantalla de Pausa Congruente
## Diseñado para congruencia visual total y eliminación de código redundante.
class_name MiniGameFlowTemplate
extends Control

signal start_requested(difficulty: String)
signal back_requested()
signal pause_resume_requested()
signal pause_restart_requested()
signal pause_exit_requested()
signal victory_continue_requested()
signal play_again_requested()
signal game_over_retry_requested()

# Vistas principales
var screen_instructions: Control
var screen_difficulty: Control
var screen_pause: Control

# Modales de resultado universal (Kenney UI de interfazDEMO)
var victory_modal: Control
var game_over_modal: Control

# Referencias dinámicas de instrucciones
var lbl_title_inst: Label
var lbl_sub_inst: Label
var card_instructions: PanelContainer
var vbox_inst_content: VBoxContainer
var btn_to_diff: Button
var btn_inst_back: Button

# Referencias dinámicas de dificultad
var lbl_title_diff: Label
var lbl_sub_diff: Label
var btn_diff_facil: Button
var btn_diff_normal: Button
var btn_diff_ing: Button
var lbl_diff_info: Label
var btn_start_game: Button
var btn_to_inst: Button
var btn_diff_back: Button

# Referencias de pausa
var btn_pause_resume: Button
var btn_pause_restart: Button
var btn_pause_exit: Button

const DIFF_INFO_BOX_SIZE := Vector2(272, 62)

# Configuración activa
var config: Dictionary = {}
var selected_diff: String = "NORMAL"
var classroom_scene_path: String = "res://scenes/classroom/AulaProgramacion.tscn"

func _init() -> void:
	name = "MiniGameFlowTemplate"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP

func setup(p_config: Dictionary) -> void:
	config = p_config
	selected_diff = config.get("default_difficulty", "NORMAL")
	if config.has("classroom_path"):
		classroom_scene_path = config.get("classroom_path")

	_build_instructions_screen()
	_build_difficulty_screen()
	_build_pause_screen()
	_build_result_modals()

	# Iniciar mostrando instrucciones
	show_instructions()

## Paso 1: Construcción de Pantalla de Instrucciones
func _build_instructions_screen() -> void:
	screen_instructions = Control.new()
	screen_instructions.name = "ScreenInstructions"
	screen_instructions.set_anchors_preset(Control.PRESET_FULL_RECT)
	_attach_bg(screen_instructions, 0.65)
	add_child(screen_instructions)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_instructions.add_child(center)

	var main_vbox := VBoxContainer.new()
	main_vbox.custom_minimum_size = Vector2(320, 0)
	main_vbox.add_theme_constant_override("separation", 10)
	center.add_child(main_vbox)

	# Encabezado (Título cyan + Subtítulo)
	var header_vbox := VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 2)
	main_vbox.add_child(header_vbox)

	lbl_title_inst = Label.new()
	lbl_title_inst.text = config.get("title", "Minijuego")
	lbl_title_inst.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title_inst.add_theme_font_size_override("font_size", 20)
	lbl_title_inst.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
	header_vbox.add_child(lbl_title_inst)

	lbl_sub_inst = Label.new()
	lbl_sub_inst.text = config.get("subtitle", "Instrucciones del Desafío")
	lbl_sub_inst.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub_inst.add_theme_font_size_override("font_size", 11)
	lbl_sub_inst.add_theme_color_override("font_color", Color(0.72, 0.80, 0.90))
	header_vbox.add_child(lbl_sub_inst)

	# Tarjeta central con panel Kenney
	card_instructions = PanelContainer.new()
	_style_panel(card_instructions, "inner")
	main_vbox.add_child(card_instructions)

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 12)
	card_margin.add_theme_constant_override("margin_right", 12)
	card_margin.add_theme_constant_override("margin_top", 10)
	card_margin.add_theme_constant_override("margin_bottom", 10)
	card_instructions.add_child(card_margin)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(296, 230)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card_margin.add_child(scroll)

	vbox_inst_content = VBoxContainer.new()
	vbox_inst_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_inst_content.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox_inst_content)

	# Contenido: Objetivo
	var obj_text: String = config.get("objective", "")
	if obj_text != "":
		var lbl_obj := Label.new()
		lbl_obj.text = "🎯 Objetivo: " + obj_text
		lbl_obj.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_obj.add_theme_font_size_override("font_size", 11)
		lbl_obj.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
		vbox_inst_content.add_child(lbl_obj)

	# Contenido: Secciones personalizadas o Reglas
	if config.has("sections"):
		var sections: Array = config.get("sections", [])
		for sec in sections:
			var sec_title: String = sec.get("title", "")
			if sec_title != "":
				var lbl_sec_title := Label.new()
				lbl_sec_title.text = sec_title
				lbl_sec_title.add_theme_font_size_override("font_size", 12)
				lbl_sec_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
				vbox_inst_content.add_child(lbl_sec_title)
			
			var sec_text: String = sec.get("text", "")
			if sec_text != "":
				var lbl_sec := Label.new()
				lbl_sec.text = sec_text
				lbl_sec.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				lbl_sec.add_theme_font_size_override("font_size", 11)
				lbl_sec.add_theme_color_override("font_color", Color(0.88, 0.92, 0.98))
				vbox_inst_content.add_child(lbl_sec)
	elif config.has("rules"):
		var rules: Array = config.get("rules", [])
		for r in rules:
			var lbl_rule := Label.new()
			lbl_rule.text = "• " + str(r)
			lbl_rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl_rule.add_theme_font_size_override("font_size", 11)
			lbl_rule.add_theme_color_override("font_color", Color(0.88, 0.92, 0.98))
			vbox_inst_content.add_child(lbl_rule)

	# Botones de navegación
	btn_to_diff = Button.new()
	btn_to_diff.text = "Siguiente: Elegir Dificultad →"
	_style_button(btn_to_diff, "green", 44.0)
	btn_to_diff.pressed.connect(func():
		_play_click()
		show_difficulty()
	)
	main_vbox.add_child(btn_to_diff)

	btn_inst_back = Button.new()
	btn_inst_back.text = "← Volver al Salón"
	_style_button(btn_inst_back, "neutral", 38.0)
	btn_inst_back.pressed.connect(_on_back_pressed)
	main_vbox.add_child(btn_inst_back)

## Paso 2: Construcción de Pantalla de Selección de Dificultad
func _build_difficulty_screen() -> void:
	screen_difficulty = Control.new()
	screen_difficulty.name = "ScreenDifficulty"
	screen_difficulty.set_anchors_preset(Control.PRESET_FULL_RECT)
	_attach_bg(screen_difficulty, 0.65)
	add_child(screen_difficulty)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_difficulty.add_child(center)

	var main_vbox := VBoxContainer.new()
	main_vbox.custom_minimum_size = Vector2(320, 0)
	main_vbox.add_theme_constant_override("separation", 10)
	center.add_child(main_vbox)

	# Encabezado congruente
	var header_vbox := VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 2)
	main_vbox.add_child(header_vbox)

	lbl_title_diff = Label.new()
	lbl_title_diff.text = config.get("title", "Minijuego")
	lbl_title_diff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title_diff.add_theme_font_size_override("font_size", 20)
	lbl_title_diff.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
	header_vbox.add_child(lbl_title_diff)

	lbl_sub_diff = Label.new()
	lbl_sub_diff.text = config.get("subtitle", "Selección de Dificultad")
	lbl_sub_diff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub_diff.add_theme_font_size_override("font_size", 11)
	lbl_sub_diff.add_theme_color_override("font_color", Color(0.72, 0.80, 0.90))
	header_vbox.add_child(lbl_sub_diff)

	var lbl_prompt := Label.new()
	lbl_prompt.text = "Selecciona la Dificultad:"
	lbl_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_prompt.add_theme_font_size_override("font_size", 13)
	lbl_prompt.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	main_vbox.add_child(lbl_prompt)

	# Selector de Dificultad (3 Botones con sus colores oficiales)
	var diff_hbox := HBoxContainer.new()
	diff_hbox.add_theme_constant_override("separation", 8)
	main_vbox.add_child(diff_hbox)

	btn_diff_facil = Button.new()
	btn_diff_facil.text = "Fácil"
	btn_diff_facil.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(btn_diff_facil, "blue", 42.0)
	btn_diff_facil.pressed.connect(func(): select_difficulty("FACIL"))
	diff_hbox.add_child(btn_diff_facil)

	btn_diff_normal = Button.new()
	btn_diff_normal.text = "Normal"
	btn_diff_normal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(btn_diff_normal, "yellow", 42.0)
	btn_diff_normal.pressed.connect(func(): select_difficulty("NORMAL"))
	diff_hbox.add_child(btn_diff_normal)

	btn_diff_ing = Button.new()
	btn_diff_ing.text = "Ingeniero"
	btn_diff_ing.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(btn_diff_ing, "red", 42.0)
	btn_diff_ing.pressed.connect(func(): select_difficulty("INGENIERO"))
	diff_hbox.add_child(btn_diff_ing)

	# Panel de información de dificultad seleccionada
	var diff_plate := PanelContainer.new()
	_style_panel(diff_plate, "inner")
	diff_plate.custom_minimum_size = Vector2(0, 95)
	main_vbox.add_child(diff_plate)

	var diff_margin := MarginContainer.new()
	diff_margin.add_theme_constant_override("margin_left", 12)
	diff_margin.add_theme_constant_override("margin_right", 12)
	diff_margin.add_theme_constant_override("margin_top", 10)
	diff_margin.add_theme_constant_override("margin_bottom", 10)
	diff_plate.add_child(diff_margin)

	var diff_info_host := Control.new()
	diff_info_host.custom_minimum_size = DIFF_INFO_BOX_SIZE
	diff_info_host.clip_contents = true
	diff_margin.add_child(diff_info_host)

	lbl_diff_info = Label.new()
	lbl_diff_info.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_diff_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_diff_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_diff_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_diff_info.add_theme_font_size_override("font_size", 11)
	lbl_diff_info.add_theme_color_override("font_color", Color(1.0, 0.95, 0.70))
	diff_info_host.add_child(lbl_diff_info)

	# Botón principal para iniciar
	btn_start_game = Button.new()
	btn_start_game.text = "▶ ¡COMENZAR!"
	_style_button(btn_start_game, "green", 46.0)
	btn_start_game.add_theme_font_size_override("font_size", 14)
	btn_start_game.pressed.connect(_on_start_pressed)
	main_vbox.add_child(btn_start_game)

	# Botón volver a instrucciones
	btn_to_inst = Button.new()
	btn_to_inst.text = "← Ver Instrucciones"
	_style_button(btn_to_inst, "blue", 38.0)
	btn_to_inst.pressed.connect(func():
		_play_click()
		show_instructions()
	)
	main_vbox.add_child(btn_to_inst)

	# Botón volver al aula
	btn_diff_back = Button.new()
	btn_diff_back.text = "← Volver al Salón"
	_style_button(btn_diff_back, "neutral", 38.0)
	btn_diff_back.pressed.connect(_on_back_pressed)
	main_vbox.add_child(btn_diff_back)

	select_difficulty(selected_diff)

## Paso 3: Construcción de Pantalla de Pausa Universal
func _build_pause_screen() -> void:
	screen_pause = Control.new()
	screen_pause.name = "ScreenPause"
	screen_pause.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_pause.visible = false
	screen_pause.process_mode = Node.PROCESS_MODE_ALWAYS
	_attach_bg(screen_pause, 0.75)
	add_child(screen_pause)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_pause.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 0)
	_style_panel(panel, "screws")
	center.add_child(panel)

	var p_margin := MarginContainer.new()
	p_margin.add_theme_constant_override("margin_left", 16)
	p_margin.add_theme_constant_override("margin_right", 16)
	p_margin.add_theme_constant_override("margin_top", 14)
	p_margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(p_margin)

	var p_vbox := VBoxContainer.new()
	p_vbox.add_theme_constant_override("separation", 10)
	p_margin.add_child(p_vbox)

	var p_title := Label.new()
	p_title.text = "JUEGO PAUSADO"
	p_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_title.add_theme_font_size_override("font_size", 16)
	p_title.add_theme_color_override("font_color", Color(1.0, 0.90, 0.35))
	p_vbox.add_child(p_title)

	var p_sub := Label.new()
	p_sub.text = "Tiempo detenido"
	p_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_sub.add_theme_font_size_override("font_size", 11)
	p_sub.add_theme_color_override("font_color", Color(0.70, 0.75, 0.85))
	p_vbox.add_child(p_sub)

	btn_pause_resume = Button.new()
	btn_pause_resume.text = "Reanudar"
	_style_button(btn_pause_resume, "green", 40.0)
	btn_pause_resume.pressed.connect(_on_pause_resume)
	p_vbox.add_child(btn_pause_resume)

	btn_pause_restart = Button.new()
	btn_pause_restart.text = "Reiniciar Nivel"
	_style_button(btn_pause_restart, "yellow", 40.0)
	btn_pause_restart.pressed.connect(_on_pause_restart)
	p_vbox.add_child(btn_pause_restart)

	btn_pause_exit = Button.new()
	btn_pause_exit.text = "Volver al Salón"
	_style_button(btn_pause_exit, "red", 38.0)
	btn_pause_exit.pressed.connect(_on_pause_exit)
	p_vbox.add_child(btn_pause_exit)

## Paso 4: Construcción / Conexión de Modales Universales de Resultado (Kenney UI)
func _build_result_modals() -> void:
	var vic_scene = load("res://scenes/ui/modals/VictoryModal.tscn")
	if vic_scene:
		victory_modal = vic_scene.instantiate()
		add_child(victory_modal)
		victory_modal.visible = false
		if victory_modal.has_signal("continue_requested"):
			victory_modal.continue_requested.connect(_on_victory_continue)
		if victory_modal.has_signal("play_again_requested"):
			victory_modal.play_again_requested.connect(_on_victory_play_again)
		if victory_modal.has_signal("exit_requested"):
			victory_modal.exit_requested.connect(_on_back_pressed)

	var go_scene = load("res://scenes/ui/modals/GameOverModal.tscn")
	if go_scene:
		game_over_modal = go_scene.instantiate()
		add_child(game_over_modal)
		game_over_modal.visible = false
		if game_over_modal.has_signal("retry_requested"):
			game_over_modal.retry_requested.connect(_on_game_over_retry)
		if game_over_modal.has_signal("exit_requested"):
			game_over_modal.exit_requested.connect(_on_back_pressed)

## Selección de Dificultad con modulación limpia
func select_difficulty(diff: String) -> void:
	selected_diff = diff
	var dim_color := Color(0.55, 0.55, 0.55, 1.0)
	btn_diff_facil.modulate = Color.WHITE if diff == "FACIL" else dim_color
	btn_diff_normal.modulate = Color.WHITE if diff == "NORMAL" else dim_color
	btn_diff_ing.modulate = Color.WHITE if diff == "INGENIERO" else dim_color

	var diffs_dict: Dictionary = config.get("difficulties", {})
	if diffs_dict.has(diff):
		var d_data = diffs_dict[diff]
		if d_data is Dictionary:
			lbl_diff_info.text = d_data.get("info", d_data.get("desc", ""))
		else:
			lbl_diff_info.text = str(d_data)
	else:
		lbl_diff_info.text = "Dificultad seleccionada: %s" % diff

	MiniGameBase.apply_text_auto_fit(lbl_diff_info, DIFF_INFO_BOX_SIZE, 11, 7, 0.0, 0.0, true)

## Control de visibilidad
func show_instructions() -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	screen_instructions.visible = true
	screen_difficulty.visible = false
	screen_pause.visible = false

func show_difficulty() -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	screen_instructions.visible = false
	screen_difficulty.visible = true
	screen_pause.visible = false

func show_pause() -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	screen_pause.visible = true

func hide_pause() -> void:
	screen_pause.visible = false
	if (not victory_modal or not victory_modal.visible) and (not game_over_modal or not game_over_modal.visible):
		visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_victory(score: int, stars: int = 3, reward: int = -1, is_new_record: bool = false, custom_title: String = "") -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	if screen_instructions: screen_instructions.visible = false
	if screen_difficulty: screen_difficulty.visible = false
	if screen_pause: screen_pause.visible = false
	if game_over_modal and game_over_modal.has_method("close"):
		game_over_modal.close()
	var total_points: int = reward
	if StateManager and StateManager.has_method("get_points"):
		total_points = StateManager.get_points()
	elif total_points < 0:
		total_points = score
	if victory_modal and victory_modal.has_method("open"):
		victory_modal.open(score, stars, total_points, is_new_record, custom_title)

func show_game_over(reason: String = "Has agotado todas tus vidas disponibles.", score: int = 0) -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	if screen_instructions: screen_instructions.visible = false
	if screen_difficulty: screen_difficulty.visible = false
	if screen_pause: screen_pause.visible = false
	if victory_modal and victory_modal.has_method("close"):
		victory_modal.close()
	if game_over_modal and game_over_modal.has_method("open"):
		game_over_modal.open(reason, score)

func hide_all() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if screen_instructions:
		screen_instructions.visible = false
	if screen_difficulty:
		screen_difficulty.visible = false
	if screen_pause:
		screen_pause.visible = false
	if victory_modal and victory_modal.has_method("close"):
		victory_modal.close()
	if game_over_modal and game_over_modal.has_method("close"):
		game_over_modal.close()

func get_selected_difficulty() -> String:
	return selected_diff

# Handlers internos
func _on_start_pressed() -> void:
	_play_click()
	hide_all()
	start_requested.emit(selected_diff)
	if config.has("on_start") and config["on_start"] is Callable:
		config["on_start"].call(selected_diff)

func _unpause_tree() -> void:
	var tree := get_tree()
	if tree:
		tree.paused = false

func _on_back_pressed() -> void:
	_play_click()
	_unpause_tree()
	back_requested.emit()
	if config.has("on_back") and config["on_back"] is Callable:
		config["on_back"].call()
	else:
		if ResourceLoader.exists(classroom_scene_path):
			get_tree().change_scene_to_file(classroom_scene_path)
		else:
			get_tree().change_scene_to_file("res://scenes/campus/Lobby.tscn")

func _on_pause_resume() -> void:
	_play_click()
	_unpause_tree()
	hide_pause()
	pause_resume_requested.emit()
	if config.has("on_resume") and config["on_resume"] is Callable:
		config["on_resume"].call()

func _on_pause_restart() -> void:
	_play_click()
	_unpause_tree()
	hide_pause()
	pause_restart_requested.emit()
	if config.has("on_restart") and config["on_restart"] is Callable:
		config["on_restart"].call()

func _on_pause_exit() -> void:
	_play_click()
	_unpause_tree()
	hide_pause()
	pause_exit_requested.emit()
	_on_back_pressed()

func _on_victory_continue() -> void:
	_play_click()
	_unpause_tree()
	victory_continue_requested.emit()
	if config.has("on_continue") and config["on_continue"] is Callable:
		config["on_continue"].call()
	else:
		_on_back_pressed()

func _on_victory_play_again() -> void:
	_play_click()
	_unpause_tree()
	hide_all()
	play_again_requested.emit()
	if config.has("on_restart") and config["on_restart"] is Callable:
		config["on_restart"].call()
	elif config.has("on_start") and config["on_start"] is Callable:
		show_difficulty()

func _on_game_over_retry() -> void:
	_play_click()
	_unpause_tree()
	hide_all()
	game_over_retry_requested.emit()
	if config.has("on_restart") and config["on_restart"] is Callable:
		config["on_restart"].call()
	elif config.has("on_start") and config["on_start"] is Callable:
		show_difficulty()

func _play_click() -> void:
	if AudioManager and AudioManager.has_method("play_click"):
		AudioManager.play_click()

## Helpers de diseño
func _attach_bg(target: Control, overlay_alpha: float = 0.65) -> void:
	var bg := TextureRect.new()
	bg.name = "ClassroomBg"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var path := "res://assets/lobby/salon.jpg"
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			bg.texture = res

	var overlay := ColorRect.new()
	overlay.name = "DarkOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.04, 0.05, 0.08, overlay_alpha)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	target.add_child(bg)
	target.move_child(bg, 0)
	target.add_child(overlay)
	target.move_child(overlay, 1)

func _style_button(btn: Button, color_type: String = "neutral", custom_h: float = 40.0) -> void:
	var base_path := "res://scenes/ui/theme/classic/btn_%s_" % color_type
	var norm_path := base_path + "normal.tres"
	var hov_path := base_path + "hover.tres"
	var press_path := base_path + "pressed.tres"

	if ResourceLoader.exists(norm_path) and ResourceLoader.exists(hov_path) and ResourceLoader.exists(press_path):
		btn.add_theme_stylebox_override("normal", load(norm_path))
		btn.add_theme_stylebox_override("hover", load(hov_path))
		btn.add_theme_stylebox_override("pressed", load(press_path))
		btn.add_theme_stylebox_override("focus", load(hov_path))

	match color_type:
		"green":
			btn.add_theme_color_override("font_color", Color(0.04, 0.22, 0.08, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(0.02, 0.30, 0.05, 1.0))
		"yellow":
			btn.add_theme_color_override("font_color", Color(0.24, 0.18, 0.02, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(0.34, 0.24, 0.02, 1.0))
		"blue":
			btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
		"red":
			btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
		"neutral", _:
			btn.add_theme_color_override("font_color", Color(0.18, 0.20, 0.28, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(0.08, 0.10, 0.18, 1.0))

	if custom_h > 0.0:
		btn.custom_minimum_size = Vector2(btn.custom_minimum_size.x, custom_h)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _style_panel(panel: PanelContainer, panel_type: String = "inner") -> void:
	var path := ""
	match panel_type:
		"screws":
			path = "res://scenes/ui/theme/classic/panel_screws.tres"
		"inner", _:
			path = "res://scenes/ui/theme/classic/panel_inner_plate.tres"

	if ResourceLoader.exists(path):
		panel.add_theme_stylebox_override("panel", load(path))
