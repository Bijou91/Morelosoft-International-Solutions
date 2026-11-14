## Lobby.gd - CU-03: Explorar campus virtual
## Escena principal del Lobby de Ingeniería de Software en Godot 4
## Implementación fiel a la Interfaz Gráfica (InterfazLobby.jpg) y CU-03
## Responsable: Carlos Manuel Aguirre Norato (Líder Técnico)
extends Control

@onready var lbl_user: Label = $VBox/TopHUD/UserBadge/LabelUser
@onready var lbl_points: Label = $VBox/TopHUD/PointsBadge/LabelPoints

@onready var room_left: Control = $VBox/RoomsContainer/RoomLeft
@onready var room_center: Control = $VBox/RoomsContainer/RoomCenter
@onready var room_right: Control = $VBox/RoomsContainer/RoomRight
@onready var bg_lobby: TextureRect = $BackgroundLobby
@onready var bg_left: TextureRect = $BackgroundLeft
@onready var bg_right: TextureRect = $BackgroundRight

@onready var btn_prog: Button = $VBox/RoomsContainer/RoomLeft/BtnAulaProg
@onready var btn_soft: Button = $VBox/RoomsContainer/RoomLeft/BtnAulaSoft
@onready var btn_logic: Button = $VBox/RoomsContainer/RoomRight/BtnAulaLogic
@onready var btn_linux: Button = $VBox/RoomsContainer/RoomRight/BtnAulaLinux

@onready var btn_left_to_center: BaseButton = $VBox/RoomsContainer/RoomLeft/BtnToCenter
@onready var btn_center_to_left: BaseButton = $VBox/RoomsContainer/RoomCenter/BtnToLeft
@onready var btn_center_to_right: BaseButton = $VBox/RoomsContainer/RoomCenter/BtnToRight
@onready var btn_right_to_center: BaseButton = $VBox/RoomsContainer/RoomRight/BtnToCenter

@onready var btn_ajustes: Button = $VBox/TopHUD/BtnAjustes
@onready var settings_modal: Control = $SettingsModal

const TEX_PANEL_INNER = preload("res://scenes/ui/theme/classic/panel_inner_plate.tres")
const TEX_BTN_NEUT_NORM = preload("res://scenes/ui/theme/classic/btn_neutral_normal.tres")
const TEX_BTN_NEUT_HOV = preload("res://scenes/ui/theme/classic/btn_neutral_hover.tres")
const TEX_BTN_NEUT_PRESS = preload("res://scenes/ui/theme/classic/btn_neutral_pressed.tres")

func _ready() -> void:
	_apply_classic_lobby_assets()
	update_hud()
	EventBus.points_updated.connect(func(_new_tot, _delta): update_hud())

	# Modal de Ajustes (CU-01)
	btn_ajustes.pressed.connect(_open_settings)

	# Carga dinámica de las texturas del Campus
	_load_lobby_background()
	_load_left_background()
	_load_right_background()

	# Configuración inicial: Mostrar Centro (Lobby principal)
	_show_room(room_center)

	# Efecto de respiración y flotación sutil en las flechas de navegación
	_setup_arrow_breathing()

	# Navegación entre alas
	btn_center_to_left.pressed.connect(func():
		AudioManager.play_click()
		_show_room(room_left)
	)
	
	btn_center_to_right.pressed.connect(func():
		AudioManager.play_click()
		_show_room(room_right)
	)
	
	btn_left_to_center.pressed.connect(func():
		AudioManager.play_click()
		_show_room(room_center)
	)
	
	btn_right_to_center.pressed.connect(func():
		AudioManager.play_click()
		_show_room(room_center)
	)

	# Acceso a minijuegos
	btn_prog.pressed.connect(func(): _open_classroom("Aula 101: Programación", "res://scenes/classroom/AulaProgramacion.tscn"))
	btn_soft.pressed.connect(func(): _open_classroom("Aula 102: Ing. Software", "res://scenes/classroom/AulaIngSoftware.tscn"))
	btn_logic.pressed.connect(func(): _open_classroom("Aula 103: Lógica", "res://scenes/classroom/AulaLogica.tscn"))
	btn_linux.pressed.connect(func(): _open_classroom("Aula 104: Linux", "res://scenes/classroom/SistemaOperativoLinux.tscn"))

func _load_lobby_background() -> void:
	if not bg_lobby:
		return
	
	bg_lobby.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_lobby.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	var candidates: Array[String] = [
		"res://assets/lobby/lobby_centro.jpg",
		"res://assets/lobby/4a19f15e-dd55-473f-9006-e995718ef46b.jpg"
	]
	
	for path in candidates:
		if FileAccess.file_exists(path):
			# Si ya fue procesado por Godot, cargarlo directamente
			if ResourceLoader.exists(path):
				var res = load(path)
				if res is Texture2D:
					bg_lobby.texture = res
					print("[Lobby] Fondo centro cargado desde: ", path)
					return
			# Si es una imagen aún sin importar por el motor, cargarla como Image en memoria
			var img := Image.load_from_file(path)
			if img and not img.is_empty():
				bg_lobby.texture = ImageTexture.create_from_image(img)
				print("[Lobby] Fondo centro cargado como Image desde: ", path)
				return

func _load_left_background() -> void:
	if not bg_left:
		return
	
	bg_left.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_left.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	var candidates: Array[String] = [
		"res://assets/lobby/ala_izquierda.jpg",
		"res://assets/lobby/izquierda.jpg"
	]
	
	for path in candidates:
		if FileAccess.file_exists(path):
			if ResourceLoader.exists(path):
				var res = load(path)
				if res is Texture2D:
					bg_left.texture = res
					print("[Lobby] Fondo ala izquierda cargado desde: ", path)
					return
			var img := Image.load_from_file(path)
			if img and not img.is_empty():
				bg_left.texture = ImageTexture.create_from_image(img)
				print("[Lobby] Fondo ala izquierda cargado como Image desde: ", path)
				return

func _load_right_background() -> void:
	if not bg_right:
		return
	
	bg_right.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_right.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	var candidates: Array[String] = [
		"res://assets/lobby/ala_derecha.jpg",
		"res://assets/lobby/derecha.jpg"
	]
	
	for path in candidates:
		if FileAccess.file_exists(path):
			if ResourceLoader.exists(path):
				var res = load(path)
				if res is Texture2D:
					bg_right.texture = res
					print("[Lobby] Fondo ala derecha cargado desde: ", path)
					return
			var img := Image.load_from_file(path)
			if img and not img.is_empty():
				bg_right.texture = ImageTexture.create_from_image(img)
				print("[Lobby] Fondo ala derecha cargado como Image desde: ", path)
				return

func _show_room(target_room: Control) -> void:
	room_left.visible = false
	room_center.visible = false
	room_right.visible = false
	target_room.visible = true
	if bg_lobby:
		bg_lobby.visible = (target_room == room_center)
	if bg_left:
		bg_left.visible = (target_room == room_left)
	if bg_right:
		bg_right.visible = (target_room == room_right)

func update_hud() -> void:
	lbl_user.text = StateManager.get_username()
	lbl_points.text = "Puntos: %d" % StateManager.get_points()

func _make_lobby_plate_style(pad_x: float = 10.0, pad_y: float = 4.0, tint: Color = Color(0.08, 0.11, 0.17, 0.92)) -> StyleBoxTexture:
	var sb := TEX_PANEL_INNER.duplicate() as StyleBoxTexture
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y
	sb.modulate_color = tint
	return sb

func _apply_classic_lobby_assets() -> void:
	# Botón Ajustes con estética Kenney UI clásica translúcida (congruente con ClassroomBase)
	if is_instance_valid(btn_ajustes):
		btn_ajustes.custom_minimum_size = Vector2(92.0, 32.0)
		btn_ajustes.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn_ajustes.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for pair in [
			["normal", TEX_BTN_NEUT_NORM, Color(1.0, 1.0, 1.0, 0.92)],
			["hover", TEX_BTN_NEUT_HOV, Color(1.05, 1.05, 1.05, 0.98)],
			["pressed", TEX_BTN_NEUT_PRESS, Color(0.90, 0.90, 0.90, 0.95)]
		]:
			var sb := (pair[1] as StyleBoxTexture).duplicate() as StyleBoxTexture
			sb.content_margin_left = 10.0
			sb.content_margin_right = 10.0
			sb.content_margin_top = 4.0
			sb.content_margin_bottom = 6.0
			sb.modulate_color = pair[2]
			btn_ajustes.add_theme_stylebox_override(pair[0], sb)
			if pair[0] == "hover":
				btn_ajustes.add_theme_stylebox_override("focus", sb)
		btn_ajustes.add_theme_color_override("font_color", Color(0.14, 0.16, 0.24, 1.0))
		btn_ajustes.add_theme_color_override("font_hover_color", Color(0.05, 0.08, 0.16, 1.0))
		btn_ajustes.add_theme_color_override("font_pressed_color", Color(0.0, 0.0, 0.0, 1.0))

	# Tarjetas de Usuario y Puntos con panel Kenney clásico
	var user_badge := get_node_or_null("VBox/TopHUD/UserBadge") as PanelContainer
	if is_instance_valid(user_badge):
		user_badge.custom_minimum_size.y = 32.0
		user_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		user_badge.add_theme_stylebox_override("panel", _make_lobby_plate_style(10.0, 4.0))
	if is_instance_valid(lbl_user):
		lbl_user.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_user.add_theme_color_override("font_color", Color(0.90, 0.95, 1.0, 1.0))

	var points_badge := get_node_or_null("VBox/TopHUD/PointsBadge") as PanelContainer
	if is_instance_valid(points_badge):
		points_badge.custom_minimum_size.y = 32.0
		points_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		points_badge.add_theme_stylebox_override("panel", _make_lobby_plate_style(10.0, 4.0))
	if is_instance_valid(lbl_points):
		lbl_points.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_points.add_theme_color_override("font_color", Color("ffd54f"))

	# Placas de aulas bajo las flechas amarillas
	var classroom_plate_sb := _make_lobby_plate_style(8.0, 3.0, Color(0.07, 0.10, 0.16, 0.92))
	for btn in [btn_prog, btn_soft, btn_logic, btn_linux]:
		if not is_instance_valid(btn):
			continue
		var badge := btn.get_node_or_null("VBox/NameBadge") as PanelContainer
		if is_instance_valid(badge):
			badge.add_theme_stylebox_override("panel", classroom_plate_sb)

	# Letreros inferiores de zona ("ALA IZQUIERDA", "CENTRO", "ALA DERECHA") en placa Kenney
	var wing_plate_sb := _make_lobby_plate_style(12.0, 3.0, Color(0.07, 0.10, 0.16, 0.88))
	for room in [room_left, room_center, room_right]:
		if not is_instance_valid(room):
			continue
		var lbl_ala := room.get_node_or_null("LabelAla") as Label
		if not is_instance_valid(lbl_ala) or lbl_ala.get_parent() is PanelContainer:
			continue
		var plate := PanelContainer.new()
		plate.name = "WingBadge"
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		plate.anchor_left = 0.5
		plate.anchor_right = 0.5
		plate.anchor_top = 1.0
		plate.anchor_bottom = 1.0
		plate.offset_left = -74.0
		plate.offset_right = 74.0
		plate.offset_top = -32.0
		plate.offset_bottom = -4.0
		plate.grow_horizontal = Control.GROW_DIRECTION_BOTH
		plate.grow_vertical = Control.GROW_DIRECTION_BEGIN
		plate.add_theme_stylebox_override("panel", wing_plate_sb)
		room.add_child(plate)
		room.remove_child(lbl_ala)
		lbl_ala.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_ala.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_ala.add_theme_font_size_override("font_size", 11)
		lbl_ala.add_theme_color_override("font_color", Color(0.75, 0.94, 1.0, 1.0))
		plate.add_child(lbl_ala)

func _open_classroom(classroom_name: String, scene_path: String) -> void:
	AudioManager.play_click()
	if scene_path != "" and ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		print("[Lobby] %s no se encuentra disponible en este momento." % classroom_name)

func _open_settings() -> void:
	AudioManager.play_click()
	if settings_modal:
		settings_modal.open_modal()

func _setup_arrow_breathing() -> void:
	var lateral_arrows: Array[Control] = [
		btn_center_to_left,
		btn_center_to_right,
		btn_left_to_center,
		btn_right_to_center
	]
	for arrow in lateral_arrows:
		if arrow:
			_apply_breathing_effect(arrow)

	var classroom_buttons: Array[Control] = [
		btn_prog,
		btn_soft,
		btn_logic,
		btn_linux
	]
	for btn in classroom_buttons:
		if btn:
			_apply_classroom_arrow_breathing(btn)

func _apply_breathing_effect(arrow: Control) -> void:
	arrow.pivot_offset = Vector2(arrow.size.x * 0.5 if arrow.size.x > 0 else 26.0, arrow.size.y * 0.5 if arrow.size.y > 0 else 28.0)
	var base_top: float = arrow.offset_top
	var base_bottom: float = arrow.offset_bottom
	var amplitude_y: float = 5.0
	var cycle_duration: float = 1.3

	var tween := create_tween().set_loops()
	# Inhalación: Sube sutilmente (-5px) y se expande levemente (1.06)
	tween.tween_property(arrow, "offset_top", base_top - amplitude_y, cycle_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(arrow, "offset_bottom", base_bottom - amplitude_y, cycle_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(arrow, "scale", Vector2(1.06, 1.06), cycle_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Exhalación: Baja sutilmente (+5px) y se contrae levemente (0.96)
	tween.tween_property(arrow, "offset_top", base_top + amplitude_y, cycle_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(arrow, "offset_bottom", base_bottom + amplitude_y, cycle_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(arrow, "scale", Vector2(0.96, 0.96), cycle_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _apply_classroom_arrow_breathing(btn: Control) -> void:
	var base_top: float = btn.offset_top
	var base_bottom: float = btn.offset_bottom
	btn.pivot_offset = Vector2(btn.size.x * 0.5 if btn.size.x > 0 else 60.0, btn.size.y * 0.5 if btn.size.y > 0 else 46.0)
	var amplitude_y: float = 4.0
	var cycle_duration: float = 1.1

	var tween := create_tween().set_loops()
	# Flotación hacia arriba (apuntando hacia la puerta)
	tween.tween_property(btn, "offset_top", base_top - amplitude_y, cycle_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(btn, "offset_bottom", base_bottom - amplitude_y, cycle_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(btn, "scale", Vector2(1.04, 1.04), cycle_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Descenso sutil a la posición base
	tween.tween_property(btn, "offset_top", base_top + amplitude_y, cycle_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(btn, "offset_bottom", base_bottom + amplitude_y, cycle_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(btn, "scale", Vector2(0.98, 0.98), cycle_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
