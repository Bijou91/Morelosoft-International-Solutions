class_name PauseModal
extends Control

signal resume_requested
signal settings_requested
signal restart_requested
signal exit_requested

@onready var anim_panel: Control = $Center/PanelContainer
@onready var title_label: Label = $Center/PanelContainer/MainPanel/Margin/VBox/HeaderBox/TitleLabel
@onready var btn_resume: Button = $Center/PanelContainer/MainPanel/Margin/VBox/InnerPlate/ButtonsContainer/BtnResume
@onready var btn_settings: Button = $Center/PanelContainer/MainPanel/Margin/VBox/InnerPlate/ButtonsContainer/BtnSettings
@onready var btn_restart: Button = $Center/PanelContainer/MainPanel/Margin/VBox/InnerPlate/ButtonsContainer/BtnRestart
@onready var btn_exit: Button = $Center/PanelContainer/MainPanel/Margin/VBox/InnerPlate/ButtonsContainer/BtnExit

func _ready() -> void:
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)

func open(title: String = "PAUSA TÁCTICA") -> void:
	title_label.text = title
	visible = true
	anim_panel.scale = Vector2(0.85, 0.85)
	anim_panel.modulate.a = 0.0
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(anim_panel, "scale", Vector2.ONE, 0.2)
	tw.tween_property(anim_panel, "modulate:a", 1.0, 0.16)

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

func _on_resume_pressed() -> void:
	AudioManager.play_click() if AudioManager else null
	resume_requested.emit()
	close()

func _on_settings_pressed() -> void:
	AudioManager.play_click() if AudioManager else null
	settings_requested.emit()

func _on_restart_pressed() -> void:
	AudioManager.play_click() if AudioManager else null
	restart_requested.emit()
	close()

func _on_exit_pressed() -> void:
	AudioManager.play_click() if AudioManager else null
	exit_requested.emit()
	close()
