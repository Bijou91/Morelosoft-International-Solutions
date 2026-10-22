class_name VictoryModal
extends Control

signal continue_requested
signal play_again_requested
signal exit_requested

@onready var anim_panel: Control = $Center/PanelContainer
@onready var title_label: Label = $Center/PanelContainer/MainPanel/Margin/VBox/HeaderBox/TitleLabel
@onready var stars_label: Label = $Center/PanelContainer/MainPanel/Margin/VBox/StarsBox/StarsIcons
@onready var stars_desc: Label = $Center/PanelContainer/MainPanel/Margin/VBox/StarsBox/StarsDesc
@onready var score_val_label: Label = $Center/PanelContainer/MainPanel/Margin/VBox/InnerPlate/StatsBox/ScoreRow/ValLabel
@onready var reward_row: HBoxContainer = $Center/PanelContainer/MainPanel/Margin/VBox/InnerPlate/StatsBox/RewardRow
@onready var reward_val_label: Label = $Center/PanelContainer/MainPanel/Margin/VBox/InnerPlate/StatsBox/RewardRow/ValLabel
@onready var record_badge: Label = $Center/PanelContainer/MainPanel/Margin/VBox/InnerPlate/StatsBox/RecordBadge
@onready var btn_continue: Button = $Center/PanelContainer/MainPanel/Margin/VBox/ButtonsContainer/BtnContinue
@onready var btn_play_again: Button = $Center/PanelContainer/MainPanel/Margin/VBox/ButtonsContainer/BtnPlayAgain
@onready var btn_exit: Button = $Center/PanelContainer/MainPanel/Margin/VBox/ButtonsContainer/BtnExit

func _ready() -> void:
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_play_again.pressed.connect(_on_play_again_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)

func open(score: int, stars: int = 3, reward: int = 0, is_new_record: bool = false, custom_title: String = "") -> void:
	AudioManager.play_success() if AudioManager else null
	if not custom_title.is_empty():
		title_label.text = custom_title
	else:
		title_label.text = "¡DESAFÍO SUPERADO!"
		
	# Star display
	var star_icons = ""
	for i in range(3):
		if i < stars:
			star_icons += " ★ "
		else:
			star_icons += " ☆ "
	stars_label.text = star_icons.strip_edges()
	
	match stars:
		3:
			stars_desc.text = "¡DESEMPEÑO IMPECABLE! (3 ESTRELLAS)"
			stars_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
		2:
			stars_desc.text = "¡BUEN TRABAJO DE INGENIERÍA! (2 ESTRELLAS)"
			stars_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
		_:
			stars_desc.text = "¡MISIÓN COMPLETADA! (1 ESTRELLA)"
			stars_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
			
	score_val_label.text = "+%d PTS" % score
	
	if reward > 0:
		reward_val_label.text = "+%d MONEDAS" % reward
		reward_row.visible = true
	else:
		reward_row.visible = false
		
	record_badge.visible = is_new_record
	
	visible = true
	anim_panel.scale = Vector2(0.82, 0.82)
	anim_panel.modulate.a = 0.0
	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(anim_panel, "scale", Vector2.ONE, 0.24)
	tw.tween_property(anim_panel, "modulate:a", 1.0, 0.2)
	
	# Extra celebratory punch on star label
	stars_label.pivot_offset = stars_label.size * 0.5
	stars_label.scale = Vector2(0.5, 0.5)
	var tw_star = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw_star.tween_property(stars_label, "scale", Vector2.ONE, 0.4).set_delay(0.1)

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

func _on_continue_pressed() -> void:
	AudioManager.play_click() if AudioManager else null
	continue_requested.emit()
	close()

func _on_play_again_pressed() -> void:
	AudioManager.play_click() if AudioManager else null
	play_again_requested.emit()
	close()

func _on_exit_pressed() -> void:
	AudioManager.play_click() if AudioManager else null
	exit_requested.emit()
	close()
