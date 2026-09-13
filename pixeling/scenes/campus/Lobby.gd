## Lobby.gd - CU-03: Explorar campus virtual
## Escena principal del Lobby de Ingeniería de Software en Godot 4
## Responsable: Carlos Manuel Aguirre Norato (Líder Técnico)
extends Control

@onready var lbl_user: Label = $VBox/TopHUD/UserBadge/LabelUser
@onready var lbl_points: Label = $VBox/TopHUD/PointsBadge/LabelPoints
@onready var npc_dialogue: Label = $VBox/VisualNovelSection/PanelNPC/DialogueBubble
@onready var btn_npc: Button = $VBox/VisualNovelSection/PanelNPC/BtnTalkNPC

@onready var btn_door_prog: Button = $VBox/DoorsContainer/BtnAulaProg
@onready var btn_door_soft: Button = $VBox/DoorsContainer/BtnAulaSoft
@onready var btn_door_logic: Button = $VBox/DoorsContainer/BtnAulaLogic
@onready var btn_door_linux: Button = $VBox/DoorsContainer/BtnAulaLinux

var tips: Array[String] = [
	"¡Hola novato! En RoboFlow debes orientar al robot antes de avanzar.",
	"La metodología TSP exige verificar casos de uso con listas de chequeo.",
	"Completa el algoritmo con la menor cantidad de comandos para obtener maxima puntuacion."
]

func _ready() -> void:
	update_hud()
	EventBus.points_updated.connect(func(_new_tot, _delta): update_hud())

	btn_npc.pressed.connect(_on_npc_talk)
	btn_door_prog.pressed.connect(func(): _open_classroom("Aula 101: Introducción a la Programación", "res://scenes/classroom/AulaProgramacion.tscn"))
	btn_door_soft.pressed.connect(func(): _open_classroom("Aula 102: Fundamentos de Ing. de Software", ""))
	btn_door_logic.pressed.connect(func(): _open_classroom("Aula 103: Lógica Computacional y Algoritmos", ""))
	btn_door_linux.pressed.connect(func(): _open_classroom("Aula 104: Sistemas Operativos y Linux", ""))

func update_hud() -> void:
	lbl_user.text = StateManager.get_username()
	lbl_points.text = "Puntos: %d" % StateManager.get_points()

func _on_npc_talk() -> void:
	AudioManager.play_click()
	npc_dialogue.text = tips.pick_random()

func _open_classroom(classroom_name: String, scene_path: String) -> void:
	AudioManager.play_click()
	if scene_path != "" and ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		npc_dialogue.text = "%s en preparacion para este semestre." % classroom_name
