## Lobby.gd - CU-03: Explorar campus virtual
## Escena principal del Lobby de Ingeniería de Software en Godot 4
## Implementación fiel a la Interfaz Gráfica (InterfazLobby.jpg) y CU-03
## Responsable: Carlos Manuel Aguirre Norato (Líder Técnico)
extends Control

@onready var lbl_user: Label = $VBox/TopHUD/UserBadge/LabelUser
@onready var lbl_points: Label = $VBox/TopHUD/PointsBadge/LabelPoints
@onready var npc_dialogue: Label = $VBox/PanelNPC/DialogueBubble

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

@onready var btn_left_to_center: Button = $VBox/RoomsContainer/RoomLeft/BtnToCenter
@onready var btn_center_to_left: Button = $VBox/RoomsContainer/RoomCenter/BtnToLeft
@onready var btn_center_to_right: Button = $VBox/RoomsContainer/RoomCenter/BtnToRight
@onready var btn_right_to_center: Button = $VBox/RoomsContainer/RoomRight/BtnToCenter

@onready var btn_ajustes: Button = $VBox/TopHUD/BtnAjustes
@onready var settings_modal: Control = $SettingsModal

func _ready() -> void:
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
	npc_dialogue.text = "¡Bienvenido al Campus Virtual! Puedes moverte al Ala Izquierda o al Ala Derecha."

	# Navegación entre alas
	btn_center_to_left.pressed.connect(func():
		AudioManager.play_click()
		_show_room(room_left)
		npc_dialogue.text = "Ala Izquierda: Salones de Programación e Ing. de Software. Tienda Mike disponible."
	)
	
	btn_center_to_right.pressed.connect(func():
		AudioManager.play_click()
		_show_room(room_right)
		npc_dialogue.text = "Ala Derecha: Salones de Lógica y Linux."
	)
	
	btn_left_to_center.pressed.connect(func():
		AudioManager.play_click()
		_show_room(room_center)
		npc_dialogue.text = "Lobby Central: Escaleras principales y Máquina Expendedora."
	)
	
	btn_right_to_center.pressed.connect(func():
		AudioManager.play_click()
		_show_room(room_center)
		npc_dialogue.text = "Lobby Central: Escaleras principales y Máquina Expendedora."
	)

	# Acceso a minijuegos
	btn_prog.pressed.connect(func(): _open_classroom("Aula 101: Programación", "res://scenes/classroom/AulaProgramacion.tscn"))
	btn_soft.pressed.connect(func(): _open_classroom("Aula 102: Ing. Software", "res://scenes/classroom/AulaIngSoftware.tscn"))
	btn_logic.pressed.connect(func(): _open_classroom("Aula 103: Lógica", "res://scenes/classroom/AulaLogica.tscn"))
	btn_linux.pressed.connect(func(): _open_classroom("Aula 104: Linux", "res://scenes/classroom/SistemaOperativoLinux.tscn"))

func _load_lobby_background() -> void:
	if not bg_lobby:
		return
	
	var candidates: Array[String] = [
		"res://assets/lobby centro/4a19f15e-dd55-473f-9006-e995718ef46b.jpg",
		"res://assets/lobby centro/lobby_centro.jpg"
	]
	
	for path in candidates:
		if FileAccess.file_exists(path):
			# Si ya fue procesado por Godot, cargarlo directamente
			if ResourceLoader.exists(path):
				var res = load(path)
				if res is Texture2D:
					bg_lobby.texture = res
					return
			# Si es una imagen aún sin importar por el motor, cargarla como Image en memoria
			var img := Image.load_from_file(path)
			if img and not img.is_empty():
				bg_lobby.texture = ImageTexture.create_from_image(img)
				return

func _load_left_background() -> void:
	if not bg_left:
		return
	
	var candidates: Array[String] = [
		"res://assets/Ala izquierda/izquierda.jpg",
		"res://assets/Ala izquierda/ala_izquierda.jpg"
	]
	
	for path in candidates:
		if FileAccess.file_exists(path):
			if ResourceLoader.exists(path):
				var res = load(path)
				if res is Texture2D:
					bg_left.texture = res
					return
			var img := Image.load_from_file(path)
			if img and not img.is_empty():
				bg_left.texture = ImageTexture.create_from_image(img)
				return

func _load_right_background() -> void:
	if not bg_right:
		return
	
	var candidates: Array[String] = [
		"res://assets/Ala derecha/derecha.jpg",
		"res://assets/Ala derecha/ala_derecha.jpg"
	]
	
	for path in candidates:
		if FileAccess.file_exists(path):
			if ResourceLoader.exists(path):
				var res = load(path)
				if res is Texture2D:
					bg_right.texture = res
					return
			var img := Image.load_from_file(path)
			if img and not img.is_empty():
				bg_right.texture = ImageTexture.create_from_image(img)
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

func _open_classroom(classroom_name: String, scene_path: String) -> void:
	AudioManager.play_click()
	if scene_path != "" and ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		npc_dialogue.text = "%s no se encuentra disponible en este momento." % classroom_name

func _open_settings() -> void:
	AudioManager.play_click()
	if settings_modal:
		settings_modal.open_modal()
