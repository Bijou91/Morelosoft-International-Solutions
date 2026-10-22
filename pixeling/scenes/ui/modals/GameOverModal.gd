class_name GameOverModal
extends Control

signal retry_requested
signal exit_requested

@onready var anim_panel: Control = $Center/PanelContainer
@onready var title_label: Label = $Center/PanelContainer/MainPanel/Margin/VBox/HeaderBox/TitleLabel
@onready var desc_label: Label = $Center/PanelContainer/MainPanel/Margin/VBox/InnerPlate/ReasonBox/DescLabel
@onready var score_label: Label = $Center/PanelContainer/MainPanel/Margin/VBox/InnerPlate/ReasonBox/ScoreLabel
@onready var btn_retry: Button = $Center/PanelContainer/MainPanel/Margin/VBox/ButtonsContainer/BtnRetry
@onready var btn_exit: Button = $Center/PanelContainer/MainPanel/Margin/VBox/ButtonsContainer/BtnExit

func _ready() -> void:
	btn_retry.pressed.connect(_on_retry_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)

func open(reason: String = "Has agotado todas tus vidas disponibles.", score: int = 0) -> void:
	AudioManager.play_game_over() if AudioManager else null
	desc_label.text = reason
	if score > 0:
		score_label.text = "Puntaje alcanzado: %d pts" % score
		score_label.visible = true
	else:
		score_label.visible = false
		
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

func _on_retry_pressed() -> void:
	AudioManager.play_click() if AudioManager else null
	retry_requested.emit()
	close()

func _on_exit_pressed() -> void:
	AudioManager.play_click() if AudioManager else null
	exit_requested.emit()
	close()
