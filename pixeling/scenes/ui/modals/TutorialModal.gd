class_name TutorialModal
extends Control

signal start_requested

@onready var anim_panel: Control = $Center/PanelContainer
@onready var title_label: Label = $Center/PanelContainer/MainPanel/Margin/VBox/HeaderBox/TitleLabel
@onready var content_label: Label = $Center/PanelContainer/MainPanel/Margin/VBox/InnerPlate/Scroll/ContentLabel
@onready var btn_start: Button = $Center/PanelContainer/MainPanel/Margin/VBox/BtnStart

func _ready() -> void:
	btn_start.pressed.connect(_on_start_pressed)

func open(title: String = "MANUAL DE OPERACIONES", briefing_text: String = "") -> void:
	title_label.text = title
	if not briefing_text.is_empty():
		content_label.text = briefing_text
	visible = true
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

func _on_start_pressed() -> void:
	AudioManager.play_click() if AudioManager else null
	start_requested.emit()
	close()
