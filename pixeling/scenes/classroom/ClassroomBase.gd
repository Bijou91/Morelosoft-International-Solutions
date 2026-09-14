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
	if lbl_title:
		lbl_title.text = classroom_name
	if lbl_code:
		lbl_code.text = subject_code
	if lbl_tip:
		lbl_tip.text = "%s:\n\"%s\"" % [teacher_name, teacher_tip]
	if btn_back:
		btn_back.pressed.connect(_on_back_to_lobby)
	
	_populate_minigames()

func _populate_minigames() -> void:
	if not minigames_container:
		return
	
	for child in minigames_container.get_children():
		child.queue_free()
		
	for game in minigames_list:
		var btn := Button.new()
		var cu_id: String = game.get("id", "CU-XX")
		var title: String = game.get("name", "Minijuego")
		var scene_path: String = game.get("scene", "")
		
		var saved_data: Dictionary = StateManager.get_minigame_data(cu_id)
		var stars_count: int = saved_data.get("stars", 0)
		var stars_str: String = "⭐".repeat(stars_count) + "☆".repeat(3 - stars_count)
		btn.text = "%s\n%s (%d/3)  •  Récord: %d pts" % [title, stars_str, stars_count, saved_data.get("score", 0)]
		btn.custom_minimum_size = Vector2(0, 54)
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(func(): _launch_minigame(scene_path))
		minigames_container.add_child(btn)

func _launch_minigame(scene_path: String) -> void:
	AudioManager.play_click()
	if scene_path != "" and ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		print("[ClassroomBase] Escena de minijuego no encontrada o en desarrollo: ", scene_path)

func _on_back_to_lobby() -> void:
	AudioManager.play_click()
	get_tree().change_scene_to_file("res://scenes/campus/Lobby.tscn")
