class_name GameOverModal
extends Control

signal retry_requested
signal exit_requested

@onready var anim_panel: Control = $Center/PanelContainer
@onready var title_label: Label = $Center/PanelContainer/Margin/VBox/HeaderBox/TitleLabel
@onready var subtitle_label: Label = $Center/PanelContainer/Margin/VBox/HeaderBox/SubtitleLabel
@onready var desc_label: Label = $Center/PanelContainer/Margin/VBox/InnerPlate/ReasonBox/DescLabel
@onready var score_val_label: Label = $Center/PanelContainer/Margin/VBox/InnerPlate/ReasonBox/ScoreRow/ValLabel
@onready var total_val_label: Label = $Center/PanelContainer/Margin/VBox/InnerPlate/ReasonBox/TotalRow/ValLabel
@onready var btn_retry: Button = $Center/PanelContainer/Margin/VBox/ButtonsContainer/BtnRetry
@onready var btn_exit: Button = $Center/PanelContainer/Margin/VBox/ButtonsContainer/BtnExit

var _active_tween: Tween = null

func _ready() -> void:
	btn_retry.pressed.connect(_on_retry_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)

func open(reason: String = "Has agotado todas tus vidas disponibles.", score: int = 0) -> void:
	if AudioManager and AudioManager.has_method("play_game_over"):
		AudioManager.play_game_over()
	desc_label.text = reason
	score_val_label.text = "%d PTS" % score
	var accumulated: int = 0
	if StateManager and StateManager.has_method("get_points"):
		accumulated = StateManager.get_points()
	total_val_label.text = "%d PTS" % accumulated

	if is_instance_valid(_active_tween) and _active_tween.is_running():
		_active_tween.kill()
	visible = true
	anim_panel.scale = Vector2(0.85, 0.85)
	anim_panel.modulate.a = 0.0
	_active_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_active_tween.tween_property(anim_panel, "scale", Vector2.ONE, 0.22)
	_active_tween.tween_property(anim_panel, "modulate:a", 1.0, 0.18)

func close() -> void:
	if is_instance_valid(_active_tween) and _active_tween.is_running():
		_active_tween.kill()
	if not visible:
		return
	if anim_panel:
		_active_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_active_tween.tween_property(anim_panel, "scale", Vector2(0.9, 0.9), 0.12)
		_active_tween.tween_property(anim_panel, "modulate:a", 0.0, 0.12)
		_active_tween.finished.connect(func():
			if is_instance_valid(self):
				visible = false
		)
	else:
		visible = false

func _on_retry_pressed() -> void:
	if AudioManager and AudioManager.has_method("play_click"):
		AudioManager.play_click()
	retry_requested.emit()
	close()

func _on_exit_pressed() -> void:
	if AudioManager and AudioManager.has_method("play_click"):
		AudioManager.play_click()
	exit_requested.emit()
	close()
