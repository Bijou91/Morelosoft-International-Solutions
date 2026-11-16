## ClassroomBase.gd - Plantilla Base Reutilizable para Aulas Temáticas de PixelIng
## Permite añadir nuevas materias y catálogos de minijuegos con Cero Retrabajo
## Responsable: Carlos Manuel Aguirre Norato (Líder Técnico & Arquitecto)
class_name ClassroomBase extends Control

@export var classroom_name: String = "Aula: Materia Universitaria"
@export var subject_code: String = "MAT-01"
@export var teacher_name: String = "Profesor de la Asignatura"
@export var teacher_tip: String = "Revisa los conceptos clave antes de ingresar al minijuego didáctico."
@export var minigames_list: Array[Dictionary] = []

@onready var lbl_title: Label = $VBox/Title
@onready var lbl_code: Label = $VBox/TopHUD/SubjectCode
@onready var lbl_tip: Label = $VBox/Blackboard/Margin/VBox/LabelTip
@onready var minigames_container: VBoxContainer = $VBox/MinigamesSection/Scroll/MinigamesList
@onready var btn_back: Button = $VBox/TopHUD/BtnBack

func _ready() -> void:
	_load_background()
	_setup_ui_styles()
	
	if lbl_title:
		lbl_title.text = classroom_name
	if lbl_code:
		lbl_code.text = subject_code
	if lbl_tip:
		lbl_tip.text = "%s:\n\"%s\"" % [teacher_name, teacher_tip]
	if btn_back:
		btn_back.pressed.connect(_on_back_to_lobby)
		_style_translucent_button(btn_back)
	
	var eb: Node = null
	if is_inside_tree() and get_tree() and get_tree().root:
		eb = get_tree().root.get_node_or_null("EventBus")
	if eb:
		eb.minigame_completed.connect(func(_id, _res): _populate_minigames())
		eb.points_updated.connect(func(_tot, _delta): _populate_minigames())

	# Asegurar música de fondo del campus si regresa de un minijuego
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_music"):
		am.play_music("res://assets/lobby/musica/Geometry_of_Thought.mp3", true)

	_populate_minigames()

func _load_background() -> void:
	var bg: TextureRect = get_node_or_null("Background")
	if not bg:
		return
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	if bg.texture == null:
		var path := "res://assets/lobby/salon.jpg"
		if ResourceLoader.exists(path):
			var res = load(path)
			if res is Texture2D:
				bg.texture = res
				return
		if FileAccess.file_exists(path):
			var img := Image.load_from_file(path)
			if img and not img.is_empty():
				bg.texture = ImageTexture.create_from_image(img)

func _setup_ui_styles() -> void:
	var blackboard: PanelContainer = get_node_or_null("VBox/Blackboard")
	if blackboard:
		var sb_board := StyleBoxFlat.new()
		sb_board.bg_color = Color(0.08, 0.10, 0.15, 0.85)
		sb_board.set_corner_radius_all(6)
		sb_board.border_width_left = 1
		sb_board.border_width_top = 1
		sb_board.border_width_right = 1
		sb_board.border_width_bottom = 1
		sb_board.border_color = Color(0.25, 0.32, 0.45, 0.60)
		blackboard.add_theme_stylebox_override("panel", sb_board)

func _style_translucent_button(btn: Button) -> void:
	if not btn:
		return
	var norm_path := "res://scenes/ui/theme/classic/btn_neutral_normal.tres"
	var hov_path := "res://scenes/ui/theme/classic/btn_neutral_hover.tres"
	var press_path := "res://scenes/ui/theme/classic/btn_neutral_pressed.tres"
	if ResourceLoader.exists(norm_path) and ResourceLoader.exists(hov_path) and ResourceLoader.exists(press_path):
		var sb_norm: StyleBox = load(norm_path).duplicate()
		var sb_hov: StyleBox = load(hov_path).duplicate()
		var sb_press: StyleBox = load(press_path).duplicate()
		if sb_norm is StyleBoxTexture:
			sb_norm.modulate_color = Color(1.0, 1.0, 1.0, 0.85)
		if sb_hov is StyleBoxTexture:
			sb_hov.modulate_color = Color(1.1, 1.1, 1.1, 0.95)
		if sb_press is StyleBoxTexture:
			sb_press.modulate_color = Color(0.9, 0.9, 0.9, 0.90)
		btn.add_theme_stylebox_override("normal", sb_norm)
		btn.add_theme_stylebox_override("hover", sb_hov)
		btn.add_theme_stylebox_override("pressed", sb_press)
		btn.add_theme_stylebox_override("focus", sb_hov)
		btn.add_theme_color_override("font_color", Color(0.12, 0.15, 0.22, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(0.05, 0.08, 0.15, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.0, 0.0, 0.0, 1.0))
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		return

	# Fallback a estilo plano con transparencia si los temas no están disponibles
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.10, 0.12, 0.18, 0.80)
	sb_normal.set_corner_radius_all(6)
	sb_normal.set_content_margin_all(8)
	sb_normal.border_width_left = 1
	sb_normal.border_width_top = 1
	sb_normal.border_width_right = 1
	sb_normal.border_width_bottom = 1
	sb_normal.border_color = Color(0.35, 0.45, 0.65, 0.70)

	var sb_hover := sb_normal.duplicate()
	sb_hover.bg_color = Color(0.16, 0.22, 0.32, 0.85)
	sb_hover.border_color = Color(0.55, 0.75, 1.0, 0.95)

	var sb_pressed := sb_normal.duplicate()
	sb_pressed.bg_color = Color(0.06, 0.08, 0.12, 0.90)
	sb_pressed.border_color = Color(0.25, 0.35, 0.50, 0.80)

	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_stylebox_override("focus", sb_hover)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _populate_minigames() -> void:
	if not minigames_container:
		minigames_container = find_child("MinigamesList", true, false) as VBoxContainer
	if not minigames_container:
		return
	
	for child in minigames_container.get_children():
		child.queue_free()
		
	for game in minigames_list:
		var btn := Button.new()
		var cu_id: String = game.get("id", "CU-XX")
		var title: String = game.get("name", "Minijuego")
		var scene_path: String = game.get("scene", "")
		
		var sm: Node = null
		if is_inside_tree() and get_tree() and get_tree().root:
			sm = get_tree().root.get_node_or_null("StateManager")
		var saved_data: Dictionary = sm.get_minigame_data(cu_id) if sm else {}
		var last_stars: int = clampi(int(saved_data.get("last_stars", 0)), 0, 3)
		var last_score: int = maxi(0, int(saved_data.get("last_score", 0)))
		var last_diff: String = str(saved_data.get("last_difficulty", "")).strip_edges()

		btn.text = ""
		btn.custom_minimum_size = Vector2(0, 58)
		btn.tooltip_text = title
		_style_translucent_button(btn)

		var card_vbox := VBoxContainer.new()
		card_vbox.name = "CardVBox"
		card_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		card_vbox.offset_left = 10.0
		card_vbox.offset_right = -10.0
		card_vbox.offset_top = 4.0
		card_vbox.offset_bottom = -6.0
		card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_theme_constant_override("separation", 2)
		btn.add_child(card_vbox)

		var title_lbl := Label.new()
		title_lbl.name = "TitleLabel"
		title_lbl.text = title
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_lbl.add_theme_font_size_override("font_size", 12)
		title_lbl.add_theme_color_override("font_color", Color(0.12, 0.15, 0.22, 1.0))
		title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		card_vbox.add_child(title_lbl)

		var stats_row := HBoxContainer.new()
		stats_row.name = "StatsRow"
		stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
		stats_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stats_row.add_theme_constant_override("separation", 6)
		card_vbox.add_child(stats_row)

		var stars_box := HBoxContainer.new()
		stars_box.name = "StarsBox"
		stars_box.alignment = BoxContainer.ALIGNMENT_CENTER
		stars_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stars_box.add_theme_constant_override("separation", 1)
		stats_row.add_child(stars_box)

		for i in range(3):
			var star_lbl := Label.new()
			star_lbl.name = "Star_%d" % i
			star_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			star_lbl.add_theme_font_size_override("font_size", 13)
			if i < last_stars:
				star_lbl.text = "★"
				star_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
				star_lbl.add_theme_color_override("font_outline_color", Color(0.18, 0.12, 0.02, 1.0))
				star_lbl.add_theme_constant_override("outline_size", 3)
			else:
				star_lbl.text = "☆"
				star_lbl.add_theme_color_override("font_color", Color(0.38, 0.42, 0.50, 0.90))
			stars_box.add_child(star_lbl)

		var info_lbl := Label.new()
		info_lbl.name = "InfoLabel"
		info_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		info_lbl.add_theme_font_size_override("font_size", 11)
		info_lbl.add_theme_color_override("font_color", Color(0.18, 0.22, 0.30, 1.0))
		info_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if last_diff == "":
			info_lbl.text = "Sin jugar  •  0 pts"
		else:
			info_lbl.text = "%s  •  Último: %d pts" % [_format_difficulty_label(last_diff), last_score]
		stats_row.add_child(info_lbl)

		btn.pressed.connect(func(): _launch_minigame(scene_path))
		minigames_container.add_child(btn)

func _format_difficulty_label(diff_code: String) -> String:
	match diff_code.to_upper():
		"FACIL":
			return "Fácil"
		"NORMAL":
			return "Normal"
		"INGENIERO":
			return "Ingeniero"
		_:
			return diff_code.capitalize() if diff_code != "" else "Sin jugar"

func _launch_minigame(scene_path: String) -> void:
	var am: Node = null
	if is_inside_tree() and get_tree() and get_tree().root:
		am = get_tree().root.get_node_or_null("AudioManager")
	if am:
		am.play_click()
	if scene_path != "" and ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		print("[ClassroomBase] Escena de minijuego no encontrada o en desarrollo: ", scene_path)

func _on_back_to_lobby() -> void:
	var am: Node = null
	if is_inside_tree() and get_tree() and get_tree().root:
		am = get_tree().root.get_node_or_null("AudioManager")
	if am:
		am.play_click()
	get_tree().change_scene_to_file("res://scenes/campus/Lobby.tscn")
