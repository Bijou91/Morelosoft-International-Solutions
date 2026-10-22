class_name DifficultyModal
extends Control

signal difficulty_selected(difficulty: String)
signal cancelled

@onready var anim_panel: Control = $Center/PanelContainer
@onready var title_label: Label = $Center/PanelContainer/MainPanel/Margin/VBox/HeaderBox/TitleLabel
@onready var subtitle_label: Label = $Center/PanelContainer/MainPanel/Margin/VBox/HeaderBox/SubtitleLabel
@onready var btn_facil: Button = $Center/PanelContainer/MainPanel/Margin/VBox/InnerPlate/CardsContainer/BtnFacil
@onready var btn_normal: Button = $Center/PanelContainer/MainPanel/Margin/VBox/InnerPlate/CardsContainer/BtnNormal
@onready var btn_ingeniero: Button = $Center/PanelContainer/MainPanel/Margin/VBox/InnerPlate/CardsContainer/BtnIngeniero
@onready var btn_cancel: Button = $Center/PanelContainer/MainPanel/Margin/VBox/BtnCancel

func _ready() -> void:
	btn_facil.pressed.connect(func(): _on_difficulty_picked("FACIL"))
	btn_normal.pressed.connect(func(): _on_difficulty_picked("NORMAL"))
	btn_ingeniero.pressed.connect(func(): _on_difficulty_picked("INGENIERO"))
	btn_cancel.pressed.connect(_on_cancel_pressed)
	
	# Close on outside click if desired
	$DimOverlay.gui_input.connect(_on_dim_overlay_input)

func open(game_title: String = "", info: Dictionary = {}) -> void:
	if not game_title.is_empty():
		title_label.text = game_title.to_upper()
	else:
		title_label.text = "SELECCIÓN DE DIFICULTAD"
		
	if info.has("subtitle"):
		subtitle_label.text = info["subtitle"]
	else:
		subtitle_label.text = "Selecciona el nivel de desafío táctico:"

	if info.has("facil_text"):
		btn_facil.text = info["facil_text"]
	if info.has("normal_text"):
		btn_normal.text = info["normal_text"]
	if info.has("ingeniero_text"):
		btn_ingeniero.text = info["ingeniero_text"]

	visible = true
	# Mini opening tween
	anim_panel.scale = Vector2(0.85, 0.85)
	anim_panel.modulate.a = 0.0
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(anim_panel, "scale", Vector2.ONE, 0.22)
	tw.tween_property(anim_panel, "modulate:a", 1.0, 0.18)

func close() -> void:
	if not visible:
		return
	if anim_panel:
		var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_property(anim_panel, "scale", Vector2(0.9, 0.9), 0.12)
		tw.tween_property(anim_panel, "modulate:a", 0.0, 0.12)
		tw.finished.connect(func(): visible = false)
	else:
		visible = false

func _on_difficulty_picked(diff: String) -> void:
	AudioManager.play_click() if AudioManager else null
	difficulty_selected.emit(diff)
	close()

func _on_cancel_pressed() -> void:
	AudioManager.play_click() if AudioManager else null
	cancelled.emit()
	close()

func _on_dim_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_cancel_pressed()
